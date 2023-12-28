#!/usr/bin/env python
from pathlib import Path

BASE_REQUIREMENTS = Path("InvenTree/requirements.txt")
OUTPUT = Path("python-requirements.nix")

def get_requirements_list():
    with open(BASE_REQUIREMENTS, "r") as f:
        lines = f.readlines()
    cleaned_lines = []
    for line in lines:
        if not line.strip() or line.strip().startswith("#"):
            continue
        idx = line.index("=")
        try:
            idx = line.index("[")
        except ValueError:
            pass
        cleaned_lines.append(line[:idx])
    return cleaned_lines

def main():
    print("Generating environment requirements list")
    requirements = get_requirements_list()
    lines = [
        "ps: with ps; ["
    ]
    for r in requirements:
        print(r)
        lines.append(f"  {r}")
    lines.append("]")
    with open(OUTPUT, "w") as f:
        f.write("\n".join(lines))

if __name__ == "__main__":
    main()
