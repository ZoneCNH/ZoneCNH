# TASK-ALERTX-005 开发 Prompt

> 通知路由：Notifier 接口 + webhook 渠道 + 重试幂等

- 上游 Task：[TASK-ALERTX-005.md](../tasks/TASK-ALERTX-005.md) | Spec：[SPEC.md#FR-004](../SPEC.md)

## 任务

实现 vendor-neutral Notifier 接口、webhook channel、指数退避重试、通知幂等、channel 配置校验。

## 关联需求

| 类型 | 编号 | AC | TC |
| --- | --- | --- | --- |
| FR | FR-004 | AC-004 | TC-006, TC-011 |
| BR | BR-002 | AC-009 | TC-020 |
| BR | BR-005 | AC-012 | TC-006 |

## 依赖

- 上游：TASK-004（分级路由后的 AlertEvent 发送通知）
- resiliencx：退避重试（基座）

## 实现要点

1. `pkg/alertx/notifier.go`：Notifier 接口 + 路由实现
   - 按 event.Severity 路由到对应渠道
   - 幂等表 `map[string]struct{}`（DedupKey+event.ID），重复发送跳过（BR-002）
   - 未定义 channel ID → 启动时 ErrChannelUnknown（BR-005/AC-012）
2. `internal/channel/webhook.go`：webhook 渠道
   - POST JSON payload（不含 secret）到配置 URL
   - 失败：指数退避 1s/2s/4s（resiliencx），最多 3 次，全失败 → ErrNotifyFailed + notify_failed counter
   - 渠道持续失败不阻塞评估循环（EC-004/TC-011）

## 验证

```bash
cd /home/alertx && GOWORK=off go test ./internal/channel/... -run TestWebhook -v
GOWORK=off go test ./pkg/alertx/... -run TestNotifier -v
```

## 关键测试（用 httptest.Server mock，不依赖外部）

- `TestNotifier_RetryAndIdempotent`：500 错误 → 退避重试 3 次；同 event.ID 二次发送跳过
- `TestNotifier_ChannelFailure`：持续失败 → ErrNotifyFailed，不 panic，不阻塞
- `TestNotifier_UnknownChannel`：未定义 channel → 启动阻塞
- `TestWebhook_PayloadNoSecret`：payload 不含 webhook url/routing key
