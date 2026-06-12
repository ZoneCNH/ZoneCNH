# Goal 体系程序化拆解报告

> **日期**: 2026-06-09
> **分析对象**: `docs/goal/` (28 文件, 5,929 行) + `.config/goal/` + `.claude/agents/goal-*.md`
> **方法**: 资产盘点 → 差距分析 → 五层架构设计 → 实现路线图
> **前置报告**: `docs/report/goal-entropy-reduction-analysis-20260609.md`

---

## 1. 现状资产盘点

### 1.1 已有程序化资产

Goal 体系并非纯文档 — 已有大量可执行基础设施：

| #   | 资产          | 路径                                  | 语言   | 行数  | 功能                                                                                                 |
| --- | ------------- | ------------------------------------- | ------ | ----- | ---------------------------------------------------------------------------------------------------- |
| T1  | Schema 规则   | `.config/goal/schema/rules.yaml`      | YAML   | 309   | ID 正则、状态枚举、Gate 定义、Matrix 字段契约                                                        |
| T2  | 验证器        | `docs/goal/tools/goal-validate.py`    | Python | 987   | 5 大检查域: runtime/matrix/gate/risk/consistency                                                     |
| T3  | 矩阵生成器    | `docs/goal/tools/matrix-gen.py`       | Python | 388   | 从 Spec/Task 目录生成 edge model + checker 模式                                                      |
| T4  | Lint 检查     | `docs/goal/tools/lint-goal.sh`        | Bash   | 304   | 4 组规则 (G/S/M/P), 含内嵌 Python 矩阵检查                                                           |
| T5  | Gate 检查     | `docs/goal/tools/gate-check.sh`       | Bash   | 278   | Matrix 覆盖率 + Evidence 字段 + 测试文件 + 孤儿检查                                                  |
| T6  | Evidence 收集 | `docs/goal/tools/evidence-collect.sh` | Bash   | 156   | Git diff + 测试运行 + 自动生成 Evidence Markdown                                                     |
| T7  | 规则漂移检测  | `docs/goal/tools/rule-drift-check.py` | Python | —     | 检测 SSOT 文件与 tools 间的词汇漂移                                                                  |
| T8  | 自测套件      | `docs/goal/tools/self-test.sh`        | Bash   | 433   | 18+ 测试用例, 覆盖 validator/matrix/gate/drift                                                       |
| T9  | CI 工作流     | `.github/workflows/goal-ci.yml`       | YAML   | —     | 目标状态: 10 个必须 job                                                                              |
| T10 | Agent 集群    | `.claude/agents/goal-*.md`            | MD     | 10 个 | goal-spec/matrix/planner/prompt-builder/evidence/reviewer/lint/governance/architect/context-recovery |

**数据目录结构** (`.config/goal/`):

```text
.config/goal/
├── schema/rules.yaml          # 机器可读规则投影 (309行)
├── registry/
│   ├── goals.yaml             # Goal 注册表
│   ├── tasks.yaml             # Task 注册表 (待建)
│   ├── issues.yaml            # Issue 注册表 (待建)
│   ├── releases.yaml          # Release 注册表 (待建)
│   ├── risks.yaml             # Risk 注册表 (待建)
│   └── decisions.yaml         # Decision 注册表 (待建)
├── matrix/matrix.yaml         # 追溯矩阵 (edge model, 261行)
├── gates/state.yaml           # Gate 状态 (397行, G0-G11)
├── pipeline/state.yaml        # Pipeline 状态 (267行, 完整状态历史)
├── evidence/                  # Evidence 文件 (待扩展)
├── prompts/                   # Prompt 文件 (待扩展)
└── runtime/                   # 运行时 (gitignored)
```

### 1.2 缺失的程序化层次

| #   | 缺失能力              | 当前替代方案                                      | 影响                       |
| --- | --------------------- | ------------------------------------------------- | -------------------------- |
| G1  | 统一 CLI 入口         | 各工具独立运行，需记住 6+ 个命令                  | 认知负担高，无法编排       |
| G2  | Pipeline 状态机引擎   | 人工编辑 `state.yaml`                             | 状态转换无约束，可跳过阶段 |
| G3  | Gate 自动仲裁器       | `gate-check.sh` 只做制品检查，不做 PASS/FAIL 判定 | Gate 结果靠人工填写        |
| G4  | Registry CRUD API     | 手动编辑 YAML                                     | 格式易错，无校验           |
| G5  | Agent 统一调度        | 10 个 Agent 各自独立                              | 无管线编排，需人工串联     |
| G6  | 可观测性仪表盘        | 手动查看各 YAML 文件                              | 无法快速了解全局状态       |
| G7  | Change Level 自动判定 | 人工判断 CL0-CL5                                  | 判断标准靠记忆             |
| G8  | Release Precheck      | 无自动化                                          | G10 阻塞条件靠人工检查     |

### 1.3 能力覆盖率评估

```text
Schema 层:    ████████████████████ 95%  (rules.yaml 完整)
Data 层:      ██████████████░░░░░░ 70%  (目录结构在, 部分 registry 缺失)
Engine 层:    ████████░░░░░░░░░░░░ 40%  (验证器强, 引擎弱)
Integration:  ██████░░░░░░░░░░░░░░ 30%  (CI 基础在, CLI/API 缺失)
Orchestrate:  ████░░░░░░░░░░░░░░░░ 20%  (Agent 在, 编排缺失)
```

---

## 2. 五层架构设计

### 2.1 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│                    L5: Orchestration 编排层                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │
│  │ Agent 调度器  │ │ CI/CD 集成   │ │ Dashboard / 报告生成器   │ │
│  └──────┬───────┘ └──────┬───────┘ └────────────┬─────────────┘ │
├─────────┼────────────────┼──────────────────────┼───────────────┤
│         │          L4: Integration 集成层        │               │
│  ┌──────┴───────┐ ┌──────┴───────┐ ┌────────────┴─────────────┐ │
│  │ goalctl CLI  │ │ REST API     │ │ Hook System              │ │
│  └──────┬───────┘ └──────┬───────┘ └────────────┬─────────────┘ │
├─────────┼────────────────┼──────────────────────┼───────────────┤
│         │          L3: Engine 引擎层             │               │
│  ┌──────┴───────┐ ┌──────┴───────┐ ┌────────────┴─────────────┐ │
│  │ Pipeline     │ │ Gate         │ │ Validator                │ │
│  │ StateMachine │ │ Arbiter      │ │ (goal-validate.py)       │ │
│  ├──────────────┤ ├──────────────┤ ├──────────────────────────┤ │
│  │ Matrix       │ │ Evidence     │ │ Registry                 │ │
│  │ Generator    │ │ Lifecycle    │ │ CRUD Engine              │ │
│  │ (matrix-gen) │ │ (evid-collect)│ │                          │ │
│  └──────┬───────┘ └──────┬───────┘ └────────────┬─────────────┘ │
├─────────┼────────────────┼──────────────────────┼───────────────┤
│         │          L2: Data 数据层               │               │
│  ┌──────┴───────┐ ┌──────┴───────┐ ┌────────────┴─────────────┐ │
│  │ Registry     │ │ Matrix       │ │ State Files              │ │
│  │ (6 YAML)     │ │ (edge model) │ │ (pipeline/gates/evidence)│ │
│  └──────┬───────┘ └──────┬───────┘ └────────────┬─────────────┘ │
├─────────┼────────────────┼──────────────────────┼───────────────┤
│         │          L1: Schema 模式层             │               │
│  ┌──────┴───────┐ ┌──────┴───────┐ ┌────────────┴─────────────┐ │
│  │ rules.yaml   │ │ ID Patterns  │ │ Status Enums             │ │
│  │ (SSOT)       │ │ (regex)      │ │ (YAML)                   │ │
│  └──────────────┘ └──────────────┘ └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 各层职责与接口

