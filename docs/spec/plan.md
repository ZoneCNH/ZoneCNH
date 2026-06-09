# goalctl v1 实施计划

| 字段          | 值                                                                 |
| ------------- | ------------------------------------------------------------------ |
| Plan ID       | `PLAN-GOAL-20260609-001-v1`                                        |
| Source Spec   | `docs/spec/goalctl-spec.md`（`SPEC-goalctl-v1` v1.2.1）            |
| Source Design | `docs/spec/DESIGN.md`（`DESIGN-goalctl-v1`）                       |
| Source Tasks  | `docs/spec/task.md`                                                |
| 状态          | Draft                                                              |
| Readiness     | Plan Ready Candidate；Task Binding Pending；Implementation Blocked |
| 日期          | 2026-06-09                                                         |
| 输出位置      | `docs/spec/plan.md`                                                |

## 0. 前置条件

本计划是实施顺序与验证计划，不表示已进入开发。

进入代码阶段前必须满足：

1. `docs/spec/task.md` 中的 Task 写入 `.config/goal/registry/tasks.yaml`。
2. 23 条 Requirement 到 Task/Test/Evidence 的追溯边写入 `.config/goal/matrix/matrix.yaml`。
3. `docs/spec/goalctl-spec.md` 第 20.2 节候选 Test/Evidence ID 必须与 `docs/spec/task.md` 的 Task-scoped ID 保持一致，并在 Task Binding 时写入 registry/matrix；若 Task Binding 改号，必须登记 `replaced_by` 或 `drop_reason`。
4. G2/G3/G4/G5 对应 Gate 通过。
5. `docs/spec/goalctl-spec.md` 第 22 节命令全部通过。
6. 第 23 节 blocker 已关闭或登记受控例外。

## 1. 执行策略

实施顺序采用“只读控制面先行，写入路径最后”的策略：

1. 建立 CLI 入口、上下文、输出 envelope 和错误模型。
2. 实现 pipeline/status、ID、registry、matrix、gate 等只读校验器。
3. 接入 evidence、release report、CI parity 和 lint。
4. 在所有只读校验可运行后实现 `--write` 事务与 propagation。
5. 用 spec 第 22 节命令、Go 单测和 CLI golden test 收敛证据。

## 2. 依赖 DAG

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

依赖说明：

- `TASK-GOAL-20260609-001-001` 是所有命令的基础。
- `TASK-GOAL-20260609-001-003` 是 registry、matrix、gate 的 ID 前置。
- `TASK-GOAL-20260609-001-007` 和 `TASK-GOAL-20260609-001-008` 依赖 registry、matrix、gate 的只读模型。
- `TASK-GOAL-20260609-001-009` 必须最后实施，避免写入路径先于校验路径存在。

## 3. 里程碑

| Milestone               | 范围                                           | Task                                                         | 完成证据                                     |
| ----------------------- | ---------------------------------------------- | ------------------------------------------------------------ | -------------------------------------------- |
| M1 Foundation           | CLI、context、output、pipeline、ID             | `TASK-GOAL-20260609-001-001` 至 `TASK-GOAL-20260609-001-003` | 单测通过；status/schema JSON envelope 稳定   |
| M2 Core Validators      | registry、matrix、gate                         | `TASK-GOAL-20260609-001-004` 至 `TASK-GOAL-20260609-001-006` | 失败 fixture 和通过 fixture 均有 golden 结果 |
| M3 Evidence And Reports | evidence、release report、CI parity、lint      | `TASK-GOAL-20260609-001-007` 至 `TASK-GOAL-20260609-001-008` | report/lint 输出覆盖 spec 要求               |
| M4 Controlled Writes    | read-only gate、write transaction、propagation | `TASK-GOAL-20260609-001-009`                                 | dry-run、backup、restore、stale 检测测试通过 |
| M5 Readiness            | 端到端验证                                     | 全部 Task                                                    | spec 第 22 节命令和 goalctl CLI smoke 通过   |

