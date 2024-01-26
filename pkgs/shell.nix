{mkShell, inventree, yarn, yarn2nix, pip2nix}:

mkShell {
  inputsFrom = [
    inventree.server
  ];
  nativeBuildInputs = [
    # pip2nix.packages.${system}.
    pip2nix
    inventree.pythonWithPackages
    yarn
    yarn2nix
    inventree.server
    inventree.cluster
    inventree.gen-secret
    inventree.python
    inventree.invoke
    inventree.refresh-users
  ];
}