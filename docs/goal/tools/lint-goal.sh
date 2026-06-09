#!/usr/bin/env bash
# lint-goal.sh — Goal/Spec/Matrix Lint 规则检查
# 执行 docs/goal/10-lint-rules.md 中定义的自动化检查
# 用法: ./docs/goal/tools/lint-goal.sh <目标目录或文件>

set -euo pipefail

TARGET="${1:?用法: $0 <目标目录或文件>}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
LINT_GROUPS=("G" "S" "M" "P")

declare -A RULE_TOTAL=(
    ["G"]=7
    ["S"]=8
    ["M"]=8
    ["P"]=10
)
declare -A RULE_AUTOMATED=(
    ["G"]=3
    ["S"]=3
    ["M"]=8
    ["P"]=2
)
declare -A RULE_FINDINGS=(
    ["G"]=0
    ["S"]=0
    ["M"]=0
    ["P"]=0
)
declare -A RULE_SEEN=()

error() { echo -e "${RED}ERROR${NC}: $1"; ((ERRORS += 1)); }
warn()  { echo -e "${YELLOW}WARN${NC}:  $1"; ((WARNINGS += 1)); }
ok()    { echo -e "${GREEN}OK${NC}:    $1"; }
mark_rule() { RULE_SEEN["$1:$2"]=1; }
finding() { ((RULE_FINDINGS["$1"] += 1)); }

echo "=========================================="
echo "  Goal 体系 Lint 检查"
echo "=========================================="
echo ""

