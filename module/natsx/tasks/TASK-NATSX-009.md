---
TASK-NATSX-009:
  module: natsx
  scope: "可观测集成：foundationx_nats_* 指标、连接事件日志、错误脱敏"
  spec_ref:
    - "module/natsx/SPEC.md#FR-NFR-009"
    - "module/natsx/SPEC.md#18-observability"
  acceptance_criteria:
    - "AC-OBS-001: foundationx_nats_publish_total 等 counter 正确 emit"
    - "AC-OBS-002: foundationx_nats_connection_state gauge 反映连接状态"
    - "AC-OBS-003: 错误/日志不含 payload/credential 内容"
  files:
    - "natsx.go"
    - "metrics_test.go"
  priority: P1
  status: pending
---

## Scope

可观测集成：foundationx_nats_* 指标、连接事件日志、错误脱敏

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does not claim distributed tracing coverage.

## Acceptance

- [ ] NFR-009 verified via TC-009
