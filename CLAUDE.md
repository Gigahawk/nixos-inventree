# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides a NixOS module for running [InvenTree](https://inventree.org/) (an open-source inventory management system) as a native NixOS service. The module packages InvenTree's Python backend and frontend, creates systemd services, and provides a declarative NixOS configuration interface.

## Architecture

### Package Structure

The flake exposes several packages under `pkgs.inventree.*`:

- **src** (`pkgs/src.nix`): Fetches InvenTree source from GitHub, pre-built frontend from releases, patches deprecated Django calls, and builds static files. Includes a patch to disable filesystem mutation tasks.
- **server** (`pkgs/server.nix`): Wrapper script that runs gunicorn WSGI server
- **cluster** (`pkgs/cluster.nix`): Wrapper script that runs Django Q2 background worker (`manage.py qcluster`)
- **invoke** (`pkgs/invoke.nix`): Wrapper for InvenTree's invoke tasks (used for migrations, etc.)
- **python** (`pkgs/python.nix`): Python interpreter with all InvenTree dependencies
- **refresh-users** (`pkgs/refresh-users.nix`): Script to declaratively manage InvenTree users from NixOS config
- **gen-secret** (`pkgs/gen-secret.nix`): Utility to generate Django secret keys
- **shell** (`pkgs/shell.nix`): Development shell
- **venv**: Virtual environment with all dependencies (for development)

### Python Dependency Management

Uses `uv2nix` and `pyproject-nix` to convert `uv.lock` into Nix packages. Python dependencies are defined in `pyproject.toml`, which tracks InvenTree's requirements. Several packages require build system overrides in `flake.nix` (django-allauth, django-mailbox, etc.) to add setuptools/wheel.

The `weasyprint` package uses a special hack to use the pre-built nixpkgs version instead of building from source.

### NixOS Module

The module (defined at bottom of `flake.nix`) provides `services.inventree` options:

- Creates systemd services: `inventree-server` (gunicorn) and `inventree-cluster` (background worker)
- Manages directories via systemd's RuntimeDirectory/StateDirectory/etc
- Handles config file generation, database migrations, static file deployment, and user provisioning in `ExecStartPre`
- Provides `inventree-invoke` command-line tool (wrapped with INVENTREE_CONFIG_FILE)

### Two-Service Architecture

InvenTree requires two services running simultaneously:
1. **inventree-server**: HTTP server (gunicorn/WSGI) for web UI and API
2. **inventree-cluster**: Background worker (Django Q2) for async tasks

Both services share the same configuration file and database.

## Development Commands

### Building and Testing

```bash
# Build the source package (includes frontend and static files)
nix build .#src

# Build server wrapper
nix build .#server

# Build cluster worker wrapper
nix build .#cluster

# Format Nix files
nix fmt
```

### Development Shells

```bash
# Enter default development shell (includes all InvenTree tools)
nix develop

# Enter uv development shell (for updating dependencies)
nix develop .#uv
```

### Updating InvenTree Version

Follow the process in README.md:

1. Enter uv devshell: `nix develop .#uv`
2. Update InvenTree submodule to latest release
3. Update version and hashes in `pkgs/src.nix` (use dummy hashes initially)
4. Run `./update-overrides.sh` to regenerate `pyproject.toml` and `uv.lock`
5. Run `nix build .#src` to verify builds and get correct hashes

The `update-overrides.sh` script:
- Cleans existing uv files
- Runs `uv init` and `uv add` with InvenTree's requirements
- Adds custom dependencies (invoke from git, pip for plugins)
- Adds setuptools workaround to pyproject.toml

### Using MCP NixOS Tools

When working with this repository, use the MCP NixOS tools for:
- Searching NixOS packages: `mcp__nixos__nixos_search`
- Looking up package info: `mcp__nixos__nixos_info`
- Finding package versions: `mcp__nixos__nixhub_package_versions`
- Checking Home Manager options: `mcp__nixos__home_manager_search`

## Key Technical Details

### Path Structure in Packages

The source package has a nested structure: `${src}/src/src/backend/InvenTree` is the actual Django project root. This is because:
- The build process creates a `src/` directory
- InvenTree's source has backend code in `src/backend/`
- The Django project itself is in `InvenTree/`

### Configuration Management

Environment variables control InvenTree behavior:
- `INVENTREE_CONFIG_FILE`: Path to config.yaml
- `INVENTREE_SITE_URL`: Base URL for the server
- `INVENTREE_ALLOWED_HOSTS`: Comma-separated list of allowed hostnames
- `INVENTREE_SRC`: Path to source code (set by wrapper scripts)
- Various database and storage paths

The module generates `config.yaml` from NixOS options and copies it to the dataDir at service startup.

### User Management

The `refresh-users` package reads a JSON file (generated from NixOS config) and creates/updates users in the InvenTree database. Users are defined declaratively in `services.inventree.users` with password files.

### Static Files

Static files are pre-built during the `src` package build phase and then copied to `static_root` by the systemd service. The Django collectstatic process runs during build, not at runtime.

### Patches Applied

`patches/disable-fs-mutation-tasks.patch`: Disables invoke tasks that would attempt to modify the Nix store after static files are generated.

## Flake Inputs

- **nixpkgs**: NixOS package repository (follows unstable channel)
- **pyproject-nix**: Library for building Python projects with Nix
- **uv2nix**: Converts uv.lock files to Nix expressions
- **pyproject-build-systems**: Provides Python build system packages
- **flake-utils**: Utilities for multi-system flakes

## Testing the Module

To test the NixOS module in a VM or system:

```nix
{
  imports = [ nixos-inventree.nixosModules.default ];

  services.inventree = {
    enable = true;
    siteUrl = "http://localhost:8000";
    config = {
      # Database, media paths, etc.
    };
    users.admin = {
      email = "admin@example.com";
      is_superuser = true;
      password_file = /path/to/password;
    };
  };
}
```
