# force_order 事件流设计

> 状态：Proposed / runtime opt-in scaffold，postponed release
> 日期：2026-07-10
> 关联：`module/binance/todo.md` §6、`design/EVENT-TYPE-MAPPING.md` §2.2/§3

## 1. 结论

`forceOrder` 必须作为独立的 `force_order` 事件流设计，禁止映射为 `trade`、`ticker` 或 `book_ticker`。[KNOWN, HIGH]

Binance Futures 官方市场流同时支持按 symbol 的 `<symbol>@forceOrder` 与全市场 `!forceOrder@arr`；事件包含强平订单快照，但不提供可当作成交事件的稳定 `tradeId`/`orderId`。[KNOWN, HIGH](https://developers.binance.com/legacy-docs/derivatives/usds-margined-futures/websocket-market-streams/All-Market-Liquidation-Order-Streams)

本文件完成“单独设计”任务。runtime 已有隔离的 parser/mapper/storage scaffold 与显式 allowlist 路径，但不默认订阅、不纳入普通 trade 统计；在独立 live gate 与 release owner 批准前，不宣称该事件已达到发布能力。[FRAME, HIGH]

## 2. 边界与语义

| 维度 | 规则 |
| --- | --- |
| canonical | `force_order` |
| 原生来源 | `forceOrder` |
| 事件类别 | 风险事件快照；不是普通成交 |
| 采集范围 | UM/CM 公共 market stream；spot/options 不宣称支持 |
| 全局流 | `!forceOrder@arr` 的 payload 必须逐条展开，保留原始 event time |
| symbol 流 | `<symbol>@forceOrder` 的 symbol 以内层订单 `o.s` 为准，并校验与订阅 symbol 一致 |
| 下游策略 | 不进入普通 trade 成交量、VWAP、盘口或 ticker 聚合 |
| 发布 | 使用 `binance.market.{product_line}.force_order.v1` 的 opt-in scaffold，须待独立 FR/AC/TC、live evidence 与 release owner 批准后作为发布能力启用 |

## 3. 最小字段契约

```json
{
  "event_type": "force_order",
  "event_time": "2026-07-10T00:00:00Z",
  "symbol": "BTCUSDT",
  "order": {
    "pair": "BTCUSDT",
    "side": "SELL",
    "order_type": "LIMIT",
    "time_in_force": "IOC",
    "original_qty": "1",
    "price": "60000",
    "average_price": "60001",
    "status": "FILLED",
    "last_filled_qty": "1",
    "filled_qty": "1",
    "trade_time": 1783641600000
  }
}
```

字段全部按字符串保留 Binance 数值精度；缺失的稳定订单 ID 不得由本地时间伪造为权威 ID。[INFERRED, HIGH]

## 4. 幂等、丢失与重放

1. 幂等键候选为 `venue/product_line/symbol/event_time/order payload digest`；同一 1000ms 窗口内不同订单 payload 不得合并。[INFERRED, MED]
2. `event_time` 相同不代表同一事件；重放必须依赖完整 payload digest。[INFERRED, HIGH]
3. 全市场流展开后，必须在展开前记录原始 envelope，展开失败不得静默丢弃。[INFERRED, HIGH]
4. 该流是“窗口内最新强平快照”，缺失事件不能推导为“没有强平”。[KNOWN, HIGH]

## 5. 激活门槛

进入 runtime 前必须新增独立 FR/AC/TC、schema、NATS/Kafka/TDengine/Redis/API 路径和 live capture；至少通过：

- symbol 与全局流 payload 的 parser/fixture 测试；
- 重复 payload、同时间不同 payload、全局展开失败的幂等测试；
- server allowlist、storage stable、history/reconcile 和 retention 测试；
- 不污染 `trade` 统计的 contract test；
- 真实 UM/CM market stream capture 与 release evidence。

在上述门槛满足前，`force_order` 保持 opt-in/postponed release；显式 parser/storage scaffold 不构成生产发布证据。[COMPUTED, HIGH]

[RULES I BROKE]：无
