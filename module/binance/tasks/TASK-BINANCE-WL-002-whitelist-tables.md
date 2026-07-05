# TASK-BINANCE-WL-002 whitelist 表 + version SSOT + sync_log migration

## Metadata

```yaml
TASK-BINANCE-WL-002:
  module: binance
  scope: "创建 whitelist / whitelist_meta / whitelist_sync_log 三表 + DDL"
  spec_ref:
    - "module/binance/spec/SPEC.md#FR-046"
    - "module/binance/spec/SPEC.md#BR-009"
  files:
    - "migrations/011_whitelist.sql"
    - "internal/server/storage/pg_whitelist.go"
    - "internal/server/storage/pg_whitelist_test.go"
  acceptance_criteria:
    - "AC-001: whitelist 表包含 market_type/symbol/base_asset/quote_asset/exchange_status/tier/enabled/source/last_change_version/effective_at/updated_at/remark"
    - "AC-001: whitelist_meta 单行表（id=1 CHECK 约束），current_version 初始为 0"
    - "AC-001: whitelist_sync_log 含 version/added/removed/updated/triggered_by/created_at + 索引"
    - "AC-001: PgWhitelist.UpsertEntries 在单事务内更新 whitelist + 递增 whitelist_meta.current_version + 写 sync_log"
  depends_on:
    - "TASK-BINANCE-WL-001"
  estimated_effort: "4h"
  priority: P0
  status: pending
```

## Objective

建立白名单持久化层。三张表分工：`whitelist`（当前快照）、`whitelist_meta`（全局 version SSOT，单行表）、`whitelist_sync_log`（审计日志）。

## Scope

- `migrations/011_whitelist.sql` 追加 whitelist / whitelist_meta / whitelist_sync_log DDL（与 WL-001 的 ALTER 同文件）
- 新增 `internal/server/storage/pg_whitelist.go`：`PgWhitelist` 结构 + `UpsertEntries(ctx, added, removed, updated)` 方法
  - 单事务：`pg_try_advisory_xact_lock` → `UPDATE whitelist_meta ... RETURNING current_version` → 批量 upsert whitelist → INSERT sync_log
  - 冲突处理：`ON CONFLICT (market_type, symbol) DO UPDATE SET enabled/source/last_change_version/...`
- `pg_whitelist_test.go`：测试事务原子性、version 递增、advisory lock 互斥

## Design Reference

- `module/binance/design/EXCHANGEINFO-WHITELIST-DESIGN.md` §5.2.2~5.2.4、§5.3.1
- `module/binance/design/ADR-006-server-side-whitelist-rewrite.md`

## Dependencies

- TASK-BINANCE-WL-001（catalog_symbols 扩展字段先行，whitelist 读取候选数据）