#### L1: Schema 模式层

**职责**: 定义所有 Goal 体系对象的结构、约束和枚举值。单一事实来源。

**SSOT 文件**: `.config/goal/schema/rules.yaml`

**对外接口**:

```python
# Schema 查询接口 (概念)
class SchemaRegistry:
    def get_id_pattern(object_type: str) -> re.Pattern
        # 返回 GOAL/SPEC/TASK/REQ/AC/TEST/EVID/PROMPT/RISK 的正则

    def get_valid_statuses(object_type: str) -> list[str]
        # 返回 goal/issue/release/risk/decision/matrix/gate/pipeline 的合法状态

    def get_required_fields(object_type: str) -> list[str]
        # 返回 canonical_goal_object / matrix_edge / evidence / gate 的必填字段

    def get_gate_definition(gate_id: str) -> dict
        # 返回 G0-G11 的阈值、类型、allow_pass_with_risk 等
```

**依赖**: 无（最底层）

#### L2: Data 数据层

**职责**: 持久化所有 Goal 状态为 YAML 文件。提供结构化读取。

**文件清单**:

| 数据集            | 路径                               | 写入者              | 读取者                     |
| ----------------- | ---------------------------------- | ------------------- | -------------------------- |
| Goal Registry     | `registry/goals.yaml`              | goal-spec           | 全部                       |
| Task Registry     | `registry/tasks.yaml`              | goal-planner        | goal-matrix, goal-evidence |
| Issue Registry    | `registry/issues.yaml`             | goal-governance     | 全部                       |
| Risk Registry     | `registry/risks.yaml`              | goal-reviewer       | goal-governance            |
| Release Registry  | `registry/releases.yaml`           | goal-planner        | goal-governance            |
| Decision Registry | `registry/decisions.yaml`          | goal-architect      | 全部                       |
| Matrix            | `matrix/matrix.yaml`               | goal-matrix         | goal-reviewer, goal-lint   |
| Pipeline State    | `pipeline/state.yaml`              | Pipeline Engine     | 全部                       |
| Gate State        | `gates/state.yaml`                 | Gate Arbiter        | 全部                       |
| Evidence          | `evidence/{date}/{task}/{evid}.md` | goal-evidence       | goal-reviewer              |
| Prompts           | `prompts/{task}/prompt.md`         | goal-prompt-builder | 编码 Agent                 |

**对外接口**:

```python
class DataStore:
    def read_registry(registry_type: str) -> list[dict]
    def write_registry(registry_type: str, entries: list[dict]) -> None
    def read_matrix() -> list[Edge]
    def write_matrix(edges: list[Edge]) -> None
    def read_pipeline_state(goal_id: str) -> PipelineState
    def write_pipeline_state(goal_id: str, state: PipelineState) -> None
    def read_gate_state() -> list[Gate]
    def write_gate_state(gates: list[Gate]) -> None
    def read_evidence(evidence_id: str) -> Evidence
    def write_evidence(evidence: Evidence) -> None
```

**依赖**: L1 (Schema)

#### L3: Engine 引擎层

**职责**: 核心业务逻辑。状态机推进、Gate 仲裁、验证、生成。

**3.1 Pipeline StateMachine**

```text
状态转换图 (来自 rules.yaml):

INIT → CONTEXT → GOAL → SPEC → DESIGN → PLAN → TASKS → PROMPT → CODE → TEST → REVIEW → RELEASE → DONE
                                                                                                      │
                                                                                              RETROSPECTIVE
```

```python
class PipelineStateMachine:
    TRANSITIONS = {
        "INIT":      ["CONTEXT"],
        "CONTEXT":   ["GOAL"],
        "GOAL":      ["SPEC"],
        "SPEC":      ["DESIGN"],
        "DESIGN":    ["PLAN"],
        "PLAN":      ["TASKS"],
        "TASKS":     ["PROMPT"],
        "PROMPT":    ["CODE"],
        "CODE":      ["TEST"],
        "TEST":      ["REVIEW"],
        "REVIEW":    ["RELEASE"],
        "RELEASE":   ["DONE", "RETROSPECTIVE"],
        "DONE":      [],
        "RETROSPECTIVE": ["DONE"],
    }

    def transition(goal_id: str, target_state: str) -> TransitionResult
        # 1. 校验 target_state 在 TRANSITIONS[current] 中
        # 2. 检查 Gate 前置条件 (该阶段的 Gate 必须 PASS)
        # 3. 更新 pipeline/state.yaml
        # 4. 记录 state_history
        # 5. 返回 TransitionResult(success, blockers)

    def get_blockers(goal_id: str) -> list[Blocker]
        # 返回阻止状态推进的所有因素
```

**3.2 Gate Arbiter**

```python
class GateArbiter:
    def evaluate(gate_id: str, goal_id: str) -> GateResult
        # 1. 读取 gate 定义 (阈值、类型、allow_pass_with_risk)
        # 2. 执行对应的 check 脚本/规则
        # 3. 计算 score
        # 4. 判定: PASS / PASS_WITH_RISK / FAIL / BLOCKED
        #    - PASS_WITH_RISK 需要 risk 元数据完整
        #    - G6/G10 不允许 PASS_WITH_RISK
        # 5. 写入 gates/state.yaml

    def get_pending_gates(goal_id: str) -> list[str]
        # 返回所有状态为 PENDING/BLOCKED 的 Gate

    def check_release_readiness(goal_id: str) -> ReleaseReadiness
        # 检查 G10 所有条件:
        # - G0-G9 全部 PASS 或 PASS_WITH_RISK
        # - 无 OPEN 的 release_blocking 风险
        # - Release Evidence 完整
```

**3.3 Validator (已有, 需封装)**

