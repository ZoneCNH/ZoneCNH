# fred 数据问题解决报告

- [COMPUTED][HIGH] 日期：2026-06-22。
- [COMPUTED][HIGH] 范围：`module/fred/` 规格文档、`report/fred/` 既有报告、`/home/workspace/fred` 当前实现。
- [COMPUTED][HIGH] 分支：`docs/fred-deep-analysis-20260622`。
- [COMPUTED][HIGH] 输出目标：回答历史数据、实时/实施数据、同步对象、同步周期、数据清洗、数据处理、数据缺口及解决方案。
- [COMPUTED][HIGH] 约束：未读取 `sre/secrets/env/dev.md` 中的密钥值，只按规格引用配置来源。

## 1. 总结判断

[COMPUTED][HIGH] `module/fred/SPEC.md` 已经把目标架构定义为独立 C/S 宏观数据服务，并要求共享基座、`domain_macro` 领域共享层、`taos + kafka + postgres + Redis + oss + nats + clickhouse` 七类持久化职责。  
[COMPUTED][HIGH] `/home/workspace/fred` 当前实现仍是旧骨架：启动注释为 `adapter 零存储`，bootstrap 配置使用 `Stores: bootstrap.None`，未发现 `internal/server`、`internal/domain`、`internal/store`、`StartBackfill`、`QueryObservations`、`ScanRevisions`、`available_at`、`vintage_at` 或 `domain_macro` 的 Go 实现。  
[INFERRED][HIGH] 因此，fred 的核心问题不是再选择更多存储或再扩展 provider，而是先把 FRED 官方数据语义落成可追溯的数据生命周期：原始响应先归档、领域映射显式化、幂等 checkpoint 可恢复、事实可见性使用 `available_at` 防止未来函数、缺口检测可定位并可重放。  
[INFERRED][MED] 在代码未补齐前，模块只能被视为规格完整但运行态未闭环，不能承诺已具备生产级历史回填、实时同步、缺口修复或下游查询能力。

## 2. 官方 FRED 数据语义约束

[KNOWN][HIGH] FRED `series/observations` 支持 `realtime_start`、`realtime_end`、`frequency`、`aggregation_method`、`output_type`、`vintage_dates` 等参数；其中 `output_type=2` 面向所有 vintage date 下的所有观测，`output_type=3` 面向新增或修订观测，`output_type=4` 面向 initial release only。  
[KNOWN][HIGH] FRED `series/vintagedates` 返回某个 series 发生新发布或修订的 vintage dates，并且不包含对该 series 没有数据变化的 release date。  
[KNOWN][HIGH] FRED `releases/dates` 文档说明，数据源发布日不一定等于数据在 FRED 或 ALFRED 上可用的时间。  
[KNOWN][HIGH] FRED `series/updates` 返回最近两周内按 `last_updated` 排序的 series 更新列表。  
[KNOWN][HIGH] FRED real-time period 表达事实在某段时间内被认为真实，默认 real-time period 是当天。  
[KNOWN][HIGH] FRED observation 的 `value` 以字符串保存以降低精度损失风险，缺失值使用 `"."` 表示。

## 3. 历史数据问题与解决方案

| 问题 | 当前风险 | 解决方案 |
| --- | --- | --- |
| [INFERRED][HIGH] 首次历史回填跨度大，容易中断后重复或漏写 | [COMPUTED][HIGH] 规格要求 job/checkpoint/idempotency，但 `/home/workspace/fred` 尚未实现 backfill job 和 checkpoint 存储 | [INFERRED][HIGH] 以 `(series_id, endpoint, params_hash, vintage_date, page_or_window)` 建 checkpoint 和幂等键；每页原始响应先写 OSS，再写 Postgres checkpoint，再进入规范化和时序写入 |
| [KNOWN][HIGH] FRED 有 real-time/vintage/revision 语义 | [INFERRED][HIGH] 只按 observation date 保存会丢失修订历史，导致回测无法复现当时可见数据 | [INFERRED][HIGH] 用 `series/vintagedates` 枚举 revision anchor，用 `series/observations` 的 `realtime_start/realtime_end`、`vintage_dates`、`output_type=2/3/4` 分别支持全量 vintage、增量修订、初值快照 |
| [KNOWN][HIGH] release date 不等于 FRED available time | [INFERRED][HIGH] 若用 release date 直接作为可见时间，会引入 no-lookahead 错误 | [INFERRED][HIGH] `released_at` 只表示数据源发布日或发布窗口，`available_at` 表示 fred 实际观察到或保守推导出的可用时间；所有 as-of 查询必须过滤 `available_at <= as_of` |
| [KNOWN][HIGH] 缺失观测以 `"."` 表示 | [COMPUTED][HIGH] 当前 `/home/workspace/fred/pkg/fredx/client.go` 会跳过 `"."`、空值和解析失败值 | [INFERRED][HIGH] 不应静默丢弃缺失观测；应保存原始字符串、nullable numeric、quality flag 和 skip reason，使缺失是可解释事实而不是数据消失 |
| [INFERRED][MED] series 可能停更、改名、口径变化或被替换 | [INFERRED][MED] 只保留最新 registry 会污染历史解释 | [INFERRED][HIGH] Postgres 维护 series catalog 版本、状态、单位、频率、季调、替代关系；历史观测绑定当时 metadata snapshot 或 metadata_version |

