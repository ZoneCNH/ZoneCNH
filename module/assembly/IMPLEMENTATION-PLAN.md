# assembly 实现计划
> 来源：[SPEC.md](./SPEC.md) v0.1.0 | 生成日期：2026-06-29
## Phase 1: Middleware Injection
| Task | Scope | Effort |
|------|-------|--------|
| TASK-ASM-001 | ServerDeps + Validate | 1h |
| TASK-ASM-002 | Assemble + Build | 2h |
| TASK-ASM-003 | NopMiddleware | 1h |
| TASK-ASM-004 | Test suite | 2h |
## CI Gate
| Gate | 条件 |
|------|------|
| go build | 零错误 |
| go test -race | 全部通过 |
| go vet | 零警告 |
