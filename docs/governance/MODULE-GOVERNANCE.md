# 模块治理总纲 — Module Governance Charter

- Module-Version: v1.1.1
- Last-Updated: 2026-06-27
- 适用范围：本仓库全部 `module/*/` 规格制品、`module/registry.yaml` 注册表、以及本仓库索引的全部外部模块仓库（`github.com/ZoneCNH/*`）
- 效力层级：本文位于 `docs/governance/` 层，受 [`CONSTITUTION.md` §13.1](../constitution/13-supreme-clause.md) 效力层级管辖（CONSTITUTION > module/\*/SPEC.md > governance 文档 > ARCHITECTURE > module 详情 > 其他）
- 优先级：本文 > `module/{module}/spec/SPEC.md` 治理条款 > `module/{module}/gate/RULES.md` 单模块规则；与 CONSTITUTION 冲突时以 CONSTITUTION 为准
- 强制级别：每条规则标注【硬】（违反即治理违规）/【软】（推荐）/【开】（仅验证存在性），沿用 [`module/binance/gate/RULES.md`](../../module/binance/gate/RULES.md) R1-R10 模式

> 本体系源自 2026-06-25 治理缺口审计。审计确认现有三层治理栈（宪法 §0-§20 / governance Spec→Code 管线 / goal 交付 OS）在 **Spec 治理**上极强，但在**"模块本身"（作为可独立发布的代码制品/仓库单元）的治理**上存在 8 个一致缺口。本总纲将其转化为可执行规则。

---

## §0 定位与效力层级

### §0.1 本体系管什么

本体系管**模块作为独立单元**的全生命周期治理：注册登记、生命周期状态、负责人、发布账本、健康度、准入、退役、业务域依赖矩阵。这是 **Spec 治理之外**的治理维度——Spec 治理（`LIFECYCLE.md`、`DEVELOPMENT-WORKFLOW.md`）管 `SPEC.md` 文档从 Draft 到 Deprecated 的状态；本体系管模块本身从 proposed 到 archived 的状态。

### §0.2 本体系不管什么

本体系**不覆盖**以下宪法条款，而是将其在模块管理维度**操作化**（引用而非重复）：

| 宪法条款 | 管辖内容 | 本体系角色 |
| --- | --- | --- |
| §2 模块边界 | 拥有/不拥有声明、违规判定、仲裁 | 准入流程引用 §2.1 边界声明作为门禁 |
| §2.5 模块增殖约束 | 奥卡姆剃刀三条件 | 转化为准入 ADR 必答项（[06](module-governance/06-module-onboarding.md)） |
| §3 依赖方向 | 拓扑、单向下行、禁止矩阵 | 退役/准入流程引用 §3 依赖审查；业务域扩展规划见 [08](module-governance/08-business-domain-deps.md) |
| §7 命名规范 | `<name>x` / `domain-<name>` / `<exchange>` 模式 | 准入流程引用 §7.2 命名审批作为门禁 |
| §10 变更管理 | PATCH/MINOR/MAJOR、Spec-Version/Runtime-Version | 发布账本引用 §10.4 版本字段规则 |
| §12 修正程序 | CONSTITUTION 修订流程 | **本体系不触发 §12**；本体系自身修订走 §5 |

### §0.3 不走 §12 修正程序

本体系位于 governance 层，不修改 CONSTITUTION.md / docs/constitution/。若本体系的规则演进触及 §14 受保护文件清单（Rubric / STRUCTURAL-SCORING / ARBITER-PROTOCOL / agent 配置 / 工作流入口），则该部分修订须走 §19 CRI 流程；其余部分走本总纲 §5 规则修订流程。

---

## §1 模块治理八域总览

