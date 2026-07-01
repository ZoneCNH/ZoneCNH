#!/usr/bin/env bash
# registry-lint.sh — 校验 module/registry.yaml 统一模块注册表的完整性
#
# 校验规则（见 docs/governance/module-governance/01-module-registry.md）：
#   1. 元字段：schema_version == module-registry/v1；updated 合法日期
#   2. 必填字段存在性：repo/local_path/domain/layer/arch_type/lifecycle/owner/registered/spec_ref
#   3. 枚举合法性：domain ∈ 8 值；layer ∈ 10 值；arch_type ∈ 5 值；lifecycle ∈ 5 值
#   4. 格式校验：repo/local_path/registered/spec_version 格式合规
#   5. spec_ref 路径存在性：非 archived 且非 ~ 时路径须存在；非 archived 且 ~ → WARN
#   6. 计数口径守卫：domain=foundation 须 == 20；domain=l2_5 须 == 5
#
# 退出码：0 = 通过（可有 WARN）；1 = 失败；2 = 工具错误（YAML 解析失败等）

set -euo pipefail

FAIL=0
WARN=0
REGISTRY_PATH="${REGISTRY_PATH:-module/registry.yaml}"
REPO_ROOT="$(git rev-parse --show-toplevel)"

echo "=== Registry Lint ==="
echo ""

# YAML 解析与全部校验在 Python 内完成（pyyaml safe_load）
python3 - "$REPO_ROOT/$REGISTRY_PATH" "$REPO_ROOT" <<'PYEOF'
import os
import re
import sys
from datetime import date

import yaml
registry_path = sys.argv[1]
repo_root = sys.argv[2]

failures = 0
warnings = 0

def err(msg):
    global failures
    failures += 1
    print(f"  ❌ {msg}")

def warn(msg):
    global warnings
    warnings += 1
    print(f"  ⚠️  {msg}")

def ok(msg):
    print(f"  ✅ {msg}")

