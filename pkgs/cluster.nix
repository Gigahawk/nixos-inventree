{writeShellApplication, inventree}:

writeShellApplication rec {
  name = "inventree-cluster";
  runtimeInputs = [
    inventree.pythonWithPackages
    inventree.src
  ];

  text = ''
    INVENTREE_SRC=${inventree.src}/src
    pushd $INVENTREE_SRC/InvenTree
    python manage.py qcluster
    popd
  '';
}