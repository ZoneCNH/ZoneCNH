# fred Runtime Mapping

- Last-Updated: 2026-07-03
- Module-Spec: [../spec/SPEC.md](../spec/SPEC.md)
- Runtime-Repo: `/home/workspace/fred`

## 1. 目标运行时目录映射

```text
github.com/ZoneCNH/fred/
  cmd/
    fred-client/          # 独立采集进程
    fred-server/          # 独立消费/查询进程
  internal/
    client/               # provider pull + normalize + nats publish
    server/               # nats consume + persistence + api
    cs/                   # client/server wire contract + schema validation
    domain/               # domain_macro mapping + no-lookahead helper
    store/                # taos/postgres/redis/clickhouse/oss adapters
    events/               # kafka topic schema + outbox
    control/              # nats control subject handlers
  pkg/
    fredx/                # external Go client
  scripts/
    boundary-gates.sh
    integration-check.sh
```

## 2. 模块文档到运行时映射

| 模块文档 | Runtime 目标 |
| --- | --- |
| `goal/goal.md` | `cmd/fred-client`、`cmd/fred-server` 角色与边界 |
| `spec/SPEC.md` | `internal/*` 功能与接口实现 |
| `spec/client/SPEC.md` | `internal/client` 与 `cmd/fred-client` |
| `spec/server/SPEC.md` | `internal/server` 与 `cmd/fred-server` |
| `matrix/TRACEABILITY.md` | 测试命令与证据路径 |
| `gate/BOUNDARY-GATES.md` | `scripts/boundary-gates.sh` 规则 |
| `ci-workflow.yaml` | `.github/workflows/ci.yml` |

## 3. 配置映射（仅键类别）

| 配置域 | Runtime 读取位置 | 来源 |
| --- | --- | --- |
| FRED provider | `config/fred-client` | `sre/secrets/env/dev.md` |
| NATS handoff/control | `config/fred-client` + `config/fred-server` | `sre/secrets/env/dev.md` |
| Postgres/TDengine/Redis/OSS/ClickHouse | `config/fred-server` | `sre/secrets/env/dev.md` |
| Kafka producer | `config/fred-server` | `sre/secrets/env/dev.md` |
| Observability | 两个服务共享配置模型 | `sre/secrets/env/dev.md` |

> 约束：只存键名和映射规则，不在仓库内保存 secret 值。

## 4. 运行时交付物

| 交付物 | 说明 |
| --- | --- |
| `fred-client` binary | 周期采集 + 手动回补触发 |
| `fred-server` binary | 持久化 + API + Kafka fanout |
| NATS stream/consumer contract | client/server handoff 契约 |
| Kafka topic contract | 下游 durable event 契约 |
| Migration scripts | Postgres/ClickHouse/TDengine schema 初始化与升级 |

## 5. 系列目录、外部路由与派生序列运行时映射

本小节细化 `spec/SERIES-CATALOG.md` 与 `spec/SERIES-API.md` 在 `/home/workspace/fred` 中的运行时落点。

### 5.1 系列目录运行时映射

| 模块规格 | Runtime 落点 | 说明 |
| --- | --- | --- |
| `spec/SERIES-CATALOG.md` §3 12 类 90 序列 | `config/series-catalog.yaml`（或 `internal/catalog/catalog.yaml`） | 权威目录的只读镜像；runtime 启动时加载，用于覆盖率对账与缺口识别 |
| P0/P1/P2 优先级 | `internal/client/scheduler.go` | 按 P0→P1→P2 顺序调度 backfill/incremental，P0 优先接入端到端 |
| 修订敏感度标签 | `internal/client/revision_window.go` | 高/中敏感度序列自动走最近 3 个月修订回拉窗口 |
| 采集节奏（日/周/月/季） | `internal/client/trigger.go` + `internal/server/release_calendar.go` | release calendar trigger 优先，兜底轮询按频率调度 |
| 派生序列（T10Y2Y/T10Y3M） | `internal/domain/derived/` 或 ClickHouse materialized view | 由 DGS3MO/DGS2/DGS10/DGS30 原始值计算，不写入原始 observation |

### 5.2 外部路由（source_component）运行时映射

| 模块规格 | Runtime 落点 | 说明 |
| --- | --- | --- |
| authority registry（`spec/SERIES-API.md` §4） | `config/authority-registry.yaml` | 从 `sre/secrets/env/dev.md` 经 `configx` 映射；判定 `source_component` |
| `source_component` 路由判定 | `internal/domain/source_router.go` | 输入 series_id，输出 NATIVE / EXTERNAL(ECB/BoJ) |
| `GetSeries` 返回 `source_component` | `internal/server/api/series.go` | 外部路由序列附加 `external_source_url` |
| `GetCatalogCoverage` 分母排除外部 | `internal/server/api/coverage.go` | `coverage_ratio` 仅基于 FRED-native；单列 `external_routed_count` |
| 外部序列无 FRED vintage | `internal/server/query/no_lookahead.go` | 外部序列拒绝 vintage selector，不生成 `MacroRevision` |
| Kafka event 透传 `source` | `internal/events/publisher.go` | `MacroObservationUpserted.source` 携带真实权威 |
| 外部路由 boundary gate | `scripts/boundary-gates.sh` | 拦截外部序列被误写入“FRED 完整采集”断言 |

### 5.3 运行时交付物补充

| 交付物 | 说明 |
| --- | --- |
| `internal/domain/source_router.go` | 基于 authority registry 判定 `source_component` |
| `internal/server/api/series.go` | `GetSeries` 路由字段返回 |
| `internal/server/api/coverage.go` | 覆盖审计分母/外部路由计数 |
| `internal/server/query/no_lookahead.go` | 外部序列 vintage 拒绝逻辑 |
| `config/authority-registry.yaml` | authority registry 只读配置 |
| `config/series-catalog.yaml` | 目录只读镜像（P0/P1/P2、修订敏感度、频率） |
| `internal/client/scheduler.go` | P0→P1→P2 调度与修订窗口逻辑 |

> 约束：只存键名与映射规则，不保存 secret 值。
