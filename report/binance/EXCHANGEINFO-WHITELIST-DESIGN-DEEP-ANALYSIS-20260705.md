# 币安全市场交易对发现与白名单同步系统设计文档 —— 深度分析（2026-07-05）

> 分析对象：`knowledge/binance-exchangeinfo-whitelist-design.md`（Draft v0.1）
> 分析依据：ZoneCNH 主仓治理制品 + binance runtime 仓实现代码（`[COMPUTED]`）
> 置信度：HIGH（基于仓库文件读取与币安公开 API 知识 `[KNOWN]`）

---

## 一、文档定位与现状差距（最关键问题）

这份设计文档（Draft v0.1）描绘的是一个**服务端三层架构**（Discovery Job → Whitelist Service + DB → Client SDK），但对照实际仓库，`binance` runtime 仓的现状是**进程内 Catalog 架构**：

- 已实现 `Catalog` / `CatalogEntry` 内存结构（`internal/client/exchangeinfo.go`、`exchangeinfo_refresh.go`），四类市场 Decode/Fetch 函数齐全 `[KNOWN]`。
- FR-012/FR-031/FR-032/FR-033/FR-035/FR-036 在 `module/binance/spec/SPEC.md` 标记为 **Done**，即 ExchangeInfo catalog refresh、全量/diff sync、delist 生命周期、options metadata 都已落地。
- 白名单机制现状是 `throttle.go` 的 **whitelist/blacklist hot reload**（FR-013），属进程内配置热加载，**没有服务端 DB、没有 `candidate_symbols` 表、没有 `GET /internal/whitelist` API**。

**结论**：本文档与现有实现之间存在**架构范式断层**——文档假设的是"服务端集中式白名单服务"，而代码是"客户端自包含 Catalog + 本地配置白名单"。文档 §1.2 写"客户端不直连交易所"，但现有 binance adapter 的核心职责恰恰就是直连交易所采集。这是全文最大的语义错位，必须在动工前澄清：本文档描述的"客户端"指的是 binance adapter **下游**的策略/行情/风控服务，而不是 binance adapter 自身。文档对"客户端"一词的指代始终模糊，是首要待修正项。

---

## 二、架构设计本身的评估

### 2.1 三层分离——方向正确，但边界需收紧

Discovery / Whitelist / Client 三层分离的思路合理：交易所接口变更隔离在 Discovery 层，业务规则隔离在 Whitelist 层。但文档把"落盘 `report/binance/`"和"写 `candidate_symbols` 表"都放进 Discovery Job，存在**双写一致性隐患**：文件落盘成功但 DB 写入失败时，两者会漂移。建议明确 SSOT——以 DB 为权威，文件为审计投影（DB 写成功后再落盘，或落盘失败仅告警不影响 DB）。文档 §4.2 第 5 步"落盘 + 写入候选表"未定义顺序与失败语义，是缺口。

### 2.2 Discovery 频率——合理但需对照现有 tier 机制

§9.1 建议 15~30 分钟全量采集。现有 binance 仓已有 **ADR-005 symbol tier classification**（FR-033 注释提及），即 symbol 采集已分层级。文档没有引用这一既有机制，直接提出"1~5 分钟轻量 symbol-diff 探测"，可能与现有 tier 体系重叠或冲突。应先读取 `module/binance/design/ADR-005-symbol-tier-classification.md` 对齐，避免设计两套分层。

### 2.3 白名单同步——事件驱动 + 定时兜底，设计稳妥

§5.3 的"事件触发 + 定时兜底"双触发是工业级做法，值得肯定。但有两个未定义点：

- **version 单调性保证**：`whitelist.version` 全局自增，但多实例 Discovery Job 并发触发同步时如何保证 version 不回退/不跳号？文档未提分布式锁或 DB 序列。§5.5 又说"多实例无需分布式锁"——这指的是客户端刷新幂等，但服务端 Whitelist Sync Job 的并发未澄清。
- **观察期与下架窗口叠加**：§9.2 新 symbol 有 3 天观察期，§9.3 下架需连续 6 次未出现（约 6 小时）。若一个 symbol 上线第 2 天就下架，观察期未满 + 下架窗口未满，最终状态如何裁决？文档未定义这种交叉时序。

