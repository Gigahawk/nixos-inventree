{
  description = "Devshell and package definition";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    pip2nix = {
      url = "github:nix-community/pip2nix";
    };
  };

  outputs = { self, nixpkgs, flake-utils, pip2nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      version = "0.13.0";

      pythonOverrides = pkgs.callPackage ./python-overrides.nix { };
      customOverrides = pkgs.callPackage ./custom-overrides.nix { };
      packageOverrides = nixpkgs.lib.composeManyExtensions [ pythonOverrides customOverrides ];
      python = pkgs.python3.override { inherit packageOverrides; };
      pythonPackages = import ./python-all-requirements.nix;
      pythonWithPackages = python.withPackages pythonPackages;
    in {
      packages = {
        inventree-src = with import nixpkgs { inherit system; };
        stdenv.mkDerivation rec {
          pname = "inventree-src";
          inherit version;

          srcs = [
            (pkgs.fetchFromGitHub {
              name = "inventree-src";
              #owner = "inventree";
              owner = "Gigahawk";
              repo = "InvenTree";
              #rev = version;
              rev = "eb5b161617fc5ff36e91ab007008736b1d37a0d7";
              hash = "sha256-oTkL7Lu+llj1O23Ql1EQKt24UmTLxJNYT5cJhcEReWQ=";
            })
            (pkgs.fetchzip {
              name = "inventree-frontend";
              url = "https://github.com/inventree/InvenTree/releases/download/${version}/frontend-build.zip";
              hash = "sha256-w4QJ03Bgy9hikrSIaJzqeEwlR+hHkBZ0bljXp+JW56o=";
              stripRoot=false;
            })
          ];

          sourceRoot = ".";


          nativeBuildInputs = [
            pkgs.yarn
          ];

          installPhase = ''
            runHook  preInstall

            pushd inventree-src
            find . -type f -exec install -Dm 755 "{}" "$out/src/{}" \;
            popd

            pushd inventree-frontend
            find . -type f -exec install -Dm 755 "{}" "$out/src/InvenTree/web/static/web/{}" \;
            popd

            runHook postInstall
          '';

          meta = with lib; {
            homepage = "https://github.com/Gigahawk/nixos-inventree";
            description = "InvenTree packaged for nixos";
            license = licenses.gpl3;
            platforms = platforms.all;
          };
        };
        inventree-server = with import nixpkgs { inherit system; };
        pkgs.writeShellApplication rec {
          name = "inventree-server";
          runtimeInputs = [
            pythonWithPackages
            self.packages.${system}.inventree-src
          ];

          text = ''
            INVENTREE_SRC=${self.packages.${system}.inventree-src}/src
            pushd $INVENTREE_SRC/InvenTree
            gunicorn -c gunicorn.conf.py InvenTree.wsgi "$@"
            popd
          '';
        };
        inventree-cluster = with import nixpkgs { inherit system; };
        pkgs.writeShellApplication rec {
          name = "inventree-cluster";
          runtimeInputs = [
            pythonWithPackages
            self.packages.${system}.inventree-src
          ];

          text = ''
            INVENTREE_SRC=${self.packages.${system}.inventree-src}/src
            pushd $INVENTREE_SRC/InvenTree
            python manage.py qcluster
            popd
          '';
        };
        inventree-invoke = with import nixpkgs { inherit system; };
        let
          # invoke command from nixpkgs is a prebuilt binary that appears to
          # ignore the environment, create our own script to run invoke with
          # our environment
          invokeMain = pkgs.writeScript "invokeMain" ''
            from invoke import Program, __version__

            program = Program(
                name="Invoke",
                binary="inv[oke]",
                binary_names=["invoke", "inv"],
                version=__version__,
            )
            program.run()
          '';
        in
        pkgs.writeShellApplication rec {
          name = "inventree-invoke";
          runtimeInputs = [
            pkgs.yarn
            pythonWithPackages
            self.packages.${system}.inventree-src
          ];

          text = ''
            INVENTREE_SRC=${self.packages.${system}.inventree-src}/src
            pushd $INVENTREE_SRC > /dev/null 2>&1
            python ${invokeMain} "$@"
            popd > /dev/null 2>&1
          '';
        };
        inventree-python = with import nixpkgs { inherit system; };
        pkgs.writeShellApplication rec {
          name = "inventree-python";
          runtimeInputs = [
            pythonWithPackages
            self.packages.${system}.inventree-src
          ];

          text = ''
            INVENTREE_SRC=${self.packages.${system}.inventree-src}/src
            pushd "$INVENTREE_SRC/''${INVENTREE_PYTHON_CWD:-}"
            python "$@"
            popd
          '';
        };
        inventree-refresh-users = with import nixpkgs { inherit system; };
        let
          refreshScript = pkgs.writeScript "refresh_users.py" (builtins.readFile ./refresh_users.py);
        in
        pkgs.writeShellApplication rec {
          name = "inventree-refresh-users";
          runtimeInputs = [
            pythonWithPackages
            self.packages.${system}.inventree-src
          ];

          text = ''
            INVENTREE_SRC=${self.packages.${system}.inventree-src}/src
            pushd $INVENTREE_SRC/InvenTree > /dev/null 2>&1
            python ${refreshScript}
            popd > /dev/null 2>&1
          '';
        };
        inventree-gen-secret = with import nixpkgs { inherit system; };
        let
          genScript = pkgs.writeScript "gen_secret_key.py" ''
            import sys
            sys.path.insert(0 , '.')
            from InvenTree.config import get_secret_key
            get_secret_key()
          '';
        in
          pkgs.writeShellApplication rec {
            name = "inventree-gen-secret";
            runtimeInputs = [
              pythonWithPackages
              self.packages.${system}.inventree-src
            ];

            text = ''
              INVENTREE_SRC=${self.packages.${system}.inventree-src}/src
              INVENTREE_CONFIG_FILE="$(pwd)/config.yaml"
              export INVENTREE_CONFIG_FILE
              INVENTREE_SECRET_KEY_FILE="$(pwd)/secret_key.txt"
              export INVENTREE_SECRET_KEY_FILE
              unset INVENTREE_SECRET_KEY

              pushd $INVENTREE_SRC/InvenTree > /dev/null 2>&1
              echo "Removing any existing secret $INVENTREE_SECRET_KEY_FILE"
              rm -rf "$INVENTREE_SECRET_KEY_FILE"
              python ${genScript}
              echo "Removing temp config file $INVENTREE_CONFIG_FILE"
              rm "$INVENTREE_CONFIG_FILE"
              # TODO: is this something we actually want to do?
              echo "Secret key written to $INVENTREE_SECRET_KEY_FILE"
              cat "$INVENTREE_SECRET_KEY_FILE"
              echo
              popd > /dev/null 2>&1
            '';
          };

      };
      devShell = pkgs.mkShell {
        inputsFrom = [
          self.packages.${system}.inventree-server
        ];
        nativeBuildInputs = [
          pip2nix.packages.${system}.pip2nix.python39
          pythonWithPackages
          pkgs.yarn
          pkgs.yarn2nix
          self.packages.${system}.inventree-server
          self.packages.${system}.inventree-cluster
          self.packages.${system}.inventree-gen-secret
          self.packages.${system}.inventree-python
          self.packages.${system}.inventree-invoke
          self.packages.${system}.inventree-refresh-users
        ];
      };
    }) // {
      nixosModule = { lib, pkgs, config, ... }:
        with lib;
        let
          cfg = config.services.inventree;
          settingsFormat = pkgs.formats.json { };
          defaultUser = "inventree";
          defaultGroup = defaultUser;
          configFile = pkgs.writeText "config.yaml" (builtins.toJSON cfg.config);
          usersFile = pkgs.writeText "users.json" (builtins.toJSON cfg.users);
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

          config = mkIf cfg.enable ({
            environment.systemPackages = [
              self.packages.${pkgs.system}.inventree-invoke
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
                    ${self.packages.${pkgs.system}.inventree-invoke}/bin/inventree-invoke migrate

                    echo "Ensuring static files are populated"
                    ${self.packages.${pkgs.system}.inventree-invoke}/bin/inventree-invoke static

                    echo "Setting up users"
                    cat ${usersFile} | \
                      ${self.packages.${pkgs.system}.inventree-refresh-users}/bin/inventree-refresh-users
                  ''}";
                ExecStart = ''
                  ${self.packages.${pkgs.system}.inventree-server}/bin/inventree-server -b ${cfg.serverBind}
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
                  ${self.packages.${pkgs.system}.inventree-cluster}/bin/inventree-cluster
                '';
              };
            };
          });
        };
    };
}
