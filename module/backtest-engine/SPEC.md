# backtest_engine 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 决策域 · 回测引擎
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `../factor_engine/`, `../domain_market/`

> 本文档发布 backtest_engine 基线。运行时实现为 Pending。

---

## 1. 摘要

backtest_engine 是决策域的事件驱动回测引擎，消费 signal_factory 信号执行历史回测。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 事件驱动回测循环、滑点/手续费模型、绩效指标（Sharpe/MaxDD/Calmar）、回测报告 |
| Depends on | signal_factory（交易信号）、feature_store（PIT 特征）、domain_market |
| Consumed by | optimizer（参数优化）、策略研发（回测分析） |
| Excludes | 见上下游模块职责边界 |

## 3. 功能需求

### FR-001: 回测循环

WHEN WHEN 启动回测
THEN 按时间顺序重放 MarketEventEnvelope 并记录信号→订单→成交→PnL

### FR-002: 滑点模型

WHEN WHEN 模拟成交
THEN 应用配置的滑点模型（固定/比例/OB-based）

### FR-003: 绩效报告

WHEN WHEN 回测完成
THEN 输出 BacktestReport{Sharpe, MaxDD, Calmar, AnnualReturn, WinRate, AvgTrade}


## 4. 接口契约

```go
type BacktestEngine interface {
    Run(ctx context.Context, config BacktestConfig) (BacktestReport, error)
}
type BacktestReport struct {
    SharpeRatio   float64
    MaxDrawdown   float64
    CalmarRatio   float64
    AnnualReturn  float64
    WinRate       float64
    TotalTrades   int
    EquityCurve   []float64
}

```

## 5. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed，非法数据拒绝处理 |
| BR-002 | 输出数据结构不可变，下游只读消费 |
| BR-003 | 计算不得依赖未来数据（no lookahead） |

## 6. CI 门禁

| Gate | 命令 |
| --- | --- |
| 编译 | `go build ./...` |
| 测试 | `go test ./... -race -count=1` |
| 覆盖率 | `go test -coverprofile=...` (≥80%) |

## 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始基线 | ZoneCNH |
