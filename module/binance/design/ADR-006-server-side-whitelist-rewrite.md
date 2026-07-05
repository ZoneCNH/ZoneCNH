# ADR-006：服务端白名单重写——Catalog 从内存演进为 DB SSOT

> 状态：Proposed
> 日期：2026-07-05
> 决策者：binance 模块架构
> 关联：ADR-005（symbol tier classification，本 ADR 复用其 Tier 字段作为白名单准入依据）；`module/binance/spec/SPEC.md` FR-012~036；`report/binance/EXCHANGEINFO-WHITELIST-DESIGN-DEEP-ANALYSIS-20260705.md`
> 仓库归属：ZoneCNH 主仓 `module/binance/`

---

## 背景

binance 模块当前 Catalog 架构是**进程内内存结构**：

- `Catalog`（`internal/client/catalog.go:56`）维护 `map[string]CatalogEntry` + `generation int64`，diff 非空时递增。
- client 侧完成 ExchangeInfo 采集与 diff 后，通过 NATS subject `binance.catalog.diff` 发布 `CatalogDiffMessage`（`catalog_publisher.go`）。
- server 侧 `catalogdiff.Subscriber`（queue group `binance-catalog-diff`）接收 diff，委托 `CatalogUpdater.ApplyDiff` 写入 PostgreSQL `catalog_symbols` 表（`pg_catalog.go`、`migrations/001_catalog.sql`）。
- 白名单现状：client 侧 `buildSymbolWhitelist(cfg.StreamSymbols)` + `filterCatalogEntriesByWhitelist`（配置驱动，`runtime.go`）；server 侧 `SymbolBlacklist` interface（ingest 路径拒绝，`server.go`，FR-013）。

**问题**：白名单是配置驱动的静态过滤，无服务端 DB、无版本管理、无下游消费方 API、无审计日志。下游消费方（策略/行情/风控）无法获取"业务允许的交易对子集"，只能各自直连交易所或硬编码。

业务需要：全量发现 → 服务端白名单决策 → 下游消费方统一拉取 + 缓存 + NATS 推送通知。

---

## 决策

**重写**：将 Catalog 从纯内存结构演进为"内存缓存 + 服务端 DB SSOT"双层架构，新增白名单层。不保留旧的配置驱动白名单作为主路径。

1. **Discovery 层复用**：现有 `catalogdiff` NATS pipeline + `catalog_symbols` 表复用，`catalog_symbols` 即候选表（不重命名，避免迁移成本），新增 `first_seen_at` / `last_seen_at` / `exchange_status` 字段。
2. **Whitelist 层新增**：新增 `whitelist` 表 + `whitelist_meta` 单行表（version SSOT）+ `whitelist_sync_log` 审计表；新增 Whitelist Sync Job（事件驱动 + 定时兜底）。
3. **API 层新增**：`GET /internal/whitelist`（全量 + 增量）+ NATS subject `binance.whitelist.version`（version 变更推送）。
4. **旧白名单降级**：`buildSymbolWhitelist` / `filterCatalogEntriesByWhitelist` / `SymbolBlacklist` 保留为本地兜底过滤层（client 启动时 DB 不可用的降级），不再是白名单权威源。

---

## 替代方案

### 方案 A：叠加（保留 Catalog 内存白名单 + 新增独立白名单服务）

在现有 Catalog 之上叠加一个独立的白名单服务模块，Catalog 不变。

- 优点：零改造现有代码，风险低。
- 缺点：两套 symbol 数据源（Catalog 内存 + 白名单 DB），一致性维护复杂；白名单服务与 Catalog 职责重叠；下游消费方面对两个接口。
- 否决理由：决策者选择重写，避免长期维护两套并行体系。

### 方案 B：独立 module（symbol_registry）

将白名单服务拆为独立 module `symbol_registry`。

- 优点：职责隔离清晰，可复用于其他交易所。
- 缺点：本期只实现 Binance，过早抽象；增加跨模块协调成本；`catalog_symbols` 表在 binance 仓，拆模块需跨仓引用。
- 否决理由：决策者指定归入 binance 仓。架构预留扩展点（`market_type` 字段已支持多交易所），未来需要时再拆。

---

## 影响

| 影响面 | 说明 |
|--------|------|
| 现有 FR | FR-013（whitelist/blacklist hot reload）从"配置热加载"升级为"DB SSOT + NATS 推送"，需更新 SPEC evidence 指向 |
| 新增 FR | 需新增 FR-045~051（见设计文档 §8），进入 Spec→Code 管线 |
| DB migration | 新增 `migrations/011_whitelist.sql`（whitelist + whitelist_meta + whitelist_sync_log + catalog_symbols 字段扩展） |
| NATS | 新增 subject `binance.whitelist.version`，publisher 使用**独立 NATS 连接**（不依赖 ingest transport），不新增基础设施；publish 失败非致命 |
| 代码 | Whitelist Sync Job、Whitelist Service API、下游消费方 SDK 为新增代码；`catalogdiff` pipeline 扩展：subscribeCatalogDiff 直接调用 ApplyDiff |
| tier 保留 | ApplyDiff upsert 用 `COALESCE(NULLIF(EXCLUDED.x, ''), catalog_symbols.x)` 保留手动分配的 tier/collection，不被 diff-sync 覆盖 |
| 币股识别 | `contract_type='TRADIFI_PERPETUAL'` 自动区分币股，`collection='tradifi'` |
| FR-051 统一 | v0.4 起四类市场（spot/um_perp 加密/币股/cm_perp/options）各取 24h quoteVolume top 20，统一 core 准入；options 准入层与采集分桶层解耦（ADR-008）。cm_perp/options 从人工审核改为自动准入，币股配额 top 50→top 20 |
| 兼容性 | 旧 `StreamSymbols` 配置保留为降级兜底，不影响现有部署 |
