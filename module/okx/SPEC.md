# module/okx SPEC

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-17
- Owner: ZoneCNH
- Layer: 数据域 · 行情
- Module-Version: v1.0.0-spec
- Repository: [github.com/ZoneCNH/okx](https://github.com/ZoneCNH/okx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [`module/binance`](../binance/), [`module/_template/cex-cs-module/README.md`](../_template/cex-cs-module/README.md), `module/domain-market`, `module/contracts`, `module/market-data`, `module/transportx`

> 子模块规格：`module/okx/client/SPEC.md`、`module/okx/server/SPEC.md`
>
> 本 SPEC 客制化 §1-§10 与 §15 / §19 中的 OKX 特异性内容；§11-§14 / §16-§18 / §20-§23 与 [`module/binance/SPEC.md`](../binance/SPEC.md) 范式保持一致，差异部分显式标注。

---

## 2. Summary

`module/okx` 是 OKX 专属 Market Data C/S Module，定义 OKX 行情数据从交易所采集到 ZoneCNH 内部摄入的完整边界：

```text
OKX Exchange (REST/WebSocket)
  ↓
module/okx/client          ← 交易所侧采集器（5 product lines）
  ↓ contracts-defined gRPC (MarketDataService)
module/okx/server          ← 摄入受理服务器
  ↓ downstream dispatch port
module/market-data         ← 交易所中立的后续管线
```

OKX 与 Binance 在产品线编码上存在关键差异：OKX 单独区分 **Margin** 产品线（Binance 将 Margin 内嵌于 Spot），并使用 `-SWAP` 后缀显式标注永续合约（Binance 使用 USDⓈ-M / COIN-M 隐式区分）。

---

## 3. Problem

OKX 行情集成面临以下问题：

1. **旧 SDK 模型职责不清**：v0.1.1 的 `okx` SDK 是 passive client，采集、转换、持久化边界模糊。
2. **OKX 产品线编码与 Binance 不一致**：
   - Spot：`BTC-USDT`
   - Margin：`BTC-USDT`（与 Spot 同名，仅靠请求参数区分）
   - USDⓈ-M Perp：`BTC-USDT-SWAP`
   - Coin-M Perp：`BTC-USD-SWAP`
   - USDⓈ-M Future：`BTC-USDT-240628`
   - Coin-M Future：`BTC-USD-240628`
   - Options：`BTC-USD-240628-50000-C`
   
   缺少显式 product_line 维度时，Spot/Margin 的 `BTC-USDT` 与下游会发生身份碰撞。
3. **传输契约缺失**：旧 SDK 直接暴露 OKX response，下游每个消费者各自映射 canonical 类型，导致不一致。
4. **可靠性无保障**：at-least-once + idempotent + ACK-driven checkpoint 端到端语义未定义。
5. **OKX 特有的 simulated trading endpoint** 未在采集层显式区分，可能误把模拟数据混入生产管线。

---

## 4. Goals

- 定义 OKX C/S 双端架构，client 拥有交易所侧采集，server 拥有摄入受理
- 支持 OKX 5 条产品线：Spot、Margin、USDⓈ-M Futures/Perp、Coin-M Futures/Perp、Options
- 通过 contracts-defined `MarketDataService` gRPC bidirectional stream 传输
- 明确 at-least-once (client) + idempotent acceptance (server) + ACK-driven checkpoint 交付语义
- 定义 canonical instrument identity 所需维度，覆盖 5 条产品线碰撞场景（特别是 Spot/Margin `BTC-USDT` 同名）
- 显式区分 OKX simulated trading endpoint 与 production endpoint，simulated 数据不进入生产 pipeline
- 移除旧 OKX SDK active 引用

---

## 5. Non-goals

| 不做 | 原因 |
|------|------|
| 定义 canonical domain model | 由 `module/domain-market` 拥有 |
| 定义 proto/gRPC wire contract | 由 `module/contracts` 拥有 |
| 拥有 market-data storage engine | 由 `module/market-data` 拥有 |
| 暴露 query API / strategy API | 不属于数据域 |
| 实现 OKX 下单功能 | 属于执行域 |
| 兼容旧 `okx` SDK passive 接口 | 已硬切移除 |
| 处理跨 CEX 通用 ingestion | 本模块仅 OKX，通用部分在 `module/market-data` |
| 模拟盘数据混入生产 | simulated endpoint 在 client config 层显式隔离 |

---

## 6. Consumers

| 消费者 | 使用方式 | 状态 |
|--------|----------|------|
| `module/market-data` | 通过 server downstream dispatch port 接收 canonical market events | SPEC v1.0.0 已就绪 |
| `module/okx/client` | 通过 contracts-defined gRPC 调用 `module/okx/server` 的 `MarketDataService.Ingest` | 待实现 |
| `module/okx/server` | 接收 client 发送的 `IngestRequest` 流 | 待实现 |
| Operator / SRE | 通过 client/server Gin admin 端点监控和管理 | 待实现 |
| CI Pipeline | 通过 BOUNDARY-GATES（继承 binance 范式）执行边界检查 | 待实现 |

---

## 7. Functional Requirements

### FR-001: Product-Line Support

**WHEN** 配置启用 Spot 产品线 → client 通过 Spot connector 采集 OKX spot data
**WHEN** 配置启用 Margin 产品线 → client 通过 Margin connector 采集（与 Spot 共用 symbol，但订阅 channel 不同）
**WHEN** 配置启用 USDⓈ-M Futures/Perp → client 通过 SWAP connector 采集 USDT/USDC 保证金合约
**WHEN** 配置启用 Coin-M Futures/Perp → client 通过 USD-margined SWAP connector 采集币本位合约
**WHEN** 配置启用 Options → client 通过 Options connector 采集

### FR-002: Instrument Identity

**WHEN** parser 解析 Spot `BTC-USDT`
**THEN** InstrumentKey 包含 `product_line=spot`，与 Margin 同 symbol 不碰撞

**WHEN** parser 解析 Margin `BTC-USDT`
**THEN** InstrumentKey 包含 `product_line=margin`

**WHEN** parser 解析 USDⓈ-M Perp `BTC-USDT-SWAP`
**THEN** InstrumentKey 包含 `product_line=usdm_perp` + `contract_code=BTC-USDT-SWAP`

**WHEN** parser 解析 Coin-M Perp `BTC-USD-SWAP`
**THEN** InstrumentKey 包含 `product_line=coinm_perp` + `settlement_asset=BTC`

**WHEN** parser 解析 USDⓈ-M Future `BTC-USDT-240628`
**THEN** InstrumentKey 包含 `expiry=2026-06-28`

**WHEN** parser 解析 Options `BTC-USD-240628-50000-C`
**THEN** InstrumentKey 包含 `expiry`、`strike=50000`、`option_type=Call`

### FR-003: gRPC Ingestion

> 与 [`module/binance/SPEC.md`](../binance/SPEC.md) §7 FR-003 范式一致：通过 contracts-defined `MarketDataService` bidirectional stream 通信，server 对每条 `IngestRequest` 返回一个 `IngestResult`（exactly one of Ack/Reject is non-nil）。

### FR-004: At-Least-Once Delivery

> 与 binance §7 FR-004 范式一致：client 持久化 spool → 收到 server durable ACK 后才推进 checkpoint。

### FR-005: Idempotent Acceptance

> 与 binance §7 FR-005 范式一致：server 每个 idempotency key 最多接受一次并 downstream dispatch 一次。

### FR-006: Admin Surface

> 与 binance §7 FR-006 范式一致：client 和 server 各自暴露 Gin admin 端点（/healthz, /readyz, /debug/*, /admin/*），仅变更本地状态。

### FR-007: Boundary Enforcement

> 与 binance §7 FR-007 范式一致：CI gate 阻断 client/server 跨界 import、legacy SDK 引用、storage/query/strategy 所有权声明。

### FR-008: Simulated Endpoint Isolation （OKX 特异性）

**功能描述**：OKX 提供 simulated trading endpoint（`/v5/sim`），数据语义与生产盘隔离。

**WHEN** 配置 `okx.endpoints.environment=simulated`
**THEN** client 仅连接 OKX simulated endpoint
**AND** 所有产生的 canonical event 的 `source_metadata.environment=simulated`
**AND** server 拒绝接受 simulated 与 production 混合的 stream（基于 source_metadata 判定）

**WHEN** 配置 `okx.endpoints.environment=production`
**THEN** client 仅连接 OKX production endpoint
**AND** 所有 event 的 `source_metadata.environment=production`

**违反时**：mixed-environment stream 触发 `terminal_validation` reject，告警。

---

## 8. Business Rules

### BR-001 ~ BR-009 与 binance 范式一致

> 详见 [`module/binance/SPEC.md`](../binance/SPEC.md) §8 BR-001 ~ BR-009：
> - BR-001 No legacy SDK（适配为：`okx-market` legacy 不存在；改为禁止旧 passive SDK 接口）
> - BR-002 Client Must Not Import Server Internals
> - BR-003 Server Must Not Import Client Internals
> - BR-004 Checkpoint Requires ACK
> - BR-005 No Domain Ownership
> - BR-006 No Storage/Query/Strategy Ownership
> - BR-007 Wire Contract Externality
> - BR-008 Idempotency Key Stability
> - BR-009 Admin Boundary

### BR-010: Environment Isolation （OKX 特异性）

**规则**：simulated 与 production 数据流必须在 client 配置层显式隔离。

**约束**：
- 同一 client 进程不得同时启用 simulated 与 production endpoint
- canonical event 必须携带 `source_metadata.environment` 字段
- server 必须拒绝单 stream 内出现 `environment` 值漂移的事件

**违反时**：CI gate 检查 client config 不允许同时配置两种 environment；运行时校验失败返回 `terminal_validation` reject。

---

## 9. Interface Contract

### MarketDataService（由 module/contracts §8.4 定义）

> 与 binance 一致。详见 [`module/contracts/SPEC.md`](../contracts/SPEC.md) §8.4。

### OKX-Specific Source Metadata Extension

`IngestRequest.source_metadata` 字段对 OKX 必须包含：

| 字段 | 类型 | 必填 | 说明 |
|------|------|:---:|------|
| `environment` | enum | ✅ | `production` 或 `simulated` |
| `okx_channel` | string | ✅ | OKX WebSocket channel name（如 `tickers`, `books`, `trades-all`） |
| `okx_inst_type` | enum | ✅ | OKX 原生 instType：`SPOT` / `MARGIN` / `SWAP` / `FUTURES` / `OPTION` |
| `okx_inst_id` | string | ✅ | OKX 原生 instId |

server 校验：缺失任一字段 → `terminal_validation` reject。

### Downstream Dispatch Port

> 与 binance 一致。详见 [`module/market-data/SPEC.md`](../market-data/SPEC.md) v1.0.0 §4。

---

## 10. Data Model

### Canonical Event Concepts

> 全部由 `module/domain-market` 拥有。详见 [`module/binance/SPEC.md`](../binance/SPEC.md) §10 Canonical Event Concepts 表。

### Instrument Identity Dimensions（OKX 5 条产品线）

| Dimension | Spot | Margin | USDⓈ-M Perp/Future | Coin-M Perp/Future | Options |
|-----------|:----:|:------:|:------------------:|:------------------:|:-------:|
| exchange | ✅ | ✅ | ✅ | ✅ | ✅ |
| product_line | ✅ | ✅ | ✅ | ✅ | ✅ |
| instrument_type | ✅ | ✅ | ✅ | ✅ | ✅ |
| base_asset | ✅ | ✅ | ✅ | ✅ | ✅ |
| quote_asset | ✅ | ✅ | — | — | — |
| margin_asset | — | ✅ | ✅ | — | — |
| settlement_asset | — | — | — | ✅ | — |
| contract_code | — | — | ✅（`-SWAP` 或 expiry 编码） | ✅ | — |
| expiry | — | — | ✅（仅 Future） | ✅（仅 Future） | ✅ |
| strike | — | — | — | — | ✅ |
| option_type | — | — | — | — | ✅ |

**碰撞场景验证**：
- Spot `BTC-USDT` vs Margin `BTC-USDT` → 通过 `product_line` 区分
- USDⓈ-M Perp `BTC-USDT-SWAP` vs USDⓈ-M Future `BTC-USDT-240628` → 通过 `instrument_type` + `expiry` 区分
- Coin-M Perp `BTC-USD-SWAP` vs USDⓈ-M Perp `BTC-USDT-SWAP` → 通过 `settlement_asset` / `quote_asset` 区分

### Spool State Machine

> 与 binance §10 Spool State Machine 一致：`pending → sending → acked / failed_retryable → pending(retry) / failed_terminal`。

### Reject Classification

> 与 contracts §8.4 RejectCode 10 码一致。

---

## 11. Config Schema

> 与 binance §11 范式一致。OKX 特异配置：

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `okx.endpoints.environment` | `enum` | `production` | `production` / `simulated`（**互斥**） |
| `okx.endpoints.rest` | `string` | `https://www.okx.com` | OKX REST API base URL |
| `okx.endpoints.ws_public` | `string` | `wss://ws.okx.com:8443/ws/v5/public` | OKX 公共行情 WebSocket |
| `okx.endpoints.ws_business` | `string` | `wss://ws.okx.com:8443/ws/v5/business` | OKX 业务 WebSocket（部分高频频道） |
| `okx.product_lines` | `[]string` | `[]` | 启用的产品线：`spot` / `margin` / `usdm_swap` / `coinm_swap` / `usdm_future` / `coinm_future` / `options` |
| `okx.api_key` / `okx.secret_key` / `okx.passphrase` | `string` | 从环境变量读取 | OKX 三段鉴权（`OKX_API_KEY` / `OKX_SECRET_KEY` / `OKX_PASSPHRASE`） |

> 其余 spool / checkpoint / retry / admin 配置与 binance §11 一致。

---

## 12. Error Handling

> 与 binance §12 范式一致。OKX 特异错误码前缀使用 `OKX-`（替代 binance 的 `BNC-`）：

| 错误码 | 触发条件 |
|-------|----------|
| `OKX-001` ~ `OKX-008` | 与 binance 同名错误对齐 |
| `OKX-101` | 同时配置 simulated 与 production endpoint |
| `OKX-102` | 收到的 `environment` 字段与 client 配置不一致 |

---

## 13. Edge Cases

> 与 binance §13 范式一致。OKX 特有 edge cases：

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| Spot/Margin 同名碰撞 | 同时启用 Spot 与 Margin，订阅 `BTC-USDT` | parser 通过 `okx_channel` 与配置上下文区分 product_line，产生不同 InstrumentKey |
| Simulated/Production 混淆 | 配置同时含两种 environment | 启动时校验失败，返回 `OKX-101`，进程退出 |
| OKX rate limit | 收到 `429 Too Many Requests` 或 WebSocket `60026` 限速码 | 退避重连，记录 metric |
| OKX maintenance | 交易所维护窗口（每周三 04:00 UTC） | client 检测到连接拒绝，退避重连，spool 持续累积 |

---

## 14. Directory Structure

> 文档目录与 binance 同名结构：

```text
module/okx/
  goal.md
  README.md
  SPEC.md                    # 本文件
  IMPLEMENTATION-PLAN.md
  TRACEABILITY.md
  BOUNDARY-GATES.md          # 引用 binance 等价文档
  RUNTIME-MAPPING.md         # 引用 binance 等价文档
  client/SPEC.md
  server/SPEC.md
  tasks/                     # 推迟到 SPEC Approved 后
```

Runtime 仓库 `github.com/ZoneCNH/okx/` 结构与 binance 一致（详见 `RUNTIME-MAPPING.md`）。

---

## 15. Dependencies

> 允许依赖与 binance §15 一致：`module/contracts` / `module/domain-market` / `module/market-data` / `module/transportx` / `module/configx` / `module/observex` + 第三方 `gin` / `grpc` / `sqlite3`。

OKX 特异第三方：

| 依赖 | 用途 |
|------|------|
| `nhooyr.io/websocket` 或同类 | WebSocket client（需支持 OKX 100MB/min 帧大小） |

---

## 16. Testing

> 与 binance §16 范式一致。OKX 测试编号 TC-001 ~ TC-018 与 §7 FR 编号对齐，TC-019 ~ TC-020 覆盖 OKX 特异 FR-008（simulated isolation）。

---

## 17. Performance Budget

> 与 binance §17 一致。OKX 因 WebSocket 帧较大（含完整 channel 元数据），event normalization P99 上调到 < 2ms（binance 为 < 1ms）。

---

## 18. Observability

> 与 binance §18 范式一致。Metric 前缀使用 `okx_` 替代 `binance_`，新增：

- `okx_simulated_events_total`（counter）：simulated 环境的事件数（监控不漏入生产）

---

## 19. Security

> 与 binance §19 一致。OKX 特异：
> - 鉴权三段：`OKX_API_KEY` / `OKX_SECRET_KEY` / `OKX_PASSPHRASE`（环境变量）
> - 禁止在 logs 暴露 passphrase
> - simulated environment 的 API key 禁止与 production 共用同一变量名

---

## 20. CI Gate

> 与 binance §20 范式一致。OKX 特异 gate：

| Gate | 命令 | 通过条件 |
|------|------|----------|
| No simulated/production mix | 配置文件静态检查脚本 | 同一 config 仅一种 environment |
| Source metadata validation | `go test -run TestOkxSourceMetadata ./...` | 全部通过 |

---

## 21. Upgrade Compatibility

> 与 binance §21 一致。

---

## 22. Release DoD

`module/okx` v1.0.0 发布完成标准：

- [ ] 旧 passive SDK references 已移除
- [ ] `module/okx/client` 和 `module/okx/server` specs 完成并通过 spec-lint
- [ ] root/client/server TRACEABILITY.md 完成，所有需求可追溯
- [ ] 5 条产品线 connector 实现并通过身份碰撞测试（FR-002）
- [ ] Simulated/production isolation 实现并通过 FR-008 测试
- [ ] At-least-once + idempotent acceptance 端到端 testable
- [ ] Boundary gates 在 CI 执行（CI 复制 binance 脚本并按 §6 替换规则改写）
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过
- [ ] Performance Budget 达标
- [ ] Integration test 演示 `client → server → downstream port` 完整数据流

---

## 23. Open Questions

### Resolved

| ID | 问题 | 状态 |
|----|------|------|
| OQ-001 | contracts §8.4 wire 是否就绪？ | ✅ 已确认（v1.2.0-spec） |
| OQ-002 | market-data downstream port 是否就绪？ | ✅ 已确认（v1.0.0 §4） |

### Non-blocking

| ID | 问题 | 状态 |
|----|------|------|
| OQ-003 | OKX `ws_business` channel 是否需要独立 connector？ | 待评估，v1.1 决定 |
| OQ-004 | OKX 子账号鉴权是否纳入 v1.0？ | 待评估 |

### Future

| ID | 问题 | 状态 |
|----|------|------|
| OQ-005 | 是否支持 OKX 的 "books-l2-tbt" tick-by-tick 订阅？ | 待评估 |
| OQ-006 | 是否需要 OKX Asia / Europe endpoint 切换？ | 待评估 |
