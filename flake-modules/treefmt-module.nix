{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.dos2unix.enable = true;

        programs.nixfmt.enable = true;

        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;

        programs.ruff.enable = true;

        programs.actionlint.enable = true;
        programs.yamlfmt.enable = true;
      };
    };
}
