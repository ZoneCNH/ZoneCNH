# module/binance 数据流架构深度分析

- Report-Date: 2026-06-23
- Scope: `module/binance/` 数据流架构、业务类型覆盖、模块规则/标准规范评估
- Method: 读取 `SPEC.md`（1266 行）、`RULES.md`、`STANDARD.md`、`NAMING.md`、`TRACEABILITY.md`、client/server 子规格，交叉比对 `docs/report/binance/business-types-coverage-20260622.md`
- Confidence: HIGH（架构层）/ MED（迭代优先级排序含主观判断）

> [COMPUTED][HIGH] Post-PR #936/current-docs note: 本报告中的 R2 `4×4` 矩阵缺口为 2026-06-23 历史分析口径；current module docs/checks have moved to a 4×6 event matrix and preserve the remaining rows as provenance/backlog context. See `pr-936-governance-docs-closure-20260623.md`.

> 本报告聚焦用户四问：① 数据流架构图 ② 业务类型（现货/合约/期权/订单簿）覆盖 ③ 其他需补充/优化/迭代点 ④ 是否需建立模块规则与标准规范。

---

## 1. 数据流架构图 — 现状评估

### 1.1 现有架构图（SPEC.md Appendix C）

[KNOWN][HIGH] 当前架构图为 ASCII 单向管道图，覆盖 6 层处理 + 7 个外部模块依赖：

```text
Binance Exchange (REST/WebSocket)
  ├─ Spot / USDⓈ-M / COIN-M / Options connector
  ▼
  Product-Line Catalog → Instrument Parser → Raw Event Normalizer
  → Canonical Mapper (domain_market) → Idempotency Key Generator
  → natsx Publisher (JetStream BINANCE_MARKET)
  ▼
  natsx Consumer (Server, ManualAck)
  → Validation → redisx SetNX Idempotency
  → taosx Storage / postgresx Catalog / kafkax Dispatch
  → msg.Ack() → Gin REST API
  ▼
  module/market_data (exchange-neutral pipeline)
```

[COMPUTED][HIGH] 架构图已表达的核心语义：

- **C/S 进程隔离**：client 采集 → natsx → server 消费，单向解耦
- **at-least-once + 幂等**：client 端 PubAck、server 端 ManualAck + redisx SetNX
- **canonical 映射**：Binance exchange-specific → domain_market canonical 类型
- **fanout**：kafkax 向下游 market_data 派发

### 1.2 架构图缺口

[COMPUTED][MED] 当前图未显式表达以下实际存在的支路，建议补强：

| #   | 缺失支路                             | 证据                                                                                        | 影响                                                           |
| --- | ------------------------------------ | ------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| G1  | **clickhousex OLAP + ETL scheduler** | FR-010、AC-BNC-011/014、ETL 每 5min 聚合                                                    | 图中无 taosx→clickhousex ETL 路径，OLAP 与热路径分离关系不可见 |
| G2  | **ossx 冷归档**                      | FR-008、AC-BNC-009、`binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` | 图中无 taosx 热数据→ossx 冷数据生命周期                        |
| G3  | **redisx 热缓存读路径**              | FR-007、AC-BNC-008/010，cache miss 回退 taosx                                               | Gin API→redisx→taosx 三级读路径未画                            |
| G4  | **coordinator lease（分布式锁）**    | FR-011、AC-BNC-015，redisx SetNX 竞选 + 10s 续期                                            | ETL/归档协调者选举机制不可见                                   |
| G5  | **kafkax 下游拓扑**                  | `binance.{product_line}.{event_type}.v1`                                                    | 仅画"Dispatch"方框，未表达下游 market_data 如何消费            |
| G6  | **funding_rate / mark_price 事件**   | FR-020/FR-021、NAMING.md §50-51                                                             | 图只画 tick/trade/bar/depth 四类，funding/mark price 缺席      |

[INFERRED][MED] G1-G4 是"已规划但图未更新"，G6 是"事件类型矩阵已扩但架构图仍是早期四事件快照"。建议在 SPEC Appendix C 增补一张**完整数据流图 v2**，分层标注热路径（real-time）、温路径（OLAP ETL）、冷路径（归档）、读路径（API cache）。

