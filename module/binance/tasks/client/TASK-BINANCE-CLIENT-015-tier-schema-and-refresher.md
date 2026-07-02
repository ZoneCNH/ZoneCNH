# TASK-BINANCE-CLIENT-015 Tier Schema & 4 线 Refresher

> 版本：v1.0.0
> 关联：ADR-005（数据字段层）；GAP-E6 / GAP-E24（RUNTIME-GAP-MATRIX）；EXCHANGEINFO 报告 §1.2/§1.3/§4.1/§4.2

## Objective

实现 ADR-005 的**数据模型层 + refresher 装配层**，为后续 CLIENT-017（classifyTier + 白名单路由）提供数据地基：

1. **4 线 ExchangeInfoRefresher 装配**（GAP-E6 [CRITICAL]）：UM/CM/Options 启动时与 spot 并行拉取，catalog 不再只有 1 条种子 symbol
2. **CatalogEntry 加 4 个分级字段**（ADR-005 §3）：`Tier` / `SymbolPriority` / `Collection` / `QuoteVolumeUSD`
3. **decode 保留 quoteVolume 流动性信号**：修复 spot/um/cm 在入口丢弃 `quoteVolume` 的根因（ADR-005 §4 前置）
4. **options decode 加 status 字段 + TRADING 过滤**（ADR-005 §6.1 前置）：分级落地前必须修，否则 options 分桶会塞满无效合约

## 分布式约束

- 本任务只改 **client 侧**的 catalog/refresher/decode，不碰 server schema（SERVER-018 专责）
- `CatalogEntry` 是 binance 仓内部类型，不跨 ADR-002 wire 边界，新增 4 字段零值对旧 catalog 反序列化向后兼容
- 不引入 classifyTier 算法（那是 CLIENT-017）、不引入 per-tier 配置（CLIENT-017）、不动决策谓词（CLIENT-017）

## Scope

```text
scope_in:
  internal/client/runtime.go:199-217          ← 4 线 refresher 循环装配，去掉 ProductLineSpot 硬编码
  internal/client/catalog.go:16-46            ← CatalogEntry 加 Tier/SymbolPriority/Collection/QuoteVolumeUSD
  internal/client/exchangeinfo.go:19-24       ← spotExchangeSymbol decode 加 QuoteVolume/Permissions 字段
  internal/client/exchangeinfo.go             ← um/cm decode 同理加 QuoteVolume
  internal/client/exchangeinfo_option.go:30-36,74-84  ← optionsExchangeSymbol 加 status 字段 + TRADING 过滤

scope_out:
  internal/client/lifecycle.go / history_lifecycle.go / stream_control.go  ← 决策谓词（CLIENT-017）
  pkg/binancecfg/config.go                                                    ← per-tier 配置矩阵（CLIENT-017）
  internal/server/                                                            ← binance_symbols 表加列（SERVER-018）
```

## 接口设计

### CatalogEntry 扩展（ADR-005 §3）

```go
// internal/client/catalog.go
type CatalogEntry struct {
    // ... 原 12 字段（ProductLine ~ OptionType）保持不变
    Status string

    // ADR-005 新增——symbol 级分级四字段
    Tier           int     // 0=核心 / 1=主流 / 2=次主流 / 3=长尾 / 4=监控
    SymbolPriority int     // 同 Tier 内调度优先级（0=最高）；与任务级 LifecycleTask.Priority 区分
    Collection     string  // full_stream/stream_no_depth/kline_only/rest_sample/rest_daily/disabled
    QuoteVolumeUSD float64 // decode 保留的流动性信号（分级判定依据，ADR-005 §4）
}
```

### 4 线 refresher 装配（runtime.go:199-217）

```go
// 原：硬编码 ProductLineSpot 单线 refresher
// 改：循环装配 4 产品线，每线独立 ExchangeInfoRefresher
productLines := []string{"spot", "um", "cm", "options"}
for _, pl := range productLines {
    refresher := NewExchangeInfoRefresher(pl, client, catalog)
    go refresher.Run(ctx)  // 各线独立 goroutine，启动时拉取 + 周期刷新
}
```

