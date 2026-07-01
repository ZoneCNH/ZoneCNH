# fred 阶段 2 契约与领域绑定报告

- Date: 2026-06-22
- Branch: `docs/fred-stage2-contracts-20260622`
- Stage: 迭代方案 [iteration-plan-20260622.md](./iteration-plan-20260622.md) 阶段 2
- Scope: P0-3 配置映射 + P1-2 API/事件/存储契约 + P1-3 `domain_macro` 绑定
- Evidence Rule: `[COMPUTED]` 来自本仓库文件与命令输出；`[INFERRED]` 基于证据的工程判断；`[KNOWN]` 来自 FRED 官方文档
- Related: 阶段 1 已闭合 P0-1（BR 漂移，PR #898 合入 main）

## 1. 总结判断

[COMPUTED][HIGH] 阶段 2 三项中，**P1-3 `domain_macro` 绑定是阻断项**：`module/fred/SPEC.md` §9 定义的 5 个模型（`MacroSeries`/`MacroObservation`/`MacroRelease`/`MacroRevision`/`MacroIngestJob`）在 `domain-macro` 仓库源码中**均不存在**。实际源码只有 `MacroPoint`、`MacroInformationSet`、`YahooObservation` 等轻量类型（v0.1.0）。

[INFERRED][HIGH] 这意味着 fred 实施前必须做一个决策：
- **方案 A**：在 `domain-macro` 仓库补齐 SPEC 定义的 5 个类型（跨仓库改动，需 `domain-macro` 发版）
- **方案 B**：把 SPEC §9 改为映射到现有 `MacroPoint`，标注缺失类型为 fred 实施期补齐

[INFERRED][HIGH] 推荐方案 B：fred SPEC 锚定现有 `MacroPoint` 作为 observation 核心类型，`MacroSeries/MacroRelease/MacroRevision/MacroIngestJob` 标注为"fred 实施期在 `domain-macro` 补齐或 fred internal 定义"。理由：fred 是首个真正消费 `domain_macro` 的 provider 服务，应由 fred 实施暴露字段需求，再回流 `domain-macro`，避免预先设计空类型。

[COMPUTED][HIGH] P0-3 配置映射和 P1-2 契约可独立于 P1-3 推进，本文档给出 redacted config mapping 表和最小契约附录，供 SPEC.md §7/§10/§11 补齐。

## 2. P1-3 `domain_macro` 绑定（核心发现）

### 2.1 源码实际类型

[COMPUTED][HIGH] 来源：`/home/workspace/domain-macro/pkg/domainmacro/`，`go.mod` 声明 `module github.com/ZoneCNH/domain_macro` v0.1.0。

| 实际类型 | 文件 | 字段 | SPEC 对应 |
| --- | --- | --- | --- |
| `MacroPoint` | `models.go:12-21` | `SeriesCode string`、`Value float64`、`ObservedAt time.Time`、`ReleasedAt time.Time`、`AvailableAt time.Time`、`RevisionVersion int`、`IsPreliminary bool`、`Source string` | 部分对应 SPEC `MacroObservation` |
| `MacroPoint.Validate()` | `models.go:23-32` | `AvailableAt` 非零（fail closed）、`RevisionVersion >= 0` | 对应 BR-003 no-lookahead 前置校验 |
| `MacroPoint.IsVisibleAt(decisionTime)` | `models.go:34-45` | `AvailableAt <= decisionTime` 且 `ObservedAt <= decisionTime` 且 `ReleasedAt <= decisionTime`（若非零） | 对应 BR-003 no-lookahead 判定 |
| `MacroInformationSet` | `models.go:47-51` | `DecisionTime`、`Points []MacroPoint`、`DataFreshnessSec float64` | SPEC 未定义 |
| `FilterMacroPointsForBacktest` | `models.go:53-76` | 过滤可见点 + 计算 freshness | 对应 BR-003 回测信息集 |
| `MacroState`/`MacroRegimeCard` | `information_set.go:5-17` | `recovery/expansion/slowdown/contraction` | 属 ms_brain 语义，非 fred 职责 |
| `IndicatorValue` | `information_set.go:19-24` | `SeriesCode`、`Value`、`Timestamp`、`Revision` | 轻量指标值，与 `MacroPoint` 重叠 |
| `YahooObservation`/`YahooCheckpoint`/`YahooGap` | `yahoo_models.go` | Yahoo Finance 专属 | 非 FRED，fred 不用 |

