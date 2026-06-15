# resiliencx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-16
Source: SPEC.md v1.0.1

---

## §1 FR Traceability

| FR ID | Requirement | AC ID(s) | TC ID(s) | Verification | Status |
|-------|-------------|----------|----------|--------------|--------|
| FR-001 | Timeout | AC-RES-001 | TC-001 | `go test -run TestTimeout` | ✅ |
| FR-002 | Retry | AC-RES-002 | TC-001 | `go test -run TestRetry` | ✅ |
| FR-003 | CircuitBreaker | AC-RES-003, AC-RES-004 | TC-002, TC-003 | `go test -run TestCircuitBreaker -race` | ✅ |
| FR-004 | Bulkhead | AC-RES-005 | TC-004 | `go test -run TestBulkhead` | ✅ |
| FR-005 | RateLimiter | AC-RES-006 | TC-005 | `go test -run TestRateLimiter -race` | ✅ |
| FR-006 | Fallback | AC-RES-007 | TC-006 | `go test -run TestFallback` | ✅ |

---

## §2 BR Traceability

| BR ID | Rule | TC ID(s) | Verification | Status |
|-------|------|----------|--------------|--------|
| BR-001 | 所有策略必须接受 `context.Context` 参数 | — | `go vet` | ✅ |
| BR-002 | 策略参数从 `configx.Reader` 读取，不硬编码 | — | `go build` + code review | ✅ |
| BR-003 | 策略组合使用装饰器模式，外层包装内层 | TC-008 | `go test -run TestCompose` | ✅ |
| BR-004 | 熔断器状态必须并发安全 | — | `go test -race -run TestCircuitBreaker` | ✅ |
| BR-005 | 限流器必须并发安全 | — | `go test -race -run TestRateLimiter` | ✅ |
| BR-006 | 策略执行 metrics 通过 `observex.Meter` 采集 | — | 指标端点验证 | ✅ |
| BR-007 | 使用 stdlib + 最少依赖，不引入框架 | — | `go mod graph` | ✅ |
| BR-008 | 策略可独立测试，不依赖外部服务 | — | `go test -run` 各策略独立执行 | ✅ |

---

## §3 NFR Traceability

| NFR ID | Category | Requirement | Verification | Status |
|--------|----------|-------------|--------------|--------|
| NFR-001 | 性能 | 单策略调用 < 200ns，5 层嵌套 < 1μs | `go test -bench=. -benchmem` | ✅ |
| NFR-002 | 可观测性 | metrics 注册且可抓取，状态变更日志正确 | 指标端点验证 + 日志检查 | ✅ |
| NFR-003 | 安全 | 无凭证泄露、输入校验、panic 恢复 | `gitleaks detect` + code review | ✅ |
| NFR-004 | CI Gate | 编译/测试/-race/vet/lint/覆盖率均通过 | CI 全部门禁 | ✅ |

---

## §4 TC→FR Reverse

| TC ID | Covers FR(s) | Command |
|-------|-------------|---------|
| TC-001 | FR-001, FR-002 | `go test -run "TestTimeout\|TestRetry"` |
| TC-002 | FR-003 | `go test -run TestCircuitBreaker -race` |
| TC-003 | FR-003 | `go test -run TestCircuitBreaker -race` |
| TC-004 | FR-004 | `go test -run TestBulkhead` |
| TC-005 | FR-005 | `go test -run TestRateLimiter -race` |
| TC-006 | FR-006 | `go test -run TestFallback` |
| TC-008 | FR-001, FR-002, FR-006, BR-003 | `go test -run TestCompose` |

---

## §5 AC Registry

| AC ID | FR/BR Ref | Criterion | Verification | Status |
|-------|-----------|-----------|--------------|--------|
| AC-RES-001 | FR-001 | 正常完成返回 fn 结果；超时返回 ErrTimeout；ctx 取消返回 ctx.Err() | `go test -run TestTimeout` | ✅ |
| AC-RES-002 | FR-002 | 首次成功不重试；持续失败按 policy 重试至 max_retries；ctx 取消立即返回 | `go test -run TestRetry` | ✅ |
| AC-RES-003 | FR-003 | Closed→Open→Half-Open→Closed 三态转换正确 | `go test -run TestCircuitBreaker` | ✅ |
| AC-RES-004 | FR-003 | 多 goroutine 并发 Execute 无 panic 无数据竞争 | `go test -race -run TestCircuitBreaker` | ✅ |
| AC-RES-005 | FR-004 | 并发 < max_concurrent 执行；达上限等待；超时返回 ErrBulkheadFull | `go test -run TestBulkhead` | ✅ |
| AC-RES-006 | FR-005 | Allow/Wait 正确，速率超限拒绝，并发安全 | `go test -race -run TestRateLimiter` | ✅ |
| AC-RES-007 | FR-006 | primary 成功返回 primary 结果；primary 失败执行 secondary | `go test -run TestFallback` | ✅ |

---

## 覆盖率仪表盘

| 类别 | 总数 | 已覆盖 | 覆盖率 |
|------|------|--------|--------|
| FR   | 6    | 6      | 100%   |
| BR   | 8    | 8      | 100%   |
| NFR  | 4    | 4      | 100%   |

---

## 变更历史

| 日期 | 变更内容 |
|------|----------|
| 2026-06-16 | 重构为 5 节标准追溯结构（§1 FR / §2 BR / §3 NFR / §4 TC→FR / §5 AC），补全 Verification 列 |
| 2026-06-12 | 补全 Task 列、全部 BR (BR-001~BR-008)、NFR 行 (NFR-001~NFR-004)；Task 映射填充 |
| 2026-06-09 | 初始版本（从全局矩阵迁移） |
