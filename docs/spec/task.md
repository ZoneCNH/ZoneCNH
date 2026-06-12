# goalctl v1 Task Spec

| 字段          | 值                                                      |
| ------------- | ------------------------------------------------------- |
| Task Set ID   | `TASKSET-goalctl-v1`                                    |
| Source Spec   | `docs/spec/goalctl-spec.md`（`SPEC-goalctl-v1` v1.2.1） |
| Source Design | `docs/spec/DESIGN.md`（`DESIGN-goalctl-v1`）            |
| 状态          | Draft                                                   |
| Readiness     | Task Binding Candidate；Registry/Matrix Pending         |
| 日期          | 2026-06-09                                              |
| 输出位置      | `docs/spec/task.md`                                     |

## 0. 绑定声明

本文中的 Task、Test、Evidence ID 是候选 ID。只有写入 `.config/goal/registry/tasks.yaml`、`.config/goal/matrix/matrix.yaml` 并通过对应 Gate 后，才可作为 Goal 体系事实使用。

`goalctl-spec.md` 第 20.2 节中的 `Planned Test ID` 与 `Planned Evidence ID` 已与本文的 Task 分组候选 ID 对齐，格式为 `TEST-TASK-GOAL-20260609-001-<task>-<seq>` 与 `EVID-TEST-...`。Task Binding 写入 registry/matrix 时必须保持同一套 canonical 候选；若后续改号，必须登记 `replaced_by` 或 `drop_reason`，避免同一验收项出现双套测试 ID。

拆分约束：

- 覆盖 `SPEC-goalctl-v1` 的 23条 Requirement，并拆分为 9个候选 Task。
- 单个 Task 最多绑定 3条 Requirement。
- 单个 Task 最多声明 5个目标文件。
- 测试与实现同 Task 交付。
- Task 不跨模块；本任务集模块边界为 `goalctl`。
- 不生成 Goal、Spec、Design、Plan、Task 的实质内容。

## 1. Task 列表

```yaml
task_id: TASK-GOAL-20260609-001-001
task_name: goalctl CLI runtime and output contract
module: goalctl
status: pending
priority: P0
source:
  spec: docs/spec/goalctl-spec.md
  design: docs/spec/DESIGN.md
objective: 建立 CLI 入口、根上下文、权威来源声明、JSON envelope、错误输出和 blocker 输出。
spec_ref:
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-001
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-014
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-018
target_files:
  - cmd/goalctl/main.go
  - internal/goalctl/cli/root.go
  - internal/goalctl/context/root.go
  - internal/goalctl/output/envelope.go
  - internal/goalctl/output/envelope_test.go
acceptance_criteria:
  - AC-REQ-SPEC-goalctl-v1-001-001
  - AC-REQ-SPEC-goalctl-v1-014-001
  - AC-REQ-SPEC-goalctl-v1-018-001
test_requirement:
  - TEST-TASK-GOAL-20260609-001-001-001: authority source appears in every command result.
  - TEST-TASK-GOAL-20260609-001-001-002: JSON envelope contains command, status, exit_code, root, summary, results, warnings, errors, next_actions.
  - TEST-TASK-GOAL-20260609-001-001-003: failure output includes errors, blocked_by, and next_actions.
  - TEST-TASK-GOAL-20260609-001-001-004: doctor and version commands run read-only and return root, version, or schema diagnostics without a write plan.
evidence_candidate:
  - EVID-TEST-TASK-GOAL-20260609-001-001-001-001
  - EVID-TEST-TASK-GOAL-20260609-001-001-002-001
  - EVID-TEST-TASK-GOAL-20260609-001-001-003-001
  - EVID-TEST-TASK-GOAL-20260609-001-001-004-001
depends_on: []
validation:
  - go test ./cmd/goalctl ./internal/goalctl/cli ./internal/goalctl/context ./internal/goalctl/output
```

