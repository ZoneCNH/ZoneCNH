# xlib-standard 子分析：Harness、goalcli 与 Evidence Runtime

本文件是本地分析，不是可执行规格。覆盖 Harness、goalcli 与 Evidence Runtime。

- Snapshot-Date: 2026-06-08
- Upstream-Commit: `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` (v0.6.5)
- Analysis-Version: v3.1.0
- Parent: ../ANALYSIS.md

## 1. 分析边界

- gate、goalcli、ledger、manifest 均属于上游可执行体系；本仓库只保存分析快照。
- 本文件不声明任何上游裁决标准已在本仓库通过。
- gate 列表的上游索引见 `../INDEX.md`；执行证据见上游 artifact 或 `../REMOTE-EVIDENCE.md` 的 pinned 记录。
- 完整 FR WHEN/THEN 详见 `../FR-DETAIL.md`；完整裁决标准详见上游 `docs/standard/release-standard.md`。

## 2. 覆盖职责（FR 摘要）

### 2.1 Harness

> 权威来源：`../FR-DETAIL.md` FR-020..FR-025。

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-020 | 66 个 gate 条目 | P0 | harness.yaml 44+10+6+6 条目，MVA 为 alias |
| FR-021 | 4 个 Context Profiles | P0 | context-lite/release 等 Profile 定义 |
| FR-022 | P0 Gate 失败阻断发布 | P0 | 任一 P0 failed 则阻断 git tag |
| FR-023 | Gate 结果归档为 Evidence | P0 | 结果写入 ledger.jsonl |
| FR-024 | Release Scorecard | P0 | goalcli score 返回 0~10.0 分 |
| FR-025 | Debt Governance Gate | P0 | make debt 返回 debt score，<9.8 阻断 |

### 2.2 Evidence Runtime

> 权威来源：`../FR-DETAIL.md` FR-026..FR-032。

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-026 | Evidence Ledger | P0 | JSONL append-only ledger，篡改检测 |
| FR-027 | Release Manifest | P0 | make evidence 生成 latest.json 20+ 字段 |
| FR-028 | DONE with evidence 格式 | P0 | 完成声明必须使用 DONE with evidence: 格式 |
| FR-029 | 禁止无证据的 tests pass | P0 | tests pass 必须附带完整命令输出 |
| FR-030 | 禁止 skipped gate 记为 passed | P0 | skipped 不得记为 passed |
| FR-031 | 禁止 dirty workspace release | P0 | git status 有变更则阻断 release |
| FR-032 | 禁止删除失败 Evidence | P0 | append-only 策略阻止删除 |

### 2.3 Goal Runtime v3.1.1

> 权威来源：`../FR-DETAIL.md` FR-040..FR-046。

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-040 | Goal Kernel（8 个核心对象） | P0 | Goal/Spec/Design/Plan/Task/Test/Evidence/Review |
| FR-041 | Harness Runtime | P0 | Mode Router + Gate/Command Registry + Blocking Policy |
| FR-042 | goalcli 唯一执行面 | P0 | 拒绝第二套并列执行面 |
| FR-043 | 6 个 MVA Gate | P0 | G12~G16 按序执行，失败阻断后续 |
| FR-044 | 4-Plane 架构 | P0 | Spec→Execution→Proof→Automation 四层 |
| FR-045 | 10 个 REQ-PROOF | P0 | Proof Runtime 逐项验证 |
| FR-046 | 28 个 PR 执行包 | P1 | 5 Phase 有序排列，Phase N 未完则 N+1 不得开始 |

## 3. Harness / goalcli / Evidence 契约正文

### 3.1 Gate 分类（66 个 harness.yaml 条目）

| harness.yaml section | 数量 | 语义边界 |
|----------------------|------|----------|
| required_gates | 44 | 当前权威 gate 定义来源，覆盖 fmt/vet/lint/test/race、治理、registry、Docker、release scope、evidence、version、doctor 等必跑条目 |
| extended_gates | 10 | 扩展验证，包含 property、golden、fuzz_smoke、ci_extended、release_check_extended 和 goalcli G12-G15 下游/交付条目 |
| final_gates | 6 | 发布最终判定，包含 release_score_final、release_final_check、release_preflight、score、kernel_downstream、goalcli_g16_runtime_final |
| goalcli_mva_gates | 6 | 大写 MVA alias，映射到 goalcli G12-G16 流程，不生成第二套权威 gate |

9 个 proof_depth taxonomy 条目（file_exists, command_registered, dry_run, positive_fixture, negative_fixture, mutation_fixture, live_run, evidence_replay, downstream_adoption）不计入 gate 总数。

### 3.2 Gate Result Envelope 与 Exit Code

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

| 退出码 | 含义 |
|--------|------|
| 0 | passed |
| 1 | failed/planned/gap |
| 2 | 非法参数 |
| 3-9 | 保留 |

### 3.3 goalcli CLI Contract

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

v0.2.0 gap ledger 中有 5 个命令处于 pending 状态（score-gate、proof-replay、depth-report、conformance-check、standard-impact-report），待后续 PR 实现。

