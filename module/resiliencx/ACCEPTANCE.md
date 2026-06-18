# resiliencx 完整验收清单

- Status: Generated from current module SSOT (contract-corrected)
- Last-Updated: 2026-06-18
- Module-Version: v0.4.14（运行时代码实测基线）
- Spec-Version: v1.0.2
- Module-State: 已发布
- Layer: L1 基础能力（与 SPEC §3 / FOUNDATION-DEPS.yaml 一致）
- Runtime-Repo: /home/resiliencx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 resiliencx 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。
>
> **v1.0.2 契约纠正**：本版本依据运行时代码实测修正 AC 命令中的测试函数名、error 名、层级与版本口径。原登记的 `TestTimeout`/`TestRetry`/`ErrTimeout`/`ErrCircuitOpen` 等在代码中不存在，已替换为实际符号。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/resiliencx/FEATURES.md && test -f module/resiliencx/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/resiliencx | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/resiliencx && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/resiliencx && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/resiliencx && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/resiliencx && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛（实测 98.1%） |
| 依赖边界 | cd /home/resiliencx && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界（实测仅 stdlib） |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务（实际符号） | 当前登记状态 | 运行时证据 | 来源 |
| --- | --- | --- | --- | --- | --- |
| AC-RES-001 | FR-001 | 正常完成返回 fn 结果；超时返回 `context.DeadlineExceeded`；ctx 取消返回 ctx.Err() / `go test -run TestDo_ ./pkg/resiliencx/timeout/` | ✅ | ✅ | TRACEABILITY.md |
| AC-RES-002 | FR-002 | 首次成功不重试；持续失败按 policy 重试至 MaxAttempts；ctx 取消立即返回 / `go test -run TestDo_ ./pkg/resiliencx/retry/` | ✅ | ✅ | TRACEABILITY.md |
| AC-RES-003 | FR-003 | Closed→Open→Half-Open→Closed 三态转换正确（连续失败 >= threshold） / `go test -run TestBreaker_ ./pkg/resiliencx/circuit/` | ✅ | ✅ | TRACEABILITY.md |
| AC-RES-004 | FR-003 | 多 goroutine 并发 Do 无 panic 无数据竞争 / `go test -race -run TestBreaker_ ./pkg/resiliencx/circuit/` | ✅ | ✅ | TRACEABILITY.md |
| AC-RES-005 | FR-004 | 并发 < max_concurrent 执行；达上限 Do 等待；TryAcquire 返回 `bulkhead.ErrFull` / `go test -run TestBulkhead_ ./pkg/resiliencx/bulkhead/` | ✅ | ✅ | TRACEABILITY.md |
| AC-RES-006 | FR-005 | Allow 令牌充足返回 true，不足返回 false；Reserve 返回等待时长；并发安全 / `go test -race -run TestLimiter_ ./pkg/resiliencx/ratelimit/` | ✅ | ✅ | TRACEABILITY.md |
| AC-RES-007 | FR-006 | primary 成功返回 nil；primary 失败依次尝试 fallbacks / `go test -run TestDo_ ./pkg/resiliencx/fallback/` | ✅ | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 运行时证据 | 来源 |
| --- | --- | --- | --- | --- | --- |
| TC-001 | FR-001, FR-002 | `go test -run "TestDo_" ./pkg/resiliencx/timeout/ ./pkg/resiliencx/retry/` | - | ✅ | TRACEABILITY.md |
| TC-002 | FR-003 | `go test -race -run TestBreaker_ClosedToOpen ./pkg/resiliencx/circuit/` | - | ✅ | TRACEABILITY.md |
| TC-003 | FR-003 | `go test -race -run TestBreaker_HalfOpen_ProbeSuccess ./pkg/resiliencx/circuit/` | - | ✅ | TRACEABILITY.md |
| TC-004 | FR-004 | `go test -run TestBulkhead_LimitsConcurrency ./pkg/resiliencx/bulkhead/` | - | ✅ | TRACEABILITY.md |
| TC-005 | FR-005 | `go test -race -run TestLimiter_AllowWithinBurst ./pkg/resiliencx/ratelimit/` | - | ✅ | TRACEABILITY.md |
| TC-006 | FR-006 | `go test -run TestDo_FallbackSucceeds ./pkg/resiliencx/fallback/` | - | ✅ | TRACEABILITY.md |
| TC-008 | FR-001, FR-002, FR-006, BR-003 | `go test -run TestCompose` | - | ❌ TestCompose/compose.go 不存在 | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 运行时证据 | 来源 |
| --- | --- | --- | --- | --- | --- |
| FR-001 | Timeout | AC-RES-001 / TC-001 / `go test -run TestDo_ ./pkg/resiliencx/timeout/` | ✅ | ✅ | TRACEABILITY.md |
| FR-002 | Retry | AC-RES-002 / TC-001 / `go test -run TestDo_ ./pkg/resiliencx/retry/` | ✅ | ✅ | TRACEABILITY.md |
| FR-003 | CircuitBreaker | AC-RES-003, AC-RES-004 / TC-002, TC-003 / `go test -race -run TestBreaker_ ./pkg/resiliencx/circuit/` | ✅ | ✅（无失败率维度） | TRACEABILITY.md |
| FR-004 | Bulkhead | AC-RES-005 / TC-004 / `go test -run TestBulkhead_ ./pkg/resiliencx/bulkhead/` | ✅ | ✅ | TRACEABILITY.md |
| FR-005 | RateLimiter | AC-RES-006 / TC-005 / `go test -race -run TestLimiter_ ./pkg/resiliencx/ratelimit/` | ✅ | ✅ | TRACEABILITY.md |
| FR-006 | Fallback | AC-RES-007 / TC-006 / `go test -run TestDo_ ./pkg/resiliencx/fallback/` | ✅ | ✅ | TRACEABILITY.md |
| BR-001 | 策略函数接受 context.Context（timeout/retry/bulkhead/fallback） | — / go vet | ✅ | ✅ | TRACEABILITY.md |
| BR-002 | 参数通过构造函数/Policy struct 传入，可由 configx 注入 | — / go build + code review | ✅ | ✅ | TRACEABILITY.md |
| BR-003 | 策略组合用函数嵌套（装饰器模式） | TC-008 / `go test -run TestCompose` | ✅ | ❌ 缺 TestCompose/compose.go | TRACEABILITY.md |
| BR-004 | 熔断器并发安全（sync.Mutex） | — / `go test -race -run TestBreaker_` | ✅ | ✅ | TRACEABILITY.md |
| BR-005 | 限流器并发安全（sync.Mutex） | — / `go test -race -run TestLimiter_` | ✅ | ✅ | TRACEABILITY.md |
| BR-006 | metrics 通过本地 Metrics interface 暴露，调用方注入 observex adapter | — / 代码审查 metrics.go | ✅ | ⚠️ 仅客户端层 metric，策略层 metric 未实现 | TRACEABILITY.md |
| BR-007 | 纯 stdlib，go mod graph 无第三方包 | — / go mod graph | ✅ | ✅ | TRACEABILITY.md |
| BR-008 | 策略可独立测试，不依赖外部服务 | — / go test ./pkg/resiliencx/... | ✅ | ✅ | TRACEABILITY.md |
| NFR-001 | 性能 | 单策略 < 200ns，5 层嵌套 < 1μs / `go test -bench=. -benchmem` | ✅ | ⚠️ 无 Benchmark 函数，目标未验证 | TRACEABILITY.md |
| NFR-002 | 可观测性 | metrics 注册且可抓取，状态变更日志正确 / 指标端点验证 + 日志检查 | ✅ | ⚠️ 仅客户端层 metric；策略层 metric 与日志未实现 | TRACEABILITY.md |
| NFR-003 | 安全 | 无凭证泄露、输入校验、panic 恢复 / gitleaks detect + code review | ✅ | ⚠️ 脱敏/输入校验 ✅；panic 恢复 ❌ | TRACEABILITY.md |
| NFR-004 | CI Gate | 编译/测试/-race/vet/lint/覆盖率均通过 / CI 全部门禁 | ✅ | ✅ 实测 98.1% | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC v1.0.2 / TRACEABILITY 当前登记一致。
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致（已纠正测试函数名）。
- [x] 运行时代码仓库 /home/resiliencx 通过 go test、go test -race、go vet 与覆盖率门槛（实测 98.1%）。
- [x] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据（纯 stdlib，无外部服务依赖）。
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致（运行时 v0.4.14 vs SPEC v1.0.2，待发布时统一）。

## 6. 当前缺口登记

- **BR-003 / TC-008**：策略组合辅助 `compose.go`/`TestCompose` 未实现。发布前需补实现或在 SPEC §22 显式声明延后。
- **NFR-001**：无 Benchmark 函数，性能预算为目标值未验证。发布前需补 `benchmark_test.go` 或降级 SPEC §16。
- **NFR-002 / BR-006**：策略层 metric（`resiliencx.timeout.count` 等）未实现，当前仅有客户端生命周期层 metric。
- **NFR-003**：fn panic 恢复未实现（SPEC §12/§18 P2 项）。
- 本文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