| # | 治理域 | 缺口描述 | 本体系专题 | 关键产物 |
| --- | --- | --- | --- | --- |
| 1 | 模块注册登记 | 无统一 registry；分散在 module/README、appendix、FOUNDATION-DEPS、.foundationx/status，无一致性校验 | [01-module-registry.md](module-governance/01-module-registry.md) | `module/registry.yaml` |
| 2 | 模块生命周期 | 只有 Spec 六态，无模块自身 proposed→active→maintained→deprecated→archived 状态机 | [02-module-lifecycle.md](module-governance/02-module-lifecycle.md) | registry.yaml `lifecycle` 字段 |
| 3 | 模块负责人 | Owner 字段恒为 `ZoneCNH`，CODEOWNERS 未按模块细分，无负责人登记/交接 | [03-module-ownership.md](module-governance/03-module-ownership.md) | registry.yaml `owner` 字段 + CODEOWNERS |
| 4 | 模块发布账本 | 无模块级 release/tag/notes 追踪；VERSIONING.md 只管文档全局版本 | [04-module-release-ledger.md](module-governance/04-module-release-ledger.md) | registry.yaml `release` 字段 |
| 5 | 模块健康度 | 现有评分是制品级，无模块级聚合健康度与阈值触发规则 | [05-module-health.md](module-governance/05-module-health.md) | 健康度四维模型 |
| 6 | 新模块准入 | §2.5 奥卡姆剃刀有原则无流程；无立项 ADR/边界论证/依赖审查/命名审批门禁 | [06-module-onboarding.md](module-governance/06-module-onboarding.md) | 准入 ADR 模板 |
| 7 | 模块退役/迁移 | 无 sunset/EOL/合并/拆分/重命名标准流程（仅 4 占位模块删除先例） | [07-module-decommission.md](module-governance/07-module-decommission.md) | 退役 ADR 模板 |
| 8 | 业务域依赖矩阵 | FOUNDATION-DEPS 只覆盖 20 基座+domainx；业务域仅出现在 forbidden 黑名单 | [08-business-domain-deps.md](module-governance/08-business-domain-deps.md) | 扩展 schema 规划（后续工作） |

八域是模块治理的基础面。数据 C/S 模块分级、模板抽取与季度剪枝属于操作性覆盖专题，用于把八域规则落到 `module/data_cs_module/`、`module/binance/` 与后续数据源模块。

---

## §2 与现有治理栈的关系

### §2.1 宪法操作化

本体系是宪法 §2/§2.5/§3/§7/§10 在"模块管理"维度的操作层：

- **§2.1 边界声明** → 准入流程必答项（[06](module-governance/06-module-onboarding.md) §2）
- **§2.5 奥卡姆剃刀** → 准入 ADR 三条件必答（[06](module-governance/06-module-onboarding.md) §3）
- **§3 依赖拓扑** → 准入依赖审查门禁（[06](module-governance/06-module-onboarding.md) §4）+ 退役下游影响分析（[07](module-governance/07-module-decommission.md) §2）
- **§7.2 命名模式** → 准入命名审批门禁（[06](module-governance/06-module-onboarding.md) §5）
- **§10.4 版本字段** → 发布账本字段规则引用（[04](module-governance/04-module-release-ledger.md) §2）

### §2.2 governance Spec 管线衔接

本体系的模块生命周期（[02](module-governance/02-module-lifecycle.md)）与 `LIFECYCLE.md` 的 Spec 六态是**两个不同粒度的状态机**，存在映射关系（模块态驱动 Spec 态，非反之）。详见 [02-module-lifecycle.md](module-governance/02-module-lifecycle.md) §4。

本体系的准入流程（[06](module-governance/06-module-onboarding.md)）与 `DEFINITION-OF-READY.md` 是**两个不同层级的门禁**：DoR 是 Spec 进入开发的前置条件；准入是新模块加入本仓库索引的前置条件。准入通过后，Spec 才能进入 DoR。

### §2.3 goal 体系衔接

本体系的发布账本（[04](module-governance/04-module-release-ledger.md)）与 goal 体系的 `releases` registry（`.config/goal/registry/releases.yaml`）是**投影关系**：registry.yaml 的 `release` 字段是模块级投影，goal releases registry 是发布事件级 SSOT。

本体系的健康度（[05](module-governance/05-module-health.md)）与 goal 体系的 Gate（G0-G11）是**互补关系**：Gate 管单次交付流程的通过/失败；健康度管模块跨多次交付的累积状态。

---

## §3 模块治理三 SSOT 边界

