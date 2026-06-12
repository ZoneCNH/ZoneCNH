# goalctl v1 设计文档

| 字段        | 值                                                                   |
| ----------- | -------------------------------------------------------------------- |
| Design ID   | `DESIGN-goalctl-v1`                                                  |
| Source Spec | `docs/spec/goalctl-spec.md`（`SPEC-goalctl-v1` v1.2.1）              |
| 状态        | Draft                                                                |
| Readiness   | Design Ready Candidate；Task Binding Pending；Implementation Blocked |
| 日期        | 2026-06-09                                                           |
| 权威来源    | `docs/goal/` 与 `.config/goal/schema/rules.yaml`                     |
| 输出位置    | `docs/spec/DESIGN.md`                                                |

## 0. 文档边界与权威

本文只根据 `docs/spec/goalctl-spec.md` 描述 `goalctl` v1 的实现设计，不替代 `docs/goal/` 的规范权威，也不把 `Matrix` 定义为主流程阶段。

设计遵守以下边界：

- `docs/goal/` 是 Goal 体系文档权威，只读使用。
- `.config/goal/schema/rules.yaml` 是 ID、阶段、Gate、字段约束的机器可读权威。
- `.config/goal/registry/`、`.config/goal/matrix/`、`.config/goal/gates/`、`.config/goal/evidence/`、`.config/goal/pipeline/` 是控制面输入与状态快照。
- `.config/goal/runtime/` 与 `.omx/state/` 只作为运行态缓存，不参与权威判定。
- `goalctl` 默认只读；任何写入必须显式传入 `--write`，且写入范围只限 `.config/goal/`。

## 1. 设计目标

`goalctl` 是仓库本地 CLI 控制面，用于读取 Goal 体系权威配置并输出确定性的状态、校验、Gate、Matrix、Evidence 与 Release-readiness 结果。

设计目标：

1. 权威映射可追溯：每条校验规则必须能映射到 `docs/goal/` 或 `.config/goal/schema/rules.yaml`。
2. 输出可被机器消费：所有命令支持 JSON envelope，错误码稳定。
3. 状态判定可解释：四轴状态冲突必须进入 `INCONSISTENT_STATE`。
4. Gate 与 Evidence 不可绕过：不得产生无证据 PASS，不支持 `WAIVED`。
5. 写入可回滚：写入前备份，临时文件原子替换，写后复验，失败恢复。

非目标：

- 不生成 Goal、Spec、Design、Plan、Task 的实质内容。
- 不替代 reviewer、agent、CI 或人工审批。
- 不新增阶段、Gate、registry 文件或矩阵关系。
- 不访问凭证、远程生产系统或部署环境。

## 2. 总体架构

```text
cmd/goalctl
  -> CLI Adapter
  -> Command Router
  -> Root Context Loader
  -> Domain Stores
  -> Validators / Reporters
  -> Output Renderer
  -> Exit Mapper

write-enabled command
  -> Write Planner
  -> Transaction Runner
  -> Revalidator
  -> Restore on Failure
  -> Output Renderer
```

核心原则：

- CLI 层只解析参数、构造上下文、调度命令。
- Store 层只负责从权威路径读取结构化数据。
- Validator 层只返回诊断，不直接打印或退出进程。
- Reporter 层只聚合只读结果。
- Output 层统一 envelope、text summary 与 exit code。
- Write 层独立于校验器，通过 `ChangeSet` 和 `WritePlan` 描述变更。

## 3. 模块边界