# 收集目标文档和配置文件
if [ -d "$TARGET" ]; then
    FILES=$(find "$TARGET" \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" \) -type f 2>/dev/null)
elif [ -f "$TARGET" ]; then
    FILES="$TARGET"
else
    echo "目标不存在: $TARGET"
    exit 1
fi

for f in $FILES; do
    BASENAME=$(basename "$f")

    # === Goal Lint 规则 ===
    if echo "$BASENAME" | grep -qi "goal\|spec\|task"; then

        # G-LINT-001: Goal 必须有衡量指标
        mark_rule "G" "G-LINT-001"
        if grep -qi "goal" "$f"; then
            if ! grep -qE "[0-9]+(%|秒|分钟|小时|ms|个|次|条|行)" "$f"; then
                if grep -qi "成功\|完成\|达到\|目标" "$f"; then
                    warn "[$BASENAME] G-LINT-001: Goal 描述成功但缺少量化指标"
                    finding "G"
                fi
            fi
        fi

        # G-LINT-002: 禁止模糊词
        mark_rule "G" "G-LINT-002"
        FUZZY_WORDS=("优化" "提升" "改善" "完善" "加强" "尽量" "尽可能" "适时" "酌情")
        for word in "${FUZZY_WORDS[@]}"; do
            if grep -q "$word" "$f"; then
                if ! grep -A1 "$word" "$f" | grep -qE "[0-9]+"; then
                    warn "[$BASENAME] G-LINT-002: 发现模糊词「$word」且无量化说明"
                    finding "G"
                fi
            fi
        done

        # G-LINT-003: Goal 不应包含实现细节
        mark_rule "G" "G-LINT-003"
        IMPL_WORDS=("数据库" "Redis" "PostgreSQL" "API" "接口" "前端" "后端" "微服务" "SDK")
        for word in "${IMPL_WORDS[@]}"; do
            if grep -q "$word" "$f"; then
                if grep -B2 "$word" "$f" | grep -qi "goal"; then
                    warn "[$BASENAME] G-LINT-003: Goal 包含实现细节「$word」，应改为结果描述"
                    finding "G"
                fi
            fi
        done
    fi

    # === Spec Lint 规则 ===
    if echo "$BASENAME" | grep -qi "spec"; then

        # S-LINT-001: Spec 必须有 Acceptance Criteria
        mark_rule "S" "S-LINT-001"
        if ! grep -qi "acceptance.criteria\|验收标准\|AC-" "$f"; then
            error "[$BASENAME] S-LINT-001: Spec 缺少 Acceptance Criteria"
            finding "S"
        fi

        # S-LINT-002: Spec 必须有边界场景
        mark_rule "S" "S-LINT-002"
        if ! grep -qi "edge.case\|边界\|异常\|错误处理\|error.handling" "$f"; then
            warn "[$BASENAME] S-LINT-002: Spec 缺少边界场景或错误处理"
            finding "S"
        fi

        # S-LINT-003: Requirement 必须可测试（兼容旧 FR-*，优先使用 REQ-SPEC-*）
        mark_rule "S" "S-LINT-003"
        REQ_COUNT=$(grep -cE "REQ-SPEC-|FR-" "$f" || true)
        AC_COUNT=$(grep -cE "AC-|test_|测试" "$f" || true)
        if [ "$REQ_COUNT" -gt 0 ] && [ "$AC_COUNT" -eq 0 ]; then
            error "[$BASENAME] S-LINT-003: 有 $REQ_COUNT 个 Requirement 但无测试覆盖"
            finding "S"
        fi
    fi

    # === Matrix Lint 规则 ===
    if echo "$BASENAME" | grep -qi "matrix\|traceability"; then
        for rule in M-LINT-001 M-LINT-002 M-LINT-003 M-LINT-004 M-LINT-005 M-LINT-006 M-LINT-007 M-LINT-008; do
            mark_rule "M" "$rule"
        done

        MATRIX_FINDINGS=$(python3 - "$f" <<'PY'
import re
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()

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
for raw_line in text.splitlines():
    start = re.match(r"^\s*-\s+(source_id|goal_id):\s*(.*)$", raw_line)
    if start:
        if current is not None:
            rows.append(current)
        current = {"source_id": clean(start.group(2))}
        continue
    if current is None:
        continue
    field = re.match(r"^\s+([A-Za-z_]+):\s*(.*)$", raw_line)
    if field:
        current[field.group(1)] = clean(field.group(2))
if current is not None:
    rows.append(current)


def emit(level: str, rule: str, message: str) -> None:
    print(f"{level}\t{rule}\t{message}")


if not rows:
    emit("ERROR", "M-LINT-008", "未发现以 source_id 或 goal_id 开始的 Matrix edge")

for idx, row in enumerate(rows, 1):
    missing = [name for name in required if name not in row]
    if missing:
        emit("ERROR", "M-LINT-001", f"edge {idx} 缺少字段: {', '.join(missing)}")

    empty_ids = [name for name in ("source_id", "target_id") if row.get(name, "") == ""]
    if empty_ids:
        emit("ERROR", "M-LINT-006", f"edge {idx} 空 ID 字段: {', '.join(empty_ids)}")

    empty_meta = [name for name in ("gate_id", "owner", "updated_at") if row.get(name, "") == ""]
    if empty_meta:
        emit("ERROR", "M-LINT-007", f"edge {idx} 空元数据字段: {', '.join(empty_meta)}")

    empty_required = [name for name in non_empty if name in row and row.get(name, "") == ""]
    if empty_required:
        emit("ERROR", "M-LINT-001", f"edge {idx} 必填字段为空: {', '.join(sorted(empty_required))}")

    relation = row.get("relation", "")
    if relation and relation not in relations:
        emit("ERROR", "M-LINT-002", f"edge {idx} 非法 relation: {relation}")

    status = row.get("status", "")
    if status and status not in statuses:
        emit("ERROR", "M-LINT-003", f"edge {idx} 非法 status: {status}")

    if status == "Verified" and row.get("evidence_id", "") == "":
        emit("ERROR", "M-LINT-004", f"edge {idx} Verified 缺少 evidence_id")

    if status == "Dropped" and row.get("drop_reason", "") == "":
        emit("ERROR", "M-LINT-005", f"edge {idx} Dropped 缺少 drop_reason")
PY
)
        if [ -n "$MATRIX_FINDINGS" ]; then
            while IFS=$'\t' read -r level rule message; do
                [ -z "$level" ] && continue
                if [ "$level" = "ERROR" ]; then
                    error "[$BASENAME] $rule: $message"
                else
                    warn "[$BASENAME] $rule: $message"
                fi
                finding "M"
            done <<< "$MATRIX_FINDINGS"
        fi
    fi

    # === Prompt Lint 规则 ===
    if echo "$BASENAME" | grep -qi "prompt"; then

        # P-LINT-001: Prompt 必须有 Constraints
        mark_rule "P" "P-LINT-001"
        if ! grep -qi "constraint\|限制\|禁止\|do.not" "$f"; then
            warn "[$BASENAME] P-LINT-001: Prompt 缺少 Constraints/限制条件"
            finding "P"
        fi

        # P-LINT-002: Prompt 必须有明确输出格式
        mark_rule "P" "P-LINT-002"
        if ! grep -qi "output\|输出\|格式\|format" "$f"; then
            warn "[$BASENAME] P-LINT-002: Prompt 缺少输出格式说明"
            finding "P"
        fi
    fi

    # === 通用检查 ===
    if grep -qE "[0-9]{5,}.*@(163|qq|gmail)\.(com|cn)" "$f"; then
        error "[$BASENAME] 安全: 发现疑似真实邮箱地址"
    fi
    if grep -qE "api[_-]?key.*=.*[A-Za-z0-9]{20,}" "$f"; then
        error "[$BASENAME] 安全: 发现疑似 API Key"
    fi

done

echo ""
echo "=========================================="
echo "  规则覆盖摘要"
echo "=========================================="
for group in "${LINT_GROUPS[@]}"; do
    CHECKED=0
    for key in "${!RULE_SEEN[@]}"; do
        if [[ "$key" == "$group:"* ]]; then
            ((CHECKED += 1))
        fi
    done
    TOTAL="${RULE_TOTAL[$group]:-0}"
    AUTOMATED="${RULE_AUTOMATED[$group]:-0}"
    FINDINGS="${RULE_FINDINGS[$group]:-0}"
    echo "${group}-LINT: automated=${AUTOMATED}/${TOTAL} checked_this_run=${CHECKED} findings=${FINDINGS}"
done

echo ""
echo "=========================================="
echo "  结果: ERRORS=${ERRORS}  WARNINGS=${WARNINGS}"
echo "=========================================="

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}存在错误，需修复。${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}存在警告，建议修复。${NC}"
    exit 0
else
    echo -e "${GREEN}全部通过。${NC}"
    exit 0
fi
