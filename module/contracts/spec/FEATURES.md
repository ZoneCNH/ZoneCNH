# contracts 功能清单

- Status: Docs Baseline Synced / Feature Inventory Closed
- Last-Updated: 2026-06-30
- Layer: 基座 · 跨域接口契约
- Source-of-Truth: `/home/workspace/contracts/pkg/contracts`
- Related: `SPEC.md`, `TRACEABILITY.md`, `ACCEPTANCE.md`, `README.md`, `goal.md`, `IMPLEMENTATION-PLAN.md`, `tasks/`

> 本清单只记录当前公开导出面与边界约束，不保留旧 API 名称、旧分层命名、旧版本标记、重大改名故事或旧交易所接入叙事。

## 1. 当前导出面

| ID | 组件 | runtime 锚点 | 说明 |
| --- | --- | --- | --- |
| CORE-001 | `Event`, `Command`, `Query` | `contracts.go` | 统一跨域消息信封，字段与 JSON tag 稳定 |
| CORE-002 | `DTO`, `Port`, `ErrorCode` | `contracts.go` | 标记接口与错误元数据注册 |
| CORE-003 | `RegimeSnapshot`, `RegimeCard`, `DecisionCard` | `regime_snapshot.go`, `regime_card.go`, `decision_card.go` | 市场态势、宏观态势与决策卡载体 |
| CORE-004 | `SignalIntent` | `signal_intent.go` | 供 `signal_factory` 生成的下游意图载体 |
| CORE-005 | `MarketDataProvider`, `MacroDataProvider`, `DecisionCardProvider`, `SignalFactoryProvider` | `ports.go` | 最新态势查询、订阅和信号生成端口 |
| CORE-006 | `MarketDataService`, `IngestRequest`, `IngestResult`, `IngestAck`, `IngestReject`, `RejectCode`, `AllRejectCodes()` | `ingestion.go` | 单请求 / 单结果摄入契约与 10 个 canonical 拒绝码 |
| CORE-007 | `RegimeSnapshotEvent`, `RegimeCardEvent`, `DecisionCardEvent`, `MarketRegimePort`, `MacroRegimePort`, `RegimeEnginePort` | `projections.go` | 迁移期兼容投影与旧命名别名 |
| CORE-008 | 文档基线同步 | `README.md`, `SPEC.md`, `TRACEABILITY.md`, `ACCEPTANCE.md`, `FEATURES.md`, `IMPLEMENTATION-PLAN.md`, `tasks/` | 只保留当前 runtime truth 的文档投影 |

## 2. 边界与非目标

| 项目 | 约束 |
| --- | --- |
| 模块职责 | 跨域契约、错误元数据、兼容投影与验收文档 |
| 运行时代码目录 | `/home/workspace/contracts` |
| 文档目录 | `module/contracts` |
| Go 基线 | 1.23 |
| 允许依赖 | stdlib 与 `module/FOUNDATION-DEPS.yaml` 允许的共享层 |
| 禁止依赖 | 业务层、传输实现、未授权基座模块 |
| 非目标 | HTTP/gRPC/Kafka/NATS 实现、旧分层命名、旧 API 名称、重大改名故事、双向流 ingestion |

## 3. 当前一致性规则

- `MarketDataService.Ingest(...)` 是单次请求 / 单次结果契约，不是双向流。
- `AllRejectCodes()` 只返回 10 个 canonical code；`RejectUnsupportedChannel` 仍是导出常量，并进入 canonical 列表。
- 兼容别名只承担迁移和过渡，不引入新语义。
- 任意新增、删除或重命名公开符号，必须先更新 `SPEC.md`，再同步 `TRACEABILITY.md`、`ACCEPTANCE.md` 与 `tasks/`。

## 4. 相关模块

- `market_data`
- `macro_data`
- `regime_engine`
- `signal_factory`
- `risk_engine`
- `order_engine`
- `module/binance`
