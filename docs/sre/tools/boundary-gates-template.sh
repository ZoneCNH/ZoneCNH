#!/usr/bin/env bash
#
# boundary-gates-template.sh — 通用 9 道 CI 边界门禁模板
#
# 用法：
#   1. 复制到 {module}/scripts/boundary-gates.sh
#   2. 设置 MODULE 变量（模块名，如 okx、fred）
#   3. 运行 ./scripts/boundary-gates.sh
#
# 门禁会自动跳过不适用于当前模块结构的检查（如没有 cmd/{module}-server 目录）。
# 对齐 Bootstrap SOP §八（PR #688）的 9 道标准。
#
set -euo pipefail

# ============ 配置（复制后修改）============
MODULE="{module}"                    # 模块名，如 binance / fred
LEGACY_NAME=""                        # 旧模块名（如有迁移历史，如 binance-market），无则留空
# ==========================================

MODULE_UPPER="$(echo "$MODULE" | tr '[:lower:]-' '[:upper:]_')"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

pass=0
fail=0
gates_failed=()

run_gate() {
  local id="$1" name="$2"
  shift 2
  if "$@" >/tmp/gate-out 2>&1; then
    echo "PASS  $id  $name"
    pass=$((pass + 1))
  else
    echo "FAIL  $id  $name"
    sed 's/^/      /' /tmp/gate-out >&2 || true
    fail=$((fail + 1))
    gates_failed+=("$id")
  fi
}

# §2 no-legacy: 无遗留模块引用（如有迁移历史）
gate_no_legacy() {
  if [ -z "$LEGACY_NAME" ]; then
    return 0  # 无迁移历史，跳过
  fi
  ! grep -R -n -E "module/$LEGACY_NAME|github.com/ZoneCNH/$LEGACY_NAME" \
    --include='*.go' --include='go.mod' \
    . 2>/dev/null | grep -vE 'README|CHANGELOG|boundary-gates|SPEC|_test'
}

# §3 client-no-server: client 包不 import server
gate_client_no_server() {
  if [ ! -d internal/client ]; then return 0; fi
  if [ ! -d internal/server ]; then return 0; fi
  ! grep -R -n -E "internal/server" \
    internal/client 2>/dev/null | grep -vE '//|_test'
}

# §4 server-no-client: server 不 import client
gate_server_no_client() {
  if [ ! -d internal/client ]; then return 0; fi
  if [ ! -d internal/server ]; then return 0; fi
  ! grep -R -n -E "internal/client" \
    internal/server 2>/dev/null | grep -vE '//|_test'
}

# §4b server-cmd-no-client: server cmd 不 import client
gate_server_cmd_no_client() {
  local cmd_dir="cmd/${MODULE}-server"
  if [ ! -d "$cmd_dir" ]; then return 0; fi
  ! grep -R -n -E "internal/client" \
    "$cmd_dir" 2>/dev/null | grep -vE '//|_test'
}

# §5 no-storage-query-strategy: 不 import storage/query/strategy
gate_no_storage_query_strategy() {
  ! grep -R -n -E 'github.com/ZoneCNH/(factor-engine|risk-engine|order-engine)' \
    --include='*.go' \
    . 2>/dev/null | grep -vE '_test|vendor'
}

# §6 no-local-proto: 无 .proto 文件（wire schema 归 contracts）
gate_no_local_proto() {
  [ -z "$(find . -name '*.proto' -not -path './.git/*' -not -path './vendor/*' 2>/dev/null)" ]
}

# §7 no-canonical-ssot-claim: 不声明自己是 canonical SSOT
gate_no_canonical_ssot_claim() {
  ! grep -R -n -iE 'canonical (ssot|source of truth)' \
    --include='*.go' \
    internal/ pkg/ 2>/dev/null | grep -viE 'domain-market|domain-macro|contracts'
}

# §8 no-xlib-standard: go.mod 无 xlib-standard（标准源不参与运行时）
gate_no_xlib_standard() {
  if [ ! -f go.mod ]; then return 0; fi
  ! grep -q 'xlib-standard' go.mod
}

# §9 no-storage-adapter: go.mod 无 L2 存储适配器（adapter 零存储）
gate_no_storage_adapter() {
  if [ ! -f go.mod ]; then return 0; fi
  ! grep -qE 'ZoneCNH/(taosx|postgresx|redisx|kafkax|natsx|ossx|clickhousex)' go.mod
}

# ============ 运行 ============
echo "=== $MODULE boundary-gates (9 gates) ==="
run_gate "§2"  "no legacy module"                 gate_no_legacy
run_gate "§3"  "client must not import server"    gate_client_no_server
run_gate "§4a" "server must not import client"    gate_server_no_client
run_gate "§4b" "server cmd must not import client" gate_server_cmd_no_client
run_gate "§5"  "no storage/query/strategy"        gate_no_storage_query_strategy
run_gate "§6"  "no local proto files"             gate_no_local_proto
run_gate "§7"  "no canonical SSOT claim"          gate_no_canonical_ssot_claim
run_gate "§8"  "no xlib-standard in go.mod"       gate_no_xlib_standard
run_gate "§9"  "no storage adapter in go.mod"     gate_no_storage_adapter

echo ""
echo "Results: $pass passed, $fail failed"

if [ "$fail" -gt 0 ]; then
  echo "Failed gates: ${gates_failed[*]}"
  exit 1
fi
exit 0
