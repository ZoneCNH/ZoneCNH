---
TASK-NATSX-003:
  module: natsx
  scope: "JetStream 发布订阅：ack/redelivery/dead-letter 行为"
  acceptance_criteria:
    - "AC-004: JetStream Publish 收到 pubAck"
    - "AC-005: Subscribe 正确处理 ack/redelivery"
  priority: P0
  status: pending
---

## Scope

JetStream 发布订阅：ack/redelivery/dead-letter 行为

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Files

- (implementation files — TBD)

## Acceptance

- [ ] FR-004 verified via TC
- [ ] FR-005 verified via TC
