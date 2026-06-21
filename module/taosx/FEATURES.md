# taosx 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-21
- Module-Version: v1.0.5
- Module-State: 本地发布候选
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/taosx/.worktree/workspaces/taosx-20260619
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 taosx 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | TDengine 配置、写入、查询、健康检查、指标端口与驱动注入契约适配 |
| 文档目录 | module/taosx |
| 运行时代码目录 | /home/taosx/.worktree/workspaces/taosx-20260619 |
| Go 基线 | 1.23 |
| 允许依赖 | kernel |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Config.Normalize 补齐默认名称、驱动模式和零值超时 | AC-TAO-001 / TC-001 / go test ./pkg/taosx -run TestConfigNormalize | ✅ | TRACEABILITY.md |
| FR-002 | Config.Validate 拒绝缺失 endpoint/database、非法驱动模式、负超时、负重试次数 | AC-TAO-002 / TC-002, TC-003 / go test ./pkg/taosx -run TestConfigValidate | ✅ | TRACEABILITY.md |
| FR-003 | New 校验 context/config/options，默认驱动显式不可用，注入驱动后委托 | AC-TAO-003 / TC-004, TC-005 / go test ./pkg/taosx -run TestNew | ✅ | TRACEABILITY.md |
| FR-004 | Exec 校验非空 SQL，委托驱动执行 | AC-TAO-004 / TC-006, TC-007 / go test ./pkg/taosx -run TestExec | ✅ | TRACEABILITY.md |
| FR-005 | Query 校验非空查询，返回 Rows 可遍历可关闭 | AC-TAO-005 / TC-008, TC-009 / go test ./pkg/taosx -run TestQuery | ✅ | TRACEABILITY.md |
| FR-006 | WriteBatch 校验 database/table/timestamp/fields/points，空 batch 拒绝 | AC-TAO-006 / TC-010, TC-011 / go test ./pkg/taosx -run TestWriteBatch | ✅ | TRACEABILITY.md |
| FR-007 | SchemalessWrite 校验 lines/协议/精度，空 lines 拒绝 | AC-TAO-007 / TC-012, TC-013 / go test ./pkg/taosx -run TestSchemalessWrite | ✅ | TRACEABILITY.md |
| FR-008 | Health 调用 Driver.Health 映射为 HealthStatus，默认驱动 degraded | AC-TAO-008 / TC-014, TC-015 / go test ./pkg/taosx -run TestHealth | ✅ | TRACEABILITY.md |
| FR-009 | Close 幂等，接受 context，关闭后操作返回 closed 错误 | AC-TAO-009 / TC-016, TC-017 / go test ./pkg/taosx -run TestClose | ✅ | TRACEABILITY.md |
| FR-010 | Metrics 端口可选，默认 no-op，注入后记录 taosx_client_* 指标 | AC-TAO-010 / TC-018, TC-019 / go test ./pkg/taosx -run TestMetrics | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | 直接 foundation 依赖只允许 kernel，不得声明直接依赖 configx/observex/resiliencx | — / ./scripts/check_boundary.sh + ./scripts/check_dependency_diff.sh | ✅ | TRACEABILITY.md |
| BR-002 | 所有外部操作接受 context.Context | TC-004, TC-005, TC-006, TC-007 / go test ./pkg/taosx ./contracts | ✅ | TRACEABILITY.md |
| BR-003 | 错误分类使用 taosx. 且输出脱敏，不含密码原文 | TC-002, TC-003 / go test ./pkg/taosx -run TestErrorClassification | ✅ | TRACEABILITY.md |
| BR-004 | MaxRetries 是配置契约保留字段，不代表核心 client 自动重试 | — / go test ./contracts | ✅ | TRACEABILITY.md |
| BR-005 | 默认驱动必须显式不可用，避免零配置被误认为真实 TDengine 连接 | TC-004 / go test ./pkg/taosx -run TestDefaultUnavailable | ✅ | TRACEABILITY.md |
| BR-006 | 原始 SQL 只做空值校验，不声明注入防护 | TC-006 / go test ./pkg/taosx -run TestSQL | ✅ | TRACEABILITY.md |
| BR-007 | 真实集成测试不得进入默认测试路径，失败输出不得包含 DSN/用户名/密码 | — / go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1 -v；TAOSX_INTEGRATION=1 时执行 live gate | ✅ | TRACEABILITY.md |
| BR-008 | 官方 taosWS WebSocket 集成测试必须显式 opt-in、环境变量配置且凭据脱敏 | — / TAOSX_INTEGRATION=1 GOWORK=off go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1 -v | ✅ | TRACEABILITY.md |
| NFR-001 | Config | Config 归一化仅补齐安全默认值，不连接外部系统；校验拒绝非法输入 / go test ./pkg/taosx -run TestConfig -count=1 | ✅ | TRACEABILITY.md |
| NFR-002 | Concurrency | Client 构造后可被并发调用；Close 必须幂等，关闭过程中不得 panic / go test -race ./pkg/taosx ./contracts | ✅ | TRACEABILITY.md |
| NFR-003 | Observability | 指标端口只记录低基数标签；默认 no-op 零配置可用；健康状态不含明文密码 / go test ./pkg/taosx -run TestMetrics + go test ./pkg/taosx -run TestHealth | ✅ | TRACEABILITY.md |
| NFR-004 | Security | 错误/状态/日志/测试输出/示例均不得暴露真实密码、API key、私有 endpoint / ./scripts/check_contracts.sh | ✅ | TRACEABILITY.md |
| NFR-005 | Dependency | 核心包直接 Zone 依赖仅允许 kernel；驱动/指标/配置通过端口注入 / ./scripts/check_boundary.sh + ./scripts/check_dependency_diff.sh | ✅ | TRACEABILITY.md |
| NFR-006 | Compatibility | v1.0.5 不改变 v1.0.0 公共构造入口和核心接口语义；破坏性变更进后续 major / GOWORK=off make taosx-coverage-check + GOWORK=off make release-check | ✅ | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-TAOSX-001 | TASK-TAOSX-001: Config.Normalize/Validate、NewClient 工厂、driver 注入 | module/taosx/tasks/TASK-TAOSX-001.md | ✅ | tasks/TASK-TAOSX-001.md |
| TASK-TAOSX-002 | TASK-TAOSX-002: SQL 执行接口 | module/taosx/tasks/TASK-TAOSX-002.md | ✅ | tasks/TASK-TAOSX-002.md |
| TASK-TAOSX-003 | TASK-TAOSX-003: 批量写入 | module/taosx/tasks/TASK-TAOSX-003.md | ✅ | tasks/TASK-TAOSX-003.md |
| TASK-TAOSX-004 | TASK-TAOSX-004: Health 检查、幂等 Close、degraded 状态 | module/taosx/tasks/TASK-TAOSX-004.md | ✅ | tasks/TASK-TAOSX-004.md |
| TASK-TAOSX-005 | TASK-TAOSX-005: taosx_client_* 指标、noop 默认、日志脱敏 | module/taosx/tasks/TASK-TAOSX-005.md | ✅ | tasks/TASK-TAOSX-005.md |
| TASK-TAOSX-006 | TASK-TAOSX-006: go.mod、单元测试、集成测试、benchmark、README、CHANGELOG | module/taosx/tasks/TASK-TAOSX-006.md | ✅ | tasks/TASK-TAOSX-006.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/taosx/goal.md |
| SPEC.md | 存在 | module/taosx/SPEC.md |
| TRACEABILITY.md | 存在 | module/taosx/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/taosx/IMPLEMENTATION-PLAN.md |
| tasks/ | 6 个 Markdown 文件 | module/taosx/tasks |

