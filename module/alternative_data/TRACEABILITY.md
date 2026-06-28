# alternative_data 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-29
Source: [SPEC.md](./SPEC.md) v0.1.0-draft
Status: Draft — SPEC 为占位规格，FR/BR/NFR 待定义

---

## §1 功能需求追溯（FR）

> SPEC 当前为 Draft 占位规格，未定义正式 FR 编号。以下为從 SPEC §1-§3 提取的隐含功能点。

| FR ID | Requirement | AC | TC | Task | Status |
| ----- | ----------- | --- | --- | --- | ------ |
| FR-ALT-001 | 链上数据归一化 — 整合链上数据源，归一化为统一信号/特征输入 | -- | -- | -- | Draft |
| FR-ALT-002 | 社交情绪归一化 — 整合社交情绪数据源，归一化为统一信号/特征输入 | -- | -- | -- | Draft |
| FR-ALT-003 | 新闻 NLP 归一化 — 整合新闻 NLP 数据源，归一化为统一信号/特征输入 | -- | -- | -- | Draft |
| FR-ALT-004 | 聚合层分发 — 归一化后数据分发给 factor_engine / signal_factory | -- | -- | -- | Draft |

> 完整 FR/BR/NFR/AC/TC 待 SPEC 补全 23 节结构后定义。

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Status |
| ----- | ---- | -------- | --- | ------ |
| BR-ALT-001 | 不实现具体数据源爬取（→ 子模块/采集器） | -- | -- | Draft |
| BR-ALT-002 | 不实现信号生成（→ signal_factory） | -- | -- | Draft |
| BR-ALT-003 | 不实现数据持久化（聚合层只做分发协调） | -- | -- | Draft |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Status |
| ------ | -------- | ----------- | --- | ------ |
| NFR-ALT-001 | 架构 | 独立进程聚合层，与 market_data/macro_data 并列 | -- | Draft |

---

## §4 TC -> FR 反向追溯

> 待 SPEC 补全后创建。

---

## §5 全局 AC 注册表

> 待 SPEC 补全后创建。

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 4 | 0 | 0% |
| BR (业务规则) | 3 | 0 | 0% |
| NFR (非功能需求) | 1 | 0 | 0% |
| AC (验收标准) | 0 | 0 | -- |
| TC (测试用例) | 0 | 0 | -- |

> 说明：SPEC v0.1.0-draft 为占位规格。所有 FR/BR/NFR 均为從 SPEC 文本提取的隐含功能点，未正式编号。覆盖率 0%。

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线初始化：從 SPEC.md Draft 提取隐含 FR/BR/NFR 创建占位追溯矩阵 |
| 2026-06-26 | SPEC.md v0.1.0-draft 创建（占位规格） |
