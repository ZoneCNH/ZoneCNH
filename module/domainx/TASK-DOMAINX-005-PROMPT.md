# Context Packet: TASK-DOMAINX-005

## Current Task

**TASK-DOMAINX-005**: JSON 序列化 + 不可变性验证 + testdata

## Related Spec

`module/domainx/SPEC.md` §7 FR-005, FR-006, §8 BR-005, BR-006, §13 Edge Cases（并发）

## Related Requirements

### Functional Requirements
- **FR-005**: 所有值对象支持 JSON snake_case round-trip（Marshal → Unmarshal → 字段一致）
- **FR-006**: 值对象不可变，并发读取安全（go test -race 零告警）

### Business Rules
- **BR-005**: 不可变性 — 私有字段 + 公开 getter（编译期约束）
- **BR-006**: snake_case JSON tag — 与 contracts DTO 对齐

### Acceptance Criteria
- AC-011: Order JSON round-trip
- AC-012: Fill JSON round-trip
- AC-013: JSON 缺失必填字段 → 返回错误
- AC-014: 100 goroutines 并发 getter → 零 data race

### Test Cases
- TC-011: Order Marshal → Unmarshal → 字段一致（含 decimal.Decimal）
- TC-012: Fill Marshal → Unmarshal → 字段一致
- TC-013: `{"quantity": 1.5}` 反序列化到 Order → 返回错误（缺 symbol）
- TC-014: 100 goroutines 并发读取 Order → `-race` 零告警

## Project Rules
- JSON tag 全部 snake_case
- decimal.Decimal 序列化依赖 decimalx 的 MarshalJSON/UnmarshalJSON
- testdata/ 存放 golden files

## Scope

只实现：
- `json_test.go`：TC-011~014（跨所有 4 种值对象类型）
- `testdata/order_valid.json`, `order_invalid.json`, `fill_valid.json`, `position_valid.json`, `exposure_valid.json`

## Out of Scope
- Benchmark → TASK-006
- protobuf 序列化 → OQ-005
- 不修改现有 .go 文件（仅新增测试）

## Files to Modify

| 文件 | 操作 |
|------|------|
| `json_test.go` | 新增 |
| `testdata/*.json` | 新增（5 文件） |

## Implementation Notes

- TC-011/012 使用 golden file 或 inline JSON 字符串
- TC-013 验证 `json.Unmarshal` 返回非 nil 错误
- TC-014 使用 `sync.WaitGroup` + 100 goroutines + `go test -race`
- 每个值对象类型至少测试 1 次 round-trip

## Acceptance Criteria

- [ ] AC-011: Order JSON round-trip ✓
- [ ] AC-012: Fill JSON round-trip ✓
- [ ] AC-013: 缺失字段 → 错误 ✓
- [ ] AC-014: `go test -race` 零告警 ✓

## Validation Commands

```bash
cd /home/workspace/domainx
go test ./... -race -count=1
go test -run TestJSON ./...
```
