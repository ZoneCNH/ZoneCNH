## 三引擎详细规格

### 1. market_engine → S State

**输入源**：`domain-market`（经 `MarketEventEnvelope` 质量门禁）

| 数据类型   | 字段                       | 说明      |
| ---------- | -------------------------- | --------- |
| Bar        | Open/High/Low/Close/Volume | K线 OHLCV |
| Tick       | Price/Qty/Side             | 逐笔成交  |
| OrderBook  | Bids[]/Asks[]              | 盘口深度  |

**质量门禁规则**（`ValidateBarQuality`）：

1. High < Low → `ErrHighBelowLow`
2. Close ≤ 0 → `ErrZeroPrice` / `ErrNegativePrice`
3. OpenTime 为零 → `ErrMissingEventTime`
4. 延迟 > 5s → `ErrStaleEvent`

**五维评分体系**：

| 维度                 | 权重   | 数据来源               |
| -------------------- | ------ | ---------------------- |
| Trend（趋势）        | 30%    | 价格动量、均线结构     |
| Leverage（杠杆）     | 25%    | OI 变化、资金费率      |
| Heat（过热）         | 20%    | 成交量偏离、情绪指标   |
| Deleverage（去杠杆） | 15%    | 爆仓量、清算级联       |
| Volatility（波动率） | 10%    | 实现波动率、隐含波动率 |

**S 状态枚举**：

| 状态   | 语义     | 主导特征                           |
| ------ | -------- | ---------------------------------- |
| S1     | 多头趋势 | 价格+OI 同向上行，流动性健康       |
| S2     | 挤空尾声 | 急涨，Funding/Basis 偏热，清算上升 |
| S3     | 空头趋势 | 价格+OI 同向走弱                   |
| S4     | 踩踏尾声 | 急跌后高波动，清算级联             |
| S5     | 箱体震荡 | 方向不清，均值回复增强             |
| S6     | 低波横盘 | 波动压缩，成交收缩                 |
| S7     | 压缩蓄势 | 波动+深度压缩，突破压力累积        |

**输出字段**：`RegimeSnapshot`

| 字段               | 类型                                                     | 说明             |
| ------------------ | -------------------------------------------------------- | ---------------- |
| `snapshot_id`      | UUID v4                                                  | 快照唯一 ID      |
| `symbol`           | string                                                   | 标准化 symbol    |
| `regime_state`     | S1-S7 / UNKNOWN / DISLOCATED                             | 市场状态         |
| `bias`             | LONG / SHORT / NEUTRAL                                   | 方向偏向         |
| `trade_permission` | ALLOW_NORMAL / ALLOW_REDUCED / REDUCE_ONLY / FORBID_OPEN | 交易许可         |
| `confidence`       | decimal [0,1]                                            | 置信度（DI-001） |
| `five_dim_scores`  | FiveDimScores                                            | 五维评分向量     |
| `freshness_state`  | healthy / degraded / stale / recovering                  | 数据新鲜度       |
| `risk_tags`        | []string                                                 | 活跃风险标签     |
| `event_time`       | int64 (UTC ms)                                           | 数据事件时间     |
| `observed_at`      | int64 (UTC ms)                                           | 系统处理时间     |
| `pit_vintage`      | string                                                   | PIT 快照版本标签 |

**PIT 时间约束**：`event_time ≤ observed_at`（违反则拒绝快照）

---

### 2. macro_engine → M State

**输入源**：`domain-macro`（经 PIT 防泄露过滤）

| 数据类型   | 字段                                  | 说明           |
| ---------- | ------------------------------------- | -------------- |
| MacroPoint | SeriesCode / Value                    | 宏观指标值     |
|            | ObservedAt / ReleasedAt / AvailableAt | PIT 三时间字段 |
|            | RevisionVersion / IsPreliminary       | 修正版本       |

**防泄露过滤**（`FilterMacroPointsForBacktest`）：

- `AvailableAt` 为零 → `ErrMissingAvailableAt`
- `ObservedAt > DecisionTime` → 排除（未来观测值）
- `ReleasedAt > DecisionTime` → 排除（未发布数据）
- `AvailableAt > DecisionTime` → 排除（不可用数据）

