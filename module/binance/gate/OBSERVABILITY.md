# module/binance OBSERVABILITY.md — Metrics & Alerting Standard

## Metadata

| Field | Value |
| --- | --- |
| Status | Active |
| Module-Version | v3.9.8 |
| Last-Updated | 2026-07-04 |
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

## 6. ACK 时序语义（N3 声明）

`[COMPUTED, HIGH]` binance-server ingest 流程的 ACK/persist 时序如下（`internal/server/ingest.go:129-172`）：

| 模式 | 时序 | 行为 | 适用场景 |
| --- | --- | --- | --- |
| 默认模式（`StrictStorageWrite=false`） | MarkDurable(3) → Dispatch(4) → Persist(5) | 落库失败仅记 dead-letter，ACK 已 durable（消息不会重投） | 高吞吐场景，容忍少量落库延迟 |
| 严格模式（`StrictStorageWrite=true`） | MarkDurable(3) → Dispatch(4) → Persist(5)，persist 失败 → reject | 落库失败触发 reject，消息重投 | 数据完整性优先场景 |

**SLA 声明**：
- 默认模式下，落库失败的事件通过 dead-letter 队列补偿，不丢失消息但可能有短暂落库延迟
- 严格模式下，落库失败触发 NATS 重投（MaxDeliver=5, NakDelay=5s），超过重试次数后进 dead-letter
- `StrictDispatchHandoff=true` 时，dispatch 成功后才 MarkDurable，dispatch 失败返回 retryable reject
- Dead-letter 率 SLO：≤ 0.1%（见 §3）

## 7. OLAP 聚合源口径（N5 声明）

`[COMPUTED, HIGH]` 当前 OLAP 聚合源为**进程内存窗口模式**（`internal/server/assembly/olap_source.go`）：

| 属性 | 值 | 说明 |
| --- | --- | --- |
| 实现类型 | `memoryAggSource` | 进程内存聚合，非持久化物化视图 |
| 窗口时长 | 10 分钟（默认） | 超过窗口的数据被淘汰 |
| 最大点数 | 100,000 | 内存上限保护 |
| 数据来源 | 实时 `AcceptedEvent` | 通过 `Add()` 方法写入 |
| 查询接口 | `FetchRecent(since)` | 返回窗口内且晚于 `since` 的聚合点 |

**限制声明**：
- 进程重启后 OLAP 聚合数据丢失（非持久化）
- 窗口外历史数据不可查（需从 TDengine/ClickHouse 查询原始数据）
- 长期升级路径：迁移到 ClickHouse 物化视图（P2 优先级，非阻断）

## 8. Document Synchronization

[FRAME, HIGH] 本文档与 `SPEC.md` NFR-001~004、`ACCEPTANCE.md` 可观测性 AC 同步。
