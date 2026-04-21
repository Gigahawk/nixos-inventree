{
  stdenv,
  fetchFromGitHub,
  pyprojectHook,
  resolveBuildSystem,
  prev,
}:
stdenv.mkDerivation rec {
  pname = "inventree-digikey-supplier";
  version = "0unstable";
  src = (
    fetchFromGitHub {
      owner = "Gigahawk";
      repo = "inventree-digikey-supplier";
      rev = "bc1f65e";
      hash = "sha256-oHtnAWccHwGinSEc3ff5MK39VSVrdA3eY932/GPn4m4=";
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
