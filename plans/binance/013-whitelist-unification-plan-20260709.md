# Plan 013：binance 白名单规则统一重构（禁止向后兼容）

> **生成日期**：2026-07-09
> **基线**：ZoneCNH `origin/main`（e38c7908）+ binance runtime `main`
> **输入报告**：[`report/binance/WHITELIST-LOGIC-ANALYSIS-20260709.md`](../../report/binance/WHITELIST-LOGIC-ANALYSIS-20260709.md)（PR #1742）
> **目标仓**：`/home/workspace/binance`（runtime）+ 本仓（治理文档）
> **认识论声明**：代码现状标 `[COMPUTED]`（Explore agent + 主会话 grep 双重核验），设计决策标 `[INFERRED]`
> **交付边界**：本文件为纯计划文档（Lead 产出）；各 Phase 代码实现由 Executor 在独立 worktree 执行，不在此 PR 写代码

---

## 0. Context（为什么做这个）

用户反馈「行情流白名单 + 订单簿白名单逻辑混乱」。深度核查（PR #1742）证实 binance 存在 **7 套 symbol 控制机制，仅 3 套生效**。根因是**一次架构范式迁移（本地文件 → 服务端 SSOT）没清理完**：第一代设计（`whitelist.yaml` + 4 级 tier + `policy.Manager`）的代码和配置注释还留着，第二代（PG 双表 + 2 级 tier）已接管生产。两套并存导致：

- 运维改 `configs/whitelist.yaml` 无任何运行时效果，但文件注释声称「三个白名单层级叠加生效」
- `tier_map.go` 4 级分级的 `MaxDepth()` 在订单簿订阅路径完全断链，所有订阅硬编码 Full 深度
- PG schema 缺列（`allowed_streams`/`orderbook_features`/`depth_level` 根本不在表里），这些维度全靠客户端默认值/硬编码

**本计划目标**：按已确认决策「重新设计统一词表 + PG 双表 SSOT + 接通 DepthLevel 全链路 + 禁止向后兼容」，把 7 套机制收敛为 **1 套规则**，删除全部死代码，让 PG 双表成为唯一权威。

### 已确认的 6 项决策

