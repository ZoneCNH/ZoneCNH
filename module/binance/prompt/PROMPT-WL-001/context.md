# PROMPT-WL-001 Context Packet

- Task: TASK-BINANCE-WL-001
- Target: `/home/workspace/binance`
- FR: FR-050
- ADR: ADR-006

## Context

`catalog_symbols` 表（`migrations/001_catalog.sql`）需扩展 5 字段供白名单层读取。`PgCatalog`（`internal/server/storage/pg_catalog.go`）需新增 `ApplyDiff` 方法实现 `catalogdiff.CatalogUpdater` 接口，将 `CatalogDiff.Added/Updated/Removed` 写入 DB 并填充新字段。

## Files to Create/Modify

| File | Action |
|------|--------|
| `migrations/011_whitelist.sql` | Create — ALTER TABLE catalog_symbols ADD COLUMN ×5 |
| `internal/server/storage/pg_catalog.go` | Modify — add `ApplyDiff` method + new upsert SQL |
| `internal/server/storage/pg_catalog_test.go` | Modify — add ApplyDiff tests |

## Key Interfaces

- `catalogdiff.CatalogUpdater` interface: `ApplyDiff(ctx, CatalogDiff) error` — in `internal/server/catalogdiff/subscriber.go:64`
- `catalogdiff.CatalogDiff` struct: `ProductLine, Generation, Added []CatalogEntry, Removed []string, Updated []CatalogEntry`
- `catalogdiff.CatalogEntry` has: `Tier`, `Collection`, `Status`, `BaseAsset`, `QuoteAsset` etc.

## Constraints

- `storage` package may import `catalogdiff` package (no cycle: catalogdiff does not import storage)
- New columns must be nullable / have defaults (don't break existing rows)
- `ApplyDiff` must be idempotent (ON CONFLICT DO UPDATE)
- Removed entries: UPDATE status='delisted' (soft delete, not physical delete)
- Test with fake PGExecer (existing pattern in pg_catalog_test.go)
