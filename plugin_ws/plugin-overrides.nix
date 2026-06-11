final: prev: {
  bravado = prev.bravado.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.setuptools
    ];
  });
  bravado-core = prev.bravado-core.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.setuptools
    ];
  });
  digikey-api-v4 = prev.digikey-api-v4.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.uv-build
    ];
  });
}
