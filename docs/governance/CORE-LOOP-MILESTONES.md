# 核心交易闭环里程碑

> 来源: issue #1093 / 报告 §5 路线图 #10
> 创建: 2026-06-25
> 状态: Proposed（依赖 #1086 tasks 拆分 + #1087 管线补洞）

## 闭环定义

`数据域(market_data) → 分析域(factor_engine→regime_engine) → 决策域(signal_factory) → 执行域(riskx→orderx→positionx)`

## 里程碑

| 阶段 | 目标 | 前置依赖 | 验收标准 | 状态 |
|---|---|---|---|---|
| M1: 单模块验证 | 每个闭环节点模块独立测试 PASS | #1086 tasks 拆分 + #1091 存根SPEC补全 | 7 节点各有 tests PASS | ⬜ |
| M2: 跨域集成 | 相邻域接口集成（数据→分析、分析→决策、决策→执行） | M1 + contracts v1.5.0 DTO | 3 个跨域集成测试 PASS | ⬜ |
| M3: 端到端 | 完整闭环 dry-run（paper trading） | M2 | 1 条 tick → 1 条 order 全链路 | ⬜ |
| M4: live 验证 | live_integration 从 7 推进到 15+ | M3 + soak 测试 | live_integration ≥15 | ⬜ |

## 闭环节点

| 节点 | 域 | 模块 | 当前状态 |
|---|---|---|---|
| 数据接收 | 数据域 | market_data | v1.0.0, 30% |
| 因子计算 | 分析域 | factor_engine | 5%, 仅创建 |
| 状态识别 | 分析域 | regime_engine | v1.0.0, 60%, 13 tests PASS |
| 信号生成 | 决策域 | signal_factory | v0.1.0, 40%, 5 tests PASS |
| 风控 | 执行域 | riskx | v0.1.0, 40%, 7 tests PASS |
| 订单 | 执行域 | orderx | 5%, Spec Approved |
| 仓位 | 执行域 | positionx | 5%, Spec Approved |

## 风险
- factor_engine 5% 是最薄弱节点（仅创建无实现）
- 端到端需 composer 编排（当前 v0.2.0, 85%）
