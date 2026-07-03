# eastmoney 架构设计

## 1. 运行时拓扑

```text
eastmoney-client (独立进程)
  -> oss(raw)
  -> nats(ingest/control)
      -> eastmoney-server (独立进程)
         -> taos / postgres / Redis / clickhouse
         -> kafka(durable events)
         -> query/admin API
```

## 2. 共享基座约束

1. 配置：统一 `configx`。
2. 观测：统一 `observex`（metrics/log/trace）。
3. 弹性：统一 `resiliencx`（timeout/retry/backoff/circuit）。
4. 消息：统一 `natsx`/`kafkax` 适配层。
5. 存储：统一 `taosx`/`postgresx`/`redisx`/`ossx`/`clickhousex`。

## 3. 领域共享层约束

出域模型必须来自 `domain_macro`，禁止 provider DTO 透传；统一携带 `observed_at/released_at/available_at/vintage_at` 语义。

## 4. 数据写入原则

1. OSS first，后规范化。
2. 幂等写入 + checkpoint 推进。
3. NATS 仅 handoff/control，Kafka 仅 durable business events。
4. Redis/ClickHouse 均为可重建层。

## 5. 采集架构分层

1. `collector`：按 CMD/GMD/IED 分源采集，支持 API/XHR/headless 三通道。
2. `normalizer`：统一口径（同比/环比、季调/未季调、时区）。
3. `scheduler`：发布日历触发 + cron 触发双轨执行。
4. `quality-gate`：coverage/freshness/revision-lag/consistency 四维校验。
5. `publisher`：NATS ingest/control 与 Kafka durable event 分层发布。

## 6. 数据规模与存储策略

1. 指标空间：百万级指标主键（provider + dataset + series）。
2. 时序空间：亿级 observation（series + timestamp + vintage）。
3. 分层：`oss` 保存 raw 权威，`taos` 保存时序权威，`postgres` 保存控制面权威。
4. 派生层：`Redis`/`clickhouse` 仅缓存与分析读模型，支持重建。
