# resiliencx 完整实现清单

- Status: Synced from v1.0.2 runtime release evidence
- Last-Updated: 2026-06-19
- Module-Version: v1.0.2（已发布运行时代码基线）
- Spec-Version: v1.0.2
- Module-State: 已发布
- Layer: L1 基础能力（与 SPEC §3 / FOUNDATION-DEPS.yaml 一致）
- Runtime-Repo: /home/resiliencx @ tag v1.0.2
- Release-Evidence: tag v1.0.2 -> 1aaa0dc；GitHub Release Check 27777166525 passed；release-check / release-final-check 通过
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单约束 resiliencx 的完整实现范围，并同步运行时代码仓库的 v1.0.2 发布证据。`GOWORK=off XLIB_CONTEXT=ci_pull_request make release-check` 通过，score=10.00，证据 hash 为 `d2556ba0605e0b4c24a8b3f82a50ef7ede47309282d038ece810905f006c6781`；`GOWORK=off XLIB_CONTEXT=release_verify make release-final-check` 通过，score=10.00，证据 hash 为 `18ba39ad95d66126679b05d38d4221b6bb1f0e6401849bc5ffc1adbfe83e5a32`。
>
> **v1.0.2 发布同步**：本版本已补齐 Compose、InstrumentStrategy、recovered panic、benchmark 与 integration runner 发布证据。`example_test.go` 不属于 v1.0.2 阻塞交付项，公共示例由 README 与 `examples/basic|config|health` 承载。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | timeout、retry、circuit、bulkhead、rate、fallback、Compose、InstrumentStrategy 与 recovered panic 等韧性原语 |
| 文档目录 | module/resiliencx |
| 运行时代码目录 | /home/resiliencx |
| Go 基线 | 1.23 |
| 实际依赖 | 纯 stdlib（`go mod graph` 无第三方包；不依赖 kernel/configx/observex） |
| 允许依赖（SPEC 许可） | kernel（运行时未直接依赖）、configx（由消费者侧注入） |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 子包/入口（实际） | 验收/测试/任务挂钩 | 当前登记状态 | 运行时证据 | 来源 |
| --- | --- | --- | --- | --- | --- | --- |
| FR-001 | Timeout | `timeout.Do(ctx, d, fn)` | AC-RES-001 / TC-001 / `go test -run TestDo_ ./pkg/resiliencx/timeout/` | ✅ | ✅ | TRACEABILITY.md |
| FR-002 | Retry | `retry.Do(ctx, policy, fn)` | AC-RES-002 / TC-001 / `go test -run TestDo_ ./pkg/resiliencx/retry/` | ✅ | ✅ | TRACEABILITY.md |
| FR-003 | CircuitBreaker | `circuit.New(threshold, cooldown)` + `.Do(fn)` | AC-RES-003, AC-RES-004 / TC-002, TC-003 / `go test -race -run TestBreaker_ ./pkg/resiliencx/circuit/` | ✅ | ✅（连续失败阈值；失败率维度保留为演进项） | TRACEABILITY.md |
| FR-004 | Bulkhead | `bulkhead.New(max)` + `.Do(ctx, fn)` | AC-RES-005 / TC-004 / `go test -run TestBulkhead_ ./pkg/resiliencx/bulkhead/` | ✅ | ✅ | TRACEABILITY.md |
| FR-005 | RateLimiter | `ratelimit.New(rate, max)` + `.Allow()`/`.Reserve()` | AC-RES-006 / TC-005 / `go test -race -run TestLimiter_ ./pkg/resiliencx/ratelimit/` | ✅ | ✅ | TRACEABILITY.md |
| FR-006 | Fallback | `fallback.Do(ctx, fn, fallbacks...)` | AC-RES-007 / TC-006 / `go test -run TestDo_ ./pkg/resiliencx/fallback/` | ✅ | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 运行时证据 | 来源 |
| --- | --- | --- | --- | --- | --- |
| BR-001 | 策略函数接受 context.Context（timeout/retry/bulkhead/fallback） | — / go vet | ✅ | ✅ | TRACEABILITY.md |
| BR-002 | 参数通过构造函数/Policy struct 传入，可由 configx 注入 | — / go build + code review | ✅ | ✅ | TRACEABILITY.md |
| BR-003 | 策略组合用函数嵌套（装饰器模式） | TC-008 / `go test -run TestCompose ./pkg/resiliencx/` | ✅ | ✅ `compose.go` + `compose_test.go` / `TestCompose*` | TRACEABILITY.md |
| BR-004 | 熔断器并发安全（sync.Mutex） | — / `go test -race -run TestBreaker_` | ✅ | ✅ | TRACEABILITY.md |
| BR-005 | 限流器并发安全（sync.Mutex） | — / `go test -race -run TestLimiter_` | ✅ | ✅ | TRACEABILITY.md |
| BR-006 | metrics 通过本地 Metrics interface 暴露，调用方注入 observex adapter | — / `InstrumentStrategy` tests | ✅ | ✅ `Metrics`/`EventSink` + `InstrumentStrategy` 事件与计量测试通过 | TRACEABILITY.md |
| BR-007 | 纯 stdlib，go mod graph 无第三方包 | — / go mod graph | ✅ | ✅ | TRACEABILITY.md |
| BR-008 | 策略可独立测试，不依赖外部服务 | — / go test ./pkg/resiliencx/... | ✅ | ✅ | TRACEABILITY.md |
| NFR-001 | 性能 | `go test ./pkg/resiliencx/... -bench=. -benchmem -run '^$'` | ✅ | ✅ `benchmark_test.go`；Compose 9.096 ns/op；InstrumentStrategy 664.0 ns/op | TRACEABILITY.md |
| NFR-002 | 可观测性 | metrics/events 可由调用方注入并测试 | ✅ | ✅ metrics/tracing 事件测试通过 | TRACEABILITY.md |
| NFR-003 | 安全 | 无凭证泄露、输入校验、panic 恢复 / release checks + code review | ✅ | ✅ panic recovery：`IsRecoveredPanic` / observer / Compose 测试通过 | TRACEABILITY.md |
| NFR-004 | CI Gate | 编译/测试/-race/vet/lint/coverage/release gates | ✅ | ✅ release-check + release-final-check；score=10.00 | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-RESILIENCX-000 | go.mod/doc.go/errors.go 骨架 | module/resiliencx/tasks/TASK-RESILIENCX-000.md | 已交付 | tasks/TASK-RESILIENCX-000.md |
| TASK-RESILIENCX-001 | timeout 策略 | module/resiliencx/tasks/TASK-RESILIENCX-001.md | 已交付 | tasks/TASK-RESILIENCX-001.md |
| TASK-RESILIENCX-002 | retry 策略 | module/resiliencx/tasks/TASK-RESILIENCX-002.md | 已交付 | tasks/TASK-RESILIENCX-002.md |
| TASK-RESILIENCX-003 | circuit breaker 策略 | module/resiliencx/tasks/TASK-RESILIENCX-003.md | 已交付 | tasks/TASK-RESILIENCX-003.md |
| TASK-RESILIENCX-004 | bulkhead 策略 | module/resiliencx/tasks/TASK-RESILIENCX-004.md | 已交付 | tasks/TASK-RESILIENCX-004.md |
| TASK-RESILIENCX-005 | rate limiter 策略 | module/resiliencx/tasks/TASK-RESILIENCX-005.md | 已交付 | tasks/TASK-RESILIENCX-005.md |
| TASK-RESILIENCX-006 | fallback 策略 | module/resiliencx/tasks/TASK-RESILIENCX-006.md | 已交付 | tasks/TASK-RESILIENCX-006.md |
| TASK-RESILIENCX-007 | options/errors/options 模式 | module/resiliencx/tasks/TASK-RESILIENCX-007.md | 已交付 | tasks/TASK-RESILIENCX-007.md |
| TASK-RESILIENCX-008 | 策略组合（compose.go/TestCompose） | module/resiliencx/tasks/TASK-RESILIENCX-008.md | v1.0.2 已交付/已验证 | tasks/TASK-RESILIENCX-008.md |
| TASK-RESILIENCX-009 | benchmark/集成测试 | module/resiliencx/tasks/TASK-RESILIENCX-009.md | v1.0.2 已交付/已验证 | tasks/TASK-RESILIENCX-009.md |
| TASK-RESILIENCX-010 | CI/Benchmark/Docs | module/resiliencx/tasks/TASK-RESILIENCX-010.md | v1.0.2 已交付/已验证 | tasks/TASK-RESILIENCX-010.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在（v1.0.2 发布同步） | module/resiliencx/goal.md |
| SPEC.md | 存在（v1.0.2 发布同步） | module/resiliencx/SPEC.md |
| TRACEABILITY.md | 存在（v1.0.2 运行时证据闭合） | module/resiliencx/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/resiliencx/IMPLEMENTATION-PLAN.md |
| tasks/ | 11 个 Markdown 文件 | module/resiliencx/tasks |

## 6. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试覆盖。
- [x] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC；TASK-008/009/010 的 v1.0.2 运行时证据已闭合。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖（实测纯 stdlib）。
- [x] 运行时代码仓库 /home/resiliencx 的 release-check 与 release-final-check 均通过，score=10.00。
- [x] 发布说明、版本标签与本目录登记状态一致（v1.0.2 已发布）。
- [ ] factory-grade / BLK-007 仍在机器事实层保持 factory=false，不作为 v1.0.2 文档同步阻塞项。
