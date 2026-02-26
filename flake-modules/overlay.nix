{
  config,
  lib,
  self,
  inputs,
  ...
}:
{
  options = {
    inventree.packages = lib.mkOption {
      type = lib.types.functionTo lib.types.attrs;
    };
  };
  config = {
    flake.overlays.default = final: prev: {
      inventree = final.lib.makeScope final.newScope config.inventree.packages;
    };
    perSystem =
      { system, ... }:
      {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
          ];
          config = { };
        };
      };
  };
}
