# Context Packet: TASK-DOMAINX-001

## Current Task

**TASK-DOMAINX-001**: Order 值对象 + 枚举常量 + 错误定义

## Related Spec

`module/domainx/SPEC.md` §7 FR-001, §8 BR-002/003/004/007, §10 Data Model (Order), §12 Error Handling

## Related Requirements

### Functional Requirements
- **FR-001**: Order 值对象 — NewOrder(symbol, side, orderType, quantity, price) 返回 (Order, error)。校验 quantity>0, price>=0, symbol!="", decimal 非零值。

### Business Rules
- **BR-002**: Quantity 必须 > 0，违者 ErrInvalidQuantity
- **BR-003**: Price 必须 >= 0，违者 ErrInvalidPrice
- **BR-004**: Symbol 必须非空，违者 ErrEmptySymbol
- **BR-007**: decimal.Decimal 零值（未初始化）拒绝，与数值 0 区分

### Acceptance Criteria
- AC-001: Order 正常构造 → 返回 Order, nil 错误
- AC-002: 非法 quantity → ErrInvalidQuantity
- AC-003: 非法 price → ErrInvalidPrice
- AC-004: 空 symbol → ErrEmptySymbol

### Test Cases
- TC-001: 合法参数 → Order 创建成功，id 非空，status=pending
- TC-002: quantity=0 或 decimal 零值 → ErrInvalidQuantity
- TC-003: price<0 或 decimal 零值 → ErrInvalidPrice
- TC-004: symbol="" → ErrEmptySymbol

## Project Rules
- L2.5 模块：只依赖 stdlib + decimalx，禁止依赖 L1 运行时
- 所有金额/价格字段使用 `decimal.Decimal`（来自 `github.com/ZoneCNH/decimalx`）
- 值对象不可变：私有字段 + 公开 getter
- 错误消息格式：`"domainx: <detail>"`
- JSON tag 使用 snake_case

## Scope

只实现：
- `enums.go`：Side (buy/sell), OrderType (market/limit/stop), OrderStatus (六态), FillSide (buy/sell)
- `errors.go`：ErrInvalidQuantity, ErrInvalidPrice, ErrEmptySymbol, ErrInvalidSide, ErrInvalidOrderType, ErrInvalidOrderStatus
- `order.go`：Order struct（9 字段，全部私有）+ NewOrder() + getter 方法（ID, Symbol, Side, OrderType, Quantity, Price, Status, CreatedAt, UpdatedAt）
- `order_test.go`：TC-001~004 测试

## Out of Scope

不要实现：
- Fill / Position / Exposure（TASK-002~004）
- JSON 序列化测试（TASK-005）
- Benchmark（TASK-006）
- README / CHANGELOG（TASK-006）

## Files to Modify

| 文件 | 操作 | 说明 |
|------|------|------|
| `enums.go` | 新增 | 4 组常量定义 |
| `errors.go` | 新增 | 6 个 sentinel errors |
| `order.go` | 新增 | Order + NewOrder + getters |
| `order_test.go` | 新增 | TC-001~004 |

## Acceptance Criteria

- [ ] AC-001: NewOrder 合法参数 → Order + nil
- [ ] AC-002: quantity<=0 → ErrInvalidQuantity
- [ ] AC-003: price<0 → ErrInvalidPrice
- [ ] AC-004: symbol="" → ErrEmptySymbol
- [ ] go build ./... 通过
- [ ] go test ./... -race 通过

## Validation Commands

```bash
cd /home/domainx
go build ./...
go test ./... -race -count=1
go vet ./...
```

## Implementation Notes

```go
// Order 结构体（私有字段）
type Order struct {
    id        string
    symbol    string
    side      Side
    orderType OrderType
    quantity  decimal.Decimal
    price     decimal.Decimal
    status    OrderStatus
    createdAt time.Time
    updatedAt time.Time
}

// 构造函数签名
func NewOrder(symbol string, side Side, orderType OrderType, quantity, price decimal.Decimal) (Order, error)
```

- id 用 `github.com/google/uuid` 或 `fmt.Sprintf("ord-%d", time.Now().UnixNano())`
- createdAt/updatedAt = time.Now()
- status = OrderStatusPending
- price 为 0 时允许（market order 场景），但负价拒绝
- decimal 零值检测：`price.IsZero() && price.Equal(decimal.Zero)` 可能不可靠，用 `price.Coefficient().IsZero()` 或与 `decimal.Decimal{}` 比较

## Required Output

1. 修改文件清单
2. TC-001~004 测试结果
3. go build + go test 输出
4. 有无 out-of-scope 变更
