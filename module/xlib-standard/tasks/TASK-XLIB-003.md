# TASK-XLIB-003

> PR-4：核心包 — pkg/templatex、contracts、examples、testkit

---

```yaml
task_id: TASK-XLIB-003
module: xlib-standard
scope: "重写 pkg/templatex/ 为核心包，更新 contracts/、examples/、testkit/"
spec_ref:
  - "module/xlib-standard/SPEC.md#7"
  - "module/xlib-standard/SPEC.md#9"
  - "module/xlib-standard/SPEC.md#10"
  - "module/xlib-standard/goal/1.md#7"
  - "module/xlib-standard/goal/1.md#8"
  - "module/xlib-standard/goal/1.md#9"
  - "module/xlib-standard/goal/1.md#10"
files:
  - "pkg/templatex/doc.go"
  - "pkg/templatex/config.go"
  - "pkg/templatex/errors.go"
  - "pkg/templatex/metrics.go"
  - "pkg/templatex/client.go"
  - "pkg/templatex/health.go"
  - "pkg/templatex/config_test.go"
  - "pkg/templatex/errors_test.go"
  - "pkg/templatex/metrics_test.go"
  - "pkg/templatex/client_test.go"
  - "pkg/templatex/health_test.go"
  - "contracts/errors.schema.json"
  - "contracts/health.schema.json"
  - "contracts/metrics.json"
  - "examples/basic/main.go"
  - "testkit/metrics.go"
  - "testkit/assertions.go"
acceptance_criteria:
  - "AC-001: pkg/templatex/ 只有 11 个文件（5 源码 + 5 测试 + 1 doc.go）"
  - "AC-002: 公共 API 包含 Config/Validate/Sanitize/New/Close/HealthCheck/Error/Metrics/Version"
  - "AC-003: ErrorKind 只有 8 种（validation/config/connection/auth/timeout/unavailable/closed/internal）"
  - "AC-004: P0 metrics 只有 5 个（client_created_total/client_closed_total/client_errors_total/client_health_status/client_health_latency_ms）"
  - "AC-005: contracts/errors.schema.json 的 kind enum 只有 8 种"
  - "AC-006: GOWORK=off go test ./... 通过"
  - "AC-007: GOWORK=off go test -race ./... 无竞态"
depends_on:
  - "TASK-XLIB-000"
  - "TASK-XLIB-001"
estimated_effort: "4h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-001 | Config 标准 | Config/Validate/Sanitize 存在 |
| FR-002 | Error 标准 | 8 种 ErrorKind |
| FR-003 | Health 标准 | HealthCheck 返回格式正确 |
| FR-004 | Metrics 标准 | 5 个 P0 指标 |
| FR-005 | Client 标准 | New/Close/HealthCheck 存在 |
| FR-007 | 公共 API 模板 | 全部 API 存在 |
| FR-008 | 模板可编译 | go test 通过 |
| §9 | Interface Contract | 接口定义正确 |
| §10 | Data Model | ErrorKind/HealthStatus 正确 |
| §12 | Error Handling | 8 个错误变量 |

## Test Plan

```bash
# 验收命令
GOWORK=off go test ./...
GOWORK=off go test -race ./...
ls pkg/templatex/ | wc -l  # 应为 11
grep -c "validation" contracts/errors.schema.json  # 应 > 0
grep -c "conflict" contracts/errors.schema.json  # 应为 0
```

## Implementation Notes

1. pkg/templatex/ 按 goal/1.md §7.1 只保留 11 个文件
2. 公共 API 按 goal/1.md §7.2 实现
3. Config 按 goal/1.md §7.3 实现（显式传入、Validate、Sanitize）
4. ErrorKind 按 goal/1.md §7.4 只有 8 种
5. Metrics 按 goal/1.md §7.5 只有 5 个 P0
6. Health 按 goal/1.md §7.6 实现
7. contracts 按 goal/1.md §8 更新 JSON schema
8. 测试按 goal/1.md §9 编写
9. examples 按 goal/1.md §10.1 只保留 basic/main.go
10. testkit 按 goal/1.md §10.2 只保留 metrics.go 和 assertions.go
