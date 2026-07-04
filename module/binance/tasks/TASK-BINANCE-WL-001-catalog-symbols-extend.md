# TASK-BINANCE-WL-001 catalog_symbols 扩展字段 migration + ApplyDiff 改造

## Metadata

```yaml
TASK-BINANCE-WL-001:
  module: binance
  scope: "catalog_symbols 表新增 5 字段，PgCatalog.ApplyDiff 扩展写入"
  spec_ref:
    - "module/binance/spec/SPEC.md#FR-050"
    - "module/binance/spec/SPEC.md#BR-009"
  files:
    - "migrations/011_whitelist.sql"
    - "internal/server/storage/pg_catalog.go"
    - "internal/server/storage/pg_catalog_test.go"
  acceptance_criteria:
    - "AC-001: migration 011_whitelist.sql 幂等执行，新增 exchange_status/last_seen_at/tier/collection/raw_extra 字段"
    - "AC-001: ApplyDiff 写入 exchange_status（TRADING/BREAK/HALT）和 last_seen_at（now()）"
    - "AC-001: ApplyDiff 从 CatalogEntryDTO 同步 tier 和 collection 字段"
    - "AC-001: 已有 catalog_symbols 数据迁移后新字段有默认值，不破坏现有查询"
  depends_on: []
  estimated_effort: "3h"
  priority: P0
  status: pending
```

## Objective

为白名单层提供候选表基础。`catalog_symbols` 需要承载 `exchange_status`（交易所原始状态）、`last_seen_at`（最近存在时间）、`tier` / `collection`（ADR-005 分级）、`raw_extra`（冗余字段），供 Whitelist Sync Job 读取判断。

## Scope

- 新增 `migrations/011_whitelist.sql`：ALTER TABLE 添加 5 字段（`catalog_symbols` 扩展部分，whitelist 表在 WL-002 创建）
- 改造 `pg_catalog.go` `PgCatalog.ApplyDiff`：从 `CatalogDiffMessage` 的 `CatalogEntryDTO` 提取 `tier` / `collection` 写入；`exchange_status` 从 entry status 映射；`last_seen_at` 设为 `now()`
- `pg_catalog_test.go` 新增测试覆盖字段写入

## Design Reference

- `module/binance/design/EXCHANGEINFO-WHITELIST-DESIGN.md` §5.2.1
- `module/binance/design/ADR-006-server-side-whitelist-rewrite.md`
- 现有：`migrations/001_catalog.sql`、`internal/server/catalogdiff/subscriber.go` `CatalogEntry` DTO

## Dependencies

- 无前置 task（基于现有 FR-006b `catalog_symbols` 表）
