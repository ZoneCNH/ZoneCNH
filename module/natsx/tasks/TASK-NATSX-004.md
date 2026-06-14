---
TASK-NATSX-004:
  module: natsx
  scope: "AddStream/AddConsumer：创建、幂等、冲突配置、drain"
  acceptance_criteria:
    - "AC-006: AddStream 创建或幂等返回已有 stream"
    - "AC-007: AddConsumer 创建或幂等返回已有 consumer"
  priority: P0
  status: pending
---

## Scope

AddStream/AddConsumer：创建、幂等、冲突配置、drain

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Files

- (implementation files — TBD)

## Acceptance

- [ ] FR-006 verified via TC
- [ ] FR-007 verified via TC
