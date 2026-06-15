# orderx 规格

- Status: Review
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-14
- Layer: 执行域 · 订单引擎
- Module-Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `riskx`, `positionx`

> 公开投影 caveat：Status=Review 与矩阵覆盖证据不等同于 factory-grade；四源评分通过前机器事实层保持 factory=false。

---

## 1. 摘要

`orderx` 是执行域的订单管理器，负责订单全生命周期管理、订单路由、智能订单路由（SOR）、订单状态机和订单簿维护。它接收 strategyx 或 maestro 的订单请求，通过 riskx 进行风控检查，然后路由到交易所执行。架构规则明确：策略只能通过 riskx 提交订单，riskx 通过 orderx 执行。

---

## 2. Problem

多交易所交易场景中的订单管理挑战：

- 订单状态分散在各交易所，无统一视图
- 订单路由逻辑硬编码，无法根据流动性动态选择
- 订单状态变更无审计轨迹，排查成交异常困难
- 撤单/改单接口不统一，各交易所 API 差异大
- 缺乏 SOR（Smart Order Routing），大订单无法拆分执行

---

## 3. Goals

- 统一订单状态机：NEW → PENDING → PARTIAL → FILLED / CANCELLED / REJECTED / EXPIRED
- 订单路由：根据 symbol、exchange、liquidity 选择最优执行场所
- 智能路由（SOR）：大订单自动拆分为多个子订单
- 订单审计轨迹：每次状态变更记录完整上下文
- 撤单/改单统一接口：屏蔽交易所 API 差异

---

## 4. Non-goals

- 不做风控决策（→ riskx）
- 不做策略决策（→ strategyx）
- 不做仓位计算（→ positionx）
- 不做交易所 API 对接（通过 exchange adapter）
- 不做订单策略（TWAP/VWAP → 未来版本）

---

## 5. Consumers

| 消费者       | 使用方式                            |
| ------------ | ----------------------------------- |
| riskx        | 调用 Submit 执行通过风控的订单      |
| strategyx    | 接收订单状态回执                   |
| positionx    | 消费 fill 事件更新仓位              |
| maestro      | 编排 workflow 中提交订单            |
| observex     | 消费订单事件用于监控               |

---

## 6. Functional Requirements

### FR-001: Order Lifecycle

WHEN 创建订单
THEN 状态机必须遵循以下转换：
```text
NEW → PENDING (已发送至交易所)
PENDING → PARTIAL (部分成交)
PENDING → FILLED (全部成交)
PENDING → CANCELLED (已取消)
PENDING → REJECTED (被拒绝)
PENDING → EXPIRED (过期)
PARTIAL → FILLED (剩余部分成交)
PARTIAL → CANCELLED (取消剩余)
```
AND 每次状态变更必须记录 timestamp、oldState、newState、reason

### FR-002: Order Submission

WHEN Submit(order)
THEN 必须通过 riskx.CheckOrder 风控检查
AND 风控拒绝时返回拒绝原因
AND 通过后发送至 exchange adapter
AND 返回 orderId 和初始状态

### FR-003: Order Routing

WHEN 订单需要选择交易所
THEN 使用路由策略：PREFERRED（指定交易所）、BEST_PRICE（最优价格）、LOWEST_FEE（最低手续费）
AND PREFERRED 策略优先使用指定交易所，不可用时 FAIL
AND BEST_PRICE 策略同时询价，选择最优

### FR-004: SOR (Smart Order Routing)

WHEN 订单数量超过单笔上限
THEN 自动拆分为多个子订单（slice）
AND 子订单可路由到不同交易所
AND 父订单状态 = 所有子订单状态的聚合
AND 支持按时间、按成交量加权拆分

### FR-005: Cancel / Amend

WHEN CancelOrder(orderId)
THEN 向交易所发送撤单请求
AND 更新状态为 CANCELLED（如果尚未成交）
AND 部分成交的订单只能取消剩余部分
WHEN AmendOrder(orderId, newPrice, newQty)
THEN 先取消原订单 → 创建新订单（Cancel-Replace 模式）
AND 保留原 orderId 不变

### FR-006: Order Query

WHEN 查询 Order(orderId)
THEN 返回：orderId, symbol, exchange, side, type, qty, filledQty, avgPrice, status, createTime, updateTime
WHEN 查询 OpenOrders(account)
THEN 返回所有非终态的订单（NEW/PENDING/PARTIAL）

### FR-007: Order Audit

WHEN 订单状态变更
THEN 记录 OrderAuditEvent：orderId, timestamp, oldState, newState, reason, fillId(if fill), price, qty
AND 审计事件不可删除

