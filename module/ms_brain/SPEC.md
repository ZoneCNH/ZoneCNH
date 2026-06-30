# ms_brain 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-30
- Layer: 分析域 · M×S 架构分析
- Version: v0.1.0-draft
- Related: `module/market_regime`, `module/macro_regime`, `module/regime_engine`

---

## 1. 摘要

`ms_brain` 是 M×S 系统架构分析体系，提供市场/宏观双引擎联合分析的理论框架、可视化决策矩阵和架构推演工具。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | M×S DecisionMatrix、架构可视化、决策推演工具、分析文档 |
| Depends on | market_regime（S 分类）、macro_regime（M 分类） |
| Consumed by | regime_engine（决策参考）、策略研发（分析工具） |
| Excludes | 在线 regime 分类、交易执行、实时数据管线 |

## 3. 功能需求

### FR-001: DecisionMatrix

WHEN S 和 M 分类可用
THEN 构建 M×S DecisionMatrix[M1-M7][S1-S7] → {action, risk, permission}
AND 矩阵支持热更新

### FR-002: 可视化

WHEN 架构状态变化
THEN 展示当前 S/M 坐标位置和推荐 action
AND 展示 regime 历史轨迹

### FR-003: 推演

WHEN 假设 S 或 M 变化
THEN 计算推演结果（what-if analysis）
AND 对比不同假设路径的决策差异

## 4. 接口契约

```go
type MSBrain interface {
    GetDecisionMatrix() DecisionMatrix
    Visualize(ctx context.Context) (RegimeMap, error)
    Simulate(ctx context.Context, s SClassification, m MClassification) (DecisionCard, error)
}

type DecisionMatrix map[string]map[string]DecisionCard
```

## 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始基线 | ZoneCNH |
