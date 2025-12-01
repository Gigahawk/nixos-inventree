{
  writeShellApplication,
  writeScript,
  pythonWithPackages,
  src,
}:

let
  refreshScript = writeScript "refresh_db_config.py" (builtins.readFile ./refresh_db_config.py);
in

writeShellApplication rec {
  name = "inventree-refresh-db-config";
  runtimeInputs = [
    pythonWithPackages
    src
  ];

  text = ''
    INVENTREE_SRC=${src}/src/src/backend
    pushd $INVENTREE_SRC/InvenTree > /dev/null 2>&1
    python ${refreshScript}
    popd > /dev/null 2>&1
  '';
}
