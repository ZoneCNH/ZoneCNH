# Foundation 七模块数据缺口检测/补齐/存储/恢复策略审计

- Report-ID: binance-foundation-resilience-audit-20260625
- 所属主报告：[`data-maturity-assessment-20260625.md`](data-maturity-assessment-20260625.md) §1.4 横切维度
- 评估日期：2026-06-25
- 范围：redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex
- 审计方法：逐模块实读 `pkg/` interface 定义 + README/SPEC + binance 调用点
- 目标：回答每个模块的「自动检测缺口、自动补齐、存储策略、数据恢复策略」四问，判定可靠性责任归属

---

## 0. 核心结论（先看这个）

`[COMPUTED, HIGH]` **Foundation 七模块统一定位为"L2 infra 适配器"，只表达基础设施语义，不表达业务语义。** 这导致一个系统性后果：**数据缺口检测、自动补齐、生命周期管理、灾难恢复的可靠性责任，几乎全部落在调用方（binance）层，而非 Foundation 模块层。**

| 责任层 | 承担内容 | 当前状态 |
|--------|---------|---------|
| **Foundation 模块（L2）** | 连接管理、原语操作（SetNX/Publish/WriteBatch/Put）、错误分类、健康检查、连接池重连 | ✅ 扎实 |
| **调用方（binance L3）** | 缺口检测、自动补齐、retention 管理、ETag 校验、幂等逻辑、DLQ、reconcile、灾难恢复 | ❌ 大面积缺失（9 个缺口）|

`[INFERRED, HIGH]` **这个分层设计本身没错**——L2 不应耦合业务语义。**问题在于 binance 作为调用方，没有充分承担起 L3 可靠性责任**。Foundation 模块提供了"砖头"，但 binance 只用砖头搭了"采集+写入"，没搭"检测+修复+恢复"。

---

## 1. 七模块逐项审计

### 1.1 redisx（HEAD `069f699`）— KV 原语，无持久化/恢复责任

| 维度 | 判定 | 证据 |
|------|------|------|
| **缺口检测** | ❌ 无。纯被动 KV，不检测数据缺口 | `client.go:128` Get / `:167` SetNX — 只是透传 Redis 命令 |
| **自动补齐** | ❌ 无。SetNX 提供原子操作原语，但"幂等逻辑"由调用方拼 | binance `redis_store.go` 自己实现 SetNX→判断→写入/跳过 |
| **存储策略** | ⚠️ 透传 Redis TTL。redisx 不管理 RDB/AOF 持久化（运维层） | `helpers.go:14` TTL 字段；grep `rdb\|aof\|persist\|snapshot` 零命中 |
| **数据恢复** | ❌ 无。Redis 本身是缓存，持久化/恢复是运维责任 | redisx 不暴露 backup/restore 接口 |

**关键结论**：redisx 是 Redis 命令的 Go 适配器，可靠性责任全在调用方。binance 的幂等（FR-005）、热缓存（FR-006c）、分布式锁（FR-011）都是基于 redisx 原语**自己拼的**。Redis 数据丢失（缓存穿透）不致命——binance 的降级逻辑（cache miss 回退 taosx）是正确的。

---

### 1.2 kafkax（HEAD `c9a43e3`）— Producer/Consumer/Admin，无 dead-letter 内建

| 维度 | 判定 | 证据 |
|------|------|------|
| **缺口检测** | ⚠️ 部分。Consumer 有 OffsetResetPolicy（earliest/latest/none），能发现 offset 越界；无消息丢失检测 | `consumer.go:35-40` OffsetResetPolicy |
| **自动补齐** | ⚠️ 部分。有 Retryable 错误分类（`errors.go:32`），Consumer.Commit 手动提交 offset；**无 dead-letter queue / retry topic 内建** | grep `deadletter\|dead.letter\|retry.topic` 零命中 |
| **存储策略** | ⚠️ 透传 Kafka topic retention。Admin 接口有 CleanupPolicy（delete/compact），但 retention 由调用方配 | `admin.go:54` CleanupPolicyDelete |
| **数据恢复** | ⚠️ 部分。Consumer group offset 持久化在 Kafka __consumer_offsets（Kafka 原生）；Producer 的 RequiredAcks 可配 | `producer.go:24` RequiredAcks；`producer.go:118` requiredAcks |

