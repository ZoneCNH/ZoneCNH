---
TASK-NATSX-014:
  module: natsx
  scope: "发布就绪：README、CHANGELOG、CI gate 集成、测试覆盖率"
  spec_ref:
    - "module/natsx/SPEC.md#20-ci-gate"
    - "module/natsx/SPEC.md#22-release-dod"
  acceptance_criteria:
    - "§20: CI gate 全绿（build/test/vet/lint/secret scan）"
    - "§22: 测试覆盖率 >= 80%，benchmark 无 >10% 回退"
    - "§22: README 含快速开始 + API 概览，CHANGELOG 记录 v1.0.0"
  files:
    - "go.mod"
    - "README.md"
    - "CHANGELOG.md"
    - "example_test.go"
    - "integration_test.go"
  priority: P2
  status: pending
---

## Scope

发布就绪：README、CHANGELOG、CI gate 集成、测试覆盖率

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Acceptance

- [ ] NFR-005 verified via TC-014
