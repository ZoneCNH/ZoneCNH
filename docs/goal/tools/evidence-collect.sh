#!/usr/bin/env bash
# evidence-collect.sh — Evidence 自动收集脚本
# 必填字段对齐 docs/goal/schema/evidence.schema.yaml (§Part A: evidence_file.required_fields)
# 输出 Evidence ID 格式: EVID-<test_id>-NNN
# 用法: ./docs/goal/tools/evidence-collect.sh <task-id> <spec-id> <acceptance-criteria-id> <test-id> [goal-id]

set -euo pipefail

TASK_ID="${1:?用法: $0 <task-id> <spec-id> <acceptance-criteria-id> <test-id> [goal-id]}"
SPEC_ID="${2:?用法: $0 <task-id> <spec-id> <acceptance-criteria-id> <test-id> [goal-id]}"
AC_ID="${3:?用法: $0 <task-id> <spec-id> <acceptance-criteria-id> <test-id> [goal-id]}"
TEST_ID="${4:?用法: $0 <task-id> <spec-id> <acceptance-criteria-id> <test-id> [goal-id]}"
GOAL_ID="${5:-GOAL-AUTO}"
DATE=$(date +%Y-%m-%d)
EVID_ID="EVID-${TEST_ID}-001"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
EVIDENCE_ROOT="${GOAL_EVIDENCE_DIR:-$ROOT/.config/goal/evidence}"
EVIDENCE_FILE="$EVIDENCE_ROOT/$DATE/$TASK_ID/$EVID_ID.md"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

echo "收集 Evidence: $EVID_ID"
echo "Task: $TASK_ID"
echo "Spec: $SPEC_ID"
echo "Acceptance Criteria: $AC_ID"
echo "Test: $TEST_ID"
echo "Goal: $GOAL_ID"
echo "日期: $DATE"
echo ""

# --- 文件变更 ---
echo "=== 收集文件变更 ==="
CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null || echo "(无法获取 git diff)")
ADDED=$(git diff --diff-filter=A --name-only HEAD~1 2>/dev/null | wc -l || echo 0)
MODIFIED=$(git diff --diff-filter=M --name-only HEAD~1 2>/dev/null | wc -l || echo 0)
DELETED=$(git diff --diff-filter=D --name-only HEAD~1 2>/dev/null | wc -l || echo 0)

# --- Diff 摘要 ---
echo "=== 收集 Diff 摘要 ==="
DIFF_STAT=$(git diff --stat HEAD~1 2>/dev/null || echo "(无法获取)")

# --- 测试结果 ---
echo "=== 运行测试 ==="
TEST_RESULT=""
TEST_STATUS="PARTIAL"

# 尝试 Go 测试
if [ -f "go.mod" ]; then
    TEST_RESULT=$(go test ./... 2>&1 | tail -20 || true)
    if echo "$TEST_RESULT" | grep -q "^ok"; then
        TEST_STATUS="PASS"
    elif echo "$TEST_RESULT" | grep -q "^FAIL"; then
        TEST_STATUS="FAIL"
    fi
fi

# 尝试 Node 测试
if [ -f "package.json" ] && [ "$TEST_STATUS" = "PARTIAL" ]; then
    TEST_RESULT=$(npm test 2>&1 | tail -20 || true)
    if echo "$TEST_RESULT" | grep -q "passing"; then
        TEST_STATUS="PASS"
    elif echo "$TEST_RESULT" | grep -q "failing"; then
        TEST_STATUS="FAIL"
    fi
fi

# 尝试 Python 测试
if { [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; } && [ "$TEST_STATUS" = "PARTIAL" ]; then
    TEST_RESULT=$(python -m pytest 2>&1 | tail -20 || true)
    if echo "$TEST_RESULT" | grep -q "passed"; then
        TEST_STATUS="PASS"
    elif echo "$TEST_RESULT" | grep -q "failed"; then
        TEST_STATUS="FAIL"
    fi
fi

# --- 生成 Evidence 文件 ---
cat > "$EVIDENCE_FILE" << EOF
# Evidence

## 基本信息

- **Evidence ID**: $EVID_ID
- **Acceptance Criteria ID**: $AC_ID
- **Test ID**: $TEST_ID
- **Task ID**: $TASK_ID
- **Spec ID**: $SPEC_ID
- **Goal ID**: $GOAL_ID
- **Date**: $DATE
- **Status**: $TEST_STATUS
- **Files Changed**: see section below
- **Commands Run**: see section below

## 文件变更

### 变更统计

- 新增: $ADDED 文件
- 修改: $MODIFIED 文件
- 删除: $DELETED 文件

### 变更清单

\`\`\`
$CHANGED_FILES
\`\`\`

## Diff 摘要

\`\`\`
$DIFF_STAT
\`\`\`

## 测试结果

### 状态: $TEST_STATUS

\`\`\`
$TEST_RESULT
\`\`\`

## 命令记录

\`\`\`bash
git diff --name-only HEAD~1
git diff --stat HEAD~1
# 测试命令根据项目类型自动选择
\`\`\`

## 需求证明

<!-- TODO: 核对此 Evidence 对应的 Acceptance Criteria 是否完全满足 -->

- [ ] $AC_ID: <!-- 填入验收标准 -->

## 已知限制

<!-- TODO: 填入已知限制 -->

## 风险

<!-- TODO: 填入风险 -->

## 回滚方案

<!-- TODO: 填入回滚方案 -->
EOF

echo ""
echo "Evidence 已生成: $EVIDENCE_FILE"
echo ""
echo "后续步骤:"
echo "  1. 检查并补充 TODO 项"
echo "  2. 确认 Status 是否准确"
echo "  3. 补充需求证明和回滚方案"
