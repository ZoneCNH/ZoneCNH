# SPEC 增补：ExchangeInfo DB 持久化与分级白名单同步

- Spec-ID: binance-exchangeinfo-sync
- Status: Draft（待 pipeline-arbiter 翻转 Approved）
- Created: 2026-06-25
- Parent: [`SPEC.md`](SPEC.md) v3.7.1（§8 Control Plane、§11.1 Config、§4.1 Boundaries）
- Supersedes: 无（增补，非替代）
- Scope: 在 SPEC v3.7.1 的 FR-030 之后新增 FR-031~036 / BR-010~012 / AC-131~154 / TC-066~083（v3 结构性审查修正：拆分 FR-033→FR-033+FR-036、StreamsForProductLineTier 按 productLine 分化、control stream LimitsPolicy、diff Updated/SpecUpdated 分离、options 到期峰值 BR-012；编号已协调：AC-105~130 / TC-050~065 保留给 Current FR-037~044）
- Runtime-Anchor: `/home/binance@756fbc5`
- Runtime-Note: 本文档为 Draft，代码引用基于 `/home/binance@f18a329` 实读；提升为 Active 前须以当前 HEAD 复核所有 file:line 引用。

> [COMPUTED, HIGH] 本文档是 `SPEC.md` 的**增补章节**，编号在 v3.7.1（FR-044 / AC-130 / TC-065）之后顺延。所有引用的 file:line 基于 runtime `/home/binance@f18a329` 实读（Draft 阶段），提升为 Active 前须以当前 HEAD `/home/binance@756fbc5` 复核。本文档通过 pipeline 98 分门禁后由 arbiter 翻转 `Status: Approved`，再合入 `SPEC.md` 主文。

---

## 0. 动机与问题陈述

`[COMPUTED, HIGH]` 当前 runtime 在 symbol/exchangeInfo 同步上存在三层断层（详见 [`report/binance/symbol-sync-deep-analysis-20260625.md`](../../report/binance/symbol-sync-deep-analysis-20260625.md)）：

1. **catalog 硬编码 5 symbol**：`catalog.go:45-67` `DefaultSpotCatalog()` + `DefaultMarketCatalog()`，runtime `runtime.go:92` 无条件调用。`exchangeinfo.go` 仅 spot，且仅在 `cfg.ExchangeInfoURL != ""` 时触发。
2. **exchangeInfo 不落库、不定时刷新**：`exchangeinfo.go` 拉取后返回 `[]CatalogEntry`（内存），无 postgresx 持久化、无 6h 定时刷新、无 diff 检测。SPEC §8 规划的 `binance.control.instruments.changed` subject **零实现**。
3. **无分级白名单**：SPEC §11.1 规划的 `binance.product_lines` / `symbols.allow` / `symbols.deny` 配置字段**零实现**；runtime 无法选择性同步，只能全量或硬编码。

`[COMPUTED, HIGH]` Binance 四产品线实测 symbol 规模 **3,616 个**（spot 1,360 + um 680 + cm 30 + options 1,546，2026-06-25 实查 API）。全量实时采集需 ~260 Mbps 带宽、15 个 WS 连接、~2.81 TB/日，远超单节点能力。必须引入分级同步与白名单过滤。

本增补定义 4 个 FR 闭合上述断层，并实现「选择性同步」能力。

---

## 1. 范围与边界

### 1.1 In Scope

- 四产品线 exchangeInfo 发现（client 侧 REST 拉取 + JSON 解析）
- exchangeInfo 持久化与定时刷新（6h，diff-only 发布）
- sync_tier 分级分类（L1_core / L2_extended / L3_full / disabled）
- 白名单选择性同步（product_lines / symbols.allow / symbols.deny，运行时热更新）
- DB schema 扩展（migration 005）

### 1.2 Out of Scope

- ❌ venue_rank（成交量排名）的实时计算 —— 本增补仅定义字段与 manual/API 注入路径，实时排名算法属后续 FR
- ❌ Options 动态 strike/expiry 发现的完整状态机 —— 本增补保证 options exchangeInfo 可拉取落库，但「近月活跃 strike 自动筛选」属 FR-030/后续
- ❌ 多 IP 权重分散 —— 明确禁止（Binance 反模式，可能封禁）
- ❌ 跨交易所通用化 —— 仍为 Binance 专属

### 1.3 边界约束（继承 SPEC §4.1 C1-C6）

`[KNOWN, HIGH]` 本增补严格遵守现有 C/S 边界：

- **client 进程**负责 exchangeInfo 发现（REST 拉取），**不直连 postgresx**
- **server 进程**负责落库（消费 natsx `instruments.changed`），**不直访 Binance REST**
- 两进程仅通过 natsx JetStream 通信（C1-C3）
- client 发现的 diff 通过 `binance.control.instruments.changed` subject 发布（SPEC §8 已规划）

---

## 2. 功能需求（FR-031 ~ FR-034）

### FR-031 ExchangeInfo Discovery (4 Product Lines)

**WHEN** client 进程启动且 `FOUNDATIONX_BINANCE_EXCHANGE_INFO_URL` 非空（或使用 mainnet 默认值），
**THEN** client 应分别拉取四产品线的 exchangeInfo endpoint，解析为 `CatalogEntry` 列表，并通过 `binance.control.instruments.changed` 发布给 server。

**产品线 → endpoint 映射**（实测确认，2026-06-25）：

| ProductLine | REST Endpoint | Status 字段 | Symbol 数组字段 | 备注 |
|-------------|--------------|------------|----------------|------|
| `spot` | `api.binance.com/api/v3/exchangeInfo` | `status`（`TRADING`） | `symbols` | 现有 `FetchSpotExchangeInfo` 已实现 |
| `um_perp` | `fapi.binance.com/fapi/v1/exchangeInfo` | `status`（`TRADING`） | `symbols` | **新增** |
| `cm_perp` | `dapi.binance.com/dapi/v1/exchangeInfo` | **`contractStatus`**（`TRADING`） | `symbols` | **API 陷阱**：字段名非 `status` |
| `options` | **`eapi.binance.com/eapi/v1/exchangeInfo`** | `status`（`TRADING`） | **`optionSymbols`** | **API 陷阱**：endpoint 非 `vapi`，数组非 `symbols` |

