# ADR：五模块生产事实链 v1

- Status: Proposed
- Date: 2026-07-11
- Scope: contracts, domain_market, binance, market_data, market_regime
- Release Verdict: NO-GO until all P0 gates pass

## Context

当前链路存在三个相互冲突的提交边界：

1. binance client → NATS → binance server；
2. binance server 自行验收、持久化、查询和 fanout；
3. market_data 再次执行验收、幂等、排序和 TDengine/Kafka 双写。

这使系统无法定义唯一权威提交点，也无法证明重试不会造成永久丢数或假 ACK。

## Decision

### 产品形态

- contracts：稳定 wire/event 契约库。
- domain_market：纯市场领域值对象库。
- binance：独立 Binance provider/collector 服务。
- market_data：独立 canonical market fact 服务。
- market_regime：独立 S 状态分析服务。

### 模块通信

- 同步跨模块通信：HTTP。
- HTTP server：Gin。
- HTTP DTO、错误信封和 endpoint：contracts 定义。
- 异步事实流：Kafka，允许作为 HTTP 之后的下游事件分发。
- 禁止业务服务通过 sibling implementation import 通信。

### 唯一权威提交点

market_data 的 append-only Capture Log 是 ingestion 权威事实源。

binance 必须在发送前将 canonical fact 写入 module-owned durable outbox。market_data 仅在 Capture transaction 提交后返回 CAPTURED receipt。CAPTURED 不代表 TDengine、Kafka、Redis、ClickHouse 或 OSS 已完成投影。

### 责任边界

- binance owns：Binance WS/REST、catalog、collection whitelist、history、realtime、Binance orderbook protocol、canonical mapping、durable outbox、HTTP client。
- market_data owns：Gin ingress、capture、acceptance、dedup、ordering、coverage、quarantine、outbox、projection、reconcile、query。
- market_regime owns：accepted fact consumption、event-time windows、S-specific features、S1-S7 state、confidence、evidence、deterministic replay。
- market_regime 不拥有最终 trade permission、position cap、leverage 或 order execution。

### Delivery semantics

系统不声称 cross-system exactly-once。目标是：

- at-least-once submission；
- stable event identity；
- same-key/same-hash idempotency；
- same-key/different-hash conflict；
- capture transaction；
- transactional outbox；
- idempotent projectors；
- continuous reconciliation。

## Superseded decisions

- binance → market_data 的同步路径不再使用 gRPC。
- binance → market_data 的权威提交路径不再使用 NATS。
- binance server 不再拥有跨 provider canonical storage/query/fanout。
- market_data 不再使用 synchronous TDengine + Kafka dual-write 作为 ACK barrier。

旧路径只允许在 migration shadow 阶段存在，并必须显式标记 non-authoritative。

## P0 Gates

1. false-durable-ack
2. same-key-different-hash
3. sequence-gap
4. capture-crash-recovery
5. projection-reconcile
6. replay-determinism
7. no-lookahead
8. final-bar-only
9. contract-conformance
10. repository-identity-consistency

## Consequences

正向结果：职责唯一、故障可恢复、投影可重放、跨 provider 可复用、regime 可确定性验证。

成本：需要 contracts/domain breaking migration、market_data Capture/Outbox 重建、binance data server 退役和双链 shadow cutover。

## Rollback

任何 cutover 失败时：

- binance 保留 durable outbox；
- market_data Capture Log 不回滚或删除；
- 停止新 projector，恢复上一稳定 projector；
- 不把旧 NATS path 自动恢复为 authoritative；
- 通过 replay/reconcile 修复，不通过手工改状态制造成功。

[RULES I BROKE]：无
