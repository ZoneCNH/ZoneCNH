# Context Packet: TASK-MAC-001

## Current Task

**TASK-MAC-001**: MacroPoint 三类时间语义

## Related Spec

`module/domain_macro/SPEC.md` §7 FR-MAC-001, §8 BR-MAC-001, §9 Interface Contract (MacroPoint), §10 Data Model, §12 Error Handling, §13 Edge Cases

## Related Requirements

### Functional Requirements
- **FR-MAC-001**: MacroPoint 必须表达 ObservedAt/ReleasedAt/AvailableAt 三类时间。AvailableAt 缺失时 Validate 失败。

### Business Rules
- **BR-MAC-001**: IsVisibleAt 必须 fail-closed：缺失 AvailableAt 的点不可见

### Acceptance Criteria
- AC-MAC-001: MacroPoint 构造时 ObservedAt/ReleasedAt/AvailableAt 三类时间字段语义固定
- AC-MAC-001a: AvailableAt 缺失（零值）时 Validate 返回 ErrMissingAvailableAt

### Test Cases
- TC-MAC-001: 缺失 AvailableAt 的 MacroPoint → Validate 失败
- TC-MAC-001a: 三类时间字段正确赋值 → Validate 通过

## Project Rules
- L2.5 模块：只依赖 stdlib + decimalx（按 ADR），禁止依赖 L1 运行时
- 所有宏观数值字段使用 `decimalx.Decimal`（按 ADR 决策）
- 值对象不可变：私有字段 + 公开 getter
- 错误消息格式：`"domain_macro: <detail>"`
- 时间字段使用 UTC

## Scope

只实现：
- `macropoint.go`：MacroPoint struct + NewMacroPoint() + Validate() + IsVisibleAt() + getter 方法
- `errors.go`：ErrMissingAvailableAt, ErrLookAheadBias, ErrInvalidSeriesCode, ErrInvalidRevision, ErrFutureDataRejected
- `macropoint_test.go`：TC-MAC-001, TC-MAC-001a 及时间组合测试

## Out of Scope

不要实现：
- MacroInformationSet / FilterMacroPointsForBacktest（TASK-MAC-004）
- RevisionVersion 选择逻辑（TASK-MAC-005）
- MacroState / MacroRegimeCard（TASK-MAC-006）
- 精度 ADR 决策（TASK-MAC-007）

## Files to Modify

| 文件 | 操作 | 说明 |
|------|------|------|
| `macropoint.go` | 新增 | MacroPoint struct + 构造 + Validate + IsVisibleAt |
| `errors.go` | 新增 | sentinel errors |
| `macropoint_test.go` | 新增 | TC-MAC-001 系列测试 |

## Acceptance Criteria

- [ ] AC-MAC-001: MacroPoint 三类时间字段语义正确
- [ ] AC-MAC-001a: AvailableAt 零值 → Validate 返回 ErrMissingAvailableAt
- [ ] go build ./... 通过
- [ ] go test ./... -race 通过

## Validation Commands

```bash
cd /home/domain_macro
go build ./...
go test ./... -race -count=1
go vet ./...
```

## Implementation Notes

```go
type MacroPoint struct {
    seriesCode      string
    value           decimalx.Decimal
    observedAt      time.Time
    releasedAt      time.Time
    availableAt     time.Time
    revisionVersion int
    isPreliminary   bool
    source          string
}

func NewMacroPoint(seriesCode string, value decimalx.Decimal, observedAt, releasedAt, availableAt time.Time, revisionVersion int, isPreliminary bool, source string) (MacroPoint, error)
func (p MacroPoint) Validate() error
func (p MacroPoint) IsVisibleAt(decisionTime time.Time) bool
```

- AvailableAt 零值检测：`availableAt.IsZero()` → ErrMissingAvailableAt
- IsVisibleAt fail-closed：ObservedAt/ReleasedAt/AvailableAt 任一晚于 decisionTime → false
- DecisionTime 恰好等于 AvailableAt：可见（<= 含边界）

## Required Output

1. 修改文件清单
2. TC-MAC-001 系列测试结果
3. go build + go test 输出
4. 有无 out-of-scope 变更
