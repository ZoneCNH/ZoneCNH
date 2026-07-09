# OrderBook 深度分析 — knowledge/OrderBook.md vs binance 模块

> 基于 `knowledge/OrderBook.md` (v2) 与 binance 模块实际实现对比。
> 日期: 2026-07-09

## 执行摘要

```
文档 19 章设计 vs 实际实现:
├── 维度 A (Stream 矩阵):   ✅ 85% 对齐 (StreamType 8位掩码 + streamConfig 接入)
├── 维度 B (Depth 档位):   ✅ 90% 对齐 (DepthLevel L0-L4 + Book.TopN 截断)
├── 维度 C (Policy/Demand): ⚠️ 30% (Policy 上界存在, Demand 聚合缺失)
├── OrderBook 同步协议:     ✅ 95% 对齐 (Snapshot+Diff+U/u+漂移+重建 全部已实现)
├── CollectionPolicy 分离:   ⚠️ 40% (有分离意图, 但部分字段仍混入)
├── Market State Engine:    ❌ 0%  (未来规划)
└── Market Digital Twin:    ❌ 0%  (3-5年愿景)
────────────────────────────────────
整体对齐度: ~60%
```

---

## 1. 维度 A: Stream 矩阵 (§1-2) — 85% 对齐

### 文档需求

```
Symbol × Stream 布尔矩阵
BTCUSDT: trade ✓, ticker ✓, depth ✗
ETHUSDT: trade ✓, depth ✓
```

### 当前实现

```
StreamType 8位掩码 (cache.go):
  StreamTrade(1) | StreamBookTicker(2) | StreamDepth20(4) |
  StreamDepthFull(8) | StreamKline(16) | StreamMarkPrice(32) |
  StreamFundingRate(64) | StreamTicker(128)

streamConfig() 中 per-symbol 过滤:
  allowed := streamMaskProvider(symbol).Effective()
  if streamBit != 0 && !allowed.Has(streamBit) { continue }

whitelist.yaml:
  BTCUSDT: allowed_streams: [trade, bookTicker, kline]  ← 不支持深度
```

### 差距

| 项 | 文档期望 | 当前状态 |
|----|---------|---------|
| 配置粒度 | per-symbol per-stream boolean | ✅ StreamType 位掩码 |
| 流开关 | 每个流独立开/关 | ✅ 8 种流可独立控制 |
| combined stream 上限感知 | 自动分片 | ❌ 未实现 |
| Total/symbol 维度 | 支持 | ❌ (streams.yaml 配置已存在, 但加载逻辑未实现) |

**建议**: 接入 `total_streams` 配置（已在 `whitelist.yaml` 中定义了 `blocked` 层，但缺少 `total_stream_limit`）。

---

## 2. 维度 B: Depth 档位 (§3-4) — 90% 对齐

### 文档需求

```
partial (服务端推送): @depth20, @depth100 — 省 CPU
full (本地重建):     @depth@100ms diff — 需同步协议

BTC: level=full (最贵)
ETH: level=20   (轻量)
DOGE: level=10  (更轻)
```

### 当前实现

```
DepthLevel 枚举 (depthlevel.go):
  DepthLevelNone(0) / L1(10) / L2(20) / L3(100) / L4(Full)

pushTopN 中 per-symbol depth 截断:
  symbolDepth := depth
  if sb.depthLevel != DepthLevelL4 {
      levels := sb.depthLevel.Levels()
      if levels > 0 { symbolDepth = levels }
  }
  book.TopN(symbolDepth)  ← 按档位截断

Entry.DepthLevel 字段 (0=Full, 向后兼容)
```

### 差距

| 项 | 文档期望 | 当前状态 |
|----|---------|---------|
| partial depth stream | @depth20, @depth100 | ✅ StreamDepth20 位对应 @depth20@100ms |
| full diff stream | @depth@100ms | ✅ StreamDepthFull 位对应 @depth@1000ms |
| per-symbol depth 档位 | L0-L4 | ✅ DepthLevel 枚举 |
| TopN 截断 | 档位限制输出 | ✅ Book.TopN(symbolDepth) |
| StreamRate 控制 | 100ms / 1000ms | ⚠️ 全局配置, 非 per-symbol |

