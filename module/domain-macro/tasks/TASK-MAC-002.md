# Context Packet: TASK-MAC-002

## Current Task

**TASK-MAC-002**: MacroPoint 修订版本与来源审计

## Related Spec

`module/domain-macro/SPEC.md` §7 FR-MAC-002, §8 BR-MAC-002, §9 Interface Contract, §10 Data Model, §12 Error Handling

## Related Requirements

### Functional Requirements
- **FR-MAC-002**: MacroPoint 必须记录 revision version、preliminary flag 和 source。同一 SeriesCode+ObservedAt 存在多个 revision 时，RevisionVersion >= 0 且用于 deterministic ordering；preliminary/final 标识可追溯。

### Business Rules
- **BR-MAC-002**: FilterMacroPointsForBacktest 必须拒绝缺失 AvailableAt 的点，避免前视偏差

### Acceptance Criteria
- AC-MAC-002: RevisionVersion >= 0，违者 Validate 返回 ErrInvalidRevision
- AC-MAC-002a: IsPreliminary + Source 字段可追溯

### Test Cases
- TC-MAC-002: RevisionVersion < 0 → ErrInvalidRevision
- TC-MAC-002a: 合法 revision + preliminary + source → Validate 通过

## Project Rules
- L2.5 模块：只依赖 stdlib + decimalx（按 ADR），禁止依赖 L1 运行时
- 值对象不可变：私有字段 + 公开 getter
- 错误消息格式：`"domain-macro: <detail>"`

## Scope

只实现：
- `macropoint.go`：补充 RevisionVersion/IsPreliminary/Source 校验逻辑（如 TASK-MAC-001 未覆盖）
- `macropoint_test.go`：TC-MAC-002 系列测试

## Out of Scope

不要实现：
- FilterMacroPointsForBacktest（TASK-MAC-004）
- RevisionVersion 选择去重逻辑（TASK-MAC-005）
- MacroState / MacroRegimeCard（TASK-MAC-006）

## Files to Modify

| 文件 | 操作 | 说明 |
|------|------|------|
| `macropoint.go` | 修改 | 补充 revision/preliminary/source 校验 |
| `macropoint_test.go` | 修改 | TC-MAC-002 系列 |

## Acceptance Criteria

- [ ] AC-MAC-002: RevisionVersion < 0 → ErrInvalidRevision
- [ ] AC-MAC-002a: IsPreliminary/Source 字段 getter 可追溯
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

- RevisionVersion 校验：`revisionVersion < 0` → ErrInvalidRevision
- Source 字段可为空字符串（允许匿名数据源）
- IsPreliminary 为 bool，无需额外校验
- 确保与 TASK-MAC-001 的 MacroPoint 构造逻辑一致

## Required Output

1. 修改文件清单
2. TC-MAC-002 系列测试结果
3. go build + go test 输出
4. 有无 out-of-scope 变更
