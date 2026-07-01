# bootstrap 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-30
Source: SPEC.md, FEATURES.md, ACCEPTANCE.md
Runtime-Repo: /home/workspace/bootstrap

> 本矩阵补齐 bootstrap 的 FEATURES/ACCEPTANCE 追溯输入。v0.1.0 仅 Stores=None 路径已发布；非 None 存储构造、foundationx 清零与 Spec Approved 属于 v0.2.0 准入。

---

## §1 功能需求追溯（FR）

| FR | 需求摘要 | AC | TC ID(s) | Task | 当前状态 |
| --- | --- | --- | --- | --- | --- |
| FR-001 | Build 入口 | AC-001 | TC-001, TC-003 | TASK-BS-001 | v0.1.0 Stores=None 已发布；需运行 `TestBuildAdapter` 与 `TestBuildEmptyModule` 复验 |
| FR-002 | configx 加载 | AC-002 | TC-001 | TASK-BS-002 | 已登记；需单测或人工审查证据 |
| FR-003 | observex 初始化 | AC-003 | TC-005, TC-006, TC-007 | TASK-BS-003 | v0.1.0 已发布；需 lifecycle 测试与 CI 证据复验 |
| FR-004 | stores 可选构造 | AC-004 | TC-002, TC-004 | TASK-BS-001, TASK-BS-005 | Stores=None 已发布；非 None 存储构造为 v0.2.0 准入 |
| FR-005 | lifecycle 编排 | AC-003 | TC-005, TC-006, TC-007 | TASK-BS-003 | 已登记；需运行时复验 |
| FR-006 | 组件注册 | AC-003 | TC-005, TC-006 | TASK-BS-003 | 已登记；需运行时复验 |
| FR-007 | 信号捕获 | AC-003 | TC-005 | TASK-BS-003 | 已登记；需运行时复验 |
| FR-008 | EffectiveConfigHash 暴露 | AC-002 | TC-001 | TASK-BS-002 | 已登记；需单测或人工审查证据 |

---

## §2 业务规则追溯（BR）

| BR ID | 约束摘要 | AC | TC ID(s) | Task | 当前状态 |
| --- | --- | --- | --- | --- | --- |
| BR-001 | 禁止 import domain_market/domain_macro/domainx/contracts | AC-005 | TC-008, boundary-gates.sh | TASK-BS-004 | v0.1.0 boundary gate 已通过；需复验脚本证据 |
| BR-002 | 禁止 import 数据域子模块 | AC-005 | TC-008, boundary-gates.sh | TASK-BS-004 | v0.1.0 boundary gate 已通过；需复验脚本证据 |
| BR-003 | 禁止启动 HTTP/gRPC server 或 net.Listen | AC-005 | boundary-gates.sh | TASK-BS-004 | v0.1.0 boundary gate 已通过；需复验脚本证据 |
| BR-004 | 只能向下依赖基座与存储适配器 | AC-005 | go list / dependency scan | TASK-BS-004 | 已登记；需复验 |
| BR-005 | adapter Spec.Stores 必须为 None | AC-004, AC-005 | TC-001, TC-009 | TASK-BS-001, TASK-BS-004 | v0.1.0 Stores=None 已发布；需复验 |
| BR-006 | 仅聚合层可使用非 None Stores | AC-004 | TC-002, TC-004 | TASK-BS-001, TASK-BS-005 | v0.2.0 准入 |
| BR-007 | Spec.Stores 位掩码控制存储构造 | AC-004 | TC-004 | TASK-BS-001 | v0.2.0 准入 |
| BR-008 | 文档批准前不得新增运行时代码或依赖 | AC-005 | 文档状态与 diff 审查 | TASK-BS-004 | SPEC 仍为 Draft；禁止扩大运行时代码 |

---

## §3 非功能需求追溯（NFR）

