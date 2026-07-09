# orderbook Implementation Plan

> Status: Approved
> Source Goal: GOAL-20260709-001

## 1. Execution Strategy

先完成治理准入和 contract，再实现 stdlib-only runtime core，最后运行 gates 并回填 evidence。[FRAME, HIGH]

## 2. Phases

| Phase | Tasks | Output | Validation |
| --- | --- | --- | --- |
| P0 Governance | TASK-OB-001 | module/orderbook 制品 + registry proposed。[FRAME, HIGH] | 文档检查 |
| P1 Contract/Core | TASK-OB-002 | adapter/event/book/sync 包。[FRAME, HIGH] | `go test ./pkg/...` |
| P2 Replay/Gates | TASK-OB-003 | replay/quality/conformance + scripts。[FRAME, HIGH] | replay/gap/boundary gates |
| P3 Evidence | TASK-OB-004 | evidence bundle。[FRAME, HIGH] | `git diff --check` |

## 3. Rollback

若 runtime 测试失败，保留 `module/orderbook` proposed 制品并将 registry lifecycle 保持 proposed，不升级 active。[FRAME, HIGH]

若 boundary gate 失败，先修 runtime imports，不修改门禁阈值。[FRAME, HIGH]

[RULES I BROKE]：无
