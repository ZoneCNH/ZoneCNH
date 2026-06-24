# module/binance DATA-QUALITY-SLA.md — Data Freshness & Quality SLA

## Metadata

| Field | Value |
| --- | --- |
| Status | Active |
| Module-Version | v3.5.2 |
| Last-Updated | 2026-06-25 |
| Scope | `module/binance` 数据新鲜度 SLA、stale 告警、schema drift 处理 |
| Spec-Impact | FR-029（数据质量监控）对外承诺 |
| Source | `internal/server/quality.go`、`SPEC.md` NFR |

> [FRAME, HIGH] 本文档定义 binance 模块对下游消费者（market_data/signal/risk）的数据质量承诺：新鲜度、完整性、schema 稳定性。

## 1. Scope

[FRAME, HIGH] 覆盖：数据新鲜度 SLA（freshness P95/P99）、stale 告警阈值、schema drift 检测与处理流程。

## 2. 数据新鲜度 SLA

[FRAME, HIGH] 对外承诺（基于 FR-029）：

| 产品线 | 事件类型 | Freshness P95 | Freshness P99 | 说明 |
| --- | --- | --- | --- | --- |
| spot | trade | ≤ 500ms | ≤ 2s | 高频公开流 |
| spot | bookTicker | ≤ 500ms | ≤ 2s | top-of-book |
| um/cm_perp | trade | ≤ 500ms | ≤ 2s | 合约公开流 |
| all | kline | ≤ 1 interval | ≤ 2 interval | bar 闭合后推送 |
| all | depth | ≤ 200ms | ≤ 1s | 100ms 推送间隔 |

[FRAME, HIGH] Freshness 定义：`LocalReceiveTime - EventTime`（server 本地接收减交易所事件时间）。

## 3. Stale 告警

[COMPUTED, HIGH] 当前 stale 检测（`internal/server/ingest.go`）：
- `StaleThreshold = 30s`（DefaultServerConfig）：EventTime 超过 now-30s 的事件被拒绝
- `MaxEventGap = 2min`：流连续性 gap 超 2min 触发 quality 事件
- `FutureTolerance = 5s`：EventTime 超 now+5s 拒绝（时钟漂移保护）

[FRAME, HIGH] 告警阈值（SRE 配置）：
- `binance_event_stale_total` rate > 1% → 数据延迟告警
- `stream_active` 突降 → 流中断告警
- 单 symbol 5min 无事件 → 该 symbol stale 告警

## 4. Schema Drift 处理

[FRAME, HIGH] Binance 上游 schema 变更的处理流程：

| 变更类型 | 检测方式 | 处理 |
| --- | --- | --- |
| 新增字段 | normalize 解析正常（JSON 忽略未知字段） | 无需处理（向后兼容） |
| 字段重命名 | normalize 报错（missing field） | 更新 normalize.go + testdata fixture |
| 字段移除 | normalize 报错或返回空值 | 评估影响 + 更新 parser |
| 新事件类型 | 落 rawPassThrough 兜底 | 评估是否需结构化 parser |

[FRAME, HIGH] Schema drift 监控：
- `rejected_total` by `reject_code` 突增 → 可能 schema 变更
- rawPassThrough 事件突增 → 新事件类型出现
- 定期 mainnet 抓样比对 fixture（建议每日）

## 5. 数据完整性

[FRAME, HIGH] 完整性保证：
- **幂等**：redisx SetNX 72h，重复消息去重（FR-005）
- **顺序**：JetStream 单 subject 保序；consumer 按序处理
- **不丢失**：NakWithDelay + MaxDeliver=5 + deadletter 兜底（FR-004）
- **落盘**：StrictStorageWrite=true，落盘失败转 retryable（G0 修复后）

## 6. Evidence Gates

[FRAME, HIGH] 数据质量 SLA 就绪的证据要求：

| Gate | 证据 |
| --- | --- |
| stale 检测 | ingest.go StaleThreshold/MaxEventGap 实现 |
| 质量指标 | quality.go + metrics stale_total |
| 幂等 | idempotency RedisStore + 72h TTL |
| 完整性 | NakWithDelay + deadletter + StrictStorageWrite |

## 7. Document Synchronization

[FRAME, HIGH] 本文档与 `SPEC.md` FR-029/NFR、`OBSERVABILITY.md` stale 指标、`ACCEPTANCE.md` 数据质量 AC 同步。
