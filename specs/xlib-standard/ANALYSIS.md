# xlib-standard 本地结构分析快照

本文件是 `github.com/ZoneCNH/xlib-standard@93753b30` 的本地结构分析快照，**不是**可执行规格。

- Snapshot-Date: 2026-06-08
- Upstream-Commit: `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` (v0.6.5)
- Analysis-Version: v3.1.0
- Upstream: [github.com/ZoneCNH/xlib-standard](https://github.com/ZoneCNH/xlib-standard)
- 本仓库角色: `ZoneCNH/ZoneCNH` 文档枢纽，仅保存本地分析、追溯锚点和边界说明，不承载实现源码。

## 1. 子分析索引

| 子分析 | 覆盖职责 | 主要内容 |
|--------|----------|----------|
| [`analysis/rules.md`](analysis/rules.md) | Standard Source + Debt Governance | 规则源、BR/RULE 编号、技术债规则、规则权威顺序 |
| [`analysis/template.md`](analysis/template.md) | Go Reference Template + Generator | 公共 API、ErrorKind、metrics、HealthCheck、模板渲染与目录边界 |
| [`analysis/runtime.md`](analysis/runtime.md) | Harness + goalcli + Evidence Runtime | gate 分类、goalcli 契约、Evidence Ledger、Release Manifest、TC 命名空间 |
| [`analysis/governance.md`](analysis/governance.md) | 仓库治理 + 采纳状态机 + 远端治理 | 消费者、采纳状态、仓库治理、远端证据边界、TRUTH 同义引用表 |

## 2. 快照事实层级

上游规格按事实强度分层：

| 层级 | 来源 | 用法 |
|------|------|------|
| Current Standard | `docs/standard/**`、根级 `docs/*.md` | 当前可执行规范和门禁事实。 |
| Domain Supplement | `docs/testing/**`、`docs/l2/**`、`docs/evidence/**` | 下游、L2、测试和证据补充。 |
| Historical Plan | `.worktree/*.md`、`docs/v0.6.0/**`、Downloads | 迁移目标、历史审查、未落地设计和冲突证据。 |
| Runtime Proof | release/evidence、ledger、CI artifact、remote ruleset proof | 只有真实产物可证明执行状态或远端状态。 |

禁止把弱事实升级为强事实：

- `registered` ≠ `adopted`
- `baseline_scanned` ≠ `implemented`
- `dry_run_ready` ≠ `executed`
- `artifact_exists` ≠ `usable`
- `CHECK_STATUS=passed` ≠ release-ready evidence
- downstream sync plan ≠ downstream adoption proof

## 3. 问题（Problem）摘要

### 3.1 痛点

1. **身份漂移**：旧名 `baselib-template` 和 `foundationx` 导致 README、docs、.agent 出现身份混乱。
2. **规则散文化**：419 条规则存在于散文和 registry/enforcer 源之间，需要明确机器化口径。
3. **伪完成风险**：登记态、dry-run、patch-only 容易被误判为 adopted 或 release-ready。
4. **配置分散**：`.agent/`、`.xlib/`、`.config/` 三套路径并存，下游无法直接判断权威来源。
5. **Gate 缺口**：本地 hooks、CI gate 与 GitHub Ruleset 必须区分，不能用本地文件证明远端启用。

### 3.2 量化现状

- 规则总数：419 条（P0=119, P1=244, P2=56）。
- 规则机器化率：87%（363/419 active）。
- 治理能力评分：8.5/10（缺口与证据边界见 `SNAPSHOT-BOUNDARY.md`、`REMOTE-EVIDENCE.md`）。
- 下游采纳状态：分析口径下仍按 proof-based adoption 证据判断。
- L2 适配器：release ladder 以 T3 作为首个 release-allowed 阶段。

## 4. 目标（Goals）摘要

### 4.1 P0 目标

- **G-P0-1 唯一主身份**：`xlib-standard` 是唯一主身份，承担标准源、模板、生成器、Harness、Evidence Runtime 与治理协议职责。
- **G-P0-2 规则机器化**：419 条规则以 registry/enforcer 为机器化执行口径。
- **G-P0-3 证据驱动完成**：没有 Evidence 不允许 DONE，完成声明必须使用 `DONE with evidence:` 格式。
- **G-P0-4 Proof-based adoption**：登记态 ≠ adopted，只有 downstream repo 自身生成的 proof-based adoption 才能进入 adopted。
- **G-P0-5 配置统一目标**：v1.0.0 前将配置拓扑收敛到 `.config/`。
- **G-P0-6 三层硬约束**：本地 hooks + CI gate + GitHub Ruleset 三重强制。

### 4.2 P1 目标

- **G-P1-7 Goal Runtime v3.1.1**：Goal Kernel + Harness Runtime + Extensions 架构逐步落地。
- **G-P1-8 L2 测试工厂**：L2 适配器按 release ladder 达到 T2/T3/T4。
- **G-P1-9 Debt Governance**：7 类技术债治理规则纳入 Gate。
- **G-P1-10 自动化**：Issue → Goal → Task → Branch → Commit → PR → Version → Release → Issue Close 全链路。

## 5. Non-goals

- 本仓库不承载 `xlib-standard` 实现源码、`goalcli` 二进制、release artifact 或下游实现。
- 本分析不声明上游 release-ready、GitHub Release object 已创建、远端 ruleset 当前启用或 downstream adopted。
- 本分析只摘要上游规格与 pinned 快照，不重新定义 23 节可执行规格结构。
- 本分析不把 `.worktree/**`、Downloads 或历史计划升级为 Current Standard。
- 本分析不替代 `FR-DETAIL.md` 的 52 条 WHEN/THEN 详细规格。

## 6. 消费者（Consumers）

| 消费者 | 领域 / 层级 | 消费方式 | 采纳状态口径 |
|--------|-------------|----------|--------------|
| kernel | 基座 / L0 | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| configx | 基座 / L1 | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| observex | 基座 / L1（横切） | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| testkitx | 基座 / L1 | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| resiliencx | 基座 / L1 | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| schedulex | 基座 / L1 | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| redisx | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| kafkax | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| natsx | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| postgresx | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| taosx | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| ossx | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| clickhousex | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| xgo-market-data | 数据域（私有） | 标准继承 | consumer-only |
| xgo-macro-data | 数据域（私有） | 标准继承 | consumer-only |
| x.go | 入口（私有） | 标准继承 | consumer-only |

> 注：L0/L1/L2 是基座领域内部依赖层级，详见 `analysis/governance.md` §3.6 与仓库根 `ARCHITECTURE.md`。

## 7. 关键数字与职责分布

> **FR SSOT**：52 条 FR 的完整 WHEN/THEN 行为规格以 [`FR-DETAIL.md`](./FR-DETAIL.md) 为准；下表只给出职责入口和 FR 区间。

| 职责 | FR 覆盖 | 子分析入口 | 详细规格 |
|------|---------|------------|----------|
| Standard Source | FR-001..FR-008 | `analysis/rules.md` §2.1 | `FR-DETAIL.md` §1 |
| Go Reference Template | FR-009..FR-014 | `analysis/template.md` §2.1 | `FR-DETAIL.md` §2 |
| Generator | FR-015..FR-019 | `analysis/template.md` §2.2 | `FR-DETAIL.md` §3 |
| Harness | FR-020..FR-025 | `analysis/runtime.md` §2.1 | `FR-DETAIL.md` §4 |
| Evidence Runtime | FR-026..FR-032 | `analysis/runtime.md` §2.2 | `FR-DETAIL.md` §5 |
| Debt Governance Runtime | FR-033..FR-039 | `analysis/rules.md` §2.2 | `FR-DETAIL.md` §6 |
| Goal Runtime v3.1.1 | FR-040..FR-046 | `analysis/runtime.md` §2.3 | `FR-DETAIL.md` §7 |
| 仓库治理协议 | FR-047..FR-052 | `analysis/governance.md` §2.1 | `FR-DETAIL.md` §8 |

## 8. 冲突总览

详见 `CONFLICT-LEDGER.md` 与 `SNAPSHOT-BOUNDARY.md`。本快照把冲突分为两类：

| 类型 | 文件 | 范围 |
|------|------|------|
| 同一 SSOT 内部硬冲突 | `CONFLICT-LEDGER.md` | 身份、默认下游、执行面、生成器策略、证据语义等 |
| 分析快照 vs 现实边界 | `SNAPSHOT-BOUNDARY.md` | strict-config、adoption proof、远端治理、release-ready、路径可移植等 |

## 9. 追溯口径

FR 来源锚定 52/52；其中行级 49、file 1（FR-008）、validator-output 2（FR-041, FR-046）。不得把“来源锚定完整”读作“语义验证完整”。

TC 使用 `xlib-TC-001..xlib-TC-017` 命名空间，禁止在跨模块文档中裸用 `TC-NNN`。完整 TC 表见 `analysis/runtime.md` §6。
