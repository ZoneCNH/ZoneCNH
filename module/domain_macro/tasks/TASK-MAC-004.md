# Context Packet: TASK-MAC-004

## Current Task

**TASK-MAC-004**: MacroInformationSet 与 copy-on-write

## Related Spec

`module/domain_macro/SPEC.md` §7 FR-MAC-004, §8 BR-MAC-003/004/005, §9 Interface Contract, §10 Data Model, §12 Error Handling, §13 Edge Cases

## Related Requirements

### Functional Requirements
- **FR-MAC-004**: MacroInformationSet.AsOf 必须只返回 decision time 可见数据，并保持 copy-on-write。

### Business Rules
- **BR-MAC-003**: MacroInformationSet 构造器 copy-on-write：getter 返回 slice 副本
- **BR-MAC-004**: 同一 DecisionTime + 同一输入数据 → MacroInformationSet 输出 deterministic
- **BR-MAC-005**: DataFreshnessSec 规则：无可见点时返回 -1 或特殊值；未来数据拒绝

### Acceptance Criteria
- AC-MAC-004: MacroInformationSet.Points 只含 IsVisibleAt(DecisionTime) == true 的数据
- AC-MAC-004a: getter 返回 slice 副本（copy-on-write）
- AC-MAC-004b: DataFreshnessSec 为空集时返回 -1

### Test Cases
- TC-MAC-004: MacroInformationSet 不暴露可变内部 slice（copy-on-write）
- TC-MAC-004a: AsOf 过滤后仅含可见点
- TC-MAC-004b: 空点集 → DataFreshnessSec == -1
- TC-MAC-004c: 并发读取 MacroInformationSet 无 data race

## Project Rules
- L2.5 模块：只依赖 stdlib + decimalx（按 ADR），禁止依赖 L1 运行时
- Copy-on-write：Points() getter 返回 `append([]MacroPoint(nil), d.points...)`
- 确定性：相同输入 → 相同输出，无随机性

## Scope

只实现：
- `information_set.go`：MacroInformationSet struct + FilterMacroPointsForBacktest + getter + DataFreshnessSec
- `information_set_test.go`：TC-MAC-004 系列 + race 测试

## Out of Scope

不要实现：
- RevisionVersion 去重选择（TASK-MAC-005）
- MacroState / MacroRegimeCard（TASK-MAC-006）
- 精度 ADR（TASK-MAC-007）

## Files to Modify

| 文件 | 操作 | 说明 |
|------|------|------|
| `information_set.go` | 新增 | MacroInformationSet + FilterMacroPointsForBacktest |
| `information_set_test.go` | 新增 | TC-MAC-004 系列 + race 测试 |

## Acceptance Criteria

- [ ] AC-MAC-004: Points 仅含可见点
- [ ] AC-MAC-004a: getter 返回 slice 副本
- [ ] AC-MAC-004b: 空集 → DataFreshnessSec == -1
- [ ] race 测试通过
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
type MacroInformationSet struct {
    decisionTime     time.Time
    points           []MacroPoint
    dataFreshnessSec float64
}

func FilterMacroPointsForBacktest(points []MacroPoint, decisionTime time.Time) MacroInformationSet
func (s MacroInformationSet) Points() []MacroPoint  // copy-on-write
func (s MacroInformationSet) DecisionTime() time.Time
func (s MacroInformationSet) DataFreshnessSec() float64
```

- FilterMacroPointsForBacktest：遍历 points，仅保留 IsVisibleAt(decisionTime)==true
- DataFreshnessSec：若有可见点，计算最新 AvailableAt 与 DecisionTime 差值；无可见点返回 -1
- Race 测试：多个 goroutine 并发调用 Points() getter

## Required Output

1. 修改文件清单
2. TC-MAC-004 系列测试结果
3. race 测试结果
4. go build + go test 输出
5. 有无 out-of-scope 变更
