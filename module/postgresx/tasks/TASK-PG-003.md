# TASK-PG-003: 可观测契约与 v1.0 文档冻结

## Scope

冻结 v1.0.0 契约一致性：指标命名、Go 版本矩阵、public API contract、SPEC、goal 与 TRACEABILITY。

## Requirements

- FR-007
- BR-009
- BR-012

## Acceptance

- 指标名在代码和 contract 中唯一，并已通过 contract/evidence gate。
- `go.mod` 的 `go 1.25.0` 与版本矩阵文档保持一致。
- public API contract 不列出当前代码未实现的符号。
- `SPEC.md`、`goal.md`、`TRACEABILITY.md` 和 `ARCHITECTURE.md` 反映同一 v1.0.0 release 基线。
- Secret、DSN、SQL 参数不得进入日志和指标标签。

## Evidence

- `/home/postgresx/pkg/postgresx/metrics.go`
- `/home/postgresx/contracts/metrics.md`
- `/home/postgresx/docs/VERSION_MATRIX.md`
- `/home/postgresx/contracts/`
- `GOWORK=off VERSION=v1.0.0 make release-evidence-check`
- `GOWORK=off VERSION=v1.0.0 make release-final-check`
- `GOWORK=off VERSION=v1.0.0 make release-preflight`，在 `POSTGRESX_REQUIRE_INTEGRATION=1` 与注入的 dev PostgreSQL DSN/凭据下执行
- `tag v1.0.0 / commit 310a249e`
- `module/postgresx/SPEC.md`
- `module/postgresx/TRACEABILITY.md`

## Status

Done。TASK-PG-003 已关闭；指标命名、Go baseline、Public API contract 与 v1.0.0 release evidence 已对齐。
