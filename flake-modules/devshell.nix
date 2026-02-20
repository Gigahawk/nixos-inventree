{ inputs, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      ...
    }:
    {
      devShells = rec {
        uv = pkgs.mkShell {
          packages = [
            pkgs.uv
          ];
          env = {
            # Don't create venv using uv
            UV_NO_SYNC = "1";

            # Force uv to use nixpkgs Python interpreter
            UV_PYTHON = self'.packages.python.interpreter;

            # Prevent uv from downloading managed Python's
            UV_PYTHON_DOWNLOADS = "never";
          };

          shellHook = ''
            # Undo dependency propagation by nixpkgs.
            unset PYTHONPATH

            # Get repository root using git. This is expanded at runtime by the editable `.pth` machinery.
            export REPO_ROOT=$(git rev-parse --show-toplevel)
          '';
        };
        default = uv;
      };
    };

}
