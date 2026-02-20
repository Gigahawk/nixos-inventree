{
  writeShellApplication,
  venv,
  src,
  ...
}:

writeShellApplication rec {
  name = "inventree-python";
  runtimeInputs = [
    venv
    src
  ];

  text = ''
    INVENTREE_SRC=${src}/src/src/backend
    pushd "$INVENTREE_SRC/''${INVENTREE_PYTHON_CWD:-}"
    python "$@"
    popd
  '';
}