```yaml
task_id: TASK-GOAL-20260609-001-002
task_name: pipeline state and status model
module: goalctl
status: pending
priority: P0
source:
  spec: docs/spec/goalctl-spec.md
  design: docs/spec/DESIGN.md
objective: 实现四轴状态模型、canonical phase 校验、status 命令和状态冲突诊断。
spec_ref:
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-002
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-003
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-004
target_files:
  - internal/goalctl/pipeline/state.go
  - internal/goalctl/pipeline/status.go
  - internal/goalctl/pipeline/state_test.go
  - internal/goalctl/commands/status.go
  - internal/goalctl/testdata/status/README.md
acceptance_criteria:
  - AC-REQ-SPEC-goalctl-v1-002-001
  - AC-REQ-SPEC-goalctl-v1-003-001
  - AC-REQ-SPEC-goalctl-v1-004-001
test_requirement:
  - TEST-TASK-GOAL-20260609-001-002-001: status never reports Matrix as current_phase.
  - TEST-TASK-GOAL-20260609-001-002-002: conflicting four-axis state returns INCONSISTENT_STATE and GOALCTL_STATE_INCONSISTENT.
  - TEST-TASK-GOAL-20260609-001-002-003: unknown current_phase fails validation.
evidence_candidate:
  - EVID-TEST-TASK-GOAL-20260609-001-002-001-001
  - EVID-TEST-TASK-GOAL-20260609-001-002-002-001
  - EVID-TEST-TASK-GOAL-20260609-001-002-003-001
depends_on:
  - TASK-GOAL-20260609-001-001
validation:
  - go test ./internal/goalctl/pipeline ./internal/goalctl/commands
```

```yaml
task_id: TASK-GOAL-20260609-001-003
task_name: canonical ID and AC validation
module: goalctl
status: pending
priority: P0
source:
  spec: docs/spec/goalctl-spec.md
  design: docs/spec/DESIGN.md
objective: 从 schema 读取 ID 规则，校验 Goal/Spec/Design/Plan/Task/Test/Evidence 与 AC ID。
spec_ref:
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-005
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-006
target_files:
  - internal/goalctl/rules/ids.go
  - internal/goalctl/rules/ids_test.go
  - internal/goalctl/commands/schema.go
  - internal/goalctl/testdata/ids/README.md
acceptance_criteria:
  - AC-REQ-SPEC-goalctl-v1-005-001
  - AC-REQ-SPEC-goalctl-v1-006-001
test_requirement:
  - TEST-TASK-GOAL-20260609-001-003-001: invalid canonical ID returns GOALCTL_ID_INVALID.
  - TEST-TASK-GOAL-20260609-001-003-002: invalid AC ID returns GOALCTL_ID_INVALID.
evidence_candidate:
  - EVID-TEST-TASK-GOAL-20260609-001-003-001-001
  - EVID-TEST-TASK-GOAL-20260609-001-003-002-001
depends_on:
  - TASK-GOAL-20260609-001-001
validation:
  - go test ./internal/goalctl/rules ./internal/goalctl/commands
```

```yaml
task_id: TASK-GOAL-20260609-001-004
task_name: registry store and required-field validation
module: goalctl
status: pending
priority: P0
source:
  spec: docs/spec/goalctl-spec.md
  design: docs/spec/DESIGN.md
objective: 校验 registry 六文件清单、额外文件、缺失文件和 Goal required fields。
spec_ref:
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-007
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-008
target_files:
  - internal/goalctl/registry/store.go
  - internal/goalctl/registry/validate.go
  - internal/goalctl/registry/validate_test.go
  - internal/goalctl/commands/registry.go
  - internal/goalctl/testdata/registry/README.md
acceptance_criteria:
  - AC-REQ-SPEC-goalctl-v1-007-001
  - AC-REQ-SPEC-goalctl-v1-008-001
test_requirement:
  - TEST-TASK-GOAL-20260609-001-004-001: registry directory rejects files outside the six YAML authority files.
  - TEST-TASK-GOAL-20260609-001-004-002: missing Goal required field returns structured error.
evidence_candidate:
  - EVID-TEST-TASK-GOAL-20260609-001-004-001-001
  - EVID-TEST-TASK-GOAL-20260609-001-004-002-001
depends_on:
  - TASK-GOAL-20260609-001-001
  - TASK-GOAL-20260609-001-003
validation:
  - go test ./internal/goalctl/registry ./internal/goalctl/commands
```

