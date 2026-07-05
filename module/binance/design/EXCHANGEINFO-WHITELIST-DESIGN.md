# 币安全市场交易对发现与白名单同步系统 —— 技术设计文档

| 项目     | 内容                                                                   |
| -------- | ---------------------------------------------------------------------- |
| 文档状态 | Draft（已纳入 Spec→Code 管线，ADR-006 裁决：重写）                     |
| 版本     | v0.2                                                                   |
| 更新日期 | 2026-07-05                                                             |
| 覆盖范围 | Binance Spot / USDⓈ-M 永续 (um_perp) / COIN-M 永续 (cm_perp) / Options |
| 模块归属 | `module/binance`（ZoneCNH 主仓 spec + binance runtime 仓代码）         |
| 关联 ADR | [ADR-006](ADR-006-server-side-whitelist-rewrite.md)（重写裁决）        |
| 关联 ADR | [ADR-005](ADR-005-symbol-tier-classification.md)（Tier 分级，白名单准入依据） |

> **v0.1 → v0.2 变更摘要**：
> 1. 架构决策：演进现有 Catalog 为服务端白名单（**重写**，非叠加），见 ADR-006。
> 2. 模块归属：明确归入 `module/binance`，不新建独立 module。
> 3. 对齐现有实现：引用 FR-012~036、ADR-005，标注"已复用 / 需改造 / 新增"。
> 4. 补齐 version 语义与并发模型：`whitelist_meta` 单行表 + PG advisory lock + NATS 推送。
> 5. 术语澄清："客户端"统一改为"下游消费方"，与 binance adapter 区分。
> 6. 迁移至 `module/binance/design/`，进入 Spec→Code 管线。

---

## 1. 背景与目标

### 1.1 背景

业务需要持续跟踪币安在四类市场（现货、U 本位永续、币本位永续、期权）上线的全部交易对，作为下游行情采集、风控、产品展示等模块的"数据源之一"。但交易所侧全量交易对并不等于业务侧允许使用的交易对（可能存在下架币、低流动性币、合规排除币等），因此需要在"全量发现"之上叠加一层"白名单"，由服务端统一管理，下游消费方只消费、不直连交易所。

### 1.2 目标

- 定时、全量地发现币安四类市场当前挂牌的交易对/币种，并留存历史快照，落盘到 binance runtime 仓 `report/binance/` 便于审计和回溯。
- 建立服务端白名单机制：数据落库、有统一的生成/审核策略、通过内部 API 对外提供服务。
- 下游消费方（策略/行情/风控等下游服务）不直接调用交易所 API，而是从 binance server 拉取白名单，并本地缓存，缓存有效期 3 小时，到期自动刷新；同时通过 NATS 推送实现 version 变更近实时感知。

### 1.3 非目标（本期不做）

- 不涉及交易所下单/账户类接口的封装。
- 不涉及白名单审核工作流的前端界面（本期先支持配置化/规则化生成，人工审核界面留待后续迭代）。
- 不涉及除币安以外的其他交易所（架构预留扩展点，但本期只实现 Binance）。

---

## 2. 名词术语

| 术语                     | 说明                                                                             |
| ------------------------ | -------------------------------------------------------------------------------- |
| ExchangeInfo             | 交易所返回的"当前交易规则及交易对信息"接口，四类市场各有独立 endpoint            |
| spot                     | 现货                                                                             |
| um_perp                  | USDⓈ-M（U 本位）永续合约，对应币安 `fapi`                                        |
| cm_perp                  | COIN-M（币本位）永续合约，对应币安 `dapi`                                        |
| options                  | 欧式期权，对应币安 `eapi`                                                        |
| 全量发现 (Discovery)     | 定时拉取四类市场 ExchangeInfo，得到当前"交易所侧存在"的全部交易对                |
| 白名单 (Whitelist)       | 业务侧允许使用的交易对子集，由 Discovery 结果 + 规则/人工审核生成，存于服务端 DB |
| 采集清单                 | Discovery 每次运行产出的结构化清单文件，落盘于 binance runtime 仓 `report/binance/` |
| 下游消费方 (Consumer)    | 从 binance server 拉取白名单的下游服务（策略/行情/风控等），**不是** binance adapter 自身 |
| Catalog                  | binance adapter 进程内的交易对目录（`internal/client/catalog.go`），Discovery 层的核心数据结构 |
| Generation               | Catalog 的 diff 计数器（`Catalog.generation int64`，FR-032），候选层版本号       |
| Whitelist Version        | 白名单全局版本号（`whitelist_meta.current_version`），与 Generation 独立         |

---

## 3. 总体架构

