# module/okx IMPLEMENTATION PLAN

## 1. Goal

Deliver `module/okx` v1.0.0 as a complete OKX-specific market_data C/S module，硬切替换旧 passive `okx` SDK。

## 2. Required Preflight Decisions

实施前需确认：

1. 旧 `okx` v0.1.1 SDK 接口在 active code 中清除（CI gate 接管）
2. `module/okx/client` 和 `module/okx/server` 文档已就绪（本 PR 范围）
3. canonical domain 仍由 `module/domain_market` 拥有（OKX 不重定义）
4. wire contract 仍由 `module/contracts` §8.4 拥有（OKX 不重定义）
5. downstream dispatch 经 `module/market_data` 中转
6. delivery 语义：at-least-once + idempotent acceptance + ACK-driven checkpoint
7. 5 product line 身份维度按 [`module/okx/SPEC.md`](./SPEC.md) §10 表格
8. simulated/production environment 隔离按 §7 FR-008 强制

### Phase 0: Upstream Contract Closure Gate

| Gate | 验证项 | 状态 |
|------|--------|:---:|
| G0-1 | contracts §8.4 MarketDataService + IngestRequest/Result/Ack/Reject + RejectCode(10码) | ✅ |
| G0-2 | domain_market ProductLine(4值)/InstrumentKey(12维)/MarketFactEnvelope | ✅（OKX 5 条产品线在 InstrumentKey 内通过 product_line + instrument_type 维度区分） |
| G0-3 | market_data DownstreamDispatchPort + binance reject 映射规则 | ✅（OKX RejectCode 映射沿用 §4.4.1 规则） |
| G0-4 | OKX 旧 SDK 清单整理（确认要清除的 active references） | 🔧 PR-000 范围 |
| G0-5 | binance C/S Module 模板已稳定（继承基线） | ✅ |
| G0-6 | BOUNDARY-GATES.md（继承 binance）9 项 CI gate 可执行 | ✅（通过 stub 引用） |

## 3. Recommended PR Sequence

```text
PR-000  legacy okx SDK references cleanup
PR-001  module/okx root（goal/README/SPEC/PLAN/TRACEABILITY/BOUNDARY-GATES/RUNTIME-MAPPING）
PR-002  module/okx/client SPEC + tasks
PR-003  module/okx/server SPEC + tasks
PR-004  domain_market dependency 验证（无新增需求）
PR-005  contracts dependency 验证（无新增需求）
PR-006  transportx dependency 验证
PR-007  runtime implementation（github.com/ZoneCNH/okx 改造）
```

> 本仓库 PR-001/002/003 合并执行（在阶段 A 单一 PR 中），PR-004 ~ PR-007 落到 GitHub `okx` 仓库或后续 PR。

## 4. PR-000 Legacy SDK Cleanup（待执行）

Scope:
- 在 `github.com/ZoneCNH/okx` repo 标注 v0.1.1 之前的 passive SDK 接口为 `Deprecated`
- 移除 active doc 中对 passive SDK 的引用
- 保留 `CHANGELOG.md` 中的迁移记录

Acceptance:
- 无 active 文档引用 passive SDK 模式
- CI no-legacy gate 通过

## 5. PR-001 Root Module（本 PR 范围）

Scope: 添加 `module/okx/{goal.md, README.md, SPEC.md, IMPLEMENTATION-PLAN.md, TRACEABILITY.md, BOUNDARY-GATES.md, RUNTIME-MAPPING.md}`

Acceptance:
- root SPEC 定义 client/server 拆分与 5 product line 身份维度
- 无 storage/query/strategy 所有权出现在 root
- 无 passive SDK 路径残留
- BOUNDARY-GATES / RUNTIME-MAPPING 通过 stub 引用 binance（合规且简洁）

## 6. PR-002 Client Docs（本 PR 范围）

Scope: 添加 `client/SPEC.md` + 后续 task spec

Acceptance:
- client SPEC 定义 5 connector
- Spot/Margin 同 symbol 身份不碰撞（FR-002）
- simulated/production environment 隔离（FR-008）
- checkpoint 依赖 server ACK

## 7. PR-003 Server Docs（本 PR 范围）

Scope: 添加 `server/SPEC.md` + 后续 task spec

Acceptance:
- server 不连接 OKX endpoint（仅接收 client gRPC）
- environment isolation 在 stream 层强制
- 无 storage/query/strategy 所有权

## 8. PR-004 ~ PR-007（后续 PR / 后续仓库）

| PR | 范围 | 触发时机 |
|----|------|----------|
| PR-004 | domain_market 依赖验证 | 无 SPEC 变化时 stub PR |
| PR-005 | contracts 依赖验证 | 同上 |
| PR-006 | transportx 依赖验证 | 同上 |
| PR-007 | github.com/ZoneCNH/okx runtime 改造 | 本 PR 合并 + SPEC Approved 后 |

Runtime 实现序列与 binance §11 PR-007 一致：generated contracts → domain mapping → server mock → client catalog/parser → 5 connectors → mapper → spool/checkpoint → gRPC sender → real server ingest → validation/idempotency/ACK → downstream dispatch → admin/observability → integration tests → boundary gates.

## 9. Done Definition

`module/okx` v1.0.0 完成标准：

- [ ] 文档体系自洽
- [ ] 所有 task 有 acceptance criteria
- [ ] client/server 边界 CI 强制
- [ ] server ACK 驱动 client checkpoint
- [ ] duplicate idempotency key 仅 dispatch 一次
- [ ] 5 product line 身份不碰撞
- [ ] simulated/production 严格隔离
- [ ] 无 passive `okx` SDK active 引用
- [ ] integration test 演示 client → server → downstream port 完整数据流

## Task Reference

| Task | Scope | Effort |
|------|-------|--------|
| TASK-OKX-001-core-implementation | Implementation | 2h |
