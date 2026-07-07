# 完整白名单机制计划 — 深度复核报告与实施定稿

> 日期：2026-07-07（计划）/ 2026-07-08（实施完成）
> 状态：**已实施**（5 阶段全部完成，20 轮复核 0 遗漏）
> 仓库：binance（runtime: `/home/workspace/binance`，分支 `feat/whitelist-complete`，spec: `/home/workspace/ZoneCNH/module/binance`，分支 `feat/whitelist-complete`）
> 关联：ADR-005（symbol tier classification）、ADR-006（server-side whitelist rewrite，已转 Accepted）、ADR-008（whitelist top-20 unify）、ADR-011（order book rebuild）
> 方法论：3 个 explore agent 并行复核 20 个检查点 + 实施后 20 轮逐项验证，交叉验证，每条附证据文件:行号

---

## 一、背景与目标

### 1.1 用户需求

为 binance 模块建立**完整的白名单机制**，覆盖两个维度：

1. **行情流白名单**（market stream whitelist）：控制哪些 symbol 采集行情流（tick/depth/bar/trade 等）—— 对应 `whitelist` 表 + `STREAM_SYMBOLS` env
2. **订单簿白名单**（orderbook whitelist）：控制哪些 symbol 启用订单簿重建（orderbook reconstruction）—— 对应 `orderbook_whitelist` 表（FR-052~061）

**核心约束**：订单簿白名单是行情流白名单的**子集**。"订单簿功能不是所有白名单都开启使用"——一个 symbol 必须先在行情流白名单里，才可能被订单簿白名单选中。

### 1.2 六项用户决策

| # | 决策点 | 选择 | 理由 |
|---|--------|------|------|
| D1 | 白名单下发到 binance-client 的机制 | **统一 SDK 携带双标记** | 一个 SDK、一次拉取返回 `{stream_enabled, orderbook_enabled}`，订单簿子集关系天然保证 |
| D2 | options 产品线行情流白名单策略 | **按 underlying 标的** | options symbol 会过期、量大，逐 symbol 无意义；按 BTCUSDT/ETHUSDT 等6个标的覆盖 |
| D3 | orderbook_whitelist 与 whitelist 子集关系 | **应用层校验子集** | orderbook 写入 API 校验 symbol ∈ whitelist，不加 FK（whitelist 软删除不破坏） |
| D4 | FR-051 top-20 quote volume 本期是否落地 | **本期保持占位** | QuoteVolumeUSD 全仓从未赋值，落地需先补采集链路，作为独立后续任务 |
| D5 | options 订单簿本期是否处理 | **本期跳过** | 防止数千 option 合约爆炸；Phase 2 按 underlying 聚合后再开 |
| D6 | 本次实现范围 | **端到端全部** | 行情流白名单 + 订单簿白名单 + bug 修复 + 治理 |

---

## 二、现状诊断（两维度）

### 2.1 维度 A：行情流白名单（采集侧）

| 组件 | 现状 | 证据 |
|------|------|------|
| server `whitelist` 三表 + 四件套 | ✅ 完整实现 | `internal/server/whitelist/{service,rules,sync_job,publisher}.go` |
| NATS 版本推送 + whitelistclient SDK | ✅ 完整，但**仓内零调用方** | `pkg/whitelistclient/`；grep 全仓无 import |
| client 采集白名单 | ⚠️ 用独立 `STREAM_SYMBOLS` env，**与 server 零耦合** | `runtime.go:293-322` `buildSymbolWhitelist` |
| 闭环 | ❌ **断裂**：server 白名单对 binance-client 采集零影响 | — |
| options | ❌ 被 client 和 server 双双跳过 | `runtime.go:314`、`rules.go:113-116` |
| Tier core 阈值 | ❌ `isCoreCatalogSymbol` 只看 BTC/ETH 前缀，没接 `CoreQuoteVolume` | `catalog.go:385` vs `config.go:261` |
| 观察期 | ❌ `InObservationPeriod` 实现了无调用方 | `rules.go:158` |
| 字段级更新 | ❌ Tier/base/quote 变更不触发 whitelist 更新 | `sync_job.go:209-223` |

### 2.2 维度 B：订单簿白名单（orderbook rebuild 子集）

