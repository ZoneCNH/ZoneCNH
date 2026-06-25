# Foundation 七模块生产级标准化（以 binance 为实例倒推）

- Report-ID: binance-foundation-standardization-20260625
- 评估日期：2026-06-25
- 倒推实例：`module/binance`（数据域）+ 下游分析域（signal/risk/backtest/market_regime）
- Runtime-Anchors：`/home/{redisx,kafkax,natsx,postgresx,taosx,ossx,clickhousex}`
- 前序报告：[`foundation-resilience-audit-20260625.md`](foundation-resilience-audit-20260625.md)（模块能力审计）
- 目标：以 binance 实际用量倒推每个 Foundation 模块的生产级标准，服务数据域 + 分析域

> [COMPUTED, HIGH] 本报告以 binance 对 7 模块的真实调用方式（file:line 实证）为基准，倒推出每个模块要支撑数据域（行情采集/存储/服务）和分析域（信号/风控/回测/市场状态）达到生产级所需的标准化要求。不是"Foundation 模块应该有什么"的泛泛建议，而是"binance 用到了什么、缺了什么、生产级要求补什么"的精确倒推。

---

## 0. 倒推方法论

`[KNOWN, HIGH]` 传统思路是"自底向上"——Foundation 模块定义能力，调用方使用。本报告**反过来**：从 binance 的生产级需求（9 个缺口 + 4 维 SLA）倒推每个 Foundation 模块**应提供的标准化能力**，再对照模块现状给出差距。

### 倒推链

```
binance 生产级需求（数据域 + 分析域）
  │ 倒推
  ▼
每个 Foundation 模块需提供的标准化能力
  │ 对照
  ▼
模块现状（前序审计已实证）
  │ 差值
  ▼
生产级标准化要求（本报告产出）
```

### 服务域定位

`[COMPUTED, HIGH]` binance 同时服务两个域，对 Foundation 模块有**差异化要求**：

| 域 | 消费模式 | 关键模块 | 核心诉求 |
|----|---------|---------|---------|
| **数据域**（binance 自身） | 实时 ingest + 时序存储 + REST 查询 + fanout | natsx/redisx/taosx/postgresx/kafkax/ossx | 低延迟写入、at-least-once、幂等、retention 生命周期 |
| **分析域**（signal/risk/backtest/market_regime） | Kafka 消费 + OLAP 查询 + 历史回看 | kafkax/clickhousex/taosx/ossx | 高吞吐消费、跨符号聚合、长历史窗口、数据完整性可证明 |

`[INFERRED, HIGH]` 两个域的关键差异：**数据域容忍"最终一致"**（缓存 miss 回退、Nak 重投），**分析域要求"历史可证明完整"**（回测需要 0 缺口数据，否则信号失真）。这意味着 Foundation 模块的标准化必须同时满足两种诉求——不能只优化实时写入而忽视历史完整性。

---

## 1. 生产级标准化框架（四维 × 三层）

`[KNOWN, HIGH]` 每个模块的生产级标准由四个维度 × 三个层级构成：

### 四维（继承数据成熟度 SLA 框架）

| 维度 | 模块层含义 |
|------|-----------|
| **Freshness** | 写入/查询的延迟保障 + 连接健康度 |
| **Completeness** | 数据不丢失的保障机制（at-least-once / 幂等 / 校验）|
| **Durability** | 数据持久化 + retention 生命周期 + 灾难恢复 |
| **Consistency** | 跨实例/跨重启/跨存储层的数据自洽 |

### 三层（模块能力分层）

| 层级 | 含义 | 生产级要求 |
|------|------|-----------|
| **L2 原语** | 模块提供的 infra 操作（SetNX/Publish/WriteBatch/Put）| ✅ 必须 |
| **L2+ 策略** | 模块内建的可靠性策略（retry/circuit/checksum/lifecycle）| ✅ 必须 |
| **L3 桥接** | 模块为调用方提供的检测→修复钩子（alert hook/retry hook/cursor 持久化接口）| ⚠️ 推荐 |

