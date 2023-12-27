#!/usr/bin/env python
from pathlib import Path

BASE_REQUIREMENTS = Path("InvenTree/requirements.txt")

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

if __name__ == "__main__":
    for l in get_requirements_list():
        print(l)
