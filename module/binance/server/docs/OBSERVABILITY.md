# module/binance/server OBSERVABILITY.md — Metrics & Alerting Standard

## Metadata

| Field | Value |
| --- | --- |
| Status | Active |
| Module-Version | v3.7.1 |
| Last-Updated | 2026-06-25 |
| Scope | `module/binance` Prometheus metrics 语义、告警阈值、SLO 仪表盘 |
| Spec-Impact | NFR-001~004（可观测性） |
| Source | `internal/server/metrics/`、`cmd/binance-server/main.go` |

> [FRAME, HIGH] 本文档定义 binance 模块的 9 个 Prometheus 指标的语义与告警阈值，供 SRE 配置告警与仪表盘。

## 1. Scope

[FRAME, HIGH] 覆盖：metrics 命名与语义、告警阈值、SLO 目标、仪表盘布局建议。

## 2. Metrics 清单（9 指标）

[COMPUTED, HIGH] 基于 `internal/server/metrics/` 代码核实：

| Metric | 类型 | 语义 | 告警阈值 |
| --- | --- | --- | --- |
| `binance_ingest_events_total` | counter | 接受的事件总数（按 product_line/event_type） | 5min 无增长 → 数据流中断 |
| `binance_ingest_rejected_total` | counter | 拒绝事件数（按 reject_code） | reject rate > 5% → 数据质量下降 |
| `binance_dispatch_latency_seconds` | histogram | dispatch（kafkax）延迟 | P99 > 1s → 下游积压 |
| `binance_storage_write_latency_seconds` | histogram | 存储（taosx）写入延迟 | P99 > 500ms → 落盘瓶颈 |
| `binance_idempotency_hits_total` | counter | 幂等命中数 | 突增 → 上游重发异常 |
| `binance_deadletter_total` | counter | dead-letter 入队数 | 5min > 0 → 持久化故障 |
| `binance_natsx_consumer_lag` | gauge | NATS consumer 积压 | > 1000 → 消费跟不上 |
| `binance_stream_active` | gauge | 活跃 stream 数（按 product_line） | 突降 → 连接断开 |
| `binance_event_stale_total` | counter | 过期事件数（EventTime 超阈值） | rate > 1% → 时钟/网络问题 |

[FRAME, HIGH] 所有指标通过 `GET /metrics`（Prometheus exposition）暴露，无认证（供 scrape）。

## 3. SLO 目标

[FRAME, HIGH] 生产 SLO（基于 NFR-001~004）：

| SLO | 目标 | 关联 metric |
| --- | --- | --- |
| 事件接受可用性 | ≥ 99.9% | ingest_events_total / (accepted+rejected) |
| Dispatch 延迟 P99 | ≤ 1s | dispatch_latency_seconds |
| 落盘延迟 P99 | ≤ 500ms | storage_write_latency_seconds |
| Dead-letter 率 | ≤ 0.1% | deadletter_total / ingest_events_total |

## 4. 仪表盘建议

[FRAME, HIGH] Grafana 仪表盘布局（3 行）：
1. **流量行**：events_total（按 product_line 堆叠）+ stream_active
2. **延迟行**：dispatch/storage latency P50/P95/P99
3. **健康行**：rejected/deadletter/stale rate + consumer_lag

## 5. Evidence Gates

[FRAME, HIGH] 可观测性就绪的证据要求：

| Gate | 证据 |
| --- | --- |
| metrics 实现 | `internal/server/metrics/` 9 指标全部实现 |
| exposition | `GET /metrics` 返回 Prometheus 格式 |
| SLO benchmark | `release/evidence/binance/20260625/slo-report.md` 24 bench PASS |

## 6. Document Synchronization

[FRAME, HIGH] 本文档与 `SPEC.md` NFR-001~004、`ACCEPTANCE.md` 可观测性 AC 同步。
