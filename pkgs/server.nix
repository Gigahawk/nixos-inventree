{writeShellApplication, inventree}:

writeShellApplication rec {
  name = "inventree-server";
  runtimeInputs = [
    inventree.pythonWithPackages
    inventree.src
  ];

  text = ''
    INVENTREE_SRC=${inventree.src}/src
    pushd $INVENTREE_SRC/InvenTree
    gunicorn -c gunicorn.conf.py InvenTree.wsgi "$@"
    popd
  '';
}
