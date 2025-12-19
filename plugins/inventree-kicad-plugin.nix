{
  stdenv,
  fetchurl,
  pyprojectHook,
  resolveBuildSystem,
  prev,
}:
stdenv.mkDerivation {
  pname = "inventree-kicad-plugin";
  version = "1.5.1";
  src = (
    fetchurl {
      url = "https://files.pythonhosted.org/packages/be/46/f12460bcd77e477b814909201f7fed90856516f37917fb48b50c518013eb/inventree_kicad_plugin-1.5.1.tar.gz";
      hash = "sha256-BhoaGfg9jdx2ym8Vxg5jqR7rDmLPh2ek0uMX/CPyPc0=";
    }
  );
  nativeBuildInputs = [
    # Add hook responsible for configuring, building & installing.
    pyprojectHook
  ]
  # Build systems needs to be resolved since we don't propagate dependencies.
  # Otherwise dependencies of our build-system will be missing.
  ++ resolveBuildSystem { flit-core = [ ]; };

  buildInputs = [
    prev.setuptools
  ];

  # Dependencies go in passthru to avoid polluting runtime package.
  passthru = {
    #inherit (lockpkg) dependencies optional-dependencies;
  };
}
