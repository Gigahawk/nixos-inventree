{writeShellApplication, pythonWithPackages, src}:

writeShellApplication rec {
  name = "inventree-cluster";
  runtimeInputs = [
    pythonWithPackages
    src
  ];

  text = ''
    INVENTREE_SRC=${src}/src/src/backend
    pushd $INVENTREE_SRC/InvenTree
    python manage.py qcluster
    popd
  '';
}
