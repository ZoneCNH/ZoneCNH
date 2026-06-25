# 数据存储链路成熟度评估（分报告）

- Report-ID: binance-data-maturity-storage-20260625
- 所属主报告：[`data-maturity-assessment-20260625.md`](data-maturity-assessment-20260625.md) §3 数据存储行
- Runtime-Anchor：`/home/binance@3f20be0`
- 评估日期：2026-06-25
- 范围：FR-005（幂等）/ FR-006a~d（taos/pg/redis/oss 四层存储）/ FR-007/007a（API）/ FR-010（clickhouse OLAP）/ FR-011（分布式锁）/ FR-018（归档 manifest）

> [COMPUTED, HIGH] 本报告所有缺口声明经 Explore agent 在 runtime `/home/binance` 逐条 file:line 核查。规格参数来自 `module/binance/SPEC.md` §11 Config 实读。

---

## 1. 链路成熟度评分（SLA 四维）

| 维度 | 得分 | 级别 | 依据 |
|------|:----:|:----:|------|
| **Freshness** | **1.5** | **L1+** | G0 存储装配闭合（PR #101）；写入延迟达标 |
| **Completeness** | **1.0** | **L1** | 四层存储写入路径齐全；归档完整性有缺口（G7）|
| **Durability** | **0.8** | **L1-** | taosx retention 无删除（G6）；OSS 语义错位（G7）|
| **Consistency** | **1.5** | **L1+** | 幂等 SetNX 扎实；跨层一致性无对账（依赖历史 G5）|
| **加权** | **1.2** | **预生产** | 有基础设施，缺生命周期治理 |

`[COMPUTED, HIGH]` **存储链路是"基础设施齐全但生命周期管理空白"**。G0 存储装配断层在 PR #101（`245b31c` "5/5 infra + Kafka + mainnet 全部 LIVE-PASS，G0 端到端完全闭合"）后已闭合——四层存储（redis/taos/pg/oss）+ clickhouse + kafka 都能真实写入。但**数据写进去之后怎么管理（过期、归档、回热）几乎是空白**。

---

## 2. 缺口详析

### 2.1 G6：taosx retention 无删除（P0，Durability）

**规格要求**（SPEC §11.2.4）：
- `taos.retention.ticks` = `720h`（30d）
- `taos.retention.bars` = `8760h`（365d）
- `taos.retention.depth` = `72h`（3d）

**runtime 实证**：
- grep `internal/server/storage` 下 `retention|Retention|DropRange|DeleteRange|DROP|DELETE|prune|TTL`：唯一命中是 `oss_archiver.go:51-146`（OSS 冷存 `Retention`/`PurgeExpired`），**针对 OSS 对象，与 taosx 热数据无关**。
- `internal/server/storage/taos_writer.go`：grep `[Dd]elete|[Dd]rop|Remove|retention` **零命中**。`TaosClient` 接口（:28-29）只暴露 `Exec`/`WriteBatch`，**无删除能力**；`Write`/`ensureStables` 只 CREATE+INSERT。
- `migrations/taos_ddl.sql:20` `CREATE DATABASE IF NOT EXISTS binance;` —— **无 `KEEP`/`DAYS`/`RETENTIONS` 子句**，即数据库层也未配置保留期。
- 全仓搜 `720h|8760h|72h` 仅命中 `cmd/binance-server/storage_env.go:175`（idempotency TTL，与 taosx 无关）。

`[COMPUTED, HIGH]` **判定：L0（零实现）**。720h tick / 8760h bar / 72h depth 的热数据保留期**既无应用层删除，也无 DB 层 KEEP 配置**。SPEC §11.2.4 定义的三个配置键在 runtime 无任何消费方。

**生产级影响**：
- **磁盘只增不减**。tick 数据高频写入，30d 后 taosx 数据量持续膨胀，最终撑爆磁盘。
- 无 retention 意味着无法控制 taosx 的查询性能——数据量增长后，时间范围查询越来越慢。
- 与 OSS 归档（G7）断裂：即使归档到 OSS，taosx 热数据也不删，冷热数据并存。

`[KNOWN, HIGH]` **TDengine 的正确做法**：TDengine 原生支持库级 `KEEP` 参数（`CREATE DATABASE ... KEEP 30 DURATION 10`，KEEP=保留天数）。binance 应在 DDL 层配置 KEEP，而非应用层手动删——这比手动 DELETE 更安全、更高效（TDengine 自动淘汰过期文件块）。

### 2.2 G7：OSS 归档语义错位（P1，Durability）

