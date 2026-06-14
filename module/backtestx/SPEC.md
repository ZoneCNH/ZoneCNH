# backtestx 完整规格

> 决策域 · 回测引擎。历史回放、策略评估、绩效指标、Walk-Forward 优化、蒙特卡洛模拟。

最后更新：2026-06-14

---

## 1. Metadata

- Status: Draft
- Spec-Version: v0.1.0
- Last-Updated: 2026-06-14
- Owner: ZoneCNH
- Layer: 决策域 · 回测引擎
- Version: v0.1.0-draft
- Repository: [github.com/ZoneCNH/backtestx](https://github.com/ZoneCNH/backtestx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期       | 版本         | 变更内容 | 作者    |
| ---------- | ------------ | -------- | ------- |
| 2026-06-14 | v0.1.0-draft | 初始版本 | ZoneCNH |
| 2026-06-14 | v0.1.0-draft | FR-008 Module Identity (README H1 + go.mod 校验) | ZoneCNH |

## 2. Summary

`backtestx` 是决策域的回测引擎，负责历史数据回放、策略模拟执行、绩效指标计算和 Walk-Forward 参数优化。回测与实盘共享因子、信号和风控代码（架构规则：同一段逻辑在回测和实盘中运行），确保回测结果可复现于实盘。

---

## 3. Problem

量化策略开发中的回测挑战：

- 回测框架与实盘代码分离，回测结果不可信
- 绩效指标口径不统一，难以横向比较策略
- 过拟合检测缺失，样本外表现与样本内偏差大
- 参数优化缺乏系统化方法（网格搜索效率低）
- 缺乏压力测试（极端行情、流动性枯竭场景）

---

## 4. Goals

- 事件驱动回测：按历史行情时间序列逐 tick/bar 驱动
- 与实盘共享代码：回测和实盘使用相同的因子、信号、风控模块
- 完整绩效指标：Sharpe、Sortino、Max Drawdown、Calmar、Win Rate、Profit Factor
- Walk-Forward 优化：滚动训练/测试窗口，防过拟合
- 蒙特卡洛模拟：随机打乱交易序列评估策略稳健性
- 压力测试：模拟极端行情场景（闪崩、流动性枯竭）

---

## 5. Non-goals

- 不做因子计算（→ factor-engine）
- 不做信号生成（→ strategyx）
- 不做实时数据采集（→ market-data）
- 不执行真实订单（纯模拟）
- 不做参数优化算法研究

---

## 6. Consumers

| 消费者       | 使用方式                              |
| ------------ | ------------------------------------- |
| strategyx    | 提交策略进行回测评估                 |
| factor-eval  | 消费回测结果评估因子有效性           |
| optimizer    | 使用回测结果进行参数优化             |
| maestro      | 编排 workflow 中触发批量回测         |

---

## 7. Functional Requirements

### FR-001: Event-Driven Simulation

WHEN 启动 Backtest(config, strategy, data)
THEN 按时间序列顺序回放历史数据（tick/bar）
AND 每个事件驱动 strategy.OnTick / strategy.OnBar 回调
AND 模拟 orderx 的订单执行（延迟 + 滑点 + 手续费）
AND 模拟 riskx 的风控检查
AND 通过 positionx 追踪虚拟仓位

### FR-002: Performance Metrics

WHEN 回测完成
THEN 计算以下指标：
  - Total Return, Annualized Return
  - Sharpe Ratio, Sortino Ratio
  - Max Drawdown, Max Drawdown Duration
  - Calmar Ratio
  - Win Rate, Profit Factor
  - Average Win / Average Loss
  - Number of Trades
AND 输出分年度/分月的绩效明细

### FR-003: Walk-Forward Optimization

WHEN 执行 WalkForward(config, strategy, paramSpace, data)
THEN 将历史数据分为多个训练/测试窗口
AND 每个窗口：在训练集上优化参数 → 在测试集上评估
AND 输出每个窗口的绩效指标和最优参数
AND 最终参数 = 各窗口最优参数的平均值

### FR-004: Monte Carlo Simulation

WHEN 执行 MonteCarlo(trades, iterations)
THEN 随机打乱交易序列（保留原始交易特征）
AND 每次迭代重新计算 Equity Curve 和绩效指标
AND 输出指标分布（mean, median, 5th/95th percentile）
AND 判断策略稳健性：MC 95% 置信区间不穿越零收益线

### FR-005: Stress Testing

WHEN 执行 StressTest(config, strategy, scenarios)
THEN 注入预定义的极端行情场景（闪崩 -30%、波动率 5x、流动性 0）
AND 评估策略在各场景下的最大亏损和恢复能力
AND 输出情景分析报告

### FR-006: Benchmark Comparison

WHEN 配置 Benchmark(symbol)
THEN 回测同时计算基准收益（如 BTC/USDT buy-and-hold）
AND 输出超额收益 (Alpha) 和 Beta

### FR-007: Slippage and Fee Model

WHEN 模拟订单成交
THEN 应用滑点模型：固定 + 比例（基于订单量与市场深度）
AND 应用手续费模型：maker/taker 费率按交易所配置
AND 支持自定义滑点和手续费函数

---

### FR-008: Module Identity

WHEN downstream consumer reads `backtestx` `README.md`
THEN the H1 heading MUST be `# backtestx`
AND MUST NOT be `# xlib-standard`

WHEN module documentation references the `backtestx` Go module path
THEN it MUST use `github.com/ZoneCNH/backtestx`
AND MUST NOT use `github.com/ZoneCNH/xlib-standard`

WHEN `go.mod` declares the module name
THEN it MUST be `module github.com/ZoneCNH/backtestx`



## 8. Business Rules

| 编号   | 规则                                   | 违反后果 |
| ------ | -------------------------------------- | -------- |
| BR-001 | 回测必须使用与实盘相同的因子/信号/风控代码 | 回测结果不可信 |
| BR-002 | 回测期间禁止访问实时行情和交易所 API   | 结果污染 |
| BR-003 | Walk-Forward 训练窗口和测试窗口不得重叠 | 过拟合 |
| BR-004 | 手续费和滑点必须在回测中模拟           | 结果过于乐观 |
| BR-005 | 至少输出 10 项绩效指标                 | 无法全面评估 |

---

## 9. Interface Contract

```go
type BacktestEngine interface {
    Run(ctx context.Context, config BacktestConfig, strategy Strategy, data DataFeed) (*BacktestResult, error)
    WalkForward(ctx context.Context, config WalkForwardConfig, strategyFactory StrategyFactory, paramSpace ParamSpace, data DataFeed) (*WalkForwardResult, error)
    MonteCarlo(ctx context.Context, trades []Trade, iterations int) (*MonteCarloResult, error)
    StressTest(ctx context.Context, config StressTestConfig, strategy Strategy, scenarios []Scenario, data DataFeed) (*StressTestResult, error)
}

type Strategy interface {
    OnTick(ctx context.Context, tick Tick, portfolio Portfolio) (*Signal, error)
    OnBar(ctx context.Context, bar Bar, portfolio Portfolio) (*Signal, error)
}

type DataFeed interface {
    Next(ctx context.Context) (Event, error)
    Reset()
}
```

---

## 10. Data Model

| 模型              | 字段 |
| ----------------- | ---- |
| BacktestConfig    | symbol, startDate, endDate, initialCapital, feeRate, slippageModel |
| BacktestResult    | totalReturn, annualReturn, sharpeRatio, sortinoRatio, maxDrawdown, calmarRatio, winRate, profitFactor, trades[], equityCurve[] |
| WalkForwardConfig | trainWindow, testWindow, stepSize, minTrainWindows |
| WalkForwardResult | windows[]{trainPeriod, testPeriod, bestParams, metrics} |
| MonteCarloResult  | meanReturn, medianReturn, p5Return, p95Return, sharpeDistribution[] |
| Trade             | timestamp, symbol, side, qty, price, fee, pnl |
| EquityCurve       | timestamps[], values[] |

---

## 11. Config Schema

```yaml
backtestx:
  default_fee_rate: 0.001      # 0.1%
  default_slippage: 0.0005     # 0.05%
  max_trades_per_backtest: 100000
  walk_forward:
    default_train_window: 365  # days
    default_test_window: 90
    default_step_size: 90
  monte_carlo:
    default_iterations: 1000
```

---

## 12. Error Handling

| 错误                  | 处理方式                       |
| --------------------- | ------------------------------ |
| 数据不足               | 拒绝启动，返回 DataInsufficient |
| 回测中 panic          | 捕获并记录，输出部分结果       |
| 参数空间为空           | 拒绝 Walk-Forward 启动         |
| 初始资金 ≤ 0          | 拒绝启动                       |

---

## 13. Edge Cases

| 场景                       | 预期行为                         |
| -------------------------- | -------------------------------- |
| 历史数据有缺口              | 跳过缺口，不生成信号              |
| 策略连续亏损导致资金不足    | 标记 bankrupt，停止交易           |
| 分红/拆股事件               | 调整历史价格和持仓数量            |
| 训练窗口数不足              | 拒绝 Walk-Forward                 |

---

## 14. Directory Structure

```text
backtestx/
├── go.mod
├── go.sum
├── README.md
├── engine.go          # BacktestEngine 实现
├── metrics.go         # 绩效指标计算
├── walkforward.go     # Walk-Forward 优化
├── montecarlo.go      # 蒙特卡洛模拟
├── stress.go          # 压力测试
├── slippage.go        # 滑点模型
├── fee.go             # 手续费模型
├── benchmark.go       # 基准比较
├── broker.go          # 模拟 broker
├── errors.go          # 错误定义
└── example_test.go
```

---

## 15. Dependencies

| 可以依赖                             | 禁止依赖                     |
| ------------------------------------ | ---------------------------- |
| kernel, configx, observex, contracts | 实时行情 API                |
| domainx (decimal)                    | 交易所 SDK                  |
| riskx (风控接口, 代码级复用)         |                             |
| positionx (仓位计算, 代码级复用)     |                             |
| orderx (订单模拟, 代码级复用)        |                             |

---

## 16. Testing

| 测试场景            | 验证点                           |
| ------------------- | -------------------------------- |
| 事件驱动回测         | tick/bar 按时间顺序正确驱动      |
| 绩效指标             | 手工计算验证所有指标             |
| Walk-Forward         | 窗口不重叠，参数收敛             |
| 蒙特卡洛             | 分布合理，置信区间有效           |
| 压力测试             | 极端场景下策略行为可预测         |

---

## 17. Performance Budget

| 操作                  | 目标       |
| --------------------- | ---------- |
| 1 年日线回测          | < 1s       |
| 1 年 1min K线回测     | < 30s      |
| Walk-Forward (5 窗口) | < 5 min    |
| Monte Carlo (1000 iter, 500 trades) | < 10s |

---

## 18. Observability

| 信号   | 指标                                  |
| ------ | ------------------------------------- |
| Metric | backtestx.progress.pct               |
| Metric | backtestx.result.sharpe              |
| Metric | backtestx.walkforward.window_count   |
| Log    | backtestx.start / .complete / .error  |

---

## 19. Security

| 要求               | 实现方式                         |
| ------------------ | -------------------------------- |
| 回测无真实交易     | 编译/运行时隔离，不链接交易所 SDK |
| 策略代码安全       | 沙箱执行（v1.2+）               |

---

## 20. CI Gate

| Gate   | 命令                               | 阻塞条件       |
| ------ | ---------------------------------- | -------------- |
| 编译   | `go build ./...`                   | 编译失败       |
| 测试   | `go test ./... -race -count=1`     | 测试失败       |
| 覆盖率 | `go test -coverprofile=...`        | < 80%          |

---

## 21. Upgrade Compatibility

| 变更类型             | 版本升级 |
| -------------------- | -------- |
| 新增绩效指标         | minor    |
| Strategy 接口变更    | major    |
| 新增模拟特性         | minor    |

---

## 22. Release DoD

- [ ] 事件驱动回测引擎完整实现
- [ ] 10+ 项绩效指标全部计算
- [ ] Walk-Forward 逻辑验证
- [ ] 蒙特卡洛模拟验证
- [ ] 滑点/手续费模型验证
- [ ] 覆盖率 ≥ 80%

---

## 23. Open Questions

- 是否支持多资产组合回测（basket backtest）？
- 是否需要支持 Tick 级回测（非 bar 级）？
- 是否接入实时行情做 paper trading？