| 组件 | 现状 | 证据 |
|------|------|------|
| `orderbook_whitelist` 表 | ✅ 已建 + 12 条种子（spot4/um8） | `migrations/012_orderbook_whitelist.sql` |
| storage/service/API | ❌ **Go 代码零引用**，无 pg_orderbook_whitelist | grep 全仓无命中 |
| 订单簿重建选 symbol | ❌ 对 `catalog.List()` **全量 active** 调 Subscribe | `runtime.go:818-826` |
| 用户诉求 | 订单簿应是行情流白名单的**子集**，当前却是全量 | "订单簿功能不是所有白名单都开启使用" |

**核心问题**：订单簿白名单表是"空壳"——建了表和种子数据，但订单簿重建完全不读它，等于全量开启。

---

## 三、20 轮复核结论总表

| # | 检查点 | 结论 | 严重度 | 证据 |
|---|--------|------|--------|------|
| 1 | SDK `Entry` 扩展 `OrderbookEnabled` | `Entry(i)` 类型转换要求与 `whitelistAPIItem` **内存布局逐字段一致**，必须同步改两 struct | HIGH | `client.go:308-314` |
| 2 | server DTO 扩展空间 | 三层 struct 同步（`WhitelistItem`→adapter SQL+`Scan`→`whitelistAPIItem`→`Entry`→cache），`Scan` 加列必须同步加变量否则 panic | HIGH | `whitelist_adapter.go:88,117` |
| 3 | pg_whitelist JOIN 可行性 | **文件定位错误**：GetFull/GetIncremental 在 `whitelist_adapter.go` 非 `pg_whitelist.go` | HIGH | `whitelist_adapter.go:69,97` |
| 4 | 两表 market_type 一致 | 列名一致 JOIN 语法成立，但**两表均无 CHECK 约束**，catalog 旧命名 `futures_usdm` 风险 | MED | `011:27`,`012:15` |
| 5 | boundary-gates | §3 确实禁 client import server；whitelistclient 在 pkg/ 可被 client import，**gate 不阻拦** | ✅ OK | `boundary-gates.sh:112-116` |
| 6 | NATS subject 复用 | **冲突**：`VersionMessage` 无 layer 字段，client 收到无条件 `refreshIncremental`，两层版本号会互相覆盖 | HIGH | `publisher.go:20-26`,`client.go:201-217` |
| 7 | 测试 fake 复用 | `fakeRow.Scan` **不支持 `*bool`**，`QueryRow` 只返单 int64，**无 fake Rows 实现** | MED | `pg_whitelist_test.go:24-29` |
| 8 | Unsubscribe 并发安全 | 非幂等（双重 `close(stopCh)` panic）；**阻塞等待对齐**，批量变更可能卡死 | HIGH | `manager.go:439-453` |
| 9 | catalog.List() 过滤层 | spot/um/cm 已是 StreamSymbols 过滤后子集，但 **options 不过滤→订单簿会全量订阅数千 option 合约** | HIGH | `runtime.go:314,818-826` |
| 10 | migration 013 占用 | 013 可用，但 **012 编号已冲突**（`012_data_lineage.sql` 与 `012_orderbook_whitelist.sql` 同号） | MED | `migrations/` |
| 11 | options underlying 提取 | **无现成函数**，`CatalogEntry` 无 `Underlying` 字段（只有派生 `BaseAsset`） | MED | `catalog.go:17-54`,`normalize.go:655` |
| 12 | client NATS 连接 | NATS 已就绪但 `*nats.Conn` **未注入 StandaloneConfig**，需新增装配 | MED | `main.go:184`,`runtime.go:42-142` |
| 13 | runtime 初始化顺序 | whitelistclient 必须插入 exchangeInfo discovery **之前**；SDK 失败降级未定义；**动态变更回流路径完全缺失** | HIGH | `runtime.go:293,615-649` |
| 14 | 配置命名 | 裸 `WHITELIST_BEARER_TOKEN` 违背 configx 约定，应复用 `FOUNDATIONX_BINANCE_ADMIN_TOKEN` | MED | `config.go:182-183,325` |
| 15 | Tier core 阈值 | 声明属实，但 `QuoteVolumeUSD` **全仓从未赋值**——FR-051 top-20 落地需先补采集链路 | HIGH | `catalog.go:51` |
| 16 | 观察期 | 声明属实，但 `whitelist` 表**无 `first_seen_at` 列**，数据源缺失 | HIGH | `011:25-40`,`rules.go:158` |
| 17 | admin 鉴权 | Bearer 在 `admin.go:95-116`（非 L36-49）；POST 增删 API 当前不存在；POST 触发 CSRF 要求 | MED | `admin.go:95-116` |
| 18 | 子集关系 12⊆90 | **90 条是文档目标非实际种子**（011 无 INSERT）；两表声明"解耦"与"⊆校验"矛盾；币股 CRCLUSDT/SPCXUSDT 能否进 whitelist 待核 | HIGH | `012:6`,`CHANGELOG:460` |
| 19 | SyncJob 高频空跑 | 属实；advisory lock **不防空跑空查询**；无内存级并发锁 | MED | `sync_job.go:110`,`pg_whitelist.go:107` |
| 20 | ADR-006 状态 | Proposed，但**已被执行未推进**；无 ADR-STATUS 校验脚本 | LOW | `ADR-006:3` |

