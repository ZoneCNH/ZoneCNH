# Context Packet: TASK-DOMAINX-004

## Current Task

**TASK-DOMAINX-004**: Exposure 值对象

## Related Spec

`module/domainx/SPEC.md` §7 FR-004, §10 Data Model (Exposure), §13 Edge Cases（除零保护）

## Related Requirements

### Functional Requirements
- **FR-004**: Exposure — NewExposure(symbol, netPosition, grossExposure, netExposure) 返回 (Exposure, error)。NetExposureRatio() = netExposure / grossExposure。除零保护：grossExposure=0 返回 0。

### Acceptance Criteria
- AC-009: Exposure 正常构造 → Exposure + nil
- AC-010: NetExposureRatio() 除零 → 返回 0（不 panic）

### Test Cases
- TC-009: 合法参数 → Exposure 创建成功
- TC-010: grossExposure=0 → NetExposureRatio() = 0；正常值 → 比值正确

## Project Rules
- L2.5 | 不可变 | decimal.Decimal | snake_case JSON | 除零保护不 panic

## Scope

只实现：
- `exposure.go`：Exposure struct + NewExposure() + NetExposureRatio()
- `exposure_test.go`：TC-009~010

## Out of Scope
- Greek 字母（delta/gamma/theta）→ OQ-004
- 多交易所聚合 → OQ-006
- JSON round-trip → TASK-005

## Files to Modify

| 文件 | 操作 |
|------|------|
| `exposure.go` | 新增 |
| `exposure_test.go` | 新增 |

## Implementation Notes

- 除零保护：if grossExposure.IsZero() { return decimal.Zero }
- netPosition 可为负（short 仓位）
- delta 字段可选（nil pointer 或零值）
- 依赖 TASK-001 的 errors.go

## Acceptance Criteria

- [ ] AC-009: 正常构造
- [ ] AC-010: 除零安全 + 正常比值
- [ ] go build + go test -race 通过

## Validation Commands

```bash
cd /home/domainx
go build ./...
go test ./... -race -count=1
```