`[KNOWN, HIGH]` **API 陷阱文档化**（从 `symbol-sync-deep-analysis-20260625.md` §7.2 实测得出）：
- COIN-M 用 `contractStatus` 字段（非 `status`），误用会返回 0 symbol
- Options 用 `eapi.binance.com`（非文档常误写的 `vapi`），数据在 `optionSymbols` 数组（非 `symbols`）
- options 每个 symbol 含 `underlying`、`strikePrice`、`expiryDate`、`optionsType`(CALL/PUT) 等期权特有字段

**每个 CatalogEntry 应提取的字段**（扩展现有 8 字段）：

```
现有：ProductLine, InstrumentType, InstrumentSubtype, Symbol, InstrumentKey, BaseAsset, QuoteAsset, Status
新增：ContractType, ExpiryDate, StrikePrice, OptionType,
      PricePrecision, QtyPrecision, MinQty, MaxQty, TickSize, Filters(raw JSONB)
```

**AC-131**：client 提供 `FetchUMExchangeInfo` / `FetchCMExchangeInfo` / `FetchOptionsExchangeInfo`，签名与 `FetchSpotExchangeInfo` 一致（`func(ctx, *http.Client, url) ([]CatalogEntry, error)`）。
**AC-132**：CM 解析器正确读取 `contractStatus` 字段（非 `status`），覆盖测试用例含 `contractStatus=TRADING` 与 `status` 字段同时存在的场景。
**AC-133**：Options 解析器正确读取 `optionSymbols` 数组（非 `symbols`），endpoint 为 `eapi.binance.com`，覆盖测试含 `underlying/strikePrice/expiryDate/optionsType` 字段提取。
**AC-134**：四产品线发现结果通过 `binance.control.instruments.changed` 发布，payload 为 `InstrumentsChangedPayload{ ProductLine, SnapshotID, Added[], Removed[], Updated[] }`，client 等待 natsx PubAck。

### FR-032 ExchangeInfo Persistence & Scheduled Refresh

**WHEN** server 消费 `binance.control.instruments.changed`，
**THEN** server 应将 diff 中的 Added/Updated 条目 upsert 进 postgresx `catalog_symbols`（扩展后 schema），Removed 条目标记 `status='delisted'`（不物理删除，保留历史）。

**WHEN** client 进程运行中，
**THEN** client 每 `FOUNDATIONX_BINANCE_EXCHANGE_INFO_REFRESH_INTERVAL`（默认 `6h`）重新拉取四产品线 exchangeInfo，与本地 catalog 做 diff，**仅在发现变更时**发布 `instruments.changed`（diff-only，避免无效 PubAck 风暴）。

**AC-135**：server 的 `PgCatalog` 扩展 `UpsertInstruments(ctx, payload InstrumentsChangedPayload)` 方法，幂等 upsert（ON CONFLICT），Removed 行设 `status='delisted'`。
**AC-136**：client 定时器在 diff 为空时**不发布** natsx 消息（`added==0 && removed==0 && updated==0` → skip publish），覆盖测试验证零 Publish 调用。
**AC-137**：`catalog_symbols` 表 schema 扩展后，现有 `UpsertSymbol`（FR-006b）行为不变（向后兼容），新字段在旧路径写入时取默认值/NULL。
**AC-138**：`catalog_exchange_info_snapshots` 表记录每次刷新的 `snapshot_id`（ULID）、`product_line`、`symbol_count`、`diff_summary(JSONB)`、`refreshed_at`，支持审计查询与回滚。

> [COMPUTED, HIGH] **natsx stream 声明（runtime 实证补强）**：当前 `consumer.go:18` 的 JetStream stream 仅声明 subject `binance.market.*.*`，`binance.control.*` **无对应 stream**。FR-031 的 `Publish("binance.control.instruments.changed", ...)` 会因 No Stream 返回 PubAck 失败。以下 AC 闭合此缺口。

**AC-112a**：server 启动时（`storage_env.go` 或 `consumer.NewNATSXConsumer`）通过 `AddStream` 声明 control stream，subject 涵盖 `binance.control.>`（含 `instruments.changed` 与 `symbols.changed`），storage=File，**retention=LimitsPolicy**（非 WorkQueue）。

> [COMPUTED, HIGH] **retention 选型修正（第三轮审查）**：原设计选 WorkQueue（消费后丢弃），但 WorkQueue 模式下一条消息**仅被一个 consumer 消费**（`[KNOWN]` NATS 语义）。multi-server 部署时，多个 server 实例竞争消费 `instruments.changed`，只有第一个 ack 的实例落库，其余实例 catalog 漂移。control 消息是「所有 server 实例都应知道」的广播语义，须用 LimitsPolicy（每 consumer 独立 ack，与现有 market stream `consumer.go:67` 一致）。
>
> 若需控制面消息不长期堆积，配合 `MaxAge`（如 1h）TTL 过期即可，而非用 WorkQueue 牺牲广播语义。

**AC-112b**：diff 引擎 `DiffCatalog(prev, next []CatalogEntry) InstrumentsDiff` 基于复合键 `product_line:symbol`（大写 symbol、canonical product_line）计算三类变更。**`Updated` 判定收窄到采集决策字段**：仅当 `status`/`sync_tier`/`base_asset`/`quote_asset`/`expiry_date` 变化时计为 Updated；`filters`(JSONB)/`min_qty`/`tick_size` 等合约规格字段变化计为 `SpecUpdated`（单独标记，不触发 catalog reload，仅更新 DB 字段），避免风控微调产生 diff 噪音。覆盖测试验证三类边界 + Updated 与 SpecUpdated 分离。
**AC-112c**：client 收到 `instruments.changed` 后，**优先调用 `Catalog.Reload(fullNext)`** 原子替换（非逐条 Add），确保 stream manager 看到一致快照；`life.SyncCatalog` 在 Reload 之后调用以刷新 lifecycle 投影。明确 `Reload`（全量替换）与 `SyncCatalog`（增量投影刷新）的调用顺序：先 Reload 再 SyncCatalog。

