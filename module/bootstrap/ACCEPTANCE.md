# bootstrap 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.1.0
- Module-State: 已发布
- Layer: L1 启动装配
- Runtime-Repo: /home/bootstrap
- Source: SPEC.md

> 本清单用于验收 bootstrap 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/bootstrap/FEATURES.md && test -f module/bootstrap/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
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
| TC-BS-001 | FR-001 | Build 成功，Stores=None，App.Stores 为 nil / go test -run TestBuildAdapter | - | SPEC.md |
| TC-BS-002 | FR-001 | Build 成功，Stores=All，App.Stores 全非 nil / go test -run TestBuildAggregate | - | SPEC.md |
| TC-BS-003 | FR-001 | Spec.Module 为空 → ErrEmptyModule / go test -run TestBuildEmptyModule | - | SPEC.md |
| TC-BS-004 | FR-004 | Stores=TD\|PG，仅构造 TD+PG，其余 nil / go test -run TestBuildPartialStores | - | SPEC.md |
| TC-BS-005 | FR-005 | Run 收到 SIGTERM → 逆序 Stop / go test -run TestRunShutdown | - | SPEC.md |
| TC-BS-006 | FR-005 | Component Start 失败 → 回滚 / go test -run TestStartRollback | - | SPEC.md |
| TC-BS-007 | FR-005 | Shutdown 幂等（二次返回 nil） / go test -run TestShutdownIdempotent | - | SPEC.md |
| TC-BS-008 | BR-001 | go.mod 无 domain-market/contracts / boundary-gate | - | SPEC.md |
| TC-BS-009 | BR-005 | adapter Spec.Stores=None 编译期约束 / go test -run TestAdapterZeroStore | - | SPEC.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Build 入口 | - | - | SPEC.md |
| FR-002 | configx 加载 | - | - | SPEC.md |
| FR-003 | observex 初始化 | - | - | SPEC.md |
| FR-004 | stores 可选构造 | - | - | SPEC.md |
| FR-005 | lifecycle 编排 | - | - | SPEC.md |
| FR-006 | 组件注册 | - | - | SPEC.md |
| FR-007 | 信号捕获 | - | - | SPEC.md |
| FR-008 | EffectiveConfigHash 暴露 | - | - | SPEC.md |
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
- 若 SPEC/TRACEABILITY 缺少 AC 或 TC，必须先补齐追溯矩阵，再执行发布验收。
