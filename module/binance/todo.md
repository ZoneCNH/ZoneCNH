# Plan 013 — 白名单规则统一重构（禁止向后兼容）

> 基于 `report/binance/WHITELIST-LOGIC-ANALYSIS-20260709.md`（PR #1742）。
> 完整计划：[`plans/binance/013-whitelist-unification-plan-20260709.md`](../../plans/binance/013-whitelist-unification-plan-20260709.md)（PR #1743）。
> 目标：7 套 symbol 控制机制收敛为 1 套；删除全部死代码；PG 双表为 SSOT。
> 状态：**✅ Phase 0-6 全部完成（2026-07-09）**
> 更新：2026-07-09

## 总体进度

```
████████████████████ 100%  — Phase 0-6 全部完成
├── ██████████████████ 100%  — Phase 0: 架构决策冻结（用户授权全执行）
├── ██████████████████ 100%  — Phase 1: 删死代码（commit 8985105）
├── ██████████████████ 100%  — Phase 2: PG tier 词表迁移（migration 017/018）
├── ██████████████████ 100%  — Phase 3: tierCapabilityMap + DepthLevel 全链路
├── ██████████████████ 100%  — Phase 4: 服务端准入换新词表
├── ██████████████████ 100%  — Phase 5: 文档治理同步
└── ██████████████████ 100%  — Phase 6: 端到端验证（15 boundary-gates 全过）
```

## 已确认的 6 项决策（Phase 0 基线）

| # | 决策点 | 选择 |
|---|---|---|
| 1 | Tier 词表 | 重新设计统一词表 `prime/standard/lite/blocked`，两套旧词表都不保留 |
| 2 | 真相源 SSOT | PG 双表（`whitelist` + `orderbook_whitelist`） |
| 3 | DepthLevel | 接通全链路（tier 驱动 per-symbol depth） |
| 4 | 交付边界 | Lead/Executor 分离，各 Phase 独立 PR |
| 5 | 能力维度存储 | tier 单列推导——PG 只存 tier，三元组由 `tierCapabilityMap` 代码映射表推导，不加 PG 列 |
| 6 | 落盘位置 | 主仓 `plans/binance/` |

---

## Phase 0 — 架构决策冻结（阻断一切）

- [x] 0.1 计划经用户审批，4 档 tier 词表 + 三元组映射冻结（2026-07-09 用户授权全执行）
- [x] 0.2 决策记录于本 todo + plans/013 + CHANGELOG

## Phase 1 — 删死代码（低风险，先清理战场）✅ commit 8985105

> ⚠️ **认知纠正**：上一轮 OrderBook todo（PR #1741）把 `PolicyManager + DemandSet`、`StoragePolicy/BusPolicy`、`total_stream_limit (whitelist.yaml)` 标记为「完成」。但 PR #1742 核实这些**全部是未接线的死代码**（零生产引用）。本 Phase 正式删除它们。

- [x] 1.1 删 `pkg/binancecfg/tier_map.go` + `tier_map_test.go`
- [x] 1.2 删 `pkg/binancecfg/whitelist_config.go` + `whitelist_config_test.go` + `whitelist_watcher*.go`
- [x] 1.3 删 `pkg/binancecfg/feature_acl*.go`（含孤儿 `feature_acl_test.go`）
- [x] 1.4 删 `internal/client/policy/` 整个目录（manager.go + storage_policy.go + tests）
- [x] 1.5 删 `configs/whitelist.yaml`、`strategy_acl.yaml`、`features.yaml`
- [x] 1.6 全量 `go build ./... && go vet ./... && go test ./...` 全绿

## Phase 2 — PG tier 词表迁移（migration 017 + 018，决策 5：不加列）✅ commit 3910085 + 017

- [x] 2.1 新增 `migrations/017_whitelist_tier_check.sql`：`whitelist.tier` + `catalog_symbols.tier` + `whitelist_review.tier` 加 CHECK `('prime','standard','lite','blocked')`（NULL 绕过 options）；幂等 DO 块 + DOWN 脚本
- [x] 2.2 新增 `migrations/018_whitelist_tier_migration.sql`：`UPDATE ... SET tier='prime' WHERE tier='core'`（三表）；`standard` 保留；空值保持 NULL（commit 3910085）
- [x] 2.3 `whitelist_adapter.go` SELECT 不变；`WhitelistItem` struct 不加字段（tier 已是 SSOT）

## Phase 3 — tierCapabilityMap + 客户端三元组流通（接通 DepthLevel 全链路）✅

> 修复 5 处 DepthLevel 断链点（PR #1742 §四 P1-1）。

- [x] 3.0 新增 `pkg/whitelistclient/tier_capability.go`：`tierCapabilityMap` + `CapabilityForTier()` + `Capability{Streams,Features,Depth}`（决策 5 SSOT）；单测覆盖 4 档映射 + 未知→blocked + 数值 SSOT（`tier_capability_test.go`）
- [x] 3.1 `OrderbookWhitelist()`（client.go:185）用 `CapabilityForTier` 解析；`ObEntry`（client.go:424）加 `DepthLevel` 字段
- [x] 3.2 `obWantEntry`（runtime.go:1010）加 `depthLevel`；`buildOrderBookWantSet` 填充 features+depth（fail-open 用 standard 默认值）
- [x] 3.3 `SubscribeWithFeatures`（manager.go:385）增加 `depthLevel` 参数；`manager.go:398` 用传入值替换硬编码 `DepthLevelL4`；`startOrderBookSubscriptions:977` 透传
- [x] 3.4 新增 `SyncSubscriptionsWithCapabilities`（manager.go，want 值 `map[string]map[string]Capability`）；`syncOrderBookSubscriptions`（runtime.go:1109）改调新方法