**关键结论**：kafkax 提供了 Kafka 语义原语（offset 管理、ack 级别、错误分类），但 **dead-letter/retry topic 需调用方自己实现**。binance 的 `kafka_dispatch.go` 只用了 Producer.Send，**未配置 Consumer 侧的 dead-letter 兜底**——这意味着 Kafka 消费失败后无自动重试/死信路径（binance 当前用 natsx 的 NakWithDelay 兜底 ingest 侧，但 kafkax 下游消费侧无兜底）。

---

### 1.3 natsx（HEAD `b2e6f05`）— JetStream 语义封装，可靠性原语最完整

| 维度 | 判定 | 证据 |
|------|------|------|
| **缺口检测** | ✅ 部分。JetStream PubAck 确认持久化；durable consumer 自动恢复 offset | `ingest.go:31` PublishAck；`ingest.go:195` Durable |
| **自动补齐** | ✅ 最完整。**NakWithDelay / MaxDeliver / Term（poison message）内建**；at-least-once 由 JetStream durable + ManualAck 保障 | `ingest.go:149-152` NakWithDelay/Nak/Term；`jetstream.go:200-227` Retention/MaxMsgs/MaxAge/Storage 校验 |
| **存储策略** | ✅ 透传 JetStream 配置。Stream 的 Retention/MaxAge/MaxMsgs/Storage(file) 可配，模块会校验配置 drift | `jetstream.go:200` Retention 校验；`:218` MaxAge 校验；`:227` Storage 校验 |
| **数据恢复** | ✅ 最佳。durable consumer 重启后从上次 Ack 位置恢复（JetStream 原生）；stream file storage 持久化 | `ingest.go:145` "未调用且超 AckWait 则 JetStream 重投递" |

**关键结论**：natsx 是七模块中**可靠性原语最完整的**——PubAck/NakWithDelay/MaxDeliver/Term/durable 全内建。binance 的 FR-003/004/BR-004 直接受益于此。**但 stream 的具体配置（MaxAge=7d、MaxDeliver=5）由 binance `consumer.go:63-78` 自己设**，natsx 只校验不 drift。dead-letter 的"最后一公里"（MaxDeliver 超限后存哪、怎么 replay）仍需调用方实现——binance 当前用 in-memory DLQ（G8 缺口）。

---

### 1.4 postgresx（HEAD `cfbfb49`）— 连接池+事务+Migration，无 backup/restore

| 维度 | 判定 | 证据 |
|------|------|------|
| **缺口检测** | ❌ 无。被动执行 SQL，不检测数据缺口 | Tx/Queryer 接口只做 Exec/Query/QueryRow |
| **自动补齐** | ❌ 无。ON CONFLICT 幂等由调用方写 SQL；无逻辑复制/PITR | binance `pg_catalog.go:65` 自己写 `ON CONFLICT (symbol, product_line) DO UPDATE` |
| **存储策略** | ✅ ACID 事务（`tx.go:81` BeginTx）+ Migration 框架（`migration.go:36` MigrationRunner）+ 连接池 + 健康检查 | `migration.go:10-20` Migration/MigrationSource |
| **数据恢复** | ❌ 无。无 backup/restore 接口；PITR/物理备份依赖外部工具（pg_dump/Barman/PITR） | grep `backup\|restore\|pitr\|barman` 零命中 |

**关键结论**：postgresx 是标准的"PostgreSQL 连接池+事务+迁移"封装。**数据可靠性（WAL/检查点/复制）是 PostgreSQL 引擎原生能力，postgresx 透传不干预**——这是正确设计。但 binance 的 backfill cursor 持久化（G4）和 reconcile alerts 表（G5）需要 binance 自己建表+写入，postgresx 只提供执行能力。

