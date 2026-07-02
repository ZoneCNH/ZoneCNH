# TASK-BINANCE-CLIENT-016 Interval SSOT

> 版本：v1.0.0
> 关联缺口：GAP-E26 [HIGH]（RUNTIME-GAP-MATRIX.md L61）
> 关联 ADR：ADR-005（per-tier interval 配置）、TIER-DESIGN-DETAILS §1（interval 列对齐 Binance REST 15 个标准 interval）

## Objective

建立 binance client 侧 interval 单一权威源（SSOT），消除"interval 列表碎片化 + REST/mapper 静默降级 `1m`"的治理黑洞，让 ADR-005 的 per-tier interval 配置（TIER-DESIGN-DETAILS §1）有权威引用基础。把 WebSocket RequiredBarIntervals 覆盖率从 6/15=40% 提到 15/15=100%。

## 缺口证据（GAP-E26）

| 层 | 现状 | 源码证据 | 覆盖率 |
|------|------|----------|:------:|
| WebSocket | RequiredBarIntervals 仅硬编码 6 个 | `product_line.go:26` | 6/15=40% |
| REST backfill | fallback `return "1m"` + 硬编码 `"i":"1m"` | `history_rest.go:181-188,284` | 1/15=6.7% |
| mapper | `coalesce(ev.Bar.Interval, "1m")` 静默降级 | `mapper.go:166` | — |
| TDengine | `Kline.Interval` 接受任意 string，无白名单 | `taos_writer.go:295` | — |
| 完全缺失 | 9 个 interval 未建模 | 3m/30m/2h/6h/8h/12h/3d/1w/1M | — |

## Scope

```text
internal/client/
  interval.go            ← 新建 SSOT（常量 + 白名单 + IsValidInterval）
  product_line.go:26     ← RequiredBarIntervals 改引用 SSOT，补齐 15 个
  history_rest.go:181-188,284 ← 删除 `return "1m"` fallback 与硬编码 `"i":"1m"`，缺字段直接 error
  mapper.go:166          ← 删除 coalesce(…,"1m")，缺 interval 直接 reject
  taos_writer.go:295     ← 写入前校验 interval ∈ 白名单
```

## 接口设计

```go
// internal/client/interval.go
package client

// BinanceStandardIntervals 是 Binance REST/WSP kline 端点支持的 15 个标准 interval。
// 单一权威源（SSOT）：product_line / history_rest / mapper / taos_writer 全部引用本常量。
// [KNOWN] 与 Binance 官方文档（klines endpoint）对齐，TIER-DESIGN-DETAILS §1 的 interval 列为本集合子集。
var BinanceStandardIntervals = []string{
    "1m", "3m", "5m", "15m", "30m",
    "1h", "2h", "4h", "6h", "8h", "12h",
    "1d", "3d", "1w", "1M",
}

var intervalSet = func() map[string]struct{} {
    m := make(map[string]struct{}, len(BinanceStandardIntervals))
    for _, i := range BinanceStandardIntervals {
        m[i] = struct{}{}
    }
    return m
}()

// IsValidInterval 判断 interval 是否属于 Binance 标准 15 个。非标准值一律拒绝。
func IsValidInterval(interval string) bool {
    _, ok := intervalSet[interval]
    return ok
}
```

## Functional Requirements

**FR-016-001**: `internal/client/interval.go` 是 interval 列表的**唯一权威源**；client 包内任何其他文件出现裸字符串 interval 字面量（`"1m"`/`"5m"` 等）均为违规，必须引用 `BinanceStandardIntervals` 或 `IsValidInterval`。

**FR-016-002**: `BinanceStandardIntervals` 必须等于 Binance REST klines 端点的 15 个标准 interval（1m/3m/5m/15m/30m/1h/2h/4h/6h/8h/12h/1d/3d/1w/1M），不得多不得少。

**FR-016-003**: `product_line.go:26` 的 `RequiredBarIntervals` 必须改为引用 SSOT，覆盖率从 6/15 提升到 15/15。

**FR-016-004**: `history_rest.go` **禁止**任何形式的 `1m` fallback。当 backfill 请求缺少 interval 字段或 interval 非法时，必须返回显式 error（携带 symbol/任务上下文），由调用方决定重试或上报，不得静默降级到 `1m`。

**FR-016-005**: `history_rest.go` 拉取 4h backfill 时，URL 参数必须实际带 `i=4h`，禁止"4h 请求 → 60× 的 1m 拼接"。

**FR-016-006**: `mapper.go:166` **禁止** `coalesce(ev.Bar.Interval, "1m")`。事件缺少 interval 字段时 mapper 必须**返回 error / reject 事件**，不得用 `1m` 兜底污染下游时间桶。

**FR-016-007**: `taos_writer.go` 写入 Kline 行前必须调用 `IsValidInterval(interval)`，非白名单 interval 拒绝写入并返回 error。

**FR-016-008**: SSOT 是 ADR-005 per-tier interval 配置（TIER-DESIGN-DETAILS §1 的 1m/5m/1h/4h/1d/1w）的引用基础——Tier 配置只能选用 `BinanceStandardIntervals` 的成员，配置加载时校验。

## Acceptance Criteria

| AC | 验证方式 |
|----|---------|
| AC-016-001 WS 覆盖 15/15 | `len(client.RequiredBarIntervals) == len(client.BinanceStandardIntervals) == 15`，单测断言集合相等 |
| AC-016-002 4h backfill 实际拉 4h | 注入 mock HTTP，请求 4h backfill，断言 outgoing URL 含 `i=4h` 且请求次数按 4h 桶计，而非 60× 的 1m |
| AC-016-003 mapper 缺 interval reject | 构造 `Bar.Interval == ""` 的 kline 事件喂 mapper，断言返回 error 且不向下游发送任何时间桶事件 |
| AC-016-004 history_rest 无 fallback | 构造缺 interval 的 backfill 请求，断言返回带上下文的 error，grep `history_rest.go` 无 `"1m"` 字面量 |
| AC-016-005 TDengine 白名单校验 | 对 `taos_writer` 喂 `interval="13m"`（非法），断言拒绝写入并返回 error |
| AC-016-006 SSOT 无重复定义 | `grep -rn '"1m"\|"5m"\|"15m"' internal/client/ --exclude=interval.go` 仅命中注释或测试夹具 |

## Dependencies

| 依赖 | 类型 | 说明 |
|------|------|------|
| CLIENT-017 | 前置 | Tier 配置驱动 interval 订阅子集；CLIENT-017 的 per-tier interval 字段引用本任务 SSOT |
| GAP-E8（SchemaVersion） | 同 PR | interval SSOT 与 schema 协商同批落地（RUNTIME-GAP-MATRIX L133） |
| GAP-E23（精度校验） | 同 PR | 写入前校验链（interval 白名单 + 精度）共用同一 guard 点 |
| ADR-005 | 上游 | per-tier interval 配置消费本 SSOT |

## Non-scope

- 不动 Tier 分级逻辑（`classifyTier` 三层降级）——属 CLIENT-017
- 不动 CatalogEntry 字段（Tier/SymbolPriority/Collection）——属 CLIENT-015
- 不动 server 侧 `binance_symbols` 表 schema——属 SERVER-018
- 不实现 per-tier interval → 订阅子集的动态路由（CLIENT-017 职责）
