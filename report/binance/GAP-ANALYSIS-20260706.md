# Binance 模块差距分析报告 — report/binance/20260704.md vs module/binance/

> **分析日期**：2026-07-06（UTC）
> **分析对象**：`report/binance/20260704.md`（Binance 四产品线事件流深度分析）
> **对比基线**：`module/binance/` 全量治理制品（SPEC v3.18.0 / Runtime v0.13.0 / 55 FR Done）
> **分析目标**：识别报告中涉及但 `module/binance/` 未覆盖/未文档化的内容，按 spot/um_perp/cm_perp/options 四线拆解
> **v3.18.0 更新**：canonical 命名对齐 Binance 原生事件名（camelCase→snake_case），6 个 rename（tick→book_ticker / bar→kline / depth→depth_update / mark_price→mark_price_update / liquidation→force_order / contract_meta→contract_info）
> **认识论声明**：本报告所有事实性声明均标注证据标签与置信度

---

## 一、报告内容概览

`report/binance/20260704.md` 是一份针对 Binance 四条产品线（spot / um_perp / cm_perp / options）事件流的工程级深度分析，包含四大板块：

| 板块                 | 内容                                                         | 事件类型数 |
| -------------------- | ------------------------------------------------------------ | ---------- |
| 行情数据流（公开流） | 20 种 Binance 原生事件类型 × 4 产品线覆盖矩阵 + 幂等键维度   | 20         |
| 用户数据流（私有流） | 19 种 Binance 原生事件类型 × 4 产品线覆盖矩阵 + 幂等键维度   | 19         |
| 序号连续性校验       | 行情流 + 用户流的序号连续性策略（强制/间接/自愈/不适用）     | 39         |
| 历史数据同步         | 公开行情起始时间策略 + 私有数据 REST 窗口限制 + 系统设计建议 | —          |

**额外包含**三个平台变更风险提示：

1. CM Perp → UM 架构迁移（2026-06-29 完成，`fs`:"UM"/"CM" 区分）
2. Options 系统重构期（事件名可能变更）
3. 现货 CSV 时间戳单位变更（2025-01-01 起 ms → μs）

---

## 二、module/binance/ 现有覆盖

### 2.1 SPEC 覆盖 `[KNOWN, HIGH]`

| SPEC 条款                        | 覆盖内容                                                                 | 与报告的关系                                                                   |
| -------------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| §3 Scope                         | "不包含交易下单、账户管理、私有交易策略"                                 | 明确排除用户数据流，现已补充指向 ADR-009                                       |
| §6 Product Lines and Event Types | `event_type = tick, bar, depth, trade, funding_rate, mark_price`（6 类） | 覆盖 20 种行情事件中的 6 种 canonical 映射，现已补充指向 EVENT-TYPE-MAPPING.md |
| FR-015 (client SPEC)             | 6 类 event_type 的幂等键生成规则                                         | 覆盖 6 类 canonical 类型，现已补充完整映射表                                   |
| FR-016~019, FR-026~027           | 回填规划、资源治理、检查点恢复、多产品线生命周期                         | 覆盖回填基础设施，现已补充策略层文档                                           |
| ADR-003                          | Order book rebuild 排除决策                                              | 覆盖 depth 序号校验的排除决策，现已补充完整序号策略文档                        |

### 2.2 Design 覆盖（修复后） `[KNOWN, HIGH]`

