final: prev:

{
  inventree = rec {
    pythonOverrides = prev.callPackage ./python-overrides.nix { };
    customOverrides = prev.callPackage ./custom-overrides.nix { };
    pythonBin = prev.python3.override {
      packageOverrides = prev.lib.composeManyExtensions [
        (import ./maybe-overrides.nix)
        pythonOverrides
        customOverrides
        (self: super: {
          buildPythonPackage = super.oldBuildPythonPackage;
        })
      ];
    };
    pythonPackages = import ./python-all-requirements.nix;
    pythonWithPackages = pythonBin.withPackages pythonPackages;

    src = prev.callPackage ./pkgs/src.nix {};
    server = prev.callPackage ./pkgs/server.nix {};
    cluster = prev.callPackage ./pkgs/cluster.nix {};
    invoke = prev.callPackage ./pkgs/invoke.nix {};
    python = prev.callPackage ./pkgs/python.nix {};
    refresh-users = prev.callPackage ./pkgs/refresh-users.nix {};
    gen-secret = prev.callPackage ./pkgs/gen-secret.nix {};

    # Requires pip2nix overlay, which is managed by the flake.
    shell = prev.callPackage ./pkgs/shell.nix {};
  };
}