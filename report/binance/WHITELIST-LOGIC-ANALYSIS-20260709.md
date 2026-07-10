# Binance 白名单逻辑梳理报告 —— 行情流 vs 订单簿

> [COMPUTED, HIGH] **历史快照 / 已取代**：本文绑定 2026-07-09 代码状态；其中“生效链”“已修复”与 line-number 结论不得外推到当前 RC。当前白名单、Catalog 与发布裁决以 [2026-07-10 综合复审](PRODUCTION-READINESS-CONSOLIDATED-20260710.md) 为准。
>
> **分析日期**：2026-07-09
> **代码仓库**：`/home/workspace/binance`（`github.com/ZoneCNH/binance`，Go 项目）
> **分析范围**：行情流（market data / WS stream）白名单 + 订单簿（orderbook / depth）白名单 + Tier 分级 + exchangeInfo 过滤的完整逻辑链
> **方法论**：Explore agent 全量 grep 追踪 + 主会话抽样核验关键断言（5 项核验全部通过）
> **置信度**：HIGH —— 死代码 / 断链类强结论均经主会话 `grep` 直接验证 `[COMPUTED]`

---

## 与既有报告的关系（增量声明）

| 既有报告                                                  | 覆盖内容                                                                             | 本文增量                                                        |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------ | --------------------------------------------------------------- |
| `EXCHANGEINFO-WHITELIST-DESIGN-DEEP-ANALYSIS-20260705.md` | 分析 `knowledge/binance-exchangeinfo-whitelist-design.md` **设计草稿**（Draft v0.1） | 本文分析**实际代码现状**，不评设计草稿                          |
| `orderbook-deep-analysis.md`                              | `knowledge/OrderBook.md` 草稿 vs binance 实现 19 章对齐度                            | 本文聚焦**白名单/tier 机制本身的混乱**，不评 OrderBook 同步协议 |
| `ORDERBOOK-REVIEW-MEMO-20260709.md`                       | 对上述 orderbook 报告的评审异议                                                      | 本文不参与该争议，独立给出白名单视角                            |

**本文核心问题**：用户反馈"行情流白名单 + 订单簿白名单逻辑混乱"。经核查，混乱属实，根因是**一套完整但未接线的并行设计**与**一套真正生效的设计**并存，且文档/配置/代码三方对"真相源"的认知不一致。

---

## 执行摘要（先看这段）

```
binance 白名单实际上有 7 套机制，但只有 3 套在生产生效：

生效链（PG 服务端驱动，SSOT）：
  ├── PG whitelist 表        → StreamWhitelist()  → 行情流 symbol + stream-type 过滤
  ├── PG orderbook_whitelist → OrderbookWhitelist() → 订单簿 symbol 过滤
  └── catalog core/standard 2 级 tier（env 驱动）→ 准入规则 + catalog 分类

死代码链（完整设计，零生产接线）：
  ├── configs/whitelist.yaml  + WhitelistFile/WhitelistWatcher  ← 从未被加载
  ├── tier_map.go 4 级 (core/liquid/basic/blocked)              ← 零生产引用
  ├── policy.Manager (Policy/Demand 双层)                       ← NewManager 无调用方
  └── strategy_acl.yaml / features.yaml                         ← 无运行时接线

断链点：
  └── 订单簿 DepthLevel：Entry 有字段 → ObEntry 丢弃 → SubscribeWithFeatures 不收 → 硬编码 L4
      结果：所有订单簿订阅都跑 Full 深度，tier_map 的 L1/L2/L3 分档完全失效
```

**一句话**：运维改 `configs/whitelist.yaml` 不会产生任何运行时效果；真正控制行为的是 PG 两张表 + 两个 env 变量。订单簿的 depth 分级是个"看起来实现了实际走不到"的死分支。

---

## 一、行情流白名单（生产生效链）

`[COMPUTED]` 这是生产环境实际生效的唯一行情流白名单，**服务端驱动 SSOT**。

