{
  writeShellApplication,
  writeScript,
  yarn,
  bash,
  pythonWithPackages,
  src,
}:

writeShellApplication rec {
  name = "inventree-invoke";
  runtimeInputs = [
    yarn
    pythonWithPackages
    src
    bash
  ];

  text = ''
    INVENTREE_SRC=${src}/src
    pushd $INVENTREE_SRC > /dev/null 2>&1
    invoke "$@"
    popd > /dev/null 2>&1
  '';
}
