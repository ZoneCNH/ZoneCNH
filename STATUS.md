# 📊 项目状态监控

> FoundationX 量化交易基础设施的实时健康度与风险追踪
>
> 数据来源：各 GitHub 仓库实际状态，定期更新
>
> 最后更新：2026-06-09
>
> 同步基线：`module/` 为模块规格库 SSOT，`docs/governance/` 为 Spec 治理 SSOT，`docs/goal/` 为 Goal 规则 SSOT，`specs/` 已移除。

---

## 总览仪表盘

```
组件总数: 70    已有: 54    已创建: 16    平均进度: 47%

进度分布:
  ███░ 80%  ████████████████████████░░░░░░░░░░░░░░░░  26 个 (38%)
  ██░░ 60%  ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   1 个 ( 1%)
  █░░░ 15%  ██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   6 个 ( 9%)
  ░░░░  5%  ██████████████░░░░░░░░░░░░░░░░░░░░░░░░░░  17 个 (25%)
  未标注    ████████████████████░░░░░░░░░░░░░░░░░░░░░░  20 个 (29%)

版本覆盖: 有版本号 18 个 (26%)    无版本号 52 个 (74%)
```text

### 按域统计

| 域                     | 总数   | 已有   | 已创建 | 平均进度 | 有版本号                                                  |
| ---------------------- | ------ | ------ | ------ | -------- | --------------------------------------------------------- |
| 基座                   | 16     | 16     | 0      | 54%      | 6 (kernel/configx/observex/testkitx/resiliencx/schedulex) |
| L2.5 领域共享层        | 4      | 4      | 0      | 80%      | 4 (全部)                                                  |
| 数据域 · 行情 SDK      | 14     | 14     | 0      | 80%      | 0                                                         |
| 数据域 · 行情 Provider | 5      | 5      | 0      | 80%      | 5 (全部)                                                  |
| 数据域 · 宏观          | 10     | 10     | 0      | 80%      | 0                                                         |
| 数据域 · 另类          | 1      | 0      | 1      | 5%       | 0                                                         |
| 分析域                 | 7      | 1      | 6      | 8%       | 1 (regime-engine)                                         |
| 决策域                 | 4      | 1      | 3      | 19%      | 0                                                         |
| 执行域                 | 4      | 0      | 4      | 5%       | 0                                                         |
| 入口                   | 1      | 1      | 0      | 80%      | 1 (x.go)                                                  |
| 横切                   | 2      | 1      | 1      | 43%      | 1 (observex)                                              |
| Rust                   | 1      | 1      | 0      | -        | 0                                                         |
| 独立                   | 1      | 1      | 0      | -        | 0                                                         |
| **合计**               | **70** | **54** | **16** | **47%**  | **18**                                                    |

---

## 域健康度

### 🟢 基座（健康）

- 组件：16 个，平均进度 54%
- 核心模块（kernel/configx/observex/resiliencx）已成熟（80%），有版本号
- 存储层 6/7 仅骨架（15%）：redisx/kafkax/postgresx/taosx/ossx/clickhousex
- **阻塞项**：存储层实现滞后，但不影响上层开发（可通过 contracts 稳定端口 mock）

### 🟢 L2.5 领域共享层（健康）

- 组件：4 个，全部 v0.1.0，进度 80%
- Phase 0 已完成，所有上层模块已依赖此层
- **无阻塞项**

### 🟢 数据域 · 行情（健康）

- SDK：14 个交易所适配器，全部 80%，无版本号
- Provider：5 个 Kline/Ticker Provider，全部 v0.1.0，进度 80%
- **待确认**：SDK 全部无版本号，是否已通过生产验证？

### 🟡 数据域 · 宏观（注意）

- 组件：10 个，全部 80%，无版本号
- 6 个央行数据源结构高度相似（fred/treasury/bea/ecb/uk-cb/japan-cb）
- **风险**：同质化严重，是否考虑合并为统一适配器？

### 🔴 数据域 · 另类（阻塞）

- 组件：1 个，仅创建（5%）
- **阻塞项**：链上数据、社交情绪、新闻 NLP 尚未开始实现

### 🔴 分析域（阻塞）

- 组件：7 个，6 个处于早期（5%），regime-engine 骨架完成（25%）
- **阻塞项**：factor-engine / feature-store / factor-eval / market_regime / macro_regime / ms_brain 均未实现到可用闭环
- **依赖**：需要数据域提供数据，L2.5 已就绪

