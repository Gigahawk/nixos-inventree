{ inputs, ... }:
{
  inventree.packages = _self: {
    src = _self.callPackage ../pkgs/src.nix { };

    server = _self.callPackage ../pkgs/server.nix { };
    cluster = _self.callPackage ../pkgs/cluster.nix { };
    invoke = _self.callPackage ../pkgs/invoke.nix { };
    refresh-users = _self.callPackage ../pkgs/refresh-users.nix { };
    gen-secret = _self.callPackage ../pkgs/gen-secret.nix { };

    inventree-python = _self.callPackage ../pkgs/python.nix { };
  };

  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages = {
        inherit (pkgs.inventree)
          src
          server
          cluster
          invoke
          refresh-users
          gen-secret
          inventree-python
          venv
          ;
        venvWithPlugins = pkgs.inventree.venv.override (final: {
          extraWorkspaces = ../plugin_ws;
        });
      };
    };
}
