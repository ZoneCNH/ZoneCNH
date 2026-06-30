# pe_data 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-30
- Layer: 数据域 · 另类数据
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/contracts`, `module/domain_market`

> `AlternativeDataProvider` 接口已由 `module/contracts` §8.1b 定义。pe_data 直接实现该接口，下游通过 `GetLatest(category, symbol)` 消费，不经过中间 hub 层。

---

## 1. 摘要

`module/pe_data` 是 PE 另类数据采集模块，直接实现 `contracts.AlternativeDataProvider` 接口。爬取 SEC EDGAR 13F / Form 4 / 机构持仓变化等公开数据源，归一化为 `AltDataPoint`，下游（signal_factory / backtestx）通过接口直接消费。

```text
SEC EDGAR / WhaleWisdom / OpenInsider
  ↓
module/pe_data → 实现 AlternativeDataProvider
  ↓
signal_factory / backtestx (直接消费)
```

---

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | PE 数据源爬取、13F/内部交易/机构持仓归一化逻辑、数据时效性管理（季度更新容错）、`AlternativeDataProvider` 接口实现 |
| Depends on | `module/contracts`（`AlternativeDataProvider` 接口 + `AltDataPoint` DTO）、`module/domain_market`（canonical InstrumentKey/ProductLine 类型） |
| Consumed by | `module/signal_factory`（PE 信号）、`module/backtestx`（回测验证）、`module/factor_eval`（PE 因子评估） |
| Excludes | PE 信号生成（→ signal_factory）、PE 策略（→ strategyx）、数据持久化（pe_data 只做采集+归一化，不存储历史）、支付/认证（→ 配置密钥管理） |

---

## 3. 数据源

| 数据源 | 数据类型 | 更新频率 | 免费/付费 |
| --- | --- | --- | --- |
| SEC EDGAR 13F | 机构季度持仓（>1亿美元管理资产） | 每季度（45天延迟） | 免费 |
| Form 4 | 内部人交易申报（买入/卖出/期权行权） | 交易后2天内 | 免费 |
| WhaleWisdom | 13F 聚合 + 基金跟踪 + 13D/G 激进持仓 | 每日更新 | 免费层可用 |
| OpenInsider | 内部人交易聚合 + 集群分析 | 每日更新 | 免费 |
| Preqin / PitchBook | PE/VC 基金表现、LP 配置、估值 | 每季度 | 付费 |

> **优先级**: 先用免费数据源验证 PE 信号有效性，信号确认后再接入付费源。adapter 接口不变。

---

## 4. 功能需求

### FR-001: 13F 数据采集

WHEN 新季度 13F 申报发布
THEN 爬取所有管理资产 >1亿美元的机构持仓
AND 解析字段：filing_date、cik、fund_name、symbol、cusip、shares_held、market_value、change_from_prev_qtr
AND 映射 `symbol` 到 canonical `InstrumentKey`（通过 domain_market）
AND 标记 `is_new_position`、`is_closed_position`、`pct_of_portfolio`

### FR-002: 内部人交易采集

WHEN Form 4 申报提交
THEN 采集内部人交易记录
AND 解析字段：filing_date、insider_name、insider_role、symbol、transaction_type（buy/sell/option_exercise）、shares、price、total_value
AND 标记 `is_cluster`（同一 symbol 多个内部人同方向交易）
AND 映射到 `InstrumentKey`

### FR-003: 机构持仓变化检测

WHEN 连续两个季度 13F 数据就绪
THEN 计算每只股票的机构持仓变化：
  - `institutional_flow` = Σ(shares_bought) - Σ(shares_sold)
  - `ownership_concentration` = Top10 机构持仓占比
  - `new_buyers_count` = 新增机构数
AND 输出 `PEvent{Type=13FChange, Symbol, QoQ_Flow, Concentration, NewBuyers}`

### FR-004: PE 事件归一化

WHEN 任一数据源产生新数据
THEN 归一化为 canonical `PEvent` 结构：
```
PEvent {
    Type        "13F" | "insider_trade" | "institutional_flow"
    InstrumentKey
    Timestamp
    Data        map[string]float64  // 量化后的特征值
    RawMetadata json.RawMessage     // 原始数据留底
    Quality     PEDataQuality       // 数据质量标签
}
```
AND `Quality` 包含 source、freshness、completeness 三维度

### FR-005: 数据时效性管理

WHEN 数据源超过预期更新周期未刷新
THEN 标记 `Quality.Freshness = STALE`
AND 下游消费时获取 STALE 标签，自行决定是否使用
WHEN 数据源恢复更新
THEN 自动恢复 `Freshness = CURRENT`

---

## 5. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 免费数据源爬取必须遵守 rate limit，不得触发 IP ban |
| BR-002 | PE 数据通过 `AlternativeDataProvider` 接口暴露，下游只通过接口消费，不直接依赖数据源实现 |
| BR-003 | 季频数据缺失时不得填零——标记为 NaN，由下游决定处理方式 |
| BR-004 | 内部人交易数据仅用公开申报，不得抓取非公开信息 |

---

## 6. 配置模式

```yaml
pe_data:
  sources:
    sec_13f:
      enabled: true
      update_interval: 24h
      rate_limit: 10/min    # SEC 限制
    sec_form4:
      enabled: true
      update_interval: 6h
    whalewisdom:
      enabled: false         # 免费 API key 待申请
    openinsider:
      enabled: true
  freshness:
    13f_stale_after: 100d   # 季度 + 45天延迟 + 缓冲
    form4_stale_after: 7d
  mapping:
    symbol_resolution: domain_market  # 通过 InstrumentKey 映射
```

---

## 7. 接口契约

> `AlternativeDataProvider` 接口由 `module/contracts` 定义。以下为 pe_data 的预期实现签名：

```go
// PEProvider 实现 contracts.AlternativeDataProvider
type PEProvider interface {
    // GetLatest13F 获取指定 symbol 的最新机构持仓
    GetLatest13F(ctx context.Context, symbol string) (*PEvent, error)
    // GetInsiderTrades 获取指定 symbol 的内部人交易历史
    GetInsiderTrades(ctx context.Context, symbol string, since time.Time) ([]PEvent, error)
    // GetInstitutionalFlow 获取机构资金流向
    GetInstitutionalFlow(ctx context.Context, symbol string, quarters int) ([]PEvent, error)
}
```

---

## 8. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始文档基线：13F/内部交易/机构持仓采集、PEvent 归一化、数据时效性管理 | ZoneCNH |
