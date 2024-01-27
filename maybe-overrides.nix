# Extend python packages.

self: super: {
  oldBuildPythonPackage = super.buildPythonPackage;
  buildPythonPackage = pkg:
    let
      oldVersion = super."${pkg.pname or " "}".version or "";
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