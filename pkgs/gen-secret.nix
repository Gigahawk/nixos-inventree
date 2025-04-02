{writeShellApplication, writeScript, pythonWithPackages, src}:

let
  genScript = writeScript "gen_secret_key.py" ''
    import sys
    sys.path.insert(0 , '.')
    from InvenTree.config import get_secret_key
    get_secret_key()
  '';
in

writeShellApplication rec {
  name = "inventree-gen-secret";
  runtimeInputs = [
    pythonWithPackages
    src
  ];

  text = ''
    INVENTREE_SRC=${src}/src/src/backend
    INVENTREE_CONFIG_FILE="$(pwd)/config.yaml"
    export INVENTREE_CONFIG_FILE
    INVENTREE_SECRET_KEY_FILE="$(pwd)/secret_key.txt"
    export INVENTREE_SECRET_KEY_FILE
    unset INVENTREE_SECRET_KEY

    pushd $INVENTREE_SRC/InvenTree > /dev/null 2>&1
    echo "Removing any existing secret $INVENTREE_SECRET_KEY_FILE"
    rm -rf "$INVENTREE_SECRET_KEY_FILE"
    python ${genScript}
    echo "Removing temp config file $INVENTREE_CONFIG_FILE"
    rm "$INVENTREE_CONFIG_FILE"
    # TODO: is this something we actually want to do?
    echo "Secret key written to $INVENTREE_SECRET_KEY_FILE"
    cat "$INVENTREE_SECRET_KEY_FILE"
    echo
    popd > /dev/null 2>&1
  '';
}
