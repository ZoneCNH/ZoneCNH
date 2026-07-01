```yaml
TASK-PG-002a:
  module: postgresx
  scope: "实现事务边界（WithTx/WithTxOptions）与健康检查（HealthChecker/Stats）"
  spec_ref:
    - "module/postgresx/SPEC.md#FR-003"
    - "module/postgresx/SPEC.md#FR-005"
    - "module/postgresx/SPEC.md#BR-006"
    - "module/postgresx/SPEC.md#BR-008"
  files:
    - "pkg/postgresx/tx.go"
    - "pkg/postgresx/health.go"
  acceptance_criteria:
    - "TC-003: WithTx/WithTxOptions 覆盖 commit、rollback、context 取消和 panic 回滚"
    - "TC-005: HealthChecker 输出 healthy/degraded/unhealthy，Stats 不泄露 Secret"
  depends_on:
    - "TASK-PG-001"
  estimated_effort: "3h"
  priority: P0
  status: done
```

## Non-scope

- 不涉及迁移执行（MigrationRunner）—— 见 TASK-PG-002b
- 不涉及错误映射（MapError/IsRetryable）—— 见 TASK-PG-002b
- 不涉及可观测 hook（Logger/Metrics）—— 见 TASK-PG-003
- 不承诺事务传播、嵌套事务或 savepoint 语义

## Test Plan

| TC | 验证内容 | 验证命令 |
|-----|---------|---------|
| TC-003 | WithTx 提交/回滚、context 取消、panic 回滚、read-only 选项 | `GOWORK=off go test -run "TestWithTx|TestTxOptions" ./pkg/postgresx/` |
| TC-005 | HealthChecker Name/Check、Ping、Stats、超时、安全元数据 | `GOWORK=off go test -run "TestHealth|TestStats" ./pkg/postgresx/` |

## Evidence

- `/home/workspace/postgresx/pkg/postgresx/tx.go`
- `/home/workspace/postgresx/pkg/postgresx/health.go`
- `/home/workspace/postgresx/docs/EVIDENCE-20260601.md`
