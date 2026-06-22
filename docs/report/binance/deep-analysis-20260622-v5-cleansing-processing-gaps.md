# Binance 模块深度分析报告 v5 — 数据清洗 / 数据处理 / 数据缺口

> 接 v4 历史/实时分析；本轮聚焦 **数据清洗、处理管线、缺口检测** 的 SPEC 覆盖度。
>
> 证据：`grep` 命中 5 处 `enrich/aggregate/derive`，全部在 `RUNTIME-MAPPING.md` / `DEEP-ANALYSIS.md`，**SPEC 主线 FR/AC/TC 一处都没有**。

- [COMPUTED, HIGH] 报告日期：2026-06-22
- [COMPUTED, HIGH] 分析范围：`module/binance/SPEC.md` v2.2.2 + `client/SPEC.md` v2.1.1 + `server/SPEC.md` v2.1.0 + `NAMING.md` v1.0.0 + `RUNTIME-MAPPING.md` v2.0.0 + `TRACEABILITY.md` v2.2.3 + `ACCEPTANCE.md` + `DEEP-ANALYSIS.md`
- [COMPUTED, HIGH] 上一轮：`docs/report/binance/deep-analysis-20260622-v4.md`（历史 vs 实时缺口）
- [COMPUTED, HIGH] 本轮新主题：数据清洗 / 数据处理 / 数据缺口

---

## 一、数据清洗（Data Cleansing）— SPEC 覆盖度

### 1.1 SPEC 实际定义的"清洗"等同物（评估：[COMPUTED, HIGH]）

| SPEC 位置 | 内容 | 性质 |
|---|---|---|
| `server/SPEC.md` FR-003 | 缺字段 / product_line 不支持 / event_type 未知 / event_time 零值或未来 → `terminal_validation` reject | **结构校验**，非清洗 |
| `server/SPEC.md` §10 RejectReason | `terminal_validation` / `terminal_conflict` / `quality_rejected` 等枚举 | `quality_rejected` 仅命名存在，**无 FR 触发条件** |
| `client/SPEC.md` FR-004 | normalize 保留 10 字段（含 raw_payload 与 compact_payload） | **格式归一**，非清洗 |
| `client/SPEC.md` FR-005 | mapper 转 `domain_market.MarketEvent` | **类型映射**，非清洗 |

### 1.2 数据清洗的完整定义（业界基线）

清洗 = 在事件进入持久化之前消除**异常 / 不一致 / 冗余 / 噪声**，包括：

| 清洗维度 | Binance SPEC 是否定义 |
|---|---|
| 字段缺失（null 必填项） | ✅ FR-003 |
| 字段类型错（string vs number） | ⚠️ 隐含在 JSON unmarshal，无显式规则 |
| 字段值域（price < 0、qty < 0、ts < 0） | ❌ **完全缺失** |
| 异常值（price 飞单 1000x） | ❌ **完全缺失** |
| 时钟漂移（local_time vs exchange_time 偏移 > N 秒） | ❌ **完全缺失** |
| 乱序事件（event_time 倒退） | ❌ **完全缺失** |
| 重复 trade（相同 trade_id 不同 event_time） | ⚠️ 部分被 SetNX 覆盖，但**幂等 ≠ 清洗**（SetNX 静默丢弃，无质量记账） |
| Depth 序号不连续（update_id gap） | ❌ **完全缺失** |
| Bar 不闭合（end_time - start_time ≠ interval） | ❌ **完全缺失** |
| Symbol 大小写 / 空格 / 全角字符 | ❌ **完全缺失** |
| Funding rate / Mark price 越界 | ❌ 整个 stream 缺失（v4 报告已覆盖） |
| 单 stream 重复订阅（同一 ticker 被两条 connector 抓） | ❌ **完全缺失** |

### 1.3 SPEC 对"清洗"的隐性误指

- `DEEP-ANALYSIS.md` 第 231 行画的 `enrich / aggregate / derive`，是 server processor 的**衍生计算**（补 VWAP / 累积 Volume），不是清洗
- `RUNTIME-MAPPING.md` 第 79 行的 `enricher.go`，仅占目录位，无 SPEC FR 约束
- 当前 SPEC 实际把"清洗"折叠成了"校验失败 → terminal_reject"**二元开关**，但脏数据 ≠ 校验失败：
  - 例如 price = 0.0000001（极小但合法）会过校验，但是"飞单残值"
  - 例如 trade_id 倒退（Binance 偶发）会过校验，但是"乱序"