| 模块                           | 职责                                        | 主要输入                           | 主要输出                          |
| ------------------------------ | ------------------------------------------- | ---------------------------------- | --------------------------------- |
| `cmd/goalctl`                  | 进程入口                                    | argv、环境变量                     | exit code                         |
| `internal/goalctl/cli`         | 全局参数、命令路由、strict/audit/write 选项 | argv                               | `CommandSpec`                     |
| `internal/goalctl/context`     | 根目录定位、路径解析、权威来源加载          | `--root`、`--config`               | `RootContext`、`AuthorityCatalog` |
| `internal/goalctl/rules`       | schema 规则读取与投影校验                   | `rules.yaml`、文档锚点             | `SchemaRules`、诊断               |
| `internal/goalctl/registry`    | 六文件 registry 读取与字段校验              | `.config/goal/registry/*.yaml`     | `RegistryStore`、诊断             |
| `internal/goalctl/matrix`      | Matrix edge 校验、覆盖率计算                | `.config/goal/matrix/matrix.yaml`  | `MatrixGraph`、覆盖率             |
| `internal/goalctl/gate`        | G0-G11、Gate result、H-CHK 校验             | `.config/goal/gates/state.yaml`    | `GateState`、诊断                 |
| `internal/goalctl/pipeline`    | 四轴状态与 canonical phase 判定             | `.config/goal/pipeline/state.yaml` | `PipelineState`、状态结论         |
| `internal/goalctl/evidence`    | Evidence 字段、状态、证据链校验             | `.config/goal/evidence/*.md`       | `EvidenceIndex`                   |
| `internal/goalctl/lint`        | 38 条规则与 CI parity 校验入口              | 文档与配置路径                     | lint 结果                         |
| `internal/goalctl/propagation` | stale、upstream/downstream 影响分析         | registry、matrix、evidence         | stale 诊断                        |
| `internal/goalctl/report`      | release-readiness 汇总                      | gates、matrix、evidence、review    | report                            |
| `internal/goalctl/write`       | dry-run、备份、原子替换、恢复               | `ChangeSet`                        | `WriteResult`                     |
| `internal/goalctl/output`      | JSON/text envelope 与 exit code 映射        | `Result`、诊断                     | stdout/stderr、exit code          |
| `internal/goalctl/testdata`    | 固定输入与 golden 输出                      | fixtures                           | 测试数据                          |

模块之间只通过 typed model 和 diagnostic 交互，不共享可变全局状态。

## 4. 核心接口

```go
type Command interface {
    Run(ctx context.Context, root RootContext, args Args) Result
}

type Store[T any] interface {
    Load(ctx context.Context, root RootContext) (T, []Diagnostic)
}

type Validator[T any] interface {
    Validate(value T, mode ValidationMode) []Diagnostic
}

type Renderer interface {
    Render(env Envelope) ([]byte, error)
}

type WritePlanner interface {
    Plan(changeSet ChangeSet) (WritePlan, []Diagnostic)
}

type TransactionRunner interface {
    Apply(ctx context.Context, root RootContext, plan WritePlan) WriteResult
}
```

核心模型：

| 模型               | 字段要点                                                                                             | 来源                               |
| ------------------ | ---------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `RootContext`      | `Root`、`ConfigRoot`、`Strict`、`Audit`、`WriteEnabled`、`Format`                                    | CLI                                |
| `AuthorityCatalog` | 文档锚点、schema path、loaded version                                                                | `docs/goal/`、`rules.yaml`         |
| `SchemaRules`      | ID regex、阶段枚举、Gate 枚举、registry 文件清单                                                     | `.config/goal/schema/rules.yaml`   |
| `PipelineState`    | `pipeline_state`、`current_phase`、`phase_status`、`workflow_step`                                   | `.config/goal/pipeline/state.yaml` |
| `RegistryStore`    | goals、tasks、issues、releases、risks、decisions                                                     | `.config/goal/registry/`           |
| `MatrixEdge`       | `source_id`、`target_id`、`relation`、`status`、`evidence_id`、`gate_id`、`owner`、`updated_at`      | matrix                             |
| `GateState`        | `gate_id`、`result`、`requirements`、`evidence`、`h_check`                                           | gates                              |
| `EvidenceRecord`   | `evidence_id`、`test_id`、`status`、`artifact`、`validator`、`timestamp`                             | evidence                           |
| `TraceGraph`       | Goal -> Spec -> Requirement -> AC -> Task -> Prompt -> Code -> Test -> Evidence                      | registry + matrix                  |
| `Envelope`         | `command`、`status`、`exit_code`、`root`、`summary`、`results`、`warnings`、`errors`、`next_actions` | output                             |
| `Diagnostic`       | `code`、`severity`、`message`、`path`、`source`、`blocked_by`、`next_actions`                        | validators                         |
| `WritePlan`        | target files、backup files、temporary files、expected hash、revalidation commands                    | write                              |

