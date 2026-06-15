# Context Packet: TASK-MAC-006

## Current Task

**TASK-MAC-006**: MacroState / MacroRegimeCard 枚举与校验

## Related Spec

`module/domain-macro/SPEC.md` §7 FR-MAC-006, §9 Interface Contract, §10 Data Model, §16.1 TC-MAC-006, §21 Upgrade Compatibility

## Related Requirements

### Functional Requirements
- **FR-MAC-006**: MacroState / MacroRegimeCard 必须有稳定枚举和 validate 规则。

### Acceptance Criteria
- AC-MAC-006: MacroState 枚举 recovery/expansion/slowdown/contraction 稳定
- AC-MAC-006a: IsValid() 可校验非法值

### Test Cases
- TC-MAC-006: 合法枚举值 → IsValid() == true
- TC-MAC-006a: 非法枚举值 → IsValid() == false
- TC-MAC-006b: MacroRegimeCard 校验

## Project Rules
- L2.5 模块：只依赖 stdlib + decimalx（按 ADR），禁止依赖 L1 运行时
- MacroState 枚举只可追加，不可删除或改值（兼容性承诺）
- 值对象不可变

## Scope

只实现：
- `macrostate.go`：MacroState 枚举 + IsValid() + MacroRegimeCard struct + Validate()
- `indicator_value.go`：IndicatorValue struct（如需要）
- `macrostate_test.go`：TC-MAC-006 系列

## Out of Scope

不要实现：
- 精度 ADR（TASK-MAC-007）
- Provider DTO 边界（SPEC FR-MAC-008）
- 宏观日历事件模型（v1.1 范围）

## Files to Modify

| 文件 | 操作 | 说明 |
|------|------|------|
| `macrostate.go` | 新增 | MacroState 枚举 + IsValid + MacroRegimeCard |
| `indicator_value.go` | 新增 | IndicatorValue struct |
| `macrostate_test.go` | 新增 | TC-MAC-006 系列 |

## Acceptance Criteria

- [ ] AC-MAC-006: 四枚举值 IsValid == true
- [ ] AC-MAC-006a: 非法值 IsValid == false
- [ ] go build ./... 通过
- [ ] go test ./... -race 通过

## Validation Commands

```bash
cd /home/domain-macro
go build ./...
go test ./... -race -count=1
go vet ./...
```

## Implementation Notes

```go
type MacroState string

const (
    MacroRecovery    MacroState = "recovery"
    MacroExpansion   MacroState = "expansion"
    MacroSlowdown    MacroState = "slowdown"
    MacroContraction MacroState = "contraction"
)

func (s MacroState) IsValid() bool

type MacroRegimeCard struct {
    state     MacroState
    updatedAt time.Time
    source    string
}

func (c MacroRegimeCard) Validate() error
```

- IsValid：检查是否为四个常量之一
- MacroRegimeCard.Validate：state.IsValid() + updatedAt 非零 + source 非空

## Required Output

1. 修改文件清单
2. TC-MAC-006 系列测试结果
3. go build + go test 输出
4. 有无 out-of-scope 变更
