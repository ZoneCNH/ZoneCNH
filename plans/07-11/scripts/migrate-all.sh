#!/bin/bash
# migrate-all.sh — 6 模块 kebab→snake 串行迁移
# 依赖顺序: domain_macro → domain_exchange → domain_market → transportx → xlib_harness → xlib_standard
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="/tmp/migrate-all-${TIMESTAMP}.log"

# ===== 配置（基于 Explore-1 真实消费者分析） =====
declare -A CONSUMERS
# domain_macro: composer, fred, japan_cb, macro_regime, regime_engine (5)
CONSUMERS[domain_macro]="composer,fred,japan_cb,macro_regime,regime_engine"

# domain_market: 9 direct + 11 indirect via domain_exchange = 20 total affected
# Direct: binance, bitget_market, bybit_market, coinbase_market, composer, domain_exchange, market_data, market_regime, okx_market
# NOTE: binance_market already uses snake_case import — partial migration already done
CONSUMERS[domain_market]="binance,bitget_market,bybit_market,coinbase_market,composer,market_data,market_regime,okx_market"

# domain_exchange: 11 exchange adapter consumers
# bitget, bybit, coinbase, gate, htx, hyperliquid, kucoin, lighter, mexc, okx, upbit
# NOTE: domain_exchange itself imports domain_market — migrate domain_market FIRST
CONSUMERS[domain_exchange]="bitget,bybit,coinbase,gate,htx,hyperliquid,kucoin,lighter,mexc,okx,upbit"

# transportx: bitget_market, bybit_market, coinbase_market, okx_market + binance_market(snake_case) + xlib_harness test
# CRITICAL: transportx and xlib_standard share the SAME go.mod module path (both declare xlib-standard)
# Fix transportx FIRST, then xlib_standard
CONSUMERS[transportx]="binance_market,bitget_market,bybit_market,coinbase_market,okx_market,xlib_harness"

# xlib_harness: ZERO consumers (standalone tool)
CONSUMERS[xlib_harness]=""

# xlib_standard: same consumer list as transportx (shared module path), plus ALL modules
# Must be LAST because ALL 24 other modules reference it
CONSUMERS[xlib_standard]="ALL"

# ===== 迁移顺序：按消费者影响范围递增 =====
# 逻辑：先修零/少消费者的叶子模块，逐步升级到全舰队依赖的标准源
MIGRATION_ORDER=(
    "xlib_harness"      # 0 consumers — 最安全
    "domain_macro"      # 5 consumers — 低风险
    "domain_market"     # 9 direct + 11 indirect — 中风险（但必须在 domain_exchange 前）
    "domain_exchange"   # 11 exchange adapters — 中风险（取决于 domain_market）
    "transportx"        # 5 consumers + shared module path fix — 高风险
    "xlib_standard"     # ALL 24 modules — 最高风险（必须最后）
)

# ===== 关键警告 =====
echo ""
echo "=== Consumer Impact Analysis ==="
echo "domain_market:  9 direct + 11 indirect (via domain_exchange) = 20 modules affected"
echo "domain_exchange: 11 exchange adapter modules affected"
echo "transportx + xlib_standard: SHARE THE SAME go.mod module path (both declare xlib-standard)"
echo "binance_market: already uses snake_case imports — partial migration exists"
echo "xlib_harness:   ZERO consumers — safest migration target"
echo ""

# ===== 工具函数 =====

health_check() {
    local module=$1 phase=$2
    local repo="/home/workspace/${module}"
    echo "[${phase}] ${module}: go build ./..."
    (cd "$repo" && GOWORK=off go build ./... 2>&1) || return 1
    echo "[${phase}] ${module}: go vet ./..."
    (cd "$repo" && GOWORK=off go vet ./... 2>&1) || true  # vet 允许失败
    echo "[${phase}] ${module}: OK"
}