| Design 文档                                  | 覆盖内容                                                      | 与报告的关系                   |
| -------------------------------------------- | ------------------------------------------------------------- | ------------------------------ |
| DESIGN.md §3                                 | 数据流图                                                      | 架构层覆盖                     |
| ADR-003                                      | depth order book rebuild 排除                                 | 覆盖 depth                     |
| ADR-005~008                                  | 符号分级、白名单                                              | 不涉及事件类型映射             |
| **EVENT-TYPE-MAPPING.md**（新增，v3.17.0 重写） | 事件类型语义分类框架：四问判据 + 20 种行情事件逐一语义归类 + 5 个 planned canonical 类型 + 误映射后果登记 + 四产品线覆盖矩阵 | **完整覆盖报告 §一** |
| **SEQUENCE-CONTINUITY-STRATEGY.md**（新增）  | 行情流 + 用户流序号策略 + depthUpdate 8 步重建 + z/l 交叉校验 | **完整覆盖报告 §序号连续性**   |
| **HISTORICAL-DATA-SYNC-STRATEGY.md**（新增） | 公开行情起始时间 + REST 窗口 + 时间戳变更 + depth 无回溯      | **完整覆盖报告 §历史数据同步** |
| **ADR-009**（新增）                          | 用户数据流排除决策 + 未来路径                                 | **完整覆盖报告 §二排除理由**   |
| **ADR-010**（新增）                          | CM→UM 迁移 + Options 重构 + 时间戳变更风险                    | **完整覆盖报告平台变更提示**   |

---

## 三、逐产品线差距分析

### 3.1 Spot `[COMPUTED, HIGH]`

**报告覆盖的 spot 行情事件**（13 种）：aggTrade ✓, trade ✓, blockTrade ✓, kline ✓, depthUpdate ✓, bookTicker ✓, 24hrTicker/24hrMiniTicker ✓, 滚动窗口 ticker ✓, avgPrice ✓, referencePrice ✓, serverShutdown ✓

**SPEC §6 canonical 覆盖**：4 类（trade, bar, depth, tick）—— 通过 aggTrade→trade, kline→bar, depthUpdate→depth, bookTicker→tick 映射

**未覆盖的 spot 专属事件及决策**：

| Binance 原生事件            | 决策             | 理由                                     | 文档位置                 |
| --------------------------- | ---------------- | ---------------------------------------- | ------------------------ |
| blockTrade                  | 排除             | spot 新增大宗交易流，无下游需求          | EVENT-TYPE-MAPPING.md §2 |
| 24hrTicker/24hrMiniTicker   | 排除             | 可由 trade/bar 聚合计算                  | EVENT-TYPE-MAPPING.md §2 |
| 滚动窗口 ticker（1h/4h/1d） | 排除             | 同上，可聚合计算                         | EVENT-TYPE-MAPPING.md §2 |
| avgPrice                    | 排除             | 可由 trade 聚合计算                      | EVENT-TYPE-MAPPING.md §2 |
| referencePrice              | 排除             | 少量新资产，覆盖面极窄                   | EVENT-TYPE-MAPPING.md §2 |
| serverShutdown              | 排除（事件本身） | 连接级生命周期事件，由 WS reconnect 处理 | EVENT-TYPE-MAPPING.md §2 |

**spot 专属风险**：2025-01-01 起 CSV 时间戳 ms→μs 变更（仅影响 spot）→ ADR-010 R-P3 + HISTORICAL-DATA-SYNC-STRATEGY.md §5.1

**报告覆盖的 spot 用户数据流事件**（6 种）：outboundAccountPosition, balanceUpdate, executionReport, listStatus, eventStreamTerminated, externalLockUpdate → ADR-009 排除

---

### 3.2 UM Perp (USDⓈ-M) `[COMPUTED, HIGH]`

**报告覆盖的 UM 行情事件**（14 种）：aggTrade ✓, kline ✓, continuousKline ✓, indexPriceKline/markPriceKline ✓, depthUpdate ✓, bookTicker ✓, 24hrTicker/24hrMiniTicker ✓, markPriceUpdate ✓, forceOrder ✓, compositeIndex ✓, assetIndex ✓, contractInfo ✓, serverShutdown ✓

**SPEC §6 canonical 覆盖**：6 类全覆盖（trade, bar, depth, tick, funding_rate, mark_price）—— aggTrade→trade, kline→bar, depthUpdate→depth, bookTicker→tick, markPriceUpdate→mark_price/funding_rate