**规格要求**（SPEC §11.2.7 / FR-006d / AC-026~028）：
- `oss.archiver.schedule` = `0 3 * * *`（**每日 03:00 UTC 定时归档**）
- archiver 扫描到超过 retention cutoff 的数据 → 归档 OSS → ETag 校验 → 删 taosx 热数据
- ticks_cutoff `720h`（30d）、bars_cutoff `2160h`（90d）

**runtime 实证**：
- `cmd/binance-server/storage_env.go:241` — OSS 归档实际装配为：
  ```go
  ossHook := newOssArchiveHook(archiver, 500, 30*time.Second) // 攒批 500 条或 30s flush
  ```
  这是一个 **per-event batch hook**（每接受一个事件就攒批，攒满 500 或 30s 到就写 OSS），**不是定时归档调度**。
- `ossArchiveHook`（`storage_env.go:323-400`）经 `PostAcceptHooks` 注入，**每个被接受的事件实时触发**归档。
- 无 `0 3 * * *` cron 调度器；无"扫描 taosx 超 retention 数据 → 迁移 OSS → 删热"逻辑。
- `oss_archiver.go:139` `PurgeExpired` 删过期 OSS 对象（30d），**但没有任何定时器调用它**。

`[COMPUTED, HIGH]` **判定：L1（语义错位）**。runtime 实现的是"实时冷备份"（每个事件同时写 taosx + OSS），SPEC 定义的是"定时生命周期迁移"（热数据超期后搬冷 + 删热）。两者**不是同一件事**。

**语义差异详解**：

| 维度 | SPEC 意图（定时迁移） | runtime 实现（实时 batch） |
|------|---------------------|--------------------------|
| 触发 | 每日 03:00 UTC cron | 每个事件 accept 时 |
| 数据流 | taosx 热数据 → 超期 → 迁移 OSS → 删 taosx | 事件 → 同时写 taosx + OSS |
| taosx 删除 | 归档后删热（控制 taosx 体积）| **不删**（taosx 只增不减）|
| OSS 角色 | 冷归档（超期数据才能查） | 实时副本（与 taosx 数据重叠）|
| 带宽 | 每日批量 | 实时持续 |

`[INFERRED, HIGH]` runtime 的实现实际上**比 SPEC 意图更安全**（实时冷备份，数据冗余更高），但**违背了"控制 taosx 体积"的核心目标**——因为不删热数据。正确的生产级做法是**两者结合**：实时 batch 备份（当前）+ 定时迁移删热（SPEC 意图）。

### 2.3 G9：冷数据 rehydrate 未接线（P1，Durability）

> 此缺口与[历史分报告 §2.4](data-maturity-history-20260625.md) 是同一断点。rehydrate 代码已实现（`oss_rehydrate.go`），但未接入 API 查询路径。此处从存储视角补充。

**存储视角实证**：
- `internal/server/storage/oss_rehydrate.go:44-60` — `Rehydrate(ctx, reader, writer, pl, et, from, to, cfg)` 签名完整，读 OSS NDJSON → 写回 StorageWriter（taosx）。
- **未接线的存储层影响**：冷数据回热需要 taosx 临时表 + 24h TTL。runtime 的 `TaosClient` 接口无临时表 / TTL 表达式能力，`migrations/taos_ddl.sql` 也无临时表 DDL。
- OSS 对象路径格式 `{prefix}/{pl}/{et}/{YYYY}/{MM}/{DD}/{batchID}.jsonl`（`oss_archiver.go:198`），rehydrate 需按此格式 List+Get，但无 admin endpoint 触发。

`[COMPUTED, HIGH]` **判定：L0（存储层未接线）**。rehydrate 代码存在但存储层缺少配套（临时表机制、admin 触发点）。

---

## 3. 四层存储生命周期全景

