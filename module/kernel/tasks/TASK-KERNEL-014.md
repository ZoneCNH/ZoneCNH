# TASK-KERNEL-014

> contracts/：契约验证层

---

```yaml
task_id: TASK-KERNEL-014
module: kernel
scope: "实现 contracts/ 契约验证层：API 快照、golden 行为测试、消费者导入测试、public_api 声明"
spec_ref:
  - "module/kernel/SPEC.md#FR-001~FR-012"
  - "module/kernel/SPEC.md#20.2"
  - "module/kernel/SPEC.md#BR-009"
  - "module/kernel/SPEC.md#22"
files:
  - "contracts/contracts_test.go"
  - "contracts/api_docs_test.go"
  - "contracts/golden_behavior_test.go"
  - "contracts/release_docs_ci_test.go"
  - "contracts/public_api/api.snapshot"
  - "contracts/golden/errx.golden"
  - "contracts/golden/healthx.golden"
  - "contracts/examples/README.md"
  - "contracts/consumers/xgo/minimal_import_test.go"
acceptance_criteria:
  - "AC-CONTRACTS-01: public-api-snapshot gate 通过"
  - "AC-CONTRACTS-02: golden-behavior gate 通过"
  - "AC-CONTRACTS-03: 消费者最小导入测试通过"
  - "AC-CONTRACTS-04: go test -race -count=1 ./contracts/... 通过"
depends_on:
  - "TASK-KERNEL-001"
  - "TASK-KERNEL-002"
  - "TASK-KERNEL-003"
  - "TASK-KERNEL-004"
  - "TASK-KERNEL-005"
  - "TASK-KERNEL-006"
  - "TASK-KERNEL-007"
  - "TASK-KERNEL-008"
  - "TASK-KERNEL-009"
  - "TASK-KERNEL-010"
  - "TASK-KERNEL-011"
  - "TASK-KERNEL-012"
estimated_effort: "3h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| §20.2 | kernel 专属 CI Gate |
| §22 | Release DoD |

## Non-scope

- 不在 contracts 中实现业务逻辑
- golden 文件不包含随机值/时间戳
- 消费者导入测试不依赖 testkitx

## Implementation Notes

- contracts_test.go：公共 API 快照对比
- golden_behavior_test.go：golden 行为回归
- consumers/xgo/：验证 x.go 可独立导入 kernel 子包