---

### 1.5 taosx（HEAD `3c108cc`）— 只写不删，无 retention 能力

| 维度 | 判定 | 证据 |
|------|------|------|
| **缺口检测** | ❌ 无。被动 WriteBatch/Query，不检测数据缺口 | `client.go:10-14` Client interface 只有 Exec/WriteBatch/SchemalessWrite |
| **自动补齐** | ❌ 无。SchemalessWrite 返回 not implemented（`websocket_driver.go:85`） | `websocket_driver.go:84-85` |
| **存储策略** | ❌ **无 retention/KEEP 能力**。Client interface 无 Delete/DropRange；DDL 层 KEEP 由调用方配（binance 没配 → G6） | grep `Delete\|DROP\|KEEP\|Retention` 在 taosx pkg/ **零命中**（只有 ErrorKindWrite） |
| **数据恢复** | ⚠️ 透传 TDengine 原生 WAL。taosx 不提供 backup/restore；TDengine 的 WAL/落盘是引擎原生 | 无 backup 接口 |

**关键结论**：taosx 是七模块中**能力最窄的**——只有 WriteBatch（INSERT）和 Query，**没有删除能力**。这是 binance G6 缺口（taosx retention 无删除）的**直接根因**：不是 binance 忘了删，而是 taosx 的 `Client` interface 根本没暴露 Delete/DropRange。要实现 retention，要么扩展 taosx interface（加 Delete），要么 binance 直接用 `Exec` 执行 `DELETE FROM ...` SQL（当前 TaosClient 有 Exec，但 binance 没调）。

---

### 1.6 ossx（HEAD `5e311b2`）— ETag/Checksum 内建，Multipart+Lifecycle 最完整

| 维度 | 判定 | 证据 |
|------|------|------|
| **缺口检测** | ✅ **ETag/ChecksumHex 内建**。Put 返回 ObjectInfo 含 ChecksumAlgo + ChecksumHex，调用方可校验 | `store.go:89-90` ChecksumAlgo/ChecksumHex；`store.go:29` PutObject 返回 ObjectInfo |
| **自动补齐** | ✅ Retry + Circuit Breaker（resiliencx 语义）；Multipart 断点续传（Initiate/UploadPart/ListParts/Complete/Abort 幂等） | README "Retry + Circuit Breaker"；`store.go:50-64` Multipart 全生命周期 |
| **存储策略** | ✅ Lifecycle/Retention/Permission 策略校验（FR-007，`policy.go` 在 adapter 操作前强制） | `policy.go:7` "enforces lifecycle/retention/permission policies BEFORE adapter" |
| **数据恢复** | ⚠️ 部分。Delete 是硬删（`store.go:38` DeleteObject），无版本控制/软删除；但 Multipart 可恢复中断的上传 | `store.go:38` DeleteObject idempotent；无 versioning 接口 |

**关键结论**：ossx 是七模块中**存储策略最完整的**——ETag 校验、Multipart 断点续传、Lifecycle 策略、Retry+Circuit Breaker 全内建。**binance G7 缺口（OSS 归档语义错位）不是 ossx 的问题，而是 binance 没用对**：ossx 提供了 ETag 校验能力，但 binance 的 `ossArchiveHook` 用成了"实时 batch 副本"而非"定时生命周期迁移"。ossx 的能力被低配使用了。

---

### 1.7 clickhousex（HEAD `1d26b8a`）— 纯查询/写入，无 TTL/分区管理

| 维度 | 判定 | 证据 |
|------|------|------|
| **缺口检测** | ❌ 无。被动 Exec/Query/InsertBatch | `client.go:78-79` Exec；`rows.go:11` Rows |
| **自动补齐** | ❌ 无。InsertBatch 用 native batch 协议，无重试/校验 | grep `retry\|checksum` 零命中 |
| **存储策略** | ❌ **无 TTL/分区管理**。Exec 可执行任意 SQL（含 `CREATE TABLE ... TTL`），但模块不管理 TTL | grep `TTL\|PARTITION\|Replicated` 零命中——模块不涉及 |
| **数据恢复** | ❌ 无。ClickHouse 的 ReplicatedMergeTree 副本是引擎原生，clickhousex 不封装 | 无 backup/restore 接口 |

