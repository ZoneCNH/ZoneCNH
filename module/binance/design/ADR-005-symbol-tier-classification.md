# ADR-005：Symbol 采集分级体系（CatalogEntry Tier/SymbolPriority/Collection）

> **Status**: Accepted（2026-07-04 — runtime `catalog.go` 已实现 Tier/Collection 字段与 classifyTier 逻辑，见 `internal/client/catalog.go:44-366`）
> **Date**: 2026-07-02
> **Accepted**: 2026-07-04（runtime `main@7a989e7`）
> **决策者**: binance 模块架构（基于用户架构指令 + EXCHANGEINFO 报告 §8 勘误）
> **关联**: GAP-E6/GAP-E24/GAP-E25/GAP-E26（RUNTIME-GAP-MATRIX）；上位报告 `report/binance/EXCHANGEINFO-SYMBOL-TIER-ANALYSIS-20260702.md`；ADR-004（连接拓扑层，本 ADR 提供数据字段层 Tier 供其消费）
> **仓库归属**: ZoneCNH 主仓 `module/binance/`

---

## 1. 背景与问题

用户架构指令要求"ExchangeInfo symbol 采集的币种要分级别、分层级、分优先级，不是所有币种都采集"。EXCHANGEINFO 报告 §1 的源码审计（核验日期 2026-07-02）证明：当前实现在这三个维度上均为零支撑，属全新能力建设。

### 1.1 现状证据（四个层面全无支撑点）

| 层面 | 现状 | 源码证据 |
|------|------|----------|
| 数据模型 | CatalogEntry 12 字段，零分级槽位 | `internal/client/catalog.go:16-46`；全仓 grep `tier` 零命中 |
| 信号采集 | decode 在入口丢弃 `quoteVolume` 流动性信号 | `internal/client/exchangeinfo.go:19-24`（spot decode 仅 4 字段） |
| 决策谓词 | 全部以 `Status == "active"` 为唯一谓词，全量采集 | `lifecycle.go:161-174`、`history_lifecycle.go:530-583`、`stream_control.go:333-357` |
| 配置层 | 零范围控制项 | `pkg/binancecfg/config.go:249-269` 无 symbol/tier 字段 |

symbol 的采集命运仅由 `Status` 单字段决定——所有 active symbol 平等对待，无数量上限、无流动性筛选、无优先级。

### 1.2 全量采集物理不可行

[COMMON] Binance 单 WS 连接最多 1024 stream。spot 全量 ~2000 active symbol × 4 流后缀（trade/quote/depth/kline）= 8000 stream，逼近 `defaultMaxWSConns=10`（`stream_control.go:13`）× 1024 上限。分级后降到 ~940 stream（2 连接），是从"物理不可行"到"轻松承载"的关键 [INFERRED]。

分级也是 GAP-E6 全量化的硬前置——全量化后若不分级，资源账（spot 2000 × 1m kline × 4 线，30 天 backfill 103K 请求，120/min throttle = 14h 冷启动）不可承受。

---

## 2. 三维度设计裁决（Tier / Level / Priority）

用户用了三个近义词，落到数据模型上是三个正交维度，必须分别建模，不可混为一谈（EXCHANGEINFO 报告 §2）。

| 维度 | 含义 | 决定什么 | 数据模型字段 | 判定依据 |
|------|------|----------|--------------|----------|
| **Tier（级别）** | symbol 的"重要性档位" | 采集策略（stream/kline/REST/不采）+ retention TTL | `Tier int`（0-4） | 流动性 + 显式配置 |
| **Level（层级）** | symbol 的"市场归属" | 采集范围边界（哪些产品线参与、各 Tier 数量上限） | 配置层 `tiers[product_line][tier]` | 产品线 × 计价资产 × 数量 cap |
| **Priority（优先级）** | 同 Tier 内的调度次序 | 任务出队顺序、资源争用谁先采、降级谁最后丢 | `SymbolPriority int` | 显式配置 + Tier 派生 |

三者的关系：**Level（范围）→ 该采哪些 Tier → 每个 Tier 用什么策略（Tier）→ 同 Tier 内谁先采（Priority）**。Tier 是主轴（怎么采），Level 是边界（采多少），Priority 是调度（先采谁）。

### 2.1 命名裁决：消解 Priority 冲突

现有 `LifecycleTask.Priority`（`lifecycle.go:16-19`：gapfill=100/coldstart=50/reconcile=20）是**任务类型**优先级，与用户要的 symbol 级优先级语义完全不同。

**裁决**：symbol 级用 `SymbolPriority`（避开同名冲突），任务级保留 `Priority`。任务最终出键采用复合排序 `(SymbolPriority, TaskPriority)`：先按 symbol 优先级，再按任务类型。

