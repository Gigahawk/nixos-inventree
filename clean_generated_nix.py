#!/usr/bin/env python

import os
from pathlib import Path

from generate_missing_requirements import get_existing_requirements

GENERATED = Path(os.environ.get("OVERRIDES", "python-overrides.nix"))

existing_requirements = get_existing_requirements()

print(f"Opening overrides file {GENERATED}")
with open(GENERATED, "r") as f:
    lines = f.readlines()

for idx, line in enumerate(lines):
    if "self: super: {" in line:
        break
idx += 1

header = lines[:idx]
lines = lines[idx:]

package_lines = []
curr_pkg = []
for line in lines:
    if line.startswith("}"):
        last_line = line
        break
    if line.strip().startswith('"'):
        package_lines.append(curr_pkg)
        curr_pkg = []
    curr_pkg.append(line)
package_lines.pop(0)

needed_package_lines = []

for pkg in package_lines:
    pkg_name = pkg[0].strip()[1:]
    pkg_name = pkg_name[:pkg_name.index('"')]
    if pkg_name in existing_requirements:
        print(f"Removing {pkg_name} from overrides")
        continue
    needed_package_lines.append(pkg)

output_lines = header

for p in needed_package_lines:
    for l in p:
        output_lines.append(l)
output_lines.append(last_line)

print(f"Saving stripped overrides to {GENERATED}")
with open(GENERATED, "w") as f:
    f.write("".join(output_lines))