## 4. Task 执行计划

| Task                         | 依赖                         | 验证命令                                                                                            | 回滚策略                                          |
| ---------------------------- | ---------------------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `TASK-GOAL-20260609-001-001` | 无                           | `go test ./cmd/goalctl ./internal/goalctl/cli ./internal/goalctl/context ./internal/goalctl/output` | 删除 CLI 入口与输出层新增代码，保留文档           |
| `TASK-GOAL-20260609-001-002` | 001                          | `go test ./internal/goalctl/pipeline ./internal/goalctl/commands`                                   | 回退 pipeline/status 文件；不影响 context/output  |
| `TASK-GOAL-20260609-001-003` | 001                          | `go test ./internal/goalctl/rules ./internal/goalctl/commands`                                      | 回退 ID validator；保留 schema 读取接口           |
| `TASK-GOAL-20260609-001-004` | 001, 003                     | `go test ./internal/goalctl/registry ./internal/goalctl/commands`                                   | 回退 registry store/validator                     |
| `TASK-GOAL-20260609-001-005` | 001, 003                     | `go test ./internal/goalctl/matrix ./internal/goalctl/commands`                                     | 回退 matrix store/coverage                        |
| `TASK-GOAL-20260609-001-006` | 001, 003                     | `go test ./internal/goalctl/gate ./internal/goalctl/commands`                                       | 回退 gate validator                               |
| `TASK-GOAL-20260609-001-007` | 001, 004, 005, 006           | `go test ./internal/goalctl/evidence ./internal/goalctl/report ./internal/goalctl/commands`         | 回退 evidence/report 组件                         |
| `TASK-GOAL-20260609-001-008` | 001, 003, 004, 005, 006      | `go test ./internal/goalctl/lint ./internal/goalctl/commands`                                       | 回退 lint runner，不改变现有脚本                  |
| `TASK-GOAL-20260609-001-009` | 001, 004, 005, 006, 007, 008 | `go test ./internal/goalctl/write ./internal/goalctl/propagation ./internal/goalctl/commands`       | 删除 write/propagation 新增代码；恢复测试 fixture |

## 5. Plan 追溯闭合表

本表用于计划评审时从实施单元反查 Requirement 与 Acceptance Criteria。测试与证据 ID 的唯一候选清单仍以 `docs/spec/task.md` 第 2 节和 `docs/spec/goalctl-spec.md` 第 20.2 节为准；Task Binding 后必须写入 `.config/goal/registry/tasks.yaml` 与 `.config/goal/matrix/matrix.yaml`。

