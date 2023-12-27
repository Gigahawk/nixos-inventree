{
  description = "Devshell and package definition";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    pip2nix = {
      url = "github:nix-community/pip2nix";
    };
  };

  outputs = { self, nixpkgs, flake-utils, pip2nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      version = "0.13.0";
    in {
      packages = {
        inventree-src = with import nixpkgs { inherit system; };
        stdenv.mkDerivation rec {
          pname = "inventree-src";
          inherit version;

          src = pkgs.fetchFromGitHub {
            owner = "inventree";
            repo = "InvenTree";
            rev = version;
            hash = "sha256-PW/aX8h3W2xcFZ1zfYE9+Uy6bkNrPeoDc48CA70cOhA=";
          };

          installPhase = ''
            runHook  preInstall

            find . -type f -exec install -Dm 755 "{}" "$out/src/{}" \;

            runHook postInstall
          '';

          meta = with lib; {
            homepage = "https://github.com/Gigahawk/nixos-inventree";
            description = "InvenTree packaged for nixos";
            license = licenses.gpl3;
            platforms = platforms.all;
          };
        };
        inventree = with import nixpkgs { inherit system; };
        let
          #generatedOverrides = pkgs.callPackage ./python-packages.nix { };
          #manualOverrides = self: super: {
          #  pillow = pythonPackages.pillow.overrideDerivation(old:
          #    with super.pillow; { inherit name src; }
          #);};
          #packageOverrides = lib.mkMerge [ generatedOverrides manualOverrides ];
          packageOverrides = pkgs.callPackage ./python-packages.nix { };
          python = pkgs.python3.override { inherit packageOverrides; };

          pythonPackages = ps: with ps; [
            asgiref
            async-timeout
            attrs
            babel
            bleach
            brotli
            certifi
            cffi
            charset-normalizer
            coreapi
            coreschema
            cryptography
            cssselect2
            defusedxml
            diff-match-patch
            dj-rest-auth
            django
            django-allauth
            django-allauth-2fa
            django-cleanup
            django-cors-headers
            django-crispy-forms
            django-dbbackup
            django-error-report-2
            django-filter
            django-flags
            django-formtools
            django-ical
            django-import-export
            django-js-asset
            django-maintenance-mode
            django-markdownify
            django-money
            django-mptt
            django-otp
            django-picklefield
            django-q-sentry
            django-q2
            django-recurrence
            django-redis
            django-sesame
            django-sql-utils
            django-sslserver
            django-stdimage
            django-taggit
            django-user-sessions
            django-weasyprint
            django-xforwardedfor-middleware
            djangorestframework
            djangorestframework-simplejwt
            drf-spectacular
            dulwich
            et-xmlfile
            feedparser
            fonttools
            gunicorn
            html5lib
            icalendar
            idna
            importlib-metadata
            inflection
            itypes
            jinja2
            jsonschema
            jsonschema-specifications
            markdown
            markuppy
            markupsafe
            oauthlib
            odfpy
            openpyxl
            packaging
            pdf2image
            pillow
            pint
            py-moneyed
            pycparser
            pydyf
            pyjwt
            pyphen
            pypng
            python-barcode
            python-dateutil
            python-dotenv
            python-fsutil
            python3-openid
            pytz
            pyyaml
            qrcode
            rapidfuzz
            redis
            referencing
            regex
            requests
            requests-oauthlib
            rpds-py
            sentry-sdk
            sgmllib3k
            six
            sqlparse
            tablib
            tinycss2
            typing-extensions
            uritemplate
            urllib3
            weasyprint
            webencodings
            xlrd
            xlwt
            zipp
            zopfli
          ];
          pythonWithPackages = python.withPackages pythonPackages;
        in
        pkgs.writeShellApplication rec {
          name = "inventree";
          runtimeInputs = [
            #python311Packages.gunicorn
            pythonWithPackages
            self.packages.${system}.inventree-src
          ];

          text = ''
            INVENTREE_SRC=${self.packages.${system}.inventree-src}/src
            pushd $INVENTREE_SRC/InvenTree
            ls
            type gunicorn
            gunicorn -c gunicorn.conf.py InvenTree.wsgi -b 127.0.0.1:8000
            popd
          '';
        };
        default = self.packages.${system}.inventree;
      };
      devShell = pkgs.mkShell {
        inputsFrom = [ self.packages.${system}.inventree ];
        nativeBuildInputs = [
          pip2nix.packages.${system}.pip2nix.python39
        ];
      };
    });
}
