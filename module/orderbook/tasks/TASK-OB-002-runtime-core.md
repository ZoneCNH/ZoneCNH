# TASK-OB-002: Runtime Core

> Status: Done
> Source: GOAL-20260709-001
> Priority: P0

## Objective

实现 adapter contract、event schema、book mutation、sequence policy 和 alignment core。[FRAME, HIGH]

## Acceptance Criteria

- `pkg/adapter` 支持 range 与 prev-link sequence policy。[FRAME, HIGH]
- `pkg/book` 支持 qty=0 deletion、排序 snapshot 和 deterministic hash。[FRAME, HIGH]
- `pkg/sync` 支持 snapshot + diff alignment。[FRAME, HIGH]

[RULES I BROKE]：无
