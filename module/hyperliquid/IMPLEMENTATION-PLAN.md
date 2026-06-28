# module/hyperliquid IMPLEMENTATION PLAN

## 1. Goal

Deliver `module/hyperliquid` v1.0.0 as Hyperliquid-specific DEX market_data C/S module。硬切替换旧 passive `hyperliquid` SDK，并引入 onchain origin metadata + wallet signature 鉴权 + chain reorg 兼容机制。

## 2. Required Preflight Decisions

1. 旧 passive SDK 在 active code 中清除
2. `module/hyperliquid/client` 与 `server` 文档就绪
3. canonical domain 由 `module/domain_market` 拥有；onchain metadata 通过 `source_metadata` 扩展（不在 canonical core 中新增字段）
4. wire contract 由 `module/contracts` §8.4 拥有
5. downstream dispatch 经 `module/market_data` 中转，下游需感知 onchain metadata
6. delivery 语义：at-least-once + idempotent acceptance + ACK-driven checkpoint + reorg-tolerant idempotency key
7. wallet signature 优先使用外部 signer endpoint，避免私钥进入应用进程
8. confirmation_threshold 默认 3 blocks（约 6 秒延迟）

### Phase 0: Upstream Contract Closure Gate

| Gate | 验证项 | 状态 |
|------|--------|:---:|
| G0-1 | contracts §8.4 全部 wire types | ✅ |
| G0-2 | domain_market `source_metadata` map 字段支持任意 key/value | ✅ |
| G0-3 | market_data DownstreamDispatchPort 接受含 onchain metadata 的事件 | ✅（源不敏感） |
| G0-4 | binance C/S Module 模板已稳定 | ✅ |
| G0-5 | hyperliquid 旧 SDK 清单整理 | 🔧 PR-000 |
| G0-6 | BOUNDARY-GATES（继承 binance + 钱包安全 gate） 可执行 | ✅ |

## 3. Recommended PR Sequence

```text
PR-000  legacy hyperliquid SDK cleanup
PR-001  module/hyperliquid root
PR-002  module/hyperliquid/client SPEC + tasks
PR-003  module/hyperliquid/server SPEC + tasks
PR-004  domain_market source_metadata 扩展验证
PR-005  contracts dependency 验证
PR-006  transportx dependency 验证
PR-007  runtime implementation（github.com/ZoneCNH/hyperliquid 改造）
```

本仓库 PR-001/002/003 合并执行（阶段 A 单 PR）；PR-004 ~ PR-007 后续 PR / 后续仓库。

## 4. PR-000 Legacy SDK Cleanup

Scope:
- 标注旧 passive SDK 为 Deprecated
- 移除 active doc 引用
- 保留 CHANGELOG 迁移记录

## 5. PR-001 Root Module（本 PR）

Scope: `goal.md / README.md / SPEC.md / IMPLEMENTATION-PLAN.md / TRACEABILITY.md / BOUNDARY-GATES.md / RUNTIME-MAPPING.md`

Acceptance:
- root SPEC 定义 DEX 特异性（onchain metadata, wallet signature, reorg tolerance）
- 仅 Perp + Spot 产品线
- 无 storage/query/strategy 所有权

## 6. PR-002 Client Docs（本 PR）

Scope: `client/SPEC.md` + 后续 task spec

Acceptance:
- 双源采集（offchain WebSocket + onchain L1 RPC）
- onchain confirmation gate 实现
- wallet signature 安全隔离
- idempotency key 包含 block_height / tx_hash

## 7. PR-003 Server Docs（本 PR）

Scope: `server/SPEC.md` + 后续 task spec

Acceptance:
- onchain metadata 校验
- reorg 容忍：新 block_height 事件视为新 event
- idempotency TTL 48h 覆盖 reorg 窗口

## 8. PR-004 ~ PR-007（后续）

| PR | 范围 |
|----|------|
| PR-004 | domain_market source_metadata 字段验证 |
| PR-005 | contracts dependency stub |
| PR-006 | transportx dependency stub |
| PR-007 | github.com/ZoneCNH/hyperliquid runtime 改造（含 chain RPC 与 signer 集成） |

Runtime 序列：generated contracts → domain mapping → server mock → client catalog → WebSocket connector → chain RPC connector → signer wrapper → reorg detection → mapper → spool/checkpoint → gRPC sender → server ingest → onchain validation → idempotency → downstream dispatch → admin/observability → integration tests（含 reorg 场景）→ boundary gates + secret leakage gate.

## 9. Done Definition

`module/hyperliquid` v1.0.0 完成标准：

- [ ] 文档自洽
- [ ] task 有 AC
- [ ] 边界 CI 强制
- [ ] onchain reorg 测试通过
- [ ] wallet secret 零泄露（gitleaks + 自定义 hex pattern）
- [ ] confirmation_threshold gate 通过
- [ ] integration test 演示 offchain + onchain 双源 → server → downstream port 数据流

## Task Reference

| Task | Scope | Effort |
|------|-------|--------|
| TASK-HL-001-core-implementation | Implementation | 2h |