## 5. 命令映射

| 命令          | 组件                                                 | 关键职责                                           | 只读   |
| ------------- | ---------------------------------------------------- | -------------------------------------------------- | ------ |
| `status`      | `pipeline`、`gate`、`output`                         | 输出当前状态、下一状态、允许动作、阻塞项、证据缺口 | 是     |
| `validate`    | `registry`、`matrix`、`gate`、`evidence`、`pipeline` | 聚合 audit/strict 校验                             | 是     |
| `registry`    | `registry`、`rules`                                  | 校验六文件与 required fields                       | 默认是 |
| `matrix`      | `matrix`、`evidence`                                 | 校验关系、终态、覆盖率                             | 默认是 |
| `gate`        | `gate`、`evidence`                                   | 校验 G0-G11、PASS 证据、H-CHK                      | 默认是 |
| `pipeline`    | `pipeline`                                           | 校验四轴状态和 phase 枚举                          | 默认是 |
| `evidence`    | `evidence`                                           | 校验证据字段、状态、artifact 引用                  | 默认是 |
| `lint`        | `lint`                                               | 执行 38 条规则与 CI parity 检查                    | 是     |
| `propagation` | `propagation`、`matrix`                              | 检测 stale 与影响链                                | 默认是 |
| `report`      | `report`                                             | 输出 release-readiness 报告                        | 是     |
| `doctor`      | `context`、`rules`                                   | 检查本地环境和权威文件可读性                       | 是     |
| `schema`      | `rules`                                              | 输出 schema 规则摘要和 regex                       | 是     |
| `version`     | `cli`                                                | 输出版本与构建信息                                 | 是     |

命令面完整性按 spec 第 13 节闭合：

| Command family | Required subcommands                   | Design owner                                         |
| -------------- | -------------------------------------- | ---------------------------------------------------- |
| `status`       | root status                            | `pipeline`、`output`                                 |
| `validate`     | aggregate validate                     | `registry`、`matrix`、`gate`、`evidence`、`pipeline` |
| `registry`     | `validate`、`list`、`show`             | `registry`、`rules`                                  |
| `matrix`       | `check`、`coverage`、`trace`、`render` | `matrix`、`report`                                   |
| `gate`         | `check`、`report`、`explain`           | `gate`、`evidence`                                   |
| `pipeline`     | `status`、`next`、`transition`         | `pipeline`、`write`                                  |
| `evidence`     | `check`、`report`、`list`、`link`      | `evidence`                                           |
| `lint`         | all rule runner                        | `lint`、`rules`                                      |
| `propagation`  | `check`、`mark-stale`                  | `propagation`、`write`                               |
| `report`       | `acceptance`、`release-readiness`      | `report`                                             |
| `doctor`       | environment/root/schema diagnostics    | `context`、`rules`                                   |
| `schema`       | schema summary、regex、enum            | `rules`                                              |
| `version`      | version/build metadata                 | `cli`                                                |

默认只读命令在缺少 `--write` 时不得修改任何文件；有写入能力的子命令必须先产出 dry-run 计划。

## 6. 校验设计

### 6.1 权威与状态校验

- 权威冲突以 `GOALCTL_AUTHORITY_VIOLATION` 返回。
- `Matrix` 永远不允许作为 `current_phase` 输出。
- `pipeline_state`、`current_phase`、`phase_status`、`workflow_step` 的冲突进入 `INCONSISTENT_STATE`。
- `current_phase` 只接受 11 个 canonical stage。

覆盖需求：`REQ-SPEC-goalctl-v1-001`、`REQ-SPEC-goalctl-v1-002`、`REQ-SPEC-goalctl-v1-003`、`REQ-SPEC-goalctl-v1-004`。

### 6.2 ID 与 registry 校验