**建议**: 将 `StreamRate` 从全局 `ManagerConfig.TopNInterval` 提升为 per-symbol 字段。

---

## 3. OrderBook 同步协议 (§5-6) — 95% 对齐

### 文档期望

```
1. REST getDepthSnapshot → 全量快照 + lastUpdateId
2. 订阅 @depth diff stream
3. 应用 diff, U/u 边界校验
4. 漂移检测: checksum / 对账
5. 失步重建: 重置 → 重走步骤 1
```

### 当前实现

```
orderbook/manager.go: SubscribeWithFeatures()
  → full_incremental mode: REST snapshot + diff 接续

orderbook/align.go: startAlignment()
  → 9-step alignment algorithm
  → U/u boundary check (FirstUpdateID / FinalUpdateID / PreviousUpdateID)

orderbook/health.go: checksumSample()
  → 周期性 REST vs 内存 checksum 对比
  → 漂移检测 + 子集轮询 (ChecksumSampleSize, offset rotation)

orderbook/state.go: State machine
  → UNINIT → BUFFERING → ALIGNED → REBUILDING → BUFFERING

orderbook/persist.go: persistAll()
  → 快照持久化, 快速恢复 (fast recovery from disk)
```

### 差距

| 项 | 文档期望 | 当前状态 |
|----|---------|---------|
| 快照+diff 接续 | ✅ | ✅ 9-step alignment |
| U/u 边界校验 | ✅ | ✅ 完整实现 |
| 漂移检测 | ✅ | ✅ checksumSample |
| 失步重建 | ✅ | ✅ State machine rebuild |
| 快照+diff时序 | 先 sub 后 snapshot | ✅ 实现正确 |
| Replay Buffer | Ring buffer 30s | ❌ 未实现 |

**结论**: 同步协议已经完整实现，**超出文档期望** (文档认为这是"90% 的工程难度"且"原版缺失")。binance 模块的 orderbook/ 包已经是生产级实现。

---

## 4. 维度 C: Policy/Demand 双层 (§7) — 30% 对齐

### 文档期望

```
静态层 Policy (能力上界)
  └── whitelist.yaml 启动时加载, 定义每个 symbol 的允许上限

动态层 Demand (运行时需求)
  └── Strategy 声明需求 → Demand Aggregator → Policy Manager → 激活采集

裁决规则:
  Demand ⊆ Policy
  Demand 超出 Policy → 拒绝并告警
```

### 当前实现

```
Policy 静态层:
  ✅ whitelist.yaml + LoadWhitelistFile()
  ✅ WhitelistWatcher 热加载

Demand 动态层:
  ❌ Demand Aggregator 不存在
  ❌ Strategy→Demand 注册 API 不存在
  ❌ Demand ⊆ Policy 校验逻辑不存在

替代方案 (简化的):
  Catalog (exchangeInfo) 决定 active symbols
  WhitelistProvider 决定可采集范围
  StreamMaskProvider 决定 per-symbol 流类型
  ── 全部是静态策略, 无运行时 Demand 聚合
```

### 需要实现

```go
// policy/manager.go — 新建文件
type PolicyManager struct {
    policy map[string]CollectionPolicy  // 静态上界
    demand map[string]DemandSet          // 运行时需求
}

func (pm *PolicyManager) Request(symbol, feature string) bool {
    if !pm.policy[symbol].Allows(feature) {
        return false  // Demand 超出 Policy
    }
    pm.demand[symbol].Add(feature)
    return true
}

func (pm *PolicyManager) ActiveStreams() map[string]StreamType {
    // 聚合 Policy ∩ Demand → 最终采集集
}
```

**建议**: 在 `internal/client/` 下新建 `policy/` 包实现 Policy Manager。

---

## 5. CollectionPolicy 三路分离 (§8-9) — 40% 对齐

### 文档期望

