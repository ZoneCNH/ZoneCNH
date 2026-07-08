# fred 模块索引

`fred` 是数据域 · 宏观的独立 C/S 模块，按 **client/server 双进程** 形态运行，面向 FRED 宏观序列采集、领域归一化、持久化、事件发布和查询服务。

## 文档入口

| 文档 | 用途 |
| ---- | ---- |
| [goal/goal.md](goal/goal.md) | 目标、边界、成功标准 |
| [spec/SPEC.md](spec/SPEC.md) | 根规格（23 节） |
| [spec/SERIES-CATALOG.md](spec/SERIES-CATALOG.md) | FRED 系列分类目录（源自 `.beads/1.md`，12 类 90 序列权威采集集） |
| [spec/SERIES-API.md](spec/SERIES-API.md) | 路由接口细节（source_component、authority registry、外部路由集成测试） |
| [spec/client/SPEC.md](spec/client/SPEC.md) | client 子模块规格 |
| [spec/server/SPEC.md](spec/server/SPEC.md) | server 子模块规格 |
| [matrix/TRACEABILITY.md](matrix/TRACEABILITY.md) | 根追溯矩阵 |
| [matrix/client/TRACEABILITY.md](matrix/client/TRACEABILITY.md) | client 追溯矩阵 |
| [matrix/server/TRACEABILITY.md](matrix/server/TRACEABILITY.md) | server 追溯矩阵 |
| [plan/PLAN.md](plan/PLAN.md) | 根实施计划 |
| [plan/client/PLAN.md](plan/client/PLAN.md) | client 实施计划 |
| [plan/server/PLAN.md](plan/server/PLAN.md) | server 实施计划 |
| [design/DESIGN.md](design/DESIGN.md) | 生产级架构与数据流 |
| [design/RUNTIME-MAPPING.md](design/RUNTIME-MAPPING.md) | spec→runtime 映射 |
| [gate/BOUNDARY-GATES.md](gate/BOUNDARY-GATES.md) | 边界门禁与禁止项 |
| [schema/README.md](schema/README.md) | API/事件/存储契约 |
| [ci-workflow.yaml](ci-workflow.yaml) | CI/CD 工作流模板 |

## C/S 子模块与独立服务

| 子模块 | 运行形态 | 核心职责 |
| ---- | ---- | ---- |
| `fred-client` | 独立进程（`cmd/fred-client`） | 拉取 FRED 完整信息域（series/observations/vintages/releases/categories/tags/sources/updates）、归一化为 `domain_macro`、写 OSS raw、发布 NATS ingest envelope |
| `fred-server` | 独立进程（`cmd/fred-server`） | 消费 NATS envelope、执行幂等校验、写 `taos/postgres/Redis/clickhouse`、发布 Kafka durable event、提供查询/管理 API |

## 生产级持久化职责

| 介质 | 职责 | 权威性 |
| ---- | ---- | ---- |
| `oss` | provider raw 归档、回放输入、审计快照 | 原始数据权威 |
| `taos` | 规范化 observation 时间序列 | 时间序列权威 |
| `postgres` | catalog、release calendar、checkpoint、idempotency ledger | 控制面权威 |
| `Redis` | 热缓存、锁、限流桶、短游标 | 可重建派生层 |
| `clickhouse` | 分析读模型与批量校验 | 可重建派生层 |
| `nats` | client→server ingest handoff + admin control plane | 服务间通信通道 |
| `kafka` | 下游 durable business events | 事件分发权威 |

## 关键边界

1. 共享基座强制：配置、观测、韧性、存储、消息必须经共享基座组件接入。
2. 领域共享层强制：出域模型必须来自 `domain_macro`，禁止泄露 provider DTO。
3. 服务独立强制：`fred-client`/`fred-server` 可独立部署与扩缩容，不允许单进程耦合路径。
4. 无前视强制：`available_at` 是 as-of 可见性判定基准。
5. secret 红线：只引用 `sre/secrets/env/dev.md` 键名与映射规则，不复制值。

## 完整采集范围

`fred` 的“完整采集”包含以下信息族，不仅是 observation：

1. 序列与值：series metadata、observations、vintages/revisions。
2. 发布体系：releases、release dates、release tables、release-series 关联。
3. 分类体系：categories、category children、category-series 关联。
4. 标签体系：tags、related tags、tag-series 关联。
5. 来源体系：sources、source-releases 关联。
6. 增量体系：series updates 与变更游标。

### Endpoint 级清单（FRED v1）

1. Category：`/category`、`/category/children`、`/category/related`、`/category/related_tags`、`/category/series`、`/category/tags`
2. Release：`/releases`、`/releases/dates`、`/release`、`/release/dates`、`/release/series`、`/release/sources`、`/release/tables`、`/release/tags`、`/release/related_tags`
3. Series：`/series`、`/series/categories`、`/series/observations`、`/series/release`、`/series/search`、`/series/search/tags`、`/series/search/related_tags`、`/series/tags`、`/series/updates`、`/series/vintagedates`
4. Source：`/sources`、`/source`、`/source/releases`
5. Tags：`/tags`、`/related_tags`、`/tags/series`

## 核心指标包（初始）

> 以下 27 个锚点为 **P0（首期）** 优先级。完整权威采集集见 [spec/SERIES-CATALOG.md](spec/SERIES-CATALOG.md)（源自 `.beads/1.md`，12 类 90 序列，含 P0/P1/P2 分层与差异对账）。别名统一建议：`WDTGAL→WTREGEN`、`VXVCLS→VIXCLS`。

| 维度 | 指标 |
| --- | --- |
| 流动性 | `WALCL`、`WDTGAL`、`RRPONTSYD`、`ECBASSETSW`、`JPNASSETS`、`DEXUSEU`、`DEXJPUS` |
| 增长与通胀 | `INDPRO`、`PERMIT`、`T5YIE`、`CPIAUCSL`、`PCEPILFE` |
| 风险 | `VXVCLS`、`STLFSI4` |
| 政策立场 | `DFEDTARU`、`PCEPI`、`GDPC1`、`GDPPOT`、`UNRATE`、`NROU` |
| 基础宏观 | `GDP`、`FEDFUNDS`、`CPILFESL`、`PAYEMS`、`ICSA`、`DGS10`、`M2SL` |

## 同步与回补策略（默认）

1. 首次全量默认起点 `1990-01-01`（约 35 年回溯），series 若更晚则以最早可用日期为准。
2. 增量同步按 `last_success_cursor -> now` 执行，每次额外回拉最近 3 个月覆盖修订。
3. 支持批量采集（multi-series batch）与频率聚合（D->M、M->Q），不覆盖原始频率事实。
4. 日频每日、周频每周、月频/季频按发布后 24h 内触发同步；release calendar trigger 优先。
5. FRED 限流基线：无 key `30 req/min`、有 key `120 req/min`、突发 `<=2 req/s`，429 走退避重试。
6. 版本管理保留 `realtime_start`/`realtime_end` + `vintage_at`，支撑 ALFRED 风格回溯分析。
