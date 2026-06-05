# 你好，我是 ZoneCNH 👋

**量化交易基础设施工程师** | 构建高性能、高可靠的金融数据与交易系统

## 🔧 技术栈

Go 🐹 (主要) · Rust 🦀 (底层) · Python 🐍 (脚本/数据) · TypeScript ⚡ (前端)

## 🏗️ 分层架构

> 📐 完整依赖拓扑、域间关系与子模块明细 → **[ARCHITECTURE.md](./ARCHITECTURE.md)**

```
基座: xlib-standard → kernel → configx/observex/testkitx/resiliencx/schedulex
                             → redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex
                             → contracts
      │
      ▼
数据域: market-data (19) / macro-data (10) / alternative-data
      │
      ▼
分析域: factor-engine ◄──► feature-store ◄──► factor-eval
      │
      ▼
决策域: signal-factory / backtest-engine / optimizer
      │
      ▼
执行域: risk-engine → order-engine → portfolio-engine / settlement
      │
      ▼
入口: x.go

横切: alertx (告警) / observex (可观测)
```

## 📦 核心项目

### 基座 · 基础设施

- [kernel](https://github.com/ZoneCNH/kernel) — 核心基础框架
- [configx](https://github.com/ZoneCNH/configx) — 配置管理模块
- [resiliencx](https://github.com/ZoneCNH/resiliencx) — 弹性与容错模块
- [observex](https://github.com/ZoneCNH/observex) — 可观测性模块
- [schedulex](https://github.com/ZoneCNH/schedulex) — 调度任务模块
- [testkitx](https://github.com/ZoneCNH/testkitx) — 测试工具包
- [xlib-standard](https://github.com/ZoneCNH/xlib-standard) — 基础库规范（基座的前置依赖）
- [xlibgate](https://github.com/ZoneCNH/xlibgate) — 门禁与验证运行时

### 基座 · 存储与中间件

- [postgresx](https://github.com/ZoneCNH/postgresx) — PostgreSQL 模块
- [redisx](https://github.com/ZoneCNH/redisx) — Redis 模块
- [clickhousex](https://github.com/ZoneCNH/clickhousex) — ClickHouse 模块
- [taosx](https://github.com/ZoneCNH/taosx) — TDengine 模块
- [kafkax](https://github.com/ZoneCNH/kafkax) — Kafka 模块
- [natsx](https://github.com/ZoneCNH/natsx) — NATS 内部通信模块
- [ossx](https://github.com/ZoneCNH/ossx) — 对象存储 (OSS) 模块

### 基座 · 契约层

- [contracts](https://github.com/ZoneCNH/contracts) — 跨模块接口与协议定义

### L2.5 · 领域共享层

- [decimalx](https://github.com/ZoneCNH/decimalx) — 高精度十进制类型（Decimal/Price/Qty/Ratio/Money）
- [domain-market](https://github.com/ZoneCNH/domain-market) — 市场数据域模型（Tick/Quote/Bar/OrderBook）
- [domain-exchange](https://github.com/ZoneCNH/domain-exchange) — 交易域模型（VenueAdapter 13 方法接口）
- [domain-macro](https://github.com/ZoneCNH/domain-macro) — 宏观数据域模型（MacroPoint/MacroState）

### 数据域 · market-data（SDK 14 + Provider 5）

**交易所 SDK：**
- [binance](https://github.com/ZoneCNH/binance) — 币安 Binance
- [okx](https://github.com/ZoneCNH/okx) — OKX
- [bybit](https://github.com/ZoneCNH/bybit) — Bybit
- [bitget](https://github.com/ZoneCNH/bitget) — Bitget
- [kucoin](https://github.com/ZoneCNH/kucoin) — KuCoin
- [gate](https://github.com/ZoneCNH/gate) — Gate.io
- [mexc](https://github.com/ZoneCNH/mexc) — MEXC
- [htx](https://github.com/ZoneCNH/htx) — HTX (火币)
- [coinbase](https://github.com/ZoneCNH/coinbase) — Coinbase
- [hyperliquid](https://github.com/ZoneCNH/hyperliquid) — Hyperliquid
- [lighter](https://github.com/ZoneCNH/lighter) — Lighter
- [upbit](https://github.com/ZoneCNH/upbit) — Upbit
- [coinglass](https://github.com/ZoneCNH/coinglass) — Coinglass 加密货币数据
- [yield-curve](https://github.com/ZoneCNH/yield-curve) — 收益率曲线

**Kline/Ticker Provider：**
- [binance-market](https://github.com/ZoneCNH/binance-market) — Binance
- [bybit-market](https://github.com/ZoneCNH/bybit-market) — Bybit
- [bitget-market](https://github.com/ZoneCNH/bitget-market) — Bitget SPOT
- [okx-market](https://github.com/ZoneCNH/okx-market) — OKX
- [coinbase-market](https://github.com/ZoneCNH/coinbase-market) — Coinbase

### 数据域 · macro-data

- [fred](https://github.com/ZoneCNH/fred) — 美联储经济数据 (FRED)
- [treasury](https://github.com/ZoneCNH/treasury) — 美国国债/财政数据
- [bea](https://github.com/ZoneCNH/bea) — 美国经济分析局 (BEA)
- [ecb](https://github.com/ZoneCNH/ecb) — 欧洲央行 (ECB)
- [uk-cb](https://github.com/ZoneCNH/uk-cb) — 英国央行
- [japan-cb](https://github.com/ZoneCNH/japan-cb) — 日本央行
- [eastmoney](https://github.com/ZoneCNH/eastmoney) — 东方财富
- [jinshi](https://github.com/ZoneCNH/jinshi) — 金十快讯
- [jin10](https://github.com/ZoneCNH/jin10) — 金十行情
- [yahoo](https://github.com/ZoneCNH/yahoo) — Yahoo Finance

### 数据域 · alternative-data

- [alternative-data](https://github.com/ZoneCNH/alternative-data) — 链上数据、社交情绪、新闻 NLP

### 分析域

- [factor-engine](https://github.com/ZoneCNH/factor-engine) — 因子计算引擎
- [feature-store](https://github.com/ZoneCNH/feature-store) — 特征存储与版本管理
- [factor-eval](https://github.com/ZoneCNH/factor-eval) — 因子评估

### 决策域

- [signal-factory](https://github.com/ZoneCNH/signal-factory) — 信号生成与组合
- [backtest-engine](https://github.com/ZoneCNH/backtest-engine) — 事件驱动回测引擎
- [optimizer](https://github.com/ZoneCNH/optimizer) — 参数优化
- [strategies](https://github.com/ZoneCNH/strategies) — 策略研究与信号参考

### 执行域

- [risk-engine](https://github.com/ZoneCNH/risk-engine) — 风险管理引擎
- [order-engine](https://github.com/ZoneCNH/order-engine) — 订单执行引擎
- [portfolio-engine](https://github.com/ZoneCNH/portfolio-engine) — 投资组合管理
- [settlement](https://github.com/ZoneCNH/settlement) — 结算与对账

### 横切 · 入口 · Rust

- [alertx](https://github.com/ZoneCNH/alertx) — 告警引擎
- [x.go](https://github.com/ZoneCNH/x.go) — 主程序，编排所有引擎
- [stdlib.rs](https://github.com/ZoneCNH/stdlib.rs) — Rust 标准库

## 📊 GitHub 统计

<p align="center">
  <img src="https://github-readme-stats.vercel.app/api?username=ZoneCNH&show_icons=true&theme=radical&hide_border=true" alt="GitHub 统计" />
</p>

---

<p align="center">
  <i>构建稳定可靠的量化基础设施 ⚡</i>
</p>
