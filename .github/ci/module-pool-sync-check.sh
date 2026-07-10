#!/usr/bin/env bash
# module-pool-sync-check.sh — 校验 RUNNER-POOLS.yaml 与 module/registry.yaml 的分配一致性
# CICD-001: 确保每个注册模块/历史归档记录都有 sre/* pool 记录，且不重复分配

set -euo pipefail

ROOT="${1:-.}"
CHECK_TIMEOUT_SECONDS="${MODULE_POOL_SYNC_TIMEOUT_SECONDS:-30}"

if [[ ! "$CHECK_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: MODULE_POOL_SYNC_TIMEOUT_SECONDS must be a positive integer" >&2
  exit 2
fi

failures=0
fail() {
  echo "  ERROR: $*" >&2
  failures=$((failures + 1))
}

timeout "$CHECK_TIMEOUT_SECONDS" python3 - "$ROOT" <<'PY'
import sys
import yaml
from pathlib import Path

root = Path(sys.argv[1])
registry_path = root / "module" / "registry.yaml"
pools_path = root / "docs" / "sre" / "RUNNER-POOLS.yaml"

# 1. Load registry modules
with open(registry_path) as f:
    reg = yaml.safe_load(f)

reg_modules = set()
reg_lifecycle = {}
for k, v in reg.items():
    if isinstance(v, dict) and 'domain' in v:
        reg_modules.add(k)
        reg_lifecycle[k] = v.get('lifecycle', 'unknown')

active_modules = {m for m in reg_modules if reg_lifecycle[m] != 'archived'}
archived_modules = {m for m in reg_modules if reg_lifecycle[m] == 'archived'}
print(
    f"Registry records: {len(reg_modules)} "
    f"({len(active_modules)} active, {len(archived_modules)} archived)"
)

# 2. Load RUNNER-POOLS.yaml pool modules
with open(pools_path) as f:
    pools_data = yaml.safe_load(f)

pools = pools_data.get('pools', {})
pool_modules = {}
for pool_name, conf in pools.items():
    mods = conf.get('modules', [])
    module_list = []
    for m in mods:
        if isinstance(m, str):
            m_name = m.split('#')[0].strip()
            module_list.append(m_name)
    pool_modules[pool_name] = module_list

all_pool_modules = set()
pool_record_locations = {}
for pool_name, mods in pool_modules.items():
    for module in mods:
        all_pool_modules.add(module)
        pool_record_locations.setdefault(module, []).append(pool_name)

print(f"Pool-assigned records: {len(all_pool_modules)}")
print()

# 3. Cross-check
missing_in_pools = reg_modules - all_pool_modules
extra_in_pools = all_pool_modules - reg_modules

errors = 0

if missing_in_pools:
    print(f"ERROR: {len(missing_in_pools)} modules in registry have no pool assignment:")
    for m in sorted(missing_in_pools):
        print(f"  - {m}")
        errors += 1

if extra_in_pools:
    print(f"ERROR: {len(extra_in_pools)} modules in RUNNER-POOLS.yaml not in registry:")
    for m in sorted(extra_in_pools):
        print(f"  - {m}")
        errors += 1

duplicate_assignments = {
    m: locations for m, locations in pool_record_locations.items() if len(locations) > 1
}
if duplicate_assignments:
    print("ERROR: duplicate pool assignments:")
    for m in sorted(duplicate_assignments):
        pools_for_module = ", ".join(duplicate_assignments[m])
        print(f"  - {m}: {pools_for_module}")
        errors += 1

# 4. Verify pool count
online_pools = sum(1 for c in pools.values() if c.get('status') == 'online')
print(f"Pools total: {len(pools)}, online: {online_pools}")

# 5. Verify each pool has valid module names
for pool_name, mods in pool_modules.items():
    if not pool_name.startswith('sre/'):
        print(f"ERROR: invalid pool name '{pool_name}' (must start with sre/)")
        errors += 1
    for m in mods:
        if m not in reg_modules:
            print(f"WARN: {pool_name} lists unknown module '{m}'")

if errors:
    print(f"\nmodule-pool-sync-check: {errors} sync violation(s)")
    sys.exit(1)

print("\nmodule-pool-sync-check: PASSED")
print(f"  registry: {len(reg_modules)} records ({len(active_modules)} active, {len(archived_modules)} archived)")
print(f"  pools: {len(pools)} pools, {online_pools} online")
print(f"  assigned: {len(all_pool_modules)} records")
PY