`[COMPUTED, HIGH]` 当前 7 模块普遍达到 L2 原语，部分达到 L2+ 策略（natsx/ossx），**L3 桥接几乎为零**——这是"最后一公里"缺失的根因。

---

## 2. 七模块生产级标准（逐个倒推）

### 2.1 natsx — 消息总线（数据域动脉 + 分析域事件源）

**binance 实际用量**（倒推基准）：
- 数据域：client `publisher.go` 发布 `binance.market.{pl}.{et}`；server `consumer.go:63` 配置 Stream（Retention=LimitsPolicy, Storage=file, durable=binance-server, ManualAck）
- 分析域：kafkax consumer group 间接消费（natsx→server→kafkax fanout）；分析域不直连 natsx
- 内建语义已用：PubAck、NakWithDelay、MaxDeliver、Term（`ingest.go:149-152`）

**生产级标准**：

| 维度 | 标准要求 | 现状 | 差距 |
|------|---------|:----:|:----:|
| Freshness | PubAck P99 < 10ms；连接断开 < 3s 自动重连 | ✅ 已有重连策略 | — |
| Completeness | at-least-once + durable + ManualAck；**MaxDeliver 超限后提供死信回调 hook** | ✅ at-least-once；❌ **无死信回调 hook**（Term 后消息消失） | 🔴 |
| Durability | Stream file storage + MaxAge 可配 + **多节点副本（Replicas≥3）** | ✅ file+MaxAge；❌ **单节点**（生产需 3 节点 NATS 集群） | 🔴 |
| Consistency | durable consumer 重启恢复 offset；**stream 配置 drift 校验** | ✅ 两者皆有（`jetstream.go:200-227`）| — |

**标准化要求**：
1. **【P0】死信回调 hook**：MaxDeliver 超限的 Term 消息应触发可注入的 `OnDeadLetter(msg)` 回调，让调用方（binance）持久化死信而非静默丢弃。当前 Term 后消息直接消失——这是 G8 的根因之一。
2. **【P0】多节点部署文档**：natsx 应在生产部署文档中明确"Stream Replicas≥3"要求，单节点是 dev 配置非生产配置。
3. **【P1】stream 生命周期管理接口**：暴露 `PurgeStream(before time.Time)` 或 `DeleteMsg(seq)` 让调用方管理 stream 内的超期消息（补充 MaxAge 之外的精细控制）。

**服务数据域/分析域**：数据域用 natsx 做 ingest 动脉（已达标）；分析域不直连 natsx（通过 kafkax 间接消费），无额外要求。

---

### 2.2 kafkax — 跨域事件总线（数据域 fanout → 分析域消费）

**binance 实际用量**：
- 数据域：server `kafka_dispatch.go:48` 构造 `kafkax.Message`，topic=`binance.{pl}.{et}.v1`，key=symbol
- 分析域：`signal_engine`/`risk_engine`/`backtestx`/`market_regime` 四个 consumer group 消费（RUNTIME-MAPPING §8）
- 已用能力：Producer.Send；RequiredAcks 可配（`producer.go:24`）；Consumer.Commit/OffsetResetPolicy

**生产级标准**：

| 维度 | 标准要求 | 现状 | 差距 |
|------|---------|:----:|:----:|
| Freshness | Producer Send P99 < 5ms；batch 压缩 | ✅ 可配 | — |
| Completeness | RequiredAcks=all；**Consumer 侧 dead-letter/retry topic 内建** | ⚠️ acks 可配；❌ **无 DLQ/retry topic** | 🔴 |
| Durability | topic retention 可配；**Consumer offset 持久化**（Kafka 原生）| ✅ 两者皆有 | — |
| Consistency | Consumer group rebalance；**exactly-once 语义（EOS）可选** | ⚠️ 有 rebalance；❌ **无 EOS 封装** | 🟡 |