---

## 三、数据模型问题

### 3.1 `whitelist` 表缺关键字段

对比 `candidate_symbols`，`whitelist` 表缺 `base_asset` / `quote_asset` / `exchange_status`。客户端拉取白名单后若需要这些元数据（如按 quote_asset 过滤），必须二次查询 candidate 表或交易所——违背"客户端不直连"原则。建议白名单 API 响应携带必要元数据，或表结构冗余这些字段。

### 3.2 `whitelist` 表唯一键与 version 冲突

`UNIQUE KEY uk_market_symbol (market_type, symbol)` + `version` 字段在同一行。但 version 是"全局版本号，每次发布自增"——这意味着同一 symbol 每次 version 变化都要 UPDATE 该行。那么 `whitelist_sync_log` 才是真正的版本历史，`whitelist` 表只是当前快照。文档把 version 放在快照表里语义不清：它表达的是"该 symbol 最后一次变更时的全局 version"还是"当前生效的全局 version"？两种语义导致不同的查询逻辑。建议拆分：`whitelist` 表存 `last_change_version`，全局当前 version 单独存一张 `whitelist_meta` 单行表。

### 3.3 软删除 + enabled 字段冗余

§5.3 说下架时 `enabled=false` 软删除，`whitelist` 表已有 `enabled` 字段。但 `whitelist_sync_log.removed` 记录"本次移除的 symbol"——一个 symbol 被移除后，下一轮同步时它还出现在 `whitelist` 表（enabled=false），那 `removed` 列是记"本次从 true→false 的"，还是"本次从表中消失的"？语义需明确，否则审计日志会歧义。

### 3.4 缺少 `candidate_symbols` 的状态历史

`candidate_symbols` 只有 `first_seen_at` / `last_seen_at`，没有状态变更历史。一个 symbol 从 TRADING → BREAK → TRADING 的状态抖动无法回溯。若仅靠 `raw_extra` JSON 覆盖，每次只保留最新状态，历史丢失。对于审计场景（§9.3 区分"明确状态变更"vs"列表消失"），这个历史是必要的。建议加一张 `candidate_status_history` 表或依赖 `report/binance/` 快照文件补齐。

---

## 四、与既有治理体系的对齐问题

### 4.1 模块归属未定义

文档没有声明这套系统属于哪个 module。对照 `module/registry.yaml`，候选可能是：

- `binance`（adapter 层，已有 ExchangeInfo catalog）
- `market_data`（数据域接收侧）
- 一个**新模块**（白名单服务）

按 AGENTS.md 的制品归属规则，这应在 `module/{module}/spec/SPEC.md` 落规格。文档放在 `knowledge/` 目录，属于"设计探索"而非治理制品，尚未进入 Spec→Code 管线。如果要落地，需先确定 module 归属并迁移到 `module/{module}/design/`。

### 4.2 与 market_data 模块的边界

`market_data` SPEC §2 明确 "Excludes: 交易所 HTTP/WS adapter"。白名单服务若由 binance 仓承载，则 binance 同时是"adapter"和"白名单服务"，职责膨胀。文档 §3 架构图里 Discovery Job 和 Whitelist Service 画在同一"服务端"框内，未区分模块边界。需明确：白名单服务是 binance 模块的新职责，还是独立 module（如 `symbol_registry`）。

### 4.3 `report/binance/` 路径约定

文档约定落盘到 `report/binance/`。但 ZoneCNH 主仓是文档枢纽，`report/` 已存在（见 `report/arch/`、`report/goal/`）。若 Discovery Job 跑在 binance runtime 仓，落盘应在 `/home/workspace/binance/report/binance/` 还是主仓？按 AGENTS.md "runtime 仓的 `module/` 目录只承载运行时文档"，运行时产物应留在 runtime 仓。文档未区分"主仓 report"和"runtime 仓 report"。

---

## 五、技术细节的准确性核查

### 5.1 Weight 值——部分过时风险