**R2 修复状态**：已修复 @fundingRate + @markPrice 独立流订阅（todo.md R2 Done）

**未覆盖的 UM 专属事件及决策**：

| Binance 原生事件                 | 决策             | 理由                                    | 文档位置                 |
| -------------------------------- | ---------------- | --------------------------------------- | ------------------------ |
| continuousKline                  | 排除             | 连续合约 K 线，需 contractType 维度扩展 | EVENT-TYPE-MAPPING.md §2 |
| indexPriceKline / markPriceKline | 排除             | mark_price 已通过 markPriceUpdate 覆盖  | EVENT-TYPE-MAPPING.md §2 |
| 24hrTicker/24hrMiniTicker        | 排除             | 可由 trade/bar 聚合计算                 | EVENT-TYPE-MAPPING.md §2 |
| forceOrder                       | 排除             | 属交易域事件（强平单），与 ADR-009 一致 | EVENT-TYPE-MAPPING.md §2 |
| compositeIndex                   | 排除             | 多资产模式指数，当前无多资产需求        | EVENT-TYPE-MAPPING.md §2 |
| assetIndex                       | 排除             | UM 资产指数，当前无下游需求             | EVENT-TYPE-MAPPING.md §2 |
| contractInfo                     | 部分覆盖         | FR-031~036 通过 REST ExchangeInfo 覆盖  | EVENT-TYPE-MAPPING.md §2 |
| serverShutdown                   | 排除（事件本身） | 连接级生命周期事件                      | EVENT-TYPE-MAPPING.md §2 |

**报告覆盖的 UM 用户数据流事件**（13 种）：listenKeyExpired, ACCOUNT_UPDATE, ORDER_TRADE_UPDATE, TRADE_LITE, MARGIN_CALL, ACCOUNT_CONFIG_UPDATE, ALGO_UPDATE, CONDITIONAL_ORDER_TRADE_UPDATE, STRATEGY_UPDATE, GRID_UPDATE → ADR-009 排除

---

### 3.3 CM Perp (COIN-M) `[COMPUTED, HIGH]`

**报告覆盖的 CM 行情事件**（11 种）：aggTrade ✓, kline ✓, continuousKline ✓, indexPriceKline/markPriceKline ✓, depthUpdate ✓, bookTicker ✓, 24hrTicker/24hrMiniTicker ✓, markPriceUpdate ✓, forceOrder ✓, contractInfo ✓, serverShutdown ✓

**SPEC §6 canonical 覆盖**：6 类全覆盖（与 UM 相同的映射）—— aggTrade→trade, kline→bar, depthUpdate→depth, bookTicker→tick, markPriceUpdate→mark_price/funding_rate

**CM 专属平台变更风险**：

> `[KNOWN, MED]` CM 于 2026-06-29 左右完成向 UM 架构的迁移整合。用户数据流事件与 UM 趋同，payload 用 `fs`:"UM"/"CM" 区分。公开行情流是否受影响待确认。

→ ADR-010 R-P1 记录为"监控中"

**未覆盖的 CM 专属事件及决策**：与 UM 基本一致，但 CM 不推 compositeIndex（仅 UM 多资产模式）和 assetIndex（仅 UM）

**报告覆盖的 CM 用户数据流事件**（~9 种，部分带"?"）：listenKeyExpired, ACCOUNT_UPDATE, ORDER_TRADE_UPDATE, MARGIN_CALL, ACCOUNT_CONFIG_UPDATE, CONDITIONAL_ORDER_TRADE_UPDATE, STRATEGY_UPDATE；TRADE_LITE?, ALGO_UPDATE?, GRID_UPDATE? → ADR-009 排除

**CM 不确定项**（报告标注 "?"）：TRADE_LITE, ALGO_UPDATE, GRID_UPDATE 是否在 CM 上线——建议上线前对一遍最新 changelog

---