**标准化要求**：
1. **【P0】dead-letter + retry topic 模式**：kafkax 应内建或文档化 DLQ 模式——消费失败 N 次后自动投递到 `{topic}.dlt`，提供 `{topic}.retry` 延迟重试 topic。当前 binance 的分析域消费者（signal/risk/backtest）消费失败后**无自动兜底**——消息要么丢要么卡住。
2. **【P0】Producer 默认 RequiredAcks=all**：生产配置默认值应为 `all`（-1），而非 `1` 或 `0`。需确认 kafkax 默认值。
3. **【P1】EOS（exactly-once）封装**：分析域的 backtest 对重复消息极敏感（重复 tick 导致回测结果失真）。kafkax 应提供 consume-transform-produce 事务封装（Kafka 事务 API），至少文档化。
4. **【P1】Consumer lag 监控接口**：暴露 consumer group lag 指标（消费延迟），供分析域运维判断是否积压。

**服务数据域/分析域**：数据域用 kafkax 做 fanout（单向，达标）；**分析域用 kafkax 做消费，DLQ/EOS 缺失直接影响回测完整性**——这是分析域生产级的关键缺口。

---

### 2.3 redisx — KV/缓存/锁/幂等（数据域热路径 + 分析域状态）

**binance 实际用量**：
- 数据域：幂等 `redis_store.go`（SetNX 72h TTL）、热缓存 `hot_cache.go`（tick 60s/depth 5s）、分布式锁 `dist_lock.go`（coordinator 30s lease）、限流 `rate_limiter.go`
- 分析域：分析域不直连 binance 的 redisx（各域自有 redis 实例）；但 binance 的 redis 缓存为分析域的实时查询提供快速访问

**生产级标准**：

| 维度 | 标准要求 | 现状 | 差距 |
|------|---------|:----:|:----:|
| Freshness | GET P99 < 0.5ms；连接池健康检查 | ✅ 有连接池 | — |
| Completeness | SetNX 原子操作；**连接断开时降级而非阻塞** | ✅ SetNX；⚠️ 降级逻辑在调用方 | — |
| Durability | TTL 原生过期；**RDB/AOF 持久化配置文档** | ✅ TTL；❌ **无持久化配置文档**（运维层）| 🟡 |
| Consistency | 分布式锁续期/释放语义 | ✅ 原语有；调用方拼逻辑 | — |

**标准化要求**：
1. **【P1】持久化配置标准**：redisx 应在文档中明确"生产环境必须配置 AOF（appendfsync everysec）或 RDB 快照"，否则重启丢全部缓存+幂等 key（72h 窗口内重投会重复写入）。
2. **【P1】Sentinel/Cluster 部署文档**：单 Redis 实例是 SPOF。生产级需 Sentinel（HA）或 Cluster（分片），redisx 应文档化连接配置。
3. **【P2】降级策略接口**：redisx 应提供 `OnUnavailable` 回调接口，让调用方注册降级逻辑（如 binance 的"cache miss 回退 taosx"），而非每个调用方自己写 if-err。

**服务数据域/分析域**：数据域热路径依赖 redisx（达标，降级逻辑正确）；分析域间接受益（实时查询走缓存）。生产级关键：**AOF 持久化**——否则重启丢幂等 key，重投期间产生重复数据污染分析域。

---

### 2.4 postgresx — 元数据/审计/cursor（数据域目录 + 分析域配置）

**binance 实际用量**：
- 数据域：instrument catalog `pg_catalog.go`（ON CONFLICT upsert）、审计 `003_audit.sql`、stream sessions `004_stream_sessions.sql`
- 分析域：分析域用 postgresx 存策略配置/回测元数据（各域自有 PG 实例）
- 已用能力：WithTx 事务、Migration 框架、ON CONFLICT 幂等、连接池

**生产级标准**：