```python
class GoalValidator:
    # 封装 docs/goal/tools/goal-validate.py 的 5 大检查域
    def validate_runtime(root: str, mode: str) -> list[Finding]
    def validate_matrix(root: str) -> list[Finding]
    def validate_gates(root: str) -> list[Finding]
    def validate_risks(root: str) -> list[Finding]
    def validate_consistency(root: str) -> list[Finding]
    def validate_all(root: str, mode: str) -> ValidationReport
```

**3.4 Matrix Generator (已有, 需封装)**

```python
class MatrixGenerator:
    # 封装 docs/goal/tools/matrix-gen.py
    def generate(spec_dirs: list[str], task_dirs: list[str]) -> list[Edge]
    def check(matrix_path: str) -> CheckResult
```

**3.5 Evidence Lifecycle**

```python
class EvidenceManager:
    def collect(task_id: str, spec_id: str, ac_id: str, test_id: str) -> Evidence
        # 封装 evidence-collect.sh 逻辑
        # 1. 从 git diff 收集文件变更
        # 2. 运行测试收集结果
        # 3. 生成 Evidence Markdown
        # 4. 写入 evidence/{date}/{task}/

    def verify(evidence_id: str) -> bool
        # 检查 Evidence 文件存在且字段完整

    def get_missing_evidence(goal_id: str) -> list[str]
        # 返回 Matrix 中 Verified 但缺少 evidence_id 的 edge
```

**3.6 Registry CRUD Engine**

```python
class RegistryEngine:
    def create(registry_type: str, entry: dict) -> str  # 返回 ID
    def read(registry_type: str, entry_id: str) -> dict
    def update(registry_type: str, entry_id: str, patch: dict) -> dict
    def delete(registry_type: str, entry_id: str) -> bool
    def list(registry_type: str, filters: dict = None) -> list[dict]
    def validate_entry(registry_type: str, entry: dict) -> list[str]
```

**依赖**: L1 (Schema), L2 (Data)

#### L4: Integration 集成层

**职责**: 对外暴露统一接口。CLI、API、Hook。

**4.1 goalctl CLI**

```bash
# 统一入口: goalctl
goalctl goal create "标题" --priority P0 --owner zone
goalctl goal list --status Active
goalctl goal show GOAL-20260608-001

goalctl pipeline status GOAL-20260608-001
goalctl pipeline advance GOAL-20260608-001 --to SPEC
goalctl pipeline blockers GOAL-20260608-001

goalctl gate evaluate G2 --goal GOAL-20260608-001
goalctl gate status --goal GOAL-20260608-001
goalctl gate readiness --goal GOAL-20260608-001

goalctl matrix generate --spec-dir module/ --task-dir docs/goal/tasks/
goalctl matrix check
goalctl matrix coverage

goalctl evidence collect TASK-GOAL-20260608-001-001 SPEC-goal-system-v1 AC-001 TEST-001
goalctl evidence verify EVID-xxx

goalctl validate --mode strict --format text
goalctl lint docs/goal/
goalctl drift-check

goalctl risk list --status OPEN --release-blocking
goalctl risk close RISK-GOAL-20260608-001-001

goalctl report summary
goalctl report goal GOAL-xxx
goalctl report gate GOAL-xxx
```

**4.2 Hook System**

```yaml
# PreToolUse hooks
- gate-eval: Gate 评估前自动运行制品检查
- matrix-check: Matrix 写入前自动校验 edge 合法性
- registry-validate: Registry 写入前自动校验必填字段

# PostToolUse hooks
- state-sync: Pipeline 状态变更后自动更新关联文件
- evidence-remind: Task 完成后提醒收集 Evidence
- drift-detect: 规则文件变更后自动运行漂移检测

# CI hooks
- pre-merge: 合并前运行 full validation
- post-merge: 合并后更新 Pipeline 状态
```

**依赖**: L3 (Engine)

#### L5: Orchestration 编排层

**职责**: 协调多个 Agent 完成完整 Goal 生命周期。

**5.1 Agent 调度器**

```text
Agent 编排流程:

goal-spec ──→ goal-matrix ──→ goal-architect ──→ goal-planner ──→ goal-prompt-builder
    │              │                │                  │                  │
    ▼              ▼                ▼                  ▼                  ▼
 registry/     matrix/          design/            tasks/           prompts/
 goals.yaml   matrix.yaml      SPEC.md            tasks.yaml       prompt.md
    │              │                │                  │                  │
    └──────────────┴────────────────┴──────────────────┴──────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │  编码 Agent (executor/coder)   │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              goal-evidence    goal-reviewer    goal-lint
                    │               │               │
                    ▼               ▼               ▼
              evidence/        gates/state.yaml  lint report
                    │               │
                    └───────┬───────┘
                            ▼
                    goal-governance
                    (SSOT 一致性审计)
```

**5.2 CI/CD 管线**

```yaml
# .github/workflows/goal-ci.yml (目标状态)
jobs:
  validate-schema: # L1: rules.yaml 完整性
  validate-registry: # L2: Registry 格式校验
  validate-matrix: # L3: Matrix 覆盖率 + edge 合法性
  validate-gates: # L3: Gate 状态一致性
  validate-pipeline: # L3: Pipeline 状态合法性
  validate-evidence: # L3: Evidence 字段完整性
  validate-risk: # L3: Risk 关闭状态
  validate-consistency: # L3: 跨组件一致性
  lint-goal: # L3: Lint 规则
  gate-arbitration: # L3: Gate 自动仲裁
```

**依赖**: L4 (Integration)

### 2.3 层间依赖拓扑

```text
L5 Orchestration
  │
  ├──→ L4 Integration
  │      │
  │      ├──→ L3 Engine
  │      │      │
  │      │      ├──→ L1 Schema (rules.yaml)
  │      │      │
  │      │      └──→ L2 Data (YAML files)
  │      │             │
  │      │             └──→ L1 Schema (校验)
  │      │
  │      └──→ L1 Schema (CLI 参数校验)
  │
  └──→ L2 Data (Dashboard 读取)
```

**关键约束**: 上层只能调用下层，不能反向依赖。同层模块平级协作。

---

## 3. 关键设计决策

### ADR-001: 复用现有工具 vs 重写

**决策**: 封装复用，不重写。

**理由**:

- `goal-validate.py` (987行) 已覆盖 5 大检查域，逻辑成熟
- `matrix-gen.py` (388行) 已实现生成 + checker 双模式
- `self-test.sh` (433行) 已有 18+ 测试用例保障正确性
- 重写风险高、周期长，封装只需加薄层接口

**方案**: Python 包装层调用现有脚本，逐步将 Bash 逻辑迁移到 Python。

### ADR-002: Pipeline 引擎实现方式

**决策**: Python 状态机 + YAML 持久化。

**理由**:

- rules.yaml 已定义完整的状态枚举和转换规则
- Python 可直接解析 rules.yaml 作为状态机定义
- YAML 持久化与现有 `.config/goal/` 结构一致
- 不引入额外数据库依赖

