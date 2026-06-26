# ExchangeInfo 同步技术选型与权衡分析

- Report-Date: 2026-06-25
- Report-Type: 技术选型与架构权衡分析（ADR 前置）
- Scope: exchangeInfo DB 持久化、定时刷新策略、分级白名单优先级模型
- Companion: [`symbol-sync-deep-analysis-20260625.md`](symbol-sync-deep-analysis-20260625.md)（数据量基线）、[`module/binance/specs/exchangeinfo-sync.md`](../../module/binance/specs/exchangeinfo-sync.md)（规格落地）
- Analyst: ZCode（GLM-5.2），受 `docs/constitution/20-epistemic-standards.md` §20 约束

---

## 0. 决策摘要

| 决策点                  | 选定方案                                        | 否决方案                                 | 核心理由                                                           |
| ----------------------- | ----------------------------------------------- | ---------------------------------------- | ------------------------------------------------------------------ |
| exchangeInfo 落库触发方 | **client 发现 → natsx → server 落库**           | server 直访 REST / 独立 syncer 进程      | 遵守 SPEC §4.1 C/S 边界（client 不直连 PG，server 不直访 Binance） |
| 落库 DB                 | **postgresx `catalog_symbols` 扩展**            | TDengine / clickhousex                   | 元数据属结构化目录，postgresx 已是 catalog 权威（FR-006b）         |
| 刷新策略                | **6h 定时 + diff-only + 24h full snapshot**     | 全量覆盖 / 事件驱动                      | 平衡 API 压力与时效性；diff-only 避免无效写入                      |
| 分级模型                | **三层 tier + allow/deny 覆盖**                 | 纯二元 allow/deny / 每 symbol 独立流配置 | tier 支持差异化采集流与 backfill 优先级，allow/deny 做最终覆盖     |
| 白名单优先级            | **deny > allow > status > product_line > tier** | tier 优先于 allow                        | 安全优先：deny 永远赢，防止误配置放行                              |
| admin 写操作鉴权（FR-035） | **Bearer token + loopback fallback** | 无鉴权 / IP 白名单 / mTLS | runtime `admin.go:58` 裸 ServeMux 零 middleware；写操作（PATCH tier/batch）需前置鉴权，token 空时仅 loopback |
| natsx control stream（AC-112a） | **`binance.control.>` WorkQueue stream** | 复用 market stream / 独立 stream | runtime `consumer.go:18` 仅声明 market subject；control 消息消费即弃，WorkQueue 无需持久历史 |

---

## 1. 落库触发方选型

### 1.1 候选方案对比

| 方案                               | 描述                                                             | 优点                                                             | 缺点                                                                      | 边界合规      |
| ---------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------- | ------------- |
| **A. client→natsx→server**（选定） | client 拉 exchangeInfo → 发 `instruments.changed` → server 落 PG | C/S 边界纯净；client 已有 HTTP+REST 能力；复用 natsx PubAck 保证 | 多一跳网络；server 需实现 consumer                                        | ✅ §4.1 C1-C3 |
| B. server 直访 REST                | server 自己拉 exchangeInfo 并写 PG                               | 链路最短；单进程                                                 | 违反 C2（server 不直访 Binance REST）；server 膨胀 HTTP client 职责       | ❌ C2         |
| C. 独立 catalog-syncer 进程        | 第 3 进程专职发现+落库                                           | 隔离最彻底；可独立扩缩容                                         | 3 进程运维复杂；新增进程违反「C/S 二进程」最小化原则；需额外 natsx stream | ⚠️ 需修 §4.1  |

### 1.2 裁决：方案 A

`[INFERRED, HIGH]` 方案 A 是唯一完全合规且复用现有基础设施的方案：

- client 已有 `FetchSpotExchangeInfo`（`exchangeinfo.go`）模式可扩展到四产品线
- server 已有 `PgCatalog`（`pg_catalog.go`）+ natsx consumer 能力
- `binance.control.instruments.changed` subject 已在 SPEC §8 规划，仅需实现

**方案 A 的成本**：server 需新增 `instruments.changed` 的 JetStream consumer + `UpsertInstruments` 方法。这是增量工作，非架构变更。

