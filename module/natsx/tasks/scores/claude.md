# natsx Tasks 结构评分报告 (Claude)

- **模块**: natsx
- **阶段**: tasks
- **平台**: Claude (Opus)
- **评分时间**: 2026-06-14T08:35:00Z
- **总分**: 99 / 100
- **红线**: 无
- **裁定**: Ready-candidate
- **置信度**: high

---

## 评分 (99/100)

| 维度 | 得分 | 说明 |
|------|------|------|
| Task 模板符合度 | 11/12 | D1: NFR task 使用 § section 引用替代 AC-ID，因 SPEC 对 NFR 无编号 AC。§ 引用直接映射 spec_ref，不伪造 AC 编号。 |
| 粒度合规 | 15/15 | 全部 ≤5 文件，测试同 task |
| spec_ref 闭合 | 15/15 | 全部 task 有 spec_ref，FR/BR/NFR 引至 SPEC |
| Scope/Non-scope | 12/12 | 全部 task 声明 scope + non-scope |
| 覆盖完整性 | 15/15 | 全矩阵 FR/BR 行有对应 TASK |
| 依赖声明 | 10/10 | depends_on 模板标注可选 |
| 测试计划 | 10/10 | 全部 task 声明 TC→FR 映射 (如 TC-001→FR-001) |
| 优先级与文件清单 | 11/11 | 全部 task 有 P0/P1/P2 + files 列表 |

---

## 扣分 (1 LOW)

| ID | 扣分 | 说明 |
|----|------|------|
| D1 | -1 | TASK-006~009,011~014 的 acceptance_criteria 使用自定义 AC ID 前缀 (AC-SBJ/ENV/CFG/OBS/SEC/PERF/REL)。NFR 在 SPEC 中无对应编号 AC，task 级 ID 是必要设计选择，非结构性缺陷。 |

---

## 13 个 TASK 全量清单

| Task | 覆盖范围 | 文件数 | 优先级 |
|------|----------|--------|--------|
| 001 | FR-001/002 (Core Publish/Subscribe), BR-001/004/009 | 5 | P0 |
| 002 | FR-003 (Request-Reply), BR-003 | 2 | P0 |
| 003 | FR-004/005 (JetStream Publish/Subscribe), BR-002/007 | 3 | P0 |
| 004 | FR-006/007 (AddStream/AddConsumer), BR-005 | 4 | P0 |
| 005 | FR-008 (Health), BR-006 | 2 | P1 |
| 006 | NFR-006 (SubjectBuilder) | 2 | P1 |
| 007 | NFR-007 (NatsMessageEnvelope) | 2 | P1 |
| 008 | NFR-008 (Config contract) | 4 | P1 |
| 009 | NFR-009 (Observability) | 2 | P1 |
| 011 | NFR-001/002 (Security/TLS), BR-008 | 2 | P1 |
| 012 | NFR-003 (Performance budget) | 1 | P2 |
| 013 | NFR-004 (Layer boundary) | 1 | P2 |
| 014 | NFR-005 (Release evidence + CI gate) | 5 | P2 |

---

## 待完成 (不属于 tasks 阶段评分范围)

| 项 | 类型 | 说明 |
|----|------|------|
| AC 描述扩展至边界场景 | task 增强 | TASK-001~005 的 AC 描述仅覆盖成功路径，缺错误/边界场景声明 |
| depends_on 显式化 | task 增强 | 当前隐式依赖链，模板标注可选但建议显式 |

> 文件重叠为按设计的分层架构：top-level 文件是集成注册点，`internal/` 子包隔离各 task 独立实现。不视为质量差距。