---

## 3. 决策：CatalogEntry 数据字段层加 4 字段

`catalog.go:16-46` 扩展（注释指向本 ADR-005）：

```go
type CatalogEntry struct {
    // ... 原 12 字段（ProductLine ~ OptionType）
    Status string

    // ADR-005 新增——symbol 级分级四字段
    Tier           int     // 0=核心 / 1=主流 / 2=次主流 / 3=长尾 / 4=监控
    SymbolPriority int     // 同 Tier 内调度优先级（0=最高）；与任务级 LifecycleTask.Priority 区分
    Collection     string  // full_stream/stream_no_depth/kline_only/rest_sample/rest_daily/disabled
    QuoteVolumeUSD float64 // decode 保留的流动性信号（分级判定依据，§4）
}
```

字段语义：

| 字段 | 语义 | 取值范围 | 判定来源 |
|------|------|----------|----------|
| `Tier` | symbol 重要性档位，决定采集策略与 TTL | 0-4 整数 | `classifyTier` 三层降级（§4） |
| `SymbolPriority` | 同 Tier 内调度次序，资源争用时裁决 | ≥0 整数，0 最高 | 显式配置 + Tier 派生 |
| `Collection` | 采集策略路由键 | 6 个枚举值（见下表） | 由 Tier 映射 + 配置 override |
| `QuoteVolumeUSD` | 流动性信号，分级判定核心依据 | float64，USD | decode 保留（修复 `exchangeinfo.go:19-24` 丢弃问题） |

Collection 枚举与触发路径：

| Collection | 触发路径 | 占 WS 连接 | 占 REST budget |
|------------|----------|:----------:|:--------------:|
| `full_stream` | trade+quote+depth+kline 全订阅 | ✅ | ❌（冷启动例外） |
| `stream_no_depth` | 减 depth 后缀 | ✅ | ❌ |
| `kline_only` | 仅 kline 后缀 | ✅ | ❌ |
| `rest_sample` | backfill cron 周期采样 | ❌ | ✅ |
| `rest_daily` | backfill cron 每日触发 | ❌ | ✅ |
| `disabled` | 不采集 | ❌ | ❌ |

---

## 4. classifyTier 三层降级算法

分级判定按优先级降级，详细伪代码与阈值表见 `TIER-DESIGN-DETAILS.md §3`。本 ADR 仅记录决策骨架：

```
① 显式配置（Level 决策，T0 人工维护最高优先）
   → configuredTier(symbol) 命中即返回

② 流动性信号（依赖 decode 保留 quoteVolume）
   → quoteVolumeUSD 阈值分档 T1/T2/T3

③ quoteAsset 兜底（无 volume 信号时）
   → USDT/USDC 至少 T2，其他 → T3
```

**关键依赖**：第二层依赖 `exchangeinfo.go:19-24` 的 spotExchangeSymbol 结构体扩展 `QuoteVolume string` 字段（Binance 原始 JSON 已含，当前被 `json.Decode` 静默丢弃）。UM/CM 同理扩展。**修复分级必须先改 decode 结构体**——这是 §1.2 的根因洞察。

**风险**：T0 被错误降级 → 核心 symbol 降为 REST 采样 → 实时策略失效。缓解：T0 配置人工 review + admin API 强制 override + metrics 监控 T0 symbol 数量。

---

## 5. 白名单 MVP 优先（§8.3 勘误）

EXCHANGEINFO §8.3 复核指出：原文 §3-§4 把"五级动态分级 + classifyTier 三层降级 + per-tier 配置矩阵"作为唯一路径，忽略了 ROI 高得多的渐进方案。本 ADR 采纳此勘误。

**第一版（MVP）决策**：

- catalog 仍全量化（GAP-E6 独立该修）
- `stream_control.go:337` 加一个 `STREAM_SYMBOLS` 配置白名单 + 静态 Tier 表，仅白名单内 symbol 进 WS 订阅
- 改动量 ~20 行，工时 ~0.5d
- 动态 `classifyTier` 与 per-tier 配置矩阵延后

**理由**：[INFERRED, MED] DATA-INTEGRITY §GAP-E24 原文明确"策略通常只需 Top 50-100 主流 symbol 实时"，0.5d 覆盖 ~90% 业务需求。stop-and-evaluate 后再决定是否上动态分级（3-5d，覆盖 100%），最后才考虑分片（5-8d）。跳过 stop-and-evaluate 直接做后两步违反 Simplicity First。

---

## 6. §8 勘误强制纳入（三项）

EXCHANGEINFO 报告 §8 的对抗性复核产出三项修正，本 ADR 显式纳入为设计约束。

