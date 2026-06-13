# xlib-evidence TRACEABILITY

## §1 FR 表

| FR | 名称 | 验收标准（AC） | 测试用例（TC） |
|----|------|---------------|---------------|
| FR-001 | collect-coverage | AC-001: 覆盖率数据被结构化收集 | TC-001: mock 覆盖率输出 → CoverageReport 正确 |
| FR-002 | generate-manifest | AC-002: 门禁全绿时生成 manifest，含 version/commitSHA/gates/coverage | TC-002: 给定全部门禁通过 → manifest 生成且 hash 有效 |
| FR-003 | validate-manifest | AC-003: manifest hash 校验通过；篡改检测失败 | TC-003: 合法 manifest 通过；篡改 manifest 拒绝 |
| FR-004 | remote-evidence | AC-004: 远程查询返回结构化证据 | TC-004: HTTP endpoint 返回 JSON 证据 |
| FR-005 | evidence-report | AC-005: 多模块聚合报告含全部模块状态 | TC-005: 3 模块输入 → 统合报告列出全部状态 |

## §2 BR 表

| BR | 规则 | 验证方式 |
|----|------|---------|
| BR-001 | manifest 含门禁全绿证据 | 生成 manifest 前校验门禁结果 |
| BR-002 | 覆盖率 < 80% 拒绝发布 | 覆盖率边界测试 |
| BR-003 | manifest hash 链防篡改 | hash 校验 golden |
| BR-004 | evidence 不可变追加 | append-only 存储测试 |

## §3 TC → FR 反向追溯

| TC | 覆盖 FR |
|----|--------|
| TC-001 | FR-001 |
| TC-002 | FR-002 |
| TC-003 | FR-003 |
| TC-004 | FR-004 |
| TC-005 | FR-005 |

## §4 FR → Task 映射

| FR | Task ID |
|----|---------|
| FR-001 | TASK-EVIDENCE-001 |
| FR-002 | TASK-EVIDENCE-002 |
| FR-003 | TASK-EVIDENCE-003 |
| FR-004 | TASK-EVIDENCE-004 |
| FR-005 | TASK-EVIDENCE-005 |

## §5 AC 注册表

| AC | 类型 | 验证人 | 状态 |
|----|------|--------|------|
| AC-001 | 功能 | CI | pending |
| AC-002 | 功能 | CI | pending |
| AC-003 | 功能 | CI | pending |
| AC-004 | 功能 | CI | pending |
| AC-005 | 功能 | CI | pending |