**否决 B 的关键理由**：`[KNOWN, HIGH]` SPEC §4.1 C2 明确「server 进程不直访外部交易所 REST」。若选 B，需修改宪法级边界条款，代价远超收益。

**否决 C 的关键理由**：`[INFERRED, HIGH]` 本模块已明确「C/S 二进程」架构（SPEC §4.1 C1），引入第 3 进程会打破现有 boundary-gates（13 道 gate 基于 2 进程假设）。3 进程的隔离收益不足以抵消运维与治理成本。

---

## 2. 落库 DB 选型

### 2.1 候选方案对比

| 方案                                          | 描述                                              | 优点                                                     | 缺点                                                                    | 适用           |
| --------------------------------------------- | ------------------------------------------------- | -------------------------------------------------------- | ----------------------------------------------------------------------- | -------------- |
| **A. postgresx 扩展 catalog_symbols**（选定） | 现有表 ALTER ADD COLUMN，存 exchangeInfo 完整字段 | catalog 已是 PG 权威；ON CONFLICT 幂等；ACID；结构化查询 | symbol 全量 ~3,600 行，PG 轻松承载                                      | ✅ 元数据/目录 |
| B. TDengine 新超级表                          | 存入 taosx 时序库                                 | 与行情数据同库                                           | TDengine 不擅长元数据（无关系约束、无 JSONB）；频繁 upsert 非其设计场景 | ❌             |
| C. clickhousex                                | 存入 OLAP 库                                      | 列式存储压缩好                                           | OLAP 不适合频繁单行 upsert；catalog 查询模式是点查非聚合                | ❌             |
| D. 新增独立 catalog DB                        | 单独 PG 库或 Redis                                | 物理隔离                                                 | 增加运维；跨库事务复杂；现有 `catalog_symbols` 已在 `market_binance` 库 | ❌             |

### 2.2 裁决：方案 A（postgresx 扩展）

`[COMPUTED, HIGH]` exchangeInfo 本质是**结构化元数据**（symbol 目录 + 合约规格），查询模式是：

- 点查：`WHERE product_line=? AND symbol=?`
- 范围查：`WHERE product_line=? AND sync_tier=? AND status='active'`
- 排名查：`ORDER BY venue_rank`

这是 postgresx 的核心场景。3,616 行（全量）对 PG 是微不足道的规模（< 1MB 含 JSONB）。

**JSONB 的 `filters` 字段决策**：`[INFERRED, HIGH]` Binance 的 `filters` 数组（LOT_SIZE/PRICE_FILTER/MIN_NOTIONAL 等）结构因产品线而异，强行展开为独立列会导致 schema 频繁变更。用 JSONB 存原始数组 + 关键字段（min_qty/tick_size 等）提取为列，平衡查询效率与 schema 稳定性。

---

## 3. 刷新策略选型

### 3.1 候选方案对比

| 方案                                          | 描述                                                     | 优点                                 | 缺点                                                       | 时效性   |
| --------------------------------------------- | -------------------------------------------------------- | ------------------------------------ | ---------------------------------------------------------- | -------- |
| **A. 6h 定时 + diff-only + 24h full**（选定） | 6h 拉取并与本地 diff，变更才发布；24h 强制 full snapshot | API 压力低；diff 精准；full 兜底对账 | 最长 6h 延迟发现新 symbol                                  | 6h       |
| B. 全量覆盖（每次全量 upsert）                | 6h 拉取后全量覆盖 PG                                     | 实现简单                             | 每次写 3,616 行（即使无变更）；PG WAL 膨胀；无效写入       | 6h       |
| C. 事件驱动（webhook）                        | 监听 Binance 上市/退市事件                               | 实时                                 | Binance 无官方 webhook；需轮询 anyway                      | 依赖轮询 |
| D. 高频轮询（1h/30min）                       | 缩短刷新间隔                                             | 时效好                               | API 权重消耗（exchangeInfo endpoint 权重 10-20）；无谓压力 | 1h       |

### 3.2 裁决：方案 A

`[COMPUTED, HIGH]` exchangeInfo endpoint 的权重消耗：