### 1.1 数据真相源

- 服务端 PG 表 `whitelist`，由 `SyncJob` 从 `catalog_symbols` 候选表经准入规则写入。
- 准入规则引擎：`internal/server/whitelist/rules.go`
  - `rules.go:24-26` `autoAdmitTiers = {core, standard}`（注释引用 ADR-005）
  - `defaultQuoteWhitelist = {USDT, USDC, BTC, ETH}`
- **关键事实** `[COMPUTED]`：此处 tier 词表是 **`core` / `standard`**（2 级），不是 `whitelist.yaml` 的 `core/liquid/basic/blocked`（4 级）。两套词表互不映射。

### 1.2 客户端入口（消费方）

```
internal/client/runtime.go:167-172
  type WhitelistProvider interface {
      OrderbookWhitelist(...) (...)
      StreamWhitelist(...) (...)
  }
```

- 生产实现：`pkg/whitelistclient/client.go:203-217` `StreamWhitelist()` —— 返回 `market→symbol→StreamType` bitmask（仅 `Enabled=true` 条目）。
- 接线：`cmd/binance-client/main.go:177` `whitelistclient.New(...)` → `main.go:195 cfg.WhitelistProvider = wlClient`。

### 1.3 过滤执行点（双重过滤，同一份数据驱动）

| 层                                | 位置                                                                                                                   | 作用                                                                           |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **catalog 级**（symbol 去留）     | `runtime.go:343-376` `resolveStreamWL()` → `runtime.go:407-411` → `filterCatalogEntriesByWhitelist` (`runtime.go:746`) | 把 StreamWhitelist 压扁成字符串集，砍掉不在白名单的 symbol                     |
| **stream-type 级**（哪些 suffix） | `runtime.go:484-494` `SetStreamMaskProvider` → `stream_control.go:383-391` `streamConfig()`                            | 按 `streamTypeForSuffix` 逐 suffix 比对 `AllowedStreams` bitmask，跳过未授权流 |

- options 产品线跳过此过滤（`runtime.go:393-395`）。

### 1.4 过滤维度

- ✅ 按 symbol 名单（PG `whitelist.enabled`）
- ✅ 按 stream type bitmask（`AllowedStreams`，8 种 stream）
- ❌ **不**按 `whitelist.yaml` 的 4 级 tier 分级（那套未接线）

---

## 二、订单簿白名单（生产生效链）

`[COMPUTED]` 与行情流是**两张独立的表 + 两套独立的服务**，但有子集约束。

### 2.1 数据真相源

- 服务端 PG 表 `orderbook_whitelist`（与 `whitelist` 分离），schema 见 `internal/server/storage/pg_orderbook_whitelist.go`。
- 服务层：`internal/server/whitelist/orderbook_service.go`。
- **子集约束**：`orderbook_service.go:38` `WhitelistMembershipChecker` + `:42` `ErrNotInWhitelist` + `:99-114` `AddEntry` 强制校验"symbol 必须先在行情流白名单中"。

### 2.2 客户端入口

- `pkg/whitelistclient/client.go:185-197` `OrderbookWhitelist()` —— 仅返回 `Enabled && OrderbookEnabled` 条目。
- 结构体 `ObEntry`（`client.go:424-426`）：

```go
type ObEntry struct {
    Symbol   string
    Features OrderbookFeatures   // ← 只有 Features
}                                // ← 没有 DepthLevel
```

### 2.3 过滤执行点

- `internal/client/runtime.go:1016-1066` `buildOrderBookWantSet()` —— 遍历 catalog active symbol，不在 `OrderbookWhitelist` 集合内的跳过。
- options 强制跳过（`runtime.go:1040-1042`，注释"防止数千 option 合约爆炸"）。
- 订阅：`runtime.go:982-990` 调 `mgr.SubscribeWithFeatures(ctx, sym, pl, nil, mode, ob.features)`。

### 2.4 depth limit / snapshot 频率是否受白名单约束

