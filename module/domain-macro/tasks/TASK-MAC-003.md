# Context Packet: TASK-MAC-003

## Current Task

**TASK-MAC-003**: IsVisibleAt fail-closed 可见性规则

## Related Spec

`module/domain-macro/SPEC.md` §7 FR-MAC-003, §8 BR-MAC-001/002/005, §9 Interface Contract, §13 Edge Cases

## Related Requirements

### Functional Requirements
- **FR-MAC-003**: IsVisibleAt(decisionTime) 必须 fail-closed，available time 缺失或晚于 decision time 时不可见。

### Business Rules
- **BR-MAC-001**: IsVisibleAt 必须 fail-closed：缺失 AvailableAt 的点不可见
- **BR-MAC-002**: FilterMacroPointsForBacktest 必须拒绝缺失 AvailableAt 的点
- **BR-MAC-005**: DataFreshnessSec 规则：无可见点时返回 -1 或特殊值；未来数据拒绝

### Acceptance Criteria
- AC-MAC-003: ObservedAt/ReleasedAt/AvailableAt 任一晚于 decisionTime → IsVisibleAt 返回 false
- AC-MAC-003a: AvailableAt 缺失 → IsVisibleAt 返回 false
- AC-MAC-003b: DecisionTime 恰好等于 AvailableAt → 可见（<= 边界）

### Test Cases
- TC-MAC-003: DecisionTime 之后 AvailableAt 的点 → IsVisibleAt 返回 false
- TC-MAC-003a: AvailableAt 缺失 → IsVisibleAt 返回 false
- TC-MAC-003b: DecisionTime == AvailableAt → IsVisibleAt 返回 true
- TC-MAC-003c: Property 测试：随机时间组合验证 IsVisibleAt 不泄露未来数据

## Project Rules
- L2.5 模块：只依赖 stdlib + decimalx（按 ADR），禁止依赖 L1 运行时
- Fail-closed 默认策略：缺失时间、未来数据均返回 false

## Scope

只实现：
- `visibility.go`：IsVisibleAt 完整逻辑（如与 TASK-MAC-001 合并则在 macropoint.go 中）
- `visibility_test.go`：TC-MAC-003 系列测试 + property 测试

## Out of Scope

不要实现：
- FilterMacroPointsForBacktest（TASK-MAC-004）
- MacroState / MacroRegimeCard（TASK-MAC-006）

## Files to Modify

| 文件 | 操作 | 说明 |
|------|------|------|
| `macropoint.go` | 修改 | IsVisibleAt 完整 fail-closed 逻辑 |
| `visibility_test.go` | 新增 | TC-MAC-003 系列 + property 测试 |

## Acceptance Criteria

- [ ] AC-MAC-003: 时间晚于 decisionTime → false
- [ ] AC-MAC-003a: AvailableAt 缺失 → false
- [ ] AC-MAC-003b: DecisionTime == AvailableAt → true
- [ ] Property 测试通过（随机时间组合无泄露）
- [ ] go build ./... 通过
- [ ] go test ./... -race 通过

## Validation Commands

```bash
cd /home/domain-macro
go build ./...
go test ./... -race -count=1
go test ./... -count=100  # property test
go vet ./...
```

## Implementation Notes

- IsVisibleAt 逻辑：
  - AvailableAt.IsZero() → false（fail-closed）
  - ObservedAt.After(decisionTime) → false
  - ReleasedAt.After(decisionTime) → false
  - AvailableAt.After(decisionTime) → false
  - 否则 → true
- 边界：`!AvailableAt.After(decisionTime)` 等价于 `AvailableAt <= decisionTime`
- Property 测试：生成随机时间组合，断言"可见 → 所有时间 <= decisionTime"

## Required Output

1. 修改文件清单
2. TC-MAC-003 系列测试结果
3. Property 测试结果
4. go build + go test 输出
5. 有无 out-of-scope 变更
