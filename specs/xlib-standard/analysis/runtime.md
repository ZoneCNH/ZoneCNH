# xlib-standard 子分析：Harness、goalcli 与 Evidence Runtime

本文件是本地分析，不是可执行规格。覆盖 Harness、goalcli 与 Evidence Runtime。

## 1. 分析边界

- gate、goalcli、ledger、manifest 均属于上游可执行体系；本仓库只保存分析快照。
- 本文件不声明任何上游裁决标准已在本仓库通过。
- gate 列表的上游索引见 `../INDEX.md`；执行证据见上游 artifact 或本目录 `REMOTE-EVIDENCE.md` 的 pinned 记录。

### 7.4 Harness

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-020 | 66 个 gate 条目 | P0 | harness.yaml 44+10+6+6 条目，MVA 为 alias |
| FR-021 | 4 个 Context Profiles | P0 | context-lite/release 等 Profile 定义 |
| FR-022 | P0 Gate 失败阻断发布 | P0 | 任一 P0 failed 则阻断 git tag |
| FR-023 | Gate 结果归档为 Evidence | P0 | 结果写入 ledger.jsonl |
| FR-024 | Release Scorecard | P0 | goalcli score 返回 0\~10.0 分 |
| FR-025 | Debt Governance Gate | P0 | make debt 返回 debt score，<9.8 阻断 |

### 7.5 Evidence Runtime

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-026 | Evidence Ledger | P0 | JSONL append-only ledger，篡改检测 |
| FR-027 | Release Manifest | P0 | make evidence 生成 latest.json 20+ 字段 |
| FR-028 | DONE with evidence 格式 | P0 | 完成声明必须使用 DONE with evidence: 格式 |
| FR-029 | 禁止无证据的 tests pass | P0 | tests pass 必须附带完整命令输出 |
| FR-030 | 禁止 skipped gate 记为 passed | P0 | skipped 不得记为 passed |
| FR-031 | 禁止 dirty workspace release | P0 | git status 有变更则阻断 release |
| FR-032 | 禁止删除失败 Evidence | P0 | append-only 策略阻止删除 |

### 7.7 Goal Runtime v3.1.1

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-040 | Goal Kernel（8 个核心对象） | P0 | Goal/Spec/Design/Plan/Task/Test/Evidence/Review |
| FR-041 | Harness Runtime | P0 | Mode Router + Gate/Command Registry + Blocking Policy |
| FR-042 | goalcli 唯一执行面 | P0 | 拒绝第二套并列执行面 |
| FR-043 | 6 个 MVA Gate | P0 | G12\~G16 按序执行，失败阻断后续 |
| FR-044 | 4-Plane 架构 | P0 | Spec→Execution→Proof→Automation 四层 |
| FR-045 | 10 个 REQ-PROOF | P0 | Proof Runtime 逐项验证 |
| FR-046 | 28 个 PR 执行包 | P1 | 5 Phase 有序排列，Phase N 未完则 N+1 不得开始 |

### 10.2 Gate Result Envelope

```json
{
  "schema_version": "1.0",
  "goal_id": "GOAL-...",
  "gate_id": "...",
  "status": "passed|failed|planned|gap",
  "exit_code": 0,
  "timestamp": "2026-06-07T...",
  "evidence_path": "..."
}
```

### 10.3 Exit Code 契约

| 退出码 | 含义 |
|--------|------|
| 0 | passed |
| 1 | failed/planned/gap |
| 2 | 非法参数 |
| 3-9 | 保留 |

### 10.4 goalcli CLI Contract

| 字段 | 要求 |
|------|------|
| 输出格式 | JSON report 符合 goalcli-report.schema.json |
| status=passed | 返回 0 |
| status=failed/planned/gap | 返回 1 |
| --verify/--strict | 遇到 planned/gap 必须阻断 |
| P0 commands | 68 个必须实现 |
| P1 commands | 26 个必须实现 |
| P2 commands | 12 个必须实现 |
| 14 个 surface | 必须同批同步 |

