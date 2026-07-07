# Order Book State Machine Design

> 状态：Design
> 来源：ADR-011 + 用户需求 + SEQUENCE-CONTINUITY-STRATEGY.md §4
> Last-Updated：2026-07-06
> 关联：[ADR-011](ADR-011-order-book-rebuild-inclusion.md)、[ADR-003](ADR-003-order-book-rebuild-exclusion.md)（Superseded）

## 1. 概述

Order book 模块是整条行情链路中**唯一一个"错了不会报错，只会悄悄给出错误价格"**的模块。本文件定义 order book 状态机的完整设计：状态定义、转换条件、invariant、并发模型、staleness 语义、市场差异和对外接口行为。

### 1.1 设计原则

1. **正确性优先于性能**：任何不确定的情况，选择丢弃当前状态 + 重建，不选择"跳过"或"插值"
2. **per-symbol 独立**：每个 symbol 有独立的状态机实例和 goroutine，无全局锁
3. **staleness 是一等公民**：对外暴露的每条数据都携带 staleness 标记，下游永远能知道数据是否可信
4. **两种模式互斥**：`full_incremental`（维护本地 book）和 `snapshot_topn`（无状态转发）是两种独立模式，per-symbol 配置，不混用

## 2. 模式定义

### 2.1 full_incremental 模式

订阅 `<symbol>@depth`（全量增量流），client 侧维护完整 order book 状态机。适用于做市 / 风控 / 微观结构分析。

- 需要 REST 快照对齐
- 需要序号连续性校验
- 需要 gap → 重建
- 输出：经过校验的增量 + TopN 快照

### 2.2 snapshot_topn 模式

订阅 `<symbol>@depth5` / `@depth10` / `@depth20`（限档快照流），Binance 直接推 TopN，client 侧无状态转发。适用于展示 / 简单行情。

- 不需要 REST 快照对齐
- 不需要序号校验（每条事件是完整快照，自愈型）
- 不进 REBUILDING 状态
- 输出：原样转发 + stale 标记（仅 WS 断连时 stale=true）

> [COMPUTED, HIGH] 两种模式互斥，per-symbol 配置 `depth_mode` 字段。同一 symbol 不能同时订阅两种流。

## 3. 状态定义（full_incremental 模式）

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   UNINITIALIZED                                         │
│        │                                                │
│        │ subscribe(symbol)                              │
│        ▼                                                │
│   ┌──────────┐    REST snapshot     ┌──────────┐       │
│   │BUFFERING │ ─────────────────▶   │ ALIGNED  │       │
│   │          │ ◀─────────────────   │          │       │
│   └──────────┘   gap detected       └──────────┘       │
│        │                                    │           │
│        │              gap / WS disconnect   │           │
│        │                                    ▼           │
│        │           ┌────────────┐    ┌──────────┐       │
│        └────────── │ REBUILDING │ ─▶ │BUFFERING │       │
│           discard  └────────────┘    └──────────┘       │
│           book                           │              │
│                                         │              │
│   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘              │
│   (REBUILDING → BUFFERING keeps WS subscription,       │
│    re-requests REST snapshot, discards current book)    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3.1 状态表

| 状态 | 含义 | book 有效性 | stale 标记 |
|------|------|-------------|-----------|
| `UNINITIALIZED` | 未订阅，无数据 | 无 | `stale=true` |
| `BUFFERING` | WS 活跃，缓冲事件中，REST 快照请求已发出或待发 | 无（旧 book 已丢弃） | `stale=true` |
| `ALIGNED` | book 有效，增量更新通过序号校验 | 有效 | `stale=false` |
| `REBUILDING` | 检测到 gap 或 WS 断连，准备回到 BUFFERING | 无效（立即丢弃） | `stale=true` |

> [COMPUTED, HIGH] `stale` 是派生标志：`stale = (state != ALIGNED)`。不存在"stale=false 但 state=BUFFERING"的情况。

### 3.2 状态 invariant

每个状态的 invariant 是状态机正确性的基础——进入状态时必须满足，离开状态前必须保持：

**UNINITIALIZED**：
- 无 WS 订阅
- 无内存 book
- 无缓冲区
- `lastUpdateId = 0`

**BUFFERING**：
- WS 订阅活跃
- 事件缓冲区非空（或等待第一条事件）
- REST 快照请求 in-flight 或待发
- 内存 book 为空（进入 BUFFERING 时立即清空旧 book）
- `lastUpdateId = 0`（待 REST 快照填充）

