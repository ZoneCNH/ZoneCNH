# xlib-harness TRACEABILITY

## §1 FR 表

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | generate-module | AC-001: 生成目录包含 SPEC.md/TRACEABILITY.md/goal.md/tasks//IMPLEMENTATION-PLAN.md | TC-001 | TASK-HARNESS-001 | Pending |
| FR-002 | spec-lint | AC-002: 检查 23 节结构、WHEN/THEN 格式、AC 可验证性 | TC-002 | TASK-HARNESS-002 | Pending |
| FR-003 | boundary-check | AC-003: 验证依赖矩阵、production-import-testkitx、stdlib-only | TC-003 | TASK-HARNESS-003 | Pending |
| FR-004 | template-validate | AC-004: xlib-standard 模板自身通过所有检查 | TC-004 | TASK-HARNESS-004 | Pending |
| FR-005 | format-check | AC-005: Markdown 结构、链接有效性、表格对齐 | TC-005 | TASK-HARNESS-005 | Pending |
| FR-006 | traceability-gate | AC-006: FR → AC → TC 全链路闭合 | TC-006 | TASK-HARNESS-006 | Pending |

## §2 BR 表

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- |
| BR-001 | generate 5s 内完成 | benchmark test | TC-001 | TASK-HARNESS-001 | Pending |
| BR-002 | check 不修改被检文件 | 前后文件 hash 对比 | TC-002 | TASK-HARNESS-002 | Pending |
| BR-003 | check 失败非零退出 | exit code 验证 | TC-006 | TASK-HARNESS-006 | Pending |

## §3 TC → FR 反向追溯

| Test Case | 覆盖 FR |
| --- | --- |
| TC-001 | FR-001 |
| TC-002 | FR-002 |
| TC-003 | FR-003 |
| TC-004 | FR-004 |
| TC-005 | FR-005 |
| TC-006 | FR-006 |

## §4 FR → Task 映射

| Requirement Ref | Task ID |
| --- | --- |
| Harness FR-001 | TASK-HARNESS-001 |
| Harness FR-002 | TASK-HARNESS-002 |
| Harness FR-003 | TASK-HARNESS-003 |
| Harness FR-004 | TASK-HARNESS-004 |
| Harness FR-005 | TASK-HARNESS-005 |
| Harness FR-006 | TASK-HARNESS-006 |

## §5 AC 注册表

| AC | 类型 | 验证人 | 状态 |
| --- | --- | --- | --- |
| AC-001 | 功能 | CI | pending |
| AC-002 | 功能 | CI | pending |
| AC-003 | 功能 | CI | pending |
| AC-004 | 功能 | CI | pending |
| AC-005 | 功能 | CI | pending |
| AC-006 | 功能 | CI | pending |
