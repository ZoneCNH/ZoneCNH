---
TASK-NATSX-005:
  module: natsx
  scope: "Health 检查、GracefulShutdown、Drain、错误脱敏"
  depends_on:
    - "TASK-NATSX-001"
  spec_ref:
    - "module/natsx/SPEC.md#FR-008"
    - "module/natsx/SPEC.md#BR-006"
  acceptance_criteria:
    - "AC-008: NATS 连接正常时 Health() 返回 Ready=true, Live=true"
    - "AC-008: NATS 不可达时 Health() 返回 Ready=false, Live=false"
    - "AC-008: JetStream 不可用时 Health() 返回 Ready=false, Live=true"
  files:
    - "health.go"
    - "health_test.go"
  priority: P1
  status: pending
---

## Scope

Health 检查、GracefulShutdown、Drain、错误脱敏

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Acceptance

- [ ] FR-008 verified via TC-005
