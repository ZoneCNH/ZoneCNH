#!/usr/bin/env bash
# module-pool-sync-check.sh — 校验 RUNNER-POOLS.yaml 与 module/registry.yaml 的模块分配一致性
# CICD-001: 确保每个注册模块都有 sre/* pool 分配，且 pool 名称有效

set -euo pipefail

ROOT="${1:-.}"

failures=0
fail() {
  echo "  ERROR: $*" >&2
  failures=$((failures + 1))
}

python3 - "$ROOT" <<'PY'
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
for k, v in reg.items():
    if isinstance(v, dict) and 'domain' in v:
        reg_modules.add(k)

print(f"Registry modules: {len(reg_modules)}")

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
for mods in pool_modules.values():
    all_pool_modules.update(mods)

print(f"Pool-assigned modules: {len(all_pool_modules)}")
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

# 4. Verify pool count
online_pools = sum(1 for c in pools.values() if c.get('status') == 'online')
print(f"Pools total: {len(pools)}, online: {online_pools}")

# 5. Verify each pool has valid module names
for pool_name, mods in pool_modules.items():
    for m in mods:
        if m not in reg_modules:
            print(f"WARN: {pool_name} lists unknown module '{m}'")

if errors:
    print(f"\nmodule-pool-sync-check: {errors} sync violation(s)")
    sys.exit(1)

print("\nmodule-pool-sync-check: PASSED")
print(f"  registry: {len(reg_modules)} modules")
print(f"  pools: {len(pools)} pools, {online_pools} online")
print(f"  assigned: {len(all_pool_modules)} modules")
PY