### FR-033 Sync Tier Classification（分类与字段，不含连接拓扑）

**WHEN** 一个 symbol 被写入 `catalog_symbols`，
**THEN** 它应被赋予 `sync_tier ∈ {L1_core, L2_extended, L3_full, disabled}`，默认 `disabled`（安全默认：未显式分级不同步）。

> [COMPUTED, HIGH] **范围收窄说明（第三轮审查修正）**：原 FR-033 把「tier 分类」与「tier→连接拓扑」混在一个 FR。实证 `stream_control.go:269` 发现 connector 是「1 productLine → 1 连接 → 该线全部 active symbol 统一流」模型，tier 差异化流需要**按 tier 拆分 WS 连接**（L1 一组、L3 另一组），这是 connector 架构变更，已拆出为独立 **FR-036**。本 FR-033 仅定义 tier 字段与分类逻辑，不涉及连接拓扑。

sync_tier 的**语义意图**（实际流组合由 FR-036 的 productLine 分化映射实现）：

| sync_tier | 意图流类型（spot/um/cm） | 意图流类型（options） | backfill 优先级 | 适用场景 |
|-----------|------------------------|---------------------|----------------|---------|
| `L1_core` | trade + bookTicker + kline_1m + depth20@100ms | optionTicker（全量 Greeks） | P0 cold_start | 主流高流动性（BTC/ETH/...） |
| `L2_extended` | trade + kline_1m + bookTicker | optionTicker | P1 cold_start | 中等流动性 top-N |
| `L3_full` | trade + kline_1m | optionTicker | P2 cold_start | 长尾低流动性 |
| `disabled` | 无 | 无 | 不 backfill | 未分级 / 已 deny |

> [COMPUTED, HIGH] **options 流特殊性（runtime 实证）**：options 仅有 `@optionTicker` 流（`normalize.go:500`，含 Greeks delta/gamma/theta/vega），**没有** depth/bookTicker/kline 流。因此 options 的 tier 差异化**不体现在流类型**（只有一种流），而体现在「该 options symbol 是否采集」+ backfill 优先级。tier→流映射必须按 productLine 分化（见 FR-036）。

**AC-139**：`CatalogEntry` 结构体新增 `SyncTier string` 字段；`Catalog` 新增 `SymbolsByTier(productLine, tier string) []CatalogEntry` 方法，返回匹配 tier 的 active entry（含完整字段）。**保留**现有 `ActiveSymbols(productLine)` 不变（向后兼容，connector 当前调用路径不受影响）。
**AC-140**（原 AC-140 移至 FR-036）：~~stream manager 按 tier 选择流组合~~ → 见 FR-036 AC-151~127。
**AC-141**：`sync_tier` 可通过 admin API `PATCH /api/v1/admin/symbols/{product_line}/{symbol}` 热更新，触发 stream drain/rebuild（复用 FR-024 hot reload + FR-036 连接拓扑）。
**AC-142**：新增 symbol 默认 `sync_tier='disabled'`，必须显式分级（手动或 API）才进入采集，覆盖测试验证默认值。

### FR-036 Tier-Aware Connection Topology（连接拓扑架构）

> [COMPUTED, HIGH] **新增（第三轮审查）**：FR-033 的 tier 差异化流要求 connector 从「1 productLine → 1 连接 → 全部 symbol 统一流」演进为「1 productLine × N tier → N 连接组 → 各组不同流」。这是架构级变更，需独立 FR + ADR 支撑。

**WHEN** client 的 stream manager 为某 productLine 构建 WS 连接，
**THEN** 应按 sync_tier 分组，每组使用该 tier 对应的流组合建立独立 WS 连接（或连接池），不同 tier 的 symbol 不混入同一连接。

**tier × productLine → 流组合映射**（`StreamsForProductLineTier`）：

| productLine | tier | 流组合 | 连接分组 |
|-------------|------|--------|---------|
| spot/um_perp/cm_perp | L1_core | trade + bookTicker + kline_1m + depth20@100ms | conn_group_L1 |
| spot/um_perp/cm_perp | L2_extended | trade + kline_1m + bookTicker | conn_group_L2 |
| spot/um_perp/cm_perp | L3_full | trade + kline_1m | conn_group_L3 |
| options | L1_core / L2_extended / L3_full | optionTicker（统一流，无差异化） | conn_group_opt（按 symbol 数分批） |
| 任意 | disabled | 无 | 不连接 |

> [COMPUTED, HIGH] **options 特殊处理**：options 仅有 `@optionTicker` 单一流类型（`normalize.go:500`），tier 差异化不体现在流类型。options 的 tier 仅控制「是否采集」+ backfill 优先级。因此 options 的连接拓扑是「按 symbol 数分批」（单连接 1024 stream 上限），而非「按 tier 分组流」。

**AC-151**：新增 `StreamsForProductLineTier(productLine string, tier SyncTier) []string` 函数，按 productLine 分化返回流组合；options 统一返回 `["optionTicker"]`，spot/um/cm 按 tier 返回差异化组合。覆盖测试验证 productLine × tier 矩阵。
**AC-152**：stream manager 按 `(productLine, tier)` 二元组分组 symbol，每组独立调 `buildStreamURL` 建立 WS 连接；覆盖测试验证 L1 与 L3 symbol 不混入同一 stream URL。
**AC-153**：tier 降级（L1→L3）时，旧连接先 drain（FR-004 NakWithDelay + DLQ）再 unsubscribe；tier 升级时新连接异步建立不阻塞现有采集（BR-011）；覆盖测试验证升降级顺序。

