{
  stdenv,
  fetchFromGitHub,
  fetchzip,
  writeScript,
  yarn,
  pythonWithPackages,
  lib,
}:
stdenv.mkDerivation rec {
  pname = "inventree-src";
  version = "1.1.7";

  srcs = [
    (fetchFromGitHub {
      name = "inventree-src";
      owner = "inventree";
      repo = "InvenTree";
      rev = version;
      hash = "sha256-FtvL4jDLWUs1mWOf8NsTcSFv17gMDVaJJ77NVGpyEw0=";
    })
    (fetchzip {
      name = "inventree-frontend";
      url = "https://github.com/inventree/InvenTree/releases/download/${version}/frontend-build.zip";
      hash = "sha256-PtVsDaak9bNT2wi/UTi9MGqqQBsv0DGDNH57o+NQAAE=";
      stripRoot = false;
    })
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


    echo "Patching deprecated django calls"
    # Patch is_ajax method as it has been deprecated in django.
    # https://docs.djangoproject.com/en/3.1/releases/3.1/#id2
    find ./src -name \*.py -exec sed -ie 's,.is_ajax(),.headers.get("x-requested-with") == "XMLHttpRequest",g' "{}" \;

    echo "Building static files"
    export INVENTREE_SRC=$(pwd)/src
    export INVENTREE_SITE_URL="http://build.dummy.inventree.com"
    export INVENTREE_STATIC_ROOT=$(pwd)/static
    export INVENTREE_MEDIA_ROOT=$(pwd)/media
    export INVENTREE_BACKUP_DIR=$(pwd)/backup
    export INVENTREE_DB_ENGINE=sqlite3
    export INVENTREE_DB_NAME=$(pwd)/db/db.sqlite3
    pushd $INVENTREE_SRC
    invoke static
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
