# TASK-XLIB-004

> Go 参考模板：公共 API、HealthCheck、Error Handling、Config Sanitize

---

```yaml
task_id: TASK-XLIB-004
module: xlib-standard
scope: "实现 Go 参考模板——公共 API（New/Close/HealthCheck）、ErrorKind 体系、Config Sanitize、Metrics 接口"
spec_ref:
  - "specs/xlib-standard/SPEC.md#FR-009"
  - "specs/xlib-standard/SPEC.md#FR-010"
  - "specs/xlib-standard/SPEC.md#FR-011"
  - "specs/xlib-standard/SPEC.md#FR-012"
  - "specs/xlib-standard/SPEC.md#FR-013"
  - "specs/xlib-standard/SPEC.md#FR-014"
files:
  - "template/go/client.go"
  - "template/go/error.go"
  - "template/go/config.go"
  - "template/go/health.go"
  - "template/go/metrics.go"
acceptance_criteria:
  - "AC-T01: 模板渲染产物通过 `go vet ./...` 零警告"
  - "xlib-TC-001: New(ctx, Config{}) 零值 Config 返回 ErrorKindValidation"
  - "xlib-TC-004: Close(ctx) 调用 N 次幂等"
  - "xlib-TC-006: Sanitize() 所有 secret 字段为空"
  - "xlib-TC-014: IsKind(err, ErrorKindTimeout) 正确匹配"
depends_on:
  - "TASK-XLIB-000"
estimated_effort: "6h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-009 | 公共 API（New/Close） |
| FR-010 | ErrorKind 体系 |
| FR-011 | Metrics 接口（9 个指标） |
| FR-012 | HealthCheck 接口 |
| FR-013 | Config 必须显式传入 |
| FR-014 | Config Sanitize（deep copy + secret 清除） |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| xlib-TC-001~017 | TL1~TL4 | 17 个 TC 全部覆盖 |
| — | CI Gate | `go vet ./...` 零警告 |
| — | CI Gate | `go test -race ./...` 通过 |

## Implementation Plan

### Step 1: 定义 ErrorKind 体系
- `error.go`：ErrorKind 枚举（Validation, Timeout, Unavailable, Config, RateLimit, Internal）
- `WrapError(kind, cause, msg)` 函数
- `IsKind(err, kind)` 函数
- `errors.Is(err, cause)` 兼容

### Step 2: 实现 Config Sanitize
- `config.go`：Config 结构体定义
- `Sanitize()` 方法：deep copy + 清除所有 secret 字段
- `Validate()` 方法：校验必填字段
- nil receiver 防护

### Step 3: 实现公共 API
- `client.go`：`New(ctx, Config)` 和 `Close(ctx)` 函数
- 零值 Config 返回 ErrorKindValidation
- nil context 返回 ErrorKindValidation
- canceled context 返回 ErrorKindTimeout
- Close 幂等

### Step 4: 实现 HealthCheck 和 Metrics
- `health.go`：`HealthCheck(ctx)` 返回 status/latency_ms/checked_at
- `metrics.go`：9 个指标定义

### Step 5: 验证
- xlib-TC-001~017 全部通过
- `go vet ./...` 零警告
- `go test -race ./...` 通过

### 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| ErrorKind 语义与上游不一致 | 中 | 高 | 从上游 template/go/error.go 提取 |
| Sanitize 遗漏 secret 字段 | 中 | 高 | 对照上游 template/go/config.go 核对 |