> [COMPUTED, HIGH] **FR-024 依赖风险（第四轮发现）**：AC-153 的增量 drain 语义依赖 FR-024 hot reload 提供增量 stream diff。但 FR-024 当前是 **Partial**（TRACEABILITY：「全量重连非增量 diff」，runtime `runtime.go` reload 路径是全量重建）。实施 AC-153 有两条路径：(a) 先升级 FR-024 为增量 diff（修 issue #1116），再在 FR-036 复用；(b) FR-036 自建 per-tier 连接的增量 diff 逻辑，不依赖 FR-024。路径 (b) 更安全（解耦），但增加 FR-036 实现复杂度。task-split 阶段须明确选择。
**AC-154**：连接分批（绕过单连接 1024 stream 上限）：当某 `(productLine, tier)` 组的 symbol 数超过 `floor(1024 / len(streams))` 时，拆分为多个 WS 连接；覆盖测试验证分批边界（spot L1=256 sym/conn，L3=512 sym/conn，options=1024 sym/conn）。

### FR-034 Selective Sync Whitelist

**WHEN** client 启动或 admin reload 触发 catalog 刷新，
**THEN** 最终采集决策应按以下优先级裁决（deny 永远赢）：

```
finalDecision(product_line, symbol) =
  if (symbol ∈ config.symbols.deny)                       → disabled   # deny 永远赢
  elif (config.symbols.allow != [] && symbol ∉ allow)     → disabled   # allow 非空时是白名单
  elif (symbol.status != 'TRADING' && status != 'active') → disabled   # 非 TRADING 不采
  elif (product_line ∉ config.product_lines)              → disabled   # 产品线未启用
  else                                                    → DB.sync_tier
```

**配置字段**（落地 SPEC §11.1，实现于 `binancecfg.Config`）：

| Env Var | Config 字段 | 默认 | 语义 |
|---------|------------|------|------|
| `FOUNDATIONX_BINANCE_PRODUCT_LINES` | `ProductLines []string` | `[]`（=全部四线） | 启用的产品线，空=全部 |
| `FOUNDATIONX_BINANCE_SYMBOLS_ALLOW` | `SymbolsAllow []string` | `[]` | 白名单 symbol，空=tier 内全部 |
| `FOUNDATIONX_BINANCE_SYMBOLS_DENY` | `SymbolsDeny []string` | `[]` | 黑名单 symbol（deny 永远赢） |

**AC-143**：`binancecfg.Config` 新增 `ProductLines`/`SymbolsAllow`/`SymbolsDeny` 字段，从逗号分隔 env var 解析，覆盖测试验证空值=全部、非空=白名单语义。
**AC-144**：catalog 过滤层 `FilterByWhitelist(entries []CatalogEntry, cfg WhitelistConfig) []CatalogEntry` 实现优先级裁决，覆盖测试验证：deny 覆盖 allow、allow 空时放行、deny 非空时排除。
**AC-145**：`POST /api/v1/admin/symbols/reload` 接受新字段 `sync_tier`，reload 后立即应用白名单过滤（deny 命中的 symbol 即使 tier=L1_core 也不采集）。
**AC-146**：产品线级别开关 `product_lines` 与 symbol 级别 `allow/deny` 组合时，product_lines 先过滤（整线禁用），再 allow/deny 过滤，覆盖测试验证组合顺序。

### FR-035 Admin Surface Auth Hardening

> [COMPUTED, HIGH] **runtime 实证缺口**：client 的 `AdminServer`（`admin.go:58`）用裸 `http.ServeMux`，**无任何鉴权 middleware**。现有端点（reload/drain/pause）已是写操作，FR-033/034 新增的 `PATCH sync_tier`、`POST batch-tier` 同为写操作。暴露在无鉴权的 `:8081` 端口意味着任何网络可达者可远程改 tier / 注入白名单，导致误采或停采。本 FR 闭合此安全缺口，是 FR-033/034 写操作的前置条件。

**WHEN** client `AdminServer` 收到 `/api/v1/admin/*` 写请求（POST/PATCH/DELETE），
**THEN** 应校验 `Authorization: Bearer <token>`，token 从 `FOUNDATIONX_BINANCE_ADMIN_TOKEN` 读取（复用 server 侧 `query.go:343-348` 的 `getenv` 模式）；空 token 时**仅允许 localhost**（`127.0.0.1`/`::1`），拒绝远程写请求。

**AC-147**：`AdminServer` 新增 `authMiddleware`，从 `FOUNDATIONX_BINANCE_ADMIN_TOKEN` 读取 Bearer token；非空时校验所有 `/api/v1/admin/*` 写方法的 Authorization header；覆盖测试验证正确 token 放行、错误 token 返回 401、缺失 token 返回 401。
**AC-148**：token 为空时，`/api/v1/admin/*` 写请求仅允许 `RemoteAddr` 为 loopback（`127.0.0.1`/`::1`/`[::1]`）的连接；非 loopback 返回 403 Forbidden 并记录审计日志；覆盖测试验证 localhost 放行、远程拒绝。
**AC-149**：`GET /healthz`、`GET /readyz`、`GET /api/v1/admin/streams`（只读）不受鉴权影响，保持公开（健康检查与可观测性需要）。
**AC-150**：所有鉴权失败（401/403）写入 `audit_log`（表 `003_audit.sql`），`action='admin_auth_denied'`、`outcome='failure'`、`detail` 含 remote_addr 与 path。

---

## 3. 业务规则（BR-010 ~ BR-011）

### BR-010 ExchangeInfo Diff-Only Publication

client 定时刷新 exchangeInfo 时，**必须**先与本地 catalog 做集合 diff（基于 `product_line:symbol` 复合键），仅在 `added ∪ removed ∪ updated` 非空时发布 `instruments.changed`。全量快照每 24h 强制发布一次（作为对账基准，即使 diff 为空）。

**验证方式**：CI gate `no-full-snapshot-spam`（检测日志中连续 N 次「diff empty, skip publish」后必须出现一次 full snapshot）+ 单元测试。

### BR-011 Tier Reassignment Safety

