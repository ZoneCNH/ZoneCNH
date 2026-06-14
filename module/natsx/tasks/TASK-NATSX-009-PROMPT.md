# TASK-NATSX-009 实现 Prompt

## Context

TASK-NATSX-009 实现 Prompt — 本次实现背景与约束

## Scope

module/natsx/SPEC.md#module/natsx/SPEC.md#18-observability

## Non-scope

- 不涉及本 Prompt 范围外的功能


## Files

metrics.go, health_test.go, client.go
## Acceptance

§18: foundationx_nats_publish_total 等 counter 正确 emit; §18: foundationx_nats_connection_state gauge 反映连接状态; §18: 错误/日志不含 payload/credential 内容

## Validation

NFR-009 verified via TC-009
