#!/bin/bash
# check-version-drift.sh — 模块 Spec-Version 变更后检测过时引用
#
# 用法:
#   ./scripts/check-version-drift.sh binance v3.7.0 v3.7.1
#       → 检查 binance 模块的 v3.7.0 引用是否已全部更新为 v3.7.1
#   ./scripts/check-version-drift.sh --help
#       → 打印覆盖范围数（供 agent 引用，避免硬编码）
#
# 退出码:
#   0 — 零残留引用，通过
#   1 — 发现过时引用，阻止合并
#
# 来源: 2026-06-26 binance v3.7.1 会话复盘 — 一个 Spec-Version 变更被证实
#       会影响 25+ 个文件。CI 门禁确保这些文件在 PR 中同步更新，而非事后补丁。

set -euo pipefail

# --help: 打印覆盖范围数并退出（供 agent 动态引用，避免硬编码数字漂移）
if [ "${1:-}" = "--help" ]; then
    SCOPE_COUNT=$(grep -c '^# ── 范围' "$0")
    echo "check-version-drift.sh — $SCOPE_COUNT 个覆盖范围（模块感知，动态依赖/模板）"
    exit 0
fi

MODULE="${1:?Usage: $0 <module-name> <old-version> <new-version>}"
OLD_VERSION="${2:?Usage: $0 <module-name> <old-version> <new-version>}"
NEW_VERSION="${3:?Usage: $0 <module-name> <old-version> <new-version>}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

# ── 范围 A: 模块治理文档 ──
echo "--- check-version-drift: module/$MODULE (v$OLD_VERSION → v$NEW_VERSION) ---"
echo ""

if [ -d "$ROOT/module/$MODULE" ]; then
    STALE=$(grep -rn "v$OLD_VERSION" "$ROOT/module/$MODULE"/*.md 2>/dev/null | \
        grep -v CHANGELOG.md | grep -v "弃用" | grep -v "历史" | grep -v "已撤回" | \
        grep -v "新增" | grep -v "升级" | grep -v "draft" | grep -v "Applies-To" | \
        grep -v "ARCHIVED" | grep -v "已被" | grep -v "DEEP-ANALYSIS" | \
        grep -v "审计对齐" | grep -v "版本跳空" | grep -v "登记到" | grep -v "对齐 v" | \
        grep -v "投影" || true)
    if [ -n "$STALE" ]; then
        echo "FAIL: module/$MODULE/ 中发现过时引用:"
        echo "$STALE"
        FAILED=1
    else
        echo "PASS: module/$MODULE/ 中无过时引用"
    fi
fi

# ── 范围 B: 仓库锚点文档 ──
for FILE in README.md ARCHITECTURE.md STATUS.md module/README.md; do
    if [ -f "$ROOT/$FILE" ]; then
        STALE=$(grep -n "v$OLD_VERSION" "$ROOT/$FILE" 2>/dev/null | \
            grep -i "$MODULE" | \
            grep -v "弃用" | grep -v "历史" | grep -v "已撤回" | \
            grep -v "v$OLD_VERSION 新增" | grep -v "v$OLD_VERSION FR-" || true)
        if [ -n "$STALE" ]; then
            echo "FAIL: $FILE 中发现过时引用:"
            echo "$STALE"
            FAILED=1
        fi
    fi
done

# ── 范围 C: 架构文档 ──
ARCH_FILES=$(find "$ROOT/docs/architecture/" -name "*.md" 2>/dev/null || true)
if [ -n "$ARCH_FILES" ]; then
    STALE=$(grep -rn "v$OLD_VERSION" $ARCH_FILES 2>/dev/null | \
        grep -i "$MODULE" | grep -v "弃用" | grep -v "历史" || true)
    if [ -n "$STALE" ]; then
        echo "FAIL: docs/architecture/ 中发现过时引用:"
        echo "$STALE"
        FAILED=1
    fi
fi

# ── 范围 D: 模板文件 ──
for TEMPLATE_DIR in $(ls -d "$ROOT/module/_"* 2>/dev/null); do
    STALE=$(grep -rn "v$OLD_VERSION" "$TEMPLATE_DIR"/*.md 2>/dev/null | grep -i "$MODULE" | \
        grep -v "弃用" | grep -v "历史" || true)
    if [ -n "$STALE" ]; then
        echo "FAIL: $(basename "$TEMPLATE_DIR") 中发现过时引用:"
        echo "$STALE"
        FAILED=1
    fi
done

# ── 范围 E: 依赖模块反向引用（动态读取 — 从 SPEC.md §1 Related 行获取）──
RELATED=$(grep '^\- Related:' "$ROOT/module/$MODULE/SPEC.md" 2>/dev/null | \
    grep -oP 'module/[a-z_]+' | sed 's|^module/||' || true)
for DEP in $RELATED; do
    DEP_DIR="$ROOT/module/$DEP"
    if [ -d "$DEP_DIR" ]; then
        STALE=$(grep -rni "$MODULE" "$DEP_DIR"/*.md 2>/dev/null | grep "v$OLD_VERSION" || true)
        if [ -n "$STALE" ]; then
            echo "WARN: $DEP/SPEC.md 中引用了 $MODULE 的过时版本:"
            echo "$STALE"
            echo "      (交叉仓库修复需要 PR 到依赖模块)"
        fi
    fi
done

# ── 范围 F: plans/ 和 report/ ──
# 这些属于活跃编辑文档，但其版本引用通常属于历史上下文，而非过时元数据。
# 若发现命中，仅告警（不标记为失败），提示人工复核。
PLAN_STALE=$(grep -rn "v$OLD_VERSION" "$ROOT/plans/" "$ROOT/report/" --include="*.md" 2>/dev/null | \
    grep -i "$MODULE" | grep -v "弃用" | grep -v "历史" | grep -v "draft" | grep -v "archive" || true)
if [ -n "$PLAN_STALE" ]; then
    echo "WARN: plans/ 或 report/ 中发现 $OLD_VERSION 引用（仅告警，需人工复核）:"
    echo "$PLAN_STALE"
fi

echo ""
if [ "$FAILED" -eq 1 ]; then
    echo "--- DRIFT DETECTED: 请将以上过时引用更新为 v$NEW_VERSION 后重新提交 ---"
    exit 1
else
    echo "--- PASS: 所有引用均已更新为 v$NEW_VERSION ---"
    exit 0
fi
