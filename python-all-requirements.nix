ps: with ps;
pkgs.callPackage ./python-requirements.nix { inherit ps; } ++
pkgs.callPackage ./python-extra-requirements.nix { inherit ps; }
