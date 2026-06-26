# module/binance OPERATIONS.md — Deployment & Runbook

## Metadata

| Field | Value |
| --- | --- |
| Status | Active |
| Module-Version | v3.7.1 |
| Last-Updated | 2026-06-25 |
| Scope | `module/binance` 部署、扩缩容、故障注入、灾恢复 Runbook |
| Spec-Impact | 生产运维 SRE 指引 |
| Source | `docker-compose.yml`、`configs/`、`cmd/binance-{server,client}/main.go` |

> [FRAME, HIGH] 本文档是 binance 模块生产部署后的 SRE 运维手册，覆盖部署、扩缩容、常见故障诊断与恢复。

## 1. Scope

[FRAME, HIGH] 覆盖：binance-server/binance-client 双进程部署、7 个 infra 依赖、扩缩容策略、故障注入测试、灾恢复流程。

## 2. 部署架构

[COMPUTED, HIGH] 双进程 + 7 infra：

```
binance-client（采集进程）         binance-server（服务进程）
  ├─ Binance WS/REST               ├─ NATS JetStream consumer
  ├─ NormalizeMarketMessage        ├─ idempotency (redisx + pg durable)
  └─ natsx.Publish ───────────►    ├─ persist (taosx 落库)
                                   ├─ PostAcceptHooks (pg_catalog/hot_cache/oss_archive)
                                   ├─ kafkax fanout ──► 下游
                                   ├─ ClickHouse ETL (goroutine)
                                   └─ Gin :8080 REST API
依赖 infra: NATS / Redis / PostgreSQL / TDengine / Kafka / ClickHouse / OSS
```

[COMPUTED, HIGH] 部署方式：`docker-compose up`（docker-compose.yml 含 server + client 两服务，infra 外部连接）。

## 3. 扩缩容策略

[FRAME, HIGH] binance 是**水平可扩展**的（无状态 server + JetStream consumer durable）：

| 组件 | 扩容方式 | 注意事项 |
| --- | --- | --- |
| binance-server | 多实例（JetStream durable consumer 自动负载均衡） | consumer group 必须一致 |
| binance-client | 单实例（每产品线一个 collector） | 多实例需 symbol 分片避免重复采集 |
| infra | 各自扩容（TDengine cluster / Redis cluster / Kafka partition） | 参照各 infra 仓文档 |

## 4. 常见故障诊断

[FRAME, HIGH] 故障矩阵：

| 症状 | 可能原因 | 诊断步骤 | 恢复 |
| --- | --- | --- | --- |
| events_total 无增长 | Binance WS 断连 | 查 `stream_active` gauge；client 日志 | 重启 client；检查网络 |
| storage_write_latency P99 高 | TDengine 负载高 | 查 `storage_write_latency_seconds`；TDengine 监控 | 扩容 TDengine；降采集频率 |
| deadletter 增长 | 存储写入失败 | 查 `deadletter_total`；deadletter 包内容 | 修复 infra；重放 deadletter |
| consumer_lag 高 | server 消费慢 | 查 `natsx_consumer_lag` | 扩容 server 实例 |
| reject rate 高 | 数据质量问题 | 查 `rejected_total` by reject_code | 修复 normalize/stale 阈值 |

## 5. 灾恢复

[FRAME, HIGH] RTO/RPO 目标：

| 场景 | RTO | RPO | 恢复步骤 |
| --- | --- | --- | --- |
| server 进程崩溃 | < 1min | 0（JetStream 持久） | k8s/container 自动重启；JetStream 重放未 ACK 消息 |
| infra 单点故障 | < 5min | 取决于 infra | 切换 infra 副本；验证 consumer 重连 |
| 数据丢失（taosx） | < 1h | 取决于归档 | 从 OSS 归档回热（FR-027）；JetStream 7d retention 重放 |

[FRAME, HIGH] Dead-letter 重放流程：
1. 从 `deadletter` 包提取失败事件
2. 修复根因（infra/normalize bug）
3. 经 admin API 或脚本重放（重新走 ingest 路径）

## 6. 故障注入测试

[FRAME, HIGH] 建议的故障注入（验证韧性）：

| 注入 | 验证 | 现有覆盖 |
| --- | --- | --- |
| NATS 断连 | consumer 自动重连 + JetStream 重放 | `testNATSXIntegrationJetStreamSemantics` |
| Kafka broker 不可用 | dispatch 失败转 retryable reject | `BINANCE_KAFKA_LIVE` gate（PENDING） |
| taosx 写入失败 | dead-letter 入队 + StrictStorageWrite reject | storage_ingest_test.go |
| 消息重复 | idempotency 命中 | idempotency 测试 |

## 7. Evidence Gates

[FRAME, HIGH] 运维就绪的证据要求：

| Gate | 证据 |
| --- | --- |
| 部署文档 | 本 OPERATIONS.md + docker-compose.yml |
| 健康检查 | `/healthz` + `/readyz` 端点存在 |
| 灾恢复 | JetStream 7d retention + OSS 归档配置 |

## 8. Document Synchronization

[FRAME, HIGH] 本文档与 `SPEC.md` §11（部署）、`OBSERVABILITY.md`（metrics）同步。
