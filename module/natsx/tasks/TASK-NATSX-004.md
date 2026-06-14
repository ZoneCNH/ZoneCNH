---
TASK-NATSX-004:
  module: natsx
  scope: "AddStream/AddConsumer：创建、幂等、冲突配置、drain"
  depends_on:
    - "TASK-NATSX-003"
  spec_ref:
    - "module/natsx/SPEC.md#FR-006"
    - "module/natsx/SPEC.md#FR-007"
    - "module/natsx/SPEC.md#BR-005"
  acceptance_criteria:
    - "AC-006: AddStream 创建不存在的 stream 返回 nil"
    - "AC-006: AddStream 重复调用且配置兼容返回 nil（幂等）"
    - "AC-006: AddStream 重复调用且配置冲突返回 ErrStreamExists"
    - "AC-007: AddConsumer 创建不存在的 consumer 返回 nil"
    - "AC-007: AddConsumer 重复调用且配置兼容返回 nil（幂等）"
    - "AC-007: AddConsumer 重复调用且配置冲突返回 ErrConsumerExists"
  files:
    - "jetstream.go"
    - "options.go"
    - "internal/reconnect/backoff.go"
    - "jetstream_test.go"
  priority: P0
  status: pending
---

## Scope

AddStream/AddConsumer：创建、幂等、冲突配置、drain

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Acceptance

- [ ] FR-006 verified via TC-003
- [ ] FR-007 verified via TC-003
