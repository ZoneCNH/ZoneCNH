# module/binance GOAL

## 元数据

| 字段 | 值 |
| --- | --- |
| 模块 | `binance` |
| 层级 | 数据域 · 行情（C/S Module 参考实现） |
| 仓库 | <https://github.com/ZoneCNH/binance> |
| 当前版本 | v0.15.1（last published tag；本轮 audit branch 未创建新 tag） |
| Spec 版本 | v4.1.0 |
| 状态 | [COMPUTED, HIGH] 历史已发布版本的成熟度投影为 L3；当前 RC 为 13 Done / 52 Partial / 0 Drifted / 0 Pending，`release_closeable_spec=NO`且 `release_closeable_runtime=NO` |

## Purpose

`module/binance` defines the Binance-specific market_data ingest module for ZoneCNH.

It replaces the previous ambiguous SDK/Provider split with a single explicit C/S architecture:

```text
module/binance/client
module/binance/server
```

## Primary Goal

Provide a reliable, canonical, Binance-specific market_data ingestion path for:

- Spot
- USDⓈ-M Futures
- COIN-M Futures
- Options

## Non-Goals

`module/binance` does not own:

- generic market_data domain semantics
- cross-exchange market_data ingestion policy
- generic cross-exchange market_data storage/query ownership
- strategy APIs
- trading decisions
- order execution
- portfolio accounting
- risk management
- legacy Provider compatibility

## Success Criteria

`module/binance` is successful when:

1. Binance market data can be collected by `module/binance/client`.
2. Canonical market events can be durably published through `natsx` JetStream using `domain_market` envelopes.
3. `module/binance/server` can validate, deduplicate, persist, expose, and fan out accepted Binance events.
4. Spot `BTCUSDT`, USDⓈ-M `BTCUSDT`, COIN-M `BTCUSD`, and Options contracts produce non-colliding canonical instrument identities.
5. Client publish success is confirmed by JetStream PubAck, and server consumption advances only after durable ManualAck.
6. Archived legacy Provider names remain confined to SPEC Appendix B, BR gates, migrations, and reports.
7. Client/server internals remain separated by boundary gates.
