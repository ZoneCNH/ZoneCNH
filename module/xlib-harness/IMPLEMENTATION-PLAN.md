# xlib-harness IMPLEMENTATION-PLAN

## Phase 1: 核心生成器

- FR-001: 实现 generate 命令
- 从 xlib-standard/templates/ 读取模板
- 渲染 SPEC.md / TRACEABILITY.md / goal.md / tasks/ / IMPL-PLAN

## Phase 2: 门禁检查

- FR-002: spec-lint（23 节结构、WHEN/THEN 格式）
- FR-005: format-check（Markdown 结构、链接有效性）
- FR-006: traceability-gate（FR → AC → TC 闭合）

## Phase 3: 边界与自举

- FR-003: boundary-check（依赖矩阵、testkitx 禁止）
- FR-004: template-validate（xlib-standard 模板自举）

## Task 列表

| ID | 标题 | FR | AC |
|----|------|----|----|
| TASK-HARNESS-001 | 实现 generate 命令 | FR-001 | AC-001 |
| TASK-HARNESS-002 | 实现 spec-lint 检查 | FR-002 | AC-002 |
| TASK-HARNESS-003 | 实现 boundary-check 检查 | FR-003 | AC-003 |
| TASK-HARNESS-004 | 实现 template-validate 自举 | FR-004 | AC-004 |
| TASK-HARNESS-005 | 实现 format-check | FR-005 | AC-005 |
| TASK-HARNESS-006 | 实现 traceability-gate | FR-006 | AC-006 |

## 5. 风险与回滚

| 风险 | 级别 | 缓解 | 回滚 |
|------|------|------|------|
| API 破坏性变更 | LOW | 已有可工作实现，向后兼容 | `git revert` |
| 外部依赖不可用 | MEDIUM | 健康检查 + 降级策略 | 回退到上一稳定版本 |
| 配置兼容性回归 | LOW | 已有 canonical+legacy 测试覆盖 | 回退配置变更 |

