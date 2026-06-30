# module/coinglass/client SPEC

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Owner: ZoneCNH
- Layer: 数据域 · Coinglass 聚合数据接入
- Module-Version: v0.1.0-spec
- Repository: [github.com/ZoneCNH/coinglass](https://github.com/ZoneCNH/coinglass)（client/ 子目录）
- Pattern: 继承 [`module/binance/client/SPEC.md`](../../binance/client/SPEC.md) 范式

---

## 1. Summary

`module/coinglass/client` 是 Coinglass 衍生品聚合数据采集器。它通过 REST polling 采集 funding_rate / open_interest / liquidation / long_short_ratio 4 个 channel，按聚合窗口规范化为 ZoneCNH canonical events，spool + checkpoint，通过 contracts gRPC 发送到 `module/coinglass/server`。

## 2. Inherited Behavior

以下内容**完全继承** [`module/binance/client/SPEC.md`](../../binance/client/SPEC.md) 范式：

- §3 通用 Problem / §5 Non-goals / §6 Consumers
- §7 FR-004 Normalization / FR-005 Mapping / FR-007 Spool / FR-008 Checkpoint / FR-009 gRPC Sender / FR-010 Admin
- §8 通用 BR-001 ~ BR-005
- §9-10 通用 interface（Mapper / Sender / IdempotencyKeyer 签名一致；Connector 在本模块改为 Channel 概念，详见 §3.3）
- §11-21 通用 config / error / edge / directory / dependencies / testing / performance / observability / security / upgrade

## 3. Coinglass-Specific Customization

### 3.1 Channel Catalog（覆盖 binance §7 FR-001 Product Line Catalog）

Coinglass 的概念是 **channel + venue + symbol** 三维订阅，而非交易所产品线。client 的 catalog 表达：

| channel | poll 间隔默认 | 必填字段（来自 Coinglass response） |
|---------|---------------|-----------------------------------|
| `funding_rate` | 8h（按 funding 时点对齐） | venue, symbol, rate, period_start, period_end, mark_price |
| `open_interest` | 60s | venue, symbol, oi_value, oi_value_currency, snapshot_time |
| `liquidation` | 30s | venue, symbol, liquidation_id, side, qty, price, ts |
| `long_short_ratio` | 5m（按 interval：5m / 15m / 1h / 4h） | venue, symbol, interval, long/short pct, window_start, window_end |

每个 channel × venue × symbol 组合是一个独立 polling task。

### 3.2 Venue Mapping（Coinglass 特异 BR-011）

Coinglass response 中 `exchange` 字段是 native string，client parser 必须规范化：

```
internal/client/venue_map/venue_map.go：
  "Binance" / "BINANCE" → "binance"
  "OKX" / "Okx" / "okx" → "okx"
  "Bybit" / "BYBIT" → "bybit"
  "Bitget" / "BITGET" → "bitget"
  ... （13 项已知 venue）
  unknown → unmapped_venue=true（标注后让 server reject）
```

新增 venue 时更新 venue_map，并补充测试。

### 3.3 Channel "Connector" Implementation

替代 binance §7 FR-003 Connector 模型，Coinglass 是 polling-based：

```
type Channel interface {
    Name() string                // funding_rate / open_interest / ...
    Poll(ctx) ([]RawEvent, error) // 单次 poll，返回多事件
    Schema() ChannelSchema       // 必填字段定义
}
```

Channel 实现位于 `internal/client/channels/`。

### 3.4 Quota-Aware Scheduler（Coinglass 特异 FR-008）

`internal/client/scheduler/`：

```
- 维护 quota window（默认每分钟 30 req）
- 按 channel 优先级分配 token：
    liquidation > open_interest > long_short_ratio > funding_rate
- quota 紧张时降低低优先级 channel 频率
- 监听 429 / quota_exceeded 响应，退避到 quota window 重置
```

### 3.5 Idempotency Key Strategy（覆盖 binance §7 FR-006）

按 channel 不同：

| channel | key 维度 |
|---------|---------|
| funding_rate | `coinglass + funding_rate + venue + symbol + period_start` |
| open_interest | `coinglass + open_interest + venue + symbol + snapshot_time(min-aligned)` |
| liquidation | `coinglass + liquidation + venue + symbol + liquidation_id`（API 已唯一） |
| long_short_ratio | `coinglass + lsr + venue + symbol + interval + window_start` |

**关键**：`window_start` 维度保证相邻 poll 重叠窗口不重复 dispatch。

### 3.6 Source Metadata Extension

每条 canonical event 必须填充：

| 字段 | 必填 |
|------|:---:|
| `aggregator` | ✅（固定 `coinglass`） |
| `coinglass_venue` | ✅（规范化后值） |
| `coinglass_channel` | ✅ |
| `window_start` | ✅ |
| `window_end` | ✅ |
| `interval` | LSR 必填 |

### 3.7 Error Codes

错误码使用 `CGS-` 前缀，详见父规格 §12。

## 4. Test Matrix Delta

新增（编号续接 binance client TC-018）：

| TC 编号 | 场景 | 预期 |
|---------|------|------|
| TC-019 | 相邻 poll 重叠窗口的 funding_rate 事件 | idempotency key 通过 period_start 区分，不重复 dispatch |
| TC-020 | parser 输入 venue=`Binance` | 规范化为 `binance`，写入 source_metadata |
| TC-021 | 未知 venue（`SomeNewExchange`） | 标注 unmapped_venue=true，event 不发送（client 拒绝写入 spool） |
| TC-022 | 4 channel 同时启用，quota 仅 30/min | scheduler 按优先级降级 funding/LSR 频率 |
| TC-023 | Coinglass response 缺少必填字段 | 返回 CGS-103，事件不规范化 |

## 5. Release DoD Delta

继承 binance client §22，新增：

- [ ] 4 channel parser 全部实现并通过 schema 测试
- [ ] Venue map 覆盖 13 项已知 venue（CEX 列表 + Hyperliquid）
- [ ] Quota-aware scheduler 通过 TC-022
- [ ] Polling 重叠 idempotency 通过 TC-019
- [ ] COINGLASS_API_KEY 不出现在任何 artifact
