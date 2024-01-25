#!/usr/bin/env bash

set -Eeuo pipefail

OVERRIDES=python-overrides.nix

./generate_package_list.py

echo "Generating initial override list as $OVERRIDES"
pip2nix generate -r InvenTree/requirements.txt --output "$OVERRIDES"

echo "Initial generation complete, saving copy as ${OVERRIDES}.orig"
cp "$OVERRIDES" "${OVERRIDES}.orig"

echo "Removing overrides with matching names on nixpkgs"
./clean_generated_nix.py
