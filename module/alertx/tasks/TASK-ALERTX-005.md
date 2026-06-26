# TASK-ALERTX-005

> 通知路由：Notifier 接口 + webhook 实现

---

```yaml
task_id: TASK-ALERTX-005
module: alertx
scope: "实现 Notifier 接口（vendor-neutral）+ webhook channel 实现 + 指数退避重试 + 通知幂等 + channel 配置校验"
spec_ref:
  - "module/alertx/SPEC.md#FR-004"
  - "module/alertx/SPEC.md#BR-002"
  - "module/alertx/SPEC.md#BR-005"
files:
  - "pkg/alertx/notifier.go"
  - "internal/channel/webhook.go"
  - "internal/channel/webhook_test.go"
acceptance_criteria:
  - "AC-004: 通知按 severity 路由；失败指数退避重试 3 次（1s/2s/4s）；通知幂等（同 event.ID 不重复发送）"
  - "AC-012: 未定义 channel 启动时返回 ErrChannelUnknown 阻塞"
  - "TestNotifier_RetryAndIdempotent 通过"
  - "TestNotifier_ChannelFailure 通过（持续失败不阻塞评估循环）"
  - "webhook payload 不含 secret"
depends_on:
  - "TASK-ALERTX-004"
estimated_effort: "3h"
priority: P0
status: pending
```

## Non-scope

- 不实现 email/pagerduty 渠道（TASK-008）
- 不实现健康导出/进程入口（TASK-007）