> 注：v0.2.0 gap ledger 中有 5 个命令处于 pending 状态（score-gate、proof-replay、depth-report、conformance-check、standard-impact-report），待后续 PR 实现。

### 11.1 Goal 对象模型

Goal 是 Goal Runtime 的核心承载对象，贯穿 Spec → Plan → Task → Evidence → Release。

| 字段          | 类型                | 必填 | 说明                                                             |
|---------------|---------------------|:----:|------------------------------------------------------------------|
| `ID`          | `string`            |  ✅  | 形如 `GOAL-YYYYMMDD-NNN`；全局唯一                               |
| `Title`       | `string`            |  ✅  | 一句话目标描述                                                   |
| `Status`      | `GoalStatus`        |  ✅  | `draft / accepted / in_progress / blocked / done / superseded`  |
| `Priority`    | `string`            |  ✅  | `P0 / P1 / P2`                                                   |
| `SpecRef`     | `string`            |  ✅  | 关联 ANALYSIS.md 路径与锚点                                          |
| `Plan`        | `[]TaskRef`         |  ⭕  | 拆解出的 Task 列表                                               |
| `Evidence`    | `[]EvidenceRef`     |  ⭕  | Evidence Ledger 行号或路径                                       |
| `CreatedAt`   | `time.Time`         |  ✅  | RFC3339                                                          |
| `UpdatedAt`   | `time.Time`         |  ✅  | RFC3339                                                          |

```go
type Goal struct {
    ID        string         `json:"id"`
    Title     string         `json:"title"`
    Status    GoalStatus     `json:"status"`
    Priority  string         `json:"priority"`
    SpecRef   string         `json:"spec_ref"`
    Plan      []TaskRef      `json:"plan,omitempty"`
    Evidence  []EvidenceRef  `json:"evidence,omitempty"`
    CreatedAt time.Time      `json:"created_at"`
    UpdatedAt time.Time      `json:"updated_at"`
}

type GoalStatus string

const (
    GoalStatusDraft       GoalStatus = "draft"
    GoalStatusAccepted    GoalStatus = "accepted"
    GoalStatusInProgress  GoalStatus = "in_progress"
    GoalStatusBlocked     GoalStatus = "blocked"
    GoalStatusDone        GoalStatus = "done"
    GoalStatusSuperseded  GoalStatus = "superseded"
)
```

**Evidence Chain 9 Goal Groups**：

| 组 | 目标              | 产出              |
|----|-------------------|-------------------|
| G1 | Goal Acceptance   | MVA Gate 1        |
| G2 | Spec Verification | Requirement ATDD  |
| G3 | Design Review     | Architecture ADR  |
| G4 | Plan Execution    | Task breakdown    |
| G5 | Task Completion   | Implementation    |
| G6 | Test Evidence     | Coverage report   |
| G7 | Review Approval   | Code review       |
| G8 | Delivery          | Release manifest  |
| G9 | Retrospective     | Lessons learned   |

### 11.2 Proof Runtime 4-Plane 架构

```text
Spec Plane → Execution Plane → Proof Plane → Automation Plane
```

> 注：Proof Runtime 当前完成度约 88-92%。10 个 REQ-PROOF 中，Facts SSOT、GateReport、Evidence Replay 已完全实现；Downstream Proof Schema、Proof Depth D0-D7 等处于设计封顶阶段，待 PR 逐步落地。

### 11.3 Goal Kernel 对象（8 个）

每个对象都是 Go struct，导出字段为 PascalCase，JSON tag 为 snake_case。

