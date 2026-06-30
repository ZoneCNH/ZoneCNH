# module/hyperliquid/client SPEC

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Owner: ZoneCNH
- Layer: 数据域 · Hyperliquid DEX 接入
- Module-Version: v0.1.0-spec
- Repository: [github.com/ZoneCNH/hyperliquid](https://github.com/ZoneCNH/hyperliquid)（client/ 子目录）
- Pattern: 继承 [`module/binance/client/SPEC.md`](../../binance/client/SPEC.md) 范式

---

## 1. Summary

`module/hyperliquid/client` 是 Hyperliquid DEX 对向行情采集器。它连接 Hyperliquid WebSocket（wallet-signed 鉴权）与 L1 RPC，统一规范化链上 + 链下双源事件，spool + checkpoint，通过 contracts gRPC 发送到 `module/hyperliquid/server`。

## 2. Inherited Behavior

以下内容**完全继承** [`module/binance/client/SPEC.md`](../../binance/client/SPEC.md) 范式：

- §3 通用 Problem / §5 Non-goals / §6 Consumers
- §7 FR-001 Catalog / FR-004 Normalization / FR-005 Mapping / FR-007 Spool / FR-008 Checkpoint / FR-009 gRPC Sender / FR-010 Admin
- §8 通用 BR-001 ~ BR-005
- §9-10 通用 interface（Connector / Parser / Mapper / Sender / IdempotencyKeyer 签名一致）
- §11-21 通用 config / error / edge / directory / dependencies / testing / performance / observability / security / upgrade

## 3. Hyperliquid-Specific Customization

### 3.1 Product Line Catalog（覆盖 binance §7 FR-001）

仅 2 条产品线：

| product_line 值 | Hyperliquid 含义 | endpoint channel |
|----------------|------------------|------------------|
| `perp` | USDⓈ-margined Perpetual | `webData2` / `trades` / `l2Book` / `bbo` / `userFunding` |
| `spot` | Spot（部分上线 token） | `spotTrade` / `spotBook`（venue capability gate） |

无 COIN-M / Options / Margin / Future 维度。

### 3.2 Instrument Parser（覆盖 §7 FR-002）

| Hyperliquid 原生 symbol | 解析结果 |
|------------------------|---------|
| `BTC` + perp 上下文 | product_line=perp, base=BTC, margin=USDC |
| `ETH` + perp | product_line=perp, base=ETH, margin=USDC |
| `BTC/USDC` + spot | product_line=spot, base=BTC, quote=USDC |

无 contract_code / expiry / strike 维度。

### 3.3 Connector（覆盖 §7 FR-003）

双源订阅：

```
WebSocket connector (offchain_ws):
  - perp: webData2 / trades / l2Book / bbo
  - spot: spotTrade / spotBook
  → event_origin = offchain_ws

Chain RPC connector (onchain_l1):
  - polling block events: liquidation, funding settlement, deposit/withdraw
  → event_origin = onchain_l1
  → 含 block_height + tx_hash + log_index + confirmations
```

WebSocket 鉴权使用 wallet signature（详见 §3.5）。

### 3.4 Onchain Confirmation Gate（Hyperliquid 特异 FR-008）

onchain_l1 事件在 `confirmations < hyperliquid.confirmation_threshold`（默认 3）时**不写入 spool**，仅缓存于 pending_chain 队列。达到阈值后规范化并写入 spool。

reorg 检测：
- 若 pending_chain 中事件的 `block_height` 在新链中已被替换（`tx_hash` 不存在于当前链头追溯链） → 弃置该事件
- 若 spool 中已 acked 的事件被 reorg → 不撤销（idempotent at downstream），告警上报

### 3.5 Wallet Signature Management（Hyperliquid 特异 FR-009）

```
启动时：
  if hyperliquid.signer_endpoint != "":
    使用外部签名服务（推荐生产环境）
  elif env[HYPERLIQUID_PRIVATE_KEY] != "":
    使用本地私钥（仅开发/受控环境）
  else:
    启动失败

WebSocket 鉴权：
  - 生成 nonce（递增整数）
  - 用 EIP-191 typed message 签名
  - 提交 wallet_address + nonce + signature
  - 服务器验证后建立鉴权 session
```

**安全约束**：
- 私钥仅在内存使用，禁止落盘
- nonce 在 spool / log / admin 中均不暴露
- admin `/admin/wallet-health` 仅返回 wallet_address（脱敏）+ 最近 nonce 的 hash 前缀

### 3.6 Idempotency Key Strategy（覆盖 binance §7 FR-006）

按 event_origin 分两套：

```
event_origin = offchain_ws:
  key = exchange + product_line + instrument_key + event_type + event_time

event_origin = onchain_l1:
  key = exchange + product_line + instrument_key + event_type +
        block_height + tx_hash + log_index
```

reorg 后，原 `block_height` 的事件不再发生，新 block 中的等价事件以新 key 进入 pipeline。

### 3.7 Source Metadata Extension

每条 canonical event 必须填充：

| 字段 | offchain_ws 必填 | onchain_l1 必填 |
|------|:-:|:-:|
| `event_origin` | ✅ | ✅ |
| `wallet_address` | ✅ | ✅ |
| `block_height` | — | ✅ |
| `tx_hash` | — | ✅ |
| `log_index` | — | ✅ |
| `confirmations` | — | ✅ |

### 3.8 Error Codes

错误码使用 `HYP-` 前缀，详见父规格 §12。

## 4. Test Matrix Delta

新增（编号续接 binance client TC-018）：

| TC 编号 | 场景 | 预期 |
|---------|------|------|
| TC-019 | onchain_l1 事件 idempotency key 包含 block_height + tx_hash | key 跨 reorg 后唯一 |
| TC-020 | confirmations < threshold 的事件 | 不写入 spool，缓存 pending_chain |
| TC-021 | reorg 检测：pending_chain 中事件 block_height 被替换 | 弃置事件，告警上报 |
| TC-022 | wallet signature WebSocket 鉴权 | 鉴权成功，建立 session |
| TC-023 | private key 不出现在任何 log/admin/debug 输出 | grep test 通过 |

## 5. Release DoD Delta

继承 binance client §22，新增：

- [ ] Perp + Spot connector 实现
- [ ] Onchain L1 chain connector 实现并通过 reorg 测试
- [ ] Wallet signature management 通过 secret-isolation gate
- [ ] FR-008 confirmation gate 通过 TC-020/021
- [ ] FR-009 wallet signature 通过 TC-022
- [ ] HYPERLIQUID_PRIVATE_KEY 不出现在任何 artifact（CI gate）
