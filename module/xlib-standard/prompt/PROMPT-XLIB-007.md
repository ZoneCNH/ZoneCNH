# Context Packet — TASK-XLIB-007

> PR-4c：Health + Metrics — pkg/templatex/health.go + metrics.go + contracts
> 工作分支: `feat/xlib-v1-packages`

## Current Task

TASK-XLIB-007: HealthCheck 和 Metrics 5 个 P0 指标

## Related Spec

- module/xlib-standard/SPEC.md §7 Functional Requirements, §9 Interfaces, §10 Data Model

## Related Requirements

- FR-003: Health 标准 — HealthCheck 返回格式正确
- FR-004: Metrics 标准 — 5 个 P0 指标
- AC-009~AC-013

## Current Scope

1. **pkg/templatex/health.go** — HealthCheck 接口实现
2. **pkg/templatex/health_test.go** — 完整测试
3. **pkg/templatex/metrics.go** — NoopMetrics + 5 个 P0 指标
4. **pkg/templatex/metrics_test.go** — 完整测试
5. **contracts/health.schema.json** — 健康契约
6. **contracts/metrics.json** — 指标契约

## Out of Scope

- 不新增高基数 label
- 不引入 Prometheus、OpenTelemetry 或其他外部指标依赖
- 不修改 Client、Error 或生成脚本

## Allowed Files

- `pkg/templatex/health.go`
- `pkg/templatex/health_test.go`
- `pkg/templatex/metrics.go`
- `pkg/templatex/metrics_test.go`
- `contracts/health.schema.json`
- `contracts/metrics.json`

## Prohibited Actions

- 禁止引入外部指标依赖（Prometheus、OTel）
- 禁止新增高基数 label
- 禁止修改 errors.go / client.go / config.go

## Acceptance Criteria

- AC-009: HealthCheck nil context 返回 unhealthy
- AC-010: HealthCheck 健康客户端返回 healthy
- AC-011: NoopMetrics 不 panic
- AC-012: 指标名匹配 contract 5 个 P0 指标名一致
- AC-013: label 低基数只有 op/kind/status

## Validation Commands

```bash
GOWORK=off go test ./pkg/templatex/ -run TestHealth -v
GOWORK=off go test ./pkg/templatex/ -run TestMetrics -v
GOWORK=off go test -race ./pkg/templatex/
```

## Evidence Format

```markdown
- **Evidence ID**: EVID-TEST-TASK-XLIB-007-001
- **Task ID**: TASK-XLIB-007
- **Status**: PASS/FAIL
- **Validation Run**: <命令及输出>
- **Files Changed**: <文件列表>
- **AC Verified**: AC-009~AC-013
- **Timestamp**: <ISO-8601>
- **Verifier**: <agent/human>
```

## Test Case Reference

参见 `module/xlib-standard/TRACEABILITY.md` FR-003 / FR-004 对应 TC-009~TC-013。