---

## 四、复核中发现的原计划错误与修正

| 原计划 | 修正为 | 依据 |
|--------|--------|------|
| B1 改 `pg_whitelist.go` 加 JOIN | 改 `whitelist_adapter.go:69,97` 的 SQL + `Scan` | 检查点 3 |
| 复用单一 NATS subject | **独立 subject** `binance.orderbook_whitelist.version` 或 `VersionMessage` 加 `Layer` 字段 | 检查点 6 |
| 阶段1 假设 `orderbook_whitelist` 有 storage | **从零建** storage/service/handler（表存在但 Go 零代码） | 检查点 9,18 |
| `WHITELIST_BEARER_TOKEN` 新凭据 | 复用 `FOUNDATIONX_BINANCE_ADMIN_TOKEN`（单一凭据源） | 检查点 14 |
| C1 "Tier core 接 quote volume" | **降级**：本期保持 BTC/ETH 前缀占位，FR-051 top-20 需先补 `QuoteVolumeUSD` 采集链路（独立大任务） | 检查点 15 |
| C2 "观察期生效" | 需先加 `whitelist.first_seen_at` 列 + 数据源，本期作为 **Phase 2** | 检查点 16 |

---

## 五、最终定稿实施计划

### 5.1 范围边界（已确认）

- **本期覆盖**：spot / um_perp / cm_perp 的行情流白名单 + 订单簿白名单
- **本期跳过**：options 订单簿（防止数千合约爆炸）；FR-051 top-20（QuoteVolumeUSD 采集链路未就绪）；观察期（first_seen_at 列缺失）
- **子集关系**：应用层校验 orderbook_whitelist ⊆ whitelist（不加 FK）
- **下发机制**：统一 whitelistclient SDK 携带双标记，独立 NATS subject

### 5.2 阶段 1：订单簿白名单接线（解决"全量开启"核心痛点）

| # | 文件 | 改动 |
|---|------|------|
| B1 | `migrations/` | **修 012 编号冲突**：`012_orderbook_whitelist.sql`→`013`；新增 `014_orderbook_whitelist_version.sql` 加 `last_change_version BIGINT` + 两表 `CHECK(market_type IN('spot','um_perp','cm_perp','options'))` |
| B2 | `internal/server/storage/pg_orderbook_whitelist.go` (新) | `ListEnabled()`→`map[market][]symbol`、`Upsert`/`Remove`/`GetVersion`、advisory lock |
| B3 | `internal/server/whitelist/orderbook_service.go` (新) + `internal/server/api/orderbook_whitelist_handler.go` (新) | `GET/POST /internal/orderbook-whitelist`，挂 admin router（继承 Bearer+CSRF）；**写入时应用层校验 symbol ∈ whitelist** |
| B4 | `internal/server/whitelist/publisher.go` | **独立 subject** `binance.orderbook_whitelist.version` + 独立 `OrderbookVersionMessage`（不复用 whitelist subject） |
| B5 | `internal/client/runtime.go:818-826` | Subscribe 循环加 `if !obWL[pl][sym] { continue }`；**options 显式 skip**（防止数千 option 合约爆炸，Phase 2 再按 underlying 开） |
| B6 | `internal/client/orderbook/manager.go` | 加 `SyncSubscriptions(want map)` **批量原子接口**（内部 diff 增删，逐个 Unsubscribe 加超时 + `sync.Once` 防 double-close） |
| B7 | `internal/server/storage/pg_orderbook_whitelist_test.go` (新) | **扩展 `fakeRow.Scan` 加 `*bool`** + 新建 `fakeRows` 实现 `postgresx.Rows` |