**方案**:

```python
# 核心状态机定义从 rules.yaml 读取，不硬编码
import yaml

rules = yaml.safe_load(open(".config/goal/schema/rules.yaml"))
pipeline_states = rules["pipeline"]["states"]
transitions = rules["pipeline"]["transitions"]  # 需在 rules.yaml 中补充
```

### ADR-003: Gate 仲裁策略

**决策**: 分层仲裁 — 制品检查自动化，语义判定保留人工。

**理由**:

- Gate 分三类: Semantic (G1/G2/G3/G4/G9/G11), Executable (G5/G6/G7/G8), Hybrid (G0/G10)
- Executable Gate 的制品检查可完全自动化
- Semantic Gate 的语义判定需要人工或 AI Agent
- Hybrid Gate 混合两者

**方案**:

| Gate 类型                     | 制品检查 | 语义判定     | 仲裁者                       |
| ----------------------------- | -------- | ------------ | ---------------------------- |
| Executable (G5/G6/G7/G8)      | 自动     | —            | Gate Arbiter                 |
| Semantic (G1/G2/G3/G4/G9/G11) | 自动     | Agent        | goal-reviewer Agent          |
| Hybrid (G0/G10)               | 自动     | Agent + 规则 | goal-reviewer + Gate Arbiter |

### ADR-004: CLI 技术选型

**决策**: Python Click/Typer + 薄 Bash 包装。

**理由**:

- 现有工具以 Python 和 Bash 为主
- Click/Typer 提供子命令、参数校验、帮助文档
- Bash 包装 (`goalctl.sh`) 提供零依赖入口
- 可逐步将 Bash 工具迁移到 Python

### ADR-005: Agent 编排模式

**决策**: 管线式编排 + Gate 门控。

**理由**:

- Goal 生命周期是线性管线 (Goal → Spec → ... → Release)
- 每个阶段结束后有 Gate 检查
- Gate 通过才能进入下一阶段
- 与 `docs/goal/22-delivery-os.md` 的阶段模型一致

**方案**:

```text
Phase 1: goal-spec      → G1 Gate →
Phase 2: goal-matrix    → G2 Gate →
Phase 3: goal-architect  → G3 Gate →
Phase 4: goal-planner    → G4 Gate →
Phase 5: goal-prompt-builder → G5 Gate →
Phase 6: executor        → G6 Gate →
Phase 7: goal-evidence   → G7 Gate →
Phase 8: goal-reviewer   → G8/G9 Gate →
Phase 9: goal-governance → G10 Gate → Release
```

---

## 4. 实现路线图

### Phase 1: Schema 权威 + 引擎封装 (1-2 天)

**目标**: 将现有工具封装为统一 Python 引擎。

| 任务                                                | 依赖     | 产出                     |
| --------------------------------------------------- | -------- | ------------------------ |
| 1.1 在 rules.yaml 补充 pipeline transitions 定义    | —        | rules.yaml 更新          |
| 1.2 创建 `goal_engine/` Python 包骨架               | —        | 包结构                   |
| 1.3 封装 goal-validate.py → `GoalValidator` 类      | 1.2      | goal_engine/validator.py |
| 1.4 封装 matrix-gen.py → `MatrixGenerator` 类       | 1.2      | goal_engine/matrix.py    |
| 1.5 封装 evidence-collect.sh → `EvidenceManager` 类 | 1.2      | goal_engine/evidence.py  |
| 1.6 实现 `PipelineStateMachine`                     | 1.1, 1.2 | goal_engine/pipeline.py  |
| 1.7 实现 `RegistryEngine` CRUD                      | 1.2      | goal_engine/registry.py  |
| 1.8 运行 self-test.sh 验证封装正确性                | 1.3-1.7  | 测试通过                 |

**验收标准**:

- `python -c "from goal_engine import PipelineStateMachine"` 无报错
- 现有 self-test.sh 全部通过
- Pipeline 状态机可执行 INIT → CONTEXT 转换

### Phase 2: Gate 仲裁 + CLI (2-3 天)

**目标**: 实现 Gate 自动仲裁和统一 CLI。

| 任务                                | 依赖     | 产出                 |
| ----------------------------------- | -------- | -------------------- |
| 2.1 实现 `GateArbiter`              | Phase 1  | goal_engine/gate.py  |
| 2.2 实现 Executable Gate 自动判定   | 2.1      | G5/G6/G7/G8 自动仲裁 |
| 2.3 实现 `goalctl` CLI 骨架 (Typer) | Phase 1  | goal_engine/cli.py   |
| 2.4 实现 `goalctl validate` 子命令  | 2.3, 1.3 | 可运行               |
| 2.5 实现 `goalctl pipeline` 子命令  | 2.3, 1.6 | 可运行               |
| 2.6 实现 `goalctl gate` 子命令      | 2.3, 2.1 | 可运行               |
| 2.7 实现 `goalctl matrix` 子命令    | 2.3, 1.4 | 可运行               |
| 2.8 创建 `goalctl.sh` Bash 入口     | 2.3      | 零依赖入口           |

**验收标准**:

- `goalctl validate --mode strict` 运行成功
- `goalctl pipeline status GOAL-xxx` 显示正确状态
- `goalctl gate evaluate G5` 自动判定 PASS/FAIL

### Phase 3: Agent 编排 + Registry (2-3 天)

**目标**: 实现 Agent 统一调度和 Registry 完整 CRUD。

| 任务                                       | 依赖     | 产出                              |
| ------------------------------------------ | -------- | --------------------------------- |
| 3.1 实现完整 Registry CRUD (6 个 registry) | Phase 1  | registry.py 扩展                  |
| 3.2 实现 `goalctl goal/task/risk` 子命令   | 3.1, 2.3 | CLI 扩展                          |
| 3.3 设计 Agent 编排协议                    | Phase 2  | agent_orchestrator.py             |
| 3.4 实现管线式 Agent 调度                  | 3.3      | 编排逻辑                          |
| 3.5 实现 Change Level 自动判定             | Phase 1  | change_level.py                   |
| 3.6 实现 Release Precheck                  | 2.1      | release_precheck.py               |
| 3.7 补建缺失 Registry 文件                 | 3.1      | tasks/issues/risks/decisions.yaml |

**验收标准**:

- `goalctl goal create "标题"` 创建并写入 registry
- `goalctl risk list --release-blocking` 正确过滤
- Agent 编排可执行完整管线

### Phase 4: 可观测性 + CI 深度集成 (1-2 天)

**目标**: 全局仪表盘和完整 CI 管线。

