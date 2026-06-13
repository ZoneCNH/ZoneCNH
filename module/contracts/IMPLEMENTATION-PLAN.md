# contracts 实现计划

> 来源：[SPEC.md](./SPEC.md)
> 生成日期：2026-06-14

---

## 1. 依赖 DAG

```text
TASK-CONTRACTS-000 (Phase 1: foundation)
├── TASK-CONTRACTS-001
├── TASK-CONTRACTS-002
├── TASK-CONTRACTS-003
├── TASK-CONTRACTS-004
```

## 2. 实现顺序

### Phase 1: Foundation (2 tasks)

| Task | Scope | Effort |
|------|-------|--------|
| TASK-CONTRACTS-000 | Core implementation | 2h |
| TASK-CONTRACTS-001 | Core implementation | 2h |

### Phase 2: Features (3 tasks)

| Task | Scope | Effort |
|------|-------|--------|
| TASK-CONTRACTS-002 | Feature implementation | 2h |
| TASK-CONTRACTS-003 | Feature implementation | 2h |

### Phase 3: Quality Gates (1 task)

| TASK-CONTRACTS-004 | CI/Benchmark/Docs | 2h |


## 3. 总 Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Foundation | 2 | 4h |
| Features | 2 | 4h |
| Quality | 1 | 2h |
| **Total** | **5** | **10h** |

## 4. CI Gate 矩阵

| Gate | Phase | 条件 |
|------|-------|------|
| go build | All | 零错误 |
| go test -race | All | 全部通过 |
| coverage >= 80% | Final | 覆盖率达标 |
| go vet | Final | 零警告 |
| golangci-lint | Final | 零错误 |
| gitleaks | Final | 零命中 |