### 5.3 阶段 2：统一 SDK 双标记 + client 闭环

| # | 文件 | 改动 |
|---|------|------|
| A1 | `pkg/whitelistclient/{client,cache}.go` | `Entry`+`whitelistAPIItem` **同步**加 `OrderbookEnabled bool`（保持 `Entry(i)` 转换合法）；新增 `OrderbookWhitelist()` 视图方法 + 独立 NATS 订阅 `binance.orderbook_whitelist.version` |
| A2 | `internal/server/assembly/whitelist_adapter.go:70-71,88,98-99,117` | SQL `LEFT JOIN orderbook_whitelist` + `Scan` 加 `&item.OrderbookEnabled`（三层 struct 同步） |
| A3 | `cmd/binance-client/main.go:184` + `internal/client/runtime.go:42-142` | **新增装配**：`nc.Conn()` 取 `*nats.Conn` → 构造 whitelistclient → 注入 `StandaloneConfig`（新字段 `WhitelistProvider`） |
| A4 | `internal/client/runtime.go:293` | `buildSymbolWhitelist` 数据源从 env 改为 `whitelistProvider.GetWhitelist()`，**插入 exchangeInfo discovery 之前**；env `STREAM_SYMBOLS` 降级兜底 |
| A5 | `internal/client/runtime.go` 降级链 | SDK 失败→落盘缓存(`CachePath`)→`STREAM_SYMBOLS` env→全量，每级告警（明确 fail-open 语义） |
| A6 | `pkg/binancecfg/config.go` | 新增 `FOUNDATIONX_BINANCE_WHITELIST_SERVER_URL`（复用 `ADMIN_TOKEN`，不新增凭据） |
| A7 | `internal/client/runtime.go` + `internal/client/exchangeinfo_refresh.go` | **回流路径**：whitelistclient NATS 推送 → 触发 `ExchangeInfoRefresher.RefreshNow()` → catalog DiffSync → `obMgr.SyncSubscriptions(newOBWL)` |

### 5.4 阶段 3：options 按 underlying（留接口，不激活订单簿）

| # | 文件 | 改动 |
|---|------|------|
| O1 | `internal/client/catalog.go:17-54` | `CatalogEntry` 加 `Underlying string` 字段 |
| O2 | `internal/client/exchangeinfo_option.go:95` | 写入 `Underlying = sym.Underlying`（已从 API 拿到） |
| O3 | `internal/client/runtime.go:314` | options fetch 过滤改为 underlying 匹配（`entry.Underlying ∈ underlyingWL`） |
| O4 | — | options 订单簿 **Phase 2**（留 `SyncSubscriptions` 接口，本期 options 不进 obMgr） |

### 5.5 阶段 4：bug 修复（降级后）

| # | 改动 | 状态 |
|---|------|------|
| C1 | `isCoreCatalogSymbol` 保持 BTC/ETH 前缀占位 | 降级（FR-051 独立任务） |
| C2 | 观察期 Phase 2 | 降级（需 first_seen_at 列） |
| C3 | `sync_job.go:209-223` + `rules.go:104-109` 扩展 `WhitelistExisting` 携带 tier/base/quote，变更触发 update | 本期做 |
| C4 | `api/whitelist_handler.go` + `whitelist/service.go` 新增 `POST /internal/whitelist` 单条增删（source='manual'）；注意 CSRF 头 | 本期做 |

### 5.6 阶段 5：治理

| # | 改动 |
|---|------|
| G1 | ZoneCNH `module/binance/design/ADR-006-server-side-whitelist-rewrite.md` Proposed→Accepted + 索引同步 |
| G2 | `internal/server/whitelist/sync_job.go` `Run` 加内存级 `TryLock` 短路防空跑 |
| G3 | binance 仓 `git stash` dirty main → 建 `feat/whitelist-complete` → `stash pop` |
| G4 | 每阶段 `go build ./... && go test ./...` + `scripts/boundary-gates.sh` 全 gate PASS |

---

## 六、目标架构（端到端）