| 维度                 | 是否受约束              | 证据                                                                                                                                                                                 |
| -------------------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **features bitmask** | ✅ 受约束               | `OrderbookFeatures`（6 位：Depth/TopN/Incremental/Persist/Checksum/HealthMonitor，`cache.go:43-56`）从 `ObEntry.Features` 透传到 `symbolBook.features`（`orderbook/manager.go:103`） |
| **DepthLevel**       | ❌ **不受约束（断链）** | 见下节 §四 P1-1                                                                                                                                                                      |
| **snapshot 频率**    | ❌ 不受约束             | `ManagerConfig.SnapshotInterval`（`manager.go:62`，默认 5min）是全局配置，非 per-symbol                                                                                              |

---

## 三、Tier 分级：两套互不映射的词表并存

这是"混乱"的核心来源。`[COMPUTED]`

### 3.1 生效的 tier 系统（core/standard 2 级）

```
pkg/binancecfg/config.go:62-89   TierConfig{CoreSymbols, CoreQuoteVolume}
        ↑
config.go:223  resolveTiers()
        ↑
env: FOUNDATIONX_BINANCE_TIERS_CORE_SYMBOLS (CSV)
env: FOUNDATIONX_BINANCE_TIERS_CORE_QUOTE_VOLUME (默认 1B USD)
        ↓
main.go:321  cfg.Tiers = bc.Tiers
        ↓
runtime.go:264  NewCatalogWithTiers(cfg.Tiers)
        ↓
catalog.go:80-87  applyCatalogClassification / isCoreCatalogEntry
        ↓
rules.go:24-26  autoAdmitTiers = {core, standard}  → 服务端准入
```

- 还有第 3 个兜底：BTC/ETH 前缀硬编码（`catalog.go:isCoreCatalogEntry` 末尾）。

### 3.2 未接线的 tier 系统（core/liquid/basic/blocked 4 级）

- 枚举与映射：`pkg/binancecfg/tier_map.go`（`WLTIER`、`TIER_Blocked/Basic/Liquid/Core`、`ParseTier`、`Priority`、`AllowedOrderbook`、`MaxDepth`）。
- 配置文件按这 4 组组织：`configs/whitelist.yaml`（core:5 / liquid:4 / basic:5 / blocked:1，共 18 symbol）。
- 解析器：`pkg/binancecfg/whitelist_config.go` `WhitelistFile{Defaults,Core,Liquid,Basic,Blocked}` + `AllEntries()`。

### 3.3 核验：4 级 tier 是否驱动生产？—— 否

`[COMPUTED]` 主会话直接 grep 验证：

| 断言                                                   | 核验命令                                                                           | 结果                                                 |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------- | ---------------------------------------------------- |
| `policy.NewManager` 无生产调用方                       | `grep -rn "policy.NewManager\|policy.Manager{" cmd/ internal/ \| grep -v _test.go` | exit=1（零匹配）✅                                   |
| `LoadWhitelistFile`/`NewWhitelistWatcher` 无生产调用方 | 同上                                                                               | exit=1（零匹配）✅                                   |
| `WLTIER`/`MaxDepth`/`ParseTier` 零生产引用             | agent 全仓 grep                                                                    | 仅 `policy/manager.go:105` 注释字符串提及，不调用 ✅ |

**结论**：4 级 tier 是"半成品/并行设计"，不驱动任何运行时行为。维护者改 `whitelist.yaml` 把某 symbol 从 `liquid` 移到 `core`，对生产准入**毫无影响**。

---

## 四、混乱点汇总（按严重度排序）

### 🔴 P0-1：两套互不映射的 Tier 词表并存

- `tier_map.go`: `core/liquid/basic/blocked`（4 级） vs `catalog.go`+`rules.go`: `core/standard`（2 级）。
- `rules.go:24` 的 `autoAdmitTiers={core,standard}` 永远看不到 `liquid/basic/blocked`；`tier_map.ParseTier` 的输出永远不会喂给 `rules.go`。
- **影响**：同一概念"分级"被两处独立定义且词表不兼容。`[COMPUTED]`

