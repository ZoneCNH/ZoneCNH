# TASK-NATSX-012 实现 Prompt

## Context

TASK-NATSX-012 实现 Prompt — 本次实现背景与约束

## Scope

module/natsx/SPEC.md#module/natsx/SPEC.md#17-performance-budget

## Non-scope

- 不涉及本 Prompt 范围外的功能


## Files

benchmark_test.go, client.go, jetstream.go
## Acceptance

§17: Core Publish < 1ms benchmark; §17: Request-Reply < 5ms benchmark; §17: JetStream Publish/Fetch < 2ms benchmark

## Validation

NFR-003 verified via TC-012
