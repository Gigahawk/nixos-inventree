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

      packageOverrides = pkgs.callPackage ./python-overrides.nix { };
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
              rev = "27cad60d52a081d3fe2ac12992ea8dc44056b9b3";
              hash = "sha256-ofbftq80mzA4EWddSbw/DBade0UL/OZIgqt4xUDyHoc=";
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
            gunicorn -c gunicorn.conf.py InvenTree.wsgi
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
          self.packages.${system}.inventree-cluster
        ];
        nativeBuildInputs = [
          pip2nix.packages.${system}.pip2nix.python39
          pythonWithPackages
        ];
      };
    });
}