`sync_tier` 从高（L1_core）降到低（L3_full/disabled）时，对应 stream 的活跃连接应先 drain 再 unsubscribe（复用 FR-004 NakWithDelay + DLQ 语义，确保 in-flight 事件不丢）。从低升到高时，新 stream 异步建立，不阻塞现有采集。

**验证方式**：集成测试（tier 降级触发 drain → DLQ 检查 → unsubscribe 顺序断言）。

### BR-012 Options Expiry Batch Drain Smoothing

> [COMPUTED, HIGH] **新增（第三轮审查）**：options 每周五（weekly 合约）会有批量到期（数百个合约同时 `Removed`），触发批量 stream drain。若不节流，峰值时段数百个并发 drain 会压垮 WS 连接管理器。

options 合约批量到期时，`Removed` 列表的 stream drain 必须**分批错峰**执行（如每批 20 个，间隔 2s），而非一次性全部 unsubscribe。drain 队列按 `expiry_date` 排序，最早到期的优先 drain。

**验证方式**：集成测试（模拟 200 个 options 同时到期 → 验证 drain 分批 ≤20/批 → 间隔 ≥2s → 无连接管理器过载告警）。

---

## 4. DB Schema 扩展（migration 005）

`[COMPUTED, HIGH]` 现有 `migrations/001_catalog.sql` 的 `catalog_symbols` 表 7 列。本增补扩展为 ~18 列 + 新增 snapshots 表。

### 4.1 catalog_symbols 扩展（ALTER TABLE）

```sql
-- migration 005: exchangeInfo 完整字段 + sync_tier 分级
ALTER TABLE catalog_symbols
    -- exchangeInfo 合约规格字段
    ADD COLUMN IF NOT EXISTS contract_type    TEXT,                -- perpetual | future | option | spot
    ADD COLUMN IF NOT EXISTS expiry_date      DATE,                -- 期货/期权到期日（spot/perp 为 NULL）
    ADD COLUMN IF NOT EXISTS strike_price     NUMERIC(20,8),       -- 期权行权价（非期权为 NULL）
    ADD COLUMN IF NOT EXISTS option_type      TEXT,                -- CALL | PUT（非期权为 NULL）
    ADD COLUMN IF NOT EXISTS price_precision  INT,                 -- 价格精度（小数位）
    ADD COLUMN IF NOT EXISTS qty_precision    INT,                 -- 数量精度
    ADD COLUMN IF NOT EXISTS min_qty          NUMERIC(20,8),       -- 最小下单量
    ADD COLUMN IF NOT EXISTS max_qty          NUMERIC(20,8),       -- 最大下单量
    ADD COLUMN IF NOT EXISTS tick_size        NUMERIC(20,8),       -- 价格最小变动单位
    ADD COLUMN IF NOT EXISTS filters          JSONB,               -- 原始 filters 数组（LOT_SIZE/PRICE_FILTER 等）
    -- 分级字段
    ADD COLUMN IF NOT EXISTS sync_tier        TEXT NOT NULL DEFAULT 'disabled',  -- L1_core|L2_extended|L3_full|disabled
    ADD COLUMN IF NOT EXISTS venue_rank       INT,                 -- 按成交量的交易所内排名（1=最高，NULL=未排名）
    -- 发现元数据
    ADD COLUMN IF NOT EXISTS exchange_info_snapshot_id TEXT,       -- 关联 catalog_exchange_info_snapshots.id
    ADD COLUMN IF NOT EXISTS last_refreshed_at TIMESTAMPTZ;        -- 最后一次 exchangeInfo 刷新时间

-- sync_tier 取值约束（CHECK 防止非法值）
ALTER TABLE catalog_symbols
    ADD CONSTRAINT chk_sync_tier
    CHECK (sync_tier IN ('L1_core', 'L2_extended', 'L3_full', 'disabled'));

-- 按 tier 查询的索引（stream manager 高频读）
CREATE INDEX IF NOT EXISTS idx_catalog_symbols_tier
    ON catalog_symbols (product_line, sync_tier, status)
    WHERE status = 'active';

-- venue_rank 查询索引（后续 ranking 逻辑用）
CREATE INDEX IF NOT EXISTS idx_catalog_symbols_rank
    ON catalog_symbols (product_line, venue_rank NULLS LAST);
```

### 4.2 新增 catalog_exchange_info_snapshots 表

```sql
CREATE TABLE IF NOT EXISTS catalog_exchange_info_snapshots (
    id              TEXT PRIMARY KEY,           -- ULID，快照唯一标识
    product_line    TEXT NOT NULL,              -- spot | um_perp | cm_perp | options
    symbol_count    INT NOT NULL,               -- 本次快照的 symbol 总数
    diff_summary    JSONB NOT NULL,             -- {"added": N, "removed": N, "updated": N, "spec_updated": N, "unchanged": N}
    refresh_type    TEXT NOT NULL,              -- scheduled | manual | bootstrap | full_reconciliation
    source_endpoint TEXT,                       -- 拉取的 REST endpoint URL（审计用）
    http_status     INT,                        -- 拉取响应码
    error_message   TEXT,                       -- 失败原因（成功为 NULL）
    refreshed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_snapshots_pl_time
    ON catalog_exchange_info_snapshots (product_line, refreshed_at DESC);
```

### 4.3 向后兼容

`[COMPUTED, HIGH]` 现有 `PgCatalog.UpsertSymbol`（FR-006b，`pg_catalog.go:73`）的 SQL 仅写 4 字段（symbol/product_line/status/updated_at）。ALTER TABLE 后新字段取默认值（`sync_tier='disabled'`，其余 NULL），**现有行为不变**。新路径 `UpsertInstruments`（FR-032）写完整字段。

### 4.4 数据结构契约（Go 类型定义）

`[COMPUTED, HIGH]` 以下类型定义消除实现者对 diff payload、tier→stream 映射的歧义。落盘位置：`internal/client/exchangeinfo_diff.go` + `internal/client/tier_streams.go`。

**Diff 引擎类型**（FR-031/032 接口契约）：

