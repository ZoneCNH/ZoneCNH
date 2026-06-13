# TASK-KAFKAX-002: TASK-KAFKAX-002

- **Module**: kafkax
- **spec_ref**: module/kafkax/SPEC.md#FR-003 ,module/kafkax/SPEC.md#FR-004
- **BR_ref**: module/kafkax/SPEC.md#BR-003
- **ACs**: AC-003, AC-004
- **Phase**: Foundation (Phase 1)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Pending

## Scope

实现 Consumer 接口：Subscribe 消费组加入、Poll 阻塞拉取、ctx 超时取消

## Non-Scope

Does NOT implement Kafka broker deployment, topic auto-creation, or Kafka Connect integration. Does NOT implement business event semantics or domain DTOs.

## Files

- (implementation files — TBD)

## Acceptance

- [ ] FR-003 verified via TC
- [ ] FR-004 verified via TC
