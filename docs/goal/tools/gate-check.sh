#!/usr/bin/env bash
# gate-check.sh — Gate 制品就绪检查脚本
# 检查 Matrix 覆盖率、Evidence 字段完整性、测试覆盖率；不替代四源 Gate arbiter。
# 用法: ./docs/goal/tools/gate-check.sh [项目根目录]

set -euo pipefail

ROOT="${1:-.}"
CONFIG_GOAL_DIR="${GOAL_CONFIG_DIR:-$ROOT/.config/goal}"
DOC_GOAL_DIR="${DOC_GOAL_DIR:-$ROOT/docs/goal}"
REGISTRY_DIR="${GOAL_REGISTRY_DIR:-$CONFIG_GOAL_DIR/registry}"
EVIDENCE_DIR="${GOAL_EVIDENCE_DIR:-$CONFIG_GOAL_DIR/evidence}"
MATRIX_FILE="${GOAL_MATRIX_FILE:-$CONFIG_GOAL_DIR/matrix/matrix.yaml}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

pass() { echo -e "${GREEN}✓ PASS${NC}: $1"; ((PASS += 1)); }
fail() { echo -e "${RED}✗ FAIL${NC}: $1"; ((FAIL += 1)); }
warn() { echo -e "${YELLOW}⚠ WARN${NC}: $1"; ((WARN += 1)); }

echo "=========================================="
echo "  Goal 驱动交付 — Gate 制品就绪检查"
echo "=========================================="
echo ""

# --- G5: Task Gate ---
echo "--- G5: Task Gate ---"
if [ -f "$REGISTRY_DIR/tasks.yaml" ]; then
    TOTAL=$(grep -cE "^[[:space:]-]*task_id:" "$REGISTRY_DIR/tasks.yaml" 2>/dev/null || echo 0)
    WITH_DOD=$(grep -c "dod:" "$REGISTRY_DIR/tasks.yaml" 2>/dev/null || echo 0)
    if [ "$TOTAL" -gt 0 ]; then
        COVERAGE=$((WITH_DOD * 100 / TOTAL))
        if [ "$COVERAGE" -ge 90 ]; then
            pass "Task DoD 覆盖率 ${COVERAGE}% (${WITH_DOD}/${TOTAL})"
        elif [ "$COVERAGE" -ge 50 ]; then
            warn "Task DoD 覆盖率 ${COVERAGE}% (${WITH_DOD}/${TOTAL}) — 建议补充"
        else
            fail "Task DoD 覆盖率 ${COVERAGE}% (${WITH_DOD}/${TOTAL}) — 严重不足"
        fi
    else
        warn "未找到 Task 记录"
    fi
else
    fail "Task Registry 不存在: $REGISTRY_DIR/tasks.yaml"
fi
echo ""

# --- G7: Test Gate ---
echo "--- G7: Test Gate ---"
if [ -f "$REGISTRY_DIR/tasks.yaml" ]; then
    WITH_EVIDENCE=$(grep -c "evidence:" "$REGISTRY_DIR/tasks.yaml" 2>/dev/null || echo 0)
    if [ "$TOTAL" -gt 0 ]; then
        EVIDENCE_COVERAGE=$((WITH_EVIDENCE * 100 / TOTAL))
        if [ "$EVIDENCE_COVERAGE" -ge 90 ]; then
            pass "Evidence 覆盖率 ${EVIDENCE_COVERAGE}% (${WITH_EVIDENCE}/${TOTAL})"
        elif [ "$EVIDENCE_COVERAGE" -ge 50 ]; then
            warn "Evidence 覆盖率 ${EVIDENCE_COVERAGE}% (${WITH_EVIDENCE}/${TOTAL})"
        else
            fail "Evidence 覆盖率 ${EVIDENCE_COVERAGE}% (${WITH_EVIDENCE}/${TOTAL})"
        fi
    fi
fi

# 检查测试文件是否存在
TEST_COUNT=$(find "$ROOT" -type f \( -name "*_test.go" -o -name "*.test.ts" -o -name "*.spec.ts" -o -name "test_*.py" \) 2>/dev/null | wc -l)
if [ "$TEST_COUNT" -gt 0 ]; then
    pass "发现 ${TEST_COUNT} 个测试文件"
else
    warn "未发现测试文件"
fi
echo ""