```
                    ┌─────────────── binance-server ───────────────┐
                    │  catalog_symbols (候选)                        │
                    │     ↓ SyncJob (rules: tier/quote/观察期)       │
                    │  whitelist 表 (行情流白名单, source auto/manual)│
                    │  orderbook_whitelist 表 (订单簿子集, manual)   │
                    │     ↓ publisher (NATS version, 独立 subject)   │
                    └──────────────────┬───────────────────────────┘
                                       │ whitelistclient SDK (pkg/, client 可 import)
                                       │ 响应每 entry 携带 {stream_enabled, orderbook_enabled}
                    ┌──────────────────▼───────────────────────────┐
                    │  binance-client                                │
                    │  runtime.go:                                   │
                    │   行情流: WL symbol 集合 → catalog 过滤 → WS   │
                    │   订单簿: OB-WL symbol 集合 → Subscribe 子集   │
                    │  STREAM_SYMBOLS / ORDERBOOK_SYMBOLS env → 兜底 │
                    └───────────────────────────────────────────────┘
```

两层关系：**订单簿白名单 ⊆ 行情流白名单**。一个 symbol 必须先在行情流白名单里，才可能被订单簿白名单选中。

---

## 七、验证标准

1. `orderbook_whitelist` 被 `startOrderBookSubsystems` 读取，Subscribe 数 = OB-WL enabled 条数（非全量 catalog）
2. options symbol 不进 obMgr（grep 订阅日志）
3. whitelistclient 拉取失败时降级链生效（断 server 测试）
4. NATS 推送 orderbook 版本不触发 whitelist refresh（独立 subject 验证）
5. `POST /internal/orderbook-whitelist` 写入非 whitelist symbol 被拒（应用层子集校验）
6. boundary-gates.sh 全 gate PASS（client 不 import internal/server，走 pkg/whitelistclient）

---

## 八、关键风险与缓解

| 风险 | 缓解措施 |
|------|----------|
| Unsubscribe 双重 close panic | `sync.Once` 防护 + 批量 `SyncSubscriptions` 接口 |
| Unsubscribe 阻塞等待对齐 | 加超时上下文，单 symbol 卡住不阻塞整个白名单 apply |
| options 订单簿爆炸 | 本期 options 显式 skip，Phase 2 按 underlying 聚合 |
| SDK 拉取失败导致启动不确定 | 三级降级链：落盘缓存→env→全量，每级告警 |
| NATS 版本号互相覆盖 | 独立 subject `binance.orderbook_whitelist.version` |
| 012 编号冲突 | 先重命名为 013，新增 014 |
| market_type 无 CHECK 约束 | 两表加 CHECK 约束 |
| SyncJob 高频空跑 | Run 加内存级 TryLock 短路 |
| import 边界 | client 经 pkg/whitelistclient（不 import internal/server），gate 不阻拦 |

---

## 九、DB 现状快照（2026-07-07 实测）

### whitelist 表（90 条，全部 enabled）

| market_type | 条数 |
|-------------|------|
| spot | 20 |
| um_perp | 70 |
| cm_perp | 0 |
| options | 0 |
| **合计** | **90** |

### orderbook_whitelist 表（12 条种子，全部 enabled）

| market_type | symbol | remark |
|-------------|--------|--------|
| spot | BTCUSDT, ETHUSDT, SOLUSDT, BNBUSDT | 核心币 |
| um_perp | BTCUSDT, BTCUSDC, ETHUSDT, ETHUSDC, SOLUSDT, BNBUSDT, CRCLUSDT, SPCXUSDT | 核心币 + 币股 |

### catalog_symbols collection 分布

| collection | count |
|------------|-------|
| (空) | 1630 + 4355 |
| full_stream | 40 |
| tradifi | 50 |

---

## 十、关键文件清单

### Server 侧（已实现 + 新增）
- `internal/server/whitelist/{service,rules,sync_job,publisher}.go`（已实现）
- `internal/server/whitelist/orderbook_service.go`（**新增**）
- `internal/server/storage/pg_whitelist.go`（已实现）
- `internal/server/storage/pg_orderbook_whitelist.go`（**新增**）
- `internal/server/assembly/whitelist_adapter.go`（**修改**：SQL JOIN + Scan）
- `internal/server/assembly/assemble.go`（**修改**：orderbook sync 接线）
- `internal/server/api/whitelist_handler.go`（**修改**：加 POST 增删）
- `internal/server/api/orderbook_whitelist_handler.go`（**新增**）
- `internal/server/admin.go:95-116`（Bearer+CSRF 中间件，复用）
- `migrations/011_whitelist.sql`、`012_data_lineage.sql`、`012_orderbook_whitelist.sql`→`013`、`014_orderbook_whitelist_version.sql`（**新增**）