### 1.4 清洗缺口的 8 条具体问题（评估：[INFERRED, HIGH]）

| # | 缺口 | 风险 |
|---|---|---|
| **C1** | 无 price/qty 数值域校验（业务上 price > 0, qty > 0） | 0 价/负量入库污染下游 VWAP |
| **C2** | 无 spike detector（与最近 N 笔均价偏离 > X%） | 飞单点燃止损链 |
| **C3** | 无 timestamp sanity（abs(local - exchange) > 30s 告警） | 时钟漂移期间生成错误的 latency metric |
| **C4** | 无乱序检测（event_time < watermark） | bar 闭合后又来旧 trade，破坏聚合 |
| **C5** | 无 depth update_id 连续性检查（U/u 字段连号） | depth book 损坏，下游 orderbook 重建失败 |
| **C6** | 无 bar 自洽检查（high ≥ max(open,close), low ≤ min(open,close), close ∈ [low,high]） | bar 数据自相矛盾，回测信号错 |
| **C7** | 无 symbol 归一化（`btcusdt` vs `BTCUSDT` vs `BTC/USDT`） | identity 碰撞，跨产品线统计错 |
| **C8** | 无质量计数（`quality_rejected` 枚举存在但无 FR 触发、无 metric） | 脏数据被静默吞掉，运维不知情 |

---

## 二、数据处理（Data Processing）— SPEC 覆盖度

### 2.1 SPEC 主线 vs 旁支（评估：[COMPUTED, HIGH]）

| 处理类型 | SPEC 主线 | 旁支文档 | 是否实施约束 |
|---|---|---|---|
| Validation（结构校验） | ✅ FR-003 + AC-004 | — | 实施约束清晰 |
| Idempotency（去重） | ✅ FR-005 + BR-002 | — | 实施约束清晰 |
| Enrichment（补衍生字段） | ❌ | `RUNTIME-MAPPING.md` 提了 enricher.go | **无 FR 约束** |
| Aggregation（累积 VWAP/Volume） | ❌ | `DEEP-ANALYSIS.md` 提了 | **无 FR 约束** |
| Derivation（推导 mark price 等） | ❌ | `DEEP-ANALYSIS.md` 提了 | **无 FR 约束** |
| 重采样（1m→5m bar） | ⚠️ FR-010 ETL 提了 `1m_ohlcv / 5m_vwap / 15m_stats` | — | 仅 3 种聚合，**未明确算法、未明确口径** |
| 跨产品线聚合（spot vs um_perp basis） | ❌ | — | **完全缺失** |

### 2.2 处理管线的 7 个具体问题（评估：[INFERRED, HIGH]）

| # | 缺口 | 风险 |
|---|---|---|
| **P1** | enricher.go / aggregator.go **无 FR 锚定** | 实现期由开发者随意补字段，下游消费者依赖什么字段全靠口口相传 |
| **P2** | 多周期 bar 推导（taosx 是否落 1m，5m/15m/1h 都靠 clickhousex 重采样？） | 实时 5m bar 延迟 > 5min（要等 ETL）；如直接订阅 5m WS 又会与重采样结果不一致 |
| **P3** | VWAP / TWAP 口径未定义（按 trade 加权？按 bar 加权？时间窗滚动还是固定？） | 跨模块语义分裂 |
| **P4** | Mark Price / Index Price 来源未明（um_perp 用 `markPriceUpdate` ws，还是从 trades 衍生？） | 决策域 risk_engine 拿到的 mark price 可能是错的 |
| **P5** | Cross-symbol basis（BTCUSDT spot - BTCUSDT um_perp）由谁算？binance 模块算还是 factor_engine 算？ | 重复实现 + 时延不一致 |
| **P6** | Bar 闭合规则（exchange-side 闭合 vs server-side 按 wall clock 闭合） | server 重启后聚合状态丢失 |
| **P7** | Watermark / late event policy（迟到事件是否回填 bar？过多迟到怎么标记？） | 实时 bar 看着稳定，回看历史时数据变了 |

---

## 三、数据缺口（Data Gap）— SPEC 覆盖度

### 3.1 SPEC 仅在 1 处隐式提及 gap（评估：[COMPUTED, HIGH]）