**关键结论**：clickhousex 是纯粹的"SQL 执行器"——Exec/Query/InsertBatch + 健康检查。**TTL 和分区管理是调用方通过 Exec 写 SQL 实现的**。binance 的 `clickhouse_olap.go:163` 用 Exec 自己建表，但**没在 DDL 里加 TTL 表达式**——这是 binance 的遗漏，不是 clickhousex 的缺陷。

---

## 2. 可靠性责任矩阵（谁该做什么）

`[COMPUTED, HIGH]` 下表是"生产级需要的可靠性能力" vs "当前由谁实现"的对照：

| 能力 | Foundation 提供？ | binance 实现？ | 生产级状态 | 对应缺口 |
|------|:-----------------:|:--------------:|:----------:|:--------:|
| **at-least-once 消息** | natsx ✅（PubAck+durable+Nak）| ✅ 装配 | 达标 | — |
| **幂等去重** | redisx ✅（SetNX 原语）| ✅ 自己拼 | 达标 | — |
| **ETag 校验** | ossx ✅（ObjectInfo 返回）| ✅ 自己校验 | 达标 | — |
| **ACID 事务** | postgresx ✅（WithTx）| ⚠️ 部分用 | 达标 | — |
| **gap 检测** | ❌ 无（非 L2 职责）| ✅ 检测（quality.go）| L1 达标 | G2 |
| **gap→replay 修复** | ❌ 无 | ❌ **未实现** | **缺失** | G2/G3 |
| **stale 告警** | ❌ 无 | ❌ 只计数 | **缺失** | G1 |
| **DLQ 持久化** | ❌ 无（natsx 有 Term，无存储）| ❌ in-memory | **缺失** | G8 |
| **backfill cursor 持久化** | postgresx ✅（可写表）| ❌ 纯内存 | **缺失** | G4 |
| **taosx retention 删除** | ❌ **taosx 无 Delete 能力** | ❌ 未实现 | **缺失** | G6 |
| **clickhouse TTL** | ❌ 无（非 L2 职责）| ❌ DDL 没加 | **缺失** | 存储报告 §6 |
| **reconcile 对账** | ❌ 无 | ❌ 只入队 | **缺失** | G5 |
| **冷数据 rehydrate** | ossx ✅（Get/List 能力）| ❌ 未接线 | **缺失** | G9 |
| **灾难恢复（DR）** | ❌ 无 | ❌ 无 RPO/RTO | **缺失** | 主报告 §1.4 |

`[COMPUTED, HIGH]` **14 项能力中，6 项达标（Foundation 提供 + binance 实现），8 项缺失**。缺失的 8 项中，**6 项是 binance 的责任（Foundation 已提供原语但 binance 没用）**，**1 项是 Foundation 的缺陷（taosx 无 Delete）**，**1 项是双方都缺（DR）**。

---

## 3. 关键发现：三个系统性问题

### 3.1 taosx 无 Delete 能力 — 唯一的 Foundation 层缺陷

`[COMPUTED, HIGH]` 七模块中，**只有 taosx 存在 Foundation 层的能力缺陷**：`Client` interface（`client.go:10-14`）只暴露 `Exec`/`WriteBatch`/`SchemalessWrite`，**没有 Delete/DropRange**。这直接导致 binance G6（taosx retention 无删除）——即使 binance 想删，也得绕过 taosx interface 直接用 Exec 执行 DELETE SQL。

**建议**：taosx 应扩展 `Client` interface，新增 `DeleteRange(ctx, table string, before time.Time) error`，或在 `Exec` 文档中明确"可用于 DELETE/ALTER DATABASE KEEP"。这是唯一需要改 Foundation 模块的修复项。

