{ lib, pkgs, config, ... }:

with lib;
let
  cfg = config.services.inventree;
  settingsFormat = pkgs.formats.json { };
  defaultUser = "inventree";
  defaultGroup = defaultUser;
  configFile = pkgs.writeText "config.yaml" (builtins.toJSON cfg.config);
  usersFile = pkgs.writeText "users.json" (builtins.toJSON cfg.users);
  inventree = pkgs.inventree;
in

{
  options.services.inventree = {
    enable = mkEnableOption
      (lib.mdDoc "Open Source Inventory Management System");

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

    serverBind = mkOption {
      type = types.str;
      default = "127.0.0.1:8000";
      example = "0.0.0.0:1337";
      description = lib.mdDoc ''
        The address and port the server will bind to.
        (nginx should point to this address if running in production mode)
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
      default = {};
      description = lib.mdDoc ''
        Config options, see https://docs.inventree.org/en/stable/start/config/
        for details
      '';
    };

    users = mkOption {
      default = {};
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
      type = types.attrsOf (types.submodule ({ name, ... }: {
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
      }));
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [ (import ./overlay.nix) ];

    environment.systemPackages = [
      inventree.invoke
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
      serviceConfig = {
        User = defaultUser;
        Group = defaultGroup;
        TimeoutStartSec = cfg.serverStartTimeout;
        TimeoutStopSec= cfg.serverStopTimeout;
        ExecStartPre =
          "+${pkgs.writers.writeBash "inventree-setup" ''
            echo "Creating config file"
            mkdir -p "$(dirname "${toString cfg.configPath}")"
            cp ${configFile} ${toString cfg.configPath}

            echo "Running database migrations"
            ${inventree.invoke}/bin/inventree-invoke migrate

            echo "Ensuring static files are populated"
            ${inventree.invoke}/bin/inventree-invoke static

            echo "Setting up users"
            cat ${usersFile} | \
              ${inventree.refresh-users}/bin/inventree-refresh-users
          ''}";
        ExecStart = ''
          ${inventree.server}/bin/inventree-server -b ${cfg.serverBind}
        '';
      };
    };
    systemd.services.inventree-cluster = {
      description = "InvenTree background worker";
      wantedBy = [ "multi-user.target" ];
      environment = {
        INVENTREE_CONFIG_FILE = toString cfg.configPath;
      };
      serviceConfig = {
        User = defaultUser;
        Group = defaultGroup;
        ExecStart = ''
          ${inventree.cluster}/bin/inventree-cluster
        '';
      };
    };
  };
}