| 任务                                    | 依赖       | 产出            |
| --------------------------------------- | ---------- | --------------- |
| 4.1 实现 `goalctl report summary`       | Phase 2, 3 | 全局仪表盘      |
| 4.2 实现 `goalctl report goal GOAL-xxx` | Phase 2, 3 | 单 Goal 报告    |
| 4.3 更新 goal-ci.yml 为 10 job 完整管线 | Phase 2    | CI 更新         |
| 4.4 实现 PreToolUse/PostToolUse hooks   | Phase 2    | hooks 配置      |
| 4.5 实现规则漂移自动检测 (CI 集成)      | 已有工具   | CI job          |
| 4.6 文档更新                            | 全部       | docs/goal/ 更新 |

**验收标准**:

- `goalctl report summary` 输出全局状态
- CI 10 个 job 全部通过
- Hook 系统在编辑后自动运行验证

---

## 5. 目录结构规划

```text
goal_engine/                    # Python 包 (新建)
├── __init__.py
├── schema.py                   # L1: Schema 查询
├── data/                       # L2: Data 层
│   ├── __init__.py
│   ├── store.py                # 统一数据读写
│   └── models.py               # Pydantic 模型
├── engine/                     # L3: Engine 层
│   ├── __init__.py
│   ├── pipeline.py             # Pipeline 状态机
│   ├── gate.py                 # Gate 仲裁器
│   ├── validator.py            # 封装 goal-validate.py
│   ├── matrix.py               # 封装 matrix-gen.py
│   ├── evidence.py             # 封装 evidence-collect.sh
│   ├── registry.py             # Registry CRUD
│   └── change_level.py         # Change Level 判定
├── cli/                        # L4: CLI
│   ├── __init__.py
│   ├── main.py                 # goalctl 入口
│   ├── goal.py                 # goal 子命令
│   ├── pipeline.py             # pipeline 子命令
│   ├── gate.py                 # gate 子命令
│   ├── matrix.py               # matrix 子命令
│   ├── evidence.py             # evidence 子命令
│   ├── validate.py             # validate 子命令
│   ├── risk.py                 # risk 子命令
│   └── report.py               # report 子命令
└── orchestrator/               # L5: 编排层
    ├── __init__.py
    ├── agent_scheduler.py      # Agent 调度
    └── ci_integration.py       # CI 集成

docs/goal/tools/                # 现有工具 (保留, 逐步迁移)
├── goal-validate.py            # → 封装到 engine/validator.py
├── matrix-gen.py               # → 封装到 engine/matrix.py
├── evidence-collect.sh         # → 封装到 engine/evidence.py
├── gate-check.sh               # → 封装到 engine/gate.py
├── lint-goal.sh                # → 保留为独立 lint 工具
├── rule-drift-check.py         # → 集成到 CI
└── self-test.sh                # → 扩展为 goal_engine 测试套件
```

---

## 6. 与现有体系的关系

### 6.1 文档与代码的边界

| 内容            | 位置                                             | 角色             |
| --------------- | ------------------------------------------------ | ---------------- |
| 为什么这样做    | `docs/goal/00-24*.md`                            | 理念、原则、愿景 |
| 做什么 (规则)   | `.config/goal/schema/rules.yaml`                 | 机器可读 SSOT    |
| 怎么做 (工具)   | `docs/goal/tools/*.py/*.sh` → `goal_engine/`     | 可执行代码       |
| 做了什么 (状态) | `.config/goal/{registry,matrix,gates,pipeline}/` | 运行时数据       |

### 6.2 Agent 与引擎的协作

```text
人类/CI 触发
    │
    ▼
goalctl CLI ──→ Engine 层 ──→ Data 层
    │                │
    │                ▼
    │         Agent 编排器
    │                │
    │    ┌───────────┼───────────┐
    │    ▼           ▼           ▼
    │  goal-spec  goal-matrix  goal-reviewer ...
    │    │           │           │
    │    └───────────┼───────────┘
    │                │
    └────────────────┘
         通过 Engine 层读写 Data 层
```

**关键原则**: Agent 不直接操作 YAML 文件，全部通过 Engine 层接口。Engine 层保证数据合法性。

### 6.3 渐进式迁移策略

```text
阶段 A: 共存 (Phase 1-2)
  - goal_engine/ 封装现有工具
  - 旧工具继续可用
  - self-test.sh 验证兼容性

阶段 B: 替代 (Phase 3)
  - goalctl 成为主要入口
  - 旧工具标记为 deprecated
  - Agent 切换到 Engine 接口

阶段 C: 清理 (Phase 4)
  - 移除旧 Bash 工具 (保留 lint-goal.sh)
  - goal_engine/ 成为唯一执行层
  - CI 完全基于 goal_engine
```

---

## 7. 风险与缓解

| 风险                       | 概率 | 影响 | 缓解                                       |
| -------------------------- | ---- | ---- | ------------------------------------------ |
| rules.yaml 与引擎不同步    | 中   | 高   | rules.yaml 是 SSOT，引擎从中读取，不硬编码 |
| 旧工具迁移到引擎后行为差异 | 中   | 中   | self-test.sh 覆盖 18+ 用例，迁移前后对比   |
| Agent 编排复杂度超预期     | 低   | 高   | 先实现管线式，不做 DAG 调度                |
| Python 包依赖管理          | 低   | 低   | 最小依赖: PyYAML, Click/Typer, Pydantic    |

---

## 8. Go 实现可行性分析

### 9.1 决策：Go 实现

**结论**: 使用 Go 实现 Goal 程序化引擎，替代原计划的 Python 方案。

**核心理由**: FoundationX 生态全栈 Go (kernel, x.go, xlib-standard, xlibgate)，Goal 引擎应作为一等公民而非 Python 异构依赖。

### 9.2 生态适配评估

| 维度                   | 现状                                                         | Go 实现优势                                       |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------------- |
| **生态一致性**         | FoundationX 全栈 Go (kernel, x.go, xlib-standard, xlibgate)  | goalctl 成为一等公民，不引入 Python/Bash 异构依赖 |
| **xlibgate 对口**      | xlibgate 已做 import 边界、go.mod、release evidence 机器门禁 | Gate Arbiter 直接复用 xlibgate 的门禁模式         |
| **xlib-standard 对口** | 已承担 Harness Gate + Evidence Runtime                       | Engine 层可作为 xlib-standard 的扩展              |
| **CLI 交付**           | 当前 6 个独立脚本                                            | 单二进制 `goalctl`，零依赖部署                    |
| **类型安全**           | rules.yaml 的 schema 靠人工遵守                              | Go struct + enum 在编译期强制                     |
| **并发验证**           | self-test.sh 串行执行                                        | goroutine 并行跑 Gate 检查、Matrix 校验           |
| **CI 集成**            | goal-ci.yml 调 Python/Bash                                   | `go run ./cmd/goalctl validate` 统一入口          |

### 9.3 实现边界

Go 只实现 Engine + CLI + CI 层，Agent 层保持 Claude Agent 不变：

