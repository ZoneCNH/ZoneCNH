# Goal 驱动交付 — 可执行工具

本目录包含 Goal 体系的自动化检查和生成工具。

## 工具列表

| 工具                                       | 语言     | 功能                                                              |
| ------------------------------------------ | -------- | ----------------------------------------------------------------- |
| [goal-delivery.sh](goal-delivery.sh)       | Bash     | 端到端交付编排：init、goal、spec、design、plan、tasks、prompt、matrix、evidence、status、check、dashboard |
| [goal-workflow.sh](goal-workflow.sh)       | Bash     | 统一工作流入口：preflight、validate、gate、ci、release             |
| [gate-check.sh](gate-check.sh)             | Bash     | Gate 制品就绪检查：Matrix 终态覆盖率、Evidence 字段、测试覆盖、孤儿检查 |
| [goal-validate.py](goal-validate.py)       | Python 3 | Goal 控制面一致性验证：runtime root、Matrix、Gate、Risk、CI 合约 |
| [matrix-gen.py](matrix-gen.py)             | Python 3 | Matrix 生成与更新：从 Spec/Tasks 自动生成 Traceability Matrix     |
| [evidence-collect.sh](evidence-collect.sh) | Bash     | Evidence 收集：从 Git diff 和测试结果自动生成 Evidence 文件       |
| [lint-goal.sh](lint-goal.sh)               | Bash     | Lint 规则检查：Goal/Spec/Matrix/Prompt 的自动化规则验证           |
| [rule-drift-check.py](rule-drift-check.py) | Python 3 | 规则漂移检查：扫描旧路径、旧状态、旧 Gate/CI 命名和旧 ID 示例     |
| [self-test.sh](self-test.sh)               | Bash     | 工具链自测：执行正向基线与负向 fixture，验证工具不会静默放行错误  |
| [.github/ci/goal-release-gate.sh](../../../.github/ci/goal-release-gate.sh) | Bash/Python | 发布硬阻断：strict validator、G10、release-blocking 风险、Evidence、Goal CI 合约 |

## 使用方式

### 统一工作流入口

```bash
bash docs/goal/tools/goal-workflow.sh preflight
bash docs/goal/tools/goal-workflow.sh validate
bash docs/goal/tools/goal-workflow.sh gate
bash docs/goal/tools/goal-workflow.sh ci
bash docs/goal/tools/goal-workflow.sh release
```

`goal-workflow.sh` 是 `docs/goal` 的默认执行入口；直接调用底层脚本只用于调试单个检查器。

### 端到端交付编排

```bash
# 初始化项目结构和配置中心
bash docs/goal/tools/goal-delivery.sh init

# 按管线顺序创建制品
bash docs/goal/tools/goal-delivery.sh goal --title "订单 CSV 导出"
bash docs/goal/tools/goal-delivery.sh spec --goal-id GOAL-20260609-001
bash docs/goal/tools/goal-delivery.sh design --spec-id SPEC-feature-v1
bash docs/goal/tools/goal-delivery.sh plan --goal-id GOAL-20260609-001
bash docs/goal/tools/goal-delivery.sh tasks --plan-id PLAN-GOAL-20260609-001-v1
bash docs/goal/tools/goal-delivery.sh prompt --task-id TASK-GOAL-20260609-001-001
bash docs/goal/tools/goal-delivery.sh evidence --task-id TASK-GOAL-20260609-001-001

# 运行 Gate 检查
bash docs/goal/tools/goal-delivery.sh check --gate G1
bash docs/goal/tools/goal-delivery.sh check        # 全量 G0-G11

# 查看状态和看板
bash docs/goal/tools/goal-delivery.sh status
bash docs/goal/tools/goal-delivery.sh dashboard
```

`goal-delivery.sh` 覆盖 Goal→Spec→Design→Plan→Tasks→Prompt→Code→Test→Review→Release→Retrospective 全 11 层管线的制品创建和 Gate 检查。与 `goal-workflow.sh` 互补：后者负责验证/检查，前者负责编排/创建。

支持三种复杂度模式（通过 `--mode` 参数）：

| 模式 | 适用场景 | 流程 |
| ---- | -------- | ---- |
| `lite` | CL0/CL1 文档/配置变更 | Goal→Plan→Tasks→Code→Test→Evidence→Review |
| `standard` | CL2 功能开发 | 全流程 + Matrix + Risk + Evidence |
| `full` | CL3+ 架构变更 | 全流程 + ADR + Human Approval + Rollback |

