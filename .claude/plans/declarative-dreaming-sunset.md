# goalctl — Goal 驱动交付体系 Go 完整实现计划

## TL;DR

> **Quick Summary**: 将 `docs/goal/` 体系的 30 份文档和 7 个现有工具（3200 行 shell/Python）统一重写为 Go CLI 工具 `goalctl`，实现类型安全、单二进制、零外部运行时依赖的 Goal 控制面。
>
> **Deliverables**:
> - `github.com/ZoneCNH/goalctl` 独立 Go 模块
> - `goalctl` CLI 二进制（cobra）
> - 15+ 子命令覆盖 validate/gate/lint/pipeline/matrix/registry/evidence/ci
> - ~290 个测试用例
> - 完整迁移现有 shell/Python 工具
>
> **Estimated Effort**: 8 天
> **Parallel Execution**: YES - 4 waves
> **Critical Path**: Task 1 → Task 2 → Task 5 → Task 8 → Task 12 → Task 15

---

## Context

### Original Request
用户要求完整实现 `docs/goal/` 体系为 Go 工程。分析报告已产出在 `report/goal-full-go-implementation-20260609.md`。

### 现有基础设施
- **30 份文档**在 `docs/goal/` 定义了完整的 Goal 驱动交付体系
- **7 个现有工具**（3 Python + 2 Bash + self-test + release-gate）在 `docs/goal/tools/`，共 3200 行
- **运行时数据**在 `.config/goal/`：6 个 YAML registry、matrix、pipeline state、gates state、evidence（markdown）、schema/rules.yaml
- **`.config/goal/schema/rules.yaml`** 是所有规则的机器可读投影（SSOT），包含 ID regex、状态枚举、edge 字段契约、CI 合约

### 为什么用 Go 重写
1. 现有工具分散在 Bash/Python，接口不统一
2. Go 单二进制，零运行时依赖，启动 <10ms
3. 类型安全，编译期捕获错误
4. 泛型 Collection[T] 统一 6 个 Registry
5. 可被 FoundationX 其他 Go 模块直接引用

---

## Work Objectives

### Core Objective
构建 `goalctl` CLI 工具，完整替代现有 7 个 shell/Python 工具，并扩展覆盖 `docs/goal/` 体系的全部可执行规则。

### Concrete Deliverables
- `goalctl` Go 模块（types/engine/cmd 三层架构）
- CLI 命令：validate, gate, lint, pipeline, matrix, registry, evidence, ci, propagate, status, dor, dod
- 与现有 `.config/goal/` YAML 格式 100% 兼容
- 与现有 `docs/goal/tools/self-test.sh` 负例 fixture 对齐的测试套件

### Definition of Done
- [ ] `goalctl ci preflight` 在 ZoneCNH 仓库通过
- [ ] `goalctl gate check G5` 输出与 `gate-check.sh` 一致
- [ ] `goalctl lint M` 输出与 `lint-goal.sh` 一致
- [ ] `goalctl validate GOAL GOAL-20260608-001` 通过
- [ ] 所有现有 self-test.sh 负例被 Go 测试覆盖
- [ ] `go test ./...` 通过，覆盖率 ≥ 80%

### Must Have
- 与 `.config/goal/schema/rules.yaml` 完全对齐的 ID 格式校验
- 与 `.config/goal/matrix/matrix.yaml` 完全对齐的 edge 模型
- 与 `.config/goal/pipeline/state.yaml` 完全对齐的四轴状态机
- 11 个 Gate (G0-G11) 的自动检查器
- 33 条 Lint 规则（22 条可自动化）
- Evidence 收集与验证
- CI preflight / verify 检查

### Must NOT Have (Guardrails)
- 不引入外部业务依赖（仅 cobra + yaml + testify）
- 不修改现有 `.config/goal/` 数据格式
- 不在 main 分支直接提交（遵循 CONSTITUTION.md 第零条）
- 不实现 AI/LLM 调用逻辑（goalctl 是纯规则引擎）
- 不实现 Git 操作（仅读取 git diff 输出，不执行 git write）

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES（现有 self-test.sh 有完整 fixture）
- **Automated tests**: YES（TDD 强制）
- **Framework**: Go stdlib testing + testify
- **Test types**: 单元测试（checker/lint/ID）+ 集成测试（CLI 命令端到端）

### QA Policy
每个 Task 必须附带验证命令。Evidence 保存在 `.config/goal/evidence/` 下。

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Day 1-2): 基础骨架 — 4 个 Task 并行
├── Task 1: Go 模块初始化 + types/ [quick]
├── Task 2: ID 系统 + 格式校验 [quick]
├── Task 3: Pipeline 状态机 [quick]
└── Task 4: CLI 骨架 (cobra) [quick]

Wave 2 (Day 2-4): 核心引擎 — 4 个 Task 并行
├── Task 5: Gate 检查器框架 + G0-G11 [deep]
├── Task 6: Lint 引擎 + 33 条规则 [deep]
├── Task 7: Registry CRUD + Collection[T] [unspecified-high]
└── Task 8: Matrix 操作 + 覆盖率/孤立检查 [unspecified-high]