## 4. 实时/实施数据问题与解决方案

[COMPUTED][HIGH] 当前实现只有 `pkg/fredx` provider client、normalizer 和 registry，尚未具备独立 C/S 服务、领域接口、存储端口、队列事件、同步 job 或读模型。  
[COMPUTED][HIGH] 当前边界脚本存在 `no-storage-adapter` gate，仍在阻止 fred 直接接入 ZoneCNH shared storage adapter。  
[INFERRED][HIGH] 解决实时/实施数据问题的第一步是把边界从“零存储 provider adapter”迁移为“独立宏观数据服务”，但存储接入仍必须通过共享基座组件和领域共享层，不应在 fred 内部手写数据库驱动。

推荐实施路径：

1. [INFERRED][HIGH] 用 `configx` 或既有 shared config 读取 `sre/secrets/env/dev.md` 对应 key，不复制密钥值到仓库。
2. [INFERRED][HIGH] 建 `internal/domain` 或等价层承接 `domain_macro` 模型：`MacroSeries`、`MacroObservation`、`MacroRelease`、`MacroRevision`、`MacroIngestJob`。
3. [INFERRED][HIGH] 建 store ports，再通过共享 `taosx/postgresx/redisx/kafkax/natsx/clickhousex/oss` 组件实现 adapter。
4. [INFERRED][HIGH] 把 provider client 的限速、重试、分页、错误分类和 raw archive 纳入 job runner，而不是散落在 HTTP client 内。
5. [INFERRED][HIGH] 对实时增量采用 release-driven trigger + daily catch-up + revision lookback，不依赖单一 `last_updated` 信号。

## 5. 同步对象与同步周期

| 同步对象 | 权威接口或来源 | 周期建议 | 落库/事件目标 |
| --- | --- | --- | --- |
| [KNOWN][HIGH] Series catalog / metadata | FRED series metadata、项目 registry | [INFERRED][MED] 跟踪集每日增量；全量或重点集每周 reconcile | [INFERRED][HIGH] Postgres catalog，Kafka `series.updated`，ClickHouse metadata projection |
| [KNOWN][HIGH] Series updates | FRED `series/updates` | [INFERRED][HIGH] 每日运行；只作为最近两周增量 hint | [INFERRED][HIGH] Postgres sync cursor，Kafka candidate event |
| [KNOWN][HIGH] Release calendar | FRED `releases/dates` 或 release dates | [INFERRED][HIGH] 每日滚动未来 90 天；每月历史 reconcile | [INFERRED][HIGH] Postgres release calendar，NATS 触发手工补偿 |
| [KNOWN][HIGH] Current observations | FRED `series/observations` | [INFERRED][HIGH] release-driven 后延迟抓取；每日 catch-up | [INFERRED][HIGH] OSS raw，Taos observations，Kafka observation events，ClickHouse read model |
| [KNOWN][HIGH] Vintage / revisions | FRED `series/vintagedates` + `series/observations` | [INFERRED][HIGH] release 后 lookback；夜间 7/30/90 天窗口；每月重点 series 全量审计 | [INFERRED][HIGH] Taos revision facts，Postgres revision index，Kafka revision events |
| [INFERRED][HIGH] Raw payload manifests | 每次 provider request | [INFERRED][HIGH] 每次请求立即写入 | [INFERRED][HIGH] OSS raw authority，Postgres manifest/checksum |
| [INFERRED][HIGH] Checkpoints / idempotency | Job runner | [INFERRED][HIGH] 每页、每批、每个 vintage transaction 后更新 | [INFERRED][HIGH] Postgres checkpoint/idempotency table |
| [INFERRED][MED] Read model rebuild | Kafka + Taos + Postgres | [INFERRED][MED] 近实时消费；每日对账；必要时全量重建 | [INFERRED][HIGH] ClickHouse projection，Redis cache 可丢弃重建 |

[INFERRED][HIGH] 初始版本应固定为“每日 catch-up + release-driven job + nightly revision lookback + monthly audit”，等缺口率、API 限速和下游 SLA 有证据后再增加 per-series 自定义周期。

## 6. 数据清洗与数据处理规则

