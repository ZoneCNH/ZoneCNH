# xlib-evidence TRACEABILITY

## §1 FR 表

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | collect-coverage | AC-001: 覆盖率数据被结构化收集 | TC-001 | TASK-EVIDENCE-001 | Pending |
| FR-002 | generate-manifest | AC-002: 门禁全绿时生成 manifest，含 version/commitSHA/gates/coverage | TC-002 | TASK-EVIDENCE-002 | Pending |
| FR-003 | validate-manifest | AC-003: manifest hash 校验通过；篡改检测失败 | TC-003 | TASK-EVIDENCE-003 | Pending |
| FR-004 | remote-evidence | AC-004: 远程查询返回结构化证据 | TC-004 | TASK-EVIDENCE-004 | Pending |
| FR-005 | evidence-report | AC-005: 多模块聚合报告含全部模块状态 | TC-005 | TASK-EVIDENCE-005 | Pending |

## §2 BR 表

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- |
| BR-001 | manifest 含门禁全绿证据 | 生成 manifest 前校验门禁结果 | TC-002 | TASK-EVIDENCE-002 | Pending |
| BR-002 | 覆盖率 < 80% 拒绝发布 | 覆盖率边界测试 | TC-001 | TASK-EVIDENCE-001 | Pending |
| BR-003 | manifest hash 链防篡改 | hash 校验 golden | TC-003 | TASK-EVIDENCE-003 | Pending |
| BR-004 | evidence 不可变追加 | append-only 存储测试 | TC-005 | TASK-EVIDENCE-005 | Pending |

## §3 TC → FR 反向追溯

| Test Case | 覆盖 FR |
| --- | --- |
| TC-001 | FR-001 |
| TC-002 | FR-002 |
| TC-003 | FR-003 |
| TC-004 | FR-004 |
| TC-005 | FR-005 |

## §4 FR → Task 映射

| Requirement Ref | Task ID |
| --- | --- |
| Evidence FR-001 | TASK-EVIDENCE-001 |
| Evidence FR-002 | TASK-EVIDENCE-002 |
| Evidence FR-003 | TASK-EVIDENCE-003 |
| Evidence FR-004 | TASK-EVIDENCE-004 |
| Evidence FR-005 | TASK-EVIDENCE-005 |

## §5 AC 注册表

| AC | 类型 | 验证人 | 状态 |
| --- | --- | --- | --- |
| AC-001 | 功能 | CI | pending |
| AC-002 | 功能 | CI | pending |
| AC-003 | 功能 | CI | pending |
| AC-004 | 功能 | CI | pending |
| AC-005 | 功能 | CI | pending |
