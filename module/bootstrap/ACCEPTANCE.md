# bootstrap 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.1.0
- Module-State: 已发布
- Layer: L1 启动装配
- Runtime-Repo: /home/bootstrap
- Source: SPEC.md, TRACEABILITY.md, goal.md

> 本清单用于验收 bootstrap 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/bootstrap/FEATURES.md && test -f module/bootstrap/ACCEPTANCE.md && test -f module/bootstrap/TRACEABILITY.md && test -f module/bootstrap/goal.md | FEATURES.md、ACCEPTANCE.md、TRACEABILITY.md 与 goal.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/bootstrap | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/bootstrap && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/bootstrap && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/bootstrap && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/bootstrap && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/bootstrap && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-BS-001 | Build(ctx, Spec{Module, Stores: None}) 返回 App，App.Stores 为 nil，Spec.Module 为空返回 ErrEmptyModule | FR-001, TC-BS-001, TC-BS-003, TASK-BS-001 | 已登记，需运行 `go test -run TestBuildAdapter` 与 `go test -run TestBuildEmptyModule` 复验 | SPEC.md §6/§16 |
| AC-BS-002 | Build 使用 configx loader、XGO_ 环境源与 SecretString 脱敏，并暴露 ConfigHash | FR-002, FR-008, NFR-003, TASK-BS-002 | 已登记，需单测/人工审查证据 | SPEC.md §6/§9/§19 |
| AC-BS-003 | Build/Run/Shutdown 接入 observex、resiliencx、lifecycx，支持顺序 Start、逆序 Stop、失败回滚与幂等 Shutdown | FR-003, FR-005, FR-006, FR-007, TC-BS-005..TC-BS-007, TASK-BS-003 | 已登记，需运行 lifecycle 相关测试复验 | SPEC.md §6/§9.3/§16 |
| AC-BS-004 | Stores=None 路径端到端就绪；非 None 存储位目标态进入 v0.2.0 准入 | FR-004, TC-BS-002, TC-BS-004, TASK-BS-001 | v0.1.0 已发布 Stores=None；Stores=All/组合冒烟待 v0.2.0 | SPEC.md §6/§16/§22 |
| AC-BS-005 | 边界门禁阻止 domain/contracts/数据域子模块/server 监听和越界依赖 | BR-001..BR-008, TC-BS-008..TC-BS-009, TASK-BS-004 | v0.1.0 boundary-gates.sh 5 道已通过，需复验脚本证据 | SPEC.md §7/§20/§22 |
| AC-BS-006 | foundationx 遗留依赖按 OQ-004 清零，不晚于 v0.2.0 准入 | OQ-004, v0.2.0 DoD, TASK-BS-005 | Open | SPEC.md §15.1/§22/§23 |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-BS-001 | FR-001 | Build 成功，Stores=None，App.Stores 为 nil / go test -run TestBuildAdapter | v0.1.0 Stores=None 已发布；需运行复验 | TRACEABILITY.md §1 |
| TC-BS-002 | FR-001 | Build 成功，Stores=All，App.Stores 全非 nil / go test -run TestBuildAggregate | v0.2.0 准入；当前非 None 存储仍待完成 | TRACEABILITY.md §1 |
| TC-BS-003 | FR-001 | Spec.Module 为空 → ErrEmptyModule / go test -run TestBuildEmptyModule | 已登记，需运行复验 | TRACEABILITY.md §1 |
| TC-BS-004 | FR-004 | Stores=TD\|PG，仅构造 TD+PG，其余 nil / go test -run TestBuildPartialStores | v0.2.0 准入；需补充部分组合冒烟 | TRACEABILITY.md §1 |
| TC-BS-005 | FR-005 | Run 收到 SIGTERM → 逆序 Stop / go test -run TestRunShutdown | 已登记，需 lifecycle 测试复验 | TRACEABILITY.md §1 |
| TC-BS-006 | FR-005 | Component Start 失败 → 回滚 / go test -run TestStartRollback | 已登记，需 lifecycle 测试复验 | TRACEABILITY.md §1 |
| TC-BS-007 | FR-005 | Shutdown 幂等（二次返回 nil） / go test -run TestShutdownIdempotent | 已登记，需 lifecycle 测试复验 | TRACEABILITY.md §1 |
| TC-BS-008 | BR-001 | go.mod 无 domain-market/contracts / boundary-gate | v0.1.0 boundary-gates.sh 通过；需复验脚本证据 | TRACEABILITY.md §2 |
| TC-BS-009 | BR-005 | adapter Spec.Stores=None 编译期约束 / go test -run TestAdapterZeroStore | 已登记，需 adapter zero store 测试复验 | TRACEABILITY.md §2 |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Build 入口 | AC-BS-001 / TC-BS-001, TC-BS-003 / TASK-BS-001 | v0.1.0 Stores=None 已发布；需运行时代码复验 | TRACEABILITY.md §1 |
| FR-002 | configx 加载 | AC-BS-002 / TC-BS-001 / TASK-BS-002 | 已登记，需单测或人工审查证据 | TRACEABILITY.md §1 |
| FR-003 | observex 初始化 | AC-BS-003 / TC-BS-005..TC-BS-007 / TASK-BS-003 | v0.1.0 已发布，需 lifecycle 测试与 CI 证据复验 | TRACEABILITY.md §1 |
| FR-004 | stores 可选构造 | AC-BS-004 / TC-BS-002, TC-BS-004 / TASK-BS-001, TASK-BS-005 | Stores=None 已发布；非 None 存储为 v0.2.0 准入 | TRACEABILITY.md §1 |
| FR-005 | lifecycle 编排 | AC-BS-003 / TC-BS-005..TC-BS-007 / TASK-BS-003 | 已登记，需运行时复验 | TRACEABILITY.md §1 |
| FR-006 | 组件注册 | AC-BS-003 / TC-BS-005, TC-BS-006 / TASK-BS-003 | 已登记，需运行时复验 | TRACEABILITY.md §1 |
| FR-007 | 信号捕获 | AC-BS-003 / TC-BS-005 / TASK-BS-003 | 已登记，需运行时复验 | TRACEABILITY.md §1 |
| FR-008 | EffectiveConfigHash 暴露 | AC-BS-002 / TC-BS-001 / TASK-BS-002 | 已登记，需单测或人工审查证据 | TRACEABILITY.md §1 |
| BR-001 | bootstrap 不得 import domain-market/domain-macro/domainx/contracts（禁业务语义） | AC-BS-005 / TC-BS-008, boundary-gates.sh / TASK-BS-004 | v0.1.0 boundary gate 已通过；需复验脚本证据 | TRACEABILITY.md §2 |
| BR-002 | bootstrap 不得 import 任何数据域子模块（binance/fred/…）（禁采集逻辑） | AC-BS-005 / TC-BS-008, boundary-gates.sh / TASK-BS-004 | v0.1.0 boundary gate 已通过；需复验脚本证据 | TRACEABILITY.md §2 |
| BR-003 | bootstrap 不得起 HTTP/gRPC server（源码无 net.Listen） | AC-BS-005 / boundary-gates.sh / TASK-BS-004 | v0.1.0 boundary gate 已通过；需复验脚本证据 | TRACEABILITY.md §2 |
| BR-004 | bootstrap 只向下依赖 kernel/configx/observex/resiliencx/存储适配器，不向上 | AC-BS-005 / go list, dependency scan / TASK-BS-004 | 已登记，需复验 | TRACEABILITY.md §2 |
| BR-005 | adapter 进程的 Spec.Stores 必须为 None；App.Stores 为 nil | AC-BS-004, AC-BS-005 / TC-BS-001, TC-BS-009 / TASK-BS-001, TASK-BS-004 | v0.1.0 Stores=None 已发布；需复验 | TRACEABILITY.md §2 |
| BR-006 | 仅聚合层（market-data/macro-data）的 Spec.Stores 可非 None | AC-BS-004 / TC-BS-002, TC-BS-004 / TASK-BS-001, TASK-BS-005 | v0.2.0 准入 | TRACEABILITY.md §2 |
| BR-007 | Spec.Stores 位掩码控制；未启用的存储不构造不连接 | AC-BS-004 / TC-BS-004 / TASK-BS-001 | v0.2.0 准入 | TRACEABILITY.md §2 |
| BR-008 | 文档批准前不得新增运行时代码或依赖 | AC-BS-005 / 文档状态与 diff 审查 / TASK-BS-004 | SPEC 仍为 Draft；禁止扩大运行时代码 | TRACEABILITY.md §2 |
| NFR-001 | 职责单一 | AC-BS-005 / boundary review / TASK-BS-004 | 已登记，需复验 | TRACEABILITY.md §2 |
| NFR-002 | 稳定性 | AC-BS-001, AC-BS-003, AC-BS-004 / API review / TASK-BS-001, TASK-BS-003 | 已登记，需复验 | TRACEABILITY.md §2 |
| NFR-003 | 边界纯净 | AC-BS-002, AC-BS-005 / static review / TASK-BS-002, TASK-BS-004 | 已登记，需复验 | TRACEABILITY.md §2 |
| NFR-004 | 可观测 | AC-BS-003 / observability review / TASK-BS-003 | 已登记，需补充指标证据 | TRACEABILITY.md §2 |
| NFR-005 | 零存储默认 | AC-BS-004 / TC-BS-001, TC-BS-009 / TASK-BS-001 | v0.1.0 已发布；需复验 | TRACEABILITY.md §2 |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/bootstrap 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- TRACEABILITY.md 和 goal.md 已补齐为追溯输入；运行时代码证据仍需在 /home/bootstrap 复验。