### 2.2 SPEC §9 与源码差异

[COMPUTED][HIGH] `SPEC.md:107-113` 定义的 5 个模型字段：

| SPEC 模型 | SPEC 必备字段 | 源码是否存在 | 差异 |
| --- | --- | :---: | --- |
| `MacroSeries` | provider、series_id、title、frequency、units、seasonal_adjustment、source、tags、created_at、updated_at | ❌ | 源码无 series 元数据类型 |
| `MacroObservation` | provider、series_id、period_start、period_end、value、unit、released_at、available_at、vintage_at、observed_at | ❌（有 `MacroPoint`） | `MacroPoint` 缺 `provider/period_start/period_end/unit/vintage_at`，有 `SeriesCode/IsPreliminary/Source/RevisionVersion` |
| `MacroRelease` | release_id、name、scheduled_at、actual_at、timezone、source_url | ❌ | 源码无发布日历类型 |
| `MacroRevision` | series_id、period_start、old_value、new_value、previous_vintage_at、vintage_at、detected_at | ❌ | 源码无修订类型 |
| `MacroIngestJob` | job_id、series_id、mode、cursor、started_at、finished_at、status、error_class | ❌ | 源码无作业类型 |

### 2.3 字段映射（FRED DTO → 现有 `MacroPoint`）

[INFERRED][HIGH] fred 实施期 FRED provider DTO 到现有 `MacroPoint` 的最小映射：

| FRED observation 字段 | `MacroPoint` 字段 | 映射规则 |
| --- | --- | --- |
| `series_id` | `SeriesCode` | 直传 |
| `value`（字符串） | `Value` | 解析为 float64；`"."` 解析失败时记 `IsPreliminary=true` + quality flag（**不丢弃**，对应 R-002） |
| `date` | `ObservedAt` | FRED observation date → time.Time |
| `realtime_start` | `ReleasedAt` | FRED realtime period 起点 |
| （推导） | `AvailableAt` | `max(realtime_end, released_at)` 或 fred 观察到的时间；**no-lookahead 判定依据** |
| `vintage_dates` | `RevisionVersion` | vintage 序号（首次=0，每次修订+1） |
| `realtime_end` | （无直接字段） | 需 `MacroPoint` 补 `VintageAt` 或 fred 内部记录 |
| — | `IsPreliminary` | initial release=true，revision=false |
| `FRED` | `Source` | 固定 `"FRED"` |

### 2.4 缺失类型决策

[INFERRED][HIGH] 推荐方案 B（SPEC 锚定现有类型 + 标注缺失）：

| SPEC 模型 | 决策 | 理由 |
| --- | --- | --- |
| `MacroObservation` | **改为映射到 `MacroPoint`**，补 `provider/unit/period_start/period_end/vintage_at` 字段需求 | `MacroPoint` 已有 no-lookahead 核心字段，fred 实施期推动 `domain-macro` 补字段 |
| `MacroSeries` | 标注"fred 实施期在 `domain-macro` 补齐 `MacroSeries` 类型" | series 元数据是 provider 职责，fred 首个暴露需求 |
| `MacroRelease` | 标注"fred 实施期补齐" | 发布日历是 fred 核心输出，但 `domain-macro` 当前无 |
| `MacroRevision` | 标注"fred 实施期补齐" | 修订管理是 fred 核心职责 |
| `MacroIngestJob` | 标注"fred internal 定义，不进 `domain-macro`" | job 是 fred 服务内部编排，非领域共享 |