### 3.4 Options `[COMPUTED, HIGH]`

**报告覆盖的 Options 行情事件**（7 种）：trade ✓（underlyingAsset@trade）, kline ✓, depthUpdate ✓, 24hrTicker/24hrMiniTicker ✓, openInterest ✓, serverShutdown ✓, markPriceUpdate ?（期权有独立 markPrice 结构）

**SPEC §6 canonical 覆盖**：3~4 类—— trade→trade, kline→bar, depthUpdate→depth；mark_price 为"?"（需验证 eapi 是否推送 markPriceUpdate 或独立结构）

**Options 专属风险**：

> `[KNOWN, MED]` Options 处于系统重构期（官方 "Options Demo Trading" 升级），事件名可能变更。FR-030 Options Chain Raw Field Pass-through 的字段名可能需要更新。

→ ADR-010 R-P2 记录为"监控中"

**未覆盖的 Options 专属事件及决策**：

| Binance 原生事件          | 决策             | 理由                                 | 文档位置                 |
| ------------------------- | ---------------- | ------------------------------------ | ------------------------ |
| openInterest              | 排除             | options 持仓量 WS 流，当前无下游需求 | EVENT-TYPE-MAPPING.md §2 |
| 24hrTicker/24hrMiniTicker | 排除             | 可由 trade/bar 聚合计算              | EVENT-TYPE-MAPPING.md §2 |
| serverShutdown            | 排除（事件本身） | 连接级生命周期事件                   | EVENT-TYPE-MAPPING.md §2 |

**Options 特殊点**：

- Options 不推 aggTrade（用 underlyingAsset@trade 替代）
- Options 不推 bookTicker（无 `tick` canonical 对应）
- Options 不推 forceOrder
- markPriceUpdate 标注 "?"——期权有独立 markPrice 结构，需验证
- openInterest 在 options 是 WS 流，在 futures 仅 REST 轮询

**报告覆盖的 Options 用户数据流事件**（2 种）：BALANCE_POSITION_UPDATE, ORDER_TRADE_UPDATE（payload 更简）→ ADR-009 排除

**Options REST 窗口限制**：`GET /eapi/v1/historyOrders` 仅最近 5 天（全产品线最短）→ HISTORICAL-DATA-SYNC-STRATEGY.md §3

---

### 3.5 四产品线差异速查 `[COMPUTED, HIGH]`

> **v3.17.0 更新**：以下"排除"措辞已过时，v3.17.0 引入四问分类判据后，14 个未覆盖事件已全部完成语义归类（→ planned canonical 类型或传输层处理）。详见 EVENT-TYPE-MAPPING.md §3。

| 差异维度         | spot                                             | um_perp                                     | cm_perp   | options                                                   |
| ---------------- | ------------------------------------------------ | ------------------------------------------- | --------- | --------------------------------------------------------- |
| 已实现 canonical | 4/6                                              | 6/6                                         | 6/6       | 3-4/6                                                     |
| planned canonical | ticker, index_reference                          | ticker, liquidation, index_reference, contract_meta | ticker, liquidation, contract_meta | ticker, open_interest |
| 独有行情事件     | blockTrade, 滚动ticker, avgPrice, referencePrice | continuousKline, compositeIndex, assetIndex | —         | openInterest(WS)                                          |
| 不适用的 canonical | funding_rate, mark_price, liquidation, open_interest, contract_meta | open_interest(WS) | open_interest, index_reference, liquidation? | tick, funding_rate, liquidation, index_reference, contract_meta |
| 用户数据流事件数 | 6                                                | ~13                                         | ~9(部分?) | 2                                                         |
| REST 回溯窗口    | 最宽松                                           | 30天-6个月                                  | 同 UM     | **5天**（最短）                                           |
| 平台变更风险     | CSV时间戳ms→μs                                   | —                                           | →UM迁移   | 系统重构期                                                |

---

## 四、差距清单（修复后状态）

