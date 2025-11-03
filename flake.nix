{
  description = "Devshell and package definition";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
        inherit (nixpkgs) lib;
        python = pkgs.python312;

        hacks = pkgs.callPackage pyproject-nix.build.hacks { };

        workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

        overlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel";
        };

        pyprojectOverrides = final: prev: {
          weasyprint = hacks.nixpkgsPrebuilt {
            from = python.pkgs.weasyprint;
          };

          # Seems packages aren't generally available unless they are explicitly
          # specified in an overlay?
          binaryornot = hacks.nixpkgsPrebuilt {
            from = python.pkgs.binaryornot;
          };
          #binaryornot = prev.binaryornot;

          django-allauth = prev.django-allauth.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [
              prev.setuptools
              prev.wheel
            ];
          });

          django-mailbox = prev.django-mailbox.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [
              prev.setuptools
              prev.wheel
            ];
          });

          django-xforwardedfor-middleware = prev.django-xforwardedfor-middleware.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [
              prev.setuptools
              prev.wheel
            ];
          });

          dj-rest-auth = prev.dj-rest-auth.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [
              prev.setuptools
              prev.wheel
            ];
          });

          odfpy = prev.odfpy.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [
              prev.setuptools
              prev.wheel
            ];
          });

          sgmllib3k = prev.sgmllib3k.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [
              prev.setuptools
              prev.wheel
            ];
          });

          coreschema = prev.coreschema.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [
              prev.setuptools
              prev.wheel
            ];
          });

          invoke = prev.invoke.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [
              prev.setuptools
              prev.wheel
            ];
          });

          # Plugins
          # TODO: is there a nice way to not have to inherit prev?
          inventree-kicad-plugin = (final.callPackage ./plugins/inventree-kicad-plugin.nix { inherit prev; });
        };

        pythonSet =
          (pkgs.callPackage pyproject-nix.build.packages {
            inherit python;
          }).overrideScope
            (
              lib.composeManyExtensions [
                pyproject-build-systems.overlays.default
                overlay
                pyprojectOverrides
              ]
            );

        venvWithPlugins = (
          plugins: pythonSet.mkVirtualEnv "inventree-python" (workspace.deps.default // plugins)
        );
      in
      {
        formatter = pkgs.nixfmt-tree;
        packages = rec {
          inherit (pkgs.inventree)
            src
            server
            cluster
            invoke
            python
            refresh-users
            gen-secret
            ;
          venv = (venvWithPlugins { inventree-kicad-plugin = [ ]; });
        };
        devShells = rec {
          uv = pkgs.mkShell {
            packages = [
              pkgs.uv
            ];
            env = {
              # Don't create venv using uv
              UV_NO_SYNC = "1";

              # Force uv to use nixpkgs Python interpreter
              UV_PYTHON = python.interpreter;

              # Prevent uv from downloading managed Python's
              UV_PYTHON_DOWNLOADS = "never";
            };

            shellHook = ''
              # Undo dependency propagation by nixpkgs.
              unset PYTHONPATH

              # Get repository root using git. This is expanded at runtime by the editable `.pth` machinery.
              export REPO_ROOT=$(git rev-parse --show-toplevel)
            '';
          };
          default = uv;
        };
      }
    )
    // {
      overlays.default = (
        final: prev: {
          inventree = final.lib.makeScope final.newScope (_self: {
            pythonWithPackages = self.packages.${prev.system}.venv;

            src = _self.callPackage ./pkgs/src.nix { };
            server = _self.callPackage ./pkgs/server.nix { };
            cluster = _self.callPackage ./pkgs/cluster.nix { };
            invoke = _self.callPackage ./pkgs/invoke.nix { };
            python = _self.callPackage ./pkgs/python.nix { };
            refresh-users = _self.callPackage ./pkgs/refresh-users.nix { };
            gen-secret = _self.callPackage ./pkgs/gen-secret.nix { };
          });
        }
      );

      nixosModules.default =
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
          configFile = pkgs.writeText "config.yaml" (builtins.toJSON cfg.config);
          usersFile = pkgs.writeText "users.json" (builtins.toJSON cfg.users);
          inventree = pkgs.inventree;
          serverBind = "${cfg.bindIp}:${toString cfg.bindPort}";
          allowedHostsStr = concatStringsSep "," cfg.allowedHosts;

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
        in

        {
          options.services.inventree = {
            enable = mkEnableOption (lib.mdDoc "Open Source Inventory Management System");

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

            siteUrl = mkOption {
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

            allowedHosts = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "*" ];
              description = lib.mdDoc ''
                List of allowed hosts used to connect to the server.

                If set, siteUrl is appended to this list at runtime.
                If the list evaluates to empty at runtime, it defaults to allow
                all (`["*"]`).
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
              type = types.attrs;
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

          config = mkIf cfg.enable {
            nixpkgs.overlays = [ self.overlays.default ];

            environment.systemPackages = [
              (pkgs.symlinkJoin {
                name = "inventree-invoke";
                paths = [ inventree.invoke ];
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
                INVENTREE_SITE_URL = cfg.siteUrl;
                INVENTREE_ALLOWED_HOSTS = allowedHostsStr;
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
                  ${inventree.invoke}/bin/inventree-invoke migrate

                  echo "Ensuring static files are populated"
                  pushd ${inventree.src}/static
                  find . -type f -exec install -Dm 644 "{}" "${cfg.config.static_root}/{}" \;
                  popd

                  echo "Setting up users"
                  cat ${usersFile} | \
                    ${inventree.refresh-users}/bin/inventree-refresh-users
                ''}";
                ExecStart = ''
                  ${inventree.server}/bin/inventree-server -b ${serverBind}
                '';
              };
            };
            systemd.services.inventree-cluster = {
              description = "InvenTree background worker";
              wantedBy = [ "multi-user.target" ];
              environment = {
                INVENTREE_CONFIG_FILE = toString cfg.configPath;
                INVENTREE_SITE_URL = cfg.siteUrl;
                INVENTREE_ALLOWED_HOSTS = allowedHostsStr;
              };
              serviceConfig = systemdDirectories // {
                User = defaultUser;
                Group = defaultGroup;
                ExecStart = ''
                  ${inventree.cluster}/bin/inventree-cluster
                '';
              };
            };
          };
        };

      nixosModule = self.nixosModules.default;
    };
}
