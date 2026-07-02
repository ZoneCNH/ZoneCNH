# module/coinglass SPEC

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Owner: ZoneCNH
- Layer: 数据域 · 行情
- Module-Version: v1.0.0-spec
- Repository: [github.com/ZoneCNH/coinglass](https://github.com/ZoneCNH/coinglass)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [`module/binance`](../binance/), [`module/_template/cex-cs-module/README.md`](../_template/cex-cs-module/README.md), `module/domain_market`, `module/contracts`, `module/market_data`

> 子模块规格：`module/coinglass/client/SPEC.md`、`module/coinglass/server/SPEC.md`
>
> 本 SPEC 客制化 §1-§10 与 §15 / §19 中的 Coinglass 特异性内容（聚合数据源特征）；§11-§14 / §16-§18 / §20-§23 与 [`module/binance/SPEC.md`](../binance/SPEC.md) 范式保持一致，差异部分显式标注。

---

## 2. Summary

`module/coinglass` 是 Coinglass 衍生品聚合数据专属 C/S Module。Coinglass 不是交易所，而是**对外暴露多家交易所聚合后衍生品数据**的数据服务（funding rate / open interest / liquidation / long-short ratio）。

```text
Coinglass HTTP API (REST polling)
  ↓
module/coinglass/client       ← 聚合数据采集器（多窗口 polling）
  ↓ contracts-defined gRPC (MarketDataService)
module/coinglass/server       ← 摄入受理服务器
  ↓ downstream dispatch port
module/market_data
```

为什么本模块仍统一采用 C/S Module 范式（而非旧 SDK / Provider）：

- **下游不感知来源差异**：`module/market_data` 接收的 `MarketDataService.Ingest` 输入面对来源不敏感，无论是 binance Spot trade 还是 Coinglass funding rate，都是 canonical event
- **可靠性诉求一致**：聚合数据虽然延迟更高（分钟级），但 at-least-once + idempotent acceptance + ACK-driven checkpoint 同样需要
- **未来可扩展**：把 ZoneCNH 自营聚合算法加入时，只需新建 `module/{custom-aggregator}` C/S Module 而无需重构数据域

---

## 3. Problem

Coinglass 集成面临以下问题：

1. **聚合数据语义不清晰**：funding rate / OI / liquidation 各自有独立的时间窗口与 venue scope，旧 SDK 直接透传原始 response，下游消费者各自解读语义。
2. **Polling 重叠**：Coinglass API 是 REST polling（无 WebSocket push），polling 间隔 30s ~ 60s，相邻 poll 可能返回**部分重叠**的 funding rate window，需要显式 idempotency 处理。
3. **Venue 字段歧义**：Coinglass 的 `exchange` 字段是其 native 字符串（如 `Binance`、`OKX`、`Bybit`），与 ZoneCNH 内部 canonical exchange 名称（`binance`、`okx`、`bybit`）不同步。
4. **API rate limit 严格**：典型 30 req/min 的 quota，naive polling 多个 channel 会超限。
5. **product_line 语义不一致**：Coinglass 没有 Spot/Perp/Options 这种交易所产品线，事件本身**就是聚合产品**（funding 期、OI 截面）。canonical layer 需要新的 `product_line=derivatives_aggregate` 表达。

---

## 4. Goals

- 定义 Coinglass 专属 C/S 双端架构
- 支持 Coinglass 主要数据 channel：funding_rate / open_interest / liquidation / long_short_ratio
- 通过 contracts-defined `MarketDataService` 与交易所 C/S Module **共享同一 wire contract**
- 明确 polling 重叠窗口的 idempotency key 维度（含 `venue + symbol + window_start`）
- Venue 名称在 client 层规范化为 canonical `exchange` 值（`Binance` → `binance`），server 校验
- Rate limit 在 client 层显式调度，避免单 channel 浪费 quota
- 下游 `module/market_data` 对来源不敏感
- 移除旧 `coinglass` SDK active 引用

---

## 5. Non-goals

| 不做 | 原因 |
|------|------|
| 定义 canonical domain model | 由 `module/domain_market` 拥有（含 derivatives_aggregate 类型扩展） |
| 定义 proto/gRPC wire contract | 由 `module/contracts` 拥有 |
| 拥有 storage / query / strategy | 不属于数据域 |
| 自营衍生品聚合算法 | 应另立模块（`{custom-aggregator}`） |
| Coinglass dashboard 复刻 | 不属于本模块 |
| 历史数据回填 | 由 `module/market_data` 或 backfill 模块负责 |
| 旧 coinglass SDK 兼容 | 硬切移除 |

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `module/market_data` | 通过 server downstream dispatch port 接收 canonical events |
| `module/coinglass/client` | 通过 contracts gRPC 调用 server `MarketDataService.Ingest` |
| `module/coinglass/server` | 接收 client 流 |
| 下游 `module/factor_engine` | 通过 market_data 消费 derivatives_aggregate 事件作为因子输入 |

---

## 7. Functional Requirements

### FR-001: Channel Subscription Support

**WHEN** 配置启用 `funding_rate` channel
**THEN** client 按配置的 venue 列表 polling Coinglass `/api/futures/fundingRate` 系列端点

**WHEN** 配置启用 `open_interest` channel
**THEN** client polling `/api/futures/openInterest`

**WHEN** 配置启用 `liquidation` channel
**THEN** client polling `/api/futures/liquidation`

**WHEN** 配置启用 `long_short_ratio` channel
**THEN** client polling `/api/futures/longShortRatio`

### FR-002: Instrument & Venue Identity

**功能描述**：Coinglass canonical event 必须既标识 venue（哪家交易所）又标识 instrument（哪个合约）。

**WHEN** parser 处理 Coinglass response 中的 `exchange="Binance"` + `symbol="BTCUSDT"`
**THEN** canonical event 含 `source_metadata.coinglass_venue="binance"`（小写规范化）+ `instrument_key.exchange="binance"` + `instrument_key.product_line="usdm_perp"` + `instrument_key.contract_code="BTCUSDT"`

**WHEN** parser 遇到无法映射的 venue（如 Coinglass 新增交易所未在 canonical 列表）
**THEN** event_metadata 标注 `unmapped_venue=true`，server 返回 `unsupported_channel` reject

**身份碰撞**：
- Coinglass funding_rate@Binance@BTCUSDT vs Coinglass funding_rate@OKX@BTC-USDT-SWAP → 通过 `coinglass_venue` 区分
- Coinglass funding_rate@Binance@BTCUSDT vs binance C/S Module 直采的 funding event（如有）→ 通过 `source_metadata.aggregator=coinglass` vs `aggregator=null` 区分，但 InstrumentKey 相同（语义上是同一个合约的 funding rate，下游可选择 dedup 或并存策略）

### FR-003: gRPC Ingestion

> 与 [`module/binance/SPEC.md`](../binance/SPEC.md) §7 FR-003 范式一致。

### FR-004: At-Least-Once Delivery

> 与 binance §7 FR-004 范式一致。

### FR-005: Idempotent Acceptance

> 与 binance §7 FR-005 范式一致，但 idempotency key 维度因 polling 重叠而扩展（详见 §8 BR-010）。

### FR-006: Admin Surface

> 与 binance §7 FR-006 范式一致。新增端点：
> - `GET /admin/quota-status` 返回当前 Coinglass API quota 使用情况
> - `GET /admin/poll-schedule` 返回各 channel 的 polling 计划与上次成功时间

### FR-007: Boundary Enforcement

> 与 binance §7 FR-007 范式一致。

### FR-008: Polling Schedule（Coinglass 特异性）

**功能描述**：client 必须在 Coinglass API quota 内调度多 channel polling，避免限速。

**WHEN** 启用多个 channel 且总 quota 紧张
**THEN** client 按 channel 优先级与窗口语义分配 quota：
- funding_rate：每 8h 一次（按 venue 实际 funding 时点）
- open_interest：每 60s
- liquidation：每 30s（高频）
- long_short_ratio：每 5min

**WHEN** quota 即将耗尽
**THEN** 暂缓低优先级 channel，metric 上报，告警阈值触发

**WHEN** 收到 429 / quota_exceeded 响应
**THEN** 退避重试，重试间隔随 quota window 重置时间

---

## 8. Business Rules

### BR-001 ~ BR-009 与 binance 范式一致

> 详见 [`module/binance/SPEC.md`](../binance/SPEC.md) §8。

### BR-010: Idempotency Key Includes Window Start（Coinglass 特异性）

**规则**：聚合事件的 idempotency key 必须包含 `window_start` 字段，避免 polling 重叠时重复 dispatch。

**约束**：
- funding_rate event key：`coinglass + funding_rate + venue + symbol + funding_period_start`
- open_interest event key：`coinglass + open_interest + venue + symbol + snapshot_time（按分钟向下取整）`
- liquidation event key：`coinglass + liquidation + venue + symbol + liquidation_id`（API 已提供唯一 id）
- long_short_ratio event key：`coinglass + lsr + venue + symbol + interval + window_start`

**违反时**：相邻 poll 重叠窗口数据被重复 dispatch 给下游，导致因子统计偏差。CI gate `TestCoinglassIdempotencyKey` 失败。

### BR-011: Venue Name Normalization

**规则**：Coinglass 原生 venue 字符串必须在 client parser 阶段规范化为 canonical `exchange` 值。

**约束**：
- `Binance` / `BINANCE` → `binance`
- `Bybit` / `BYBIT` → `bybit`
- `OKX` / `Okx` → `okx`
- 未知 venue → event 标注 `unmapped_venue=true`，server reject

**违反时**：下游 InstrumentKey 与其他模块产生的同合约不一致，因子无法跨源 join。

---

## 9. Interface Contract

### MarketDataService（由 module/contracts §8.4 定义）

> 与 binance 一致。

### Coinglass-Specific Source Metadata Extension

| 字段 | 类型 | 必填 | 说明 |
|------|------|:---:|------|
| `aggregator` | string | ✅ | 固定 `coinglass` |
| `coinglass_venue` | string | ✅ | 规范化后的 canonical exchange（如 `binance`） |
| `coinglass_channel` | enum | ✅ | `funding_rate` / `open_interest` / `liquidation` / `long_short_ratio` |
| `window_start` | int64 | ✅ | 聚合窗口起始 UTC ms timestamp |
| `window_end` | int64 | ✅ | 聚合窗口结束 UTC ms timestamp |
| `interval` | string | LSR 必填 | LSR 的窗口长度（`5m` / `15m` / `1h` / `4h`） |

server 校验：缺失任一字段 → `terminal_validation` reject；`coinglass_venue` 非 canonical 列表 → `unsupported_channel` reject。

### Downstream Dispatch Port

> 与 binance 一致。`module/market_data` 接收的事件包含 `aggregator=coinglass` 标注，下游可基于此做去重或并存策略。

---

## 10. Data Model

### Canonical Event Concepts

> 与 binance §10 一致。增加：

| Concept | Purpose | Owned By |
|---------|---------|----------|
| `DerivativesAggregateEvent` | 聚合事件 wrapper，含 venue + window 维度 | domain_market（v1.1+ 扩展） |

### Coinglass Channel Schema

| Channel | event_type | Required Fields | Optional Fields |
|---------|-----------|-----------------|-----------------|
| funding_rate | `funding_rate` | venue, symbol, rate, period_start, period_end, mark_price | predicted_rate |
| open_interest | `open_interest` | venue, symbol, oi_value, oi_value_currency, snapshot_time | oi_value_change_24h |
| liquidation | `liquidation` | venue, symbol, liquidation_id, side, qty, price, ts | — |
| long_short_ratio | `long_short_ratio` | venue, symbol, interval, long_account_pct, short_account_pct, window_start, window_end | top_long_account_pct, top_short_account_pct |

### Polling Overlap State

```text
poll_window_t-1: [t-90s, t-30s]
poll_window_t  : [t-60s, t   ]
                 ^^^^^^^^^^ 30s 重叠
```

idempotency key 通过 `window_start` 区分两个 window（t-90s vs t-60s），即使 venue/symbol 相同也不会重复 dispatch。

### Reject Classification

> 与 contracts §8.4 RejectCode 10 码一致。

---

## 11. Config Schema

> 与 binance §11 范式一致。Coinglass 特异：

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `coinglass.endpoints.rest` | `string` | `https://open-api.coinglass.com` | Coinglass API base URL |
| `coinglass.api_key_env` | `string` | `COINGLASS_API_KEY` | API key 环境变量名 |
| `coinglass.channels` | `[]string` | `[]` | 启用的 channel：`funding_rate` / `open_interest` / `liquidation` / `long_short_ratio` |
| `coinglass.venues` | `[]string` | `[]` | 监控的交易所列表（canonical 值） |
| `coinglass.symbols` | `[]string` | `[]` | 监控的合约 symbol 列表 |
| `coinglass.poll_intervals.funding_rate` | `duration` | `8h` | funding rate polling 间隔 |
| `coinglass.poll_intervals.open_interest` | `duration` | `60s` | OI polling 间隔 |
| `coinglass.poll_intervals.liquidation` | `duration` | `30s` | liquidation polling 间隔 |
| `coinglass.poll_intervals.long_short_ratio` | `duration` | `5m` | LSR polling 间隔 |
| `coinglass.quota_per_minute` | `int` | `30` | API quota（用于调度） |

---

## 12. Error Handling

> 与 binance §12 范式一致。错误码前缀使用 `CGS-`：

| 错误码 | 触发条件 |
|-------|----------|
| `CGS-001` ~ `CGS-008` | 与 binance 同名错误对齐 |
| `CGS-101` | Coinglass venue 无法映射到 canonical exchange |
| `CGS-102` | API quota 耗尽且重试窗口未到 |
| `CGS-103` | Polling 响应 schema 与本模块预期不一致（Coinglass API 升级） |

---

## 13. Edge Cases

> 与 binance §13 范式一致。Coinglass 特有：

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| Polling 重叠 | 相邻 poll 返回部分重叠 funding window | idempotency key 通过 `window_start` 区分，不重复 dispatch |
| Coinglass API 升级 | response schema 增加新字段 | parser 容错（忽略未知字段），不阻断 |
| Coinglass API 降级 | response 缺少必填字段 | 返回 `CGS-103` 错误，告警，不规范化 |
| Quota 紧张 | 多 channel 共抢 quota | 按 §7 FR-008 优先级调度，低优先级 channel 暂缓 |
| Coinglass 新增 venue | response 出现未映射的 `exchange` 字段 | 标注 `unmapped_venue=true`，server reject，告警 |
| 同 venue/symbol 多 aggregator | 未来 ZoneCNH 自营聚合也产出 funding rate | 通过 `source_metadata.aggregator` 区分，下游决策是否并存 |

---

## 14. Directory Structure

> 文档目录与 binance 同名结构。Runtime 仓库 `github.com/ZoneCNH/coinglass/` 结构与 binance 一致，新增：

```text
internal/client/
  channels/              # 各 channel 的 parser
    funding_rate.go
    open_interest.go
    liquidation.go
    long_short_ratio.go
  scheduler/             # quota 感知的 polling 调度器
  venue_map/             # Coinglass venue 名称 → canonical exchange 映射表
```

---

## 15. Dependencies

> 允许依赖与 binance §15 一致。Coinglass 特异第三方：

| 依赖 | 用途 |
|------|------|
| `github.com/go-resty/resty/v2` 或同类 | HTTP client（无 WebSocket 需求） |

明确禁止：任何 WebSocket 客户端库（Coinglass 主要是 REST，不需要）。

---

## 16. Testing

> 与 binance §16 范式一致。Coinglass 特异 TC：
> - TC-019: polling 重叠窗口的 idempotency key 不冲突
> - TC-020: venue 名称规范化（`Binance` → `binance`）
> - TC-021: 未知 venue 返回 unsupported_channel reject
> - TC-022: API quota 耗尽时降级低优先级 channel

---

## 17. Performance Budget

> 与 binance §17 一致。Coinglass 特异：
> - Polling 完整周期 P99 < 5min（受 API rate limit 影响，无法做到 CEX 级实时）
> - 单 channel parsing P99 < 5ms

---

## 18. Observability

> 与 binance §18 范式一致。Metric 前缀使用 `coinglass_`，新增：

- `coinglass_client_quota_used_total`（counter）：累计 quota 消耗
- `coinglass_client_quota_remaining`（gauge）：当前剩余 quota
- `coinglass_client_unmapped_venue_total`（counter）：未映射 venue 触发次数（按 venue 标签）
- `coinglass_client_poll_lag_seconds`（histogram）：polling 实际间隔与配置间隔差

---

## 19. Security

> 与 binance §19 一致。Coinglass 特异：
> - `COINGLASS_API_KEY` 仅从环境变量读取
> - 禁止在 logs / admin / debug 暴露 API key
> - rate limit 严格：禁止在测试/开发环境直接打 production API（应使用 mock 或 sandbox）

---

## 20. CI Gate

> 与 binance §20 范式一致。Coinglass 特异 gate：

| Gate | 命令 | 通过条件 |
|------|------|----------|
| Idempotency key window | `go test -run TestCoinglassIdempotencyKey ./...` | 全部通过 |
| Venue mapping completeness | `go test -run TestVenueMap ./...` | 全部通过（覆盖已知 venue） |
| Quota scheduler | `go test -run TestQuotaScheduler ./...` | 全部通过 |

---

## 21. Upgrade Compatibility

> 与 binance §21 一致。Coinglass 特异：
> - venue map 增加新 venue：向后兼容
> - poll_intervals 调整：向后兼容
> - Coinglass API schema 变更：可能需要 minor bump，parser 容错策略保护过渡期

---

## 22. Release DoD

`module/coinglass` v1.0.0 发布完成标准：

- [ ] 旧 passive SDK references 已移除
- [ ] `module/coinglass/client` 和 `server` specs 完成
- [ ] root/client/server TRACEABILITY.md 完成
- [ ] 4 个 channel parser 实现并通过 schema 测试
- [ ] FR-002 venue normalization 通过 BR-011 验证
- [ ] FR-008 polling schedule 在 quota 内运行
- [ ] At-least-once + idempotent acceptance + window-overlap 兼容 testable
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过
- [ ] Performance Budget 达标
- [ ] Integration test 演示 4 channel 完整 polling → dispatch 链路

---

## 23. Open Questions

### Resolved

| ID | 问题 | 状态 |
|----|------|------|
| OQ-001 | contracts §8.4 wire 是否就绪？ | ✅ 已确认 |
| OQ-002 | market_data downstream port 是否就绪？ | ✅ 已确认 |
| OQ-003 | derivatives_aggregate 在 domain_market 的扩展位置？ | 待 domain_market v1.1 决议；过渡期通过 `source_metadata.aggregator` 标注 |

### Non-blocking

| ID | 问题 | 状态 |
|----|------|------|
| OQ-004 | 是否同时支持 Coinglass v3 / v4 API？ | v1.0 仅 v4，v3 兼容评估 |
| OQ-005 | LSR `top_*_pct` 是否纳入 v1.0 必填？ | 待评估 |

### Future

| ID | 问题 | 状态 |
|----|------|------|
| OQ-006 | 是否扩展到其他衍生品聚合数据源（CryptoQuant, Glassnode）？ | 待评估，需新模块或 generic aggregator 抽象 |
| OQ-007 | 是否需要 ZoneCNH 自营聚合替代 Coinglass？ | 待评估 |
