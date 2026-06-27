# SPEC-TEMPLATE.md — C/S Module 23 节规格模板

> **适用**：数据域 C/S 子模块（行情采集 binance/okx/bybit/...、宏观采集 fred/treasury/bea/...）。
>
> **架构类型**：C/S Module — 独立进程，含 `internal/client`（数据源采集）+ `internal/server`（数据服务）+ `internal/cs`（共享类型）。
>
> **参考实现**：[module/binance/spec/SPEC.md](../binance/spec/SPEC.md) — 首个完整 C/S Module 规格。
>
> **使用方式**：复制本文件为 `module/{module}/SPEC.md`，将 `{MODULE}` 替换为实际模块名（如 `okx`、`fred`），填写所有 `{...}` 占位符。

最后更新：2026-06-21

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-21
- Owner: ZoneCNH
- Layer: 数据域 · {行情|宏观}
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/{module}](https://github.com/ZoneCNH/{module})
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), `module/domain_market` (行情) 或 `module/domain_macro` (宏观), `module/contracts`, `module/{dispatch_module}`, `module/transportx`

> 架构类型：**[C/S Module](../../ARCHITECTURE.md#模块架构类型)** — 含 `internal/client`（采集）+ `internal/server`（服务）+ `internal/cs`（共享类型）
>
> 子模块规格（可选）：`module/{module}/client/SPEC.md`、`module/{module}/server/SPEC.md`

---

## 2. Summary

`module/{module}` 是 {数据源名称} 专属 {行情|宏观}数据 C/S Module，定义数据从 {数据源} 采集到 ZoneCNH 内部摄入的完整边界。

```text
{数据源} Exchange / API
  ↓
module/{module}/client          ← 数据源侧采集器
  ↓ contracts-defined gRPC / 传输契约
module/{module}/server          ← 摄入受理服务器
  ↓ downstream dispatch port
module/{dispatch}               ← 数据源中立的下游管线
```

子模块 `client` 负责连接 {数据源}、解析和规范化数据；`server` 负责验证、去重、ACK 和下游分发。

---

## 3. Problem

{数据源} 数据集成面临以下问题：

1. **旧 SDK 模型职责不清**：采集、转换、持久化边界模糊，新增数据维度时无法确定代码归属。
2. **无明确传输契约**：采集端产出的数据"向谁发送"未定义，server 侧 ingest 接受语义缺失。
3. **{数据源特有痛点 1}**：{描述}
4. **可靠性无保障**：at-least-once delivery + idempotent acceptance + ACK-driven checkpoint 的端到端语义未定义。
5. **边界侵蚀**：模块容易引入 storage/query/strategy 所有权，违背数据域"采集后即交付"的架构原则。

---

## 4. Goals

- 定义 client/server 双端架构，client 拥有数据源侧采集，server 拥有摄入受理
- 支持 {数据源} 全部 {N} 条 {产品线|数据维度}
- 通过 contracts-defined 传输契约通信
- 明确 at-least-once (client) + idempotent acceptance (server) + ACK-driven checkpoint 交付语义
- 定义 canonical data identity 所需维度
- 定义 enforceable boundary gates，防止跨边界导入和所有权扩散

---

## 5. Non-goals

`module/{module}` 明确不做以下事情：

| 不做 | 原因 |
|------|------|
| 定义 canonical domain model | 由 `module/domain_{market|macro}` 拥有 |
| 定义 proto/gRPC wire contract | 由 `module/contracts` 拥有 |
| 拥有 dispatch/storage engine | 由 `module/{dispatch}` 拥有 |
| 暴露 query API | 属于 `module/{dispatch}` 或下游模块 |
| 实现 strategy API / trading decision | 属于分析域和决策域 |
| 实现 order execution | 属于执行域 |
| 作为跨数据源通用 ingestion server | 本模块仅处理 {数据源}，通用部分在 `module/{dispatch}` |

---

## 6. Consumers

| 消费者 | 使用方式 | 状态 |
|--------|----------|------|
| `module/{dispatch}` | 通过 server downstream dispatch port 接收 canonical events | SPEC Approved, runtime integration pending |
| `module/{module}/client` | 通过 contracts-defined 传输契约调用 `module/{module}/server` | 待实现 |
| `module/{module}/server` | 接收 client 发送的 event 流 | 待实现 |
| Operator / SRE | 通过 client/server admin 端点监控和管理 | 待实现 |
| CI Pipeline | 通过 BOUNDARY-GATES.md 中的 gate 脚本执行边界检查 | 待实现 |

---

## 7. Functional Requirements

### FR-001: Data Source Connectivity

**功能描述**：模块必须连接 {数据源} 并采集 {数据类型}。

**WHEN** 配置启用 {数据维度 1}
**THEN** client 可通过对应 connector 采集 {数据源} 的 {具体数据}

**WHEN** 配置启用 {数据维度 2}
**THEN** client 可通过对应 connector 采集 {具体数据}

### FR-002: Data Identity

**功能描述**：模块生成的数据 identity 必须在不同数据维度间不发生碰撞。

**WHEN** parser 解析 {场景 A} 和 {场景 B}
**THEN** 两者产生不同的 identity（通过 {区分维度} 区分）

### FR-003: Transmission Contract

**功能描述**：client 和 server 之间通过 contracts-defined 传输契约通信。

**WHEN** client 有 canonical event 待发送
**THEN** 通过 contracts-defined 接口发送 event

**WHEN** server 收到有效 event
**THEN** 验证、去重后返回 ACK

**WHEN** server 收到无效 event
**THEN** 返回 Reject，含 machine-readable reject reason

### FR-004: At-Least-Once Delivery

**功能描述**：client 提供 at-least-once 交付语义。

**WHEN** client 规范化并映射一个 event 为 canonical envelope
**THEN** 先将 event 持久化到本地 spool，状态为 `pending`

**WHEN** server 返回 durable ACK 确认接受
**THEN** client 将 spool 状态更新为 `acked` 并推进 checkpoint

**WHEN** 发送成功但 server 未确认 durable acceptance
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

**功能描述**：client 和 server 各自暴露 admin 端点。

**WHEN** 请求 `GET /healthz`
**THEN** 返回 process liveness 状态（200 或 503）

**WHEN** 请求 `GET /readyz`
**THEN** 返回模块就绪状态（200 或 503）

**WHEN** 请求 `GET /debug/*`
**THEN** 返回只读诊断信息，不暴露 secrets

### FR-007: Boundary Enforcement

**功能描述**：模块边界通过 CI gate 强制执行。

**WHEN** client 代码尝试 import server internal 包
**THEN** CI boundary gate 失败

**WHEN** 模块内声明 storage/query/strategy 所有权
**THEN** CI ownership gate 失败

### FR-008: Bootstrap Integration

**功能描述**：模块通过 bootstrap 组装为独立进程。

**WHEN** `cmd/{module}-server/main.go` 调用 `bootstrap.Build(ctx, Spec{Module, Stores=None})`
**THEN** 模块获得 config/observe/lifecycle 标准化组装

**WHEN** 收到 SIGTERM/SIGINT
**THEN** 逆序 Stop 注册的组件，幂等清理资源

---

## 8. Business Rules

### BR-001: Client Must Not Import Server Internals

**规则**：client 不得 import server internal 包。

**约束**：`internal/client` 与 `cmd/{module}-client` → 禁止 import `internal/server/*`。允许 client → `module/contracts`、`module/domain_{market|macro}` 语义类型、shared config/observability。

**违反时**：CI boundary gate 失败。

### BR-002: Server Must Not Import Client Internals

**规则**：server 不得 import client internal 包。

**约束**：`internal/server` 与 `cmd/{module}-server` → 禁止 import `internal/client/*`。允许 server → `module/contracts`、`module/domain_{market|macro}` 语义类型、`module/{dispatch}` downstream port、shared config/observability。

**违反时**：CI boundary gate 失败。

### BR-003: Checkpoint Requires ACK

**规则**：client checkpoint 仅可在 server 返回 durable ACK 后推进。

**约束**：禁止在 serialization 成功、local enqueue 成功、send attempt 成功后推进 checkpoint。

**违反时**：spool 状态机拒绝 transition；重启后 checkpoint 回退到上一个 durable ACK 位置。

### BR-004: No Domain Ownership

**规则**：`module/{module}` 不得定义 canonical domain semantics 的 source of truth。

**约束**：canonical enum/type 必须来自 `module/domain_{market|macro}`。模块可定义数据源特定 parsing/mapping，但输出必须是对 domain 类型的引用。

**违反时**：CI ownership gate 失败。

### BR-005: No Storage/Query/Strategy Ownership

**规则**：`module/{module}` 不得拥有 storage engine、query API 或 strategy API。

**约束**：server downstream dispatch port 只做 handoff，不实现物理存储。禁止引入 storage/strategy 作为 owned dependency。

**违反时**：CI ownership gate 失败。

### BR-006: Wire Contract Externality

**规则**：`module/{module}` 不得定义自己的 proto 文件或 wire schema。

**约束**：proto 定义和 code generation 由 `module/contracts` 拥有。

**违反时**：CI gate 失败。

### BR-007: Idempotency Key Stability

**规则**：client 生成的 idempotency key 必须在 retry 场景下稳定。

**约束**：key 必须基于 {数据源} + 数据维度 + identity + event_type + event_time/source_sequence 等确定性维度生成。

**违反时**：retry 时 server 无法识别重复，产生 duplicate downstream effect。

---

## 9. Interface Contract

### Ingestion Service (defined by module/contracts)

```go
// {ServiceName} receives normalized upstream {data_type} ingestion requests.
// Defined in module/contracts/SPEC.md.
// Implemented by module/{module}/server.
// Called by module/{module}/client.
//
// THIS INTERFACE IS OWNED BY module/contracts — reproduced here for spec clarity only.
type {ServiceName} interface {
    // Ingest accepts an event stream and returns per-event outcomes.
    Ingest(ctx context.Context, event *IngestRequest) (*IngestResult, error)
}
```

**Wire DTOs** (全部由 `module/contracts` 拥有)：

| DTO | 说明 |
|-----|------|
| `IngestRequest` | 采集端提交的归一化事件（含 request_id, source, identity, event_type, event_time, payload, source_metadata） |
| `IngestResult` | `Ack *IngestAck` 或 `Reject *IngestReject`（exactly one non-nil） |
| `IngestAck` | request_id, identity, accepted_at, durable |
| `IngestReject` | request_id, reject_code, reason, details |

### Downstream Dispatch Port

Server 通过数据源中立的 downstream port 将 accepted events 分发给 `module/{dispatch}`。该 port 的具体接口由 `module/{dispatch}` SPEC 定义；server 只做 handoff 适配。

---

## 10. Data Model

### Canonical Concepts (owned by module/domain_{market|macro})

| Concept | Purpose | Owned By |
|---------|---------|----------|
| `{IdentityType}` | Unique data identity across dimensions | `domain_{market|macro}` |
| `{DimensionType}` | 数据维度枚举 | `domain_{market|macro}` |
| `{EnvelopeType}` | Canonical event wrapper | `domain_{market|macro}` |

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

## 11. Config Schema

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `{module}.endpoints.rest` | `string` | `{数据源 API URL}` | REST API base URL |
| `{module}.endpoints.ws` | `string` | `{WebSocket URL}` | WebSocket base URL（如适用） |
| `{module}.data_dimensions` | `[]string` | `[]` | 启用的数据维度（canonical domain 值） |
| `{module}.symbols.allow` | `[]string` | `[]` | 白名单（空=全部） |
| `{module}.symbols.deny` | `[]string` | `[]` | 黑名单 |
| `server.addr` | `string` | `localhost:9090` | server 监听地址 |
| `spool.path` | `string` | `./spool` | spool 文件路径 |
| `spool.max_size_mb` | `int` | `1024` | spool 最大大小 (MB) |
| `checkpoint.path` | `string` | `./checkpoint` | checkpoint 文件路径 |
| `retry.max_attempts` | `int` | `5` | 最大重试次数 |
| `retry.backoff_initial` | `duration` | `1s` | 初始退避时间 |
| `retry.backoff_max` | `duration` | `60s` | 最大退避时间 |
| `admin.bind` | `string` | `:8080` | admin HTTP 绑定地址 |

> **Security**：API keys、secrets、signatures 从环境变量注入，不从配置文件读取。禁止在 logs 和 admin/debug 端点暴露。

---

## 12. Error Handling

| 错误 | 触发条件 | 处理方式 | 错误码 |
|------|----------|----------|--------|
| `ErrDataDimensionDisabled` | 配置未启用的 data dimension 被请求 | 记录日志，跳过 | `{MOD}-001` |
| `ErrInvalidData` | parser 无法解析数据源原始数据 | 结构化错误返回，记录原始数据 | `{MOD}-002` |
| `ErrSpoolFull` | spool 超过 max_size | 阻塞接收，触发告警 | `{MOD}-003` |
| `ErrCheckpointStale` | checkpoint 落后超过阈值 | 触发告警，暂停新数据采集 | `{MOD}-004` |
| `ErrConnectFailed` | 无法连接 server | 指数退避重试，spool 继续累积 | `{MOD}-005` |
| `ErrDuplicateConflict` | server 收到同一 key 但不同 payload 的 event | terminal reject，记录冲突详情 | `{MOD}-006` |
| `ErrValidation` | server 收到缺少必需字段的 event | terminal reject，含 machine-readable reason | `{MOD}-007` |
| `ErrDispatchFailed` | downstream dispatch 失败 | 重试（指数退避），超过阈值告警 | `{MOD}-008` |

---

## 13. Edge Cases

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| 数据维度身份碰撞 | 两个不同维度产生相似 identity | parser 产生不同 identity，维度区分 |
| Client 进程重启 | spool 中有 `pending`/`sending` 事件 | 从 checkpoint 位置恢复发送，duplicate 由 server idempotency 消解 |
| 传输断连 | server 不可达或网络中断 | client 退避重连，spool 状态保持 `sending`，checkpoint 不推进 |
| Server 已接受后崩溃 | durable acceptance 完成但 ACK 未发给 client | client 重发同一 key，server 返回 idempotent ACK |
| Spool 写满 | spool 达到 max_size | 阻塞新数据接收，触发 `ErrSpoolFull` 告警 |
| Idempotency key 冲突 | 同一 key 但不同 payload 到达 server | server 返回 `terminal_conflict` reject |
| 无效数据 | parser 收到未知格式的数据 | 返回结构化 `ErrInvalidData`，不产生 canonical event |
| 数据维度禁用 | 配置中 data dimension 未启用 | connector 不订阅该维度的 stream |
| Downstream dispatch 持续失败 | dispatch 下游不可用 | 指数退避重试，超过阈值告警，不丢失已 accepted event |

---

## 14. Directory Structure

### Documentation (`module/{module}/`)

```text
module/{module}/
  goal.md                          # 模块 Goal 文档
  README.md                        # 模块索引
  SPEC.md                          # 本文件 — 模块完整规格
  TRACEABILITY.md                  # 需求追溯矩阵
  IMPLEMENTATION-PLAN.md           # 实现计划（PR 序列）
  BOUNDARY-GATES.md                # CI 边界门禁定义
  RUNTIME-MAPPING.md               # 规格到 runtime 仓库映射
  tasks/                           # Root 层 task spec
  client/                          # Client 子模块（可选）
    SPEC.md
    TRACEABILITY.md
    tasks/
  server/                          # Server 子模块（可选）
    SPEC.md
    TRACEABILITY.md
    tasks/
```

### Runtime (`github.com/ZoneCNH/{module}/`)

```text
github.com/ZoneCNH/{module}/
  go.mod
  cmd/
    {module}-server/main.go        # bootstrap.Build() 独立进程入口
  internal/
    client/                         # 数据源采集
      connector/                    #   数据源连接器
      parser/                       #   数据解析器
      mapper/                       #   canonical 映射器
      idempotency/                  #   幂等 key 生成
      spool/                        #   本地 spool
      checkpoint/                   #   checkpoint 管理
      sender/                       #   发送器
      admin/                        #   admin 端点
    server/                         # 摄入受理
      ingest/                       #   接收处理
      validation/                   #   验证
      idempotency/                  #   幂等性检查
      dispatch/                     #   downstream 分发
      admin/                        #   admin 端点
    cs/                             # client-server 共享类型
  pkg/
    {module}x/                      # 公开 adapter（供 composer 注册）
      adapter.go
      version.go
  test/
    contract/
    integration/
    fixtures/
```

---

## 15. Dependencies

### Allowed Dependencies

| 依赖 | 用途 | 消费方 |
|------|------|--------|
| `module/domain_{market|macro}` | canonical 语义类型 | client mapper, server validation |
| `module/contracts` | 传输契约（wire types） | client sender, server ingest |
| `module/{dispatch}` | downstream dispatch port | server dispatch |
| `module/transportx` | 传输策略、retry/backoff 约定、admin 约定 | client, server |
| `module/bootstrap` | 进程组装（config/observe/lifecycle） | `cmd/{module}-server` |

### Forbidden Dependencies

| 禁止导入 | 原因 |
|----------|------|
| `internal/client/*` (在 server 中) | 违反 client/server 边界 |
| `internal/server/*` (在 client 中) | 违反 client/server 边界 |
| `github.com/ZoneCNH/storage` (as owned) | storage ownership 属于 dispatch |
| `github.com/ZoneCNH/strategy` (as owned) | strategy ownership 属于分析/决策域 |

---

## 16. Testing

### Test Matrix

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 集成 | 启用 {数据维度}，连接数据源 | connector 产生 canonical events |
| TC-002 | FR-002 | 单元 | parser 输入 {碰撞场景} | 产生不同 identity |
| TC-003 | FR-003 | 契约 | client 发送 event → mock server | server 收到有效请求 |
| TC-004 | FR-004 | 集成 | 发送 event 后 kill client 进程，重启 | spool 中的 event 从 checkpoint 位置恢复 |
| TC-005 | FR-005 | 集成 | 发送同一 idempotency key 两次 | server 返回 idempotent ACK，downstream 仅 dispatch 一次 |
| TC-006 | FR-005 | 集成 | 发送同一 key 但不同 payload | server 返回 terminal_conflict reject |
| TC-007 | FR-006 | 单元 | GET /healthz | 返回 200 |
| TC-008 | FR-007 | CI | client 代码 import server internal | boundary gate 失败，CI exit 1 |
| TC-009 | FR-008 | 集成 | 启动 `cmd/{module}-server` | bootstrap 组装完成，进程正常运行 |

### Test Tools

- 框架：`testing` + `testify`
- Mock：`testkitx`
- 覆盖率：`go test -cover`
- 竞态：`go test -race`
- 进程测试：`cmd/{module}-server` smoke test

---

## 17. Performance Budget

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| Client event normalization | 延迟 P99 | < 1ms | `go test -bench` |
| Canonical mapping | 延迟 P99 | < 100μs | `go test -bench` |
| Spool write | 延迟 P99 | < 5ms | `go test -bench` |
| Event send (单 event) | 延迟 P99 | < 10ms | integration test |
| Server validation | 延迟 P99 | < 100μs | `go test -bench` |
| Server idempotency check | 延迟 P99 | < 1ms | `go test -bench` |
| ACK lag (receive → ACK send) | P99 | < 100ms | integration test |
| Client restart recovery | 时间 | < 10s | integration test |

---

## 18. Observability

### Metrics

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `{module}_client_raw_events_total` | counter | 收到的原始事件数（per dimension） |
| `{module}_client_events_normalized_total` | counter | 规范化后的事件数 |
| `{module}_client_events_mapped_total` | counter | 映射为 canonical 的事件数 |
| `{module}_client_events_spooled_total` | counter | spool 写入的事件数 |
| `{module}_client_events_sent_total` | counter | 发送成功的事件数 |
| `{module}_client_ack_lag_seconds` | histogram | ACK 延迟 |
| `{module}_client_retry_total` | counter | 重试次数 |
| `{module}_client_connects_total` | counter | 连接/重连次数 |
| `{module}_server_connections_active` | gauge | 活跃连接数 |
| `{module}_server_events_accepted_total` | counter | 接受的唯一事件数 |
| `{module}_server_events_duplicate_total` | counter | 重复事件数 |
| `{module}_server_events_rejected_total` | counter | 拒绝事件数（per reject_reason） |
| `{module}_server_dispatch_latency_seconds` | histogram | downstream dispatch 延迟 |

### Logging

| 事件 | 级别 | 必要字段 |
|------|------|----------|
| Connection established/disconnected | info | connection_id |
| Event accepted | debug | connection_id, dimension, identity, idempotency_key |
| Event rejected | warn | connection_id, reject_reason, idempotency_key |
| Duplicate detected | debug | connection_id, idempotency_key |
| Dispatch failed | error | connection_id, identity, error |
| Checkpoint advanced | debug | checkpoint_position, connection_id |
| Spool near capacity | warn | spool_usage_percent |

### Tracing

| Span 名 | 说明 |
|---------|------|
| `{module}.client.normalize` | 原始事件规范化 |
| `{module}.client.map` | 映射为 canonical event |
| `{module}.client.spool_write` | spool 写入 |
| `{module}.client.send` | 事件发送 |
| `{module}.server.validate` | server 端验证 |
| `{module}.server.idempotency_check` | 幂等性检查 |
| `{module}.server.dispatch` | downstream dispatch |

---

## 19. Security

- 禁止硬编码 API key、secret、signature
- 所有 secret 从环境变量注入，不在 config 文件中存储
- `/debug/*` 和 `/admin/*` 端点不得暴露 secrets、API keys、签名或私有配置
- Admin 端点在暴露于非本地可信网络时必须使用认证
- 日志中禁止记录 API key、secret、signature、完整 payload（仅记录 metadata）
- Client/server 通信建议使用 mTLS（由 `module/transportx` TLS policy 指导）
- 输入校验：所有收到的数据源原生 payload 在进入 parser 前验证基本结构
- Idempotency store 不暴露外部查询接口

---

## 20. CI Gate

### 通用 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 编译 | `go build ./...` | 零错误 |
| 测试 | `go test ./... -race -count=1` | 全部通过 |
| 覆盖率 | `go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out` | ≥ 80% |
| Vet | `go vet ./...` | 零警告 |
| Lint | `golangci-lint run` | 零警告 |
| 安全 | `gitleaks detect --no-git` | 零泄露 |
| 依赖 | `go mod tidy && git diff --exit-code` | 无变更 |

### C/S Module 专属 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| Client/server boundary | boundary gate script | 零跨边界 import |
| Ownership | ownership gate script | 零 storage/query/strategy 所有权声明 |
| Contracts only | contracts gate script | 零 local proto 文件 |
| Domain source | domain gate script | 零独立 canonical enum 定义 |
| Admin boundary | admin gate script | 零跨模块 admin mutation |
| Checkpoint requires ACK | checkpoint gate script | 零 send-only checkpoint advance |

---

## 21. Upgrade Compatibility

| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| 新增数据维度 | 向后兼容 | 添加 connector + parser rule |
| IngestRequest / IngestAck 变更 | 取决于 contracts 兼容策略 | 升级 contracts 版本，regenerate client/server |
| Canonical domain type 变更 | 取决于 domain 兼容策略 | 更新 mapper，regenerate 测试 fixtures |
| Spool schema 变更 | 可能需要 migration | 提供 spool migration 工具或清空重建 |
| Admin endpoint 新增 | 向后兼容 | 无迁移需求 |

---

## 22. Release DoD

`module/{module}` v1.0.0 发布完成标准：

- [ ] Client 和 server specs 完成并通过 spec-lint
- [ ] Root/client/server TRACEABILITY.md 完成，所有需求可追溯
- [ ] Client/server task sets 独立可执行
- [ ] Delivery semantics 明确为 at-least-once + idempotent acceptance（FR-004, FR-005）
- [ ] ACK/checkpoint semantics 已定义且 testable（BR-003）
- [ ] Data identity 碰撞 case 已文档化（FR-002, §10 Data Model）
- [ ] Boundary gates 可在 CI 执行（FR-007, BOUNDARY-GATES.md）
- [ ] Runtime mapping 未将 storage/query/strategy ownership 放在模块内（BR-005）
- [ ] `cmd/{module}-server` 通过 bootstrap 组装为独立进程（FR-008）
- [ ] 所有 FR 实现完成，所有 AC 验证通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过（通用 + C/S Module 专属）
- [ ] Performance Budget 达标
- [ ] Integration test 演示 `client → server → downstream port` 完整数据流

---

## 23. Open Questions

### Blocking（阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | `module/contracts` 的传输契约是否已就绪？ | 待确认 | contracts owner |
| OQ-002 | `module/{dispatch}` 的 downstream dispatch port 接口是否已定义？ | 待确认 | dispatch owner |

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-003 | server idempotency store 的 backing storage 选型（in-memory / SQLite / Redis）？ | 待定 | module owner |
| OQ-004 | 是否需要多 endpoint 切换？ | 待评估 | module owner |

### Future（未来考虑）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-005 | 是否需要压缩传输 payload？ | 待评估 | performance |
| OQ-006 | 其他同类数据源是否参照此 C/S 架构统一？ | 待评估 | architecture |

---

## 使用指南

1. 复制本文件为 `module/{module}/SPEC.md`
2. 全局替换 `{module}` → 实际模块名（如 `okx`、`fred`）
3. 全局替换 `{MOD}` → 错误码前缀（如 `OKX`、`FRD`）
4. 替换 `{数据源}` → 实际数据源名称（如 `OKX`、`美联储 FRED`）
5. 替换 `{dispatch}` → 对应的 dispatch 模块名（行情 → `market_data`，宏观 → `macro_data`）
6. 行情类选择 `domain_market`，宏观类选择 `domain_macro`
7. 填写 §3 Problem 的数据源特有痛点
8. 填写 §7 FR 的数据源特有维度
9. 填写 §10 Data Model 的 canonical 类型
10. 填写 §11 Config 的数据源特有配置项
11. 确保每个 FR 有 WHEN/THEN
12. 确保每个 BR 有"违反时"处理
13. 确保每个 TC 对应至少一个 FR
14. 运行 `spec-lint.sh` 验证结构
15. 提交 PR，进入 Review

---

## 相关文档

| 文档 | 用途 |
|------|------|
| [`ARCHITECTURE.md`](../../ARCHITECTURE.md#模块架构类型) | C/S Module 架构类型定义 |
| [`module/binance/spec/SPEC.md`](../binance/spec/SPEC.md) | C/S Module 参考实现 |
| [`docs/governance/module-governance/09-data-cs-governance-levels.md`](../../docs/governance/module-governance/09-data-cs-governance-levels.md) | C/S Module L1/L2/L3 治理等级 |
| [`docs/governance/module-governance/templates/GOVERNANCE-TEMPLATE.md`](../../docs/governance/module-governance/templates/GOVERNANCE-TEMPLATE.md) | C/S Module 治理模板 |
| [`docs/governance/SPEC-TEMPLATE.md`](../../docs/governance/SPEC-TEMPLATE.md) | 通用 23 节 SPEC 模板 |
| [`docs/governance/LIFECYCLE.md`](../../docs/governance/LIFECYCLE.md) | 规格生命周期状态机 |
| [`docs/governance/TRACEABILITY.md`](../../docs/governance/TRACEABILITY.md) | 追溯矩阵规范 |
| [`.github/ci/spec-lint.sh`](../../.github/ci/spec-lint.sh) | 结构校验脚本 |
