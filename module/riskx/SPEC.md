# riskx 完整规格

> 执行域 · 风控引擎。事前风控检查、仓位限额、回撤控制、熔断机制、风险指标计算。

最后更新：2026-06-14

---

## 1. Metadata

- Status: Draft
- Spec-Version: v0.1.0
- Last-Updated: 2026-06-14
- Owner: ZoneCNH
- Layer: 执行域 · 风控引擎
- Version: v0.1.0-draft
- Repository: [github.com/ZoneCNH/riskx](https://github.com/ZoneCNH/riskx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期       | 版本         | 变更内容 | 作者    |
| ---------- | ------------ | -------- | ------- |
| 2026-06-14 | v0.1.0-draft | 初始版本 | ZoneCNH |

## 2. Summary

`riskx` 是执行域的风控引擎，负责对所有订单进行事前风控检查、执行仓位限额控制、监控回撤和触发熔断。它是订单进入交易所前的最后一道门禁，架构规则明确：策略只能通过 riskx 提交订单。

---

## 3. Problem

量化交易中的风控挑战：

- 风控规则散落在各策略和订单代码中，无统一执行点
- 事前风控缺失，错误订单直接到达交易所
- 回撤检测滞后，无法在实盘中实时止损
- 多策略共享账户时无仓位限额协调
- 缺乏熔断机制，异常行情下持续亏损

---

## 4. Goals

- 统一风控门禁：所有订单必须通过 riskx 检查
- 事前风控：下单前检查仓位限额、单笔限额、频率限制
- 实时风控：监控回撤、波动率、集中度
- 熔断机制：触发条件时暂停交易
- 风险报告：定时输出风险指标（VaR, Sharpe, maxDrawdown）

---

## 5. Non-goals

- 不做仓位管理（→ positionx）
- 不做订单执行（→ orderx）
- 不做策略决策（→ strategyx）
- 不做交易所风控配置（交易所自有风控独立）
- 不做合规监管报告

---

## 6. Consumers

| 消费者       | 使用方式                              |
| ------------ | ------------------------------------- |
| orderx       | 下单前调用 checkOrder 进行风控检查    |
| positionx    | 提供仓位数据供风控计算               |
| strategyx    | 接收风控拒绝通知以调整策略            |
| observex     | 消费风控事件用于告警                 |
| maestro      | 编排 workflow 中插入风控节点         |

---

## 7. Functional Requirements

### FR-001: Pre-Trade Risk Check

WHEN orderx 调用 CheckOrder(ctx, order, position)
THEN 依次检查以下规则（短路求值，首个失败即拒绝）：
  AND order.qty * price ≤ maxOrderValue
  AND position.netQty + order.qty ≤ maxPositionSize
  AND account.dailyOrders + 1 ≤ maxDailyOrders
  AND account.dailyVolume + order.qty * price ≤ maxDailyVolume
  AND symbol 不在禁止交易列表中

### FR-002: Drawdown Control

WHEN 账户回撤（从峰值到当前净值的百分比）超过 maxDrawdown
THEN 拒绝所有该账户的新订单
AND emit drawdown_circuit_breaker 事件
AND 恢复条件：回撤降至 maxDrawdown * 0.5 以下（滞后阈值）

### FR-003: Kill Switch

WHEN 管理员发出 KillSwitch(account)
THEN 立即取消该账户所有挂单（通过 orderx CancelAll）
AND 拒绝该账户所有新订单
AND 状态持久化（重启后仍生效）
WHEN 管理员发出 Resume(account)
THEN 恢复该账户的下单能力

### FR-004: Rate Limiting

WHEN 单账户订单频率超过 maxOrderRate（orders/sec）
THEN 拒绝超出部分并返回 RATE_LIMITED 错误
AND 使用滑动窗口计数

### FR-005: Concentration Control

WHEN 单 symbol 仓位占总仓位比例超过 maxConcentration
THEN 拒绝该 symbol 的新增仓位
AND 减仓不受此限制

### FR-006: Risk Metrics

WHEN 定时计算风险指标
THEN 输出 Value-at-Risk (95%, 99%)、Sharpe Ratio、Max Drawdown、Calmar Ratio、Volatility (annualized)
AND 计算周期可配置（默认 5 min）

### FR-007: Risk Event Audit

WHEN 风控检查通过（PASS）或被拒绝（REJECT）
THEN 记录审计事件：timestamp, account, symbol, side, qty, price, result, reason, rule_id
AND 审计事件不可删除

---

## 8. Business Rules

| 编号   | 规则                                   | 违反后果 |
| ------ | -------------------------------------- | -------- |
| BR-001 | 所有订单必须通过 riskx 检查后才能提交交易所 | orderx 拒绝下单 |
| BR-002 | KillSwitch 状态必须持久化              | 重启后恢复风控状态 |
| BR-003 | 回撤熔断有滞后恢复阈值（0.5×maxDrawdown） | 避免反复触发 |
| BR-004 | 风控规则优先级：KillSwitch > Drawdown > PositionLimit > RateLimit | 保证最关键规则先执行 |
| BR-005 | 减仓不受集中度限制                     | 风控不阻止降风险操作 |

---

## 9. Interface Contract

```go
type RiskEngine interface {
    CheckOrder(ctx context.Context, order Order, position Position) (*RiskResult, error)
    CheckAccount(ctx context.Context, account string) (*AccountRiskStatus, error)
    KillSwitch(ctx context.Context, account string, reason string) error
    Resume(ctx context.Context, account string) error
    GetMetrics(ctx context.Context, account string) (*RiskMetrics, error)
}

type RiskResult struct {
    Allowed   bool
    Reason    string
    RuleID    string
    Timestamp time.Time
}

type RiskMetrics struct {
    VaR95       decimal.Decimal
    VaR99       decimal.Decimal
    SharpeRatio decimal.Decimal
    MaxDrawdown decimal.Decimal
    Volatility  decimal.Decimal
}
```

---

## 10. Data Model

| 模型              | 字段 |
| ----------------- | ---- |
| RiskRule          | id, name, type(POSITION/ORDER/RATE/DRAWDOWN/CONCENTRATION), threshold, enabled |
| RiskResult        | allowed:bool, reason, ruleID, timestamp |
| AccountRiskStatus | account, killSwitchActive, drawdown, currentExposure, dailyOrders, dailyVolume |
| RiskMetrics       | VaR95, VaR99, SharpeRatio, MaxDrawdown, Volatility, CalmarRatio |

---

## 11. Config Schema

```yaml
riskx:
  rules:
    max_order_value: 100000        # 单笔最大订单价值
    max_position_size: 1000        # 最大持仓量
    max_daily_orders: 500          # 每日最大订单数
    max_daily_volume: 10000000     # 每日最大成交量
    max_order_rate: 10             # 每秒最大订单数
    max_drawdown: 0.20             # 最大回撤 20%
    max_concentration: 0.30        # 最大集中度 30%
    banned_symbols: []             # 禁止交易列表
  metrics_interval: 5m
  sliding_window_size: 1s
```

---

## 12. Error Handling

| 错误                  | 处理方式                         |
| --------------------- | -------------------------------- |
| 风控拒绝              | 返回 RiskResult{Allowed:false}   |
| 风控规则计算超时       | 保守策略：拒绝订单 + alert       |
| positionx 不可用       | 使用最后一次已知仓位 + stale 标记 |

---

## 13. Edge Cases

| 场景                       | 预期行为                         |
| -------------------------- | -------------------------------- |
| 多策略同时下单超限          | 并发控制，先到先得              |
| KillSwitch 生效中收到订单   | 直接拒绝，不检查其他规则         |
| 回撤刚好在阈值边界          | 含边界值（drawdown ≥ max → reject） |
| 减仓订单在风控中            | 减仓不检查 positionLimit         |

---

## 14. Directory Structure

```text
riskx/
├── go.mod
├── go.sum
├── README.md
├── engine.go          # RiskEngine 接口和实现
├── rules.go           # 风控规则定义
├── limits.go          # 限额检查
├── drawdown.go        # 回撤控制
├── killswitch.go      # Kill Switch
├── ratelimit.go       # 频率限制
├── concentration.go   # 集中度控制
├── metrics.go         # VaR, Sharpe 等指标计算
├── audit.go           # 审计事件记录
├── errors.go          # 错误定义
└── example_test.go
```

---

## 15. Dependencies

| 可以依赖                             | 禁止依赖                   |
| ------------------------------------ | -------------------------- |
| kernel, configx, observex, contracts | 策略逻辑（→ strategyx）   |
| positionx (仓位查询接口)             | 订单执行（→ orderx）      |
| domainx (decimal)                    | 交易所 SDK                 |
| stdlib                               |                            |

---

## 16. Testing

| 测试场景            | 验证点                           |
| ------------------- | -------------------------------- |
| 订单风控检查        | 各规则独立检查，首个失败短路     |
| 回撤熔断             | 触发 → 恢复的完整周期            |
| KillSwitch          | 拒绝所有订单，持久化恢复         |
| 并发下单             | 并发安全，计数准确               |

---

## 17. Performance Budget

| 操作              | 目标     |
| ----------------- | -------- |
| CheckOrder        | < 1ms    |
| RiskMetrics 计算  | < 100ms  |
| KillSwitch 切换   | < 10ms   |

---

## 18. Observability

| 信号   | 指标                                      |
| ------ | ----------------------------------------- |
| Metric | riskx.check.pass / riskx.check.reject     |
| Metric | riskx.drawdown.current                   |
| Metric | riskx.killswitch.active                  |
| Event  | riskx.circuit_breaker                    |
| Audit  | 每次风控决策 (timestamp, result, reason)  |

---

## 19. Security

| 要求               | 实现方式                       |
| ------------------ | ------------------------------ |
| 风控规则不可篡改   | 配置通过 configx 只读加载      |
| 审计事件不可删除   | append-only log                |

---

## 20. CI Gate

| Gate   | 命令                                   | 阻塞条件       |
| ------ | -------------------------------------- | -------------- |
| 编译   | `go build ./...`                       | 编译失败       |
| 测试   | `go test ./... -race -count=1`         | 测试失败       |
| 覆盖率 | `go test -coverprofile=...`            | < 80%          |
| vet    | `go vet ./...`                         | vet 错误       |

---

## 21. Upgrade Compatibility

| 变更类型             | 版本升级 |
| -------------------- | -------- |
| 新增风控规则类型     | minor    |
| RiskEngine 接口变更  | major    |
| 修改风控阈值默认值   | minor    |

---

## 22. Release DoD

- [ ] CheckOrder 全规则链路通过
- [ ] KillSwitch + 恢复流程验证
- [ ] 所有风控规则有对应测试
- [ ] 覆盖率 ≥ 80%

---

## 23. Open Questions

- 是否需要支持多级风控（账户级 + 策略级 + 全局级）？
- 是否需要接入实时波动率动态调整仓位限额？
- 风控规则是否支持用户自定义 DSL？
