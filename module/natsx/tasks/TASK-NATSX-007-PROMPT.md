# TASK-NATSX-007 实现 Prompt

## Context

TASK-NATSX-007 实现 Prompt — 本次实现背景与约束

## Scope

module/natsx/SPEC.md#module/natsx/SPEC.md#9-interface-contract

## Non-scope

- 不涉及本 Prompt 范围外的功能


## Files

envelope.go, envelope_test.go, msg.go
## Acceptance

§9: traceId/messageId/schemaVersion Header→Envelope 正确映射; §9: 已有上游 Header 不被丢弃，冲突以 Envelope 为准

## Validation

NFR-007 verified via TC-007