**LGIP 四因子框架**：

| 因子   | 代码   | 计算指标                 | 数据源           |
| ------ | ------ | ------------------------ | ---------------- |
| 流动性 | L      | M2、央行资产负债表、SOFR | FRED、各国央行   |
| 增长   | G      | GDP、PMI、就业           | BEA、FRED        |
| 通胀   | I      | CPI、PCE、PPI            | FRED、各国统计局 |
| 压力   | P      | VIX、信用利差、DXY       | Yahoo、FRED      |

**M 状态枚举**：

| 状态   | 名称     | LGIP 判别   | 含义                             |
| ------ | -------- | ----------- | -------------------------------- |
| M1     | 流动牛市 | L↑ G↑ I↓    | 流动性宽松 + 增长上行 + 通胀温和 |
| M2     | 再通复苏 | L↓ G↑ I↓    | 流动性收紧 + 增长恢复 + 通胀回落 |
| M3     | 软着繁荣 | L→ G↑ I→    | 流动性中性 + 增长强劲 + 通胀稳定 |
| M4     | 鹰派通胀 | L↓ G↓ I↑    | 流动性收紧 + 增长放缓 + 通胀上行 |
| M5     | 衰退降息 | L↑ G↓ I↓    | 流动性宽松 + 增长下行 + 通胀回落 |
| M6     | 信用去杠 | L↓↓ G↓ P↑↑  | 流动性枯竭 + 增长暴跌 + 压力飙升 |
| M7     | 滞胀冲击 | L→ G↓ I↑    | 流动性中性 + 增长停滞 + 通胀高企 |
| M0     | 数据不足 | —           | fallback，不参与 M×S 决策        |

**输出字段**：`RegimeCard`

| 字段             | 类型               | 说明                    |
| ---------------- | ------------------ | ----------------------- |
| `m_state`        | M1-M7 / M0_UNKNOWN | 宏观状态                |
| `lgip`           | LGIPScore          | 四因子得分              |
| `confidence`     | float64 [0,1]      | 分类置信度              |
| `timestamp`      | time.Time          | 计算时间                |
| `data_freshness` | time.Time          | 数据新鲜度              |
| `input_source`   | string             | macro-data-py 数据产品来源 |

**黄金案例校验**：

| 历史事件        | 预期 M-State  | 验证要素              |
| --------------- | ------------- | --------------------- |
| COVID 暴跌 2020 | M6 → M5       | 流动性枯竭 → 紧急降息 |
| 加息周期 2022   | M4            | 鹰派通胀              |
| 复苏 2023       | M2 → M3       | 再通复苏 → 软着繁荣   |

---

### 3. regime_engine → DecisionCard

**输入**：M State（`RegimeCard`）+ S State（`RegimeSnapshot`）

**M×S 联合决策矩阵**：

| M \ S           | S1 多头   | S2 挤空   | S3 空头   | S4 踩踏   | S5 震荡   | S6 低波   | S7 压缩   |
| --------------- | --------- | --------- | --------- | --------- | --------- | --------- | --------- |
| **M1 流动牛市** | A agg     | A mod     | B mod     | C         | B mod     | B mod     | B mod     |
| **M2 再通复苏** | A mod     | B mod     | B con     | C         | B mod     | B mod     | B mod     |
| **M3 软着繁荣** | A mod     | B mod     | B con     | C         | B mod     | B con     | B con     |
| **M4 鹰派通胀** | B con     | C         | D con     | D         | C         | C         | C         |
| **M5 衰退降息** | B mod     | C         | D con     | D         | C         | C         | C         |
| **M6 信用去杠** | D         | D         | E         | E         | D         | D         | D         |
| **M7 滞胀冲击** | D         | D         | E         | E         | D         | D         | D         |

> `agg` = aggressive, `mod` = moderate, `con` = conservative

**Action 定义**：

