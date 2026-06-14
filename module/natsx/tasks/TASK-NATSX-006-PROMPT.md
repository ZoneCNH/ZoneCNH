# TASK-NATSX-006 实现 Prompt

## Context

TASK-NATSX-006 实现 Prompt — 本次实现背景与约束

## Scope

module/natsx/SPEC.md#module/natsx/SPEC.md#9-interface-contract

## Non-scope

- 不涉及本 Prompt 范围外的功能


## Files

subject.go, subject_test.go
## Acceptance

§9: Build 产出合法 subject 字符串; §9: Parse 还原 domain/resource/action/version; §9: 非法 token 拒绝并返回错误

## Validation

NFR-006 verified via TC-006
