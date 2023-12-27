#!/usr/bin/env bash

pip2nix generate -r InvenTree/requirements.txt

# Keep original copy just in case
cp python-packages.nix python-packages.nix.orig

# Remove existing packages from overrides
./clean_generated_nix.py