| Action   | 含义     | 触发条件                        |
| -------- | -------- | ------------------------------- |
| **A**    | 积极进攻 | M bullish + S bullish           |
| **B**    | 保守进攻 | M/S 一方 bullish 另一方 neutral |
| **C**    | 观望等待 | M neutral 或 S 低置信度         |
| **D**    | 防御收缩 | M bearish + S bearish           |
| **E**    | 紧急避险 | M shock 或 S crisis             |

**Profile 定义**：

| Profile      | 风险偏好       | 典型杠杆范围  |
| ------------ | -------------- | ------------- |
| aggressive   | 高风险高收益   | 3-5x          |
| moderate     | 中等风险       | 1.5-3x        |
| conservative | 低风险         | 0.5-1.5x      |
| defensive    | 极低风险       | 0-0.5x        |
| flat         | 无风险（平仓） | 0x            |

**Risk Tier 定义**：

| Tier   | 风险水平   | risk_multiplier  |
| ------ | ---------- | ---------------- |
| 1      | 低风险     | 0.8-1.0          |
| 2      | 中低风险   | 0.6-0.8          |
| 3      | 中等风险   | 0.4-0.6          |
| 4      | 中高风险   | 0.2-0.4          |
| 5      | 高风险     | 0.0-0.2          |

**Template 定义**：

| Template        | 适用场景   | 策略特征             |
| --------------- | ---------- | -------------------- |
| trend_following | 强趋势市场 | 顺势持仓，宽止损     |
| range_trading   | 震荡市场   | 高抛低吸，窄止损     |
| breakout        | 关键位突破 | 突破追单，确认后加仓 |
| hedge           | 不确定市场 | 多空对冲，降低净暴露 |
| cash            | 危机市场   | 清仓观望，现金为王   |

**冲突门（Conflict Gate）**：

触发条件：M 和 S 方向相反 **且** 双方置信度均 > 0.6

| 调整项       | 调整幅度     | 原因                   |
| ------------ | ------------ | ---------------------- |
| position_cap | 降低 40%     | 方向冲突降低仓位确定性 |
| leverage_cap | 降低 50%     | 冲突环境下杠杆风险倍增 |
| risk_tier    | 提升一级     | 提高风险阈值保守度     |
| 冲突证据     | 写入决策日志 | 审计追踪               |

**输出字段**：`DecisionCard`

| 字段                             | 类型   | 值域                                              | 下游消费者                     |
| -------------------------------- | ------ | ------------------------------------------------- | ------------------------------ |
| `action`                         | enum   | A/B/C/D/E                                         | signal-factory（信号强度调制） |
| `profile`                        | enum   | aggressive/moderate/conservative/defensive/flat   | signal-factory（策略模板选择） |
| `risk_tier`                      | int    | 1-5                                               | risk-engine（风险阈值）        |
| `template`                       | enum   | trend_following/range_trading/breakout/hedge/cash | signal-factory（策略模板）     |
| `position_caps.max_leverage`     | float  | —                                                 | risk-engine（杠杆上限）        |
| `position_caps.max_position_pct` | float  | —                                                 | risk-engine（仓位上限）        |
| `risk_multiplier`                | float  | 0.3-1.0                                           | risk-engine（风险乘数）        |
| `conflict`                       | bool   | —                                                 | 审计/监控                      |
| `explain`                        | string | —                                                 | 人类可读决策解释               |

---

## 决策日志审计

每次 regime_engine 决策自动写入决策日志，结构：

```text
DecisionLog
├── log_id (UUID v4)
├── timestamp (RFC3339)
├── input_snapshot
│   ├── instrument (交易对)
│   ├── m_state (M State 快照)
│   └── s_state (S State 快照)
├── mapping_process
│   ├── steps[] (映射步骤 + 耗时)
│   ├── decision_logic (决策逻辑说明)
│   └── conflict_detection (冲突检测结果 + 调整记录)
├── output_result
│   ├── decision_card (DecisionCard 快照)
│   ├── explain_text (人类可读解释)
│   └── confidence_score (综合置信度)
└── metadata
    ├── engine_version
    ├── schema_version
    ├── execution_time_ms
    └── trace_id / span_id
```text

**存储策略**：热数据 7 天（高速存储）→ 温数据 30 天（标准存储）→ 冷数据归档（审计保留 365 天）

---