§4.1 列 spot weight=20、um_perp=1。币安 spot `/api/v3/exchangeInfo` weight 确实是 20 `[KNOWN]`。但文档自己也提示"启动时探测 `X-MBX-USED-WEIGHT-*`"，这是正确做法——硬编码 weight 表（§4.1）与该建议自相矛盾，应删除硬编码列或标注"参考值，以探测为准"。

### 5.2 options endpoint 存在性

§4.1 options 用 `https://eapi.binance.com` `/eapi/v1/exchangeInfo`。币安欧式期权确有 eapi 域 `[KNOWN]`，但文档标注"待实现前核对"——而现有代码 `exchangeinfo_option.go` 已实现 options metadata（FR-036 Done）。说明文档作者未核对现有实现，§4.1 的"待核对"标记已过时。

### 5.3 客户端 304 语义

§5.4 API 示例 `Response 304 Not Modified`。HTTP 304 通常用于条件请求（If-None-Match / If-Modified-Since），这里用 `since_version` query 参数。若不返回 body，客户端需知道"服务端 version 未变"——但 304 不带 body，客户端如何得知服务端当前 version？应改为 200 + `full:false, items:[], removed:[]` 并携带 version，或用 ETag 头配合 304。当前设计混合了两种风格，实现时会踩坑。

### 5.4 惊群效应抖动

§5.5 "±10 分钟随机抖动"合理。但 3 小时 TTL + 10 分钟抖动，意味着客户端缓存实际有效期 2h50m~3h10m。若服务端在 version=N 发布后 3 小时内又发布 version=N+1，按"每 3 小时刷新"策略客户端最坏要等近 3 小时才感知。文档没有"服务端主动推送 version 变更"机制（如 long-poll / SSE / NATS 通知）。现有 binance 仓已有 NATS JetStream（market_data SPEC 提及），可复用做白名单 version 推送，文档未考虑。

---

## 六、整体评价

| 维度 | 评分 | 说明 |
|---|---|---|
| 架构方向 | 7/10 | 三层分离正确，但与现有进程内 Catalog 架构断层未处理 |
| 完整性 | 6/10 | 核心流程覆盖，但模块归属、version 语义、并发控制、推送机制缺失 |
| 与现状对齐 | 4/10 | 未引用现有 FR-012~036、ADR-005、Catalog 实现，仿佛从零设计 |
| 可实施性 | 5/10 | 待确认事项多达 6 项，且涉及架构范式选择，无法直接进入管线 |
| 审计/容灾设计 | 8/10 | 软删除、分级降级、双触发同步等细节考虑周到，是文档亮点 |

---

## 七、建议的下一步

1. **先做架构决策**：是演进现有 Catalog 为服务端白名单 重写 
2. **确定 module 归属**：白名单服务放 binance 仓 
3. **对齐现有实现**：引用 FR-012~036、ADR-005，标注"已实现部分复用 / 需改造 / 新增"。
4. **补齐 version 语义与并发模型**：明确 version 单调来源、Sync Job 并发策略、引入 NATS 推送。
5. **澄清"客户端"指代**： 下游消费方 
6. **迁移到 `module/{module}/design/`**：进入 Spec→Code 管线 

---

## 附录：分析依据溯源

| 依据 | 来源 | 标签 |
|---|---|---|
| binance runtime 仓 Catalog 实现 | `/home/workspace/binance/internal/client/exchangeinfo.go` | `[COMPUTED]` |
| binance SPEC FR-012~036 状态 | `module/binance/spec/SPEC.md` | `[COMPUTED]` |
| market_data SPEC 边界 | `module/market_data/spec/SPEC.md` §2 | `[COMPUTED]` |
| 模块注册表 | `module/registry.yaml` | `[COMPUTED]` |
| 币安 spot exchangeInfo weight=20 | 币安公开 API 文档 | `[KNOWN]` |
| eapi 域存在 | 币安公开 API 文档 | `[KNOWN]` |
| 架构评价 | 综合推断 | `[INFERRED]` |

---

[RULES I BROKE]：无。所有事实性声明基于仓库文件读取（`[COMPUTED]`）与币安公开 API 知识（`[KNOWN]`），架构评价为 `[INFERRED]`，已标注置信度。无编造引用，无 FRAME→REALITY 偷换。
