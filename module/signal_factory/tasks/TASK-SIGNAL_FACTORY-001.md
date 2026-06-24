---
TASK-ID: TASK-SIGNAL_FACTORY-001
module: signal_factory
scope: "实现 Signal 生成与 Regime Gate"
spec_ref:
  - "module/signal_factory/SPEC.md#FR-001"
  - "module/signal_factory/SPEC.md#FR-002"
  - "module/signal_factory/SPEC.md#FR-003"
  - "module/signal_factory/SPEC.md#FR-004"
files:
  - "internal/factory.go"
  - "internal/factory_test.go"
  - "pkg/signal_factoryx/signal_factory.go"
acceptance_criteria:
  - "AC-SIGNAL_FACTORY-001: 消费 DecisionCard 生成 SignalIntent[]"
  - "AC-SIGNAL_FACTORY-002: 多信号组合权重归一化"
  - "AC-SIGNAL_FACTORY-003: Regime Gate DENY=FLAT"
  - "AC-SIGNAL_FACTORY-004: Signal DTO 符合 contracts"
depends_on:
  - "TASK-REGIME_ENGINE-001"
estimated_effort: "2d"
priority: P0
status: pending
---

# TASK-SIGNAL_FACTORY-001: Signal 生成与 Regime Gate

## 范围

实现 signal_factory 核心：消费 DecisionCard → 生成 SignalIntent[]，含冲突门 + 强度映射 + 权重归一化 + Regime Gate（DENY=FLAT）。

## 前置

- `contracts` v1.5.0（SignalIntent P1 DTO，PR #12）
- `regime_engine` TASK-REGIME_ENGINE-001（DecisionCard 产出）

## 验证

```bash
go test ./... -run TestSignalFactory
go vet ./...
```

## 来源

- SPEC: `module/signal_factory/SPEC.md`（v1.0.0，386 行 23 节完整，PR #847）
- TRACEABILITY: `module/signal_factory/TRACEABILITY.md`（4 FR + 3 BR + 7 TC + 4 AC）
- Evidence 投影: §8（5 tests PASS，待归档 CI run id）
