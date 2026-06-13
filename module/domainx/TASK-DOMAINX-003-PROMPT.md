# Context Packet: TASK-DOMAINX-003

## Current Task

**TASK-DOMAINX-003**: Position 值对象

## Related Spec

`module/domainx/SPEC.md` §7 FR-003, §10 Data Model (Position)

## Related Requirements

### Functional Requirements
- **FR-003**: Position — NewPosition(symbol, quantity, avgPrice) 返回 (Position, error)。MarketValue() = quantity * avgPrice。UnrealizedPnL(currentPrice) = (currentPrice - avgPrice) * quantity。

### Acceptance Criteria
- AC-007: MarketValue() = quantity * avgPrice
- AC-008: UnrealizedPnL(currentPrice) = (currentPrice - avgPrice) * quantity

### Test Cases
- TC-007: Position{symbol="BTCUSDT", quantity=1.5, avgPrice=50000} → MarketValue() = 75000
- TC-008: UnrealizedPnL(51000) = 1500（盈利）；UnrealizedPnL(49000) = -1500（亏损）

## Project Rules
- L2.5 约束 | 不可变 | decimal.Decimal 精确运算 | snake_case JSON

## Scope

只实现：
- `position.go`：Position struct + NewPosition() + MarketValue() + UnrealizedPnL()
- `position_test.go`：TC-007~008

## Out of Scope
- 不做 Exposure（TASK-004）
- 不做 JSON round-trip（TASK-005）
- 不做多 Position 聚合（属于 portfolio-engine）

## Files to Modify

| 文件 | 操作 |
|------|------|
| `position.go` | 新增 |
| `position_test.go` | 新增 |

## Implementation Notes

- MarketValue() 和 UnrealizedPnL() 使用 decimal 精确乘法/减法
- 不缓存结果
- symbol 非空校验，avgPrice >= 0 校验
- 依赖 TASK-001 的 errors.go

## Acceptance Criteria

- [ ] AC-007: MarketValue() 精度正确
- [ ] AC-008: UnrealizedPnL() 正负值正确
- [ ] go build + go test -race 通过

## Validation Commands

```bash
cd /home/domainx
go build ./...
go test ./... -race -count=1
```
