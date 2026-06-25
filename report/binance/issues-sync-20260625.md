# report/binance issue 同步账本（2026-06-25）

| 字段 | 值 |
| --- | --- |
| Last-Updated | 2026-06-25 |
| Scope | `report/binance/` 当前有效报告与历史语境对齐 |
| Runtime Anchor | `/home/binance@f18a329` |
| Status Projection | `24 Done / 10 Partial / 0 Pending` |
| Issue Range | GitHub / Beads `#1104`-`#1118` |
| Sync Result | Beads 15 / GitHub 15 |
| Team Evidence | Pauli 完成 Beads/GitHub 查重；Jason 完成 `/home/binance@f18a329` 运行时代码与证据复核 |
| Team Limitation | OMX team worktree 因当前仓库已有未提交文档迁移变更被阻断，改用 native agent team 执行 |
| Status Policy | `#1106` 已由本轮 `report/binance/` 文档对齐关闭；`#1104`、`#1105`、`#1107`-`#1118` 保持 Open，直到 runtime 或证据闭合 |

## 当前结论

`report/binance/` 的当前严格口径是：`binance` runtime 已闭合 storage assembly 基础设施路径，但仍有 15 个可追踪事项。其中 3 个为 P0，7 个为 P1，5 个为 P2；其中 `#1106` 为文档对齐项，本文档更新后已关闭，其余 14 个 runtime/evidence items 保持开放。

当前模块状态投影统一为 `24 Done / 10 Partial / 0 Pending`。Partial FR 为 `FR-007`、`FR-007a`、`FR-011`、`FR-016`、`FR-017`、`FR-023`、`FR-024`、`FR-026`、`FR-027`、`FR-028`。

## Beads / GitHub 映射

| Gap ID | Priority | Beads | GitHub | 标题 | 当前状态 | 关闭条件 |
| --- | --- | --- | --- | --- | --- | --- |
| RB-20260625-P0-01 | P0 | ZoneCNH-4ba | #1104 | 补齐 FR-016 历史回补运行时 REST fetcher 注入 | Open | runtime 注入真实 REST fetcher，并用 live/smoke 证据证明 history backfill 不再只依赖 mock |
| RB-20260625-P0-02 | P0 | ZoneCNH-rfx | #1105 | 厘清 Kafka broker roundtrip 证据冲突 | Open | 以同一 commit、同一 broker 配置重新运行 producer/consumer roundtrip，并废弃或标注旧冲突证据 |
| RB-20260625-P0-03 | P0 | ZoneCNH-hw2 | #1106 | 对齐 report/binance 状态文档 | Closed | `report/binance/` 当前口径全部指向本账本和 `/home/binance@f18a329`；本切片不修改 `module/binance/` |
| RB-20260625-P1-01 | P1 | ZoneCNH-9p8 | #1107 | 明确或实现 UM/CM/Options 历史 REST endpoint 支持 | Open | spot/um/cm/options 历史 endpoint 行为被实现或明确降级，并有测试覆盖 |
| RB-20260625-P1-02 | P1 | ZoneCNH-5kn | #1108 | 用 mainnet 样本校验 Options ticker 字段归一化 | Open | Options ticker mainnet 样本覆盖 `normalize.go` 中 Options 字段映射 |
| RB-20260625-P1-03 | P1 | ZoneCNH-0y2 | #1109 | 补齐速率限制平滑与 token bucket 机制 | Open | 从窗口计数升级为可验证的平滑/token bucket 限流，并覆盖 websocket/reconnect 场景 |
| RB-20260625-P1-04 | P1 | ZoneCNH-5xi | #1110 | 补齐分布式 tracing 与 trace context 传播 | Open | runtime 边界传递 trace context，并有 span/trace 证据 |
| RB-20260625-P1-05 | P1 | ZoneCNH-cg1 | #1111 | 补齐 Options active symbol live 覆盖 | Open | Options active symbol 通过 live mainnet 证据闭合 |
| RB-20260625-P1-06 | P1 | ZoneCNH-0pz | #1112 | 建立 storage mock 与 fake 的测试标准 | Open | 区分 fake/mock/live 证据级别，更新测试命名、文档和 gate 规则 |
| RB-20260625-P1-07 | P1 | ZoneCNH-nr1 | #1113 | 补齐 100K TPS/backpressure 标准与实证 | Open | 提供可复现的 100K TPS/backpressure benchmark 与结果解释 |
| RB-20260625-P2-01 | P2 | ZoneCNH-3e1 | #1114 | 补齐增量 order book rebuild 状态机 | Open | replay/order book rebuild 拥有增量状态机、乱序处理与测试 |
| RB-20260625-P2-02 | P2 | ZoneCNH-eg8 | #1115 | 将 ClickHouse ETL 从内存源升级为持久/多实例来源 | Open | AggSource 不再只依赖进程内内存源，并有多实例/持久源验证 |
| RB-20260625-P2-03 | P2 | ZoneCNH-zwb | #1116 | 支持增量 hot reload diff 而非全量重连 | Open | hot reload 能按 diff 更新订阅，避免全量断连重连 |
| RB-20260625-P2-04 | P2 | ZoneCNH-ioy | #1117 | 持久化历史回补进度 | Open | history/reconcile/rehydration progress 持久化，重启后可恢复 |
| RB-20260625-P2-05 | P2 | ZoneCNH-1i0 | #1118 | 补齐持久 DLQ wiring 与 replay 流程 | Open | DLQ 使用持久 backend，并有 replay 与 operational runbook |

## 文档对齐范围

本轮同步只更新以下 `report/binance/` 文档；`module/binance/` 不在本写入切片内。

- `report/binance/INDEX.md`
- `report/binance/issues-sync-20260625.md`
- `report/binance/symbol-sync-deep-analysis-20260625.md`
- `report/binance/binance-module-analysis.md`
- `report/binance/binance-data-flow-architecture.md`
- `report/binance/binance-module-standards.md`
- `report/binance/v0.2.0-release-gate-verdict-20260625.md`

## 证据锚点

- `/home/binance@f18a329`
- `report/binance/archive/2026-06-25-v0.2.0-live-gate/release-evidence/storage-assembly-live.txt`
- `report/binance/archive/2026-06-25-v0.2.0-live-gate/release-evidence/kafka-broker-live.txt`
- Beads IDs `ZoneCNH-4ba`、`ZoneCNH-rfx`、`ZoneCNH-hw2`、`ZoneCNH-9p8`、`ZoneCNH-5kn`、`ZoneCNH-0y2`、`ZoneCNH-5xi`、`ZoneCNH-cg1`、`ZoneCNH-0pz`、`ZoneCNH-nr1`、`ZoneCNH-3e1`、`ZoneCNH-eg8`、`ZoneCNH-zwb`、`ZoneCNH-ioy`、`ZoneCNH-1i0`
- GitHub Issues #1104-#1118

[RULES I BROKE]：无