| 对象       | 必填字段（最小）                                | JSON tag 关键字            |
|------------|-------------------------------------------------|----------------------------|
| `Goal`     | 见 §11.1                                        | 同上                       |
| `Spec`     | `ID`, `Path`, `Version`, `FRs[]`                | `id / path / version`      |
| `Design`   | `ID`, `GoalID`, `ADRRefs[]`                     | `id / goal_id / adr_refs`  |
| `Plan`     | `GoalID`, `Tasks[]`                             | `goal_id / tasks`          |
| `Task`     | `ID`, `Title`, `Status`, `Owner`                | `id / title / status`      |
| `Test`     | `ID`, `TaskID`, `Kind`, `Result`                | `id / task_id / kind`      |
| `Evidence` | 见 §11.5                                        | 同 §11.5                   |
| `Review`   | `ID`, `Subject`, `Reviewer`, `Decision`         | `id / subject / decision`  |

### 11.4 Harness Runtime 对象（14 个）

`HarnessConfig`、`ModeRouter`、`GateRegistry`、`CommandRegistry`、`BlockingPolicy`、`EvidencePolicy`、`CostBudget`、`ConformanceLevel`、`RuntimeVersion`、`RuntimeConstitution`、`StopConditions`、`ExpansionPolicy`、`SimplificationPolicy`、`RuntimeBenchmark`。

完整 struct 定义由 `cmd/goalcli/internal/runtime/` 包承载；本规格只约束对象集合与边界。

### 11.5 Evidence Ledger

- **源**：`.agent/evidence/ledger.jsonl`（append-only JSONL，禁止删除失败 Evidence，FR-032）
- **派生**：`release/evidence/goalcli/`（generated packs，不是 source ledger）

每一行记录 schema（与 §14.2 truth-state、§11.7 AdoptionStatus 共享枚举）：

| 字段              | 类型     | 必填 | 说明                                                  |
|-------------------|----------|:----:|-------------------------------------------------------|
| `schema_version`  | `string` |  ✅  | 形如 `"1.0"`                                          |
| `timestamp`       | `string` |  ✅  | RFC3339                                               |
| `goal_id`         | `string` |  ✅  | 关联 Goal                                             |
| `gate_id`         | `string` |  ✅  | 关联 Gate                                             |
| `status`          | `string` |  ✅  | `passed / failed / planned / gap`                     |
| `exit_code`       | `int`    |  ✅  | 与 §10.3 一致                                          |
| `truth_state`     | `string` |  ✅  | `verified / planned / weak / violated / unverified_remote / incomplete`；详见 §14.2 / §2.1 |
| `adoption_status` | `string` |  ⭕  | 与 §11.7 AdoptionStatus 枚举一致；仅 downstream 相关 gate 必填 |
| `evidence_state`  | `string` |  ⭕  | `not_run / partial / complete`；与 §11.7 一致         |
| `evidence_path`   | `string` |  ⭕  | 派生 evidence pack 相对路径                            |
| `command`         | `string` |  ⭕  | 触发命令                                              |
| `details`         | `object` |  ⭕  | 任意 JSON 详情                                         |

```go
type EvidenceEntry struct {
    SchemaVersion   string          `json:"schema_version"`
    Timestamp       string          `json:"timestamp"`
    GoalID          string          `json:"goal_id"`
    GateID          string          `json:"gate_id"`
    Status          string          `json:"status"`
    ExitCode        int             `json:"exit_code"`
    TruthState      TruthState      `json:"truth_state"`
    AdoptionStatus  AdoptionStatus  `json:"adoption_status,omitempty"`
    EvidenceState   string          `json:"evidence_state,omitempty"`
    EvidencePath    string          `json:"evidence_path,omitempty"`
    Command         string          `json:"command,omitempty"`
    Details         map[string]any  `json:"details,omitempty"`
}

type TruthState string

const (
    TruthStateVerified         TruthState = "verified"
    TruthStatePlanned          TruthState = "planned"
    TruthStateWeak             TruthState = "weak"             // registered / baseline_scanned / dry_run_ready 等弱事实
    TruthStateViolated         TruthState = "violated"         // 弱事实尝试升级为强事实
    TruthStateUnverifiedRemote TruthState = "unverified_remote" // 远端治理不可本地证明
    TruthStateIncomplete       TruthState = "incomplete"       // manifest 字段缺失等
)
```

