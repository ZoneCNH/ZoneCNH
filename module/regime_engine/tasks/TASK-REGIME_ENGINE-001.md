---
TASK-ID: TASK-REGIME_ENGINE-001
module: regime_engine
scope: "实现 M×S 融合 DecisionCard 生成"
spec_ref:
  - "module/regime_engine/SPEC.md#FR-001"
  - "module/regime_engine/SPEC.md#FR-002"
  - "module/regime_engine/SPEC.md#FR-003"
  - "module/regime_engine/SPEC.md#FR-004"
files:
  - "internal/engine.go"
  - "internal/engine_test.go"
  - "pkg/regime_enginex/regime_engine.go"
acceptance_criteria:
  - "AC-REGIME_ENGINE-001: M×S 融合输出 DecisionCard"
  - "AC-REGIME_ENGINE-002: DecisionCard 含 action/risk_tier/position_caps"
  - "AC-REGIME_ENGINE-003: 状态转移可追溯"
  - "AC-REGIME_ENGINE-004: 输出可解释性字段完整"
depends_on: []
estimated_effort: "2d"
priority: P0
status: pending
---

# TASK-REGIME_ENGINE-001: M×S 融合 DecisionCard 生成

## 范围

实现 regime_engine 核心：接收 market_regime S 状态 + macro_regime M 状态，融合生成 DecisionCard（含 action A-E / risk_tier / position_caps / trade_permission）。

## 前置

- `contracts` v1.5.0 已发布（RegimeSnapshot / RegimeCard / DecisionCard P0 DTO）
- `market_regime` v0.2.0（S1-S7，12 tests PASS）
- `macro_regime` v0.2.0（M1-M7，13 tests PASS）

## 验证

```bash
go test ./... -run TestRegimeEngine
go vet ./...
```

## 来源

- SPEC: `module/regime_engine/SPEC.md`（23 节完整结构，issue #1091 补全后）
- TRACEABILITY: `module/regime_engine/TRACEABILITY.md`（4 FR + 3 BR + 7 TC + 4 AC）
- Evidence 投影: §8（13 tests PASS，待归档 CI run id）
