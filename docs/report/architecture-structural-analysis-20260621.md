# FoundationX 项目深度分析报告 — 架构 · 结构 · 综合评分

> 生成时间：2026-06-21 02:35 CST  
> Release：`v1.12.1`（`9cb609f`）  
> 审计基线：`audit-status.py` 52/52 PASS  
> 分析范围：53 个模块目录、6 个治理维度、架构拓扑、结构性问题全集

---

## 一、综合评分卡

| 维度 | 权重 | 得分 | 贡献 | 等级 |
|------|:----:|:----:|:----:|:----:|
| A · 架构完整性 | 20% | 74 | 14.8 | 🟡 |
| B · 规格质量 | 20% | 52 | 10.4 | 🔴 |
| C · 管线覆盖 | 20% | 46 | 9.2 | 🔴 |
| D · 治理成熟度 | 15% | 87 | 13.1 | 🟢 |
| E · 文档一致性 | 15% | 84 | 12.6 | 🟢 |
| F · 交付健康度 | 10% | 85 | 8.5 | 🟢 |
| **加权综合** | 100% | **68.6** | — | **C · 需改进** |

> **等级定义**：S≥90 卓越 / A≥80 良好 / B≥70 合格 / C≥60 需改进 / D<60 危险

**一句话判断**：治理框架世界级，业务域实现几乎空白——架构文档完备度与代码交付进度之间存在系统性剪刀差。

---

## 二、架构问题分析

### 2.1 依赖拓扑 — 设计优势 ✅

架构在文档层面设计严谨，有以下几个显著优势：

**分层清晰**
```
L0 kernel（stdlib-only）
  └─ L1 primitives：configx / observex / resiliencx / schedulex
       └─ L1 assembly：bootstrap（只做进程组装）
            └─ L2 存储扩展：redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex
                 └─ L2.5 域共享：decimalx / domainx / domain_market / domain_macro / domain_exchange
                      └─ 业务域：数据域 → 分析域 ⇄ 决策域 → 执行域
                           └─ composer（Composition Root，只做装配）
```

**边界守卫完整**
- `FOUNDATION-DEPS.yaml` v1.2.2：机器可读依赖矩阵，CI 可直接消费
- `forbidden_deps`：48 个禁止依赖明确声明
- `constraints`：kernel stdio-only / testkitx 生产禁用 / foundationx 退出门禁已激活
- `interface_only_integrations`：resiliencx ⇄ observex 接口隔离有文档规范

**宪法级约束**（§1-§3）
- P1–P13 设计不变量；依赖方向单向下行；接口契约 ≤7 方法

### 2.2 架构问题 — 关键风险 ⚠️

#### 问题 A1：contracts 尚未 Approved（严重）

`contracts`（跨域稳定端口、事件协议、DTO 契约）是整个业务链路的依赖枢纽，但当前 `Status: Docs Baseline Approved / Runtime Pending`，未进入 Approved。

其中 P1 / P2 的兼容投影名已通过 contracts type alias 补齐，当前未闭合的是 Approved 门禁、AC / TC 收口和运行时验证，不是命名缺口。

**影响链**：
```
contracts 未冻结
  → 分析域/决策域/执行域无法安全依赖 DTO 契约
  → signal_factory / riskx / orderx / positionx 等核心路径处于漂移风险
  → 所有下游模块 AC/TC 均难以固化
```

**优先级**：P0，是业务域开发的关键前置条件。

#### 问题 A2：业务域实现进度与架构文档严重脱节（严重）

| 域 | 模块数 | tasks | plan | prompt | evidence |
|---|:---:|:---:|:---:|:---:|:---:|
| 分析域 | 6 | 0% | 33% | 0% | 0% |
| 决策域 | 8 | 0% | 0% | 0% | 0% |
| 执行域 | 7 | 0% | 0% | 0% | 0% |