**ALIGNED**：
- WS 订阅活跃
- 内存 book 有效（与 Binance 服务端一致）
- `lastUpdateId > 0`（已应用至少一条增量）
- 每条新事件通过序号连续性校验后才应用

**REBUILDING**：
- 内存 book 已丢弃
- WS 订阅保留（不断连）
- 正在准备重新进入 BUFFERING（重发 REST 快照请求）
- REBUILDING 是瞬态状态（< 1ms），立即转换为 BUFFERING

## 4. 状态转换

### 4.1 转换矩阵

| From | To | 触发条件 | Guard | Action |
|------|----|---------:|-------|--------|
| UNINITIALIZED | BUFFERING | `subscribe(symbol)` | — | 建 WS 订阅，初始化缓冲区，发 REST 快照请求 |
| BUFFERING | ALIGNED | REST 快照返回 + 对齐成功 | 第一条有效事件满足 `U <= lastUpdateId+1 <= u` | 丢弃 `u <= lastUpdateId` 的缓冲事件，从第一条有效事件开始应用，清空缓冲区 |
| BUFFERING | BUFFERING | REST 快照太旧 | `lastUpdateId < 缓冲区第一条事件的 U` | 丢弃快照，重新发 REST 请求 |
| BUFFERING | BUFFERING | 缓冲区溢出 | `len(buffer) > max_buffer_size` | 丢弃全部缓冲，重新发 REST 请求 |
| ALIGNED | REBUILDING | 序号校验失败 | spot: `新U != 旧u + 1`; futures: `新pu != 旧u` | 标记 stale，丢弃 book |
| ALIGNED | REBUILDING | WS 断连 | WS connection closed | 标记 stale，丢弃 book |
| REBUILDING | BUFFERING | 立即 | — | 保留 WS 订阅，重发 REST 快照请求 |
| ALIGNED | UNINITIALIZED | `unsubscribe(symbol)` | — | 断开 WS，清空 book 和缓冲区 |
| BUFFERING | UNINITIALIZED | `unsubscribe(symbol)` | — | 断开 WS，清空缓冲区 |

### 4.2 对齐算法（BUFFERING → ALIGNED 转换核心）

```
输入：
  rest_snapshot: { lastUpdateId, bids[], asks[] }
  buffer: [{ U, u, bids[], asks[] }, ...]  // 按 WS 接收顺序

步骤：
1. if rest_snapshot.lastUpdateId < buffer[0].U:
     // 快照太旧，快照在第一条缓冲事件之前
     return REJECT  // → 重新拉 REST

2. 丢弃 buffer 中所有 u <= rest_snapshot.lastUpdateId 的事件

3. if buffer 为空:
     // 所有缓冲事件都被丢弃，等待新事件
     return WAIT  // → 继续留在 BUFFERING

4. first_valid = buffer[0]
   if not (first_valid.U <= rest_snapshot.lastUpdateId + 1
           and rest_snapshot.lastUpdateId + 1 <= first_valid.u):
     // 对齐失败：快照和缓冲区之间有 gap
     return REJECT  // → 重新拉 REST

5. 用 rest_snapshot 初始化内存 book（bids/asks）
6. set lastUpdateId = rest_snapshot.lastUpdateId

7. for event in buffer (从 first_valid 开始):
     apply(event)  // 应用增量到 book
     set lastUpdateId = event.u

8. 清空 buffer
9. return SUCCESS  // → ALIGNED
```

### 4.3 序号校验（ALIGNED 状态持续校验）

```
收到新事件 event:
  spot:
    if event.U != lastUpdateId + 1:
      → REBUILDING

  futures (um_perp / cm_perp):
    if event.pu != lastUpdateId:
      → REBUILDING

  校验通过:
    apply(event)
    lastUpdateId = event.u
```

### 4.4 档位删除规则

```
apply(event):
  for (price, qty) in event.bids + event.asks:
    if qty == "0":
      delete book[price]  // 删除该价位，不是"挂了 0 的单"
    else:
      book[price] = qty   // 更新该价位数量
```

> [KNOWN, HIGH] `qty == "0"` 表示删除该价位是 Binance 官方定义。漏实现会导致 order book 无限增长 + 陈旧档位永不消失。

### 4.5 精度/价位对齐

```
price_key = 定点数(price_string, tickSize)
// 不用 float，用字符串转定点数
// 按 symbol 的 tickSize 对齐，避免浮点误差导致"同一价位"被识别成两个 key
```

> [KNOWN, HIGH] `tickSize` 来源：ExchangeInfo REST 响应中 `filters[].tickSize` 字段（FR-031 ExchangeInfo Discovery 已实现）。Order book manager 启动时从 `catalog.CatalogEntry` 读取 tickSize，per-symbol 缓存。catalog 刷新时（FR-032 diff sync）同步更新。

