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
