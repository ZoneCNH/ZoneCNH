# TASK-EXC-001

> Exchange SPI 拆分：读写能力接口与组合接口

---

```yaml
task_id: TASK-EXC-001
module: domain-exchange
scope: "拆分 Exchange 大接口为 AccountReader、OrderPlacer、OrderCanceler、OrderQuerier、MarketReader、DerivativeReader、Streamer 能力接口及 Exchange 组合接口"
spec_ref:
  - "module/domain-exchange/SPEC.md#FR-EXC-001"
  - "module/domain-exchange/SPEC.md#§9"
files:
  - "exchange.go"
  - "exchange_test.go"
  - "venue.go"
acceptance_criteria:
  - "AC-EXC-001: SPI 拆分为 7 个能力接口 + 1 个 Exchange 组合接口"
  - "AC-EXC-001: 下游 adapter 可按能力实现单个接口"
  - "AC-EXC-001: Exchange 组合接口嵌入所有能力接口"
  - "AC-EXC-001: VenueProfile、Capability、Venue 类型定义完整"
depends_on: []
estimated_effort: "2h"
priority: P0
status: pending
non_scope:
  - "不实现 adapter 逻辑（仅接口签名）"
  - "不实现 request/error 模型（→TASK-EXC-002/003）"
  - "不实现 Registry（→TASK-EXC-005）"
```

---

## Non-scope

- 不实现 adapter 逻辑（仅接口签名）
- 不实现 request/error 模型（→TASK-EXC-002/003）
- 不实现 Registry（→TASK-EXC-005）

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| ----------- | ----------- | ------------------- |
| FR-EXC-001 | SPI 拆分读写能力接口 | AC-EXC-001: 7 个能力接口 + Exchange 组合接口清晰 |

## Test Plan

| Test Case | Type     | Description |
| --------- | -------- | ----------- |
| TC-EXC-001 | Compile  | 编译期检查 `var _ Exchange = (*Impl)(nil)` 通过 |

## Implementation Notes

- 接口签名与 SPEC §9 Interface Contract 一致
- Exchange 组合接口嵌入所有能力接口，适配器可选择性实现
- Venue/Capability/VenueProfile 在 venue.go 中定义

## Implementation Plan

| Step | Description | Deliverables | Verification |
| ---- | ----------- | ------------ | ------------ |
| 1    | 定义 Venue、Capability、VenueProfile 类型 | `venue.go` | `go build ./...` 通过 |
| 2    | 定义 7 个能力接口 + Exchange 组合接口 | `exchange.go` | `go build ./...` 通过 |
| 3    | 编译期检查测试 | `exchange_test.go` | `go test ./...` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| 接口签名与下游不匹配 | Medium | High | 对照 SPEC §9 |