### 6.1 options 不归 T4，单列 options_classification 维度

[INFERRED, HIGH] 期权的"重要性"由**距到期天数 + moneyness（strike 与标的现价比）**决定，而非 quoteVolume。末日/近月期权（0DTE、近月 ATM）是 gamma 交易最活跃的合约，日级 REST 采样会丢失全部日内 gamma——Tier 按"流动性/重要性"分档的语义对 options 错配。

**决策**：

- options **不进 Tier 模型**，单列 `options_classification` 维度，按 `(距到期天数, moneyness)` 分桶：
  - 近月 + 近价（ATM）→ 实时 stream（类比 T0/T1）
  - 远月或深虚值（OTM）→ REST 采样或不采
- §3.1 Tier 表的"T4（监控）其他产品线"行应拆分：cm_perp 可按 Tier 分（有 volume），options 不在此列

**与白名单准入层的关系（ADR-008 层间解耦）**：本节"options 不进 Tier 模型"指**采集分桶层**——决定 options 进入系统后如何采样（实时 stream vs REST 采样）。白名单准入层（哪些 options contract 进入系统）自 v0.4 起改用 24h quoteVolume top 20 自动准入（FR-051 / ADR-008），与本节采集分桶正交、不替代。即"采不采"由白名单 top 20 决定，"怎么采"由 options_classification 决定。

**与白名单准入层的关系（ADR-008 层间解耦）**：本节"options 不进 Tier 模型"指**采集分桶层**——决定 options 进入系统后如何采样（实时 stream vs REST 采样）。白名单准入层（哪些 options contract 进入系统）自 v0.4 起改用 24h quoteVolume top 20 自动准入（FR-051 / ADR-008），与本节采集分桶正交、不替代。即"采不采"由白名单 top 20 决定，"怎么采"由 options_classification 决定。

**前置必修**：[COMPUTED, HIGH] `exchangeinfo_option.go:30-36` 的 `optionsExchangeSymbol` 结构体无 status 字段，`DecodeOptionsExchangeInfo`（L74-84）仅按 `expiryDate > now` 判 active，**不做 TRADING 过滤**（spot/um/cm 都做了）。所有未过期合约——含大量远月、深度虚值的低流动性合约——全部以 `status="active"` 灌入 catalog。**分级落地前必须先修 options 的 TRADING 过滤，否则 options 分桶会塞满无效合约**。

### 6.2 GAP-E25 改为可选扩容，非 E24 下游依赖

[INFERRED, HIGH] EXCHANGEINFO §8.2 指出原依赖链 `E6 → E26 → E24 → E25 → E1` 的逻辑矛盾：报告 §3.2 已论证分级后单副本 WS 占用 = T0+T1(110)×4 + T2(500)×1 = **940 stream（2 连接）**，REST 冷启动 T3 ~60K 请求（8h）。即分级后单副本完全扛得住。

那么"GAP-E25 是 GAP-E24 的放大器：无分片时 3 副本都跑全量"的前提**在分级落地后不成立**——既然单副本只采 T0+T1+T2 子集（≤940 stream），就不存在"3 副本跑全量"的 3 倍浪费。

**决策**：GAP-E25（一致性哈希分片）**不是 E24 下游依赖，而是分级后单副本仍不够时的可选扩容路径**。修正依赖链：

```
GAP-E6（全量化）→ GAP-E26（interval SSOT）→ GAP-E24（分级）→ [评估单副本负载]
                                                       ↓ 大概率够
                                                      完成
                                                       ↓ 极少数情况不够
                                                     GAP-E25（可选扩容）
```

E24 和 E25 是**互斥的扩容路径**，不是配套。把 E25 列为 E24 下游依赖会诱导过度工程化（一致性哈希 ring + Redis ClientRegistry + NATS heartbeat + 分片 diff 广播，5-8d 工作量服务于一个不存在的需求）。

### 6.3 白名单 MVP

见 §5。第一版仅 `STREAM_SYMBOLS` 配置白名单 + 静态 Tier 表，动态分级延后。

---

## 7. 与 ADR-004 的分层边界（关键）

binance 模块存在两个"tier"概念，必须显式划清边界，避免 W-1（Anti-Shadowing）重复定义：

| ADR | 层次 | 职责 | 持久化 |
|------|------|------|--------|
| **ADR-005（本 ADR）** | 数据字段层 | CatalogEntry 持久化 Tier/SymbolPriority/Collection/QuoteVolumeUSD | catalog 结构体内 |
| **ADR-004** | 连接拓扑层 | FR-036 stream manager 按 `(productLine, tier)` 分组 WS 连接做增量 diff | stream manager 运行时 map |