```
                     ┌─────────────────────────────┐
                     │        Binance API           │
                     │ api / fapi / dapi / eapi      │
                     └───────────────┬───────────────┘
                                      │ ExchangeInfo (定时拉取)
                                      ▼
                     ┌─────────────────────────────┐
                     │  Discovery（binance-client） │  ← 已实现：FR-012/031/032/033
                     │  - 4 类市场并行采集           │     ADR-005 Tier 分级
                     │  - 落盘 report/binance/       │
                     │  - NATS 发布 catalog.diff     │  ← 已实现：catalog_publisher.go
                     └───────────────┬───────────────┘
                                      │ NATS binance.catalog.diff
                                      │ (queue group: binance-catalog-diff)
                                      ▼
                     ┌─────────────────────────────┐
                     │  catalogdiff.Subscriber      │  ← 已实现：subscriber.go
                     │  → PgCatalog.ApplyDiff       │     pg_catalog.go
                     │  → catalog_symbols 表 (PG)    │     migrations/001_catalog.sql
                     └───────────────┬───────────────┘
                                      │ 触发（事件 + 定时兜底）
                                      ▼
                     ┌─────────────────────────────┐
                     │  Whitelist Sync Job（新增）   │  ← 本设计新增
                     │  - 规则引擎 + 人工审核结果     │
                     │  - PG advisory lock 单写者    │
                     │  - 写 whitelist 表            │
                     │  - 递增 whitelist_meta.version │
                     │  - NATS 发布 whitelist.version │
                     └───────────────┬───────────────┘
                                      │
                                      ▼
                     ┌─────────────────────────────┐
                     │  Whitelist Service API       │  ← 本设计新增
                     │  GET /internal/whitelist      │     (binance-server Gin)
                     └───────────────┬───────────────┘
                                      │ HTTP（内网）
                     ┌────────────────┼────────────────┐
                     │ NATS push      │                 │
                     │ binance.whitelist.version       │
                     ▼                ▼                 ▼
              Consumer SDK A    Consumer SDK B    Consumer SDK N
            （本地缓存 3h TTL）  （本地缓存 3h TTL）  （本地缓存 3h TTL）
            （NATS 订阅 version 变更 → 提前刷新）
```

架构分三层，对应 binance 现有 client/server 拆分：

1. **Discovery 层**（binance-client）：只负责"从交易所把数据如实搬回来"，不做业务判断，产出快照文件 + 候选表（`catalog_symbols`）。**已实现，复用**。
2. **Whitelist 层**（binance-server 新增）：在候选数据之上叠加业务规则/审核，产出真正可用的白名单，是唯一的"业务决策点"。**本设计新增**。
3. **Consumer 层**：所有下游消费方通过统一 SDK/API 消费白名单，不直连交易所，也不越过服务端自行做全量发现。**本设计新增**。

---

## 4. 模块一：ExchangeInfo 全量发现（已实现，复用）

### 4.1 现有实现状态

| 能力 | FR | 状态 | 实现文件 | 复用方式 |
|------|----|----|----------|----------|
| spot ExchangeInfo decode/fetch | FR-031 | Done | `exchangeinfo.go` | 直接复用 |
| um_perp ExchangeInfo decode/fetch | FR-031 | Done | `exchangeinfo.go` | 直接复用 |
| cm_perp ExchangeInfo decode/fetch | FR-031 | Done | `exchangeinfo.go` | 直接复用 |
| options ExchangeInfo decode/fetch | FR-035/036 | Done | `exchangeinfo_option.go` | 直接复用 |
| 全量 sync | FR-031 | Done | `exchangeinfo_refresh.go` | 直接复用 |
| diff sync + generation | FR-032 | Done | `catalog.go` `generation int64` | 直接复用 |
| delist lifecycle (BREAK/HALT) | FR-033 | Done | `exchangeinfo.go` | 复用 + 扩展（§4.4） |
| catalog diff NATS 发布 | — | Done | `catalog_publisher.go` | 直接复用 |
| catalog diff NATS 订阅 | — | Done | `catalogdiff/subscriber.go` | 直接复用 |
| PG catalog_symbols 持久化 | FR-006b | Done | `pg_catalog.go` | 复用 + 扩展字段（§5.2.1） |
| symbol Tier 分级 | ADR-005 | Done | `catalog.go` `Tier/Collection` | 复用（Tier 作为白名单准入依据） |

### 4.2 数据源

| 市场    | Base URL                   | Endpoint                    | 参考权重(Weight)                  |
| ------- | -------------------------- | --------------------------- | --------------------------------- |
| spot    | `https://api.binance.com`  | `GET /api/v3/exchangeInfo`  | 20（参考值，以运行时探测为准）    |
| um_perp | `https://fapi.binance.com` | `GET /fapi/v1/exchangeInfo` | 1（参考值，以运行时探测为准）     |
| cm_perp | `https://dapi.binance.com` | `GET /dapi/v1/exchangeInfo` | 1（参考值，以运行时探测为准）     |
| options | `https://eapi.binance.com` | `GET /eapi/v1/exchangeInfo` | 1（参考值，以运行时探测为准）     |

