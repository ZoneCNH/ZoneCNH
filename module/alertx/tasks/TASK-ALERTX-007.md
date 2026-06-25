# TASK-ALERTX-007

> 健康导出 + 自观测指标 + 进程入口

---

```yaml
task_id: TASK-ALERTX-007
module: alertx
scope: "实现 health.JSON（对齐 observex schema）+ 自观测指标 foundationx_alertx_* + cmd/alertx/main.go 独立进程入口（signal handling + graceful shutdown）+ Dockerfile"
spec_ref:
  - "module/alertx/SPEC.md#FR-006"
  - "module/alertx/SPEC.md#BR-007"
  - "module/alertx/SPEC.md#13"
  - "module/alertx/SPEC.md#17"
files:
  - "pkg/alertx/health.go"
  - "pkg/alertx/labels.go"
  - "cmd/alertx/main.go"
  - "Dockerfile"
acceptance_criteria:
  - "AC-006: health.JSON 输出 ready/live/message/components 四字段；渠道不可达 component live=false 不 panic"
  - "AC-014: 指标命名符合 foundationx_alertx_<measure>（alerts_fired/dedup_suppressed/notify_failed/rules_loaded/evaluations/alerts_dropped/reload_failed）"
  - "AC-015: SIGTERM 触发优雅关闭（flush 通知，关闭 AlertStore，干净退出）"
  - "TestHealth_JSONSchema 通过"
  - "TestMain_GracefulShutdown 通过（集成测试）"
  - "cmd/alertx 可编译为独立二进制"
  - "Dockerfile 多阶段构建，产出最小镜像"
depends_on:
  - "TASK-ALERTX-005"
  - "TASK-ALERTX-006"
estimated_effort: "3h"
priority: P0
status: pending
```

## Non-scope

- 不实现额外通知渠道（email/pagerduty 在 TASK-008）
- 不实现 AT-007 集成测试（TASK-008）