# --- G8: Evidence Gate ---
echo "--- G8: Evidence Gate ---"
if [ -d "$EVIDENCE_DIR" ]; then
    EVIDENCE_FILES=$(find "$EVIDENCE_DIR" -type f -name "EVID-*.md" 2>/dev/null | wc -l)
    if [ "$EVIDENCE_FILES" -gt 0 ]; then
        pass "发现 ${EVIDENCE_FILES} 份 Evidence 文件"

        # 检查 Evidence 必须字段
        MISSING_FIELDS=0
        for f in $(find "$EVIDENCE_DIR" -type f -name "EVID-*.md" 2>/dev/null); do
            for field in "Evidence ID" "Acceptance Criteria ID" "Test ID" "Task ID" "Spec ID" "Goal ID" "Date" "Status" "Files Changed" "Commands Run"; do
                if ! grep -qi "$field" "$f" 2>/dev/null; then
                    warn "$f 缺少字段: $field"
                    ((MISSING_FIELDS += 1))
                fi
            done
        done
        if [ "$MISSING_FIELDS" -eq 0 ]; then
            pass "所有 Evidence 文件字段完整"
        fi
    else
        fail "Evidence 目录存在但无文件"
    fi
else
    fail "Evidence 目录不存在: $EVIDENCE_DIR"
fi
echo ""

# --- Matrix 覆盖率 ---
echo "--- Matrix 覆盖率 ---"
if [ -f "$MATRIX_FILE" ]; then
    MATRIX_ROWS=$(grep -cE "^[[:space:]]*-[[:space:]]*goal_id:" "$MATRIX_FILE" 2>/dev/null || true)
    MAPPED=$(grep -c "status:.*\(Verified\|Dropped\)" "$MATRIX_FILE" 2>/dev/null || true)
    if [ "$MATRIX_ROWS" -gt 0 ]; then
        MATRIX_COVERAGE=$((MAPPED * 100 / MATRIX_ROWS))
        if [ "$MATRIX_COVERAGE" -ge 95 ]; then
            pass "Matrix 完成率 ${MATRIX_COVERAGE}% (${MAPPED}/${MATRIX_ROWS})"
        else
            fail "Matrix 完成率 ${MATRIX_COVERAGE}% (${MAPPED}/${MATRIX_ROWS})"
        fi

        DROPPED_WITHOUT_REASON=$(python3 - "$MATRIX_FILE" <<'PY'
import re
import sys

rows = []
current = None
for line in open(sys.argv[1], encoding="utf-8"):
    if re.match(r"^\s*-\s+goal_id:", line):
        if current is not None:
            rows.append(current)
        current = {}
        continue
    if current is None:
        continue
    match = re.match(r"^\s+([A-Za-z_]+):\s*(.*)\s*$", line)
    if match:
        value = match.group(2).strip().strip('"').strip("'")
        current[match.group(1)] = value
if current is not None:
    rows.append(current)

print(sum(1 for row in rows if row.get("status") == "Dropped" and not row.get("drop_reason")))
PY
)
        if [ "$DROPPED_WITHOUT_REASON" -gt 0 ]; then
            fail "Matrix 有 ${DROPPED_WITHOUT_REASON} 个 Dropped 行缺少非空 drop_reason"
        fi
    else
        warn "Matrix 文件为空或格式无法解析"
    fi
else
    fail "Matrix 文件不存在: $MATRIX_FILE"
fi
echo ""

# --- 孤儿检查 ---
echo "--- 孤儿检查 ---"
if [ -f "$REGISTRY_DIR/tasks.yaml" ]; then
    TASKS_WITH_GOAL=$(grep -cE "^[[:space:]]*goal_id:" "$REGISTRY_DIR/tasks.yaml" 2>/dev/null || echo 0)
    if [ "$TOTAL" -gt 0 ] && [ "$TASKS_WITH_GOAL" -lt "$TOTAL" ]; then
        ORPHAN_COUNT=$((TOTAL - TASKS_WITH_GOAL))
        fail "发现 ${ORPHAN_COUNT} 个无 Goal 来源的孤儿 Task"
    elif [ "$TOTAL" -gt 0 ]; then
        pass "无孤儿 Task"
    fi
fi
echo ""

# --- 总结 ---
echo "=========================================="
echo "  结果: PASS=${PASS}  FAIL=${FAIL}  WARN=${WARN}"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}存在阻塞问题，需修复后才能进入下一阶段。${NC}"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}存在风险项，建议修复。${NC}"
    exit 0
else
    echo -e "${GREEN}全部通过。${NC}"
    exit 0
fi
