# resiliencx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-30
Source: SPEC.md v1.0.2（runtime-release-synced）
Runtime-Repo: `/home/workspace/resiliencx` @ tag v1.0.2
Release-Evidence: tag v1.0.2 -> 1aaa0dc；GitHub Release Check 27777166525 passed；release-check / release-final-check 通过，score=10.00

---

## 证据口径说明

本矩阵区分两种状态列，避免"口径 ✅"掩盖"实测缺口"：

- **登记状态（Registry）**：该追溯项是否在文档中登记了验收口径。
- **运行时证据（Runtime Evidence）**：该追溯项是否有运行时代码/测试/CI 的机器事实支撑。`✅` = 已验证；`⚠️` = 非阻塞演进项或有边界说明；`❌` = 缺失。

---

## §1 FR Traceability

| FR ID | Requirement | AC ID(s) | TC ID(s) | Verification（实际测试函数） | Task | Status |
|-------|-------------|----------|----------|------------------------------|------|--------|
| FR-001 | Timeout | AC-RES-001 | TC-001 | `go test -run TestDo_ ./pkg/resiliencx/timeout/` | TASK-RESILIENCX-001 | ✅ |
| FR-002 | Retry | AC-RES-002 | TC-001 | `go test -run TestDo_ ./pkg/resiliencx/retry/` | TASK-RESILIENCX-002 | ✅ |
| FR-003 | CircuitBreaker | AC-RES-003, AC-RES-004 | TC-002, TC-003 | `go test -race -run TestBreaker_ ./pkg/resiliencx/circuit/`；连续失败阈值已覆盖，失败率维度保留为演进项 | TASK-RESILIENCX-003 | ✅ |
| FR-004 | Bulkhead | AC-RES-005 | TC-004 | `go test -run TestBulkhead_ ./pkg/resiliencx/bulkhead/` | TASK-RESILIENCX-004 | ✅ |
| FR-005 | RateLimiter | AC-RES-006 | TC-005 | `go test -race -run TestLimiter_ ./pkg/resiliencx/ratelimit/` | TASK-RESILIENCX-005 | ✅ |
| FR-006 | Fallback | AC-RES-007 | TC-006 | `go test -run TestDo_ ./pkg/resiliencx/fallback/` | TASK-RESILIENCX-006 | ✅ |

> **测试函数名口径**：实际测试函数为 `TestDo_*`（timeout/retry/fallback）、`TestBreaker_*`（circuit）、`TestBulkhead_*`、`TestLimiter_*`。v1.0.2 继续沿用该运行时命名。

---

## §2 BR Traceability

| BR ID | Rule | TC ID(s) | Verification | Task | Status |
|-------|------|----------|--------------|------|--------|
| BR-001 | 策略函数接受 `context.Context`（timeout/retry/bulkhead/fallback；circuit.Do/ratelimit 为纯内存操作不接 ctx） | — | `go vet` + 代码审查 | TASK-RESILIENCX-007 | ✅ |
| BR-002 | 策略参数通过构造函数/Policy struct 传入，可由 configx 注入；本库不自带配置解析 | — | `go build` + code review | TASK-RESILIENCX-007 | ✅ |
| BR-003 | 策略组合通过函数嵌套（装饰器模式）实现 | TC-008 | `go test -run TestCompose ./pkg/resiliencx/`；`compose.go` + `compose_test.go` / `TestCompose*` | TASK-RESILIENCX-008 | ✅ |
| BR-004 | 熔断器状态并发安全（sync.Mutex） | — | `go test -race -run TestBreaker_` | TASK-RESILIENCX-003 | ✅ |
| BR-005 | 限流器并发安全（sync.Mutex） | — | `go test -race -run TestLimiter_` | TASK-RESILIENCX-005 | ✅ |
| BR-006 | metrics 通过**本地 Metrics interface** 暴露，调用方注入 observex adapter（运行时未直接依赖 observex） | — | `Metrics`/`EventSink` + `InstrumentStrategy` 事件与计量测试通过 | TASK-RESILIENCX-009 | ✅ |
| BR-007 | 纯 stdlib，`go mod graph` 无第三方包 | — | `go mod graph` | TASK-RESILIENCX-007 | ✅ |
| BR-008 | 策略可独立测试，不依赖外部服务 | — | `go test ./pkg/resiliencx/...` | TASK-RESILIENCX-010 | ✅ |

> **BR-006 口径**：v1.0.2 稳定承诺为本地 `Metrics` interface（`IncCounter`/`ObserveHistogram`/`SetGauge`）与 `EventSink`，调用方可注入 observex adapter。运行时不直接依赖 observex。

---

## §3 NFR Traceability