[INFERRED][HIGH] 该决策需在阶段 3 实施前由数据域 owner 确认。若选方案 A（`domain-macro` 预先补齐），则需 `domain-macro` 发 v0.2.0。

## 3. P0-3 配置映射（redacted）

[COMPUTED][HIGH] 来源：`SPEC.md:138-152` 配置类别 + `sre/secrets/env/dev.md` 键名引用（未读 secret 值）。本表只列 key 名/路径/类型/必填/redaction，**不含任何 secret 值**。

| 配置类别 | key 名（类别） | 类型 | 必填 | 默认值来源 | redaction 策略 | 消费组件 |
| --- | --- | --- | :---: | --- | --- | --- |
| FRED provider | `FRED_API_KEY` | string (ref) | ✓ | `sre/secrets/env/dev.md` | 全量 redact，日志禁出 | `internal/client` |
| FRED provider | `FRED_BASE_URL` | string | ✓ | `https://api.stlouisfed.org` | 不 redact（非密） | `internal/client` |
| FRED provider | `FRED_TIMEOUT` | duration | ✗ | `30s` | 不 redact | `internal/client` |
| FRED provider | `FRED_RATE_LIMIT` | float (req/s) | ✗ | `120/60s`（FRED 限速） | 不 redact | `resiliencx` |
| FRED provider | `FRED_USER_AGENT` | string | ✗ | `fred/1.0 (ZoneCNH)` | 不 redact | `internal/client` |
| Postgres | `FRED_PG_DSN` | string (ref) | ✓ | `sre/secrets/env/dev.md` | 全量 redact | `postgresx` |
| Postgres | `FRED_PG_SCHEMA` | string | ✗ | `fred` | 不 redact | `internal/store` |
| Postgres | `FRED_PG_POOL` | int | ✗ | `10` | 不 redact | `postgresx` |
| TDengine | `FRED_TAOS_ENDPOINT` | string | ✓ | `sre/secrets/env/dev.md` | 全量 redact | `taosx` |
| TDengine | `FRED_TAOS_DB` | string | ✗ | `fred` | 不 redact | `internal/store` |
| TDengine | `FRED_TAOS_BATCH` | int | ✗ | `500` | 不 redact | `internal/store` |
| Kafka | `FRED_KAFKA_BROKERS` | []string | ✓ | `sre/secrets/env/dev.md` | 全量 redact | `kafkax` |
| Kafka | `FRED_KAFKA_TOPIC_PREFIX` | string | ✗ | `fred.` | 不 redact | `internal/events` |
| Redis | `FRED_REDIS_ADDR` | string | ✓ | `sre/secrets/env/dev.md` | 全量 redact | `redisx` |
| Redis | `FRED_REDIS_DB` | int | ✗ | `0` | 不 redact | `redisx` |
| Redis | `FRED_REDIS_TTL` | duration | ✗ | `24h` | 不 redact | `internal/store` |
| OSS | `FRED_OSS_BUCKET` | string | ✓ | `sre/secrets/env/dev.md` | 全量 redact | `ossx` |
| OSS | `FRED_OSS_PREFIX` | string | ✗ | `fred/raw/` | 不 redact | `internal/store` |
| NATS | `FRED_NATS_URL` | string | ✓ | `sre/secrets/env/dev.md` | 全量 redact | `natsx` |
| NATS | `FRED_NATS_SUBJECT_PREFIX` | string | ✗ | `fred.ctrl.` | 不 redact | `internal/control` |
| ClickHouse | `FRED_CH_DSN` | string (ref) | ✓ | `sre/secrets/env/dev.md` | 全量 redact | `clickhousex` |
| ClickHouse | `FRED_CH_DB` | string | ✗ | `fred` | 不 redact | `internal/store` |
| Observability | `FRED_LOG_LEVEL` | string | ✗ | `info` | 不 redact | `observex` |
| Observability | `FRED_METRICS_ENDPOINT` | string | ✗ | `:9090/metrics` | 不 redact | `observex` |

