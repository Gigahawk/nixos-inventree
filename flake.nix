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
        inventree = with import nixpkgs { inherit system; };
        let
          #generatedOverrides = pkgs.callPackage ./python-packages.nix { };
          #manualOverrides = self: super: {
          #  pillow = pythonPackages.pillow.overrideDerivation(old:
          #    with super.pillow; { inherit name src; }
          #);};
          #packageOverrides = lib.mkMerge [ generatedOverrides manualOverrides ];
          packageOverrides = pkgs.callPackage ./python-overrides.nix { };
          python = pkgs.python3.override { inherit packageOverrides; };

          pythonPackages = import ./python-requirements.nix;
          pythonWithPackages = python.withPackages pythonPackages;
        in
        pkgs.writeShellApplication rec {
          name = "inventree";
          runtimeInputs = [
            #python311Packages.gunicorn
            pythonWithPackages
            self.packages.${system}.inventree-src
          ];

          text = ''
            INVENTREE_SRC=${self.packages.${system}.inventree-src}/src
            pushd $INVENTREE_SRC/InvenTree
            ls
            type gunicorn
            gunicorn -c gunicorn.conf.py InvenTree.wsgi -b 127.0.0.1:8000
            popd
          '';
        };
        default = self.packages.${system}.inventree;
      };
      devShell = pkgs.mkShell {
        inputsFrom = [ self.packages.${system}.inventree ];
        nativeBuildInputs = [
          pip2nix.packages.${system}.pip2nix.python39
        ];
      };
    });
}
