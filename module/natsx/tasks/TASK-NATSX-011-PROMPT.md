# TASK-NATSX-011 实现 Prompt

## Context

TASK-NATSX-011 实现 Prompt — 本次实现背景与约束

## Scope

module/natsx/SPEC.md#module/natsx/SPEC.md#19-security, module/natsx/SPEC.md#BR-008

## Non-scope

- 不涉及本 Prompt 范围外的功能

## Acceptance

§19: FOUNDATIONX_NATS_TOKEN/USERNAME/PASSWORD/NKEY 安全加载; §19: TLS ca-file 可配置，配置错误不泄露凭据; §19: live integration 测试通过且输出不含凭据

## Validation

NFR-001 verified via TC-011; NFR-002 verified via TC-011
