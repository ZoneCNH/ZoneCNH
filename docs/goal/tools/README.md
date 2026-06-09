# Goal 驱动交付 — 可执行工具

本目录包含 Goal 体系的自动化检查和生成工具。

## 工具列表

| 工具                                       | 语言     | 功能                                                              |
| ------------------------------------------ | -------- | ----------------------------------------------------------------- |
| [gate-check.sh](gate-check.sh)             | Bash     | Gate 制品就绪检查：Matrix 终态覆盖率、Evidence 字段、测试覆盖、孤儿检查 |
| [matrix-gen.py](matrix-gen.py)             | Python 3 | Matrix 生成与更新：从 Spec/Tasks 自动生成 Traceability Matrix     |
| [evidence-collect.sh](evidence-collect.sh) | Bash     | Evidence 收集：从 Git diff 和测试结果自动生成 Evidence 文件       |
| [lint-goal.sh](lint-goal.sh)               | Bash     | Lint 规则检查：Goal/Spec/Matrix/Prompt 的自动化规则验证           |
| [rule-drift-check.py](rule-drift-check.py) | Python 3 | 规则漂移检查：扫描旧路径、旧状态、旧 Gate/CI 命名和旧 ID 示例     |

## 使用方式

### Gate 制品就绪检查

```bash
# 检查项目 docs/goal 与 .config/goal 目录下的完整性
./docs/goal/tools/gate-check.sh .

# 检查指定目录
./docs/goal/tools/gate-check.sh /path/to/project
```

`gate-check.sh` 检查 Goal 运行制品是否具备进入人工/agent Gate 裁决的基本条件；它不替代四源 Gate arbiter，也不输出全局 98 分门禁结论。

检查需要项目已经生成运行制品：

- `.config/goal/registry/tasks.yaml`
- `.config/goal/matrix/matrix.yaml`
- `.config/goal/evidence/`

仅维护规则文档、尚未落地具体 Goal 的仓库，应先运行 `lint-goal.sh`、`rule-drift-check.py --quiet`、`bash -n` 和 `python3 -m py_compile`；不要把 `gate-check.sh .` 作为无运行制品仓库的必过检查。

检查内容：

- G5 Task Gate：Task DoD 覆盖率
- G7 Test Gate：测试文件存在性、Evidence 覆盖率
- G8 Evidence Gate：Evidence 文件完整性、必须字段
- Matrix 覆盖率：`Verified` / `Dropped` 终态覆盖率，目标不低于 95%
- Dropped 行约束：每个 `Dropped` 行必须有 `drop_reason`
- 孤儿检查：无 Goal 来源的 Task

### Matrix 生成

```bash
# 从 Spec 和 Tasks 生成 Matrix
python3 docs/goal/tools/matrix-gen.py \
  --spec-dir module \
  --task-dir docs/goal/tasks \
  --output .config/goal/matrix/matrix.yaml \
  --goal-id GOAL-20260608-001

# 仅检查现有 Matrix
python3 docs/goal/tools/matrix-gen.py \
  --check-only \
  --matrix .config/goal/matrix/matrix.yaml
```

### Evidence 收集

```bash
# 为指定 Task / Spec / AC / Test 收集 Evidence
./docs/goal/tools/evidence-collect.sh \
  TASK-GOAL-20260608-001-001 \
  SPEC-order-export-v1 \
  AC-REQ-SPEC-order-export-v1-001-001 \
  TEST-TASK-GOAL-20260608-001-001-001 \
  GOAL-20260608-001
```

自动生成：

- 文件变更清单（git diff）
- Diff 统计摘要
- 测试运行结果（自动检测 Go/Node/Python）
- Evidence Markdown 模板（包含 Goal / Spec / Task / AC / Test 追溯字段）

### Lint 检查

```bash
# 检查单个文件
./docs/goal/tools/lint-goal.sh docs/goal/02-goal-standard.md

# 检查整个目录
./docs/goal/tools/lint-goal.sh docs/goal/
```