21 个核心业务模块，tasks 覆盖率 **0%**。架构在文档层完备，但管线从 Spec/Matrix 之后完全停止，无任何可执行任务被拆分。

#### 问题 A3：模块命名规范三种格式并存（中）

全局规范（`CONSTITUTION.md §7`、`CLAUDE.md`）要求统一 `snake_case`，但 `module/` 目录下存在：

| 格式 | 数量 | 示例 |
|------|:----:|------|
| kebab-case | **18** | `factor-engine`, `risk-engine`, `domain-market` |
| snake_case | 3 | `market_regime`, `macro_regime`, `ms_brain` |
| 无分隔符小写 | 32 | `kernel`, `configx`, `binance` |

规范文档与实际目录不一致，会导致脚本扫描、路径引用、CI 检查出现歧义。

#### 问题 A4：L2.5 域共享层命名已完成显示层对齐，但历史投影仍需收口（中）

`domain-market`（kebab）对应仓库 `domain_market`（snake），`domain-macro` 对应 `domain_macro`，`domain-exchange` 对应 `domain_exchange`——目录命名、仓库命名、SPEC 内部引用曾长期并存。当前 `module/README.md` 已切到 `snake_case` 显示层，剩余工作不再是重新定义命名，而是把旧路径投影限制在同步文档与历史引用清单中，不再扩散到主分析报告。

#### 问题 A5：x.go / composer 说明入口已完成口径收口（低）

`x.go` 已固定为治理/工具 CLI，`composer` 已固定为运行时 Composition Root；顶部架构图、分层索引、原则文档、基础层文档与本分析报告已统一收口，后续只需保持这条分工在新增文档中的一致性。

---

## 三、结构性问题分析

### 3.1 规格体系结构性问题

#### 问题 S1：AC 缺失率 68%（严重）

验收标准（AC）是 Spec-to-Code 管线中 S1 门禁的核心验收依据。

```
有 FR 但无 AC 的模块（14个）：
  backtestx（FR=17）、binance（FR=20）、factor-engine（FR=12）、
  flowx（FR=21）、maestro（FR=22）、orderx（FR=17）、ossx（FR=17）、
  positionx（FR=17）、riskx（FR=18）、schedulex（FR=6）、
  strategyx（FR=12）、testkitx（FR=35）、taosx（FR=22）、postgresx（FR=25）

Approved 但无 AC 的模块（历史快照，已收口）：
  binance、decimalx、domain-exchange、domain-market、
  postgresx、resiliencx、taosx、testkitx
```

Approved 模块无 AC 曾是最严重的问题——对应的 8 个模块已完成 AC 回写并冻结，当前不再属于未完成项；当前仍需关注的是其余有 FR 但无 AC 的模块池。

#### 问题 S2：TC 缺失率 55%（严重）

29/53 个模块无 TC（测试用例），包括分析/决策/执行域全部模块。TC 缺失意味着测试设计完全未启动。

#### 问题 S3：5 个 SPEC 基线已实化（已收口）

以下模块 SPEC 已从占位符升级为完整基线，当前不再计入未完成项；完整规格已回写到各模块 `SPEC.md`：

| 模块 | 字节数 | 域 |
|------|:------:|-----|
| `settlement` | 792 | 执行域 |
| `portfolio-engine` | 864 | 执行域 |
| `risk-engine` | 909 | 执行域 |
| `order-engine` | 964 | 执行域 |
| `macro_regime` | 859 | 分析域 |

执行域 4/7 个核心模块曾为占位符，这是分析时点的系统安全性重大风险点；该风险已由 `#3` 收口消除。

#### 问题 S4：管线在 Spec/Matrix 后系统性断裂（严重）

```
制品数分布（53个模块）：
  6/6 制品：2 个（3.8%）
  5/6 制品：2 个（3.8%）
  4/6 制品：22 个（41.5%）— 有 Spec+Goal+Trace+Plan 但无 tasks/prompt/evidence
  3/6 制品：5 个（9.4%）
  2/6 制品：20 个（37.7%）— 仅有 Spec+Goal
  0/6 制品：2 个（3.8%）
```