```
ACCEPTANCE.md AC-019: postgresx.UpdateIngestStatus 更新 last_seq 用于 gap fill
TRACEABILITY.md AC-020: 同上
client/TRACEABILITY.md AC-013: 规范化事件保留 sequence-id / update-id 共 10 字段
server/TRACEABILITY.md AC-015: postgresx.UpdateIngestStatus 更新 last_seq，用于 gap fill 检测
```

**问题**：
1. `last_seq` 写到 postgresx 了，**但没有 FR 定义"谁检测 gap"、"何时检测"、"检测到怎么办"**
2. `UpdateIngestStatus` 不在任何 FR 的 WHEN/THEN 里出现，是悬挂的 AC
3. 完整的 gap 处理链路（检测 → 报告 → 修复 → 验证）只有第 1 步的字段记账

### 3.2 数据缺口的 4 类（按检测窗口分类）

| 类别 | 描述 | SPEC 覆盖 |
|---|---|---|
| **G1 — Stream-internal**（流内） | 单条 stream 的 sequence/update_id 连号断点 | ❌ 仅记录 last_seq，无检测 |
| **G2 — Cross-stream**（流间） | trade 流有数据但 bar 流空缺（同一 symbol 同一分钟） | ❌ 完全缺失 |
| **G3 — Cross-product-line**（产品线间） | spot BTCUSDT 全天有数据，um_perp BTCUSDT 全天空（订阅遗漏） | ❌ 完全缺失 |
| **G4 — Cross-source**（数据源间） | WS 实时数据 vs REST 历史回填的偏差 | ❌ 完全缺失 |

### 3.3 缺口检测维度的具体问题（评估：[INFERRED, HIGH]）

| # | 缺口 | 风险 |
|---|---|---|
| **G-Q1** | 无 gap 检测 FR（v4 已建议 FR-017，本节确认必须） | 数据缺失永远不会被发现，回测拿到"看似完整"的脏数据集 |
| **G-Q2** | last_seq 写了但无消费者 | AC-019/AC-020 是死代码 |
| **G-Q3** | 无"期望条数"基线（每分钟 BTCUSDT 应有多少 trade？深度更新？） | 即使建检测，无基线 = 无判断 |
| **G-Q4** | 无 gap 报告 API（运维不知道当前有多少缺口） | 不可观测 |
| **G-Q5** | 无 SLA 定义（gap 多大触发告警？1 分钟？1 秒？） | 告警洪水或漏报 |
| **G-Q6** | 无 historical recovery 路径（gap 检测到了，但 REST 历史接口未在 SPEC 内授权） | 检测 = 干瞪眼 |

---

## 四、是否遗漏？— 综合判定

> 判定方式：把 SPEC 的覆盖范围画在一张矩阵上，与"完整 Market Data Pipeline"标准动作做差。

### 4.1 Market Data Pipeline 标准阶段 vs SPEC 覆盖

| 阶段 | 标准动作 | SPEC 覆盖 | 评估 |
|---|---|:---:|---|
| 1. Discovery | 发现 symbol / instrument | ❌ | v4 FR-012 已建议 |
| 2. Subscription | 决定订什么、订多少档 | ⚠️ | v4 FR-013/014/015 已建议 |
| 3. Ingestion | WS + REST 接入 | ✅ | 已覆盖 |
| 4. Normalization | 格式归一 | ✅ | FR-004 |
| 5. Validation | 结构校验 | ✅ | FR-003 |
| 6. **Cleansing** | **值域 / 异常值 / 时钟 / 乱序** | ❌ | **本报告 C1-C8 新增 8 个缺口** |
| 7. Idempotency | 去重 | ✅ | FR-005 |
| 8. **Processing** | **enrich / aggregate / derive** | ⚠️ | **本报告 P1-P7 仅 RUNTIME-MAPPING 提及，无 FR** |
| 9. Persistence | taosx + ossx + clickhousex | ✅ | FR-006a~d, FR-010 |
| 10. Fanout | kafkax | ✅ | FR-008 |
| 11. Serving | Gin REST | ✅ | FR-007 |
| 12. **Gap Detection** | **Stream/Cross-stream/Cross-line/Cross-source** | ❌ | **本报告 G-Q1~Q6 新增 6 个缺口** |
| 13. **Backfill** | **冷启动 / Gap 填补 / 节流** | ❌ | v4 FR-016/017/018/019 已建议 |
| 14. **Reconciliation** | **每日全量对账** | ❌ | v4 FR-021 已建议 |