| # | 决策点 | 选择 |
|---|---|---|
| 1 | Tier 词表 | **重新设计统一词表**（core/standard 2级 与 core/liquid/basic/blocked 4级 都不保留） |
| 2 | 真相源 SSOT | **PG 双表**（`whitelist` + `orderbook_whitelist`），env/yaml 降级或删除 |
| 3 | DepthLevel | **接通全链路**（tier 驱动 per-symbol depth） |
| 4 | 交付边界 | **纯计划文档**（本文件），Lead/Executor 分离 |
| 5 | 能力维度存储 | **tier 单列推导**——PG 只存 tier，三元组(streams/features/depth)由代码静态映射表推导，不加 PG 列 |
| 6 | 落盘位置 | **主仓 ZoneCNH/plans/binance/**（本仓是文档枢纽） |

---

## 1. 目标架构（统一后的唯一规则）

`[INFERRED]` 设计基于 agent 调研的 20 个维度全集（StreamType 8位 / OrderbookFeatures 6位 / DepthLevel 5档 为正交坐标轴）。

### 1.1 核心原则

Tier 是正交维度的**预设组合**，不是平行新维度。新词表不新增维度，而是定义「运营快捷方式 → (streams, features, depth) 三元组」的预设映射。

**按决策 5**：SSOT 是 **PG 的 tier 单列**，三元组由代码里一张 `tierCapabilityMap` 静态映射表推导（`tier → (StreamType, OrderbookFeatures, DepthLevel)`）。PG 不存三元组列——schema 最精简，改 capability 只改代码一处映射表，不碰数据库。

### 1.2 新 Tier 词表（4 档，语义重新定义）

| Tier | 含义 | StreamType | OrderbookFeatures | DepthLevel | 准入策略 |
|---|---|---|---|---|---|
| `prime` | 核心主力，全流全深度 | `StreamAll`(255) | `ObFeatureAll`(63) | `L4`(Full) | auto-admit，观察期 3 天 |
| `standard` | 标准订阅，全流无落盘 | trade+bookTicker+kline+ticker(146) | Depth+TopN+Incremental(7) | `L2`(Top20) | auto-admit，观察期 3 天 |
| `lite` | 轻量订阅，仅行情无订单簿 | trade+ticker(129) | 0（不订阅 OB） | `None` | auto-admit，观察期 3 天 |
| `blocked` | 显式禁用 | 0 | 0 | `None` | 拒绝准入 |

**设计理由** `[INFERRED]`：
- 不复用 `core/standard` 也不复用 `core/liquid/basic/blocked`，避免与旧词表的语义联想 → 符合「禁止向后兼容」
- capability 差异通过 `tierCapabilityMap` 静态表达，杜绝「tier 名 vs 实际行为脱节」（旧 4 级 tier_map 的死代码病灶）
- `options` 产品线**不进 tier 体系**，保持现有「强制人工审核」短路（`rules.go:139`），独立于这套词表
- **取舍**：tier 单列推导牺牲 per-symbol 微调能力（同 tier 的所有 symbol capability 完全相同）。这是有意的——当前的 per-symbol 差异（如 `whitelist.yaml` 里 core/liquid 不同 features）本就是死代码从未生效，统一为 tier 粒度反而消除「为何这两个 standard symbol 行为不同」的困惑。若未来确需 per-symbol 覆盖，再开 follow-up plan 加 override 层。

### 1.3 `tierCapabilityMap` 代码映射表（SSOT 的代码侧）

`[INFERRED]` 新增于 `pkg/whitelistclient/`（`tier_capability.go`）：

```go
// tierCapabilityMap 是 tier → (streams, features, depth) 的唯一映射 SSOT。
// 改任何 tier 的采集行为，只改这张表。
var tierCapabilityMap = map[string]Capability{
    "prime":    {Streams: StreamAll, Features: ObFeatureAll, Depth: DepthLevelL4},
    "standard": {Streams: 146,       Features: 7,            Depth: DepthLevelL2},
    "lite":     {Streams: 129,       Features: 0,            Depth: DepthLevelNone},
    "blocked":  {Streams: 0,         Features: 0,            Depth: DepthLevelNone},
}

type Capability struct {
    Streams  StreamType
    Features OrderbookFeatures
    Depth    DepthLevel
}

// CapabilityForTier 返回 tier 对应的采集能力三元组；未知 tier 返回 blocked 语义（最保守）。
func CapabilityForTier(tier string) Capability { ... }
```

### 1.4 数据模型（PG 为 SSOT，决策 5：tier 单列）

PG `whitelist.tier` 列保持 `VARCHAR(16)`，但：
- migration 017 加 CHECK 约束收窄为 `('prime','standard','lite','blocked')`
- migration 018 数据迁移：旧值 `core → prime`、`standard` 保留、空值（options）保持 NULL
- **不加** `allowed_streams`/`orderbook_features`/`depth_level` 三列——三元组由 `tierCapabilityMap` 推导

`orderbook_whitelist` 表保持子集约束（必须先在 `whitelist` 中）。SyncJob 写入时按 `tierCapabilityMap[tier].Features > 0` 决定是否插入（`prime`/`standard` 可订阅 OB，`lite`/`blocked` 不可）。

### 1.5 客户端订阅链（接通后）

```
PG whitelist 表 (tier)
  ↓ whitelistclient.StreamWhitelist() / OrderbookWhitelist()
  ↓ 内部调 CapabilityForTier(entry.Tier) 查 tierCapabilityMap
Entry { Tier → 解析出 Streams, Features, DepthLevel }   ← ObEntry 加回 DepthLevel 字段
  ↓ runtime.buildOrderBookWantSet()
obWantEntry { features, depthLevel }      ← 加 depthLevel 字段
  ↓ mgr.SyncSubscriptionsWithCapabilities(want map[...]Capability)  ← 新签名
symbolBook.depthLevel = capability.Depth  ← 不再硬编码 L4
  ↓ manager.go:264 已有分档逻辑真正生效
按 tier 截断到 L4/L2/None
```

---

## 2. 现状证据（删除/改动清单的基础）

`[COMPUTED]` 全部经 Explore agent + 主会话 grep 双重核验。

### 2.1 死代码文件（零生产引用，全删）

| 文件 | 引用情况 | 核验方式 |
|---|---|---|
| `pkg/binancecfg/tier_map.go` | 仅 `tier_map_test.go` + `policy/manager.go:105` 注释字符串 | grep `WLTIER\|ParseTier\|MaxDepth` 零生产命中 |
| `pkg/binancecfg/whitelist_config.go` | 仅 `whitelist_config_test.go` | `LoadWhitelistFile` 零生产调用 |
| `pkg/binancecfg/whitelist_watcher.go` | 仅 `whitelist_watcher_test.go` | `NewWhitelistWatcher` 零生产调用 |
| `pkg/binancecfg/feature_acl*.go` | 仅 test（源文件疑似已缺） | `LoadFeatureACL` 零生产命中 |
| `internal/client/policy/` 整个目录 | 仅自身 `_test.go` | `policy.NewManager` 零生产调用（主会话 grep exit=1） |
| `configs/whitelist.yaml` | 无 env/compose/docs 引用 | 全仓 grep |
| `configs/strategy_acl.yaml` | 无 Go loader | — |
| `configs/features.yaml` | 无 Go loader | — |

随删测试文件：`tier_map_test.go`、`whitelist_config_test.go`、`whitelist_watcher_test.go`、`feature_acl_test.go`、`policy/{manager,storage_policy}_test.go`。

### 2.2 DepthLevel 断链点（5 处，全修）

| # | 位置 | 当前 | 目标 |
|---|---|---|---|
| 1 | `pkg/whitelistclient/client.go:424` `ObEntry` | 只有 `Features` | 加 `DepthLevel` 字段 |
| 2 | `pkg/whitelistclient/client.go:470` `OrderbookWhitelist()` | 丢弃 DepthLevel | 透传 DepthLevel |
| 3 | `internal/client/orderbook/manager.go:385` `SubscribeWithFeatures` | 签名不收 depth | 增加 depthLevel 参数 |
| 4 | `internal/client/orderbook/manager.go:398` | 硬编码 `DepthLevelL4` | 用传入值 |
| 5 | `internal/client/orderbook/manager.go:534` `SyncSubscriptions` | 只收 `map[string]map[string]bool`，丢 features+depth | 新增 `SyncSubscriptionsWithCapabilities`，want 值改为 Capability 结构体 |

### 2.3 生效链改动点（换新词表）

| 位置 | 当前 | 目标 |
|---|---|---|
| `internal/server/whitelist/rules.go:24-26` | `autoAdmitTiers={core,standard}` | `{prime,standard,lite}` |
| `internal/client/catalog.go:391-406` `applyCatalogClassification` | 写 `core`/`standard` | 写新 tier，SymbolPriority 重映射 |
| `internal/client/catalog.go:417-426` `isCoreCatalogEntry` | BTC/ETH 前缀兜底 | 改 `isPrimeCatalogEntry`，阈值用 env |
| `pkg/binancecfg/config.go:62-71` `TierConfig` | 只有 CoreSymbols/CoreQuoteVolume | 扩展为多档阈值（prime/standard 判定） |

### 2.4 PG schema 现状（决策 5 的依据）

`[COMPUTED]` `whitelist_adapter.go` 的 SELECT 只读 8 列（market_type/symbol/base_asset/quote_asset/exchange_status/tier/enabled/orderbook_enabled）——`allowed_streams`/`orderbook_features`/`depth_level` 列在 PG 中根本不存在，客户端这些字段当前全是零值/硬编码默认。

**决策 5 据此选择不加这三列**。理由：(a) 三列从未存在，加列是净新增 schema 复杂度；(b) 三元组与 tier 强绑定，存 tier 单列 + 代码映射表更符合 SSOT；(c) 改 capability 只改代码，无需数据库迁移。

migrations 现有到 **016**，下一个可用 **017**（tier CHECK）、**018**（数据迁移）。命名规范 `NNN_description.sql`，编号保留不重用（007 已占用为空位）。

---

## 3. 执行编排（6 Phase，严格串行 + STOP 条件）

> **角色分工**：本计划是 Lead 产出。各 Phase 代码实现由 Executor（task-executor agent）在独立 worktree 执行；每 Phase 完成后由 verifier 独立验证。

### Phase 0：架构决策冻结（阻断一切）

| Task | 内容 | 验收 |
|---|---|---|
| 0.1 | 本计划经用户审批，4 档 tier 词表 + 三元组映射冻结 | 计划文件审批通过 |
| 0.2 | 新建 bd issue 绑定本计划（beads），记录决策 | `bd show` 可见 |

**STOP**：Phase 0 未审批 → 禁止 Phase 1+。

### Phase 1：删除死代码（低风险，先清理战场）

| Task | 文件 | 验证 |
|---|---|---|
| 1.1 | 删 `pkg/binancecfg/tier_map.go` + `tier_map_test.go` | `go build ./pkg/binancecfg/...` |
| 1.2 | 删 `pkg/binancecfg/whitelist_config.go` + `whitelist_config_test.go` + `whitelist_watcher*.go` | 同上 |
| 1.3 | 删 `pkg/binancecfg/feature_acl*.go` | 同上 |
| 1.4 | 删 `internal/client/policy/` 整个目录 | `go build ./internal/client/...` |
| 1.5 | 删 `configs/whitelist.yaml`、`strategy_acl.yaml`、`features.yaml` | 无文件引用 |
| 1.6 | 全量 `go build ./... && go vet ./... && go test ./...` | 全绿（删除后无编译断裂） |

**STOP**：Phase 1 任一包编译失败 → 修复后重跑，不得跳过。

### Phase 2：PG tier 词表迁移（migration 017 + 018，决策 5：不加列）

| Task | 内容 | 验证 |
|---|---|---|
| 2.1 | 新增 `017_whitelist_tier_check.sql`：`whitelist.tier` + `catalog_symbols.tier` 加 CHECK 约束 `('prime','standard','lite','blocked')`（options 空值用 NULL 绕过） | `psql` 应用成功，违反约束的行报错 |
| 2.2 | 新增 `018_whitelist_tier_migration.sql`：`UPDATE whitelist SET tier='prime' WHERE tier='core'`；`standard` 保留；空值保持 NULL | 迁移后 `SELECT DISTINCT tier` 仅含新词表 + NULL |
| 2.3 | `whitelist_adapter.go` SELECT 不变；`WhitelistItem` struct 不加字段（tier 已是 SSOT） | `go test ./internal/server/assembly/...` 现有测试仍绿 |

**STOP**：migration 必须可回滚（017/018 各保留 DOWN 脚本或 PR 描述记录回滚 SQL：`core←prime` 反向 UPDATE + DROP CHECK）。

### Phase 3：tierCapabilityMap + 客户端三元组流通（接通 DepthLevel 全链路）

| Task | 文件 | 验证 |
|---|---|---|
| 3.0 | 新增 `pkg/whitelistclient/tier_capability.go`：`tierCapabilityMap` + `CapabilityForTier()` + `Capability` 结构体（决策 5 SSOT） | 单测覆盖 4 档映射 + 未知 tier→blocked |
| 3.1 | `OrderbookWhitelist()`（client.go:185）内部用 `CapabilityForTier(entry.Tier)` 解析；`ObEntry`（client.go:424）加 `DepthLevel` 字段 | `go test ./pkg/whitelistclient/...` |
| 3.2 | `obWantEntry`（runtime.go:1010）加 `depthLevel`；`buildOrderBookWantSet` 用 `CapabilityForTier` 填充 features+depth | `go test ./internal/client/...` |
| 3.3 | `SubscribeWithFeatures`（manager.go:385）增加 `depthLevel` 参数；`manager.go:398` 用传入值替换硬编码 `DepthLevelL4` | 单测：prime→L4、standard→L2、lite→None |
| 3.4 | 新增 `SyncSubscriptionsWithCapabilities`（manager.go:534 扩展，want 值改为 `map[string]map[string]Capability`）；`syncOrderBookSubscriptions`（runtime.go:1109）改调新方法，不再丢 features+depth | 单测：重订阅后各 symbol depth 正确 |

### Phase 4：服务端准入规则换新词表

| Task | 文件 | 验证 |
|---|---|---|
| 4.1 | `rules.go:24-26` `autoAdmitTiers={prime,standard,lite}` | `go test ./internal/server/whitelist/...` |
| 4.2 | `catalog.go` `applyCatalogClassification` 写新 tier；`isCoreCatalogEntry`→`isPrimeCatalogEntry` | 单测覆盖 4 档判定 |
| 4.3 | `config.go` `TierConfig` 扩展多档阈值 + env 变量（注意正确前缀 `FOUNDATIONX_BINANCE_TIERS_*`） | 单测覆盖 env 解析 |

### Phase 5：文档 + 治理同步

| Task | 文件 | 验证 |
|---|---|---|
| 5.1 | `module/binance/spec/SPEC.md` 相关 FR 更新（FR-013/033 等） | spec lint |
| 5.2 | `report/binance/README.md` 链接本计划 | — |
| 5.3 | `plans/binance/README.md` 索引表加 Plan 013 行 | 索引一致 |
| 5.4 | 版本 bump（runtime + manifest） | VersionGuard PASS |

### Phase 6：端到端验证

| Task | 验证方式 |
|---|---|
| 6.1 | `go build ./... && go vet ./... && go test -race ./...` 全绿 |
| 6.2 | 集成测试：PG 填入不同 tier 的 symbol → 客户端订阅得到对应 streams/features/depth |
| 6.3 | 回归：options 产品线仍强制人工审核，不进 tier 体系 |
| 6.4 | boundary-gates 全过 |

---

## 4. 关键 STOP 条件

1. Phase 0 未审批 → 禁止 Phase 1+
2. Phase 1 删除后编译断裂 → 必须修复，不得跳过（验证死代码判断正确性）
3. Phase 2 migration 不可回滚 → 阻断
4. Phase 3 DepthLevel 任何一环仍断链 → 不得进入 Phase 4
5. 任一 Phase `go test` 不绿 → 不得声明该 Phase DONE

---

## 5. 回归风险

`[INFERRED]`
- **数据迁移风险**：Phase 2 把生产 PG 的 `core→prime`，若迁移脚本有误会导致准入规则失效。缓解：018 脚本先在 staging 验证 + 保留回滚 SQL。
- **options 短路**：必须确保 options 产品线不误入新 tier 体系（保持 rules.go:139 强制审核）。缓解：Phase 4 单测显式覆盖。
- **env 降级语义变化**：`FOUNDATIONX_BINANCE_STREAM_SYMBOLS` 的 provider/env/allow-all 三态降级（runtime.go:353-371）在新架构下需重新定义。缓解：Phase 3 明确 fail-open 时用 `standard` tier 默认值而非 allow-all。

---

## 6. 不在本计划范围（follow-up）

- `strategy_acl.yaml`（策略→stream 权限矩阵）的真正接线——本计划直接删除，若未来需要策略层权限，另开 plan
- Market State Engine / Market Digital Twin（orderbook-deep-analysis.md 提及的远期规划）——独立轨道
- `total_stream_limit`（连接级流分片）——YAML-only 维度，本计划删除，连接分片另设计

---

## 7. 关键文件索引

**删除**：`pkg/binancecfg/{tier_map,whitelist_config,whitelist_watcher,feature_acl}*.go`、`internal/client/policy/`、`configs/{whitelist,strategy_acl,features}.yaml`

**改动**：`internal/server/whitelist/rules.go`、`internal/client/catalog.go`、`pkg/binancecfg/config.go`、`pkg/whitelistclient/client.go`、`internal/client/orderbook/manager.go`、`internal/client/runtime.go`、`internal/server/assembly/whitelist_adapter.go`

**新增**：`pkg/whitelistclient/tier_capability.go`（tierCapabilityMap SSOT）、`migrations/017_whitelist_tier_check.sql`、`migrations/018_whitelist_tier_migration.sql`

---

## 8. 验收口径

- **计划文档本 PR**：本文件落盘 + `plans/binance/README.md` 索引更新 + 决策与 PR #1742 报告一致 + 认识论标签完备
- **后续各 Phase PR**：见各 Task 列验证方式 + Section 4 STOP 条件全过

---

[RULES I BROKE]：无。代码现状声明标 `[COMPUTED]`（双重核验），tier 词表设计与架构标 `[INFERRED]`。无 FRAME→REALITY 偷换。`prime/standard/lite/blocked` 词表为设计提案，标注为推断，待 Phase 0 审批冻结。
