# xlib-standard 子分析：仓库治理、采纳状态机与远端治理

本文件是本地分析，不是可执行规格。覆盖仓库治理、采纳状态机与远端治理。

## 1. 分析边界

- 本仓库不证明上游远端规则、release object 或下游采纳状态；这些必须由 GitHub API、CI artifact、release artifact 或下游仓库 commit 证明。
- 采纳状态、远端治理和 release-ready 差距类事项统一记录到 `../SNAPSHOT-BOUNDARY.md`。

### 7.8 仓库治理协议

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-047 | 5 层执行链 | P0 | 标准源→生成器→hooks→CI→ruleset 逐层生效 |
| FR-048 | 禁止 main 开发 | P0 | 三重阻断（pre-commit + pre-push + main-guard） |
| FR-049 | 必须使用 git worktree | P0 | worktree-guard 验证当前目录是 worktree |
| FR-050 | 采纳状态机（8 状态） | P0 | 8 个合法枚举值 |
| FR-051 | 6 个禁止状态转换 | P0 | 禁止 registered→adopted 等 6 种跳跃 |
| FR-052 | 下游同步治理（20 PR） | P1 | 标准变更按依赖顺序同步下游 |

---

### 9.6 采纳状态机禁止转换（6 个）

从 `main.md` 和 `goal.md` 提取的 6 个禁止状态转换：

| # | 禁止转换 | 原因 |
|---|----------|------|
| 1 | registered → adopted | 登记态不等于已采纳，必须经过 proof-based adoption |
| 2 | dry_run → adopted | dry-run 只验证流程，不证明落地 |
| 3 | patch_only → adopted | patch-only 不等于 proof-based adoption |
| 4 | not_run → adopted | 未运行禁止直接 adopted |
| 5 | gate_outputs_missing → proof_based_adoption | 缺少 gate 输出不能声称 proof-based（条件状态：evidence_state=partial 时的中间态） |
| 6 | baseline_scanned → adopted | 基线扫描不等于采纳完成（条件状态：adoption_status=registered 时的扫描态） |

核心铁律：`registered != adopted`、`patch_only != proof_based_adoption`、`gate_outputs_missing != proof_based_adoption`。

### 11.7 Adoption Registry

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

type AdoptionRecord struct {
    Module             string         `json:"module"`
    AdoptionStatus     AdoptionStatus `json:"adoption_status"`
    EvidenceState      string         `json:"evidence_state"`
    ProofBasedAdoption bool           `json:"proof_based_adoption"`
    LastUpdated        time.Time      `json:"last_updated"`
}
```

合法状态转换由 FR-051 的 6 个禁止转换规则约束。

### 14.2 治理视角失败语义（Governance Edge Cases）

#### 14.2.1 xlibgate 硬性失败（7 种）

见 §13.3。任一触发即 fail-closed，不得降级。每条对应 §23.7.2 风险表与 §11.5 EvidenceEntry 中 `truth_state=violated` 记录。

#### 14.2.2 弱事实禁止升级（truth-state）

| Edge | 弱事实 | 不可视为 | 检测点 |
|------|--------|----------|--------|
| EC-G1 | `registered` | `adopted` | FR-006 / FR-051 / §11.7 AdoptionStatus 枚举 |
| EC-G2 | `baseline_scanned` | `implemented` | §11.5 EvidenceEntry.truth_state |
| EC-G3 | `dry_run_ready` | `executed` | §10.3 退出码 / §11.5 status |
| EC-G4 | `artifact_exists` | `usable` | release-final-check / §11.6 字段完整性 |
| EC-G5 | `CHECK_STATUS=passed` | `release-ready evidence` | §23.3 Gate Chain |
| EC-G6 | downstream sync plan | downstream adoption proof | FR-052 / FR-006 |

详见 §2.1 / §9.7 / `CONFLICT-LEDGER.md`。

#### 14.2.3 远端治理不可本地证明

本地文件不能证明 GitHub branch protection 已启用、ruleset 生效、required checks 绑定、GitHub Release object 已创建等。详见 §23.7.3 / §23.7 OQ-001。这些必须通过远端 API / CI artifact / ruleset export 单独证明，记录为 EvidenceEntry 中 `truth_state=unverified_remote`。

---

## 16. 依赖（Dependencies）

### 16.1 层级依赖模型

> **领域命名口径**：与 `ARCHITECTURE.md` / `CLAUDE.md` 一致，采用 **领域分层**（基座 / 数据域 / 分析域 / 决策域 / 执行域 / 入口 / 横切）。`xlib-standard`、`xlibgate` 属于 **基座领域的 Foundation Gate 治理子层**，不是独立于五领域之外的第六领域。下表保留旧 L 编号仅作历史映射。

```text
基座 · Foundation Gate 子层：xlib-standard, xlibgate
    ↓
基座 L0（原 L0）：kernel
    ↓