> Weight 会随官方调整变化，Discovery 启动时应做一次"探测请求 + 校验响应头 `X-MBX-USED-WEIGHT-*`"的健康检查，不要硬编码权重去做限频假设。上表为参考值，非权威。

### 4.3 采集流程（已实现，无变更）

1. 定时任务触发（当前实现：ExchangeInfo refresh，建议频率 **每 15~30 分钟一次**，可配置）。
2. 四类市场并行请求，每类独立超时、独立重试（指数退避，最多 3 次），互不阻塞——某一市场失败不影响其他三类正常产出。
3. 对每类市场的返回结果做结构化解析，提取核心字段：`symbol` / `pair`、`baseAsset`、`quoteAsset`、`status`、`contractType`、上下架相关字段。
4. 与上一次快照做 Diff，得出「新增」「下架/状态变更」「无变化」三类结果。`Catalog.generation` 在 diff 非空时递增。
5. NATS 发布 `CatalogDiffMessage`（`binance.catalog.diff` subject），server 侧 `catalogdiff.Subscriber` 接收并 `ApplyDiff` 写入 `catalog_symbols`。
6. 落盘 `report/binance/` 快照文件（见 §4.5）。
7. 无论成功或失败都上报监控指标（见第 7 节）。

### 4.4 异常处理（复用 + 扩展）

- 网络/超时：指数退避重试；连续失败达到阈值后告警，但**不清空**候选表/白名单。**已实现，复用**。
- 限频（429/418）：读取响应头退避时间，暂停该市场本轮采集。**已实现，复用**。
- 响应字段变化：解析层宽松容错。**已实现，复用**。
- 交易对状态变为 `BREAK`/下架：标记状态而非物理删除（FR-033）。**已实现，复用**。
- **新增**：symbol 连续 N 次采集未出现（非状态变更，而是从列表消失）的确认机制——需连续 6 次（约覆盖 6 小时@15min 频率）都未再出现才确认下架，避免一次网络抖动误伤白名单（见 §9.3）。

### 4.5 落盘规范（`report/binance/`）

> **路径约定**：落盘在 binance runtime 仓 `/home/workspace/binance/report/binance/`，非 ZoneCNH 主仓。主仓是文档枢纽，不承载运行时产物。

```
report/binance/
├── spot/
│   └── 2026-07-05/
│       ├── exchange_info_raw.json        # 原始响应，供审计/排错
│       └── symbols.csv                   # 结构化清单
├── um_perp/
│   └── 2026-07-05/...
├── cm_perp/
│   └── 2026-07-05/...
├── options/
│   └── 2026-07-05/...
└── summary/
    └── 2026-07-05/
        ├── coin_universe.csv             # 四类市场去重后的币种全集
        └── diff_from_previous.csv        # 相对上一次快照的增减变化
```

- 按日分目录，文件名固定，便于下游脚本按日期拉取。
- `symbols.csv` 字段：`market_type, symbol, base_asset, quote_asset, status, contract_type, tier, collection, onboard_date, raw_extra(json)`。
- 原始响应保留原文，便于排查字段解析遗漏或响应格式变更。
- **双写一致性**：DB（`catalog_symbols`）为 SSOT，文件为审计投影。写盘顺序为 DB 写成功后再落盘文件；文件落盘失败仅告警，不回滚 DB。
- 保留策略：见 §9.6，明细快照热存储保留 30~90 天，超期归档至冷存储长期保留。

---

## 5. 模块二：白名单管理（新增）

### 5.1 为什么要有白名单这一层

Discovery 拿到的是"交易所侧存在"的全集，但业务侧真正想用的往往是子集（例如排除低流动性币、排除合规敏感标的、或者上线初期先小范围放量）。把"发现"和"业务决策"拆成两层，能保证：交易所数据的采集稳定可靠，同时业务规则可以独立灵活调整，互不影响。

现有 `buildSymbolWhitelist`（配置驱动）和 `SymbolBlacklist`（interface）是 client/server 各自的本地过滤，无统一 DB、无版本管理、无下游消费方 API。本设计将其升级为服务端 DB SSOT + NATS 推送。

### 5.2 数据模型（服务端 PostgreSQL）

#### 5.2.1 表 `catalog_symbols`（已有，扩展字段）

> 现有表定义见 `migrations/001_catalog.sql`。本设计新增 3 个字段以支持白名单层需求。

