# macro_data 实现计划

> 来源：[SPEC.md](./SPEC.md) v0.1.0 | 生成日期：2026-06-29

## Phase 1: Dispatch Port

| Task | Scope | Effort |
|------|-------|--------|
| TASK-MACD-001-core-implementation | Implementation | 2h |
## Pre-Gates

| Gate | 条件 |
|------|------|
| Contract Gate | MacroDataProvider 已定义 |
| Domain Gate | domain_macro 运行时发布 MacroPoint |

## CI Gate

| Gate | 条件 |
|------|------|
| go build | 零错误 |
| go test -race | 全部通过 |
| go vet | 零警告 |

## 风险

| 风险 | 缓解 |
|------|------|
| domain_macro 运行时待冻结 | 先完成 docs baseline，runtime 后续 |