Wave 3 (Day 4-6): 高级功能 — 4 个 Task 并行
├── Task 9: Evidence 收集与验证 [unspecified-high]
├── Task 10: DoR/DoD 检查器 [unspecified-high]
├── Task 11: 变更传播 + 优先级评分 [unspecified-high]
└── Task 12: CI Preflight + x.go 检查 [unspecified-high]

Wave 4 (Day 6-8): 集成与迁移 — 3 个 Task 并行
├── Task 13: 现有工具迁移验证 [unspecified-high]
├── Task 14: self-test.sh 用例迁移 [unspecified-high]
└── Task 15: 文档 + README + 使用示例 [unspecified-high]

Wave FINAL: 评审
└── Task F1: plan compliance audit [advisor]
└── Task F2: code quality review [unspecified-high]
└── Task F3: scope fidelity check [deep]
```

### Dependency Matrix
| Task | Blocked By | Blocks |
|------|-----------|--------|
| 1 | — | 2,3,4,5,6,7,8 |
| 2 | 1 | 5,6,13 |
| 3 | 1 | 5,10,12 |
| 4 | 1 | 5,6,7,8,9,10,11,12 |
| 5 | 2,3,4 | 12,13 |
| 6 | 2,4 | 13 |
| 7 | 4 | 8,13 |
| 8 | 4,7 | 12,13 |
| 9 | 4 | 12,13 |
| 10 | 3,4 | 13 |
| 11 | 4 | 13 |
| 12 | 3,5,8,9 | 13 |
| 13 | 5,6,7,8,9,10,11,12 | 14 |
| 14 | 13 | 15 |
| 15 | 14 | F1 |

### Agent Dispatch Summary
- **Wave 1**: 4 tasks — T1→`quick`, T2→`quick`, T3→`quick`, T4→`quick`
- **Wave 2**: 4 tasks — T5→`deep`, T6→`deep`, T7→`unspecified-high`, T8→`unspecified-high`
- **Wave 3**: 4 tasks — T9→`unspecified-high`, T10→`unspecified-high`, T11→`unspecified-high`, T12→`unspecified-high`
- **Wave 4**: 3 tasks — T13→`unspecified-high`, T14→`unspecified-high`, T15→`unspecified-high`
- **FINAL**: 3 tasks — F1→`advisor`, F2→`unspecified-high`, F3→`deep`

---

## TODOs

- [ ] 1. Go 模块初始化 + types/ 基础结构体

  **What to do**:
  - 创建 `goalctl/` 目录，`go mod init github.com/ZoneCNH/goalctl`
  - 实现 `types/` 包：Pipeline 四轴状态模型（PipelineState/CurrentPhase/PhaseStatus/WorkflowStep 全部枚举）、Gate 类型（GateType/GateResult/GateDefinition/CheckItem/Risk）、Matrix Edge 模型（MatrixEdge/EdgeRelation/EdgeStatus）、Evidence 结构体、Registry 类型（Goal/Task/Issue/Release/Decision/RiskEntry）、DoDCheck 结构体
  - 所有枚举值必须与 `.config/goal/schema/rules.yaml` 完全对齐
  - 每个 Registry 类型实现 `Identifiable` 接口
  - 实现 `Collection[T Identifiable]` 泛型容器（Add/Get/Update/Delete/Filter/Len）

  **Must NOT do**:
  - 不实现任何业务逻辑（logic belongs in engine/）
  - 不引入 cobra 或其他 CLI 依赖

  **Recommended Agent Profile**:
  - `category`: quick
  - `skills`: [] — 纯数据结构，无需特殊技能

  **Parallelization**:
  - `can_run_in_parallel`: YES
  - `parallel_group`: Wave 1
  - `blocks`: [2, 3, 4, 5, 6, 7, 8]
  - `blocked_by`: []

  **References**:
  - `.config/goal/schema/rules.yaml` — 所有枚举值、状态列表、ID 正则的 SSOT
  - `.config/goal/registry/goals.yaml` — Goal 对象的实际字段和示例值
  - `.config/goal/registry/tasks.yaml` — Task 对象的实际字段（含 change_level, execution_mode）
  - `.config/goal/matrix/matrix.yaml` — Matrix edge 的 8 个必填字段和实际 relation 类型
  - `.config/goal/pipeline/state.yaml` — 四轴状态模型的实际值和 state_history 格式
  - `report/goal-full-go-implementation-20260609.md` §3 — 完整的 Go 类型定义参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: 编译通过
    Tool: Bash
    Steps:
      1. cd goalctl && go build ./types/
    Expected Result: 退出码 0，无编译错误
    Evidence: .config/goal/evidence/

  Scenario: Collection[T] 泛型 CRUD
    Tool: Bash
    Steps:
      1. go test ./types/ -run TestCollection
    Expected Result: Add/Get/Update/Delete/Filter 全部通过
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): initialize Go module with core type definitions`
  - Files: `goalctl/go.mod`, `goalctl/types/*.go`

