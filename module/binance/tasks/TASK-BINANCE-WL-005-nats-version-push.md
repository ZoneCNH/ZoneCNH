# TASK-BINANCE-WL-005 NATS whitelist.version 推送

## Metadata

```yaml
TASK-BINANCE-WL-005:
  module: binance
  scope: "SyncJob 提交后通过 NATS binance.whitelist.version 发布 version 变更通知"
  spec_ref:
    - "module/binance/spec/SPEC.md#FR-048"
    - "module/binance/spec/SPEC.md#BR-009"
  files:
    - "internal/server/whitelist/publisher.go"
    - "internal/server/whitelist/publisher_test.go"
    - "internal/server/whitelist/sync_job.go"
  acceptance_criteria:
    - "AC-001: SyncJob.Run 成功后发布 NATS subject binance.whitelist.version"
    - "AC-001: payload 为 JSON {version, changed_at}，version 与 whitelist_meta.current_version 一致"
    - "AC-001: 使用 core NATS pub/sub（fire-and-forget），不使用 JetStream"
    - "AC-001: 发布失败仅告警（slog.Warn），不影响 SyncJob 事务已提交的白名单变更"
    - "AC-001: 复用现有 NATS 连接（nats.Conn），不新建连接"
  depends_on:
    - "TASK-BINANCE-WL-003"
  estimated_effort: "2h"
  priority: P1
  status: pending
```

## Objective

白名单 version 变更后主动通知下游消费方，使其近实时刷新而非等待 3h TTL。复用 binance 现有 NATS 连接，与 `binance.catalog.diff` 一致使用 core NATS fire-and-forget。

## Scope

- `internal/server/whitelist/publisher.go`：`VersionPublisher`
  - `Publish(ctx, version int64) error`：`nc.Publish("binance.whitelist.version", payload)`
  - payload 结构：`{version int64, changed_at time.Time}`
- `sync_job.go` 修改：`Run` 成功后调用 `VersionPublisher.Publish`
  - 发布失败 `slog.Warn` 记录，不 panic、不回滚
- `publisher_test.go`：使用 NATS test server 验证发布

## Design Reference

- `module/binance/design/EXCHANGEINFO-WHITELIST-DESIGN.md` §5.6
- 现有：`internal/client/catalog_publisher.go`（`binance.catalog.diff` 发布模式参考）

## Dependencies

- TASK-BINANCE-WL-003（SyncJob.Run 成功后触发发布）