```yaml
task_id: TASK-GOAL-20260609-001-005
task_name: matrix validation and coverage
module: goalctl
status: pending
priority: P0
source:
  spec: docs/spec/goalctl-spec.md
  design: docs/spec/DESIGN.md
objective: 校验 Matrix edge 字段、关系、状态、终态证据与 release coverage 门槛。
spec_ref:
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-009
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-010
target_files:
  - internal/goalctl/matrix/store.go
  - internal/goalctl/matrix/coverage.go
  - internal/goalctl/matrix/coverage_test.go
  - internal/goalctl/commands/matrix.go
  - internal/goalctl/testdata/matrix/README.md
acceptance_criteria:
  - AC-REQ-SPEC-goalctl-v1-009-001
  - AC-REQ-SPEC-goalctl-v1-010-001
test_requirement:
  - TEST-TASK-GOAL-20260609-001-005-001: Verified without evidence_id and Dropped without drop_reason fail with exit 7.
  - TEST-TASK-GOAL-20260609-001-005-002: coverage below 95 percent returns GOALCTL_MATRIX_COVERAGE_LOW.
evidence_candidate:
  - EVID-TEST-TASK-GOAL-20260609-001-005-001-001
  - EVID-TEST-TASK-GOAL-20260609-001-005-002-001
depends_on:
  - TASK-GOAL-20260609-001-001
  - TASK-GOAL-20260609-001-003
validation:
  - go test ./internal/goalctl/matrix ./internal/goalctl/commands
```

```yaml
task_id: TASK-GOAL-20260609-001-006
task_name: gate, change-level, and H-CHK validation
module: goalctl
status: pending
priority: P0
source:
  spec: docs/spec/goalctl-spec.md
  design: docs/spec/DESIGN.md
objective: 校验 G0-G11、Gate result、WAIVED 禁止、CL0-CL5 与 G9/G10 H-CHK。
spec_ref:
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-011
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-017
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-021
target_files:
  - internal/goalctl/gate/state.go
  - internal/goalctl/gate/hcheck.go
  - internal/goalctl/gate/state_test.go
  - internal/goalctl/commands/gate.go
  - internal/goalctl/testdata/gate/README.md
acceptance_criteria:
  - AC-REQ-SPEC-goalctl-v1-011-001
  - AC-REQ-SPEC-goalctl-v1-017-001
  - AC-REQ-SPEC-goalctl-v1-021-001
test_requirement:
  - TEST-TASK-GOAL-20260609-001-006-001: WAIVED gate result is rejected.
  - TEST-TASK-GOAL-20260609-001-006-002: CL4 or CL5 returns human approval blocker.
  - TEST-TASK-GOAL-20260609-001-006-003: G9 and G10 require H-CHK evidence.
evidence_candidate:
  - EVID-TEST-TASK-GOAL-20260609-001-006-001-001
  - EVID-TEST-TASK-GOAL-20260609-001-006-002-001
  - EVID-TEST-TASK-GOAL-20260609-001-006-003-001
depends_on:
  - TASK-GOAL-20260609-001-001
  - TASK-GOAL-20260609-001-003
validation:
  - go test ./internal/goalctl/gate ./internal/goalctl/commands
```

```yaml
task_id: TASK-GOAL-20260609-001-007
task_name: evidence validation and release report
module: goalctl
status: pending
priority: P1
source:
  spec: docs/spec/goalctl-spec.md
  design: docs/spec/DESIGN.md
objective: 校验 Evidence required fields、无证据 PASS，并生成 release-readiness 报告。
spec_ref:
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-012
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-013
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-020
target_files:
  - internal/goalctl/evidence/store.go
  - internal/goalctl/evidence/validate.go
  - internal/goalctl/report/release.go
  - internal/goalctl/report/release_test.go
  - internal/goalctl/commands/report.go
acceptance_criteria:
  - AC-REQ-SPEC-goalctl-v1-012-001
  - AC-REQ-SPEC-goalctl-v1-013-001
  - AC-REQ-SPEC-goalctl-v1-020-001
test_requirement:
  - TEST-TASK-GOAL-20260609-001-007-001: evidence missing required field returns structured error.
  - TEST-TASK-GOAL-20260609-001-007-002: PASS gate without evidence fails.
  - TEST-TASK-GOAL-20260609-001-007-003: release report includes Matrix, Gate, Evidence, Review, Rollback.
evidence_candidate:
  - EVID-TEST-TASK-GOAL-20260609-001-007-001-001
  - EVID-TEST-TASK-GOAL-20260609-001-007-002-001
  - EVID-TEST-TASK-GOAL-20260609-001-007-003-001
depends_on:
  - TASK-GOAL-20260609-001-001
  - TASK-GOAL-20260609-001-004
  - TASK-GOAL-20260609-001-005
  - TASK-GOAL-20260609-001-006
validation:
  - go test ./internal/goalctl/evidence ./internal/goalctl/report ./internal/goalctl/commands
```

