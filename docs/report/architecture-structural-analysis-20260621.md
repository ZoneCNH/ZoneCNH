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
                           └─ x.go（Composition Root，只做装配）
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

`contracts`（跨域稳定端口、事件协议、DTO 契约）是整个业务链路的依赖枢纽，但当前 `Status: Docs`，未进入 Approved。

**影响链**：
```
contracts 未冻结
  → 分析域/决策域/执行域无法安全依赖 DTO 契约
  → signal_factory / risk_engine / order_engine 等核心路径处于漂移风险
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

#### 问题 A4：L2.5 域共享层定义与命名混乱（中）

`domain-market`（kebab）对应仓库 `domain_market`（snake），`domain-macro` 对应 `domain_macro`，`domain-exchange` 对应 `domain_exchange`——目录命名、仓库命名、SPEC 内部引用三者不一致。L2.5 是所有业务域的依赖根节点，混乱将随依赖扩散放大。

#### 问题 A5：x.go 组合根无模块规格（低）

`x.go` 已从 `module/` 移除，设计上合理，但 `sre/docs/x.go/` 文档与 `ARCHITECTURE.md` 中的 x.go 描述未形成统一管理入口，在系统集成阶段可能造成盲区。

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

Approved 但无 AC 的模块（8个）：
  binance、decimalx、domain-exchange、domain-market、
  postgresx、resiliencx、taosx、testkitx
```

Approved 模块无 AC 是最严重的问题——意味着已过审批但无验收标准，无法证明实现满足需求。

#### 问题 S2：TC 缺失率 55%（严重）

29/53 个模块无 TC（测试用例），包括分析/决策/执行域全部模块。TC 缺失意味着测试设计完全未启动。

#### 问题 S3：5 个 SPEC 为占位符（中）

以下模块 SPEC 内容 <1KB，为明显占位符，缺乏实质性需求定义：

| 模块 | 字节数 | 域 |
|------|:------:|-----|
| `settlement` | 792 | 执行域 |
| `portfolio-engine` | 864 | 执行域 |
| `risk-engine` | 909 | 执行域 |
| `order-engine` | 964 | 执行域 |
| `macro_regime` | 859 | 分析域 |

执行域 4/7 个核心模块均为占位符，这是系统安全性的重大风险点。

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
| 执行域 | 7 | 100% | 0% | 0% | 🔴 4/7 SPEC 占位符，最高优先级风险 |

---

## 五、优先行动矩阵

### P0 — 关键路径解锁（1-2 周）

| # | 行动 | 受益 | 工作量 |
|---|------|------|:------:|
| 1 | **contracts 推进至 Approved** | 解锁所有业务域 AC 定义 | 大 |
| 2 | **为 8 个 Approved 模块补充 AC** | 消除验收盲区，直接可用 | 中 |
| 3 | **执行域 5 个占位符 SPEC 扩充** | risk/order/portfolio/settlement 是实盘核心 | 大 |

### P1 — 管线前进（2-4 周）

| # | 行动 | 受益 | 工作量 |
|---|------|------|:------:|
| 4 | **18 个 Draft → Review/Approved** | 直接解锁 tasks 拆分资格 | 大 |
| 5 | **分析域/决策域补充 tasks**（从 regime_engine / signal_factory 开始）| 核心业务链路启动 | 大 |
| 6 | **L2.5 目录命名统一**（kebab→snake）| 消除引用歧义，与宪法对齐 | 小 |

### P2 — 质量提升（持续）

| # | 行动 | 受益 | 工作量 |
|---|------|------|:------:|
| 7 | **数据域补全 tasks**（macro-data / market-data）| 数据域进入可执行状态 | 中 |
| 8 | **补全 prompt / evidence**（从 Foundation 层开始）| 四源评分后段实际激活 | 中 |
| 9 | **ADR 补录**（L2.5 设计、三引擎契约决策）| 减少隐性技术债 | 小 |
| 10 | **live_integration 推进**（7→15+）| v0.1.0 里程碑 | 大 |

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

### 综合数据速查

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
SPEC 占位符(<1KB):     5 个
业务域 tasks=0 的域:   分析域（6）+ 决策域（8）+ 执行域（7）= 21 个模块
```

---

*[RULES I BROKE]：无*
