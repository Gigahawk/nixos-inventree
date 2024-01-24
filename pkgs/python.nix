{writeShellApplication, inventree }:

writeShellApplication rec {
  name = "inventree-python";
  runtimeInputs = [
    inventree.pythonWithPackages
    inventree.src
  ];

  text = ''
    INVENTREE_SRC=${inventree.src}/src
    pushd "$INVENTREE_SRC/''${INVENTREE_PYTHON_CWD:-}"
    python "$@"
    popd
  '';
}