```yaml
task_id: TASK-GOAL-20260609-001-008
task_name: CI parity and lint rule runner
module: goalctl
status: pending
priority: P1
source:
  spec: docs/spec/goalctl-spec.md
  design: docs/spec/DESIGN.md
objective: 暴露 CI parity 命令集合和 38 条 lint rule 的 CLI 运行结果。
spec_ref:
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-019
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-022
target_files:
  - internal/goalctl/lint/rules.go
  - internal/goalctl/lint/runner.go
  - internal/goalctl/lint/runner_test.go
  - internal/goalctl/commands/lint.go
  - internal/goalctl/testdata/lint/README.md
acceptance_criteria:
  - AC-REQ-SPEC-goalctl-v1-019-001
  - AC-REQ-SPEC-goalctl-v1-022-001
test_requirement:
  - TEST-TASK-GOAL-20260609-001-008-001: command output lists yaml-lint, registry-check, rule-drift-check, goal-validator, id-format-check, matrix-coverage, gate-check, orphan-check, agent-check, docs-check.
  - TEST-TASK-GOAL-20260609-001-008-002: lint command exposes 38 rule IDs and failing fixtures.
evidence_candidate:
  - EVID-TEST-TASK-GOAL-20260609-001-008-001-001
  - EVID-TEST-TASK-GOAL-20260609-001-008-002-001
depends_on:
  - TASK-GOAL-20260609-001-001
  - TASK-GOAL-20260609-001-003
  - TASK-GOAL-20260609-001-004
  - TASK-GOAL-20260609-001-005
  - TASK-GOAL-20260609-001-006
validation:
  - go test ./internal/goalctl/lint ./internal/goalctl/commands
```

```yaml
task_id: TASK-GOAL-20260609-001-009
task_name: read-only default, write transaction, and propagation
module: goalctl
status: pending
priority: P1
source:
  spec: docs/spec/goalctl-spec.md
  design: docs/spec/DESIGN.md
objective: 实现默认只读门禁、写入事务、失败恢复和 propagation stale 检测。
spec_ref:
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-015
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-016
  - docs/spec/goalctl-spec.md#REQ-SPEC-goalctl-v1-023
target_files:
  - internal/goalctl/write/plan.go
  - internal/goalctl/write/transaction.go
  - internal/goalctl/propagation/stale.go
  - internal/goalctl/write/transaction_test.go
  - internal/goalctl/commands/propagation.go
acceptance_criteria:
  - AC-REQ-SPEC-goalctl-v1-015-001
  - AC-REQ-SPEC-goalctl-v1-016-001
  - AC-REQ-SPEC-goalctl-v1-023-001
test_requirement:
  - TEST-TASK-GOAL-20260609-001-009-001: write request without --write returns GOALCTL_WRITE_REQUIRES_FLAG and no file change.
  - TEST-TASK-GOAL-20260609-001-009-002: failed write restores backup and returns GOALCTL_WRITE_FAILED.
  - TEST-TASK-GOAL-20260609-001-009-003: upstream and downstream stale states are reported with source and target IDs.
evidence_candidate:
  - EVID-TEST-TASK-GOAL-20260609-001-009-001-001
  - EVID-TEST-TASK-GOAL-20260609-001-009-002-001
  - EVID-TEST-TASK-GOAL-20260609-001-009-003-001
depends_on:
  - TASK-GOAL-20260609-001-001
  - TASK-GOAL-20260609-001-004
  - TASK-GOAL-20260609-001-005
  - TASK-GOAL-20260609-001-006
  - TASK-GOAL-20260609-001-007
  - TASK-GOAL-20260609-001-008
validation:
  - go test ./internal/goalctl/write ./internal/goalctl/propagation ./internal/goalctl/commands
```

