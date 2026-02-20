{ inputs, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      self',
      ...
    }:
    let
      hacks = pkgs.callPackage inputs.pyproject-nix.build.hacks { };
      workspace = inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ../.; };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };
      pyprojectOverrides = import ./_pyproject-overrides.nix {
        python = self'.packages.python;
        inherit hacks;
      };

      pythonSet =
        (pkgs.callPackage inputs.pyproject-nix.build.packages {
          python = self'.packages.python;
        }).overrideScope
          (
            lib.composeManyExtensions [
              inputs.pyproject-build-systems.overlays.default
              overlay
              pyprojectOverrides
            ]
          );

      venvWithPlugins = lib.makeOverridable (
        {
          plugins ? { },
        }:
        pythonSet.mkVirtualEnv "inventree-python" (workspace.deps.default // plugins)
      );

    in
    {
      packages = rec {
        venv = venvWithPlugins { };
        # Example venv with plugins enabled
        # venv2 = venv.override {
        #   plugins = {
        #     inventree-kicad-plugin = [ ];
        #   };
        # };
      };
    };
}