- ID regex 从 `.config/goal/schema/rules.yaml` 读取。
- AC ID 必须使用 Spec 约定格式。
- registry 目录只能包含六个 YAML 权威文件。
- Goal registry 必须含 required fields。

覆盖需求：`REQ-SPEC-goalctl-v1-005`、`REQ-SPEC-goalctl-v1-006`、`REQ-SPEC-goalctl-v1-007`、`REQ-SPEC-goalctl-v1-008`。

### 6.3 Matrix 与 coverage 校验

- Edge 必须含 `source_id`、`target_id`、`relation`、`status`、`evidence_id`、`gate_id`、`owner`、`updated_at`。
- `Verified` edge 必须含 `evidence_id`。
- `Dropped` edge 必须含 `drop_reason`。
- release 前 Matrix coverage 必须大于等于 95%。

覆盖需求：`REQ-SPEC-goalctl-v1-009`、`REQ-SPEC-goalctl-v1-010`。

### 6.4 Gate、Evidence 与 Release 校验

- Gate 只接受 G0-G11 与允许结果。
- `WAIVED` 是错误。
- PASS 必须有 Evidence 支撑。
- G9/G10 必须校验 H-CHK。
- Release-readiness report 必须列出 Matrix、Gate、Evidence、Review、Rollback。

覆盖需求：`REQ-SPEC-goalctl-v1-011`、`REQ-SPEC-goalctl-v1-012`、`REQ-SPEC-goalctl-v1-013`、`REQ-SPEC-goalctl-v1-020`、`REQ-SPEC-goalctl-v1-021`。

### 6.5 输出、CI parity、lint 与传播校验

- JSON envelope 字段固定。
- 失败输出必须包含 `errors`、`blocked_by`、`next_actions`。
- CI parity 命令集合必须可映射。
- lint 暴露 38 条规则。
- propagation 检测 upstream stale 与 downstream stale。

覆盖需求：`REQ-SPEC-goalctl-v1-014`、`REQ-SPEC-goalctl-v1-018`、`REQ-SPEC-goalctl-v1-019`、`REQ-SPEC-goalctl-v1-022`、`REQ-SPEC-goalctl-v1-023`。

### 6.6 写入校验

- 缺少 `--write` 的写入请求返回 `GOALCTL_WRITE_REQUIRES_FLAG`。
- 写入范围只限 `.config/goal/`。
- 写前备份、临时文件、原子替换、写后复验、失败恢复是同一 transaction。

覆盖需求：`REQ-SPEC-goalctl-v1-015`、`REQ-SPEC-goalctl-v1-016`。

### 6.7 Change Level 校验

- CL0-CL5 与 Lite/Standard/Full 模式从规则读取。
- CL4/CL5 不能自动通过，必须输出人工审批阻塞。

覆盖需求：`REQ-SPEC-goalctl-v1-017`。

## 7. 写入事务设计

写入流程：

1. 命令构造 `ChangeSet`，不得直接写文件。
2. `WritePlanner` 检查目标路径是否在 `.config/goal/` 下。
3. 缺少 `--write` 时返回 dry-run 计划与 `GOALCTL_WRITE_REQUIRES_FLAG`。
4. 启用 `--write` 后，为每个目标文件创建 backup path 与 temporary path。
5. 写入 temporary file 并校验 expected hash。
6. 使用原子替换更新目标文件。
7. 执行同命令复验和必要的 cross-check。
8. 复验失败时恢复 backup，返回 `GOALCTL_WRITE_FAILED`。

禁止写入：

- `docs/goal/`
- `docs/spec/`
- `.git/`
- 凭证文件
- 远程端点
- 生产配置

## 8. 错误与输出映射