模块治理涉及三个机器可读 SSOT，各管一面，**引用而非重复**：

```
module/registry.yaml            → 身份 + 治理状态（lifecycle / owner / domain / arch_type）
module/FOUNDATION-DEPS.yaml     → 依赖矩阵（allowed / forbidden / constraints / edges）
.foundationx/status/index.json  → 成熟度事实（version / spec / impl / release / factory）
```

| SSOT | 管辖字段 | 生成方式 | 覆盖范围 |
| --- | --- | --- | --- |
| `registry.yaml` | repo, local_path, domain, layer, arch_type, lifecycle, owner, spec_ref, registered | 人工维护（治理事实） | 全域（基座+L2.5+业务域+入口+横切） |
| `FOUNDATION-DEPS.yaml` | modules.path/layer/stdlib_only, allowed_deps, forbidden_deps, constraints, forbidden_foundation_edges | 人工维护（治理规则） | 基座(20)+domainx |
| `.foundationx/status/index.json` | version, spec, impl, release, live, ci, adopt, soak, factory, note | xlibgate fleet-status 生成（机器事实） | 基座+L2.5(21) |

### §3.1 引用规则【硬】

- `registry.yaml` 的 `deps_ref` 字段指向 `FOUNDATION-DEPS.yaml`（若模块在 DEPS 中登记）；不重复登记依赖边
- `registry.yaml` 的 `maturity_ref` 字段指向 `.foundationx/status/index.json`（若模块在 status 中登记）；不重复登记 version/release/factory
- `registry.yaml` 的 `spec_version` 字段是**投影**（mirror from `module/{module}/SPEC.md` Metadata），不作为版本 SSOT
- `FOUNDATION-DEPS.yaml` 和 `.foundationx/status/index.json` 的字段**不反向引用** registry.yaml（保持各自独立性）

### §3.2 覆盖范围差异【软】

当前三个 SSOT 覆盖范围不一致：FOUNDATION-DEPS 覆盖 20 基座+domainx；.foundationx/status 覆盖 21 基座+L2.5；registry.yaml 覆盖全域（含 ~50 业务域模块）。这是**已知现状**，业务域模块在 DEPS 和 status 中的扩展是后续工作（见 [08](module-governance/08-business-domain-deps.md)）。

---

## §4 强制级别约定

沿用 `module/binance/gate/RULES.md` 的三级标注：

| 级别 | 标注 | 含义 | 违规后果 |
| --- | --- | --- | --- |
| 硬 | 【硬】 | 违反即治理违规 | PR 阻断 / 治理审计标记 |
| 软 | 【软】 | 推荐遵守 | 不阻断，评审时提示 |
| 开 | 【开】 | 仅验证存在性 | 缺失提示，不阻断 |

每条规则在专题文档中标注级别。本总纲的条款（§3.1 引用规则等）已标注。

---

## §5 规则修订流程

### §5.1 governance 层修订【硬】

本体系（MODULE-GOVERNANCE.md + module-governance/ 子目录 + module/registry.yaml）的修订走 governance 层 PR：

1. 从 main HEAD 创建 `docs/module-governance-{描述}` 分支
2. 修订规则文档 + 同步 registry.yaml（若涉及 schema 变更）
3. PR 描述附：变更理由 + 影响范围 + 与宪法的引用关系是否变化
4. 合入 main 后同步更新 module/README.md 等投影（若需要）

### §5.2 受 §14 约束时的升级【硬】

若修订触及 §14.1 受保护文件清单（Rubric / STRUCTURAL-SCORING / ARBITER-PROTOCOL / agent 配置 / 工作流入口 / outer-metrics / CONSTITUTION），该部分须走 §19 CRI 流程（Fork → A/B ≥3 模块 → Outer 验证 → 人类批准 → 合并）。

### §5.3 registry.yaml schema 变更【硬】

`registry.yaml` 的 `schema_version` 变更（字段增删/语义变更）须：

1. 在 `01-module-registry.md` 更新 schema 定义
2. 同 PR 内迁移全部已有模块条目到新 schema
3. PR 描述附迁移说明 + 新旧 schema diff

---

## §6 关键文档索引

