{ hacks, python }:

final: prev: {
  weasyprint = hacks.nixpkgsPrebuilt {
    from = python.pkgs.weasyprint;
  };

  # Seems packages aren't generally available unless they are explicitly
  # specified in an overlay?
  binaryornot = hacks.nixpkgsPrebuilt {
    from = python.pkgs.binaryornot;
  };
  #binaryornot = prev.binaryornot;

  django-allauth = prev.django-allauth.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.setuptools
      prev.wheel
    ];
  });

  django-mailbox = prev.django-mailbox.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.setuptools
      prev.wheel
    ];
  });

  django-xforwardedfor-middleware = prev.django-xforwardedfor-middleware.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.setuptools
      prev.wheel
    ];
  });

  dj-rest-auth = prev.dj-rest-auth.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.setuptools
      prev.wheel
    ];
  });

  odfpy = prev.odfpy.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.setuptools
      prev.wheel
    ];
  });

  sgmllib3k = prev.sgmllib3k.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.setuptools
      prev.wheel
    ];
  });

  coreschema = prev.coreschema.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.setuptools
      prev.wheel
    ];
  });

  invoke = prev.invoke.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.setuptools
      prev.wheel
    ];
  });

  # Plugins
  # TODO: is there a nice way to not have to inherit prev?
  inventree-kicad-plugin = (
    final.callPackage ../plugins/inventree-kicad-plugin.nix { inherit prev; }
  );

}
