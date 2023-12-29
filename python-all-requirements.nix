ps: with ps;
pkgs.callPackage ./python-requirements.nix { inherit ps; } ++
pkgs.callPackage ./python-database-requirements.nix { inherit ps; }