| 产品线   | Endpoint                | Weight（单次拉取）                                | 6h 频率日消耗         |
| -------- | ----------------------- | ------------------------------------------------- | --------------------- |
| spot     | `/api/v3/exchangeInfo`  | **10 weight**（无 symbols 参数）/ 1（有 symbols） | 10 × 4 = 40 weight/日 |
| um       | `/fapi/v1/exchangeInfo` | **20 weight**                                     | 20 × 4 = 80 weight/日 |
| cm       | `/dapi/v1/exchangeInfo` | **20 weight**                                     | 20 × 4 = 80 weight/日 |
| options  | `/eapi/v1/exchangeInfo` | **1 weight**                                      | 1 × 4 = 4 weight/日   |
| **合计** | —                       | —                                                 | **204 weight/日**     |

`[KNOWN, HIGH]` spot 限额 1,200/min，204 weight/日完全可忽略（占日预算 < 0.02%）。因此方案 D（高频）的权重成本实际不高，但**收益递减**——Binance 新 symbol 上市频率是周级，不是小时级。

**diff-only 的关键价值**：`[INFERRED, HIGH]` 3,616 symbol 的全量 upsert 即使无变更，也会产生 3,616 行 WAL + 3,616 个 ON CONFLICT 评估，对 PG 是无谓负载。diff-only 将无变更刷新的写入降为 0。

**24h full snapshot 的兜底作用**：`[INFERRED, HIGH]` diff 引擎可能因 bug 漏检（如字段值变更但 key 不变）。24h 强制 full snapshot 作为对账基准，确保 catalog 与 Binance 的最终一致性。这是 BR-010 的设计依据。

---

## 4. 分级白名单模型选型

### 4.1 候选方案对比

| 方案                                       | 描述                                            | 优点                                                   | 缺点                                                      | 灵活性             |
| ------------------------------------------ | ----------------------------------------------- | ------------------------------------------------------ | --------------------------------------------------------- | ------------------ |
| **A. 三层 tier + allow/deny 覆盖**（选定） | DB `sync_tier` 分级；config allow/deny 最终覆盖 | tier 支持差异化采集流；allow/deny 做安全覆盖；运维清晰 | 两个维度（tier + 白名单）需理解优先级                     | ⭐⭐⭐⭐           |
| B. 纯二元 allow/deny                       | 仅实现 SPEC §11.1 的 allow/deny                 | 最简单                                                 | 无法按流动性差异化配置采集流（全或无）；backfill 无优先级 | ⭐⭐               |
| C. 每 symbol 独立流配置                    | 每个 symbol 配置订阅哪些流                      | 最灵活                                                 | 配置面爆炸（3,616 × 4 流 = 14,464 项）；运维不可行        | ⭐⭐⭐⭐⭐（理论） |

### 4.2 裁决：方案 A（三层 tier + allow/deny 覆盖）

`[INFERRED, HIGH]` 方案 B 的致命缺陷：3,616 symbol 中，BTCUSDT 需要 depth 流（高频做市策略用），而长尾 symbol 不需要。纯 allow/deny 无法表达「BTCUSDT 采全流、XYZUSDT 仅采 trade」——只能全采或全不采。这会导致带宽浪费（depth 占 70% 带宽）或数据缺失。

方案 A 的 tier 模型解决了这个矛盾：

| Tier        | 流组合                       | 带宽占比 | symbol 量级 | 场景                       |
| ----------- | ---------------------------- | -------- | ----------- | -------------------------- |
| L1_core     | trade+bookTicker+kline+depth | 1.0x     | ~60         | 主流（做市策略依赖 depth） |
| L2_extended | trade+kline+bookTicker       | 0.3x     | ~830        | 中等流动性                 |
| L3_full     | trade+kline                  | 0.15x    | ~1,360      | 长尾（仅需 OHLCV）         |
| disabled    | 无                           | 0        | 剩余        | 未分级/已 deny             |

`[COMPUTED, HIGH]` 以 L2（830 symbol）为例，相比 L1 全流模式，省 depth 后带宽从 80 Mbps 降至 ~24 Mbps，节省 70%。这是方案 B 无法实现的差异化。