| 命令 | 执行内容 | 使用场景 |
| ---- | -------- | -------- |
| `preflight` | Python 编译、Shell 语法、规则漂移、Goal 文档 lint | 修改 `docs/goal` 或工具脚本后的最快反馈 |
| `validate` | `preflight` + strict 控制面验证 + Matrix check-only | PR 前的默认本地验证 |
| `gate` | `validate` + Gate 制品就绪检查 | 已有 `.config/goal` 运行制品时的合入前门禁 |
| `ci` | `validate` + 工具链自测 + 有运行制品时自动 Gate 检查 | CI workflow 的聚合入口 |
| `release` | `gate` + `.github/ci/goal-release-gate.sh` | tag/release 前硬阻断；通过时会写 `release/manifest/goal-release-gate.json` |
| `self-test` | 仅运行工具链 fixture 自测 | 调试工具链自身 |

可选参数：

```bash
bash docs/goal/tools/goal-workflow.sh validate --root . --mode strict --format text
```

### Goal 控制面验证

```bash
# 审计模式：报告 ERROR/WARN，但即使存在 ERROR 也返回 0，适合人工盘点或迁移期间观察
python3 docs/goal/tools/goal-validate.py --root . --mode audit --format text

# 严格模式：存在 ERROR 时返回非零，适合 CI 强门禁
python3 docs/goal/tools/goal-validate.py --root . --mode strict --format json

# 只检查部分区域
python3 docs/goal/tools/goal-validate.py --root . --only gate,risk,consistency
```

`goal-validate.py` 是单文件、标准库实现。它不修复制品，只把当前控制面是否可发布说清楚：

- runtime/cache 输出根必须是 `.config/cache/`，不得继续使用 `.config/goal/runtime|cache|logs`。
- Matrix 行必须使用 canonical edge 字段：`source_id`、`target_id`、`relation`、`status`、`evidence_id`、`gate_id`、`owner`、`updated_at`。
- Gate 必须覆盖 `G0`-`G11`，每个 `gate_id` 只能出现一次；状态/裁决枚举必须是 `PASS|PASS_WITH_RISK|FAIL|BLOCKED`，不得再出现 `PENDING`。
- `PASS_WITH_RISK` 必须有结构化风险元数据，且 `G6`、`G10` 不允许风险通过。
- Risk Registry 的 `risk_id` 必须唯一，并使用 `RISK-GOAL-YYYYMMDD-NNN-NNN` 格式。
- 打开的 `release_blocking` 风险必须进入 Risk Registry；存在这类风险时，`G10`、`G11`、Pipeline、Release 状态不得伪装为完成/发布。
- GitHub workflow 中不得保留旧字段或旧枚举，例如 `requirement_id`、`evidence_ids`、`PENDING`；result verdict 必须包含 `BLOCKED`，并且必须定义 `goal-validator` 独立 job、在 `.config/goal/schema/rules.yaml` 的 `ci.required_jobs` 中列出它、调用 `goal-validate.py --mode strict`。

### Release 发布硬阻断

```bash
bash .github/ci/goal-release-gate.sh
```

`goal-release-gate.sh` 是 tag/release workflow 的硬门禁。它先运行 `goal-validate.py --mode strict`，然后继续检查：

- `G10` 的 gate 状态和 `result.verdict` 必须都是 `PASS`。
- 不得存在打开的 `release_blocking` 风险，来源包括 Gate 元数据和 Risk Registry。
- 必须存在至少一个 `.config/goal/evidence/**/*.md` Evidence 包。
- Goal CI 必须定义 `goal-validator` job，并且 `.config/goal/schema/rules.yaml` 的 `ci.required_jobs` 必须要求 `goal-validator`。

只有全部通过时，脚本才会写出 `release/manifest/goal-release-gate.json`。当前控制面如果仍处于 `G10 BLOCKED`、有打开的发布阻断风险或缺失 Evidence，脚本应非零退出；这是正确的发布阻断结果。

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

### 工具链自测

```bash
./docs/goal/tools/self-test.sh
```

`self-test.sh` 在临时目录中构造 fixture，不修改仓库制品；它先运行真实控制面的正向基线，再验证负例会被对应工具以非零退出拒绝。

## 负例 fixture 覆盖契约（GDR-FIXTURE-01）