# --- 规则 1：YAML 可解析 + 元字段 ---
try:
    with open(registry_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
except FileNotFoundError:
    print(f"  ❌ registry 文件不存在: {registry_path}")
    sys.exit(2)
except yaml.YAMLError as e:
    print(f"  ❌ YAML 解析失败: {e}")
    sys.exit(2)

if not isinstance(data, dict):
    print("  ❌ registry 顶层不是 mapping")
    sys.exit(2)

print("--- 规则 1: 元字段 ---")
schema_version = data.get("schema_version")
if schema_version == "module-registry/v1":
    ok(f"schema_version = {schema_version}")
else:
    err(f"schema_version 应为 module-registry/v1，实际 = {schema_version!r}")

updated = data.get("updated")
# YAML 可能将 YYYY-MM-DD 解析为 datetime.date 对象
if isinstance(updated, date):
    updated_str = updated.isoformat()
    ok(f"updated = {updated_str}")
elif isinstance(updated, str) and re.match(r"^\d{4}-\d{2}-\d{2}$", updated):
    try:
        date.fromisoformat(updated)
        ok(f"updated = {updated}")
    except ValueError:
        err(f"updated 不是合法日期: {updated!r}")
else:
    err(f"updated 应为 YYYY-MM-DD，实际类型={type(updated).__name__} 值={updated!r}")

# --- 收集模块块（排除元字段 key） ---
META_KEYS = {"schema_version", "updated"}
modules = {k: v for k, v in data.items() if k not in META_KEYS}
print(f"  ℹ️  发现 {len(modules)} 个模块条目")
print("")

# --- 规则 2：必填字段存在性 ---
# spec_ref 是引用字段，允许 ~（None）；其存在性由规则 5 单独检查
# local_path 对 archived 模块允许 ~（代码仓已删除）
REQUIRED_FIELDS = ["repo", "domain", "layer", "arch_type",
                   "lifecycle", "owner", "registered"]
print("--- 规则 2: 必填字段存在性 ---")
for name, mod in modules.items():
    if not isinstance(mod, dict):
        err(f"{name}: 条目不是 mapping")
        continue
    is_archived = mod.get("lifecycle") == "archived"
    missing = [f for f in REQUIRED_FIELDS if f not in mod or mod[f] is None]
    # local_path：非 archived 必填，archived 允许 ~
    if not is_archived and (mod.get("local_path") is None):
        missing.append("local_path")
    if missing:
        err(f"{name}: 缺少必填字段 {missing}")
print("")

# --- 规则 3：枚举合法性 ---
VALID_DOMAINS = {"foundation", "l2_5", "data", "analytics", "decision",
                 "execution", "entry", "crosscut"}
VALID_LAYERS = {"L0", "L1", "storage", "contracts", "l2_5",
                "standard_source", "harness", "evidence", "gate", "business"}
VALID_ARCH_TYPES = {"library", "cs_module", "independent_process", "cli", "contract"}
VALID_LIFECYCLES = {"proposed", "active", "maintained", "deprecated", "archived", "production"}

print("--- 规则 3: 枚举合法性 ---")
for name, mod in modules.items():
    if not isinstance(mod, dict):
        continue
    d = mod.get("domain")
    if d not in VALID_DOMAINS:
        err(f"{name}: domain={d!r} 不在合法枚举 {sorted(VALID_DOMAINS)}")
    l = mod.get("layer")
    if l not in VALID_LAYERS:
        err(f"{name}: layer={l!r} 不在合法枚举 {sorted(VALID_LAYERS)}")
    a = mod.get("arch_type")
    if a not in VALID_ARCH_TYPES:
        err(f"{name}: arch_type={a!r} 不在合法枚举 {sorted(VALID_ARCH_TYPES)}")
    lc = mod.get("lifecycle")
    if lc not in VALID_LIFECYCLES:
        err(f"{name}: lifecycle={lc!r} 不在合法枚举 {sorted(VALID_LIFECYCLES)}")
print("")

# --- 规则 4：格式校验 ---
REPO_RE = re.compile(r"^github\.com/ZoneCNH/[a-z0-9_.-]+$")
PATH_RE = re.compile(r"^/home/workspace/[a-z0-9_.-]+$")
VERSION_RE = re.compile(r"^v\d+\.\d+\.\d+")

print("--- 规则 4: 格式校验 ---")
for name, mod in modules.items():
    if not isinstance(mod, dict):
        continue
    lifecycle = mod.get("lifecycle")
    is_archived = lifecycle == "archived"

    repo = mod.get("repo")
    if isinstance(repo, str) and repo != "~":
        # GitHub repo name may use hyphens while module name uses underscores (e.g. xlib_standard → xlib-standard)
        expected_repo = f"github.com/ZoneCNH/{name.replace('_', '-')}"
        if repo != expected_repo and repo != f"github.com/ZoneCNH/{name}":
            err(f"{name}: repo={repo!r} 应为 {expected_repo!r}")
        elif not REPO_RE.match(repo):
            err(f"{name}: repo={repo!r} 格式不合规")

    lp = mod.get("local_path")
    if isinstance(lp, str) and lp != "~":
        expected_path = f"/home/workspace/{name.replace('_', '-')}"
        if lp != expected_path and lp != f"/home/workspace/{name}":
            err(f"{name}: local_path={lp!r} 应为 {expected_path!r}")
        elif not PATH_RE.match(lp):
            err(f"{name}: local_path={lp!r} 格式不合规")
    elif lp != "~" and not is_archived and lp is not None:
        # 非 archived 模块的 local_path 不应为空
        pass

    reg = mod.get("registered")
    if isinstance(reg, str):
        if DATE_RE.match(reg):
            try:
                date.fromisoformat(reg)
            except ValueError:
                err(f"{name}: registered={reg!r} 不是合法日期")
        else:
            err(f"{name}: registered={reg!r} 应为 YYYY-MM-DD")

    sv = mod.get("spec_version")
    if isinstance(sv, str) and sv != "~" and not VERSION_RE.match(sv):
        err(f"{name}: spec_version={sv!r} 不匹配 vX.Y.Z 格式")
print("")

# --- 规则 5：spec_ref 路径存在性 ---
print("--- 规则 5: spec_ref 路径存在性 ---")
for name, mod in modules.items():
    if not isinstance(mod, dict):
        continue
    lifecycle = mod.get("lifecycle")
    is_archived = lifecycle == "archived"
    spec_ref = mod.get("spec_ref")

    if is_archived:
        # archived 模块跳过 spec_ref 存在性检查
        continue

    if spec_ref is None or spec_ref == "~":
        warn(f"{name}: 非 archived 模块 spec_ref 为空（建议指向已建 SPEC）")
        continue

    full_path = os.path.join(repo_root, spec_ref)
    if os.path.exists(full_path):
        ok(f"{name}: spec_ref 路径存在 ({spec_ref})")
    else:
        err(f"{name}: spec_ref 路径不存在: {spec_ref}")
print("")

# --- 规则 6：计数口径守卫 ---
print("--- 规则 6: 计数口径守卫 ---")
from collections import Counter
domain_counts = Counter(m.get("domain") for m in modules.values() if isinstance(m, dict))

foundation_n = domain_counts.get("foundation", 0)
if foundation_n == 20:
    ok(f"domain=foundation 计数 = {foundation_n}（基座 20，不含 domainx）")
else:
    err(f"domain=foundation 计数 = {foundation_n}，应为 20（基座口径钉死，见 01 §6.1）")

l25_n = domain_counts.get("l2_5", 0)
if l25_n == 5:
    ok(f"domain=l2_5 计数 = {l25_n}（decimalx/domainx/domain_market/domain_macro/domain_exchange）")
else:
    err(f"domain=l2_5 计数 = {l25_n}，应为 5（L2.5 口径钉死，见 01 §6.1）")
print("")

# --- 汇总 ---
print("=== 结果 ===")
print(f"  模块总数: {len(modules)}")
print(f"  ❌ 失败: {failures}")
print(f"  ⚠️  警告: {warnings}")

if failures > 0:
    sys.exit(1)
sys.exit(0)
PYEOF