---

## 2. 业务类型覆盖 — 现货 / 合约 / 期权 / 订单簿

### 2.1 覆盖矩阵

[COMPUTED][HIGH] 基于 SPEC §7 FR-001~003、§9 subject 表、NAMING.md §1-§3：

| 业务类型          | 是否包含                | product_line 标识 | 证据                                                                   |
| ----------------- | ----------------------- | ----------------- | ---------------------------------------------------------------------- |
| 现货 Spot         | ✅                      | `spot`            | FR-001、connector、subject `binance.market.spot.*`                     |
| U 本位合约 USDⓈ-M | ✅                      | `um_perp`         | FR-001、subject `binance.market.um_perp.*`、funding_rate/mark_price    |
| 币本位合约 COIN-M | ✅                      | `cm_perp`         | FR-001、subject `binance.market.cm_perp.*`、funding_rate/mark_price    |
| 期权 Options      | ✅                      | `options`         | FR-003、identity 含 expiry/strike/option_type                          |
| 订单簿 Order Book | ✅（作为 `depth` 事件） | 跨四产品线        | FR-002、`@depth20@100ms` 快照 + `@depth@1000ms` 增量，`update_id` 拼合 |

[KNOWN][HIGH] 订单簿在本模块被建模为**行情数据类型 `depth`**，不是交易执行/下单系统——SPEC 明确排除订单执行（见 business-types-coverage 报告 §覆盖矩阵）。

### 2.2 真实缺口：交割合约（Delivery Futures）无 product_line 承载

[COMPUTED][HIGH] 这是本次分析发现的最重要结构性缺口：

- Binance USDⓈ-M 与 COIN-M 两条产品线**同时含永续（Perpetual）与交割（Delivery/Quarterly）两类合约**。
- 当前 `product_line` 枚举 `spot / um_perp / cm_perp / options` 中，`um_perp`/`cm_perp` 的命名**语义锁定为"永续"**（NAMING.md §17-18 明示"USDⓈ-M 永续"/"COIN-M 永续"）。
- SPEC §9 InstrumentType 枚举含 `Perpetual / Futures / Option / Spot`（line 548），且 um_perp/cm_perp 都带 `expiry` 维度（line 569）——**架构层可建模交割合约，但 product_line 命名层未承载**。
- 由此产生语义张力：`binance.market.um_perp.tick` 主题若承载交割合约 `BTCUSDT_240329`，subject 名与内容不符。

[INFERRED][MED] 影响：

1. 交割合约 symbol（如 `BTCUSDT_240329`）落入 `um_perp` subject，下游消费者无法从 subject 区分永续 vs 交割。
2. R2「4×4 对称矩阵」为历史分析口径；current docs/checks 已按 4×6 event matrix 收敛，剩余交割合约问题仅影响 product_line/instrument_subtype 决策。
3. 交割合约特有的 delivery_date / contract_type 字段在 identity 矩阵（SPEC line 559-571）未列。

### 2.3 其他业务类型评估

[COMPUTED][MED] 以下 Binance 业务类型**显式不在范围内**（SPEC 边界声明），无需补充，但建议在 SPEC §3 边界节显式列出以消歧：

| 业务类型          | 是否在范围 | 说明                       |
| ----------------- | ---------- | -------------------------- |
| 杠杆保证金 Margin | ❌ 排除    | 非 market data 采集目标    |
| 现货杠杆借贷      | ❌ 排除    | 同上                       |
| 下单/交易执行     | ❌ 排除    | 由 `orderx` / `riskx` 承担 |
| Portfolio Margin  | ❌ 排除    | 账户层，非行情             |
| Fiat/法币         | ❌ 排除    | 非 crypto market data      |

[FRAME][LOW] 若未来策略域需要交割合约价差或期权 IV 曲线，本模块需先扩 product_line 或引入 `instrument_subtype` 维度。

---

## 3. 需补充 / 优化 / 迭代点

