{mkShell, pythonWithPackages, server, cluster, gen-secret, python, invoke, refresh-users, yarn, yarn2nix, pip2nix}:

mkShell {
  inputsFrom = [
    server
  ];
  nativeBuildInputs = [
    # pip2nix.packages.${system}.
    pip2nix
    pythonWithPackages
    yarn
    yarn2nix
    server
    cluster
    gen-secret
    python
    invoke
    refresh-users
  ];
}
