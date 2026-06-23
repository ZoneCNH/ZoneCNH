# ADR: module/binance 多交易所泛化架构决策

- Report-Date: 2026-06-23
- Scope: SPEC §23 OQ-005 / OQ-006 — `Binance server` 是否支持非 Binance multi-exchange；Binance 以外 CEX 是否参照此 C/S 架构统一
- Status: **Proposed**（待 architecture owner 决策；本报告提供分析与推荐，不直接修改 SPEC）
- Confidence: HIGH（架构事实层）/ MED（推荐方案含主观权衡）

> 本 ADR 对应数据流架构分析报告（PR #916）§3.3 P2-1。结论采纳后另起 SPEC 变更 PR。

---

## 1. 决策背景

[KNOWN][HIGH] `module/binance` 当前架构强绑定 Binance：
- natsx subject 前缀 `binance.market.*`
- Kafka topic 前缀 `binance.{product_line}.{event_type}.v1`
- OSS path 前缀 `binance/{product_line}/...`
- TDengine database `binance_market`
- 模块名 / 仓库名 / 进程名 `binance-client` / `binance-server`
- BR-007 约束：canonical domain semantics 必须来自 `domain_market`（exchange-neutral）

[COMPUTED][HIGH] OQ-005/006 的本质：当接入 OKX / Bybit / Deribit 等第二交易所时，是**复用 binance 模块**（扩成通用 CEX 模块）还是**复制一套同构模块**（每交易所独立模块）？

## 2. 选项分析

### Option A：扩 binance 为通用 CEX 模块

[FRAME][MED] 抽 exchange 维度：subject 改 `market.{exchange}.{product_line}.{event_type}`，binance 成为 `exchange=binance` 的实例。

| 维度 | 评估 |
|---|---|
| 优点 | 单模块单 server，跨交易所 OLAP/归档统一；subject 自描述 exchange |
| 缺点 | 破坏当前 4×6 矩阵（R2）、所有 subject/topic/path 重写、binance 特有逻辑（funding_rate/mark_price/depth 拼合）与通用抽象冲突 |
| 风险 | [INFERRED][MED] 通用抽象过早，YAGNI；不同交易所 event 模型差异大（Binance depth update_id vs OKX checksum），强行统一会泄漏复杂度进 canonical mapper |

### Option B：每交易所独立模块，共享 C/S 架构模板（推荐）

[COMPUTED][HIGH] binance 模块保持 Binance 专属；抽取 C/S 架构为**可复用模板**（文档级 + domain_market 接口级），新交易所照此建 `module/okx/`、`module/bybit/`。

| 维度 | 评估 |
|---|---|
| 优点 | 模块边界清晰、BR-007 exchange-neutral canonical 类型复用、不破坏 binance 现有矩阵、每交易所特有逻辑自包含 |
| 缺点 | 跨交易所联合查询需 market_data 层聚合（已是其职责） |
| 风险 | [INFERRED][LOW] 模板漂移——通过 CONSTITUTION 补"CEX 模块标准"节治理 |

### Option C：抽象 `module/exchange_base` 共享层

[FRAME][LOW] binance/okx 共用 `exchange_base`（client/server 骨架 + natsx/taosx 接入），交易所特有逻辑下沉。

| 维度 | 评估 |
|---|---|
| 优点 | 代码复用最大化 |
| 缺点 | 引入新跨模块依赖层，违反"域内模块平级"原则；抽象成本高，当前仅 1 个交易所实例不摊薄 |
| 风险 | [INFERRED][MED] 过早抽象，违反 YAGNI；待有 2+ 交易所实例后再评估 |

## 3. 推荐方案

[COMPUTED][HIGH] **推荐 Option B**：binance 保持专属模块，C/S 架构作为模板供未来交易所参照。

### 理由

1. **YAGNI**：当前仅 Binance 一个交易所实例，通用化（Option A/C）的抽象成本无摊薄对象。
2. **BR-007 已隔离 canonical 语义**：`domain_market` 已是 exchange-neutral，新交易所复用 canonical 类型零成本，无需改 binance。
3. **R2 矩阵稳定**：binance 的 4×6 subject 矩阵不破坏，交割合约 instrument_subtype（v3.4.0）等已落地的契约不受影响。
4. **聚合职责在 market_data**：跨交易所联合查询本就是 exchange-neutral pipeline 职责（SPEC §2、§6 Consumers），不需 binance 承担。
5. **模板化成本可控**：C/S 架构、boundary gate、storage 层、idempotency 模式已是文档化知识，新交易所模块按 CONSTITUTION §1-§14 + 本模块结构照建即可。

### 边界条件（何时重评估）

[FRAME][MED] 若出现以下任一，重评估升级到 Option A 或 C：
- 接入第 3 个交易所，且跨交易所联合 OLAP 成为高频需求（市场中性套利等）
- 交易所间 event 模型收敛到可统一抽象（如统一 depth 增量协议）
- market_data 层聚合成为性能瓶颈

## 4. 落地动作（采纳后）

| # | 动作 | 涉及 | 触发条件 |
|---|---|---|---|
| A1 | SPEC §23 OQ-005/006 状态从"待评估"改为"已决策 — Option B" | SPEC.md | 本 ADR 采纳 |
| A2 | CONSTITUTION 补"CEX 行情模块标准"节（C/S 模板 + boundary gate 范式 + domain_market 复用要求） | CONSTITUTION.md | 首个非 binance 交易所立项时 |
| A3 | 新建 `module/{exchange}/` 按本模块结构照建 | 新模块 | 业务需求驱动 |

## 5. 决策结论

[COMPUTED][HIGH] OQ-005：**否**——binance server 不支持非 Binance multi-exchange，保持 Binance 专属。
[COMPUTED][HIGH] OQ-006：**是（模板复用，非代码合并）**——Binance 以外 CEX 参照此 C/S 架构建独立模块，不合并进 binance。

[KNOWN][HIGH] 本决策不触发 SPEC bump（OQ 状态变更属文档治理，按 R3/CONSTITUTION §10.4 不 bump Spec-Version）。采纳后 A1 同 PR 更新 OQ 状态即可。

[RULES I BROKE]：无。本报告为只读分析 + 决策建议，未修改任何受保护产物。所有判断附证据标签与置信度，对齐宪法 §20。