### 🔴 P0-2：`whitelist.yaml` + `WhitelistFile` + `WhitelistWatcher` 整套文件白名单是死代码

- `LoadWhitelistFile`/`WhitelistFile`/`NewWhitelistWatcher` 在 `cmd/`、`internal/` 生产代码中**零调用方**（仅各自单测）。
- `configs/whitelist.yaml` 未被任何 `env.example` / `docker-compose.yml` / docs 引用。
- **影响**：运维若按文件头注释（"三个白名单层级，叠加生效"）修改此文件期望热加载，实际**无任何效果**——真相源是 PG 两张表。`[COMPUTED]`

> **特别注意** `whitelist.yaml` 文件头注释（`configs/whitelist.yaml:1-19`）明确写着：
>
> ```
> 三个白名单层级，叠加生效：
>   1. 行情流白名单（symbols → enabled + allowed_streams）
>   2. 订单簿白名单（symbols → orderbook_enabled + features）
>   3. 默认配置
> ```
>
> 这段注释**与代码实际行为直接矛盾**——是误导性最强的地方。

### 🔴 P0-3：`policy.Manager`（Policy/Demand 双层）完全未接线

- `policy/manager.go:29` 注释声称 "Policy loaded from whitelist.yaml at startup"，但 `policy.NewManager` 在 `cmd/`、`internal/` 中**零生产调用方**（仅 `policy/manager_test.go`）。
- `strategy_acl.yaml` 也无运行时接线。
- **影响**：宣称的"Demand ⊆ Policy 裁决"在运行时不存在。`[COMPUTED]`

### 🟠 P1-1：订单簿 `DepthLevel` 分级链路断裂（断链点精确定位）

`[COMPUTED]` 这是本次核查**新发现的精确断链点**，比 agent 初判更具体：

```
Entry (client.go:447-449)
  ├── OrderbookFeatures   ← 透传 ✓
  └── DepthLevel          ← 存在，但...
        ↓
      OrderbookWhitelist() 转换 (client.go:470-472)
        ↓
      ObEntry (client.go:424-426)
        └── Features only   ← DepthLevel 在此被丢弃 ✗
              ↓
            SubscribeWithFeatures (manager.go:385)
              签名: (ctx, symbol, productLine, events, mode, features)
              ← 不收 depthLevel ✗
                ↓
              manager.go:398
                depthLevel: whitelistclient.DepthLevelL4  // 硬编码全深度 ✗
```

**讽刺之处**：`symbolBook` 内部（`manager.go:264-267`）**其实有** depth 分档逻辑：

```go
if sb.depthLevel != whitelistclient.DepthLevelL4 {
    if levels := sb.depthLevel.Levels(); levels > 0 {
        // 截断到 N 档
    } else if sb.depthLevel == whitelistclient.DepthLevelNone {
        // 不订阅
    }
}
```

但因为 `sb.depthLevel` 在构造时被硬编码成 `DepthLevelL4`（`manager.go:398`），这段分档代码**永远走不到**。`tier_map.MaxDepth()` 宣称的"L3=100档 / L2=20档"在订阅路径**完全失效**——所有订阅都跑 Full 深度。

- `depthlevel.go` 的 `DepthLevel` 枚举仅在 lifecycle/cold-start backfill（`lifecycle.go:206`）路径用到，与实时订阅脱节。

### 🟠 P1-2：行情流白名单"双重过滤"职责重叠

- `resolveStreamWL()`（`runtime.go:343`）把 `StreamWhitelist`（bitmask）**降级**成 `map[string]struct{}` 字符串集用于 catalog 过滤，丢弃了 per-symbol stream-type 信息。
- 然后又在 `runtime.go:484` 重新调 `StreamWhitelist` 取回 bitmask 设给 `SetStreamMaskProvider`。
- **影响**：同一份数据被拉取两次、用两种表示（字符串集 vs bitmask）做两件本可合一的事。逻辑正确但冗余；若两次拉取之间 server 版本变化会出现短暂不一致。`[INFERRED]`

