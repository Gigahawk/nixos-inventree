{ inputs, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:
    let
      venv = self'.packages.venv;

      mkOverride =
        scope: path:
        let
          pkgFun = import path;
        in
        lib.makeOverridable (args: pkgs.callPackage pkgFun (scope // { inherit venv; } // args)) { };

      packages = lib.fix (
        self:
        let
          call = mkOverride self;
        in
        {
          src = call ../pkgs/src.nix;

          server = call ../pkgs/server.nix;
          cluster = call ../pkgs/cluster.nix;
          invoke = call ../pkgs/invoke.nix;
          refresh-users = call ../pkgs/refresh-users.nix;
          gen-secret = call ../pkgs/gen-secret.nix;

          inventree-python = call ../pkgs/python.nix;
        }
      );
    in
    {
      inherit packages;
    };
}
