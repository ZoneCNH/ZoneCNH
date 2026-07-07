# Sequence Continuity Strategy

> 状态：Reference
> 来源：report/binance/20260704.md + ADR-003
> Last-Updated: 2026-07-06

## 1. Overview

Binance 各事件流（行情公开流 / 用户私有流）对序号连续性的要求差异极大。本文件按「在线时怎么发现丢包」与「丢了之后怎么恢复」两个维度，把所有事件类型归入四类：

| 分类 | 含义 | 典型事件 |
| ---- | ---- | -------- |
| **强制** | 唯一必须做序号连续性校验的场景；丢了会导致本地状态永久错误且不会自愈，必须整体重建 | `depthUpdate` |
| **间接必须** | 没有全局递增序号，但可通过累计量交叉校验感知丢包；不一致时需 REST 补齐 | `executionReport` / `ORDER_TRADE_UPDATE`（z/l 累计量） |
| **自愈** | 每条都是绝对值或全量快照，丢一条不影响下一条正确性；断线后需 REST 全量对账兜底 | kline、bookTicker、24hrTicker、markPriceUpdate、ACCOUNT_UPDATE 等 |
| **不适用** | 连接生命周期信号或纯提示类，触发的是「重建连接 + 全量对账」而非去重/续接 | `listenKeyExpired`、`eventStreamTerminated`、`MARGIN_CALL` |

> **证据标签**：本文件中所有分类与策略来自 `report/binance/20260704.md` 的分析结论，标注为 `[INFERRED]`（工程推断，非币安官方定义）；"幂等键维度"是按 payload 字段推出的工程建议，不是币安官方概念 `[INFERRED]`。depthUpdate 强制校验属 `[KNOWN]`（币安官方文档明确定义 U/u/pu 校验规则）。

## 2. Market Data Stream Strategy

> 下表为行情数据流（公开流）的序号连续性校验策略，来源 `report/binance/20260704.md` §一（第二张表）。

| event_type | 序号连续性校验 | 说明 |
| ---------- | -------------- | ---- |
| aggTrade | 可选/仅监控 | `a`（聚合成交 ID）理论单调递增，可用来发现丢包做告警，但没有官方快照可对齐，丢了就是丢了，不影响后续消息正确性 |
| trade / blockTrade | 可选/仅监控 | 用 `t`（成交 ID） |
| kline | 否，自愈 | 每次推送都是该根 K 线的**当前完整状态**（`o/h/l/c/v` 是引擎重新计算的，不是增量叠加），丢一条下一条依然正确 |
| depthUpdate | **强制** | 唯一必须做的。spot 用 `U/u`，futures(UM/CM) 多一个 `pu`（等于上一条的 `u`）。丢了会导致本地订单簿永久错误且不会自己恢复 |
| bookTicker | 否，自愈 | 每条都是当前最优买卖价的完整状态，用 `u` 只是用来丢弃乱序的旧包，不是拼接依据 |
| 24hrTicker/MiniTicker/avgPrice | 否，自愈 | 滚动窗口统计，每条都是重新计算的绝对值 |
| markPriceUpdate | 否，自愈 | 绝对值推送 |
| forceOrder | 可选/仅监控 | 纯信息流，无状态需要拼接；如需完整审计只能靠 REST `forceOrders` 兜底，没有序号可对 |
| compositeIndex / assetIndex / contractInfo / openInterest / referencePrice | 否，自愈 | 都是绝对值/全量元数据快照 |

## 3. User Data Stream Strategy (Future Reference)

> **当前 SPEC §3 排除用户数据流（user data stream）的落库实现，此处仅作未来扩展参考。**
>
> 下表为用户数据流（私有流，需 listenKey/API Key）的序号连续性校验策略，来源 `report/binance/20260704.md` §二（第二张表）。标注为 `[INFERRED]`（工程推断）。