### 已修复的差距

| # | 差距 | 严重度 | 修复方式 | 状态 |
|---|------|--------|---------|------|
| G1 | Binance 原生事件类型 → canonical event_type 映射表缺失 | HIGH | EVENT-TYPE-MAPPING.md §3（v3.17.0 四问判据驱动） | ✅ 已修复 |
| G2 | 14 种未覆盖行情事件的归类决策缺失 | HIGH | EVENT-TYPE-MAPPING.md §3 + §3.1 误映射后果登记 | ✅ 已修复 |
| G3 | 用户数据流排除决策缺少 ADR | MED | 新建 ADR-009 | ✅ 已修复 |
| G4 | 序号连续性校验策略缺少系统化设计文档 | HIGH | 新建 SEQUENCE-CONTINUITY-STRATEGY.md | ✅ 已修复 |
| G5 | 历史数据同步策略缺少设计文档 | HIGH | 新建 HISTORICAL-DATA-SYNC-STRATEGY.md | ✅ 已修复 |
| G6 | CM Perp → UM 架构迁移未记录 | MED | 新建 ADR-010 R-P1 | ✅ 已修复 |
| G7 | Options 系统重构期风险未记录 | MED | 新建 ADR-010 R-P2 | ✅ 已修复 |
| G8 | 幂等键维度完整映射表未沉淀 | MED | EVENT-TYPE-MAPPING.md §5 | ✅ 已修复 |
| G9 | SPEC §3 scope 描述过于简略 | LOW | SPEC §3 补充指向 ADR-009 | ✅ 已修复 |
| G10 | depthUpdate U/u 重建算法未沉淀 | MED | SEQUENCE-CONTINUITY-STRATEGY.md §4 | ✅ 已修复 |
| G11 | 订单成交累计量交叉校验方案未沉淀 | MED | SEQUENCE-CONTINUITY-STRATEGY.md §5 | ✅ 已修复 |
| G12 | DESIGN.md §5 ADR 表缺少新增条目 | LOW | 更新 DESIGN.md §5 | ✅ 已修复 |
| G13 | DESIGN.md §6 Risks 表缺少平台变更风险 | LOW | 更新 DESIGN.md §6 | ✅ 已修复 |
| G14 | SPEC §22 changelog 缺少条目 | LOW | 更新 SPEC §22（v3.16.0 + v3.17.0） | ✅ 已修复 |
| G15 | README.md design 文档列表未更新 | LOW | 更新 README.md Read Next | ✅ 已修复 |
| G16 | TRACEABILITY.md Source-SPEC 版本未回刷 | LOW | 回刷至 v3.17.0 | ✅ 已修复 |
| G17 | registry.yaml spec_version 未回刷 | LOW | 回刷至 v3.17.0 | ✅ 已修复 |
| G18 | docs/architecture/05-foundation.md 版本未回刷 | LOW | 回刷至 v3.17.0 | ✅ 已修复 |
| **G19** | **14 事件"排除"是一刀切偷懒，未建立语义分类判据** | **HIGH** | **v3.17.0 引入四问判据（Q1 ID/Q2 快照/Q3 传输层/Q4 非权威）+ 5 个 planned canonical 类型 + 误映射后果登记** | **✅ 已修复** |

---

## 五、修复计划

### 5.1 已完成的新增设计文档

| 文档                                       | 覆盖差距     | 覆盖产品线                                                 |
| ------------------------------------------ | ------------ | ---------------------------------------------------------- |
| `design/EVENT-TYPE-MAPPING.md`             | G1, G2, G8   | spot ✓ / um_perp ✓ / cm_perp ✓ / options ✓                 |
| `design/SEQUENCE-CONTINUITY-STRATEGY.md`   | G4, G10, G11 | 行情流全量 + 用户流（未来参考）                            |
| `design/HISTORICAL-DATA-SYNC-STRATEGY.md`  | G5           | spot（CSV时间戳） / um_perp / cm_perp / options（5天窗口） |
| `design/ADR-009-user-data-stream-scope.md` | G3           | 19 种事件 × 4 产品线排除决策                               |
| `design/ADR-010-platform-change-risks.md`  | G6, G7       | spot（时间戳） / cm_perp（→UM迁移） / options（重构期）    |