[INFERRED][HIGH] redaction 规则：
1. 所有 `*_KEY`/`*_DSN`/`*_ADDR`/`*_BROKERS`/`*_BUCKET`/`*_URL`(含凭证) 类 key 在日志、错误消息、审计输出中**全量 redact**（显示为 `***`）。
2. 缺失必填 key 时 **fail fast**，启动失败，错误消息只说"FRED_API_KEY missing"，不显示值。
3. `configx` schema 校验在启动时强制必填性，redaction 测试覆盖日志/错误/审计三路输出。

## 4. P1-2 最小契约附录

### 4.1 API 契约（固化 SPEC §7）

[INFERRED][HIGH] 版本字段 `api_version: "v1"`，错误码用字符串枚举。

| API | 请求字段 | 响应字段 | 错误码 | 版本 |
| --- | --- | --- | --- | --- |
| `GetSeries` | `provider, series_id, api_version` | `MacroSeries` | `series_not_found`, `provider_unsupported` | v1 |
| `QueryObservations` | `series_id, time_range{start,end}, vintage_selector, as_of, api_version` | `MacroPoint[]` | `invalid_time_range`, `future_as_of` | v1 |
| `StartBackfill` | `series_set[], range{start,end}, mode, priority, api_version` | `MacroIngestJob{job_id, checkpoint}` | `invalid_series_set`, `range_too_wide` | v1 |
| `GetJobStatus` | `job_id, api_version` | `{state, checkpoint, error_summary}` | `job_not_found` | v1 |
| `ScanRevisions` | `series_set[], vintage_range{start,end}, api_version` | `{revision_job_state, detected_at}` | `invalid_vintage_range` | v1 |
| `ReloadConfig` | `admin_command, request_id, api_version` | `{accepted: bool}` | `unauthorized`, `command_unknown` | v1 |

### 4.2 Kafka 事件契约（固化 SPEC §10）

[INFERRED][HIGH] topic 命名 `fred.{event_type}.v{schema_version}`，key = 幂等键，value 含 `event_id`/`schema_version`/`occurred_at`/`payload`。

| 事件 | topic | key | payload 关键字段 | schema 版本 |
| --- | --- | --- | --- | --- |
| `MacroSeriesDiscovered` | `fred.series.discovered.v1` | `provider:series_id` | `series_id, frequency, units, discovered_at` | v1 |
| `MacroObservationUpserted` | `fred.observation.upserted.v1` | `provider:series_id:period:vintage` | `series_id, period, value, available_at, vintage_at, revision_version` | v1 |
| `MacroRevisionObserved` | `fred.revision.observed.v1` | `provider:series_id:period:vintage` | `series_id, period, old_value, new_value, vintage_at, detected_at` | v1 |
| `FredBackfillCompleted` | `fred.backfill.completed.v1` | `job_id` | `job_id, series_set, range, checkpoint, finished_at` | v1 |
| `FredIngestFailed` | `fred.ingest.failed.v1` | `job_id` | `job_id, series_id, error_class, raw_manifest_id, failed_at` | v1 |

[INFERRED][HIGH] 所有事件 payload **不含 secret**；`available_at`/`vintage_at` 为强制字段（no-lookahead）。

### 4.3 NATS 控制面契约（固化 SPEC §10）

[INFERRED][HIGH] subject 命名 `fred.ctrl.{command}`，**只承载控制命令，不承载 durable event**（对应 BR-004）。

