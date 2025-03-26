{
  description = "Devshell and package definition";

  inputs = {
    # django-allauth-2fa has been removed from unstable
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
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.pip2nix self.overlays.default ];
      };
    in {
      packages = {
        inherit (pkgs.inventree) src server cluster invoke python
          refresh-users gen-secret shell;
        inherit (pkgs) pip2nix;
      };
      devShell = pkgs.inventree.shell;
    }) // {
      overlays.default = import ./overlay.nix;
      overlays.pip2nix = final: prev: {
        # Note: packages.x86_64-linux.pip2nix does not exists.
        pip2nix = pip2nix.defaultPackage.${prev.system};
      };

      nixosModules.default = import ./module.nix;

      # Backward compatibility.
      nixosModule = import ./module.nix;
    };
}
