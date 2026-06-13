# TASK-PG-001: Config、连接池与 SQL 执行基线

## Scope

锁定 `postgresx` 的最小客户端基线：显式 `Config`、`New` / `Open`、连接池生命周期、`Exec`、`Query`、`QueryRow`、`Rows` 和依赖边界。

## Requirements

- FR-001
- FR-002
- BR-001
- BR-002
- BR-003
- BR-004
- BR-005
- BR-011

## Acceptance

- `go.mod` 只包含允许的基座依赖：`foundationx` 与 `pgx/v5`。
- `Config` 不读取环境变量、配置文件或 Secret 文件。
- `New` / `Open` 初始化失败时关闭连接池。
- `Close` 幂等，关闭后查询和事务入口返回错误。
- 查询接口保留 `context.Context` 行为，`Rows` 暴露 `Close` 与 `Err`。
- `GOWORK=off go test ./...` 和 `GOWORK=off go vet ./...` 通过。

## Evidence

- `/home/postgresx/pkg/postgresx/client.go`
- `/home/postgresx/pkg/postgresx/config.go`
- `/home/postgresx/pkg/postgresx/dsn.go`
- `/home/postgresx/pkg/postgresx/query.go`
- `/home/postgresx/go.mod`
- `/home/postgresx/docs/EVIDENCE-20260601.md`

## Status

已有实现和验证证据。v1.0.0 已通过 TASK-PG-003 冻结 public API contract 与代码一致性。