| 文档 | 用途 |
| --- | --- |
| [module-governance/README.md](module-governance/README.md) | 八专题 + 模板索引 |
| [module-governance/01-module-registry.md](module-governance/01-module-registry.md) | 模块统一注册表 schema 与规则 |
| [module-governance/02-module-lifecycle.md](module-governance/02-module-lifecycle.md) | 模块生命周期五态状态机 |
| [module-governance/03-module-ownership.md](module-governance/03-module-ownership.md) | 模块负责人机制 |
| [module-governance/04-module-release-ledger.md](module-governance/04-module-release-ledger.md) | 模块发布账本 |
| [module-governance/05-module-health.md](module-governance/05-module-health.md) | 模块健康度四维模型 |
| [module-governance/06-module-onboarding.md](module-governance/06-module-onboarding.md) | 新模块准入流程 |
| [module-governance/07-module-decommission.md](module-governance/07-module-decommission.md) | 模块退役/迁移流程 |
| [module-governance/08-business-domain-deps.md](module-governance/08-business-domain-deps.md) | 业务域依赖矩阵扩展规划 |
| [module-governance/09-data-cs-governance-levels.md](module-governance/09-data-cs-governance-levels.md) | 数据 C/S 模块 L1/L2/L3 治理等级 |
| [module-governance/09-maintenance-cadence.md](module-governance/09-maintenance-cadence.md) | 模块治理维护节奏与 issue closeout 边界 |
| [module-governance/10-quarterly-pruning-audit.md](module-governance/10-quarterly-pruning-audit.md) | 季度治理剪枝审计机制 |
| [module-governance/10-governance-levels.md](module-governance/10-governance-levels.md) | 通用 L1/L2/L3 治理等级与证据口径 |
| [module-governance/templates/GOVERNANCE-TEMPLATE.md](module-governance/templates/GOVERNANCE-TEMPLATE.md) | 数据 C/S 模块治理模板 |
| [module-governance/templates/MODULE-GOVERNANCE-REVIEW.md](module-governance/templates/MODULE-GOVERNANCE-REVIEW.md) | 模块季度治理 review 模板 |
| [module-governance/templates/ADR-MODULE-ONBOARDING.md](module-governance/templates/ADR-MODULE-ONBOARDING.md) | 准入 ADR 模板 |
| [module-governance/templates/ADR-MODULE-DECOMMISSION.md](module-governance/templates/ADR-MODULE-DECOMMISSION.md) | 退役 ADR 模板 |
| [`module/registry.yaml`](../../module/registry.yaml) | 统一模块注册表（机器可读） |
| [`module/FOUNDATION-DEPS.yaml`](../../module/FOUNDATION-DEPS.yaml) | Foundation 依赖矩阵（引用，非本体系管辖） |
| [`.foundationx/status/index.json`](../../.foundationx/status/index.json) | 成熟度事实层（引用，非本体系管辖） |
| [`module/binance/gate/RULES.md`](../../module/binance/gate/RULES.md) | 单模块治理规则先例（R1-R10 模式来源） |
| [`docs/governance/LIFECYCLE.md`](LIFECYCLE.md) | Spec 生命周期（六态，与本体系模块生命周期映射） |
| [`docs/governance/DEFINITION-OF-READY.md`](DEFINITION-OF-READY.md) | Spec 进入开发前置条件（准入通过后适用） |
| [`docs/governance/boundary-gates-cross-module-promotion.md`](boundary-gates-cross-module-promotion.md) | 跨模块边界门禁推广先例 |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-27 | v1.1.1 | 登记模块维护节奏、通用治理等级和季度 review 模板；同步 GitHub/Beads issue closeout 文档边界 | Codex |
| 2026-06-27 | v1.1.0 | 增加数据 C/S 模块 L1/L2/L3 等级、通用治理模板与季度剪枝审计；同步 binance 迁移后 spec/gate 路径 | ZoneCNH |
| 2026-06-25 | v1.0.0 | 首次建立。闭合 2026-06-25 治理缺口审计确认的 8 个模块治理缺口，定义三 SSOT 边界、八域总览、强制级别约定与修订流程 | ZoneCNH |
