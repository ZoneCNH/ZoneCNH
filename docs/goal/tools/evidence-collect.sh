#!/usr/bin/env bash
# evidence-collect.sh — Evidence 自动收集脚本
# 从 Git diff 和测试结果自动生成 Evidence 文件
# 用法: ./docs/goal/tools/evidence-collect.sh <task-id> [goal-id]

set -euo pipefail

TASK_ID="${1:?用法: $0 <task-id> [goal-id]}"
GOAL_ID="${2:-GOAL-AUTO}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d)
EVID_ID="EVID-${TASK_ID}-${TIMESTAMP}-001"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
EVIDENCE_DIR="$ROOT/.agent/evidence/$DATE/$TASK_ID"
EVIDENCE_FILE="$EVIDENCE_DIR/evidence.md"

mkdir -p "$EVIDENCE_DIR"

echo "收集 Evidence: $EVID_ID"
echo "Task: $TASK_ID"
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
TEST_STATUS="UNKNOWN"

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
if [ -f "package.json" ] && [ "$TEST_STATUS" = "UNKNOWN" ]; then
    TEST_RESULT=$(npm test 2>&1 | tail -20 || true)
    if echo "$TEST_RESULT" | grep -q "passing"; then
        TEST_STATUS="PASS"
    elif echo "$TEST_RESULT" | grep -q "failing"; then
        TEST_STATUS="FAIL"
    fi
fi

# 尝试 Python 测试
if { [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; } && [ "$TEST_STATUS" = "UNKNOWN" ]; then
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
- **Task ID**: $TASK_ID
- **Goal ID**: $GOAL_ID
- **Date**: $DATE
- **Status**: $TEST_STATUS

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

<!-- TODO: 填入此 Evidence 对应的 Acceptance Criteria -->

- [ ] AC-xxx: <!-- 填入验收标准 -->

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
