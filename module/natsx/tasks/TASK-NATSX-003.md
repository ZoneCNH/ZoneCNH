---
TASK-NATSX-003:
  module: natsx
  scope: "JetStream 发布订阅：ack/redelivery/dead-letter 行为"
  depends_on:
    - "TASK-NATSX-002"
  spec_ref:
    - "module/natsx/SPEC.md#FR-004"
    - "module/natsx/SPEC.md#FR-005"
    - "module/natsx/SPEC.md#BR-002"
    - "module/natsx/SPEC.md#BR-007"
  acceptance_criteria:
    - "AC-004: JetStream Publish 返回 PublishAck（stream 已创建）"
    - "AC-004: JetStream Publish 时 stream 未创建返回错误"
    - "AC-005: Subscribe 注册返回 Subscription"
    - "AC-005: ack 后 offset 推进"
    - "AC-005: 消息 nack 后触发 redelivery"
    - "AC-005: 超过 max_deliver 后消息进入 Dead Letter"
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
