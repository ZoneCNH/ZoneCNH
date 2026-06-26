# TASK-ALERTX-004 开发 Prompt

> 分级路由 + 生命周期状态机 + 内存 AlertStore

- 上游 Task：[TASK-ALERTX-004.md](../tasks/TASK-ALERTX-004.md) | Spec：[SPEC.md#FR-003](../SPEC.md) [#FR-005](../SPEC.md)

## 任务

实现 severity 分级路由逻辑、firing/pending/resolved/suppressed 状态机、内存 AlertStore。

## 关联需求

| 类型 | 编号 | AC | TC |
| --- | --- | --- | --- |
| FR | FR-003 | AC-003 | TC-005 |
| FR | FR-005 | AC-005 | TC-007 |
| BR | BR-006 | AC-013 | TC-005 |

## 依赖

- 上游：TASK-003（去重后的 AlertEvent 进入分级+生命周期）
- contracts：`contracts.Severity` / `contracts.AlertStatus`

## 实现要点

1. `pkg/alertx/severity.go`：分级路由
   - critical → paging-capable 渠道（pagerduty/webhook）
   - warning → 通知渠道（email/webhook），不 paging
   - info → 仅日志，不通知
   - critical 必须尝试 paging，不因渠道失败降级（BR-006/AC-013）
2. `pkg/alertx/lifecycle.go`：状态机
   - firing → suppressed（抑制）/ resolved（恢复条件满足）
   - pending 窗口：抖动（flap）场景延迟 firing
   - ResolvedAt 记录（`*time.Time`）
3. `internal/store/memory_store.go`：AlertStore 内存实现
   - `map[string]contracts.AlertEvent`（DedupKey 索引）+ `sync.RWMutex`
   - Active/Upsert/Resolve
   - 内存上限：达上限拒绝新告警 + dropped counter（EC-006/TC-013）

## 验证

```bash
cd /home/alertx && GOWORK=off go test ./... -run 'TestSeverity|TestLifecycle|TestAlertStore' -race -v
```

## 关键测试

- `TestSeverityRouting_CriticalPages`：critical→paging；warning→通知不 paging；info→仅日志
- `TestLifecycle_FiringToResolved`：firing→resolved 流转，ResolvedAt 记录
- `TestLifecycle_FlapPending`：抖动场景 pending 窗口生效
- `TestAlertStore_MemoryExhaustion`：达上限拒绝 + dropped counter