### 🔴 决策域（阻塞）

- 核心组件 3 个仅创建（5%）：signal-factory / backtest-engine / optimizer
- strategies 已有（60%，3.5MB/746 项），但定位模糊
- **阻塞项**：依赖分析域产出因子

### 🔴 执行域（阻塞）

- 组件：4 个，全部仅创建（5%）
- **阻塞项**：依赖决策域产出信号

### 🟡 入口（注意）

- x.go 已有（80%，v0.0.1），但 2.8MB/33 项体量异常大
- **架构守卫**：x.go 应只承担组合根职责；需核实是否存在因子计算、信号判断、风控规则或订单路由
- **待确认**：入口主逻辑是否能收敛为配置加载、依赖 wiring 和生命周期控制

### 🟡 横切（注意）

- alertx 仅创建（5%），observex 已有（80%）
- observex 同属基座和横切，职责边界需明确

---

## 组件明细表

### 基座

| 组件                                                      | 版本   | 进度     | 仓库大小    | 说明                       |
| --------------------------------------------------------- | ------ | -------- | ----------- | -------------------------- |
| [kernel](https://github.com/ZoneCNH/kernel)               | v0.7.3 | ███░ 80% | 594KB/30 项 | 核心基础框架               |
| [configx](https://github.com/ZoneCNH/configx)             | v0.1.4 | ███░ 80% | 258KB/20 项 | 配置管理                   |
| [observex](https://github.com/ZoneCNH/observex)           | v0.3.1 | ███░ 80% | 220KB/18 项 | 可观测性                   |
| [testkitx](https://github.com/ZoneCNH/testkitx)           | v0.4.0 | ███░ 80% | 254KB/27 项 | 测试工具包                 |
| [resiliencx](https://github.com/ZoneCNH/resiliencx)       | v0.4.8 | ███░ 80% | 707KB/27 项 | 弹性与容错                 |
| [schedulex](https://github.com/ZoneCNH/schedulex)         | v0.1.2 | ███░ 80% | 398KB/25 项 | 调度任务                   |
| [xlibgate](https://github.com/ZoneCNH/xlibgate)           | -      | -        | -           | 门禁与验证运行时           |
| [xlib-standard](https://github.com/ZoneCNH/xlib-standard) | v1.0.0 | ████ 100% | 标准源 + Template + Generator + Gate + Evidence（16 FR，38 AC，34 TC，AC/TC→Code 闭合） | 标准事实源 / Go Reference Template / Generator / Harness Gate / Evidence Runtime |
| [redisx](https://github.com/ZoneCNH/redisx)               | -      | █░░░ 15% | -           | Redis，仅骨架              |
| [kafkax](https://github.com/ZoneCNH/kafkax)               | -      | █░░░ 15% | -           | Kafka，仅骨架              |
| [natsx](https://github.com/ZoneCNH/natsx)                 | -      | ███░ 80% | 349KB/27 项 | NATS                       |
| [postgresx](https://github.com/ZoneCNH/postgresx)         | -      | █░░░ 15% | -           | PostgreSQL，仅骨架         |
| [taosx](https://github.com/ZoneCNH/taosx)                 | -      | █░░░ 15% | -           | TDengine，仅骨架           |
| [ossx](https://github.com/ZoneCNH/ossx)                   | -      | █░░░ 15% | -           | 对象存储，仅骨架           |
| [clickhousex](https://github.com/ZoneCNH/clickhousex)     | -      | █░░░ 15% | -           | ClickHouse，仅骨架         |
| [contracts](https://github.com/ZoneCNH/contracts)         | -      | ███░ 80% | 191KB/27 项 | 跨域稳定端口/事件/DTO 契约 |

### L2.5 · 领域共享层

| 组件                                                          | 版本   | 进度     | 说明             |
| ------------------------------------------------------------- | ------ | -------- | ---------------- |
| [decimalx](https://github.com/ZoneCNH/decimalx)               | v0.1.0 | ███░ 80% | 高精度十进制类型 |
| [domain-market](https://github.com/ZoneCNH/domain-market)     | v0.1.0 | ███░ 80% | 市场数据域模型   |
| [domain-exchange](https://github.com/ZoneCNH/domain-exchange) | v0.1.0 | ███░ 80% | 交易域模型       |
| [domain-macro](https://github.com/ZoneCNH/domain-macro)       | v0.1.0 | ███░ 80% | 宏观数据域模型   |

### 数据域 · 行情

| 组件                                                          | 类型     | 版本   | 进度     | 说明                  |
| ------------------------------------------------------------- | -------- | ------ | -------- | --------------------- |
| [binance](https://github.com/ZoneCNH/binance)                 | SDK      | -      | ███░ 80% | Binance CEX           |
| [okx](https://github.com/ZoneCNH/okx)                         | SDK      | -      | ███░ 80% | OKX CEX               |
| [bybit](https://github.com/ZoneCNH/bybit)                     | SDK      | -      | ███░ 80% | Bybit CEX             |
| [bitget](https://github.com/ZoneCNH/bitget)                   | SDK      | -      | ███░ 80% | Bitget CEX            |
| [kucoin](https://github.com/ZoneCNH/kucoin)                   | SDK      | -      | ███░ 80% | KuCoin CEX            |
| [gate](https://github.com/ZoneCNH/gate)                       | SDK      | -      | ███░ 80% | Gate CEX              |
| [mexc](https://github.com/ZoneCNH/mexc)                       | SDK      | -      | ███░ 80% | MEXC CEX              |
| [htx](https://github.com/ZoneCNH/htx)                         | SDK      | -      | ███░ 80% | HTX CEX               |
| [coinbase](https://github.com/ZoneCNH/coinbase)               | SDK      | -      | ███░ 80% | Coinbase CEX          |
| [hyperliquid](https://github.com/ZoneCNH/hyperliquid)         | SDK      | -      | ███░ 80% | Hyperliquid DEX       |
| [lighter](https://github.com/ZoneCNH/lighter)                 | SDK      | -      | ███░ 80% | Lighter DEX           |
| [upbit](https://github.com/ZoneCNH/upbit)                     | SDK      | -      | ███░ 80% | Upbit CEX             |
| [coinglass](https://github.com/ZoneCNH/coinglass)             | SDK      | -      | ███░ 80% | 衍生品聚合数据        |
| [yield-curve](https://github.com/ZoneCNH/yield-curve)         | SDK      | -      | ███░ 80% | 收益率曲线            |
| [binance-market](https://github.com/ZoneCNH/binance-market)   | Provider | v0.1.0 | ███░ 80% | Binance Kline/Ticker  |
| [bybit-market](https://github.com/ZoneCNH/bybit-market)       | Provider | v0.1.0 | ███░ 80% | Bybit Kline/Ticker    |
| [bitget-market](https://github.com/ZoneCNH/bitget-market)     | Provider | v0.1.0 | ███░ 80% | Bitget Kline/Ticker   |
| [okx-market](https://github.com/ZoneCNH/okx-market)           | Provider | v0.1.0 | ███░ 80% | OKX Kline/Ticker      |
| [coinbase-market](https://github.com/ZoneCNH/coinbase-market) | Provider | v0.1.0 | ███░ 80% | Coinbase Kline/Ticker |

### 数据域 · 宏观

| 组件                                              | 版本 | 进度     | 说明           |
| ------------------------------------------------- | ---- | -------- | -------------- |
| [fred](https://github.com/ZoneCNH/fred)           | -    | ███░ 80% | 美联储 FRED    |
| [treasury](https://github.com/ZoneCNH/treasury)   | -    | ███░ 80% | 美国财政部     |
| [bea](https://github.com/ZoneCNH/bea)             | -    | ███░ 80% | 美国经济分析局 |
| [ecb](https://github.com/ZoneCNH/ecb)             | -    | ███░ 80% | 欧洲央行       |
| [uk-cb](https://github.com/ZoneCNH/uk-cb)         | -    | ███░ 80% | 英国央行       |
| [japan-cb](https://github.com/ZoneCNH/japan-cb)   | -    | ███░ 80% | 日本央行       |
| [eastmoney](https://github.com/ZoneCNH/eastmoney) | -    | ███░ 80% | 东方财富 A 股  |
| [jinshi](https://github.com/ZoneCNH/jinshi)       | -    | ███░ 80% | 金十快讯       |
| [jin10](https://github.com/ZoneCNH/jin10)         | -    | ███░ 80% | 金十行情       |
| [yahoo](https://github.com/ZoneCNH/yahoo)         | -    | ███░ 80% | Yahoo Finance  |

### 数据域 · 另类

| 组件                                                            | 版本 | 进度    | 说明                     |
| --------------------------------------------------------------- | ---- | ------- | ------------------------ |
| [alternative-data](https://github.com/ZoneCNH/alternative-data) | -    | ░░░░ 5% | 链上、社交情绪、新闻 NLP |

### 分析域

| 组件                                                      | 版本 | 进度    | 说明               |
| --------------------------------------------------------- | ---- | ------- | ------------------ |
| [factor-engine](https://github.com/ZoneCNH/factor-engine) | -    | ░░░░ 5% | 因子计算引擎       |
| [feature-store](https://github.com/ZoneCNH/feature-store) | -    | ░░░░ 5% | 特征存储与版本管理 |
| [factor-eval](https://github.com/ZoneCNH/factor-eval)     | -    | ░░░░ 5% | 因子评估           |
| [market_regime](https://github.com/ZoneCNH/market_regime) | -    | ░░░░ 5% | 市场状态识别       |
| [macro_regime](https://github.com/ZoneCNH/macro_regime)   | -    | ░░░░ 5% | 宏观经济体制识别（M1-M7）   |
| [ms_brain](https://github.com/ZoneCNH/ms_brain)           | -    | ░░░░ 5% | M×S 系统架构分析体系 |
| [regime-engine](https://github.com/ZoneCNH/regime-engine) | v0.1.0 | ██░░ 25% | M×S 联合决策引擎（M+S → action/risk/permission），骨架完成，30+ 测试通过 |

### 决策域

| 组件                                                          | 版本 | 进度     | 说明                           |
| ------------------------------------------------------------- | ---- | -------- | ------------------------------ |
| [signal-factory](https://github.com/ZoneCNH/signal-factory)   | -    | ░░░░ 5%  | 信号生成与组合                 |
| [backtest-engine](https://github.com/ZoneCNH/backtest-engine) | -    | ░░░░ 5%  | 事件驱动回测                   |
| [optimizer](https://github.com/ZoneCNH/optimizer)             | -    | ░░░░ 5%  | 参数优化                       |
| [strategies](https://github.com/ZoneCNH/strategies)           | -    | ██░░ 60% | 策略研究与参考库，3.5MB/746 项 |

### 执行域

| 组件                                                            | 版本 | 进度    | 说明         |
| --------------------------------------------------------------- | ---- | ------- | ------------ |
| [risk-engine](https://github.com/ZoneCNH/risk-engine)           | -    | ░░░░ 5% | 风险管理引擎 |
| [order-engine](https://github.com/ZoneCNH/order-engine)         | -    | ░░░░ 5% | 订单执行引擎 |
| [portfolio-engine](https://github.com/ZoneCNH/portfolio-engine) | -    | ░░░░ 5% | 投资组合管理 |
| [settlement](https://github.com/ZoneCNH/settlement)             | -    | ░░░░ 5% | 结算与对账   |

### 入口 · 横切 · Rust

| 组件                                              | 域   | 版本   | 进度     | 说明                     |
| ------------------------------------------------- | ---- | ------ | -------- | ------------------------ |
| [x.go](https://github.com/ZoneCNH/x.go)           | 入口 | v0.0.1 | ███░ 80% | 组合根，2.8MB/33 项      |
| [alertx](https://github.com/ZoneCNH/alertx)       | 横切 | -      | ░░░░ 5%  | 告警引擎                 |
| [observex](https://github.com/ZoneCNH/observex)   | 横切 | v0.3.1 | ███░ 80% | 可观测性（同时归属基座） |
| [stdlib.rs](https://github.com/ZoneCNH/stdlib.rs) | Rust | -      | -        | Rust 标准库              |
| [module](./module/README.md)                      | 独立 | -      | -        | 项目技术规范与接口定义   |

---

## 风险清单

### 🔴 高风险

| #   | 风险                                 | 影响             | 建议                         |
| --- | ------------------------------------ | ---------------- | ---------------------------- |
| R1  | 分析域/决策域/执行域核心链路低完成度（多数 5%） | 核心业务链路断裂 | 当前最高优先级，聚焦 Phase 1 |
| R2  | alternative-data 仅创建（5%）        | 另类数据能力缺失 | 可延后，不影响核心链路       |

### 🟡 中风险

| #   | 风险                                | 影响                     | 建议                                              |
| --- | ----------------------------------- | ------------------------ | ------------------------------------------------- |
| R3  | x.go 2.8MB 体量异常                 | 可能违反组合根边界       | 按 ARCHITECTURE.md 的组合根守卫核实，剥离业务逻辑 |
| R4  | 14 个交易所 SDK 全部无版本号        | 无法追踪 API 兼容性      | 建立版本化发布机制                                |
| R5  | 宏观数据源 6 个央行适配器同质化     | 维护成本高               | 考虑合并为统一适配器                              |
| R6  | strategies 定位模糊（3.5MB/746 项） | 参考代码 vs 生产代码不清 | 明确定位，考虑从状态表分离                        |
| R7  | observex 双重归属（基座+横切）      | 职责边界模糊             | 在代码层面严格界定                                |
| R10 | ~~`.omc/state/sessions` 已入库~~        | ~~可能泄露 prompt/会话/环境信息~~ | ✅ 已修复：`git rm -r --cached .omc`（2026-06-07）   |
| R11 | ~~公开 README 含 `127.0.0.1` 本地链接~~ | ~~外部无法访问，降低专业度~~     | ✅ 已修复：批量移除所有本地链接（2026-06-07）        |
| R12 | 70 个仓库无统一命名前缀             | 分类困难，增加维护成本       | 按 `foundation-*`/`adapter-*`/`engine-*`/`lab-*` 重整 |

### 🟢 低风险

| #   | 风险                        | 影响                  | 建议                                           |
| --- | --------------------------- | --------------------- | ---------------------------------------------- |
| R8  | 存储层 6/7 仅骨架（15%）    | 不阻塞上层开发        | 按需实现，contracts 稳定端口可 mock            |
| R9  | 分析域↔决策域若用实现包互调 | Go 循环导入和边界泄漏 | 只允许通过 contracts 事件/DTO 与 L2.5 模型连接 |

---

## 待办与阻塞

### 当前阻塞项

- [ ] Phase 1（分析域）未开始 → 阻塞 Phase 2/3/4/5
- [ ] x.go 体量待核实 → 按组合根守卫确认并剥离业务逻辑

### 下一步行动

1. **聚焦 Phase 1**：先固化 MarketDataProvider / FactorInput / FactorOutput，再实现 factor-engine → feature-store → factor-eval
2. **核实 x.go**：确认只包含配置加载、依赖 wiring 和生命周期控制，必要时剥离业务逻辑
3. **版本化 SDK**：为 14 个交易所 SDK 建立 tagged release
4. **统一宏观适配器**：评估 6 个央行数据源合并可行性
5. ~~**清理仓库卫生**（R10）~~：✅ 已完成（2026-06-07）
6. ~~**移除本地链接**（R11）~~：✅ 已完成（2026-06-07）
7. **重整仓库命名**（R12）：评估按 `foundation-*`/`adapter-*`/`engine-*`/`lab-*` 前缀重命名的可行性

---

## 文档同步检查

| 检查项           | README | ARCHITECTURE | STATUS                            | 一致性 |
| ---------------- | ------ | ------------ | --------------------------------- | ------ |
| 组件总数         | 70（按域视图） | 70           | 70                                | ✅     |
| market-data 数量 | 19     | 19 (14+5)    | 19 (14+5)                         | ✅     |
| macro-data 数量  | 10     | 10           | 10                                | ✅     |
| L2.5 组件        | 4      | 4            | 4                                 | ✅     |
| 分析域组件       | 7      | 7            | 7                                 | ✅     |
| 决策域组件       | 4      | 4            | 4                                 | ✅     |
| 横切组件         | 2      | 2            | 2                                 | ✅     |

注：README 按域视图计数，observex 同时归属基座与横切，因此与唯一仓库链接数不完全等价。

### 迁移与门禁基线

| 项目 | 当前状态 | 验证方式 |
| ---- | -------- | -------- |
| 规格库入口 | `module/` 承载 17 份模块与组合根规格；`docs/governance/` 承载治理模板、生命周期、追溯与评分规则 | 旧路径扫描、`spec-lint.sh`、治理路径扫描 |
| Goal 规则入口 | `docs/goal/` 定义交付规则；`.config/goal/` 承载运行状态 | `traceability-check.sh`、`task-spec-validate.sh` |
| 公开索引 | `README.md`、`ARCHITECTURE.md`、`STATUS.md` 区分 `module/` 与 `docs/governance/` 入口 | `status-consistency-check.sh`、治理路径扫描 |
| 漂移防护 | 不恢复旧 `specs/` 与 `module/governance` 路径，agent 与 CI 引用保持 `module/` + `docs/governance/` 口径 | 旧路径扫描、`spec-drift-guard.sh` |
