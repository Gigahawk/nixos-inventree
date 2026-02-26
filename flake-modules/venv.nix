{ inputs, lib, ... }:
{
  inventree.packages = _self: {
    hacks = _self.callPackage inputs.pyproject-nix.build.hacks { };
    workspace = inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ../.; };

    pyprojectOverlay = _self.workspace.mkPyprojectOverlay {
      sourcePreference = "wheel";
    };

    pyprojectOverrides = import ./_pyproject-overrides.nix;

    packageOverrides = lib.composeManyExtensions [
      inputs.pyproject-build-systems.overlays.default
      _self.pyprojectOverlay
      (_: _: {
        inherit (_self) hacks;
      })
      _self.pyprojectOverrides
    ];

    plugins = { };

    python = _self.callPackage ({ python312 }: python312) { };

    pythonSet = _self.callPackage (
      {
        callPackage,
        packageOverrides,
      }:
      (callPackage inputs.pyproject-nix.build.packages { }).overrideScope packageOverrides
    ) { };

    venv = _self.callPackage (
      {
        pythonSet,
        workspace,
        plugins,
      }:
      pythonSet.mkVirtualEnv "inventree-python" (workspace.deps.default // plugins)
    ) { };
  };
}
