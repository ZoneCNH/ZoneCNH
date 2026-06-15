# backtestx 需求追溯矩阵

> 更新：2026-06-15
> 来源：module/backtestx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | Event-Driven Simulation：按时间序列回放历史数据，驱动 strategy.OnTick/OnBar，模拟订单执行、风控检查和仓位追踪 | AC-BTX-001 | TC-BTX-001 | - | 🔲 |
| FR-002 | Performance Metrics：计算 10+ 项绩效指标（Return/Sharpe/Sortino/MaxDD/Calmar/WinRate/ProfitFactor/AvgWinLoss/TradeCount），输出分年/分月明细 | AC-BTX-002 | TC-BTX-002 | - | 🔲 |
| FR-003 | Walk-Forward Optimization：训练/测试窗口滚动优化，最终参数为各窗口最优参数平均值 | AC-BTX-003 | TC-BTX-003 | - | 🔲 |
| FR-004 | Monte Carlo Simulation：随机打乱交易序列，输出指标分布和稳健性判断 | AC-BTX-004 | TC-BTX-004 | - | 🔲 |
| FR-005 | Stress Testing：注入极端行情场景，评估最大亏损和恢复能力 | AC-BTX-005 | TC-BTX-005 | - | 🔲 |
| FR-006 | Benchmark Comparison：同时计算基准收益，输出 Alpha 和 Beta | AC-BTX-006 | TC-BTX-006 | - | 🔲 |
| FR-007 | Slippage and Fee Model：固定+比例滑点模型、maker/taker 手续费模型，支持自定义 | AC-BTX-007 | TC-BTX-007 | - | 🔲 |
| FR-008 | Module Identity：README H1 为 `# backtestx`；Go module path 为 `github.com/ZoneCNH/backtestx` | AC-BTX-008 | TC-BTX-008 | - | 🔲 |

---

## 2. 业务规则追溯（BR）

| BR | Description | 违反后果 | 验证方式 | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | 回测必须使用与实盘相同的因子/信号/风控代码 | 回测结果不可信 | TC-BTX-001 共享代码路径断言 | - | 🔲 |
| BR-002 | 回测期间禁止访问实时行情和交易所 API | 结果污染 | TC-BTX-009 CI gate：回测模块无交易所 SDK import | - | 🔲 |
| BR-003 | Walk-Forward 训练窗口和测试窗口不得重叠 | 过拟合 | TC-BTX-003 窗口不重叠断言 | - | 🔲 |
| BR-004 | 手续费和滑点必须在回测中模拟 | 结果过于乐观 | TC-BTX-007 滑点+手续费应用验证 | - | 🔲 |
| BR-005 | 至少输出 10 项绩效指标 | 无法全面评估 | TC-BTX-002 指标数量断言 | - | 🔲 |

---

## 3. 非功能需求追溯（NFR）

| NFR | Description | 目标值 | 验证方式 | Task | Status |
|-----|-------------|--------|----------|------|--------|
| NFR-001 | 1 年日线回测性能 | < 1s | Benchmark | - | 🔲 |
| NFR-002 | 1 年 1min K线回测性能 | < 30s | Benchmark | - | 🔲 |
| NFR-003 | Walk-Forward (5 窗口) 性能 | < 5 min | Benchmark | - | 🔲 |
| NFR-004 | Monte Carlo (1000 iter, 500 trades) 性能 | < 10s | Benchmark | - | 🔲 |
| NFR-005 | 测试覆盖率 | >= 80% | `go tool cover -func` | - | 🔲 |
| NFR-006 | 无硬编码密钥 | 全仓扫描零命中 | `gitleaks detect --no-git` | - | 🔲 |

---

## 4. TC → FR 反向追溯

| TC | FR/BR | Given/When/Then 场景 |
|----|-------|---------------------|
| TC-BTX-001 | FR-001, BR-001 | 按时间序列回放历史数据；事件驱动 OnTick/OnBar；模拟订单执行+风控+仓位追踪；使用共享代码路径 |
| TC-BTX-002 | FR-002, BR-005 | 回测完成后计算全部 10 项指标；输出分年/分月绩效明细 |
| TC-BTX-003 | FR-003, BR-003 | WalkForward 分训练/测试窗口；窗口不重叠；最终参数为各窗口平均值 |
| TC-BTX-004 | FR-004 | MonteCarlo 随机打乱交易序列；输出 mean/median/p5/p95 分布；MC 95% 置信区间判断稳健 |
| TC-BTX-005 | FR-005 | StressTest 注入极端场景（闪崩/波动率5x/流动性0）；输出最大亏损和恢复能力报告 |
| TC-BTX-006 | FR-006 | Benchmark 同时计算基准收益；输出 Alpha 和 Beta |
| TC-BTX-007 | FR-007, BR-004 | 滑点模型（固定+比例）和手续费模型（maker/taker）正确应用；支持自定义函数 |
| TC-BTX-008 | FR-008 | README H1 为 `# backtestx`；go.mod 声明 `module github.com/ZoneCNH/backtestx` |
| TC-BTX-009 | BR-002 | CI gate：回测模块无交易所 SDK import |

---

## 5. 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 |
|----|-----------|-------------|
| AC-BTX-001 | FR-001 | 回测按时间序列顺序回放；事件驱动 OnTick/OnBar；模拟订单执行+风控+仓位追踪 |
| AC-BTX-002 | FR-002 | 计算全部 10 项指标；输出分年/分月绩效明细 |
| AC-BTX-003 | FR-003 | WalkForward 训练/测试窗口；窗口不重叠；最终参数为各窗口最优参数平均值 |
| AC-BTX-004 | FR-004 | MonteCarlo 随机打乱；输出 mean/median/p5/p95 分布；MC 95% 置信区间判断稳健 |
| AC-BTX-005 | FR-005 | StressTest 注入极端场景；输出最大亏损和恢复能力情景报告 |
| AC-BTX-006 | FR-006 | Benchmark 同时计算基准收益；输出 Alpha 和 Beta |
| AC-BTX-007 | FR-007 | 滑点模型（固定+比例）+手续费模型（maker/taker）正确应用；支持自定义 |
| AC-BTX-008 | FR-008 | README H1 为 `# backtestx`；go.mod 声明 `module github.com/ZoneCNH/backtestx` |

---

## 6. 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 8 | FR-001 ~ FR-008 |
| FR 有 AC 覆盖 | 8/8 (100%) | |
| FR 有 TC 覆盖 | 8/8 (100%) | |
| BR 总数 | 5 | BR-001 ~ BR-005 |
| BR 有 TC 覆盖 | 5/5 (100%) | |
| NFR 总数 | 6 | NFR-001 ~ NFR-006 |
| AC 总数 | 8 | AC-BTX-001 ~ AC-BTX-008 |
| TC 总数 | 9 | TC-BTX-001 ~ TC-BTX-009 |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-15 | v1.0 | 初始版本：8 FR + 5 BR + 6 NFR + 9 TC + 8 AC |
