# TASK-BINANCE-SERVER-016 ossx Archiver

> 版本：v2.0.0

## Objective

利用 ossx（对象存储）将 taosx 中超过保留期（默认 90 天）的历史行情数据归档到冷存储，降低 TDengine 存储压力，同时保留完整数据供离线分析。

## Scope

```text
internal/server/storage/archiver/
  archiver.go        ← Archiver 主实现（定时任务）
  archiver_test.go
```

## 存储路径规范

```
binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet

示例：
binance/spot/BTCUSDT/2024/01/01/tick.parquet
binance/futures_usdt/ETHUSDT/2024/01/01/depth.parquet
binance/spot/BTCUSDT/2024/01/01/kline_1m.parquet
```

## 接口设计

```go
// internal/server/storage/archiver/archiver.go
package archiver

type Archiver struct {
    oss    ossx.Client
    ts     timeseries.Store   // taosx — 读取 + 删除
    cfg    ArchiverConfig
}

type ArchiverConfig struct {
    RetentionDays int           // 默认 90
    BucketName    string        // "binance-market-archive"
    Interval      time.Duration // 默认 24h（每日凌晨运行）
}

// Run 启动定时归档任务，阻塞直到 ctx 取消。
func (a *Archiver) Run(ctx context.Context) error {
    ticker := time.NewTicker(a.cfg.Interval)
    defer ticker.Stop()
    for {
        select {
        case <-ticker.C:
            if err := a.archiveExpired(ctx); err != nil {
                // 仅告警，不中断（下次定时补跑）
                observex.ErrorContext(ctx, "archiver: archiveExpired", "err", err)
            }
        case <-ctx.Done():
            return ctx.Err()
        }
    }
}

// archiveExpired 查询 cutoff（now - RetentionDays）之前的数据，
// 按日期 + symbol 分组，序列化为 Parquet，上传到 ossx，成功后从 taosx 删除。
func (a *Archiver) archiveExpired(ctx context.Context) error {
    cutoff := time.Now().AddDate(0, 0, -a.cfg.RetentionDays)
    // 1. 从 taosx 分组查询过期数据
    // 2. 序列化为 Parquet（arrow/parquet-go）
    // 3. ossx.PutObject(ctx, bucket, key, reader)
    // 4. 确认上传成功后，taosx 删除对应时间段数据
    return nil  // 详细实现见 archiver.go
}
```

## Functional Requirements

**FR-ARC-001**: 每日定时（可配置，默认 00:00 UTC）查询 taosx 中超过 RetentionDays 的数据。

**FR-ARC-002**: 按 `{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` 路径上传到 ossx。

**FR-ARC-003**: 上传完成并验证 ETag 后，才从 taosx 删除对应时间段数据（先写冷，再删热）。

**FR-ARC-004**: ossx 上传失败时仅记录告警，不删除 taosx 数据，下次定时补跑。

**FR-ARC-005**: 支持按 product_line 和 symbol 过滤，允许只归档部分数据（用于存储优化）。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| 先上传后删除顺序 | mock 验证 PutObject 在 taosx.Delete 之前调用 |
| 上传失败不删除 taosx | mock PutObject 返回 error，验证 Delete 未被调用 |
| 路径格式正确 | 验证 key = `binance/spot/BTCUSDT/2024/01/01/tick.parquet` |
| RetentionDays 边界 | cutoff = now - 90d，验证 taosx 查询参数 |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| `github.com/ZoneCNH/ossx` | v1.0.0 | 对象存储上传/验证 |
| `github.com/ZoneCNH/taosx` | v1.0.0 | 历史数据查询 + 删除 |
| `github.com/ZoneCNH/observex` | v1.0.0 | 归档进度日志/告警 |
| `github.com/apache/arrow/go` | v14 | Parquet 序列化 |

## Non-scope

- 不做从 ossx 恢复（离线分析工具负责）
- 不做增量压缩（Parquet 直接存储原始列数据）
- 不做跨账号复制（单 bucket 双副本由 ossx 基础设施负责）