基座 L1（原 L1）：configx / observex / testkitx / resiliencx / schedulex
    ↓
基座 L2（原 L2）：redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex
    ↓
（以下为私有域，不开源；对应 ARCHITECTURE.md 的数据域 / 分析域 / 决策域 / 执行域 / 入口）
xgo-contracts → xgo-market-data, xgo-macro-data → market-engine, macro-engine, regime-engine → x.go
```

### 16.2 L2 Provider 规格

L2 模块包括 `postgresx`、`redisx`、`kafkax`、`natsx`、`taosx`、`ossx`、`clickhousex`。

L2 交付链：capability manifest → contract pack → adapter implementation → evidence pack → contract/integration/chaos/benchmark/adoption gates → xlibgate release judgment。

Release ladder：

| 阶段 | 语义 |
|------|------|
| T0 | 文档和计划存在，不可发布。 |
| T1 | capability 和 contract 初步存在，不可发布。 |
| T2 | 本地 contract/integration 有证据，但未达 release profile。 |
| T3 | 首个 release-allowed 阶段。 |
| T4 | factory-grade；包括更完整的故障、性能、兼容和 adoption 证据。 |

缺失 profile、pack、readiness 或证据时，L2 release 必须 fail closed。

### 16.3 依赖方向规则

- 依赖只能从高层指向低层，不可反向
- L3-L6 不公开、不开源
- xlib-standard 不得依赖 x.go 或业务仓库
- 生成库不得依赖 x.go

### 16.4 工具依赖

| 工具 | 版本 | 用途 |
|------|------|------|
| Go | 1.23.x | 编译 |
| golangci-lint | v2.1.6 | Lint |
| govulncheck | v1.3.0 | 漏洞扫描 |
| python3 | 3.x | 脚本 |
| sha256sum | - | 校验和 |
| make | - | 构建 |
| git | - | 版本控制 |
| Docker | - | 工具链运行时 |

---

## 22. 迁移（Upgrade Compatibility）

### 22.1 v1.0.0 配置迁移

- **目标**：`.config/` 作为唯一机器可读事实源
- **迁移表**：20+ 条目（`.agent/` → `.config/`，`.xlib/` → `.config/`）
- **37 No-Go 条件**（Part F）：任一为真则不得发布 v1.0.0，核心包括：
  - CHANGELOG 缺 v1.0.0 条目
  - public API surface 未冻结
  - stable/experimental/internal surface 未分类
  - breaking change 缺 migration note
  - release.yml 仍使用 cmd/xlibgate
  - workflow 仍使用 deprecated release entrypoint
  - toolchain 版本在 docs/workflow/manifest 间漂移
  - 任一 workflow action 未 pin 40-char SHA
  - workflow 无 explicit permissions
  - PR template / CODEOWNERS 缺失
  - registry schema validation 缺失
  - release artifact schema validation 缺失
  - generator determinism / idempotency 未证明
  - kernel/configx/redisx replay 未通过
  - downstream not_run 被报告为 passed
  - P0 debt > 0
  - truth-state violation > 0
  - release manifest 缺 goal/worktree/branch/cicd/governance/risk/downstream blocks
  - open P0 blocker / RC blocker 未清零
  - rollback policy 缺失
  - Docker toolchain runtime parity 未证明
  - 其余 16 条见源文件 Part F 完整列表
- **平台适配器分类学**（5 类）：
  1. xlib_standard_fact（标准源事实）
  2. platform_native（平台原生）
  3. thin_adapter（薄适配器）
  4. generated_projection（生成投影，如 CODEOWNERS）
  5. forbidden_legacy（禁止遗留）

### 22.2 迁移路径

```text
v1 提出概念 → v2 审计补全 → v3 修补 P0 缺口 → v5 终极版
```

### 22.3 关键决策

- `.agent/` 控制面保留，`.config/` 数据面统一
- 迁移必须有回滚计划
- 下游 effective subset 限制为 7 个文件
- CODEOWNERS 从 `.config/github/codeowners.json` 生成

### 22.4 未来考虑（Future Considerations）

> 原 §附录 B，2026-06-08 并入 §21（消解结构债 S3）。

1. **v1.0.0-rc.1**：先进入 rc.1，P0 清零后再发布 stable
2. **Goal Runtime v3.1.1**：28 个 PR 执行包逐步落地
3. **L2 测试工厂**：15 个适配器全部达到 L2-T2+
4. **自动化全链路**：Issue → Goal → ... → Release → Issue Close
5. **xlibctl**：pinned CLI binary 用于工具链分发
6. **Proof Depth D0-D7**：gate 验证深度标准化
7. **Standard Production Kernel**：Canonical Facts → Standard Graph → Goal Graph → Debt Graph → Harness Proof Graph → Evidence Ledger

---
## 7. TRUTH 同义引用表（非独立编号空间）

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