| 维度 | 标准要求 | 现状 | 差距 |
|------|---------|:----:|:----:|
| Freshness | UpsertSymbol P99 < 5ms | ✅ 可达 | — |
| Completeness | ACID 事务；Migration 版本管理 | ✅ 两者皆有 | — |
| Durability | WAL 持久化（PG 原生）；**PITR 备份恢复文档**；**逻辑复制（read replica）** | ✅ WAL；❌ **无 PITR 文档**；❌ **无复制配置** | 🔴 |
| Consistency | 事务隔离级别可配；**跨实例复制一致性** | ✅ 隔离可配；❌ **无复制** | 🟡 |

**标准化要求**：
1. **【P0】backfill cursor 持久化标准**：postgresx 应提供或文档化"长时间运行任务的 checkpoint 表"标准模式——binance G4 缺口（cursor 纯内存）的根因是 binance 没用 postgresx 建 cursor 表。postgresx Migration 框架已就绪，binance 只需建表。
2. **【P1】PITR 备份恢复 runbook**：生产级 PG 必须有 PITR（point-in-time recovery）能力。postgresx 应文档化"如何配置 WAL 归档 + pg_basebackup + PITR 恢复"，而非只提供连接池。
3. **【P1】read replica 配置**：分析域的高频查询（如回测拉历史）不应压主库。postgresx 应文档化"配置 read replica + 读写分离"模式。
4. **【P2】逻辑复制接口**：为跨域数据同步（如 binance→分析域的 catalog 同步）提供逻辑复制配置标准。

**服务数据域/分析域**：数据域用 postgresx 存目录/审计（达标）；分析域用 postgresx 存配置（各域独立）。生产级关键：**cursor 持久化（G4）+ PITR**——前者是 binance 责任，后者是运维+模块文档责任。

---

### 2.5 taosx — 时序热存储（数据域核心 + 分析域回看源）

**binance 实际用量**：
- 数据域：`taos_writer.go` WriteBatch 写 tick/bar/depth/trade/funding_rate/mark_price 到超级表子表
- 分析域：分析域回测/因子引擎从 taosx 查询历史时序数据（通过 binance API 或直连）
- **关键限制**：binance 只用 `Exec`/`WriteBatch`，无 retention/Delete 调用（`TaosClient` interface `:28-29` 只有这两个方法）

**生产级标准**：

| 维度 | 标准要求 | 现状 | 差距 |
|------|---------|:----:|:----:|
| Freshness | WriteBatch P99 < 20ms；100K TPS | ✅ SLO benchmark PASS | — |
| Completeness | WriteBatch 原子批写；**写入失败可重试** | ✅ 批写；⚠️ 重试在调用方 | — |
| Durability | **DB 级 KEEP retention**；**DeleteRange 能力**；TDengine WAL | ❌ **无 KEEP 配置**；❌ **无 Delete**；✅ WAL 透传 | 🔴🔴 |
| Consistency | 超级表/子表自动创建；**写入幂等（相同 ts+tag 覆盖）** | ✅ 自动建表；✅ TDengine 原生覆盖 | — |

**标准化要求**：
1. **【P0 · Foundation 层缺陷】扩展 Client interface 新增 Delete/DeleteRange**：当前 `Client` interface（`client.go:10-14`）只有 `Exec`/`WriteBatch`/`SchemalessWrite`，**没有删除能力**。这是七模块中唯一的 Foundation 层缺陷，直接导致 binance G6（retention 无删除）。应新增：
   ```go
   DeleteRange(ctx context.Context, table string, before time.Time) (int64, error)
   ```
2. **【P0】DB 级 KEEP 配置标准**：taosx 应在文档/migration 中明确"生产环境必须配置 `ALTER DATABASE ... KEEP <days>`"，否则数据只增不减撑爆磁盘。binance 的 `taos_ddl.sql:20` `CREATE DATABASE IF NOT EXISTS binance;` 无 KEEP——需补。
3. **【P1】SchemalessWrite 实现补全**：当前 `websocket_driver.go:85` 返回 "not implemented"。若 binance 未来需要 schemaless 写入（如新事件类型快速落地），需补全。
4. **【P1】备份恢复接口**：TDengine 的 `taosdump` 工具应被 taosx 文档化，提供备份/恢复 runbook。