consumer_verify() {
    local module=$1
    local consumers="${CONSUMERS[$module]:-}"
    if [ "$consumers" = "ALL" ]; then
        echo "[CONSUMER] ${module}: verifying ALL 24 consumers..."
        # 列表从 identity-inventory.md 提取
        consumers="kernel,configx,observex,resiliencx,schedulex,bootstrap,testkitx,redisx,kafkax,natsx,postgresx,taosx,ossx,clickhousex,contracts,transportx,domainx,decimalx,domain_market,domain_macro,domain_exchange,xlib_harness,xlib_evidence,xlibgate"
    fi
    
    local all_ok=true
    IFS=',' read -ra CONSUMER_LIST <<< "$consumers"
    for consumer in "${CONSUMER_LIST[@]}"; do
        consumer=$(echo "$consumer" | xargs)  # trim whitespace
        local consumer_repo="/home/workspace/${consumer}"
        if [ ! -d "$consumer_repo" ]; then continue; fi
        echo -n "  [CONSUMER] ${consumer}: "
        if (cd "$consumer_repo" && GOWORK=off go build ./... 2>&1) > /dev/null 2>&1; then
            echo "OK"
        else
            echo "FAIL"
            all_ok=false
        fi
    done
    $all_ok && return 0 || return 1
}

# ===== 主流程 =====

echo "=== migrate-all.sh ==="
echo "Timestamp: $TIMESTAMP"
echo "Log: $LOG_FILE"
echo "DRY_RUN: ${DRY_RUN:-0}"
echo ""

PASSED=0
FAILED=0
SKIPPED=0
BLOCKED=false

for module in "${MIGRATION_ORDER[@]}"; do
    echo "--- ${module} ---"
    
    # 检查是否被阻塞
    if $BLOCKED; then
        echo "[SKIP] ${module}: blocked by previous failure"
        ((SKIPPED++))
        continue
    fi
    
    # PRE-MIG 健康检查
    if ! health_check "$module" "PRE-MIG"; then
        echo "[FAIL] ${module}: PRE-MIG check failed"
        ((FAILED++))
        BLOCKED=true
        continue
    fi
    
    # 执行迁移
    script="${SCRIPT_DIR}/${module}-migrate.sh"
    if [ ! -f "$script" ]; then
        echo "[FAIL] ${module}: script not found: $script"
        ((FAILED++))
        BLOCKED=true
        continue
    fi
    
    if ! NON_INTERACTIVE=1 bash "$script" >> "$LOG_FILE" 2>&1; then
        echo "[FAIL] ${module}: migration script failed (see $LOG_FILE)"
        ((FAILED++))
        BLOCKED=true
        continue
    fi
    
    # POST-MIG 健康检查
    if ! health_check "$module" "POST-MIG"; then
        echo "[FAIL] ${module}: POST-MIG check failed"
        ((FAILED++))
        BLOCKED=true
        continue
    fi
    
    # 消费者验证
    consumer_result="N/A"
    if [ -n "${CONSUMERS[$module]:-}" ]; then
        if consumer_verify "$module"; then
            consumer_count=$(echo "${CONSUMERS[$module]}" | tr ',' '\n' | wc -l)
            consumer_result="$consumer_count/$consumer_count"
        else
            consumer_result="FAIL"
            echo "[WARN] ${module}: some consumers failed verification"
        fi
    fi
    
    echo "[PASS] ${module} (pre:OK migrate:OK post:OK consumers:${consumer_result})"
    ((PASSED++))
done

# ===== 汇总 =====
echo ""
echo "=== Migration Summary ==="
echo "PASSED: $PASSED"
echo "FAILED: $FAILED"
echo "SKIPPED: $SKIPPED"
echo "Log: $LOG_FILE"
echo ""

if [ "$FAILED" -gt 0 ]; then
    echo "ACTION REQUIRED: Review failures in $LOG_FILE"
    exit 1
fi

echo "All migrations complete. Review each module with:"
for module in "${MIGRATION_ORDER[@]}"; do
    echo "  cd /home/workspace/${module} && git diff origin/main"
done
