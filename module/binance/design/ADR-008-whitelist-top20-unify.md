# ADR-008：白名单策略统一为四类市场各 top 20

> 状态：Proposed
> 日期：2026-07-05
> 决策者：binance 模块架构
> 关联：ADR-005（§6.1 options 不进 Tier 模型，本 ADR 与其层间解耦）；ADR-006（服务端白名单重写，本 ADR 细化 FR-051）；`module/binance/spec/SPEC.md` FR-051；`module/binance/design/EXCHANGEINFO-WHITELIST-DESIGN.md` §5.4.1a
> 仓库归属：ZoneCNH 主仓 `module/binance/`

---

## 背景

ADR-006 落地后，白名单 Tier 分配策略（FR-051）实盘现状为 90 symbols：

- spot top 20 + um_perp(PERPETUAL) top 20 + um_perp(TRADIFI_PERPETUAL) top 50 = 90
- **cm_perp 无自动准入规则**，全部走人工审核，实盘 0 symbols
- **options 全部强制人工审核**（`rules.go:113-116` 硬编码 `if MarketType == "options" return DecisionNeedsReview`），实盘 0 symbols

四类市场的准入口径不一致：spot/um_perp 按流动性 top N 自动放行，cm_perp/options 完全人工。这导致：

1. cm_perp/options 长期无白名单覆盖，下游消费方无法从服务端获取这两类市场的业务允许子集（违反 BR-009 的"从服务端而非交易所直连获取"初衷）。
2. 币股 top 50 与其他市场 top 20 配额不统一，运维 SQL 分配脚本口径碎片化。
3. ADR-005 §6.1 明确 options 不进 Tier 流动性分级（按距到期+moneyness 分桶），被误读为"options 不能用 quoteVolume 做白名单准入"，混淆了"采不采"与"怎么采"两个正交决策。

## 决策

### D1：四类市场统一 top 20 准入

spot / um_perp(PERPETUAL) / um_perp(TRADIFI_PERPETUAL) / cm_perp / options **各取 24h quoteVolume 流动性 top 20**，统一分配 `tier=core`，自动放行（+观察期）。新白名单总量 = 20×5 = 100 symbols。

| 市场类型 | 配额 | tier | collection |
|----------|------|------|------------|
| spot | top 20 | core | full_stream |
| um_perp(PERPETUAL) | top 20 | core | full_stream |
| um_perp(TRADIFI_PERPETUAL) | top 20 | core | tradifi |
| cm_perp | top 20 | core | full_stream |
| options | top 20 | core | full_stream |

变化：cm_perp 新增自动准入；options 从全人工改自动 top 20；币股 top 50→top 20。

### D2：options 准入层与采集分桶层解耦

ADR-005 §6.1 的"options 不进 Tier 模型"语义保留，但限定作用域为**采集分桶层**：

| 层 | 决策问题 | 依据 | 文档 |
|----|----------|------|------|
| 白名单准入层 | 哪些 option contract 进入系统（采不采） | 24h quoteVolume top 20 | 本 ADR / FR-051 |
| 采集分桶层 | 进入后如何采样（怎么采） | 距到期天数 + moneyness | ADR-005 §6.1 |

两层正交，互不替代。白名单 top 20 决定"采不采"，options_classification 决定"怎么采"。

### D3：options top 20 粒度

按 **option contract 粒度**（如 `BTC-240105-50000-C`）的 24h quoteVolume 排序取 top 20，不按 underlying 聚合。预期 top 20 集中在 BTC/ETH 近月 ATM 合约（流动性最高）。这与中国语义下"流动性前 20"的直觉一致——即 20 个最活跃的合约，而非 20 个标的的全部合约链。

## 替代方案

### 方案 A：options 仍走人工审核（维持现状）

放弃 options 自动准入。问题：cm_perp/options 长期 0 覆盖，BR-009 的服务端白名单对这两类市场失效，下游仍需直连交易所或硬编码列表。与用户"四类市场各 top 20"诉求冲突。否决。

### 方案 B：options 按 underlying top 20（聚合）

按 underlying（BTC、ETH…）的 24h quoteVolume 排序取 top 20 标的，再纳入其全部合约。问题：单个标的（如 BTC）有数百个 contract，top 20 标的可能灌入数千 contract，远超"流动性前 20"的语义。否决。

### 方案 C：四类各 top 20 但 options 用距到期+moneyness 排序

options 准入用 ADR-005 §6.1 的分桶维度而非 quoteVolume。问题：与其他三类口径不统一，运维 SQL 需为 options 单独实现一套排序逻辑；且"近月 ATM"与"高 quoteVolume"高度相关，统一用 quoteVolume 简化且语义可接受。否决。

## 影响

| 影响面 | 说明 |
|--------|------|
| SPEC.md | FR-051 描述重写，Spec-Version v3.13.0 → v3.14.0 |
| 设计文档 | EXCHANGEINFO-WHITELIST-DESIGN.md §5.4.1/§5.4.1a 更新，版本 v0.3 → v0.4 |
| ADR-005 | §6.1 增补层间解耦说明，引用本 ADR |
| ADR-006 | 影响表新增"FR-051 统一"行 |
| Runtime rules.go | 移除 `if MarketType == "options" return DecisionNeedsReview` 硬编码，options 改按 tier 准入 |
| Runtime ListCandidates | 候选查询需支持按 quoteVolume 排序——当前 catalog_symbols 无 quoteVolume 列，需拉 ticker 24hr 数据写入或 JOIN |
| 运维 SQL | 分配脚本更新：cm_perp/options 新增 top 20、币股 50→20 |
| 数据源 | Binance exchangeInfo 不返回 24h quoteVolume，需额外拉 ticker 24hr 接口（spot/fapi/dapi/eapi 各一个） |
| 下架处理 | 币股 top 50→top 20 触发 ~30 个已 enabled symbol 置 enabled=false，走 §5.4.2 下架流程 |

## 风险

### R1 [HIGH] quoteVolume 数据源

exchangeInfo 接口不返回 24h quoteVolume，FR-051 当前实现是"运维 SQL 批量分配"（人工拉 ticker 后写 tier）。自动准入若要运行时化，需 SyncJob 拉 ticker 24hr。eapi ticker 是否提供 per-contract 24h quoteVolume 需实现前验证。本 ADR 允许运维 SQL 路径继续作为过渡实现。

### R2 [MED] options TRADING 过滤前置

ADR-005 §6.1 前置必修指出 `exchangeinfo_option.go` 不做 TRADING 过滤，所有未过期合约全灌入 catalog。options 启用 top 20 自动准入前必须先修此过滤，否则 top 20 计算混入无效合约。需在 runtime PR 中验证此前置已落地。

### R3 [LOW] 币股缩减的下架波及

币股 top 50→top 20 使 ~30 个 symbol 下架，下游消费者增量刷新需确认无副作用（version bump + removed 列表）。

## 验证

- 文档自洽：FR-051 描述在 SPEC.md / 设计文档 / TRACEABILITY 三处一致
- Runtime 单测：`rules.go` options + tier=core → DecisionAutoAdmit（非 DecisionNeedsReview）
- 实盘数据：白名单总量 100，cm_perp/options 各 20 行，version 递增

## 后续

- Runtime 仓 PR：rules.go / ListCandidates / 运维 SQL 落地（跨仓，引用本 ADR）
- options TRADING 过滤前置验证（R2）
- ticker 24hr 数据落盘 schema 设计（R1，若运行时自动化）
