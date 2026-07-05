# contracts 规格

- Status: Approved (Docs Baseline Synced / Runtime Truth Verified)
- Spec-Version: v1.2.0
- Last-Updated: 2026-06-30
- Owner: ZoneCNH
- Layer: 基座 · 跨域接口契约
- Fast-Track: true
- Source-of-Truth: `/home/workspace/contracts/pkg/contracts`
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `README.md`, `TRACEABILITY.md`, `ACCEPTANCE.md`, `IMPLEMENTATION-PLAN.md`, `tasks/`

> 本文档只描述当前 runtime 的公开契约面，不承诺具体传输、存储或业务实现。
> 本模块为纯接口契约模块（无运行时依赖，暴露 DTO/Port marker 等公开类型），适用快速通道。

## 1. 摘要

contracts 是 ZoneCNH 跨域接口契约模块，定义 `Event`/`Command`/`Query` 基础封装、`DTO`/`Port` 标记接口、`ErrorCode` 错误元数据、`RegimeSnapshot`/`RegimeCard`/`DecisionCard` 行情/决策卡片、`SignalIntent` 下单意图，以及 provider port 和 ingestion wire contract。

## 2. 问题与背景

跨域模块（market_data / factor_engine / riskx / orderx 等）需要共享的类型定义和接口契约，但不得产生运行时依赖。contracts 作为纯接口模块提供编译时类型安全。

## 3. 目标

1. 提供跨域共享的公共类型定义
2. 定义 provider/consumer 接口契约
3. 保持零运行时依赖（stdlib only）
4. 编译时类型检查替代运行时耦合

## 4. 非目标

- 不包含任何业务逻辑实现
- 不定义传输协议或存储格式
- 不包含可执行入口（无 main / cmd）
- 不依赖任何 FoundationX 模块
- 不定义 transport adapter、broker、HTTP client 或 gRPC server
- 不恢复 Topic 常量层
- 不恢复旧方法名或旧 DTO 命名族
- 不把 release history 写成契约本体
- 不承载业务流程编排或状态机

## 5. 导出面概览

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
| 告警契约 | `AlertEvent`, `AlertRule`, `Severity`, `AlertStatus`, `AlertSink`, `AlertRuleStore` | alertx 告警引擎的跨域输入面：告警事件、声明式规则、严重等级、端口订阅。来源 `pkg/contracts/alert.go`（待 v1.6.0 tag）。 |

## 6. 功能需求

> FR 全集 FR-001..FR-009 详见 `TRACEABILITY.md`。本节以稳定契约格式描述。

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

> 字段集自 ADR-007（`module/binance/design/ADR-007-wire-to-contracts-migration.md`）富化，吸收原 binance `internal/wire` 的跨域语义字段。InstrumentKey 保持 `json.RawMessage`，由各 ingestor 在 boundary 序列化（见 BR-011）。本次为 breaking change（字段补入 + Payload 类型统一 + 命名对齐），版本 bump 由 release 流程裁定。

- `IngestRequest` 字段：`RequestID`、`Source`、`ProductLine`、`Symbol`、`InstrumentKey`（`json.RawMessage`）、`EventType`、`EventTime`、`ReceivedAt`、`SchemaVersion`、`Payload`（`json.RawMessage`）、`PayloadHash`、`Sequence`、`OrderingKey`、`SourceMetadata`、`TraceContext`、`Quality`
- `IngestResult` 只携带一个结果分支：`Ack` 或 `Reject`
- `IngestAck` 字段：`StreamID`、`AcceptedKey`、`AcceptedCount`、`DuplicateCount`、`Durable`、`AcceptedAt`、`Quality`、`Gap`、`SLA`
- `IngestReject` 字段：`RequestID`、`RejectCode`、`Reason`、`Retryable`
- 跨域语义辅助类型（contracts 导出）：`TraceContext`（W3C traceparent/tracestate/baggage）、`QualityVerdict`（cleansing verdict）、`GapStatus`（event-time gap）、`SLAStatus`（freshness/processing latency）
- `RejectCode` 的 canonical 集合由 `AllRejectCodes()` 给出，共 10 个：`RejectRetryable`、`RejectTerminalValidation`、`RejectTerminalConflict`、`RejectUnauthorized`、`RejectRateLimited`、`RejectServerUnavailable`、`RejectContractViolation`、`RejectQualityRejected`、`RejectOrderingViolation`、`RejectUnsupportedChannel`
- `RejectUnsupportedChannel` 仍然导出，并且属于 canonical 集合
- 模块私有拒绝码（如 binance `BNC-001..019`）不得进入 canonical 集合；各 ingestor 在 boundary 维护私有码→canonical 码映射（见 BR-011）

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

