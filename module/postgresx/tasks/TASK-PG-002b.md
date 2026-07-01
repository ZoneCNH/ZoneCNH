```yaml
TASK-PG-002b:
  module: postgresx
  scope: "实现迁移执行（MigrationRunner）与错误归一化（MapError/IsRetryable）"
  spec_ref:
    - "module/postgresx/SPEC.md#FR-004"
    - "module/postgresx/SPEC.md#FR-006"
    - "module/postgresx/SPEC.md#BR-007"
    - "module/postgresx/SPEC.md#BR-010"
  files:
    - "pkg/postgresx/migration.go"
    - "pkg/postgresx/errors.go"
  acceptance_criteria:
    - "TC-004: MigrationRunner 升序执行、幂等跳过、重复版本和无效迁移阻断"
    - "TC-006: MapError/IsRetryable 覆盖 context、no rows、认证、约束、序列化、连接和停机错误"
  depends_on:
    - "TASK-PG-001"
  estimated_effort: "3h"
  priority: P0
  status: done
```

## Non-scope

- 不涉及事务边界（WithTx/WithTxOptions）—— 见 TASK-PG-002a
- 不涉及健康检查（HealthChecker/Stats）—— 见 TASK-PG-002a
- 不涉及可观测 hook（Logger/Metrics）—— 见 TASK-PG-003
- 不承诺迁移回滚、checksum 验证或迁移历史清理

## Test Plan

| TC | 验证内容 | 验证命令 |
|-----|---------|---------|
| TC-004 | MigrationRunner.Up 升序执行、已应用跟踪、重复版本/非正版本/空名称/空 SQL 阻断 | `GOWORK=off go test -run "TestMigration" ./pkg/postgresx/` |
| TC-006 | MapError SQLSTATE 映射（context/认证/约束/序列化/连接/停机），IsRetryable 判定 | `GOWORK=off go test -run "TestMapError|TestIsRetryable" ./pkg/postgresx/` |

## Evidence

- `/home/workspace/postgresx/pkg/postgresx/migration.go`
- `/home/workspace/postgresx/pkg/postgresx/errors.go`
- `/home/workspace/postgresx/docs/EVIDENCE-20260601.md`