| 场景                       | Diagnostic code               | Exit code | Envelope status |
| -------------------------- | ----------------------------- | --------- | --------------- |
| schema rules 缺失          | `GOALCTL_SCHEMA_MISSING`      | 3         | `error`         |
| schema rules 无法解析      | `GOALCTL_SCHEMA_INVALID`      | 4         | `error`         |
| 权威冲突                   | `GOALCTL_AUTHORITY_VIOLATION` | 5         | `error`         |
| Registry 六文件之一缺失    | `GOALCTL_REGISTRY_MISSING`    | 3         | `error`         |
| Registry 字段或状态非法    | `GOALCTL_REGISTRY_INVALID`    | 1         | `error`         |
| ID 非法                    | `GOALCTL_ID_INVALID`          | 1         | `error`         |
| 四轴状态冲突               | `GOALCTL_STATE_INCONSISTENT`  | 9         | `error`         |
| Gate 阻塞                  | `GOALCTL_GATE_BLOCKED`        | 6         | `blocked`       |
| Gate 检查失败或 H-CHK 缺失 | `GOALCTL_GATE_FAIL`           | 6         | `blocked`       |
| Gate 结果值非法            | `GOALCTL_GATE_INVALID_RESULT` | 6         | `error`         |
| Matrix 关键链路未映射      | `GOALCTL_MATRIX_UNMAPPED`     | 7         | `blocked`       |
| Matrix coverage 不足       | `GOALCTL_MATRIX_COVERAGE_LOW` | 7         | `blocked`       |
| Evidence 缺失              | `GOALCTL_EVIDENCE_MISSING`    | 8         | `blocked`       |
| Evidence 字段或状态非法    | `GOALCTL_EVIDENCE_INVALID`    | 8         | `error`         |
| 写入缺少 `--write`         | `GOALCTL_WRITE_REQUIRES_FLAG` | 2         | `blocked`       |
| 写入失败                   | `GOALCTL_WRITE_FAILED`        | 10        | `error`         |

不得引入 spec 第 15.2 节之外的新 Diagnostic code；Matrix 结构错误应归入 `GOALCTL_MATRIX_UNMAPPED`、`GOALCTL_MATRIX_COVERAGE_LOW` 或 envelope `details`，不得新增单独的 Matrix-invalid 类错误码。

所有错误输出必须提供：

- `errors[]`
- `blocked_by[]`
- `next_actions[]`
- 关联 authority source 或 path

## 9. 需求到组件追溯

| Requirement               | 主组件        | 辅助组件                     | 设计判定                          |
| ------------------------- | ------------- | ---------------------------- | --------------------------------- |
| `REQ-SPEC-goalctl-v1-001` | `context`     | `rules`、`output`            | 权威源声明与冲突错误              |
| `REQ-SPEC-goalctl-v1-002` | `pipeline`    | `output`                     | Matrix 不进入 `current_phase`     |
| `REQ-SPEC-goalctl-v1-003` | `pipeline`    | `output`                     | 四轴冲突进入 `INCONSISTENT_STATE` |
| `REQ-SPEC-goalctl-v1-004` | `pipeline`    | `rules`                      | 只接受 11 个 canonical phase      |
| `REQ-SPEC-goalctl-v1-005` | `rules`       | `registry`、`matrix`         | ID regex 与重复检测               |
| `REQ-SPEC-goalctl-v1-006` | `rules`       | `matrix`                     | AC ID 格式校验                    |
| `REQ-SPEC-goalctl-v1-007` | `registry`    | `rules`                      | 六文件 registry 限定              |
| `REQ-SPEC-goalctl-v1-008` | `registry`    | `output`                     | Goal required fields              |
| `REQ-SPEC-goalctl-v1-009` | `matrix`      | `evidence`                   | edge 字段、状态、终态证据         |
| `REQ-SPEC-goalctl-v1-010` | `matrix`      | `report`                     | coverage 大于等于 95%             |
| `REQ-SPEC-goalctl-v1-011` | `gate`        | `rules`                      | G0-G11 与 `WAIVED` 禁止           |
| `REQ-SPEC-goalctl-v1-012` | `evidence`    | `rules`                      | Evidence required fields          |
| `REQ-SPEC-goalctl-v1-013` | `gate`        | `evidence`                   | PASS 必须有 Evidence              |
| `REQ-SPEC-goalctl-v1-014` | `output`      | `cli`                        | JSON envelope 固定字段            |
| `REQ-SPEC-goalctl-v1-015` | `write`       | `cli`、`output`              | 默认只读与 `--write` 门禁         |
| `REQ-SPEC-goalctl-v1-016` | `write`       | `registry`、`matrix`         | 备份、原子替换、复验、恢复        |
| `REQ-SPEC-goalctl-v1-017` | `gate`        | `rules`                      | CL0-CL5 与人工审批                |
| `REQ-SPEC-goalctl-v1-018` | `output`      | all validators               | 可执行 blocker 与 next action     |
| `REQ-SPEC-goalctl-v1-019` | `lint`        | `rules`、`commands`          | CI parity 命令映射                |
| `REQ-SPEC-goalctl-v1-020` | `report`      | `matrix`、`gate`、`evidence` | Release-readiness 报告            |
| `REQ-SPEC-goalctl-v1-021` | `gate`        | `evidence`                   | G9/G10 H-CHK                      |
| `REQ-SPEC-goalctl-v1-022` | `lint`        | `rules`                      | 38 条 lint 规则                   |
| `REQ-SPEC-goalctl-v1-023` | `propagation` | `matrix`、`registry`         | stale 传播检测                    |

