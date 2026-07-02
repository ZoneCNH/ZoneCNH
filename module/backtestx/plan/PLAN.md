# backtestx 实现计划

> 来源：[SPEC.md](./SPEC.md) v1.0.0 | 生成日期：2026-06-29

## Phase 1: Core Engine

| Task | Scope | Effort |
|------|-------|--------|
| AC-BTX-001 | Implementation | 2h |
| AC-BTX-002 | Implementation | 2h |
| AC-BTX-003 | Implementation | 2h |
| AC-BTX-004 | Implementation | 2h |
| AC-BTX-005 | Implementation | 2h |
| AC-BTX-006 | Implementation | 2h |
| AC-BTX-007 | Implementation | 2h |
| AC-BTX-008 | Implementation | 2h |
| README | Implementation | 2h |
| TASK-BTX-001-core-implementation | Implementation | 2h |
## CI Gate

| Gate | 条件 |
|------|------|
| go build | 零错误 |
| go test -race | 全部通过 |
| coverage >= 80% | 达标 |
| go vet | 零警告 |

## 风险

| 风险 | 缓解 |
|------|------|
| 回测结果可重现性 | deterministic seed + snapshot |
