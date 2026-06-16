# module/binance SPEC

- Status: Docs Baseline Approved / Runtime Pending
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-17
- Owner: ZoneCNH
- Layer: 数据域 · 行情
- Module-Version: v1.0.0-spec
- Repository: [github.com/ZoneCNH/binance](https://github.com/ZoneCNH/binance)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), `module/domain-market`, `module/contracts`, `module/market-data`, `module/transportx`

> 子模块规格：`module/binance/client/SPEC.md`、`module/binance/server/SPEC.md`

---

## 0. Upstream Contract Gate

在从 docs baseline 推进到运行时实现前，必须逐项验证以下上游契约链闭合条件：

| # | Gate | 验证 | 状态 |
|---|------|------|:----:|
| G0-1 | `module/contracts` §8.4 `MarketDataService` + `IngestRequest`(12字段)/`IngestResult`/`IngestAck`/`IngestReject` + `RejectCode`(9码) | contracts SPEC v1.2.0 | ✅ |
| G0-2 | `module/domain-market` `ProductLine`(4值)/`InstrumentKey`(12维)/`MarketFactEnvelope` canonical 类型 | domain-market SPEC v1.0.1 §10 | ✅ |
| G0-3 | `module/market-data` DownstreamDispatchPort + 12 输入字段 + 8 种 reject reason + §4.4.1 binance reject 映射 | market-data SPEC v0.1.1 §4 | ✅ |
| G0-4 | binance OQ-001（contracts wire 就绪？） | 已确认 (2026-06-17) | ✅ |
| G0-5 | binance OQ-002（market-data dispatch port 就绪？） | 已确认 (2026-06-17) | ✅ |
| G0-6 | BOUNDARY-GATES.md 全部 9 门禁有 CI 脚本 | 9/9 (2026-06-17) | ✅ |

> **6/6 通过** — 上游契约链闭合。本 SPEC 处于 Docs Baseline Approved 状态，可进入运行时实现阶段（PR-007）。实现时必须严格遵循 contracts §8.4 wire types、domain-market §10 canonical semantics、market-data §4 dispatch port 契约。

---

## 1. Summary

`module/binance` 是 Binance 专属 Market Data C/S Module，定义 Binance 行情数据从交易所采集到 ZoneCNH 内部摄入的完整边界。它从被动 SDK / 旧式 Provider 模型升级为显式 client/server 双端架构：

```text
Binance Exchange
  ↓
module/binance/client          ← 交易所侧采集器
  ↓ contracts-defined gRPC
module/binance/server          ← 摄入受理服务器
  ↓ downstream dispatch port
module/market-data             ← 交易所中立的后续管线
```

子模块 `client` 负责连接 Binance、解析和规范化行情事件；`server` 负责验证、去重、ACK 和下游分发。`binance-market` 已移除。

---

## 2. Problem

Binance 行情集成面临以下问题：

1. **旧 SDK 模型职责不清**：`binance` SDK 和 `binance-market` Provider 并存，采集、转换、持久化边界模糊，新增产品线时无法确定代码放在哪个模块。
2. **无明确传输契约**：采集端产出的数据"向谁发送"未定义，server 侧 ingest 接受语义缺失，导致每个 CEX 集成各自发明传输方式。
3. **身份碰撞风险**：Spot `BTCUSDT`、USDⓈ-M `BTCUSDT`、COIN-M `BTCUSD` 和 Options 合约若不以显式 product_line 区分，会在下游产生身份碰撞。
4. **可靠性无保障**：at-least-once delivery + idempotent acceptance + ACK-driven checkpoint 的端到端语义从未定义，client 重启或 server 故障时事件丢失或重复不可控。
5. **边界侵蚀**：Binance 模块容易向其内部引入 storage/query/strategy 所有权，违背数据域"采集后即交付"的架构原则。

---

## 3. Goals

- 定义 client/server 双端架构，client 拥有交易所侧采集，server 拥有摄入受理
- 支持 Binance 四产品线：Spot、USDⓈ-M Futures、COIN-M Futures、Options
- 通过 contracts-defined `MarketDataService` gRPC bidirectional stream 传输
- 明确 at-least-once (client) + idempotent acceptance (server) + ACK-driven checkpoint 交付语义
- 定义 canonical instrument identity 所需维度，覆盖四产品线碰撞场景
- 定义 enforceable boundary gates，防止跨边界导入和所有权扩散
- 移除 `binance-market` 作为 active/legacy Provider

---

## 4. Non-goals

`module/binance` 明确不做以下事情：

| 不做 | 原因 |
|------|------|
| 定义 canonical domain model（ProductLine/InstrumentKey 等） | 由 `module/domain-market` 拥有 |
| 定义 proto/gRPC wire contract | 由 `module/contracts` 拥有 |
| 拥有 market-data storage engine | 由 `module/market-data` 拥有 |
| 暴露 query API | 属于 `module/market-data` 或下游模块 |
| 实现 strategy API / trading decision | 属于分析域和决策域 |
| 实现 order execution | 属于执行域 |
| 兼容旧 `binance-market` Provider | 已移除，迁移历史详见 `docs/migrations/` |
| 作为跨 CEX 通用 ingestion server | 本模块仅处理 Binance，通用部分在 `module/market-data` |

---

## 5. Consumers

| 消费者 | 使用方式 | 状态 |
|--------|----------|------|
| `module/market-data` | 通过 server downstream dispatch port 接收 canonical market events | 待实现 |
| `module/binance/client` | 通过 contracts-defined gRPC 调用 `module/binance/server` 的 `MarketDataService.Ingest` | 待实现 |
| `module/binance/server` | 接收 client 发送的 `IngestRequest` 流 | 待实现 |
| Operator / SRE | 通过 client/server Gin admin 端点监控和管理 | 待实现 |
| CI Pipeline | 通过 BOUNDARY-GATES.md 中的 gate 脚本执行边界检查 | 待实现 |

---

## 6. Functional Requirements

### FR-001: Product-Line Support

**功能描述**：模块必须支持 Binance 四种产品线的行情数据采集。

**WHEN** 配置启用 Spot 产品线
**THEN** client 可通过 Spot connector 采集 Binance spot market data

**WHEN** 配置启用 USDⓈ-M 产品线
**THEN** client 可通过 USDⓈ-M connector 采集 USDT/USDC 保证金合约行情

**WHEN** 配置启用 COIN-M 产品线
**THEN** client 可通过 COIN-M connector 采集币本位合约行情

**WHEN** 配置启用 Options 产品线
**THEN** client 可通过 Options connector 采集期权行情

### FR-002: Instrument Identity

**功能描述**：模块生成的 canonical instrument identity 必须在四条产品线间不发生碰撞。

**WHEN** parser 解析 Spot `BTCUSDT` 和 USDⓈ-M `BTCUSDT`
**THEN** 两者产生不同的 `InstrumentKey`（通过 `product_line` 维度区分）

**WHEN** parser 解析 COIN-M `BTCUSD`
**THEN** identity 包含 settlement_asset 维度

**WHEN** parser 解析 Options 合约
**THEN** identity 包含 expiry、strike、option_type 三个维度

### FR-003: gRPC Ingestion

**功能描述**：client 和 server 之间通过 contracts-defined `MarketDataService` gRPC 通信。

**WHEN** client 有 canonical event 待发送
**THEN** 通过 `MarketDataService.Ingest` bidirectional stream 发送 `IngestRequest`

**WHEN** server 收到有效 `IngestRequest`
**THEN** 验证、去重后返回 `IngestAck`，包含 stream_id、accepted key、durable acceptance indicator

**WHEN** server 收到无效 `IngestRequest`
**THEN** 返回 `IngestReject`，含 machine-readable reject reason

### FR-004: At-Least-Once Delivery

**功能描述**：client 提供 at-least-once 交付语义。

**WHEN** client 规范化并映射一个 event 为 canonical envelope
**THEN** 先将 event 持久化到本地 spool，状态为 `pending`

**WHEN** server 返回 durable ACK 确认接受
**THEN** client 将 spool 状态更新为 `acked` 并推进 checkpoint

**WHEN** gRPC 写成功但 server 未确认 durable acceptance
**THEN** client 不得推进 checkpoint

### FR-005: Idempotent Acceptance

**功能描述**：server 每个 idempotency key 最多接受一次并 downstream dispatch 一次。

**WHEN** server 收到新 idempotency key 的有效 event
**THEN** 接受、durable 记录、ACK、dispatch downstream

**WHEN** server 收到已 accepted 的 idempotency key
**THEN** 返回 idempotent ACK，不再次 dispatch

**WHEN** server 收到已 accepted 的 idempotency key 但 payload 冲突
**THEN** 返回 terminal_conflict reject

### FR-006: Admin Surface

**功能描述**：client 和 server 各自暴露 Gin admin 端点。

**WHEN** 请求 `GET /healthz`
**THEN** 返回 process liveness 状态（200 或 503）

**WHEN** 请求 `GET /readyz`
**THEN** 返回模块就绪状态（200 或 503），不检查下游业务正确性

**WHEN** 请求 `GET /debug/*`
**THEN** 返回只读诊断信息，不暴露 secrets

**WHEN** 请求 `/admin/*` 变更操作
**THEN** 仅变更本地服务状态，不跨模块边界

### FR-007: Boundary Enforcement

**功能描述**：模块边界通过 CI gate 强制执行。

**WHEN** client 代码尝试 import server internal 包
**THEN** CI boundary gate 失败

**WHEN** 任何代码 reintroduce `binance-market` 引用
**THEN** CI no-legacy gate 失败

**WHEN** 模块内声明 storage/query/strategy 所有权
**THEN** CI ownership gate 失败

---

## 7. Business Rules

### BR-001: No binance-market

**规则**：禁止在 active architecture 中引用 `binance-market`。

**约束**：`module/binance-market`、`github.com/ZoneCNH/binance-market`、`docs/services/binance-market-client-svc.md` 不得出现在 active documentation（除 `CHANGELOG.md` 和 `docs/migrations/` 外）。

**违反时**：CI gate 失败，PR 不可合并。

### BR-002: Client/Server Boundary

**规则**：client 不得 import server internal 包，server 不得 import client internal 包。

**约束**：
- `module/binance/client` → 禁止 import `module/binance/server/*`
- `module/binance/server` → 禁止 import `module/binance/client/*`
- Runtime: `internal/client` → 禁止 import `internal/server`，反之亦然

**违反时**：CI boundary gate 失败。

### BR-003: Checkpoint Requires ACK

**规则**：client checkpoint 仅可在 server 返回 durable ACK 后推进。

**约束**：禁止在 serialization 成功、local enqueue 成功、gRPC write 成功或 send attempt 成功后推进 checkpoint。

**违反时**：spool 状态机拒绝 transition；重启后 checkpoint 回退到上一个 durable ACK 位置。

### BR-004: No Domain Ownership

**规则**：`module/binance` 不得定义 canonical domain semantics 的 source of truth。

**约束**：`ProductLine`、`InstrumentKey`、`InstrumentType`、`MarketScope`、`OptionType`、`PriceKind` 等 canonical enum 必须来自 `module/domain-market`。Binance 可定义 exchange-specific parsing/mapping，但输出必须是对 domain-market 类型的引用。

**违反时**：CI ownership gate 失败。

### BR-005: No Storage/Query/Strategy Ownership

**规则**：`module/binance` 不得拥有 storage engine、query API 或 strategy API。

**约束**：server downstream dispatch port 只做 handoff，不实现物理存储。禁止引入 `github.com/ZoneCNH/storage`、`github.com/ZoneCNH/strategy` 作为 owned dependency。

**违反时**：CI ownership gate 失败。

### BR-006: Wire Contract Externality

**规则**：`module/binance` 不得定义自己的 proto 文件或 wire schema。

**约束**：proto 定义和 gRPC code generation 由 `module/contracts` 拥有。禁止 `module/binance/proto/*` 和独立 canonical wire enum 定义。

**违反时**：CI gate 失败。

### BR-007: Idempotency Key Stability

**规则**：client 生成的 idempotency key 必须在 retry 场景下稳定。

**约束**：key 必须基于 exchange + product_line + instrument_key + event_type + event_time/source_sequence 等确定性维度生成。bar 事件包含 interval/open_time，trade 包含 trade_id，depth 包含 sequence/update dimensions。

**违反时**：retry 时 server 无法识别重复，产生 duplicate downstream effect。

### BR-008: Admin Boundary

**规则**：client admin 仅可变更 client-local state，server admin 仅可变更 server-local state。

**约束**：禁止 client admin 变更 server state、server admin 变更 client connector state、admin 变更 downstream storage/strategy state、未经显式保护操作删除 checkpoint。

**违反时**：操作被拒绝并返回错误。

---

## 8. Interface Contract

### MarketDataService (defined by module/contracts)

```go
// MarketDataService defines the gRPC ingest contract.
// Implemented by module/binance/server.
// Called by module/binance/client.
//
// THIS INTERFACE IS OWNED BY module/contracts — reproduced here for spec clarity only.
type MarketDataService interface {
    // Ingest accepts a bidirectional stream of market data events.
    // Client sends IngestRequest; server responds with IngestAck.
    Ingest(stream MarketData_IngestServer) error
}
```

### Wire Protocol

```go
// MarketDataService receives normalized upstream market-data ingestion requests.
// Defined in module/contracts/SPEC.md §8.4.
// Each IngestRequest returns exactly one IngestResult (Ack or Reject).
type MarketDataService interface {
    Ingest(stream IngestRequest) (stream IngestResult, error)
}
```

- Client 发送 `IngestRequest`（canonical market event envelope + idempotency key + source metadata）
- Server 对每个 `IngestRequest` 返回一个 `IngestResult`，其中 exactly one of `Ack` or `Reject` is non-nil

### Downstream Dispatch Port

Server 通过 exchange-neutral downstream port 将 accepted events 分发给 `module/market-data`。该 port 的具体接口由 `module/market-data` 定义；server 只做 handoff 适配。

---

## 9. Data Model

### Canonical Event Concepts (owned by module/domain-market)

| Concept | Purpose | Owned By |
|---------|---------|----------|
| `InstrumentKey` | Unique instrument identity across product lines | domain-market |
| `ProductLine` | Spot / USDⓈ-M / COIN-M / Options | domain-market |
| `InstrumentType` | Perpetual / Futures / Option / Spot | domain-market |
| `OptionType` | Call / Put | domain-market |
| `PriceKind` | Bid / Ask / Last / Mark / Index | domain-market |
| `MarketScope` | Exchange-native liquidity scope | domain-market |
| `MarketFactEnvelope` | Canonical event wrapper | domain-market |
| `decision_time` | Exchange event time for strategy feed | domain-market |

### Instrument Identity Dimensions

Minimum dimensions for collision-free identity across Binance product lines:

| Dimension | Spot | USDⓈ-M | COIN-M | Options |
|-----------|:----:|:-------:|:------:|:-------:|
| exchange | ✅ | ✅ | ✅ | ✅ |
| product_line | ✅ | ✅ | ✅ | ✅ |
| instrument_type | ✅ | ✅ | ✅ | ✅ |
| base_asset | ✅ | ✅ | ✅ | ✅ |
| quote_asset | ✅ | — | — | — |
| margin_asset | — | ✅ | ✅ | — |
| settlement_asset | — | — | ✅ | — |
| contract_code | — | ✅ | ✅ | — |
| expiry | — | ✅ | ✅ | ✅ |
| strike | — | — | — | ✅ |
| option_type | — | — | — | ✅ |

### Spool State Machine

```text
pending → sending → acked
                  → failed_retryable → pending (retry)
                  → failed_terminal
```

### Reject Classification

```text
retryable
terminal_validation
terminal_conflict
unauthorized
rate_limited
server_unavailable
```

---

## 10. Config Schema

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `binance.endpoints.rest` | `string` | `https://api.binance.com` | Binance REST API base URL |
| `binance.endpoints.ws` | `string` | `wss://stream.binance.com:9443` | Binance WebSocket base URL |
| `binance.product_lines` | `[]string` | `[]` | 启用的产品线：spot/usdm/coinm/options |
| `binance.symbols.allow` | `[]string` | `[]` | 白名单 symbol（空=全部） |
| `binance.symbols.deny` | `[]string` | `[]` | 黑名单 symbol |
| `grpc.target` | `string` | `localhost:9090` | server gRPC 地址 |
| `spool.path` | `string` | `./spool` | SQLite spool 文件路径 |
| `spool.max_size_mb` | `int` | `1024` | spool 最大大小 (MB) |
| `checkpoint.path` | `string` | `./checkpoint` | checkpoint 文件路径 |
| `retry.max_attempts` | `int` | `5` | 最大重试次数 |
| `retry.backoff_initial` | `duration` | `1s` | 初始退避时间 |
| `retry.backoff_max` | `duration` | `60s` | 最大退避时间 |
| `admin.bind` | `string` | `:8080` | admin HTTP 绑定地址 |

> **Security**：API keys、secrets、signatures 从环境变量注入，不从配置文件读取。禁止在 logs 和 admin/debug 端点暴露。

---

## 11. Error Handling

| 错误 | 触发条件 | 处理方式 | 错误码 |
|------|----------|----------|--------|
| `ErrProductLineDisabled` | 配置未启用的 product line 被请求 | 记录日志，跳过该 product line | `BNC-001` |
| `ErrInvalidSymbol` | parser 无法解析 Binance symbol | 结构化错误返回，记录原始 symbol | `BNC-002` |
| `ErrSpoolFull` | spool 超过 max_size | 阻塞接收，触发告警 | `BNC-003` |
| `ErrCheckpointStale` | checkpoint 落后超过阈值 | 触发告警，暂停新事件采集 | `BNC-004` |
| `ErrGRPCConnect` | 无法连接 server gRPC | 指数退避重试，spool 继续累积 | `BNC-005` |
| `ErrDuplicateConflict` | server 收到同一 key 但 payload 不同的 event | terminal reject，记录冲突详情 | `BNC-006` |
| `ErrValidation` | server 收到缺少必需字段的 event | terminal reject，含 machine-readable reason | `BNC-007` |
| `ErrDispatchFailed` | downstream dispatch 失败 | 重试（指数退避），超过阈值告警 | `BNC-008` |

---

## 12. Edge Cases

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| 产品线身份碰撞 | Spot `BTCUSDT` 和 USDⓈ-M `BTCUSDT` 同时采集 | parser 产生不同 `InstrumentKey`，product_line 维度区分 |
| Client 进程重启 | spool 中有 `pending`/`sending` 事件 | 从 checkpoint 位置恢复发送，duplicate 由 server idempotency 消解 |
| gRPC stream 断连 | server 不可达或网络中断 | client 退避重连，spool 状态保持 `sending`，checkpoint 不推进 |
| Server 已接受后崩溃 | durable acceptance 完成但 ACK 未发给 client | client 重发同一 key，server 返回 idempotent ACK |
| Spool 写满 | spool 达到 max_size_mb | 阻塞新事件接收，触发 `ErrSpoolFull` 告警 |
| Idempotency key 冲突 | 同一 key 但不同 payload 到达 server | server 返回 `terminal_conflict` reject |
| 无效 symbol | parser 收到未知 format 的 symbol | 返回结构化 `ErrInvalidSymbol`，不产生 canonical event |
| 产品线禁用 | 配置中 product line 未启用 | connector 不订阅该 product line 的 stream |
| Downstream dispatch 持续失败 | market-data 下游不可用 | 指数退避重试，超过阈值告警，不丢失已 accepted event |

---

## 13. Directory Structure

### Documentation (`module/binance/`)

```text
module/binance/
  goal.md                          # 模块 Goal 文档
  README.md                        # 模块索引
  SPEC.md                          # 本文件 — 模块完整规格
  TRACEABILITY.md                  # 需求追溯矩阵
  IMPLEMENTATION-PLAN.md           # 实现计划（PR 序列）
  BOUNDARY-GATES.md                # CI 边界门禁定义
  RUNTIME-MAPPING.md               # 规格到 runtime 仓库映射
  tasks/                           # Root 层 task spec
    TASK-BINANCE-ROOT-000-*.md
    ...
  client/                          # Client 子模块
    README.md
    SPEC.md
    TRACEABILITY.md
    IMPLEMENTATION-PLAN.md
    tasks/                         # Client task spec（12 个）
  server/                          # Server 子模块
    README.md
    SPEC.md
    TRACEABILITY.md
    IMPLEMENTATION-PLAN.md
    tasks/                         # Server task spec（8 个）
```

### Runtime (`github.com/ZoneCNH/binance/`)

```text
github.com/ZoneCNH/binance/
  go.mod
  cmd/
    binance-client/main.go
    binance-server/main.go
  internal/
    client/     # app/config/catalog/parser/spot/usdm/coinm/options/normalize/mapper/idempotency/spool/checkpoint/sender/admin/observability
    server/     # app/config/ingest/validation/idempotency/ack/dispatch/admin/observability
  pkg/
    config/
    observability/
    version/
  test/
    contract/
    integration/
    fixtures/
```

---

## 14. Dependencies

### Allowed Dependencies

| 依赖 | 用途 | 消费方 |
|------|------|--------|
| `module/domain-market` | canonical 语义类型（InstrumentKey/ProductLine/MarketFactEnvelope 等） | client mapper, server validation |
| `module/contracts` | proto/gRPC wire contract（MarketDataService/IngestRequest/IngestAck） | client sender, server ingest |
| `module/market-data` | downstream exchange-neutral dispatch port | server dispatch |
| `module/transportx` | gRPC 流策略、retry/backoff 约定、Gin admin 约定 | client, server |

### Forbidden Dependencies

| 禁止导入 | 原因 |
|----------|------|
| `module/binance/client/*` (在 server 中) | 违反 client/server 边界 |
| `module/binance/server/*` (在 client 中) | 违反 client/server 边界 |
| `github.com/ZoneCNH/binance-market` | legacy 模块已移除 |
| `github.com/ZoneCNH/storage` (as owned) | storage ownership 属于 market-data |
| `github.com/ZoneCNH/strategy` (as owned) | strategy ownership 属于分析/决策域 |

---

## 15. Testing

### Test Matrix

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 集成 | 启用 Spot product line，连接 Binance testnet | connector 产生标有 ProductLine=Spot 的 normalized events |
| TC-002 | FR-002 | 单元 | parser 输入 Spot `BTCUSDT` 和 USDⓈ-M `BTCUSDT` | 两个不同的 InstrumentKey |
| TC-003 | FR-002 | 单元 | parser 输入 COIN-M `BTCUSD` | InstrumentKey 含 settlement_asset |
| TC-004 | FR-003 | 契约 | client 发送 IngestRequest → mock server | server 收到有效请求 |
| TC-005 | FR-004 | 集成 | 发送 event 后 kill client 进程，重启 | spool 中的 event 从 checkpoint 位置恢复 |
| TC-006 | FR-005 | 集成 | 发送同一 idempotency key 两次 | server 返回 idempotent ACK，downstream 仅 dispatch 一次 |
| TC-007 | FR-005 | 集成 | 发送同一 key 但不同 payload | server 返回 terminal_conflict reject |
| TC-008 | FR-006 | 单元 | GET /healthz | 返回 200 |
| TC-009 | FR-007 | CI | client 代码 import server internal | boundary gate 失败，CI exit 1 |

### Test Tools

- 框架：`testing` + `testify`
- Mock：gRPC mock server（contract tests）
- 覆盖率：`go test -cover`
- 竞态：`go test -race`

---

## 16. Performance Budget

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| Client event normalization | 延迟 P99 | < 1ms | `go test -bench` |
| Canonical mapping | 延迟 P99 | < 100μs | `go test -bench` |
| Spool write | 延迟 P99 | < 5ms | `go test -bench` |
| gRPC send (单 event) | 延迟 P99 | < 10ms | integration test |
| Server validation | 延迟 P99 | < 100μs | `go test -bench` |
| Server idempotency check | 延迟 P99 | < 1ms | `go test -bench` |
| ACK lag (server receive → ACK send) | P99 | < 100ms | integration test |
| Client restart recovery | 时间 | < 10s | integration test |

---

## 17. Observability

### Metrics

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `binance_client_raw_events_total` | counter | 收到的原始事件数（per product_line） |
| `binance_client_events_normalized_total` | counter | 规范化后的事件数 |
| `binance_client_events_mapped_total` | counter | 映射为 canonical 的事件数 |
| `binance_client_events_spooled_total` | counter | spool 写入的事件数 |
| `binance_client_events_sent_total` | counter | gRPC 发送成功的事件数 |
| `binance_client_ack_lag_seconds` | histogram | ACK 延迟（send → ACK receive） |
| `binance_client_retry_total` | counter | 重试次数 |
| `binance_client_stream_reconnects_total` | counter | stream 重连次数 |
| `binance_server_streams_active` | gauge | 活跃 stream 数 |
| `binance_server_events_accepted_total` | counter | 接受的唯一事件数 |
| `binance_server_events_duplicate_total` | counter | 重复事件数 |
| `binance_server_events_rejected_total` | counter | 拒绝事件数（per reject_reason） |
| `binance_server_dispatch_latency_seconds` | histogram | downstream dispatch 延迟 |

### Logging

| 事件 | 级别 | 必要字段 |
|------|------|----------|
| Stream connected/disconnected | info | stream_id |
| Event accepted | debug | stream_id, product_line, instrument_key, idempotency_key |
| Event rejected | warn | stream_id, reject_reason, idempotency_key |
| Duplicate detected | debug | stream_id, idempotency_key |
| Dispatch failed | error | stream_id, instrument_key, error |
| Checkpoint advanced | debug | checkpoint_position, stream_id |
| Spool near capacity | warn | spool_usage_percent |

### Tracing

| Span 名 | 说明 |
|---------|------|
| `binance.client.normalize` | 原始事件规范化 |
| `binance.client.map` | 映射为 canonical event |
| `binance.client.spool_write` | spool 写入 |
| `binance.client.grpc_send` | gRPC 发送 |
| `binance.server.validate` | server 端验证 |
| `binance.server.idempotency_check` | 幂等性检查 |
| `binance.server.dispatch` | downstream dispatch |

---

## 18. Security

- 禁止硬编码 API key、secret、signature
- 所有 secret 从环境变量注入，不在 config 文件中存储
- `/debug/*` 和 `/admin/*` 端点不得暴露 secrets、API keys、签名或私有配置
- Admin 端点在暴露于非本地可信网络时必须使用认证
- 日志中禁止记录 API key、secret、signature、完整 payload（仅记录 metadata）
- Client/server gRPC 通信建议使用 mTLS（由 `module/transportx` TLS policy 指导）
- 输入校验：所有收到的 exchange-native payload 在进入 parser 前验证基本结构
- Idempotency store 不暴露外部查询接口

---

## 19. CI Gate

### 通用 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 编译 | `go build ./...` | 零错误 |
| 测试 | `go test ./... -race -count=1` | 全部通过 |
| 覆盖率 | `go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out` | ≥ 80% |
| Vet | `go vet ./...` | 零警告 |
| Lint | `golangci-lint run` | 零警告 |
| 安全 | `gitleaks detect --no-git` | 零泄露 |

### Module-Specific Gates

| Gate | 命令 | 通过条件 |
|------|------|----------|
| No legacy binance-market | `BOUNDARY-GATES.md` §2 gate script | 零 forbidden 引用 |
| Client/server boundary | `BOUNDARY-GATES.md` §3-§4 gate scripts | 零跨边界 import |
| Ownership | `BOUNDARY-GATES.md` §5 gate script | 零 storage/query/strategy 所有权声明 |
| Contracts only | `BOUNDARY-GATES.md` §6 gate script | 零 local proto 文件 |
| Domain-market source | `BOUNDARY-GATES.md` §7 gate script | 零独立 canonical enum 定义 |
| Admin boundary | `BOUNDARY-GATES.md` §8 gate script | 零跨模块 admin mutation |
| Checkpoint requires ACK | `BOUNDARY-GATES.md` §9 gate script | 零 send-only checkpoint advance |

---

## 20. Upgrade Compatibility

| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| 新增 product line | 向后兼容 | 添加 connector + parser rule + catalog entry |
| `IngestRequest` 或 `IngestAck` proto 变更 | 取决于 contracts 兼容策略 | 升级 contracts 版本，regenerate client/server |
| Canonical domain type 变更 | 取决于 domain-market 兼容策略 | 更新 mapper，regenerate 测试 fixtures |
| Spool schema 变更 | 可能需要 migration | 提供 spool migration 工具或清空重建 |
| Admin endpoint 新增 | 向后兼容 | 无迁移需求 |
| 移除 `binance-market` references | Breaking（新模块无此 legacy） | `docs/migrations/remove-binance-market.md` |

---

## 21. Release DoD

`module/binance` v1.0.0 发布完成标准：

- [ ] `binance-market` references 已移除或隔离到 migration history（BR-001）
- [ ] `module/binance/client` 和 `module/binance/server` specs 完成并通过 spec-lint
- [ ] root/client/server TRACEABILITY.md 完成，所有需求可追溯
- [ ] client/server task sets 独立可执行
- [ ] Delivery semantics 明确为 at-least-once + idempotent acceptance（FR-004, FR-005）
- [ ] ACK/checkpoint semantics 已定义且 testable（BR-003）
- [ ] ProductLine 和 InstrumentKey 碰撞 case 已文档化（FR-002, §9 Data Model）
- [ ] Boundary gates 可在 CI 执行（FR-007, BOUNDARY-GATES.md）
- [ ] Runtime mapping 未将 storage/query/strategy ownership 放在 Binance 内（BR-005）
- [ ] 所有 FR 实现完成，所有 AC 验证通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过（通用 + 模块专属）
- [ ] Performance Budget 达标
- [ ] Integration test 演示 `client → server → downstream port` 完整数据流

---

## 22. Open Questions

### Resolved (was Blocking)

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | `MarketDataService` proto 的 final wire 定义是否已在 `module/contracts` 中完成？ | 已确认 — contracts §8.4 已提供 docs-only wire contract 基线（IngestRequest/IngestResult），运行时 proto 编译待后续阶段 | contracts owner |
| OQ-002 | `module/market-data` 的 downstream dispatch port 接口是否已定义？ | 已确认 — market-data SPEC v0.1.1 已定义 DownstreamDispatchPort 语义、12 项输入字段、8 种 reject reason 和 binance reject 映射规则 | market-data owner |

### Non-blocking

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-003 | server idempotency store 的 backing storage 选型（in-memory / SQLite / Redis）？ | 待定 | binance owner |
| OQ-004 | 是否需要 multi-region Binance endpoint 切换？ | 待评估 | binance owner |
| OQ-005 | `MarketDataService` 是否需要支持非 Binance 的 multi-exchange server？ | 待评估 | architecture |

### Future

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-006 | 是否需要 Binance 以外的 CEX 参照此 C/S 架构统一？ | 待评估 | architecture |
| OQ-007 | 是否需要压缩 gRPC payload（特别是 depth snapshot）？ | 待评估 | performance |

---

## Appendix A: Architecture Decision Record

| 日期 | 决策 | 理由 |
|------|------|------|
| 2026-06-16 | 采用 client/server 双端架构 | SDK + Provider 模型职责不清，C/S 明确采集端和受理端边界 |
| 2026-06-16 | 移除 `binance-market` | 统一到 client/server，消除 ambiguous split |
| 2026-06-16 | gRPC bidirectional stream 作为传输协议 | client 需要 per-event ACK 以驱动 checkpoint |
| 2026-06-16 | At-least-once + idempotent acceptance 交付语义 | 不声称 exactly-once（client 端不可实现），但保证 downstream 无重复 |

## Appendix B: Reference — Removed Legacy Module

`binance-market` 不再存在。以下路径禁止用于新开发：

```text
module/binance-market
github.com/ZoneCNH/binance-market
docs/services/binance-market-client-svc.md
```

允许的历史性提及：

```text
docs/migrations/remove-binance-market.md
CHANGELOG.md
```

## Appendix C: Data Flow Diagram

```text
Binance Exchange (REST/WebSocket)
  │
  ├─ Spot connector ─────────────┐
  ├─ USDⓈ-M connector ──────────┤
  ├─ COIN-M connector ───────────┤
  └─ Options connector ──────────┘
           │
           ▼
    ┌──────────────────┐
    │  Product-Line     │
    │  Catalog          │
    ├──────────────────┤
    │  Instrument       │
    │  Parser           │
    ├──────────────────┤
    │  Raw Event        │
    │  Normalizer       │
    ├──────────────────┤
    │  Canonical        │
    │  Mapper           │ ◄── module/domain-market
    ├──────────────────┤
    │  Idempotency Key  │
    │  Generator        │
    ├──────────────────┤
    │  SQLite Spool     │
    ├──────────────────┤
    │  Checkpoint       │
    ├──────────────────┤
    │  gRPC Sender      │ ◄── module/contracts
    └────────┬─────────┘
             │  MarketDataService.Ingest (bidirectional stream)
             ▼
    ┌──────────────────┐
    │  gRPC Ingest      │ ◄── module/contracts
    │  Server            │
    ├──────────────────┤
    │  Validation        │
    ├──────────────────┤
    │  Idempotent        │
    │  Acceptance        │
    ├──────────────────┤
    │  ACK / Reject      │
    ├──────────────────┤
    │  Downstream        │
    │  Dispatch          │ ◄── module/market-data downstream port
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │  module/          │
    │  market-data      │
    │  (exchange-neutral│
    │   pipeline)       │
    └──────────────────┘
```
