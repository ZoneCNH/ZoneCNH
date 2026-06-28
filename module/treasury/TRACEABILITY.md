# treasury 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-29
Source: [SPEC.md](./SPEC.md) v0.1.0-draft
Status: Draft — SPEC 为占位规格，FR/BR/NFR 待按 data_cs_module/SPEC-TEMPLATE.md 补齐

---

## §1 功能需求追溯（FR）

> SPEC 当前为 Draft 占位规格，未定义正式 FR 编号。以下为从 SPEC §1-§3 提取的隐含功能点。

| FR ID | Requirement | AC | TC | Task | Status |
| ----- | ----------- | --- | --- | --- | ------ |
| FR-TRY-001 | 国债收益率曲线采集 — 采集 Daily Treasury Par Yield Curve（1M~30Y） | -- | -- | -- | Draft |
| FR-TRY-002 | 国债拍卖数据采集 — 采集 Treasury Direct 拍卖结果与发行规模 | -- | -- | -- | Draft |
| FR-TRY-003 | TIC 数据采集 — 采集跨境资本流动月度数据 | -- | -- | -- | Draft |
| FR-TRY-004 | MacroPoint 归一化 — 归一化为 domain_macro canonical MacroPoint | -- | -- | -- | Draft |
| FR-TRY-005 | MacroDataProvider 实现 — 实现 contracts.MacroDataProvider 接口 | -- | -- | -- | Draft |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Status |
| ----- | ---- | -------- | --- | ------ |
| BR-TRY-001 | C/S Module 架构：client 采集 / server 服务 / wire 契约 | -- | -- | Draft |
| BR-TRY-002 | 通过 MacroDataProvider 接口暴露，下游只通过接口消费 | -- | -- | Draft |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Status |
| ------ | -------- | ----------- | --- | ------ |
| NFR-TRY-001 | 架构 | C/S Module 遵循 data_cs_module 标准化模板 | -- | Draft |

---

## §4 TC -> FR 反向追溯

> 待 SPEC 按 data_cs_module/SPEC-TEMPLATE.md 补齐后创建。

---

## §5 全局 AC 注册表

> 待 SPEC 补全后创建。

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 5 | 0 | 0% |
| BR (业务规则) | 2 | 0 | 0% |
| NFR (非功能需求) | 1 | 0 | 0% |
| AC (验收标准) | 0 | 0 | -- |
| TC (测试用例) | 0 | 0 | -- |

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线初始化：从 SPEC.md Draft 提取隐含 FR/BR/NFR 创建占位追溯矩阵 |
| 2026-06-26 | SPEC.md v0.1.0-draft 创建（占位规格） |