41.5% 的模块停在 Plan 层，没有任何可执行任务；37.7% 停在 Spec/Goal 层。管线在 S3（Tasks）处出现系统性断层。

### 3.2 治理结构性问题

#### 问题 G1：管线后段（Prompt/Evidence）实际执行率极低

| 阶段 | 模块覆盖率 |
|------|:----------:|
| S1 Spec | 100% |
| S2 Matrix | 96.2% |
| S3 Tasks | 49.1% |
| S4 Plan | 56.6% |
| S5 Prompt | **9.4%** |
| S6 Evidence | **3.8%** |

Prompt（S5）和 Evidence（S6）几乎为零，表明四源评分体系的后两阶段在绝大多数模块上从未实际触发。

#### 问题 G2：Draft 模块全部缺少 AC（严重信号）

18 个 Draft 模块，**100% 无 AC**。这意味着当前进入 Draft 的模式是"先写 FR、跳过 AC"，AC 被推迟到 Review 或 Approved 阶段——但审计显示即使是 Approved 也有 8 个无 AC。这是流程执行层面的系统性偏差。

#### 问题 G3：ADR 数量偏少（低）

5 篇 ADR 对应了 70+ 模块、21 个基座、多个重大架构决策（foundationx 退出、domainx 归属、L2.5 设计等），记录密度偏低，存在隐性决策未留存的风险。

---

## 四、各域深度评估

| 域 | 模块数 | Spec覆盖 | AC覆盖 | tasks | 评估 |
|---|:---:|:---:|:---:|:---:|------|
| Foundation L0/L1 | 7 | 100% | 71% | 86% | 🟢 健康，evidence 待补 |
| Foundation L2 存储 | 7 | 100% | 0% | 100% | 🟡 tasks 全 ✓，AC 全缺 |
| Foundation Contracts | 2 | 100% | 50% | 100% | 🟡 contracts 未 Approved |
| Foundation Gate | 4 | 100% | 50% | 100% | 🟢 门禁工具完备 |
| L2.5 域共享 | 5 | 100% | 20% | 100% | 🟡 命名不一致，AC 严重缺 |
| 数据域 | 7 | 100% | 0% | 29% | 🔴 tasks 不足，AC 全缺 |
| 分析域 | 6 | 100% | 0% | 0% | 🔴 管线完全停滞 |
| 决策域 | 8 | 100% | 0% | 0% | 🔴 全部为 Draft/Review，无任何执行制品 |
| 执行域 | 7 | 100% | 0% | 0% | 🔴 4/7 SPEC 占位符（分析时点风险，已由 `#3` 收口消除） |

---

## 五、优先修复方案（Plan）

### 5.1 修复原则

| 原则 | 说明 |
|---|---|
| 契约先行 | `contracts` 未 Approved 之前，不向下游扩 AC / TC 口径。 |
| AC 先于任务 | 先补 AC，再补 TC，再拆 tasks，避免“先实现、后补验收”。 |
| 占位符先实化 | 1KB 以下 SPEC 先补成完整需求，再进入后续阶段。 |
| 命名先定基准 | 新增文档、任务与引用只使用 `snake_case`，历史 kebab 仅保留在迁移说明。 |
| 投影分层 | `L2.5` 的目标命名口径与当前文件投影分开维护；`module/README.md` 只负责历史路径同步，不把投影写成已完成重命名事实。 |
| 入口单一 | `composer` 只保留组合根职责，不再派生第二套模块边界。 |

### 5.1.1 当前收口结果

