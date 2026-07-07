# module/fred BOUNDARY GATES

- Last-Updated: 2026-07-03
- Runtime-Repo: `/home/workspace/fred`
- Scope: `fred-client` + `fred-server`

## Gate 列表

| Gate | 检查点 | 失败条件 |
| --- | --- | --- |
| BG-001 | 双服务入口存在：`cmd/fred-client`、`cmd/fred-server` | 任一入口缺失或退化为单进程路径 |
| BG-002 | client/server 只能通过契约化 handoff 通信 | client 直接 import `internal/server` 或反向 import |
| BG-003 | 配置、观测、韧性能力通过共享基座接入 | 手写配置装载、日志/指标/重试实现绕过基座 |
| BG-004 | 出域模型只允许 `domain_macro` | 对外暴露 provider DTO 或 `internal/*` 类型 |
| BG-005 | raw-first：provider 响应先入 `oss` | 未归档 raw 即继续下游持久化 |
| BG-006 | `taos/postgres/Redis/clickhouse/kafka/nats` 访问必须经适配器层 | 在业务包直连驱动或直接 SQL/协议调用 |
| BG-007 | NATS 与 Kafka 职责分离 | 用 NATS 替代 Kafka durable event，或 Kafka 承担 control plane |
| BG-008 | no-lookahead 字段完整：`released_at/available_at/vintage_at` | 缺失字段或 as-of 查询越界可见 |
| BG-009 | checkpoint 先于 completed 结论 | 持久化失败但 job 标记完成 |
| BG-010 | Redis/ClickHouse 标记为可重建派生层 | 把 Redis/ClickHouse 当唯一权威源 |
| BG-011 | admin API 强鉴权与审计 | 未鉴权 admin 入口或无 request id 审计 |
| BG-012 | secret 不落盘 | 代码、文档、fixture 出现明文密钥 |
| BG-013 | 外部路由序列不混入 FRED 完整性断言 | 外部路由序列（`ECBASSETSW`/`JPNASSETS` 等）被计入 FRED 完整采集覆盖分母或断言 |

## 建议校验命令

```bash
cd /home/workspace/fred

# 入口与依赖边界
test -d cmd/fred-client && test -d cmd/fred-server
go list ./... >/tmp/fred-packages.txt
rg -n 'internal/server' internal/client || true
rg -n 'internal/client' internal/server || true

# 共享基座与领域边界
rg -n 'domain_macro|pkg/domainmacro' internal pkg
rg -n 'fred/internal|provider dto|raw dto' internal pkg --glob '*.go'

# 持久化职责与消息分层
rg -n 'kafka|nats|taos|postgres|redis|oss|clickhouse' internal --glob '*.go'
go test ./internal/integration/... -run NATSIngestHandoff -count=1
go test ./internal/server/... -run NoLookahead -count=1

# 安全与基础门禁
bash scripts/boundary-gates.sh
go test ./... -count=1
```

## 结论口径

所有 Gate 通过后，才允许把 `matrix/TRACEABILITY.md` 中对应 FR/AC 从 `Planned` 更新为已验证状态。
