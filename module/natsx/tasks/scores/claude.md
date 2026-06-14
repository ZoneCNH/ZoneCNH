# natsx Tasks 结构评分报告 (Claude)

- **模块**: natsx
- **阶段**: tasks
- **平台**: Claude (Opus)
- **评分时间**: 2026-06-14T08:10:00Z
- **总分**: 98 / 100
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
| 测试计划 | 10 | -1 | 9 |
| 优先级与文件清单 | 11 | 0 | 11 |
| **合计** | **100** | **-2** | **98** |

---

## 扣分（2 条，均为 LOW）

| ID | 扣分 | 说明 |
|----|------|------|
| D1 | -1 | TASK-006 acceptance_criteria 使用 § 引用替代 AC-ID |
| D2 | -1 | 验证条目未附执行命令 |

---

## Task 清单

| Task | 覆盖 | 文件数 | 状态 |
|------|------|--------|------|
| 001 | FR-001/002, BR-001/004/009 | 5 | pending |
| 002 | FR-003, BR-003 | 2 | pending |
| 003 | FR-004/005, BR-002/007 | 3 | pending |
| 004 | FR-006/007, BR-005 | 4 | pending |
| 005 | FR-008, BR-006 | 2 | pending |
| 006 | NFR-006 (SubjectBuilder) | 2 | pending |
| 007 | NFR-007 (Envelope) | 2 | pending |
| 008 | NFR-008 (Config) | 4 | pending |
| 009 | NFR-009 (Observability) | 2 | pending |
| 011 | NFR-001/002, BR-008 | 2 | pending |
| 012 | NFR-003 (Performance) | 1 | pending |
| 013 | NFR-004 (Layer) | 1 | pending |
| 014 | NFR-005 (Release + CI gate) | 5 | pending |

---

## 非 Rubric 质量差距（不扣分）

| 项 | 说明 |
|----|------|
| AC 描述仅成功路径 | TASK-001 至 005 的 AC 未声明错误/边界场景 |
| 文件重叠 | TASK-001/002 共享 client.go；003/004 共享 jetstream.go；001/007 共享 msg.go |
| depends_on 隐式 | 模板标注可选，实现时可显式化 |
