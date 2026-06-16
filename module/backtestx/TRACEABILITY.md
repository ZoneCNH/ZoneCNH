# backtestx 需求追溯矩阵

> 更新：2026-06-16
> 来源：module/backtestx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## §1 功能需求追溯（FR）

| FR | Description | WHEN | THEN | AC | TC | Task | Status |
|----|-------------|------|------|----|----|------|--------|
| FR-001 | Event-Driven Simulation | 启动 Backtest(config, strategy, data) | 按时间序列顺序回放历史数据（tick/bar）；每个事件驱动 strategy.OnTick/OnBar；模拟 orderx 订单执行（延迟+滑点+手续费）；模拟 riskx 风控；通过 positionx 追踪虚拟仓位 | AC-BTX-001 | TC-BTX-001 | - | 🔲 |
| FR-002 | Performance Metrics | 回测完成 | 计算 Total/Annualized Return、Sharpe、Sortino、MaxDD/Duration、Calmar、WinRate、ProfitFactor、AvgWin/AvgLoss、TradeCount；输出分年/分月绩效明细 | AC-BTX-002 | TC-BTX-002 | - | 🔲 |
| FR-003 | Walk-Forward Optimization | 执行 WalkForward(config, strategy, paramSpace, data) | 将历史数据分为多个训练/测试窗口；每个窗口训练集优化参数→测试集评估；最终参数=各窗口最优参数平均值 | AC-BTX-003 | TC-BTX-003 | - | 🔲 |
| FR-004 | Monte Carlo Simulation | 执行 MonteCarlo(trades, iterations) | 随机打乱交易序列；每次迭代重新计算 Equity Curve 和绩效指标；输出指标分布（mean/median/5th/95th percentile）；MC 95% 置信区间不穿越零收益线时判定稳健 | AC-BTX-004 | TC-BTX-004 | - | 🔲 |
| FR-005 | Stress Testing | 执行 StressTest(config, strategy, scenarios) | 注入极端行情场景（闪崩-30%、波动率5x、流动性0）；评估最大亏损和恢复能力；输出情景分析报告 | AC-BTX-005 | TC-BTX-005 | - | 🔲 |
| FR-006 | Benchmark Comparison | 配置 Benchmark(symbol) | 同时计算基准收益（BTC/USDT buy-and-hold）；输出超额收益 Alpha 和 Beta | AC-BTX-006 | TC-BTX-006 | - | 🔲 |
| FR-007 | Slippage and Fee Model | 模拟订单成交 | 应用滑点模型（固定+比例，基于订单量与市场深度）；应用手续费模型（maker/taker 费率）；支持自定义函数 | AC-BTX-007 | TC-BTX-007 | - | 🔲 |
| FR-008 | Module Identity | downstream consumer 读取 README.md | H1 为 `# backtestx`；Go module path 为 `github.com/ZoneCNH/backtestx`；go.mod 声明 `module github.com/ZoneCNH/backtestx` | AC-BTX-008 | TC-BTX-008 | - | 🔲 |

---


| BR | Rule | 违反后果 | TC ID(s) | Task | Status |
|----|------|----------|---------------------|------|--------|
| BR-001 | 回测必须使用与实盘相同的因子/信号/风控代码 | 回测结果不可信 | TC-BTX-001 共享代码路径断言 | - | 🔲 |
| BR-002 | 回测期间禁止访问实时行情和交易所 API | 结果污染 | TC-BTX-009 CI gate：回测模块无交易所 SDK import | - | 🔲 |
| BR-003 | Walk-Forward 训练窗口和测试窗口不得重叠 | 过拟合 | TC-BTX-003 窗口不重叠断言 | - | 🔲 |
| BR-004 | 手续费和滑点必须在回测中模拟 | 结果过于乐观 | TC-BTX-007 滑点+手续费应用验证 | - | 🔲 |
| BR-005 | 至少输出 10 项绩效指标 | 无法全面评估 | TC-BTX-002 指标数量断言 | - | 🔲 |

---

## §3 非功能需求追溯（NFR）

| NFR | Category | Requirement | Verification | Task | Status |
|-----|----------|-------------|--------------|------|--------|
| NFR-001 | 性能 | 1 年日线回测 < 1s | Benchmark `BenchmarkDailyBacktest` | - | 🔲 |
| NFR-002 | 性能 | 1 年 1min K线回测 < 30s | Benchmark `BenchmarkMinuteBacktest` | - | 🔲 |
| NFR-003 | 性能 | Walk-Forward（5 窗口）< 5 min | Benchmark `BenchmarkWalkForward` | - | 🔲 |
| NFR-004 | 性能 | Monte Carlo（1000 iter, 500 trades）< 10s | Benchmark `BenchmarkMonteCarlo` | - | 🔲 |
| NFR-005 | 质量 | 测试覆盖率 >= 80% | `go tool cover -func` | - | 🔲 |
| NFR-006 | 安全 | 无硬编码密钥 | `gitleaks detect --no-git` | - | 🔲 |

