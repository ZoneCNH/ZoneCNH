# xlib-standard 子分析：仓库治理、采纳状态机与远端治理

本文件是本地分析，不是可执行规格。覆盖仓库治理、采纳状态机与远端治理。

- Snapshot-Date: 2026-06-08
- Upstream-Commit: `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` (v0.6.5)
- Analysis-Version: v3.1.0
- Parent: ../ANALYSIS.md

## 1. 分析边界

- 本仓库不证明上游远端规则、release object 或下游采纳状态；这些必须由 GitHub API、CI artifact、release artifact 或下游仓库 commit 证明。
- 采纳状态、远端治理和 release-ready 差距类事项统一记录到 `../SNAPSHOT-BOUNDARY.md`。
- 完整 FR WHEN/THEN 详见 `../FR-DETAIL.md`；本文件只保存治理语义和引用锚点。

## 2. 覆盖职责（FR 摘要）

### 2.1 仓库治理协议

> 权威来源：`../FR-DETAIL.md` FR-047..FR-052。

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-047 | 5 层执行链 | P0 | 标准源→生成器→hooks→CI→ruleset 逐层生效 |
| FR-048 | 禁止 main 开发 | P0 | 三重阻断（pre-commit + pre-push + main-guard） |
| FR-049 | 必须使用 git worktree | P0 | worktree-guard 验证当前目录是 worktree |
| FR-050 | 采纳状态机（8 状态） | P0 | 8 个合法枚举值 |
| FR-051 | 6 个禁止状态转换 | P0 | 禁止 registered→adopted 等 6 种跳跃 |
| FR-052 | 下游同步治理（20 PR） | P1 | 标准变更按依赖顺序同步下游 |

## 3. 仓库治理与采纳状态机正文

### 3.1 Branch Governance 与 5 层执行链

FR-047 定义的执行链为：标准源 → 生成器 → hooks → CI → GitHub Ruleset。任何单层通过都不得替代全链路通过；远端 ruleset 和 branch protection 必须由 GitHub API / ruleset export 证明。

### 3.2 Adoption Registry

```yaml
adoption_status: not_run | registered | dry_run | patch_only | proof_verified | adopted | blocked | superseded
evidence_state: not_run | partial | complete
proof_based_adoption: true | false
```

```go
type AdoptionStatus string

const (
    AdoptionNotRun         AdoptionStatus = "not_run"
    AdoptionRegistered     AdoptionStatus = "registered"
    AdoptionDryRun         AdoptionStatus = "dry_run"
    AdoptionPatchOnly      AdoptionStatus = "patch_only"
    AdoptionProofVerified  AdoptionStatus = "proof_verified"
    AdoptionAdopted        AdoptionStatus = "adopted"
    AdoptionBlocked        AdoptionStatus = "blocked"
    AdoptionSuperseded     AdoptionStatus = "superseded"
)
```

合法状态转换由 FR-051 的 6 个禁止转换规则约束。

### 3.3 采纳状态机禁止转换（6 个）

| # | 禁止转换 | 原因 |
|---|----------|------|
| 1 | registered → adopted | 登记态不等于已采纳，必须经过 proof-based adoption |
| 2 | dry_run → adopted | dry-run 只验证流程，不证明落地 |
| 3 | patch_only → adopted | patch-only 不等于 proof-based adoption |
| 4 | not_run → adopted | 未运行禁止直接 adopted |
| 5 | gate_outputs_missing → proof_based_adoption | 缺少 gate 输出不能声称 proof-based |
| 6 | baseline_scanned → adopted | 基线扫描不等于采纳完成 |

### 3.4 下游同步治理

下游同步计划、patch-only 和 registry 记录不得升级为 adopted；需要下游 commit、gate output、proof schema 和 rollback。该边界对应 `../SNAPSHOT-BOUNDARY.md` B-02。

### 3.5 消费者与仓库角色

默认代表下游为 `kernel`、`configx`、`redisx`。全部 L2 是矩阵和路线图对象；`x.go` 是 consumer-review-only。仓库角色、repository roles 和 downstream registry 的上游位置见 `../INDEX.md` §1。

### 3.6 层级依赖模型

> 领域命名口径：与 `ARCHITECTURE.md` / `CLAUDE.md` 一致，采用领域分层（基座 / 数据域 / 分析域 / 决策域 / 执行域 / 入口 / 横切）。`xlib-standard`、`xlibgate` 属于基座领域的 Foundation Gate 治理子层。

```text
基座 · Foundation Gate 子层：xlib-standard, xlibgate
    ↓
基座 L0：kernel
    ↓
基座 L1：configx / observex / testkitx / resiliencx / schedulex
    ↓
基座 L2：redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex
    ↓
私有域：xgo-contracts → xgo-market-data, xgo-macro-data → engines → x.go
```

依赖只能从高层指向低层，不可反向；L3-L6 不公开、不开源；`xlib-standard` 不得依赖 `x.go` 或业务仓库；生成库不得依赖 `x.go`。

### 3.7 L2 Provider 规格

