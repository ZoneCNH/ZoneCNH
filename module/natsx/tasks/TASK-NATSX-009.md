---
TASK-NATSX-009:
  module: natsx
  scope: "可观测集成：foundationx_nats_* 指标、连接事件日志、错误脱敏"
  spec_ref:
    - "module/natsx/SPEC.md#18-observability"
  acceptance_criteria:
    - "§18: foundationx_nats_publish_total 等 counter 正确 emit"
    - "§18: foundationx_nats_connection_state gauge 反映连接状态"
    - "§18: 错误/日志不含 payload/credential 内容"
  files:
    - "natsx.go"
    - "metrics_test.go"
  priority: P1
  status: pending
---

## Scope

可观测集成：foundationx_nats_* 指标、连接事件日志、错误脱敏

## Non-Scope

Does not claim distributed tracing coverage.

## Acceptance

- [ ] NFR-009 verified via TC-009
