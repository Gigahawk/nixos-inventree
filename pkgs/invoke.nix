{writeShellApplication, writeScript, yarn, pythonWithPackages, src}:

let
  # invoke command from nixpkgs is a prebuilt binary that appears to
  # ignore the environment, create our own script to run invoke with
  # our environment
  invokeMain = writeScript "invokeMain" ''
    from invoke import Program, __version__

    program = Program(
        name="Invoke",
        binary="inv[oke]",
        binary_names=["invoke", "inv"],
        version=__version__,
    )
    program.run()
  '';
in

writeShellApplication rec {
  name = "inventree-invoke";
  runtimeInputs = [
    yarn
    pythonWithPackages
    src
  ];

  text = ''
    INVENTREE_SRC=${src}/src
    pushd $INVENTREE_SRC > /dev/null 2>&1
    python ${invokeMain} "$@"
    popd > /dev/null 2>&1
  '';
}
