# Context Packet: TASK-DOMAINX-002

## Current Task

**TASK-DOMAINX-002**: Fill 值对象

## Related Spec

`module/domainx/SPEC.md` §7 FR-002, §10 Data Model (Fill), §12 Error Handling

## Related Requirements

### Functional Requirements
- **FR-002**: Fill 值对象 — NewFill(orderID, symbol, side, quantity, price, fee, feeCurrency) 返回 (Fill, error)。校验 quantity>0, price>=0, fee>=0。

### Business Rules
- **BR-002**: Quantity 必须 > 0

### Acceptance Criteria
- AC-005: Fill 正常构造 → Fill + nil
- AC-006: 非法 fee → ErrInvalidFee

### Test Cases
- TC-005: 合法参数 → Fill 创建成功
- TC-006: fee < 0 → ErrInvalidFee；quantity <= 0 → ErrInvalidQuantity

## Project Rules
- L2.5 约束：stdlib + decimalx only
- 不可变：私有字段 + getter
- 错误前缀：`"domainx: "`
- JSON tag snake_case

## Scope

只实现：
- `fill.go`：Fill struct（10 字段）+ NewFill() + getter
- `fill_test.go`：TC-005~006

## Out of Scope

不要实现：
- Position / Exposure（TASK-003~004）
- JSON round-trip（TASK-005）
- Benchmark / Docs（TASK-006）

## Files to Modify

| 文件 | 操作 | 说明 |
|------|------|------|
| `fill.go` | 新增 | Fill + NewFill + getters |
| `fill_test.go` | 新增 | TC-005~006 |

## Implementation Notes

- Fill 的 orderID 字段为 string 类型（不 import Order）
- feeCurrency 可选（空字符串表示与交易对基础币种相同）
- id 自动生成（UUID 或 `fmt.Sprintf("fill-%d", time.Now().UnixNano())`）
- 依赖 TASK-001 的 enums.go（FillSide）和 errors.go（ErrInvalidQuantity, ErrInvalidFee）

## Acceptance Criteria

- [ ] AC-005: Fill 正常构造
- [ ] AC-006: 非法 fee → ErrInvalidFee
- [ ] go build + go test 通过

## Validation Commands

```bash
cd /home/workspace/domainx
go build ./...
go test ./... -race -count=1
```