### 5.2 待完成的文档更新

| 文档                                    | 更新内容                     | 覆盖差距 |
| --------------------------------------- | ---------------------------- | -------- |
| `design/DESIGN.md` §5                   | 新增 ADR-009/010 条目        | G12      |
| `design/DESIGN.md` §6                   | 新增平台变更风险             | G13      |
| `spec/SPEC.md` §22                      | 新增 v3.16.0 changelog       | G14      |
| `module/binance/README.md`              | 更新 design 文档列表         | G15      |
| `module/binance/matrix/TRACEABILITY.md` | Source-SPEC 版本回刷 v3.16.0 | G16      |
| `module/registry.yaml`                  | spec_version 回刷 v3.16.0    | G17      |
| `docs/architecture/05-foundation.md`    | 版本回刷 v3.16.0             | G18      |

### 5.3 不修改的内容

- **不新增 FR**：这些差距是设计文档层面的知识沉淀，不改变功能面（55 FR Done 不变）
- **不修改 runtime 代码**：本仓库是文档枢纽，runtime 代码在 `/home/workspace/binance`
- **不修改 SPEC §7 FR 表**：保持 55 FR 不变
- **SPEC.md 保持 < 300 行**：详细内容放 design/ 文档

---

## 六、认识论声明

- `[KNOWN]`：来自 `module/binance/` 现有文档和 `report/binance/20260704.md` 的直接引用
- `[COMPUTED]`：通过 `rg` 搜索、交叉验证和逐产品线矩阵拆解得出
- `[INFERRED]`：基于报告内容与现有文档的差距推断
- 置信度：`HIGH`（核心差距结论和逐线覆盖分析）/ `MED`（平台变更风险的时效性和 CM "?" 项）

---

## 七、证据索引

| 证据                             | 来源                                                            | 标签         |
| -------------------------------- | --------------------------------------------------------------- | ------------ |
| 报告原文                         | `report/binance/20260704.md`                                    | `[KNOWN]`    |
| SPEC v3.16.0                     | `module/binance/spec/SPEC.md`                                   | `[KNOWN]`    |
| client SPEC FR-005               | `module/binance/spec/client/SPEC.md:147-163`                    | `[KNOWN]`    |
| ADR-003                          | `module/binance/design/ADR-003-order-book-rebuild-exclusion.md` | `[KNOWN]`    |
| EVENT-TYPE-MAPPING.md            | `module/binance/design/EVENT-TYPE-MAPPING.md`                   | `[KNOWN]`    |
| SEQUENCE-CONTINUITY-STRATEGY.md  | `module/binance/design/SEQUENCE-CONTINUITY-STRATEGY.md`         | `[KNOWN]`    |
| HISTORICAL-DATA-SYNC-STRATEGY.md | `module/binance/design/HISTORICAL-DATA-SYNC-STRATEGY.md`        | `[KNOWN]`    |
| ADR-009                          | `module/binance/design/ADR-009-user-data-stream-scope.md`       | `[KNOWN]`    |
| ADR-010                          | `module/binance/design/ADR-010-platform-change-risks.md`        | `[KNOWN]`    |
| DATA-INTEGRITY 报告              | `report/binance/DATA-INTEGRITY-DEEP-ANALYSIS-20260706.md`       | `[KNOWN]`    |
| 逐产品线矩阵拆解                 | 基于报告 §一覆盖矩阵按列拆分                                    | `[COMPUTED]` |

---

`[RULES I BROKE]`：无。本报告所有声明均标注证据标签与置信度，未编造引用，未在无新证据下让步。