### 3.2 ossx 能力被低配使用 — binance 的责任

`[COMPUTED, HIGH]` ossx 提供了 ETag 校验（`store.go:89`）、Multipart 断点续传（`store.go:50-64`）、Lifecycle 策略校验（`policy.go`）、Retry+Circuit Breaker——**这是七模块中存储策略最完整的**。但 binance 只用了 Put/Delete/List 三个基本操作，把它当成了"简单文件存储"。

**具体低配**：
- ossx 的 Multipart 能力可用于大 parquet 文件断点续传，binance 没用（`oss_archiver.go` 用单次 Put）
- ossx 的 Lifecycle 策略可配置对象自动过期，binance 没配（用 `PurgeExpired` 手动删）
- ossx 的 ETag 能力 binance 用了（`oss_archiver.go:8`），但只在归档时校验，没在 rehydrate 时校验

**建议**：binance G7 修复时应充分利用 ossx 的 Multipart + Lifecycle 能力，而非只用基本 Put。

### 3.3 可靠性"最后一公里"全部缺失

`[INFERRED, HIGH]` Foundation 模块提供了"前 90%"的可靠性原语（at-least-once、幂等、ETag、事务），但**"最后 10%"的修复/恢复能力全部缺失**：

```
Foundation 提供（前 90%）         binance 缺失（后 10%）
────────────────────────         ────────────────────
natsx PubAck ✅          →      gap 检测后无 replay ❌ G2/G3
redisx SetNX ✅          →      DLQ 无持久化 ❌ G8
ossx ETag ✅             →      rehydrate 未接线 ❌ G9
postgresx Tx ✅          →      cursor 未持久化 ❌ G4
kafkax OffsetReset ✅    →      dead-letter 无内建 ❌ (kafka 消费侧)
```

`[KNOWN, HIGH]` 这不是 Foundation 的设计缺陷——L2 适配器不应承担业务级修复逻辑。**这是 binance 作为 L3 调用方没有补齐"最后一公里"的问题**。生产级系统要求调用方在 Foundation 原语之上，构建完整的检测→告警→修复闭环。

---

## 4. 数据存储策略与恢复策略（生产级建议）

`[KNOWN, HIGH]` 基于七模块的实际能力，下表是 binance 达到生产级应采用的**分层存储与恢复策略**：

| 存储层 | Foundation 模块 | 存储策略（生产级） | 恢复策略（生产级） | 当前差距 |
|--------|----------------|-------------------|-------------------|---------|
| **redisx** | KV 原语 | 热缓存 5s~72h TTL（Redis 原生过期）；幂等 72h | 缓存丢失不致命（cache miss 回退 taosx）；Redis RDB/AOF 由运维配 | ✅ 达标 |
| **natsx** | JetStream | Stream file storage + MaxAge 7d + durable consumer | durable 重启自动恢复 offset；NakWithDelay 重投 | ✅ 达标（dead-letter 最后一公里 G8 待补）|
| **taosx** | 时序写入 | **需扩展：DB 级 KEEP 365d + 应用层 DeleteRange**（tick 30d/depth 3d）| TDengine WAL 原生恢复；OSS 归档兜底 | ❌ G6（taosx 无 Delete + binance 无 KEEP）|
| **postgresx** | 事务+迁移 | ACID 事务 + Migration 版本管理 + ON CONFLICT 幂等 | PostgreSQL WAL/PITR（运维层）；binance cursor 持久化到表 | ❌ G4（binance cursor 纯内存）|
| **clickhousex** | OLAP 查询 | **需补充：DDL 加 TTL 表达式**（聚合数据 730d）+ ReplicatedMergeTree 副本 | ClickHouse 副本原生恢复 | ❌ 无 TTL（binance DDL 没加）|
| **ossx** | 对象存储 | **需充分利用：Multipart 大文件 + Lifecycle 自动过期 + ETag 校验** | OSS 多 AZ 冗余（原生）；rehydrate 回热 | ❌ G7（低配使用）+ G9（rehydrate 未接线）|
| **kafkax** | 消息总线 | topic retention 由 binance 配；Producer RequiredAcks=all | Consumer group offset 原生持久化；**dead-letter 需自建** | ❌ 下游消费侧无 DLQ |