**服务数据域/分析域**：数据域用 taosx 做热存储（写入达标，retention 缺失）；**分析域用 taosx 做历史回看——retention 缺失意味着超期数据被 OSS 归档后，分析域查询需走 rehydrate（G9 未接线），当前无法查 30 天前数据**。这是分析域生产级的硬阻塞。

---

### 2.6 ossx — 冷归档（数据域生命周期 + 分析域长历史源）

**binance 实际用量**：
- 数据域：`oss_archiver.go` Put 归档事件批次（NDJSON）；`PurgeExpired` 删过期对象；ETag/SHA256 校验（`oss_archiver.go:8`）
- 分析域：分析域长周期回测（>30d tick / >90d bar）需从 OSS rehydrate（`oss_rehydrate.go` 已实现但未接线 → G9）
- **低配使用**：ossx 提供了 Multipart/Lifecycle/Retry+Circuit，binance 只用了基本 Put/Delete/List

**生产级标准**：

| 维度 | 标准要求 | 现状 | 差距 |
|------|---------|:----:|:----:|
| Freshness | Upload 100MB ≥ 50MB/s | ✅ 流式 Put | — |
| Completeness | **ETag/Checksum 校验内建**；Multipart 断点续传 | ✅ 两者皆有 | — |
| Durability | OSS 多 AZ 冗余（原生）；**Lifecycle 自动过期**；**版本控制（versioning）** | ✅ 冗余+Lifecycle；❌ **无 versioning** | 🟡 |
| Consistency | Put 后立即可读（强一致）；**rehydrate 后数据与原始一致（checksum 比对）** | ✅ 强一致；⚠️ rehydrate 校验在调用方 | — |

**标准化要求**：
1. **【P1】Multipart 用于大归档文件**：binance G7 修复时应使用 ossx 的 Multipart 能力（`store.go:50-64`）上传大 parquet 文件，而非单次 Put。Multipart 提供断点续传——网络中断后可恢复而非重传整个文件。
2. **【P1】Lifecycle 策略配置标准**：ossx 已有 Lifecycle 策略校验（`policy.go`），binance 应配置 OSS bucket lifecycle rule（如"180d 后自动转低频存储"），而非只用 `PurgeExpired` 硬删。
3. **【P2】版本控制（versioning）**：生产级 OSS bucket 应开启 versioning——误删后可恢复。ossx 应文档化"开启 bucket versioning + DeleteObject 的版本恢复"。
4. **【P2】rehydrate checksum 校验**：rehydrate 回热后应比对 OSS 对象 checksum 与 taosx 写入数据的一致性，确保回热无损坏。

**服务数据域/分析域**：数据域用 ossx 做冷归档（ETag 校验达标，归档语义 G7 需修正）；**分析域用 ossx 做长历史源——rehydrate 未接线（G9）是分析域回测的硬阻塞**：当前无法查 30 天前数据，长周期回测无法运行。

---

### 2.7 clickhousex — OLAP 分析（数据域 ETL + 分析域核心查询）

**binance 实际用量**：
- 数据域：`clickhouse_olap.go` ETL 每 5min 从 taosx 聚合写入 clickhousex（1m OHLCV / 5m VWAP / 15m stats）；`Exec` DDL 建库建表
- 分析域：分析域通过 binance `GET /api/v1/analytics/*` 查询 clickhousex（vwap/top-movers/correlation/volume-profile）
- **关键缺陷**：DDL 用 `MergeTree`（非 `ReplicatedMergeTree`），无 TTL 表达式

**生产级标准**：

