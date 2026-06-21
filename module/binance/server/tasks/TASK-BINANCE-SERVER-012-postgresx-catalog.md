# TASK-BINANCE-SERVER-012 postgresx Catalog

> 版本：v2.0.0

## Objective

利用 postgresx 维护 Binance 模块专属的**元数据目录**：exchange_time 与 server_time 校准记录、产品线 symbol 注册表、采集状态追踪表。服务于数据补全（gap fill）和 symbol 管理。

## Scope

```text
internal/server/storage/catalog/
  catalog.go         ← CatalogStore 主实现
  catalog_test.go
  migrations/
    001_init.sql     ← 建表 DDL
```

## Schema

```sql
-- symbol 注册表
CREATE TABLE IF NOT EXISTS binance_symbols (
    id          BIGSERIAL PRIMARY KEY,
    symbol      TEXT        NOT NULL,
    product_line TEXT       NOT NULL,  -- 'spot' / 'futures_usdt' / 'futures_coin'
    active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(symbol, product_line)
);

-- 时钟偏移校准记录（用于 exchange_time 修正）
CREATE TABLE IF NOT EXISTS binance_clock_offsets (
    id              BIGSERIAL PRIMARY KEY,
    measured_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    offset_ms       BIGINT      NOT NULL,  -- exchange_time - server_time (ms)
    product_line    TEXT        NOT NULL
);

-- 采集进度追踪（用于 gap fill）
CREATE TABLE IF NOT EXISTS binance_ingest_status (
    symbol          TEXT        NOT NULL,
    product_line    TEXT        NOT NULL,
    last_event_type TEXT        NOT NULL,
    last_seq        BIGINT      NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY(symbol, product_line, last_event_type)
);
```

## 接口设计

```go
// internal/server/storage/catalog/catalog.go
package catalog

type CatalogStore struct {
    db postgresx.DB
}

func (s *CatalogStore) UpsertSymbol(ctx context.Context, symbol, productLine string) error
func (s *CatalogStore) RecordClockOffset(ctx context.Context, productLine string, offsetMs int64) error
func (s *CatalogStore) UpdateIngestStatus(ctx context.Context, env *domainmarket.MarketFactEnvelope, seq int64) error
func (s *CatalogStore) ListActiveSymbols(ctx context.Context, productLine string) ([]string, error)
```

## Functional Requirements

**FR-CAT-001**: `UpsertSymbol` ON CONFLICT DO UPDATE SET active=TRUE，symbol 注册幂等。

**FR-CAT-002**: `RecordClockOffset` 每分钟采样一次（由 server 启动时的后台 goroutine 调用）。

**FR-CAT-003**: `UpdateIngestStatus` 更新 last_seq，用于 gap fill 检测序列号跳跃。

**FR-CAT-004**: 所有写入操作通过 postgresx 事务执行，失败时回滚，不写部分数据。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| UpsertSymbol 幂等 | 同 symbol 插入两次不报错 |
| ClockOffset 记录存储 | mock DB 验证 INSERT 被调用 |
| UpdateIngestStatus seq 更新 | mock DB 验证参数包含 seq |
| 事务回滚 | mock DB 注入 rollback，验证不会半写 |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| `github.com/ZoneCNH/postgresx` | v1.0.0 | PostgreSQL 事务 + 查询 |
| `github.com/ZoneCNH/domain_market` | v1.1.0 | MarketFactEnvelope |