- [ ] 2. ID 系统 + 格式校验

  **What to do**:
  - 实现 `types/id.go`：18 种 ID 格式的正则表（从 `rules.yaml` 的 `ids` 节提取）
  - 实现 `ValidateID(idType, id string) bool` 函数
  - 实现 `engine/validate.go`：批量校验、友好错误消息
  - 实现 `cmd/goalctl/validate.go`：`goalctl validate <id-type> <id>` 命令

  **Must NOT do**:
  - 不修改现有 ID 格式规范
  - 不自动生成 ID（仅校验）

  **Recommended Agent Profile**:
  - `category`: quick
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 3, 4 并行）
  - `parallel_group`: Wave 1
  - `blocks`: [5, 6, 13]
  - `blocked_by`: [1]

  **References**:
  - `.config/goal/schema/rules.yaml:33-47` — 全部 18 个 ID 正则模式
  - `docs/goal/07-id-system.md` — ID 格式规范文档
  - `report/goal-full-go-implementation-20260609.md` §3.4 — Go 实现参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: 正确 ID 格式校验通过
    Tool: Bash
    Steps:
      1. go test ./types/ -run TestValidateID
    Expected Result: 18 种 ID 格式的正例全部通过
    Evidence: .config/goal/evidence/

  Scenario: 错误 ID 格式被拒绝
    Tool: Bash
    Steps:
      1. go test ./types/ -run TestValidateID_Invalid
    Expected Result: 每种格式至少 3 个反例全部被拒绝
    Evidence: .config/goal/evidence/

  Scenario: CLI 命令输出
    Tool: Bash
    Steps:
      1. go run ./cmd/goalctl validate GOAL GOAL-20260608-001
    Expected Result: 输出 "✅ GOAL-20260608-001 格式正确"，退出码 0
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): implement ID format validation with 18 regex patterns`
  - Files: `goalctl/types/id.go`, `goalctl/engine/validate.go`, `goalctl/cmd/goalctl/validate.go`

- [ ] 3. Pipeline 状态机

  **What to do**:
  - 实现 `engine/pipeline.go`：正常状态转换规则表（8 条规则）、异常状态恢复路径（6 条）、TransitionGuard 前置检查、ExecuteTransition 执行转换、RecoverFromAbnormal 恢复
  - 实现 `cmd/goalctl/pipeline.go`：`goalctl pipeline status` 和 `goalctl pipeline transition <phase>` 命令
  - Pipeline 状态必须与 `.config/goal/pipeline/state.yaml` 的 state_history 对齐

  **Must NOT do**:
  - 不修改现有 state.yaml 文件（只读）
  - 不实现自动状态推断（转换必须显式调用）

  **Recommended Agent Profile**:
  - `category`: quick
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 2, 4 并行）
  - `parallel_group`: Wave 1
  - `blocks`: [5, 10, 12]
  - `blocked_by`: [1]

  **References**:
  - `.config/goal/pipeline/state.yaml` — 四轴状态模型的实际值、state_history 格式
  - `.config/goal/schema/rules.yaml:199-284` — pipeline 状态枚举、phase 列表、workflow_step 列表
  - `docs/goal/03-pipeline.md` — 状态转换规则的权威定义
  - `report/goal-full-go-implementation-20260609.md` §4.1 — Go 实现参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: 正常状态转换
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestPipelineTransitions
    Expected Result: SPEC_READY→DESIGN_READY、DESIGN_READY→PLAN_READY 等 8 条规则全部通过
    Evidence: .config/goal/evidence/

  Scenario: 异常状态拒绝直接转换
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestPipelineTransitions_Blocked
    Expected Result: BLOCKED 状态不允许直接转换，返回错误
    Evidence: .config/goal/evidence/

  Scenario: 异常状态恢复
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestRecoverFromAbnormal
    Expected Result: FAILED→EXECUTING、NEEDS_REPLAN→PLAN_READY 等恢复路径通过
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): implement pipeline state machine with 4-axis model`
  - Files: `goalctl/engine/pipeline.go`, `goalctl/cmd/goalctl/pipeline.go`

