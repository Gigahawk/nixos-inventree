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
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.pip2nix self.overlays.default ];
      };
    in {
      packages.inventree = {
        inherit (pkgs.inventree) src server cluster invoke python
          refresh-users gen-secret;
      };
      devShell = pkgs.inventree.shell;
    }) // {
      overlays.default = import ./overlay.nix;
      overlays.pip2nix = final: prev: {
        pip2nix = pip2nix.packages.${prev.system}.pip2nix;
      };

      nixosModules.default = import ./module.nix;

      # Backward compatibility.
      nixosModule = import ./module.nix;
    };
}