## 2. Requirement 覆盖表

`Gate` 列表示 Task Binding 阶段应写入 Matrix/Gate 的验证门禁，不等同于 `goalctl-spec.md` 第 20.2 节的 `Goal/Source` 来源标签；来源标签仍以 spec 为准。

| Requirement               | Task                         | Test                                  | Gate   |
| ------------------------- | ---------------------------- | ------------------------------------- | ------ |
| `REQ-SPEC-goalctl-v1-001` | `TASK-GOAL-20260609-001-001` | `TEST-TASK-GOAL-20260609-001-001-001` | G3     |
| `REQ-SPEC-goalctl-v1-002` | `TASK-GOAL-20260609-001-002` | `TEST-TASK-GOAL-20260609-001-002-001` | G3     |
| `REQ-SPEC-goalctl-v1-003` | `TASK-GOAL-20260609-001-002` | `TEST-TASK-GOAL-20260609-001-002-002` | G3     |
| `REQ-SPEC-goalctl-v1-004` | `TASK-GOAL-20260609-001-002` | `TEST-TASK-GOAL-20260609-001-002-003` | G3     |
| `REQ-SPEC-goalctl-v1-005` | `TASK-GOAL-20260609-001-003` | `TEST-TASK-GOAL-20260609-001-003-001` | G3     |
| `REQ-SPEC-goalctl-v1-006` | `TASK-GOAL-20260609-001-003` | `TEST-TASK-GOAL-20260609-001-003-002` | G3     |
| `REQ-SPEC-goalctl-v1-007` | `TASK-GOAL-20260609-001-004` | `TEST-TASK-GOAL-20260609-001-004-001` | G4     |
| `REQ-SPEC-goalctl-v1-008` | `TASK-GOAL-20260609-001-004` | `TEST-TASK-GOAL-20260609-001-004-002` | G4     |
| `REQ-SPEC-goalctl-v1-009` | `TASK-GOAL-20260609-001-005` | `TEST-TASK-GOAL-20260609-001-005-001` | G4     |
| `REQ-SPEC-goalctl-v1-010` | `TASK-GOAL-20260609-001-005` | `TEST-TASK-GOAL-20260609-001-005-002` | G4     |
| `REQ-SPEC-goalctl-v1-011` | `TASK-GOAL-20260609-001-006` | `TEST-TASK-GOAL-20260609-001-006-001` | G5     |
| `REQ-SPEC-goalctl-v1-012` | `TASK-GOAL-20260609-001-007` | `TEST-TASK-GOAL-20260609-001-007-001` | G7     |
| `REQ-SPEC-goalctl-v1-013` | `TASK-GOAL-20260609-001-007` | `TEST-TASK-GOAL-20260609-001-007-002` | G7     |
| `REQ-SPEC-goalctl-v1-014` | `TASK-GOAL-20260609-001-001` | `TEST-TASK-GOAL-20260609-001-001-002` | G6     |
| `REQ-SPEC-goalctl-v1-015` | `TASK-GOAL-20260609-001-009` | `TEST-TASK-GOAL-20260609-001-009-001` | G8     |
| `REQ-SPEC-goalctl-v1-016` | `TASK-GOAL-20260609-001-009` | `TEST-TASK-GOAL-20260609-001-009-002` | G8     |
| `REQ-SPEC-goalctl-v1-017` | `TASK-GOAL-20260609-001-006` | `TEST-TASK-GOAL-20260609-001-006-002` | G5     |
| `REQ-SPEC-goalctl-v1-018` | `TASK-GOAL-20260609-001-001` | `TEST-TASK-GOAL-20260609-001-001-003` | G6     |
| `REQ-SPEC-goalctl-v1-019` | `TASK-GOAL-20260609-001-008` | `TEST-TASK-GOAL-20260609-001-008-001` | G7     |
| `REQ-SPEC-goalctl-v1-020` | `TASK-GOAL-20260609-001-007` | `TEST-TASK-GOAL-20260609-001-007-003` | G10    |
| `REQ-SPEC-goalctl-v1-021` | `TASK-GOAL-20260609-001-006` | `TEST-TASK-GOAL-20260609-001-006-003` | G9/G10 |
| `REQ-SPEC-goalctl-v1-022` | `TASK-GOAL-20260609-001-008` | `TEST-TASK-GOAL-20260609-001-008-002` | G7     |
| `REQ-SPEC-goalctl-v1-023` | `TASK-GOAL-20260609-001-009` | `TEST-TASK-GOAL-20260609-001-009-003` | G8     |