### 4.2 遗漏总览（本轮新增 + v4 累计）

| 来源 | 已识别缺口 |
|---|---|
| v4 报告（实时 + 历史） | 15 条（R1-R6 实时 + H1-H9 历史） |
| v4 建议 FR | 13 条（FR-012 ~ FR-024） |
| **本轮新增 — 清洗** | **8 条（C1-C8）** |
| **本轮新增 — 处理** | **7 条（P1-P7）** |
| **本轮新增 — 缺口** | **6 条（G-Q1-Q6）** |
| 累计未明确问题 | **36 条** |
| 累计建议新增 FR | **≥18 条**（v4 的 13 + 本轮再追 5 条） |

---

## 五、本轮追加建议 FR（增量，不重复 v4）

| 建议 FR | 内容 | 落点 |
|---|---|---|
| **FR-025 Quality Validation** | 显式定义 8 类清洗规则（C1-C8），违反进 `quality_rejected` 路径；带 metric `binance_server_quality_rejected_total{reason=...}` | server SPEC §7 + §12 |
| **FR-026 Watermark & Late Event Policy** | 定义 watermark（per-symbol 最大 event_time），late event 阈值 30s；超阈值的事件入 `binance_late_events` 表，不进 bar 聚合 | server SPEC §7 |
| **FR-027 Processing Pipeline Contract** | 明确 enrich 字段清单（vwap_1m / volume_24h / mark_basis 等）、聚合算法、推导规则；下游基于此契约消费 | server SPEC §9 |
| **FR-028 Gap Detection Multi-Dimensional** | G1/G2/G3/G4 四类 gap 的检测规则；每类对应一个 detector goroutine；输出 `binance_data_gaps` 表 | server SPEC §7 |
| **FR-029 Data Coverage SLA** | 定义 per (product_line, symbol, event_type) 的覆盖率 SLA（5min 窗口内缺失率 < 0.1%）；超 SLA 触发告警 | server SPEC §7 + §18 |

---

## 六、对治理体系的影响（增量）

| 影响项 | v4 估算 | 本轮叠加 | 累计 |
|---|---|---|---|
| 新增 FR | 13 | +5 | 18 |
| 新增 AC | ~30 | +15 | ~45 |
| 新增 TC | ~20 | +12 | ~32 |
| 新增 BR | 2 | +2（Watermark 单调、清洗优先级） | 4 |
| 新增 postgresx 表 | 2 | +3（`binance_late_events`、`binance_data_gaps`、`binance_quality_log`） | 5 |
| 新增 metrics | — | +8（quality_rejected、watermark_lag、gap_count、coverage_ratio 等） | 8+ |

---

## 七、结论

> 评估：[INFERRED, HIGH]

1. **数据清洗** — 完全遗漏。SPEC 把校验当成清洗，但二者粒度差一个数量级；**8 条具体清洗规则未在任何 FR 中定义**
2. **数据处理** — 概念存在（enricher.go / aggregator.go），**但没有 FR 锚定**，等同于"未定义"
3. **数据缺口** — 仅有 `last_seq` 字段记账，**无检测、无修复、无报告**；4 类 gap 全部未覆盖

整体判断：当前 SPEC 是"事件转发管道"规格，不是"行情数据平台"规格。要支撑量化决策（回测 + 实盘信号），**必须先补 FR-025 ~ FR-029 五条清洗/处理/缺口规则**，否则下游因子工程拿到的不是行情数据，是 raw stream。

---

## 八、停止条件

- [COMPUTED, HIGH] 本轮未修改任何 `module/binance/` 治理文件，仅新增本报告
- [INFERRED, HIGH] 建议下一步：合并 v4 + v5 的 18 条建议 FR，统一在 `module/binance/DATA-LIFECYCLE.md` 讨论稿（一次性提案 vs 分阶段提案，由用户决策）
- [INFERRED, MED] 若同意提案，再决定是否触发 SPEC.md MAJOR bump（event_type 枚举变更 + 18 条新 FR 影响面）

[RULES I BROKE]：无 — 本次只读分析 + 新建报告文件，未触及受保护治理文件