| NFR ID | 约束摘要 | AC | TC ID(s) | Task | 当前状态 |
| --- | --- | --- | --- | --- | --- |
| NFR-001 | 职责单一 | AC-005 | boundary review | TASK-BS-004 | 已登记；需复验 |
| NFR-002 | Build/Run/Shutdown 签名稳定 | AC-001, AC-003, AC-004 | API review | TASK-BS-001, TASK-BS-003 | 已登记；需复验 |
| NFR-003 | public API 不暴露领域/传输/存储标签 | AC-002, AC-005 | static review | TASK-BS-002, TASK-BS-004 | 已登记；需复验 |
| NFR-004 | Build/Shutdown 记录 observex metrics + 日志 | AC-003 | observability review | TASK-BS-003 | 已登记；需补充指标证据 |
| NFR-005 | Stores 默认 None，显式启用才连接存储 | AC-004 | TC-001, TC-009 | TASK-BS-001 | v0.1.0 已发布；需复验 |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖需求 | 验证内容 |
| --- | --- | --- |
| TC-001 | FR-001, FR-002, FR-008, BR-005 | Build 入口 + configx 加载 + EffectiveConfigHash 暴露 |
| TC-002 | FR-004, BR-006 | stores 非 None 构造 |
| TC-003 | FR-001 | TestBuildAdapter / TestBuildEmptyModule |
| TC-004 | FR-004, BR-006, BR-007 | Stores 位掩码控制存储构造 |
| TC-005 | FR-003, FR-005, FR-006, FR-007, NFR-002 | lifecycle 编排 + 组件注册 + 信号捕获 + API 签名 |
| TC-006 | FR-003, FR-005, FR-006 | 组件注册 + lifecycle |
| TC-007 | FR-003, FR-005 | observex 初始化 + lifecycle |
| TC-008 | BR-001, BR-002 | import boundary gate |
| TC-009 | BR-005, NFR-005 | Stores=None 端到端 |

---

## §5 全局 AC 注册表

| AC | 验收摘要 | 覆盖需求 | 当前状态 |
| --- | --- | --- | --- |
| AC-001 | Build(ctx, Spec{Module, Stores: None}) 返回 App，空 Module 返回 ErrEmptyModule | FR-001, FR-004, NFR-002 | 已登记，需运行时复验 |
| AC-002 | configx loader、XGO_ 环境源、SecretString 脱敏与 ConfigHash 暴露 | FR-002, FR-008, NFR-003 | 已登记，需单测或人工审查证据 |
| AC-003 | observex/resiliencx/lifecycx 集成，支持 Start/Stop/rollback/idempotent shutdown | FR-003, FR-005, FR-006, FR-007, NFR-004 | 已登记，需 lifecycle 测试复验 |
| AC-004 | Stores=None 端到端就绪，非 None 存储位进入 v0.2.0 准入 | FR-004, BR-005, BR-006, BR-007, NFR-005 | Stores=None 已发布；v0.2.0 项待完成 |
| AC-005 | 边界门禁阻止 domain/contracts/数据域子模块/server listener 和越界依赖 | BR-001..BR-008, NFR-001, NFR-003 | boundary gate 已通过一次；需复验证据 |
| AC-006 | foundationx 遗留依赖按 OQ-004 清零 | OQ-004, TASK-BS-005 | Open；目标 v0.1.1/v0.2.0 |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done (v0.1.0) | Pending | 覆盖率 |
| --- | --- | --- | --- | --- |
| FR | 8 | 3 | 5 | 37.5% |
| BR | 8 | 4 | 4 | 50% |


| NFR | 5 | 1 | 4 | 20% |
| AC | 6 | 0 | 6 | 0% |
| TC | 9 | 0 | 9 | 0% |
| **合计** | **36** | **8** | **28** | **22.2%** |

> 说明：Done 列统计含 v0.1.0 "已发布"/"已通过" 状态项（FR-001/003/004、BR-001/002/003/005、NFR-005），但均需运行时复验证据归档。Task 总数 = TASK-BS-001~005 共 5 项。所有 AC/TC 处于 Draft 阶段未标记 Done。

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§1 FR / §2 BR / §3 NFR 独立表；新增 §4 TC→FR 反向追溯；新增 §5 全局 AC 注册表；新增 §6 覆盖率仪表盘；新增 §7 变更历史 |
| 2026-06-18 | 初始版本：FR/BR+NFR/AC 三表合并、缺口追踪 |

---

## 当前缺口

- `module/bootstrap/SPEC.md` 仍为 Draft；发布前需通过 Spec 管线翻转 Approved。
- `/home/workspace/bootstrap` 运行时测试、race、vet、coverage 与 boundary gate 证据需重新归档。
- Stores=None 是 v0.1.0 已发布路径；Stores=All、TD/PG 组合与其他非 None 位组合属于 v0.2.0 准入。
- OQ-004 仍未关闭：`stores.go` 中 foundationx 遗留依赖需在 v0.1.1 或 v0.2.0 前清零。
