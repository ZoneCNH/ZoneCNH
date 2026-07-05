# TASK-BINANCE-WL-003 Whitelist Sync Job（事件驱动 + 定时兜底 + 准入规则）

## Metadata

```yaml
TASK-BINANCE-WL-003:
  module: binance
  scope: "Whitelist Sync Job：读 catalog_symbols → 准入规则 → 写 whitelist + NATS 推送"
  spec_ref:
    - "module/binance/spec/SPEC.md#FR-045"
    - "module/binance/spec/SPEC.md#BR-009"
  files:
    - "internal/server/whitelist/sync_job.go"
    - "internal/server/whitelist/sync_job_test.go"
    - "internal/server/whitelist/rules.go"
    - "internal/server/whitelist/rules_test.go"
  acceptance_criteria:
    - "AC-001: SyncJob.Run 读取 catalog_symbols 与 whitelist 做 diff，按准入规则判断新增/移除"
    - "AC-001: 自动放行规则：exchange_status=TRADING + quote_asset∈主流白名单 + Tier∈{core,standard} + 非 options"
    - "AC-001: 强制审核规则：options 全部 + Tier∈{long_tail,monitor} + 冷门 quote_asset → 不自动 enabled"
    - "AC-001: 下架规则：状态变更→直接 enabled=false；列表消失→连续 N 次未出现才下架"
    - "AC-001: 观察期：新 symbol 命中自动放行后先入观察状态（3天），期满 enabled=true"
    - "AC-001: 事件驱动：catalogdiff.ApplyDiff 成功后触发 SyncJob.Run"
    - "AC-001: 定时兜底：每 30 分钟独立触发 SyncJob.Run"
    - "AC-001: advisory lock 互斥：并发触发时第二个直接 skip"
  depends_on:
    - "TASK-BINANCE-WL-002"
  estimated_effort: "6h"
  priority: P1
  status: pending
```

## Objective

实现白名单同步核心逻辑：从候选表读取 → 规则引擎判断 → 写入白名单表 + version 递增。事件驱动 + 定时兜底双触发，PG advisory lock 保证单写者。

## Scope

- `internal/server/whitelist/rules.go`：准入规则引擎
  - `AutoAdmit(entry CatalogEntry) bool`：自动放行判断
  - `NeedsReview(entry CatalogEntry) bool`：强制审核判断
  - `ShouldDelist(entry, missCount int) bool`：下架判断（区分状态变更 vs 列表消失）
  - 观察期逻辑：新 symbol `effective_at` 延后 3 天
- `internal/server/whitelist/sync_job.go`：`SyncJob` 结构
  - `Run(ctx)` 方法：读 catalog_symbols → diff whitelist → 规则判断 → `PgWhitelist.UpsertEntries` → NATS publish
  - 事件驱动 hook：从 `catalogdiff.Subscriber.ApplyDiff` 成功后调用
  - 定时兜底：`time.Ticker` 30min
  - `pg_try_advisory_xact_lock` 互斥（复用 WL-002 的 PgWhitelist 事务内锁）
- `sync_job_test.go` + `rules_test.go`：覆盖各准入/下架/观察期路径

## Design Reference

- `module/binance/design/EXCHANGEINFO-WHITELIST-DESIGN.md` §5.3、§5.4
- `module/binance/design/ADR-005-symbol-tier-classification.md`（Tier 分级依据）

## Dependencies

- TASK-BINANCE-WL-002（whitelist 表 + version SSOT + advisory lock 基础）
