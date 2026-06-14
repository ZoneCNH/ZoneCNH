---
TASK-NATSX-012:
  module: natsx
  scope: "性能验证：Publish/Request/JetStream benchmark 基线与 SLO 断言"
  spec_ref:
    - "module/natsx/SPEC.md#FR-NFR-003"
    - "module/natsx/SPEC.md#17-performance-budget"
  acceptance_criteria:
    - "AC-PERF-001: Core Publish < 1ms benchmark"
    - "AC-PERF-002: Request-Reply < 5ms benchmark"
    - "AC-PERF-003: JetStream Publish/Fetch < 2ms benchmark"
  files:
    - "benchmark_test.go"
  priority: P2
  status: pending
---

## Scope

性能验证：Publish/Request/JetStream benchmark 基线与 SLO 断言

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Production benchmark threshold enforcement remains separate.

## Acceptance

- [ ] NFR-003 verified via TC-012
