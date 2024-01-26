# Extend python packages.

self: super: {
  buildPythonPackages = pkg:
    let
      oldVersion = super."${pkg.pname or " "}".version or "";
      newVersion = pkg.version;
      newer =
        oldVersion == "" ||
        builtins.compareVersions newVerison oldVersion > 0;
    in
      if newer then
        __trace "${pkg.pname}: ${newVersion} > ${oldVersion}"
        super.buildPythonPackages pkg
      else
        __trace "${pkg.pname}: ${newVersion} <= ${oldVersion}"
        super."${pkg.pname}";
}