#!/usr/bin/env bash
# 验证脚本（PLAN-010）
# 用法：bash 010-verify-issues.sh
set -euo pipefail

echo "=== [1] 验证 beads issue 创建 ==="
bd stats 2>&1 | head -10
echo ""
echo "=== [2] 验证 GitHub issue 同步（需 gh auth） ==="
if ! gh auth status >/dev/null 2>&1; then
  echo "⚠️  gh CLI 未认证，跳过 GitHub 验证"
else
  gh issue list -R ZoneCNH/binance --state open --limit 50 2>&1 | head -40
fi

echo ""
echo "=== [3] 验证 plan 文件 ==="
ls -la /home/workspace/ZoneCNH/plans/binance/010-*.md /home/workspace/ZoneCNH/plans/binance/010-*.sh 2>&1

echo ""
echo "=== [4] 验证 9 个陷阱现状（修复前快照） ==="
echo "--- T0-1/T8-1: Runtime-Version ---"
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/spec/SPEC.md
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/README.md
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/deploy/DEPLOY.md
echo "--- runtime tag ---"
git -C /home/workspace/binance tag -l 'v*' | head -3 || echo "(none)"
echo ""
echo "--- T1-1: CHANGELOG vs SPEC ---"
grep -m1 'Module-Version' /home/workspace/ZoneCNH/module/binance/CHANGELOG.md
grep -m1 'Spec-Version' /home/workspace/ZoneCNH/module/binance/spec/SPEC.md
echo ""
echo "--- T2-1: evidence GAP-E 引用 ---"
grep -rl "GAP-E" /home/workspace/ZoneCNH/module/binance/evidence/ 2>/dev/null | wc -l
echo ""
echo "--- T8-2: SECURITY/CONTRIBUTING ---"
ls /home/workspace/ZoneCNH/module/binance/SECURITY.md 2>/dev/null || echo "SECURITY.md MISSING"
ls /home/workspace/ZoneCNH/module/binance/CONTRIBUTING.md 2>/dev/null || echo "CONTRIBUTING.md MISSING"

echo ""
echo "=== [5] 验证 plan 完整性 ==="
PLAN=/home/workspace/ZoneCNH/plans/binance/010-runtime-gap-fix-execution-plan-20260702.md
echo "plan 行数: $(wc -l < $PLAN)"
echo "plan 字节数: $(wc -c < $PLAN)"
echo ""
echo "Phase 数量: $(grep -c '^### Phase' $PLAN)"
echo "GAP-E 引用数: $(grep -oc 'GAP-E[0-9]\+' $PLAN || grep -c 'GAP-E' $PLAN)"
echo "Task 数量: $(grep -c '^| P[0-9]' $PLAN)"

echo ""
echo "✅ 验证完成"
