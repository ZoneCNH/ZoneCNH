# natsx Tasks 结构评分报告 (Claude)

- **模块**: natsx
- **阶段**: tasks
- **平台**: Claude (Opus)
- **评分时间**: 2026-06-14T08:20:00Z
- **总分**: 99 / 100
- **红线**: 无
- **裁定**: Ready-candidate
- **置信度**: high

---

## 评分摘要

| 维度 | 满分 | 扣分 | 得分 |
|------|------|------|------|
| Task 模板符合度 | 12 | -1 | 11 |
| 粒度合规 | 15 | 0 | 15 |
| spec_ref 闭合 | 15 | 0 | 15 |
| Scope/Non-scope | 12 | 0 | 12 |
| 覆盖完整性 | 15 | 0 | 15 |
| 依赖声明 | 10 | 0 | 10 |
| 测试计划 | 10 | 0 | 10 |
| 优先级与文件清单 | 11 | 0 | 11 |
| **合计** | **100** | **-1** | **99** |

---

## 扣分（1 LOW）

| ID | 扣分 | 说明 |
|----|------|------|
| D1 | -1 | NFR task（006-009,011-014）的 AC ID 为 task 级自定义前缀（AC-SBJ/ENV/CFG/OBS/SEC/PERF/REL），非 SPEC AC registry 中的编号 ID。NFR 在 SPEC 中无对应编号 AC，task 级 ID 是必要设计选择。 |

---

## Task 清单（13 个，全矩阵覆盖）

| Task | 覆盖 | 文件 | 状态 |
|------|------|------|------|
| 001 | FR-001/002, BR-001/004/009 | 5 | pending |
| 002 | FR-003, BR-003 | 2 | pending |
| 003 | FR-004/005, BR-002/007 | 3 | pending |
| 004 | FR-006/007, BR-005 | 4 | pending |
| 005 | FR-008, BR-006 | 2 | pending |
| 006 | NFR-006 SubjectBuilder | 2 | pending |
| 007 | NFR-007 Envelope | 2 | pending |
| 008 | NFR-008 Config | 4 | pending |
| 009 | NFR-009 Observability | 2 | pending |
| 011 | NFR-001/002, BR-008 Security/TLS | 2 | pending |
| 012 | NFR-003 Performance | 1 | pending |
| 013 | NFR-004 Layer boundary | 1 | pending |
| 014 | NFR-005 Release + CI gate | 5 | pending |

---

## 非 Rubric 质量差距

| 项 | 说明 |
|----|------|
| AC 描述仅成功路径 | TASK-001 至 005 未声明错误/边界场景 |
| 文件重叠 | 多个 TASK 共享 client.go / jetstream.go / msg.go |
| depends_on 隐式 | 模板标注可选，实现时可显式化 |