### 11.6 Release Manifest（latest.json）

> 本表字段对应上游 release-final 判定所需的 manifest 与 evidence pack 引用；本仓库只记录字段结构，不声明判定结果。

| 字段                          | 类型              | 必填 | 说明 / 关联 No-Go                       |
|-------------------------------|-------------------|:----:|---------------------------------------|
| `module`                      | `string`          |  ✅  | 模块名                                |
| `version`                     | `string`          |  ✅  | 形如 `v0.6.3`（NG-01 CHANGELOG 条目对应） |
| `commit`                      | `string`          |  ✅  | 40 char commit sha                    |
| `tree_sha`                    | `string`          |  ✅  | 40 char tree sha                      |
| `source_digest`               | `string`          |  ✅  | source pack sha256                    |
| `go_version`                  | `string`          |  ✅  | 编译时 Go 版本（NG-07 toolchain 漂移） |
| `generated_at`                | `string`          |  ✅  | RFC3339                               |
| `changelog_entry`             | `string`          |  ✅  | CHANGELOG.md 中本版本条目锚点（NG-01） |
| `public_api_surface`          | `object`          |  ✅  | API 冻结快照（NG-02）                  |
| `surface_classification`      | `object`          |  ✅  | stable / experimental / internal 分类（NG-03） |
| `breaking_changes`            | `[]BreakingChange`|  ⭕  | 含 migration_note（NG-04）             |
| `release_entrypoint`          | `string`          |  ✅  | 必须为 `cmd/goalcli`，不得为 `cmd/xlibgate`（NG-05 / NG-06） |
| `workflow_pins`               | `[]WorkflowPin`   |  ✅  | 每个 workflow action 的 40-char SHA（NG-08） |
| `workflow_permissions`        | `[]WorkflowPerm`  |  ✅  | 每个 workflow 的 explicit permissions（NG-09） |
| `pr_template_present`         | `bool`            |  ✅  | PR template + CODEOWNERS 存在（NG-10） |
| `registry_validation_status`  | `string`          |  ✅  | `passed / failed`（NG-11）             |
| `release_artifact_validation` | `string`          |  ✅  | `passed / failed`（NG-12）             |
| `generator_determinism`       | `object`          |  ✅  | determinism / idempotency 证据（NG-13） |
| `downstream_replays`          | `[]ReplayResult`  |  ✅  | kernel/configx/redisx replay 结果（NG-14） |
| `downstream_status`           | `[]AdoptionRecord`|  ✅  | 不得把 not_run 报告为 passed（NG-15）  |
| `p0_debt_count`               | `int`             |  ✅  | 必须 == 0（NG-16）                     |
| `truth_state_violations`      | `int`             |  ✅  | 必须 == 0（NG-17）                     |
| `manifest_blocks_present`     | `[]string`        |  ✅  | 必须含 goal/worktree/branch/cicd/governance/risk/downstream（NG-18） |
| `open_blockers`               | `[]BlockerRef`    |  ✅  | P0 blocker / RC blocker 必须为空（NG-19） |
| `rollback_policy`             | `RollbackPolicy`  |  ✅  | 回滚策略文件存在与摘要（NG-20）        |
| `docker_toolchain_parity`     | `object`          |  ✅  | parity 证明（NG-21）                   |
| `toolchain_drift_report`      | `object`          |  ✅  | docs/workflow/manifest 间一致性（NG-07 复核） |
| `trace_coverage_todo_count`   | `int`             |  ✅  | TRACEABILITY 中 `[行级证据 TODO]` 数量（NG-33 输入） |
| `checks`                      | `[]CheckResult`   |  ✅  | 各 gate 结果                          |
| `contracts`                   | `[]ContractRef`   |  ✅  | 接口 / schema 锚点                    |
| `dependencies`                | `[]Dependency`    |  ✅  | go.mod 关键 require                   |
| `tools`                       | `[]ToolPin`       |  ✅  | golangci-lint / govulncheck 等版本    |
| `standard_impact`             | `object`          |  ⭕  | 影响下游模块清单                       |
| `downstream_sync_required`    | `bool`            |  ⭕  | 是否要求下游同步                       |
| `score`                       | `float`           |  ✅  | scorecard 总分（≥ 9.8 才允许 release） |
| `workflow`                    | `string`          |  ✅  | 触发的 workflow 文件名                |
| `artifacts`                   | `[]ArtifactRef`   |  ✅  | 产物清单                              |
| `evidence_pack_ref`           | `string`          |  ✅  | 关联 evidence pack 路径（NG-22..NG-37 由 pack 覆盖） |