| event_type | 序号连续性校验 | 说明 |
| ---------- | -------------- | ---- |
| executionReport / ORDER_TRADE_UPDATE | **间接必须**（累计量交叉校验） | 没有全局递增序号，但订单内有 `z`（累计成交量）和 `l`（本次成交量）。校验 `新z == 旧z + l`；不等就说明中间漏了一条成交，需要用 REST 按订单查历史成交补齐 |
| TRADE_LITE | 间接（配合 ORDER_TRADE_UPDATE） | 字段被精简，没有 `z`，不能单独做累计校验；把它当"低延迟提示"，权威状态仍以 ORDER_TRADE_UPDATE 的 `z/l` 为准 |
| ACCOUNT_UPDATE / BALANCE_POSITION_UPDATE | 否，自愈（但断线需全量对账） | 每条给的是持仓/余额的**绝对值**（`pa`、`wb` 等），丢一条不影响下一条准确性；但断线期间发生的变化会被"跳过"，重连后必须调 REST account 接口拉一次全量，再从新连接的事件继续叠加 |
| outboundAccountPosition | **较特殊，需注意** | 虽有 `u`（最后更新时间），但 payload 只包含"本次事件可能变动到的资产"，不是全账户快照。丢一条＝该资产的余额永久性地在你本地是旧值，直到该资产下次变动。**强烈建议**：重连时/定期用 REST `/api/v3/account` 做一次全量核对 |
| balanceUpdate / externalLockUpdate | 否，自愈 | 划转类事件本身是增量（`d` 字段是变动量），但业务上通常配合定期全量对账即可，没有专门的序号 |
| listStatus | 否 | 按 `OrderListId` 独立管理，状态机自身有终态判断 |
| MARGIN_CALL | 否，仅提示 | 官方原话是"仅作为风险提示，不建议用于交易策略"，不需要也不适合做去重/续接，实盘风控应该主要依赖定期轮询 `positionRisk`，而不是完全依赖这个推送 |
| ACCOUNT_CONFIG_UPDATE / STRATEGY_UPDATE / GRID_UPDATE / ALGO_UPDATE / CONDITIONAL_ORDER_TRADE_UPDATE | 否，自愈（但断线需全量对账） | 都是按 ID（策略ID/算法ID）给状态机式的"当前状态"，不是增量叠加；断线重连后建议对该批未完结的策略/算法单做一次 REST 查询核对 |
| listenKeyExpired / eventStreamTerminated | 不适用 | 连接生命周期信号本身，触发的动作是"重新建连 + 全量对账"，而不是去重 |

## 4. depthUpdate Reconstruction Algorithm

> 下文为 `report/binance/20260704.md` §三中的 8 步 depthUpdate 订单簿重建流程原文。这是 ADR-003「未来升级路径」的技术参考，**当前 runtime 未实现此算法**（见 §6）。来源标注 `[KNOWN]`（币安官方文档定义的 diff depth 对齐算法）。

```
1. 建立 WS 连接，订阅 <symbol>@depth，开始缓冲收到的事件
2. 记录缓冲的第一条事件的 U
3. 调 REST /depth?symbol=X&limit=5000 拿快照，记 lastUpdateId
4. 若 lastUpdateId < 步骤2的 U，说明快照太旧，回到步骤3重新拉
5. 丢弃缓冲事件中 u <= lastUpdateId 的部分
6. 现存的第一条事件应满足 U <= lastUpdateId+1 <= u，从它开始应用到本地订单簿
7. 此后每条新事件：
   - spot: 校验 新事件.U == 上一条.u + 1
   - futures(UM/CM): 校验 新事件.pu == 上一条.u
8. 校验失败（有 gap）→ 直接回到步骤1重新拉快照，不要尝试"跳过"或"插值"
```

**关键点**：步骤 8 明确禁止"跳过"或"插值"——gap 出现时唯一的正确动作是整体重建（回到步骤 1），任何"近似恢复"都会导致本地订单簿与币安服务端永久不一致。

**与 ADR-003 的关系**：ADR-003（`ADR-003-order-book-rebuild-exclusion.md`）的「未来升级路径」第 1 步「client 侧增加 order book manager（维护本地 book 状态 + REST snapshot + 增量 diff）」即对应本节算法。当前 v0.2.0 选择快照级落库而非维护本地 order book 状态机，因此本算法为**未实施的参考实现**。

