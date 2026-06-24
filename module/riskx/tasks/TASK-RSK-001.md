---
TASK-ID: TASK-RSK-001
module: riskx
scope: "实现 Pre-Trade Risk Check 短路求值"
spec_ref:
  - "module/riskx/SPEC.md#FR-001"
  - "module/riskx/SPEC.md#BR-001"
files:
  - "internal/checker.go"
  - "internal/checker_test.go"
  - "pkg/riskx/riskx.go"
acceptance_criteria:
  - "AC-RSK-001: CheckOrder 短路求值，首个失败即拒绝；全部规则逐项校验"
depends_on:
  - "TASK-SIGNAL_FACTORY-001"
estimated_effort: "1d"
priority: P0
status: pending
---

# TASK-RSK-001: Pre-Trade Risk Check 短路求值

## 范围

实现 riskx 核心 CheckOrder：依次检查规则（短路求值，首个失败即拒绝）—— order.qty*price ≤ maxOrderValue / netQty+order.qty ≤ maxPositionSize / dailyOrders+1 ≤ maxDailyOrders / dailyVolume+order.qty*price ≤ maxDailyVolume / symbol 不在禁止交易列表。

## 前置

- `contracts` v1.5.0（SignalIntent P1 DTO）
- `signal_factory` TASK-SIGNAL_FACTORY-001（SignalIntent 产出）
- 当前已有最小实现（7 tests PASS，仓位上限/最大持仓/熔断门禁）

## 验证

```bash
go test ./... -run TestCheckOrder
go vet ./...
```

## 来源

- SPEC: `module/riskx/SPEC.md`（361 行）
- TRACEABILITY: `module/riskx/TRACEABILITY.md`（8 FR + 5 BR + 5 NFR + 8 TC + 8 AC）
- Evidence 投影: §8（7 tests PASS，待归档 CI run id）