```text
Go 实现范围 (Engine + CLI + CI):
┌─────────────────────────────────────────┐
│  L3 Engine: PipelineSM, GateArbiter,    │
│            Validator, MatrixGen,        │
│            EvidenceMgr, RegistryCRUD    │
│  L4 CLI:   goalctl (cobra)              │
│  L4 CI:    goal-ci.yml → go test/go run │
└─────────────────────────────────────────┘

保持不变 (Agent 层, LLM 驱动):
┌─────────────────────────────────────────┐
│  L5: goal-spec, goal-matrix,            │
│      goal-planner, goal-reviewer,       │
│      goal-evidence ... (Claude Agents)  │
│  Agent 通过 CLI 调用 Engine 层           │
└─────────────────────────────────────────┘
```

Agent 是 LLM prompt，不该用 Go 重写。Agent 调 `goalctl` CLI 完成操作，边界清晰。

### 9.4 模块归属方案

**推荐方案 A**: 独立 Go module。

```text
goalctl/                          # module github.com/ZoneCNH/goalctl
├── go.mod
├── cmd/goalctl/                  # CLI 入口 (cobra)
│   └── main.go
├── internal/
│   ├── schema/                   # L1: 从 rules.yaml 加载 schema
│   │   ├── loader.go             #   解析 rules.yaml
│   │   ├── idpattern.go          #   ID 正则校验
│   │   └── enums.go              #   状态/关系枚举
│   ├── data/                     # L2: YAML 读写
│   │   ├── store.go              #   统一数据访问
│   │   ├── models.go             #   Go struct 定义
│   │   └── registry.go           #   6 个 Registry 的读写
│   ├── engine/                   # L3: 核心引擎
│   │   ├── pipeline.go           #   Pipeline 状态机
│   │   ├── gate.go               #   Gate 仲裁器
│   │   ├── validator.go          #   封装 5 大检查域
│   │   ├── matrix.go             #   矩阵生成 + 校验
│   │   ├── evidence.go           #   Evidence 生命周期
│   │   ├── registry.go           #   Registry CRUD
│   │   ├── lint.go               #   Lint 规则
│   │   └── drift.go              #   规则漂移检测
│   └── cli/                      # L4: cobra 命令
│       ├── root.go               #   goalctl 根命令
│       ├── goal.go               #   goal 子命令
│       ├── pipeline.go           #   pipeline 子命令
│       ├── gate.go               #   gate 子命令
│       ├── matrix.go             #   matrix 子命令
│       ├── evidence.go           #   evidence 子命令
│       ├── validate.go           #   validate 子命令
│       ├── risk.go               #   risk 子命令
│       ├── lint.go               #   lint 子命令
│       └── report.go             #   report 子命令
└── pkg/                          # 对外 SDK (供 xlib-standard 引用)
    ├── types.go                  #   公共类型
    └── client.go                 #   编程式调用接口
```

**理由**:

- `goalctl` 的生命周期独立于 x.go 发版
- 可独立 CI/CD
- 被 Agent 和人类同样调用
- `xlib-standard` 和 `xlibgate` 可引用 `pkg/` 作为 SDK

### 9.5 现有工具 Go 重写映射

| 现有工具                      | Go 目标                        | 行数估算      | 难度                                   |
| ----------------------------- | ------------------------------ | ------------- | -------------------------------------- |
| `goal-validate.py` (987行)    | `internal/engine/validator.go` | ~1,200 行     | 中 — 5 个 check 函数，YAML 解析 + 正则 |
| `matrix-gen.py` (388行)       | `internal/engine/matrix.go`    | ~500 行       | 低 — 目录扫描 + YAML 生成              |
| `gate-check.sh` (278行)       | `internal/engine/gate.go`      | ~400 行       | 低 — 纯规则检查                        |
| `lint-goal.sh` (304行)        | `internal/engine/lint.go`      | ~400 行       | 低 — 正则匹配                          |
| `evidence-collect.sh` (156行) | `internal/engine/evidence.go`  | ~250 行       | 低 — exec git + 模板渲染               |
| `rule-drift-check.py`         | `internal/engine/drift.go`     | ~200 行       | 低 — 字符串比对                        |
| `self-test.sh` (433行)        | `internal/engine/*_test.go`    | ~600 行       | 中 — 标准 Go test                      |
| — (新增)                      | `internal/schema/`             | ~300 行       | 低 — rules.yaml 加载                   |
| — (新增)                      | `internal/data/`               | ~400 行       | 低 — YAML 读写 + models                |
| — (新增)                      | `internal/cli/` (cobra)        | ~500 行       | 低 — CLI 骨架                          |
| — (新增)                      | `pkg/` (SDK)                   | ~200 行       | 低 — 公共类型 + 接口                   |
| **合计**                      |                                | **~4,950 行** |                                        |

Go 比 Python 更冗长，但类型安全 + 编译期校验 + 单二进制部署的收益远超多出的行数。

### 9.6 依赖清单

```go
// go.mod 核心依赖
require (
    github.com/spf13/cobra      // CLI 框架
    gopkg.in/yaml.v3             // YAML 解析
    github.com/go-playground/validator/v10  // 结构体校验
    github.com/stretchr/testify  // 测试断言
)
```

最小依赖，无 CGO，无外部数据库，纯文件系统操作。

### 9.7 Go 方案的 CLI 示例

```bash
# 安装
go install github.com/ZoneCNH/goalctl/cmd/goalctl@latest

# Goal 管理
goalctl goal create "Goal 驱动交付体系落地" --priority P0 --owner zone
goalctl goal list --status Active
goalctl goal show GOAL-20260608-001

# Pipeline 状态机
goalctl pipeline status GOAL-20260608-001
goalctl pipeline advance GOAL-20260608-001 --to SPEC
goalctl pipeline blockers GOAL-20260608-001

# Gate 仲裁
goalctl gate evaluate G2 --goal GOAL-20260608-001
goalctl gate status --goal GOAL-20260608-001
goalctl gate readiness --goal GOAL-20260608-001

# Matrix 操作
goalctl matrix generate --spec-dir module/ --task-dir docs/goal/tasks/
goalctl matrix check
goalctl matrix coverage

# Evidence 管理
goalctl evidence collect --task TASK-GOAL-20260608-001-001 --spec SPEC-goal-system-v1
goalctl evidence verify EVID-xxx

# 验证
goalctl validate --mode strict --format text
goalctl lint docs/goal/
goalctl drift-check

# 风险管理
goalctl risk list --status OPEN --release-blocking
goalctl risk close RISK-GOAL-20260608-001-001

# 报告
goalctl report summary
goalctl report goal GOAL-xxx
```

### 9.8 Go 路线图调整

Phase 1-2 的 Python 封装方案替换为 Go 实现：

