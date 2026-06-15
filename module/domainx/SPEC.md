# domainx 完整规格

> 基座 · L2.5 领域共享层。订单、持仓、成交和投资组合的领域值对象与枚举定义。

最后更新：2026-06-14

---

## 1. Metadata

- Status: Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-14
- Owner: ZoneCNH
- Layer: L2.5 领域共享层
- Version: v1.0.1
- Repository: [github.com/ZoneCNH/domainx](https://github.com/ZoneCNH/domainx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [contracts](../contracts/SPEC.md), [decimalx](https://github.com/ZoneCNH/decimalx)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-14 | v1.0.0 | 初始规格：Order/Position/Trade/Portfolio/ExecutionReport 值对象 + OrderState/OrderType/OrderSide 枚举 | Claude |

## 2. Summary

`domainx` 是 FoundationX L2.5 领域共享层的投资组合与订单域模块。定义 Order、Position、Trade、Portfolio、ExecutionReport 等不可变值对象，以及 OrderState（7态）/ OrderType（6种）/ OrderSide 枚举。上层分析域、决策域、执行域通过 `domainx` 引用统一的订单-持仓语义，避免各域重复定义 Order/Position 结构。

---

## 3. Problem

交易系统的订单、持仓和成交数据跨越多个域（决策域发信号 → 执行域下单 → 成交回报 → 风控域更新持仓）。当前缺少统一的订单-持仓域值对象：

- 各域各自定义 Order/Position 结构，字段命名和语义不一致
- 订单状态流转散落在各模块，缺少统一枚举（PENDING→SUBMITTED→PARTIAL_FILLED→FILLED）
- 成交回报/执行报告格式不统一，risk-engine 和 backtest-engine 各自解析
- 持仓均价、未实现盈亏计算逻辑重复实现
- 投资组合汇总缺少标准模型，风控和报表各自拼装

---

## 4. Goals

- 定义 Order 值对象：order_id、symbol、side、type、quantity、price、state、timestamps
- 定义 Position 值对象：symbol、quantity、avg_price、unrealized_pnl、realized_pnl
- 定义 Trade 值对象：trade_id、order_id、symbol、quantity、price、fee、timestamp
- 定义 ExecutionReport 值对象：订单执行状态报告（成交进度、剩余量、均价）
- 定义 Portfolio 值对象：account_id、balances、positions、total_equity
- 定义枚举：OrderState（7态）、OrderType（6种）、OrderSide（BUY/SELL）
- 所有值对象不可变（私有+getter），构造时校验，修改操作返回新实例

---

## 5. Non-Goals

- 不做订单状态机引擎或生命周期管理（由 order-engine 负责）
- 不做仓位计算逻辑（由 risk-engine 根据 Trade 流计算 Position）
- 不做订单路由或执行逻辑（由 order-engine 负责）
- 不做风控规则评估（由 risk-engine 负责）
- 不做数据持久化（由存储扩展模块负责）
- 不做网络通信或 RPC（由 contracts / transportx 负责）
- 不做回测模拟撮合（由 backtest-engine 负责）

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| risk-engine | 引用 Position/Portfolio 计算风险敞口 |
| order-engine | 引用 Order/OrderState/ExecutionReport 管理订单生命周期 |
| signal-engine | 引用 Order 值对象生成交易信号上下文 |
| backtest-engine | 引用 Order/Trade/Position 记录回测结果 |
| execution-engine | 引用 ExecutionReport/Trade 标准化成交回报 |
| contracts | 引用 domainx 类型定义跨域 DTO 事件负载 |

---

## 7. Functional Requirements

### FR-001: Order 值对象

WHEN 调用 NewOrder(symbol, side, orderType, quantity, price) 且参数合法
THEN 创建不可变 Order 实例，自动分配唯一 order_id 和时间戳，state 初始为 PENDING

WHEN 调用 NewOrder(...) 且 quantity ≤ 0
THEN 返回 ErrInvalidQuantity，包含传入值

WHEN 调用 NewOrder(...) 且 price ≤ 0 且 orderType 为 Limit 或 StopLimit
THEN 返回 ErrInvalidPrice，限价单必须指定有效价格

WHEN 调用 NewOrder(...) 且 symbol 为空
THEN 返回 ErrInvalidSymbol

### FR-002: OrderState 枚举与流转

WHEN 查询 OrderState 枚举
THEN 提供 7 种状态：PENDING、SUBMITTED、PARTIAL_FILLED、FILLED、CANCELLED、REJECTED、EXPIRED

WHEN 调用 Order.TransitionTo(newState) 且流转合法
THEN 返回新 Order 实例，state 已更新，其余字段不变

WHEN TransitionTo 传入非法状态（如 FILLED → SUBMITTED）
THEN 返回 ErrInvalidTransition，包含当前状态和目标状态

合法流转：
PENDING → SUBMITTED、CANCELLED
SUBMITTED → PARTIAL_FILLED、FILLED、CANCELLED、REJECTED、EXPIRED
PARTIAL_FILLED → PARTIAL_FILLED、FILLED、CANCELLED
FILLED / CANCELLED / REJECTED / EXPIRED → 终态，不可流转

### FR-003: Trade 值对象

WHEN 调用 NewTrade(orderID, symbol, side, quantity, price, fee) 且参数合法
THEN 创建不可变 Trade 实例，自动分配唯一 trade_id 和时间戳

WHEN quantity ≤ 0 或 price ≤ 0
THEN 返回 ErrInvalidQuantity 或 ErrInvalidPrice

WHEN fee 不为 nil 且 fee.Currency 为空
THEN 返回 ErrInvalidFee

### FR-004: Position 值对象

WHEN 创建 Position{symbol, quantity, avgPrice}
THEN 所有字段只读，unrealizedPnl/realizedPnl 由外部计算后通过 WithPnl(...) 返回新实例

WHEN symbol 为空
THEN 返回 ErrInvalidSymbol

WHEN 调用 Position.WithQuantity(newQty, newAvgPrice) 进行仓位调整
THEN 返回新 Position 实例，quantity 和 avgPrice 已更新

### FR-005: ExecutionReport 值对象

WHEN 调用 NewExecutionReport(orderID, state, filledQty, remainingQty, avgPrice, lastPrice, lastQty)
THEN 创建不可变 ExecutionReport 实例

WHEN state 为 FILLED 且 remainingQty > 0
THEN 返回 ErrStateQuantityMismatch

WHEN filledQty + remainingQty 与原始订单量不一致（已知时）
THEN 返回 ErrQuantityMismatch

### FR-006: Portfolio 值对象

WHEN 调用 NewPortfolio(accountID, balances, positions)
THEN 创建不可变 Portfolio 实例，自动计算 totalEquity = sum(balances) + sum(positions.marketValue)

WHEN accountID 为空
THEN 返回 ErrInvalidAccount

WHEN positions 为空切片
THEN 正常创建空仓 Portfolio，totalEquity 为余额总和

### FR-007: 序列化兼容

WHEN 任意值对象被 JSON 序列化
THEN 字段名使用 snake_case，金额/价格序列化为字符串，时间序列化为 RFC3339

WHEN JSON 反序列化
THEN 执行与构造时相同的校验规则，金额字符串正确解析为 decimal.Decimal

### FR-008: 不可变性

WHEN 任意值对象创建后
THEN 无公开 setter，所有修改操作返回新实例（copy-on-write），多 goroutine 并发读取安全

---

## 8. Business Rules

| 编号 | 规则 | 违反时 |
| --- | --- | --- |
| BR-001 | 所有金额/价格字段使用 decimal.Decimal，不得使用 float64 | 编译失败：类型不匹配 |
| BR-002 | Order.quantity > 0 且限价单 price ≥ 0（市价单 price 可为 0） | 返回 ErrInvalidQuantity 或 ErrInvalidPrice |
| BR-003 | OrderState 流转必须遵循合法迁移表 | 返回 ErrInvalidTransition |
| BR-004 | Trade 必须关联有效的 OrderID | 返回 ErrOrderNotFound（由调用方校验） |
| BR-005 | Position.avgPrice 在加仓/减仓后按加权均价重新计算 | WithQuantity 返回新 Position，avgPrice 自动更新 |
| BR-006 | ExecutionReport.state 为 FILLED 时 remainingQty 必须为 0 | 返回 ErrStateQuantityMismatch |
| BR-007 | 所有值对象字段不可变（私有 + getter） | 编译期约束，无公开 setter |
| BR-008 | JSON tag 统一使用 snake_case | CI Gate: TC-003 JSON round-trip 测试失败 |
| BR-009 | 错误消息格式：`domainx: <type>: <detail>` | CI Gate 错误格式检查失败 |
| BR-010 | Portfolio.totalEquity = sum(balances) + sum(positions.marketValue) | 返回 ErrPortfolioBalanceMismatch |

---

## 9. Interface Contract

L2.5 值对象模块不定义接口。domainx 提供纯值对象类型和枚举。

```go
type OrderState int
const (
    OrderStatePending       OrderState = iota
    OrderStateSubmitted
    OrderStatePartialFilled
    OrderStateFilled
    OrderStateCancelled
    OrderStateRejected
    OrderStateExpired
)

type OrderType int
const (
    OrderTypeMarket    OrderType = iota
    OrderTypeLimit
    OrderTypeStop
    OrderTypeStopLimit
    OrderTypeIOC
    OrderTypeFOK
)

type OrderSide int
const (
    OrderSideBuy  OrderSide = iota
    OrderSideSell
)
```

---

## 10. Data Model

### Order

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| ID | string | ✅ | 全局唯一订单ID |
| Symbol | string | ✅ | 交易标的 |
| Side | OrderSide | ✅ | BUY/SELL |
| Type | OrderType | ✅ | 订单类型 |
| Quantity | decimal.Decimal | ✅ | 委托量 |
| Price | decimal.Decimal | ✅ | 委托价（市价单可为0） |
| State | OrderState | ✅ | 当前状态 |
| FilledQty | decimal.Decimal | ❌ | 已成交量（默认0） |
| AvgPrice | decimal.Decimal | ❌ | 成交均价（默认0） |
| CreatedAt | time.Time | ✅ | 创建时间 |
| UpdatedAt | time.Time | ✅ | 更新时间 |
| ClientID | string | ❌ | 客户端自定义ID |

### Trade

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| ID | string | ✅ | 全局唯一成交ID |
| OrderID | string | ✅ | 关联订单ID |
| Symbol | string | ✅ | 交易标的 |
| Side | OrderSide | ✅ | BUY/SELL |
| Quantity | decimal.Decimal | ✅ | 成交量 |
| Price | decimal.Decimal | ✅ | 成交价 |
| Fee | *Fee | ❌ | 手续费（可为nil） |
| Timestamp | time.Time | ✅ | 成交时间 |

### Fee

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Amount | decimal.Decimal | ✅ | 手续费金额 |
| Currency | string | ✅ | 手续费币种 |
| Type | string | ❌ | maker/taker |

### Position

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Symbol | string | ✅ | 交易标的 |
| Quantity | decimal.Decimal | ✅ | 持仓量（正=多，负=空） |
| AvgPrice | decimal.Decimal | ✅ | 加权均价 |
| UnrealizedPnl | decimal.Decimal | ❌ | 未实现盈亏（外部计算） |
| RealizedPnl | decimal.Decimal | ❌ | 已实现盈亏（外部计算） |
| UpdatedAt | time.Time | ✅ | 更新时间 |

### ExecutionReport

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| OrderID | string | ✅ | 关联订单ID |
| State | OrderState | ✅ | 执行状态 |
| FilledQty | decimal.Decimal | ✅ | 已成交量 |
| RemainingQty | decimal.Decimal | ✅ | 剩余量 |
| AvgPrice | decimal.Decimal | ✅ | 成交均价 |
| LastPrice | decimal.Decimal | ✅ | 最近成交价 |
| LastQty | decimal.Decimal | ✅ | 最近成交量 |
| Timestamp | time.Time | ✅ | 报告时间 |

### Portfolio

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| AccountID | string | ✅ | 账户ID |
| Balances | []Balance | ✅ | 各币种余额 |
| Positions | []Position | ✅ | 当前持仓 |
| TotalEquity | decimal.Decimal | ✅ | 总权益（余额+持仓市值） |
| UpdatedAt | time.Time | ✅ | 更新时间 |

### Balance

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| Currency | string | ✅ | 币种 |
| Amount | decimal.Decimal | ✅ | 可用余额 |
| Frozen | decimal.Decimal | ✅ | 冻结金额 |

---

## 11. Config Schema

domainx 作为 L2.5 值对象模块，不加载运行时配置。类型定义是编译时依赖。

---

## 12. Error Handling

| 错误 | 触发条件 | 处理方式 |
|------|----------|----------|
| ErrInvalidSymbol | Symbol 为空 | 返回错误 |
| ErrInvalidQuantity | Quantity ≤ 0 | 返回错误，含传入值 |
| ErrInvalidPrice | 限价单 Price ≤ 0 | 返回错误 |
| ErrInvalidTransition | 非法状态流转 | 返回错误，含from→to |
| ErrStateQuantityMismatch | ExecutionReport FILLED但remaining>0 | 返回错误 |
| ErrQuantityMismatch | filled+remaining ≠ original | 返回错误 |
| ErrInvalidFee | Fee.Currency 为空 | 返回错误 |
| ErrPortfolioBalanceMismatch | totalEquity 与余额+持仓不一致 | 返回错误 |
| ErrInvalidAccount | AccountID 为空 | 返回错误 |

消息格式：`domainx: <type>: <detail>`，使用 `%w` 保留错误链。

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| Order quantity=0 | 返回 ErrInvalidQuantity |
| Order symbol 为空 | 返回 ErrInvalidSymbol |
| 市价单 price=0 | 允许创建 |
| 限价单 price=0 | 返回 ErrInvalidPrice |
| FILLED.TransitionTo(SUBMITTED) | 返回 ErrInvalidTransition |
| Position quantity=0 | 允许（空仓），avgPrice 为 0 |
| ExecutionReport FILLED 但 remaining>0 | 返回 ErrStateQuantityMismatch |
| Portfolio positions=nil | 正常创建，totalEquity=sum(balances) |
| Position 负持仓（做空） | 允许，avgPrice 记录做空均价 |
| 加仓 avgPrice 计算 | 1BTC@50000 + 1BTC@60000 → avgPrice=55000 |
| JSON Decimal 精度 | 50000.12345678 完整保留 |
| 并发读取同一 Order | 安全（不可变） |

---

## 14. Directory Structure

```text
domainx/
├── go.mod / go.sum / README.md / CHANGELOG.md / LICENSE
├── doc.go
├── order.go / order_test.go
├── trade.go / trade_test.go
├── position.go / position_test.go
├── execution.go / execution_test.go
├── portfolio.go / portfolio_test.go
├── errors.go
├── validate.go / validate_test.go
├── internal/codec/
├── testdata/*.golden
├── example_test.go
└── benchmark_test.go
```

---

## 15. Dependencies

只依赖 stdlib + `github.com/ZoneCNH/decimalx`。禁止依赖任何 L1 运行时模块、存储扩展、业务域实现、其他 L2.5 模块。

---

## 16. Testing

### 16.1 Acceptance Criteria

| AC | Requirement | Criterion | Verification |
| --- | --- | --- | --- |
| AC-001 | FR-001 | Order 构造校验 quantity/price/symbol | `go test -run TestNewOrder ./...` |
| AC-002 | FR-002 | 合法流转成功，非法返回 ErrInvalidTransition | `go test -run TestOrderStateTransition ./...` |
| AC-003 | FR-003 | Trade 构造校验 quantity/price/fee | `go test -run TestNewTrade ./...` |
| AC-004 | FR-004 | Position 只读，WithQuantity 更新均价 | `go test -run TestPosition ./...` |
| AC-005 | FR-005 | ExecutionReport 校验 state/quantity | `go test -run TestExecutionReport ./...` |
| AC-006 | FR-006 | Portfolio 自动计算 totalEquity | `go test -run TestPortfolio ./...` |
| AC-007 | FR-007 | JSON round-trip Decimal 精度不变 | `go test -run TestJSONRoundTrip ./...` |
| AC-008 | FR-008 | 无公开 setter，修改返回新实例 | `go test -run TestImmutability ./...` |
| AC-009 | BR-002 | quantity≤0 → ErrInvalidQuantity | `go test -run TestOrderValidation ./...` |
| AC-010 | BR-003 | 非法流转 → ErrInvalidTransition | `go test -run TestOrderStateTransition ./...` |
| AC-011 | BR-010 | Portfolio 余额不一致 → 错误 | `go test -run TestPortfolioBalance ./...` |

### 16.2 Test Matrix

| TC | Coverage | Command |
| --- | --- | --- |
| TC-001 | FR-001, AC-001, AC-009 | `go test -run TestNewOrder ./...` |
| TC-002 | FR-002, AC-002, AC-010 | `go test -run TestOrderStateTransition ./...` |
| TC-003 | FR-007, AC-007 | `go test -run TestJSONRoundTrip ./...` |
| TC-004 | FR-003, AC-003 | `go test -run TestNewTrade ./...` |
| TC-005 | FR-004, AC-004 | `go test -run TestPosition ./...` |
| TC-006 | FR-005, AC-005 | `go test -run TestExecutionReport ./...` |
| TC-007 | FR-006, AC-006, AC-011 | `go test -run TestPortfolio ./...` |
| TC-008 | FR-008, AC-008 | `go test -run TestImmutability ./...` |

### 16.3 Given/When/Then

**TC-001: Order 构造与校验**
Given symbol="BTCUSDT", side=Buy, type=Limit, qty=1, price=50000
When NewOrder
Then Order{State=PENDING}, nil error

**TC-002: OrderState 合法与非法流转**
Given Order{State=SUBMITTED}
When TransitionTo(PartialFilled)
Then Order{State=PartialFilled}

Given Order{State=FILLED}
When TransitionTo(Submitted)
Then ErrInvalidTransition

**TC-003: JSON round-trip 精度**
Given Order{Price=50000.12345678}
When JSON marshal→unmarshal
Then Price=50000.12345678

**TC-004: Trade 构造与校验**
Given orderID="order-1", symbol="BTCUSDT", qty=1, price=50000
When NewTrade
Then Trade{OrderID: "order-1"}, nil error

**TC-005: Position 加仓均价**
Given Position{qty=1, avgPrice=50000}
When WithQuantity(2, 55000)
Then Position{qty=2, avgPrice=55000}

**TC-006: ExecutionReport 状态与数量一致性**
Given ExecutionReport{state=FILLED, filledQty=1, remainingQty=0}
When NewExecutionReport
Then report is accepted

Given ExecutionReport{state=FILLED, remainingQty=1}
When NewExecutionReport
Then ErrStateQuantityMismatch

**TC-007: Portfolio 总权益**
Given balances=[USDT:1000], positions=[BTC marketValue=50000]
When NewPortfolio
Then TotalEquity=51000

**TC-008: 不可变性**
Given an existing Order
When update-like operations are needed
Then a new value object is returned and no setter is exposed

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 值对象创建+校验 | < 1μs | `go test -bench` |
| JSON 序列化 | < 1μs | `go test -bench` |
| 状态流转 | < 100ns | `go test -bench` |
| Portfolio 汇总(100仓) | < 10μs | `go test -bench` |

---

## 18. Observability

纯值对象模块，不直接产生可观测输出。由调用方（risk-engine、order-engine）通过 observex 集成。

---

## 19. Security

- 不硬编码 secret/API key/密码
- 日志不记录敏感数据
- 值对象不含认证凭据字段
- 不可变对象防止并发安全问题
- JSON 反序列化后执行与构造时相同校验

---

## 20. CI Gate

通用：build / test -race / coverage≥80% / vet / lint / go mod tidy / gitleaks
专属：TestNew / TestJSONRoundTrip / TestImmutability / TestOrderStateTransition

---

## 21. Upgrade Compatibility

| 变更类型 | 兼容性 | 迁移 |
|----------|--------|------|
| 新增值对象字段（有默认值） | 向后兼容 | 无需 |
| 删除/重命名字段 | Breaking | major |
| 新增/删除 OrderState | 新增=兼容，删除=Breaking | major |
| 修改校验规则（收紧） | Breaking | major |
| 修改 JSON tag | Breaking | major |

---

## 22. Release DoD

- [x] 所有值对象有 godoc
- [x] 所有枚举有文档
- [x] CHANGELOG 已更新
- [x] README 完整
- [x] 覆盖率 ≥ 80%
- [x] -race 通过
- [x] Benchmark 无 >10% 回退
- [x] vet/lint 无警告
- [x] gitleaks 通过
- [x] 全部 FR 有测试
- [x] 全部 Edge Cases 有测试
- [x] JSON round-trip 通过（含 Decimal）
- [x] OrderState 流转全部覆盖

---

## 23. Open Questions

### Non-blocking

| ID | 问题 | 状态 |
|----|------|------|
| OQ-001 | OrderID 使用 UUID v4 还是 snowflake？当前规格不指定生成方式 | 待确认 |
| OQ-002 | Trade 是否需要 ExecutionID 关联交易所成交ID？ | 待确认 |
| OQ-003 | Position.marketValue 由 Portfolio 自动计算还是外部注入？当前为自动计算 | 待确认 |

### Future

| ID | 问题 |
|----|------|
| OQ-004 | 是否需要 protobuf 序列化？ |
| OQ-005 | 是否需要 OrderBook 快照值对象？ |
| OQ-006 | 是否需要 CommissionSplit 多级手续费模型？ |

---

## Appendix A: L2.5 约定

| 约定 | 说明 |
|------|------|
| 不可变 | 私有字段 + getter，无 setter |
| decimalx | 金额/价格用 decimal.Decimal |
| snake_case JSON | 与 contracts DTO 一致 |
| 校验在构造时 | New{Type}(...) → ({Type}, error) |
| 不依赖 L1 | stdlib + L2.5 only |
| godoc | 每个公开类型/方法有注释 |
| 状态迁移返回新实例 | TransitionTo 不修改原对象 |