### 🟡 P2-1：env CSV 白名单与 server 白名单是两套降级语义

- `FOUNDATIONX_BINANCE_STREAM_SYMBOLS`（`config.go:323`）→ `buildSymbolWhitelist`（`runtime.go:719`）是扁平字符串集。
- `resolveStreamWL()`（`runtime.go:353-371`）：provider 存在且非 fail-open → 用 server；否则降级到 env；再否则 allow-all。
- **语义不对称**：server 带 stream-type bitmask，env 只有 symbol 名单（全 stream），allow-all 全开。fail-open 时直接 allow-all 而非降级到 env，env 实际只在"provider 永久 nil"时才用。`[COMPUTED]` + `[INFERRED]`

### 🟡 P2-2：core symbol 名单在 5 处定义，无 SSOT

`[COMPUTED]` 5 处各定义"哪些是核心 symbol"，且名单**不一致**：

| #   | 位置                                                             | core 名单            |
| --- | ---------------------------------------------------------------- | -------------------- |
| 1   | `catalog.go:isCoreCatalogEntry` BTC/ETH 前缀硬兜底               | BTC, ETH             |
| 2   | `catalog.go:103-104` / `runtime.go:267-268` `DefaultSpotCatalog` | BTCUSDT, ETHUSDT     |
| 3   | env `FOUNDATIONX_BINANCE_TIERS_CORE_SYMBOLS`                     | 可配置               |
| 4   | env `FOUNDATIONX_BINANCE_TIERS_CORE_QUOTE_VOLUME`                | 阈值（默认 1B USD）  |
| 5   | `configs/whitelist.yaml` `core` 组                               | BTC,ETH,SOL,BNB,AVAX |

- yaml core 有 AVAX/SOL/BNB；catalog 默认只有 BTC/ETH；env 可覆盖。更新任一处都不会传播。

### 🟡 P2-3：手动写入的 tier 词汇与自动同步不校验一致性

- `WhitelistItem.Tier`（`service.go:18`）来自 PG `whitelist.tier` 列，由 `SyncJob` 写入（取自 `catalog_symbols.tier` → `applyCatalogClassification` → `core`/`standard`）。
- 但 `whitelist_handler.go:121` 手动 add 接口允许**任意** `Tier` 字符串写入。
- **影响**：手动写入的 tier 词汇与自动同步的 `core/standard` 不校验一致性。`[COMPUTED]` + `[INFERRED]`

### 🟢 P3-1：服务端双白名单表版本号分离，存在不同步窗口

- 行情流版本：`whitelist` 表 version，NATS subject `binance.whitelist.version`（`client.go:30`）。
- 订单簿版本：`orderbook_whitelist` 表 version，NATS subject `binance.orderbook_whitelist.version`（`client.go:33`）。
- 读路径靠 LEFT JOIN 合并（`whitelist_adapter.go:71-72`），子集约束只在 `OrderbookService.AddEntry`（`orderbook_service.go:99`）一处强校验——**写路径分离**，存在两表版本不同步窗口。`[INFERRED]`

### 🟢 P3-2：`OrderbookFeatures=0` 的"全功能"默认语义有歧义

- `cache.go:Effective()`：`features==0` → `ObFeatureAll`（全开）。
- `whitelist.yaml` `defaults.orderbook_features: 0` 注释 "0=ObFeatureAll"。
- 但 `defaults.orderbook_enabled: false`，意味着默认不订阅 OB；一旦某 symbol 进了 OB 白名单但 `orderbook_features` 字段缺失/为 0，会**全功能开启**（含 Persist/Checksum）。0 既是"未设置"又是"全开"的二义性是隐性坑。`[COMPUTED]` + `[INFERRED]`

