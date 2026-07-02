# regime_engine 实现计划

> 来源：`module/regime_engine/SPEC.md` + `tasks/TASK-REGIME_ENGINE-001.md`
> 创建：2026-06-25（issue #1087）

## 实现顺序

1. TASK-REGIME_ENGINE-001: M×S 融合 DecisionCard 生成 — P0
2. TASK-REGIME_ENGINE-002: 状态转移持久化（待拆）— P1
3. TASK-REGIME_ENGINE-003: 可解释性字段补全（待拆）— P1

## 依赖

- `contracts` v1.5.0（已发布，RegimeSnapshot/RegimeCard/DecisionCard P0 DTO）
- `market_regime` v0.2.0（S1-S7，12 tests PASS）
- `macro_regime` v0.2.0（M1-M7，13 tests PASS）
- `bootstrap` v0.2.0（进程组装）
- `kernel` v1.0.0（L0 原语）

## 验证命令

```bash
go test ./... -run TestRegimeEngine
go test -race ./...
go vet ./...
go build ./...
```

## 风险

- M×S 融合冲突门逻辑复杂（7×7=49 组合），需穷举测试
- DecisionCard 字段需与 contracts v1.5.0 P0 DTO 严格对齐
- 当前 13 tests PASS 但 TC 映射未确认（issue #1090）

## 管线阶段

| 阶段 | 状态 | 制品 |
| --- | --- | --- |
| S1 Spec | Draft | SPEC.md（issue #1091 补全中） |
| S2 Matrix | ✅ | TRACEABILITY.md |
| S3 Tasks | ✅ | tasks/TASK-REGIME_ENGINE-001.md |
| S4 Plan | ✅ | 本文件 |
| S5 Prompt | ⬜ | 待建 |
| S6 Evidence | ⬜ | 待归档（13 tests PASS） |