### 3.4 Goal Runtime 与 Proof Runtime

Goal 是 Goal Runtime 的核心承载对象，贯穿 Spec → Plan → Task → Evidence → Release。

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| `ID` | `string` | ✅ | 形如 `GOAL-YYYYMMDD-NNN`；全局唯一 |
| `Title` | `string` | ✅ | 一句话目标描述 |
| `Status` | `GoalStatus` | ✅ | `draft / accepted / in_progress / blocked / done / superseded` |
| `Priority` | `string` | ✅ | `P0 / P1 / P2` |
| `SpecRef` | `string` | ✅ | 关联 ANALYSIS.md 路径与锚点 |
| `Plan` | `[]TaskRef` | ⭕ | 拆解出的 Task 列表 |
| `Evidence` | `[]EvidenceRef` | ⭕ | Evidence Ledger 行号或路径 |
| `CreatedAt` | `time.Time` | ✅ | RFC3339 |
| `UpdatedAt` | `time.Time` | ✅ | RFC3339 |

Proof Runtime 采用 4-Plane 架构：

```text
Spec Plane → Execution Plane → Proof Plane → Automation Plane
```

Goal Kernel 对象包括 `Goal`、`Spec`、`Design`、`Plan`、`Task`、`Test`、`Evidence`、`Review`。Harness Runtime 对象包括 `HarnessConfig`、`ModeRouter`、`GateRegistry`、`CommandRegistry`、`BlockingPolicy`、`EvidencePolicy`、`CostBudget`、`ConformanceLevel`、`RuntimeVersion`、`RuntimeConstitution`、`StopConditions`、`ExpansionPolicy`、`SimplificationPolicy`、`RuntimeBenchmark`。

### 3.5 Evidence Ledger

- **源**：`.agent/evidence/ledger.jsonl`（append-only JSONL，禁止删除失败 Evidence，FR-032）。
- **派生**：`release/evidence/goalcli/`（generated packs，不是 source ledger）。

每一行记录 schema：

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| `schema_version` | `string` | ✅ | 形如 `"1.0"` |
| `timestamp` | `string` | ✅ | RFC3339 |
| `goal_id` | `string` | ✅ | 关联 Goal |
| `gate_id` | `string` | ✅ | 关联 Gate |
| `status` | `string` | ✅ | `passed / failed / planned / gap` |
| `exit_code` | `int` | ✅ | 与 §3.2 一致 |
| `truth_state` | `string` | ✅ | `verified / planned / weak / violated / unverified_remote / incomplete` |
| `adoption_status` | `string` | ⭕ | 与 `analysis/governance.md` §3.2 AdoptionStatus 枚举一致 |
| `evidence_state` | `string` | ⭕ | `not_run / partial / complete` |
| `evidence_path` | `string` | ⭕ | 派生 evidence pack 相对路径 |
| `command` | `string` | ⭕ | 触发命令 |
| `details` | `object` | ⭕ | 任意 JSON 详情 |

### 3.6 Release Manifest（latest.json）

上游 release-final 判定所需 manifest 与 evidence pack 引用至少覆盖 module/version/commit/tree/source digest、toolchain、CHANGELOG、API surface、workflow pins/permissions、registry validation、release artifact validation、generator determinism、downstream replay/status、P0 debt、truth-state violations、manifest blocks、open blockers、rollback、Docker parity、trace coverage、checks/contracts/dependencies/tools、score、workflow、artifacts 与 evidence_pack_ref。

完整 No-Go / Release 裁决标准不在本地分析中复制，详见上游 `docs/standard/release-standard.md`。

### 3.7 Context Profiles

| Profile | 组合 |
|---------|------|
| context-lite | governance-check |
| context-standard | governance-check + p1-governance-check + docs-check |
| context-full | governance-check + p1-governance-check + p2-runtime-check |
| context-release | context-full + integration + dependency-check + standard-impact-check + score-check + evidence + release-evidence |

### 3.8 性能与成本预算

| 指标 | 目标 |
|------|------|
| 单 Gate 最大执行时间 | < 5 分钟 |
| 核心质量 Gates（fmt/vet/lint/test/race 等） | < 15 分钟 |
| Release Scorecard 计算 | < 30 秒 |
| Evidence Manifest 生成 | < 10 秒 |
| goalcli score --min 9.8 | < 60 秒 |

## 4. 边界场景 / 失败语义

- P0 Gate 失败必须阻断发布；planned/gap 在 `--strict` / `--verify` 下不得被视为 passed。
- `CHECK_STATUS=passed` 只是 evidence 生成上下文，不是 release-ready evidence。
- `artifact_exists` 不等于 usable；Release Manifest 字段缺失应记录 `truth_state=incomplete`。
- 本地文件不能证明远端 branch protection、ruleset、required checks 或 GitHub Release object 当前启用；远端证据见 `../REMOTE-EVIDENCE.md`。
- 原主文件中的裁决性清单已迁出。本仓库改由 `../INDEX.md` §4 列出上游裁决标准位置，不重复声明通过/失败。

