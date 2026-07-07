# Historical Data Sync Strategy

> 状态：Reference
> 来源：report/binance/20260704.md + SPEC FR-016/FR-026/FR-027
> Last-Updated: 2026-07-07

## 1. Overview

历史数据同步必须先分清两条完全不同的路径，二者的"起始时间"定义方式截然不同 `[KNOWN]`：

- **公开行情数据**：理论上能拉到该 symbol 上线那天。起始时间由 symbol 上线时间与你需要的历史深度共同决定，可通过官方批量库、REST 分页或三方数据商获取。
- **私有订单/成交历史**：官方 REST 只给一个很短的回溯窗口（5 天～6 个月）。超过窗口的部分，**如果你没有从一开始就用用户数据流落库，事后是补不回来的** `[KNOWN]`。

这个区别直接决定了"起始时间"该怎么定：行情类可以做历史回填，私有类没有"起始时间"可谈，只有"你开始监听用户数据流的那一刻" `[INFERRED]`。

> 注：用户数据流（私有流）当前在 binance 模块中处于排除/未来扩展状态，本文 §3 的 REST 窗口表仅作未来扩展参考，不代表当前实现范围。

## 2. Public Market Data Strategy

没有一个全局固定的"起始时间"，因为每个 symbol 的上线时间不同 `[KNOWN]`。实际获取方式与覆盖范围如下：

| 方式 | 覆盖范围 | 怎么拿到"起始时间" |
| --- | --- | --- |
| **官方批量库**（推荐）<br>`data.binance.vision` / GitHub `binance/binance-public-data` | 现货、USDⓈ-M、COIN-M 的 klines/trades/aggTrades，按 symbol 分目录，daily+monthly 文件 | 直接看该 symbol 在 `data.binance.vision` 目录下最早的月份文件，那就是它能拿到的最早历史 |
| REST 分页拉取 | 同上 + depth 之外的大部分数据 | klines 用 `startTime` 从 0 往后翻页（limit 1000/1500 一批）；aggTrades/trades 用 `fromId` 从 0 往后翻页 |
| 三方数据商（如 Tardis 等） | 补 Binance 自己不存档的东西（比如逐档深度历史/订单簿重建），或者更早期的边缘数据 | 各家自己标注的覆盖起始日期，不是 Binance 官方口径 |

参考量级（不是精确上线时间，只是给起始点定量级用）`[KNOWN]`：现货最早；USDⓈ-M 永续大约 2019 年 9 月前后上线；COIN-M 交割合约同期、永续合约稍晚（2020 年中前后）；期权（eapi）大约 2020 年下半年上线。**新币种是持续上新的**，所以具体到某个 symbol，永远以 `data.binance.vision` 该 symbol 目录下最早文件为准，不要用"平台上线时间"去硬编码。

## 3. Private Data REST Window Limitations

> ⚠️ **用户数据流当前排除**：binance 模块当前版本不接入用户数据流（私有流），本节 REST 窗口表仅作未来扩展参考，不代表当前实现范围。

私有订单/成交历史的起始时间被 REST 窗口锁死 `[KNOWN]`：

| 端点 | 可回溯窗口 | 影响 |
| --- | --- | --- |
| 期权 `GET /eapi/v1/historyOrders` | 仅最近 **5 天** | 期权订单历史几乎等于"没有回溯"，必须从第一天就落 ORDER_TRADE_UPDATE |
| 期货强平记录 `forceOrders`（UM/CM/PM） | 仅最近 **90 天** | 超过 90 天的强平记录无法补录 |
| 期货成交历史 `userTrades` 类接口 | 部分端点 2024-10-30 起改为仅 **最近 6 个月** | 半年前的成交明细 REST 拉不到 |
| 期货订单历史 `allOrders` 类接口 | 部分端点 2024-10-16 起改为**不早于 30 天**，单次查询窗口 ≤ 7 天 | 需要多次翻页且窗口很短 |
| 现货 `myTrades`/`allOrders` | 官方未强制限窗口，但强烈建议按 `fromId`/`orderId` 增量拉，别依赖时间窗口 | 相对宽松，但也不建议当"历史真相来源" |

结论 `[INFERRED]`：**私有数据没有"起始时间"这个概念可谈，只有"你开始监听 ORDER_TRADE_UPDATE / executionReport / BALANCE_POSITION_UPDATE 的那一刻"**。REST 历史接口只能当"断线重连后补漏"用（补最近几天到几个月），不能当"从账户开户第一天开始回溯"用。

