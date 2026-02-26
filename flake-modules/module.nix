{ moduleWithSystem, inputs, ... }:
{
  flake = {
    nixosModules.default = moduleWithSystem (
      perSystem@{ pkgs, ... }:
      {
        lib,
        pkgs,
        config,
        ...
      }:
      with lib;
      let
        cfg = config.services.inventree;
        settingsFormat = pkgs.formats.json { };
        defaultUser = "inventree";
        defaultGroup = defaultUser;
        configFormat = pkgs.formats.yaml { };
        configFile = configFormat.generate "config.yaml" cfg.config;
        usersFile = pkgs.writeText "users.json" (builtins.toJSON cfg.users);

        # Pre-compute SystemdDirectories to create the directories if they do not exists.
        singletonIfPrefix = prefix: str: optional (hasPrefix prefix str) (removePrefix prefix str);

        systemdDir =
          prefix:
          concatStringsSep " " (
            [ ]
            ++ (singletonIfPrefix prefix cfg.dataDir)
            ++ (singletonIfPrefix prefix cfg.config.static_root)
            ++ (singletonIfPrefix prefix cfg.config.media_root)
            ++ (singletonIfPrefix prefix cfg.config.backup_dir)
          );

        maybeSystemdDir =
          prefix:
          let
            dirs = systemdDir prefix;
          in
          mkIf (dirs != "") dirs;

        systemdDirectories = {
          RuntimeDirectory = maybeSystemdDir "/run/";
          StateDirectory = maybeSystemdDir "/var/lib/";
          CacheDirectory = maybeSystemdDir "/var/cache/";
          LogsDirectory = maybeSystemdDir "/var/log/";
          ConfigurationDirectory = maybeSystemdDir "/etc/";
        };

        inherit (cfg.packages)
          src
          server
          cluster
          invoke
          refresh-users
          ;
      in
      {
        options.services.inventree = {
          enable = mkEnableOption (lib.mdDoc "Open Source Inventory Management System");

          packages = mkOption {
            default = perSystem.pkgs.inventree;
            description = ''
              This option allows you to override the package scope used for InvenTree.
            '';
            apply =
              p:
              p.overrideScope (_: _: {
                inherit (cfg) plugins;
              });
          };

          #user = mkOption {
          #  type = types.str;
          #  default = defaultUser;
          #  example = "yourUser";
          #  description = mdDoc ''
          #    The user to run InvenTree as.
          #    By default, a user named `${defaultUser}` will be created whose home
          #    directory is [dataDir](#opt-services.inventree.dataDir).
          #  '';
          #};

          #group = mkOption {
          #  type = types.str;
          #  default = defaultGroup;
          #  example = "yourGroup";
          #  description = mdDoc ''
          #    The group to run Syncthing under.
          #    By default, a group named `${defaultGroup}` will be created.
          #  '';
          #};

          plugins = mkOption {
            type = types.attrsOf (types.listOf types.str);
            default = { };
            description = ''
              Plugins to include in the environment.
              See the plugins dir for supported plugins 
            '';
            example = {
              inventree-kicad-plugin = [ ];
            };
          };

          serverBind = mkOption {
            type = types.str;
            default = "${cfg.bindIp}:${toString cfg.bindPort}";
            example = "unix:/run/inventree/inventree.sock";
            description = ''
              The address and port the server will bind to.
            '';
          };

          bindIp = mkOption {
            type = types.str;
            default = "127.0.0.1";
            example = "0.0.0.0";
            description = lib.mdDoc ''
              The IP address the server will bind to.
              (nginx should point to this address if running in production mode)
            '';
          };

          bindPort = mkOption {
            type = types.int;
            default = 8000;
            example = 1337;
            description = lib.mdDoc ''
              The port the server will bind to.
              (nginx should point to this port if running in production mode)
            '';
          };

          dataDir = mkOption {
            type = types.str;
            default = "/var/lib/inventree";
            example = "/home/yourUser";
            description = lib.mdDoc ''
              The default path for all inventree data.
            '';
          };

          serverStartTimeout = mkOption {
            type = types.str;
            # Allow for long migrations to run properly
            default = "10min";
            description = lib.mdDoc ''
              TimeoutStartSec for the server systemd service.
              See https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#TimeoutStartSec=
              for more details
            '';
          };

          serverStopTimeout = mkOption {
            type = types.str;
            default = "5min";
            description = lib.mdDoc ''
              TimeoutStopSec for the server systemd service.
              See https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#TimeoutStopSec=
              for more details
            '';
          };

          configPath = mkOption {
            type = types.str;
            default = cfg.dataDir + "/config.yaml";
            description = lib.mdDoc ''
              Path to config.yaml (automatically created)
            '';
          };

          config = mkOption {
            type = types.submodule {
              freeformType = configFormat.type;
              options = {
                site_url = mkOption {
                  type = types.str;
                  default = "";
                  example = "https://inventree.example.com";
                  description = lib.mdDoc ''
                    The INVENTREE_SITE_URL option defines the base URL for the
                    InvenTree server. This is a critical setting, and it is required
                    for correct operation of the server. If not specified, the
                    server will attempt to determine the site URL automatically -
                    but this may not always be correct!

                    The site URL is the URL that users will use to access the
                    InvenTree server. For example, if the server is accessible at
                    `https://inventree.example.com`, the site URL should be set to
                    `https://inventree.example.com`. Note that this is not
                    necessarily the same as the internal URL that the server is
                    running on - the internal URL will depend entirely on your
                    server configuration and may be obscured by a reverse proxy or
                    other such setup.
                  '';
                };
                allowed_hosts = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  example = [ "*" ];
                  description = lib.mdDoc ''
                    List of allowed hosts used to connect to the server.

                    If set, site_url is appended to this list at runtime.
                    If the list evaluates to empty at runtime, it defaults to allow
                    all (`["*"]`).
                  '';
                };
              };
            };
            default = { };
            description = lib.mdDoc ''
              Config options, see https://docs.inventree.org/en/stable/start/config/
              for details
            '';
          };

          users = mkOption {
            default = { };
            description = mdDoc ''
              Users which should be present on the InvenTree server
            '';
            example = {
              admin = {
                email = "admin@localhost";
                is_superuser = true;
                password_file = /path/to/passwordfile;
              };
            };
            type = types.attrsOf (
              types.submodule (
                { name, ... }:
                {
                  freeformType = settingsFormat.type;
                  options = {
                    name = mkOption {
                      type = types.str;
                      default = name;
                      description = lib.mdDoc ''
                        The name of the user
                      '';
                    };

                    password_file = mkOption {
                      type = types.path;
                      description = lib.mdDoc ''
                        The path to the password file for the user
                      '';
                    };

                    is_superuser = mkOption {
                      type = types.bool;
                      default = false;
                      description = lib.mdDoc ''
                        Set to true to create the account as a superuser
                      '';
                    };
                  };
                }
              )
            );
          };
        };

        imports = [
          (lib.mkRenamedOptionModule
            [ "services" "inventree" "siteUrl" ]
            [ "services" "inventree" "config" "site_url" ]
          )
          (lib.mkRenamedOptionModule
            [ "services" "inventree" "allowedHosts" ]
            [ "services" "inventree" "config" "allowed_hosts" ]
          )
        ];

        config = mkIf cfg.enable {
          environment.systemPackages = [
            (pkgs.symlinkJoin {
              name = "inventree-invoke";
              paths = [ invoke ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/inventree-invoke \
                  --set INVENTREE_CONFIG_FILE ${toString cfg.configPath}
              '';
            })
          ];

          users.users.${defaultUser} = {
            group = defaultGroup;
            # Is this important?
            #uid = config.ids.uids.inventree;
            # Seems to be required with no uid set
            isSystemUser = true;
            description = "InvenTree daemon user";
          };

          users.groups.${defaultGroup} = {
            # Is this important?
            #gid = config.ids.gids.inventree;
          };

          systemd.services.inventree-server = {
            description = "InvenTree service";
            wantedBy = [ "multi-user.target" ];
            environment = {
              INVENTREE_CONFIG_FILE = toString cfg.configPath;
            };
            serviceConfig = systemdDirectories // {
              User = defaultUser;
              Group = defaultGroup;
              TimeoutStartSec = cfg.serverStartTimeout;
              TimeoutStopSec = cfg.serverStopTimeout;
              ExecStartPre = "+${pkgs.writers.writeBash "inventree-setup" ''
                echo "Creating config file"
                mkdir -p "$(dirname "${toString cfg.configPath}")"
                cp ${configFile} ${toString cfg.configPath}

                echo "Running database migrations"
                ${invoke}/bin/inventree-invoke migrate

                echo "Ensuring static files are populated"
                pushd ${src}/static
                find . -type f -exec install -Dm 644 "{}" "${cfg.config.static_root}/{}" \;
                popd

                echo "Setting up users"
                cat ${usersFile} | \
                  ${refresh-users}/bin/inventree-refresh-users
              ''}";
              ExecStart = ''
                ${server}/bin/inventree-server -b ${cfg.serverBind}
              '';
            };
          };
          systemd.services.inventree-cluster = {
            description = "InvenTree background worker";
            wantedBy = [ "multi-user.target" ];
            environment = {
              INVENTREE_CONFIG_FILE = toString cfg.configPath;
            };
            serviceConfig = systemdDirectories // {
              User = defaultUser;
              Group = defaultGroup;
              ExecStart = ''
                ${cluster}/bin/inventree-cluster
              '';
            };
          };
        };
      }
    );
  };
}