`[KNOWN, HIGH]` binance 的四层存储应有清晰的生命周期分工。当前状态：

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 1: redisx（热缓存 + 幂等）                                 │
│  生命周期: 5s(depth) / 60s(tick) / 72h(idempotency)              │
│  删除机制: ✅ Redis TTL 自动过期                                   │
│  状态: 生产级 ✅                                                   │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: taosx（热时序存储）                                      │
│  规格: tick 30d / bar 365d / depth 3d                            │
│  删除机制: ❌ 无应用层删除，无 DB KEEP 配置（G6）                  │
│  状态: 🔴 数据只增不减，磁盘终将撑爆                               │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3: clickhousex（OLAP 分析）                                │
│  规格: 聚合数据（1m_ohlcv/5m_vwap/15m_stats）长期保留              │
│  删除机制: ❌ 无 TTL 表达式，无清理                                │
│  状态: 🟡 聚合数据增长较慢，但无上限                               │
├─────────────────────────────────────────────────────────────────┤
│  Layer 4: ossx（冷归档）                                          │
│  规格: 长期保留 + 定时归档 + ETag 校验后删热                      │
│  删除机制: ✅ PurgeExpired（30d）                                  │
│  状态: 🟡 归档方式错位（G7，实时 batch 而非定时迁移）              │
└─────────────────────────────────────────────────────────────────┘
```

`[COMPUTED, HIGH]` **四层中只有 redis（TTL）和 oss（PurgeExpired）有删除机制。taosx 和 clickhousex 的生命周期完全空白**——这是生产级存储系统的核心隐患。

---

## 4. 补齐方案（生产级）

### 4.1 G6：taosx retention——DB 层 KEEP + 应用层兜底（P0）

`[KNOWN, HIGH]` TDengine 的 retention 最佳实践是**库级 KEEP 参数**（自动淘汰），而非应用层 DELETE（低效且有锁风险）。

**设计**：双层 retention。

```text
Layer A（推荐，主）：DB 级 KEEP 配置
  ALTER DATABASE binance KEEP 365;  -- bar 保留 365d（最大值决定 KEEP）
  -- TDengine 自动淘汰超 KEEP 的文件块，无需应用层干预
  -- 注：TDengine 单库 KEEP 对所有超级表统一，无法 per-table 设置
  -- 因此取最大值 365d（bar），tick/depth 用应用层补充删除

Layer B（补充）：应用层 per-table 精细删除
  新增 internal/server/storage/taos_retention.go：
    定时任务（复用 FR-011 coordinator lock，避免多实例重复删）
      ├─ tick: DELETE FROM binance_tick WHERE ts < now - 30d
      └─ depth: DELETE FROM binance_depth WHERE ts < now - 3d
    （bar 由 DB KEEP 365d 兜底，不需应用层删）
```

**改动点**：
- `migrations/taos_ddl.sql`：`CREATE DATABASE` 加 `KEEP 365`（或新建 migration 009 ALTER）
- 新增 `internal/server/storage/taos_retention.go`：定时删除任务
- `cmd/binance-server/main.go`：装配 retention scheduler（复用 coordinator lock FR-011）
- `TaosClient` 接口扩展 `DeleteRange(ctx, table, before time.Time)` 能力

**删除安全**：`[KNOWN, HIGH]` 删除前必须确认 OSS 已归档 + ETag 校验通过（SPEC FR-006d AC-027 已定义"先写冷再删热"）。G6 的应用层删除应**在 G7 归档成功后**才执行。

**验收**：tick 数据 30d 后自动从 taosx 消失（DB KEEP 或应用层删）；磁盘占用稳定不膨胀。

### 4.2 G7：OSS 归档——实时备份 + 定时迁移双路径（P1）

`[COMPUTED, HIGH]` 保留 runtime 当前的实时 batch 备份（更安全），**新增**定时迁移路径（控制 taosx 体积）。两者互补。

**设计**：

```text
Path A（保留，实时冷备份）：
  当前 ossArchiveHook（30s batch）继续运行
  每个 accept 事件同时写 taosx + OSS（实时冗余）

Path B（新增，定时生命周期迁移）：
  新增 internal/server/storage/oss_lifecycle_scheduler.go：
    每日 03:00 UTC（coordinator 持锁实例执行）
      ├─ 扫描 taosx：SELECT distinct symbol FROM binance_tick WHERE ts < now - 30d
      ├─ 校验 OSS 已有对应归档（Rehydrate.Read 可读）
      ├─ 校验 ETag（oss_archiver.go 已有校验逻辑）
      ├─ 删 taosx 超期热数据（触发 G6 应用层删除）
      └─ 记录 manifest（FR-018 archive_manifest.go 已有 RecordArchive）
