# composer 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-30
Source: [SPEC.md](./SPEC.md) v0.1.0-draft
Status: Draft — SPEC 为占位规格，FR/BR/NFR 待定义

---

## §1 功能需求追溯（FR）

> SPEC 当前为 Draft 占位规格，未定义正式 FR 编号。以下为從 SPEC §1-§3 提取的隐含功能点。

| FR ID | Requirement | AC | TC | Task | Status |
| ----- | ----------- | --- | --- | --- | ------ |
| FR-CMP-001 | 进程编排 — 编排 25 进程全链路（data->analysis->decision->execution） | -- | -- | -- | Draft |
| FR-CMP-002 | 依赖注入与生命周期管理 — 读取配置、创建依赖、管理 Start/Stop | -- | -- | -- | Draft |
| FR-CMP-003 | HTTP health — 健康检查与就绪探针 endpoint | -- | -- | -- | Draft |
| FR-CMP-004 | Docker Compose — 25 进程编排与服务发现 | -- | -- | -- | Draft |
| FR-CMP-005 | RegimeCoordinator — dispatch->regime->engine->signal_factory 全链路协调 | -- | -- | -- | Draft |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Status |
| ----- | ---- | -------- | --- | ------ |
| BR-CMP-001 | composer 只做组装，不参与业务链路计算 | -- | -- | Draft |
| BR-CMP-002 | 不实现因子/信号/风控/订单逻辑（委托业务域模块） | -- | -- | Draft |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Status |
| ------ | -------- | ----------- | --- | ------ |
| NFR-CMP-001 | 架构 | 运行时组合根，入口包只出现 wiring / lifecycle 测试 | -- | Draft |

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
| FR (功能需求) | 5 | 0 | 0% |
| BR (业务规则) | 2 | 0 | 0% |
| NFR (非功能需求) | 1 | 0 | 0% |
| AC (验收标准) | 0 | 0 | -- |
| TC (测试用例) | 0 | 0 | -- |

> 说明：SPEC v0.1.0-draft 为占位规格。覆盖率 0%。

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线初始化：從 SPEC.md Draft 提取隐含 FR/BR/NFR 创建占位追溯矩阵 |
| 2026-06-26 | SPEC.md v0.1.0-draft 创建（占位规格） |
