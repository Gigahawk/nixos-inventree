#!/usr/bin/env python

from pprint import pprint
from pathlib import Path
import re
import subprocess
from multiprocessing.pool import ThreadPool

from generate_package_list import get_requirements_list, BASE_REQUIREMENTS

PYTHON_PACKAGES = "python311Packages"
CLEANED_REQUIREMENTS = Path(".clean-requirements.txt")

ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
base_list = get_requirements_list()
#base_list = [ "pillow" ]

def only_existing_pkgs(package):
    search_str = f"{PYTHON_PACKAGES}.{package}"
    proc = subprocess.run(
        f'nix search nixpkgs "{search_str}"',
        shell=True,
        capture_output=True,
        text=True,
        )
    stdout = ansi_escape.sub('', proc.stdout)
    out_lines = stdout.splitlines()
    for line in out_lines:
        if f"{search_str} (" in line:
            print(f"Package '{package}' is already on nixpkgs:\n{line.strip()}")
            return package
    return ""


def get_existing_requirements():
    print("Searching for overrides already present on nixpkgs")
    pool = ThreadPool(len(base_list))
    existing_packages = sorted(
        [p for p in pool.map(only_existing_pkgs, base_list) if p])
    return existing_packages

def get_cleaned_requirements():
    existing_requirements = get_existing_requirements()
    cleaned_requirements = [
        pkg for pkg in base_list if pkg not in existing_requirements
    ]
    return cleaned_requirements

def write_cleaned_requirements_file():
    #cleaned_requirements = get_cleaned_requirements()
    existing_requirements = get_existing_requirements()
    with open(BASE_REQUIREMENTS, "r") as f:
        base_lines = f.readlines()
    cleaned_lines = []
    for line in base_lines:
        if any([line.startswith(pkg + "=") or line.startswith(pkg + "[") for pkg in existing_requirements]):
            continue
        cleaned_lines.append(line)

    with open(CLEANED_REQUIREMENTS, "w") as f:
        f.writelines(cleaned_lines)


if __name__ == "__main__":
    write_cleaned_requirements_file()