**正交关系**：ADR-005 提供 Tier 字段（CatalogEntry 的数据属性），ADR-004 消费 Tier 字段（按 Tier 分组连接拓扑）。两者不重叠：

- ADR-005 回答"每个 symbol 是什么 Tier、怎么采"（数据语义）
- ADR-004 回答"同 Tier 的 symbol 如何复用 WS 连接、catalog 变更时如何 diff"（连接管理）

ADR-004 已 Accepted，其 `StreamsForProductLineTier(catalog, tierConfig)` 直接读取本 ADR 定义的 `CatalogEntry.Tier` 字段。本 ADR 落地后 ADR-004 的 tierConfig 才有数据来源。

---

## 8. 影响

### 8.1 数据模型

CatalogEntry 加 4 字段（Tier/SymbolPriority/Collection/QuoteVolumeUSD），影响：

- `internal/client/catalog.go`：结构体定义
- decode 路径：`exchangeinfo.go`（spot/um/cm 扩展 quoteVolume）、`exchangeinfo_option.go`（加 status 字段，§6.1 前置）
- DiffSync：序列化/反序列化兼容（新增字段零值不影响旧 catalog 反序列化）
- ADR-002 wire 边界：CatalogEntry 是 binance 仓内部类型，不跨 wire 边界

### 8.2 采集层

决策谓词从 `Status` 单字段扩展为 `(Status, Collection, Tier)` 复合谓词：

```go
// lifecycle.go:SyncCatalog——原 L167 唯一谓词 Status==active
if e.Status != "active" || e.Collection == "disabled" { continue }
if !tierEnabled(e.ProductLine, e.Tier) { continue }
```

`stream_control.go:337` 从 `ActiveSymbols()` 全量改为按 Collection 过滤：仅 `Collection ∈ {full_stream, stream_no_depth, kline_only}` 的 symbol 才订阅 WS。

### 8.3 配置层

`pkg/binancecfg/config.go` 的 `binanceFields`（L249-269）增加 per-tier 配置项。MVP 阶段仅 `STREAM_SYMBOLS` 白名单（§5），动态分级阶段扩展完整 `tiers[product_line][tier]` 矩阵（详见 `TIER-DESIGN-DETAILS.md`）。

### 8.4 server 侧

binance_symbols 表加列（Tier/SymbolPriority/Collection/QuoteVolumeUSD），见 TASK-BINANCE-SERVER-018。

### 8.5 双口径不变

本 ADR 属**运行时口径**（runtime catalog 数据结构演进），不独立改写 SPEC 规格状态。[COMPUTED, HIGH] 当前 root canonical 投影为 13 Done / 52 Partial / 0 Drifted / 0 Pending，运行时分级实现不得自行把 Partial 提升为 Done。

---

## 9. 关联缺口与任务

### 9.1 缺口关联

| 缺口 | 角色 | 说明 |
|------|------|------|
| GAP-E6 | 前置 | symbol 全量化（4 线 refresher 装配），分级前提是"有全集可分" |
| GAP-E26 | 前置 | interval SSOT，分级配置的 interval 字段需权威来源 |
| GAP-E24 | **本 ADR 核心** | 分级采集（Tier/Priority/Collection），用户指令的核心 |
| GAP-E25 | 可选 | 水平扩展分片，§6.2 改为可选非依赖 |

### 9.2 实现任务

| 任务 | 内容 | 阶段 |
|------|------|------|
| CLIENT-015 | schema + refresher（catalog.go 加字段 + decode 扩展） | MVP |
| CLIENT-016 | interval SSOT（GAP-E26 前置） | MVP |
| CLIENT-017 | classifyTier + Collection 路由 + STREAM_SYMBOLS 白名单 | MVP |
| SERVER-018 | binance_symbols 表加列 | MVP |
| CLIENT-018 | 一致性哈希分片（GAP-E25） | 可选，§6.2 |

---

## 修订记录

- 2026-07-04：Status Proposed → Accepted。runtime `internal/client/catalog.go` 已实现 `CatalogEntry.Tier`/`Collection` 字段（L44/L48）、`classifyTier` 逻辑（L347-366）。CLIENT-015/016/017 MVP 任务已落地；CLIENT-018（GAP-E25 分片）保持可选，不阻断 Accepted 升级。

- 2026-07-02：初版。基于 EXCHANGEINFO 报告 §8 勘误定稿，纳入 options 不归 T4（§6.1）、GAP-E25 改可选（§6.2）、白名单 MVP（§5/§6.3）三项修正。与 ADR-004 划清数据字段层 vs 连接拓扑层边界（§7）。
