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

          src = pkgs.fetchFromGitHub {
            owner = "inventree";
            repo = "InvenTree";
            rev = version;
            hash = "sha256-PW/aX8h3W2xcFZ1zfYE9+Uy6bkNrPeoDc48CA70cOhA=";
          };

          installPhase = ''
            runHook  preInstall

            find . -type f -exec install -Dm 755 "{}" "$out/src/{}" \;

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
        ];
      };
    });
}
