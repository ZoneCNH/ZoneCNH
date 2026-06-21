# contracts 规格

- Status: Docs Baseline Synced / Runtime Truth Verified
- Last-Updated: 2026-06-21
- Layer: 基座 · 跨域接口契约
- Source-of-Truth: `/home/contracts/pkg/contracts`
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `README.md`, `TRACEABILITY.md`, `ACCEPTANCE.md`, `IMPLEMENTATION-PLAN.md`, `tasks/`

> 本文档只描述当前 runtime 的公开契约面，不承诺具体传输、存储或业务实现。

## 1. 导出面概览

| 类别 | 当前符号 | 说明 |
| --- | --- | --- |
| 基础封装 | `Event`, `Command`, `Query` | 通用请求/响应/查询封装，按字段结构稳定导出。 |
| 标记接口 | `DTO`, `Port` | 用于区分数据对象与端口对象的 marker interface。 |
| 错误元数据 | `ErrorCode` | 提供 `Code`、`Domain`、`Severity`、`Retryable` 等字段。 |
| 行情快照 | `RegimeSnapshot` | 公开 `MarketState`、`MarketBias`、`TradePermission`、`FreshnessState`、`FiveDimScores`。 |
| 宏观快照 | `RegimeCard` | 公开 `MacroState`、`LGIPScore`。 |
| 决策卡片 | `DecisionCard` | 公开 `Action`、`ActionProfile`、`StrategyTemplate`、`PositionCaps`。 |
| 信号意图 | `SignalIntent` | 作为信号生成的最终意图载体。 |
| 端口 | `MarketDataProvider`, `MacroDataProvider`, `DecisionCardProvider`, `SignalFactoryProvider` | 提供最新值读取、订阅与信号生成能力。 |
| 摄入链路 | `MarketDataService`, `IngestRequest`, `IngestResult`, `IngestAck`, `IngestReject`, `RejectCode`, `AllRejectCodes()` | 统一的市场数据摄入契约。 |
| 兼容层 | `RegimeSnapshotEvent`, `RegimeCardEvent`, `DecisionCardEvent`, `MarketRegimePort`, `MacroRegimePort`, `RegimeEnginePort` | 旧名桥接到当前 runtime 符号。 |

## 2. 功能需求

### FR-001: 基础封装

`Event`、`Command`、`Query` 是当前的基础契约封装。

- `Event` 结构字段：`ID`、`Type`、`Source`、`Version`、`Data`
- `Command` 结构字段：`ID`、`Type`、`Target`、`Data`
- `Query` 结构字段：`ID`、`Type`、`Filter`

### FR-002: 标记接口与错误元数据

`DTO` 与 `Port` 只承担分类语义，不承载运行逻辑。

- `DTO` 暴露 `IsDTO() bool`
- `Port` 暴露 `IsPort() bool`
- `ErrorCode` 暴露 `Code`、`Domain`、`Severity`、`Retryable`

### FR-003: 行情与决策载体

当前 runtime 导出三类核心业务载体：

- `RegimeSnapshot`
- `RegimeCard`
- `DecisionCard`

这些类型分别承载市场状态、宏观状态与决策状态字段，不再使用旧的 `MarketEvent`、`MacroPoint`、`Bar`、`SignalEvent`、`OrderEvent`、`ExecutionEvent`、`PositionEvent`、`RiskEvent`、`AlternativeEvent` 命名族。

### FR-004: 信号意图

`SignalIntent` 是信号生成链路的输出意图对象。

- `SignalFactoryProvider.Generate(card DecisionCard, symbols []string) ([]SignalIntent, error)`
- 生成结果以决策卡片为输入，以符号列表为上下文

### FR-005: 数据端口

当前 runtime 端口以“最新值 + 订阅流”组合暴露。

- `MarketDataProvider.LatestRegimeSnapshot(ctx, symbol) (RegimeSnapshot, error)`
- `MarketDataProvider.SubscribeRegimeSnapshots(ctx, symbols) (<-chan RegimeSnapshot, error)`
- `MacroDataProvider.LatestRegimeCard(ctx) (RegimeCard, error)`
- `MacroDataProvider.SubscribeRegimeCards(ctx) (<-chan RegimeCard, error)`
- `DecisionCardProvider.LatestDecisionCard(ctx) (DecisionCard, error)`
- `DecisionCardProvider.SubscribeDecisionCards(ctx) (<-chan DecisionCard, error)`

### FR-006: 摄入契约

`MarketDataService.Ingest(in IngestRequest) (IngestResult, error)` 是当前摄入入口，签名是单次请求/响应，不是双向流。

