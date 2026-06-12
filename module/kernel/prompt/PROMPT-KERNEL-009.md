# TASK-KERNEL-009 开发 Prompt

> retryx 子包：重试策略配置原语

---

## 任务

实现 `kernel/retryx` 子包。提供重试策略校验、指数退避延迟计算和可重试错误判断，依赖 errx 子包。不包含重试执行引擎（→ resiliencx）。

## 文件清单

### 1. `retryx/retryx.go`

- `RetryPolicy` 结构体：MaxAttempts + BaseDelay + MaxDelay
- `DefaultRetryPolicy()`：{MaxAttempts: 3, BaseDelay: 100ms, MaxDelay: 2s}
- `RetryPolicy.Validate() error`：字段非法返回 ErrorKindValidation
- `RetryPolicy.Delay(attempt int) time.Duration`：指数退避 `BaseDelay * 2^(attempt-1)`，溢出保护
- `RetryPolicy.DelayWithJitter(attempt int, ratio, fraction float64) time.Duration`：jitter 钳位到 [-1,1]
- `ShouldRetry(err error) bool`：遍历 errx 错误链检查 Retryable 标记

### 2. `retryx/retryx_test.go`

覆盖：DefaultRetryPolicy 默认值、Validate 各非法组合、Delay 指数增长、溢出保护、DelayWithJitter 范围、ShouldRetry 链遍历。

### 3. `retryx/example_test.go`

展示 RetryPolicy 配置、Delay 计算、与 retry loop 结合使用（伪代码）。

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-008 | FR-005 | Delay 测试 | 指数退避 + Jitter + 溢出保护 |
| AC-RETRYX-03 | FR-005 | Delay(1) | 返回 BaseDelay |
| AC-RETRYX-06 | FR-005 | ShouldRetry | 遍历错误链 |

## 禁止事项

- 不要实现重试执行循环（属于 resiliencx）
- 不要实现熔断/限流/退避状态机
- Delay/DelayWithJitter 不要返回负值
- attempt <= 0 时返回 0

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-009/`：
1. `go test -race -count=1 ./retryx/...` 输出
2. Benchmark：`go test -bench=. -benchmem ./retryx/...`

## 完成后

1. 验证 Delay 溢出保护不 panic
2. 验证 ShouldRetry 支持 errors.Join 多链
3. 更新 TASK-KERNEL-009 状态为 completed