L2 模块包括 `postgresx`、`redisx`、`kafkax`、`natsx`、`taosx`、`ossx`、`clickhousex`。

L2 交付链：capability manifest → contract pack → adapter implementation → evidence pack → contract/integration/chaos/benchmark/adoption gates → xlibgate release judgment。

| 阶段 | 语义 |
|------|------|
| T0 | 文档和计划存在，不可发布。 |
| T1 | capability 和 contract 初步存在，不可发布。 |
| T2 | 本地 contract/integration 有证据，但未达 release profile。 |
| T3 | 首个 release-allowed 阶段。 |
| T4 | factory-grade；包括更完整的故障、性能、兼容和 adoption 证据。 |

## 4. 边界场景 / 失败语义

### 4.1 xlibgate 硬性失败（7 种）

见 `analysis/template.md` §4.2。任一触发即 fail-closed，不得降级；对应 EvidenceEntry 中 `truth_state=violated` 记录。

### 4.2 弱事实禁止升级（truth-state）

| Edge | 弱事实 | 不可视为 | 检测点 |
|------|--------|----------|--------|
| EC-G1 | `registered` | `adopted` | FR-006 / FR-051 / §3.2 AdoptionStatus 枚举 |
| EC-G2 | `baseline_scanned` | `implemented` | `analysis/runtime.md` §3.5 EvidenceEntry.truth_state |
| EC-G3 | `dry_run_ready` | `executed` | `analysis/runtime.md` §3.2 退出码 / §3.5 status |
| EC-G4 | `artifact_exists` | `usable` | release-final-check / `analysis/runtime.md` §3.6 字段完整性 |
| EC-G5 | `CHECK_STATUS=passed` | `release-ready evidence` | GitHub checks + release evidence pack |
| EC-G6 | downstream sync plan | downstream adoption proof | FR-052 / FR-006 |

详见 `../CONFLICT-LEDGER.md` 与 `../SNAPSHOT-BOUNDARY.md`。

### 4.3 远端治理不可本地证明

本地文件不能证明 GitHub branch protection 已启用、ruleset 生效、required checks 绑定、GitHub Release object 已创建等。这些必须通过远端 API / CI artifact / ruleset export 单独证明，记录为 EvidenceEntry 中 `truth_state=unverified_remote`。pinned 证据见 `../REMOTE-EVIDENCE.md`。

### 4.4 v1.0.0 配置迁移

`.config/` 是目标数据面；当前上游仍有 `.agent/**`、`.xlib/**`、registry、policy 和 evidence ledger。No-Go 条件与 release 裁决标准详见上游 `docs/standard/release-standard.md`；本地边界记录见 `../SNAPSHOT-BOUNDARY.md` B-01 / B-05。

## 5. 与其他子分析的交叉引用

| 主题 | 位置 |
|------|------|
| 核心规则、RULE 前缀和 Debt Governance | `analysis/rules.md` §3 |
| 模板配置、错误、安全和 xlibgate 失败 | `analysis/template.md` §3、§4 |
| Evidence Ledger、Release Manifest 和 TC 表 | `analysis/runtime.md` §3、§6 |
| 远端证据 | `../REMOTE-EVIDENCE.md` |
| 快照边界 | `../SNAPSHOT-BOUNDARY.md` |

## 6. TC / EC 命名空间

治理类边界场景使用 EC-G1..EC-G6。与测试用例绑定时引用 `analysis/runtime.md` §6 的 `xlib-TC-013`（truth-state / adoption）及相关 gate 级 Evidence。

## 7. 附录或同义引用表

### 附录 A：TRUTH 同义引用表（非独立编号空间）

`TRUTH-NNN` 只在本表作为 BR / FR 的同义表述保留；跨文档引用应使用 `BR-NNN`、`FR-NNN` 或 `RULE-CORE-NNN`。

| TRUTH | 推荐引用 | 同义表述 |
|-------|----------|----------|
| TRUTH-001 | BR-005 | 规则不进入 Gate 就不是规则 / Harness 是机器裁判 |
| TRUTH-002 | BR-007 | 登记态不等于 adopted |
| TRUTH-003 | FR-042 | goalcli 是唯一执行面 |
| TRUTH-004 | BR-001 | Proof 是完成的唯一合法证明 |
| TRUTH-005 | FR-004 | 依赖方向只能从高层指向低层 |
| TRUTH-006 | FR-047 | 本地 + CI + GitHub Ruleset 三重硬约束 |
| TRUTH-007 | FR-044 | 4-Plane 分离关注点 |
| TRUTH-008 | BR-001 | 没有 Evidence 不允许 DONE |
| TRUTH-009 | BR-002 | Goal 必须从真实上下文开始 |
| TRUTH-010 | BR-003 | 需求必须可验证 |
| TRUTH-011 | BR-004 | 所有变更必须可追踪 |
| TRUTH-012 | BR-005 | Harness 是机器裁判 |
| TRUTH-013 | BR-006 | Self-improving 是强制环节 |
| TRUTH-014 | BR-001 | 文档不等于证据 |
| TRUTH-015 | BR-007 | registered / baseline_scanned / patch-only 不等于 adopted |
