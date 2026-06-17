# module/binance/server SPEC

- Status: Review
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-17
- Owner: ZoneCNH
- Layer: 数据域
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/binance-server](https://github.com/ZoneCNH/binance-server)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [module/contracts](../../contracts/), [module/domain-market](../../domain-market/), [module/market-data](../../market-data/)

---

## 1. Metadata

| 字段 | 值 |
|------|-----|
| Module | `module/binance/server` |
| Go Module Path | `github.com/ZoneCNH/binance-server` |
| Layer | 数据域 · 行情接入层 |
| Role | Binance 行情数据的 gRPC ingest server |
| Port Interface | `contracts.MarketDataService` (gRPC streaming) |
| Language | Go |
| Status | Draft |

---

## 2. Summary

`module/binance/server` 是 Binance 行情数据的 gRPC 接入服务端。它接收来自 `module/binance/client` 的已规范化行情事件，执行校验、幂等去重、持久化验收，然后通过 exchange-neutral downstream port 将事件分发到 `module/market-data` 下游基础设施。服务端对外暴露 gRPC streaming ingest 接口和 Gin admin HTTP 端点。

---

## 3. Problem

Binance 行情接入需要服务端边界确保数据质量和可靠性。直接让 client 写入下游存储存在以下问题：

- **数据质量无防护**：缺少服务端校验层，畸形或缺失字段的事件可能进入下游
- **重复投递无保护**：网络重传或 client 重试会导致同一事件被多次处理，缺少幂等验收边界
- **验收语义模糊**：client 无法确定事件何时被"可靠接受"，checkpoint 推进时机不明确
- **下游耦合**：client 直接写入存储暴露了存储实现细节，违反数据域边界
- **无运维面**：缺少流状态、验收统计、排水模式等管理能力

---

## 4. Goals

- 实现 `contracts` 定义的 `MarketDataService` gRPC streaming 接口
- 对每条 ingest request 执行完整信封校验
- 基于 idempotency key 实现幂等验收，保证每条 key 最多被 dispatch 一次
- 提供 durable acceptance 边界：ACK 返回前事件已持久化或进入可靠队列
- 通过 exchange-neutral downstream port 将验收事件分发到 `module/market-data`
- 提供 Gin admin HTTP 端点（health、stats、drain）
- 提供完整的可观测性指标（active streams、accepted/rejected/duplicate counts、latency）

---

## 5. Non-goals

- 不做 Binance REST/WebSocket 适配（由 `module/binance/client` 负责）
- 不做 exchange connectivity（由 `module/binance/client` 负责）
- 不做 client-side spool/checkpoint 管理（由 `module/binance/client` 负责）
- 不做 canonical domain type 定义（由 `module/contracts` 负责）
- 不做 proto 定义（由 `module/contracts` 负责）
- 不做物理存储引擎实现（由 `module/market-data` 或存储扩展负责）
- 不做 query API（由 `module/market-data` 负责）
- 不做 strategy API（由决策域负责）
- 不做跨交易所通用 ingest server（本模块仅 Binance）
- 不做旧 `binance-market` 兼容

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `module/binance/client` | 通过 gRPC bidi stream 推送 `IngestRequest`，消费 `IngestAck` 推进 checkpoint |
| `module/market-data` | 通过 downstream port 接收已验收的行情事件 |
| `SRE / 运维` | 通过 Gin admin HTTP 端点查询流状态、触发排水 |

---

## 7. Functional Requirements

### FR-001: gRPC Server Binding

**WHEN** server 启动且 gRPC port 可用
**THEN** 绑定 `MarketDataService` 到 gRPC server 并开始接受 stream 连接

**WHEN** server 收到 `Ingest` bidi stream 请求
**THEN** 创建 stream context 并开始接收 `IngestRequest` 消息

### FR-002: Stream Lifecycle

**WHEN** client 打开新的 ingest stream
**THEN** 分配 stream_id 并初始化 stream-scoped 统计计数器

**WHEN** client 正常关闭 stream（EOF）
**THEN** 清理 stream 资源并记录最终统计

**WHEN** stream 因网络错误中断
**THEN** 释放 stream 资源，不阻塞其他 stream

### FR-003: Request Validation

**WHEN** 收到 `IngestRequest`
**THEN** 校验 required envelope 字段（product_line、instrument identity、event type、event time、idempotency key、source metadata）全部存在且有效

**WHEN** product_line 不在支持列表中
**THEN** 返回 reject，类别为 `terminal_validation`

**WHEN** instrument identity 结构无效
**THEN** 返回 reject，类别为 `terminal_validation`

**WHEN** event type 未知
**THEN** 返回 reject，类别为 `terminal_validation`

**WHEN** event time 无效（零值或未来时间超阈值）
**THEN** 返回 reject，类别为 `terminal_validation`

**WHEN** idempotency key 缺失
**THEN** 返回 reject，类别为 `terminal_validation`

**WHEN** domain enum 值不被识别
**THEN** 返回 reject，类别为 `terminal_validation`

**WHEN** payload shape 与 event type 不匹配
**THEN** 返回 reject，类别为 `terminal_validation`

**WHEN** 所有校验通过
**THEN** 进入 idempotency 检查阶段

### FR-004: Idempotent Acceptance

**WHEN** idempotency key 未被接受过
**THEN** 进入 durable acceptance 阶段

**WHEN** idempotency key 已被接受且 payload 一致
**THEN** 返回 ACK，标记为 idempotent duplicate，不重复 dispatch

**WHEN** idempotency key 已被接受但 payload 冲突
**THEN** 返回 reject，类别为 `terminal_conflict`

### FR-005: Durable Acceptance

**WHEN** event 通过校验和幂等检查
**THEN** 执行 durable acceptance（持久化 idempotency record 或写入可靠队列）

**WHEN** durable acceptance 成功
**THEN** 生成 ACK 并 dispatch 到 downstream port

**WHEN** durable acceptance 失败（存储不可用、队列满）
**THEN** 返回 reject，类别为 `retryable`，不标记 event 为已接受

**Idempotency Store 后端选择**:
- 生产默认：Redis（SCADA-redis 共享实例，TTL 24h + Lua CAS 原子操作），适用于多实例共享和跨重启持久化
- 开发/测试：in-memory（sync.Map + TTL GC），通过 `IdempotencyStore` 接口切换，仅用于本地单实例场景
- 接口抽象：`CheckAndSet(ctx, key, payloadHash) -> (accepted bool, conflict bool, err error)`

### FR-006: ACK Generation

**WHEN** event 通过 durable acceptance
**THEN** 生成 ACK 包含：stream_id、accepted idempotency key、accepted count、duplicate count、rejects list、durable acceptance indicator

**WHEN** event 被 reject
**THEN** reject 包含：stream_id、rejected idempotency key、reject classification（retryable / terminal_validation / terminal_conflict）、retry hint

**WHEN** 返回 ACK/reject
**THEN** 数据足够 client 推进 checkpoint

### FR-007: Downstream Dispatch

**WHEN** event 通过 durable acceptance
**THEN** 通过 exchange-neutral downstream port 将 event 分发到 `module/market-data`

**WHEN** downstream dispatch 失败
**THEN** 采用 retry-first + dead-letter 策略：
  1. 立即重试 dispatch（最多 3 次，指数退避 100ms/200ms/400ms）
  2. 重试耗尽后写入 dead-letter spool，触发 `alertx` 告警，不阻塞后续事件
  3. 不回滚幂等记录：ACK 已发送，client checkpoint 已推进，回滚代价大于收益
  4. Dead-letter 事件可通过 `/admin/dead-letter` 端点查看、重放或丢弃

**设计理由**: durable acceptance 成功后，幂等记录已持久化且 ACK 已返回 client。回滚（rollback-first）需撤销幂等记录 + 通知 client 撤回 ACK，显著增加复杂度和延迟，且收益有限——idempotency 层本身已防止重复。retry-first + dead-letter 在保障数据不丢失的同时保持 pipeline 简洁。

### FR-008: Admin HTTP Endpoints

**WHEN** `GET /healthz`
**THEN** 返回 200（进程存活）

**WHEN** `GET /readyz`
**THEN** 返回 200（gRPC server 就绪，下游可连通），否则 503

**WHEN** `GET /debug/*`
**THEN** 返回调试信息（pprof 等，仅 debug 模式启用）

**WHEN** `GET /admin/streams`
**THEN** 返回活跃 stream 列表及统计

**WHEN** `POST /admin/drain`
**THEN** 进入排水模式：拒绝新 stream，等待现有 stream 完成

---

## 8. Business Rules

### BR-001: Idempotency Key — Accept At Most Once

**规则**: 每条 idempotency key 最多被 durable accept 一次，最多产生一次 downstream dispatch。

**约束**: idempotency store 必须在 durable acceptance 阶段原子写入，check-and-set 语义。

**违反时**: 重复 key 的第二次请求：若 payload 一致返回 ACK（idempotent duplicate）；若 payload 冲突返回 `terminal_conflict` reject。

### BR-002: Duplicate With Conflicting Payload → Reject

**规则**: 同一 idempotency key 的不同 payload 必须被拒绝。

**约束**: idempotency store 必须存储已接受 event 的 payload hash，用于冲突检测。

**违反时**: 返回 `terminal_conflict` reject。冲突不触发 dispatch，不覆盖已接受的数据。

### BR-003: ACK Only After Durable Acceptance

**规则**: ACK（包含 durable acceptance indicator = true）必须在 durable acceptance 完成后才能发送。

**约束**: 禁止在 idempotency check 通过但 durable write 未完成时发送 ACK。

**违反时**: 若 durable write 失败但已发送 ACK → client 可能跳过未持久化的事件，数据丢失。server 必须确保 ACK 仅在实际持久化后发送。

### BR-004: Validation Failure → No Checkpoint Advancement

**规则**: 终端校验失败（terminal_validation）不应推进 client checkpoint。

**约束**: reject 分类为 `terminal_validation` 时，client 不应将对应 event 视为已消费。

**违反时**: client 推进 checkpoint 会导致该失败 event 被跳过。server 通过 reject classification 告知 client 正确处理方式。

### BR-005: Admin Surface Isolation

**规则**: Admin 端点只能变更 server-local 状态，禁止：
- 修改 client connector
- 删除 client checkpoint
- 绕过 idempotency
- 暴露 secrets
- 触发交易操作

**约束**: Admin handler 只能访问 server 内部状态（stream registry、idempotency store stats、dispatch stats）。

**违反时**: 操作被拒绝并记录 security event。

### BR-006: Server Must Not Import Client Internals

**规则**: server 禁止 import `module/binance/client` 的任何 internal 包或类型。

**约束**: server 与 client 之间仅通过 `contracts` §8.4 中定义的 gRPC wire contract 类型通信。

**违反时**: 编译失败（依赖方向违反 ARCHITECTURE.md 数据域边界）。

---

## 9. Interface Contract

### 9.1 gRPC Service（由 contracts §8.4 定义）

```go
// MarketDataService receives normalized upstream market-data ingestion requests.
// Defined in module/contracts/SPEC.md §8.4.
type MarketDataService interface {
    Ingest(stream IngestRequest) (stream IngestResult, error)
}
```

server 负责实现该接口的 server 端。每个 `IngestRequest` 返回一个 `IngestResult`，其中 exactly one of `Ack` or `Reject` is non-nil。

### 9.2 Downstream Port（exchange-neutral）

```go
// MarketDataSink 下游行情数据接收端口
type MarketDataSink interface {
    // Accept 接受已验收的行情事件
    Accept(ctx context.Context, event *MarketEvent) error
}
```

### 9.3 Gin Admin Routes

```text
GET  /healthz
GET  /readyz
GET  /debug/*
GET  /admin/streams
POST /admin/drain
```

---

## 10. Data Model

### IngestRequest / IngestResult / IngestAck / IngestReject / RejectCode（由 contracts §8.4 定义）

权威定义见 `module/contracts/SPEC.md` §8.4。以下为 server 视角的关键语义摘要：

| contracts §8.4 类型 | server 侧语义 |
|---|---|
| `IngestRequest` | 接收：12 字段（request_id/source/product_line/instrument_key/event_type/event_time/received_at/schema_version/payload/sequence/ordering_key/source_metadata）。`request_id` 即幂等键 |
| `IngestResult` | 返回：per-request 终端结果，exactly one of `Ack` or `Reject` non-nil |
| `IngestAck` | 接受确认：stream_id + accepted_count + duplicate_count + durable indicator |
| `IngestReject` | 拒绝说明：reject_code（RejectCode 枚举）+ reason + retryable flag |
| `RejectCode` | 10 个机器可读拒绝码：retryable / terminal_validation / terminal_conflict / unauthorized / rate_limited / server_unavailable / contract_violation / quality_rejected / ordering_violation / unsupported_channel |

**server 必须处理全部 10 个 RejectCode 路径**。`contract_violation`、`quality_rejected`、`ordering_violation`、`unsupported_channel` 为 contracts §8.4 新增码（此前 SPEC 仅列 3 个，本次同步至 contracts v1.2.0 的 10 码定义），server validation 层和 idempotency 层需全部覆盖。

---

## 11. Config Schema

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `server.grpc_addr` | string | `:9090` | gRPC 监听地址 |
| `server.admin_addr` | string | `:8080` | Admin HTTP 监听地址 |
| `server.max_streams` | int | `100` | 最大并发 stream 数 |
| `idempotency.store` | string | `memory` | 幂等存储类型：memory / redis |
| `idempotency.ttl` | duration | `24h` | 幂等记录保留时间 |
| `idempotency.max_entries` | int | `1000000` | 幂等记录最大条目数 |
| `dispatch.timeout` | duration | `5s` | 下游 dispatch 超时 |
| `dispatch.retry_max` | int | `3` | dispatch 失败最大重试次数 |
| `validation.future_time_threshold` | duration | `5m` | 未来时间容忍阈值 |
| `observability.log_level` | string | `info` | 日志级别 |

---

## 12. Error Handling

| 错误 | 触发条件 | 处理方式 | Reject 分类 |
|------|----------|----------|-------------|
| Envelope validation failure | 缺少必填字段或字段无效 | 返回 reject，不进入幂等检查 | `terminal_validation` |
| Unsupported product_line | product_line 不在白名单 | 返回 reject | `terminal_validation` |
| Unknown event type | event_type 不在注册表 | 返回 reject | `terminal_validation` |
| Invalid event time | 零值或未来时间超阈值 | 返回 reject | `terminal_validation` |
| Idempotency conflict | key 已存在但 payload hash 不匹配 | 返回 reject，不 dispatch | `terminal_conflict` |
| Durable write failure | 存储不可用或写入失败 | 返回 reject，不标记已接受 | `retryable` |
| Downstream dispatch failure | 下游不可达或超时 | 取决于策略：retry 或 rollback | `retryable` |
| Stream quota exceeded | 超过 max_streams | 拒绝新 stream 连接 | — (gRPC resource_exhausted) |

**错误消息格式**: `"binance-server: <operation>: <detail>"`
**错误包装**: 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| Stream 断连恢复 | client stream 网络中断后重连 | server 释放旧 stream 资源；client 新 stream 从未 ACK 的 event 继续推送；server 幂等检查保证不重复 dispatch |
| Duplicate key + conflicting payload | idempotency key 已存在，payload hash 不同 | 返回 `terminal_conflict` reject；不 dispatch；不覆盖已有数据 |
| Downstream dispatch 失败 | dispatch 到 `module/market-data` 超时或不可达 | 若策略为 rollback：撤销幂等记录，返回 `retryable` reject 让 client 重试；若策略为 retry：记录失败 metric，后台重试，ACK 已返回但 durable_indicator=false |
| Idempotency store 满 | 幂等记录达到 `max_entries` | 拒绝新 event，返回 `retryable` reject；告警触发 |
| 并发推送同一 key | 两个 stream 同时推送相同 idempotency key | check-and-set 语义保证仅一个 stream 获得 accept，另一个返回 idempotent duplicate 或 terminal_conflict |
| Payload 为空 | event_type 正确但 payload 为空 | 取决于 event type schema：若支持空 payload 则通过；否则返回 `terminal_validation` |
| Admin drain 时有活跃 stream | drain 模式开启，仍有活跃 ingest stream | 拒绝新 stream 连接；等待现有 stream 自然结束或超时后强制关闭 |
| gRPC server 未就绪时收到 /readyz | 下游 dispatch port 不可达 | `/readyz` 返回 503 |

---

## 14. Directory Structure

```text
binance-server/
├── go.mod
├── go.sum
├── README.md
├── SPEC.md
├── server.go                  # gRPC server 绑定、stream handler 主循环
├── server_test.go             # server 核心逻辑测试
├── validate.go                # 请求校验
├── validate_test.go
├── idempotency.go             # 幂等检查与 idempotency store 接口
├── idempotency_test.go
├── idempotency_memory.go      # 内存 idempotency store 实现
├── idempotency_redis.go       # Redis idempotency store 实现
├── dispatch.go                # 下游 dispatch 逻辑
├── dispatch_test.go
├── ack.go                     # ACK/reject 构造
├── admin.go                   # Gin admin HTTP handler
├── admin_test.go
├── metrics.go                 # observex metrics 注册
├── errors.go                  # 公共错误变量
├── options.go                 # Option 模式配置
├── testdata/
│   └── *.golden               # 测试数据
└── contract_test.go           # 服务端契约测试（与 contracts 对齐）
```

---

## 15. Dependencies

### 15.1 允许的依赖

| 依赖 | 用途 | 来源 |
|------|------|------|
| `module/contracts` | gRPC wire contract（§8.4）：`MarketDataService` 接口 + `IngestRequest`/`IngestResult`/`IngestAck`/`IngestReject`/`RejectCode` DTO | FoundationX 基座 |
| `module/domain-market` | 领域值对象（Instrument、ProductLine 等） | L2.5 领域共享层 |
| `module/market-data` downstream port | 已验收事件的分发目标（仅通过 port interface） | 数据域 |
| `google.golang.org/grpc` | gRPC server runtime | 第三方（标准选择） |
| `github.com/gin-gonic/gin` | Admin HTTP server | 第三方 |
| `configx` | 配置管理 | FoundationX 基座 |
| `observex` | 可观测性集成 | FoundationX 基座 |

### 15.2 禁止的依赖

| 禁止依赖 | 原因 |
|----------|------|
| `module/binance/client` | client 与 server 之间仅通过 contracts proto 通信，禁止 import client internals |
| 任何 exchange connector | exchange 连接由 client 负责，server 不应感知具体交易所 API |
| storage engine 实现 | 存储由 `module/market-data` 或 storage 扩展负责 |
| query API 实现 | server 不暴露查询 API |
| strategy / risk engine | 决策域模块不应被数据域 server 感知 |

### 15.3 依赖方向

```text
contracts (proto 定义)
    ↓
binance/server (实现 gRPC server 端)
    ↓ (通过 exchange-neutral port)
market-data (下游消费)
```

server 不反向依赖 client，二者通过 contracts 解耦。

---

## 16. Testing

### 16.1 测试矩阵

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 单元 | gRPC server 启动绑定 | server 注册成功，端口监听 |
| TC-002 | FR-002 | 单元 | client 正常关闭 stream | stream 清理，最终统计输出 |
| TC-003 | FR-003 | 单元 | 缺少必填字段的 IngestRequest | 返回 terminal_validation reject |
| TC-004 | FR-003 | 单元 | 不支持的 product_line | 返回 terminal_validation reject |
| TC-005 | FR-004 | 集成 | 首次 idempotency key | 通过，进入 dispatch |
| TC-006 | FR-004 | 集成 | 重复 idempotency key（相同 payload） | ACK idempotent duplicate，不 dispatch |
| TC-007 | FR-004 | 集成 | 重复 idempotency key（冲突 payload） | terminal_conflict reject |
| TC-008 | FR-005 | 集成 | durable write 成功 | ACK 含 durable_indicator=true |
| TC-009 | FR-005 | 集成 | durable write 失败 | retryable reject，不标记已接受 |
| TC-010 | FR-006 | 单元 | ACK 包含所有必要字段 | ACK 可驱动 client checkpoint |
| TC-011 | FR-007 | 集成 | dispatch 到下游成功 | event 被下游接受 |
| TC-012 | FR-007 | 集成 | dispatch 到下游失败 | 取决于策略：retry 或 rollback |
| TC-013 | FR-008 | 单元 | GET /healthz | 200 |
| TC-014 | FR-008 | 单元 | GET /readyz（下游不可达） | 503 |
| TC-015 | FR-008 | 单元 | POST /admin/drain | 新 stream 被拒绝 |

### 16.2 契约测试

server 必须通过 contracts 定义的 server-side contract tests：
- 编译期接口检查：`var _ MarketDataServiceServer = (*Server)(nil)`
- ACK 格式满足 contracts 定义的 `IngestAck` schema

### 16.3 测试工具

- 框架：`testing` + `testify`
- Mock：`testkitx` 或 gRPC 内置 mock
- 覆盖率：`go test -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out`
- 竞态：`go test -race -count=1`

---

## 17. Performance Budget

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| Request validation | 延迟 P99 | < 1ms | benchmark test |
| Idempotency check (memory) | 延迟 P99 | < 0.5ms | benchmark test |
| Idempotency check (redis) | 延迟 P99 | < 5ms | benchmark test |
| ACK generation | 延迟 P99 | < 0.5ms | benchmark test |
| End-to-end ingest (validate + idempotency + ACK) | 延迟 P99 | < 10ms | benchmark test |
| Concurrent streams | 吞吐 | ≥ 1000 events/s per stream | `go test -bench` |

---

## 18. Observability

### 18.1 Metrics

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `binance_server_active_streams` | gauge | 当前活跃 ingest stream 数 |
| `binance_server_ingested_total` | counter | 累计接收 ingest request 数 |
| `binance_server_accepted_total` | counter | 累计验收 event 数 |
| `binance_server_duplicate_total` | counter | 累计重复 event 数 |
| `binance_server_rejected_total` | counter | 累计拒绝 event 数（按 reject_class 分组） |
| `binance_server_ack_latency_ms` | histogram | ACK 响应的端到端延迟 |
| `binance_server_dispatch_latency_ms` | histogram | 下游 dispatch 延迟 |
| `binance_server_dispatch_failures_total` | counter | 下游 dispatch 失败计数 |
| `binance_server_idempotency_store_size` | gauge | 幂等记录数 |

### 18.2 Logging

| 事件 | 级别 | 说明 |
|------|------|------|
| stream opened | info | 含 stream_id |
| stream closed | info | 含 stream_id、accepted/rejected/duplicate 计数 |
| event accepted | debug | 含 stream_id、product_line、instrument_key、idempotency_key |
| event rejected | warn | 含 stream_id、idempotency_key、reject_class、reason |
| duplicate detected | info | 含 stream_id、idempotency_key |
| dispatch failed | error | 含 stream_id、idempotency_key、error |
| idempotency store near capacity | warn | 当前条目数 / max_entries |

### 18.3 Required Log Fields

每条 server 日志必须包含：`stream_id`、`product_line`（如适用）、`instrument_key`（如适用）、`idempotency_key`（如适用）、`ack_status`（如适用）、`reject_reason`（如适用）

---

## 19. Security

- 不硬编码 secret、API key、密码 — 全部从环境变量或 `configx` 读取
- 不在日志中记录敏感数据（secret、token、内部路径）
- Admin 端点不应暴露 secrets 或允许绕过 idempotency
- gRPC 传输使用 TLS（生产环境强制）
- 输入校验必须在所有处理之前完成
- 禁止 admin 端点触发交易操作
- 依赖扫描（`gitleaks detect --no-git`）为 CI 门禁

---

## 20. CI Gate

### 20.1 通用 Gate

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

### 20.2 模块专属 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 契约测试 | `go test -run TestContract ./...` | 全部通过 |
| 无 client import | `go list -deps ./... | grep -q 'binance/client' && exit 1 || exit 0` | 零匹配 |
| admin 安全 | `go test -run TestAdminSecurity ./...` | 全部通过 |

---

## 21. Upgrade Compatibility

| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| gRPC wire contract（contracts §8.4）新增 optional 字段 | 向后兼容 | 无需迁移 |
| gRPC wire contract（contracts §8.4）删除/重命名字段 | Breaking | contracts 版本 bump + server 同步升级 |
| 新增 Idempotency store backend | 向后兼容 | 通过 config 切换 |
| 修改 RejectClass 枚举 | Breaking | client 需同步更新分类处理逻辑 |
| 新增 admin endpoint | 向后兼容 | 无需迁移 |
| 修改 ACK 结构 | Breaking | contracts 版本 bump |

遵循 semver：breaking change → major bump；新增功能 → minor bump；修复 → patch bump。

---

## 22. Release DoD

- [ ] 所有 FR-001 ~ FR-008 实现完成
- [ ] gRPC `MarketDataService` 接口全部实现
- [ ] 请求校验覆盖所有必填字段
- [ ] 幂等验收：首次 accept、重复 ACK、冲突 reject 全部正确
- [ ] durable acceptance 正确：ACK 仅在持久化后发送
- [ ] downstream dispatch 通过 exchange-neutral port
- [ ] Gin admin endpoints 全部可用（/healthz, /readyz, /admin/*）
- [ ] 所有 TC-001 ~ TC-015 编写并全部通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过
- [ ] Performance Budget 达标
- [ ] 不 import `module/binance/client` 或任何 storage/query/strategy 模块
- [ ] SPEC.md status 更新为 Implemented

---

## 23. Open Questions

### Blocking（阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | idempotency store 首选实现：in-memory 还是 Redis？ | 已解决：Redis 为主（SCADA-redis 共享实例，TTL 24h + Lua CAS），`IdempotencyStore` 接口保留 in-memory 实现仅用于本地开发/测试（2026-06-17） | ZoneCNH |
| OQ-002 | downstream dispatch 失败策略：retry-first 还是 rollback-first？ | 已解决：retry-first + dead-letter（FR-007）。重试 3 次指数退避后写入死信队列并告警，不回滚幂等记录（2026-06-17） | ZoneCNH |
| OQ-003 | proto 定义是否已在 `module/contracts` 中可用？ | 已解决：`module/contracts/SPEC.md` §8.4 已定义全部 wire types（2026-06-17） | ZoneCNH |

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-004 | idempotency store 是否需要支持跨实例共享（Redis cluster）？ | 已解决 (2026-06-17)：见 §7 FR-005 Idempotency Store 后端选择 — Redis 为生产默认（含 Cluster/Sentinel HA 模式），server 应用层无感；多实例共享与跨重启持久化由 Redis 自身能力承担 | ZoneCNH |
| OQ-005 | admin endpoint 是否需要认证（API key / JWT）？ | 已解决 (2026-06-17)：见 §19 Security — v1 默认 localhost-only 无需认证；生产环境通过反向代理（nginx/Caddy）或 mTLS 添加认证；v1.1 可考虑内置 API key（沿用 client OQ-004 决策模式） | ZoneCNH |

### Future（未来考虑）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-006 | 是否需要支持批量 ingest（一个 request 含多个 event）以提高吞吐？ | 待评估 | — |
| OQ-007 | 是否需要扩展到非 Binance 交易所的 ingest server（模板化）？ | 待评估 | — |

---

## Appendix A: Acceptance Criteria Registry

| AC ID | FR 引用 | 验收标准 | 验证方式 |
|-------|---------|----------|----------|
| AC-001 | FR-001 | gRPC server 绑定成功，接受 stream 连接 | 集成测试 TC-001 |
| AC-002 | FR-003 | 必填字段缺失返回 terminal_validation reject | 单元测试 TC-003 |
| AC-003 | FR-004 | 首次 idempotency key 通过验收 | 集成测试 TC-005 |
| AC-004 | FR-004 | 重复 key 不产生重复 dispatch | 集成测试 TC-006 |
| AC-005 | FR-004 | 冲突 payload 返回 terminal_conflict | 集成测试 TC-007 |
| AC-006 | FR-005 | ACK 仅在 durable acceptance 后发送 | 集成测试 TC-008/TC-009 |
| AC-007 | FR-006 | ACK 包含足够数据推进 client checkpoint | 单元测试 TC-010 |
| AC-008 | FR-007 | 验收 event 分发到 downstream port | 集成测试 TC-011 |
| AC-009 | FR-008 | /healthz 返回 200 | 单元测试 TC-013 |
| AC-010 | FR-008 | drain mode 拒绝新 stream | 单元测试 TC-015 |
| AC-011 | BR-005 | admin 无法绕过 idempotency | admin security test |

## Appendix B: Change History

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-16 | v1.0.0 | 从 12 节格式迁移至 23 节标准格式 | ZoneCNH |
