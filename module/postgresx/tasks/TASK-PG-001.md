```yaml
TASK-PG-001:
  module: postgresx
  scope: "实现 Config、连接池生命周期与 SQL 执行基线（Exec/Query/QueryRow/Rows）"
  spec_ref:
    - "module/postgresx/SPEC.md#FR-001"
    - "module/postgresx/SPEC.md#FR-002"
    - "module/postgresx/SPEC.md#BR-001"
    - "module/postgresx/SPEC.md#BR-002"
    - "module/postgresx/SPEC.md#BR-003"
    - "module/postgresx/SPEC.md#BR-004"
    - "module/postgresx/SPEC.md#BR-005"
    - "module/postgresx/SPEC.md#BR-011"
  files:
    - "pkg/postgresx/client.go"
    - "pkg/postgresx/config.go"
    - "pkg/postgresx/query.go"
    - "pkg/postgresx/dsn.go"
    - "go.mod"
  acceptance_criteria:
    - "TC-001: Config 默认值稳定、DSN 脱敏、无效配置返回错误"
    - "TC-002: Exec/Query/QueryRow 保留 context 语义，Rows Close/Err 行为正确"
    - "TC-008: GOWORK=off 下测试通过，go.mod 仅含允许的基座依赖"
  depends_on: []
  estimated_effort: "4h"
  priority: P0
  status: done
```

## Non-scope

- 不涉及事务边界（WithTx/WithTxOptions）
- 不涉及迁移执行（MigrationRunner）
- 不涉及健康检查（HealthChecker/Stats）
- 不涉及错误映射（MapError/IsRetryable）
- 不涉及可观测 hook（Logger/Metrics）

## Test Plan

| TC | 验证内容 | 验证命令 |
|-----|---------|---------|
| TC-001 | Config 校验、默认值填充、DSN/RedactedDSN、New/Open 生命周期 | `GOWORK=off go test -run TestConfig ./pkg/postgresx/` |
| TC-002 | Exec/Query/QueryRow 参数绑定、扫描、Rows 生命周期与迭代错误 | `GOWORK=off go test -run "TestExec|TestQuery|TestRows" ./pkg/postgresx/` |
| TC-008 | GOWORK=off go test/go vet 通过，依赖边界检查 | `GOWORK=off go test ./... && GOWORK=off go vet ./...` |

## Evidence

- `/home/workspace/postgresx/pkg/postgresx/client.go`
- `/home/workspace/postgresx/pkg/postgresx/config.go`
- `/home/workspace/postgresx/pkg/postgresx/query.go`
- `/home/workspace/postgresx/pkg/postgresx/dsn.go`
- `/home/workspace/postgresx/go.mod`
- `/home/workspace/postgresx/docs/EVIDENCE-20260601.md`