- 已完成：`#4` 固定 L2.5 命名基准与迁移表；`#7` 统一 `x.go / composer` 说明入口并回写对齐文档；`#8` 清理 L2.5 遗留 kebab 引用，并回写统一命名 / 对齐同步文档；`#3` 的 5 个 SPEC 已升级为完整基线（`module/settlement/SPEC.md`、`module/portfolio-engine/SPEC.md`、`module/risk-engine/SPEC.md`、`module/order-engine/SPEC.md`、`module/macro_regime/SPEC.md`）；`contracts` P1 / P2 兼容投影别名（`RegimeSnapshotEvent` / `RegimeCardEvent` / `DecisionCardEvent` / `MarketRegimePort` / `MacroRegimePort` / `RegimeEnginePort`）已在 contracts 仓库以 type alias 方式补齐；`README.md`、`ARCHITECTURE.md` 与 `docs/architecture/README.md` / `01-overview.md` / `02-domain-layers.md` / `03-boundaries.md` / `04-principles.md` / `05-foundation.md` / `06-dataflow.md` / `07-three-engines.md` / `08-contracts.md` 的活跃口径已统一到 `riskx` / `orderx` / `positionx` / `backtestx`，历史投影仅保留在迁移表和对照清单中。
- 数据域 C/S Module 标准化基线已就位：`module/data-cs-module/README.md`、`SPEC-TEMPLATE.md`、`UPGRADE-ROADMAP.md` 已形成统一入口；`#9` 现阶段转为执行问题，需按该入口拆分 `market_data` / `macro_data` 落地任务。
- 当前未完成共 7 项：P0 `#1`、P1 `#5`-`#6`、P2 `#9`-`#12`；`#2` 已在模块级 AC 回写并冻结，完整执行版修复方案已拆出为 `docs/report/architecture-structural-repair-plan-20260621.md`，后续跟踪以该文档为主。
- 其中 `#4`、`#7`、`#8` 已作为同步基线收口，仅保留在历史记录和对照清单中，不再列入当前执行面。

### 5.2 P0 — 基线解锁（1-2 周）

| # | 行动 | 对应问题 | 主要产出 | 完成标准 |
|---|---|---|---|---|
| 1 | `contracts` 推进至 Approved，并补齐跨域 AC / TC | A1、S1 | 冻结版 `contracts`、协议边界清单 | `contracts = Approved`，下游引用口径单一 |
| 2 | ✅ 已完成：8 个 Approved 模块 AC 已收口 | S1、G2 | Approved 模块验收标准补丁（已回写） | Approved 无 AC = 0 |
| 3 | ✅ 已完成：将 5 个占位符 SPEC 全部扩充为完整规格 | S3、A2 | 完整 Spec 基线 | 占位符 SPEC = 0 |
| 4 | ✅ 已完成：固定 L2.5 命名基准与迁移表 | A3、A4 | `snake_case` 对照表、遗留引用清单、同步文档回写 | 新增文档不再产生新的 kebab 投影；显示层口径已收口 |

### 5.3 P1 — 管线补洞（2-4 周）

| # | 行动 | 对应问题 | 主要产出 | 完成标准 |
|---|---|---|---|---|
| 5 | 从 `regime_engine`、`signal_factory` 等核心链路开始拆分分析域 / 决策域 / 执行域 tasks | A2、S4 | 21 个核心模块的任务树 | 三个业务域全部进入可执行状态 |
| 6 | 按 AC → TC → tasks 顺序补齐测试与执行制品 | S2、S4、G2 | TC、tasks、prompt 的串联补丁 | 不再出现“有任务无验收” |
| 7 | 统一 `README.md` 与 `ARCHITECTURE.md` 的 `x.go` 说明入口 | A5 | 单一入口说明与引用更新 | `README.md` / `ARCHITECTURE.md` / `docs/architecture/README.md` / `01-overview.md` / `02-domain-layers.md` / `03-boundaries.md` / `04-principles.md` / `05-foundation.md` 的入口口径已统一；后续新增文档需沿用 `x.go`(治理 CLI) / `composer`(运行时组合根) 的分工 |
| 8 | ✅ 已完成：清理 L2.5 遗留 kebab 引用，并回写统一命名 / 对齐同步文档（`docs/report/repo-naming-unification-20260620.md`） | A3、A4 | 引用替换、迁移记录、对齐说明 | 目录、仓库、SPEC 引用分层归位，历史路径投影不再混写 |

