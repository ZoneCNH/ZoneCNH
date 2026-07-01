# pe_data 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-30
Source: [SPEC.md](./SPEC.md) v0.1.0-draft
Status: Draft — SPEC 已定义 FR-001~005 + BR-001~004，完整 FR/BR/NFR 待补全

---

## §1 功能需求追溯（FR）

| FR ID | Requirement | AC | TC | Task | Status |
| ----- | ----------- | --- | --- | --- | ------ |
| FR-001 | 13F 数据采集 — 爬取 SEC EDGAR 13F 季度机构持仓，映射到 InstrumentKey | AC-PE-001 | TC-PE-001 | TASK-PE-001 | Draft |
| FR-002 | 内部人交易采集 — 采集 Form 4 内部人交易，标记 is_cluster | AC-PE-002 | TC-PE-002 | TASK-PE-002 | Draft |
| FR-003 | 机构持仓变化检测 — 计算 institutional_flow + ownership_concentration + new_buyers_count | AC-PE-003 | TC-PE-003 | TASK-PE-003 | Draft |
| FR-004 | PE 事件归一化 — 归一化为 canonical PEvent{Type/InstrumentKey/Timestamp/Data/RawMetadata/Quality} | AC-PE-004 | TC-PE-004 | TASK-PE-004 | Draft |
| FR-005 | 数据时效性管理 — 超期未刷新标记 STALE，恢复后自动 CURRENT | AC-PE-005 | TC-PE-005 | TASK-PE-005 | Draft |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Status |
| ----- | ---- | -------- | --- | ------ |
| BR-PE-001 | 免费数据源遵守 rate limit，不得触发 IP ban | -- | TASK-PE-006 | Draft |
| BR-PE-002 | 通过 AlternativeDataProvider 接口暴露，下游只通过接口消费 | -- | TASK-PE-007 | Draft |
| BR-PE-003 | 季频数据缺失标记 NaN，不填零 | -- | TASK-PE-008 | Draft |
| BR-PE-004 | 内部人交易仅用公开申报，不抓非公开信息 | -- | TASK-PE-009 | Draft |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Status |
| ------ | -------- | ----------- | --- | ------ |
| NFR-PE-001 | 架构 | 实现 contracts.AlternativeDataProvider 接口 | TASK-PE-010 | Draft |
| NFR-PE-002 | 数据质量 | PEvent.Quality 含 source/freshness/completeness 三维度 | TASK-PE-004 | Draft |

---

## §4 TC -> FR 反向追溯

| TC ID | Covers FR | 测试类型 | Status |
| ----- | --------- | -------- | ------ |
| TC-PE-001 | FR-001 | 集成（SEC EDGAR 13F 爬取） | Draft |
| TC-PE-002 | FR-002 | 集成（Form 4 内部人交易） | Draft |
| TC-PE-003 | FR-003 | 单元（持仓变化计算） | Draft |
| TC-PE-004 | FR-004 | 单元（canonical PEvent 归一化） | Draft |
| TC-PE-005 | FR-005 | 集成（STALE/CURRENT 状态机） | Draft |

---

## §5 全局 AC 注册表

> 待 SPEC 补全后创建。

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 5 | 0 | 0% |
| BR (业务规则) | 4 | 0 | 0% |
| NFR (非功能需求) | 2 | 0 | 0% |
| AC (验收标准) | 0 | 0 | -- |
| TC (测试用例) | 0 | 0 | -- |

> 说明：SPEC v0.1.0-draft 仅定义 FR-001~005 + BR-001~004。Task 总数 = TASK-PE-001~010 共 10 项。

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线初始化：从 SPEC.md v0.1.0-draft 提取 FR/BR 创建占位追溯矩阵 |
| 2026-06-17 | SPEC.md v0.1.0-draft 创建 |
