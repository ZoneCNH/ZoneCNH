# xlib-harness TRACEABILITY

## §1 FR 表

| FR | 名称 | 验收标准（AC） | 测试用例（TC） |
|----|------|---------------|---------------|
| FR-001 | generate-module | AC-001: 生成目录包含 SPEC.md/TRACEABILITY.md/goal.md/tasks//IMPLEMENTATION-PLAN.md | TC-001: 空目录执行 generate 后文件齐全 |
| FR-002 | spec-lint | AC-002: 检查 23 节结构、WHEN/THEN 格式、AC 可验证性 | TC-002: 合规模块通过；不合规模块逐项报告 |
| FR-003 | boundary-check | AC-003: 验证依赖矩阵、production-import-testkitx、stdlib-only | TC-003: 违规依赖被检出 |
| FR-004 | template-validate | AC-004: xlib-standard 模板自身通过所有检查 | TC-004: 模板自举验证通过 |
| FR-005 | format-check | AC-005: Markdown 结构、链接有效性、表格对齐 | TC-005: 格式问题逐项输出 |
| FR-006 | traceability-gate | AC-006: FR → AC → TC 全链路闭合 | TC-006: 断开链路被检出并报告缺口 |

## §2 BR 表

| BR | 规则 | 验证方式 |
|----|------|---------|
| BR-001 | generate 5s 内完成 | benchmark test |
| BR-002 | check 不修改被检文件 | 前后文件 hash 对比 |
| BR-003 | check 失败非零退出 | exit code 验证 |

## §3 TC → FR 反向追溯

| TC | 覆盖 FR |
|----|--------|
| TC-001 | FR-001 |
| TC-002 | FR-002 |
| TC-003 | FR-003 |
| TC-004 | FR-004 |
| TC-005 | FR-005 |
| TC-006 | FR-006 |

## §4 FR → Task 映射

| FR | Task ID |
|----|---------|
| FR-001 | TASK-HARNESS-001 |
| FR-002 | TASK-HARNESS-002 |
| FR-003 | TASK-HARNESS-003 |
| FR-004 | TASK-HARNESS-004 |
| FR-005 | TASK-HARNESS-005 |
| FR-006 | TASK-HARNESS-006 |

## §5 AC 注册表

| AC | 类型 | 验证人 | 状态 |
|----|------|--------|------|
| AC-001 | 功能 | CI | pending |
| AC-002 | 功能 | CI | pending |
| AC-003 | 功能 | CI | pending |
| AC-004 | 功能 | CI | pending |
| AC-005 | 功能 | CI | pending |
| AC-006 | 功能 | CI | pending |