### FR-009: 告警契约

`AlertEvent`、`AlertRule`、`Severity`、`AlertStatus`、`AlertSink`、`AlertRuleStore` 是 alertx 告警引擎的跨域稳定契约面，定义在 `pkg/contracts/alert.go`。

- `AlertEvent`：告警事件载体（ID / Source / Severity / Status / Message / Context / FiredAt / ResolvedAt / TraceID / DedupKey）。`ResolvedAt` 用 `*time.Time` 指针确保未解决告警的 JSON `omitempty` 正确省略。
- `AlertRule`：声明式规则契约（ID / Name / Source / Severity / Condition / DedupKey / SuppressWindow / Channels / Enabled）。`Condition` 是 alertx 规则 DSL 的不透明表达式串，contracts 不持有解析逻辑。
- `Severity`：三态常量 `critical` / `warning` / `info`，映射 `docs/goal/rsi-standard/23` 的 I4-I5 / I2-I3 / I0-I1 事件分级。
- `AlertStatus`：四态生命周期 `firing` / `pending` / `resolved` / `suppressed`。
- `AlertSink` / `AlertRuleStore`：P1 Port 接口，由 alertx 实现；下游可经 `SubscribeAlerts` 订阅告警流。

> 设计来源：`module/alertx/ADR-001-foundations.md`（双订阅 + YAML DSL + v1.0.0 目标）。`Severity` 常量值是稳定字符串，变更属破坏性变更（须走 BR-010 兼容层流程）。

## 7. 行为约束

> BR 全集 BR-001..BR-010 详见 `TRACEABILITY.md`。

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

`AllRejectCodes()` 是 canonical 列表，只返回 10 个代码：

`RejectRetryable`、`RejectTerminalValidation`、`RejectTerminalConflict`、`RejectUnauthorized`、`RejectRateLimited`、`RejectServerUnavailable`、`RejectContractViolation`、`RejectQualityRejected`、`RejectOrderingViolation`、`RejectUnsupportedChannel`

### BR-007: RejectUnsupportedChannel 导出

`RejectUnsupportedChannel` 仍然可见，并且属于 canonical 列表。

### BR-008: 兼容层

兼容别名允许下游分阶段迁移，但不得被重新解释成新的独立语义。

### BR-009: 文档同步

所有契约文档必须保持同一组事实源，不允许 README、SPEC、TRACEABILITY、ACCEPTANCE、FEATURES、PLAN 与 task 文档彼此冲突。

### BR-010: 公开 API 变更治理

公开 rename/removal 视为破坏性变更，必须先完成兼容层与追溯文档更新，再进入发布决策。

### BR-011: InstrumentKey 序列化边界

`IngestRequest.InstrumentKey` 保持 `json.RawMessage`，contracts 不持有任何强类型 InstrumentKey（避免经 L2.5 层污染零依赖边界）。各 ingestor 在自身 boundary 包内维护 `domainmarket.InstrumentKey ↔ json.RawMessage` 序列化与反序列化，类型安全在 ingestor 内部保留。模块私有拒绝码（如 BNC-xxx）同样不得进入 canonical，由 ingestor boundary 维护私有码→canonical 码映射。

## 8. 非功能需求

### NFR-001: 运行时验证

`/home/workspace/contracts` 需要保持可编译、可测试、可复验。

### NFR-002: 竞态安全

`go test ./... -race -count=1` 仍应通过。

### NFR-003: 静态检查

`go vet ./...` 与当前 lint 检查应保持干净。

### NFR-004: 文档可审计

文档更新必须能够通过 `git diff --check` 和 stale-term 搜索进行审计。

### NFR-005: 公开符号注释

runtime 公开符号应保留可读的 godoc。

### NFR-006: RejectCode 稳定性

canonical reject-code 集合保持 10 项，不随文档整理漂移。

### NFR-007: 不暴露传输实现

文档不得把 gRPC、Kafka、NATS、HTTP 或其他传输层实现写成契约本体。

### NFR-008: 不回流旧叙事

`stable period`、`v1.0.1`、旧方法名与旧 Topic 叙事不得回流到当前 docs baseline。

## 9. 验收标准（Acceptance Criteria Registry）

> 验收口径：本 Registry 锚定到 §6 功能需求 与 §7 行为约束，每条 AC 必须能由 `/home/workspace/contracts/pkg/contracts/` 的 runtime 符号检查或单元测试直接验证。`Status` 与 §0 Metadata 的 `Status: Docs Baseline Synced / Runtime Truth Verified` 对齐。

