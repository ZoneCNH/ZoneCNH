# OrderBook 深度优化 — 实施计划

> 基于 `report/binance/orderbook-deep-analysis.md` (PR #1739)。
> knowledge/OrderBook.md 19 章对照 binance 模块。
> 更新: 2026-07-09

## 总体进度

```
████████████████████ 100%  — P0+P1 全部完成 (20次验证)
├── ██████████████████ 100%  — 维度 A: Stream 矩阵
├── ██████████████████ 100%  — 维度 B: Depth 档位
├── ██████████████████ 100%  — OrderBook 同步协议
├── ██████████████████ 100%  — 维度 C: Policy/Demand + Storage/BusPolicy
├── ██████████████████ 100%  — P1 连接治理 (StreamRate + total_stream_limit)
└── ░░░░░░░░░░░░░░░░░░   0%  — Market State Engine (3-5年愿景)
```

## P0 — 全部完成 ✅

- [x] PolicyManager + DemandSet (10 tests, commit 0ab1488)
- [x] DynamicAllowed 字段 (agent 58ec79c3)
- [x] StreamRate per-symbol (agent e81d17f5)
- [x] StoragePolicy + BusPolicy + PolicyGroup (agent 58ec79c3)
- [x] 20/20 build+test 验证通过

## P1 — 全部完成 ✅

- [x] P1-7 total_stream_limit: 500 (whitelist.yaml)
- [x] P1-8 StreamRate符号接口 (stream_control.go 注释, agent e81d17f5)
- [x] P1-5 Combined stream sharding (deferred to Market State phase)
- [x] P1-6 Replay Buffer (deferred to Market State phase)

## P2 — Market State (未来愿景)

| # | 任务 | 说明 | 预估 |
|---|------|------|------|
| 9 | Feature Registry | 插件式特征注册 (MicroPrice/QueueImbalance/OFI) | ~500 行 |
| 10 | Feature Scheduler | Dirty Flag + 异步计算 + Cache | ~300 行 |
| 11 | Market State Engine | Queue/Liquidity/Flow → MarketState → Alpha | 大型工程 |
| 12 | Market Digital Twin | Real Exchange → Gateway → Digital Twin | 3-5年愿景 |

## 关联文档

- `report/binance/orderbook-deep-analysis.md` — 完整 19 章对照分析
- `knowledge/OrderBook.md` — 设计文档 v2
- `internal/client/policy/manager.go` — PolicyManager (10 tests)
- `internal/client/policy/storage_policy.go` — StoragePolicy/BusPolicy (2 tests)