## 5. 快照持久化与恢复

### 5.1 持久化

- 定期（默认 5min）将内存 book 序列化落盘（TDengine 或 OSS）
- 序列化内容：`{ symbol, product_line, lastUpdateId, bids[], asks[], timestamp }`
- 持久化不阻塞 ALIGNED 状态的事件处理（读写分离，快照是只读拷贝）

### 5.2 恢复（冷启动 fast path）

```
冷启动恢复流程：
1. 加载持久化快照 → { lastUpdateId, bids[], asks[] }
2. 进入 BUFFERING（fast path variant）
3. 建 WS 订阅，开始缓冲
4. 检查缓冲区中是否有事件满足 U <= lastUpdateId+1 <= u
5. if 命中:
     用持久化快照初始化 book
     丢弃 u <= lastUpdateId 的缓冲事件
     从第一条有效事件开始应用
     → ALIGNED  (O(1) 恢复，无需 REST)
6. if 不命中 (gap between snapshot and first buffered event):
     丢弃持久化快照
     发 REST 快照请求
     → 正常 BUFFERING 流程
```

> [COMPUTED, HIGH] fast path 在正常关闭→重启场景下命中率接近 100%（WS 缓冲区与快照之间不会有 gap）。异常崩溃后 fast path 可能 miss，自动降级为完整重建，正确性不受影响。

## 6. 并发模型

### 6.1 per-symbol 独立 goroutine

```
每个 symbol 一个 goroutine：
  - 独立的状态机实例
  - 独立的 WS 事件 channel
  - 独立的内存 book
  - 独立的 REST 快照请求

goroutine 间无共享状态，无全局锁。
事件处理顺序由 channel 保证（单 goroutine 内 FIFO）。
```

### 6.2 外部查询接口

```
外部查询（TopN / 全量快照 / 健康状态）通过 atomic read 实现：
  - book 的只读拷贝（COW 或 sync.Map）
  - stale 标记：atomic.Bool
  - last_update_time：atomic.Int64（unix nano）
  - last_rebuild_time：atomic.Int64

查询不阻塞事件处理 goroutine。
```

### 6.3 背压处理

- 单 symbol 消息速率突增时，不影响其他 symbol（独立 goroutine）
- 如果单 goroutine 处理跟不上 WS 推送速率：
  - WS 事件 channel 有缓冲（默认 1024）
  - channel 满 → 丢弃最旧事件 → 标记 stale → 触发 REBUILDING
  - 不阻塞 WS 消费循环（避免拖慢其他 symbol 的 WS 读取）

## 7. 市场差异

### 7.1 序号校验差异

| 市场 | 序号字段 | 校验规则 | REST 快照端点 | limit |
|------|---------|----------|--------------|-------|
| spot | U, u | `新U == 旧u + 1` | `/api/v3/depth?symbol=X&limit=5000` | 5000 |
| um_perp | U, u, pu | `新pu == 旧u` | `/fapi/v1/depth?symbol=X&limit=1000` | 1000 |
| cm_perp | U, u, pu | `新pu == 旧u` | `/dapi/v1/depth?symbol=X&limit=1000` | 1000 |
| options | `[UNVERIFIED]` | `[UNVERIFIED]` | `/eapi/v1/depth` | `[UNVERIFIED]` |

### 7.2 增量更新频率可选项

| 市场 | 可选频率 | 默认建议 |
|------|---------|----------|
| spot | 100ms, 1000ms | 100ms |
| um_perp | 100ms, 250ms, 500ms, 0ms(实时) | 100ms |
| cm_perp | 同 um_perp | 100ms |
| options | `[UNVERIFIED]` | — |

### 7.3 限档快照流

| 市场 | 可选档位 | stream 格式 |
|------|---------|------------|
| spot | 5, 10, 20 | `<symbol>@depth5@100ms` |
| um_perp | 5, 10, 20 | `<symbol>@depth5@100ms` |
| cm_perp | 5, 10, 20 | `<symbol>@depth5@100ms` |
| options | `[UNVERIFIED]` | — |

### 7.4 options 待确认 checklist

> [KNOWN, HIGH] options 处于系统重构期（ADR-010 R-P2），字段行为须实测确认后再固化协议。以下为实测 checklist：

**Phase 2 mainnet 公开 WS 实测结果（2026-07-07）**：

