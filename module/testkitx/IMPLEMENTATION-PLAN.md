# testkitx 实现计划

> 来源：[SPEC.md](./SPEC.md)
> 生成日期：2026-06-14

---

## 1. 依赖 DAG

```text
TASK-TESTKITX-000 (Phase 1: foundation)
├── TASK-TESTKITX-001
├── TASK-TESTKITX-002
├── TASK-TESTKITX-003
├── TASK-TESTKITX-004
├── TASK-TESTKITX-005
├── TASK-TESTKITX-006
├── TASK-TESTKITX-007
├── TASK-TESTKITX-008
├── TASK-TESTKITX-009
├── TASK-TESTKITX-010
```

## 2. 实现顺序

### Phase 1: Foundation (2 tasks)

| Task | Scope | Effort |
|------|-------|--------|
| TASK-TESTKITX-000 | Core implementation | 2h |
| TASK-TESTKITX-001 | Core implementation | 2h |

### Phase 2: Features (9 tasks)

| Task | Scope | Effort |
|------|-------|--------|
| TASK-TESTKITX-002 | Feature implementation | 2h |
| TASK-TESTKITX-003 | Feature implementation | 2h |
| TASK-TESTKITX-004 | Feature implementation | 2h |
| TASK-TESTKITX-005 | Feature implementation | 2h |
| TASK-TESTKITX-006 | Feature implementation | 2h |
| TASK-TESTKITX-007 | Feature implementation | 2h |
| TASK-TESTKITX-008 | Feature implementation | 2h |
| TASK-TESTKITX-009 | Feature implementation | 2h |

### Phase 3: Quality Gates (1 task)

| TASK-TESTKITX-010 | CI/Benchmark/Docs | 2h |


## 3. 总 Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Foundation | 2 | 4h |
| Features | 8 | 16h |
| Quality | 1 | 2h |
| **Total** | **11** | **22h** |

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

