# ADR-007: 三引擎契约设计

> 状态：Accepted
> 日期：2026-06-25
> 决策者：ZoneCNH
> 关联：contracts v1.5.0, module/regime_engine/SPEC.md

---

## 背景

分析域三引擎（market_regime S1-S7 / macro_regime M1-M7 / regime_engine M×S）需协作产出 DecisionCard 供决策域消费。若无稳定契约，三引擎紧耦合，无法独立演进。

---

## 决策

通过 `contracts` v1.5.0 P0 DTO 桥接三引擎：

1. `RegimeSnapshot` — S+M 状态快照（输入）
2. `RegimeCard` — 单引擎输出（S 或 M）
3. `DecisionCard` — M×S 融合输出（action/risk_tier/position_caps/trade_permission）
4. 3 个 Provider ports：`MarketRegimePort` / `MacroRegimePort` / `RegimeEnginePort`

---

## 替代方案

### 方案 A：直接函数调用

- 优点：简单
- 缺点：紧耦合，无法独立测试
- 未选择：违反域间解耦原则

### 方案 B：事件总线

- 优点：松耦合
- 缺点：异步语义复杂，DecisionCard 需同步
- 未选择：过度设计

---

## 后果

### 正面影响

- 三引擎可独立开发/测试/发布
- DecisionCard 作为跨域稳定 DTO
- P1 SignalIntent DTO 已升入（PR #12）

### 负面影响

- contracts 变更需三引擎同步

### 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
| --- | --- | --- | --- |
| DTO 字段变更 | 中 | 高 | P0/P1 分级 + 兼容别名 |

---

## 实施计划

| 里程碑 | 目标 | 验收 |
| --- | --- | --- |
| P0 DTO | RegimeSnapshot/RegimeCard/DecisionCard + 3 ports | ✅ PR #10 |
| P1 DTO | SignalIntent 升入 | ✅ PR #12 |
| P2 别名 | 兼容投影别名 | ✅ |

---

## 参考

- contracts v1.5.0 GitHub Release
- module/regime_engine/SPEC.md §9
