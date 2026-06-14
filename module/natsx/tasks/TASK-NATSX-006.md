---
TASK-NATSX-006:
  module: natsx
  scope: "SubjectBuilder：domain.resource.action.v{version} 构造与解析"
  spec_ref:
    - "module/natsx/SPEC.md#FR-NFR-006"
    - "module/natsx/SPEC.md#9-interface-contract"
  acceptance_criteria:
    - "§9: Build 产出合法 subject 字符串"
    - "§9: Parse 还原 domain/resource/action/version"
    - "§9: 非法 token 拒绝并返回错误"
  files:
    - "subject.go"
    - "subject_test.go"
  priority: P1
  status: pending
---

## Scope

SubjectBuilder：domain.resource.action.v{version} 构造与解析

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Acceptance

- [ ] NFR-006 verified via TC-006