### 5.4 P2 — 质量收敛（持续）

| # | 行动 | 对应问题 | 主要产出 | 完成标准 |
|---|---|---|---|---|
| 9 | 补全数据域 tasks，并按 `module/data-cs-module/README.md` / `SPEC-TEMPLATE.md` / `UPGRADE-ROADMAP.md` 推进 `market_data` / `macro_data` C/S Module 落地 | 数据域短板 | 数据域任务树 + 标准化入口 | 数据域不再停留在 29% tasks 覆盖 |
| 10 | 补充 prompt / evidence，优先从 Foundation 层和 Approved 业务模块开始 | G1 | S5 / S6 运行制品 | Prompt / Evidence 覆盖率持续提升 |
| 11 | 补录关键 ADR，覆盖 L2.5、三引擎契约、业务域边界等决策 | G3 | ADR 队列 | 关键决策可追溯 |
| 12 | 按里程碑推进 `live_integration` 扩展（当前 7 → 15+） | 交付健康度 | 集成清单 | 发布级联路线上线 |

### 5.5 退出条件

- `contracts` 已 Approved，且下游不再依赖未冻结口径。
- Approved 无 AC = 0。
- 5 个 SPEC 基线已补齐并冻结，不再保留占位符文案。
- 分析域、决策域、执行域均形成可执行 tasks。
- 数据域补齐 tasks，并通过 `module/data-cs-module` 标准化入口保持新增数据域模块的一致结构，避免继续停留在低覆盖状态。
- L2.5 目标命名基准已统一为 `snake_case`，历史路径投影在同步文档中显式隔离，不再与主分析报告混写。
- `x.go` 的主文档口径已完成治理 CLI / `composer` 组合根分工同步，后续新增文档需保持同一入口分工。
- S5 / S6 不再长期停留在个位数覆盖。
- 关键 ADR 已补录，`live_integration` 继续按里程碑推进。

---

## 六、数据附录

### 管线覆盖热图

```
域               S1    S2    S3    S4    S5    S6
Foundation L0    ████  ████  ████  ████  ████  ░░░░
Foundation L1    ████  ████  █████░████░ ██░░  ░░░░
Foundation L2    ████  ████  ████  ████  █░░░  █░░░
Foundation Gat   ████  ████  ████  ████  █░░░  █░░░
Foundation Con   ████  ████  ████  ████  ░░░░  ░░░░
L2.5             ████  ████  ████  ████  ░░░░  ░░░░
数据域           ████  ████░ ██░░  ████░ ░░░░  ░░░░
分析域           ████  ████  ░░░░  ██░░  ░░░░  ░░░░  ← 停滞
决策域           ████  ████  ░░░░  ░░░░  ░░░░  ░░░░  ← 停滞
执行域           ████  ████  ░░░░  ░░░░  ░░░░  ░░░░  ← 停滞
```

### 综合数据速查（分析时点快照）

```
Release:               v1.12.1
分析时间:              2026-06-21T02:35 CST
模块总数:              53
SPEC 覆盖:             53/53（100%）
AC 覆盖:               17/53（32%）
TC 覆盖:               24/53（45%）
tasks 覆盖:            26/53（49%）
evidence 覆盖:         2/53（4%）
Foundation Blocker:    0/11（全解决）
命名不规范目录:        21/53（40%，含 18 kebab + 3 snake）
Approved 无 AC:        8 个
SPEC 占位符(<1KB):     0 个
业务域 tasks=0 的域:   分析域（6）+ 决策域（8）+ 执行域（7）= 21 个模块
```

---

*[RULES I BROKE]：无*