## 10. 测试策略

测试分层：

1. 规则单测：ID regex、阶段枚举、Gate 结果、registry 文件清单。
2. Store 单测：缺文件、额外文件、字段缺失、非法 YAML。
3. Validator 单测：每个 `REQ-SPEC-goalctl-v1-*` 至少一个失败 fixture 与一个通过 fixture。
4. Command golden test：JSON envelope 字段、text summary、exit code。
5. Write transaction test：dry-run、缺少 `--write`、备份、恢复、禁止路径。
6. Parity test：与 `docs/goal/tools/*` 现有脚本的关键输出保持一致。

实现前置检查仍以 spec 第 22 节命令为准。代码存在后增加：

```bash
go test ./cmd/goalctl ./internal/goalctl/...
goalctl --root . --strict --format json validate
goalctl --root . --strict --format json matrix coverage
```

## 11. ADR、风险与替代方案

### DEC-20260609-001：schema-first 本地解析

决策：从 `.config/goal/schema/rules.yaml` 读取 ID、阶段、Gate、状态约束，再与 `docs/goal/` 文档锚点做 drift 校验。

拒绝方案：在代码中复制一份硬编码规则。原因是会产生第三个权威来源。

### DEC-20260609-002：写入必须先形成计划

决策：所有写入命令先生成 `WritePlan`，缺少 `--write` 时只输出计划与阻塞。

拒绝方案：命令内直接修改 YAML。原因是无法统一备份、恢复与复验。

### DEC-20260609-003：report 是只读投影

决策：`report`、`status`、`validate` 默认只读，不写回状态。

拒绝方案：report 自动修正状态。原因是会绕过 Gate 与人工审批。

| 风险                                   | 影响                     | 缓解                                               |
| -------------------------------------- | ------------------------ | -------------------------------------------------- |
| schema 与文档 drift                    | 规则判定不一致           | `rule-drift-check.py` 与 `goalctl schema` 双向检查 |
| 与现有 shell/python 脚本 parity 不一致 | CI 与 CLI 结论冲突       | 使用 golden fixture 记录脚本输出                   |
| 写入恢复失败                           | `.config/goal/` 快照受损 | hash 校验、backup、atomic replace、恢复测试        |
| registry/matrix 尚未绑定 goalctl task  | 实现不可进入             | 任务阶段先更新 registry 与 matrix 并通过 Gate      |

## 12. Readiness 判定

本文达到 Design Ready Candidate，但不是 Implementation Ready。

实现前仍需满足：

1. `docs/spec/task.md` 的候选 Task 写入 `.config/goal/registry/tasks.yaml`。
2. `docs/spec/task.md` 的候选追溯边写入 `.config/goal/matrix/matrix.yaml`。
3. G2/G3/G4/G5 对应 Gate 通过。
4. `docs/spec/goalctl-spec.md` 第 22 节命令全部通过。
5. `docs/spec/goalctl-spec.md` 第 23 节列出的 blocker 已关闭或登记例外。
