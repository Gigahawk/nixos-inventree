{
  stdenv,
  fetchFromGitHub,
  pyprojectHook,
  resolveBuildSystem,
  prev,
}:
stdenv.mkDerivation rec {
  pname = "inventree-kicad-plugin";
  version = "2.0.4";
  src = (
    fetchFromGitHub {
      owner = "afkiwers";
      repo = "inventree_kicad";
      rev = version;
      hash = "sha256-yCFA9z33CzmAtR7lVMA+FKaIeoQ/+Ha+QH4W5VKtHkQ";
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
