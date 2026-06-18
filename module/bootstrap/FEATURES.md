# bootstrap 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.1.0
- Module-State: 已发布
- Layer: L1 启动装配
- Runtime-Repo: /home/bootstrap
- Source: SPEC.md

> 本清单用于约束 bootstrap 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | 以 Options/Builder/Artifact 方式装配进程入口与基础设施客户端 |
| 文档目录 | module/bootstrap |
| 运行时代码目录 | /home/bootstrap |
| Go 基线 | 1.23 |
| 允许依赖 | kernel, configx, observex, resiliencx, taosx, postgresx, redisx, kafkax, natsx, ossx, clickhousex |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Build 入口 | - | - | SPEC.md |
| FR-002 | configx 加载 | - | - | SPEC.md |
| FR-003 | observex 初始化 | - | - | SPEC.md |
| FR-004 | stores 可选构造 | - | - | SPEC.md |
| FR-005 | lifecycle 编排 | - | - | SPEC.md |
| FR-006 | 组件注册 | - | - | SPEC.md |
| FR-007 | 信号捕获 | - | - | SPEC.md |
| FR-008 | EffectiveConfigHash 暴露 | - | - | SPEC.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | bootstrap 不得 import domain-market/domain-macro/domainx/contracts（禁业务语义） | - | - | SPEC.md |
| BR-002 | bootstrap 不得 import 任何数据域子模块（binance/fred/…）（禁采集逻辑） | - | - | SPEC.md |
| BR-003 | bootstrap 不得起 HTTP/gRPC server（源码无 net.Listen） | - | - | SPEC.md |
| BR-004 | bootstrap 只向下依赖 kernel/configx/observex/resiliencx/存储适配器，不向上 | - | - | SPEC.md |
| BR-005 | adapter 进程的 Spec.Stores 必须为 None；App.Stores 为 nil | - | - | SPEC.md |
| BR-006 | 仅聚合层（market-data/macro-data）的 Spec.Stores 可非 None | - | - | SPEC.md |
| BR-007 | Spec.Stores 位掩码控制；未启用的存储不构造不连接 | - | - | SPEC.md |
| BR-008 | 文档批准前不得新增运行时代码或依赖 | - | - | SPEC.md |
| NFR-001 | 职责单一 | 只做组装，不做业务/采集/领域逻辑 | - | SPEC.md |
| NFR-002 | 稳定性 | v0.1.0 后 Build/Run/Shutdown 签名不破坏性变更 | - | SPEC.md |
| NFR-003 | 边界纯净 | public API 不暴露 domain DTO / transport tag / storage tag | - | SPEC.md |
| NFR-004 | 可观测 | Build/Shutdown 记录 observex metrics + 日志 | - | SPEC.md |
| NFR-005 | 零存储默认 | Stores 默认 None；必须显式启用才连存储 | - | SPEC.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-BS-001 | 实现 Build(ctx, Spec) 入口、Spec/App/StoreSet/Stores 类型与 ErrEmptyModule 校验 | FR-001, FR-004, TC-BS-001..TC-BS-004 | v0.1.0 Stores=None 已发布；非 None 存储目标态纳入 v0.2.0 准入 | SPEC.md §6/§9/§16/§22 |
| TASK-BS-002 | 接入 configx 加载、SecretString 脱敏与 EffectiveConfigHash 暴露 | FR-002, FR-008, NFR-003, TC-BS-001 | 已登记，需运行时代码复验 | SPEC.md §6/§9/§19 |
| TASK-BS-003 | 接入 observex、resiliencx 与 lifecycle Manager 编排 | FR-003, FR-005, FR-006, FR-007, TC-BS-005..TC-BS-007 | v0.1.0 已发布，需 CI 证据复验 | SPEC.md §6/§9.3/§16/§22 |
| TASK-BS-004 | 建立边界门禁：禁业务语义、禁采集逻辑、禁 server、依赖方向与 store 位掩码 | BR-001..BR-008, TC-BS-008..TC-BS-009 | v0.1.0 boundary-gates.sh 5 道已通过 | SPEC.md §7/§20/§22 |
| TASK-BS-005 | 关闭 foundationx 遗留依赖并完成 v0.2.0 准入项 | OQ-004, v0.2.0 DoD | Open，v0.1.1 一行替换 + go mod tidy 后关闭 | SPEC.md §15.1/§22/§23 |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| SPEC.md | 存在 | module/bootstrap/SPEC.md |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/bootstrap 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
