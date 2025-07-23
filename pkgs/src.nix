{stdenv, fetchFromGitHub, fetchzip, writeScript, yarn, pythonWithPackages, lib}:

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

stdenv.mkDerivation rec {
  pname = "inventree-src";
  version = "0.17.0";

  srcs = [
    (fetchFromGitHub {
      name = "inventree-src";
      owner = "inventree";
      repo = "InvenTree";
      rev = version;
      hash = "sha256-aP620kf0ESOejDHhIhRbczbEf2mUGmq0i/TYy+XwcyY=";
    })
    (fetchzip {
      name = "inventree-frontend";
      url = "https://github.com/inventree/InvenTree/releases/download/${version}/frontend-build.zip";
      hash = "sha256-wW9m0Iu1BPsblXgIuf3PfbT+UYSEWaPY2nQBZj2XMSI=";
      stripRoot=false;
    })
  ];

  patches = [
    ../patches/install-crispy-bootstrap4.patch
    ../patches/configurable-static-i18-root.patch
  ];

  sourceRoot = ".";

  nativeBuildInputs = [
    yarn
    pythonWithPackages
  ];

  buildPhase = ''
    echo "Creating build dirs"
    build=$(pwd)
    mkdir src static media backup db

    echo "Installing backend source files"
    pushd inventree-src
    find . -type f -exec install -Dm 755 "{}" "$build/src/{}" \;
    popd

    echo "Installing frontend source files"
    pushd inventree-frontend
    find . -type f -exec install -Dm 755 "{}" "$build/src/src/backend/InvenTree/web/static/web/{}" \;
    popd


    #cp -r inventree-src/* src/.
    #cp -r inventree-frontend/* src/.

    echo "Patching deprecated django calls"
    # Patch is_ajax method as it has been deprecated in django.
    # https://docs.djangoproject.com/en/3.1/releases/3.1/#id2
    find ./src -name \*.py -exec sed -ie 's,.is_ajax(),.headers.get("x-requested-with") == "XMLHttpRequest",g' "{}" \;

    echo "Building static files"
    export INVENTREE_SRC=$(pwd)/src
    export INVENTREE_STATIC_ROOT=$(pwd)/static
    export INVENTREE_MEDIA_ROOT=$(pwd)/media
    export INVENTREE_BACKUP_DIR=$(pwd)/backup
    export INVENTREE_DB_ENGINE=sqlite3
    export INVENTREE_DB_NAME=$(pwd)/db/db.sqlite3
    pushd $INVENTREE_SRC
    python ${invokeMain} static
    popd

    echo "Disabling fs mutation tasks"
    # Patch out invoke tasks that will attempt to mutate the nix store
    # after we generate the files
    patch -p1 < ${../patches/disable-fs-mutation-tasks.patch}
  '';

  installPhase = ''
    runHook  preInstall

    pushd ./src
    find . -type f -exec install -Dm 755 "{}" "$out/src/{}" \;
    popd

    for d in static media backup db; do
      pushd $d
      find . -type f -exec install -Dm 755 "{}" "$out/$d/{}" \;
      popd
    done

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/Gigahawk/nixos-inventree";
    description = "InvenTree packaged for nixos";
    license = licenses.gpl3;
    platforms = platforms.all;
  };
}