## 5. Order Trade Cumulative Cross-Check

> **当前 SPEC §3 排除用户数据流（user data stream）的落库实现，此处仅作未来扩展参考。**
>
> 下文为 `report/binance/20260704.md` §三中的 executionReport / ORDER_TRADE_UPDATE z/l 累计量交叉校验伪代码原文。来源标注 `[INFERRED]`（基于币安 payload 字段语义的工程推断）。

```
维护 per-orderId 的 last_z（上次看到的累计成交量）
收到新事件时：
  if 执行类型 x/executionType == 'TRADE'（有成交）:
      if 新事件.z != last_z + 新事件.l:
          触发对账：REST 查该订单的 myTrades，补齐中间丢失的成交
      last_z = 新事件.z
  更新本地订单状态机（X/orderStatus）
```

**适用事件**：spot 的 `executionReport`（字段 `z`/`l`）与 futures 的 `ORDER_TRADE_UPDATE`（字段 `o.z`/`o.l`）通用。`TRADE_LITE` 因字段精简无 `z`，不能单独做累计校验，权威状态仍以 `ORDER_TRADE_UPDATE` 为准。

**校验语义**：`z` 是订单的累计已成交量（cumulative filled quantity），`l` 是本次事件的成交增量（last filled qty）。每条 TRADE 事件应满足「新累计 = 旧累计 + 本次增量」，不等即说明中间漏了成交事件，需用 REST `myTrades` 按订单补齐。

**置信度**：`[INFERRED]` — 字段语义属 `[KNOWN]`（币安官方文档定义），"用累计量交叉校验做丢包检测"是工程推断 `[INFERRED]`。

## 6. Current Implementation Status

当前 runtime（`/home/workspace/binance@2efc44a`）的序号连续性相关实现状态：

| 维度 | 当前实现 | 决策依据 |
| ---- | -------- | -------- |
| depth 处理 | **快照级落库**，不维护本地 order book 状态机，不做增量 diff 重放 | ADR-003 |
| depth 缺口检测 | `updateId` 跳跃 → 触发快照刷新（`GET /api/v3/depth`），不生成 gap replay job | FR-017（v3.9.0 spec） |
| depthUpdate 8 步重建算法 | **未实现**（ADR-003 标注为 v4.0.0 MAJOR 升级路径） | ADR-003 §未来升级路径 |
| 用户数据流落库 | **未实现**（SPEC §3 排除 user data stream） | SPEC §3 |
| 订单成交累计量交叉校验 | **未实现**（依赖用户数据流落库，当前排除） | SPEC §3 |

**ADR-003 交叉引用**：

- ADR-003 决策：当前版本（v0.2.0）排除 order book rebuild 状态机，depth 数据以快照形式落库。
- ADR-003 未来升级路径：若下游需完整 order book 序列（做市策略、微观结构分析），升级路径为 client 侧 order book manager + 新增 FR 定义 rebuild 状态机 + 存储层扩展 + MAJOR 版本升级（v4.0.0）。
- 本文件 §4 的 8 步重建算法即为该升级路径的技术参考实现。
- ADR-003 路径：`module/binance/design/ADR-003-order-book-rebuild-exclusion.md`

**与 FR-017 的关系**：FR-017（Gap Detection and Replay）的 depth 策略在 v3.9.0 spec 中定义为「updateId 序列跳跃 → 快照刷新」，而非 replay job。本文件 §4 的完整重建算法是 FR-017 depth 策略的"完整版"——当前 runtime 只做"检测到 gap 就刷新快照"，不做"维护本地 book + 增量 diff 重放"。

---

> **证据标签汇总**：
> - `[KNOWN]`：depthUpdate U/u/pu 校验规则、币安官方文档明确定义的字段语义（z/l cumulative filled quantity）
> - `[INFERRED]`：四类分类框架、幂等键维度建议、累计量交叉校验作为丢包检测手段、"自愈"判断（均来自 `report/binance/20260704.md` 工程推断，非币安官方定义）
> - 置信度：`MED` — 分类逻辑基于币安官方字段语义推断，工程上自洽，但币安未官方背书"序号连续性校验分类"这一概念框架
