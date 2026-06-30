# module/hyperliquid/server SPEC

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Owner: ZoneCNH
- Layer: 数据域 · Hyperliquid 行情接入层
- Module-Version: v0.1.0-spec
- Repository: [github.com/ZoneCNH/hyperliquid](https://github.com/ZoneCNH/hyperliquid)（server/ 子目录）
- Pattern: 继承 [`module/binance/server/SPEC.md`](../../binance/server/SPEC.md) 范式

---

## 1. Summary

`module/hyperliquid/server` 是 Hyperliquid 行情数据的 gRPC ingest server。接收 client 流，校验链上 + 链下事件 metadata，幂等去重（含链上维度），ACK，下游分发。

## 2. Inherited Behavior

以下内容**完全继承** [`module/binance/server/SPEC.md`](../../binance/server/SPEC.md) 范式：

- §3-§6 通用问题陈述与目标
- §7 FR-001 ~ FR-008 通用 server 行为
- §8 BR-001 ~ BR-006 通用业务规则
- §9-21 通用 interface / data / config / error / edge / dependencies / testing / performance / observability / security / upgrade

## 3. Hyperliquid-Specific Customization

### 3.1 Source Metadata Validation

server validation 阶段额外检查：

| 字段 | 必填条件 | 失败 reject |
|------|----------|------------|
| `event_origin` | 始终必填 | terminal_validation |
| `wallet_address` | 始终必填 | terminal_validation |
| `block_height` / `tx_hash` / `log_index` / `confirmations` | event_origin=onchain_l1 时必填 | terminal_validation |

### 3.2 Onchain Idempotency Key Validation

onchain_l1 事件 server 校验幂等键必须包含 `block_height` + `tx_hash` 维度。若 client 提交的 idempotency key 不含这些字段（通过 key parsing 校验），→ `contract_violation` reject。

### 3.3 Reorg Tolerance

同一 logical event 在 reorg 后以**不同 idempotency key** 重新到达（含新 block_height）：

- server 视为新事件，accept + dispatch
- 旧 key 的事件保留在 idempotency store（TTL 24h），不撤销
- 下游 `module/market_data` 通过 dedup 策略决定是否合并

server 不主动检测 reorg；reorg 检测在 client 侧（详见 client SPEC §3.4）。

### 3.4 Wallet-Signed Stream Authentication

server 端可选启用 stream-level 鉴权（gRPC metadata 携带 wallet signature）：

```
gRPC metadata:
  x-hyperliquid-wallet-address: 0x...
  x-hyperliquid-nonce: 1234
  x-hyperliquid-signature: 0x...
```

server 验证 signature 后建立 trusted stream。鉴权失败 → gRPC `Unauthenticated` 错误。

> v1.0 默认**不启用** server 鉴权（仅依赖 mTLS + 网络隔离）；v1.1 评估是否引入。

### 3.5 Idempotency Store

继承 binance：Redis 为主，in-memory 为开发/测试。Hyperliquid 特异：TTL 调整到 48h，覆盖典型 reorg 窗口（通常 < 6h）的所有相关 key。

### 3.6 Error Codes

错误码使用 `HYP-` 前缀，详见父规格 §12。

## 4. Test Matrix Delta

新增（编号续接 binance server TC-015）：

| TC 编号 | 场景 | 预期 |
|---------|------|------|
| TC-016 | onchain 事件缺少 block_height | terminal_validation reject |
| TC-017 | offchain 事件错误标注 onchain（缺 confirmations） | terminal_validation reject |
| TC-018 | 同 logical event reorg 后新 key 到达 | accept 为新事件，dispatch 给下游 |
| TC-019 | wallet signature gRPC metadata 非法 | Unauthenticated（v1.1+） |

## 5. Release DoD Delta

继承 binance server §22，新增：

- [ ] Onchain metadata validation 通过 TC-016/017
- [ ] Reorg tolerance 通过 TC-018
- [ ] Idempotency TTL 调整为 48h 覆盖 reorg 窗口
- [ ] dispatch 给 market_data 的事件保留 onchain metadata
