# module/hyperliquid SPEC

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Owner: ZoneCNH
- Layer: 数据域 · 行情
- Module-Version: v1.0.0-spec
- Repository: [github.com/ZoneCNH/hyperliquid](https://github.com/ZoneCNH/hyperliquid)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [`module/binance`](../binance/), [`module/_template/cex-cs-module/README.md`](../_template/cex-cs-module/README.md), `module/domain_market`, `module/contracts`, `module/market_data`

> 子模块规格：`module/hyperliquid/client/SPEC.md`、`module/hyperliquid/server/SPEC.md`
>
> 本 SPEC 客制化 §1-§10 与 §15 / §19 中的 Hyperliquid 特异性内容（DEX 特征）；§11-§14 / §16-§18 / §20-§23 与 [`module/binance/SPEC.md`](../binance/SPEC.md) 范式保持一致，差异部分显式标注。

---

## 2. Summary

`module/hyperliquid` 是 Hyperliquid 专属 Market Data C/S Module，是本架构中**首个 DEX 接入模块**：

```text
Hyperliquid (WebSocket + onchain L1 events)
  ↓
module/hyperliquid/client    ← 链上+链下双源采集器（wallet-signed auth）
  ↓ contracts-defined gRPC (MarketDataService)
module/hyperliquid/server    ← 摄入受理服务器（含链上 reorg 兼容）
  ↓ downstream dispatch port
module/market_data
```

与 CEX C/S Module 关键差异：

- **鉴权模型**：wallet signature（EIP-191 typed message）替代 API key
- **事件来源**：链下 WebSocket（订单簿、trade）+ 链上 L1 事件（liquidation、settlement），两类事件需要在 client 侧统一规范化
- **链上语义**：每条事件可携带 `block_height` + `tx_hash`，idempotency key 必须容纳链 reorg 场景
- **产品线**：仅 Perpetual + Spot（无 COIN-M / Options，但 venue 持续扩展）
- **Rate limit**：按 wallet address 配额，子账号通过 sub-wallet 实现

---

## 3. Problem

Hyperliquid 集成面临以下问题：

1. **DEX 特异性未抽象**：直接复用 binance 模板会丢失 onchain origin 元数据，下游分析域无法判断事件 finality（链是否已确认）。
2. **链 reorg 风险**：Hyperliquid L1 在极端情况下会发生 reorg；若 idempotency key 不含 `block_height`，reorg 后旧事件复发会被误识别为重复并丢弃。
3. **Wallet 鉴权**：旧 SDK 依赖外部钱包签名工具，签名管理未集中。
4. **混合事件流**：链下 WebSocket（毫秒级延迟）与链上 L1 事件（秒级延迟）需要在 canonical 层统一表达，但保留 origin 标识。
5. **Rate limit 模型不同**：Hyperliquid 按 wallet 限速（200 req/min），与 CEX IP/API key 模型不同，client 重连策略需调整。

---

## 4. Goals

- 定义 Hyperliquid 专属 C/S 双端架构
- 支持 Perp（USDⓈ-margined）+ 可用 Spot 产品线
- 统一规范化 onchain + offchain 双源事件，每条 event 标注 `event_origin` ∈ {`offchain_ws`, `onchain_l1`}
- Idempotency key 维度增加 `block_height` 与 `tx_hash`，兼容链 reorg
- 钱包签名管理在 client 层封装，secret 仅从环境变量注入
- 使用 contracts-defined `MarketDataService` 与 CEX 共享同一 wire contract
- 移除旧 `hyperliquid` SDK 引用

---

## 5. Non-goals

| 不做 | 原因 |
|------|------|
| 定义 canonical domain model | 由 `module/domain_market` 拥有 |
| 定义 proto/gRPC wire contract | 由 `module/contracts` 拥有 |
| 拥有 storage / query / strategy | 不属于数据域 |
| 实现 Hyperliquid 下单 | 属于执行域 |
| 钱包密钥管理（多签 / hardware wallet） | 属于安全域 / wallet 模块 |
| 链上事件回填（chain replay） | 由 `module/market_data` 或独立 backfill 模块负责 |
| 旧 hyperliquid SDK 兼容 | 硬切移除 |

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `module/market_data` | 通过 server downstream dispatch port 接收 canonical events（含 onchain metadata） |
| `module/hyperliquid/client` | 通过 contracts gRPC 调用 server `MarketDataService.Ingest` |
| `module/hyperliquid/server` | 接收 client 流 |
| Operator | 通过 admin 端点监控钱包 health、链上 confirmation 状态 |

---

## 7. Functional Requirements

### FR-001: Product-Line Support

**WHEN** 配置启用 Perp 产品线
**THEN** client 通过 Hyperliquid Perp WebSocket + L1 events 采集

**WHEN** 配置启用 Spot 产品线（如 venue 已支持）
**THEN** client 通过 Hyperliquid Spot WebSocket 采集

### FR-002: Instrument Identity

**WHEN** parser 解析 Perp `BTC`
**THEN** InstrumentKey 含 `exchange=hyperliquid` + `product_line=perp` + `base_asset=BTC` + `margin_asset=USDC`

**WHEN** parser 解析 Spot `BTC/USDC`
**THEN** InstrumentKey 含 `exchange=hyperliquid` + `product_line=spot` + `base_asset=BTC` + `quote_asset=USDC`

**身份碰撞**：与 CEX 同名 symbol 通过 `exchange` 维度区分。Hyperliquid Perp `BTC` 与 binance USDⓈ-M `BTCUSDT` 在 canonical layer 是不同的 InstrumentKey。

### FR-003: gRPC Ingestion

> 与 [`module/binance/SPEC.md`](../binance/SPEC.md) §7 FR-003 范式一致。

### FR-004: At-Least-Once Delivery

> 与 binance §7 FR-004 范式一致。

### FR-005: Idempotent Acceptance

> 与 binance §7 FR-005 范式一致，但 idempotency key **维度扩展**（详见 §8 BR-010）。

### FR-006: Admin Surface

> 与 binance §7 FR-006 范式一致。新增端点：
> - `GET /admin/wallet-health` 返回当前钱包签名 health 与最近一次 nonce
> - `GET /admin/chain-status` 返回最近 L1 block height 与 lag

### FR-007: Boundary Enforcement

> 与 binance §7 FR-007 范式一致。

### FR-008: Onchain Origin Metadata（DEX 特异性）

**功能描述**：每条 canonical event 必须标注 `event_origin`，使下游可判断 finality。

**WHEN** 事件来自链下 WebSocket（trade、orderbook、ticker）
**THEN** `source_metadata.event_origin=offchain_ws`
**AND** `block_height` 与 `tx_hash` 可空

**WHEN** 事件来自链上 L1（liquidation、funding settlement、deposit/withdraw）
**THEN** `source_metadata.event_origin=onchain_l1`
**AND** `source_metadata.block_height` 与 `source_metadata.tx_hash` 必填
**AND** `source_metadata.confirmations` 表示当前确认块数

### FR-009: Wallet Signature Management（DEX 特异性）

**功能描述**：client 内部维护 wallet 签名能力，使用 EIP-191 typed message 进行 WebSocket 鉴权。

**WHEN** client 启动
**THEN** 从环境变量读取 `HYPERLIQUID_PRIVATE_KEY` 或 `HYPERLIQUID_SIGNER_ENDPOINT`（外部签名服务）
**AND** 不在日志、admin、debug 端点暴露任一字段

**WHEN** WebSocket 鉴权
**THEN** 用 EIP-191 typed message 生成 nonce + signature

**WHEN** 钱包额度耗尽（rate limit）
**THEN** client 退避重连，metric `hyperliquid_client_wallet_throttled_total` 递增

---

## 8. Business Rules

### BR-001 ~ BR-009 与 binance 范式一致

> 详见 [`module/binance/SPEC.md`](../binance/SPEC.md) §8。

### BR-010: Idempotency Key Includes Onchain Dimensions（DEX 特异性）

**规则**：onchain L1 事件的 idempotency key 必须包含 `block_height` 与 `tx_hash`。

**约束**：
- offchain_ws 事件 key 维度：`exchange + product_line + instrument_key + event_type + event_time`
- onchain_l1 事件 key 维度：上述 + `block_height + tx_hash + log_index`

**违反时**：链 reorg 后旧 block 中的事件会被误识别为重复并丢弃，造成数据丢失。CI gate `TestIdempotencyKeyOnchain` 失败。

### BR-011: No Wallet Secret Exposure

**规则**：wallet private key 与签名 nonce 仅在内存中使用，不得写入 spool、log、admin、debug。

**约束**：spool 仅存 canonical event 与 idempotency key；wallet 状态仅在 metric 中以聚合形式暴露（如 throttled count）。

**违反时**：CI `gitleaks` + 自定义 grep gate 检测到 secret 风险，CI 失败。

---

## 9. Interface Contract

### MarketDataService（由 module/contracts §8.4 定义）

> 与 binance 一致。

### Hyperliquid-Specific Source Metadata Extension

| 字段 | 类型 | 必填 | 说明 |
|------|------|:---:|------|
| `event_origin` | enum | ✅ | `offchain_ws` / `onchain_l1` |
| `block_height` | uint64 | onchain 必填 | L1 block 高度 |
| `tx_hash` | string | onchain 必填 | L1 tx hash（0x 前缀 hex） |
| `log_index` | uint32 | onchain 必填 | tx 内 log 索引 |
| `confirmations` | uint32 | onchain 必填 | 当前确认块数 |
| `wallet_address` | string | ✅ | 触发本次订阅/查询的 wallet 地址 |

server 校验：onchain_l1 事件缺失 `block_height`/`tx_hash` → `terminal_validation` reject。

### Downstream Dispatch Port

> 与 binance 一致，但 dispatched event 携带 onchain metadata。下游 `module/market_data` 需感知此扩展（详见 market_data SPEC §4 binance reject 映射，类似规则适用）。

---

## 10. Data Model

### Canonical Event Concepts

> 与 binance §10 一致。

### Instrument Identity Dimensions（Hyperliquid）

| Dimension | Perp | Spot |
|-----------|:----:|:----:|
| exchange | ✅ | ✅ |
| product_line | ✅ | ✅ |
| instrument_type | ✅ | ✅ |
| base_asset | ✅ | ✅ |
| quote_asset | — | ✅ |
| margin_asset | ✅（USDC） | — |
| settlement_asset | ✅（USDC） | — |

无 contract_code / expiry / strike / option_type 维度。

### Onchain Event Reorg State Machine

```text
pending_chain → confirmed_low (1-3 blocks)
              → confirmed_safe (>= 12 blocks)
              → reorged → re-emitted with new block_height
```

server 仅 dispatch `confirmed_low` 及以上的事件；`pending_chain` 不进入 dispatch。reorg 后的同一逻辑事件以新 idempotency key（含新 block_height）重新进入 pipeline。

### Reject Classification

> 与 contracts §8.4 RejectCode 10 码一致。

---

## 11. Config Schema

> 与 binance §11 范式一致。Hyperliquid 特异：

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `hyperliquid.endpoints.ws` | `string` | `wss://api.hyperliquid.xyz/ws` | Hyperliquid WebSocket |
| `hyperliquid.endpoints.l1_rpc` | `string` | `https://api.hyperliquid.xyz/info` | L1 events RPC |
| `hyperliquid.product_lines` | `[]string` | `["perp"]` | 启用产品线 |
| `hyperliquid.private_key_env` | `string` | `HYPERLIQUID_PRIVATE_KEY` | 钱包私钥环境变量名 |
| `hyperliquid.signer_endpoint` | `string` | `""` | 外部签名服务（非空时优先于私钥） |
| `hyperliquid.confirmation_threshold` | `int` | `3` | onchain 事件 dispatch 所需最少确认数 |

---

## 12. Error Handling

> 与 binance §12 范式一致。错误码前缀使用 `HYP-`：

| 错误码 | 触发条件 |
|-------|----------|
| `HYP-001` ~ `HYP-008` | 与 binance 同名错误对齐 |
| `HYP-101` | 钱包签名失败（nonce 失效或私钥错误） |
| `HYP-102` | onchain 事件缺少 block_height / tx_hash |
| `HYP-103` | 检测到 chain reorg |

---

## 13. Edge Cases

> 与 binance §13 范式一致。Hyperliquid 特有：

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| Chain reorg | L1 block reorg 影响已 dispatch 事件 | 旧事件不撤销（idempotent at downstream），新 block 中同一逻辑事件以新 idempotency key 重新进入 pipeline |
| 确认数不足 | 收到 onchain 事件 confirmations < threshold | 暂存于 pending_chain 队列，达到 threshold 后才规范化 + spool |
| Wallet rate limit | 收到限速响应 | 退避，nonce 更新，metric 上报 |
| WebSocket 鉴权失败 | nonce 已被使用 | 重新生成 nonce + signature，重连 |

---

## 14. Directory Structure

> 文档目录与 binance 同名结构。Runtime 仓库 `github.com/ZoneCNH/hyperliquid/` 结构与 binance 一致，新增：

```text
internal/client/
  chain/             # 链上事件订阅与 reorg 处理
  signer/            # 钱包签名能力（封装外部签名服务）
```

---

## 15. Dependencies

> 允许依赖与 binance §15 一致。Hyperliquid 特异第三方：

| 依赖 | 用途 |
|------|------|
| `github.com/ethereum/go-ethereum/crypto` | EIP-191 签名（不引入完整 go-ethereum 链上交互） |
| `github.com/btcsuite/btcd/btcec` 或同类 | 椭圆曲线签名（仅用于签名生成） |

明确禁止：
- 完整 go-ethereum client（会引入大量与本模块无关的 EVM 依赖）
- 任何 wallet management UI 库

---

## 16. Testing

> 与 binance §16 范式一致。Hyperliquid 特异 TC：
> - TC-019: onchain 事件 idempotency key 包含 block_height
> - TC-020: chain reorg 后旧事件不影响新事件 dispatch
> - TC-021: 确认数不足的事件不进入 spool

---

## 17. Performance Budget

> 与 binance §17 一致。Hyperliquid 特异：
> - Onchain event finality 等待：confirmation_threshold × block_time（典型 ~6s for 3 blocks）
> - 链下 WebSocket 延迟与 CEX 同级（< 100ms）

---

## 18. Observability

> 与 binance §18 范式一致。Metric 前缀使用 `hyperliquid_`，新增：

- `hyperliquid_client_chain_lag_blocks`（gauge）：当前 client 落后链头的 block 数
- `hyperliquid_client_chain_reorg_total`（counter）：检测到的 reorg 次数
- `hyperliquid_client_wallet_throttled_total`（counter）：钱包限速次数
- `hyperliquid_server_pending_chain_size`（gauge）：等待确认的事件数

---

## 19. Security

> 与 binance §19 一致。Hyperliquid 特异：
> - `HYPERLIQUID_PRIVATE_KEY` 仅从环境变量读取，禁止写入任何文件
> - 推荐使用外部签名服务（`hyperliquid.signer_endpoint`），避免私钥进入应用进程
> - admin 端点不暴露 wallet address 之外的任何钱包信息
> - logs 仅记录 wallet address（首尾 4 字节），完整地址按合规策略脱敏

---

## 20. CI Gate

> 与 binance §20 范式一致。Hyperliquid 特异 gate：

| Gate | 命令 | 通过条件 |
|------|------|----------|
| No private key in repo | `gitleaks detect --no-git` + 自定义 hex 模式扫描 | 零匹配 |
| Onchain idempotency key | `go test -run TestIdempotencyKeyOnchain ./...` | 全部通过 |
| Reorg compatibility | `go test -run TestReorg ./...` | 全部通过 |

---

## 21. Upgrade Compatibility

> 与 binance §21 一致。Hyperliquid 特异：
> - confirmation_threshold 调整：向后兼容（仅影响新事件 finality 时延）
> - 新增 onchain event type：向后兼容（通过 contracts schema_version 协商）

---

## 22. Release DoD

`module/hyperliquid` v1.0.0 发布完成标准：

- [ ] 旧 passive SDK references 已移除
- [ ] `module/hyperliquid/client` 和 `server` specs 完成并通过 spec-lint
- [ ] root/client/server TRACEABILITY.md 完成
- [ ] Perp + Spot connector 实现并通过身份碰撞测试
- [ ] FR-008 onchain origin metadata 实现并通过 TC-019/020/021
- [ ] FR-009 wallet signature management 实现，secret 隔离测试通过
- [ ] At-least-once + idempotent acceptance + reorg 兼容 端到端 testable
- [ ] Boundary gates 在 CI 执行
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过
- [ ] Performance Budget 达标（含 onchain finality 等待）
- [ ] Integration test 演示 `client → server → downstream port` 完整数据流（含 onchain reorg 场景）

---

## 23. Open Questions

### Resolved

| ID | 问题 | 状态 |
|----|------|------|
| OQ-001 | contracts §8.4 wire 是否就绪？ | ✅ 已确认 |
| OQ-002 | market_data downstream port 是否就绪？ | ✅ 已确认 |
| OQ-003 | onchain event metadata 是否在 contracts 中支持？ | 已确认通过 `source_metadata` map 字段（v1.2.0） |

### Non-blocking

| ID | 问题 | 状态 |
|----|------|------|
| OQ-004 | 是否需要 Hyperliquid sub-wallet 支持？ | v1.0 不支持，v1.1 评估 |
| OQ-005 | `confirmation_threshold` 默认值（3）是否够稳？ | 待 backtest 数据决定 |

### Future

| ID | 问题 | 状态 |
|----|------|------|
| OQ-006 | 是否扩展到其他 EVM-based DEX（GMX, dYdX）？ | 待评估，需新模块或 generic dex 抽象 |
| OQ-007 | 是否需要 onchain block 索引数据回填？ | 待评估 |
