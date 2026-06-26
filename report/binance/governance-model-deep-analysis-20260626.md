# Binance 模块治理模式深度分析

- Report-Date: 2026-06-26
- Module: `module/binance`
- Trigger: 数据域 CS 架构治理模式是否需要优化？
- Verdict: **需要优化 — "减负、分层、修断链" 方向，非"加规则"方向**
- Status: 分析完成，立即项已落地；中长期项待追踪

---

## 一、核心判断

binance 的治理模式是**一个先行模块在 5 个月探索中积累的有机体系**。它为整个 ZoneCNH 模块治理框架提供了宝贵的实战经验（直接催生了 `MODULE-GOVERNANCE.md` 八域体系），但也积累了 8 个可明确诊断的结构性张力。

问题不在于 binance "治理不够"，而在于：
1. **治理密度过高**（10 条单模块规则、27 个必存文档），对后续模块形成不可持续的模板预期
2. **两处断链**（maturity_ref 引用断裂、SPEC 状态滞后）— **已修复**
3. **三处真空**（子模块治理未定义、推广路径缺失、依赖矩阵无机器强制）

---

## 二、现状快照

| 维度 | 数值 | 评价 |
|------|------|------|
| SPEC 版本 | v3.7.1 | 高频迭代 |
| FR 数量 | 44 条（34 current + 4 draft + 6 pending） | 远超典型数据采集器 |
| 追溯覆盖率 | 100% FR→AC→TC→Task | 极其完备 |
| 实现进度 | 24 Done / 10 Partial / 10 Pending | 54% 完成度 |
| 边界门禁 | 13/13 PASS | 架构纪律良好 |
| 单模块规则 | R1-R10（6 硬 + 2 软 + 2 开） | 全仓库最密集 |
| 必存文档 | 27 个文件（R9 清单） | 维护成本高 |
| 运行时版本 | v0.2.0 (GitHub Release) | 已正式发布 |
| 生产就绪门禁 | PRG-001~007 全部 Pending | 尚未生产级 |
| 存储装配 | `bootstrap.None` + `MemoryIdempotencyStore` | 非生产级 |

### 在整体治理体系中的位置

- **数据域唯一 `active` 模块**：其余 9 个数据域模块（okx、hyperliquid、coinglass、fred、treasury、market_data、macro_data、pe_data、alternative_data）均为 `proposed`
- **C/S 架构先行者**：全仓库唯一 `arch_type: cs_module` 的模块
- **业务域依赖矩阵样例节点**：唯一在 `business_domain_modules` + `business_forbidden_edges` 中登记的模块
- **模块治理框架触发器**：binance 的 2026-06-22 治理审计复盘直接催生了 `MODULE-GOVERNANCE.md` 八域体系

---

## 三、八项结构张力诊断

### 张力 1：先行者过载（Pioneer Overload）【HIGH】

**现象**：binance 承载了远超一个数据采集器应有的治理密度。

**根因**：治理规则在 5 个月迭代中"有机生长"——每发现一个问题就加一条规则（R1-R10 来自 2026-06-22 审计复盘），每次复盘就增一份文档。这是**修 bug 式治理**，不是**设计式治理**。

**证据**：
- R3 自我批评：v3.1.0/v3.2.0/v3.3.0 三次 bump 是"文档治理类错误 bump"——版本通胀本身就是治理过载的症状
- SPEC.md 单文件 2176 行
- 27 个必存文档中，部分（DATA-QUALITY-SLA.md、ARCHITECTURE-DRIFT-WATCHLIST.md）使用频率存疑

**影响**：如果 okx/hyperliquid 等后续模块也被要求达到同等级别，准入门槛将高到不切实际。

**建议**：定义分层治理等级（见 §4.1）。

---

### 张力 2：成熟度假象（Maturity Illusion）【HIGH】· 部分已修复

**现象**：外部看 `lifecycle: active` + `release v0.2.0` → 生产模块。内部看：54% FR Done、PRG 全 Pending、存储用 MemoryIdempotencyStore。

**根因**：模块生命周期 `proposed→active` 的毕业门禁是"SPEC Approved + 首次 CI pass"，不要求功能完整度。binance 合法通过门禁，但 `active` 标签语义暗示"生产可用"。