| NFR ID | Category | Requirement | Verification | Task | Status |
|--------|----------|-------------|--------------|------|--------|
| NFR-001 | 性能 | Compose 与可观测包装有 benchmark 基线 | `go test ./pkg/resiliencx/... -bench=. -benchmem -run '^$'` | TASK-RESILIENCX-010 | ✅ `benchmark_test.go`；Compose 9.096 ns/op；InstrumentStrategy 664.0 ns/op |
| NFR-002 | 可观测性 | metrics/events 可由调用方注入并测试 | `InstrumentStrategy` tests | TASK-RESILIENCX-009 | ✅ metrics/tracing 事件测试通过 |
| NFR-003 | 安全 | 无凭证泄露、输入校验、panic 恢复 | release checks + code review | TASK-RESILIENCX-010 | ✅ `IsRecoveredPanic` / observer / Compose panic recovery 测试通过 |
| NFR-004 | CI Gate | 编译/测试/-race/vet/lint/coverage/release gates | release-check / release-final-check / GitHub Release Check | TASK-RESILIENCX-010 | ✅ score=10.00；GitHub Release Check 27777166525 passed |

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
| TC-008 | FR-001, FR-002, FR-006, BR-003 | `GOWORK=off go test -run TestCompose ./pkg/resiliencx/` | ✅ `compose.go` + `compose_test.go` |

---

## §5 AC Registry

| AC ID | FR/BR Ref | Criterion | Verification（实际） | Status |
|-------|-----------|-----------|----------------------|--------|
| AC-RES-001 | FR-001 | 正常完成返回 fn 结果；超过 duration 返回 `context.DeadlineExceeded`；ctx 取消返回 ctx.Err() | `go test -run TestDo_ ./pkg/resiliencx/timeout/` | ✅ |
| AC-RES-002 | FR-002 | 首次成功不重试；持续失败按 policy 重试至 MaxAttempts；达到上限返回最后一次错误；ctx 取消立即返回 | `go test -run TestDo_ ./pkg/resiliencx/retry/` | ✅ |
| AC-RES-003 | FR-003 | Closed→Open→Half-Open→Closed 三态转换正确；连续失败 >= threshold 触发 Open | `go test -run TestBreaker_ ./pkg/resiliencx/circuit/` | ✅（失败率维度保留为演进项） |
| AC-RES-004 | FR-003 | 多 goroutine 并发 Do 无 panic 无数据竞争 | `go test -race -run TestBreaker_ ./pkg/resiliencx/circuit/` | ✅ |
| AC-RES-005 | FR-004 | 并发 < max_concurrent 时执行；达上限 Do 等待或 ctx 取消；TryAcquire 返回 ErrFull | `go test -run TestBulkhead_ ./pkg/resiliencx/bulkhead/` | ✅ |
| AC-RES-006 | FR-005 | Allow 令牌充足返回 true，不足返回 false；Reserve 返回等待时长；并发安全 | `go test -race -run TestLimiter_ ./pkg/resiliencx/ratelimit/` | ✅ |
| AC-RES-007 | FR-006 | primary 成功返回 nil；primary 失败依次尝试 fallbacks 返回首个成功或最后错误 | `go test -run TestDo_ ./pkg/resiliencx/fallback/` | ✅ |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 6 | 6 | 100% |
| BR | 8 | 8 | 100% |


| NFR | 4 | 4 | 100% |
| AC | 7 | 7 | 100% |
| TC | 7 | 7 | 100% |
| **合计** | **32** | **32** | **100%** |

> 说明：全部 FR/BR/NFR/AC/TC 标记 Done。Task 总数 = TASK-RESILIENCX-001~010 共 10 项。

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§1-§5 表头替换双状态列（登记/运行时证据）为 Task+Status；新增 Task 列引用（TASK-RESILIENCX-001~010）；新增 §6 覆盖率仪表盘（标准化 Done/覆盖率格式）；新增 §7 变更历史 |
| 2026-06-19 | **v1.0.2 发布对齐**：同步 runtime tag v1.0.2 -> 1aaa0dc；记录 GitHub Release Check 27777166525 passed、release-check / release-final-check score=10.00；闭合 Compose、InstrumentStrategy、panic recovery、benchmark 与 integration runner 证据 |
| 2026-06-18 | **契约纠正**：对齐 SPEC v1.0.2；修正测试函数名（TestTimeout→TestDo_ 等）；降级 BR-003/BR-006/NFR-001/NFR-002/NFR-003/TC-008 伪闭合；新增"运行时证据"列区分口径与实测；补充待闭合项表 |
| 2026-06-16 | 重构为 5 节标准追溯结构（§1 FR / §2 BR / §3 NFR / §4 TC→FR / §5 AC），补全 Verification 列 |
| 2026-06-12 | 补全 Task 列、全部 BR (BR-001~BR-008)、NFR 行 (NFR-001~NFR-004)；Task 映射填充 |
| 2026-06-09 | 初始版本（从全局矩阵迁移） |

---

## 已闭合项（v1.0.2）

| ID | 原缺口 | v1.0.2 处置 |
|----|--------|-------------|
| BR-003 / TC-008 | 策略组合辅助 `compose.go`/`TestCompose` 未实现 | 已补 `compose.go` / `compose_test.go`，`TestCompose*` 通过 |
| NFR-001 | 历史缺口：缺少基准测试文件 | 已补 `benchmark_test.go`，发布基线记录 Compose 9.096 ns/op、InstrumentStrategy 664.0 ns/op |
| NFR-002 / BR-006 | 历史缺口：策略层指标扩展点未闭合 | 以本地 `Metrics`/`EventSink` + `InstrumentStrategy` 作为 v1.0.2 稳定扩展点闭合 |
| NFR-003 | panic 恢复未实现 | 已补 `IsRecoveredPanic`、observer 与 Compose panic recovery 测试 |
