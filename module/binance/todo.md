# Plan 013 — 白名单规则统一重构（禁止向后兼容）

> 基于 `report/binance/WHITELIST-LOGIC-ANALYSIS-20260709.md`（PR #1742）。
> 完整计划：[`plans/binance/013-whitelist-unification-plan-20260709.md`](../../plans/binance/013-whitelist-unification-plan-20260709.md)（PR #1743）。
> 目标：7 套 symbol 控制机制收敛为 1 套；删除全部死代码；PG 双表为 SSOT。
> 更新：2026-07-09

## 总体进度

```
░░░░░░░░░░░░░░░░░░░░   0%  — Phase 0 待审批后启动
├── ░░░░░░░░░░░░░░░░░░   0%  — Phase 0: 架构决策冻结
├── ░░░░░░░░░░░░░░░░░░   0%  — Phase 1: 删死代码
├── ░░░░░░░░░░░░░░░░░░   0%  — Phase 2: PG tier 词表迁移 (migration 017/018)
├── ░░░░░░░░░░░░░░░░░░   0%  — Phase 3: tierCapabilityMap + DepthLevel 全链路
├── ░░░░░░░░░░░░░░░░░░   0%  — Phase 4: 服务端准入换新词表
├── ░░░░░░░░░░░░░░░░░░   0%  — Phase 5: 文档治理同步
└── ░░░░░░░░░░░░░░░░░░   0%  — Phase 6: 端到端验证
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

- [ ] 0.1 计划经用户审批，4 档 tier 词表 + 三元组映射冻结
- [ ] 0.2 新建 bd issue 绑定本计划（beads），记录决策

**STOP**：Phase 0 未审批 → 禁止 Phase 1+。

## Phase 1 — 删死代码（低风险，先清理战场）

> ⚠️ **认知纠正**：上一轮 OrderBook todo（PR #1741）把 `PolicyManager + DemandSet`、`StoragePolicy/BusPolicy`、`total_stream_limit (whitelist.yaml)` 标记为「完成」。但 PR #1742 核实这些**全部是未接线的死代码**（零生产引用）。本 Phase 正式删除它们。

- [ ] 1.1 删 `pkg/binancecfg/tier_map.go` + `tier_map_test.go`
- [ ] 1.2 删 `pkg/binancecfg/whitelist_config.go` + `whitelist_config_test.go` + `whitelist_watcher*.go`
- [ ] 1.3 删 `pkg/binancecfg/feature_acl*.go`（含孤儿 `feature_acl_test.go`）
- [ ] 1.4 删 `internal/client/policy/` 整个目录（manager.go + storage_policy.go + tests）
- [ ] 1.5 删 `configs/whitelist.yaml`、`strategy_acl.yaml`、`features.yaml`
- [ ] 1.6 全量 `go build ./... && go vet ./... && go test ./...` 全绿

**STOP**：Phase 1 任一包编译失败 → 修复后重跑，不得跳过。

## Phase 2 — PG tier 词表迁移（migration 017 + 018，决策 5：不加列）

- [ ] 2.1 新增 `migrations/017_whitelist_tier_check.sql`：`whitelist.tier` + `catalog_symbols.tier` 加 CHECK `('prime','standard','lite','blocked')`（options 空值用 NULL 绕过）
- [ ] 2.2 新增 `migrations/018_whitelist_tier_migration.sql`：`UPDATE whitelist SET tier='prime' WHERE tier='core'`；`standard` 保留；空值保持 NULL
- [ ] 2.3 `whitelist_adapter.go` SELECT 不变；`WhitelistItem` struct 不加字段（tier 已是 SSOT）

**STOP**：migration 必须可回滚（017/018 各保留 DOWN 脚本或 PR 记录回滚 SQL：`core←prime` + DROP CHECK）。

## Phase 3 — tierCapabilityMap + 客户端三元组流通（接通 DepthLevel 全链路）

> 修复 5 处 DepthLevel 断链点（PR #1742 §四 P1-1）。

- [ ] 3.0 新增 `pkg/whitelistclient/tier_capability.go`：`tierCapabilityMap` + `CapabilityForTier()` + `Capability{Streams,Features,Depth}`（决策 5 SSOT）
- [ ] 3.1 `OrderbookWhitelist()`（client.go:185）用 `CapabilityForTier` 解析；`ObEntry`（client.go:424）加 `DepthLevel` 字段
- [ ] 3.2 `obWantEntry`（runtime.go:1010）加 `depthLevel`；`buildOrderBookWantSet` 用 `CapabilityForTier` 填充
- [ ] 3.3 `SubscribeWithFeatures`（manager.go:385）增加 `depthLevel` 参数；`manager.go:398` 用传入值替换硬编码 `DepthLevelL4`
- [ ] 3.4 新增 `SyncSubscriptionsWithCapabilities`（manager.go:534 扩展，want 值改 `map[string]map[string]Capability`）；`syncOrderBookSubscriptions`（runtime.go:1109）改调新方法

**STOP**：Phase 3 DepthLevel 任一环仍断链 → 不得进入 Phase 4。

## Phase 4 — 服务端准入规则换新词表

- [ ] 4.1 `rules.go:24-26` `autoAdmitTiers = {prime, standard, lite}`
- [ ] 4.2 `catalog.go` `applyCatalogClassification` 写新 tier；`isCoreCatalogEntry` → `isPrimeCatalogEntry`；SymbolPriority 重映射
- [ ] 4.3 `config.go` `TierConfig` 扩展多档阈值 + env（前缀 `FOUNDATIONX_BINANCE_TIERS_*`）
- [ ] 4.4 options 产品线回归：保持强制人工审核（rules.go:139），不进 tier 体系

## Phase 5 — 文档治理同步

- [ ] 5.1 `module/binance/spec/SPEC.md` 相关 FR 更新（FR-013/033 等）
- [ ] 5.2 `report/binance/README.md` 链接 Plan 013
- [ ] 5.3 `plans/binance/README.md` 索引表 Plan 013 状态 TODO→IN PROGRESS/DONE
- [ ] 5.4 版本 bump（runtime + manifest）

## Phase 6 — 端到端验证

- [ ] 6.1 `go build ./... && go vet ./... && go test -race ./...` 全绿
- [ ] 6.2 集成测试：PG 填不同 tier symbol → 客户端订阅得到对应 streams/features/depth
- [ ] 6.3 回归：options 仍强制人工审核
- [ ] 6.4 boundary-gates 全过

---

## 新 Tier 词表（决策 1，禁止向后兼容）

| Tier | StreamType | OrderbookFeatures | DepthLevel | 准入 |
|---|---|---|---|---|
| `prime` | 255 (All) | 63 (All) | L4 (Full) | auto-admit，观察期 3 天 |
| `standard` | 146 | 7 | L2 (Top20) | auto-admit，观察期 3 天 |
| `lite` | 129 | 0（无 OB） | None | auto-admit，观察期 3 天 |
| `blocked` | 0 | 0 | None | 拒绝 |

> tier 是正交维度（StreamType 8位 / OrderbookFeatures 6位 / DepthLevel 5档）的预设组合。三元组由 `tierCapabilityMap` 静态映射，PG 只存 tier 单列（决策 5）。

## 关键 STOP 条件

1. Phase 0 未审批 → 禁止 Phase 1+
2. Phase 1 删除后编译断裂 → 必须修复（验证死代码判断正确性）
3. Phase 2 migration 不可回滚 → 阻断
4. Phase 3 DepthLevel 任一环仍断链 → 不得进入 Phase 4
5. 任一 Phase `go test` 不绿 → 不得声明该 Phase DONE

## 回归风险

- **数据迁移**：Phase 2 生产 PG `core→prime`，迁移脚本须先 staging 验证 + 保留回滚 SQL
- **options 短路**：须确保 options 不误入新 tier 体系（Phase 4 单测显式覆盖）
- **env 降级语义**：`FOUNDATIONX_BINANCE_STREAM_SYMBOLS` 的 provider/env/allow-all 三态降级（runtime.go:353-371）需重新定义，fail-open 时用 `standard` 默认值而非 allow-all

## 关联文档

- `plans/binance/013-whitelist-unification-plan-20260709.md` — 完整 6 Phase 计划（PR #1743）
- `report/binance/WHITELIST-LOGIC-ANALYSIS-20260709.md` — 现状诊断报告（PR #1742）
- `report/binance/orderbook-deep-analysis.md` — OrderBook 19 章对照（维度 A/B/C）
- `module/binance/spec/SPEC.md` — FR-013/033 待 Phase 5 更新

## 不在范围（follow-up）

- `strategy_acl.yaml` 策略→stream 权限矩阵接线（本计划直接删，未来需要另开 plan）
- Market State Engine / Market Digital Twin（独立轨道）
- `total_stream_limit` 连接级流分片（本计划删，另设计）
