# TASK-BINANCE-SERVER-017 clickhousex OLAP Storage

> 版本：v2.1.0

## Objective

利用 clickhousex 承载 Binance-specific OLAP 聚合数据，为 `/api/v1/analytics/*` 查询提供跨符号、多窗口、多维分析能力。taosx 继续负责高频时序写入；clickhousex 负责从 taosx 派生后的分析型表。

## Scope

```text
internal/server/storage/analytics/
  clickhouse.go       <- clickhousex 写入/查询适配
  etl.go              <- taosx -> clickhousex 定时聚合任务
  clickhouse_test.go
  etl_test.go
```

## 数据模型

```sql
CREATE TABLE IF NOT EXISTS binance_ohlcv_1m (
    ts           DateTime64(3),
    product_line LowCardinality(String),
    symbol       LowCardinality(String),
    open         Float64,
    high         Float64,
    low          Float64,
    close        Float64,
    volume       Float64,
    trade_count  UInt64
) ENGINE = MergeTree
PARTITION BY toYYYYMMDD(ts)
ORDER BY (product_line, symbol, ts);

CREATE TABLE IF NOT EXISTS binance_vwap_5m (
    ts           DateTime64(3),
    product_line LowCardinality(String),
    symbol       LowCardinality(String),
    vwap         Float64,
    volume       Float64
) ENGINE = MergeTree
PARTITION BY toYYYYMMDD(ts)
ORDER BY (product_line, symbol, ts);
```

## 接口设计

```go
// internal/server/storage/analytics/clickhouse.go
package analytics

type Store struct {
    db clickhousex.Client
}

func (s *Store) EnsureSchema(ctx context.Context) error
func (s *Store) InsertOHLCV(ctx context.Context, rows []OHLCVRow) error
func (s *Store) QueryVWAP(ctx context.Context, q VWAPQuery) ([]VWAPResult, error)
func (s *Store) QueryTopMovers(ctx context.Context, q MoversQuery) ([]MoverResult, error)
func (s *Store) QueryCorrelation(ctx context.Context, q CorrelationQuery) (CorrelationResult, error)
```

## Functional Requirements

**FR-CH-001**: 启动时执行 clickhousex DDL，确保分析表存在且 schema 与 SPEC §11.2.5 对齐。

**FR-CH-002**: ETL 每 5 分钟从 taosx 查询已闭合窗口，聚合写入 `binance_ohlcv_1m`、`binance_vwap_5m`、`binance_stats_15m`。

**FR-CH-003**: 写入使用 `clickhousex.InsertBatch`，批大小默认 50000 行，可配置。

**FR-CH-004**: clickhousex 不可达时 ETL 记录 error 并跳过本批次；实时 market API 不受影响。

**FR-CH-005**: analytics API 查询失败时返回 HTTP 503 和 `BNC-013`，不得降级为 taosx 全表扫描。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| DDL 自动建表 | mock clickhousex.Exec 验证启动时调用 |
| ETL 聚合写入 | mock taosx.Query + clickhousex.InsertBatch 验证数据流 |
| 批量写入参数 | 验证默认 batch size = 50000，支持配置覆盖 |
| 不可达隔离 | mock clickhousex error，验证 analytics 503 且 realtime API 不受影响 |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| `github.com/ZoneCNH/clickhousex` | v1.0.0 | OLAP 写入与查询 |
| `github.com/ZoneCNH/taosx` | v1.0.0 | 热时序数据读取 |
| `github.com/ZoneCNH/observex` | v1.0.0 | ETL 指标、日志、告警 |

## Non-scope

- 不替代 taosx 热路径写入。
- 不持有跨交易所 canonical market 语义。
- 不向 `factor_engine`、`strategy_engine`、`risk_engine` 写入业务决策状态。
