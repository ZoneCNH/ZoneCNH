# Goal 驱动交付 — 可执行工具

本目录包含 Goal 体系的自动化检查和生成工具。

## 工具列表

| 工具                                       | 语言     | 功能                                                              |
| ------------------------------------------ | -------- | ----------------------------------------------------------------- |
| [gate-check.sh](gate-check.sh)             | Bash     | Gate 完整性检查：Matrix 覆盖率、Evidence 字段、测试覆盖、孤儿检查 |
| [matrix-gen.py](matrix-gen.py)             | Python 3 | Matrix 生成与更新：从 Spec/Tasks 自动生成 Traceability Matrix     |
| [evidence-collect.sh](evidence-collect.sh) | Bash     | Evidence 收集：从 Git diff 和测试结果自动生成 Evidence 文件       |
| [lint-goal.sh](lint-goal.sh)               | Bash     | Lint 规则检查：Goal/Spec/Matrix/Prompt 的自动化规则验证           |

## 使用方式

### Gate 检查

```bash
# 检查项目 .agent/ 目录下的完整性
./docs/goal/tools/gate-check.sh .

# 检查指定目录
./docs/goal/tools/gate-check.sh /path/to/project
```

检查内容：

- G5 Task Gate：Task DoD 覆盖率
- G7 Test Gate：测试文件存在性、Evidence 覆盖率
- G8 Evidence Gate：Evidence 文件完整性、必须字段
- Matrix 覆盖率：已完成行占比
- 孤儿检查：无 Goal 来源的 Task

### Matrix 生成

```bash
# 从 Spec 和 Tasks 生成 Matrix
python3 docs/goal/tools/matrix-gen.py \
  --spec-dir .agent/specs \
  --task-dir .agent/tasks \
  --output .agent/matrix.yaml \
  --goal-id GOAL-20260608-001

# 仅检查现有 Matrix
python3 docs/goal/tools/matrix-gen.py \
  --check-only \
  --matrix .agent/matrix.yaml
```

### Evidence 收集

```bash
# 为指定 Task 收集 Evidence
./docs/goal/tools/evidence-collect.sh TASK-GOAL-001-001 GOAL-20260608-001
```

自动生成：

- 文件变更清单（git diff）
- Diff 统计摘要
- 测试运行结果（自动检测 Go/Node/Python）
- Evidence YAML 模板

### Lint 检查

```bash
# 检查单个文件
./docs/goal/tools/lint-goal.sh docs/goal/02-goal-standard.md

# 检查整个目录
./docs/goal/tools/lint-goal.sh .agent/
```

检查规则：

- GL-001: Goal 必须有衡量指标
- GL-002: 禁止无量化的模糊词
- GL-003: Goal 不应包含实现细节
- SL-001: Spec 必须有 Acceptance Criteria
- SL-002: Spec 必须有边界场景
- SL-003: FR 必须有测试覆盖
- ML-001: Matrix 不允许空 Goal ID
- ML-002: Matrix 不允许空 Task ID
- ML-003: 每个 AC 必须有 Test Case
- PL-001: Prompt 必须有 Constraints
- PL-002: Prompt 必须有输出格式

## CI 集成

在 CI 流水线中添加：

```yaml
# .github/workflows/goal-lint.yml
name: Goal Lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Gate Check
        run: ./docs/goal/tools/gate-check.sh .
      - name: Lint Goal
        run: ./docs/goal/tools/lint-goal.sh .agent/
```

## 依赖

- `gate-check.sh`: bash, grep, find
- `matrix-gen.py`: Python 3.9+
- `evidence-collect.sh`: bash, git
- `lint-goal.sh`: bash, grep, find
