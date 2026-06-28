# bootstrap 实现计划
> 来源：[SPEC.md](./SPEC.md) | 生成日期：2026-06-29
## Phase 1: L1 Assembly
| Task | Scope | Effort |
|------|-------|--------|
| TASK-BS-001 | Build/Run/Shutdown + configx/observex/lifecycle + Stores=None | 4h |
## Phase 2: Stores
| Task | Scope | Effort |
|------|-------|--------|
| TASK-BS-005 | Stores=All 实现 | 3h |
## CI Gate
| Gate | 条件 |
|------|------|
| go build | 零错误 |
| boundary gate | 通过 |
| go vet | 零警告 |
