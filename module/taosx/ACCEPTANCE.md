# taosx 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-30
- Module-Version: v1.0.5
- Module-State: 本地发布候选
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/taosx/.worktree/workspaces/taosx-20260619
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 taosx 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH/.worktree/workspaces/taosx-20260619 && test -f module/taosx/FEATURES.md && test -f module/taosx/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH/.worktree/workspaces/taosx-20260619 && git diff --check -- README.md ARCHITECTURE.md module/README.md module/taosx | 无尾随空格或补丁格式错误 |
| 发布门禁 | cd /home/taosx/.worktree/workspaces/taosx-20260619 && GOWORK=off make release-check | release 本地门禁通过，manifest 生成并可验证 |
| 覆盖率证据 | cd /home/taosx/.worktree/workspaces/taosx-20260619 && GOWORK=off make taosx-coverage-check | `pkg/taosx` 覆盖率 total 等于 `100.0%` |
| 模板集成 | cd /home/taosx/.worktree/workspaces/taosx-20260619 && GOWORK=off make integration | kernel/configx/redisx 渲染下游通过，score=10 |
| TDengine opt-in guard | cd /home/taosx/.worktree/workspaces/taosx-20260619 && GOWORK=off go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1 -v | 未设置 `TAOSX_INTEGRATION=1` 时 pass 且 skip，不连接外部 TDengine |
| TDengine live gate | cd /home/taosx/.worktree/workspaces/taosx-20260619 && TAOSX_INTEGRATION=1 GOWORK=off go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1 -v | 2026-06-19 使用 `sre/secrets/env/dev.md` 的 `market_binance` dev 配置时 pass；`TestTDengineWebSocketIntegration` PASS，package result `ok github.com/ZoneCNH/taosx/pkg/taosx 0.020s`；输出不记录 endpoint、用户名、密码或完整 DSN |
| 渲染回归 | cd /home/taosx/.worktree/workspaces/taosx-20260619 && bash -n scripts/render_template.sh scripts/check_rendered_template.sh scripts/run_integration.sh && GOWORK=off go test ./scripts -run TestRenderTemplateRewritesSourceModuleIdentity -count=1 | 脚本语法与嵌套渲染回归通过 |
| 源码格式 | cd /home/taosx/.worktree/workspaces/taosx-20260619 && git diff --check | 无尾随空格或补丁格式错误 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-TAO-001 | FR-001 | 零值字段归一化为预期默认值（空名称→taosx，空驱动→websocket，零超时→5s）；负超时由 Validate 拒绝 / go test ./pkg/taosx -run TestConfigNormalize | ✅ | TRACEABILITY.md |
| AC-TAO-002 | FR-002 | 缺失 endpoint/database/非法驱动模式/负超时均返回 validation error；错误消息不含密码原文 / go test ./pkg/taosx -run TestConfigValidate | ✅ | TRACEABILITY.md |
| AC-TAO-003 | FR-003 | 无驱动构造成功，操作返回 unavailable 错误；有驱动构造成功，操作正常执行 / go test ./pkg/taosx -run TestNew | ✅ | TRACEABILITY.md |
| AC-TAO-004 | FR-004 | 空 SQL 返回 validation error；驱动错误透传；成功返回 ExecResult / go test ./pkg/taosx -run TestExec | ✅ | TRACEABILITY.md |
| AC-TAO-005 | FR-005 | 空查询返回 validation error；Rows 可遍历且可关闭；驱动错误不伪造空结果 / go test ./pkg/taosx -run TestQuery | ✅ | TRACEABILITY.md |
| AC-TAO-006 | FR-006 | 空 batch 或无 points 返回 validation error；部分失败含 partial result；成功记录写入行数指标 / go test ./pkg/taosx -run TestWriteBatch | ✅ | TRACEABILITY.md |
| AC-TAO-007 | FR-007 | 空 lines 或非法协议返回 validation error；成功路径记录 taosx_client_schemaless_lines 指标 / go test ./pkg/taosx -run TestSchemalessWrite | ✅ | TRACEABILITY.md |
| AC-TAO-008 | FR-008 | 默认驱动返回 degraded 状态；注入驱动透传健康状态；调用不 panic；错误信息不含密码 / go test ./pkg/taosx -run TestHealth | ✅ | TRACEABILITY.md |
| AC-TAO-009 | FR-009 | 首次关闭成功；重复关闭幂等返回 nil；关闭后操作返回 closed 错误 / go test ./pkg/taosx -run TestClose | ✅ | TRACEABILITY.md |
| AC-TAO-010 | FR-010 | 未注入 Metrics 时零开销；注入后正确记录指标；指标名统一 taosx_client_* 前缀 / go test ./pkg/taosx -run TestMetrics | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001 | go test ./pkg/taosx -run TestConfigNormalize | ✅ | TRACEABILITY.md |
| TC-002 | FR-002 | go test ./pkg/taosx -run TestConfigValidate | ✅ | TRACEABILITY.md |
| TC-003 | FR-002 | go test ./pkg/taosx -run TestConfigRedact | ✅ | TRACEABILITY.md |
| TC-004 | FR-003 | go test ./pkg/taosx -run TestDefaultUnavailable | ✅ | TRACEABILITY.md |
| TC-005 | FR-003 | go test ./pkg/taosx -run TestDriverInject | ✅ | TRACEABILITY.md |
| TC-006 | FR-004 | go test ./pkg/taosx -run TestExecEmpty | ✅ | TRACEABILITY.md |
| TC-007 | FR-004 | go test ./pkg/taosx -run TestExecDelegate | ✅ | TRACEABILITY.md |
| TC-008 | FR-005 | go test ./pkg/taosx -run TestQueryEmpty | ✅ | TRACEABILITY.md |
| TC-009 | FR-005 | go test ./pkg/taosx -run TestRowsIter | ✅ | TRACEABILITY.md |
| TC-010 | FR-006 | go test ./pkg/taosx -run TestWriteBatchEmpty | ✅ | TRACEABILITY.md |
| TC-011 | FR-006 | go test ./pkg/taosx -run TestWriteBatchPartial | ✅ | TRACEABILITY.md |
| TC-012 | FR-007 | go test ./pkg/taosx -run TestSchemalessEmpty | ✅ | TRACEABILITY.md |
| TC-013 | FR-007 | go test ./pkg/taosx -run TestSchemalessProtocol | ✅ | TRACEABILITY.md |
| TC-014 | FR-008 | go test ./pkg/taosx -run TestHealthDegraded | ✅ | TRACEABILITY.md |
| TC-015 | FR-008 | go test ./pkg/taosx -run TestHealthDelegate | ✅ | TRACEABILITY.md |
| TC-016 | FR-009 | go test ./pkg/taosx -run TestCloseIdempotent | ✅ | TRACEABILITY.md |
| TC-017 | FR-009 | go test ./pkg/taosx -run TestCloseRejectsOps | ✅ | TRACEABILITY.md |
| TC-018 | FR-010 | go test ./pkg/taosx -run TestMetricsNoop | ✅ | TRACEABILITY.md |
| TC-019 | FR-010 | go test ./pkg/taosx -run TestMetricsRecord | ✅ | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
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

## 5. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [x] 运行时代码仓库 /home/taosx 通过 go test、go test -race、go vet 与覆盖率门槛。
- [x] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [x] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 默认 release/coverage/integration 门禁已在源码 worktree `taosx` @ `d46af01` 通过；release evidence hash `c78f9de861cf83434140fc0e0e051e91af71736ec2d22f0ce1c0cf74c9a87f61`。
- live TDengine WebSocket run 已在 2026-06-19 使用 `sre/secrets/env/dev.md` 的 `market_binance` dev 配置通过：`TestTDengineWebSocketIntegration` PASS，package result `ok github.com/ZoneCNH/taosx/pkg/taosx 0.020s`。
- 未执行外部 push/tag/GitHub Release；当前状态是本地发布候选。