## 4. System Design Recommendations

落到同步系统设计上，起始时间的定义建议如下 `[INFERRED]`：

1. **行情类**：`start_time = max(symbol 上线时间, 你需要的历史深度)`，直接批量下载官方 CSV 到某个时间点，之后无缝切到 WS 实时流 + depth 快照对齐（U/u 衔接逻辑）。
2. **私有类**：`start_time = 你的用户数据流第一次成功建连的时间`，之前的数据只能靠 §3 窗口表内的 REST 尽量补一次性全量对账（比如刚接入时先跑一次 90 天强平记录、6 个月成交记录），窗口外的部分只能承认"历史不完整"，没有别的办法。
3. **断线重连**：起始时间 ＝上次成功处理的最后一条事件的 `E`/`T`，用它去决定 REST 补漏要查多久的窗口，而不是每次都全量重拉。

## 5. Known Pitfalls

### 5.1 Timestamp Unit Change (2025-01-01)

> 🔴 **关键风险**：时间戳单位变更会导致 1000 倍的时间错位，拼库前必须处理。

官方 CSV 从 **2025-01-01 起，现货数据的时间戳单位从毫秒变成了微秒**（futures 依旧是毫秒）`[KNOWN]`。如果你的历史库要把 2025 前后的数据拼在一起，必须按日期分段处理时间戳单位，否则会出现 1000 倍的时间错位。

**影响范围**：
- 仅影响现货（spot）CSV 数据
- futures（UM/CM）CSV 依旧是毫秒
- 变更生效日期：2025-01-01
- 影响操作：历史回填、跨年拼接、批量库下载后的解析

### 5.2 Depth No Historical Archive

**depth（订单簿）没有官方历史可回溯** `[KNOWN]`——Binance 不存档逐档快照，只能自己跑 WS 从"你开始运行的那一刻"起持续落库 + 定期打 REST 快照兜底（即订单簿重建逻辑），起始时间 = 你系统上线时间，这个没法后补。

**与 ADR-003 / ADR-011 交叉引用**：[`design/ADR-003-order-book-rebuild-exclusion.md`](ADR-003-order-book-rebuild-exclusion.md) 原决策（v0.2.0）排除 order book rebuild 状态机、depth 以快照形式落库——**该决策已被 ADR-011（v4.0.0）supersede**。v4.0.0 经 FR-052~061 在 spot/um/cm 实现本地 order book 状态机 + 增量 diff 重放（options 待 Phase 2）。这意味着：
- depth 历史仍无法从官方回溯（币安不存档逐档快照）
- depth 数据的起始时间严格等于"开始维护本地订单簿的那一刻"（即系统上线运行时间）；本地重建仅能补齐上线后的序列，无法回填上线前
- 未来若扩展 options，起始时间仍受限于"开始维护 options 本地订单簿的那一刻"

### 5.3 Symbol Launch Time Variance

每个 symbol 的上线时间不同 `[KNOWN]`，**不要硬编码"平台上线时间"**。正确做法：

- 以 `data.binance.vision` 该 symbol 目录下最早文件为准
- 新币种持续上新，上线时间不断变化
- 参考量级仅用于评估，不能当精确时间用（见 §2）

## 6. Current Implementation Mapping

当前 binance 模块 SPEC 中与历史数据同步相关的 FR 映射 `[INFERRED]`：

| FR | 标题 | 与本策略的映射 |
| --- | --- | --- |
| FR-016 | Historical Backfill Planner | 对应 §2 公开行情回填策略——规划 symbol 上线时间 → 批量库下载 → WS 实时流衔接的完整回填路径。起始时间定义遵循 §4 建议 1。 |
| FR-026 | Checkpoint Recovery | 对应 §4 建议 3——断线重连时以上次成功处理的最后事件 `E`/`T` 为起始时间，决定 REST 补漏窗口，而非全量重拉。 |
| FR-027 | Multi-product Lifecycle | 对应 §2/§3 全局——不同产品线（spot/um_perp/cm_perp/options）的上线时间、REST 窗口、时间戳单位规则各不相同，需按产品线分别管理起始时间与回填策略。 |

> 本文档为 Reference 性质，不新增 FR 或修改既有 FR 定义，仅将分散在 report 与 SPEC 中的策略信息整合为单一参考来源。