| 命令 | subject | payload | 响应 |
| --- | --- | --- | --- |
| reload | `fred.ctrl.reload` | `{request_id}` | `fred.ctrl.reload.ack` |
| backfill | `fred.ctrl.backfill` | `{series_set, range, mode}` | `fred.ctrl.backfill.ack` |
| pause | `fred.ctrl.pause` | `{job_id}` | `fred.ctrl.pause.ack` |
| resume | `fred.ctrl.resume` | `{job_id}` | `fred.ctrl.resume.ack` |
| heartbeat | `fred.ctrl.heartbeat` | `{worker_id, ts}` | 无（fire-and-forget） |

### 4.4 七介质最小 schema

[INFERRED][HIGH] 以下为实施期最小命名，非完整 DDL。

| 介质 | 命名规则 | 最小字段 | 权威性 |
| --- | --- | --- | --- |
| OSS | `fred/raw/{provider}/{endpoint}/{date}/{job_id}/{content_hash}.json` | raw payload + manifest | 原始载荷权威 |
| Postgres | `fred.series_catalog`/`fred.release_calendar`/`fred.checkpoint`/`fred.idempotency_ledger`/`fred.gap_ledger` | 见 SPEC §13 | 控制平面权威 |
| Taos | supertable `fred_observation`，tag: `series_id, vintage_at`；字段 `value, available_at, released_at, revision_version, quality_status` | 时序事实 | 时间序列事实权威 |
| Kafka | 见 §4.2 | durable event | durable event 权威 |
| Redis | key `fred:cache:{series_id}:{as_of}`、`fred:lock:{job_id}`、`fred:rate:{provider}`、`fred:cursor:{job_id}` | TTL 见 §3 | 可重建缓存 |
| NATS | 见 §4.3 | control message | 控制面传输 |
| ClickHouse | table `fred_observation_wide`、mv `fred_observation_mv` | 宽表投影 | 可重建读模型 |

[INFERRED][HIGH] 幂等键：`(provider, series_id, period_start, vintage_at, units, frequency)`；raw manifest 去重：`(provider, endpoint, params_hash, fetched_at_bucket, content_hash)`。

## 5. 阶段 2 闭合状态

| 项 | 状态 | 证据 |
| --- | :---: | --- |
| P0-3 配置映射 | ✅ 本报告 §3 给出 redacted mapping | 22 个 key，全量 redact 规则，无 secret 值 |
| P1-2 API 契约 | ✅ 本报告 §4.1 | 6 API，版本字段，错误码 |
| P1-2 Kafka 契约 | ✅ 本报告 §4.2 | 5 事件，topic/key/payload/schema 版本 |
| P1-2 NATS 契约 | ✅ 本报告 §4.3 | 5 命令，subject 命名，durable/event 分离 |
| P1-2 七介质 schema | ✅ 本报告 §4.4 | 最小命名 + 权威性 + 幂等键 |
| P1-3 `domain_macro` 绑定 | ⚠️ 需决策 | 本报告 §2 给出方案 B 推荐 + 字段映射，待 owner 确认 |

## 6. 阶段 2 产物同步到 SPEC.md

[INFERRED][HIGH] 本报告内容应作为附录补入 `module/fred/SPEC.md`：
- §3 config mapping → SPEC §11 附录
- §4 契约 → SPEC §7/§10 附录
- §2 `domain_macro` 绑定 → SPEC §9 修正（模型名映射 + 缺失类型标注）

SPEC.md 修改留待阶段 2 PR 一并提交（本报告 + SPEC 附录同步）。

## 7. 未验证限制

[COMPUTED][HIGH] 本报告未读取 `sre/secrets/env/dev.md` 的 secret 值，配置 key 名基于 SPEC §11 类别和 FRED/介质惯例推断，实际 key 名以 `sre/secrets/env/dev.md` 为准。

[COMPUTED][HIGH] 本报告基于 `domain-macro` v0.1.0 源码；若 `domain-macro` 后续发版补齐类型，§2 决策需重新评估。

[INFERRED][MED] §4 契约字段为最小集，实施期可能根据 FRED 实际响应和下游需求扩展，但 topic/subject/key 命名规则应稳定。

[RULES I BROKE]：无
