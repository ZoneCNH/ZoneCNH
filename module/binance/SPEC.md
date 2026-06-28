# module/binance SPEC

- Status: Proposed Final
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-16
- Layer: 数据域 · 交易所行情采集
- Module-Version: v1.0.0
- Repository: [github.com/ZoneCNH/binance](https://github.com/ZoneCNH/binance)
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/contracts`, `module/domain-market`, `module/market-data`

---

## 1. 摘要

`module/binance` 定义 Binance 交易所专用的行情数据 C/S 采集边界。它将 Binance 集成从被动 SDK / 旧 Provider 模型升级为显式的 client/server 采集架构，由 `module/binance/client` 和 `module/binance/server` 两个子模块构成。

```text
Binance Exchange
  ↓
module/binance/client
  ↓ contracts-defined gRPC stream
module/binance/server
  ↓ downstream dispatch port
module/market-data
```

---

## 2. 问题与背景

量化交易系统需要从 Binance 交易所采集全产品线行情数据。直接使用 Binance SDK 或沿用旧 `binance-market` Provider 模式存在以下问题：

- 旧 `binance-market` Provider 模式将采集与分发耦合在一起，无法独立扩展或替换
- 无标准化的幂等投递语义，重连时可能产生重复下游数据
- 无显式的 ACK/checkpoint 机制，client 无法确认 server 是否已持久化接收
- Binance 多产品线（Spot / USDⓈ-M / COIN-M / Options）的 instrument 标识无统一碰撞避免策略
- 事件格式未规范化为 canonical domain model，下游消费者需各自适配 Binance 原生格式

---

## 3. 目标

- 提供 Binance 全产品线行情数据的 C/S 采集通道（Spot / USDⓈ-M / COIN-M / Options）
- 实现 client 端 at-least-once 投递 + server 端幂等接收
- 定义双向流式 gRPC ACK/checkpoint 协议，使 client 可精确推进 checkpoint
- 将 Binance 原生事件规范化为 canonical `MarketFactEnvelope`
- 确保跨产品线 instrument 标识无碰撞
- 提供 client/server 独立的健康检查与管理端点
- 边界门禁可在 CI 中自动执行

---

## 4. 非目标

### 4.1 What module/binance OWNS

`module/binance` root 拥有：

- Binance 模块 goal 与 top-level boundary policy
- client/server 拆分架构
- root traceability、实现序列、运行时映射
- no-legacy-`binance-market` 规则

`module/binance/client` 拥有：

- Binance 交易所-facing 数据采集（REST/WebSocket 适配器）
- 产品线 catalog
- Binance symbol 解析
- Binance 原生事件 → canonical envelope 映射
- client 端 idempotency key 生成
- client 端 SQLite spool 与 checkpoint
- gRPC sender
- client admin 端点

`module/binance/server` 拥有：

- Binance 专用 gRPC ingest server
- `MarketDataService` 的 Binance 实现
- stream 生命周期管理
- event 校验
- server 端幂等接收
- ACK / reject 分类
- 持久化接收边界
- 下游 dispatch
- server admin 端点

### 4.2 What module/binance MUST NOT own

- canonical domain model 定义（→ `module/domain-market`）
- proto 兼容性治理（→ `module/contracts`）
- 行情数据存储引擎（→ `module/market-data`）
- 查询 API / 策略 API
- 下单执行 / 交易信号 / 组合会计
- 跨交易所通用采集服务
- 旧 `binance-market` Provider 兼容

---

## 5. 消费者

| 消费者 | 使用方式 |
|--------|----------|
| `module/market-data` | 从 server dispatch 端口接收 canonical market-data events，写入存储引擎 |
| `module/factor-engine` | 通过 market-data 查询接口消费行情数据 |
| `module/backtest-engine` | 通过 market-data 查询接口回放历史行情 |

---

## 6. 功能需求

### FR-001: Binance 数据采集

**功能描述**：Client 通过 Binance REST/WebSocket 采集全产品线行情数据。

WHEN client 启动且 product-line 已启用
THEN client 建立对应的 REST/WebSocket 连接，开始采集

WHEN WebSocket 连接断开
THEN client 自动重连，从最近 checkpoint 恢复

WHEN 收到 Binance 原生事件
THEN client 将其写入本地 SQLite spool

### FR-002: Canonical 事件映射

**功能描述**：Client 将 Binance 原生事件映射为 canonical market-data envelope。

WHEN client 从 spool 读取 Binance 原生事件
THEN client 将其映射为 canonical `MarketFactEnvelope`
AND 填充 `InstrumentKey`、`ProductLine`、`InstrumentType`、`OptionType`、`PriceKind`、`MarketScope` 等字段
AND 设置 `decision_time`

WHEN Binance 原生字段缺少 canonical 所需信息
THEN client 使用 product-line 配置补全缺失字段

### FR-003: gRPC 流式投递

**功能描述**：Client 通过 contracts 定义的 gRPC bidirectional stream 向 server 投递 canonical events。

WHEN client 有待投递的 canonical events
THEN client 打开 `MarketDataService.Ingest` bidirectional stream
AND 流式发送 `IngestRequest`（含 client 生成的 idempotency key）

WHEN gRPC stream 断开
THEN client 重连并从未 ACK 的 checkpoint 恢复投递

WHEN server 返回 `IngestAck`
THEN client 解析 ACK，确认哪些 events 已被持久化接收

### FR-004: 幂等接收

**功能描述**：Server 对重复 event 执行幂等接收，确保下游不产生重复。

WHEN server 收到 `IngestRequest` 且 idempotency key 未见过
THEN server 接受 event，写入持久化边界，返回 ACK（status=accepted）

WHEN server 收到 `IngestRequest` 且 idempotency key 已见过
THEN server 返回 ACK（status=duplicate），不产生下游副作用

WHEN server 收到 `IngestRequest` 且校验失败
THEN server 返回 ACK（status=rejected），含 reject reason

### FR-005: Checkpoint 推进

**功能描述**：Client 仅在收到 durable ACK 后推进 checkpoint。

WHEN client 收到 ACK 且 `durable_acceptance=true`
THEN client 推进本地 checkpoint，标记对应 spool 记录为已投递

WHEN client 收到 ACK 且 `durable_acceptance=false`
THEN client 不推进 checkpoint，按 retry hint 重试

WHEN client 在超时内未收到 ACK
THEN client 重发未确认的 events

### FR-006: 产品线标识

**功能描述**：Events 携带无碰撞的产品线和 instrument 标识。

WHEN client 产出 canonical event
THEN `ProductLine` 字段区分 Spot / USDⓈ-M / COIN-M / Options
AND `InstrumentKey` 包含 exchange + product_line + instrument_type + base_asset + quote_asset + margin_asset + settlement_asset + contract_code + expiry + strike + option_type

WHEN 同一 symbol 跨 product line 出现（如 BTCUSDT Spot vs BTCUSDT USDⓈ-M perpetual vs BTCUSD COIN-M perpetual vs BTC-YYYYMMDD-STRIKE-C/P Option）
THEN `InstrumentKey` 可区分，不产生碰撞

### FR-007: 管理端点

**功能描述**：Client 和 server 各自暴露 Gin admin HTTP 端点。

WHEN 请求 `GET /healthz`
THEN 返回进程存活状态（liveness only）

WHEN 请求 `GET /readyz`
THEN 返回模块就绪状态（不检查下游业务正确性）

WHEN 请求 `GET /debug/*`
THEN 返回只读调试信息，不得暴露 secrets

WHEN 请求 `/admin/*`
THEN 可变更本地服务状态；对外暴露时必须认证

---

## 7. 行为约束

| 编号 | 规则 | 违反后果 |
|------|------|----------|
| BR-001 | 禁止引用旧 `binance-market` 代码或模块 | 架构回退：旧 Provider 模式无 client/server 分离，破坏 C/S 边界 |
| BR-002 | Client 不得 import server 内部包 | 编译失败：client/server 隔离是架构硬边界 |
| BR-003 | Server 不得 import client 内部包 | 编译失败：违反单向数据流（exchange → client → server → market-data） |
| BR-004 | Client/server 通信必须使用 `contracts` 定义的 gRPC | 契约绕过：绕过 contracts 导致接口不可治理 |
| BR-005 | Domain 语义（InstrumentKey / ProductLine / MarketFactEnvelope 等）必须来自 `module/domain-market` | 语义分叉：自行定义导致下游 consumer 不一致 |
| BR-006 | Wire protocol（proto 定义）必须来自 `module/contracts` | 协议分叉：proto 分散定义导致兼容性不可控 |
| BR-007 | Product line × instrument 组合必须全局无碰撞 | 数据污染：不同产品线的同 symbol 事件混淆，下游无法区分 |
| BR-008 | Secrets（API Key / Secret）不得出现在 log、debug 端点、admin 端点输出中 | 安全泄露：凭证暴露导致交易所账户风险 |
| BR-009 | Client 不得在收到 `durable_acceptance=true` 前推进 checkpoint | 数据丢失：未确认持久化即丢弃 spool 记录 |
| BR-010 | `module/binance` 不得拥有 storage / query / strategy 逻辑 | 职责越界：侵入 market-data / factor-engine 等领域 |
| BR-011 | Admin 端点对外暴露时必须认证 | 安全风险：未授权者修改服务状态 |

---

## 8. 接口契约

### 8.1 gRPC Ingest Service

`module/contracts` 定义 `MarketDataService`。`module/binance/server` 实现该服务。`module/binance/client` 调用该服务。Wire-level service name 可保持 generic，但运行时实现是 Binance-specific。

```proto
service MarketDataService {
  rpc Ingest(stream IngestRequest) returns (stream IngestAck);
}
```

选择 bidirectional streaming 的理由：

- client 持有本地 spool
- client 需要精确的 checkpoint 推进
- server 必须区分 accepted / rejected events
- 重连不得产生重复下游副作用

### 8.2 IngestRequest

```go
type IngestRequest struct {
    StreamID       string              // stream 标识
    IdempotencyKey string              // 幂等键（client 生成）
    Event          *MarketFactEnvelope // canonical event
    SequenceNum    int64               // stream 内单调递增序号
}
```

### 8.3 IngestAck

ACK 必须包含以下信息：

```go
type IngestAck struct {
    StreamID           string         // 对应 stream
    AcceptedKeys       []string       // 已接受的 idempotency keys
    AcceptedRangeStart int64          // 已接受的 sequence 范围起点
    AcceptedRangeEnd   int64          // 已接受的 sequence 范围终点
    Rejections         []RejectReason // 拒绝明细
    DurableAcceptance  bool           // 是否已持久化
    RetryHint          string         // 重试建议
}

type RejectReason struct {
    IdempotencyKey string
    Reason         string
}
```

### 8.4 Admin HTTP Endpoints

```text
GET  /healthz    # liveness only
GET  /readyz     # module readiness (not downstream business correctness)
GET  /debug/*    # read-only debug info (no secrets)
POST /admin/*    # mutate local service state only (authenticated when non-local)
```

---

## 9. 数据模型

### 9.1 ProductLine

| 值 | 说明 | Client Connector |
|----|------|------------------|
| `spot` | Binance 现货 | Spot connector |
| `usd-m` | USDT/USDC 保证金期货 | USDⓈ-M connector |
| `coin-m` | 币本位保证金期货 | COIN-M connector |
| `option` | Binance 期权 | Options connector |

### 9.2 InstrumentKey（最小标识维度）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `exchange` | string | ✅ | 交易所标识 |
| `product_line` | string | ✅ | 产品线（spot / usd-m / coin-m / option） |
| `instrument_type` | string | ✅ | 合约类型（perpetual / delivery / option） |
| `base_asset` | string | ✅ | 基础资产 |
| `quote_asset` | string | ✅ | 计价资产 |
| `margin_asset` | string | ❌ | 保证金资产 |
| `settlement_asset` | string | ❌ | 结算资产 |
| `contract_code` | string | ❌ | 合约代码 |
| `expiry` | time.Time | ❌ | 到期日 |
| `strike` | decimal.Decimal | ❌ | 行权价 |
| `option_type` | string | ❌ | call / put |

### 9.3 Canonical 类型依赖

以下类型由 `module/domain-market` 定义，`module/binance` 消费：

| 类型 | 用途 |
|------|------|
| `InstrumentKey` | 合约全局唯一标识 |
| `ProductLine` | 产品线枚举 |
| `InstrumentType` | 合约类型枚举 |
| `OptionType` | 期权方向枚举 |
| `PriceKind` | 价格类型枚举 |
| `MarketScope` | 行情范围枚举 |
| `MarketFactEnvelope` | canonical 事件信封 |
| `decision_time` | 决策时间戳字段 |

---

## 10. 配置模式

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `binance.endpoints.rest` | string | `https://api.binance.com` | REST API 基地址 |
| `binance.endpoints.ws` | string | `wss://stream.binance.com:9443` | WebSocket 基地址 |
| `binance.product_lines` | []string | `["spot"]` | 启用的产品线 |
| `binance.symbols.allowlist` | []string | `[]` | symbol 白名单（空=全部） |
| `binance.symbols.denylist` | []string | `[]` | symbol 黑名单 |
| `grpc.target` | string | `localhost:9000` | gRPC server 地址 |
| `spool.path` | string | `./spool/` | SQLite spool 路径 |
| `checkpoint.path` | string | `./checkpoint/` | checkpoint 文件路径 |
| `retry.max_attempts` | int | `5` | 最大重试次数 |
| `retry.backoff_ms` | int | `1000` | 重试退避间隔（毫秒） |
| `admin.bind` | string | `localhost:8080` | admin HTTP 绑定地址 |
| `observex.level` | string | `info` | 日志级别 |
| `binance.api_key` | string | （从环境变量读取） | Binance API Key |
| `binance.api_secret` | string | （从环境变量读取） | Binance API Secret |

---

## 11. 错误处理

| 错误 | 触发条件 | 处理方式 |
|------|----------|----------|
| `ErrProductLineDisabled` | 配置中未启用的 product line 被引用 | client 跳过该 product line，记录 warn log |
| `ErrInvalidSymbol` | symbol 格式不符合 Binance 规范 | 记录 warn log，跳过该 symbol |
| `ErrCanonicalMapping` | Binance 原生字段无法映射到 canonical envelope | 记录 error log，event 进入 DLQ |
| `ErrGRPCStreamBroken` | gRPC stream 断开 | client 重连，从 checkpoint 恢复投递 |
| `ErrACKTimeout` | 超时未收到 ACK | client 重发未确认 events |
| `ErrDuplicateEvent` | idempotency key 已存在 | server 返回 duplicate ACK，不产生下游副作用 |
| `ErrValidationFailed` | event 校验失败 | server 返回 rejected ACK + reject reason |
| `ErrCheckpointCorrupt` | checkpoint 文件损坏 | client 从 spool 最旧未 ACK 记录重建 checkpoint |

---

## 12. 边界情况

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| 同一 symbol 跨 product line | BTCUSDT 同时存在于 Spot 和 USDⓈ-M | `InstrumentKey` 不同（product_line 字段区分），事件独立投递 |
| Idempotency key 重复 | 两事件使用相同 idempotency key | server 判定为 duplicate，返回 duplicate ACK |
| ACK 丢失 | client 发送 event 后未收到 server ACK | client 超时重发，server 幂等处理（at-least-once + idempotent） |
| gRPC stream 中断 | 网络断开 | client 重连，从最近 checkpoint 恢复投递 |
| Spool 磁盘满 | SQLite spool 写入失败 | client 暂停采集，触发告警 |
| Checkpoint 文件损坏 | 磁盘故障或写入中断 | client 从 spool 最旧未 ACK 记录重建 |
| Server 重启 | 内存中幂等 key 缓存丢失 | server 从持久化边界重建幂等 key 缓存 |
| Product line 未启用 | 配置中 `product_lines=[]` | client 不启动任何采集连接 |
| Symbol 黑名单命中 | symbol 在 denylist 中 | client 跳过该 symbol |
| Admin 端点无认证 | 外部网络访问 `/admin/*` | 拒绝请求，返回 401 |
| 大量 symbols 订阅 | symbols 数量 > 1000 | 分批采集，不超过交易所 rate limit |

---

## 13. 目录结构

```text
module/binance/
├── SPEC.md                  # 本文件（root spec）
├── README.md                # 模块文档
├── goal.md                  # 模块目标
├── IMPLEMENTATION-PLAN.md   # 实现计划
├── RUNTIME-MAPPING.md       # 运行时映射
├── BOUNDARY-GATES.md        # 边界门禁
├── TRACEABILITY.md          # 追溯矩阵
├── client/
│   ├── SPEC.md              # client 规格
│   ├── go.mod               # client Go module
│   ├── adapters/            # Binance REST/WebSocket 适配器
│   ├── catalog/             # 产品线 catalog
│   ├── normalize/           # Binance 原生 → canonical 映射
│   ├── spool/               # SQLite spool
│   ├── checkpoint/          # checkpoint 管理
│   ├── sender/              # gRPC sender
│   └── admin/               # client admin 端点
├── server/
│   ├── SPEC.md              # server 规格
│   ├── go.mod               # server Go module
│   ├── ingest/              # MarketDataService 实现
│   ├── validate/            # event 校验
│   ├── dedup/               # 幂等接收
│   ├── dispatch/            # 下游分发
│   └── admin/               # server admin 端点
└── testdata/                # 共享测试数据
```

---

## 14. 依赖

### 14.1 可以依赖

| 依赖 | 用途 | 来源 |
|------|------|------|
| stdlib | 基础库 | 标准库 |
| `module/contracts` | gRPC service 定义、proto | ZoneCNH |
| `module/domain-market` | canonical domain 类型（InstrumentKey, MarketFactEnvelope 等） | ZoneCNH |
| `module/domain-exchange` | 交易所领域模型 | ZoneCNH |
| `google.golang.org/grpc` | gRPC 通信 | 第三方 |
| `github.com/gin-gonic/gin` | admin HTTP 端点 | 第三方 |
| `github.com/mattn/go-sqlite3` | client spool | 第三方 |

### 14.2 禁止依赖

| 禁止依赖 | 原因 |
|----------|------|
| 所有业务域实现（`market-data`、`factor-engine`、`signal-engine`、`risk-engine`、`order-engine` 等） | 数据域不反向依赖分析/决策/执行域 |
| 旧 `binance-market` | 已废弃架构，违反 BR-001 |
| 其他交易所采集模块（`bybit`、`okx` 等） | 交易所间独立，不共享实现 |
| `module/binance/client` ← `module/binance/server` | 违反 BR-003 |
| `module/binance/server` ← `module/binance/client` | 违反 BR-002 |

---

## 15. 测试

### 15.1 测试矩阵

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 集成 | client 启动，连接 Binance testnet | WebSocket 连接成功，收到行情数据 |
| TC-002 | FR-002 | 单元 | Binance 原生 trade event → canonical `MarketFactEnvelope` | 所有必填字段正确填充 |
| TC-003 | FR-003 | 集成 | client 通过 gRPC stream 发送 event | server 收到 event |
| TC-004 | FR-004 | 单元 | 相同 idempotency key 发送两次 | 第一次 accepted，第二次 duplicate |
| TC-005 | FR-005 | 单元 | client 收到 ACK（`durable_acceptance=true`） | checkpoint 推进 |
| TC-006 | FR-005 | 单元 | client 收到 ACK（`durable_acceptance=false`） | checkpoint 不推进，触发重试 |
| TC-007 | FR-006 | 单元 | 构造 BTCUSDT Spot 和 BTCUSDT USDⓈ-M perpetual 的 InstrumentKey | 两个 InstrumentKey 不相等 |
| TC-008 | FR-007 | 集成 | `GET /healthz` | 返回 200 |
| TC-009 | FR-007 | 集成 | `GET /readyz`（server 未就绪） | 返回 503 |

### 15.2 测试工具

- 框架：`testing` + `testify`
- Mock：`testkitx`
- 覆盖率：`go tool cover`
- 竞态：`go test -race`
- 集成测试：Binance testnet

### 15.3 边界测试

- Idempotency key 碰撞场景
- gRPC stream 中断与重连
- ACK 超时与重发
- Spool 满、checkpoint 损坏等故障注入

---

## 16. 性能预算

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| Binance 原生事件 → canonical 映射 | 延迟 P99 | < 1ms | `go test -bench` |
| Client spool 写入 | 延迟 P99 | < 5ms | `go test -bench` |
| gRPC 单 event 投递（loopback） | 延迟 P99 | < 10ms | `go test -bench` |
| Server 幂等检查 | 延迟 P99 | < 1ms | `go test -bench` |
| ACK 往返（client → server → client） | 延迟 P99 | < 50ms | 集成测试 |
| Client 采集吞吐（单 product line） | 吞吐 | > 1000 events/s | benchmark |

---

## 17. 可观测性

### 17.1 Metrics

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `binance.client.events.collected` | counter | 采集的原始事件数（按 product_line 分组） |
| `binance.client.events.sent` | counter | 投递的 canonical events 数 |
| `binance.client.events.retried` | counter | 重试投递的事件数 |
| `binance.client.ack.lag_ms` | histogram | ACK 延迟分布（ms） |
| `binance.server.events.accepted` | counter | server 接受的 events 数 |
| `binance.server.events.rejected` | counter | server 拒绝的 events 数（按 reason 分组） |
| `binance.server.events.duplicate` | counter | 重复 events 数 |
| `binance.spool.size_bytes` | gauge | client spool 当前大小 |

### 17.2 Logging

| 事件 | 级别 | 说明 |
|------|------|------|
| `binance.client.connected` | info | WebSocket 连接建立（含 product_line） |
| `binance.client.disconnected` | warn | WebSocket 断开（含 product_line） |
| `binance.client.event.mapped` | debug | 原生事件已映射为 canonical |
| `binance.client.ack.received` | debug | 收到 server ACK |
| `binance.client.ack.timeout` | warn | ACK 超时 |
| `binance.server.event.accepted` | debug | event 已持久化接收 |
| `binance.server.event.rejected` | warn | event 校验失败（含 reason） |
| `binance.server.event.duplicate` | info | 重复 event |

日志必须携带 stream / product-line / instrument 上下文。trace correlation ID 在可用时传递。

### 17.3 Health Signals

- `/healthz`：进程存活
- `/readyz`：模块就绪（client：WebSocket 连接正常 + spool 可用；server：gRPC 服务正常 + dispatch 可用）

---

## 18. 安全

- API Key / Secret 从环境变量读取，不硬编码
- Secrets 不得出现在 log、debug 端点、admin 端点输出中
- Admin 端点对外暴露时必须认证
- gRPC 通信在可信网络内可为明文；跨网络部署时需 mTLS
- Client spool 为本地文件，不加密存储（所含 symbol 配置非敏感数据）

---

## 19. CI 门禁

### 19.1 通用 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 编译 | `go build ./...` | 零错误 |
| 测试 | `go test ./... -race -count=1` | 全部通过 |
| 覆盖率 | `go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | ≥ 80% |
| Vet | `go vet ./...` | 零警告 |
| Lint | `golangci-lint run` | 零警告 |
| 依赖 | `go mod tidy && git diff --exit-code` | 无变更 |
| 安全 | `gitleaks detect --no-git` | 零泄露 |

### 19.2 模块专属 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 边界门禁 | `go test -run TestBoundaryGates ./...` | client/server 隔离验证通过 |
| 旧引用扫描 | `grep -r "binance-market" . --include="*.go" \|\| true` | 零匹配（BR-001） |

---

## 20. 升级兼容性

| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| 新增 product line | 向后兼容 | 更新配置 `product_lines`，新增 connector |
| InstrumentKey 新增可选字段 | 向后兼容 | consumer 更新 domain-market 版本 |
| gRPC proto 新增 optional 字段 | 向后兼容 | client/server 同步升级 |
| gRPC proto 删除/修改已有字段 | Breaking | bump major，client/server 同步升级 |
| Admin 端点路径变更 | Breaking | 监控/告警配置同步更新 |
| Canonical envelope 结构变更 | 取决于 domain-market | 遵循 domain-market 的升级策略 |

---

## 21. 发布 DoD

- [ ] `binance-market` 引用已移除或隔离至迁移历史
- [ ] `module/binance/client` 和 `module/binance/server` spec 已完成
- [ ] root / client / server traceability 已完成
- [ ] client / server task sets 可独立执行
- [ ] 投递语义明确为 at-least-once + 幂等接收
- [ ] ACK/checkpoint 语义已定义并实现
- [ ] ProductLine 和 InstrumentKey 碰撞用例已文档化并通过测试
- [ ] 边界门禁可在 CI 中执行且全部通过
- [ ] 运行时映射不将 storage / query / strategy 所有权置于 binance
- [ ] 所有 FR 实现完成
- [ ] 所有 TC 编写并全部通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过
- [ ] Performance Budget 达标
- [ ] 追溯矩阵更新完成
- [ ] spec 状态更新为 Implemented

---

## 22. 待解决问题

### Blocking（阻塞开发）

| ID | 问题 | 状态 |
|----|------|------|
| OQ-001 | `MarketDataService` bidirectional streaming 的 proto 定义是否已在 `contracts` 中落地？ | 待确认 |
| OQ-002 | `MarketFactEnvelope` 及相关 canonical 类型（InstrumentKey / ProductLine / PriceKind 等）是否已在 `domain-market` 中定义？ | 待确认 |

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 |
|----|------|------|
| OQ-003 | 是否需要支持 Binance 测试网切换（spot testnet / futures testnet）？ | 待解决 |
| OQ-004 | Client spool SQLite 是否需要 WAL 模式以外的配置项？ | 待解决 |

### Future（未来考虑）

| ID | 问题 | 状态 |
|----|------|------|
| OQ-005 | 是否将 C/S 采集模式抽象为通用模板，供 Bybit / OKX 等其他交易所复用？ | 待评估 |
| OQ-006 | gRPC stream 是否支持压缩（gzip / snappy）以降低跨 AZ 带宽消耗？ | 待评估 |

---

## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-16 | v1.0.0 | 从 16 节自定义格式重写为项目标准 23 节格式；新增 §2 问题与背景、§3 目标、§5 消费者、§6 WHEN/THEN FR、§7 BR 表（含违反后果）、§8 接口契约（gRPC + ACK 结构体）、§9 数据模型、§11 错误处理表、§12 边界情况表、§14 依赖（允许/禁止）、§15 测试矩阵、§16 性能预算、§17 可观测性（metrics/logging/health）、§18 安全、§19 CI Gate、§20 升级兼容性、§22 待解决问题；全部原有架构决策保留 | ZoneCNH |