| 字段            | 类型     | 说明                               | 状态 |
| --------------- | -------- | ---------------------------------- | ---- |
| id              | bigint   | 主键（现有）                       | 已有 |
| symbol          | text     | 交易对/合约代码（现有）            | 已有 |
| product_line    | text     | spot / um_perp / cm_perp / options | 已有 |
| base_asset      | text     | 基础资产（现有）                   | 已有 |
| quote_asset     | text     | 计价资产（现有）                   | 已有 |
| status          | text     | active / delisted / suspended（现有） | 已有 |
| contract_type   | text     | 合约类型（现有，FR-035）           | 已有 |
| delivery_date   | bigint   | 交割日期（现有，FR-035）           | 已有 |
| strike          | float    | 期权行权价（现有，FR-036）         | 已有 |
| expiry          | bigint   | 期权到期日（现有，FR-036）         | 已有 |
| option_type     | text     | CALL/PUT（现有，FR-036）           | 已有 |
| discovered_at   | datetime | 首次发现时间（现有）               | 已有 |
| updated_at      | datetime | 最近更新时间（现有）               | 已有 |
| exchange_status | varchar  | 交易所原始状态（TRADING/BREAK/…）  | **新增** |
| first_seen_at   | datetime | 首次被发现时间（别名 discovered_at，显式命名） | **新增**（或复用 discovered_at） |
| last_seen_at    | datetime | 最近一次仍存在的时间               | **新增** |
| tier            | varchar  | ADR-005 分级结果（core/standard/…） | **新增**（从 CatalogEntry.Tier 同步） |
| collection      | varchar  | ADR-005 采集策略（full_stream/…）  | **新增**（从 CatalogEntry.Collection 同步） |
| raw_extra       | jsonb    | 冗余字段，便于追溯                 | **新增** |

> `catalog_symbols` 即候选表，不重命名（避免迁移成本）。`PgCatalog.ApplyDiff` 需扩展以写入新字段。

#### 5.2.2 表 `whitelist`（新增，对下游消费方生效的最终结果）

| 字段                 | 类型     | 说明                                               |
| -------------------- | -------- | -------------------------------------------------- |
| id                   | bigint   | 主键                                               |
| market_type          | varchar  | spot / um_perp / cm_perp / options                 |
| symbol               | varchar  | 交易对/合约代码                                    |
| base_asset           | varchar  | 基础资产（冗余自 catalog_symbols，避免下游二次查询） |
| quote_asset          | varchar  | 计价资产（冗余，同上）                             |
| exchange_status      | varchar  | 交易所侧状态（冗余，同上）                         |
| tier                 | varchar  | ADR-005 分级（冗余，同上）                         |
| enabled              | bool     | 是否对外生效                                       |
| source               | varchar  | auto（规则自动生成）/ manual（人工介入）           |
| last_change_version  | bigint   | 该 symbol 最后一次变更时的全局 whitelist version   |
| effective_at         | datetime | 生效时间                                           |
| updated_at           | datetime | 最近更新时间                                       |
| remark               | varchar  | 备注（如下架原因）                                 |

> **设计要点**：`base_asset` / `quote_asset` / `exchange_status` / `tier` 从 `catalog_symbols` 冗余到白名单表，避免下游消费方拉取白名单后还需二次查询候选表或交易所——违背"下游消费方不直连交易所"原则（v0.1 分析报告 §3.1 指出的缺口）。

#### 5.2.3 表 `whitelist_meta`（新增，全局 version SSOT）

| 字段              | 类型    | 说明                         |
| ----------------- | ------- | ---------------------------- |
| id                | int     | 固定为 1（单行表）           |
| current_version   | bigint  | 当前白名单全局版本号         |
| last_synced_at    | datetime | 最近一次同步时间            |

> **version 语义澄清**（v0.1 分析报告 §3.2 指出的缺口）：
> - `whitelist_meta.current_version` 是"当前生效的全局 version"，每次 Whitelist Sync Job 产出一批变更时原子递增。
> - `whitelist.last_change_version` 是"该 symbol 最后一次变更时的全局 version 快照"，用于单 symbol 粒度的变更追踪。
> - `whitelist_sync_log.version` 是历史记录，每次同步一行。
> - 三者关系：`whitelist_meta.current_version` = max(`whitelist_sync_log.version`) = max(`whitelist.last_change_version`)。

#### 5.2.4 表 `whitelist_sync_log`（新增，每次同步的差异记录，用于审计和回滚）

| 字段         | 类型     | 说明                   |
| ------------ | -------- | ---------------------- |
| id           | bigint   | 主键                   |
| version      | bigint   | 对应 whitelist_meta.current_version |
| added        | jsonb    | 本次新增 enabled 的 symbol 列表（从 false→true 或全新） |
| removed      | jsonb    | 本次从 true→false 的 symbol 列表（软删除，非物理删除） |
| updated      | jsonb    | 本次元数据变更（非 enabled 翻转）的 symbol 列表 |
| triggered_by | varchar  | job / manual           |
| created_at   | datetime | 同步时间               |

