# TASK-PG-003: 可观测契约与 v1.0 文档冻结

## Scope

冻结 v1.0 前的契约一致性：指标命名、Go 版本矩阵、public API contract、SPEC、goal 与 TRACEABILITY。

## Requirements

- FR-007
- BR-009
- BR-012

## Acceptance

- 指标名在代码和 contract 中唯一：当前需在 `postgresx_query_total` 与 `postgresx.query.total` 两种风格之间作出选择。
- `go.mod` 的 `go 1.25.0` 与版本矩阵文档保持一致，或明确升级并同步所有证据。
- public API contract 不列出当前代码未实现的符号。
- `SPEC.md`、`goal.md`、`TRACEABILITY.md` 和 `ARCHITECTURE.md` 反映同一实现基线。
- Secret、DSN、SQL 参数不得进入日志和指标标签。

## Evidence

- `/home/postgresx/pkg/postgresx/metrics.go`
- `/home/postgresx/contracts/metrics.md`
- `/home/postgresx/docs/VERSION_MATRIX.md`
- `/home/postgresx/contracts/`
- `module/postgresx/SPEC.md`
- `module/postgresx/TRACEABILITY.md`

## Status

待修正。该任务是 v1.0 冻结阻断项，但不否定当前 v0.1.0 candidate 的代码基线。