---

## §4 TC → FR 反向追溯

| TC | Covers FR(s) | Scenario | Command |
|----|-------------|----------|---------|
| TC-BTX-001 | FR-001, BR-001 | 按时间序列回放历史数据；事件驱动 OnTick/OnBar；模拟订单执行+风控+仓位追踪；共享代码路径 | `go test ./... -run TestEventDriven` |
| TC-BTX-002 | FR-002, BR-005 | 回测完成后计算全部 10 项指标；输出分年/分月绩效明细 | `go test ./... -run TestPerformanceMetrics` |
| TC-BTX-003 | FR-003, BR-003 | WalkForward 分训练/测试窗口；窗口不重叠；最终参数为各窗口平均值 | `go test ./... -run TestWalkForward` |
| TC-BTX-004 | FR-004 | MonteCarlo 随机打乱交易序列；输出 mean/median/p5/p95 分布；MC 95% 置信区间判断稳健 | `go test ./... -run TestMonteCarlo` |
| TC-BTX-005 | FR-005 | StressTest 注入极端场景（闪崩/波动率5x/流动性0）；输出最大亏损和恢复能力报告 | `go test ./... -run TestStressTesting` |
| TC-BTX-006 | FR-006 | Benchmark 同时计算基准收益；输出 Alpha 和 Beta | `go test ./... -run TestBenchmark` |
| TC-BTX-007 | FR-007, BR-004 | 滑点模型（固定+比例）和手续费模型（maker/taker）正确应用；支持自定义函数 | `go test ./... -run TestSlippageFee` |
| TC-BTX-008 | FR-008 | README H1 为 `# backtestx`；go.mod 声明 `module github.com/ZoneCNH/backtestx` | `go test ./... -run TestModuleIdentity` |
| TC-BTX-009 | BR-002 | CI gate：回测模块无交易所 SDK import | `go build ./...` + dependency check |

---

## §5 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 | Verification |
|----|-----------|-------------|--------------|
| AC-BTX-001 | FR-001 | 回测按时间序列顺序回放；事件驱动 OnTick/OnBar；模拟订单执行+风控+仓位追踪 | TC-BTX-001 |
| AC-BTX-002 | FR-002 | 计算全部 10 项指标；输出分年/分月绩效明细 | TC-BTX-002 |
| AC-BTX-003 | FR-003 | WalkForward 训练/测试窗口；窗口不重叠；最终参数为各窗口最优参数平均值 | TC-BTX-003 |
| AC-BTX-004 | FR-004 | MonteCarlo 随机打乱；输出 mean/median/p5/p95 分布；MC 95% 置信区间判断稳健 | TC-BTX-004 |
| AC-BTX-005 | FR-005 | StressTest 注入极端场景；输出最大亏损和恢复能力情景报告 | TC-BTX-005 |
| AC-BTX-006 | FR-006 | Benchmark 同时计算基准收益；输出 Alpha 和 Beta | TC-BTX-006 |
| AC-BTX-007 | FR-007 | 滑点模型（固定+比例）+手续费模型（maker/taker）正确应用；支持自定义 | TC-BTX-007 |
| AC-BTX-008 | FR-008 | README H1 为 `# backtestx`；go.mod 声明 `module github.com/ZoneCNH/backtestx` | TC-BTX-008 |

---

## §6 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 8 | FR-001 ~ FR-008 |
| FR 有 AC 覆盖 | 8/8 (100%) | |
| FR 有 TC 覆盖 | 8/8 (100%) | |
| BR 总数 | 5 | BR-001 ~ BR-005 |
| BR 有验证机制 | 5/5 (100%) | |
| NFR 总数 | 6 | NFR-001 ~ NFR-006 |
| AC 总数 | 8 | AC-BTX-001 ~ AC-BTX-008 |
| TC 总数 | 9 | TC-BTX-001 ~ TC-BTX-009 |

---

## §7 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-16 | v1.1 | 标准化为 §1-§7 结构；FR 表增加 WHEN/THEN 列；TC 表增加 Command 列；AC 表增加 Verification 列 |
| 2026-06-15 | v1.0 | 初始版本：8 FR + 5 BR + 6 NFR + 9 TC + 8 AC |