| Phase    | 原方案 (Python)       | 调整后 (Go)          | 工期变化 |
| -------- | --------------------- | -------------------- | -------- |
| Phase 1  | Python 包封装现有工具 | Go 重写 Engine 层    | +1-2 天  |
| Phase 2  | Typer CLI             | cobra CLI            | 持平     |
| Phase 3  | Python Agent 编排     | Agent 不变，CLI 调用 | 持平     |
| Phase 4  | Python 报告           | Go 报告              | 持平     |
| **总计** | 6-10 天               | **8-12 天**          | +2 天    |

多出的 2 天换来：类型安全、单二进制、零 Python/Bash 运行时依赖、与 FoundationX 生态完全一致。

---

## 9. 优化方案

> 本节对第 2-8 节的设计进行深度审视，提出 8 项优化，目标：降低复杂度、缩短工期、减少代码量。

### 9.1 架构精简：五层 → 三层

原设计五层 (Schema → Data → Engine → Integration → Orchestration) 存在过度分层：

| 层                   | 问题                                    | 优化                            |
| -------------------- | --------------------------------------- | ------------------------------- |
| L1 Schema 与 L2 Data | 界限模糊，schema 本身就是 data 的一部分 | 合并为 **types** 层             |
| L4 Integration       | 只是 L3 Engine 的薄 CLI 包装            | 合并到 **cmd** 层               |
| L5 Orchestration     | Agent 层，不写 Go                       | 移出 Go 范围，保持 Claude Agent |

**优化后三层架构**:

```text
┌─────────────────────────────────────────────────────────┐
│                    cmd (CLI + CI)                        │
│  goalctl 子命令 (cobra) + CI 集成                        │
│  每个命令 ~30-50 行，调用 engine 层                       │
├─────────────────────────────────────────────────────────┤
│                    engine (核心逻辑)                      │
│  validator / pipeline / gate / matrix /                 │
│  evidence / lint / drift / registry                     │
│  声明式引擎：规则在 YAML，代码是通用 runner               │
├─────────────────────────────────────────────────────────┤
│                    types (schema + data)                 │
│  Go struct 定义 + schema 加载 + YAML 读写               │
│  泛型 Collection[T] 统一处理 6 个 Registry              │
└─────────────────────────────────────────────────────────┘
         ↑ 调用                          ↑ 调用
    Claude Agent                    xlib-standard / xlibgate
    (保持不变)                      (渐进集成)
```

**收益**: 消除层间胶水代码，减少 ~30% 总代码量。

### 9.2 策略变更：封装复用 → 直接重写

原 ADR-001 决策是"封装复用 Python/Bash 工具"。Go 实现后应改为直接重写：

| 封装方案的问题                              | 直接重写的优势                    |
| ------------------------------------------- | --------------------------------- |
| Go 调 Python 需 os/exec + 解析 stdout，脆弱 | 统一错误处理 (Go error)           |
| Go 调 Bash 同理                             | 类型安全，编译期校验              |
| 部署依赖 Python 运行时                      | 单二进制部署                      |
| 类型信息丢失 (dict → struct 重映射)         | struct tag + validator 声明式校验 |

**采用增量重写策略**: 每完成一个模块就用 self-test.sh 验证，不需要等全部重写完。

### 9.3 声明式引擎：规则在 YAML，代码是通用 Runner

**核心洞察**: rules.yaml 已经是完整的规则定义。Go 代码应该是 "load schema, validate against it"，而非 hardcode 每条规则。

#### 声明式 Gate Checks

在 rules.yaml 的 gate 定义中加入 checks 列表：

```yaml
# rules.yaml 中 gate 定义 (扩展示例)
gates:
  G5:
    gate_name: Task Gate
    type: Executable
    threshold: { pass: 90 }
    checks:
      - id: task_dod_coverage
        type: coverage
        target: registry.tasks
        field: dod
        threshold: 90
      - id: matrix_coverage
        type: coverage
        target: matrix.edges
        field: status
        terminal_values: [Verified, Dropped]
        threshold: 95
      - id: orphan_check
        type: reference_integrity
        source: registry.tasks
        source_key: goal_id
        target: registry.goals
        target_key: goal_id
```

Go 引擎只需实现通用 checker runner + 几个内置 checker type (`coverage`, `reference_integrity`, `field_completeness`)。**新增 checker 只改 YAML，不改代码。**

#### 声明式 Lint Rules

```yaml
# rules.yaml 中 lint 规则 (扩展示例)
lint_rules:
  - id: G-LINT-001
    group: G
    target_pattern: "goal|spec|task"
    check: has_metric
    pattern: '[0-9]+(%|秒|分钟|ms|个|次|条|行)'
    missing_message: "Goal 描述成功但缺少量化指标"
    level: warn

  - id: G-LINT-002
    group: G
    target_pattern: "goal|spec|task"
    check: no_fuzzy_words
    words: [优化, 提升, 改善, 完善, 加强, 尽量, 尽可能, 适时, 酌情]
    level: warn

  - id: S-LINT-001
    group: S
    target_pattern: "spec"
    check: has_keyword
    keywords: [acceptance.criteria, 验收标准, AC-]
    missing_message: "Spec 缺少 Acceptance Criteria"
    level: error
```

Go 引擎加载 lint rules YAML，通用 matcher 执行。**新增规则只改 YAML，不改代码。**

#### Checker Output Protocol

统一所有 checker 的输出格式：

```json
{
  "check_id": "task_dod_coverage",
  "status": "PASS | FAIL | WARN",
  "score": 95,
  "details": "9/10 tasks have DoD",
  "evidence": []
}
```

支持三种 checker 实现方式，统一输出格式：
- **Go 函数**: 内置 checker，编译期确定
- **Shell 脚本**: 外部 checker，通过 os/exec 调用
- **HTTP 调用**: 远程 checker，通过 HTTP API 调用

### 9.4 泛型 Collection：一个结构替代 6 个 Registry

利用 Go 1.18+ 泛型，用一个通用 Collection 处理所有 Registry：

```go
// types/collection.go (~100 行)
type Collection[T any] struct {
    path  string
    items []T
}

func NewCollection[T any](path string) *Collection[T]
func (c *Collection[T]) Load() error                          // 从 YAML 加载
func (c *Collection[T]) Save() error                          // 写回 YAML
func (c *Collection[T]) List(filter func(T) bool) []T         // 条件过滤
func (c *Collection[T]) Get(id string, idFn func(T) string) (T, bool)  // 按 ID 查
func (c *Collection[T]) Add(item T) error                     // 追加
func (c *Collection[T]) Update(id string, idFn func(T) string, fn func(T) T) error  // 修改
```

6 个 Registry 各自定义 struct，共享 Collection 操作：

```go
// 使用示例
goals := NewCollection[Goal](".config/goal/registry/goals.yaml")
goals.Load()
active := goals.List(func(g Goal) bool { return g.Status == "Active" })
```

**收益**: 6 个 registry 的 CRUD 逻辑从 ~600 行压缩到 ~100 行。

### 9.5 Pipeline 状态机降级为 Validator Check