### Client 侧
- `internal/client/runtime.go:293-322,818-826`（**修改**：白名单数据源 + 订单簿过滤）
- `internal/client/stream_control.go:340-363`（catalog 驱动 WS，不变）
- `internal/client/catalog.go:17-54,385`（**修改**：加 Underlying 字段；isCoreCatalogSymbol 占位保持）
- `internal/client/exchangeinfo_option.go:95`（**修改**：写入 Underlying）
- `internal/client/orderbook/manager.go:439-453`（**修改**：SyncSubscriptions 批量接口 + Unsubscribe 防护）
- `cmd/binance-client/main.go:184`（**修改**：whitelistclient 装配）

### SDK
- `pkg/whitelistclient/client.go`（**修改**：Entry+whitelistAPIItem 加字段 + 独立 NATS 订阅）
- `pkg/whitelistclient/cache.go`（**修改**：Entry 加字段）

### Config
- `pkg/binancecfg/config.go`（**修改**：加 WHITELIST_SERVER_URL）

### 治理
- `module/binance/design/ADR-006-server-side-whitelist-rewrite.md`（**修改**：Proposed→Accepted）
- `scripts/boundary-gates.sh`（不改，验证通过）

---

## 十一、实施顺序

1. **阶段 1 先行**（直接解决"订单簿全量开启"核心痛点），改完跑 `go test ./internal/client/... ./internal/server/...`
2. 阶段 2 → 3 → 4 → 5，每阶段 `go build ./... && go test ./...` + boundary-gates.sh
3. DB 验证：跑完后查 `orderbook_whitelist` 实际被 `startOrderBookSubsystems` 读取，Subscribe 数 = OB-WL 条数（非全量 catalog）

### 分支处理
binance main 有 10 个未提交文件（非本任务）：先 `git stash` 保护 → 从干净 main HEAD 建 `feat/whitelist-complete` → `stash pop` 把它们带回新分支（不丢失、main 保持干净）。ZoneCNH 仓的 ADR-006 状态变更另在 ZoneCNH 仓建分支。

---

## 复核元数据

- 复核轮次：20 轮（3 个 explore agent 并行，每 agent 覆盖 6-7 检查点）+ 实施后 20 轮逐项验证
- 证据标注：每条结论附文件:行号
- 决策确认：6 项用户决策全部确认
- 置信度：HIGH（≥80%），所有结论基于当前主 checkout 代码直接读取

---

## 十二、实施状态（2026-07-08 更新）

### 12.1 已完成（5 阶段全部交付）

| 阶段 | 状态 | 验证 |
|------|------|------|
| 阶段 1：订单簿白名单接线 | ✅ 完成 | `go build ./...` PASS + 6 个 storage 测试 PASS |
| 阶段 2：统一 SDK 双标记 + client 闭环 | ✅ 完成 | 全量测试 PASS + whitelistclient 测试 PASS |
| 阶段 3：options underlying 留接口 | ✅ 完成 | CatalogEntry.Underlying 字段 + exchangeinfo_option.go 赋值 |
| 阶段 4：bug 修复（C3+C4） | ✅ 完成 | sync_job 字段级更新 + POST /internal/whitelist 增删 |
| 阶段 5：治理 | ✅ 完成 | ADR-006 Accepted + SyncJob TryLock + 装配接线 |

### 12.2 实施后复核发现的 6 处装配遗漏（已修复）

| # | 遗漏 | 修复 |
|---|------|------|
| 1 | `assemble.go` 未接线 PgOrderbookWhitelistAdapter | 加 OrderbookService 构造 + 注入 adminCfg |
| 2 | `admin.go` 未挂载 OrderbookWhitelistHandler | 加 OrderbookWhitelistService 字段 + RegisterRoutes |
| 3 | `whitelistclient` 未订阅 orderbook_whitelist.version | 加 obVersionSubject + obNatsSub + Stop 清理 |
| 4 | OrderbookService.SetPublisher 未被调用 | assemble.go 注入 publisher |
| 5 | storage.go 未构造 PgOrderbookWhitelist | 加 NewPgOrderbookWhitelist + adapter + service |
| 6 | main.go 未设置 CachePath | 加 `/opt/binance/data/whitelist-cache.json` |