> **`removed` 语义澄清**（v0.1 分析报告 §3.3 指出的缺口）：`removed` 记录的是"本次 `enabled` 从 true→false 的 symbol"，即软删除事件。symbol 行仍在 `whitelist` 表中（`enabled=false`），不物理删除。下一轮同步时已 `enabled=false` 的 symbol 不再重复出现在 `removed` 中。

### 5.3 Version 语义与并发模型（新增）

#### 5.3.1 Version 单调性保证

Version 单调来源为 PostgreSQL 单行表 `whitelist_meta`。Whitelist Sync Job 在单个数据库事务内完成：

```sql
BEGIN;
  -- 1. 获取单写者锁（见 §5.3.2）
  SELECT pg_try_advisory_lock(...);

  -- 2. 原子递增 version
  UPDATE whitelist_meta
     SET current_version = current_version + 1,
         last_synced_at = now()
   WHERE id = 1
   RETURNING current_version;

  -- 3. 应用白名单变更（INSERT ... ON CONFLICT / UPDATE enabled / ...）
  -- 4. 写 whitelist_sync_log
  -- 5. 释放锁
  SELECT pg_advisory_unlock(...);
COMMIT;
```

- `RETURNING current_version` 保证本次同步拿到唯一递增的 version 号。
- 整个变更在单事务内，要么全部生效（version 递增 + whitelist 变更 + log 写入），要么全部回滚。
- **不使用分布式锁**：所有并发控制由 PostgreSQL 单库保证，无需 Redis lock 或 etcd。

#### 5.3.2 Sync Job 并发策略——PG Advisory Lock 单写者

- Whitelist Sync Job 使用 `pg_try_advisory_xact_lock(lock_id)` 保证同一时刻只有一个 Job 实例执行同步。
- 第二个实例尝试获取锁失败时直接退出（skip this round），不阻塞、不等待。
- 锁绑定到事务（`_xact_` 变体），事务结束自动释放，无需手动 unlock，避免锁泄漏。
- 这与 §5.5 的"下游消费方多实例无需锁"不冲突——后者是只读幂等拉取，前者是写入互斥。

#### 5.3.3 触发方式——事件驱动 + 定时兜底

- **事件驱动**：`catalogdiff.Subscriber.ApplyDiff` 成功后，发一个进程内事件触发 Whitelist Sync Job。
- **定时兜底**：独立定时任务每 30 分钟执行一次，防止事件丢失导致长期不同步。
- 两种触发均经过 advisory lock 互斥，重复触发安全（幂等 skip）。

### 5.4 白名单同步逻辑（新增）

#### 5.4.1 自动准入规则

建议分层处理，不做"全自动"或"全人工"的极端。准入依据复用 ADR-005 的 Tier 分级：

- **自动放行**：`exchange_status = TRADING` 且计价资产在主流白名单内（USDT/USDC/BTC/ETH，具体清单由业务定）且市场类型为 spot/um_perp/cm_perp 且 `Tier ∈ {core, standard}`（ADR-005 Tier 0-1）。
- **强制人工审核**：options 全部默认走审核；`Tier ∈ {long_tail, monitor}`（ADR-005 Tier 3-4）同样进审核队列；冷门 quote_asset、新合约类型进审核队列。
- **观察期**：即使命中自动放行规则，新 symbol 先进入"观察中"状态（如 3 天），期满后才真正 `enabled=true`，避免刚上线的极端行情/流动性问题波及下游。

#### 5.4.2 下架/摘牌处理（区分两类"消失"）

- **交易所明确返回状态变更**（如 `status=BREAK/HALT`，FR-033 已实现）→ 下一轮同步即可直接置 `enabled=false`，置信度高。
- **symbol 单纯从列表中消失**（可能是接口抖动/临时限流漏抓）→ 需连续 N 次采集（如连续 6 次、约覆盖 6 小时@15min 频率）都未再出现才确认下架，避免一次网络抖动误伤白名单。
- **观察期与下架窗口交叉时序**：若一个 symbol 上线第 2 天就从列表消失（观察期未满 3 天 + 下架窗口未满 6 次），裁决规则为：**下架窗口优先**——连续 6 次未出现即置 `enabled=false`，不论观察期是否期满。理由：交易所已下架的 symbol 不应留在白名单，观察期只防"上线初期异常行情"，不防"已下架"。

#### 5.4.3 同步流程