## 3. 命令面覆盖表

| Command family | Owning Task                                                                                | 覆盖说明                                                              |
| -------------- | ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- |
| `status`       | `TASK-GOAL-20260609-001-002`                                                               | `status` 与 `pipeline status` 输出四轴状态、下一动作、阻塞项          |
| `validate`     | `TASK-GOAL-20260609-001-001`、`TASK-GOAL-20260609-001-004` 至 `TASK-GOAL-20260609-001-008` | 聚合 registry/matrix/gate/evidence/lint/CI parity 校验，复用 envelope |
| `registry`     | `TASK-GOAL-20260609-001-004`                                                               | `validate`、`list`、`show` 等只读 registry 入口                       |
| `matrix`       | `TASK-GOAL-20260609-001-005`                                                               | `check`、`coverage`、`trace`、`render`                                |
| `gate`         | `TASK-GOAL-20260609-001-006`                                                               | `check`、`report`、`explain`，含 G9/G10 H-CHK                         |
| `pipeline`     | `TASK-GOAL-20260609-001-002`、`TASK-GOAL-20260609-001-009`                                 | `status`、`next` 只读；`transition` 写入路径由事务保护                |
| `evidence`     | `TASK-GOAL-20260609-001-007`                                                               | `check`、`report`、`list`、`link`                                     |
| `lint`         | `TASK-GOAL-20260609-001-008`                                                               | 执行 38 条规则并与 CI parity 对齐                                     |
| `propagation`  | `TASK-GOAL-20260609-001-009`                                                               | `check`/`mark-stale` 的只读与写入保护                                 |
| `report`       | `TASK-GOAL-20260609-001-007`                                                               | `acceptance` 与 `release-readiness`                                   |
| `doctor`       | `TASK-GOAL-20260609-001-001`                                                               | 环境、authority source、schema/root 可读性诊断，只读                  |
| `schema`       | `TASK-GOAL-20260609-001-003`                                                               | schema summary、regex、allowed enum 输出                              |
| `version`      | `TASK-GOAL-20260609-001-001`                                                               | 版本和构建信息输出，只读                                              |

## 4. Task 依赖图

```text
TASK-GOAL-20260609-001-001
  -> TASK-GOAL-20260609-001-002
  -> TASK-GOAL-20260609-001-003
       -> TASK-GOAL-20260609-001-004
       -> TASK-GOAL-20260609-001-005
       -> TASK-GOAL-20260609-001-006
            -> TASK-GOAL-20260609-001-007
            -> TASK-GOAL-20260609-001-008
                 -> TASK-GOAL-20260609-001-009
```

串行约束：

- `TASK-GOAL-20260609-001-001` 先交付，因所有命令共用 envelope 与 context。
- `TASK-GOAL-20260609-001-003` 先于 registry、matrix、gate 校验，因这些校验依赖 canonical ID。
- 写入事务只在只读校验、Evidence、Report 和 lint 路径存在后实施。

## 5. Task Readiness

当前 Task Set 是候选拆分，尚未 Implementation Ready。

进入开发前必须完成：

1. 把 9 个 Task 写入 `.config/goal/registry/tasks.yaml`。
2. 把 23 条 Requirement 到 Task/Test 的边写入 `.config/goal/matrix/matrix.yaml`。
3. 核对 spec 第 20.2 节 Test/Evidence ID 与本文 Task-scoped ID 一致；若 Task Binding 改号，为废弃候选登记 `replaced_by` 或 `drop_reason`。
4. 更新对应 Evidence 候选或标注 pending。
5. 运行 `docs/spec/goalctl-spec.md` 第 22 节校验命令。
6. 对 G3、G4、G5 得到可审计 Gate 结论。