| AC ID      | FR/BR Ref      | Criterion                                                                                                       | Verification                                                                 | Status   |
| ---------- | -------------- | --------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | -------- |
| AC-CTR-001 | FR-001         | `Event` / `Command` / `Query` 导出且字段结构匹配 §6.FR-001 列表（Event=ID/Type/Source/Version/Data 等）          | `go doc github.com/ZoneCNH/contracts.{Event,Command,Query}` + 字段断言       | Verified |
| AC-CTR-002 | FR-002         | `DTO` / `Port` marker interface 暴露 `IsDTO()` / `IsPort()`；`ErrorCode` 暴露 `Code/Domain/Severity/Retryable` | runtime 包 `pkg/contracts/contracts.go` go vet + 单元测试断言                | Verified |
| AC-CTR-003 | FR-003         | `RegimeSnapshot` / `RegimeCard` / `DecisionCard` 三类业务载体在 runtime 中导出，且字段对齐 §6.FR-003           | `pkg/contracts/regime_snapshot.go` / `regime_card.go` / `decision_card.go` 导出符号检查 | Verified |
| AC-CTR-004 | FR-004         | `SignalIntent` 导出；`SignalFactoryProvider.Generate(card, symbols) ([]SignalIntent, error)` 签名稳定           | `pkg/contracts/signal_intent.go` + `ports.go` 接口签名断言                   | Verified |
| AC-CTR-005 | FR-005         | 四个 Provider 端口（MarketDataProvider/MacroDataProvider/DecisionCardProvider/SignalFactoryProvider）暴露 `Latest*` 与 `Subscribe*` 方法 | `pkg/contracts/ports.go` go doc + 接口实现断言                               | Verified |
| AC-CTR-006 | FR-006, BR-006, BR-007 | `MarketDataService.Ingest(IngestRequest) (IngestResult, error)` 为单次请求/响应；`AllRejectCodes()` 返回 10 项 canonical 集合，包含 `RejectUnsupportedChannel` | `pkg/contracts/ingestion.go` + 测试 `len(AllRejectCodes()) == 10` + 集合断言 | Verified |
| AC-CTR-007 | FR-007, BR-008 | 6 个兼容别名（RegimeSnapshotEvent / RegimeCardEvent / DecisionCardEvent / MarketRegimePort / MacroRegimePort / RegimeEnginePort）保留并指向当前 runtime 符号 | `pkg/contracts/projections.go` go doc + alias target 断言                    | Verified |
| AC-CTR-008 | FR-008, BR-009 | README / goal / TRACEABILITY / ACCEPTANCE / FEATURES / IMPLEMENTATION-PLAN / tasks/ 与 runtime 公开符号同步     | stale-term grep + `git diff --check` + docs 引用扫描                         | Verified |
| AC-CTR-009 | BR-001, BR-002, BR-003 | 文档与 runtime 不出现 `GetSnapshot` / `GetHistory` / `GetLatest` / `Subscribe` / `AlternativeDataProvider` / `ErrInvalidSymbol` / `stable period` / `v1.0.1` 等旧叙事；不包含 Topic 常量层 | stale-term grep 全仓零命中                                                   | Verified |
| AC-CTR-010 | BR-004, BR-005 | runtime 仅依赖 stdlib 与 `module/FOUNDATION-DEPS.yaml` 允许的共享层；DTO 字段保留 JSON tag 且无隐式命名变换    | `go list -m all` 依赖扫描 + DTO JSON marshal/unmarshal round-trip 测试       | Verified |
| AC-CTR-011 | BR-006, BR-007, NFR-006 | canonical reject-code 集合在版本演进中保持 10 项不漂移；新增/删除需走 BR-010 治理流程                      | snapshot test：固定 `AllRejectCodes()` golden 列表                           | Verified |
| AC-CTR-012 | BR-010         | 公开 rename/removal 必须先完成兼容层与追溯文档更新，再进入发布决策；任何破坏性变更需有 alias 过渡            | 治理 checklist + PR template；alias 出现率审计                               | Verified |
| AC-CTR-013 | NFR-001, NFR-002, NFR-003 | `/home/workspace/contracts` 通过 `go build ./...` / `go test ./... -race -count=1` / `go vet ./...` / lint 全部 ✅ | CI gate (foundation-release.yml + audit-status)                              | Verified |
| AC-CTR-014 | NFR-007, NFR-008 | 文档不把 gRPC / Kafka / NATS / HTTP 写成契约本体；`stable period` / `v1.0.1` / 旧方法名 / 旧 Topic 叙事不回流 | docs grep 扫描零命中                                                          | Verified |