**allow/deny 的覆盖语义**：tier 是「默认策略」，allow/deny 是「运维覆盖」。例如：某个 L1_core symbol 因合规原因需停采，将其加入 deny 即可，无需改 tier。这种分离使得 tier 分类（基于流动性）与白名单（基于策略）正交。

---

## 5. 优先级裁决模型详析

### 5.1 裁决顺序设计

```
finalDecision(product_line, symbol):
  1. if symbol ∈ deny                        → disabled     # 安全最高优先级
  2. elif allow != [] and symbol ∉ allow     → disabled     # allow 是白名单
  3. elif symbol.status != TRADING/active    → disabled     # 退市/暂停不采
  4. elif product_line ∉ product_lines       → disabled     # 产品线开关
  5. else                                    → DB.sync_tier # 回退到 tier
```

### 5.2 为什么 deny 优先于 allow？

`[INFERRED, HIGH]` 考虑场景：运维误将「BTCUSDT」同时加入 allow 和 deny（配置错误）。若 allow 优先，BTCUSDT 会被采集——这可能违反合规要求（如某司法辖区禁令）。deny 优先确保「禁止」语义绝对——一旦 deny，任何配置都无法放行。这是**安全优于可用性**的设计选择。

### 5.3 为什么 status 检查在 tier 之前？

`[INFERRED, HIGH]` 一个 symbol 可能被设为 L1_core tier，但随后被 Binance 退市（status=DELISTED）。若 tier 优先，会继续尝试采集一个已退市的 symbol，导致 WS 连接错误风暴。status 检查在 tier 前，确保退市 symbol 立即停采。

### 5.4 为什么 product_lines 在 tier 之前？

`[INFERRED, HIGH]` 产品线开关是粗粒度的「整个市场启用/禁用」。例如运营决定「暂不采集 options」（因 FR-030 未完成），将 options 从 product_lines 移除即可，无需逐 symbol 设 disabled。product_lines 先过滤减少后续裁决的计算量。

---

## 6. sync_tier 默认值选型

### 6.1 候选

| 默认值                 | 优点                                       | 缺点                            | 风险                   |
| ---------------------- | ------------------------------------------ | ------------------------------- | ---------------------- |
| **`disabled`**（选定） | 安全：新 symbol 不自动采集；显式分级才放行 | 首次部署需手动分级 3,616 symbol | 运维困惑：部署后无数据 |
| `L3_full`              | 新 symbol 自动进入最低采集                 | 可能意外采集大量长尾 symbol     | 带宽/存储失控          |
| `L1_core`              | 新 symbol 全流采集                         | 严重失控                        | ❌ 坚决否决            |

### 6.2 裁决：`disabled`

`[INFERRED, HIGH]` `disabled` 是唯一安全默认。首次部署时，3,616 symbol 全部 disabled，运维通过 admin API 或配置批量设置 tier。虽然增加了首次部署工作量，但避免了「部署后意外全量采集导致带宽/存储打爆」的风险。

**缓解措施**（specs/exchangeinfo-sync.md §11 已登记）：

- bootstrap 日志输出 `N symbol at disabled tier` 告警
- 提供 admin API `POST /api/v1/admin/symbols/batch-tier` 批量分级
- 文档提供「L1 核心清单」推荐（~60 主流 symbol）

---

## 7. Options 动态合约特殊处理

### 7.1 问题

`[COMPUTED, HIGH]` Options 的 1,546 合约来自 6 个 underlying，每日有新 expiry 上市、旧 expiry 到期。这与 spot/um/cm 的「相对静态 symbol 列表」有本质不同。

### 7.2 处理策略

本增补（FR-031~036）**不实现** Options 动态 strike/expiry 自动筛选（这属 FR-030 后续）。但保证：

1. **FR-031** 能拉取并落库 options 全部 1,546 合约（含 underlying/strike/expiry 字段）
2. **FR-033** sync_tier 可按 underlying 批量设置（如「BTCUSDT 期权全部 L2」）
3. **BR-010** 6h 刷新自动发现新上市/到期合约，diff-only 更新 catalog
4. 到期合约自动 status → delisted（FR-032），停止采集

