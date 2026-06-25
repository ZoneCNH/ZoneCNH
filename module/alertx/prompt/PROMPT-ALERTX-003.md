# TASK-ALERTX-003 开发 Prompt

> 去重抑制：DedupKey 指纹 + SuppressWindow 时间窗口

- 上游 Task：[TASK-ALERTX-003.md](../tasks/TASK-ALERTX-003.md) | Spec：[SPEC.md#FR-002](../SPEC.md)

## 任务

实现 Deduper 接口：同 DedupKey 在 SuppressWindow 内抑制，空 DedupKey 派生。

## 关联需求

| 类型 | 编号 | AC | TC |
| --- | --- | --- | --- |
| FR | FR-002 | AC-002 | TC-004 |
| BR | BR-003 | AC-010 | TC-004 |

## 依赖

- 上游：TASK-002（AlertEvent 产出后的去重环节）
- contracts：`contracts.AlertEvent.DedupKey` / `SuppressWindow`

## 实现要点

1. `pkg/alertx/dedup.go`：Deduper 实现
   - 维护 `map[string]time.Time`（DedupKey → 上次触发时间）+ `sync.Mutex`
   - `Check(ctx, event)`：若 DedupKey 在 SuppressWindow 内 → 返回 Status=suppressed 副本；否则 → firing，更新时间
   - 空 DedupKey 派生：`fmt.Sprintf("%s:%s", event.Source, subjectFromContext(event))`
2. 并发安全：多 goroutine 同 DedupKey 仅一个 firing（TC-010, -race）
3. trace_id 缺失（EC-009）：DedupKey 派生忽略 trace_id（TC-016）

## 验证

```bash
cd /home/alertx && GOWORK=off go test ./pkg/alertx/... -run TestDeduper -race -v
```

## 关键测试

- `TestDeduper_SuppressWindow`：窗口内重复→suppressed；窗口外→firing
- `TestDeduper_ConcurrentSameKey`：-race，100 goroutine 同 key，仅 1 个 firing
- `TestDeduper_MissingTraceID`：trace_id 空 → DedupKey 仍正确派生
- `TestDeduper_EmptyDedupKey`：空 key → 按 (Source, subject) 派生