### 3.1 P0 — 结构性缺口（建议本迭代处理）

| ID   | 项                                     | 建议                                                                                                                                                                                     | 触发规则              |
| ---- | -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| P0-1 | 交割合约 product_line 缺失             | 二选一：① 扩 product_line 为 `um_perp`/`um_delivery`/`cm_perp`/`cm_delivery`；② 保持 `um_perp`/`cm_perp` 但新增 `instrument_subtype` 维度区分永续/交割，并修订 NAMING.md §17-18 语义注释 | R2 对称矩阵需重算     |
| P0-2 | 数据流图未含 OLAP/归档/缓存/协调者支路 | SPEC Appendix C 增补完整数据流图 v2（热/温/冷/读四路径）                                                                                                                                 | R9 文档完整性         |
| P0-3 | 架构图缺 funding_rate/mark_price 事件  | 图中事件类型从 4 类扩到 6 类（+funding_rate/mark_price）                                                                                                                                 | R2 矩阵已含，图未同步 |

### 3.2 P1 — 治理优化（已有规则但需强化）

| ID   | 项                                                                                 | 现状                                                            | 建议                                               |
| ---- | ---------------------------------------------------------------------------------- | --------------------------------------------------------------- | -------------------------------------------------- |
| P1-1 | R2「4×4 矩阵」实际已扩为 4 product_line × 6 event_type（历史缺口）                   | Post-PR #936/current docs/checks 已按 4×6 收敛                      | 保留为历史 provenance；后续只跟踪新维度变更        |
| P1-2 | `check-binance-docs.sh` 位于本仓 `scripts/`，但 runtime 仓另有 `boundary-gates.sh` | 两套 gate 分离                                                  | 在 STANDARD.md 增加两脚本职责对照表                |
| P1-3 | L2 Functional FR 全部 Pending                                                      | business-types-coverage 报告确认                                | 无需文档侧动作，但应在迭代计划标注 L2 是主 backlog |

### 3.3 P2 — 迭代方向（中长期）

[INFERRED][MED] 以下不构成缺口，是演进建议：

- **P2-1 多交易所泛化**：SPEC OQ-005/006 已留开放问题。若未来接入 OKX/Bybit，当前 `binance.market.*` subject 前缀设计需评估是否抽 exchange 维度。
- **P2-2 数据质量监控**：当前有 redelivery warn，但无 schema 漂移检测、无延迟告警阈值定义。建议补 NFR for data freshness SLA。
- **P2-3 回填/历史数据**：SPEC 未明确历史回填路径（REST 拉取 vs WebSocket replay），若回测域需要，需补 FR。
- **P2-4 Options Greeks/IV**：当前 Options 只采 tick/bar/depth/trade，未规划 IV/Greeks 派生——若决策域需要，属分析域职责，但需本模块透传原始 option chain 字段。

---

## 4. 模块规则与标准规范 — 现状评估

### 4.1 已建立且成熟

[COMPUTED][HIGH] `module/binance/` **已建立完整模块规则体系**，无需从零建立：

| 制品                              | 行数 | 作用                                                       | 成熟度       |
| --------------------------------- | ---- | ---------------------------------------------------------- | ------------ |
| `RULES.md`                        | 262  | R1-R10 治理规则，每条标注【硬/软/开】+ 检测命令 + 修复义务 | ✅ 成熟      |
| `STANDARD.md`                     | 71   | Runtime control 薄标准入口（FR-024 hot reload）            | ✅ Active    |
| `NAMING.md`                       | 140  | 命名 SSOT（product_line/subject/topic/tag/path/env）       | ✅ 成熟      |
| `BOUNDARY-GATES.md`               | 359  | 12 个 CI gate 定义                                         | ✅ 成熟      |
| `ARCHITECTURE-DRIFT-WATCHLIST.md` | 126  | 漂移监控点                                                 | ✅ 成熟      |
| `scripts/check-binance-docs.sh`   | —    | 文档漂移机器检测                                           | ✅ 已接入 CI |

[COMPUTED][HIGH] 规则体系特点（优于多数模块）：

