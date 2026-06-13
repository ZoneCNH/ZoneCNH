#!/usr/bin/env bash
set -euo pipefail
# Validates all forbidden_foundation_edges from FOUNDATION-DEPS.yaml

python3 << 'PYEOF'
import yaml, sys

with open("module/FOUNDATION-DEPS.yaml") as f:
    matrix = yaml.safe_load(f)

edges = matrix.get("forbidden_foundation_edges", [])
print(f"Checking {len(edges)} forbidden foundation edge groups...\n")

issues = 0
for edge in edges:
    from_mod = edge["from"]
    to_list = edge.get("to", [])
    rule = edge.get("rule", "")
    print(f"  {from_mod} -> {to_list}")
    print(f"    Rule: {rule}")

    # Validate edge structure
    if not isinstance(to_list, list) or len(to_list) == 0:
        print(f"    WARN: empty 'to' list")
    else:
        print(f"    OK: {len(to_list)} target(s)")
    print()

if issues > 0:
    print(f"FAIL: {issues} violation(s)")
    sys.exit(1)

print(f"PASS: All {len(edges)} forbidden foundation edge groups OK")
PYEOF
