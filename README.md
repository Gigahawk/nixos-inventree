# nixos-inventree

A NixOS module to run Inventree as a native service

> [!IMPORTANT]
> If you are updating your instance from a version prior to 1.2.x you MUST FIRST:
> 1. (optional) Update to 1.1.12 and ensure all migrations run correctly (lock your flake input to https://github.com/Gigahawk/nixos-inventree/commit/cf3d49c3505df8537e7f0ecba3ad23df48d4afd1)
> 2. Update ONLY Inventree to 1.2.0 and ensure all migrations run correctly (lock your flake input to https://github.com/Gigahawk/nixos-inventree/commit/b74464f366c1d8f7d3c2b8f0fb04840eb8d9e27f)
>    
> Only then is it safe to update to the latest commit.
> Due to https://github.com/afkiwers/inventree_kicad/issues/159 it is not currently possible to simultaneously update both the Inventree and inventree-kicad-plugin versions without running into issues during migration
>
> EDIT 2026-02-20: As of https://github.com/Gigahawk/nixos-inventree/commit/8c9ab6ddfc5fb2486543127522fa4a1583edb8a2 it is now possible to define installed plugins from the NixOS module.
> If you update to at least this commit even from 1.1.x the server will boot with no plugins by default, which should allow it to start up and run migrations before you re-enable the plugin.

## Updating this Repo

1. Enter the devshell `nix develop .#uv`
2. Update the submodule to point to the latest release
3. Update the srcs targets in `pkgs/src` (use dummy hashes to ensure new downloads happen)
4. Run `update-overrides.sh`
5. Run `nix build .#src` to get expected hashes

## Plugins

For now plugins are hardcoded to be available in the env (see the Plugins section of `pyprojectOverrides` in `flake.nix`).
Figuring out how to make this conveniently configurable from the module is an exercise left to the reader.