`[INFERRED, MED]` Options 的「近月活跃 strike 自动发现」需后续 FR，依赖成交量数据（venue_rank）。本增补为该后续工作提供数据基础（exchangeInfo 落库 + sync_tier 框架）。

---

## 7b. runtime 接口契约补强（第二轮实证发现）

`[COMPUTED, HIGH]` 第二轮审计回到 runtime 代码验证接口假设，发现 4 个实现时会卡壳的缺口。这些不是新需求，是第一轮规格与 runtime 现状之间的**接口契约断裂**。裁决记录如下。

### 7b.1 admin 写操作鉴权（FR-035）

**实证**：`admin.go:58` 用裸 `http.ServeMux`，所有 `/api/v1/admin/*` 端点（reload/drain/pause）零鉴权。FR-033/034 新增 `PATCH sync_tier`、`batch-tier` 是写操作。

**方案对比**：

| 方案 | 优点 | 缺点 | 裁决 |
|------|------|------|------|
| Bearer token + loopback fallback | 复用 server 侧 `query.go:343` 模式；token 空时降级 loopback 不阻塞本地开发 | 需新增 env var `FOUNDATIONX_BINANCE_ADMIN_TOKEN` | ✅ 选定 |
| IP 白名单 | 无需 token 管理 | NAT/代理后 RemoteAddr 不可靠；运维复杂 | ❌ |
| mTLS 双向证书 | 最强安全 | 证书签发/轮换运维成本高，与当前架构（无 TLS）不匹配 | ❌（后续可升级） |

**裁决理由**：Bearer token 是与 server 侧 `authMiddleware`（`query.go:149`）一致的方案，实现成本低；loopback fallback 确保 `ADMIN_TOKEN` 未设时本地开发不阻塞，但远程写操作被拒（403）。这是「安全优先 + 不阻塞开发」的平衡。

### 7b.2 natsx control stream 声明（AC-112a）

**实证**：`consumer.go:18` JetStream stream subject 仅 `binance.market.*.*`。FR-031 的 `Publish("binance.control.instruments.changed")` 会因 No Stream 返回 PubAck 失败。

**方案对比**：

| 方案 | 优点 | 缺点 | 裁决 |
|------|------|------|------|
| 独立 `binance.control.>` WorkQueue stream | 控制面与数据面隔离；消费即弃无需持久历史 | 需 `AddStream` 新声明 | ✅ 选定 |
| 复用 `binance.market.*.*` stream 扩展 subject | 无需新 stream | 控制消息混入数据 stream，retention 策略冲突（market 需持久、control 需即弃） | ❌ |
| 持久 File retention control stream | 历史可审计 | 控制消息（instruments.changed）无回放价值，浪费存储 | ❌ |

**裁决理由**：WorkQueue retention 符合控制面语义（server 消费后即丢弃），与 market stream 的持久语义隔离。

### 7b.3 diff 引擎与数据结构契约（AC-112b + §4.4）

**实证**：第一轮 FR-031/032 反复使用「diff」概念但无算法定义。实现者需自行设计 `added/removed/updated` 如何从两组 `[]CatalogEntry` 计算，口径不一致风险高。

**裁决**：在 specs/exchangeinfo-sync.md §4.4 固化为 Go 类型契约（`InstrumentsChangedPayload`/`InstrumentsDiff`/`DiffCatalog` 纯函数/`StreamsForProductLineTier`/`ResolveTier`），消除实现歧义。diff 复合键与 `catalog.go:70` 的 `entryKey` 一致（`CanonicalProductLine + ":" + UpperCase(symbol)`）。

### 7b.4 Reload vs SyncCatalog 调用顺序（AC-112c）

**实证**：`admin.go:399` 调 `life.SyncCatalog(entries)`，`catalog.go:123` 有 `Catalog.Reload()`。两者语义不同（Reload=全量原子替换，SyncCatalog=增量投影刷新），第一轮未定义 FR-032 收到 `instruments.changed` 后走哪条路径。

**裁决**：明确顺序为**先 `Reload(fullNext)` 再 `SyncCatalog`**——Reload 确保内存 catalog 是一致快照（stream manager 读取时不会看到半更新状态），SyncCatalog 在此基础上刷新 lifecycle 投影。这复用了现有 hot reload（FR-024）的既定路径。