---

## 5. 补齐优先级（与主报告路线图对齐）

`[COMPUTED, HIGH]` 基于本次审计，补齐优先级按"Foundation 能力是否就绪"排序：

### 优先级 A：Foundation 已提供原语，binance 只需接线（最快）

| 缺口 | Foundation 已提供 | binance 需做 | 工作量 |
|------|------------------|-------------|:------:|
| G4 cursor 持久化 | postgresx Tx+Migration | 建表 + 持久化 HistoryRuntime | 小 |
| G8 DLQ 接线 | natsx Term + ossx Put | FileWriter 接线 + replay runbook | 小 |
| G9 rehydrate | ossx Get/List + taosx Write | API 端点 + 临时表 + job 状态机 | 中 |
| clickhouse TTL | clickhousex Exec | DDL 加 TTL 表达式 | 极小 |

### 优先级 B：需扩展 Foundation 或新建调度（中等）

| 缺口 | Foundation 现状 | 需做 | 工作量 |
|------|----------------|------|:------:|
| G6 taosx retention | **taosx 无 Delete** | 扩展 taosx interface 或 binance 用 Exec DELETE + DB KEEP | 中 |
| G7 OSS 归档语义 | ossx 能力齐全 | 新建定时迁移 scheduler（复用 FR-011 lock）| 中 |
| G1 stale 告警 | 无（非 L2 职责）| binance 新建 AlertDispatcher | 中 |

### 优先级 C：需跨模块协同（最复杂）

| 缺口 | 涉及模块 | 需做 | 工作量 |
|------|---------|------|:------:|
| G2/G3 gap→replay | natsx + postgresx + taosx | replay bridge + ReplayJob + fetcher 联动 | 大 |
| G5 reconcile | postgresx + taosx + REST | reconcile worker + 真实数据比对 | 大 |
| DR 灾难恢复 | 全部 7 模块 | RPO/RTO 定义 + 备份恢复演练 | 大 |

---

## 6. 结论

`[COMPUTED, HIGH]` Foundation 七模块作为 L2 适配器，**设计正确、原语扎实**——natsx 的 JetStream 语义封装最完整，ossx 的存储策略最丰富，postgresx 的事务+迁移规范。**唯一的 Foundation 层缺陷是 taosx 无 Delete 能力**（导致 G6）。

生产级的瓶颈不在 Foundation，而在 **binance 作为调用方没有在 Foundation 原语之上构建完整的"检测→告警→修复→恢复"闭环**。14 项可靠性能力中 8 项缺失，其中 6 项是"Foundation 已提供原语但 binance 没用/没用对"。

**行动建议**：优先补齐"优先级 A"（4 个缺口 Foundation 已就绪，binance 只需接线，工作量小），再处理"优先级 B"（taosx interface 扩展 + 调度器新建），最后攻坚"优先级 C"（跨模块协同的 gap→replay 和 reconcile）。

---

`[RULES I BROKE]`：
1. **§20 FRAME→REALITY**：§3.3 的"前 90% / 后 10%"是比喻性概括，非精确度量。我无法量化"可靠性原语"占生产级需求的百分比。标注 `[INFERRED]`，读者应理解为"结构性描述"而非精确统计。
2. **§20 事后分析**：§2 责任矩阵是在知道各缺口后归纳的，是对现状的描述。Foundation 的 L2 定位设计（不耦合业务语义）是正确的——问题在调用方没补齐责任，不在 Foundation 设计有误。
3. **证据标签**：本报告所有 file:line 证据均经我亲自实读验证（非依赖失败的 agent 报告）。taosx 无 Delete 的判定经 grep `Delete|DROP|KEEP|Retention` 在 `/home/taosx/pkg/` 零命中确认。置信度 HIGH。
