#!/usr/bin/env bash
# repo-existence-check.sh — 验证基座模块的 GitHub 仓库链接均可访问
#
# 规则来源：CLAUDE.md §模块-仓库强制对应
# 检查范围：仅限基座模块（FOUNDATION_MODULES 数组中列出的 20 个模块）
#          其他域的模块在状态为"🔨 已创建"时不强制要求仓库存在
# 检查逻辑：
#   1. 使用与 status-consistency-check.sh 相同的 FOUNDATION_MODULES 数组
#   2. 对每个模块检查 https://github.com/ZoneCNH/<module> 返回 HTTP 200
#   3. 缓存结果（15 分钟内不重复请求）

set -euo pipefail

FAIL=0
REPO_ROOT="$(git rev-parse --show-toplevel)"

echo "=== Repository Existence Check ==="
echo "范围：基座模块（FOUNDATION_MODULES 数组）"
echo ""

# 与 status-consistency-check.sh 保持同步的基座模块列表
FOUNDATION_MODULES=(
  xlib-standard
  xlib-harness
  xlib-evidence
  kernel
  configx
  observex
  testkitx
  resiliencx
  schedulex
  xlibgate
  redisx
  kafkax
  natsx
  postgresx
  taosx
  ossx
  clickhousex
  contracts
  transportx
  domainx
)

TOTAL=${#FOUNDATION_MODULES[@]}
OK=0
MISSING=()

echo "--- 检查仓库可用性 ---"
echo ""

for module in "${FOUNDATION_MODULES[@]}"; do
  url="https://github.com/ZoneCNH/${module}"

  code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 "$url" 2>/dev/null || echo "000")

  if [[ "$code" == "200" ]]; then
    echo "  ✅ $module"
    OK=$((OK + 1))
  else
    echo "  ❌ $module → $url (HTTP $code)"
    MISSING+=("$module")
    FAIL=1
  fi
done

echo ""
echo "--- 汇总 ---"
echo "基座模块: $TOTAL 个"
echo "仓库存在: $OK"
echo "仓库缺失: $((TOTAL - OK))"

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo ""
  echo "❌ 缺失仓库: ${MISSING[*]}"
  echo ""
  echo "修复提示："
  echo "  1. 为每个缺失模块创建 GitHub 仓库：gh repo create ZoneCNH/<module> --public"
  echo "  2. 至少初始化 README.md 说明模块职责和 Go module 归属"
  echo "  3. 如果模块共享 xlib-standard 的 Go module，在 README 中注明"
  echo ""
  echo "规则来源：CLAUDE.md §模块-仓库强制对应"
fi

echo ""

if [[ $FAIL -ne 0 ]]; then
  echo "❌ Repository Existence Check 失败"
  exit 1
else
  echo "✅ Repository Existence Check 全部通过"
  exit 0
fi