当前工具链以真实 Goal 控制面、脚本自检和临时负例 fixture 作为基线。新增 fixture 必须保持以下覆盖契约，不引入非标准库依赖：

| Fixture 类别 | 目标工具 | 期望结果 | 验收点 |
| --- | --- | --- | --- |
| 旧工作流状态或旧路径字面量 | `rule-drift-check.py --root <fixture-root>` | 非零退出 | 报出 stale literal / path drift，不能静默通过 |
| 占位或格式错误的追溯 ID | `lint-goal.sh <fixture-docs>` 与 `matrix-gen.py --check-only --matrix <fixture-matrix>` | 非零退出 | 指向具体文件或 Matrix edge |
| Evidence 缺失或字段不完整 | `gate-check.sh <fixture-root>` 与 `rule-drift-check.py --root <fixture-root>` | 非零退出 | 报出缺失 Evidence 或必填字段 |
| Matrix orphan / 非终态 / 非法 relation | `matrix-gen.py --check-only --matrix <fixture-matrix>` | 非零退出 | 覆盖率、relation/status 或 orphan 类错误可定位 |
| Gate 结果与规则不一致 | `gate-check.sh <fixture-root>` | 非零退出 | `FAIL>0`，且不把风险降级为通过 |
| 控制面发布状态不一致 | `goal-validate.py --root <fixture-root> --mode strict` | 非零退出 | runtime root、Matrix 字段、Gate 枚举、Risk Registry、G10/G11、Pipeline/Release、CI 合约错误可定位 |
| Release gate 硬阻断 | `.github/ci/goal-release-gate.sh <fixture-root>` | 非零退出 | G10 未 PASS、打开 release_blocking 风险、Evidence 缺失、Goal CI 合约漂移都不能发布 |

本轮已落地的自测覆盖：

1. 正例基线：shell 语法、Python 编译、Goal lint、rule drift、Goal validator strict、Matrix check-only、Gate check 均通过。
2. Matrix 负例：非法 relation 与缺失 evidence 必须被 `matrix-gen.py --check-only` 拒绝。
3. Rule drift 负例：临时复制的工具树注入旧可执行规则字面量后必须被 `rule-drift-check.py --quiet` 拒绝。
4. Gate 负例：只有 Task 与 Matrix、缺少 Evidence 文件时必须被 `gate-check.sh` 拒绝。
5. Goal validator 正例：临时构造的 canonical 控制面必须在 `strict` 模式下通过。
6. Goal validator 负例：缺失 `.config/cache/` ignore、旧 `.config/goal/runtime` 根、旧 Matrix 字段、`PENDING` Gate、Risk Registry 漏登、风险 ID 格式错误、Gate/Risk ID 重复、G10/G11 顺序错误、Pipeline/Release 伪完成、CI 未调用 strict validator 和 CI 旧合约都必须被拒绝。
7. Release gate 正负例：G10 已通过且有 Evidence 时允许写出发布 gate manifest；打开发布阻断风险、Evidence 缺失或 Goal CI 合约漂移时必须拒绝。

## CI 集成

在 CI 流水线中添加：

```yaml
# .github/workflows/goal-lint.yml
name: Goal Lint
on:
  workflow_call:
  push:
  pull_request:
jobs:
  goal-validator:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Goal Workflow Validate
        run: bash docs/goal/tools/goal-workflow.sh validate
  lint:
    runs-on: ubuntu-latest
    needs: goal-validator
    steps:
      - uses: actions/checkout@v4
      - name: Goal Workflow CI
        run: bash docs/goal/tools/goal-workflow.sh ci
```

发布 workflow 必须先复用 `.github/workflows/goal-ci.yml`，再执行 `bash .github/ci/goal-release-gate.sh`；只有 gate 产出 `release/manifest/goal-release-gate.json` 后，才允许生成 release manifest 和创建 GitHub Release。

## 依赖

- `goal-delivery.sh`: bash, grep, find, git, awk
- `goal-workflow.sh`: bash, Python 3.10+, grep, find, git
- `gate-check.sh`: bash, grep, find
- `goal-validate.py`: Python 3.10+
- `matrix-gen.py`: Python 3.10+
- `evidence-collect.sh`: bash, git
- `lint-goal.sh`: bash, grep, find
- `rule-drift-check.py`: Python 3.10+
- `self-test.sh`: bash, Python 3.10+, grep, find, git
