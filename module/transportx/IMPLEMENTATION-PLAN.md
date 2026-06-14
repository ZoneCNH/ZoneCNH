# transportx 实现计划

> 来源：[SPEC.md](./SPEC.md)
> 生成日期：2026-06-14

---

## 1. 依赖 DAG

```text
TASK-TRANSPORTX-001 (Phase 1: foundation)
├── TASK-TRANSPORTX-002
├── TASK-TRANSPORTX-003
├── TASK-TRANSPORTX-004
├── TASK-TRANSPORTX-005
├── TASK-TRANSPORTX-006
├── TASK-TRANSPORTX-006b
├── TASK-TRANSPORTX-006c
├── TASK-TRANSPORTX-007
├── TASK-TRANSPORTX-008
├── TASK-TRANSPORTX-009
├── TASK-TRANSPORTX-010
├── TASK-TRANSPORTX-011
├── TASK-TRANSPORTX-012
├── TASK-TRANSPORTX-013
├── TASK-TRANSPORTX-014
├── TASK-TRANSPORTX-015
├── TASK-TRANSPORTX-016
├── TASK-TRANSPORTX-017
├── TASK-TRANSPORTX-018
├── TASK-TRANSPORTX-019
├── TASK-TRANSPORTX-020
├── TASK-TRANSPORTX-021
├── TASK-TRANSPORTX-022
├── TASK-TRANSPORTX-023
├── TASK-TRANSPORTX-024
├── TASK-TRANSPORTX-025
```

## 2. 实现顺序

### Phase 1: Foundation (2 tasks)

| Task | Scope | Effort |
|------|-------|--------|
| TASK-TRANSPORTX-001 | Core implementation | 2h |
| TASK-TRANSPORTX-002 | Core implementation | 2h |

### Phase 2: Features (25 tasks)

| Task | Scope | Effort |
|------|-------|--------|
| TASK-TRANSPORTX-003 | Feature implementation | 2h |
| TASK-TRANSPORTX-004 | Feature implementation | 2h |
| TASK-TRANSPORTX-005 | Feature implementation | 2h |
| TASK-TRANSPORTX-006 | Feature implementation | 2h |
| TASK-TRANSPORTX-006b | Feature implementation | 2h |
| TASK-TRANSPORTX-006c | Feature implementation | 2h |
| TASK-TRANSPORTX-007 | Feature implementation | 2h |
| TASK-TRANSPORTX-008 | Feature implementation | 2h |
| TASK-TRANSPORTX-009 | Feature implementation | 2h |
| TASK-TRANSPORTX-010 | Feature implementation | 2h |
| TASK-TRANSPORTX-011 | Feature implementation | 2h |
| TASK-TRANSPORTX-012 | Feature implementation | 2h |
| TASK-TRANSPORTX-013 | Feature implementation | 2h |
| TASK-TRANSPORTX-014 | Feature implementation | 2h |
| TASK-TRANSPORTX-015 | Feature implementation | 2h |
| TASK-TRANSPORTX-016 | Feature implementation | 2h |
| TASK-TRANSPORTX-017 | Feature implementation | 2h |
| TASK-TRANSPORTX-018 | Feature implementation | 2h |
| TASK-TRANSPORTX-019 | Feature implementation | 2h |
| TASK-TRANSPORTX-020 | Feature implementation | 2h |
| TASK-TRANSPORTX-021 | Feature implementation | 2h |
| TASK-TRANSPORTX-022 | Feature implementation | 2h |
| TASK-TRANSPORTX-023 | Feature implementation | 2h |
| TASK-TRANSPORTX-024 | Feature implementation | 2h |

### Phase 3: Quality Gates (1 task)

| TASK-TRANSPORTX-025 | CI/Benchmark/Docs | 2h |


## 3. 总 Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Foundation | 2 | 4h |
| Features | 24 | 48h |
| Quality | 1 | 2h |
| **Total** | **27** | **54h** |

## 4. CI Gate 矩阵

| Gate | Phase | 条件 |
|------|-------|------|
| go build | All | 零错误 |
| go test -race | All | 全部通过 |
| coverage >= 80% | Final | 覆盖率达标 |
| go vet | Final | 零警告 |
| golangci-lint | Final | 零错误 |
| gitleaks | Final | 零命中 |

## 5. 风险与回滚

| 风险 | 级别 | 缓解 | 回滚 |
|------|------|------|------|
| API 破坏性变更 | LOW | 已有可工作实现，向后兼容 | `git revert` |
| 外部依赖不可用 | MEDIUM | 健康检查 + 降级策略 | 回退到上一稳定版本 |
| 配置兼容性回归 | LOW | 已有 canonical+legacy 测试覆盖 | 回退配置变更 |

