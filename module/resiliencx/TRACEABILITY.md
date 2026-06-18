# resiliencx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-18
Source: SPEC.md v1.0.2（contract-corrected）
Runtime-Repo: `/home/resiliencx`（实测基线 v0.4.14，覆盖率 98.1%）

---

## 证据口径说明

本矩阵区分两种状态列，避免"口径 ✅"掩盖"实测缺口"：

- **登记状态（Registry）**：该追溯项是否在文档中登记了验收口径。
- **运行时证据（Runtime Evidence）**：该追溯项是否有运行时代码/测试/CI 的机器事实支撑。`✅` = 已验证；`⚠️` = 目标未实现或有偏差；`❌` = 缺失。

---

## §1 FR Traceability

| FR ID | Requirement | AC ID(s) | TC ID(s) | Verification（实际测试函数） | 登记 | 运行时证据 |
|-------|-------------|----------|----------|------------------------------|------|-----------|
| FR-001 | Timeout | AC-RES-001 | TC-001 | `go test -run TestDo_ ./pkg/resiliencx/timeout/` | ✅ | ✅ |
| FR-002 | Retry | AC-RES-002 | TC-001 | `go test -run TestDo_ ./pkg/resiliencx/retry/` | ✅ | ✅ |
| FR-003 | CircuitBreaker | AC-RES-003, AC-RES-004 | TC-002, TC-003 | `go test -race -run TestBreaker_ ./pkg/resiliencx/circuit/` | ✅ | ✅（仅连续失败阈值，无失败率维度，见 §22） |
| FR-004 | Bulkhead | AC-RES-005 | TC-004 | `go test -run TestBulkhead_ ./pkg/resiliencx/bulkhead/` | ✅ | ✅ |
| FR-005 | RateLimiter | AC-RES-006 | TC-005 | `go test -race -run TestLimiter_ ./pkg/resiliencx/ratelimit/` | ✅ | ✅ |
| FR-006 | Fallback | AC-RES-007 | TC-006 | `go test -run TestDo_ ./pkg/resiliencx/fallback/` | ✅ | ✅ |

> **测试函数名纠正**：v1.0.1 矩阵登记的 `TestTimeout`/`TestRetry`/`TestCircuitBreaker`/`TestBulkhead`/`TestRateLimiter`/`TestFallback` 在代码中**不存在**。实际测试函数为 `TestDo_*`（timeout/retry/fallback）、`TestBreaker_*`（circuit）、`TestBulkhead_*`、`TestLimiter_*`。

---

## §2 BR Traceability

| BR ID | Rule | TC ID(s) | Verification | 登记 | 运行时证据 |
|-------|------|----------|--------------|------|-----------|
| BR-001 | 策略函数接受 `context.Context`（timeout/retry/bulkhead/fallback；circuit.Do/ratelimit 为纯内存操作不接 ctx） | — | `go vet` + 代码审查 | ✅ | ✅ |
| BR-002 | 策略参数通过构造函数/Policy struct 传入，可由 configx 注入；本库不自带配置解析 | — | `go build` + code review | ✅ | ✅ |
| BR-003 | 策略组合通过函数嵌套（装饰器模式）实现 | TC-008 | `go test -run TestCompose` | ✅ | ❌ `TestCompose`/`compose.go` 不存在 |
| BR-004 | 熔断器状态并发安全（sync.Mutex） | — | `go test -race -run TestBreaker_` | ✅ | ✅ |
| BR-005 | 限流器并发安全（sync.Mutex） | — | `go test -race -run TestLimiter_` | ✅ | ✅ |
| BR-006 | metrics 通过**本地 Metrics interface** 暴露，调用方注入 observex adapter（运行时未直接依赖 observex） | — | 代码审查 metrics.go | ✅ | ⚠️ 仅有客户端生命周期 metric，策略层 metric 未实现 |
| BR-007 | 纯 stdlib，`go mod graph` 无第三方包 | — | `go mod graph` | ✅ | ✅ |
| BR-008 | 策略可独立测试，不依赖外部服务 | — | `go test ./pkg/resiliencx/...` | ✅ | ✅ |

> **BR-006 口径纠正**：v1.0.1 描述为"通过 `observex.Meter` 采集"，运行时实际未依赖 observex，而是定义本地 `Metrics` interface（`IncCounter`/`ObserveHistogram`/`SetGauge`），由调用方注入 observex adapter。且当前 metric 常量集中在客户端生命周期层（`client_*`），策略层 metric（如 `resiliencx.timeout.count`）未实现。

---

## §3 NFR Traceability

| NFR ID | Category | Requirement | Verification | 登记 | 运行时证据 |
|--------|----------|-------------|--------------|------|-----------|
| NFR-001 | 性能 | 单策略 < 200ns，5 层嵌套 < 1μs | `go test -bench=. -benchmem` | ✅ | ⚠️ 无任何 Benchmark 函数，目标未验证 |
| NFR-002 | 可观测性 | metrics 注册且可抓取，状态变更日志正确 | 指标端点验证 + 日志检查 | ✅ | ⚠️ 仅客户端层 metric；策略层 metric 与状态变更日志未实现 |
| NFR-003 | 安全 | 无凭证泄露、输入校验、panic 恢复 | `gitleaks detect` + code review | ✅ | ⚠️ 脱敏/输入校验 ✅；panic 恢复 ❌ 未实现 |
| NFR-004 | CI Gate | 编译/测试/-race/vet/lint/覆盖率均通过 | CI 全部门禁 | ✅ | ✅ build/vet/test/-race/coverage 通过（98.1%） |