**证据**：
- `maturity_ref: .foundationx/status/index.json#binance` → **已修复**（registry.yaml 移除断裂引用，对齐 alertx/x.go 等业务域模块惯例：无 .foundationx 条目则不设 maturity_ref）
- G0 存储装配用 `bootstrap.None` — 9 个存储类 FR 代码存在但未真实装配

**建议**：中期区分 `active` 与 `production_ready` 子状态。

---

### 张力 3：SPEC 状态语义滞后（State Semantics Lag）【MEDIUM】· 已修复

**现象**：SPEC.md Status = `Approved`，但 runtime 已发布 v0.2.0。

**分析**：按 LIFECYCLE.md，`Approved → Implemented` 条件是"所有 FR Done + DoD 齐全"。当前 24/34 Done（71%），所以停留在 Approved 是**技术上正确的**。但 SPEC v3.7.0→v3.7.1 时做了大规模事后行为规范补齐（19 条 FR 的 WHEN/THEN/AND），代码先实现、规范后补，使 SPEC Status 无法反映实际进展。

**修复**：在 SPEC.md §1 新增 `SPEC-Runtime 关系：异步演进` 字段，显式声明"SPEC Status `Approved` 反映规格侧最新批准状态，不等于 runtime 功能完整度。完整 FR 实现状态以 TRACEABILITY.md §1 矩阵为准。"

---

### 张力 4：文档通胀与版本通胀（Doc & Version Inflation）【MEDIUM】

**现象**：
- SPEC.md 从 v1.0 增长到 v3.7.1，v3.1.0/v3.2.0/v3.3.0 被 R3 自我批评为"文档治理类错误 bump"
- ACCEPTANCE.md 有 104 条当前 AC + 24 条 Draft AC，多数 TC 为 Pending
- 治理文档只增不减——R5 要求 task 归档物理隔离（好规则），但对治理文档自身无退休机制

**根因**：治理熵增——每轮审计加文档、加规则、加检查项，几乎不退役。

**建议**：建立文档退役审计 —— 每季度检查 R9 清单中哪些文档 3 个月未被引用或更新，考虑合并或归档。

---

### 张力 5：子模块治理的隐式层级（Implicit Sub-Module Hierarchy）【MEDIUM】

**现象**：binance 有 client/ 和 server/ 子模块，各有独立的 SPEC.md、TRACEABILITY.md，但 MODULE-GOVERNANCE.md 八域体系只定义"模块"级，无"子模块"概念。

**问题**：
- client/server 的 SPEC 独立 bump（R3 允许），但不是 registry.yaml 中的独立条目
- 子模块无独立 lifecycle——隐式继承 binance 的 `active`
- 当 server 比 client 更成熟时，无法独立表达

**建议**：在 MODULE-GOVERNANCE.md 中增加子模块治理章节。

---

### 张力 6：数据域模块间推广路径缺失（Missing Propagation Path）【MEDIUM】

**现象**：数据域 10 个模块仅 binance 处于 active。binance 的治理经验（RULES.md、BOUNDARY-GATES.md、NAMING.md 模式）对其他 9 个 proposed 模块有巨大参考价值，但无文档描述"如何从 binance 模板化推广到 okx"。

**影响**：每个新交易所采集器将不得不从头摸索，或盲目复制 binance 的 27 个文档——两者都不对。

**建议**：创建 `module/binance/GOVERNANCE-TEMPLATE.md` 描述可复用模式（见 §4.2）。

---

### 张力 7：业务域依赖矩阵执行力真空（Enforcement Gap）【MEDIUM】

**现象**：FOUNDATION-DEPS.yaml 的 `business_forbidden_edges` 正确声明了 binance 禁止依赖 factor_engine/signal_factory/riskx 等，但 xlibgate 的 `FoundationDeps` struct 不消费 `business_*` 段——**依赖禁止只是文档承诺，无机器强制**。

**建议**：推进 Phase F —— 在 xlibgate 中扩展 import 扫描覆盖业务域。

---

### 张力 8：治理框架的自指问题（Self-Referential Governance）【LOW】

**现象**：binance 的 RULES.md 引用了 CONSTITUTION.md、MODULE-GOVERNANCE.md、LIFECYCLE.md、02-module-lifecycle.md、08-business-domain-deps.md、STRUCTURAL-SCORING.md、ARBITER-PROTOCOL.md……多层引用链。修改任一上层文档都可能级联触发 RULES.md 更新。

