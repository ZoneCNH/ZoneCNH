# x.go 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-29
Source: [SPEC.md](./SPEC.md) v0.1.0-draft
Status: Draft — x.go 是治理/工具 CLI，非业务模块

> x.go 是开发期工具 CLI（goalcli + templatex），不参与运行时进程组装。`module/README.md` §1 声明"x.go 组合根不再作为 module/ 下的模块规格维护"；本矩阵为治理完整性占位。

---

## §1 功能需求追溯（FR）

| FR ID | Requirement | AC | TC | Task | Status |
| ----- | ----------- | --- | --- | --- | ------ |
| FR-XGO-001 | goalcli — Goal 驱动交付工作流命令行（preflight/validate/gate/release/ci） | -- | -- | -- | Draft |
| FR-XGO-002 | templatex — 模板生成、脚手架、spec-lint 等治理工具 | -- | -- | -- | Draft |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Status |
| ----- | ---- | -------- | --- | ------ |
| BR-XGO-001 | x.go 不参与运行时进程组装（-> composer） | -- | -- | Draft |
| BR-XGO-002 | x.go 不承载业务语义（是工具 CLI，非业务模块） | -- | -- | Draft |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Status |
| ------ | -------- | ----------- | --- | ------ |
| NFR-XGO-001 | 命名 | 含点号，CONSTITUTION.md §7.2 命名例外 | -- | Draft |

---

## §4 TC -> FR 反向追溯

> 工具 CLI 模块，不适用传统 FR/TC 追溯。

---

## §5 全局 AC 注册表

> 工具 CLI 模块，不适用传统 AC 注册。

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 2 | 0 | 0% |
| BR (业务规则) | 2 | 0 | 0% |
| NFR (非功能需求) | 1 | 0 | 0% |

> 说明：x.go 是治理 CLI 工具模块，非业务模块。覆盖率 0%。

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线初始化：从 SPEC.md Draft 提取隐含 FR/BR/NFR 创建占位追溯矩阵 |
| 2026-06-26 | SPEC.md v0.1.0-draft 创建（占位规格） |
