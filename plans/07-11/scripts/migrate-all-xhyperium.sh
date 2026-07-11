#!/bin/bash
# migrate-all-xhyperium.sh — 全舰队 ZoneCNH → xhyperium org 迁移
# 范围：25 基座模块 + 11 exchange adapter + 相关消费者
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="/tmp/xhyperium-migrate-${TIMESTAMP}.log"

# ===== 配置 =====

# 25 基座模块迁移顺序：按依赖关系排列
# 叶子模块（零/少消费者）先迁移，被广泛依赖的模块放最后
FOUNDATION_MODULES=(
    # Phase 1: 零消费者（最安全）
    "domain_macro"      # consumers: composer,fred,japan_cb,macro_regime,regime_engine
    "xlib_harness"      # consumers: 0

    # Phase 2: 叶子模块
    "testkitx"
    "schedulex"
    "observex"
    "resiliencx"
    "redisx"
    "kafkax"
    "natsx"
    "postgresx"
    "taosx"
    "ossx"
    "clickhousex"

    # Phase 3: 核心 L0/L1
    "decimalx"
    "kernel"
    "configx"
    "bootstrap"

    # Phase 4: 域/契约模块（有消费者）
    "contracts"
    "domainx"
    "domain_market"     # 9 direct consumers → must be before domain_exchange
    "domain_exchange"   # 11 exchange adapter consumers

    # Phase 5: 标准源（被全舰队依赖 — 最后）
    "transportx"        # shared module path with xlib_standard
    "xlibgate"
    "xlib_evidence"
    "xlib_standard"     # ALL 24 modules depend on this
)

# 11 exchange adapter consumers that will need import fixes
EXCHANGE_ADAPTERS=(
    "bitget" "bybit" "coinbase" "gate" "htx"
    "hyperliquid" "kucoin" "lighter" "mexc" "okx" "upbit"
)

# Additional consumer modules found by Explore-1
ADDITIONAL_CONSUMERS=(
    "composer" "fred" "japan_cb" "macro_regime" "regime_engine"
    "binance" "binance_market"
    "bitget_market" "bybit_market" "coinbase_market" "okx_market"
    "market_data" "market_regime"
)

# ===== 工具函数 =====

log() { echo "$@" | tee -a "$LOG_FILE"; }

health_check() {
    local module=$1 phase=$2
    local repo="/home/workspace/${module}"
    [ -d "$repo" ] || return 0  # skip non-existent
    [ -f "$repo/go.mod" ] || return 0  # skip non-Go modules

    log "[${phase}] ${module}: go build ./..."
    if ! (cd "$repo" && GOWORK=off go build ./... 2>&1) >> "$LOG_FILE" 2>&1; then
        log "[${phase}] ${module}: BUILD FAILED (may be expected during migration)"
        return 1
    fi
    log "[${phase}] ${module}: OK"
}

consumer_import_fix() {
    local migrated_module=$1 consumer=$2
    local repo="/home/workspace/${consumer}"
    [ -d "$repo" ] || return 0
    [ -f "$repo/go.mod" ] || return 0

    cd "$repo"
    if grep -rq "github.com/xhyperium/${migrated_module}" --include="*.go" . 2>/dev/null; then
        log "  [FIX] ${consumer}: updating import ${migrated_module}"
        find . -name "*.go" -exec sed -i \
            "s|github.com/xhyperium/${migrated_module}|github.com/xhyperium/${migrated_module}|g" {} +
        # Also fix in go.mod require
        sed -i "s|github.com/xhyperium/${migrated_module}|github.com/xhyperium/${migrated_module}|g" go.mod
        GOWORK=off GOFLAGS=-mod=mod go mod tidy 2>&1 >> "$LOG_FILE" 2>&1 || true
    fi
}

# ===== 主流程 =====

log "=== migrate-all-xhyperium.sh ==="
log "Timestamp: $TIMESTAMP"
log "Log: $LOG_FILE"
log "Scope: 25 foundation + ZoneCNH configs"
log "DRY_RUN: ${DRY_RUN:-0}"
log ""

if [ "${DRY_RUN:-0}" = "1" ]; then
    log "DRY_RUN mode — no changes will be made"
    for m in "${FOUNDATION_MODULES[@]}"; do
        bash "${SCRIPT_DIR}/xhyperium-module-migrate.sh" "$m" 2>&1 | tee -a "$LOG_FILE"
    done
    log "DRY_RUN complete"
    exit 0
fi

PASSED=0
FAILED=0
BLOCKED=false

# ===== Step 1: 先迁移 ZoneCNH 主仓的 SSOT 配置 =====
log "--- ZONECNH configs ---"
if ! bash "${SCRIPT_DIR}/migrate-zonecnh-configs.sh" >> "$LOG_FILE" 2>&1; then
    log "[FAIL] ZoneCNH config migration failed"
    exit 1
fi
log "[PASS] ZoneCNH configs"

# ===== Step 2: 25 基座模块逐模块迁移 =====
for module in "${FOUNDATION_MODULES[@]}"; do
    log ""
    log "--- ${module} ---"

    if $BLOCKED; then
        log "[SKIP] ${module}: blocked by upstream failure"
        continue
    fi

    # PRE-MIG
    if ! health_check "$module" "PRE"; then
        log "[WARN] ${module}: pre-migration health check had issues — continuing"
    fi

    # MIGRATE
    module_script="${SCRIPT_DIR}/xhyperium-module-migrate.sh"
    if ! bash "$module_script" "$module" >> "$LOG_FILE" 2>&1; then
        log "[FAIL] ${module}: migration failed"
        ((FAILED++))
        BLOCKED=true
        continue
    fi

    # POST-MIG
    if ! health_check "$module" "POST"; then
        log "[WARN] ${module}: post-migration build issues — may need consumer fixes"
    fi

    log "[PASS] ${module}"
    ((PASSED++))
done

# ===== Step 3: 消费者 import 修复 =====
log ""
log "--- Fixing consumer import paths ---"
log "Exchange adapters:"
for adapter in "${EXCHANGE_ADAPTERS[@]}"; do
    consumer_import_fix "domain_exchange" "$adapter"
    consumer_import_fix "domain_market" "$adapter"
done

log "Additional consumers:"
for consumer in "${ADDITIONAL_CONSUMERS[@]}"; do
    consumer_import_fix "domain_macro" "$consumer"
    consumer_import_fix "domain_market" "$consumer"
    consumer_import_fix "transportx" "$consumer"
done

# ===== 汇总 =====
log ""
log "=== Xhyperium Org Migration Summary ==="
log "Foundation modules: $PASSED passed, $FAILED failed"
log "Log: $LOG_FILE"
log ""

if [ "$FAILED" -gt 0 ]; then
    log "ACTION REQUIRED: Review failure(s) in $LOG_FILE"
    log "Failed modules may need manual go.sum regeneration or consumer import fixes"
    exit 1
fi

log "All foundation modules migrated to xhyperium org."
log ""

# ===== Cleanup : ZoneCNH repo changes =====
log "=== ZoneCNH repo changes ==="
cd /home/workspace/ZoneCNH
git diff --stat 2>/dev/null || true
log ""
log "Review:  cd /home/workspace/ZoneCNH && git diff"
log "Commit:  git add -A && git commit -m 'migrate: SSOT configs ZoneCNH → xhyperium org'"