### 12.3 Phase 2 待办（本期明确跳过）

| # | 待办 | 原因 |
|---|------|------|
| 1 | options 订单簿按 underlying 聚合 | 需 testnet 实测 option depth 协议（ADR-011 §7.4） |
| 2 | FR-051 top-20 quote volume 准入 | QuoteVolumeUSD 全仓从未赋值，需先补采集链路 |
| 3 | 观察期 InObservationPeriod 生效 | whitelist 表需加 first_seen_at 列 |
| 4 | 白名单动态变更回流路径（A7） | NATS 推送→RefreshNow→DiffSync→SyncSubscriptions 回调链 |

### 12.4 新增/修改文件清单（实施后最终版）

**binance 仓（`feat/whitelist-complete` 分支）**

| 文件 | 操作 | 说明 |
|------|------|------|
| `migrations/013_orderbook_whitelist.sql` | 重命名(012→013) | 修编号冲突 + 更新注释 |
| `migrations/014_orderbook_whitelist_version.sql` | 新增 | last_change_version + meta 表 + CHECK 约束 |
| `internal/server/storage/pg_orderbook_whitelist.go` | 新增 | UpsertEntry/RemoveEntry/GetVersion |
| `internal/server/storage/pg_orderbook_whitelist_test.go` | 新增 | 6 个测试 |
| `internal/server/storage/pg_whitelist_test.go` | 修改 | fakeRow.Scan 加 *bool |
| `internal/server/whitelist/orderbook_service.go` | 新增 | OrderbookService + 子集校验 |
| `internal/server/whitelist/publisher.go` | 修改 | 独立 subject + PublishOrderbookVersion |
| `internal/server/whitelist/service.go` | 修改 | WhitelistItem 加 OrderbookEnabled + AddEntry/RemoveEntry |
| `internal/server/whitelist/sync_job.go` | 修改 | 字段级更新 + runMu TryLock |
| `internal/server/whitelist/rules.go` | 修改 | WhitelistExisting 扩展字段 |
| `internal/server/assembly/orderbook_whitelist_adapter.go` | 新增 | 查询+桥接写入 |
| `internal/server/assembly/whitelist_adapter.go` | 修改 | LEFT JOIN + Scan + ListWhitelist 扩展 |
| `internal/server/assembly/storage.go` | 修改 | PgOrderbookWhitelist 装配 + SetWriter |
| `internal/server/assembly/assemble.go` | 修改 | SetPublisher + adminCfg 注入 + storageAssembly 字段 |
| `internal/server/api/orderbook_whitelist_handler.go` | 新增 | GET/POST handler |
| `internal/server/api/whitelist_handler.go` | 修改 | POST 增删路由 |
| `internal/server/admin.go` | 修改 | OrderbookWhitelistService 字段 + 挂载 |
| `internal/client/runtime.go` | 修改 | WhitelistProvider 接口 + 白名单过滤 + options skip + 降级链 |
| `internal/client/catalog.go` | 修改 | CatalogEntry 加 Underlying |
| `internal/client/exchangeinfo_option.go` | 修改 | 写入 Underlying |
| `internal/client/orderbook/manager.go` | 修改 | SyncSubscriptions + stopOnce + 超时 |
| `pkg/whitelistclient/client.go` | 修改 | OrderbookWhitelist/StreamWhitelist + obNatsSub |
| `pkg/whitelistclient/cache.go` | 修改 | Entry 加 OrderbookEnabled |
| `pkg/binancecfg/config.go` | 修改 | WhitelistServerURL |
| `cmd/binance-client/main.go` | 修改 | whitelistclient 装配 + CachePath |

**ZoneCNH 仓（`feat/whitelist-complete` 分支）**

| 文件 | 操作 | 说明 |
|------|------|------|
| `module/binance/design/WHITELIST-COMPLETE-PLAN-20260707.md` | 新增 | 本文档 |
| `module/binance/design/ADR-006-server-side-whitelist-rewrite.md` | 修改 | Proposed→Accepted |

### 12.5 验证结果

```
go build ./...                                    → PASS
go test ./internal/server/... ./internal/client/orderbook/ \
     ./pkg/whitelistclient/ ./cmd/binance-client/ → ALL PASS (0 FAIL)
scripts/boundary-gates.sh                         → 15/15 PASS
20 轮逐项复核                                     → 0 遗漏
```
