# module/binance/client SPEC

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-16
- Owner: ZoneCNH
- Layer: 数据域 · Binance 交易所接入
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/binance](https://github.com/ZoneCNH/binance)（client/ 子目录）
- Related: [CONSTITUTION.md](../../../CONSTITUTION.md), [ARCHITECTURE.md](../../../ARCHITECTURE.md), [module/binance/SPEC.md](../SPEC.md), [module/contracts/SPEC.md](../../contracts/SPEC.md), [module/domain-market](../../domain-market/)

---

## 2. Summary

`module/binance/client` 是 Binance 交易所对向行情采集器。它连接 Binance 行情端点，将交易所原生事件转换为 ZoneCNH 规范行情事件，持久化本地投递状态，并通过 contracts 定义的 gRPC 协议将事件发送至 `module/binance/server`。

---

## 3. Problem

量化交易系统需要从 Binance 采集行情数据。直接使用 Binance SDK 或裸 WS/REST 调用存在以下问题：

- **多产品线身份碰撞**：`BTCUSDT` 同时存在于 Spot 和 USDⓈ-M 永续合约，裸 symbol 无法区分产品线，导致数据路由错误
- **投递不可靠**：网络断开后事件丢失，无法恢复断点；重启后无法确定哪些事件已送达 server
- **重试幂等无保障**：直接重发可能导致 server 侧重复处理同一事件
- **耦合风险**：client 直接依赖 server 内部实现，导致 C/S 边界模糊、无法独立部署
- **无本地缓冲**：网络瞬断时事件直接丢弃，缺乏 spool-and-forward 交付保障

---

## 4. Goals

- 支持 Binance 全部 4 条产品线：Spot、USDⓈ-M Futures、COIN-M Futures、Options，每条可独立启停
- 提供产品线目录，包含足够字段生成规范身份标识
- 提供 Binance 符号解析器，区分 Spot/USDⓈ-M/COIN-M/Options 身份，输出 `domain-market` 兼容的身份组件
- 提供 product-line connector 模型，每条产品线暴露一致的内部事件流
- 将交易所原生事件规范化为内部 client 事件，保留完整溯源信息
- 将规范化事件映射为 `domain-market` 规范行情事件，不自定义规范枚举
- 生成跨重试稳定的幂等键
- 提供 SQLite spool，发送前持久化事件，支持进程重启恢复
- 提供 checkpoint 机制，仅在 server 持久 ACK 后推进
- 提供 gRPC sender，处理重连、背压、流重启、部分 ACK、reject 分类
- 提供 Gin admin 端点，仅操作本地状态（/healthz, /readyz, /debug/*, /admin/*）
- 所有可观测性通过 `observex` 集成

---

## 5. Non-goals

- 不做 gRPC ingest server 实现（由 `module/binance/server` 负责）
- 不做 server 侧幂等接受或持久 ACK 逻辑（由 server 负责）
- 不做下游 dispatch（由 server → `module/market-data` 链路负责）
- 不做 storage/query/strategy（属于分析域和执行域职责）
- 不做规范行情类型定义（由 `module/domain-market` 负责）
- 不做 proto 定义（由 `module/contracts` 负责）
- 不做 `binance-market` 遗留模块迁移或兼容
- 不做交易下单（本模块仅采集行情数据）

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `module/binance/server` | 通过 contracts 定义 gRPC 协议接收 `IngestRequest` 流 |

> client 当前只有 server 一个消费者。未来若有其他模块需要直接消费 client 输出，需通过 contracts 定义接口。

---

## 7. Functional Requirements

### FR-001: Product-Line Catalog

**功能描述**：维护 Binance 产品线目录，每条产品线可独立配置和启停。

**WHEN** client 启动
**THEN** 加载产品线目录，包含 Spot、USDⓈ-M Futures、COIN-M Futures、Options 四条产品线
**AND** 每条产品线可独立配置启用/禁用

**WHEN** 触发 catalog reload
**THEN** 重新加载目录，不中断已启用产品线的活跃连接

**WHEN** 查询 catalog entry
**THEN** 返回包含 exchange、product_line、instrument_type、symbol、base_asset、quote_asset、margin_asset、settlement_asset、expiry、strike、option_type、contract_code、price precision、quantity precision、status 的完整条目

### FR-002: Instrument Parser

**功能描述**：将 Binance 原生符号和交易所元数据转换为规范身份组件。

**WHEN** 输入 Binance 原生 symbol 和 exchange metadata
**THEN** 解析器输出 identity 组件，可区分：
- `BTCUSDT` Spot
- `BTCUSDT` USDⓈ-M Perpetual
- `BTCUSD` COIN-M Perpetual
- `BTC-YYYYMMDD-STRIKE-C` Option
- `BTC-YYYYMMDD-STRIKE-P` Option

**WHEN** 输入无法解析的 symbol
**THEN** 返回错误，不产生歧义的身份映射

**WHEN** parser 输出被 mapper 使用
**THEN** 输出作为 `domain-market` 规范类型的输入，不定义独立的规范枚举

### FR-003: Product-Line Connectors

**功能描述**：每条产品线提供一致的 connector，暴露内部事件流。

**WHEN** 启用某条产品线
**THEN** 对应 connector 建立连接并开始采集

**WHEN** 连接断开
**THEN** connector 自动重连，恢复订阅

**WHEN** 收到交易所限速响应
**THEN** connector 以限速感知策略恢复

**WHEN** connector 收到原始事件
**THEN** 捕获原始 payload、记录本地时间戳、标注 product_line，输出统一格式的内部事件流

**WHEN** 禁用某条产品线
**THEN** connector 优雅关闭连接，不再产生新事件

### FR-004: Raw Event Normalization

**功能描述**：将原始事件规范化为内部 client 事件。

**WHEN** connector 输出原始事件
**THEN** 规范化后的事件保留：product_line、source stream、raw symbol、event type、exchange event time、local receive time、raw payload reference 或 compact payload、sequence/update ids（如可用）

**WHEN** 规范化完成
**THEN** 事件进入 canonical mapping 阶段

### FR-005: Canonical Mapping

**功能描述**：将规范化 client 事件转换为 domain-market 规范行情事件。

**WHEN** 规范化事件就绪
**THEN** mapper 使用 `module/domain-market` 领域语义转换

**WHEN** 映射完成
**THEN** 输出规范行情事件，类型系统完全依赖 `domain-market`

**WHEN** 映射遇到无法识别的 event type
**THEN** 返回错误，不生成半规范事件

### FR-006: Idempotency Key Generation

**功能描述**：生成跨重试稳定的幂等键。

**WHEN** 事件进入 spool 前
**THEN** 生成幂等键，维度包括：exchange、product_line、instrument_key、event_type、event_time 或 source sequence、interval/open time（K 线）、trade id（成交，如可用）、update id range（深度，如可用）

**WHEN** 不同 event type 需要不同 key 策略
**THEN** 按 event type 选择对应 key 策略

**WHEN** 同一事件重试
**THEN** 幂等键不变（跨重试稳定）

### FR-007: Spool

**功能描述**：发送前持久化事件，支持进程重启恢复。

**WHEN** 事件生成幂等键后
**THEN** 写入 SQLite spool，状态为 `pending`

**WHEN** sender 开始发送
**THEN** spool 状态转换为 `sending`

**WHEN** 收到 server ACK
**THEN** spool 状态转换为 `acked`

**WHEN** 发送失败且可重试
**THEN** spool 状态转换为 `failed_retryable`

**WHEN** 发送失败且不可重试（如永久 reject）
**THEN** spool 状态转换为 `failed_terminal`

**WHEN** client 进程重启
**THEN** spool 中所有 `pending` 和 `failed_retryable` 事件恢复为可发送状态

### FR-008: Checkpoint

**功能描述**：记录最后 server 持久接受的位置。

**WHEN** 收到 server 持久 ACK
**THEN** checkpoint 推进到已确认位置

**WHEN** 发生序列化成功、本地入队成功、gRPC 写成功、或发送尝试成功
**THEN** checkpoint 不推进

**WHEN** client 重启
**THEN** 从 checkpoint 位置恢复发送

### FR-009: gRPC Sender

**功能描述**：将事件通过 gRPC 流发送至 server。

**WHEN** spool 中有待发送事件
**THEN** sender 流式发送 `IngestRequest` 到 `module/binance/server`

**WHEN** 连接断开
**THEN** sender 自动重连并恢复流

**WHEN** 遇到背压
**THEN** sender 减速发送，不丢弃事件

**WHEN** 收到部分 ACK
**THEN** 仅确认对应事件的 spool 状态和 checkpoint

**WHEN** 收到 reject
**THEN** 分类处理：可重试的 → `failed_retryable`，终端拒绝 → `failed_terminal`

**WHEN** ACK 确认后
**THEN** 按清理策略回收 spool 空间

### FR-010: Admin Surface

**功能描述**：提供 Gin admin 端点，仅操作本地状态。

**WHEN** 访问 `/healthz`
**THEN** 返回 client 进程健康状态

**WHEN** 访问 `/readyz`
**THEN** 返回 client 就绪状态

**WHEN** 访问 `/debug/*`
**THEN** 返回调试信息（pprof 等）

**WHEN** 访问 `/admin/*`
**THEN** 提供本地管理操作：list enabled product lines、list active streams、pause/resume product-line collection、show spool stats、show checkpoint stats、trigger safe catalog reload

**WHEN** admin 操作涉及修改
**THEN** 不修改 server 状态、不删除 checkpoint（除非受保护的显式操作）、不暴露 secrets、不触发交易动作

---

## 8. Business Rules

### BR-001: Checkpoint 仅在 ACK 后推进

**约束**：checkpoint 不得在序列化成功、本地入队成功、gRPC 写成功、或发送尝试成功时推进。仅在收到 server 持久 ACK 后方可推进。

**违反时**：若 checkpoint 在未确认 ACK 时推进，server 侧存在数据丢失风险——系统必须拒绝推进并记录 error 日志。

### BR-002: Spool 状态转换规则

**约束**：spool 状态机仅允许以下转换：

```text
pending → sending
pending → failed_terminal（事件无效，不进入发送）
sending → acked
sending → failed_retryable
failed_retryable → sending（重试）
failed_retryable → failed_terminal（超过最大重试次数）
```

禁止 `acked → sending`、`failed_terminal → sending`、`pending → acked`（跳过发送阶段）。

**违反时**：非法状态转换被 spool 层拦截，返回错误并记录 event log，不写入 spool。

### BR-003: Client 不能 import server internals

**约束**：`module/binance/client` 的 Go import 图中不得出现 `module/binance/server` 的任何包。

**违反时**：CI gate 的 `boundary-check` 步骤（`go list -deps | grep 'binance/server'`）检测到违规 import，构建失败。PR 禁止合并。

### BR-004: Client 不能 import storage/query/strategy

**约束**：`module/binance/client` 的 Go import 图中不得出现 `storage/`、`query/`、`strategy/` 包。

**违反时**：同 BR-003，CI gate 检测到违规 import 后构建失败。

### BR-005: 产品线身份必须唯一

**约束**：同一 symbol 在不同产品线中必须产生不同的规范身份（如 `BTCUSDT` Spot 与 `BTCUSDT` USDⓈ-M Perpetual 必须是两个不同的 instrument key）。

**违反时**：mapper 检测到身份碰撞，拒绝映射并返回错误。

---

## 9. Interface Contract

### 9.1 Connector Interface

```go
// Connector 产品线连接器接口
type Connector interface {
    // Start 启动连接并开始采集
    Start(ctx context.Context) (<-chan NormalizedEvent, error)
    // Stop 优雅关闭连接
    Stop(ctx context.Context) error
    // ProductLine 返回产品线标识
    ProductLine() string
}
```

### 9.2 Parser Interface

```go
// InstrumentParser Binance 符号解析器
type InstrumentParser interface {
    // Parse 解析 Binance 原生 symbol，返回规范身份组件
    Parse(ctx context.Context, rawSymbol string, metadata ExchangeMetadata) (*InstrumentIdentity, error)
}
```

### 9.3 Mapper Interface

```go
// CanonicalMapper 规范化事件到规范行情的映射器
type CanonicalMapper interface {
    // Map 将规范化事件转换为规范行情事件
    Map(ctx context.Context, event NormalizedEvent) (*domain_market.MarketEvent, error)
}
```

### 9.4 Sender Interface

```go
// GrpcSender gRPC 发送器
type GrpcSender interface {
    // Send 发送事件流，返回每个事件的确认结果
    Send(ctx context.Context, events <-chan SpooledEvent) (<-chan AckResult, error)
}
```

### 9.5 IdempotencyKey Generator

```go
// IdempotencyKeyer 幂等键生成器
type IdempotencyKeyer interface {
    // Generate 为规范化事件生成跨重试稳定的幂等键
    Generate(event NormalizedEvent) (string, error)
}
```

---

## 10. Data Model

### 10.1 CatalogEntry

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Exchange | `string` | ✅ | 交易所标识，固定 `"binance"` |
| ProductLine | `string` | ✅ | 产品线：`spot` / `usdm_futures` / `coinm_futures` / `options` |
| InstrumentType | `string` | ✅ | 品种类型：`spot` / `perpetual` / `future` / `option` |
| Symbol | `string` | ✅ | Binance 原生 symbol |
| BaseAsset | `string` | ✅ | 基础资产 |
| QuoteAsset | `string` | ✅ | 计价资产 |
| MarginAsset | `string` | ❌ | 保证金资产（衍生品） |
| SettlementAsset | `string` | ❌ | 结算资产（衍生品） |
| Expiry | `*time.Time` | ❌ | 到期日（交割合约/期权） |
| Strike | `*decimal.Decimal` | ❌ | 行权价（期权） |
| OptionType | `string` | ❌ | 期权类型：`C` / `P` |
| ContractCode | `string` | ❌ | 合约代码 |
| PricePrecision | `int` | ✅ | 价格精度 |
| QuantityPrecision | `int` | ✅ | 数量精度 |
| Status | `string` | ✅ | 状态：`active` / `paused` / `delisted` |

### 10.2 NormalizedEvent

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| ProductLine | `string` | ✅ | 产品线标识 |
| SourceStream | `string` | ✅ | 来源流名称 |
| RawSymbol | `string` | ✅ | Binance 原生 symbol |
| EventType | `string` | ✅ | 事件类型 |
| ExchangeEventTime | `time.Time` | ✅ | 交易所事件时间 |
| LocalReceiveTime | `time.Time` | ✅ | 本地接收时间 |
| RawPayload | `[]byte` | ❌ | 原始 payload 引用（compact 模式下为 nil） |
| CompactPayload | `[]byte` | ❌ | 紧凑 payload（raw 模式下为 nil） |
| SequenceID | `*int64` | ❌ | 序列号（如可用） |
| UpdateIDStart | `*int64` | ❌ | 更新 ID 起始（深度数据，如可用） |
| UpdateIDEnd | `*int64` | ❌ | 更新 ID 结束（深度数据，如可用） |

### 10.3 SpooledEvent

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| ID | `string` | ✅ | spool 内唯一 ID |
| IdempotencyKey | `string` | ✅ | 幂等键 |
| Payload | `[]byte` | ✅ | 序列化后的规范事件 |
| State | `SpoolState` | ✅ | spool 状态 |
| CreatedAt | `time.Time` | ✅ | 创建时间 |
| RetryCount | `int` | ✅ | 重试次数 |
| LastAttemptAt | `*time.Time` | ❌ | 最后尝试时间 |
| AckedAt | `*time.Time` | ❌ | ACK 确认时间 |

### 10.4 SpoolState

```go
type SpoolState string

const (
    SpoolPending        SpoolState = "pending"
    SpoolSending        SpoolState = "sending"
    SpoolAcked          SpoolState = "acked"
    SpoolFailedRetryable SpoolState = "failed_retryable"
    SpoolFailedTerminal SpoolState = "failed_terminal"
)
```

### 10.5 Checkpoint

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| ProductLine | `string` | ✅ | 产品线 |
| StreamID | `string` | ✅ | 流标识 |
| LastAckedID | `string` | ✅ | 最后确认的 spool event ID |
| LastAckedTime | `time.Time` | ✅ | 最后确认时间 |
| LastEventTime | `time.Time` | ✅ | 最后事件时间 |

---

## 11. Config Schema

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `client.product_lines` | `[]string` | `["spot"]` | 启用的产品线列表 |
| `client.spool_path` | `string` | `./spool/client.db` | SQLite spool 文件路径 |
| `client.spool_max_size_mb` | `int` | `1024` | spool 文件最大大小（MB） |
| `client.checkpoint_path` | `string` | `./spool/checkpoint.db` | checkpoint 文件路径 |
| `client.grpc_server_addr` | `string` | `localhost:50051` | gRPC server 地址 |
| `client.grpc_max_retry` | `int` | `10` | gRPC 最大重试次数 |
| `client.grpc_retry_backoff_ms` | `int` | `1000` | gRPC 重试退避基数（ms） |
| `client.max_retry_per_event` | `int` | `5` | 单事件最大重试次数 |
| `client.admin_port` | `int` | `8081` | Gin admin 端口 |
| `client.binance_api_key` | `string` | 从环境变量读取 | Binance API Key（敏感） |
| `client.binance_secret_key` | `string` | 从环境变量读取 | Binance Secret Key（敏感） |

> 敏感配置（API Key、Secret Key）不设默认值，必须从环境变量或 `configx` 安全后端获取。

---

## 12. Error Handling

| 错误 | 触发条件 | 处理方式 | 错误码 |
|------|----------|----------|--------|
| `ErrInvalidSymbol` | parser 无法解析 symbol | 记录 warn 日志，跳过该事件 | `BNC-CLIENT-4001` |
| `ErrProductLineDisabled` | 尝试操作未启用的产品线 | 返回错误，不启动 connector | `BNC-CLIENT-4002` |
| `ErrSpoolFull` | spool 超过最大大小 | 拒绝写入，触发告警，不丢弃已有事件 | `BNC-CLIENT-4003` |
| `ErrCheckpointStale` | checkpoint 数据损坏或不一致 | 记录 error 日志，从最新 spool 位置重建 | `BNC-CLIENT-4004` |
| `ErrGrpcUnavailable` | gRPC server 不可达 | 指数退避重试，事件保留在 spool | `BNC-CLIENT-4005` |
| `ErrRejectTerminal` | server 返回终端拒绝 | 事件标记 `failed_terminal`，记录 error 日志 | `BNC-CLIENT-4006` |
| `ErrCatalogReloadFailed` | catalog 重载失败 | 保留当前 catalog，记录 error 日志 | `BNC-CLIENT-4007` |
| `ErrIdentityCollision` | parser/mapper 检测到身份碰撞 | 拒绝事件，记录 error 日志 | `BNC-CLIENT-4008` |

**错误消息格式**：`"binance/client: <operation>: <detail>"`
**错误包装**：使用 `%w` 保留底层错误链
**禁止**：不在库中使用 `log.Fatal` 或 `os.Exit`

---

## 13. Edge Cases

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| 产品线身份碰撞 | `BTCUSDT` 同时出现在 Spot 和 USDⓈ-M | parser 结合 product_line 上下文产生不同 identity；mapper 验证无碰撞后才映射 |
| 重连不丢事件 | connector WebSocket 断开 | connector 自动重连；重连期间产生的事件不丢失；spool 中未 acked 事件在重连后继续发送 |
| spool 满策略 | spool 文件达到 `max_size_mb` | 拒绝新事件写入，触发 `ErrSpoolFull` 告警；已持久化事件不丢失；需人工扩容或清理 `acked` 事件 |
| checkpoint 回退 | server 返回的 ACK 序列小于当前 checkpoint | 检查是否为重复 ACK；若 ACK 合法（server 侧 checkpoint 确实在此位置），记录 warn 并忽略；若 ACK 异常，记录 error 并保持当前 checkpoint |
| 空 product_lines 配置 | `client.product_lines` 为空 | client 启动但不启动任何 connector，admin 可操作 |
| 并发 spool 读写 | 多个 connector 同时写入 spool | SQLite WAL 模式保证并发安全；单 writer 串行写 |
| gRPC 流中断 | sender 正在发送时流断开 | sender 重启流，从 checkpoint 位置恢复；server 通过幂等键去重 |
| 最大重试耗尽 | 事件重试次数达到 `max_retry_per_event` | 事件转为 `failed_terminal`，记录 error 日志，触发告警 |
| 进程崩溃 | 任意时刻 SIGKILL | 重启后从 checkpoint 恢复，spool 中 `pending`/`failed_retryable` 事件重新进入发送队列 |
| catalog 热重载时活跃连接 | admin 触发 catalog reload | 已启用且仍在 catalog 中的产品线连接不中断；新增产品线启动 connector；移除产品线优雅关闭 |

---

## 14. Directory Structure

```text
client/
├── go.mod
├── go.sum
├── README.md
├── SPEC.md
├── client.go                    # client 顶层组装与生命周期
├── catalog/
│   ├── catalog.go               # 产品线目录实现
│   └── catalog_test.go
├── parser/
│   ├── parser.go                # Binance 符号解析器
│   └── parser_test.go
├── connector/
│   ├── connector.go             # Connector 接口与公共逻辑
│   ├── spot.go                  # Spot connector
│   ├── usdm_futures.go          # USDⓈ-M connector
│   ├── coinm_futures.go         # COIN-M connector
│   ├── options.go               # Options connector
│   └── connector_test.go
├── normalize/
│   ├── normalize.go             # 原始事件规范化
│   └── normalize_test.go
├── mapper/
│   ├── mapper.go                # 规范化→规范映射
│   └── mapper_test.go
├── idempotency/
│   ├── keyer.go                 # 幂等键生成
│   └── keyer_test.go
├── spool/
│   ├── spool.go                 # SQLite spool 实现
│   ├── checkpoint.go            # checkpoint 管理
│   └── spool_test.go
├── sender/
│   ├── sender.go                # gRPC sender
│   └── sender_test.go
├── admin/
│   ├── admin.go                 # Gin admin 端点
│   └── admin_test.go
├── errors.go                    # 公共错误定义
├── testdata/                    # 测试数据
│   ├── spot_raw.json
│   ├── usdm_raw.json
│   ├── coinm_raw.json
│   └── options_raw.json
└── tasks/                       # Task spec 文件
```

---

## 15. Dependencies

### 15.1 允许依赖

| 依赖 | 用途 | 来源 |
|------|------|------|
| stdlib | Go 标准库 | 标准库 |
| `module/contracts` | gRPC wire contract（§8.4）：`MarketDataService` + `IngestRequest`/`IngestResult`/`IngestAck`/`IngestReject`/`RejectCode` DTO | FoundationX |
| `module/domain-market` | 规范行情类型定义 | FoundationX L2.5 |
| `module/domain-exchange` | 交易所领域值对象 | FoundationX L2.5 |
| `module/decimalx` | 高精度数值 | FoundationX L2.5 |
| `module/configx` | 配置管理 | FoundationX L1 |
| `module/observex` | 可观测性（metrics/tracing/logging） | FoundationX L1 |
| `github.com/gin-gonic/gin` | HTTP admin 框架 | 第三方 |
| `github.com/mattn/go-sqlite3` | SQLite 驱动 | 第三方 |
| `google.golang.org/grpc` | gRPC 客户端 | 第三方 |

### 15.2 禁止依赖

| 禁止依赖 | 原因 |
|----------|------|
| `module/binance/server` | 违反 C/S 边界，client 不得引用 server 内部实现 |
| `storage/query/strategy` | 超出 client 职责范围，client 仅做采集与投递 |
| `module/market-data` | client 不直接对接 market-data，通过 server 中转 |
| `module/factor-engine` 及所有分析域模块 | 跨域依赖 |
| `module/risk-engine` 及所有决策域模块 | 跨域依赖 |

### 15.3 依赖方向

```text
module/contracts → module/domain-market
       ↑                  ↑
       │                  │
module/binance/client ─────┘
       │
       ↓ (gRPC, contracts-defined)
module/binance/server
```

---

## 16. Testing

### 16.1 测试矩阵

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 单元 | 加载包含 4 条产品线的 catalog | 4 条均加载，状态正确 |
| TC-002 | FR-002 | 单元 | 解析 `BTCUSDT` + `product_line=spot` | 返回 Spot 身份，非 USDⓈ-M |
| TC-003 | FR-002 | 单元 | 解析 `BTCUSDT` + `product_line=usdm_futures` | 返回 USDⓈ-M 永续身份 |
| TC-004 | FR-002 | 单元 | 解析 `BTC-240628-50000-C` | 返回 Options Call 身份 |
| TC-005 | FR-003 | 集成 | Spot connector 连接并接收事件 | 收到 NormalizedEvent，product_line=spot |
| TC-006 | FR-003 | 集成 | connector 断开后自动重连 | 连接恢复，事件流继续 |
| TC-007 | FR-004 | 单元 | 规范化原始 trade 事件 | 输出包含完整溯源字段 |
| TC-008 | FR-005 | 单元 | 映射规范化事件到 domain-market 类型 | 输出 `*domain_market.MarketEvent` |
| TC-009 | FR-006 | 单元 | 同一事件两次生成幂等键 | 两次 key 相同 |
| TC-010 | FR-006 | 单元 | 不同 event type 使用不同 key 策略 | key 格式符合各 type 预期 |
| TC-011 | FR-007 | 单元 | 写入 spool → 状态 pending | DB 中状态为 pending |
| TC-012 | FR-007 | 单元 | 非法状态转换 | 返回错误 |
| TC-013 | FR-008 | 单元 | 收到 ACK 后 checkpoint | checkpoint 推进到 ACK 位置 |
| TC-014 | FR-008 | 单元 | 未 ACK 时 checkpoint 不变 | checkpoint 停留在原位 |
| TC-015 | FR-009 | 集成 | sender 发送事件到 mock server | server 收到事件 |
| TC-016 | FR-009 | 集成 | sender 重连 | 事件从 checkpoint 恢复，无重复 |
| TC-017 | FR-010 | 单元 | `/healthz` 返回 200 | HTTP 200 |
| TC-018 | FR-010 | 单元 | admin pause 产品线 | connector 停止产生新事件 |

### 16.2 测试工具

- 框架：`testing` + `testify`
- Mock：`testkitx`（gRPC mock server）
- 覆盖率：`go tool cover`
- 竞态：`go test -race`
- SQLite：内存数据库（`:memory:`）

### 16.3 测试数据

| 文件 | 用途 |
|------|------|
| `testdata/spot_raw.json` | Spot 原始事件样本 |
| `testdata/usdm_raw.json` | USDⓈ-M 原始事件样本 |
| `testdata/coinm_raw.json` | COIN-M 原始事件样本 |
| `testdata/options_raw.json` | Options 原始事件样本 |

---

## 17. Performance Budget

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| 事件规范化 | 延迟 P99 | < 1ms | `go test -bench` |
| 事件映射 | 延迟 P99 | < 500μs | `go test -bench` |
| 幂等键生成 | 延迟 P99 | < 100μs | `go test -bench` |
| spool 写入 | 延迟 P99 | < 5ms | `go test -bench` |
| spool ACK 更新 | 延迟 P99 | < 2ms | `go test -bench` |
| gRPC 发送吞吐 | 吞吐 | > 1000 events/s | benchmark |
| admin `/healthz` | 延迟 P99 | < 1ms | benchmark |
| 单 connector 采集 | 吞吐 | > 500 events/s | 集成 benchmark |
| client 内存稳态 | 内存 | < 256MB | `go test -benchmem` long-running test |

---

## 18. Observability

### 18.1 Metrics

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `binance_client_raw_events_total` | counter | 原始事件接收总数（按 product_line） |
| `binance_client_events_normalized_total` | counter | 事件规范化总数 |
| `binance_client_events_mapped_total` | counter | 事件映射总数 |
| `binance_client_events_spooled_total` | counter | 事件 spool 总数 |
| `binance_client_events_sent_total` | counter | 事件发送总数 |
| `binance_client_ack_lag_seconds` | gauge | ACK 延迟（秒） |
| `binance_client_retry_count` | counter | 重试总次数 |
| `binance_client_stream_reconnects_total` | counter | 流重连总次数（按 product_line） |
| `binance_client_connector_errors_total` | counter | connector 错误总数（按 product_line） |
| `binance_client_throughput_events_per_second` | gauge | 每产品线吞吐量 |
| `binance_client_spool_size_bytes` | gauge | spool 文件大小 |
| `binance_client_checkpoint_position` | gauge | checkpoint 位置 |

### 18.2 Logging

| 事件 | 级别 | 字段 |
|------|------|------|
| connector started | info | product_line, stream_id |
| connector reconnecting | warn | product_line, stream_id, attempt |
| event normalized | debug | product_line, raw_symbol |
| event mapped | debug | product_line, instrument_key |
| event spooled | debug | idempotency_key |
| send attempt | debug | event_count |
| ack received | debug | acked_count, checkpoint_position |
| send failed retryable | warn | error, retry_count |
| send failed terminal | error | error, idempotency_key |
| checkpoint advanced | info | product_line, position |
| spool full | error | current_size_mb, max_size_mb |
| identity collision detected | error | raw_symbol, product_lines |

### 18.3 Structured Log Fields

所有日志必须包含：product_line、stream_id。按级别可选包含：raw_symbol、instrument_key、idempotency_key、checkpoint_position。

---

## 19. Security

- 不硬编码 Binance API Key、Secret Key、或任何凭证
- 不在日志中记录 API Key、Secret Key、或签名原文
- admin 端点不暴露 secrets
- admin 变更操作（pause/resume）仅允许本地访问（绑定 `127.0.0.1`）
- gRPC 通信使用 TLS（生产环境）
- catalog reload 的输入必须校验，防止注入非法 product_line 配置
- spool 文件权限设为 `0600`（仅 owner 可读写）

---

## 20. CI Gate

### 20.1 通用 Gate（所有模块）

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 编译 | `go build ./...` | 零错误 |
| 测试 | `go test ./... -race -count=1` | 全部通过 |
| 覆盖率 | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | ≥ 80% |
| Vet | `go vet ./...` | 零警告 |
| Lint | `golangci-lint run` | 零警告 |
| 依赖 | `go mod tidy && git diff --exit-code` | 无变更 |
| 安全 | `gitleaks detect --no-git` | 零泄露 |
| Benchmark | `go test -bench=. -benchmem` | 在预算内 |

### 20.2 Client 专属 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 边界检查（server） | `go list -deps ./... \| grep -q 'binance/server' && exit 1 \|\| exit 0` | 零匹配 |
| 边界检查（storage） | `go list -deps ./... \| grep -qE 'storage/\|query/\|strategy/' && exit 1 \|\| exit 0` | 零匹配 |
| Spool 状态机测试 | `go test -run TestSpoolStateMachine ./...` | 全部通过 |
| Checkpoint 安全测试 | `go test -run TestCheckpointSafety ./...` | 全部通过 |
| 幂等键稳定性测试 | `go test -run TestIdempotencyKeyStability ./...` | 全部通过 |

---

## 21. Upgrade Compatibility

| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| 新增产品线 connector | 向后兼容 | 更新配置启用即可 |
| spool schema 变更 | Breaking | 提供迁移脚本，旧 spool 事件需重放或丢弃（以 checkpoint 为界） |
| gRPC wire contract 变更（contracts §8.4 侧） | Breaking（如有字段删除/重命名） | 同步更新 contracts 版本，client 适配新 DTO |
| checkpoint 格式变更 | Breaking | 提供 checkpoint 迁移工具；若不可迁移，清空 checkpoint 从当前 spool 位置重建 |
| admin 端点路径变更 | Breaking | 更新监控和运维脚本 |
| 配置项新增 | 向后兼容 | 新配置有默认值，无需手动迁移 |
| 配置项删除/重命名 | Breaking | 提供迁移说明，旧配置项在过渡期标记 deprecated |

---

## 22. Release DoD

- [ ] 全部 4 条产品线 catalog 可加载
- [ ] parser 区分 Spot/USDⓈ-M/COIN-M/Options 身份
- [ ] 4 个 connector 均可产生规范化事件
- [ ] mapper 使用 domain-market 类型输出规范事件
- [ ] 事件在发送前已 spool
- [ ] checkpoint 仅在 server ACK 后推进
- [ ] gRPC sender 重连时与 server 幂等配合无重复投递
- [ ] client admin 仅操作本地状态
- [ ] client 不 import server internals（CI 边界检查通过）
- [ ] client 不 import storage/query/strategy
- [ ] 所有 FR 实现完成
- [ ] 所有 TC 编写并全部通过
- [ ] 覆盖率 ≥ 80%
- [ ] Performance Budget 全部达标
- [ ] CI Gate 全部通过
- [ ] 追溯矩阵更新完成
- [ ] spec 状态更新为 Implemented

---

## 23. Open Questions

### Blocking（阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | proto 定义是否已在 contracts 中确定？gRPC 流定义（`IngestRequest` 格式）需要 contracts 侧确认 | 已解决：`module/contracts/SPEC.md` §8.4 已定义全部 wire types（2026-06-17） | ZoneCNH |

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-002 | spool 清理策略：acked 事件是定时清理还是按大小阈值？ | 已解决：双重策略 — 时间 TTL 7 天为主，1GB 大小上限为辅（2026-06-17） | ZoneCNH |
| OQ-003 | connector 是否需要支持 Binance 多 endpoint 负载均衡？ | 已解决：v1 默认单 endpoint；多 endpoint 轮询/故障切换作为 v1.1 增强；通过配置 `endpoints[]` 启用（2026-06-17） | - |
| OQ-004 | admin 是否需要认证（即使仅绑定 localhost）？ | 已解决：v1 默认 localhost-only 无需认证；生产环境通过反向代理（nginx/Caddy）添加认证；v1.1 可考虑内置 API key（2026-06-17） | - |

### Future（未来考虑）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-005 | 是否需要支持 Binance WebSocket 多路复用（组合流）以减少连接数？ | 待评估 | - |
| OQ-006 | 是否需要支持 compressed payload 传输以降低 gRPC 带宽？ | 待评估 | - |
| OQ-007 | 是否需要支持 client 横向扩展（多实例分片采集不同产品线）？ | 待评估 | - |
