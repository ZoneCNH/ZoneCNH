# riskx 实现计划

> 来源：`module/riskx/SPEC.md` + `tasks/TASK-RSK-001.md`
> 创建：2026-06-25（issue #1087）

## 实现顺序

1. TASK-RSK-001: Pre-Trade Risk Check 短路求值 — P0（最小实现已有，7 tests PASS）
2. TASK-RSK-002: Drawdown Control 滞后阈值（待拆）— P1
3. TASK-RSK-003: Kill Switch 持久化（待拆）— P1
4. TASK-RSK-004: Rate Limiting 滑动窗口（待拆）— P1
5. TASK-RSK-005: Concentration Control（待拆）— P2
6. TASK-RSK-006: Risk Metrics 计算（待拆）— P2
7. TASK-RSK-007: Risk Event Audit（待拆）— P2

## 依赖

- `contracts` v1.5.0（SignalIntent P1 DTO）
- `signal_factory` TASK-SIGNAL_FACTORY-001（SignalIntent 产出）
- `bootstrap` v0.2.0
- `kernel` v1.0.0

## 验证命令

```bash
go test ./... -run TestCheckOrder
go test ./... -run TestDrawdownControl
go test ./... -run TestKillSwitch
go test -race ./...
go vet ./...
```

## 风险

- 规则优先级 KillSwitch > Drawdown > PositionLimit > RateLimit 需保证执行顺序
- KillSwitch 状态持久化需重启后恢复
- 当前 7 tests PASS（最小实现），8 TC 中 7 tests 映射未确认（issue #1090）

## 管线阶段

| 阶段 | 状态 | 制品 |
| --- | --- | --- |
| S1 Spec | Spec Approved / Tasks Pending | SPEC.md（361 行） |
| S2 Matrix | ✅ | TRACEABILITY.md |
| S3 Tasks | ✅ | tasks/TASK-RSK-001.md |
| S4 Plan | ✅ | 本文件 |
| S5 Prompt | ⬜ | 待建 |
| S6 Evidence | ⬜ | 待归档（7 tests PASS） |