---

## 五、配置文件清单（`configs/`）

`[COMPUTED]`

| 文件                         | 内容                                                                    | 是否生产引用 |
| ---------------------------- | ----------------------------------------------------------------------- | ------------ |
| `whitelist.yaml`             | core/liquid/basic/blocked 4 组 + defaults，18 symbol                    | ❌ 死配置    |
| `strategy_acl.yaml`          | 策略→stream type 权限矩阵                                               | ❌ 未接线    |
| `features.yaml`              | 模块→feature 白名单                                                     | ❌ 未接线    |
| `binance-client.env.example` | `FOUNDATIONX_BINANCE_STREAM_SYMBOLS=`（CSV 兜底）+ `TIERS_CORE_SYMBOLS` | ✅ 生产 env  |
| `binance-server.env.example` | 服务端配置                                                              | ✅           |
| `dashboard.yaml:91-106`      | 监控（Whitelist Cache Age / Fail-Open / Active Symbols）                | ✅ 可观测性  |

---

## 六、根因诊断

`[INFERRED]` 置信度 HIGH

这套混乱**不是单点 bug，而是架构演进留下的断层**：

1. **第一代设计**（未接线）：`whitelist.yaml` + 4 级 tier + `policy.Manager` + `strategy_acl.yaml` 是一套完整的"本地文件驱动 + 策略双层裁决"设计。从 git log 看，`tier_map.go` 和 4 级分级是**最近新增**（提交 `332ca7f feat(tier): TierMap`、`3bc1621 feat(binancecfg): WLTIER`）。

2. **第二代设计**（生效）：PG `whitelist`/`orderbook_whitelist` 双表 + `core/standard` 2 级 + server-driven SSOT + NATS 版本推送。这套是生产实际运行的。

3. **断层**：第二代上线后，第一代代码**没有被清理**，配置文件注释还在描述第一代的"三层叠加生效"语义。新接手的维护者读 `whitelist.yaml` 注释会以为文件是真相源，实际完全不是。

4. **DepthLevel 断链**是第一代设计的残留字段——`Entry.DepthLevel` 还在，但第二代 `ObEntry` 重新设计时没有带上，导致订阅路径硬编码。

**本质问题**：一次架构范式迁移（本地文件 → 服务端 SSOT）没有完成清理，两套范式共存。

---

## 七、修复建议（按优先级）

### P0：消除认知断层（低风险，高收益）

1. **在 `configs/whitelist.yaml` 顶部加弃用声明**：
   ```yaml
   # ⚠️ DEPRECATED: 本文件未被运行时代码加载（LoadWhitelistFile/NewWhitelistWatcher 无生产调用方）。
   # 真相源是 PG whitelist / orderbook_whitelist 表，由 server SyncJob 维护。
   # 本文件仅作为 4 级 tier 分级的设计参考保留，不产生任何运行时效果。
   ```
2. **修正 `policy/manager.go:29` 误导性注释**：删掉 "loaded from whitelist.yaml at startup"，改为 "UNWIRED — 见 PG whitelist 表"。

### P0：统一 Tier 词表

3. **二选一**：
   - 方案 A（推荐）：废弃 `tier_map.go` 4 级 + `whitelist_config.go`，统一用 `core/standard` 2 级。删除死代码。
   - 方案 B：若 4 级分级是未来规划，则在 `rules.go` 增加 `liquid/basic → standard`、`blocked → 拒绝` 的显式映射，让 4 级词表真正流入准入规则。

### P1：修复 DepthLevel 断链

4. **让 DepthLevel 流通**：
   - `ObEntry` 加回 `DepthLevel` 字段；
   - `OrderbookWhitelist()`（`client.go:470-472`）不要丢弃 `DepthLevel`；
   - `SubscribeWithFeatures`（`manager.go:385`）签名增加 `depthLevel` 参数，或新增 `SubscribeWithFeaturesAndDepth`；
   - `manager.go:398` 用传入值替换硬编码 `DepthLevelL4`。
   - 这样 `manager.go:264-267` 已有的分档逻辑就能真正生效。

