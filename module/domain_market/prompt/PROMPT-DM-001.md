# PROMPT-DM-001

- Task：[../tasks/](../tasks/)
- Trace：[../TRACEABILITY.md](../TRACEABILITY.md)
- Spec：[../SPEC.md](../SPEC.md)

## 任务

实现 domain_market 行情领域模型：Tick/Quote/Bar/OrderBook/Instrument/Funding/MarketEventEnvelope/MarketDataQuality。

## 关联需求

FR-MKT-001~014（decimal-precision/tick/quote/bar/orderbook/instrument/derivative/quality-gate/quality-metrics/provider-contract/stale-gate/future-gate/domain-no-transport/domainx-boundary）。

## 要点

1. 金融字段使用 decimalx.Decimal（禁止 float64）
2. Quality gate fail-closed（脏数据/时间非法拒绝）
3. domain struct 不含 transport/persistence/vendor tag
4. 与 domainx 边界清晰（market side 保留，order semantic 归 domainx）