## 5. 与其他子分析的交叉引用

| 主题 | 位置 |
|------|------|
| 规则源与 debt gate | `analysis/rules.md` §3 |
| Go 参考模板、ErrorKind、metrics | `analysis/template.md` §3 |
| AdoptionStatus、truth-state 与远端治理 | `analysis/governance.md` §3、§4 |
| FR 详细规格 SSOT | `../FR-DETAIL.md` |
| 上游 gate / release 索引 | `../INDEX.md` §3、§4 |
| 快照边界 | `../SNAPSHOT-BOUNDARY.md` |

## 6. TC / EC 命名空间

### 6.1 测试分层（TL0-TL7）

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

### 6.2 TC ↔ FR 追溯矩阵（核心 P0）

> 范围：以下表覆盖 `analysis/template.md` §4 Edge Cases 与 Go 参考模板 FR (FR-009..FR-014) 的最小用例集。其余 P0 FR 的 TC 由 harness.yaml 的 gate 输出 + Evidence pack 间接证明；本表为“代码可写”的最小用例样板，下游模块在自身分析中沿用并扩展。

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
| xlib-TC-009 | TL2 Security | FR-013 / metrics | `os.Setenv("HOME","/home/k8s")` 后调用 `New(ctx, Config{})` | enforcer 拒绝隐式读取 `<secret-store-path>`；返回 `ErrorKindConfig` |
| xlib-TC-010 | TL4 Golden | FR-012 | `HealthCheck()` 输出 JSON | 与 `testdata/health.golden.json` 字节级一致（除 `checked_at`/`latency_ms`） |
| xlib-TC-011 | TL4 Fuzz | FR-014 | `go test -fuzz=FuzzConfigValidate` ≥ 30s | 无 panic；任何 Validate 失败都返回 `ErrorKindValidation` 而非其他 ErrorKind |
| xlib-TC-012 | TL6 Release | FR-027 / §3.6 | `goalcli release-final-check` 在缺失 manifest 任一必填字段时 | 退出码 1；evidence 记录 `truth_state=incomplete`；阻断 release |
| xlib-TC-013 | TL2 Truth-state | FR-006 / §4 | `adoption_status=registered` 直接尝试 → `adopted` | enforcer 拒绝；返回禁止转换原因；详见 `analysis/governance.md` §3.2 / FR-051 |
| xlib-TC-014 | TL2 Contract | FR-010 / `analysis/template.md` §3.4 | `IsKind(err, ErrorKindTimeout)` 应用于 `WrapError(ErrorKindTimeout, cause, "")` | 返回 true；`errors.Is(err, cause)` 也必须为 true |
| xlib-TC-015 | TL1 Unit | FR-011 | `Metrics()` 返回值 | 长度 == 9；命名匹配 `analysis/template.md` §3.7 表；无重复 |
| xlib-TC-016 | TL2 Boundary | FR-010 / EC-005 | 注入连接池/FD/内存上限（fake limiter），调用 `New` / `client` 操作 | 返回 `ErrorKindUnavailable` 或 `ErrorKindRateLimit`；保留 cause（`errors.Is` 命中）；进程不 OOM |
| xlib-TC-017 | TL1 Unit | FR-014 / EC-008 | `var c *Config; c.Validate()`（nil receiver） | 返回 `ErrorKindValidation`；禁止 panic（防御性检查） |

### 6.3 追溯绑定

- 每条 TC 必须落到一个具体 Go test 函数（`Test<TC编号>` 或 `TestFR<NNN>_<scenario>`）。
- 每条 TC 必须有对应的 Evidence Ledger 行（FR-026 / §3.5）；失败时 `status=failed` 不得删除（FR-032）。
- 本表不替代 harness.yaml gate；harness 通过运行 `go test` + 解析 JUnit 输出消费这些 TC。
- `xlib-TC-001..xlib-TC-017` 属于 `xlib-standard` 命名空间。下游模块复用时必须使用自身模块前缀，并标注继承自 `xlib-TC-NNN`。

### 6.4 无显式 TC 的 FR 处理

| 无 TC 的 FR | 由何替代覆盖 | 证据路径 |
|-------------|--------------|----------|
| FR-001 (419 条规则) | harness gate `registry-validate` | `pack/registry-validate.json` |
| FR-002 (7 类技术债) | harness gate `debt-scan` | `pack/debt-scan.json` |
| FR-005 (8 个 REQ) | harness gate `adoption-check` | `pack/adoption-check.json` |
| FR-046 (28 个 PR 包) | 计划性 FR，由 `goal-runtime` ledger 追踪，无单元 TC | `.agent/evidence/ledger.jsonl` |
| FR-052 (20 PR 下游同步) | 计划性 FR，由 `downstream-sync-policy` gate 追踪 | `pack/downstream-sync.json` |

## 7. 附录

上游裁决性内容不在本文件复制。No-Go、release-final、release-preflight、score 和 evidence pack 判定以 `docs/standard/release-standard.md`、`.agent/harness/harness.yaml` 与上游 artifact 为准。