检查规则：

- G-LINT-001: Goal 必须有衡量指标
- G-LINT-002: 禁止无量化的模糊词
- G-LINT-003: Goal 不应包含实现细节
- S-LINT-001: Spec 必须有 Acceptance Criteria
- S-LINT-002: Spec 必须有边界场景
- S-LINT-003: Requirement 必须有测试覆盖
- M-LINT-001: Matrix 不允许空 Goal ID
- M-LINT-002: Matrix 不允许空 Task ID
- M-LINT-003: 每个 AC 必须有 Test Case
- P-LINT-001: Prompt 必须有 Constraints
- P-LINT-002: Prompt 必须有输出格式

### Rule Drift 检查

```bash
# 扫描 docs/goal 与 .config/goal/schema 中的旧路径、旧状态、旧 ID 示例和旧 Gate/CI 命名
python3 docs/goal/tools/rule-drift-check.py --root . --quiet
```

## 负例 fixture 覆盖契约（GDR-FIXTURE-01）

当前工具链以真实 Goal 控制面和脚本自检作为基线。独立负例 fixture 套件落地前，任何新增 fixture 必须保持以下覆盖契约，不引入非标准库依赖：

| Fixture 类别 | 目标工具 | 期望结果 | 验收点 |
| --- | --- | --- | --- |
| 旧工作流状态或旧路径字面量 | `rule-drift-check.py --root <fixture-root>` | 非零退出 | 报出 stale literal / path drift，不能静默通过 |
| 占位或格式错误的追溯 ID | `lint-goal.sh <fixture-docs>` 与 `matrix-gen.py --check-only --matrix <fixture-matrix>` | 非零退出 | 指向具体文件或 Matrix edge |
| Evidence 缺失或字段不完整 | `gate-check.sh <fixture-root>` 与 `rule-drift-check.py --root <fixture-root>` | 非零退出 | 报出缺失 Evidence 或必填字段 |
| Matrix orphan / 非终态 / 非法 relation | `matrix-gen.py --check-only --matrix <fixture-matrix>` | 非零退出 | 覆盖率、relation/status 或 orphan 类错误可定位 |
| Gate 结果与规则不一致 | `gate-check.sh <fixture-root>` | 非零退出 | `FAIL>0`，且不把风险降级为通过 |

关闭 `GDR-FIXTURE-01` 的最低门槛：

1. 新增正例 fixture 和至少一组负例 fixture，放在工具目录下的专用 fixture 子目录或同等隔离路径。
2. 每个负例必须在对应工具上返回非零，并在输出中包含可定位的字段、文件或 edge 信息。
3. 正例仍通过 `lint-goal.sh`、`rule-drift-check.py`、`matrix-gen.py --check-only`、`gate-check.sh` 的基线组合。
4. fixture 验收命令必须写回 `docs/report/goal/ISSUE-LEDGER.md` 和验证报告后，才能把该项从 deferred 改为 fixed。

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
      - name: Lint Goal
        run: ./docs/goal/tools/lint-goal.sh docs/goal/
      - name: Compile Goal Tools
        run: python3 -m py_compile docs/goal/tools/matrix-gen.py docs/goal/tools/rule-drift-check.py
      - name: Rule Drift Check
        run: python3 docs/goal/tools/rule-drift-check.py --root . --quiet
      - name: Gate Check
        run: |
          if [ -f .config/goal/registry/tasks.yaml ]; then
            ./docs/goal/tools/gate-check.sh .
          else
            echo "skip gate-check: no goal runtime artifacts"
          fi
```

## 依赖

- `gate-check.sh`: bash, grep, find
- `matrix-gen.py`: Python 3.9+
- `evidence-collect.sh`: bash, git
- `lint-goal.sh`: bash, grep, find
- `rule-drift-check.py`: Python 3.9+