```go
type CollectionPolicy struct { // 纯采集决策
    Symbol, Trade, Ticker, BookTicker, Depth, Liquidation, Funding, MarkPrice, Kline
    DepthLevel, StreamRate, DynamicAllowed
}

type StoragePolicy struct {   // 存储决策
    SaveTick, SaveDepth, SaveKline, RetentionTTL
}

type BusPolicy struct {       // 分发决策
    PublishTrade, PublishDepth, TopicPrefix
}
```

### 当前实现

```
CollectionPolicy:
  ✅ StreamType 位掩码 → 采集开关
  ✅ DepthLevel 枚举 → 档位控制
  ❌ DynamicAllowed 字段 → 缺失
  ⚠️ StreamRate → 全局配置, 非 per-symbol

StoragePolicy:
  ⚠️ 分散在 runtime.go (cfg.OrderBookSnapshotMin 等)
  ❌ 未抽象为独立结构体

BusPolicy:
  ✅ NATS publisher 独立 (publisher/)
  ✅ Kafka dispatcher 独立 (kafka_dispatch.go)
  ⚠️ 未抽象为独立 Policy 结构体
```

---

## 6. Market State Engine (§14-18) — 0% 对齐

### 文档规划 (3-5年愿景)

```
OrderBook Builder → Queue State → Liquidity → Order Flow
→ Feature Engine → Market State → Alpha → Execution
→ Market Digital Twin
```

### 当前状态

```
✅ OrderBook Builder (book.go — 完整实现)
❌ Queue State Engine
❌ Liquidity Engine
❌ Order Flow Engine
⚠️ Feature Engine (部分: OrderbookFeatures 6位掩码, 非 Market State 特征)
❌ Market State Engine
❌ Alpha Engine
❌ Execution Engine
❌ Market Digital Twin
```

---

## 优化建议

### P0 — 本阶段可实施

| # | 建议 | 文件 | 工作量 |
|---|------|------|--------|
| 1 | 实现 `PolicyManager` + Demand 聚合 | 新增 `internal/client/policy/manager.go` | ~200 行 |
| 2 | 接入 `DynamicAllowed` + Demand ⊆ Policy 校验 | `policy/rule.go` | ~80 行 |
| 3 | `StreamRate` per-symbol 化 | `SpotConfig` / `symbolBook` | ~30 行 |
| 4 | 抽象 `StoragePolicy` / `BusPolicy` 结构体 | `policy/config.go` | ~100 行 |

### P1 — 下一阶段

| # | 建议 | 工作量 |
|---|------|--------|
| 5 | combined stream 上限感知 + 自动分片 | ~300 行 |
| 6 | Replay Buffer (Ring buffer 30s) | ~200 行 |
| 7 | `total_stream_limit` 配置 | ~50 行 |

### P2 — 未来规划

| # | 建议 | 工作量 |
|---|------|--------|
| 8 | Feature Registry (插件式特征注册) | ~500 行 |
| 9 | Feature Scheduler (Dirty Flag + 异步计算) | ~300 行 |
| 10 | Market State Engine (Digital Twin 基础) | 大型工程 |

---

## 对比总结

| 文档章节 | 主题 | 对齐度 | 说明 |
|---------|------|--------|------|
| §1-2 | 维度 A: Stream 矩阵 | 85% | 核心已实现, 缺 combined stream 分片 |
| §3-4 | 维度 B: Depth 档位 | 90% | 已实现, 缺 per-symbol StreamRate |
| §5-6 | OrderBook 同步协议 | 95% | **超出文档期望**, 生产级实现 |
| §7 | 维度 C: Policy/Demand | 30% | Policy 层存在, Demand 聚合缺失 |
| §8-9 | CollectionPolicy 分离 | 40% | 意图存在, 结构未规范化 |
| §10-13 | Query API/Collector 设计 | 50% | API 存在, 但未通过 Policy Manager |
| §14-18 | Market State Engine | 0% | 3-5年愿景 |
| §19 | Market Digital Twin | 0% | 愿景 |

**binance 模块的核心 OrderBook 工程 (同步协议、状态机、漂移检测) 已经超出 `knowledge/OrderBook.md` 的期望。最大的未实现部分是维度 C 的 Policy/Demand 双层抽象。**
