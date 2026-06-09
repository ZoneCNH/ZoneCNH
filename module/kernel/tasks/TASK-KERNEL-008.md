# TASK-KERNEL-008

> 配置与选项：Option 模式、startup_timeout、shutdown_timeout

---

```yaml
task_id: TASK-KERNEL-008
module: kernel
scope: "实现 Option 函数模式，支持 startup/shutdown/health 配置项，提供合理默认值"
spec_ref:
  - "module/kernel/SPEC.md#11"
  - "module/kernel/SPEC.md#9.1"
files:
  - "options.go"
  - "kernel.go"
  - "options_test.go"
acceptance_criteria:
  - "AC-NEW-41: New() 无参数时使用默认值"
  - "AC-NEW-42: WithStartupTimeout 覆盖默认启动超时"
  - "AC-NEW-43: WithShutdownTimeout 覆盖默认停机超时"
  - "AC-NEW-44: WithHealthCheckInterval 覆盖默认健康检查间隔"
  - "AC-NEW-45: 返回的 App 实现 §9.1 的 App 接口"
depends_on:
  - "TASK-KERNEL-001"
estimated_effort: "1h"
priority: P1
status: pending
```

---

## Files Likely to Change

- `options.go` — 新建
- `kernel.go` — 修改（App 增加 cfg 字段）
- `options_test.go` — 新建

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §11 | Config Schema：startup_timeout, shutdown_timeout, health_check_interval | Option 函数覆盖所有配置项 |
| §9.1 | App 接口的构造函数 | New() 支持 Option 模式 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| — | Unit | 默认值：New() 的 startup_timeout 为 30s |
| — | Unit | 默认值：New() 的 shutdown_timeout 为 15s |
| — | Unit | Option 覆盖：WithStartupTimeout(5s) 生效 |
| — | Unit | Option 组合：多个 Option 叠加生效 |
| — | Unit | App 接口：New() 返回值实现 App 接口 |

## Implementation Notes

- ⚠️ 本 task 修改 TASK-KERNEL-001 创建的 kernel.go，必须在 001 完成后才能开始。
- `type Option func(*app)` 函数模式
- `app` 结构体为 App 接口的私有实现，包含 registry、graph、config 等
- 默认值在 `New()` 中设置，Option 在之后应用
- `app` 结构体应在 `kernel.go` 中定义（与接口同文件）
- 超时配置存储在 app 结构体中，供 lifecycle 和 shutdown 使用

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 定义 `Option` 类型 `func(*app)` 和 `app` 结构体（registry, graph, config 字段） | `options.go`, `kernel.go` | `go build ./...` 通过 |
| 2 | 实现 `New(opts ...Option) App` 构造函数，设置默认值（startup 30s, shutdown 15s, health 30s） | `kernel.go` | `go test ./... -run TestNewDefaults` 通过 |
| 3 | 实现 `WithStartupTimeout`、`WithShutdownTimeout`、`WithHealthCheckInterval` Option 函数 | `options.go` | `go test ./... -run TestOptions` 通过 |
| 4 | 验证 New() 返回值实现 App 接口（编译期检查） | `kernel.go` | `go vet ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| app 结构体字段与后续 task 不匹配 | Low | Medium | 对照 SPEC §11 Config Schema |
| 默认值不合理 | Low | Low | 以 SPEC 中的建议值为准 |
