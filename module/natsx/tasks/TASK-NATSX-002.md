---
TASK-NATSX-002:
  module: natsx
  scope: "Request-Reply 模式：responder、timeout、ctx cancel"
  acceptance_criteria:
    - "AC-003: Request 在超时内收到 Response"
  priority: P0
  status: pending
---

## Scope

Request-Reply 模式：responder、timeout、ctx cancel

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Files

- (implementation files — TBD)

## Acceptance

- [ ] FR-003 verified via TC
