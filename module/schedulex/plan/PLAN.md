# schedulex 实现计划

> 来源：[SPEC.md](./SPEC.md)
> 生成日期：2026-06-14

---

## 1. 依赖 DAG

```text
TASK-SCHEDULEX-000 (Phase 1: foundation)
├── TASK-SCHEDULEX-001
├── TASK-SCHEDULEX-002
├── TASK-SCHEDULEX-003
├── TASK-SCHEDULEX-004
├── TASK-SCHEDULEX-005
├── TASK-SCHEDULEX-006
├── TASK-SCHEDULEX-007
├── TASK-SCHEDULEX-008
├── TASK-SCHEDULEX-009
├── TASK-SCHEDULEX-010
├── TASK-SCHEDULEX-011
```

## 2. 实现顺序

### Phase 1: Foundation (2 tasks)

| Task | Scope | Effort |
|------|-------|--------|
| TASK-SCHEDULEX-000 | Implementation | 2h |
| TASK-SCHEDULEX-001 | Implementation | 2h |
| TASK-SCHEDULEX-002 | Implementation | 2h |
| TASK-SCHEDULEX-003 | Implementation | 2h |
| TASK-SCHEDULEX-004 | Implementation | 2h |
| TASK-SCHEDULEX-005 | Implementation | 2h |
| TASK-SCHEDULEX-006 | Implementation | 2h |
| TASK-SCHEDULEX-007 | Implementation | 2h |
| TASK-SCHEDULEX-008 | Implementation | 2h |
| TASK-SCHEDULEX-009 | Implementation | 2h |
| TASK-SCHEDULEX-010 | Implementation | 2h |
| TASK-SCHEDULEX-011 | Implementation | 2h |
## 3. 总 Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Foundation | 2 | 4h |
| Features | 9 | 18h |
| Quality | 1 | 2h |
| **Total** | **12** | **24h** |

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

