# taosx 追溯矩阵

Last-Updated: 2026-06-21
Source: `module/taosx/SPEC.md` v1.0.5

本矩阵追踪 taosx v1.0.5 规格中所有功能需求、行为约束、非功能需求与测试用例/验收标准之间的完整追溯链路。

## §1 FR 功能需求追溯

| FR ID | Requirement | AC ID(s) | TC ID(s) | Verification | Status |
| ----- | ----------- | -------- | -------- | ------------ | ------ |
| FR-001 | Config.Normalize 补齐默认名称、驱动模式和零值超时 | AC-TAO-001 | TC-001 | `go test ./pkg/taosx -run TestConfigNormalize` | ✅ |
| FR-002 | Config.Validate 拒绝缺失 endpoint/database、非法驱动模式、负超时、负重试次数 | AC-TAO-002 | TC-002, TC-003 | `go test ./pkg/taosx -run TestConfigValidate` | ✅ |
| FR-003 | New 校验 context/config/options，默认驱动显式不可用，注入驱动后委托 | AC-TAO-003 | TC-004, TC-005 | `go test ./pkg/taosx -run TestNew` | ✅ |
| FR-004 | Exec 校验非空 SQL，委托驱动执行 | AC-TAO-004 | TC-006, TC-007 | `go test ./pkg/taosx -run TestExec` | ✅ |
| FR-005 | Query 校验非空查询，返回 Rows 可遍历可关闭 | AC-TAO-005 | TC-008, TC-009 | `go test ./pkg/taosx -run TestQuery` | ✅ |
| FR-006 | WriteBatch 校验 database/table/timestamp/fields/points，空 batch 拒绝 | AC-TAO-006 | TC-010, TC-011 | `go test ./pkg/taosx -run TestWriteBatch` | ✅ |
| FR-007 | SchemalessWrite 校验 lines/协议/精度，空 lines 拒绝 | AC-TAO-007 | TC-012, TC-013 | `go test ./pkg/taosx -run TestSchemalessWrite` | ✅ |
| FR-008 | Health 调用 Driver.Health 映射为 HealthStatus，默认驱动 degraded | AC-TAO-008 | TC-014, TC-015 | `go test ./pkg/taosx -run TestHealth` | ✅ |
| FR-009 | Close 幂等，接受 context，关闭后操作返回 closed 错误 | AC-TAO-009 | TC-016, TC-017 | `go test ./pkg/taosx -run TestClose` | ✅ |
| FR-010 | Metrics 端口可选，默认 no-op，注入后记录 `taosx_client_*` 指标 | AC-TAO-010 | TC-018, TC-019 | `go test ./pkg/taosx -run TestMetrics` | ✅ |

## §2 BR 行为约束追溯

| BR ID | Rule | TC ID(s) | Verification | Status |
| ----- | ---- | -------- | ------------ | ------ |
| BR-001 | 直接 foundation 依赖只允许 `kernel`，不得声明直接依赖 `configx`/`observex`/`resiliencx` | — | `./scripts/check_boundary.sh` + `./scripts/check_dependency_diff.sh` | ✅ |
| BR-002 | 所有外部操作接受 `context.Context` | TC-004, TC-005, TC-006, TC-007 | `go test ./pkg/taosx ./contracts` | ✅ |
| BR-003 | 错误分类使用 `taosx.<Operation>` 且输出脱敏，不含密码原文 | TC-002, TC-003 | `go test ./pkg/taosx -run TestErrorClassification` | ✅ |
| BR-004 | `MaxRetries` 是配置契约保留字段，不代表核心 client 自动重试 | — | `go test ./contracts` | ✅ |
| BR-005 | 默认驱动必须显式不可用，避免零配置被误认为真实 TDengine 连接 | TC-004 | `go test ./pkg/taosx -run TestDefaultUnavailable` | ✅ |
| BR-006 | 原始 SQL 只做空值校验，不声明注入防护 | TC-006 | `go test ./pkg/taosx -run TestSQL` | ✅ |
| BR-007 | 真实集成测试不得进入默认测试路径，失败输出不得包含 DSN/用户名/密码 | — | `GOWORK=off go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1 -v` | ✅ |
| BR-008 | 官方 taosWS WebSocket 集成测试必须显式 opt-in、环境变量配置且凭据脱敏 | — | `GOWORK=off TAOSX_INTEGRATION=1 go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1 -v` | ✅ |

## §3 NFR 非功能需求追溯

