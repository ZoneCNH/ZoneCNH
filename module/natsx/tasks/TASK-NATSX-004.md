# TASK-NATSX-004: Stream + Consumer 管理

- **Module**: natsx
- **spec_ref**: module/natsx/SPEC.md#FR-006 ,module/natsx/SPEC.md#FR-007
- **BR_ref**: module/natsx/SPEC.md#BR-005
- **ACs**: AC-006, AC-007
- **Phase**: Core Implementation (Phase 2)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Pending

## Scope

AddStream/AddConsumer：创建、幂等、冲突配置、drain

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Files

- (implementation files — TBD)

## Acceptance

- [ ] FR-006 verified via TC
- [ ] FR-007 verified via TC
