# TASK-CONTRACTS-001

> MarketDataProvider + MacroDataProvider 接口定义

---

```yaml
task_id: TASK-CONTRACTS-001
module: contracts
scope: "定义 MarketDataProvider 和 MacroDataProvider 接口"
spec_ref:
  - "module/contracts/SPEC.md#FR-001"
  - "module/contracts/SPEC.md#FR-002"
  - "module/contracts/SPEC.md#BR-004"
  - "module/contracts/SPEC.md#BR-007"
files:
  - "market.go"
  - "market_test.go"
  - "macro.go"
  - "macro_test.go"
acceptance_criteria:
  - "AC-FR-001: MarketDataProvider 接口方法签名与 SPEC §9 一致"
  - "AC-FR-001: MacroDataProvider 接口方法签名与 SPEC §9 一致"
  - "AC-BR-004: 每个端口接口方法数在 3-5 范围"
  - "AC-BR-007: 编译期检查语句 var _ Interface = (*Impl)(nil) 存在且编译通过"
depends_on:
  - "TASK-CONTRACTS-000"
estimated_effort: "1h"
priority: P0
status: pending
non_scope:
  - "不实现接口逻辑（仅签名）"
  - "不实现Event/Topic（→TASK-002）"
  - "不定义BC检测（→TASK-003）"
```

---

## Non-scope

- 不实现接口逻辑（仅签名）
- 不实现Event/Topic（→TASK-002）
- 不定义BC检测（→TASK-003）

## Requirements Covered

| Requirement | Description             | Acceptance Criteria  |
| ----------- | ----------------------- | -------------------- |
| FR-001      | MarketDataProvider 接口 | AC-FR-001: 方法签名与 SPEC 一致 |
| FR-002      | MacroDataProvider 接口  | AC-FR-001: 方法签名与 SPEC 一致 |
| BR-004      | 端口接口方法数 3-5      | AC-BR-004: TC-006 |
| BR-007      | 编译期检查语句          | AC-FR-001: TC-001 |

## Test Plan

| Test Case | Type    | Description        |
| --------- | ------- | ------------------ |
| TC-001    | Compile | 端口接口编译期检查 (var _ Interface = (*impl)(nil)) |

## Implementation Notes

- 接口定义数据获取契约，不包含实现
- DTO 类型在接口文件中定义

## Implementation Plan

| Step | Description                              | Deliverables | Verification          |
| ---- | ---------------------------------------- | ------------ | --------------------- |
| 1    | 定义 `MarketDataProvider` 接口和相关 DTO | `market.go`  | `go build ./...` 通过 |
| 2    | 定义 `MacroDataProvider` 接口和相关 DTO  | `macro.go`   | `go build ./...` 通过 |

### Risk Assessment

| Risk                 | Probability | Impact | Mitigation   |
| -------------------- | ----------- | ------ | ------------ |
| 接口签名与下游不匹配 | Medium      | High   | 对照 SPEC §9 |