1. Sync Job 获取 advisory lock。
2. 读取 `catalog_symbols` 最新状态，与当前 `whitelist` 表做 Diff。
3. 按准入规则（§5.4.1）判断新增 symbol：自动放行 / 进审核队列。
4. 按下架规则（§5.4.2）判断移除 symbol：状态变更直接下架 / 连续 N 次未出现确认下架。
5. 单事务内：递增 `whitelist_meta.current_version`、更新 `whitelist` 表、写 `whitelist_sync_log`。
6. 事务提交后，NATS 发布 `binance.whitelist.version` 通知（§5.6）。

### 5.5 服务端 API（新增，binance-server Gin）

```
GET /internal/whitelist
Query 参数：
  market_type   可选，spot/um_perp/cm_perp/options，缺省返回全部
  since_version 可选，下游消费方本地版本号，用于增量返回

Response 200 (全量):
{
  "version": 10245,
  "generated_at": "2026-07-05T08:00:00Z",
  "full": true,
  "items": [
    {
      "market_type": "spot",
      "symbol": "BTCUSDT",
      "base_asset": "BTC",
      "quote_asset": "USDT",
      "exchange_status": "TRADING",
      "tier": "core",
      "enabled": true
    }
  ]
}

Response 200 (增量，since_version < current_version):
{
  "version": 10246,
  "generated_at": "2026-07-05T08:30:00Z",
  "full": false,
  "items": [
    { "market_type": "um_perp", "symbol": "ETHUSDT", ..., "enabled": true }
  ],
  "removed": [
    { "market_type": "spot", "symbol": "OLDCOINUSDT" }
  ]
}

Response 200 (无变化，since_version == current_version):
{
  "version": 10245,
  "generated_at": "2026-07-05T08:00:00Z",
  "full": false,
  "items": [],
  "removed": []
}
```

> **304 语义修正**（v0.1 分析报告 §5.3 指出的缺口）：不使用 HTTP 304（304 不带 body，下游消费方无法得知服务端当前 version）。统一使用 200 + `full:false, items:[], removed:[]` 携带 version，下游消费方据此判断"已是最新"。

```
POST /internal/whitelist/refresh     # 管理端手动触发一次同步（需要权限）
```

### 5.6 NATS 推送——version 变更通知（新增）

复用 binance 现有 NATS 连接（`catalog_publisher.go` 已有 `nats.Conn`），新增 subject：

```
Subject: binance.whitelist.version
Payload: { "version": 10246, "changed_at": "2026-07-05T08:30:00Z" }
传输: core NATS pub/sub（fire-and-forget，与 binance.catalog.diff 一致）
```

- **下游消费方订阅**：下游消费方 SDK 启动时订阅 `binance.whitelist.version`，收到 version 变更通知后立即触发一次增量刷新（带上本地 version），不必等 3 小时 TTL 到期。
- **可靠性**：core NATS 是 fire-and-forget，消息可能丢失。下游消费方仍有 3 小时定时刷新兜底，丢失推送只会导致最多 3 小时延迟，不会永久不一致。
- **不使用 JetStream**：与 `binance.catalog.diff` 一致，version 通知是 best-effort；JetStream 的持久化开销对"version 号变更通知"这种可由定时刷新补偿的场景不必要。

### 5.7 下游消费方获取与缓存策略（新增）

- **首次启动**：全量拉取一次 `GET /internal/whitelist`，写入本地缓存（内存 + 落盘，防止进程重启后有短暂空窗）。
- **定时刷新**：每 3 小时主动刷新一次；加入 ±10 分钟随机抖动，避免大量下游消费方在同一时刻集中请求服务端（惊群效应）。
- **NATS 驱动刷新**：订阅 `binance.whitelist.version`，收到通知后立即增量刷新，实现近实时感知（最坏延迟 = NATS 消息丢失后的 3h 定时兜底）。
- **增量优化**：刷新时带上本地 `version`，命中无变化时只需 200 + 空 items，减小网络和序列化开销。
- **容灾降级**：
  - 服务端不可达时，继续使用本地缓存，并记录缓存年龄（age）；
  - 分级容忍（§9.4）：缓存年龄 3h~24h 内继续用旧缓存并只上报监控；超过 24 小时触发高优先级告警，默认仍 fail open（沿用最后一次成功缓存）；
  - 不建议在服务端不可达时直接回退为"下游消费方直连交易所"，这会破坏"下游消费方不直连交易所"的架构约束。
- **多实例场景**：同一下游服务如果多实例部署，各实例可独立按自己的 3 小时周期刷新（幂等只读操作，无需分布式锁），NATS 订阅也是各实例独立接收。

---

## 6. 与现有实现的对齐矩阵

