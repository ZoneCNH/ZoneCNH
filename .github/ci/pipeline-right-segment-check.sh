#!/usr/bin/env bash
# pipeline-right-segment-check.sh — 检查 Approved 模块的 plan/prompt/evidence 覆盖
# 来源: issue #1094 / 报告 §5 路线图 #11
set -euo pipefail

WARN=0
TOTAL=0
HAS_PLAN=0
HAS_PROMPT=0
HAS_EVIDENCE=0

for d in module/*/; do
  m=$(basename "$d")
  spec="$d/SPEC.md"
  [ -f "$spec" ] || continue
  status=$(grep -m1 -iE "^Status:" "$spec" 2>/dev/null | sed 's/.*[Ss]tatus[:]* *//' || echo "")
  case "$status" in
    *Approved*|*Implemented*)
      TOTAL=$((TOTAL+1))
      [ -f "$d/PLAN.md" ] && HAS_PLAN=$((HAS_PLAN+1)) || { echo "[WARN] $m: 缺 PLAN.md"; WARN=$((WARN+1)); }
      [ -d "$d/prompt" ] && [ "$(ls -A "$d/prompt" 2>/dev/null)" ] && HAS_PROMPT=$((HAS_PROMPT+1)) || { echo "[WARN] $m: 缺 prompt/ 目录或为空"; WARN=$((WARN+1)); }
      [ -d "$d/evidence" ] && [ "$(ls -A "$d/evidence" 2>/dev/null)" ] && HAS_EVIDENCE=$((HAS_EVIDENCE+1)) || { echo "[WARN] $m: 缺 evidence/ 目录或为空"; WARN=$((WARN+1)); }
      ;;
  esac
done

echo ""
echo "=== Pipeline Right Segment Coverage ==="
echo "Approved/Implemented 模块: $TOTAL"
echo "有 PLAN.md: $HAS_PLAN ($(( TOTAL>0 ? HAS_PLAN*100/TOTAL : 0 ))%)"
echo "有 prompt/: $HAS_PROMPT ($(( TOTAL>0 ? HAS_PROMPT*100/TOTAL : 0 ))%)"
echo "有 evidence/: $HAS_EVIDENCE ($(( TOTAL>0 ? HAS_EVIDENCE*100/TOTAL : 0 ))%)"
echo "WARN 数: $WARN"
echo ""
echo "注: 本检查为 WARN 非阻断（issue #1094），未来可升级为 FAIL gate"