---

### FR-008: Module Identity

WHEN downstream consumer reads `orderx` `README.md`
THEN the H1 heading MUST be `# orderx`
AND MUST NOT be `# xlib-standard`

WHEN module documentation references the `orderx` Go module path
THEN it MUST use `github.com/ZoneCNH/orderx`
AND MUST NOT use `github.com/ZoneCNH/xlib-standard`

WHEN `go.mod` declares the module name
THEN it MUST be `module github.com/ZoneCNH/orderx`

### Acceptance Criteria

| AC 编号 | 对应 FR | 验收条件 |
| ------- | ------- | -------- |
| AC-ORD-001 | FR-001 | 订单状态机遵循 NEW→PENDING→PARTIAL/FILLED/CANCELLED/REJECTED/EXPIRED 转换；非法转换被拒绝；每次变更记录 timestamp/oldState/newState/reason |
| AC-ORD-002 | FR-002 | Submit 必须先通过 riskx.CheckOrder；风控拒绝时返回拒绝原因；通过后发送至 exchange adapter；返回 orderId 和初始状态 |
| AC-ORD-003 | FR-003 | 路由策略 PREFERRED/BEST_PRICE/LOWEST_FEE 正确执行；PREFERRED 指定交易所不可用时 FAIL |
| AC-ORD-004 | FR-004 | SOR 超过单笔上限时自动拆分为子订单；子订单可路由到不同交易所；父订单状态 = 所有子订单聚合 |
| AC-ORD-005 | FR-005 | CancelOrder 未成交订单状态更新为 CANCELLED；部分成交仅取消剩余；AmendOrder 执行 Cancel-Replace 保留原 orderId |
| AC-ORD-006 | FR-006 | Order(orderId) 返回完整订单信息；OpenOrders(account) 仅返回非终态订单 |
| AC-ORD-007 | FR-007 | 订单状态变更记录 OrderAuditEvent；审计事件不可删除 |
| AC-ORD-008 | FR-008 | README H1 为 `# orderx`；Go module path 为 `github.com/ZoneCNH/orderx`；go.mod 声明 `module github.com/ZoneCNH/orderx` |

## 7. Business Rules

| 编号   | 规则                                   | 违反后果 |
| ------ | -------------------------------------- | -------- |
| BR-001 | 订单必须先通过 riskx 才能提交交易所     | 拒绝下单 |
| BR-002 | 终态订单不可再修改（FILLED/CANCELLED/REJECTED/EXPIRED）| 拒绝操作 |
| BR-003 | SOR 父订单状态 = 所有子订单状态的聚合   | 状态不一致告警 |
| BR-004 | 撤单操作幂等（对已终态的订单撤单返回成功）| - |
| BR-005 | 订单 ID 全局唯一                        | ID 冲突时拒绝创建 |

---

## 8. Interface Contract

```go
type OrderManager interface {
    Submit(ctx context.Context, order Order) (*OrderReceipt, error)
    Cancel(ctx context.Context, orderID string) error
    Amend(ctx context.Context, orderID string, newPrice, newQty decimal.Decimal) (*OrderReceipt, error)
    Get(ctx context.Context, orderID string) (*Order, error)
    GetOpen(ctx context.Context, account string) ([]Order, error)
    GetHistory(ctx context.Context, req OrderHistoryRequest) ([]Order, error)
}

type SOR interface {
    Slice(ctx context.Context, order Order) ([]Order, error)
}

type Order struct {
    OrderID   string
    Symbol    string
    Exchange  string
    Side      Side
    OrderType OrderType
    Quantity  decimal.Decimal
    Price     decimal.Decimal
    Account   string
    Route     RoutePolicy
}

type OrderReceipt struct {
    OrderID string
    Status  OrderStatus
    Message string
}
```

---

## 9. Data Model

| 模型             | 字段 |
| ---------------- | ---- |
| Order            | orderID, symbol, exchange, side, type, qty, price, filledQty, avgPrice, status, account, routePolicy, parentOrderID, createTime, updateTime |
| OrderStatus      | enum: NEW, PENDING, PARTIAL, FILLED, CANCELLED, REJECTED, EXPIRED |
| RoutePolicy      | enum: PREFERRED, BEST_PRICE, LOWEST_FEE |
| Side             | enum: BUY, SELL |
| OrderAuditEvent  | orderID, timestamp, oldState, newState, reason, fillID, price, qty |

---

## 10. Config Schema

```yaml
orderx:
  route:
    default_policy: preferred
    best_price_timeout: 500ms
    best_price_min_exchanges: 2
  sor:
    enabled: false
    max_slices: 10
    min_slice_qty: 0.01
  max_open_orders_per_account: 100
```