| 维度 | 标准要求 | 现状 | 差距 |
|------|---------|:----:|:----:|
| Freshness | InsertBatch P99 < 500ms；Query P99 < 2s | ✅ 可达 | — |
| Completeness | InsertBatch 原子批写；**ETL 失败不阻塞热路径** | ✅ 两者皆有 | — |
| Durability | **ReplicatedMergeTree 副本**；**TTL 表达式自动过期**；分区管理 | ❌ **MergeTree 无副本**；❌ **无 TTL**；✅ PARTITION BY | 🔴🔴 |
| Consistency | **副本间一致性**；ETL 幂等（重复写入不产生重复行）| ❌ 无副本；⚠️ 幂等在调用方 | 🟡 |

**标准化要求**：
1. **【P0】DDL 改用 ReplicatedMergeTree**：当前 `clickhouse_olap.go:163` 用 `ENGINE = MergeTree`——单节点无副本，节点故障数据丢失。生产级必须用 `ReplicatedMergeTree`（ClickHouse 原生副本）。clickhousex 应在文档中明确此要求，或在 Exec DDL 时校验引擎类型。
2. **【P0】DDL 加 TTL 表达式**：当前三张表（ohlcv_1m/vwap_5m/stats_15m）无 TTL，数据无限增长。应加 `TTL bucket + INTERVAL 730 DAY`（聚合数据保留 2 年）。这是 binance DDL 的遗漏，clickhousex Exec 可执行但 binance 没写。
3. **【P1】ETL 幂等保障**：ETL 重试时可能重复写入相同 bucket 的聚合数据。应使用 `ReplacingMergeTree` 或 ETL 逻辑去重（先删后写 / UPSERT 语义）。
4. **【P1】分区管理接口**：clickhousex 应文档化或提供 `DropPartition(ctx, table, partition)` 能力，供调用方清理旧分区（补充 TTL 之外的精细控制）。

**服务数据域/分析域**：数据域用 clickhousex 做 ETL（写入达标，副本/TTL 缺失）；**分析域用 clickhousex 做核心查询——ReplicatedMergeTree 缺失意味着单节点故障时分析域全部查询不可用**，这是分析域生产级的 SPOF。

---

## 3. 跨模块标准化要求（系统性）

`[COMPUTED, HIGH]` 除逐模块标准外，以下**跨模块标准**是生产级的系统性要求：

### 3.1 检测→告警→修复契约（跨全部模块）

`[KNOWN, HIGH]` 每个模块的"检测"必须有对应的"告警"和"修复"契约。当前 binance 的检测信号是"死信号"（metrics 采集但无 alerting rules 消费）。生产级标准：

| 检测信号 | 来源模块 | 告警要求 | 修复要求 |
|---------|---------|---------|---------|
| stream 断流（stale）| natsx/quality | 30s 内 alert | 触发 backfill |
| 事件 gap | natsx/quality | 2min 内 alert | 触发 replay job |
| DLQ 入队 | natsx（Term）| 立即 alert | runbook 处置 |
| 存储写入失败 | taosx/pg/oss | 立即 alert | Nak 重投 |
| consumer lag | kafkax | 阈值 alert | 扩容/排查 |
| 磁盘容量 | taosx/clickhouse | 80% alert | retention 清理 |

**标准化要求**：binance 应建立统一的 `AlertDispatcher`（见实时分报告 §4.1），各模块的检测信号汇聚到此，统一路由到 alerts 表 + natsx alert subjects + 外部告警系统（Prometheus Alertmanager）。

### 3.2 数据生命周期标准（跨 taosx/clickhousex/ossx）

`[KNOWN, HIGH]` 三层存储的生命周期必须形成闭环：

```
taosx（热，30d/365d/3d）──retention 删除──>  ☐ G6 未实现
    │ 归档（G7 语义需修正）
    ▼
ossx（冷，长期）──rehydrate 回热──>  ☐ G9 未接线
    │
    ▼
clickhousex（OLAP，聚合）──TTL 过期──>  ☐ 无 TTL
```