**影响**：治理一致性维护成本随引用深度指数增长。

**建议**：RULES.md 对上层文档的引用改为"遵守而不重复"原则。

---

## 四、优化建议

### 4.1 分层治理等级体系【中期】

为数据域 C/S 采集器定义三个治理等级：

| 等级 | 目标 lifecycle | 最低治理要求 | 示例 |
|------|--------------|-------------|------|
| **L1 原型** | `proposed` | SPEC.md（简化版，8 节）+ 基本 AC + 命名登记 | okx、hyperliquid |
| **L2 活跃** | `active` | 完整 SPEC（23 节）+ TRACEABILITY + BOUNDARY-GATES + NAMING + IMPLEMENTATION-PLAN | binance 当前 |
| **L3 生产** | `active` + PRG 全 PASS | L2 + 全部 PRG evidence + L3 Release Done + 健康度达标 | binance 目标 |

**核心原则**：治理随模块成熟度**渐进式加载**，非准入时一步到位。

---

### 4.2 可复用治理模板提取【中期】

从 binance 的 10 条 RULES 中区分可提升与专属规则：

| 类别 | 规则 | 去向 |
|------|------|------|
| **可提升** | R3（版本 bump）、R4（L1/L2 状态分层）、R5（归档隔离）、R6（版本统一）、R7（证据标签） | 提升到 MODULE-GOVERNANCE.md |
| **专属** | R1（命名一致性，依赖 NAMING.md SSOT）、R2（4×6 矩阵） | 保留在 binance/RULES.md |
| **模板化** | BOUNDARY-GATES.md 12 gate 模式、NAMING.md §1-§11 结构 | 提取为 GOVERNANCE-TEMPLATE.md |

---

### 4.3 Phase F 推进【中期】

在 xlibgate 中扩展 `FoundationDeps` struct 以消费 `business_forbidden_edges`，使 binance 的禁止依赖边获得 CI 强制执行。当前 MODULE-GOVERNANCE.md §1 已标记为后续工作。

---

### 4.4 治理精简审计【长期】

每季度一次"治理减负审计"：检查 R9 清单中哪些文档 3 个月未被引用或更新，考虑合并或归档。防止治理文档只增不减。

---

## 五、立即修复记录（2026-06-26 已执行）

| 修复项 | 文件 | 变更 |
|--------|------|------|
| maturity_ref 引用断裂 | `module/registry.yaml` L485 | 移除断裂的 `maturity_ref: .foundationx/status/index.json#binance`，替换为注释说明（对齐 alertx/x.go 等业务域模块惯例） |
| SPEC-Runtime 异步演进说明 | `module/binance/SPEC.md` §1 | 新增 `SPEC-Runtime 关系：异步演进` 字段，声明 SPEC Status 不等于 runtime 功能完整度 |

---

## 六、结论

binance 的治理模式**需要优化，方向是减负、分层、修断链**。

**已修复（本报告产出日）**：
- maturity_ref 引用断裂
- SPEC Status 语义滞后（通过显式异步演进说明）

**待推进（中期）**：
- 分层治理等级体系（L1/L2/L3）
- 可复用模板提取（GOVERNANCE-TEMPLATE.md + R3-R7 提升）
- 子模块治理章节（MODULE-GOVERNANCE.md 补全）
- Phase F 业务域依赖机器强制

**待建立（长期）**：
- 季度治理精简审计

**核心原则**：治理应随模块成熟度渐进式加载。binance 走到今天的治理密度是合理的——它是先行者，承担了探索成本。但要求 okx 一步到位则不合理。优化方向不是"减少 binance 的治理"，而是"为后续模块定义更轻量的起点，并为 binance 减掉不再需要的负担。"

---

## Appendix：已执行变更的 git diff 摘要

```diff
# module/registry.yaml
-  maturity_ref: .foundationx/status/index.json#binance
+  # maturity_ref: ~  — .foundationx/status 当前仅覆盖基座+L2.5（21 模块），业务域模块待扩展覆盖后补登记

# module/binance/SPEC.md
+- SPEC-Runtime 关系：异步演进 — SPEC v3.7.1 覆盖全部 44 FR...
```

---

[RULES I BROKE]：无