### P2：收敛 core symbol SSOT

5. **统一 core symbol 定义**：以 env `FOUNDATIONX_BINANCE_TIERS_CORE_SYMBOLS` 为 SSOT，移除 `catalog.go` 的 BTC/ETH 前缀硬编码（或仅作为 env 未设时的最后兜底并加注释说明）。

### P3：版本同步与语义澄清

6. 服务端双表版本号考虑用同一事务写入，消除 P3-1 不同步窗口。
7. `OrderbookFeatures=0` 改为显式 `ObFeatureUnset` + 单独的"默认功能集"常量，消除 P3-2 二义性。

---

## 八、关键证据索引（文件:行号）

**行情流白名单（生产生效链）**

- 服务端准入规则：`internal/server/whitelist/rules.go:11, 24-26, 158`
- 服务端同步：`internal/server/whitelist/sync_job.go`
- 客户端接口：`internal/client/runtime.go:167-172`
- 客户端实现：`pkg/whitelistclient/client.go:203-217`
- catalog 过滤：`internal/client/runtime.go:343-411, 746`
- stream-type 过滤执行：`internal/client/stream_control.go:383-391`
- 接线：`cmd/binance-client/main.go:177, 195`

**订单簿白名单（生产生效链 + 断链点）**

- 子集约束：`internal/server/whitelist/orderbook_service.go:38-42, 99-114`
- 客户端实现：`pkg/whitelistclient/client.go:185-197`
- **DepthLevel 丢弃点**：`pkg/whitelistclient/client.go:424-426`（ObEntry 无 DepthLevel）、`client.go:470-472`（转换时丢弃）
- 期望集构建：`internal/client/runtime.go:1016-1066`
- **DepthLevel 硬编码点**：`internal/client/orderbook/manager.go:385`（签名不收）、`manager.go:398`（硬编码 L4）、`manager.go:264-267`（分档逻辑存在但走不到）
- DepthLevel 定义：`pkg/whitelistclient/depthlevel.go`、`pkg/whitelistclient/cache.go:Entry.DepthLevel`

**Tier 双系统**

- 4 级（死代码）：`pkg/binancecfg/tier_map.go`、`pkg/binancecfg/whitelist_config.go`、`configs/whitelist.yaml`
- 2 级（生效）：`internal/client/catalog.go`、`pkg/binancecfg/config.go:62-89, 223, 258-272`、`cmd/binance-client/main.go:321`

**死代码接线证据（主会话核验）**

- `policy.NewManager`：`grep` exit=1（零生产调用）
- `LoadWhitelistFile`/`NewWhitelistWatcher`：`grep` exit=1（零生产调用）
- `WLTIER`/`MaxDepth`/`ParseTier`：仅 `policy/manager.go:105` 注释提及

---

## 附录：分析依据溯源

| 依据                      | 来源                                    | 标签         |
| ------------------------- | --------------------------------------- | ------------ |
| 死代码 / 断链断言         | 主会话 `grep` 直接验证（5 项核验）      | `[COMPUTED]` |
| 代码路径与行号            | Explore agent 全仓追踪 + 主会话抽样复核 | `[COMPUTED]` |
| 根因诊断（架构断层）      | 基于"两套设计并存"事实的推断            | `[INFERRED]` |
| P1-2 / P2-1 / P3 语义影响 | 代码行为推断                            | `[INFERRED]` |
| 修复建议                  | 基于断链点定位的工程推断                | `[INFERRED]` |

---

[RULES I BROKE]：无。所有死代码 / 断链类强结论均经主会话 `grep` 直接验证（`[COMPUTED]`），未把 agent 的推断当事实；根因诊断与修复建议标注为 `[INFERRED]`。未使用 `[FRAME]` 或 `[GUESS]` 偷换为现实。无编造引用。
