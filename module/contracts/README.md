# contracts

`pkg/contracts` 的文档索引，记录当前运行时导出的契约面、兼容投影与边界约束。
当前真相以 `/home/contracts/pkg/contracts` 为准；本文档只描述现状，不保留旧版分层叙事。

## 当前导出面

| 层级 | 导出 | 作用 |
| --- | --- | --- |
| 基础信封 | `Event`, `Command`, `Query` | 统一跨域消息包，字段名与 JSON tag 稳定 |
| 标记接口 | `DTO`, `Port` | 标识数据对象与端口对象 |
| 错误注册 | `ErrorCode` | 记录 `code` / `domain` / `severity` / `retryable` |
| P0 市场态势 | `RegimeSnapshot` | 单标的市场态势快照 |
| P0 宏观态势 | `RegimeCard` | 宏观 regime card |
| P0 决策卡 | `DecisionCard` | `regime_engine` 的联合决策输出 |
| P1 信号意图 | `SignalIntent` | `signal_factory` 面向 `risk_engine` / `order_engine` 的输出 |
| 供应端口 | `MarketDataProvider`, `MacroDataProvider`, `DecisionCardProvider`, `SignalFactoryProvider` | 最新值查询、订阅流或意图生成 |
| 采集 wire contract | `MarketDataService`, `IngestRequest`, `IngestResult`, `IngestAck`, `IngestReject`, `RejectCode` | 适配器到 contracts 的单请求/单结果接入面 |
| 兼容投影 | `RegimeSnapshotEvent`, `RegimeCardEvent`, `DecisionCardEvent`, `MarketRegimePort`, `MacroRegimePort`, `RegimeEnginePort` | 过渡期别名，保留旧引用稳定性 |

## 边界

- 该包只定义契约，不实现 HTTP/gRPC/Kafka/NATS。
- 当前 ingestion 形态是单请求/单结果 `Ingest`，不是双向流。
- `AllRejectCodes()` 返回 9 个 canonical code；`RejectUnsupportedChannel` 仍是导出常量，但不在 canonical 列表中。
- 任何新增字段或方法都必须同步更新 `SPEC.md`、`TRACEABILITY.md`、`ACCEPTANCE.md` 和任务文档。

## 关联模块

- `market_data`
- `macro_data`
- `regime_engine`
- `signal_factory`
- `risk_engine`
- `order_engine`
- `module/binance`