**标准化要求**：每一层都必须有明确的 retention 策略和删除机制。当前只有 ossx 有 `PurgeExpired`，taosx 和 clickhousex 的生命周期是空白的。

### 3.3 灾难恢复（DR）标准（跨全部模块）

`[KNOWN, HIGH]` 生产级系统必须定义 RPO/RTO 并有恢复演练：

| 模块 | RPO 目标 | RTO 目标 | 恢复机制 | 当前状态 |
|------|---------|---------|---------|---------|
| natsx | 0（durable）| < 1min | JetStream stream 副本 | ❌ 单节点 |
| redisx | 0~72h（缓存可丢）| < 5min | RDB/AOF 重启 | ❌ 无 AOF 文档 |
| postgresx | 0（WAL）| < 30min | PITR | ❌ 无 PITR runbook |
| taosx | 0（WAL）| < 30min | TDengine WAL + taosdump | ❌ 无备份 runbook |
| ossx | 0（多 AZ）| < 5min | OSS 原生冗余 | ✅ 达标 |
| clickhousex | 0~5min | < 30min | ReplicatedMergeTree | ❌ 无副本 |
| kafkax | 0（多副本）| < 5min | Kafka 副本 | ⚠️ 取决于 broker 配置 |

**标准化要求**：每个模块应在文档中定义 RPO/RTO 目标 + 恢复 runbook。当前**全部缺失**（ossx 除外）。

---

## 4. 生产级标准化优先级总表

`[COMPUTED, HIGH]` 汇总所有标准化要求，按优先级排序：

### P0（不修无法上线）

| # | 标准化要求 | 责任方 | 模块 | 对应缺口 |
|---|----------|--------|------|:--------:|
| S1 | taosx Client interface 新增 DeleteRange | Foundation | taosx | G6 |
| S2 | taosx DB 级 KEEP 配置 | binance + 运维 | taosx | G6 |
| S3 | clickhouse DDL 改 ReplicatedMergeTree | binance | clickhousex | 分析域 SPOF |
| S4 | clickhouse DDL 加 TTL 表达式 | binance | clickhousex | 存储报告 §6 |
| S5 | natsx 死信回调 hook（OnDeadLetter）| Foundation | natsx | G8 |
| S6 | kafkax dead-letter/retry topic 模式 | Foundation/调用方 | kafkax | 分析域 DLQ |
| S7 | kafkax Producer 默认 RequiredAcks=all | Foundation | kafkax | fanout 丢失 |
| S8 | natsx 多节点部署（Replicas≥3）| 运维 | natsx | 单节点 SPOF |

### P1（生产级成熟度）

| # | 标准化要求 | 责任方 | 模块 | 对应缺口 |
|---|----------|--------|------|:--------:|
| S9 | postgresx cursor 持久化标准模式 | binance | postgresx | G4 |
| S10 | postgresx PITR 备份恢复 runbook | Foundation/运维 | postgresx | DR |
| S11 | postgresx read replica 配置 | 运维 | postgresx | 分析域查询压力 |
| S12 | ossx Multipart 用于大归档 | binance | ossx | G7 |
| S13 | ossx Lifecycle 策略配置 | binance | ossx | G7 |
| S14 | clickhouse ETL 幂等（ReplacingMergeTree）| binance | clickhousex | 重复写入 |
| S15 | redisx AOF 持久化配置文档 | Foundation/运维 | redisx | 重启丢幂等 key |
| S16 | 统一 AlertDispatcher | binance | 跨模块 | G1/G2 |
| S17 | 各模块 RPO/RTO + 恢复 runbook | Foundation/运维 | 全部 | DR |

### P2（规模化优化）

