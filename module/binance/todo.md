# OrderBook 深度优化 — 实施计划

> 基于 `report/binance/orderbook-deep-analysis.md` (PR #1739)。
> knowledge/OrderBook.md 19 章对照 binance 模块。
> 更新: 2026-07-09

## 总体进度

```
████████████░░░░░░░░ 60%  — OrderBook 优化完成度
├── ████████████████░░ 85%  — 维度 A: Stream 矩阵
├── █████████████████░ 90%  — 维度 B: Depth 档位
├── ██████████████████ 95%  — OrderBook 同步协议
├── ██████████████░░░░ 70%  — 维度 C: Policy/Demand
├── ░░░░░░░░░░░░░░░░░░  0%  — Market State Engine
└── ░░░░░░���░░░░░░░░��░░  0%  — 剩余基础设施
```

## P0 — PolicyManager (维度 C) ✅ 已完成

- [x] PolicyManager + DemandSet 结构体
- [x] RequestDemand / ReleaseDemand API
- [x] Demand ⊆ Policy 校验 (streams/orderbook/depth)
- [x] ActivePolicy / ActiveStreams 输出
- [x] DemandLog 审计追踪
- [x] 10 个单元测试 ALL PASS

## P0 — 剩余

| # | 任务 | 说明 | 预估 |
|---|------|------|------|
| 1 | DynamicAllowed 字段 | Entry 新增 DynamicAllowed bool, 控制运行时 Demand 扩展 | ~30 行 |
| 2 | StreamRate per-symbol | symbolBook 新增 StreamRate 字段, 替代全局 ManagerConfig.TopNInterval | ~40 行 |
| 3 | StoragePolicy 抽象 | 抽象 StoragePolicy/SaveDepth/SaveKline/RetentionTTL 为独立结构体 | ~60 行 |
| 4 | BusPolicy 抽象 | 抽象 BusPolicy/PublishTrade/PublishDepth/TopicPrefix | ~40 行 |

## P1 — 连接治理

| # | 任务 | 说明 | 预估 |
|---|------|------|------|
| 5 | Combined stream 上限感知 | streamConfig 检测 combined stream 上限, 超限自动分片 | ~300 行 |
| 6 | Replay Buffer (Ring 30s) | per-symbol ring buffer 缓存最近 30s Book Event | ~200 行 |
| 7 | total_stream_limit 配置 | whitelist.yaml 新增 total_stream_limit 字段 | ~50 行 |
| 8 | StreamRate per-symbol 接入 | 接入 P0-2 的 StreamRate 字段到 streamConfig | ~30 行 |

## P2 — Market State (未来)

| # | 任务 | 说明 | 预估 |
|---|------|------|------|
| 9 | Feature Registry | 插件式特征注册 (MicroPrice/QueueImbalance/OFI) | ~500 行 |
| 10 | Feature Scheduler | Dirty Flag + 异步计算 + Cache (Book 100次 → Feature 10次) | ~300 行 |
| 11 | Market State Engine | Queue/Liquidity/Flow → MarketState → Alpha | 大型工程 |
| 12 | Market Digital Twin | Real Exchange → Gateway → Digital Twin → Research/Backtest/AI | 3-5年愿景 |

## 关联文档

- `report/binance/orderbook-deep-analysis.md` — 完整 19 章对照分析
- `knowledge/OrderBook.md` — 设计文档 v2
- `internal/client/policy/manager.go` — PolicyManager 实现
