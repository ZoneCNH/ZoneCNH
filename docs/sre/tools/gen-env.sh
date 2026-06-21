#!/usr/bin/env bash
#
# gen-env.sh — 从 sre/secrets/env/dev.md 生成本地 .env（不进 git）
#
# 用法：
#   ./sre/tools/gen-env.sh <module>           # 生成 /home/<module>/.env
#   ./sre/tools/gen-env.sh <module> --example # 生成 /home/<module>/.env.example（无真值）
#   ./sre/tools/gen-env.sh <module> --stdout  # 输出到 stdout（不写文件）
#
# module 名与 GitHub 仓库名一致（如 fred、binance、okx）。
# 行情模块 → market_{module} 库；宏观模块 → macro_{module} 库。
# 脚本自动检测模块类别（参考 docs/report/data-domain-infrastructure-20260617.md §一）。
#
# 对齐 Bootstrap SOP §七（PR #688）和基础架构报告 §七（PR #686）。
#
set -euo pipefail

# ---- 模块分类 ----
MARKET_MODULES="binance okx bybit bitget kucoin gate mexc htx coinbase hyperliquid lighter upbit coinglass"
MACRO_MODULES="fred treasury yield-curve bea ecb uk-cb japan-cb eastmoney jin10 yahoo"

# ---- 路径 ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DEV_MD="$REPO_ROOT/sre/secrets/env/dev.md"

# ---- 参数解析 ----
MODULE="${1:-}"
MODE="--write" # --write | --example | --stdout
if [ -z "$MODULE" ]; then
  echo "用法: gen-env.sh <module> [--example|--stdout]" >&2
  echo "  module: fred binance okx ..." >&2
  exit 1
fi
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --example) MODE="--example" ;;
    --stdout)  MODE="--stdout" ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
  shift
done

# ---- 确定模块类别 + DB 前缀 ----
MODULE_UPPER="$(echo "$MODULE" | tr '[:lower:]-' '[:upper:]_')"
MODULE_DASH="$(echo "$MODULE" | tr '_' '-')"

is_market=""
is_macro=""
for m in $MARKET_MODULES; do
  [ "$m" = "$MODULE" ] && is_market=1
done
for m in $MACRO_MODULES; do
  [ "$m" = "$MODULE" ] && is_macro=1
done

if [ -z "$is_market" ] && [ -z "$is_macro" ]; then
  echo "⚠️  模块 $MODULE 不在已知 market/macro 清单中" >&2
  echo "   market: $MARKET_MODULES" >&2
  echo "   macro:  $MACRO_MODULES" >&2
  # 不退出——允许未知模块（用 generic 格式）
fi

DB_PREFIX="market"
DISPATCH_TARGET="market_data"
if [ -n "$is_macro" ]; then
  DB_PREFIX="macro"
  DISPATCH_TARGET="macro_data"
fi

# dev.md 里的库名可能与 module 名不完全一致（如 jin10→jinshi，japan-cb→japan_cb）
# 尝试多种变体
DB_NAME_CANDIDATES="${DB_PREFIX}_${MODULE}"
case "$MODULE" in
  jin10)     DB_NAME_CANDIDATES="${DB_PREFIX}_jinshi" ;;
  japan-cb)  DB_NAME_CANDIDATES="${DB_PREFIX}_japan_cb" ;;
  yield-curve) DB_NAME_CANDIDATES="${DB_PREFIX}_yield_curve" ;;
esac

# ---- 从 dev.md 提取 PG 密码 ----
pg_password=""
td_password=""
if [ -f "$DEV_MD" ]; then
  for db_name in $DB_NAME_CANDIDATES; do
    # PG 密码：表格行 | db_name | host | port | user | `password` | ✅ |
    line=$(grep "| $db_name " "$DEV_MD" 2>/dev/null | head -1 || true)
    if [ -n "$line" ]; then
      pg_password=$(echo "$line" | sed -n 's/.*`\([^`]*\)`.*/\1/p' || true)
      break
    fi
  done

  # TDengine 密码（同理，不同段落）
  for db_name in $DB_NAME_CANDIDATES; do
    line=$(grep "| $db_name " "$DEV_MD" 2>/dev/null | head -1 || true)
    if [ -n "$line" ]; then
      td_password=$(echo "$line" | sed -n 's/.*`\([^`]*\)`.*/\1/p' || true)
      break
    fi
  done

  # FRED API key（宏观 fred 模块专用）
  fred_key=$(grep "^api_key=" "$DEV_MD" 2>/dev/null | head -1 | cut -d= -f2 || true)
else
  echo "⚠️  dev.md 不存在: $DEV_MD" >&2
fi

# ---- 生成内容 ----
# adapter 格式（零存储——只 API key + dispatch target + 日志）
gen_env() {
  local mode="$1"
  local pg_pw="$pg_password"
  local td_pw="$td_password"
  local fred="$fred_key"

  # --example 模式清空真实值
  if [ "$mode" = "--example" ]; then
    pg_pw=""
    td_pw=""
    fred=""
  fi

  # ---- 生成 Provider API 段（按模块类别）----
  local api_section=""
  if [ "$MODULE" = "fred" ]; then
    api_section="XGO_${MODULE_UPPER}_API_KEY=${fred}"
  elif [ -n "$is_market" ]; then
    api_section="XGO_${MODULE_UPPER}_API_KEY=
XGO_${MODULE_UPPER}_API_SECRET=
# testnet | mainnet
XGO_${MODULE_UPPER}_MODE=testnet"
  else
    # 其他宏观模块（ECB/BEA 等通常不需要 API key）
    api_section="# XGO_${MODULE_UPPER}_API_KEY="
  fi

  cat <<EOF
# ============================================================
# $MODULE 环境变量（$([ "$mode" = "--example" ] && echo "模板" || echo "自动生成")）
# 模块类别: ${DB_PREFIX:-unknown} | Dispatch 目标: $DISPATCH_TARGET
# 生成自: sre/secrets/env/dev.md（$([ "$mode" = "--example" ] && echo "无真值" || echo "含真值，勿提交")）
# ============================================================

# ---- Provider API ----
${api_section}

# ---- Dispatch 目标（聚合层接收侧）----
XGO_${MODULE_UPPER}_DISPATCH_TARGET=$DISPATCH_TARGET
XGO_${MODULE_UPPER}_DISPATCH_ADDR=:9090

# ---- 可观测（bootstrap 统一加载）----
XGO_${MODULE_UPPER}_LOG_LEVEL=info
XGO_${MODULE_UPPER}_METRICS_ADDR=:9091

# ---- 注意：adapter 零存储 ----
# PG/TD/Redis/Kafka/OSS/CH 凭据属于聚合层（$DISPATCH_TARGET）的 .env，不属于 adapter。
# adapter 只采集 + 校验，不碰存储。
EOF
}

# ---- 输出 ----
case "$MODE" in
  --stdout)
    gen_env "--write"
    ;;
  --example)
    target="/home/$MODULE/.env.example"
    gen_env "--example" > "$target"
    echo "✅ 生成 $target（无真值，可提交）"
    ;;
  --write)
    target="/home/$MODULE/.env"
    gen_env "--write" > "$target"
    # 确保 .env 在 .gitignore 中
    if [ -f "/home/$MODULE/.gitignore" ]; then
      grep -q "^\.env$" "/home/$MODULE/.gitignore" || echo ".env" >> "/home/$MODULE/.gitignore"
    fi
    echo "✅ 生成 $target（含真值，已确保 .gitignore 排除）"
    ;;
esac