[INFERRED][HIGH] fred 的清洗原则应是 raw-first、lossless-normalization、derived-late，即先保存 provider 原文，再做最小无损规范化，最后在可重建读模型中生成派生视图。  
[INFERRED][HIGH] `value` 必须保留原始字符串，并额外解析为 decimal 或 nullable numeric；`"."`、空值和解析失败必须变成 `quality_status`，不能从事实表中静默删除。  
[INFERRED][HIGH] `date`、`realtime_start`、`realtime_end`、`vintage_at`、`released_at`、`available_at` 应同时存在；其中 `available_at` 是防止未来函数的查询门槛。  
[INFERRED][HIGH] `frequency`、`units`、`seasonal_adjustment`、`aggregation_method` 和 provider query params 应进入 metadata 或 observation context，避免不同频率或口径的数据被混写。  
[COMMON][HIGH] 默认不做插值、前向填充或异常值替换；如需要派生序列，应在 ClickHouse 或独立派生层中显式标记 `derived_from`、`method` 和 `generated_at`。  
[INFERRED][HIGH] 幂等键建议使用 `(series_id, observation_date, realtime_start, realtime_end, vintage_at, units, frequency, provider)`；raw manifest 另用 `(provider, endpoint, params_hash, fetched_at_bucket, checksum)` 去重。  
[INFERRED][HIGH] 清洗失败、单位变化、频率变化、时区异常和超范围值应进入 Postgres gap/quality ledger，并产生可追踪事件，而不是只写日志。

## 7. 数据缺口检测与恢复

### 7.1 缺口分类

| 缺口类型 | 判定方式 | 修复路径 |
| --- | --- | --- |
| [KNOWN][HIGH] Provider missing value | FRED 返回 `"."` | [INFERRED][HIGH] 保存 null observation 和 quality flag，不触发 provider 重抓 |
| [INFERRED][HIGH] Not released yet | release calendar 已知但 provider 暂无新值 | [INFERRED][HIGH] 延迟重试，直到超过 series SLA 后转为 gap |
| [INFERRED][HIGH] Request failed | 无 OSS raw manifest 或 HTTP/API 错误 | [INFERRED][HIGH] 根据 checkpoint 重试 provider request |
| [INFERRED][HIGH] Parse failed | OSS raw 存在但 normalized row 缺失 | [INFERRED][HIGH] 从 OSS raw 重放 parser，不重新请求 provider |
| [INFERRED][HIGH] Store failed | normalized row 存在但 Taos/Kafka/ClickHouse 少写 | [INFERRED][HIGH] 从 Postgres checkpoint 或 Kafka 重放目标 adapter |
| [INFERRED][HIGH] Revision missing | vintage dates 有变化但 revision facts 未覆盖 | [INFERRED][HIGH] 针对 series + vintage window 重跑 revision scan |
| [INFERRED][MED] Deprecated / discontinued | catalog 状态显示停更或长期无新 release | [INFERRED][HIGH] catalog 标记状态，保留历史，不按活跃 series 告警 |

### 7.2 对账规则

[INFERRED][HIGH] 每个 job 完成后应核对四个数量：OSS raw manifest 数、normalized observation 数、Taos 写入数、Kafka event 数。  
[INFERRED][HIGH] 每日批处理应核对 ClickHouse projection 与 Taos/Postgres source-of-record 的行数、最大 observation date、最大 available_at 和 revision count。  
[INFERRED][HIGH] gap ledger 至少应保存 `gap_id`、`series_id`、`period`、`vintage_at`、`gap_type`、`detected_at`、`source_job_id`、`raw_manifest_id`、`repair_status`、`repair_job_id`、`closed_at`。  
[INFERRED][HIGH] Redis 中的 lock、cursor、rate-limit 状态只能作为加速层；若 Redis 丢失，应能从 Postgres checkpoint 和 Kafka/OSS 重建。

## 8. 七类持久化职责边界

| 介质 | fred 中的职责 | 不应承担的职责 |
| --- | --- | --- |
| [INFERRED][HIGH] OSS | 原始响应、manifest、checksum、失败重放来源 | 不做业务查询主库 |
| [INFERRED][HIGH] Postgres | catalog、job、checkpoint、idempotency、gap ledger、release calendar | 不承载高频时序扫描 |
| [INFERRED][HIGH] Taos | 规范化宏观时序事实、revision facts | 不保存不可解释的派生填充值 |
| [INFERRED][HIGH] Kafka | observation/revision/catalog 的 durable event log | 不做同步控制命令通道 |
| [INFERRED][HIGH] Redis | rate limit、hot cache、lock、cursor cache | 不做权威 checkpoint 或事实库 |
| [INFERRED][HIGH] NATS | 手工补偿、rebuild、job control、轻量控制消息 | 不做 durable data event log |
| [INFERRED][HIGH] ClickHouse | 查询投影、对账分析、宽表 read model | 不做不可重建的唯一权威 |

