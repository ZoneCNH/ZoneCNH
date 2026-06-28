# factor_eval 实现计划
> 来源：[SPEC.md](./SPEC.md) | 生成日期：2026-06-29
## Phase 1
| Task | Scope | Effort |
|------|-------|--------|
| TASK-FEV-001 | IC 分析/分层回测/因子衰减/相关性矩阵 | 4h |
## CI Gate
| Gate | 条件 |
|------|------|
| go build | 零错误 |
| go test -race | 全部通过 |
| go vet | 零警告 |