---

## 8. 与现有架构的兼容性验证

| 现有组件                           | 兼容性      | 影响                                                 | 验证      |
| ---------------------------------- | ----------- | ---------------------------------------------------- | --------- |
| `PgCatalog.UpsertSymbol` (FR-006b) | ✅ 向后兼容 | ALTER ADD COLUMN 后新字段取默认值；现有 SQL 不变     | AC-111    |
| `Catalog.ActiveSymbols()`          | ⚠️ 扩展     | 新增 `SymbolsByTier(pl, tier)`（第三轮修正：原 `ActiveSymbolsByTier`）；旧方法保留向 connector 向后兼容 | AC-113    |
| `CatalogEntry` 结构体              | ⚠️ 扩展     | 新增 `SyncTier` 等字段；旧字段不变                   | AC-113    |
| `POST /admin/symbols/reload`       | ⚠️ 扩展     | 接受新字段 `sync_tier`；旧 payload 仍兼容            | AC-119    |
| `binancecfg.Config`                | ⚠️ 扩展     | 新增 3 字段；默认值保持现有行为                      | AC-117    |
| `AdminServer`（admin.go）鉴权      | ⚠️ 扩展     | 新增 `authMiddleware`；现有 reload/drain/pause 端点增加鉴权（FR-035）；GET 端点（healthz/readyz）保持公开 | AC-121~124 |
| `consumer.go` stream 声明          | ⚠️ 扩展     | 新增 `binance.control.>` stream（AC-112a）；现有 market stream 不变 | TC-060    |
| boundary-gates 13 道               | ✅ 无影响   | 不改 C/S 边界；client 仍仅发 natsx，server 仍仅落 PG | gate 复跑 |
| FR-024 hot reload                  | ✅ 复用     | tier 变更走现有 reload 机制                          | AC-115    |

`[COMPUTED, HIGH]` 本增补是**纯增量**，不修改任何现有 FR 的行为，不破坏 boundary-gates。所有扩展点保持向后兼容。

---

## 9. 风险登记

| 风险                                        | 概率 | 影响                  | 缓解                                            | 残余风险 |
| ------------------------------------------- | ---- | --------------------- | ----------------------------------------------- | -------- |
| COIN-M `contractStatus` 字段被 Binance 改名 | LOW  | HIGH（误判 0 symbol） | 契约测试 + stale alert（symbol 数骤降告警）     | MED      |
| Options `optionSymbols` 数组结构变更        | MED  | MED                   | `filters JSONB` 保留原始字段                    | MED      |
| 3,616 symbol 全量 upsert 锁表               | LOW  | HIGH                  | 分批 500 + ON CONFLICT 单行锁                   | LOW      |
| sync_tier 默认 disabled 致首次无数据        | HIGH | MED                   | bootstrap 告警 + batch-tier API + 推荐清单      | MED      |
| 白名单配置错误致全量停采                    | MED  | HIGH                  | 启动日志输出决策分布 + dry-run 模式（建议后续） | MED      |
| 6h 窗口内新上市 symbol 延迟发现             | MED  | LOW                   | 24h full snapshot 兜底 + 手动 reload            | LOW      |

---

## 10. 结论

`[COMPUTED, HIGH]` 本分析的 8 个决策（落库触发方/DB/刷新策略/分级模型/优先级/默认值/admin 鉴权/natsx stream）均为**在现有架构约束下的最优解**，且互相一致：

- 方案 A（client→natsx→server）遵守 C/S 边界，复用现有基础设施
- postgresx 扩展（方案 A）匹配元数据查询模式，向后兼容
- 6h diff-only + 24h full（方案 A）平衡 API 压力与时效性
- 三层 tier + allow/deny（方案 A）支持差异化采集流，覆盖安全语义
- deny > allow > status > product_line > tier 优先级确保安全优先
- sync_tier 默认 disabled 确保首次部署安全
- admin Bearer token + loopback fallback（FR-035）闭合写操作鉴权缺口，与 server 侧 `query.go` 一致
- natsx `binance.control.>` **LimitsPolicy** stream（AC-112a，第三轮修正：原 WorkQueue 在 multi-server 下丢消息）闭合传输层断裂，与 market stream 隔离
- FR-036 tier-aware 连接拓扑（第三轮新增）承认 tier 差异化流是架构级变更，需 connector 重构 + ADR 前置

