# TASK-BINANCE-SERVER-018 Catalog Tier Columns

> 版本：v1.0.0
> 关联：ADR-005（symbol 采集分级体系）；GAP-E24（采集治理）/ GAP-E25（水平扩展分片，可选）；TASK-BINANCE-SERVER-012（原 catalog 表）；配套 CLIENT-015（同 schema，client 写入这些字段）

## Objective

为 `binance_symbols` 表物化 ADR-005 数据字段层的 4 个分级字段（Tier / SymbolPriority / Collection / QuoteVolumeUSD），并预留 `shard_id` 列为 CLIENT-018 可选水平扩展分片做准备。补齐 GAP-E24 server 侧 + GAP-E25 schema 预留两层缺口——当前 schema（TASK-012）仅 symbol/product_line/active 三列，无法持久化分级与分片元数据。

## Scope

**scope_in**

```text
internal/server/storage/catalog/
  migrations/
    002_add_tier_columns.sql   ← ALTER TABLE 加 5 列（up/down 对称）
  catalog.go                   ← UpsertSymbol 扩展分级参数 + ListActiveSymbols 返回 tier
  catalog_test.go
```

**scope_out**

- client catalog 定义（CatalogEntry 结构体，归 CLIENT-015）
- 一致性哈希分片逻辑（CLIENT-018，本任务仅预留 `shard_id` 列、不实现填充）
- server 其他表（binance_clock_offsets / binance_ingest_status / OLAP / archive）

## Schema 扩展

在 TASK-012 既有 `binance_symbols` 表上 `ALTER TABLE ADD COLUMN`，类型对齐 ADR-005 §3：

```sql
-- migrations/002_add_tier_columns.sql （up）
ALTER TABLE binance_symbols ADD COLUMN IF NOT EXISTS tier              INT          NOT NULL DEFAULT 4;          -- 0=核心/1=主流/2=次主流/3=长尾/4=监控；默认 T4（未知 symbol 保守降级）
ALTER TABLE binance_symbols ADD COLUMN IF NOT EXISTS symbol_priority   INT          NOT NULL DEFAULT 0;          -- 同 Tier 内调度次序，0 最高
ALTER TABLE binance_symbols ADD COLUMN IF NOT EXISTS collection        VARCHAR(32)  NOT NULL DEFAULT 'disabled'; -- full_stream/stream_no_depth/kline_only/rest_sample/rest_daily/disabled
ALTER TABLE binance_symbols ADD COLUMN IF NOT EXISTS quote_volume_usd  DECIMAL(20,4);                            -- 流动性信号，分级判定依据；NULL=未知
ALTER TABLE binance_symbols ADD COLUMN IF NOT EXISTS shard_id          VARCHAR(64);                              -- 为 CLIENT-018 可选分片预留，默认 NULL，不强制分片
CREATE INDEX IF NOT EXISTS idx_binance_symbols_tier ON binance_symbols(tier);

-- down（幂等回滚）
DROP INDEX IF EXISTS idx_binance_symbols_tier;
ALTER TABLE binance_symbols DROP COLUMN IF EXISTS shard_id;
ALTER TABLE binance_symbols DROP COLUMN IF EXISTS quote_volume_usd;
ALTER TABLE binance_symbols DROP COLUMN IF EXISTS collection;
ALTER TABLE binance_symbols DROP COLUMN IF EXISTS symbol_priority;
ALTER TABLE binance_symbols DROP COLUMN IF EXISTS tier;
```

## 接口设计

```go
// internal/server/storage/catalog/catalog.go （扩展 TASK-012 的 CatalogStore）
type SymbolTierRow struct {
    Symbol        string
    ProductLine   string
    Tier          int
    Priority      int
    Collection    string
    QuoteVolumeUSD float64
    ShardID       *string // NULL → nil 指针
}

// UpsertSymbol 扩展签名（分级四字段；shard_id 由 CLIENT-018 分片器写入，本任务保持 NULL）
func (s *CatalogStore) UpsertSymbol(ctx context.Context, r SymbolTierRow) error
func (s *CatalogStore) ListSymbolsByTier(ctx context.Context, productLine string, minTier int) ([]SymbolTierRow, error)
```

## Functional Requirements

- **FR-018-001**：`binance_symbols` 含 5 新列，类型对齐 ADR-005：`tier INT` / `symbol_priority INT` / `collection VARCHAR(32)` / `quote_volume_usd DECIMAL(20,4)` / `shard_id VARCHAR(64) NULL`。
- **FR-018-002**：migration `002_add_tier_columns.sql` 可重复执行（`IF NOT EXISTS`），up/down 对称（down 完整删除 5 列 + 索引）。
- **FR-018-003**：`ListSymbolsByTier` 返回的每个 symbol 含 `tier` 字段，供 server 侧 gin-admin / market API 消费与 ADR-004 stream manager 按 `(productLine, tier)` 分组。
- **FR-018-004**：`shard_id` 列存在但默认 NULL——本任务不实现填充逻辑；仅当 CLIENT-018（GAP-E25 可选扩容，ADR-005 §6.2）启用一致性哈希分片时由分片器写入。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| AC-018-001 | migration 在干净库（仅跑过 001_init）执行成功，`\d binance_symbols` 含 5 新列；重复执行不报错 |
| AC-018-002 | catalog API（ListSymbolsByTier）返回的 symbol 行含非空 `tier` 字段，UpsertSymbol 写入的 tier 可读回 |
| AC-018-003 | `shard_id` 列存在但默认 NULL，UpsertSymbol 不传 shard_id 时读回 `*string == nil`，不强制分片 |
| AC-018-004 | migration down 执行后 5 列 + 索引全消失，恢复 TASK-012 三列原状 |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| `github.com/ZoneCNH/postgresx` | v1.0.0 | migration 执行 + 查询 |
| `github.com/ZoneCNH/domain_market` | v1.1.0 | ProductLine 枚举 |
| CLIENT-015（同 ADR-005 schema） | — | client 写入 tier/priority/collection/quote_volume，server 持久化；本任务提供落地点 |

## 关联缺口与说明

- **GAP-E24 server 侧**：4 个分级字段（tier/symbol_priority/collection/quote_volume_usd）物化，弥补"catalog 无 Tier 字段"的数据持久化层缺口。
- **GAP-E25 schema 预留**：`shard_id` 列仅占位，**不实现分片逻辑**。依据 ADR-005 §6.2 勘误，GAP-E25 是分级后单副本仍不够时的**可选扩容路径**，非 E24 下游依赖；预留列避免未来分片落地时再做 schema 迁移。
