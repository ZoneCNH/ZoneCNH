#!/bin/bash
# check-version-drift.sh — 模块 Spec-Version 变更后检测过时引用
#
# 用法:
#   ./scripts/check-version-drift.sh binance v3.7.0 v3.7.1
#       → 检查 binance 模块的 v3.7.0 引用是否已全部更新为 v3.7.1
#
# 退出码:
#   0 — 零残留引用，通过
#   1 — 发现过时引用，阻止合并
#
# 来源: 2026-06-26 binance v3.7.1 会话复盘 — 一个 Spec-Version 变更被证实
#       会影响 25+ 个文件。CI 门禁确保这些文件在 PR 中同步更新，而非事后补丁。

set -euo pipefail

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
        grep -v "新增" | grep -v "升级" | grep -v "draft" | grep -v "Applies-To" || true)
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
    STALE=$(grep -rn "v$OLD_VERSION" $ARCH_FILES 2>/dev/null | grep -v "弃用" | grep -v "历史" || true)
    if [ -n "$STALE" ]; then
        echo "FAIL: docs/architecture/ 中发现过时引用:"
        echo "$STALE"
        FAILED=1
    fi
fi

# ── 范围 D: 模板文件 ──
if [ -f "$ROOT/module/_exchange-template/README.md" ]; then
    STALE=$(grep -n "v$OLD_VERSION" "$ROOT/module/_exchange-template/README.md" 2>/dev/null || true)
    if [ -n "$STALE" ]; then
        echo "FAIL: _exchange-template 中发现过时引用:"
        echo "$STALE"
        FAILED=1
    fi
fi

# ── 范围 E: 依赖模块反向引用 ──
for DEP in natsx kafkax redisx taosx postgresx clickhousex ossx; do
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

echo ""
if [ "$FAILED" -eq 1 ]; then
    echo "--- DRIFT DETECTED: 请将以上过时引用更新为 v$NEW_VERSION 后重新提交 ---"
    exit 1
else
    echo "--- PASS: 所有引用均已更新为 v$NEW_VERSION ---"
    exit 0
fi