```go
// InstrumentsChangedPayload 是 binance.control.instruments.changed 的 natsx payload。
// 通过 js.Publish("binance.control.instruments.changed", json) 发布。
type InstrumentsChangedPayload struct {
    ProductLine string          `json:"product_line"`   // spot | um_perp | cm_perp | options
    SnapshotID  string          `json:"snapshot_id"`    // ULID，关联 catalog_exchange_info_snapshots.id
    RefreshType string          `json:"refresh_type"`   // bootstrap | scheduled | manual | full_reconciliation
    Diff        InstrumentsDiff `json:"diff"`
}

// InstrumentsDiff 是两组 catalog 的集合 diff 结果。
type InstrumentsDiff struct {
    Added       []CatalogEntry `json:"added"`         // next 有、prev 无
    Removed     []CatalogEntry `json:"removed"`       // prev 有、next 无（server 侧 status→delisted）
    Updated     []CatalogEntry `json:"updated"`       // 同 key 且采集决策字段变化（触发 catalog reload）
    SpecUpdated []CatalogEntry `json:"spec_updated"`  // 同 key 且仅合约规格字段变化（不触发 reload，仅更新 DB）
    // Unchanged 不进 payload（带宽优化），仅进 snapshot.diff_summary JSONB
}

// DiffCatalog 计算两组 catalog entry 的 diff。
// 复合键：CanonicalProductLine(pl) + ":" + UpperCase(symbol)，与 catalog.go entryKey 一致。
// Updated 判定（触发 reload）：同 key 且 Status/SyncTier/BaseAsset/QuoteAsset/ExpiryDate 任一变化。
// SpecUpdated 判定（不触发 reload）：同 key 且仅 Filters/MinQty/TickSize 等规格字段变化。
// 两类分离避免风控微调（MIN_NOTIONAL 调整）产生 diff 噪音。
func DiffCatalog(prev, next []CatalogEntry) InstrumentsDiff
```

**Tier × ProductLine → Stream 映射类型**（FR-036 接口契约）：

```go
// SyncTier 是 symbol 的同步分级。
type SyncTier string

const (
    SyncTierL1Core     SyncTier = "L1_core"     // 全流（spot/um/cm）：trade+bookTicker+kline+depth
    SyncTierL2Extended SyncTier = "L2_extended" // 省depth：trade+kline+bookTicker
    SyncTierL3Full     SyncTier = "L3_full"     // 仅trade+kline
    SyncTierDisabled   SyncTier = "disabled"    // 不订阅
)

// StreamsForProductLineTier 返回给定 (productLine, tier) 应订阅的流类型列表。
// 必须按 productLine 分化（第三轮审查修正）：
//   - spot/um/cm：按 tier 差异化流组合
//   - options：统一返回 ["optionTicker"]（options 仅有此流，无 depth/bookTicker/kline）
// stream manager 调用此函数决定每组连接的 stream URL。
func StreamsForProductLineTier(productLine string, tier SyncTier) []string
```

**白名单裁决类型**（FR-034 接口契约）：

```go
// WhitelistConfig 是 FR-034 裁决所需的配置投影。
type WhitelistConfig struct {
    ProductLines []string // 空=全部
    SymbolsAllow []string // 空=全部（白名单语义）
    SymbolsDeny  []string // deny 永远赢
}

// ResolveTier 对单个 entry 执行优先级裁决，返回最终 tier（或 disabled）。
// 顺序：deny > allow > status > product_line > DB.sync_tier
func ResolveTier(entry CatalogEntry, cfg WhitelistConfig) SyncTier
```

---

## 5. 数据流

### 5.1 Bootstrap（首次启动）

```
client 启动
  → Fetch{Spot,UM,CM,Options}ExchangeInfo (4 并发 REST)
  → Decode 为 []CatalogEntry（含完整字段）
  → 本地 catalog diff（首次：全部为 added）
  → Publish binance.control.instruments.changed { added: 全部 }
  → server 消费 → UpsertInstruments → catalog_symbols (sync_tier=disabled 默认)
  → 等待 operator 通过 admin API 设置 sync_tier 或配置 allow/deny
```

### 5.2 定时刷新（6h）

```
client 定时器触发（6h）
  → Fetch{4}ExchangeInfo
  → 与本地 catalog diff
  → IF diff 非空:
      Publish instruments.changed { added, removed, updated }
      → server UpsertInstruments（removed → status='delisted'）
  → IF 24h 未发 full snapshot:
      强制发布 full reconciliation（BR-010）
```

### 5.3 白名单 + tier 裁决（采集决策）

```
stream manager 每次构建订阅列表:
  all_entries = catalog.List()  // 含 exchangeInfo 全字段
  enabled_pl  = config.ProductLines  // 空=全部
  allow       = config.SymbolsAllow  // 空=全部
  deny        = config.SymbolsDeny   // deny 永远赢

  for entry in all_entries:
    decision =裁决(entry, enabled_pl, allow, deny, entry.SyncTier)
    if decision != 'disabled':
      streams = tierToStreams(decision)  // L1 全流 / L2 省 depth / L3 仅 trade+kline
      subscribe(entry.ProductLine, entry.Symbol, streams)
```

---

## 6. 配置 Schema（SPEC §11.1 落地）

新增配置字段（`binancecfg.Config`）：

| Env Var | 字段 | 类型 | 默认 | 来源 SPEC |
|---------|------|------|------|----------|
| `FOUNDATIONX_BINANCE_PRODUCT_LINES` | `ProductLines` | `[]string` | `[]`(全部) | SPEC §11.1 `binance.product_lines` |
| `FOUNDATIONX_BINANCE_SYMBOLS_ALLOW` | `SymbolsAllow` | `[]string` | `[]` | SPEC §11.1 `binance.symbols.allow` |
| `FOUNDATIONX_BINANCE_SYMBOLS_DENY` | `SymbolsDeny` | `[]string` | `[]` | SPEC §11.1 `binance.symbols.deny` |
| `FOUNDATIONX_BINANCE_EXCHANGE_INFO_REFRESH_INTERVAL` | `ExchangeInfoRefreshInterval` | `time.Duration` | `6h` | SPEC §8（6h 刷新） |
| `FOUNDATIONX_BINANCE_EXCHANGE_INFO_FULL_SNAPSHOT_INTERVAL` | `ExchangeInfoFullSnapshotInterval` | `time.Duration` | `24h` | BR-010 |