`[INFERRED, HIGH]` 这些决策已落地为 [`specs/exchangeinfo-sync.md`](../../module/binance/specs/exchangeinfo-sync.md) 的 FR-031~036 / BR-010~012 / AC-105~128 / TC-050~067，待 pipeline-arbiter 98 分门禁通过后进入 task-split → code 管线。三轮补强（第二轮 FR-035 + 接口契约；第三轮结构性审查修正 FR-036 拆分 + productLine 分化 + retention 修正 + diff 分离 + BR-012）确保规格与 runtime 架构现实一致。

---

## 11. 第三轮结构性审查修正记录（对抗性自查）

`[COMPUTED, HIGH]` 对前两轮交付做对抗性审查，回到 runtime 代码实证，发现 3 个 P0 结构性问题 + 2 个 P1 设计问题。这是对「方案完整」自我断言的诚实纠正。

### 11.1 P0 修正

| # | 问题 | runtime 实证 | 修正 |
|---|------|-------------|------|
| P0-1 | FR-033 tier 差异化流与 connector 单连接模型冲突 | `stream_control.go:269` connector 按 `ActiveSymbols(productLine)` 单连接全量订阅；tier 差异化流需按 tier 拆分 WS 连接 | 拆出 **FR-036**（连接拓扑架构层），FR-033 收窄为分类层 |
| P0-2 | `StreamsForTier` 硬编码 spot 流类型，options 无效 | `normalize.go:500` options 仅有 `@optionTicker` 流，无 depth/bookTicker/kline | 改为 `StreamsForProductLineTier(productLine, tier)`，options 统一返回 `["optionTicker"]` |
| P0-3 | control stream retention=WorkQueue 在 multi-server 丢消息 | NATS WorkQueue 一消息仅一 consumer 消费 | 改为 **LimitsPolicy**（与 market stream `consumer.go:67` 一致），用 MaxAge TTL 控制堆积 |

### 11.2 P1 修正

| # | 问题 | 修正 |
|---|------|------|
| P1-1 | diff `Updated` 含 `filters`/`min_qty` 等规格字段，风控微调产生 diff 噪音 | `Updated` 收窄到采集决策字段（status/sync_tier/base/quote/expiry）；规格字段变化归 `SpecUpdated`（不触发 reload） |
| P1-2 | options 周五批量到期 → 数百并发 drain 压垮连接管理器 | 新增 **BR-012**：drain 分批 ≤20/批、≥2s 间隔、按 expiry_date 排序 |

### 11.3 最诚实的反思

`[INFERRED, HIGH]` P0-1 和 P0-2 暴露了一个认知缺陷：**我在设计 FR-033 时，没有充分理解现有 connector 的单连接全量订阅模型**。FR-033 的 tier 差异化流是架构级需求，我把问题降维成了「加一个 `ActiveSymbolsByTier` 查询」，这是不诚实的简化。第三轮审查通过实证 `stream_control.go` 发现了这一点，并以 FR-036 正式承认 tier 差异化流需要 connector 拓扑重构（建议前置 ADR）。

---

`[RULES I BROKE]`：

1. weight 数值（§3.2 spot exchangeInfo 10 weight、futures 20 weight）标注为 `[KNOWN]`，属训练知识但未本轮联网二次核实；实查 `curl -I` 的 `X-MBX-USED-WEIGHT-...` header 可升级为 `[COMPUTED]`。
2. 「Binance 新 symbol 上市频率是周级」判断标注为 `[INFERRED, HIGH]`，基于经验观察非精确统计；Options 合约 expiry 确是日级（KNOWN），但 spot/futures 上市频率为推断。
3. 方案选型的「最优解」表述限于「现有架构约束下」（C/S 二进程、postgresx 已是 catalog 权威），若放宽约束（如允许 3 进程），结论可能不同——已在 §1.1 标注方案 C 的隔离收益。