## Functional Requirements

**FR-015-001**: WHEN client 启动 THEN 4 个产品线（spot/um/cm/options）各自的 ExchangeInfoRefresher 全部装配并启动，catalog 不再仅含 1 条 spot 种子 symbol（GAP-E6）。

**FR-015-002**: CatalogEntry 必须新增 4 字段（`Tier int` / `SymbolPriority int` / `Collection string` / `QuoteVolumeUSD float64`），字段名与 ADR-005 §3 严格一致。

**FR-015-003**: WHEN decode spot/um/cm ExchangeInfo THEN 必须保留 Binance 原始 JSON 中的 `quoteVolume` 字段，填充到 `CatalogEntry.QuoteVolumeUSD`，不得在 decode 入口丢弃（ADR-005 §4 关键依赖）。

**FR-015-004**: WHEN decode options ExchangeInfo THEN 必须新增 `status` 字段读取，且仅 `status == "TRADING"` 的合约进入 catalog（不再仅按 `expiryDate > now` 判 active，ADR-005 §6.1 前置）。

**FR-015-005**: WHEN 新建 CatalogEntry 未填充分级字段 THEN 默认值为：`Tier=3`（长尾兜底，未分级时按最低采集策略处理）/ `SymbolPriority=0` / `Collection=""` / `QuoteVolumeUSD` 由 decode 填充。

**FR-015-006**: 新增 4 字段必须对旧 catalog 反序列化向后兼容——零值不阻断 DiffSync 序列化/反序列化（ADR-005 §8.1）。

## Acceptance Criteria

> 映射关系：本 task AC → ACCEPTANCE.md §2.1 运行时口径 AC-TIER-*。

| AC | 验证方式 | 映射 AC-TIER |
|----|---------|--------------|
| AC-015-001：4 线 refresher 启动后 catalog 含全量 symbol | client 启动 mock，验证 catalog 含 spot/um/cm/options 各自的 symbol 全集，非仅 1 条种子（覆盖 GAP-E6） | AC-TIER-001 |
| AC-015-002：decode 后 entry.QuoteVolumeUSD 非零 | 单测：mock spot ExchangeInfo JSON 含 `quoteVolume`，验证 decode 后 `entry.QuoteVolumeUSD > 0`，spot BTCUSDT 有值 | AC-TIER-002 |
| AC-015-003：options decode 过滤掉非 TRADING 合约 | 单测：mock options JSON 含 `status=SETTLED` 与 `status=TRADING` 两种合约且 `expiryDate > now`，验证仅 TRADING 合约进入 catalog | AC-TIER-002 |
| AC-015-004：CatalogEntry 字段名与 ADR-005 一致 | `grep -P 'Tier\s+int\|SymbolPriority\s+int\|Collection\s+string\|QuoteVolumeUSD\s+float64' catalog.go` 命中 4 行 | AC-TIER-002 |
| AC-015-005：旧 catalog 反序列化兼容 | 单测：用不含 4 字段的旧 JSON 反序列化，验证 Tier=0 / SymbolPriority=0 / Collection="" / QuoteVolumeUSD=0，不报错 | AC-TIER-002 |

## Dependencies

| 依赖 | 版本 | 用途 |
|------|------|------|
| `encoding/json` | stdlib | decode 扩展字段 |
| ADR-005 | Proposed | 4 字段定义 + §4 decode 依赖 + §6.1 options 前置 |

- **前置任务**：无（独立可上，ROI 最高 0.5d，与 GAP-E6 估算一致）
- **被依赖**：CLIENT-017（classifyTier + STREAM_SYMBOLS 白名单路由）依赖本任务的 4 字段 + QuoteVolumeUSD 信号

## Non-scope

- 不实现 classifyTier 三层降级算法（ADR-005 §4 伪代码 → CLIENT-017）
- 不实现 STREAM_SYMBOLS 白名单与 Collection 路由谓词（CLIENT-017）
- 不改 binancecfg per-tier 配置矩阵（CLIENT-017）
- 不改 server binance_symbols 表（SERVER-018）
- 不改 lifecycle/history/stream_control 决策谓词（CLIENT-017）
