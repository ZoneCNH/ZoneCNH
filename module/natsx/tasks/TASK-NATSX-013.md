---
TASK-NATSX-013:
  module: natsx
  scope: "依赖边界：禁止依赖 kafkax/redisx/postgresx 等消息/存储模块"
  spec_ref:
    - "module/natsx/SPEC.md#FR-NFR-004"
    - "module/natsx/SPEC.md#15-dependencies"
  acceptance_criteria:
    - "§15: go list -deps 不含 ZoneCNH 消息/存储模块"
  files:
    - "go.mod"
  priority: P2
  status: pending
---

## Scope

依赖边界：禁止依赖 kafkax/redisx/postgresx 等消息/存储模块

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Acceptance

- [ ] NFR-004 verified via TC-013
