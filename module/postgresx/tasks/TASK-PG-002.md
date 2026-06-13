# TASK-PG-002: 事务、迁移、健康检查与错误模型

## Scope

锁定事务边界、迁移执行、健康检查和 PostgreSQL 错误归一化能力。

## Requirements

- FR-003
- FR-004
- FR-005
- FR-006
- BR-006
- BR-007
- BR-008
- BR-010

## Acceptance

- `WithTx` / `WithTxOptions` 在 nil callback 时提交，在 error、context 取消和 panic 时回滚。
- panic 路径回滚后重新抛出 panic，除非未来规格显式改变。
- `MigrationRunner` 拒绝非正版本、空名称、空 SQL 和重复版本。
- `Check(ctx)` 符合 `foundationx.HealthChecker`，健康元数据不泄露 Secret。
- `MapError` 和 `IsRetryable` 覆盖 context、no rows、认证、约束、序列化、连接和停机类错误。

## Evidence

- `/home/postgresx/pkg/postgresx/tx.go`
- `/home/postgresx/pkg/postgresx/migration.go`
- `/home/postgresx/pkg/postgresx/health.go`
- `/home/postgresx/pkg/postgresx/errors.go`
- `/home/postgresx/docs/EVIDENCE-20260601.md`

## Status

已有实现和验证证据。v1.0.0 public API contract 已按当前事务和迁移能力冻结，未承诺事务传播或迁移 checksum 语义。
