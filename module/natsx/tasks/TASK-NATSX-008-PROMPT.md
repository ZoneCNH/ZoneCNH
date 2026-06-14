# TASK-NATSX-008 实现 Prompt

## Context

TASK-NATSX-008 实现 Prompt — 本次实现背景与约束

## Scope

module/natsx/SPEC.md#module/natsx/SPEC.md#11-config-schema

## Non-scope

- 不涉及本 Prompt 范围外的功能


## Files

config.go, config_test.go, env.go
## Acceptance

§11: foundationx.nats.* 默认值正确; §11: FOUNDATIONX_NATS_* 优先于 legacy NATS_*; §11: 配置错误不打印 token/password/nkey/credentials

## Validation

NFR-008 verified via TC-008