- 每条规则可机器检测（grep / check 脚本）
- 措辞强度分级（【硬/软/开】）对齐 `~/.claude/rules/ecc/matrix-scoring-rules.md` R0
- L1/L2 证据分层防止"boundary gate PASS 推导功能已实现"
- 版本字段统一（R6）+ bump 触发器（R3）已上提至 CONSTITUTION §10.4

### 4.2 规则侧需迭代点

| ID  | 项                                        | 建议                                                       |
| --- | ----------------------------------------- | ---------------------------------------------------------- |
| R-1 | R2 矩阵维度过期（4×4 → 实际 4×6，历史缺口） | Post-PR #936/current docs/checks 已收敛；保留 provenance |
| R-2 | 无规则覆盖"交割合约 product_line 承载"    | P0-1 决策后补 R11 或扩 R2                                  |
| R-3 | R9 文档存在性清单已含 `DATA-LIFECYCLE.md` | 确认 OK，无需动作                                          |
| R-4 | 无规则要求数据流图与 FR/事件矩阵同步      | 建议增软规则：SPEC Appendix C 必须反映当前 event_type 全集 |

### 4.3 结论：是否需要建立模块规则

[COMPUTED][HIGH] **不需要从零建立——已建立且是仓库内最成熟的模块规则体系之一**。当前需求是**迭代**（R2 矩阵维度、交割合约承载规则、数据流图同步规则），而非新建。建议将本报告 P0/P1 项纳入 `iteration-plan-20260622.md` 下一轮迭代。

---

## 5. 行动建议（优先级排序）

| 优先级 | 行动                                                               | 涉及文件                                | 触发             |
| ------ | ------------------------------------------------------------------ | --------------------------------------- | ---------------- |
| P0     | 决策交割合约承载方案（扩 product_line vs 加 instrument_subtype）   | NAMING.md、SPEC.md §9、RULES R2         | 本报告 §2.2      |
| P0     | SPEC Appendix C 增补完整数据流图 v2                                | SPEC.md                                 | 本报告 §1.2      |
| P0     | 架构图补 funding_rate/mark_price 事件                              | SPEC.md Appendix C                      | 本报告 §1.2 G6   |
| P1     | R2 矩阵维度 4×4 → 4×6 + 更新 check 脚本（历史项，current docs/checks 已收敛） | RULES.md、scripts/check-binance-docs.sh | 本报告 §3.2 P1-1 |
| P1     | STANDARD.md 增 check-binance-docs.sh vs boundary-gates.sh 职责对照 | STANDARD.md                             | 本报告 §3.2 P1-2 |
| P2     | 评估多交易所泛化（OQ-005/006）                                     | SPEC.md §18 Open Questions              | 中长期           |

---

## 6. 最终判断

[COMPUTED][HIGH] 四问回答：

1. **数据流架构图**：已有 6 层单向管道图，但缺 OLAP/归档/缓存/协调者/funding/mark price 六条支路，建议增补 v2。
2. **业务类型覆盖**：现货 ✅、U 本位合约 ✅、币本位合约 ✅、期权 ✅、订单簿 ✅（depth 事件）。**真实缺口：交割合约无 product_line 承载**（um_perp/cm_perp 命名锁定永续）。
3. **其他需补充/优化/迭代**：P0 三项（交割合约、数据流图 v2、funding/mark price 入图）、P1 三项（R2 矩阵维度、脚本职责对照、L2 backlog）、P2 四项（多交易所、数据质量 SLA、历史回填、Options Greeks）。
4. **模块规则与标准规范**：**已建立且成熟**（R1-R10 + STANDARD + NAMING + BOUNDARY-GATES + check 脚本），无需新建，需迭代 R2 维度与新增交割合约承载规则。

[KNOWN][HIGH] 关键风险：交割合约缺口（§2.2）是本次分析唯一发现的真实结构性问题，其余多为"已规划但图/规则未同步"的文档一致性问题。

[RULES I BROKE]：无。本报告为只读分析，未修改任何受保护产物。所有判断附证据标签与置信度，对齐宪法 §20。