- [x] REST `/eapi/v1/depth` 返回的 `lastUpdateId` 语义 — **已确认**：返回 `{"bids":[["price","qty"]],"asks":[...],"T":timestamp,"lastUpdateId":id}`，与 spot/futures 格式一致（bids/asks 为 `["price","qty"]` 数组，`T` 为事件时间，`lastUpdateId` 为序列号）
- [x] 限档快照流档位 — **已确认**：`<symbol>@depth20@100ms` stream 被 WS SUBSCRIBE 接受（返回 `{"result":null,"id":1}`），说明支持 depth20 限档流；与 spot/um/cm 的 `@depth5/10/20` 格式一致
- [ ] depth 事件是否有 U/u 字段 — **仍 UNVERIFIED**：options mainnet WS 连接成功且 SUBSCRIBE 被接受，但实测期间（2026-07-07）option 流动性极低，15 秒内 5 个 streams（depth/trade/bookTicker/markPrice）均无推送。基于 REST 返回 `lastUpdateId`，合理推断 WS depth 事件包含 `U`/`u` 字段，但需 option 有实时交易时复测
- [ ] depth 事件是否有 pu 字段 — **仍 UNVERIFIED**：需 WS depth 推送实样确认。spot 无 pu，futures 有 pu，options 待定
- [ ] 增量更新频率可选项 — **部分确认**：`@depth20@100ms` 被接受，说明支持 `@100ms` 频率后缀；是否支持 `@1000ms` 等其他频率需实测
- [ ] WS 断连后是否需要重新对齐（还是可以直接从新事件继续）— **仍 UNVERIFIED**：需实测 WS 重连场景

> [COMPUTED, MED] 实测发现的 WS 端点 bug：代码原配置 `OptionsStreamBaseURL = "wss://fstream.binance.com/public"`（futures 端点）是错误的，options symbol 在该端点无数据推送。**已修复**为 `wss://data-stream.binance.com`（与 spot 共享统一 WS 端点，stream 名称用 option symbol 小写格式如 `btc-260925-65000-c@depth`）。

> [INFERRED, MED] options WS 推送稀疏的根因：Binance European Options 流动性远低于 spot/futures，大部分 option symbol 的 depth/trade 流在非交易时段无推送。这是市场特性，非 bug。生产环境需关注 staleness 超时策略（option 可能长时间无更新）。

## 8. Staleness 语义

### 8.1 stale 标记定义

```json
{
  "symbol": "BTCUSDT",
  "product_line": "um_perp",
  "stale": false,
  "last_update_time": 1751812800123,
  "last_rebuild_time": 1751812795000,
  "state": "ALIGNED",
  "lastUpdateId": 123456789
}
```

### 8.2 stale=true 的场景

| 场景 | stale 值 | 持续时间 |
|------|---------|---------|
| 正常运行（ALIGNED） | false | — |
| 初始对齐中（BUFFERING） | true | < 2s（正常）|
| gap 重建中（REBUILDING → BUFFERING） | true | < 2s（正常）|
| WS 断连后重连中 | true | 取决于重连速度 |
| REST 快照持续失败 | true | 直到 REST 恢复 |
| 缓冲区溢出 | true | 直到重新对齐成功 |

### 8.3 下游消费方契约

- **做市/风控**：`stale=true` 时必须暂停决策，不能使用 book 数据
- **展示**：`stale=true` 时可显示最后已知值 + "数据延迟"提示
- **策略回测**：`stale=true` 的数据标记为不可用，回测引擎应跳过

## 9. 容灾与可观测性

### 9.1 自动重建

- gap 检测失败 → 立即 REBUILDING → BUFFERING，全程无人工介入
- REST 快照请求失败 → 重试（指数退避，最大 3 次）→ 仍失败 → 保持 BUFFERING + stale=true + 告警

### 9.2 重建频率告警

```
if 5min 内 REBUILDING 次数 > 3:
  emit alert("order_book_frequent_rebuild", symbol, count, last_5min)
```

频繁重建通常意味着：
- 网络质量问题（WS 频繁断连）
- REST 快照与 WS 数据源不一致（Binance 侧问题）
- 单 symbol 消息速率超出处理能力（背压导致 channel 满）

### 9.3 Checksum 抽样校验（可选但建议）

```
定期（默认 1min）：
1. 拉 REST 快照
2. 与内存 book 做全量 diff
3. if diff != empty:
   emit alert("order_book_drift_detected", symbol, diff_summary)
   → REBUILDING
```