| NFR ID | Category | Requirement | Verification | Status |
| ------ | -------- | ----------- | ------------ | ------ |
| NFR-001 | Config | Config 归一化仅补齐安全默认值，不连接外部系统；校验拒绝非法输入 | `go test ./pkg/taosx -run TestConfig -count=1` | ✅ |
| NFR-002 | Concurrency | Client 构造后可被并发调用；Close 必须幂等，关闭过程中不得 panic | `go test -race ./pkg/taosx ./contracts` | ✅ |
| NFR-003 | Observability | 指标端口只记录低基数标签；默认 no-op 零配置可用；健康状态不含明文密码 | `go test ./pkg/taosx -run TestMetrics` + `go test ./pkg/taosx -run TestHealth` | ✅ |
| NFR-004 | Security | 错误/状态/日志/测试输出/示例均不得暴露真实密码、API key、私有 endpoint | `./scripts/check_contracts.sh` | ✅ |
| NFR-005 | Dependency | 核心包直接 Zone 依赖仅允许 `kernel`；驱动/指标/配置通过端口注入 | `./scripts/check_boundary.sh` + `./scripts/check_dependency_diff.sh` | ✅ |
| NFR-006 | Compatibility | v1.0.5 不改变 v1.0.0 公共构造入口和核心接口语义；破坏性变更进后续 major | `GOWORK=off make release-check` | ✅ |

## §4 TC→FR 反向追溯

| TC ID | Covers FR(s) | Command |
| ----- | ------------ | ------- |
| TC-001 | FR-001 | `go test ./pkg/taosx -run TestConfigNormalize` |
| TC-002 | FR-002 | `go test ./pkg/taosx -run TestConfigValidate` |
| TC-003 | FR-002 | `go test ./pkg/taosx -run TestConfigRedact` |
| TC-004 | FR-003 | `go test ./pkg/taosx -run TestDefaultUnavailable` |
| TC-005 | FR-003 | `go test ./pkg/taosx -run TestDriverInject` |
| TC-006 | FR-004 | `go test ./pkg/taosx -run TestExecEmpty` |
| TC-007 | FR-004 | `go test ./pkg/taosx -run TestExecDelegate` |
| TC-008 | FR-005 | `go test ./pkg/taosx -run TestQueryEmpty` |
| TC-009 | FR-005 | `go test ./pkg/taosx -run TestRowsIter` |
| TC-010 | FR-006 | `go test ./pkg/taosx -run TestWriteBatchEmpty` |
| TC-011 | FR-006 | `go test ./pkg/taosx -run TestWriteBatchPartial` |
| TC-012 | FR-007 | `go test ./pkg/taosx -run TestSchemalessEmpty` |
| TC-013 | FR-007 | `go test ./pkg/taosx -run TestSchemalessProtocol` |
| TC-014 | FR-008 | `go test ./pkg/taosx -run TestHealthDegraded` |
| TC-015 | FR-008 | `go test ./pkg/taosx -run TestHealthDelegate` |
| TC-016 | FR-009 | `go test ./pkg/taosx -run TestCloseIdempotent` |
| TC-017 | FR-009 | `go test ./pkg/taosx -run TestCloseRejectsOps` |
| TC-018 | FR-010 | `go test ./pkg/taosx -run TestMetricsNoop` |
| TC-019 | FR-010 | `go test ./pkg/taosx -run TestMetricsRecord` |

## §5 AC 验收标准注册表

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| ----- | --------- | --------- | ------------ | ------ |
| AC-TAO-001 | FR-001 | 零值字段归一化为预期默认值（空名称→taosx，空驱动→websocket，零超时→5s）；负超时由 Validate 拒绝 | `go test ./pkg/taosx -run TestConfigNormalize` | ✅ |
| AC-TAO-002 | FR-002 | 缺失 endpoint/database/非法驱动模式/负超时均返回 validation error；错误消息不含密码原文 | `go test ./pkg/taosx -run TestConfigValidate` | ✅ |
| AC-TAO-003 | FR-003 | 无驱动构造成功，操作返回 unavailable 错误；有驱动构造成功，操作正常执行 | `go test ./pkg/taosx -run TestNew` | ✅ |
| AC-TAO-004 | FR-004 | 空 SQL 返回 validation error；驱动错误透传；成功返回 ExecResult | `go test ./pkg/taosx -run TestExec` | ✅ |
| AC-TAO-005 | FR-005 | 空查询返回 validation error；Rows 可遍历且可关闭；驱动错误不伪造空结果 | `go test ./pkg/taosx -run TestQuery` | ✅ |
| AC-TAO-006 | FR-006 | 空 batch 或无 points 返回 validation error；部分失败含 partial result；成功记录写入行数指标 | `go test ./pkg/taosx -run TestWriteBatch` | ✅ |
| AC-TAO-007 | FR-007 | 空 lines 或非法协议返回 validation error；成功路径记录 `taosx_client_schemaless_lines` 指标 | `go test ./pkg/taosx -run TestSchemalessWrite` | ✅ |
| AC-TAO-008 | FR-008 | 默认驱动返回 degraded 状态；注入驱动透传健康状态；调用不 panic；错误信息不含密码 | `go test ./pkg/taosx -run TestHealth` | ✅ |
| AC-TAO-009 | FR-009 | 首次关闭成功；重复关闭幂等返回 nil；关闭后操作返回 closed 错误 | `go test ./pkg/taosx -run TestClose` | ✅ |
| AC-TAO-010 | FR-010 | 未注入 Metrics 时零开销；注入后正确记录指标；指标名统一 `taosx_client_*` 前缀 | `go test ./pkg/taosx -run TestMetrics` | ✅ |