- `IngestRequest` 字段：`RequestID`、`Source`、`ProductLine`、`InstrumentKey`、`EventType`、`EventTime`、`ReceivedAt`、`SchemaVersion`、`Payload`、`Sequence`、`OrderingKey`、`SourceMetadata`
- `IngestResult` 只携带一个结果分支：`Ack` 或 `Reject`
- `IngestAck` 字段：`RequestID`、`StreamID`、`AcceptedCount`、`DuplicateCount`、`Durable`
- `IngestReject` 字段：`RequestID`、`RejectCode`、`Reason`、`Retryable`
- `RejectCode` 的 canonical 集合由 `AllRejectCodes()` 给出，共 9 个：`RejectRetryable`、`RejectTerminalValidation`、`RejectTerminalConflict`、`RejectUnauthorized`、`RejectRateLimited`、`RejectServerUnavailable`、`RejectContractViolation`、`RejectQualityRejected`、`RejectOrderingViolation`
- `RejectUnsupportedChannel` 仍然导出，但不属于 canonical 集合

### FR-007: 兼容别名

当前 runtime 通过别名保留旧入口，避免下游一次性重命名。

| Alias | Target |
| --- | --- |
| `RegimeSnapshotEvent` | `RegimeSnapshot` |
| `RegimeCardEvent` | `RegimeCard` |
| `DecisionCardEvent` | `DecisionCard` |
| `MarketRegimePort` | `MarketDataProvider` |
| `MacroRegimePort` | `MacroDataProvider` |
| `RegimeEnginePort` | `DecisionCardProvider` |

### FR-008: 文档基线

`README.md`、`goal.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md` 与 `tasks/` 必须与当前 runtime 公开符号同步。

- 任何新增、删除或重命名的公开符号都必须同步更新这些文档
- 任何旧术语回流都视为文档回归

## 3. 行为约束

### BR-001: 契约归属

`contracts` 只定义共享契约，不实现业务逻辑、传输逻辑或 adapter 逻辑。

### BR-002: 不再使用 Topic 层

当前公开契约不包含 Topic 常量或 topic 命名族；旧的 topic 叙事不再进入文档主线。

### BR-003: 不再使用旧 API 名称

当前文档不得再出现以下旧式命名：

- `GetSnapshot`
- `GetHistory`
- `GetLatest`
- `Subscribe`
- `AlternativeDataProvider`
- `ErrInvalidSymbol`
- `stable period`
- `v1.0.1`

### BR-004: 依赖边界

`contracts` 仅依赖 stdlib 与 `module/FOUNDATION-DEPS.yaml` 允许的共享层，不向上游业务域回流依赖。

### BR-005: DTO 规则

任何参与序列化的 DTO 都必须保持导出字段与明确的 JSON tag 约定，不引入隐式命名变换。

### BR-006: Canonical RejectCode

`AllRejectCodes()` 是 canonical 列表，只返回 9 个代码：

`RejectRetryable`、`RejectTerminalValidation`、`RejectTerminalConflict`、`RejectUnauthorized`、`RejectRateLimited`、`RejectServerUnavailable`、`RejectContractViolation`、`RejectQualityRejected`、`RejectOrderingViolation`

### BR-007: 非 canonical 代码

`RejectUnsupportedChannel` 仍然可见，但它是兼容补充，不进入 canonical 列表。

### BR-008: 兼容层

兼容别名允许下游分阶段迁移，但不得被重新解释成新的独立语义。

### BR-009: 文档同步

所有契约文档必须保持同一组事实源，不允许 README、SPEC、TRACEABILITY、ACCEPTANCE、FEATURES、PLAN 与 task 文档彼此冲突。

### BR-010: 公开 API 变更治理

公开 rename/removal 视为破坏性变更，必须先完成兼容层与追溯文档更新，再进入发布决策。

## 4. 非功能需求

### NFR-001: 运行时验证

`/home/contracts` 需要保持可编译、可测试、可复验。

### NFR-002: 竞态安全

`go test ./... -race -count=1` 仍应通过。

### NFR-003: 静态检查

`go vet ./...` 与当前 lint 检查应保持干净。

### NFR-004: 文档可审计

文档更新必须能够通过 `git diff --check` 和 stale-term 搜索进行审计。

### NFR-005: 公开符号注释

runtime 公开符号应保留可读的 godoc。

### NFR-006: RejectCode 稳定性

canonical reject-code 集合保持 9 项，不随文档整理漂移。

### NFR-007: 不暴露传输实现

文档不得把 gRPC、Kafka、NATS、HTTP 或其他传输层实现写成契约本体。

### NFR-008: 不回流旧叙事

`stable period`、`v1.0.1`、旧方法名与旧 Topic 叙事不得回流到当前 docs baseline。

## 5. 非目标

- 不定义 transport adapter、broker、HTTP client 或 gRPC server
- 不恢复 Topic 常量层
- 不恢复旧方法名或旧 DTO 命名族
- 不把 release history 写成契约本体
- 不承载业务流程编排或状态机

## 6. 参考

- `/home/contracts/pkg/contracts/contracts.go`
- `/home/contracts/pkg/contracts/ports.go`
- `/home/contracts/pkg/contracts/regime_snapshot.go`
- `/home/contracts/pkg/contracts/regime_card.go`
- `/home/contracts/pkg/contracts/decision_card.go`
- `/home/contracts/pkg/contracts/signal_intent.go`
- `/home/contracts/pkg/contracts/ingestion.go`
- `/home/contracts/pkg/contracts/projections.go`
