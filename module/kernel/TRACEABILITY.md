# kernel 需求追溯矩阵

> 自动生成：2026-06-08
> 来源：module/kernel/SPEC.md v1.1.0

---

## Functional Requirements

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
|---|---|---|---|---|---|
| FR-001 | Register：模块注册、重复检测、nil 检查、已启动后注册拒绝 | AC-001, AC-008 | TC-008, TC-015 | TASK-KERNEL-003 | Pending |
| FR-002 | Run：拓扑序启动、环检测、Init/Start 失败回滚、ctx 取消、状态检查 | AC-002, AC-004, AC-007 | TC-001, TC-002, TC-003, TC-005, TC-006, TC-018 | TASK-KERNEL-004, TASK-KERNEL-007 | Pending |
| FR-003 | Shutdown：反序停止、超时 force、ctx 取消、幂等、进行中拒绝 | AC-003, AC-007 | TC-001, TC-004, TC-011, TC-012 | TASK-KERNEL-005, TASK-KERNEL-007 | Pending |
| FR-004 | ModuleHealth：查询已注册/未注册模块健康状态 | AC-005 | TC-007, TC-009, TC-013 | TASK-KERNEL-006 | Pending |
| FR-005 | DependencyGraph：返回 GraphView 只读视图 | AC-006 | TC-010, TC-014 | TASK-KERNEL-002 | Pending |

## Business Rules

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
|---|---|---|---|---|---|
| BR-001 | 依赖图不允许环 | AC-002 | TC-002 | TASK-KERNEL-002 | Pending |
| BR-002 | 启动顺序必须是拓扑序 | AC-002 | TC-001, TC-014 | TASK-KERNEL-002, TASK-KERNEL-004 | Pending |
| BR-003 | 停止顺序必须是启动反序 | AC-003 | TC-001 | TASK-KERNEL-005 | Pending |
| BR-004 | Init 失败的模块不能进入 Start | AC-004 | TC-018 | TASK-KERNEL-004 | Pending |
| BR-005 | Health(ctx) 必须幂等、无副作用 | AC-005 | TC-009 | TASK-KERNEL-006 | Pending |
| BR-006 | Stop 超时后 force shutdown，记录未完成模块 | AC-003 | TC-004 | TASK-KERNEL-005 | Pending |
| BR-007 | panic 必须被 catch，不传播到调用方 | AC-007 | TC-006, TC-016, TC-017 | TASK-KERNEL-007 | Pending |
| BR-008 | kernel 不 import 任何非 stdlib 包 | AC-008 | CI stdlib-only gate | TASK-KERNEL-000 | Pending |
| BR-009 | Deps 中的接口类型由消费方组装时注入 | AC-008 | CI stdlib-only gate | TASK-KERNEL-001 | Pending |

## Acceptance Criteria

| AC | Description | Test Case | Task | Status |
|---|---|---|---|---|
| AC-001 | Register(nil) 返回 ErrNilModule；Register(重复名) 返回 ErrAlreadyRegistered；Register(新模块) 返回 nil | TC-008, TC-015 | TASK-KERNEL-003 | Pending |
| AC-002 | Run 按拓扑序调用 Init→Start；环依赖返回 ErrCycleDetected；失败时已启动模块被回滚 | TC-001, TC-002, TC-003, TC-005 | TASK-KERNEL-004 | Pending |
| AC-003 | Shutdown 按反序调用 Stop；超时返回 ErrShutdownTimeout；幂等返回 nil | TC-001, TC-004, TC-011, TC-012 | TASK-KERNEL-005 | Pending |
| AC-004 | Init 失败模块不进入 Start | TC-018 | TASK-KERNEL-004 | Pending |
| AC-005 | ModuleHealth 幂等无副作用 | TC-009 | TASK-KERNEL-006 | Pending |
| AC-006 | DependencyGraph 返回正确 GraphView（节点、边、拓扑序） | TC-010, TC-014 | TASK-KERNEL-002 | Pending |
| AC-007 | Start/Stop panic 被捕获转换为错误 | TC-006, TC-016, TC-017 | TASK-KERNEL-007 | Pending |
| AC-008 | kernel 包内无 L1 包 import（CI stdlib-only gate） | TC-019 | TASK-KERNEL-000, TASK-KERNEL-001 | Pending |

## Test Cases

| TC | Description | FR | BR | Task | Status |
|---|---|---|---|---|---|
| TC-001 | 正常启动和停止 | FR-002, FR-003 | BR-002, BR-003 | TASK-KERNEL-004, TASK-KERNEL-005 | Pending |
| TC-002 | 循环依赖检测 | FR-002 | BR-001 | TASK-KERNEL-002 | Pending |
| TC-003 | 启动失败回滚 | FR-002 | BR-004 | TASK-KERNEL-004 | Pending |
| TC-004 | 停止超时 | FR-003 | BR-006 | TASK-KERNEL-005 | Pending |
| TC-005 | context 取消 | FR-002 | BR-002 | TASK-KERNEL-004 | Pending |
| TC-006 | panic 隔离（Start） | FR-002 | BR-007 | TASK-KERNEL-007 | Pending |
| TC-007 | 模块未找到 | FR-004 | — | TASK-KERNEL-006 | Pending |
| TC-008 | 重复注册 | FR-001 | — | TASK-KERNEL-003 | Pending |
| TC-009 | 模块健康查询（幂等） | FR-004 | BR-005 | TASK-KERNEL-006 | Pending |
| TC-010 | 依赖图输出 | FR-005 | — | TASK-KERNEL-002 | Pending |
| TC-011 | Shutdown 幂等 | FR-003 | — | TASK-KERNEL-005 | Pending |
| TC-012 | Shutdown before Run | FR-003 | — | TASK-KERNEL-005 | Pending |
| TC-013 | Health before Run | FR-004 | — | TASK-KERNEL-006 | Pending |
| TC-014 | 深依赖链（50+ 层） | FR-005 | BR-002 | TASK-KERNEL-002 | Pending |
| TC-015 | 并发 Register 安全 | FR-001 | — | TASK-KERNEL-003 | Pending |
| TC-016 | Init panic 隔离 | FR-002 | BR-007 | TASK-KERNEL-007 | Pending |
| TC-017 | Stop panic 隔离 | FR-003 | BR-007 | TASK-KERNEL-007 | Pending |
| TC-018 | Init 失败不进入 Start | FR-002 | BR-004 | TASK-KERNEL-004 | Pending |

## Coverage Summary

| Category | Total | Covered | Gaps |
|---|---|---|---|
| FR | 5 | 5 | None |
| BR | 9 | 9 | None |
| AC | 8 | 8 | None |
| TC | 18 | 18 | None |

## 编号说明

- **AC-001 ~ AC-008**：Spec 级验收标准，定义在本文件中，是追溯矩阵的权威 AC 编号。
- **AC-NEW-xx**：Task 级 DoD（Definition of Done），定义在各 `tasks/TASK-KERNEL-*.md` 中，是任务粒度的验收检查项。AC-NEW 不替代 AC-001~008，而是对其的细化展开。例如 AC-NEW-21~AC-NEW-27 是 AC-002 的 Task 级展开。

## Traceability Rules Verification

- [x] 每个 FR 有 >=1 AC
- [x] 每个 AC 有 >=1 TC
- [x] 每个 TC 映射回 >=1 FR
- [x] 无无需求支撑的 TC
- [x] 无无测试覆盖的需求