```

**改动点**：
- 新增 `internal/server/storage/oss_lifecycle_scheduler.go`：定时迁移
- 复用 `archive_manifest.go`（FR-018 已实现 `RecordArchive`/`IsArchived`）记录迁移
- 复用 FR-011 coordinator lock 确保单实例执行
- cron 表达式从 config 读取（`oss.archiver.schedule` 默认 `0 3 * * *`，SPEC §11.2.7 已定义）

**与 G6 协同**：`[COMPUTED, HIGH]` G7 的定时迁移成功（OSS ETag 校验通过）后，触发 G6 的 taosx 删除。顺序严格：**先归档校验 → 后删热**。

**验收**：03:00 UTC 自动扫描超期数据；OSS ETag 校验通过后删 taosx；manifest 记录迁移历史。

### 4.3 G9：rehydrate 接线（P1）

> 详细方案见[历史分报告 §4.4](data-maturity-history-20260625.md)。存储层补充：

**存储层改动**：
- `migrations/`：新增临时表 DDL（`binance_tick_rehydrated`，24h TTL）
- TDengine 临时表可用 `KEEP 1`（1 天）的独立库或表级 TTL
- `TaosClient` 接口：新增 `WriteToTempTable` / `QueryTempTable` 能力
- rehydrate 完成后，临时表数据供 API 查询；24h 后自动过期

**验收**：见历史分报告 §4.4。

---

## 5. 存储链路生产级标准化清单

`[KNOWN, HIGH]` 存储链路达到生产级必须满足（除补齐 3 个缺口外）：

| 标准项 | 要求 | 当前 |
|--------|------|------|
| **四层存储写入** | redis/taos/pg/ch/oss 均可写 | ✅ G0 闭合（PR #101）|
| **幂等去重** | redisx SetNX 72h | ✅ FR-005 Done |
| **taosx retention** | tick 30d / bar 365d / depth 3d 自动过期 | ❌ G6 |
| **clickhousex TTL** | 聚合数据有上限 | ❌ 无 TTL |
| **OSS 归档完整性** | ETag 校验 + 删热 + manifest | 🟡 部分（G7）|
| **归档可恢复** | OSS → taosx rehydrate | ❌ G9 未接线 |
| **manifest 审计** | 归档对象可校验 checksum/row_count | ✅ FR-018 Done |
| **分布式锁** | coordinator HA + lease | ✅ FR-011（Partial，装配待确认）|
| **存储故障降级** | 单层失败不阻塞其他层 | ✅ SPEC §12 错误处理已定义 |
| **磁盘容量告警** | 各层占用超阈值告警 | ❌ 无（阶段三）|

---

## 6. clickhousex TTL 补充建议（P2）

`[COMPUTED, HIGH]` 本报告聚焦 G6/G7/G9 三个已确认缺口。clickhousex 的 TTL 是一个**未在 SPEC 明确定义但生产级必需**的补充项：

- `clickhouse_olap.go` 的 ETL 持续写入聚合数据（1m_ohlcv/5m_vwap/15m_stats），**无 TTL 表达式**，数据无限增长。
- ClickHouse 原生支持表级 TTL：`CREATE TABLE ... TTL ts + INTERVAL 730 DAY`。
- 建议：OLAP 聚合数据保留 2 年（730d），通过 DDL TTL 自动过期。
- 这不属于当前 9 个缺口，但应在阶段三"规模化规范化"中补齐。

---

## 7. 与其他链路的协同

`[COMPUTED, HIGH]` 存储链路的补齐与其他分报告协同：

| 本链路缺口 | 协同链路 | 协同点 |
|-----------|---------|--------|
| G6（taosx 删除）| [历史 G5](data-maturity-history-20260625.md) | reconcile 需查询 taosx，删除前需确认对账无缺失 |
| G7（OSS 定时迁移）| [历史 G9](data-maturity-history-20260625.md) | 迁移后的冷数据需可 rehydrate 才有价值 |
| G7（OSS 定时迁移）| [实时 G8](data-maturity-realtime-20260625.md) | DLQ FileWriter 的死信也应纳入 OSS 归档（跨磁盘安全）|
| G6+G7 删除顺序 | — | **严格：G7 OSS 归档 + ETag 校验 → 成功后才 G6 删 taosx** |

---

`[RULES I BROKE]`：
1. **§20 FRAME→REALITY**：§4.1 的"TDengine 库级 KEEP"是 `[KNOWN]` 最佳实践（TDengine 官方文档），但 binance 的 `TaosClient` 接口当前无 ALTER DATABASE 能力，需实现时验证 adapter 支持。置信度 HIGH（TDengine 原生支持）。
2. **§20 事后分析**：§3 的四层生命周期图是对现状描述。G0 闭合（PR #101）是 git log 实证，与 retention 空白是独立事实——装配成功 ≠ 生命周期管理完善。
3. **§20 推断标注**：§4.2 "runtime 实时 batch 比 SPEC 意图更安全"是 `[INFERRED, HIGH]`——实时冗余确实更高，但"更安全"依赖 OSS 写入成功的假设（若 OSS 写失败而 taosx 成功，batch 备份形同虚设）。标注为推断而非定论。
