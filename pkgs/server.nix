{writeShellApplication, pythonWithPackages, src}:

writeShellApplication rec {
  name = "inventree-server";
  runtimeInputs = [
    pythonWithPackages
    src
  ];

  text = ''
    INVENTREE_SRC=${src}/src/src/backend
    pushd $INVENTREE_SRC/InvenTree
    gunicorn -c gunicorn.conf.py InvenTree.wsgi "$@"
    popd
  '';
}