| 现有能力 | FR / ADR | 现状 | 本设计处理 | 复用/改造/新增 |
| -------- | -------- | ---- | ---------- | -------------- |
| ExchangeInfo 采集（四类市场） | FR-031 | Done | Discovery 层直接复用 | 复用 |
| diff sync + generation | FR-032 | Done | Discovery 层直接复用，generation 作为候选层版本号 | 复用 |
| delist lifecycle (BREAK/HALT) | FR-033 | Done | 复用状态变更处理；新增 N 次未出现确认机制 | 复用 + 扩展 |
| options metadata | FR-035/036 | Done | Discovery 层直接复用 | 复用 |
| catalog diff NATS 发布 | — | Done | Discovery→Server 通道复用 | 复用 |
| catalog diff NATS 订阅 | — | Done | Server 侧接收复用 | 复用 |
| PG catalog_symbols 持久化 | FR-006b | Done | 扩展字段（exchange_status/last_seen_at/tier/collection/raw_extra） | 改造 |
| whitelist/blacklist hot reload | FR-013 | Done | 降级为本地兜底过滤；DB SSOT 成为主路径 | 改造 |
| symbol Tier 分级 | ADR-005 | Done | Tier 作为白名单自动准入规则依据 | 复用 |
| Whitelist Sync Job | — | 不存在 | 新增 | 新增 |
| whitelist 表 + version | — | 不存在 | 新增 | 新增 |
| Whitelist Service API | — | 不存在 | 新增 | 新增 |
| NATS whitelist.version 推送 | — | 不存在 | 新增（复用 NATS 连接） | 新增 |
| Consumer SDK | — | 不存在 | 新增 | 新增 |
| report/binance/ 落盘 | — | 部分 | 规范化落盘路径与双写一致性 | 改造 |

---

## 7. 监控与告警

| 指标                         | 说明                                    | 建议告警阈值                                   |
| ---------------------------- | --------------------------------------- | ---------------------------------------------- |
| discovery_success_rate       | 四类市场采集成功率（现有）              | 单市场连续 3 次失败告警                        |
| discovery_latency            | 单次采集耗时（现有）                    | P99 超过阈值告警                               |
| catalogdiff_apply_lag        | catalog.diff 发布到 ApplyDiff 的延迟    | 超过 SLA 告警                                  |
| whitelist_symbol_count_delta | 白名单数量环比变化（新增）              | 单次变动超过 X% 告警（防止误删导致大面积断供） |
| whitelist_sync_lag           | candidate 产出到 whitelist 生效的时间差 | 超过 SLA 告警                                  |
| whitelist_version_monotonic  | version 是否单调递增（新增）            | version 回退立即告警                           |
| consumer_cache_age           | 下游消费方本地缓存年龄（新增）          | 超过最大容忍阈值告警                           |
| consumer_fetch_error_rate    | 下游消费方拉取服务端接口失败率（新增）  | 超过阈值告警                                   |
| nats_whitelist_version_drop  | NATS 推送丢失率（新增）                 | 连续 N 次 version 变更未收到推送告警           |

---

## 8. 安全与权限

- 白名单相关的写操作（人工审核通过、手动触发同步、直接改库）需要走管理端并留存操作审计日志（`audit_log` 表，`migrations/003_audit.sql` 已有），记录操作人、时间、before/after。
- 内部服务间调用（下游消费方 → Whitelist Service）建议走内网 + 服务间鉴权（如 mTLS 或内部签名 token），不对公网暴露。
- Discovery 使用公开 ExchangeInfo 接口，无需 API Key，但仍需注意 IP 限频，建议独立出口 IP 或走网关做统一限流保护。

---

## 9. 新增 FR 建议

| FR | 类别 | 内容 | 依赖 |
| -- | ---- | ---- | ---- |
| FR-045 | whitelist | Whitelist Sync Job（事件驱动 + 定时兜底 + PG advisory lock） | FR-032, FR-006b |
| FR-046 | whitelist | whitelist 表 + whitelist_meta version SSOT + whitelist_sync_log 审计 | FR-045 |
| FR-047 | API | GET /internal/whitelist（全量 + 增量，200 统一响应） | FR-046 |
| FR-048 | notify | NATS subject binance.whitelist.version 推送 | FR-046 |
| FR-049 | consumer | 下游消费方 SDK（缓存 3h TTL + NATS 订阅 + 增量刷新 + 容灾降级） | FR-047, FR-048 |
| FR-050 | catalog | catalog_symbols 扩展字段（exchange_status/last_seen_at/tier/collection/raw_extra） | FR-006b |

---

## 10. 里程碑建议

| 阶段 | 内容                                                            | 依赖 |
| ---- | --------------------------------------------------------------- | ---- |
| P0   | `catalog_symbols` 扩展字段 migration + ApplyDiff 改造           | 现有 FR-006b |
| P1   | `whitelist` / `whitelist_meta` / `whitelist_sync_log` 表 + Sync Job | P0 |
| P2   | Whitelist Service API（全量 + 增量）                            | P1 |
| P3   | NATS `binance.whitelist.version` 推送                           | P1 |
| P4   | 下游消费方 SDK：缓存、3h 定时刷新、NATS 订阅、容灾降级          | P2, P3 |
| P5   | 监控告警、管理端人工审核界面                                    | P4 |