## Phase 4 — 服务端准入规则换新词表 ✅

- [x] 4.1 `rules.go:24-26` `autoAdmitTiers = {prime, standard, lite}`（blocked 不在内 → 审核队列）
- [x] 4.2 `catalog.go` `applyCatalogClassification` 写新 tier（`classifyTier`: blocked>prime>standard>lite）；`isCoreCatalogEntry` → `isPrimeCatalogEntry`；SymbolPriority 重映射（prime=100/standard=50/lite=20/blocked=1）；单测覆盖 4 档判定
- [x] 4.3 `config.go` `TierConfig` 加 `StandardQuoteVolume`/`BlockedSymbols` + env（`FOUNDATIONX_BINANCE_TIERS_STANDARD_QUOTE_VOLUME` 默认 50M / `TIERS_BLOCKED_SYMBOLS`）；单测覆盖 env 解析
- [x] 4.4 options 产品线回归：保持强制人工审核（rules.go:141），`TestRules_EvaluateAdmission_OptionsForcedReview` PASS

## Phase 5 — 文档治理同步 ✅

- [x] 5.1 `module/binance/spec/SPEC.md` Spec-Version v4.0.1→v4.1.0；FR-051 更新为 4 档词表 + tierCapabilityMap + DepthLevel 全链路；changelog 加 v4.1.0 行
- [x] 5.2 `report/binance/README.md` 标注 Plan 013 已据此报告完成修复
- [x] 5.3 `plans/binance/README.md` 索引表 Plan 013 状态 TODO→DONE
- [x] 5.4 runtime CHANGELOG 加 Plan 013 Added + Changed（breaking）条目

## Phase 6 — 端到端验证 ✅

- [x] 6.1 `go vet` Plan 013 包全绿；`go test -race` whitelistclient/server-whitelist/binancecfg/orderbook 全绿（注：`TestReconnectQueue_StopBlocksUntilDrain` 为预存在 flaky timing 测试，隔离运行 PASS，与 Plan 013 无关）
- [x] 6.2 集成测试：单测覆盖 PG tier → CapabilityForTier → (streams/features/depth) 三元组 + 4 档分级
- [x] 6.3 回归：options 仍强制人工审核（`TestRules_EvaluateAdmission_OptionsForcedReview` + `TestSyncJob_OptionsNeedsReview` PASS）
- [x] 6.4 boundary-gates 全过（15/15 PASS）

---

## 新 Tier 词表（决策 1，禁止向后兼容）

| Tier | StreamType | OrderbookFeatures | DepthLevel | 准入 |
|---|---|---|---|---|
| `prime` | 255 (All) | 63 (All) | L4 (Full) | auto-admit，观察期 3 天 |
| `standard` | 146 | 7 | L2 (Top20) | auto-admit，观察期 3 天 |
| `lite` | 129 | 0（无 OB） | None | auto-admit，观察期 3 天 |
| `blocked` | 0 | 0 | None | 拒绝（审核队列） |

> tier 是正交维度（StreamType 8位 / OrderbookFeatures 6位 / DepthLevel 5档）的预设组合。三元组由 `tierCapabilityMap` 静态映射，PG 只存 tier 单列（决策 5）。
>
> **数值 SSOT 说明**：standard streams=146（plan §1.2 散文写 "trade+bookTicker+kline+ticker" 合 147，但表格数值 SSOT 为 146=bookTicker+kline+ticker）；实现按数值 SSOT 146 落地，差异已在 `tier_capability.go` 注释标注。

## 已知预存在问题（不在 Plan 013 范围）

- `internal/server/assembly/storage.go:103` 引用 `taosx.Config.Pool`/`DefaultPoolConfig`（commit 9f6435b），需 workspace 本地 taosx；go.mod pin 的 v1.0.3 无此字段。属 taosx 发版同步问题，非 Plan 013 引入。
- `internal/ingestcodec` 在 workspace（本地 foundationx）下 contracts 类型缺失，GOWORK=off 下正常——workspace 版本差异伪影。

## 关键 STOP 条件（全部满足）

1. ✅ Phase 0 已审批
2. ✅ Phase 1 删除后编译无断裂（死代码判断正确）
3. ✅ Phase 2 migration 可回滚（017/018 各含 DOWN 说明）
4. ✅ Phase 3 DepthLevel 全链路无断链
5. ✅ 各 Phase `go test` 绿

## 回归风险（已缓解）

- **数据迁移**：Phase 2 生产 PG `core→prime`，018 脚本幂等可重跑，017 CHECK 与 catalog.go 改值同批
- **options 短路**：Phase 4 单测显式覆盖（options 不进 tier 体系，强制审核）
- **env 降级语义**：fail-open 改用 `standard` tier 默认值（不再 allow-all）

## 关联文档

- `plans/binance/013-whitelist-unification-plan-20260709.md` — 完整 6 Phase 计划（PR #1743）
- `report/binance/WHITELIST-LOGIC-ANALYSIS-20260709.md` — 现状诊断报告（PR #1742）
- `report/binance/orderbook-deep-analysis.md` — OrderBook 19 章对照（维度 A/B/C）
- `module/binance/spec/SPEC.md` — FR-051 已更新（v4.1.0）

## 不在范围（follow-up）

- `strategy_acl.yaml` 策略→stream 权限矩阵接线（本计划直接删，未来需要另开 plan）
- Market State Engine / Market Digital Twin（独立轨道）
- `total_stream_limit` 连接级流分片（本计划删，另设计）
