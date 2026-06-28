# xlibgate 实现计划
> 来源：[SPEC.md](./SPEC.md) | 生成日期：2026-06-29
## Phase 1: Check Commands
| Task | Scope | Effort |
|------|-------|--------|
| TASK-XLIBGATE-002 | check imports | 2h
| TASK-XLIBGATE-003 | check gomod | 1h
| TASK-XLIBGATE-004 | check baseline | 1h
| TASK-XLIBGATE-005 | check release | 2h
| TASK-XLIBGATE-006 | check all + output | 2h
## Phase 2: Trust Commands
| Task | Scope | Effort |
|------|-------|--------|
| TASK-XLIBGATE-011 | trust identity | 2h
| TASK-XLIBGATE-012 | trust template-residue | 1h
| TASK-XLIBGATE-013 | trust release-consistency | 2h
| TASK-XLIBGATE-018 | trust fleet-status | 2h
## CI Gate
| Gate | 条件 |
|------|------|
| go build | 零错误 |
| go test -race | 全部通过 |
| coverage >= 80% | 达标 |
| go vet | 零警告 |
| gitleaks | 零命中 |
