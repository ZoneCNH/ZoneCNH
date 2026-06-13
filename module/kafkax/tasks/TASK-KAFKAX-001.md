# TASK-KAFKAX-001: TASK-KAFKAX-001

- **Module**: kafkax
- **spec_ref**: module/kafkax/SPEC.md#FR-001 ,module/kafkax/SPEC.md#FR-002
- **BR_ref**: module/kafkax/SPEC.md#BR-001 ,module/kafkax/SPEC.md#BR-005
- **ACs**: AC-001, AC-002
- **Phase**: Foundation (Phase 1)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Pending

## Scope

实现 Producer 接口：Send 单条发送、SendBatch 批量发送、acks=all 同步确认、重试策略

## Non-Scope

Does NOT implement Kafka broker deployment, topic auto-creation, or Kafka Connect integration. Does NOT implement business event semantics or domain DTOs.

## Files

- (implementation files — TBD)

## Acceptance

- [ ] FR-001 verified via TC
- [ ] FR-002 verified via TC