| Task                         | Milestone | Checkpoint | Requirement                                                                   | Acceptance Criteria                                                                                | 计划验证                                                                                            |
| ---------------------------- | --------- | ---------- | ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `TASK-GOAL-20260609-001-001` | M1        | CP1        | REQ-SPEC-goalctl-v1-001<br>REQ-SPEC-goalctl-v1-014<br>REQ-SPEC-goalctl-v1-018 | AC-REQ-SPEC-goalctl-v1-001-001<br>AC-REQ-SPEC-goalctl-v1-014-001<br>AC-REQ-SPEC-goalctl-v1-018-001 | `go test ./cmd/goalctl ./internal/goalctl/cli ./internal/goalctl/context ./internal/goalctl/output` |
| `TASK-GOAL-20260609-001-002` | M1        | CP1        | REQ-SPEC-goalctl-v1-002<br>REQ-SPEC-goalctl-v1-003<br>REQ-SPEC-goalctl-v1-004 | AC-REQ-SPEC-goalctl-v1-002-001<br>AC-REQ-SPEC-goalctl-v1-003-001<br>AC-REQ-SPEC-goalctl-v1-004-001 | `go test ./internal/goalctl/pipeline ./internal/goalctl/commands`                                   |
| `TASK-GOAL-20260609-001-003` | M1        | CP1        | REQ-SPEC-goalctl-v1-005<br>REQ-SPEC-goalctl-v1-006                            | AC-REQ-SPEC-goalctl-v1-005-001<br>AC-REQ-SPEC-goalctl-v1-006-001                                   | `go test ./internal/goalctl/rules ./internal/goalctl/commands`                                      |
| `TASK-GOAL-20260609-001-004` | M2        | CP2        | REQ-SPEC-goalctl-v1-007<br>REQ-SPEC-goalctl-v1-008                            | AC-REQ-SPEC-goalctl-v1-007-001<br>AC-REQ-SPEC-goalctl-v1-008-001                                   | `go test ./internal/goalctl/registry ./internal/goalctl/commands`                                   |
| `TASK-GOAL-20260609-001-005` | M2        | CP2        | REQ-SPEC-goalctl-v1-009<br>REQ-SPEC-goalctl-v1-010                            | AC-REQ-SPEC-goalctl-v1-009-001<br>AC-REQ-SPEC-goalctl-v1-010-001                                   | `go test ./internal/goalctl/matrix ./internal/goalctl/commands`                                     |
| `TASK-GOAL-20260609-001-006` | M2        | CP2, CP5   | REQ-SPEC-goalctl-v1-011<br>REQ-SPEC-goalctl-v1-017<br>REQ-SPEC-goalctl-v1-021 | AC-REQ-SPEC-goalctl-v1-011-001<br>AC-REQ-SPEC-goalctl-v1-017-001<br>AC-REQ-SPEC-goalctl-v1-021-001 | `go test ./internal/goalctl/gate ./internal/goalctl/commands`                                       |
| `TASK-GOAL-20260609-001-007` | M3        | CP3, CP5   | REQ-SPEC-goalctl-v1-012<br>REQ-SPEC-goalctl-v1-013<br>REQ-SPEC-goalctl-v1-020 | AC-REQ-SPEC-goalctl-v1-012-001<br>AC-REQ-SPEC-goalctl-v1-013-001<br>AC-REQ-SPEC-goalctl-v1-020-001 | `go test ./internal/goalctl/evidence ./internal/goalctl/report ./internal/goalctl/commands`         |
| `TASK-GOAL-20260609-001-008` | M3        | CP3        | REQ-SPEC-goalctl-v1-019<br>REQ-SPEC-goalctl-v1-022                            | AC-REQ-SPEC-goalctl-v1-019-001<br>AC-REQ-SPEC-goalctl-v1-022-001                                   | `go test ./internal/goalctl/lint ./internal/goalctl/commands`                                       |
| `TASK-GOAL-20260609-001-009` | M4        | CP4        | REQ-SPEC-goalctl-v1-015<br>REQ-SPEC-goalctl-v1-016<br>REQ-SPEC-goalctl-v1-023 | AC-REQ-SPEC-goalctl-v1-015-001<br>AC-REQ-SPEC-goalctl-v1-016-001<br>AC-REQ-SPEC-goalctl-v1-023-001 | `go test ./internal/goalctl/write ./internal/goalctl/propagation ./internal/goalctl/commands`       |

## 6. Gate 与检查点

| Checkpoint | 时机       | Gate/检查                                                 |
| ---------- | ---------- | --------------------------------------------------------- |
| CP0        | 代码前     | G2/G3/G4/G5；spec 第 22 节命令；registry/matrix 绑定      |
| CP1        | M1 后      | G6 前置：CLI envelope、status、ID 单测                    |
| CP2        | M2 后      | G6/G7 前置：registry、matrix、gate 失败 fixture           |
| CP3        | M3 后      | G7：Evidence、report、lint、CI parity                     |
| CP4        | M4 后      | G8：write transaction、rollback、propagation              |
| CP5        | Release 前 | G9/G10/G11：H-CHK、release-readiness、retrospective input |

