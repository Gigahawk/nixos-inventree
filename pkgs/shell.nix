{mkShell, pythonWithPackages, server, cluster, gen-secret, python, invoke, refresh-users, yarn, yarn2nix}:

mkShell {
  inputsFrom = [
    server
  ];
  nativeBuildInputs = [
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
