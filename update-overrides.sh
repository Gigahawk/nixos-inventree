#!/usr/bin/env bash

set -Eeuo pipefail

#OVERRIDES=python-overrides.nix

#./generate_package_list.py
clean_misc() {
    echo "Cleaning generated uv files"
    rm -f main.py
    rm -f .python-version

}
clean_all() {
    echo "Cleaning old uv files"
    clean_misc
    rm -f pyproject.toml
    rm -f uv.lock
}

clean_all

echo "Generating new uv files"
uv init
uv add -r InvenTree/src/backend/requirements.txt

echo "Adding custom dependencies"
# Waiting for 2.3.0 to fix https://github.com/pyinvoke/invoke/issues/1011
uv add "invoke @ git+https://github.com/pyinvoke/invoke"

uv add crispy-bootstrap4

# Related to plugins
uv add pip

## Weasyprint deps?
#uv add tinyhtml5
#uv add "tinycss2 >= 1.4.0"

# https://stackoverflow.com/a/72547402
echo "Adding setuptools workaround to pyproject"
echo -e "[tool.setuptools]\npy-modules = []" >> pyproject.toml

clean_misc

#echo "Initial generation complete, saving copy as ${OVERRIDES}.orig"
#cp "$OVERRIDES" "${OVERRIDES}.orig"
#
#echo "Removing overrides with matching names on nixpkgs"
#./clean_generated_nix.py
