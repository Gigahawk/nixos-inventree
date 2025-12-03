# nixos-inventree

A NixOS module to run Inventree as a native service

## Updating

1. Enter the devshell `nix develop .#uv`
2. Update the submodule to point to the latest release
3. Update the srcs targets in `pkgs/src` (use dummy hashes to ensure new downloads happen)
4. Run `update-overrides.sh`
5. Run `nix build .#src` to get expected hashes

## Plugins

For now plugins are hardcoded to be available in the env (see the Plugins section of `pyprojectOverrides` in `flake.nix`).
Figuring out how to make this conveniently configurable from the module is an exercise left to the reader.