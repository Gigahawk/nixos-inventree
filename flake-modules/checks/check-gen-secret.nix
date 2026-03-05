{ inputs, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      ...
    }:
    {
      checks = {
        gen-secret = pkgs.runCommand "gen-secret-test" { } ''
          ${self'.packages.gen-secret}/bin/inventree-gen-secret > $out
        '';
      };
    };
}