## 9. 推荐实施顺序

1. [INFERRED][HIGH] 先迁移边界：保留 shared base 约束，删除或改造阻止存储接入的旧 `no-storage-adapter` 规则，新增禁止手写驱动和禁止泄漏密钥的 gate。
2. [INFERRED][HIGH] 补 `domain_macro` 映射：明确 `released_at`、`available_at`、`vintage_at`、`realtime_start`、`realtime_end` 和 quality fields。
3. [INFERRED][HIGH] 补 raw archive + checkpoint + idempotency：没有 OSS raw 和 Postgres checkpoint 前，不进入大规模历史回填。
4. [INFERRED][HIGH] 补缺失值和修订 fixture：覆盖 `"."`、空值、单位变化、频率变化、revision-only、initial-release-only、as-of no-lookahead。
5. [INFERRED][HIGH] 分阶段接入 Taos、Kafka、ClickHouse、Redis、NATS：先保证事实写入和 durable event，再加 read model、cache 和 control plane。
6. [INFERRED][HIGH] 最后跑 acceptance：把 `module/fred/ACCEPTANCE.md` 中 pending 的 V-005 至 V-010 转成实际证据。

## 10. 验收证据建议

[COMPUTED][HIGH] 当前 `module/fred/ACCEPTANCE.md` 中运行态验收仍是 Pending。  
[INFERRED][HIGH] 下列命令或等价命令应成为补齐后的最小验收证据：

```bash
go test ./pkg/fredx/...
go test ./internal/domain/... -run 'MissingValue|NoLookahead|Vintage'
go test ./internal/server/... -run 'Backfill|Checkpoint|Idempotency|Gap'
go test ./internal/store/... -run 'RawArchive|TaosWrite|KafkaEvent|ClickHouseProjection'
FRED_DEV_CONFIG=sre/secrets/env/dev.md go test ./internal/integration/... -run 'DevInfra|EndToEnd'
bash scripts/boundary-gates.sh
```

[INFERRED][HIGH] 验收通过标准应包括：raw payload 可从 OSS 重放、Postgres checkpoint 可恢复中断任务、Taos 与 ClickHouse 对账一致、Kafka event 与写入事实一一对应、Redis 丢失后可重建、NATS 控制命令不会替代 Kafka durable event、所有 as-of 查询强制 `available_at <= as_of`。

## 11. 剩余风险

[COMPUTED][HIGH] 本报告未运行 `/home/workspace/fred` 的集成环境，也未读取开发密钥值。  
[COMPUTED][HIGH] 本报告只验证了本地文档、当前源码结构和 FRED 官方 API 文档语义。  
[INFERRED][MED] 最大实施风险是把 FRED release calendar 误当成可用时间；该风险会直接破坏回测的 no-lookahead 保证。  
[INFERRED][MED] 第二风险是继续静默丢弃 `"."`、解析失败和异常值；该风险会把 provider 缺失误报为 fred 自身缺口已修复。  
[INFERRED][MED] 第三风险是 ClickHouse 或 Redis 被误当成权威事实库；该风险会导致 rebuild 后数据不一致且无法追责。

## 12. 证据来源

- [COMPUTED][HIGH] 本地规格：`module/fred/SPEC.md`、`module/fred/IMPLEMENTATION-PLAN.md`、`module/fred/ACCEPTANCE.md`。
- [COMPUTED][HIGH] 既有报告：`report/fred/deep-analysis-20260622.md`、`report/fred/structural-score-20260622.md`。
- [COMPUTED][HIGH] 当前实现：`/home/workspace/fred/cmd/fred-server/main.go`、`/home/workspace/fred/pkg/fredx/client.go`、`/home/workspace/fred/pkg/fredx/normalizer.go`、`/home/workspace/fred/pkg/fredx/registry.go`、`/home/workspace/fred/scripts/boundary-gates.sh`、`/home/workspace/fred/go.mod`。
- [KNOWN][HIGH] FRED `series/observations`：<https://fred.stlouisfed.org/docs/api/fred/series_observations.html>。
- [KNOWN][HIGH] FRED `series/vintagedates`：<https://fred.stlouisfed.org/docs/api/fred/series_vintagedates.html>。
- [KNOWN][HIGH] FRED `releases/dates`：<https://fred.stlouisfed.org/docs/api/fred/releases_dates.html>。
- [KNOWN][HIGH] FRED `series/updates`：<https://fred.stlouisfed.org/docs/api/fred/series_updates.html>。
- [KNOWN][HIGH] FRED real-time period：<https://fred.stlouisfed.org/docs/api/fred/realtime_period.html>。
- [KNOWN][HIGH] FRED release observations value semantics：<https://fred.stlouisfed.org/docs/api/fred/v2/release_observations.html>。

[RULES I BROKE]：无
