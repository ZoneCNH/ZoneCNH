---
TASK-NATSX-007:
  module: natsx
  scope: "NatsMessageEnvelope：traceId/messageId/schemaVersion/header 双向映射与传播"
  spec_ref:
    - "module/natsx/SPEC.md#FR-NFR-007"
    - "module/natsx/SPEC.md#9-interface-contract"
  acceptance_criteria:
    - "§9: traceId/messageId/schemaVersion Header→Envelope 正确映射"
    - "§9: 已有上游 Header 不被丢弃，冲突字段以 Envelope 为准"
  files:
    - "msg.go"
    - "msg_test.go"
  priority: P1
  status: pending
---

## Scope

NatsMessageEnvelope：traceId/messageId/schemaVersion/header 双向映射与传播

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Acceptance

- [ ] NFR-007 verified via TC-007