原设计 PipelineStateMachine 是独立引擎组件。但实际上状态转换就是一条校验规则：

```text
转换合法性 = (target_state IN allowed_transitions[current_state])
             AND (该阶段 Gate == PASS)
             AND (无 release_blocking 风险)
```

这不需要独立的状态机引擎，放进 validator 的 consistency check 即可：

```go
// engine/validator.go 中的一个 check 函数
func checkPipelineTransition(state PipelineState, gates []Gate, risks []Risk) []Finding {
    // 1. 校验 current_state → target_state 在转换表中
    // 2. 校验对应 Gate 已 PASS
    // 3. 校验无 release_blocking 风险
}
```

**收益**: 消除 pipeline.go 独立模块，省 ~150 行 + 层间调用代码。

### 9.6 Gate Arbiter 简化为 Checker Runner

原设计 GateArbiter 是复杂的仲裁框架。实际逻辑很简单：

```text
Gate 仲裁 = load gate 定义
           → 按顺序执行 checks (可并发)
           → 汇总 checker results
           → 对比阈值判定 PASS/FAIL/PASS_WITH_RISK/BLOCKED
           → 写入 gates/state.yaml
```

用声明式 checks (9.3) + checker runner 就够了：

```go
// engine/gate.go (~200 行)
type GateResult struct {
    GateID  string         `json:"gate_id"`
    Verdict string         `json:"verdict"`   // PASS/FAIL/PASS_WITH_RISK/BLOCKED
    Score   int            `json:"score"`
    Checks  []CheckResult  `json:"checks"`
}

func EvaluateGate(gateID string, goalID string, config Config) (GateResult, error) {
    gate := config.GetGate(gateID)
    results := runChecks(gate.Checks, config)  // 可并发
    score := calculateScore(results)
    verdict :=判定(gate, score, risks)
    writeGateState(gateID, verdict, results)
    return GateResult{...}, nil
}
```

**收益**: GateArbiter 从 ~400 行压缩到 ~200 行。

### 9.7 MVP 切分：最小可交付 2-3 天

原报告 Phase 1-4 全部功能需要 8-12 天。但 MVP 只需：

| MVP 功能   | 对应 CLI 命令                                 | 价值                  |
| ---------- | --------------------------------------------- | --------------------- |
| 状态查看   | `goalctl pipeline status GOAL-xxx`            | 一眼看到当前阶段      |
| 状态推进   | `goalctl pipeline advance GOAL-xxx --to SPEC` | 自动校验 + 写入       |
| 合法性验证 | `goalctl validate --mode strict`              | 替代 goal-validate.py |
| Gate 查看  | `goalctl gate status --goal GOAL-xxx`         | 一眼看到 Gate 状态    |

**MVP 不需要的**:
- Registry CRUD（手动编辑 YAML 够用）
- Evidence 自动收集（手动创建够用）
- Matrix 自动生成（手动维护够用）
- 报告/仪表盘
- Agent 编排

**MVP 架构**: 只需 types + validator + pipeline check + 4 个 CLI 命令。

```text
MVP 代码量估算:
  types.go       ~200 行  (struct 定义 + YAML 加载)
  validator.go   ~400 行  (5 大检查域)
  gate.go        ~150 行  (gate 状态读取 + 判定)
  cli/*.go       ~200 行  (4 个命令)
  *_test.go      ~200 行
  main.go        ~30 行
  ─────────────────────
  总计           ~1,180 行
```

**MVP 后按价值排序迭代**:

| 优先级   | 功能                            | 工期        | 价值               |
| -------- | ------------------------------- | ----------- | ------------------ |
| P0       | Gate checker runner (声明式)    | +1 天       | 自动化 Gate 判定   |
| P1       | Matrix 生成 + 校验              | +1 天       | 追溯覆盖率自动检查 |
| P2       | Registry CRUD (泛型 Collection) | +0.5 天     | 结构化写入         |
| P3       | Evidence 收集                   | +0.5 天     | 自动化 Evidence    |
| P4       | Lint + Drift (声明式)           | +0.5 天     | 规则自动化         |
| P5       | Report + Dashboard              | +1 天       | 可观测性           |
| **总计** |                                 | **+4.5 天** |                    |

### 9.8 渐进集成 xlib-standard / xlibgate

goalctl 先独立实现，再渐进集成 FoundationX 生态：

| 阶段           | 集成点                         | 方式                         |
| -------------- | ------------------------------ | ---------------------------- |
| Phase 1 (独立) | 无                             | goalctl 自包含               |
| Phase 2 (引用) | xlibgate 门禁模式              | 复用 checker output protocol |
| Phase 3 (引用) | xlib-standard Evidence Runtime | 调用其 API 替代自实现        |
| Phase 4 (嵌入) | x.go 组合根                    | goalctl 作为 x.go 的子命令   |

### 9.9 优化前后对比

| 维度         | 优化前         | 优化后                 | 改善             |
| ------------ | -------------- | ---------------------- | ---------------- |
| 架构层数     | 5 层           | 3 层                   | -40%             |
| 总代码量     | ~4,950 行      | ~2,500 行 (含测试)     | -49%             |
| MVP 代码量   | —              | ~1,180 行              | 新增             |
| 总工期       | 8-12 天        | 5-7 天                 | -40%             |
| MVP 工期     | —              | 2-3 天                 | 新增             |
| 重写策略     | 封装复用       | 直接重写 (增量)        | 类型安全         |
| 规则管理     | 硬编码在 Go    | 声明式 YAML            | 新增规则不改代码 |
| Registry     | 6 个独立实现   | 泛型 Collection        | -83% 代码        |
| Pipeline     | 独立状态机引擎 | Validator 的一个 check | 消除独立模块     |
| Gate Arbiter | 复杂仲裁框架   | Checker runner         | -50% 代码        |

---

## 10. 总结

Goal 体系的程序化不是从零开始 — **已有 ~60% 的基础设施**。核心差距在于：

1. **没有统一入口** (CLI): 6 个独立工具 → 需要 `goalctl`
2. **没有状态机引擎**: 人工编辑 YAML → 需要状态转换校验
3. **没有自动仲裁**: 制品检查有，判定没有 → 需要 Gate checker runner
4. **没有 Agent 编排**: 10 个 Agent 各自独立 → 需要编排器

**实现语言**: Go。与 FoundationX 全栈生态一致 (kernel, x.go, xlib-standard, xlibgate)，单二进制部署，类型安全，零 Python/Bash 运行时依赖。

**架构**: 三层 (types → engine → cmd)，声明式引擎 (规则在 YAML，代码是通用 runner)，泛型 Collection 统一 Registry 操作。

**策略**: 直接重写 (不封装 Python/Bash)，增量交付，MVP 2-3 天获得核心可执行能力。

**预估工作量**: MVP 2-3 天，全部功能 5-7 天。比原方案 (8-12 天) 减少 40%。



