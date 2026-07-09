# TASK-OB-003: Replay And Gates

> Status: Done
> Source: GOAL-20260709-001
> Priority: P0

## Objective

实现 ReplayRunner、QualityTimeline、Conformance runner 和 boundary/replay/gap gate 脚本。[FRAME, HIGH]

## Acceptance Criteria

- 同一 fixture replay 100 次 hash 一致。[FRAME, HIGH]
- gap injection 产生 unreliable quality。[FRAME, HIGH]
- boundary gate 不发现 forbidden import。[FRAME, HIGH]

[RULES I BROKE]：无
