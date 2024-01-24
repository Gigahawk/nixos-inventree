{stdenv, fetchFromGitHub, fetchzip, yarn, lib}:

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
  ];

  installPhase = ''
    runHook  preInstall

    pushd inventree-src
    find . -type f -exec install -Dm 755 "{}" "$out/src/{}" \;
    popd

    pushd inventree-frontend
    find . -type f -exec install -Dm 755 "{}" "$out/src/InvenTree/web/static/web/{}" \;
    popd

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/Gigahawk/nixos-inventree";
    description = "InvenTree packaged for nixos";
    license = licenses.gpl3;
    platforms = platforms.all;
  };
}