任何检查点失败时停止进入后续 Task，先回到失败 Task 修复并重新运行该检查点。

## 7. 风险登记

| Risk ID                      | 风险                                                            | 影响                         | 应对                                                                                    |
| ---------------------------- | --------------------------------------------------------------- | ---------------------------- | --------------------------------------------------------------------------------------- |
| `RISK-GOAL-20260609-001-001` | goalctl 的 registry Task 与 Matrix 追溯边尚未写入               | 不能进入代码阶段             | 先执行 Task Binding，运行 matrix 与 gate 校验                                           |
| `RISK-GOAL-20260609-001-002` | `.config/goal/schema/rules.yaml` 与 `docs/goal/` 文档 drift     | CLI 与现有脚本判定冲突       | 每个里程碑运行 `rule-drift-check.py`                                                    |
| `RISK-GOAL-20260609-001-003` | write transaction 失败恢复不完整                                | `.config/goal/` 文件可能损坏 | 写入只限最后任务；备份、hash、restore 单测为 P0                                         |
| `RISK-GOAL-20260609-001-004` | goalctl 与现有 shell/python 工具结果不一致                      | CI parity 失效               | 为关键 fixture 记录现有脚本输出并做 golden 比对                                         |
| `RISK-GOAL-20260609-001-005` | spec 第 20.2 节 Test/Evidence ID 与 Task-scoped ID 后续发生漂移 | Matrix 出现双套测试或证据 ID | Task Binding 阶段登记 canonical ID；若改号，为旧候选写入 `replaced_by` 或 `drop_reason` |

## 8. 文件冲突控制

- `internal/goalctl/output` 由 `TASK-GOAL-20260609-001-001` 首次创建，后续 Task 只能通过公共 API 使用。
- `internal/goalctl/commands` 是共享目录，每个 Task 只新增自己的 command 文件。
- `internal/goalctl/rules` 的 ID 规则由 `TASK-GOAL-20260609-001-003` 负责，registry/matrix/gate 不重复定义 regex。
- `internal/goalctl/write` 与 `internal/goalctl/propagation` 只由 `TASK-GOAL-20260609-001-009` 修改。
- `.config/goal/` 只在 Task Binding 或 `--write` 测试 fixture 中变更；不得由普通只读 Task 修改。

## 9. 最终验证命令

文档与控制面校验：

```bash
bash docs/goal/tools/lint-goal.sh docs/spec/goalctl-spec.md
bash docs/goal/tools/lint-goal.sh docs/spec/task.md
python3 docs/goal/tools/goal-validate.py --root . --mode audit --format text
python3 docs/goal/tools/goal-validate.py --root . --mode strict --format text
python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml
bash docs/goal/tools/gate-check.sh .
python3 docs/goal/tools/rule-drift-check.py --root .
git diff --check
```

代码存在后的 CLI 校验：

```bash
go test ./cmd/goalctl ./internal/goalctl/...
goalctl --root . --format json status
goalctl --root . --strict --format json validate
goalctl --root . --strict --format json matrix coverage
goalctl --root . --strict --format json gate check all
goalctl --root . --format json report release-readiness
```

## 10. 停止条件

可以停止并提交评审的条件：

1. `docs/spec/goalctl-spec.md`、`docs/spec/DESIGN.md`、`docs/spec/task.md`、`docs/spec/plan.md` 的追溯链闭合。
2. 所有 Requirement 在 task 覆盖表中出现。
3. 所有 Task 满足单 Task 不超过 3 条 Requirement、目标文件不超过 5 个。
4. 文档与控制面校验命令通过。
5. 若进入代码阶段，全部 Go 单测与 CLI smoke 通过。

必须停止并回退上游的条件：

1. registry/matrix 绑定失败且无法登记受控例外。
2. G2-G5 任一 Gate 无法通过。
3. 发现 spec 第 20 节 Requirement 互相冲突。
4. 写入事务不能证明失败恢复。