---

## 11. Error Handling

| 错误                | 处理方式                         |
| ------------------- | -------------------------------- |
| 风控拒绝            | 返回拒绝原因，不发送交易所       |
| 交易所不可达         | 重试 3 次 → 标记 REJECTED       |
| 撤单时订单已成交     | 返回 "already filled"            |
| 改单失败             | 保留原订单，返回错误             |
| 路由无可用交易所     | 返回 NO_AVAILABLE_EXCHANGE       |

---

## 12. Edge Cases

| 场景                       | 预期行为                           |
| -------------------------- | ---------------------------------- |
| SOR 部分子订单成交          | 父订单 PARTIAL，展示聚合状态        |
| 交易所返回未知订单状态      | 以本地状态为准，标记需要 reconciliation |
| 网络分区导致重复提交        | broker 端去重 by clientOrderId     |
| 撤单和成交竞争              | 交易所返回为准（成交优先）          |

---

## 13. Directory Structure

```text
orderx/
├── go.mod
├── go.sum
├── README.md
├── manager.go         # OrderManager 接口和实现
├── lifecycle.go       # 订单状态机
├── route.go           # 订单路由
├── sor.go             # SOR 智能路由
├── audit.go           # 审计事件
├── errors.go          # 错误定义
├── adapters/          # 交易所 adapter
│   ├── adapter.go     # ExchangeAdapter 接口
│   ├── binance.go
│   └── mock.go
└── example_test.go
```

---

## 14. Dependencies

| 可以依赖                             | 禁止依赖                     |
| ------------------------------------ | ---------------------------- |
| kernel, configx, observex, contracts | 策略决策（→ strategyx）     |
| riskx (CheckOrder 接口)              | 仓位管理（→ positionx）     |
| transportx                           | 交易所具体实现              |
| domainx (decimal)                    |                              |
| stdlib                               |                              |

---

## 15. Testing

| 测试场景            | 验证点                           |
| ------------------- | -------------------------------- |
| 订单状态机           | 所有合法/非法转换                 |
| 路由策略             | PREFERRED/BEST_PRICE 正确选择     |
| SOR 拆分             | 拆分数和份额正确                  |
| 撤单幂等             | 重复撤单不报错                   |
| 并发下单             | orderID 不冲突                   |

---

## 16. Performance Budget

| 操作              | 目标     |
| ----------------- | -------- |
| Submit (不含风控) | < 5ms    |
| Get/Cancel        | < 1ms    |
| SOR Split         | < 10ms   |

---

## 17. Observability

| 信号   | 指标                                  |
| ------ | ------------------------------------- |
| Metric | orderx.submit.total / .failed         |
| Metric | orderx.open_orders                    |
| Metric | orderx.latency.submit_to_fill         |
| Event  | orderx.status_change                  |
| Audit  | 每次状态变更                          |

---

## 18. Security

| 要求               | 实现方式                       |
| ------------------ | ------------------------------ |
| 订单不可篡改       | 创建后字段不可变               |
| API key 保护       | 通过 configx 注入，不落日志    |

---

## 19. CI Gate

| Gate   | 命令                                   | 阻塞条件       |
| ------ | -------------------------------------- | -------------- |
| 编译   | `go build ./...`                       | 编译失败       |
| 测试   | `go test ./... -race -count=1`         | 测试失败       |
| 覆盖率 | `go test -coverprofile=...`            | < 80%          |
| vet    | `go vet ./...`                         | vet 错误       |

---

## 20. Upgrade Compatibility

| 变更类型             | 版本升级 |
| -------------------- | -------- |
| 新增订单类型         | minor    |
| 新增路由策略         | minor    |
| OrderManager 接口变更| major    |

---

## 21. Release DoD

- [ ] 订单状态机完整实现 + 所有转换测试
- [ ] 路由策略全部实现
- [ ] SOR 拆分逻辑验证
- [ ] 审计事件完整性
- [ ] 覆盖率 ≥ 80%

---

## 22. Open Questions

- 是否支持算法订单（TWAP/VWAP/Iceberg）？
- 是否需要订单执行质量报告（slippage, fill ratio）？
- 是否支持多腿订单（OCO, bracket order）？


## 23. 变更历史

| 日期       | 版本         | 变更内容 | 作者    |
| ---------- | ------------ | -------- | ------- |
| 2026-06-14 | v0.1.0-draft | 初始版本 | ZoneCNH |
| 2026-06-14 | v0.1.0-draft | FR-008 Module Identity (README H1 + go.mod 校验) | ZoneCNH |