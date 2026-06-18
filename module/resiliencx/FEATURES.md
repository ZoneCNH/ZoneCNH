# resiliencx 完整实现清单

- Status: Generated from current module SSOT (contract-corrected)
- Last-Updated: 2026-06-18
- Module-Version: v0.4.9（运行时代码实测基线）
- Spec-Version: v1.0.2
- Module-State: 已发布
- Layer: L1 基础能力（与 SPEC §3 / FOUNDATION-DEPS.yaml 一致）
- Runtime-Repo: /home/resiliencx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 resiliencx 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。
>
> **v1.0.2 契约纠正**：本版本对齐 SPEC v1.0.2，API 名/error 名/测试命令均替换为运行时实际符号。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | timeout、retry、circuit、bulkhead、rate、fallback 等韧性原语（子包级） |
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
| FR-003 | CircuitBreaker | `circuit.New(threshold, cooldown)` + `.Do(fn)` | AC-RES-003, AC-RES-004 / TC-002, TC-003 / `go test -race -run TestBreaker_ ./pkg/resiliencx/circuit/` | ✅ | ✅（无失败率维度） | TRACEABILITY.md |
| FR-004 | Bulkhead | `bulkhead.New(max)` + `.Do(ctx, fn)` | AC-RES-005 / TC-004 / `go test -run TestBulkhead_ ./pkg/resiliencx/bulkhead/` | ✅ | ✅ | TRACEABILITY.md |
| FR-005 | RateLimiter | `ratelimit.New(rate, max)` + `.Allow()`/`.Reserve()` | AC-RES-006 / TC-005 / `go test -race -run TestLimiter_ ./pkg/resiliencx/ratelimit/` | ✅ | ✅ | TRACEABILITY.md |
| FR-006 | Fallback | `fallback.Do(ctx, fn, fallbacks...)` | AC-RES-007 / TC-006 / `go test -run TestDo_ ./pkg/resiliencx/fallback/` | ✅ | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 运行时证据 | 来源 |
| --- | --- | --- | --- | --- | --- |
| BR-001 | 策略函数接受 context.Context（timeout/retry/bulkhead/fallback） | — / go vet | ✅ | ✅ | TRACEABILITY.md |
| BR-002 | 参数通过构造函数/Policy struct 传入，可由 configx 注入 | — / go build + code review | ✅ | ✅ | TRACEABILITY.md |
| BR-003 | 策略组合用函数嵌套（装饰器模式） | TC-008 / `go test -run TestCompose` | ✅ | ❌ 缺 TestCompose/compose.go | TRACEABILITY.md |
| BR-004 | 熔断器并发安全（sync.Mutex） | — / `go test -race -run TestBreaker_` | ✅ | ✅ | TRACEABILITY.md |
| BR-005 | 限流器并发安全（sync.Mutex） | — / `go test -race -run TestLimiter_` | ✅ | ✅ | TRACEABILITY.md |
| BR-006 | metrics 通过本地 Metrics interface 暴露，调用方注入 observex adapter | — / 代码审查 metrics.go | ✅ | ⚠️ 仅客户端层 metric | TRACEABILITY.md |
| BR-007 | 纯 stdlib，go mod graph 无第三方包 | — / go mod graph | ✅ | ✅ | TRACEABILITY.md |
| BR-008 | 策略可独立测试，不依赖外部服务 | — / go test ./pkg/resiliencx/... | ✅ | ✅ | TRACEABILITY.md |
| NFR-001 | 性能 | 单策略 < 200ns，5 层嵌套 < 1μs / `go test -bench=. -benchmem` | ✅ | ⚠️ 无 Benchmark 函数 | TRACEABILITY.md |
| NFR-002 | 可观测性 | metrics 注册且可抓取，状态变更日志正确 / 指标端点验证 + 日志检查 | ✅ | ⚠️ 仅客户端层 metric | TRACEABILITY.md |
| NFR-003 | 安全 | 无凭证泄露、输入校验、panic 恢复 / gitleaks detect + code review | ✅ | ⚠️ panic 恢复 ❌ | TRACEABILITY.md |
| NFR-004 | CI Gate | 编译/测试/-race/vet/lint/覆盖率均通过 / CI 全部门禁 | ✅ | ✅ 实测 98.1% | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-RESILIENCX-000 | go.mod/doc.go/errors.go 骨架 | module/resiliencx/tasks/TASK-RESILIENCX-000.md | - | tasks/TASK-RESILIENCX-000.md |
| TASK-RESILIENCX-001 | timeout 策略 | module/resiliencx/tasks/TASK-RESILIENCX-001.md | - | tasks/TASK-RESILIENCX-001.md |
| TASK-RESILIENCX-002 | retry 策略 | module/resiliencx/tasks/TASK-RESILIENCX-002.md | - | tasks/TASK-RESILIENCX-002.md |
| TASK-RESILIENCX-003 | circuit breaker 策略 | module/resiliencx/tasks/TASK-RESILIENCX-003.md | - | tasks/TASK-RESILIENCX-003.md |
| TASK-RESILIENCX-004 | bulkhead 策略 | module/resiliencx/tasks/TASK-RESILIENCX-004.md | - | tasks/TASK-RESILIENCX-004.md |
| TASK-RESILIENCX-005 | rate limiter 策略 | module/resiliencx/tasks/TASK-RESILIENCX-005.md | - | tasks/TASK-RESILIENCX-005.md |
| TASK-RESILIENCX-006 | fallback 策略 | module/resiliencx/tasks/TASK-RESILIENCX-006.md | - | tasks/TASK-RESILIENCX-006.md |
| TASK-RESILIENCX-007 | options/errors/options 模式 | module/resiliencx/tasks/TASK-RESILIENCX-007.md | - | tasks/TASK-RESILIENCX-007.md |
| TASK-RESILIENCX-008 | 策略组合（compose.go/TestCompose） | module/resiliencx/tasks/TASK-RESILIENCX-008.md | - | tasks/TASK-RESILIENCX-008.md（⚠️ 未实现） |
| TASK-RESILIENCX-009 | benchmark/集成测试 | module/resiliencx/tasks/TASK-RESILIENCX-009.md | - | tasks/TASK-RESILIENCX-009.md（⚠️ 未实现） |
| TASK-RESILIENCX-010 | CI/Benchmark/Docs | module/resiliencx/tasks/TASK-RESILIENCX-010.md | - | tasks/TASK-RESILIENCX-010.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/resiliencx/goal.md |
| SPEC.md | 存在（v1.0.2 契约纠正） | module/resiliencx/SPEC.md |
| TRACEABILITY.md | 存在（含运行时证据列） | module/resiliencx/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/resiliencx/IMPLEMENTATION-PLAN.md |
| tasks/ | 11 个 Markdown 文件 | module/resiliencx/tasks |

## 6. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试覆盖（实测 98.1% 覆盖率）。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖（BR-003/NFR-001/NFR-002/NFR-003 有缺口）。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC（TASK-008/009 对应实现未交付）。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖（实测纯 stdlib）。
- [x] 运行时代码仓库 /home/resiliencx 的 lint、typecheck、test、race、coverage 验证证据已归档（98.1%）。
- [ ] 发布说明、版本标签与本目录登记状态一致（运行时 v0.4.9 vs SPEC v1.0.2，待发布时统一）。