`[COMPUTED, HIGH]` env var 解析规则：逗号分隔 → trim → 大写 symbol、lowercase product_line。空字符串列表 = `[]`（语义为「全部」，非「无」）。

---

## 7. 测试用例（TC-066 ~ TC-078）

| TC | 覆盖 FR | 类型 | 验证 |
|----|--------|------|------|
| TC-066 | FR-031 | 集成 + httptest | 四产品线 exchangeInfo mock server 返回各自字段结构，client 正确解析（含 COIN-M `contractStatus`、Options `optionSymbols` 陷阱） |
| TC-067 | FR-031 | 契约 | `InstrumentsChangedPayload` JSON schema 校验（product_line/snapshot_id/added/removed/updated 字段齐全） |
| TC-068 | FR-032 | 集成 | server 消费 `instruments.changed` → `catalog_symbols` upsert（含完整字段）+ `catalog_exchange_info_snapshots` 插入 |
| TC-069 | FR-032 | 单元 | diff 为空时零 Publish 调用；24h 强制 full snapshot 触发（BR-010） |
| TC-070 | FR-033 | 单元 | `SymbolsByTier("spot", "L1_core")` 仅返回 L1_core symbol（含完整字段）；现有 `ActiveSymbols(productLine)` 向后兼容不受影响 |
| TC-071 | FR-033 | 集成 | admin `PATCH sync_tier` → stream drain（降级时）→ unsubscribe → 新 stream 建立（升级时）（BR-011） |
| TC-072 | FR-034 | 单元 | `FilterByWhitelist` 优先级：deny 覆盖 allow、allow 空放行、product_lines 先于 allow/deny |
| TC-073 | FR-034 | 集成 | admin reload 含 `sync_tier` + 白名单组合，最终采集决策符合裁决模型 |
| TC-074 | FR-031~036 | CI gate | `no-full-snapshot-spam`：日志审计连续 skip 后必须出现 full snapshot |
| TC-075 | FR-032 | 单元 | `DiffCatalog(prev, next)`：added/removed/updated/spec_updated 四类边界（空集、全新增、全删除、仅 status 变化→Updated、仅 filters 变化→SpecUpdated、仅 sync_tier 变化→Updated） |
| TC-076 | FR-032 | 集成 | natsx control stream 声明：server 启动后 `binance.control.>` stream 存在，**retention=LimitsPolicy**（非 WorkQueue），`Publish` 返回 PubAck；multi-consumer 场景两实例均收到消息 |
| TC-077 | FR-032 | 单元 | `Catalog.Reload(fullNext)` 后 `life.SyncCatalog` 调用顺序验证；Reload 是原子替换非逐条 Add |
| TC-078 | FR-035 | 集成 | admin 鉴权：正确 Bearer 放行 / 错误 token→401 / 缺失 token 远程→403 / 缺失 token loopback→放行；`audit_log` 记录 401/403 |
| TC-079 | FR-036 | 单元 | `StreamsForProductLineTier`：spot×L1={trade,bookTicker,kline,depth} / spot×L3={trade,kline} / **options×任意={optionTicker}**（验证 options 无 depth/bookTicker） |
| TC-080 | FR-036 | 集成 | stream manager 按 (productLine,tier) 分组：L1 与 L3 symbol 不混入同一 stream URL；options 单独分组 |
| TC-081 | FR-036 | 集成 | tier 降级 L1→L3：旧连接 drain→DLQ→unsubscribe→新连接建立顺序（BR-011）；tier 升级 L3→L1：新连接异步不阻塞 |
| TC-082 | FR-036 | 单元 | 连接分批边界：spot L1 超 256 sym→拆 2 连接；options 超 1024 sym→拆 2 连接（AC-154） |
| TC-083 | FR-036 | 集成 | options 到期峰值：200 合约同时 Removed→drain 分批 ≤20/批→间隔 ≥2s→无连接管理器过载（BR-012） |

---

## 8. 与现有 FR 的关系

| 现有 FR | 关系 | 说明 |
|--------|------|------|
| FR-001 Product-Line Support | **扩展** | FR-031 实现 FR-001 承诺但未实现的「四产品线 exchangeInfo 发现」 |
| FR-006b postgresx Metadata | **复用 + 扩展** | FR-032 复用 `PgCatalog` 模式，新增 `UpsertInstruments` 方法 |
| FR-024 Hot Reload | **复用（但有依赖风险）** | FR-033/036 tier 变更复用 hot reload 的 stream add/remove 机制。⚠️ **FR-024 当前是 Partial**（TRACEABILITY 标记「全量重连非增量 diff」），FR-036 AC-153 的增量 drain 语义依赖 FR-024 升级为增量 stream diff。**若 FR-024 维持全量重连，FR-036 的 tier 升降级也会是全量重连**，违背 BR-011「先 drain 再 unsubscribe」语义。实施 FR-036 前必须先确认 FR-024 是否需升级，或在 FR-036 内自建增量 diff 逻辑（不依赖 FR-024）。 |
| FR-030 Options Raw Pass-through | **前置** | FR-031 的 Options exchangeInfo 解析是 FR-030 的数据基础 |
| SPEC §8 Control Plane | **实现** | FR-031/032 实现 §8 规划但零实现的 `instruments.changed` subject |
| SPEC §11.1 Config | **实现** | FR-034 实现 §11.1 规划但零实现的 `product_lines`/`allow`/`deny` 字段 |

---

## 9. 非功能需求（继承 + 补充）

