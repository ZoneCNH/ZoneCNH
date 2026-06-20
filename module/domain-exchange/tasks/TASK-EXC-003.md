# TASK-EXC-003

> ExchangeError 分类与 retry 语义

---

```yaml
task_id: TASK-EXC-003
module: domain_exchange
scope: "定义 ExchangeError 类型体系，区分临时/永久/限速/认证/余额/精度/不支持能力，支持 IsRetryable/RetryAfter/IsIdempotentSafe"
spec_ref:
  - "module/domain_exchange/SPEC.md#FR-EXC-003"
  - "module/domain_exchange/SPEC.md#§12"
  - "module/domain_exchange/SPEC.md#BR-EXC-003"
files:
  - "errors.go"
  - "errors_test.go"
acceptance_criteria:
  - "AC-EXC-003: ExchangeError 区分临时/永久/限速/认证/余额/精度/不支持能力"
  - "AC-EXC-003: IsRetryable/RetryAfter/IsIdempotentSafe 可判断重试策略"
  - "AC-EXC-003: 错误可被 errors.Is/As 识别"
  - "AC-EXC-003: adapter 必须映射原始错误为 typed ExchangeError"
depends_on:
  - "TASK-EXC-001"
estimated_effort: "2h"
priority: P0
status: pending
non_scope:
  - "不实现 adapter 错误映射逻辑"
  - "不实现 retry 框架（仅分类语义）"
  - "不定义 request 类型（→TASK-EXC-002）"
```

---

## Non-scope

- 不实现 adapter 错误映射逻辑
- 不实现 retry 框架（仅分类语义）
- 不定义 request 类型（→TASK-EXC-002）

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-EXC-003 | ExchangeError 可分类并支持 retry 判断 | AC-EXC-003: 错误分类完整，retry 语义可用 |
| BR-EXC-003 | adapter 必须映射原始错误为 typed ExchangeError | AC-EXC-003: 错误可被 errors.Is/As 识别 |

## Test Plan

| Test Case | Type    | Description |
| --------- | ------- | ----------- |
| TC-EXC-003 | Unit    | 错误可分类为 retryable / non-retryable / auth / rate limit |

## Implementation Notes

- 错误类型与 SPEC §12 Error Handling 一致
- ExchangeError 包含 venue code，可被上层 observex 包装
- Fail-closed 原则：未知错误默认不可重试

## Implementation Plan

| Step | Description | Deliverables | Verification |
| ---- | ----------- | ------------ | ------------ |
| 1    | 定义 ExchangeError 类型体系和 sentinel 错误 | `errors.go` | `go build ./...` 通过 |
| 2    | 实现 IsRetryable/RetryAfter/IsIdempotentSafe | `errors.go` | `go build ./...` 通过 |
| 3    | 错误分类 golden 测试 | `errors_test.go` | `go test ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| 错误分类遗漏交易所特有错误码 | Medium | Medium | 未知错误归为 ErrTemporary，fail-closed |
