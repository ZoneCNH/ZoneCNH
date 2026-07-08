# Context Packet: TASK-MAC-005

## Current Task

**TASK-MAC-005**: RevisionVersion 选择与去重

## Related Spec

`module/domain_macro/SPEC.md` §7 FR-MAC-005, §8 BR-MAC-004, §13 Edge Cases, §16.1 TC-MAC-003/005

## Related Requirements

### Functional Requirements
- **FR-MAC-005**: RevisionVersion 必须非负并可用于 deterministic revision ordering。同一 SeriesCode+ObservedAt 有多版本可见时，选择最高 RevisionVersion；preliminary 不得覆盖 final 除非 revision 更高且可见。

### Business Rules
- **BR-MAC-004**: 同一 DecisionTime + 同一输入数据 → MacroInformationSet 输出 deterministic

### Acceptance Criteria
- AC-MAC-005: 同一 SeriesCode+ObservedAt 多 revision → 选择最高可见 RevisionVersion
- AC-MAC-005a: preliminary 不得覆盖 final，除非 revision 更高且可见
- AC-MAC-005b: RevisionVersion 相同时有 preliminary 和 final → final 优先

### Test Cases
- TC-MAC-005: 同一 SeriesCode+ObservedAt 多 revision → 选择最高可见版本
- TC-MAC-005a: 未来修订版本不可见
- TC-MAC-005b: RevisionVersion 相同时 final 优先于 preliminary

## Project Rules
- L2.5 模块：只依赖 stdlib + decimalx（按 ADR），禁止依赖 L1 运行时
- 确定性：相同输入 → 相同输出
- RevisionVersion >= 0

## Scope

只实现：
- `revision.go`：revision 去重选择逻辑（SelectLatestRevisions 或集成到 FilterMacroPointsForBacktest）
- `revision_test.go`：TC-MAC-005 系列 + golden 测试

## Out of Scope

不要实现：
- MacroState / MacroRegimeCard（TASK-MAC-006）
- 精度 ADR（TASK-MAC-007）
- Provider DTO 边界（SPEC FR-MAC-008）

## Files to Modify

| 文件 | 操作 | 说明 |
|------|------|------|
| `revision.go` | 新增 | SelectLatestRevisions 或集成到 information_set |
| `revision_test.go` | 新增 | TC-MAC-005 系列 + golden 测试 |

## Acceptance Criteria

- [ ] AC-MAC-005: 最高可见 revision 优先
- [ ] AC-MAC-005a: preliminary 不覆盖 final（除非 revision 更高）
- [ ] AC-MAC-005b: 同 revision → final 优先
- [ ] golden 测试通过
- [ ] go build ./... 通过
- [ ] go test ./... -race 通过

## Validation Commands

```bash
cd /home/workspace/domain_macro
go build ./...
go test ./... -race -count=1
go vet ./...
```

## Implementation Notes

- 去重键：`SeriesCode + ObservedAt.Format(time.RFC3339Nano)`
- 选择策略：
  1. 按去重键分组
  2. 每组内排序：RevisionVersion 降序
  3. 同 RevisionVersion 时 final 优先于 preliminary
  4. 取每组第一个
- 集成到 FilterMacroPointsForBacktest：先过滤可见 → 再去重选最新

## Required Output

1. 修改文件清单
2. TC-MAC-005 系列测试结果
3. golden 测试结果
4. go build + go test 输出
5. 有无 out-of-scope 变更