其余 release-final 判定项由 `evidence_pack_ref` 指向的 pack 内部 JSON 文件承载；完整裁决标准见 `../INDEX.md`。

### 17.1 测试分层（TL0-TL7）

> **命名口径**：测试分层使用前缀 `TL`（Test Layer），避免与 §16.1 领域分层 "基座 L0/L1/L2" 撞名。

| 层 | 名称 | 说明 |
|----|------|------|
| TL0 | Spec/ATDD | 验收测试驱动 |
| TL1 | Unit/TDD | 单元测试 |
| TL2 | Contract/Boundary/Security | 契约/边界/安全测试 |
| TL3 | Integration Smoke | 集成冒烟测试 |
| TL4 | Property/Fuzz/Golden | 属性/模糊/黄金测试 |
| TL5 | Compatibility/Observability | 兼容性/可观测性测试 |
| TL6 | Release Evidence | 发布证据测试 |
| TL7 | Profile-Specific Heavy | 特定 Profile 重型测试 |

### 17.2 Gate 分类（66 个 harness.yaml 条目）

| harness.yaml section | 数量 | 语义边界 |
|----------------------|------|----------|
| required_gates | 44 | required_gates 是当前权威 gate 定义来源，覆盖 fmt/vet/lint/test/race、治理、registry、Docker、release scope、evidence、version、doctor 等必跑条目 |
| extended_gates | 10 | 扩展验证，包含 property、golden、fuzz_smoke、ci_extended、release_check_extended 和 goalcli G12-G15 下游/交付条目 |
| final_gates | 6 | 发布最终判定，包含 release_score_final、release_final_check、release_preflight、score、kernel_downstream、goalcli_g16_runtime_final |
| goalcli_mva_gates | 6 | 大写 MVA alias，映射到 goalcli G12-G16 流程，不生成第二套权威 gate |

> 注：9 个 proof_depth taxonomy 条目（file_exists, command_registered, dry_run, positive_fixture, negative_fixture, mutation_fixture, live_run, evidence_replay, downstream_adoption）不计入 gate 总数。

**Context Profiles（4 个）**：

| Profile | 组合 |
|---------|------|
| context-lite | governance-check |
| context-standard | governance-check + p1-governance-check + docs-check |
| context-full | governance-check + p1-governance-check + p2-runtime-check |
| context-release | context-full + integration + dependency-check + standard-impact-check + score-check + evidence + release-evidence |

### 17.3 Profile Gates

| Profile | 库类型 | 特殊要求 |
|---------|--------|----------|
| Pure Library | kernel, testkitx | 标准测试 |
| Config Library | configx | 配置验证/脱敏 |
| Observability Library | observex | metrics/health |
| Storage Library | postgresx, redisx, taosx, ossx, clickhousex | 连接池/事务 |
| Messaging Library | kafkax | 消息语义 |

### 17.4 必需覆盖

- `go test ./...` 覆盖公共包、internal/、contracts/、testkit/ 和 examples/
- 配置校验/脱敏、typed error kind、wrapped cause、客户端创建/取消/过期/幂等关闭
- HealthCheck JSON contract、生命周期 metrics、Config.Sanitize secret 不变量（property test）
- Config 边界输入（fuzz-smoke）、HealthStatus JSON 输出（golden test）

