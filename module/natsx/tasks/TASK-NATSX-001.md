---
TASK-NATSX-001:
  module: natsx
  scope: "Publish/Subscribe 基础接口：subject 校验、handler 注册、连接错误处理"
  spec_ref:
    - "module/natsx/SPEC.md#FR-001"
    - "module/natsx/SPEC.md#FR-002"
    - "module/natsx/SPEC.md#BR-001"
    - "module/natsx/SPEC.md#BR-004"
    - "module/natsx/SPEC.md#BR-009"
  acceptance_criteria:
    - "AC-001: Publish 到合法 subject 被 handler 消费"
    - "AC-002: Subscribe 注册 handler 并接收消息"
  files:
    - "client.go"
    - "subscription.go"
    - "msg.go"
    - "errors.go"
    - "client_test.go"
  priority: P0
  status: pending
---

## Scope

Publish/Subscribe 基础接口：subject 校验、handler 注册、连接错误处理

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Acceptance

- [ ] FR-001 verified via TC-001
- [ ] FR-002 verified via TC-001
