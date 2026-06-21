# regime_engine 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 分析域 · M×S 联合决策
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `../factor_engine/`, `../domain_market/`

> 本文档发布 regime_engine 基线。运行时实现为 Pending。

---

## 1. 摘要

regime_engine 是 M×S 联合决策引擎，融合 market_regime(S) 和 macro_regime(M) 输出，生成 DecisionCard(action/risk/permission)。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | M×S 融合决策逻辑、DecisionCard 生成、三元输出（action/risk/permission） |
| Depends on | market_regime（S1-S7）、macro_regime（M1-M7）、domain_market/domain_macro |
| Consumed by | signal_factory（信号权重）、riskx（风控参数） |
| Excludes | 见上下游模块职责边界 |

## 3. 功能需求

### FR-001: M×S 融合

WHEN WHEN S 和 M 分类输出可用
THEN 按 DecisionMatrix[S][M] 查表生成 action/risk/permission

### FR-002: DecisionCard

WHEN WHEN 融合完成
THEN 输出 DecisionCard{Action, RiskLevel, Permission, RegimeLabel, Confidence}

### FR-003: 状态转移

WHEN WHEN S 或 M 分类变化
THEN 检测 regime transition 并平滑输出（hysteresis）

### FR-004: 可解释性

WHEN WHEN 输出 DecisionCard
THEN 附带决策因子贡献度和 regime 匹配度


## 4. 接口契约

```go
type RegimeEngine interface {
    Decide(ctx context.Context, s SClassification, m MClassification) (DecisionCard, error)
}
type DecisionCard struct {
    Action      string  // LONG_ONLY | SHORT_ONLY | LONG_SHORT | CASH
    RiskLevel   string  // LOW | MEDIUM | HIGH | CRITICAL
    Permission  string  // ALLOW | REDUCE | DENY
    RegimeLabel string  // e.g. "S3_M5"
    Confidence  float64
    Factors     map[string]float64
}

```

## 5. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed，非法数据拒绝处理 |
| BR-002 | 输出数据结构不可变，下游只读消费 |
| BR-003 | 计算不得依赖未来数据（no lookahead） |

## 6. CI 门禁

| Gate | 命令 |
| --- | --- |
| 编译 | `go build ./...` |
| 测试 | `go test ./... -race -count=1` |
| 覆盖率 | `go test -coverprofile=...` (≥80%) |

## 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始基线 | ZoneCNH |