---

## 11. 待确认事项（Open Questions）

以下为工程侧给出的建议默认值，供业务最终确认；确认后应回填到对应位置并去掉"待确认"标记。

### 11.1 Discovery 采集频率

**建议**：主流程每 **15~30 分钟**一次全量采集（ExchangeInfo 权重不高，spot weight 20 / 其余市场普遍 1，频率提高不会带来限频压力）。若业务对"新币上线秒级感知"有硬需求，再叠加一个 1~5 分钟级的轻量 symbol-diff 探测。与 ADR-005 Tier 体系不冲突——Tier 决定"怎么采"，频率决定"多久采一次"。

### 11.2 白名单自动准入规则

见 §5.4.1，Tier 阈值（core/standard 自动放行，long_tail/monitor 审核）需业务确认。

### 11.3 下架确认次数 N

**建议**：连续 6 次（约 6 小时@15min 频率）。需业务确认容忍度。

### 11.4 下游消费方缓存容灾降级

见 §5.7，fail open 为默认策略。强监管场景是否需要 fail closed？

### 11.5 主网/测试网隔离

**建议**采用物理隔离（独立服务实例 + 独立 DB/schema），而非在同一套库里用 `env` 字段区分。

### 11.6 `report/binance/` 保留与归档策略

**建议**分级存储：明细快照热存储保留 30~90 天，超期归档至冷存储（对象存储），长期保留 1 年。`summary/diff_from_previous.csv` 可直接长期留在热存储。

---

## 附录 A：DDL 示例（PostgreSQL 方言，新增表）

> 现有 `catalog_symbols` 表见 `migrations/001_catalog.sql`，以下仅列新增表与字段扩展。

```sql
-- migrations/011_whitelist.sql

-- 1. catalog_symbols 扩展字段
ALTER TABLE catalog_symbols
  ADD COLUMN IF NOT EXISTS exchange_status VARCHAR(16),
  ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS tier VARCHAR(16),
  ADD COLUMN IF NOT EXISTS collection VARCHAR(32),
  ADD COLUMN IF NOT EXISTS raw_extra JSONB;

-- 2. whitelist 表（对下游消费方生效的最终结果）
CREATE TABLE IF NOT EXISTS whitelist (
  id                  BIGSERIAL PRIMARY KEY,
  market_type         VARCHAR(16) NOT NULL,
  symbol              VARCHAR(32) NOT NULL,
  base_asset          VARCHAR(16),
  quote_asset         VARCHAR(16),
  exchange_status     VARCHAR(16),
  tier                VARCHAR(16),
  enabled             BOOLEAN NOT NULL DEFAULT TRUE,
  source              VARCHAR(16) NOT NULL DEFAULT 'auto',
  last_change_version BIGINT NOT NULL,
  effective_at        TIMESTAMPTZ NOT NULL,
  updated_at          TIMESTAMPTZ NOT NULL,
  remark              VARCHAR(255),
  UNIQUE KEY uk_market_symbol (market_type, symbol)
);

-- 3. whitelist_meta 单行表（全局 version SSOT）
CREATE TABLE IF NOT EXISTS whitelist_meta (
  id               INT PRIMARY KEY DEFAULT 1,
  current_version  BIGINT NOT NULL DEFAULT 0,
  last_synced_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT single_row CHECK (id = 1)
);
INSERT INTO whitelist_meta (id, current_version) VALUES (1, 0)
  ON CONFLICT (id) DO NOTHING;

-- 4. whitelist_sync_log 审计表
CREATE TABLE IF NOT EXISTS whitelist_sync_log (
  id           BIGSERIAL PRIMARY KEY,
  version      BIGINT NOT NULL,
  added        JSONB,
  removed      JSONB,
  updated      JSONB,
  triggered_by VARCHAR(16),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_wsl_version ON whitelist_sync_log (version);
CREATE INDEX IF NOT EXISTS idx_wsl_created ON whitelist_sync_log (created_at DESC);
```

## 附录 B：ADR-005 Tier 与白名单准入映射

| ADR-005 Tier | Tier 值 | 白名单准入 | 采集策略 |
|-------------|---------|-----------|----------|
| core | 0 | 自动放行（+观察期） | full_stream |
| standard | 1 | 自动放行（+观察期） | stream_no_depth / kline_only |
| sub_standard | 2 | 人工审核 | kline_only / rest_sample |
| long_tail | 3 | 人工审核 | rest_sample / rest_daily |
| monitor | 4 | 人工审核 | disabled |
