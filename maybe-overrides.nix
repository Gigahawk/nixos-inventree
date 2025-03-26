# Extend python packages.

self: super: {
  oldBuildPythonPackage = super.buildPythonPackage;
  buildPythonPackage = pkg:
    let
      oldVersionSafe = builtins.tryEval (super."${pkg.pname or " "}".version or "");
      oldVersion = if oldVersionSafe.success then oldVersionSafe.value else "";
      newVersion = pkg.version;
      newer =
        oldVersion == "" ||
        builtins.compareVersions newVersion oldVersion > 0;
    in
      if newer then
        # __trace "${pkg.pname}: ${newVersion} > ${oldVersion}"
        super.buildPythonPackage pkg
      else
        super."${pkg.pname}";
}