## 6. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [x] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [x] 运行时代码仓库 /home/taosx 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [x] 发布说明、版本标签与本目录登记状态一致。

## 7. v1.0.5 本地发布候选证据

- Source commit: `/home/taosx/.worktree/workspaces/taosx-20260619` branch `taosx` @ `2bf5aaa`。
- `GOWORK=off make taosx-coverage-check`: PASS，`pkg/taosx` total `100.0%`。
- `GOWORK=off make release-check`: PASS，生成并校验 `release/manifest/latest.json`；release evidence hash `c78f9de861cf83434140fc0e0e051e91af71736ec2d22f0ce1c0cf74c9a87f61`。
- `GOWORK=off make integration`: PASS，kernel/configx/redisx 渲染下游通过。
- `GOWORK=off go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1 -v`: PASS，默认因未设置 `TAOSX_INTEGRATION=1` 跳过 live TDengine，不连接外部 TDengine。
- `TAOSX_INTEGRATION=1 GOWORK=off go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1 -v`: PASS，2026-06-19 使用 `sre/secrets/env/dev.md` 的 `market_binance` dev 配置执行；`TestTDengineWebSocketIntegration` PASS，package result `ok github.com/ZoneCNH/taosx/pkg/taosx 0.020s`；文档不记录 endpoint、用户名、密码或完整 DSN。
- 未执行外部 push/tag/GitHub Release；当前状态是本地发布候选。
