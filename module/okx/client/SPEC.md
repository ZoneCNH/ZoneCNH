# module/okx/client SPEC

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-17
- Owner: ZoneCNH
- Layer: 数据域 · OKX 交易所接入
- Module-Version: v0.1.0-spec
- Repository: [github.com/ZoneCNH/okx](https://github.com/ZoneCNH/okx)（client/ 子目录）
- Pattern: 继承 [`module/binance/client/SPEC.md`](../../binance/client/SPEC.md) 范式

---

## 1. Summary

`module/okx/client` 是 OKX 对向行情采集器，连接 OKX REST/WebSocket 端点，将 5 条产品线（Spot / Margin / USDⓈ-M / Coin-M / Options）规范化为 ZoneCNH canonical events，持久化本地 spool，通过 contracts gRPC 发送到 `module/okx/server`。

## 2. Inherited Behavior

以下内容**完全继承** [`module/binance/client/SPEC.md`](../../binance/client/SPEC.md) 范式，本文件不重复：

- §3 Problem 通用问题陈述
- §4 Goals 通用目标（catalog / parser / connector / normalize / mapper / idempotency / spool / checkpoint / sender / admin）
- §5 Non-goals
- §6 Consumers
- §7 FR-001 Catalog / FR-003 Connector / FR-004 Normalization / FR-005 Mapping / FR-006 Idempotency Key / FR-007 Spool / FR-008 Checkpoint / FR-009 gRPC Sender / FR-010 Admin
- §8 BR-001 Checkpoint / BR-002 Spool State / BR-003 No Server Imports / BR-004 No Storage 等通用边界
- §9-10 通用 interface / data model（Connector / Parser / Mapper / Sender / IdempotencyKeyer 接口签名一致）
- §12-21 通用错误处理 / edge cases / dependencies / testing / performance / observability / security / upgrade

## 3. OKX-Specific Customization

### 3.1 Product Line Catalog（覆盖 binance §7 FR-001）

5 条产品线，每条独立配置：

| product_line 值 | OKX instType | endpoint channel |
|----------------|--------------|------------------|
| `spot` | `SPOT` | `tickers` / `books` / `trades` |
| `margin` | `MARGIN` | `tickers` / `books` / `trades`（含 margin context） |
| `usdm_swap` | `SWAP`（quote_asset 为 USDT/USDC） | `tickers` / `books` / `trades` / `funding-rate` |
| `coinm_swap` | `SWAP`（settlement_asset 为 base） | `tickers` / `books` / `trades` / `funding-rate` |
| `usdm_future` | `FUTURES`（quote 计价） | `tickers` / `books` / `trades` |
| `coinm_future` | `FUTURES`（币本位） | `tickers` / `books` / `trades` |
| `options` | `OPTION` | `option/ws` / `tickers` |

### 3.2 Instrument Parser（覆盖 binance §7 FR-002 + §10 §10.1 CatalogEntry）

OKX symbol 格式与 binance 不同：

| OKX 原生 instId | 解析结果 |
|----------------|---------|
| `BTC-USDT` + instType=SPOT | product_line=spot, base=BTC, quote=USDT |
| `BTC-USDT` + instType=MARGIN | product_line=margin, base=BTC, quote=USDT, margin_asset=USDT |
| `BTC-USDT-SWAP` | product_line=usdm_swap, base=BTC, quote=USDT, contract_code=BTC-USDT-SWAP |
| `BTC-USD-SWAP` | product_line=coinm_swap, base=BTC, settlement=BTC, contract_code=BTC-USD-SWAP |
| `BTC-USDT-240628` | product_line=usdm_future, expiry=2026-06-28 |
| `BTC-USD-240628-50000-C` | product_line=options, expiry=2026-06-28, strike=50000, option_type=Call |

**关键**：parser 必须接收 `instType` 上下文参数才能正确区分 Spot/Margin（同 instId）。

### 3.3 Connector Implementation（覆盖 binance §7 FR-003）

OKX 的 WebSocket 分两个 endpoint：
- `wss://ws.okx.com:8443/ws/v5/public` — 公共行情（推荐主路径）
- `wss://ws.okx.com:8443/ws/v5/business` — 业务频道（部分高频订阅）

每个 product_line 默认连 `public`。如果配置启用 `business`，client 维护两条并行 WebSocket 连接。

### 3.4 Idempotency Key Strategy（继承 binance §7 FR-006，无差异）

继承 binance 维度：`exchange + product_line + instrument_key + event_type + event_time/source_sequence + interval/open_time/trade_id`。

### 3.5 Simulated Endpoint Isolation（OKX 特异 FR-008）

详见父规格 [`module/okx/SPEC.md`](../SPEC.md) §7 FR-008。client 启动时校验：

```
if okx.endpoints.environment == "simulated" {
  // 仅连接 OKX simulated endpoint
  // canonical event source_metadata.environment = "simulated"
} else {
  // 仅连接 production endpoint
  // canonical event source_metadata.environment = "production"
}
// 禁止同一 client 进程同时启用两种 environment
```

### 3.6 Source Metadata Extension（OKX 特异）

每条 canonical event 必须填充：

| 字段 | 来源 |
|------|------|
| `environment` | client config `okx.endpoints.environment` |
| `okx_channel` | WebSocket subscribe arg.channel |
| `okx_inst_type` | WebSocket arg.instType |
| `okx_inst_id` | WebSocket arg.instId |

### 3.7 Error Codes（OKX 特异错误前缀）

错误码使用 `OKX-` 前缀替代 `BNC-`，详见父规格 §12。

## 4. Test Matrix Delta（覆盖父 SPEC §16）

新增 OKX 特异 TC（编号续接 binance client 的 TC-018）：

| TC 编号 | 场景 | 预期 |
|---------|------|------|
| TC-019 | parser 输入 `BTC-USDT` + instType=SPOT vs instType=MARGIN | 两个不同 InstrumentKey |
| TC-020 | client 启动时同时配置 simulated 与 production | 启动失败，错误 OKX-101 |
| TC-021 | event source_metadata.environment 与 client 配置不一致 | 拒绝写入 spool，错误 OKX-102 |
| TC-022 | OKX rate limit 429 响应 | 退避重连，spool 持续累积 |

## 5. Release DoD Delta

继承 binance client §22，新增：

- [ ] 5 product line connector 全部实现
- [ ] Spot/Margin 同 symbol 身份碰撞测试通过（TC-019）
- [ ] Simulated/production isolation 测试通过（TC-020/021）
- [ ] OKX 三段鉴权（API_KEY / SECRET / PASSPHRASE）从环境变量加载