> Coverage check：14 条 AC 覆盖 9 条 FR + 10 条 BR + 8 条 NFR；FR-001..FR-009 每条至少一个 AC 锚点；BR-001..BR-010 全部映射；NFR-001..NFR-008 通过 AC-CTR-013/014 与 NFR-006 通过 AC-CTR-011 关联。

> 基线 AC 摘要（Fast-Track: true）：AC-001 (FR-001 Event/Command/Query 编译通过且字段稳定)、AC-002 (FR-002 DTO/Port marker 通过编译时类型检查)、AC-003 (FR-003 ErrorCode.Code/Domain/Severity/Retryable 字段可访问)、AC-004 (FR-004 RegimeSnapshot 五维评分字段完整)、AC-005 (FR-005 DataProvider/MarketDataProvider 接口可编译)、AC-006 (FR-006 SignalIntent 含 Action/Symbol/Quantity 必填字段)、AC-007 (FR-007 Ingestion wire contract 含 Topic/Key/Version)、AC-008 (FR-008 Alert contract 含 AlertID/Severity/Message)、AC-009 (BR-001 ErrorCode.Retryable 为 true 时调用方可重试)、AC-010 (BR-002 DecisionCard.Action 不允许 INVALID 状态)。完整 AC/TC 追溯矩阵见 `TRACEABILITY.md`。

---

## 10. 参考

- `/home/workspace/contracts/pkg/contracts/contracts.go`
- `/home/workspace/contracts/pkg/contracts/ports.go`
- `/home/workspace/contracts/pkg/contracts/regime_snapshot.go`
- `/home/workspace/contracts/pkg/contracts/regime_card.go`
- `/home/workspace/contracts/pkg/contracts/decision_card.go`
- `/home/workspace/contracts/pkg/contracts/signal_intent.go`
- `/home/workspace/contracts/pkg/contracts/ingestion.go`
- `/home/workspace/contracts/pkg/contracts/projections.go`

---

## 11. 边界情况

1. **空输入**：`Decode()` 接收空 `[]byte` 时返回 `ErrInvalidEncoding`，不 panic
2. **并发读写**：DTO 为值类型不可变，并发安全由调用方保证
3. **版本不匹配**：`RegimeSnapshot.Version` 与 consumer 期望版本不一致时，consumer 应降级处理
4. **超大 payload**：`Event.Payload` 超过 10MB 时，调用方应在传输层分片
5. **接口演进**：新增 marker interface 方法时，所有实现方必须同步更新（编译时检查）

## 12. 消费者

所有 FoundationX 业务域模块（market_data / factor_engine / riskx / orderx / signal_factory / strategyx / settlement / maestro / ms_brain / regime_engine 等）。

## 13. 接口契约

```go
type DTO interface{ ... }
type Port interface{ ... }
type DataProvider interface{ ... }
```

完整接口定义见 `/home/workspace/contracts/pkg/contracts/`。

## 14. 数据模型

DTO 为值类型（不可变），Port 为行为接口（无状态）。具体 struct 定义见 runtime 仓库。

## 15. 配置模式

本模块为纯接口契约，无运行时配置。

## 16. 错误处理

`ErrorCode` 提供 `Code`/`Domain`/`Severity`/`Retryable` 字段，调用方按需处理。

## 17. 目录结构

```
/home/workspace/contracts/pkg/contracts/
├── contracts.go
├── ports.go
├── regime_snapshot.go
├── regime_card.go
├── decision_card.go
├── signal_intent.go
├── ingestion.go
└── projections.go
```

## 18. 依赖

无内部依赖（stdlib only）。

## 19. 测试

- `go test ./... -race -count=1`（runtime 仓）
- 编译时类型检查：所有接口实现方

## 20. 性能预算

本模块为零运行时开销（纯类型定义 + 接口声明）。

## 21. 可观测性

不适用（纯接口模块无运行时）。

## 22. 安全

1. DTO 不携带凭证字段
2. ErrorCode 不泄露内部路径
3. 接口契约不绑定具体传输协议

## 23. CI 门禁

`go build ./...` + `go vet ./...` + lint（runtime 仓 CI）。

## Appendix A: 升级兼容性

接口变更遵循语义版本控制：新增方法 = MINOR，删除/修改方法签名 = MAJOR（需 migration guide）。

## Appendix B: 发布 DoD

- [x] `go build ./...` 通过
- [x] `go test ./... -race -count=1` 通过
- [x] lint 通过
- [x] TRACEABILITY.md 已更新
- [x] CHANGELOG.md 已更新

## Appendix C: 待解决问题

无。当前基线已与 runtime 仓库 `/home/workspace/contracts` 对齐。