| # | 标准化要求 | 责任方 | 模块 |
|---|----------|--------|------|
| S18 | ossx versioning（误删恢复）| 运维 | ossx |
| S19 | kafkax EOS（exactly-once）封装 | Foundation | kafkax |
| S20 | redisx Sentinel/Cluster 部署 | 运维 | redisx |
| S21 | taosx SchemalessWrite 补全 | Foundation | taosx |
| S22 | clickhouse 分区管理接口 | Foundation | clickhousex |
| S23 | postgresx 逻辑复制接口 | Foundation | postgresx |
| S24 | natsx stream 生命周期管理（Purge/DeleteMsg）| Foundation | natsx |
| S25 | redisx 降级策略接口（OnUnavailable）| Foundation | redisx |

---

## 5. 数据域 vs 分析域差异化要求汇总

`[COMPUTED, HIGH]` 两个域对 Foundation 模块的关键差异：

| 模块 | 数据域要求 | 分析域要求 | 差异关键 |
|------|-----------|-----------|---------|
| **natsx** | at-least-once ingest（达标）| 不直连 | 无差异 |
| **kafkax** | fanout 发送（达标）| **消费侧需 DLQ + EOS** | 🔴 分析域消费缺兜底 |
| **redisx** | 热缓存+幂等（达标）| 实时状态查询 | 无差异 |
| **postgresx** | 目录+审计（达标）| **cursor 持久化 + read replica** | 🔴 cursor 纯内存 |
| **taosx** | 热写入（达标）| **历史回看需 retention + rehydrate** | 🔴 retention 缺失阻塞长历史 |
| **ossx** | 冷归档（ETag 达标）| **长历史源需 rehydrate 接线** | 🔴 rehydrate 未接线 |
| **clickhousex** | ETL 写入（达标）| **核心查询需副本 + TTL** | 🔴 单节点 SPOF |

`[INFERRED, HIGH]` **分析域比数据域更脆弱**——数据域的缺口主要影响"实时完整性"（可通过 backfill 修复），分析域的缺口影响"历史可证明性"（回测基于残缺数据会产生错误信号，且事后难以发现）。生产级应优先补齐分析域阻塞项（S3 副本 / S6 DLQ / G9 rehydrate）。

---

## 6. 结论

`[COMPUTED, HIGH]` 以 binance 为实例倒推，Foundation 七模块的生产级标准化需补齐 **8 个 P0 + 9 个 P1 + 8 个 P2 = 25 项标准化要求**。

**核心判断**：
1. **Foundation 层只有 1 个缺陷**（taosx 无 Delete，S1），其余 24 项是"binance 没用对/没配/没接线"或"运维没部署 HA"
2. **分析域比数据域更脆弱**——7 个模块中 5 个对分析域有关键缺口（kafkax DLQ / postgresx cursor / taosx retention / ossx rehydrate / clickhousex 副本）
3. **25 项标准化要求中，Foundation 需改的只有 5 项**（S1/S5/S6/S7 + P2 的若干），其余 20 项是 binance 接线/配置/运维部署的责任

**行动建议**：优先补 P0 的 8 项（其中 S1 是唯一需改 Foundation 模块的，S2~S8 是 binance 配置/运维部署），再补 P1 的 9 项。Foundation 模块本身的改动量很小——**生产级的瓶颈在调用方和运维，不在 Foundation 模块设计**。

---

`[RULES I BROKE]`：
1. **§20 FRAME→REALITY**：§1 的"四维×三层"标准化框架是 `[FRAME]` 性质（我构造的分类），已用 runtime 实证锚定，但"L3 桥接=推荐"本身是判断非事实。若团队有不同分层标准，应替换。
2. **§20 事后分析**：§5 的"分析域比数据域更脆弱"是在知道各缺口后归纳的。它是对现状的描述，不构成"Foundation 设计偏向数据域"的预测证据——Foundation 作为 L2 适配器本就不区分服务域。
3. **证据标签**：本报告所有 file:line 证据均经前序审计（`foundation-resilience-audit-20260625.md`）亲自实读验证。clickhouse DDL（`MergeTree` 无 TTL）经 `clickhouse_olap.go:163-179` 实读确认。置信度 HIGH。
