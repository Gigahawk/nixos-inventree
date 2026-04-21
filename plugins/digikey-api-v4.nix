{
  stdenv,
  fetchFromGitHub,
  pyprojectHook,
  resolveBuildSystem,
  prev,
}:
stdenv.mkDerivation rec {
  pname = "digikey-api-v4";
  version = "0unstable";
  src = (
    fetchFromGitHub {
      owner = "Gigahawk";
      repo = "digikey-api-v4";
      rev = "3c0d5b7";
      hash = "sha256-W+skUxP1Fuv6WQI2XkF7LJvpw4B7nej6T91LQA/6Ux8=";
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
