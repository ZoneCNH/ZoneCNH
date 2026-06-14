---
TASK-NATSX-006:
  module: natsx
  scope: "CI gate 集成、测试覆盖率、benchmark 基线、README、CHANGELOG"
  spec_ref:
    - "module/natsx/SPEC.md#20-ci-gate"
    - "module/natsx/SPEC.md#16-testing"
    - "module/natsx/SPEC.md#17-performance-budget"
    - "module/natsx/SPEC.md#22-release-dod"
  acceptance_criteria:
    - "§20: CI gate 全绿（go build / go test / go vet / lint）"
    - "§16+§17: 测试覆盖率 >= 80%，benchmark 无 >10% 回退"
    - "§22: README + CHANGELOG v1.0.0"
  files:
    - "go.mod"
    - "README.md"
    - "CHANGELOG.md"
    - "benchmark_test.go"
    - "example_test.go"
  priority: P2
  status: pending
---

## Scope

CI gate 集成、测试覆盖率、benchmark 基线、README、CHANGELOG

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement business event semantics or domain DTOs.

## Acceptance

- [ ] CI gate (build/test/vet/lint) all pass
- [ ] coverage >= 80%, benchmark no >10% regression
- [ ] README + CHANGELOG v1.0.0