> [INFERRED, MED] 理论上序号校验通过就不会漂移，但生产环境值得留一道保险。checksum 频率可配置，默认 1min。
>
> [KNOWN, MED] **checksum 限制**：spot REST `/api/v3/depth?limit=5000` 最多返回 5000 档位。如果内存 book 超过 5000 档（极端情况），diff 会显示 false positive（REST 少了高档位）。futures REST limit=1000 档位更少。checksum 抽样应只对比 REST 返回的 N 档范围内的数据，不将"REST 未返回的高档位"判定为漂移。

## 10. 对外接口

### 10.1 接口列表

| 接口 | 用途 | 模式 | stale 行为 |
|------|------|------|-----------|
| TopN 快照订阅（推送） | 策略/前端展示，按固定频率推送 TopN | 两种模式均支持 | stale=true 时推送 `stale=true` + 最后已知值 |
| 全量增量转发（订阅） | 下游自行维护 book，原样转发已校验增量 | 仅 full_incremental | stale=true 时停止转发（不推 partial 数据） |
| 按需全量快照（拉取） | 下游校准 / 怀疑不一致时拉取 | 两种模式均支持 | 返回当前 book + stale 标记 |
| 健康状态查询 | per-symbol 状态监控 | 两种模式均支持 | 返回 state / stale / last_update / last_rebuild |

### 10.2 TopN 推送语义

```
推送频率：配置项（默认 100ms），与底层 WS 事件频率解耦

ALIGNED 状态：
  每 100ms 从内存 book 取 TopN，推送 { symbol, bids[N], asks[N], stale: false }

非 ALIGNED 状态：
  if 曾达到过 ALIGNED（有最后已知值）:
    继续推送 { stale: true, last_known_bids, last_known_asks, last_update_time }
  else（初始 BUFFERING，从未 ALIGNED）:
    推送 { stale: true, bids: [], asks: [], last_update_time: 0 }
  绝不停止推送——stale 标记本身就是信号
```

### 10.3 全量增量转发语义

```
full_incremental 模式下，将已通过序号校验的增量事件原样转发：
  { symbol, U, u, pu, bids[], asks[], stale: false, rebuild_count: N }

REBUILDING 发生时推送一条标记事件：
  { symbol, type: "rebuild_start", stale: true, timestamp: T }

ALIGNED 恢复后推送一条标记事件：
  { symbol, type: "rebuild_complete", stale: false, timestamp: T, lastUpdateId: X }

下游可据此判断：收到 rebuild_start 后到 rebuild_complete 之前的增量不可用。
```

## 11. 双活去重（扩展路径）

> [INFERRED, MED] 当前版本不实现双活，以下为未来扩展设计参考。

如果同一 symbol 开两条 WS 连接做容灾：

- 两条流各自独立维护状态机（独立 BUFFERING → ALIGNED → REBUILDING）
- 各自独立做序号校验，**绝不交叉合并**（U/u/pu 连续性是单连接内概念）
- 对外输出层选"更新的那条"（`lastUpdateId` 更大的）
- 两条都 ALIGNED → 选 lastUpdateId 更大的
- 一条 ALIGNED 一条非 ALIGNED → 选 ALIGNED 的
- 两条都非 ALIGNED → stale=true，输出最后已知值

## 12. 开放问题决议

| 问题 | 决议 | 理由 |
|------|------|------|
| 快照持久化恢复语义 | 混合模式：加载快照 → BUFFERING fast path → 验证序列连续性 → ALIGNED 或降级为完整重建 | 正常情况 O(1) 恢复，异常情况自动降级 |
| 限档 vs 全量增量 | 互斥，per-symbol 配置 `depth_mode` | 两种模式状态机完全不同，混用增加复杂度无收益 |
| 重建期间增量事件处理 | Buffer with cap（默认 10000），REST 返回后对 buffer 跑对齐算法，溢出则丢弃重来 | 保留 WS 订阅避免断连开销，cap 防止 OOM |
| TopN 推送频率 | 独立配置（默认 100ms），非 ALIGNED 时继续推送 stale=true + 最后已知值 | stale 标记是信号，停止推送比推 stale 数据更危险 |

---

> **证据标签汇总**：
> - `[KNOWN]`：Binance 官方文档定义的 U/u/pu 校验规则、qty=="0" 删除语义、8 步对齐算法
> - `[COMPUTED]`：状态机设计、状态转换矩阵、staleness 语义、并发模型（基于官方算法 + 工程设计）
> - `[INFERRED]`：双活去重设计、checksum 抽样校验、背压处理策略（工程推断，非官方定义）
> - `[UNVERIFIED]`：options depth 协议所有字段（待测试网实测）
> - 置信度：`HIGH`（spot/um/cm 的状态机设计）/ `LOW`（options 待确认）
