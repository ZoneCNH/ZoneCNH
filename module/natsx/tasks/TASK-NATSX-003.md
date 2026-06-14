---
TASK-NATSX-003:
  module: natsx
  scope: "JetStream 发布订阅：ack/redelivery/dead-letter 行为"
  spec_ref:
    - "module/natsx/SPEC.md#FR-004"
    - "module/natsx/SPEC.md#FR-005"
    - "module/natsx/SPEC.md#BR-002"
    - "module/natsx/SPEC.md#BR-007"
  acceptance_criteria:
    - "AC-004: JetStream Publish 收到 pubAck"
    - "AC-005: Subscribe 正确处理 ack/redelivery"
  files:
    - "jetstream.go"
    - "errors.go"
    - "jetstream_test.go"
  priority: P0
  status: pending
---

## Scope

JetStream 发布订阅：ack/redelivery/dead-letter 行为

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Acceptance

- [ ] FR-004 verified via TC-003
- [ ] FR-005 verified via TC-003
