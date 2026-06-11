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
        extraWorkspaces ? null,
        extraOverrides ? null,
      }:
      let
        extOverrides = if extraOverrides != null then import extraOverrides else (_: _: { });
        extWorkspace =
          if extraWorkspaces != null then
            inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = extraWorkspaces; }
          else
            null;
        extOverlay =
          if extWorkspace != null then
            extWorkspace.mkPyprojectOverlay { sourcePreference = "wheel"; }
          else
            null;
        extEditableOverlay =
          if extWorkspace != null then
            extWorkspace.mkEditablePyprojectOverlay { root = "$REPO_ROOT"; }
          else
            null;
        extSet =
          if extOverlay != null then
            pythonSet.overrideScope (
              lib.composeManyExtensions [
                inputs.pyproject-build-systems.overlays.wheel
                extOverlay
                # Is this necessary for our usecase?
                extEditableOverlay
                _self.pyprojectOverrides
                extOverrides
              ]
            )
          else
            pythonSet;
        extDeps = if extWorkspace != null then extWorkspace.deps.default else { };
      in
      extSet.mkVirtualEnv "inventree-python" (workspace.deps.default // extDeps)
    ) { };
  };
}