### 17.5 TC ↔ FR 追溯矩阵（核心 P0）

> **范围**：以下表覆盖 §14 Edge Cases 与 §7.2 Go 参考模板 FR (FR-009..FR-014) 的最小用例集。其余 P0 FR 的 TC 由 harness.yaml 的 gate 输出 + Evidence pack 间接证明；本表为"代码可写"的最小用例样板，下游模块在自身 SPEC §17 沿用并扩展。

| TC ID | 测试类型 (TL) | 对应 FR / Edge | 场景 (Given/When) | 预期结果 (Then) |
|-------|---------------|----------------|--------------------|------------------|
| xlib-TC-001 | TL1 Unit | FR-009 / FR-013 | 调用 `New(ctx, Config{})` 传入零值 Config | 返回 `ErrorKindValidation`；未创建任何 goroutine/FD |
| xlib-TC-002 | TL1 Unit | FR-014 / EC-001 | 调用 `New(nil, validCfg)` 传入 nil context | 返回 `ErrorKindValidation`；panic 不被允许 |
| xlib-TC-003 | TL1 Unit | EC-002 | 调用 `New(canceledCtx, validCfg)` | 立即返回 `ErrorKindTimeout` 或 `ErrorKindUnavailable`；不发起远端连接 |
| xlib-TC-004 | TL1 Unit | EC-003 | `client.Close(ctx)` 调用 N 次（N>=2） | 幂等：每次都返回 nil；底层资源只释放一次 |
| xlib-TC-005 | TL2 Contract | FR-012 / EC-007 | `client.HealthCheck(timeoutCtx)`，timeout=1ms，下游不可用 | 返回 `status=unhealthy / degraded`，`latency_ms<=timeout+epsilon`；不挂起 |
| xlib-TC-006 | TL2 Property | FR-014 / EC-006 | 任意嵌套 `Config{Nested: {Token: rand}}` 调用 `Sanitize()` | 返回值的所有 `token / secret / password / private_key` 字段为空；原对象不被修改 |
| xlib-TC-007 | TL2 Property | FR-014 | `cfg.Sanitize()` 返回值修改其 map/slice | 原 `cfg` 字段不变（验证 deep copy） |
| xlib-TC-008 | TL2 Boundary | EC-004 / EC-005 | 并发 N goroutine 同时调用 `client.Close(ctx)` | 无 race（`go test -race` 通过）；无 panic；其中一个 Close 成功，其余幂等返回 |
| xlib-TC-009 | TL2 Security | FR-013 / 19.1 | `os.Setenv("HOME","/home/k8s")` 后调用 `New(ctx, Config{})` | enforcer 拒绝隐式读取 ``<secret-store-path>``；返回 `ErrorKindConfig` |
| xlib-TC-010 | TL4 Golden | FR-012 | `HealthCheck()` 输出 JSON | 与 `testdata/health.golden.json` 字节级一致（除 `checked_at`/`latency_ms`） |
| xlib-TC-011 | TL4 Fuzz | FR-014 | `go test -fuzz=FuzzConfigValidate` ≥ 30s | 无 panic；任何 Validate 失败都返回 `ErrorKindValidation` 而非其他 ErrorKind |
| xlib-TC-012 | TL6 Release | FR-027 / §11.6 | `goalcli release-final-check` 在缺失 manifest 任一必填字段时 | 退出码 1；evidence 记录 `truth_state=incomplete`；阻断 release |
| xlib-TC-013 | TL2 Truth-state | FR-006 / §14.2 | `adoption_status=registered` 直接尝试 → `adopted` | enforcer 拒绝；返回禁止转换原因；详见 §11.7 / FR-051 |
| xlib-TC-014 | TL2 Contract | FR-010 / §13.1 | `IsKind(err, ErrorKindTimeout)` 应用于 `WrapError(ErrorKindTimeout, cause, "")` | 返回 true；`errors.Is(err, cause)` 也必须为 true |
| xlib-TC-015 | TL1 Unit | FR-011 | `Metrics()` 返回值 | 长度 == 9；命名匹配 §19.1 表；无重复 |
| xlib-TC-016 | TL2 Boundary | FR-010 / EC-005 | 注入连接池/FD/内存上限（fake limiter），调用 `New` / `client` 操作 | 返回 `ErrorKindUnavailable` 或 `ErrorKindRateLimit`；保留 cause（`errors.Is` 命中）；进程不 OOM |
| xlib-TC-017 | TL1 Unit | FR-014 / EC-008 | `var c *Config; c.Validate()`（nil receiver） | 返回 `ErrorKindValidation`；禁止 panic（防御性检查） |

