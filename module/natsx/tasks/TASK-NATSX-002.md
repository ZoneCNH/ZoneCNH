---
TASK-NATSX-002:
  module: natsx
  scope: "Request-Reply 模式：responder、timeout、ctx cancel"
  spec_ref:
    - "module/natsx/SPEC.md#FR-003"
    - "module/natsx/SPEC.md#BR-003"
  acceptance_criteria:
    - "AC-003: Request 在超时内收到 Response"
  files:
    - "client.go"
    - "client_test.go"
  priority: P0
  status: pending
---

## Scope

Request-Reply 模式：responder、timeout、ctx cancel

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Acceptance

- [ ] FR-003 verified via TC-002
