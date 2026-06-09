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
    MATRIX_ROWS=0
    MAPPED=0
    MATRIX_MISSING_REQUIRED=0
    MATRIX_INVALID_RELATION=0
    MATRIX_INVALID_STATUS=0
    MATRIX_VERIFIED_WITHOUT_EVIDENCE=0
    MATRIX_DROPPED_WITHOUT_REASON=0

    while IFS='=' read -r key value; do
        case "$key" in
            rows) MATRIX_ROWS="$value" ;;
            terminal) MAPPED="$value" ;;
            missing_required) MATRIX_MISSING_REQUIRED="$value" ;;
            invalid_relation) MATRIX_INVALID_RELATION="$value" ;;
            invalid_status) MATRIX_INVALID_STATUS="$value" ;;
            verified_without_evidence) MATRIX_VERIFIED_WITHOUT_EVIDENCE="$value" ;;
            dropped_without_reason) MATRIX_DROPPED_WITHOUT_REASON="$value" ;;
        esac
    done < <(python3 - "$MATRIX_FILE" <<'PY'
import re
import sys

path = sys.argv[1]
required = [
    "source_id",
    "target_id",
    "relation",
    "status",
    "evidence_id",
    "gate_id",
    "owner",
    "updated_at",
]
non_empty = {"source_id", "target_id", "relation", "status", "gate_id", "owner", "updated_at"}
relations = {
    "decomposes_to",
    "contains",
    "accepted_by",
    "planned_by",
    "implemented_by",
    "prompted_by",
    "verified_by",
    "evidenced_by",
}
statuses = {"Unmapped", "Mapped", "Linked", "Verified", "Dropped", "Drifted", "Stale", "Blocked", "Changed"}


def clean(value: str) -> str:
    value = value.split("#", 1)[0].strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        value = value[1:-1]
    return value.strip()


rows = []
current = None
for raw_line in open(path, encoding="utf-8"):
    start = re.match(r"^\s*-\s+(source_id|goal_id):\s*(.*)$", raw_line)
    if start:
        if current is not None:
            rows.append(current)
        current = {"source_id": clean(start.group(2))}
        continue
    if current is None:
        continue
    match = re.match(r"^\s+([A-Za-z_]+):\s*(.*)\s*$", raw_line)
    if match:
        current[match.group(1)] = clean(match.group(2))
if current is not None:
    rows.append(current)

missing_required = 0
invalid_relation = 0
invalid_status = 0
verified_without_evidence = 0
dropped_without_reason = 0
terminal = 0

for row in rows:
    if any(name not in row for name in required):
        missing_required += 1
    elif any(row.get(name, "") == "" for name in non_empty):
        missing_required += 1

    relation = row.get("relation", "")
    if relation and relation not in relations:
        invalid_relation += 1

    status = row.get("status", "")
    if status and status not in statuses:
        invalid_status += 1
    if status in {"Verified", "Dropped"}:
        terminal += 1
    if status == "Verified" and row.get("evidence_id", "") == "":
        verified_without_evidence += 1
    if status == "Dropped" and row.get("drop_reason", "") == "":
        dropped_without_reason += 1

print(f"rows={len(rows)}")
print(f"terminal={terminal}")
print(f"missing_required={missing_required}")
print(f"invalid_relation={invalid_relation}")
print(f"invalid_status={invalid_status}")
print(f"verified_without_evidence={verified_without_evidence}")
print(f"dropped_without_reason={dropped_without_reason}")
PY
)

    if [ "$MATRIX_ROWS" -gt 0 ]; then
        MATRIX_COVERAGE=$((MAPPED * 100 / MATRIX_ROWS))
        if [ "$MATRIX_COVERAGE" -ge 95 ]; then
            pass "Matrix 完成率 ${MATRIX_COVERAGE}% (${MAPPED}/${MATRIX_ROWS})"
        else
            fail "Matrix 完成率 ${MATRIX_COVERAGE}% (${MAPPED}/${MATRIX_ROWS})"
        fi

        if [ "$MATRIX_MISSING_REQUIRED" -gt 0 ]; then
            fail "Matrix 有 ${MATRIX_MISSING_REQUIRED} 条 edge 缺少必填字段或必填值"
        fi
        if [ "$MATRIX_INVALID_RELATION" -gt 0 ]; then
            fail "Matrix 有 ${MATRIX_INVALID_RELATION} 条 edge 使用非法 relation"
        fi
        if [ "$MATRIX_INVALID_STATUS" -gt 0 ]; then
            fail "Matrix 有 ${MATRIX_INVALID_STATUS} 条 edge 使用非法 status"
        fi
        if [ "$MATRIX_VERIFIED_WITHOUT_EVIDENCE" -gt 0 ]; then
            fail "Matrix 有 ${MATRIX_VERIFIED_WITHOUT_EVIDENCE} 条 Verified edge 缺少 evidence_id"
        fi
        if [ "$MATRIX_DROPPED_WITHOUT_REASON" -gt 0 ]; then
            fail "Matrix 有 ${MATRIX_DROPPED_WITHOUT_REASON} 条 Dropped edge 缺少非空 drop_reason"
        fi
    else
        warn "Matrix 文件为空或未发现 source_id/goal_id edge"
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