- [ ] 4. CLI 骨架 (cobra)

  **What to do**:
  - 实现 `cmd/goalctl/main.go`：cobra root command，注册所有子命令
  - 实现通用 flag：`--root`（项目根目录）、`--config`（配置目录）、`--format`（输出格式 text/json）、`--verbose`
  - 实现配置加载：从 `.config/goal/` 读取 YAML 文件的通用函数
  - 实现彩色输出：PASS=绿色、FAIL=红色、WARN=黄色

  **Must NOT do**:
  - 不实现具体业务逻辑（由后续 Task 填充）
  - 不引入 viper 等重配置库

  **Recommended Agent Profile**:
  - `category`: quick
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 2, 3 并行）
  - `parallel_group`: Wave 1
  - `blocks`: [5, 6, 7, 8, 9, 10, 11, 12]
  - `blocked_by`: [1]

  **References**:
  - `docs/goal/tools/README.md` — 现有工具的 CLI 接口和 flag 设计
  - `docs/goal/tools/gate-check.sh:8-14` — 环境变量和路径约定（GOAL_CONFIG_DIR 等）
  - `report/goal-full-go-implementation-20260609.md` §5 — CLI 命令设计参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: 编译和 help 输出
    Tool: Bash
    Steps:
      1. cd goalctl && go build -o goalctl ./cmd/goalctl/
      2. ./goalctl --help
    Expected Result: 显示所有子命令列表，退出码 0
    Evidence: .config/goal/evidence/

  Scenario: 配置目录自动发现
    Tool: Bash
    Steps:
      1. cd /home/workspace/ZoneCNH && goalctl/goalctl pipeline status
    Expected Result: 自动找到 .config/goal/ 并加载配置
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): initialize cobra CLI skeleton with config loader`
  - Files: `goalctl/cmd/goalctl/main.go`, `goalctl/cmd/goalctl/config.go`

- [ ] 5. Gate 检查器框架 + G0-G11

  **What to do**:
  - 实现 `engine/gate_check.go`：GateDefinitions 表（G0-G11 完整定义，每个 Gate 的 CheckItems）、CheckerFunc 注册表、RunGate 执行引擎、aggregateResults 结果聚合
  - 实现 14 个自动检查器：goalHasObjective、goalHasMetrics、goalHasScopeOut、goalHasTargetUser、goalHasVerifiableMetric、matrixCoverage、orphanCheck、evidenceFieldComplete、taskGateCoverage、reviewNoCritical、releaseManifest、releaseRiskClosed、specUniqueIDs、designNoCycles
  - 实现 `cmd/goalctl/gate.go`：`goalctl gate check <gate-id>` 和 `goalctl gate status` 命令
  - Gate 检查必须读取 `.config/goal/` 下的实际数据

  **Must NOT do**:
  - 不修改现有 gates/state.yaml
  - 不实现 Gate arbiter（四源仲裁是上层职责）

  **Recommended Agent Profile**:
  - `category`: deep
  - `skills`: [`notepad`] — 需要记录复杂的 Gate 规则映射

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 6, 7, 8 并行）
  - `parallel_group`: Wave 2
  - `blocks`: [12, 13]
  - `blocked_by`: [2, 3, 4]

  **References**:
  - `docs/goal/04-gates.md` — G0-G11 定义、CheckItems、PASS_WITH_RISK 策略
  - `docs/goal/08-quality-gates.md` — 质量门禁补充规则
  - `.config/goal/gates/state.yaml` — Gate 状态的实际数据格式
  - `.config/goal/schema/rules.yaml:173-198` — Gate ID 列表、状态枚举
  - `docs/goal/tools/gate-check.sh` — 现有实现（278 行），需对齐检查逻辑
  - `report/goal-full-go-implementation-20260609.md` §3.3 + §4.2 — 完整 Go 实现参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: G0 Gate 检查（Goal 完整性）
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestGateChecks/G0
    Expected Result: 使用实际 GOAL-20260608-001 数据，G0 PASS
    Evidence: .config/goal/evidence/

  Scenario: G5 Gate 检查（Matrix 覆盖率）
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestGateChecks/G5
    Expected Result: 使用实际 matrix.yaml 数据，G5 PASS（覆盖率 100%）
    Evidence: .config/goal/evidence/

  Scenario: CLI gate check 输出
    Tool: Bash
    Steps:
      1. goalctl gate check G5 --root /home/workspace/ZoneCNH
    Expected Result: 显示 G5 PASS，包含 CheckItems 详情
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): implement Gate checker framework with G0-G11 automated checks`
  - Files: `goalctl/engine/gate_check.go`, `goalctl/engine/gate_check_test.go`, `goalctl/cmd/goalctl/gate.go`

