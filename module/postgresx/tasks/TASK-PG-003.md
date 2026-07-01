```yaml
TASK-PG-003:
  module: postgresx
  scope: "实现可观测适配（Logger/Metrics hooks）与 v1.0 文档契约冻结"
  spec_ref:
    - "module/postgresx/SPEC.md#FR-007"
    - "module/postgresx/SPEC.md#BR-009"
    - "module/postgresx/SPEC.md#BR-012"
  files:
    - "pkg/postgresx/metrics.go"
    - "pkg/postgresx/options.go"
    - "contracts/metrics.md"
  acceptance_criteria:
    - "TC-007: Logger/Metrics hook 触发查询/事务/健康/池指标，不泄露 Secret"
    - "TC-009: 指标命名、Go 版本、public API contract 与 SPEC 一致"
  depends_on:
    - "TASK-PG-002a"
    - "TASK-PG-002b"
  estimated_effort: "2h"
  priority: P1
  status: done
```

## Non-scope

- 不修改已冻结的 v1.0 Public API
- 不新增指标或变更现有指标命名
- 不修改 contract 中已冻结的接口签名
- 下游真实接入证据（x.go/业务模块 import）作为发布后跟踪项

## Test Plan

| TC | 验证内容 | 验证命令 |
|-----|---------|---------|
| TC-007 | Logger/Metrics hook 插拔、Secret hygiene（DSN 脱敏、SQL 参数不入日志） | `GOWORK=off go test -run "TestLogger|TestMetrics" ./pkg/postgresx/` |
| TC-009 | go.mod Go 版本、版本矩阵、public API contract、SPEC 一致性 | `GOWORK=off VERSION=v1.0.0 make release-evidence-check` |

## Evidence

- `/home/workspace/postgresx/pkg/postgresx/metrics.go`
- `/home/workspace/postgresx/pkg/postgresx/options.go`
- `/home/workspace/postgresx/contracts/metrics.md`
- `/home/workspace/postgresx/docs/VERSION_MATRIX.md`
- `/home/workspace/postgresx/contracts/`
- `module/postgresx/SPEC.md`
- `module/postgresx/TRACEABILITY.md`
- `GOWORK=off VERSION=v1.0.0 make release-evidence-check`
- `GOWORK=off VERSION=v1.0.0 make release-final-check`
- `GOWORK=off VERSION=v1.0.0 make release-preflight`
- `tag v1.0.0 / commit 310a249e`
