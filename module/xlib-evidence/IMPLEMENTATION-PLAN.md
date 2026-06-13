# xlib-evidence IMPLEMENTATION-PLAN

## Phase 1: 核心收集与生成

- FR-001: 实现覆盖率收集（go test -cover 解析）
- FR-002: 实现 Release Manifest 生成

## Phase 2: 验证与报告

- FR-003: 实现 manifest 验证（hash 校验 + 门禁完整性）
- FR-005: 实现多模块统一证据报告

## Phase 3: 远程证据

- FR-004: 实现远程证据查询（HTTP endpoint）

## Task 列表

| ID | 标题 | FR | AC |
|----|------|----|----|
| TASK-EVIDENCE-001 | 实现覆盖率收集 | FR-001 | AC-001 |
| TASK-EVIDENCE-002 | 实现 Release Manifest 生成 | FR-002 | AC-002 |
| TASK-EVIDENCE-003 | 实现 Manifest 验证 | FR-003 | AC-003 |
| TASK-EVIDENCE-004 | 实现远程证据查询 | FR-004 | AC-004 |
| TASK-EVIDENCE-005 | 实现多模块统一报告 | FR-005 | AC-005 |