---

## §4 TC→FR Reverse

| TC ID | Covers FR(s) | Command（实际） | 运行时证据 |
|-------|-------------|-----------------|-----------|
| TC-001 | FR-001, FR-002 | `go test -run "TestDo_" ./pkg/resiliencx/timeout/ ./pkg/resiliencx/retry/` | ✅ |
| TC-002 | FR-003 | `go test -race -run TestBreaker_ClosedToOpen ./pkg/resiliencx/circuit/` | ✅ |
| TC-003 | FR-003 | `go test -race -run TestBreaker_HalfOpen_ProbeSuccess ./pkg/resiliencx/circuit/` | ✅ |
| TC-004 | FR-004 | `go test -run TestBulkhead_LimitsConcurrency ./pkg/resiliencx/bulkhead/` | ✅ |
| TC-005 | FR-005 | `go test -race -run TestLimiter_AllowWithinBurst ./pkg/resiliencx/ratelimit/` | ✅ |
| TC-006 | FR-006 | `go test -run TestDo_FallbackSucceeds ./pkg/resiliencx/fallback/` | ✅ |
| TC-008 | FR-001, FR-002, FR-006, BR-003 | `go test -run TestCompose` | ❌ TestCompose/compose.go 不存在 |

---

## §5 AC Registry

| AC ID | FR/BR Ref | Criterion | Verification（实际） | 登记 | 运行时证据 |
|-------|-----------|-----------|----------------------|------|-----------|
| AC-RES-001 | FR-001 | 正常完成返回 fn 结果；超过 duration 返回 `context.DeadlineExceeded`；ctx 取消返回 ctx.Err() | `go test -run TestDo_ ./pkg/resiliencx/timeout/` | ✅ | ✅ |
| AC-RES-002 | FR-002 | 首次成功不重试；持续失败按 policy 重试至 MaxAttempts；达到上限返回最后一次错误；ctx 取消立即返回 | `go test -run TestDo_ ./pkg/resiliencx/retry/` | ✅ | ✅ |
| AC-RES-003 | FR-003 | Closed→Open→Half-Open→Closed 三态转换正确；连续失败 >= threshold 触发 Open | `go test -run TestBreaker_ ./pkg/resiliencx/circuit/` | ✅ | ✅（无失败率维度） |
| AC-RES-004 | FR-003 | 多 goroutine 并发 Do 无 panic 无数据竞争 | `go test -race -run TestBreaker_ ./pkg/resiliencx/circuit/` | ✅ | ✅ |
| AC-RES-005 | FR-004 | 并发 < max_concurrent 时执行；达上限 Do 等待或 ctx 取消；TryAcquire 返回 ErrFull | `go test -run TestBulkhead_ ./pkg/resiliencx/bulkhead/` | ✅ | ✅ |
| AC-RES-006 | FR-005 | Allow 令牌充足返回 true，不足返回 false；Reserve 返回等待时长；并发安全 | `go test -race -run TestLimiter_ ./pkg/resiliencx/ratelimit/` | ✅ | ✅ |
| AC-RES-007 | FR-006 | primary 成功返回 nil；primary 失败依次尝试 fallbacks 返回首个成功或最后错误 | `go test -run TestDo_ ./pkg/resiliencx/fallback/` | ✅ | ✅ |

---

## 覆盖率仪表盘（按口径分层）

| 类别 | 总数 | 登记覆盖 | 运行时证据覆盖 |
|------|------|----------|----------------|
| FR   | 6    | 6 (100%) | 6 (100%) |
| BR   | 8    | 8 (100%) | 7 (87.5%) — BR-003 缺 TestCompose |
| NFR  | 4    | 4 (100%) | 1 (25%) — 仅 NFR-004 实测通过 |
| AC   | 7    | 7 (100%) | 7 (100%) |

---

## 待闭合项（发布前处置）

| ID | 缺口 | 处置 |
|----|------|------|
| BR-003 / TC-008 | 策略组合辅助 `compose.go`/`TestCompose` 未实现 | 二选一：① 在 resiliencx repo 补实现；② 在 SPEC §22 显式声明延后，本矩阵 TC-008 标 ❌ |
| NFR-001 | 无 Benchmark 函数 | 二选一：① 补 `benchmark_test.go` 实测；② SPEC §16 改为"目标值，未纳入 1.0 门禁"，本矩阵标 ⚠️ |
| NFR-002 / BR-006 | 策略层 metric 未实现（仅客户端层） | SPEC §17 已记录三套命名差异；本矩阵标 ⚠️，待策略层 metric 补齐 |
| NFR-003 | panic 恢复未实现 | SPEC §12/§18 已记录为 P2 代码补强；本矩阵标 ⚠️ |

---

## 变更历史

| 日期 | 变更内容 |
|------|----------|
| 2026-06-18 | **契约纠正**：对齐 SPEC v1.0.2；修正测试函数名（TestTimeout→TestDo_ 等）；降级 BR-003/BR-006/NFR-001/NFR-002/NFR-003/TC-008 伪闭合；新增"运行时证据"列区分口径与实测；补充待闭合项表；版本基线对齐 v0.4.14 |
| 2026-06-16 | 重构为 5 节标准追溯结构（§1 FR / §2 BR / §3 NFR / §4 TC→FR / §5 AC），补全 Verification 列 |
| 2026-06-12 | 补全 Task 列、全部 BR (BR-001~BR-008)、NFR 行 (NFR-001~NFR-004)；Task 映射填充 |
| 2026-06-09 | 初始版本（从全局矩阵迁移） |
