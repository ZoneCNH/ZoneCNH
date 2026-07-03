# fred 生产级设计

- Module: `fred`
- Last-Updated: 2026-07-03
- Runtime-Repo: `/home/workspace/fred`
- Spec: [../spec/SPEC.md](../spec/SPEC.md)
- Runtime Mapping: [RUNTIME-MAPPING.md](RUNTIME-MAPPING.md)

## 1. 架构总览

`fred` 采用双服务 C/S 架构，`fred-client` 与 `fred-server` 独立部署，服务间通过 NATS 契约化 handoff 通信：

```text
FRED API
  │
  ▼
cmd/fred-client
  ├─ pull series/observations/vintages/releases/categories/tags/sources/updates
  ├─ normalize -> domain_macro envelope
  ├─ archive raw -> oss
  └─ publish ingest envelope -> nats (JetStream / durable)
                                  │
                                  ▼
                           cmd/fred-server
                            ├─ idempotency/checkpoint (postgres + Redis)
                            ├─ observations -> taos
                            ├─ read model -> clickhouse
                            ├─ business events -> kafka
                            └─ query/admin API -> downstream consumers
```

## 2. 子模块边界

| 子模块 | 运行职责 | 禁止事项 |
| --- | --- | --- |
| `fred-client` | FRED 拉取、分页、限流、重试、归一化、OSS raw 归档、NATS 发布 | 不写业务持久化、不暴露 provider DTO |
| `fred-server` | NATS 消费、幂等校验、多存储写入、Kafka 事件、查询/API | 不直连 FRED provider，不依赖 client 进程内调用 |
| `pkg/fredx` | 对外稳定 client 契约 | 不暴露传输细节和内部错误类型 |

## 3. 核心数据流

1. client 拉取 FRED 数据，原始 payload 先写 `oss`（raw-first）。
2. client 将归一化结果封装为版本化 ingest envelope，发布到 `nats`。
3. server 按幂等键消费 envelope，先校验 schema/字段，再写 `postgres/taos`。
4. server 生成 `clickhouse` 读模型，并发布 `kafka` durable events。
5. 下游通过 API 或 Kafka 消费，不依赖 `fred/internal/*`。

### 3.1 Endpoint 覆盖矩阵（采集侧）

| 族 | 端点 |
| --- | --- |
| Category | `/category`、`/category/children`、`/category/related`、`/category/related_tags`、`/category/series`、`/category/tags` |
| Release | `/releases`、`/releases/dates`、`/release`、`/release/dates`、`/release/series`、`/release/sources`、`/release/tables`、`/release/tags`、`/release/related_tags` |
| Series | `/series`、`/series/categories`、`/series/observations`、`/series/release`、`/series/search`、`/series/search/tags`、`/series/search/related_tags`、`/series/tags`、`/series/updates`、`/series/vintagedates` |
| Source | `/sources`、`/source`、`/source/releases` |
| Tags | `/tags`、`/related_tags`、`/tags/series` |

## 4. 持久化与消息职责

| 组件 | 职责 | 恢复策略 |
| --- | --- | --- |
| `oss` | 原始响应归档、审计与回放输入 | 作为回放源重驱动 downstream 写入 |
| `postgres` | catalog、release calendar、checkpoint、idempotency ledger | 事务回滚 + checkpoint 回放 |
| `taos` | 宏观 observation 时间序列 | 由 envelope 重放补写 |
| `Redis` | 热缓存、锁、限流桶、游标 | 清空后由权威存储重建 |
| `clickhouse` | 分析宽表与聚合读模型 | 从权威写入流全量重建 |
| `nats` | client→server handoff + admin control plane | durable consumer + replay |
| `kafka` | 下游 durable business events | 按 topic/version 回放 |

## 5. 无前视与修订语义

- `available_at` 是 as-of 查询唯一可见性闸门。
- `released_at` 表示发布时刻，允许晚于观测时刻。
- `vintage_at` 用于修订版本追踪。
- 查询引擎必须确保 `as_of < available_at` 的 observation 不可见。

## 6. 一致性与失败处理

1. 幂等键：`provider + series_id + period + vintage + payload_hash`。
2. checkpoint 推进顺序：持久化成功 → 事件发布成功 → checkpoint 更新。
3. 任一关键写入失败，job 状态不得标记 `completed`。
4. 重放优先从 `oss` raw + postgres checkpoint 驱动。

## 7. 可观测与安全

| 维度 | 要求 |
| --- | --- |
| Logs | 必须带 `job_id/series_id/request_id/error_class` |
| Metrics | ingest_latency、publish_lag、store_write_latency、revision_count |
| Tracing | client pull → raw archive → nats publish → server consume → store writes |
| 安全 | 不记录 secret 值；admin API 强制鉴权与审计 |

## 8. 发布前门禁

1. `scripts/boundary-gates.sh` 全 PASS。
2. NATS handoff 与 Kafka durable event 分层验证通过。
3. 七类持久化职责均有集成证据。
4. `ms_brain` contract fixture 完成最小消费闭合。
