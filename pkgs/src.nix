{stdenv, fetchFromGitHub, fetchzip, writeScript, yarn, inventree, lib}:

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
  version = "0.13.0";

  srcs = [
    (fetchFromGitHub {
      name = "inventree-src";
      #owner = "inventree";
      owner = "Gigahawk";
      repo = "InvenTree";
      #rev = version;
      rev = "eb5b161617fc5ff36e91ab007008736b1d37a0d7";
      hash = "sha256-oTkL7Lu+llj1O23Ql1EQKt24UmTLxJNYT5cJhcEReWQ=";
    })
    (fetchzip {
      name = "inventree-frontend";
      url = "https://github.com/inventree/InvenTree/releases/download/${version}/frontend-build.zip";
      hash = "sha256-w4QJ03Bgy9hikrSIaJzqeEwlR+hHkBZ0bljXp+JW56o=";
      stripRoot=false;
    })
  ];

  sourceRoot = ".";

  nativeBuildInputs = [
    yarn
    inventree.pythonWithPackages
  ];

  buildPhase = ''
    build=$(pwd)
    mkdir src static media backup db

    pushd inventree-src
    find . -type f -exec install -Dm 755 "{}" "$build/src/{}" \;
    popd

    pushd inventree-frontend
    find . -type f -exec install -Dm 755 "{}" "$build/src/InvenTree/web/static/web/{}" \;
    popd

    #cp -r inventree-src/* src/.
    #cp -r inventree-frontend/* src/.

    # Patch is_ajax method as it has been deprecated in django.
    # https://docs.djangoproject.com/en/3.1/releases/3.1/#id2
    find ./src -name \*.py -exec sed -ie 's,.is_ajax(),.headers.get("x-requested-with") == "XMLHttpRequest",g' "{}" \;

    export INVENTREE_SRC=$(pwd)/src
    export INVENTREE_STATIC_ROOT=$(pwd)/static
    export INVENTREE_MEDIA_ROOT=$(pwd)/media
    export INVENTREE_BACKUP_DIR=$(pwd)/backup
    export INVENTREE_DB_ENGINE=sqlite3
    export INVENTREE_DB_NAME=$(pwd)/db/db.sqlite3
    pushd $INVENTREE_SRC
    python ${invokeMain} static
    popd
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
