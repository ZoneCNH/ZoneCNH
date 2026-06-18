# resiliencx 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.4.9
- Module-State: 已发布
- Layer: L0 韧性
- Runtime-Repo: /home/resiliencx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 resiliencx 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/resiliencx/FEATURES.md && test -f module/resiliencx/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/resiliencx | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/resiliencx && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/resiliencx && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/resiliencx && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/resiliencx && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/resiliencx && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-RES-001 | FR-001 | 正常完成返回 fn 结果；超时返回 ErrTimeout；ctx 取消返回 ctx.Err() / go test -run TestTimeout | ✅ | TRACEABILITY.md |
| AC-RES-002 | FR-002 | 首次成功不重试；持续失败按 policy 重试至 max_retries；ctx 取消立即返回 / go test -run TestRetry | ✅ | TRACEABILITY.md |
| AC-RES-003 | FR-003 | Closed→Open→Half-Open→Closed 三态转换正确 / go test -run TestCircuitBreaker | ✅ | TRACEABILITY.md |
| AC-RES-004 | FR-003 | 多 goroutine 并发 Execute 无 panic 无数据竞争 / go test -race -run TestCircuitBreaker | ✅ | TRACEABILITY.md |
| AC-RES-005 | FR-004 | 并发 < max_concurrent 执行；达上限等待；超时返回 ErrBulkheadFull / go test -run TestBulkhead | ✅ | TRACEABILITY.md |
| AC-RES-006 | FR-005 | Allow/Wait 正确，速率超限拒绝，并发安全 / go test -race -run TestRateLimiter | ✅ | TRACEABILITY.md |
| AC-RES-007 | FR-006 | primary 成功返回 primary 结果；primary 失败执行 secondary / go test -run TestFallback | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001, FR-002 | go test -run "TestTimeout\ / TestRetry" | - | TRACEABILITY.md |
| TC-002 | FR-003 | go test -run TestCircuitBreaker -race | - | TRACEABILITY.md |
| TC-003 | FR-003 | go test -run TestCircuitBreaker -race | - | TRACEABILITY.md |
| TC-004 | FR-004 | go test -run TestBulkhead | - | TRACEABILITY.md |
| TC-005 | FR-005 | go test -run TestRateLimiter -race | - | TRACEABILITY.md |
| TC-006 | FR-006 | go test -run TestFallback | - | TRACEABILITY.md |
| TC-008 | FR-001, FR-002, FR-006, BR-003 | go test -run TestCompose | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Timeout | AC-RES-001 / TC-001 / go test -run TestTimeout | ✅ | TRACEABILITY.md |
| FR-002 | Retry | AC-RES-002 / TC-001 / go test -run TestRetry | ✅ | TRACEABILITY.md |
| FR-003 | CircuitBreaker | AC-RES-003, AC-RES-004 / TC-002, TC-003 / go test -run TestCircuitBreaker -race | ✅ | TRACEABILITY.md |
| FR-004 | Bulkhead | AC-RES-005 / TC-004 / go test -run TestBulkhead | ✅ | TRACEABILITY.md |
| FR-005 | RateLimiter | AC-RES-006 / TC-005 / go test -run TestRateLimiter -race | ✅ | TRACEABILITY.md |
| FR-006 | Fallback | AC-RES-007 / TC-006 / go test -run TestFallback | ✅ | TRACEABILITY.md |
| BR-001 | 所有策略必须接受 context.Context 参数 | — / go vet | ✅ | TRACEABILITY.md |
| BR-002 | 策略参数从 configx.Reader 读取，不硬编码 | — / go build + code review | ✅ | TRACEABILITY.md |
| BR-003 | 策略组合使用装饰器模式，外层包装内层 | TC-008 / go test -run TestCompose | ✅ | TRACEABILITY.md |
| BR-004 | 熔断器状态必须并发安全 | — / go test -race -run TestCircuitBreaker | ✅ | TRACEABILITY.md |
| BR-005 | 限流器必须并发安全 | — / go test -race -run TestRateLimiter | ✅ | TRACEABILITY.md |
| BR-006 | 策略执行 metrics 通过 observex.Meter 采集 | — / 指标端点验证 | ✅ | TRACEABILITY.md |
| BR-007 | 使用 stdlib + 最少依赖，不引入框架 | — / go mod graph | ✅ | TRACEABILITY.md |
| BR-008 | 策略可独立测试，不依赖外部服务 | — / go test -run 各策略独立执行 | ✅ | TRACEABILITY.md |
| NFR-001 | 性能 | 单策略调用 < 200ns，5 层嵌套 < 1μs / go test -bench=. -benchmem | ✅ | TRACEABILITY.md |
| NFR-002 | 可观测性 | metrics 注册且可抓取，状态变更日志正确 / 指标端点验证 + 日志检查 | ✅ | TRACEABILITY.md |
| NFR-003 | 安全 | 无凭证泄露、输入校验、panic 恢复 / gitleaks detect + code review | ✅ | TRACEABILITY.md |
| NFR-004 | CI Gate | 编译/测试/-race/vet/lint/覆盖率均通过 / CI 全部门禁 | ✅ | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/resiliencx 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- 若 SPEC/TRACEABILITY 缺少 AC 或 TC，必须先补齐追溯矩阵，再执行发布验收。
