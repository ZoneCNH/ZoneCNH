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

error() { echo -e "${RED}ERROR${NC}: $1"; ((ERRORS += 1)); }
warn()  { echo -e "${YELLOW}WARN${NC}:  $1"; ((WARNINGS += 1)); }
ok()    { echo -e "${GREEN}OK${NC}:    $1"; }

echo "=========================================="
echo "  Goal 体系 Lint 检查"
echo "=========================================="
echo ""

# 收集所有 .md 文件
if [ -d "$TARGET" ]; then
    FILES=$(find "$TARGET" -name "*.md" -type f 2>/dev/null)
elif [ -f "$TARGET" ]; then
    FILES="$TARGET"
else
    echo "目标不存在: $TARGET"
    exit 1
fi

for f in $FILES; do
    CONTENT=$(cat "$f")
    BASENAME=$(basename "$f")

    # === Goal Lint 规则 ===
    if echo "$BASENAME" | grep -qi "goal\|spec\|task"; then

        # GL-001: Goal 必须有衡量指标
        if echo "$CONTENT" | grep -qi "goal"; then
            if ! echo "$CONTENT" | grep -qE "[0-9]+(%|秒|分钟|小时|ms|个|次|条|行)"; then
                if echo "$CONTENT" | grep -qi "成功\|完成\|达到\|目标"; then
                    warn "[$BASENAME] GL-001: Goal 描述成功但缺少量化指标"
                fi
            fi
        fi

        # GL-002: 禁止模糊词
        FUZZY_WORDS=("优化" "提升" "改善" "完善" "加强" "尽量" "尽可能" "适时" "酌情")
        for word in "${FUZZY_WORDS[@]}"; do
            if echo "$CONTENT" | grep -q "$word"; then
                if ! echo "$CONTENT" | grep -A1 "$word" | grep -qE "[0-9]+"; then
                    warn "[$BASENAME] GL-002: 发现模糊词「$word」且无量化说明"
                fi
            fi
        done

        # GL-003: Goal 不应包含实现细节
        IMPL_WORDS=("数据库" "Redis" "PostgreSQL" "API" "接口" "前端" "后端" "微服务" "SDK")
        for word in "${IMPL_WORDS[@]}"; do
            if echo "$CONTENT" | grep -q "$word"; then
                if echo "$CONTENT" | grep -B2 "$word" | grep -qi "goal"; then
                    warn "[$BASENAME] GL-003: Goal 包含实现细节「$word」，应改为结果描述"
                fi
            fi
        done
    fi

    # === Spec Lint 规则 ===
    if echo "$BASENAME" | grep -qi "spec"; then

        # SL-001: Spec 必须有 Acceptance Criteria
        if ! echo "$CONTENT" | grep -qi "acceptance.criteria\|验收标准\|AC-"; then
            error "[$BASENAME] SL-001: Spec 缺少 Acceptance Criteria"
        fi

        # SL-002: Spec 必须有边界场景
        if ! echo "$CONTENT" | grep -qi "edge.case\|边界\|异常\|错误处理\|error.handling"; then
            warn "[$BASENAME] SL-002: Spec 缺少边界场景或错误处理"
        fi

        # SL-003: Requirement 必须可测试（兼容旧 FR-*，优先使用 REQ-SPEC-*）
        REQ_COUNT=$(echo "$CONTENT" | grep -cE "REQ-SPEC-|FR-" || echo 0)
        AC_COUNT=$(echo "$CONTENT" | grep -cE "AC-|test_|测试" || echo 0)
        if [ "$REQ_COUNT" -gt 0 ] && [ "$AC_COUNT" -eq 0 ]; then
            error "[$BASENAME] SL-003: 有 $REQ_COUNT 个 Requirement 但无测试覆盖"
        fi
    fi

    # === Matrix Lint 规则 ===
    if echo "$BASENAME" | grep -qi "matrix\|traceability"; then

        # ML-001: Matrix 不允许空 Goal ID
        EMPTY_GOAL=$(echo "$CONTENT" | grep -c 'goal_id:\s*""' || echo 0)
        if [ "$EMPTY_GOAL" -gt 0 ]; then
            error "[$BASENAME] ML-001: Matrix 有 $EMPTY_GOAL 行缺少 Goal ID"
        fi

        # ML-002: Matrix 不允许空 Task ID（非 Dropped 状态）
        EMPTY_TASK=$(echo "$CONTENT" | grep -c 'task_id:\s*""' || echo 0)
        DROPPED=$(echo "$CONTENT" | grep -c "status:.*Dropped" || echo 0)
        if [ "$EMPTY_TASK" -gt "$DROPPED" ]; then
            warn "[$BASENAME] ML-002: Matrix 有 $EMPTY_TASK 行缺少 Task ID（非 Dropped）"
        fi

        # ML-003: 每个 AC 必须有 Test Case
        EMPTY_TEST=$(echo "$CONTENT" | grep -c 'test_case:\s*""' || echo 0)
        if [ "$EMPTY_TEST" -gt 0 ]; then
            warn "[$BASENAME] ML-003: Matrix 有 $EMPTY_TEST 行缺少 Test Case"
        fi
    fi

    # === Prompt Lint 规则 ===
    if echo "$BASENAME" | grep -qi "prompt"; then

        # PL-001: Prompt 必须有 Constraints
        if ! echo "$CONTENT" | grep -qi "constraint\|限制\|禁止\|do.not"; then
            warn "[$BASENAME] PL-001: Prompt 缺少 Constraints/限制条件"
        fi

        # PL-002: Prompt 必须有明确输出格式
        if ! echo "$CONTENT" | grep -qi "output\|输出\|格式\|format"; then
            warn "[$BASENAME] PL-002: Prompt 缺少输出格式说明"
        fi
    fi

    # === 通用检查 ===
    if echo "$CONTENT" | grep -qE "[0-9]{5,}.*@(163|qq|gmail)\.(com|cn)"; then
        error "[$BASENAME] 安全: 发现疑似真实邮箱地址"
    fi
    if echo "$CONTENT" | grep -qE "api[_-]?key.*=.*[A-Za-z0-9]{20,}"; then
        error "[$BASENAME] 安全: 发现疑似 API Key"
    fi

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