- [ ] 6. Lint 引擎 + 33 条规则

  **What to do**:
  - 实现 `engine/lint.go`：LintRule 结构体、33 条规则定义（G:7/3auto, S:8/3auto, M:8/8auto, P:10/2auto, C:5/5auto）、RunLint/RunAllLint 执行引擎
  - 实现 22 个自动 lint checker：lintGoalHasObjective、lintGoalHasMetrics、lintGoalHasScopeOut、lintGoalNoVagueWords、lintSpecUniqueIDs、lintSpecTestable、lintSpecACClear、lintMatrixGoalSpec、lintMatrixSpecReq、lintMatrixRowTask、lintMatrixP0P1Test、lintMatrixTaskTraceable、lintMatrixNoOrphanTask、lintMatrixNoOrphanCode、lintMatrixDoneCodeTest、lintPromptHasSource、lintPromptSingleGoal、lintCodePRTaskRef、lintCodePRMatrixRef、lintCodePRTestDesc、lintCodeP0P1Test、lintCodeNoOrphanChange
  - 模糊词检查：优化/提升/增强/完善/更好/更快/更稳定/体验更佳/高可用/易用/智能化
  - 实现 `cmd/goalctl/lint.go`：`goalctl lint [category]` 命令

  **Must NOT do**:
  - 不修改现有 lint 规则定义
  - 不实现自动修复（只报告）

  **Recommended Agent Profile**:
  - `category`: deep
  - `skills`: [`notepad`] — 需要记录 33 条规则的映射关系

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 5, 7, 8 并行）
  - `parallel_group`: Wave 2
  - `blocks`: [13]
  - `blocked_by`: [2, 4]

  **References**:
  - `docs/goal/10-lint-rules.md` — 33 条 Lint 规则的完整定义
  - `docs/goal/tools/lint-goal.sh` — 现有实现（303 行），需对齐检查逻辑
  - `report/goal-full-go-implementation-20260609.md` §4.3 — Go 实现参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: M-LINT 全部自动化
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestLintMatrix
    Expected Result: 8 条 M-LINT 规则全部可自动执行，使用实际 matrix.yaml 数据
    Evidence: .config/goal/evidence/

  Scenario: 模糊词检测
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestLintGoalNoVagueWords
    Expected Result: "优化用户体验" 被标记为 WARN
    Evidence: .config/goal/evidence/

  Scenario: CLI lint 输出
    Tool: Bash
    Steps:
      1. goalctl lint G --root /home/workspace/ZoneCNH
    Expected Result: 显示 G-LINT 检查结果
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): implement Lint engine with 33 rules (22 automated)`
  - Files: `goalctl/engine/lint.go`, `goalctl/engine/lint_test.go`, `goalctl/cmd/goalctl/lint.go`

- [ ] 7. Registry CRUD + Collection[T]

  **What to do**:
  - 实现 `engine/registry.go`：LoadYAML/SaveYAML 通用函数、6 个 Registry 的 CRUD 操作、状态转换验证
  - 实现 `cmd/goalctl/registry.go`：`goalctl registry list <type>`、`goalctl registry add <type> <file>`、`goalctl registry update <type> <id>` 命令
  - YAML 序列化必须与现有文件格式兼容（保留注释风格、字段顺序）

  **Must NOT do**:
  - 不修改现有 registry 文件结构
  - 不实现批量导入

  **Recommended Agent Profile**:
  - `category`: unspecified-high
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 5, 6, 8 并行）
  - `parallel_group`: Wave 2
  - `blocks`: [8, 13]
  - `blocked_by`: [4]

  **References**:
  - `docs/goal/15-registry.md` — 6 个 Registry 的 schema 定义
  - `.config/goal/registry/*.yaml` — 实际数据格式
  - `.config/goal/schema/rules.yaml:49-98` — 状态枚举
  - `report/goal-full-go-implementation-20260609.md` §3.5 — Go 类型定义参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: 加载现有 Registry
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestLoadRegistry
    Expected Result: 6 个 YAML 文件全部加载成功，字段完整
    Evidence: .config/goal/evidence/

  Scenario: CLI registry list 输出
    Tool: Bash
    Steps:
      1. goalctl registry list goals --root /home/workspace/ZoneCNH
    Expected Result: 显示 GOAL-20260608-001 的完整信息
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): implement Registry CRUD with Collection[T] generic container`
  - Files: `goalctl/engine/registry.go`, `goalctl/engine/registry_test.go`, `goalctl/cmd/goalctl/registry.go`

- [ ] 8. Matrix 操作 + 覆盖率/孤立检查

  **What to do**:
  - 实现 `engine/matrix.go`：LoadMatrix/SaveMatrix、AddEdge/RemoveEdge/UpdateEdge、CalculateCoverage（按 Verified+Dropped 计算终态覆盖率）、FindOrphans（无 Goal 来源的 Task）、CheckDroppedReasons（Dropped 行必须有 drop_reason）
  - 实现 `cmd/goalctl/matrix.go`：`goalctl matrix coverage`、`goalctl matrix orphans`、`goalctl matrix add-edge` 命令
  - 覆盖率目标：≥ 95%

  **Must NOT do**:
  - 不自动修改 matrix.yaml（只读检查，add-edge 需显式调用）
  - 不实现 Matrix 自动生成（那是 matrix-gen.py 的职责）

  **Recommended Agent Profile**:
  - `category`: unspecified-high
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 5, 6, 7 并行）
  - `parallel_group`: Wave 2
  - `blocks`: [12, 13]
  - `blocked_by`: [4, 7]

  **References**:
  - `docs/goal/05-layer-standards.md §3` — Matrix 覆盖率规则、状态生命周期
  - `.config/goal/matrix/matrix.yaml` — 实际 edge 数据（26 条边）
  - `.config/goal/schema/rules.yaml:100-150` — Matrix 配置、edge 字段契约
  - `docs/goal/tools/matrix-gen.py` — 现有实现（388 行）
  - `report/goal-full-go-implementation-20260609.md` §3.6 — Go 实现参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Matrix 覆盖率计算
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestMatrixCoverage
    Expected Result: 使用实际 matrix.yaml，覆盖率 100%（26/26 Verified）
    Evidence: .config/goal/evidence/

  Scenario: 孤立 Task 检查
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestFindOrphans
    Expected Result: 使用实际数据，无孤立 Task
    Evidence: .config/goal/evidence/

  Scenario: CLI matrix coverage 输出
    Tool: Bash
    Steps:
      1. goalctl matrix coverage --root /home/workspace/ZoneCNH
    Expected Result: 显示 "Matrix 覆盖率 100.0% (26/26)"
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): implement Matrix operations with coverage and orphan checks`
  - Files: `goalctl/engine/matrix.go`, `goalctl/engine/matrix_test.go`, `goalctl/cmd/goalctl/matrix.go`

- [ ] 9. Evidence 收集与验证

  **What to do**:
  - 实现 `engine/evidence.go`：CollectEvidence（从 git diff + 测试结果收集）、VerifyEvidence（10 个必填字段完整性检查）、LoadEvidence（从 markdown 文件解析）
  - 实现 `cmd/goalctl/evidence.go`：`goalctl evidence collect <task-id>`、`goalctl evidence verify <evid-id>` 命令
  - Evidence 路径格式：`.config/goal/evidence/YYYY-MM-DD/TASK_ID/EVID_ID.md`
  - 10 个必填字段：Evidence ID, Acceptance Criteria ID, Test ID, Task ID, Spec ID, Goal ID, Date, Status, Files Changed, Commands Run

  **Must NOT do**:
  - 不自动运行测试（只收集已有结果）
  - 不修改现有 evidence 文件

  **Recommended Agent Profile**:
  - `category`: unspecified-high
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 10, 11, 12 并行）
  - `parallel_group`: Wave 3
  - `blocks`: [12, 13]
  - `blocked_by`: [4]

  **References**:
  - `docs/goal/13-runtime-engine.md` — Evidence Protocol 14 字段定义
  - `docs/goal/20-metrics-evidence.md` — Evidence 收集规范
  - `.config/goal/evidence/` — 现有 Evidence 文件格式
  - `.config/goal/schema/rules.yaml:152-171` — Evidence 配置
  - `docs/goal/tools/evidence-collect.sh` — 现有实现（155 行）
  - `report/goal-full-go-implementation-20260609.md` §3.7 + §4.7 — Go 实现参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Evidence 字段验证
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestVerifyEvidence
    Expected Result: 完整 Evidence 通过，缺失字段被检测
    Evidence: .config/goal/evidence/

  Scenario: CLI evidence verify 输出
    Tool: Bash
    Steps:
      1. goalctl evidence verify EVID-TEST-TASK-GOAL-20260608-001-001-001-001 --root /home/workspace/ZoneCNH
    Expected Result: 显示 10 个字段检查结果
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): implement Evidence collection and verification`
  - Files: `goalctl/engine/evidence.go`, `goalctl/engine/evidence_test.go`, `goalctl/cmd/goalctl/evidence.go`

- [ ] 10. DoR/DoD 检查器

  **What to do**:
  - 实现 `engine/dor_dod.go`：预定义 13 个 stage 的 DoR/DoD 检查项（~80 条，~20 条可自动化）、CheckDoRDoD 执行函数
  - 实现 `cmd/goalctl/dor.go`：`goalctl dor check <stage>` 和 `goalctl dod check <stage>` 命令
  - 自动检查项必须与 checkerRegistry 共享

  **Must NOT do**:
  - 不修改 DoR/DoD 定义
  - 不自动修复未通过的检查项

  **Recommended Agent Profile**:
  - `category`: unspecified-high
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 9, 11, 12 并行）
  - `parallel_group`: Wave 3
  - `blocks`: [13]
  - `blocked_by`: [3, 4]

  **References**:
  - `docs/goal/06-dod.md` — 13 个 stage 的 DoR/DoD 完整定义
  - `report/goal-full-go-implementation-20260609.md` §4.8 — Go 实现参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Goal DoR 检查
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestCheckDoRDoD_Goal
    Expected Result: 7 条 Goal DoR 检查项执行，自动项返回 PASS/WARN
    Evidence: .config/goal/evidence/

  Scenario: CLI dor check 输出
    Tool: Bash
    Steps:
      1. goalctl dor check GOAL --root /home/workspace/ZoneCNH
    Expected Result: 显示 Goal DoR 检查结果
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): implement DoR/DoD checker for 13 stages`
  - Files: `goalctl/engine/dor_dod.go`, `goalctl/engine/dor_dod_test.go`, `goalctl/cmd/goalctl/dor.go`

- [ ] 11. 变更传播 + 优先级评分

  **What to do**:
  - 实现 `engine/propagation.go`：12 种变更类型的传播矩阵、Propagate 函数（标记下游为 STALE）
  - 实现 `engine/priority.go`：PriorityScore 公式（Impact×0.30 + Urgency×0.20 + DepUnlock×0.20 + RiskReduction×0.20 + UserValue×0.10 - Effort×0.15）、MapPriority（P0-P3）
  - 实现 `engine/change_level.go`：CL0-CL5 变更级别评估、ExecutionMode、RequiredGates、RequiresHumanApproval
  - 实现 `cmd/goalctl/propagate.go`：`goalctl propagate <type>` 命令

  **Must NOT do**:
  - 不自动执行传播（只标记，不修改文件）
  - 不实现自动优先级排序

  **Recommended Agent Profile**:
  - `category`: unspecified-high
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 9, 10, 12 并行）
  - `parallel_group`: Wave 3
  - `blocks`: [13]
  - `blocked_by`: [4]

  **References**:
  - `docs/goal/13-runtime-engine.md` — 变更传播矩阵、优先级公式、变更级别定义
  - `docs/goal/12-operations.md` — 运营操作规范
  - `report/goal-full-go-implementation-20260609.md` §4.4 + §4.5 + §4.6 — Go 实现参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: 变更传播标记
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestPropagate
    Expected Result: goal 变更传播到 spec/design/plan/tasks 等 6 个下游
    Evidence: .config/goal/evidence/

  Scenario: 优先级评分
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestPriorityScore
    Expected Result: 公式计算正确，P0-P3 映射正确
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): implement change propagation and priority scoring`
  - Files: `goalctl/engine/propagation.go`, `goalctl/engine/priority.go`, `goalctl/engine/change_level.go`

- [ ] 12. CI Preflight + x.go 检查

  **What to do**:
  - 实现 `engine/ci.go`：RunPreflight（CI-CHK0 ~ CI-CHK9）、RunXGoChecks（XG-CHK1 ~ XG-CHK8）、每个 check 的具体实现
  - CI-CHK0: WorkingDirClean、CHK1: Build、CHK2: UnitTests、CHK3: IntegrationTests、CHK4: Lint、CHK5: ArchRules、CHK6: DocsSync、CHK7: ChangelogSync、CHK8: EvidenceManifest、CHK9: ReleaseManifest
  - XG-CHK1: ModuleBoundary、CHK2: NoFakeImpl、CHK3: ConfigExample、CHK4: DocsChangelog、CHK5: ReleaseManifest、CHK6: GoFirst、CHK7: SecretsPath、CHK8: IssueSync
  - 实现 `cmd/goalctl/ci.go`：`goalctl ci preflight` 和 `goalctl ci verify` 命令

  **Must NOT do**:
  - 不修改 CI workflow 文件
  - 不执行实际构建（只检查文件存在性和格式）

  **Recommended Agent Profile**:
  - `category`: unspecified-high
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 9, 10, 11 并行）
  - `parallel_group`: Wave 3
  - `blocks`: [13]
  - `blocked_by`: [3, 5, 8, 9]

  **References**:
  - `docs/goal/16-ci-cd.md` — CI-CHK0-CHK9、XG-CHK1-CHK8、8 个执行阶段
  - `.config/goal/schema/rules.yaml:296-310` — CI required_jobs 列表
  - `report/goal-full-go-implementation-20260609.md` §8 — Go 实现参考

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: CI Preflight 执行
    Tool: Bash
    Steps:
      1. go test ./engine/ -run TestRunPreflight
    Expected Result: 10 个 CI-CHK 全部执行，返回 PASS/FAIL/WARN
    Evidence: .config/goal/evidence/

  Scenario: CLI ci preflight 输出
    Tool: Bash
    Steps:
      1. goalctl ci preflight --root /home/workspace/ZoneCNH
    Expected Result: 显示 10 个检查项结果
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): implement CI preflight and x.go boundary checks`
  - Files: `goalctl/engine/ci.go`, `goalctl/engine/ci_test.go`, `goalctl/cmd/goalctl/ci.go`

- [ ] 13. 现有工具迁移验证

  **What to do**:
  - 对比验证：`goalctl gate check G5` vs `gate-check.sh` 输出一致
  - 对比验证：`goalctl lint M` vs `lint-goal.sh` 输出一致
  - 对比验证：`goalctl validate GOAL GOAL-20260608-001` vs `goal-validate.py` 输出一致
  - 对比验证：`goalctl matrix coverage` vs `matrix-gen.py --check-only` 输出一致
  - 修复所有不一致项
  - 产出对比报告

  **Must NOT do**:
  - 不删除现有工具（保留为参考）
  - 不修改现有工具

  **Recommended Agent Profile**:
  - `category`: unspecified-high
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: NO（依赖所有引擎 Task）
  - `parallel_group`: Wave 4
  - `blocks`: [14]
  - `blocked_by`: [5, 6, 7, 8, 9, 10, 11, 12]

  **References**:
  - `docs/goal/tools/gate-check.sh` — 现有 Gate 检查实现
  - `docs/goal/tools/lint-goal.sh` — 现有 Lint 实现
  - `docs/goal/tools/goal-validate.py` — 现有 Validator 实现
  - `docs/goal/tools/matrix-gen.py` — 现有 Matrix 生成实现

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: Gate 检查输出对比
    Tool: Bash
    Steps:
      1. goalctl gate check G5 --root /home/workspace/ZoneCNH --format json > /tmp/go.json
      2. bash docs/goal/tools/gate-check.sh /home/workspace/ZoneCNH > /tmp/sh.txt 2>&1
      3. diff 检查关键指标一致
    Expected Result: PASS/FAIL/WARN 计数一致
    Evidence: .config/goal/evidence/

  Scenario: Lint 输出对比
    Tool: Bash
    Steps:
      1. goalctl lint M --root /home/workspace/ZoneCNH --format json > /tmp/go-lint.json
      2. bash docs/goal/tools/lint-goal.sh docs/goal/ > /tmp/sh-lint.txt 2>&1
      3. diff 检查关键指标一致
    Expected Result: 检查项结果一致
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): verify migration parity with existing shell/Python tools`
  - Files: `goalctl/migration_test.go`

- [ ] 14. self-test.sh 用例迁移

  **What to do**:
  - 将 `self-test.sh` 的 7 类 fixture 覆盖契约迁移为 Go 测试：
    1. 正例基线：shell 语法、Python 编译、Goal lint、rule drift、Goal validator strict、Matrix check-only、Gate check
    2. Matrix 负例：非法 relation、缺失 evidence
    3. Rule drift 负例：旧可执行规则字面量
    4. Gate 负例：缺少 Evidence 文件
    5. Goal validator 正例：canonical 控制面
    6. Goal validator 负例：旧字段、PENDING Gate、Risk 漏登等
    7. Release gate 正负例
  - 使用 `testdata/` 目录存放 fixture

  **Must NOT do**:
  - 不删除 self-test.sh
  - 不修改现有 fixture 格式

  **Recommended Agent Profile**:
  - `category`: unspecified-high
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: YES（与 Task 15 并行）
  - `parallel_group`: Wave 4
  - `blocks`: [15]
  - `blocked_by`: [13]

  **References**:
  - `docs/goal/tools/self-test.sh` — 现有自测实现（511 行）
  - `docs/goal/tools/README.md:161-183` — 负例 fixture 覆盖契约

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: 全部 fixture 迁移
    Tool: Bash
    Steps:
      1. go test ./... -count=1
    Expected Result: 所有测试通过，覆盖 7 类 fixture
    Evidence: .config/goal/evidence/

  Scenario: 覆盖率检查
    Tool: Bash
    Steps:
      1. go test ./... -cover
    Expected Result: 覆盖率 ≥ 80%
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `feat(goalctl): migrate self-test.sh fixtures to Go test suite`
  - Files: `goalctl/testdata/`, `goalctl/**/*_test.go`

- [ ] 15. 文档 + README + 使用示例

  **What to do**:
  - 编写 `goalctl/README.md`：项目介绍、安装方式、CLI 命令速查、配置说明
  - 编写 `goalctl/CONTRIBUTING.md`：开发环境搭建、测试运行、提交规范
  - 更新 `docs/goal/tools/README.md`：添加 goalctl 使用说明
  - 编写迁移指南：从 shell/Python 工具迁移到 goalctl

  **Must NOT do**:
  - 不删除现有工具文档
  - 不修改 docs/goal/ 的规范文档

  **Recommended Agent Profile**:
  - `category`: unspecified-high
  - `skills`: []

  **Parallelization**:
  - `can_run_in_parallel`: NO（依赖 Task 14）
  - `parallel_group`: Wave 4
  - `blocks`: [F1]
  - `blocked_by`: [14]

  **References**:
  - `docs/goal/tools/README.md` — 现有工具文档格式
  - `CONSTITUTION.md` — 提交规范

  **Acceptance Criteria**:

  **QA Scenarios:**

  ```
  Scenario: README 完整性
    Tool: Bash
    Steps:
      1. grep -c "##" goalctl/README.md
    Expected Result: 至少 8 个章节
    Evidence: .config/goal/evidence/

  Scenario: 所有命令有示例
    Tool: Bash
    Steps:
      1. grep -c "goalctl" goalctl/README.md
    Expected Result: 至少 15 个命令示例
    Evidence: .config/goal/evidence/
  ```

  **Commit**: YES
  - Message: `docs(goalctl): add README, CONTRIBUTING, and migration guide`
  - Files: `goalctl/README.md`, `goalctl/CONTRIBUTING.md`, `docs/goal/tools/README.md`

---

## Final Verification Wave

- [ ] F1. **plan compliance audit** — `advisor`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns. Check evidence files exist. Output: `Must Have [N/N] | Must NOT Have [N/N] | VERDICT`

- [ ] F2. **code quality review** — `unspecified-high`
  Run `go vet ./...`, `golangci-lint run ./...`, `go test ./... -cover`. Review files >300 lines, functions >50 lines. Check error handling, naming conventions. Output: `Issues [N] | VERDICT`

- [ ] F3. **scope fidelity check** — `deep`
  For each task: read "What to do", read actual diff. Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Output per task: `Tasks [N/N compliant] | VERDICT`

---

## Commit Strategy

- **1 commit per task**: `feat(goalctl): <description>`
- **Squash wave**: 每个 Wave 完成后 squash 为一个 commit
- **最终 commit**: `feat(goalctl): complete Goal-driven delivery system CLI`

---

## Success Criteria

### Verification Commands
```bash
# 编译
cd goalctl && go build ./cmd/goalctl/

# 测试
go test ./... -cover

# 功能验证
./goalctl validate GOAL GOAL-20260608-001
./goalctl gate check G5
./goalctl lint M
./goalctl pipeline status
./goalctl matrix coverage
./goalctl registry list goals
./goalctl ci preflight
```

### Final Checklist
- [ ] 所有 "Must Have" 已实现
- [ ] 所有 "Must NOT Have" 未出现
- [ ] `go test ./...` 通过，覆盖率 ≥ 80%
- [ ] 现有 self-test.sh 负例全部被 Go 测试覆盖
- [ ] 与 `.config/goal/schema/rules.yaml` 完全对齐