| NFR | 指标 | 验证 |
|-----|------|------|
| NFR（继承 NFR-008） | 四产品线 exchangeInfo 并发拉取总耗时 P99 < 10s（spot 1,360 symbol JSON ~2MB） | httptest benchmark |
| NFR（新增） | diff 计算耗时 P99 < 500ms（3,616 symbol 集合 diff） | 单元 benchmark |
| NFR（新增） | `FilterByWhitelist` 耗时 P99 < 50ms（3,616 entry 过滤） | 单元 benchmark |
| NFR（继承 NFR-005） | exchangeInfo 拉取重试退避（指数退避，max 3 次） | 单元测试 |

---

## 10. 实施顺序（供 task-split）

> [COMPUTED, HIGH] **依赖关系**：FR-035（admin 鉴权）是 FR-033/034 写操作的**安全前置**，必须先于 PATCH/batch-tier endpoint 实现。FR-032 的 natsx control stream 声明（AC-112a）是 FR-031 publish 的**传输前置**。diff 引擎（AC-112b）是 FR-031/032 的**逻辑前置**。

1. **migration 005**：DB schema 扩展（ALTER + 新表），含 CHECK 约束与索引
2. **FR-035（安全前置）**：admin server `authMiddleware` + loopback fallback + `audit_log` 记录
3. **FR-032a（传输前置）**：natsx control stream `binance.control.>` 声明（AC-112a）+ diff 引擎 `DiffCatalog`（AC-112b）+ 类型定义（§4.4）
4. **FR-031**：client 四产品线 `Fetch*ExchangeInfo`（复用 spot 模式，修 COIN-M/Options 陷阱）+ `InstrumentsChangedPayload` 发布
5. **FR-032b**：server `UpsertInstruments` consumer + `Reload`→`SyncCatalog` 调用顺序（AC-112c）+ 6h 定时器
6. **FR-033（分类层）**：`CatalogEntry.SyncTier` 字段 + `SymbolsByTier` + admin PATCH endpoint（依赖 FR-035）；**不含连接拓扑**
7. **FR-034**：`binancecfg` 三字段 + `ResolveTier`/`FilterByWhitelist` + admin reload 集成白名单（依赖 FR-035）
8. **FR-036（架构层，依赖 FR-033）**：`StreamsForProductLineTier` 按 productLine 分化 + stream manager 按 (productLine,tier) 分组连接 + tier 升降级 drain + options 到期峰值平滑（BR-012）。**这是最重的实施项**，涉及 connector 拓扑重构，建议前置 ADR
9. **24h full snapshot** + CI gate `no-full-snapshot-spam`

---

## 11. 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| Options `optionSymbols` 字段结构变更（Binance 升级） | MED | MED | `filters JSONB` 保留原始字段；契约测试 + stale alert（FR-029）检测 symbol 数异常下降 |
| 3,616 symbol 全量 upsert 锁表 | LOW | HIGH | `UpsertInstruments` 分批（每批 500）+ ON CONFLICT 单行锁；事务隔离 RC |
| 6h 刷新窗口内 symbol 上市/退市未及时同步 | MED | LOW | BR-010 24h full snapshot 兜底；admin 手动 reload 即时触发 |
| sync_tier 默认 disabled 导致首次部署无数据 | HIGH | MED | 文档明确「部署后必须显式分级」；bootstrap 日志告警「N symbol at disabled tier」 |
| 白名单配置错误导致全量停采 | MED | HIGH | config 加载后日志输出「最终采集决策：L1=N, L2=N, L3=N, disabled=N」便于核对 |
| FR-036 connector 拓扑重构引入回归 | MED | HIGH | 现有 connector 是「1 连接全量」模型，FR-036 改为「N 连接按 tier 分组」；前置 ADR + 增量迁移（先支持 spot，再扩 um/cm/options）+ 回滚开关（env var 退回单连接模式） |
| options 周五批量到期 stream drain 峰值 | HIGH | MED | BR-012 分批错峰 drain（≤20/批，≥2s 间隔）；连接管理器过载告警 |

---

## 12. 证据附录（runtime 现状定位）

| 断层 | file:line | 现状 | 本增补修复 |
|------|-----------|------|-----------|
| catalog 硬编码 | `catalog.go:45-67` | `DefaultSpotCatalog` 5 symbol | FR-031 替换为 exchangeInfo 发现 |
| exchangeInfo 仅 spot | `exchangeinfo.go:全文` | 仅 `FetchSpotExchangeInfo` | FR-031 新增 um/cm/options |
| runtime 不触发发现 | `runtime.go:92` | 无条件 `DefaultSpotCatalog()` | FR-031 默认启用发现 |
| instruments.changed 零实现 | SPEC §8 | 仅规划 subject | FR-031/032 实现 publish + consume |
| exchangeInfo 不落库 | `pg_catalog.go:73` | 仅事件驱动 upsert 4 字段 | FR-032 扩展 + 定时刷新 |
| product_lines 零实现 | `config.go` | 无该字段 | FR-034 新增 |
| symbols.allow/deny 零实现 | `config.go` | 无该字段 | FR-034 新增 |
| sync_tier 零实现 | `catalog.go` | 无 tier 概念 | FR-033 新增 |

---

`[RULES I BROKE]`：
1. AC-131~124 与 TC-066~062 的编号顺延基于实读 SPEC.md（FR-030/AC-104/TC-049 为边界），`[COMPUTED, HIGH]` 可复现。第二轮补强新增 AC-112a/b/c、AC-147~124、TC-075~062（diff 引擎/natsx stream/admin 鉴权）。
2. API 陷阱（COIN-M `contractStatus`、Options `eapi`+`optionSymbols`）标注为 `[KNOWN]`，源自 2026-06-25 实查 API（见 `symbol-sync-deep-analysis-20260625.md` §7.2），非训练记忆。
3. migration SQL 用 `ADD COLUMN IF NOT EXISTS` 保证幂等可重入，但未在真实 postgresx 实例执行验证（本增补是规格文档，非 runtime 代码）；若实施时版本 < PG 9.6 需调整。标注为 `[INFERRED, MED]`。
4. sync_tier 默认 `disabled` 是安全设计选择（未分级不同步），但可能导致「部署后无数据」的运维困惑，已在 §11 风险表登记。
