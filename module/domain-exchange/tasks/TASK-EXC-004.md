# TASK-EXC-004

> VenueCapability、RateLimitPolicy、VenueProfile 静态描述

---

```yaml
task_id: TASK-EXC-004
module: domain-exchange
scope: "定义 VenueCapability 常量、RateLimitPolicy 结构、VenueProfile 静态描述，确保可测试且可配置"
spec_ref:
  - "module/domain-exchange/SPEC.md#FR-EXC-004"
  - "module/domain-exchange/SPEC.md#§10"
  - "module/domain-exchange/SPEC.md#§11"
files:
  - "capability.go"
  - "capability_test.go"
  - "config.go"
acceptance_criteria:
  - "AC-EXC-004: VenueCapability 常量可静态声明（spot/perp/ws/funding/open_interest/margin）"
  - "AC-EXC-004: RateLimitPolicy 包含 RequestsPerSecond 和 Burst"
  - "AC-EXC-004: VenueProfile 可从 YAML 配置加载"
  - "AC-EXC-004: 不支持的 capability 查询返回 ErrUnsupportedCapability"
depends_on:
  - "TASK-EXC-001"
  - "TASK-EXC-003"
estimated_effort: "1.5h"
priority: P1
status: pending
non_scope:
  - "不实现运行时 capability 动态变更"
  - "不实现 rate limiter 中间件"
  - "不实现 Registry（→TASK-EXC-005）"
```

---

## Non-scope

- 不实现运行时 capability 动态变更
- 不实现 rate limiter 中间件
- 不实现 Registry（→TASK-EXC-005）

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-EXC-004 | capability/profile/rate limit 可静态声明 | AC-EXC-004: 类型完整，YAML 可加载 |
| BR-EXC-001 | 不支持的能力返回 typed error | AC-EXC-004: 返回 ErrUnsupportedCapability |

## Test Plan

| Test Case | Type    | Description |
| --------- | ------- | ----------- |
| TC-EXC-004 | Unit    | capability 查询不支持时返回 ErrUnsupportedCapability |

## Implementation Notes

- Capability 常量为追加式，不删除旧常量
- VenueProfile 与 SPEC §10/§11 一致
- YAML 配置可被 kernel 启动时加载

## Implementation Plan

| Step | Description | Deliverables | Verification |
| ---- | ----------- | ------------ | ------------ |
| 1    | 定义 Capability 常量和 RateLimitPolicy | `capability.go` | `go build ./...` 通过 |
| 2    | 实现 VenueProfile 构建和 YAML 加载 | `config.go` | `go build ./...` 通过 |
| 3    | capability 测试 | `capability_test.go` | `go test ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Capability 常量与下游 adapter 不一致 | Low | Medium | 新增常量为追加，不删除旧值 |
