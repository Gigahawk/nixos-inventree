final: prev:

{
  inventree = final.lib.makeScope final.newScope (self: {
    pythonOverrides = self.callPackage ./python-overrides.nix { };
    customOverrides = self.callPackage ./custom-overrides.nix { };
    pythonBin = self.callPackage ({python312}: python312.override {
      packageOverrides = final.lib.composeManyExtensions [
        (import ./maybe-overrides.nix)
        self.pythonOverrides
        self.customOverrides
        (self: super: {
          buildPythonPackage = super.oldBuildPythonPackage;
        })
      ];
    }) {};
    pythonPackages = import ./python-all-requirements.nix;
    pythonWithPackages = self.pythonBin.withPackages self.pythonPackages;

    src = self.callPackage ./pkgs/src.nix {};
    server = self.callPackage ./pkgs/server.nix {};
    cluster = self.callPackage ./pkgs/cluster.nix {};
    invoke = self.callPackage ./pkgs/invoke.nix {};
    python = self.callPackage ./pkgs/python.nix {};
    refresh-users = self.callPackage ./pkgs/refresh-users.nix {};
    gen-secret = self.callPackage ./pkgs/gen-secret.nix {};

    # Requires pip2nix overlay, which is managed by the flake.
    shell = self.callPackage ./pkgs/shell.nix {};
  });
}