**追溯绑定**：

- 每条 TC 必须落到一个具体 Go test 函数（`Test<TC编号>` 或 `TestFR<NNN>_<scenario>`）。
- 每条 TC 必须有对应的 `Evidence Ledger` 行（FR-026 / §11.5）；失败时 `status=failed` 不得删除（FR-032）。
- 本表不替代 harness.yaml gate；harness 通过运行 `go test` + 解析 JUnit 输出消费这些 TC。
- **TC 编号命名空间**：本表的 `xlib-TC-001..xlib-TC-017` 属于 `xlib-standard` 命名空间。下游模块复用时**必须使用自身模块前缀**（如 `redisx-TC-001`），并在自身追溯表标注“继承自 `xlib-TC-NNN`”，禁止跨模块裸用测试编号。
- 下游模块至少为自身独有 FR 增补 ≥1 个模块前缀测试编号，并继承本表 `xlib-TC-001..xlib-TC-017` 作为“基础合规集”。

**无显式 TC 的 FR 处理**（traceability-check.sh 已报警的 5 条）：

| 无 TC 的 FR | 由何替代覆盖 | 证据路径 |
|-------------|--------------|----------|
| FR-001 (419 条规则) | harness gate `registry-validate` | `pack/registry-validate.json` |
| FR-002 (7 类技术债) | harness gate `debt-scan` | `pack/debt-scan.json` |
| FR-005 (8 个 REQ) | harness gate `adoption-check` | `pack/adoption-check.json` |
| FR-046 (28 个 PR 包) | 计划性 FR，由 `goal-runtime` ledger 追踪，无单元 TC | `.agent/evidence/ledger.jsonl` |
| FR-052 (20 PR 下游同步) | 计划性 FR，由 `downstream-sync-policy` gate 追踪 | `pack/downstream-sync.json` |

> 上述 5 条 FR 不在 §17.5 单元 TC 集合内是**设计选择**（gate 级而非 unit 级），但 `traceability-check.sh` 仍会标黄；本表显式列出替代证据后视为已解释，进入 Approved 前由 reviewer 复核。

---

### 18.1 Gate 成本预算

- 每个 Gate 必须有成本预算（runtime_cost_budget.yaml）
- A-Z 是 Capability Catalog，不是必经流程
- Full Mode 不得滥用，只在高风险上下文阻断

### 18.2 测试性能要求

- Race detection gate 必须通过（`go test -race`）
- 竞态/共享状态必须通过 race gate 验证（XS-CORE-010）
- 不得创建隐藏全局 client、后台 goroutine 或不可关闭资源（XS-CORE-011）

### 18.3 CI 性能约束

| 指标 | 目标 |
|------|------|
| 单 Gate 最大执行时间 | < 5 分钟 |
| 核心质量 Gates（fmt/vet/lint/test/race 等） | < 15 分钟 |
| Release Scorecard 计算 | < 30 秒 |
| Evidence Manifest 生成 | < 10 秒 |
| goalcli score --min 9.8 | < 60 秒 |

## 8. 裁决性内容迁出说明

原主文件中的裁决性清单已迁出。本仓库改由 `INDEX.md` 列出上游裁决标准位置，不在本分析中重复声明通过/失败。
