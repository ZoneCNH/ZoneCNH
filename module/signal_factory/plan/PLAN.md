# signal_factory 实现计划

> 来源：`module/signal_factory/SPEC.md` + `tasks/TASK-SIGNAL_FACTORY-001.md`
> 创建：2026-06-25（issue #1087）

## 实现顺序

1. TASK-SIGNAL_FACTORY-001: Signal 生成与 Regime Gate — P0
2. TASK-SIGNAL_FACTORY-002: 多信号组合权重归一化（待拆）— P1
3. TASK-SIGNAL_FACTORY-003: Confidence 阈值过滤（待拆）— P1

## 依赖

- `contracts` v1.5.0（SignalIntent P1 DTO，PR #12）
- `regime_engine` TASK-REGIME_ENGINE-001（DecisionCard 产出）
- `bootstrap` v0.2.0
- `kernel` v1.0.0

## 验证命令

```bash
go test ./... -run TestSignalFactory
go test -race ./...
go vet ./...
go build ./...
```

## 风险

- DecisionCard→SignalIntent 映射需处理冲突门 DENY=FLAT 语义
- 权重归一化需保证数值稳定性（decimalx）
- 当前 5 tests PASS，TC 映射未确认（issue #1090）

## 管线阶段

| 阶段 | 状态 | 制品 |
| --- | --- | --- |
| S1 Spec | Approved | SPEC.md v1.0.0（386 行，PR #847） |
| S2 Matrix | ✅ | TRACEABILITY.md |
| S3 Tasks | ✅ | tasks/TASK-SIGNAL_FACTORY-001.md |
| S4 Plan | ✅ | 本文件 |
| S5 Prompt | ⬜ | 待建 |
| S6 Evidence | ⬜ | 待归档（5 tests PASS） |
