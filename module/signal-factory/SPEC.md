# signal-factory 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 决策域 · 信号生成
- Module-Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `module/factor-eval`, `module/regime-engine`, `module/feature-store`

---

## 1. 摘要

`signal-factory` 是决策域的信号生成与组合模块。消费 `factor-eval` 的因子评估结果和 `regime-engine` 的 `DecisionCard`，生成加权交易信号。它是分析域到执行域的关键决策节点。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 信号生成接口、信号组合策略、信号权重管理、Signal DTO |
| Depends on | `module/factor-eval`（因子评估）、`module/regime-engine`（DecisionCard）、`module/feature-store`（特征数据） |
| Consumed by | `module/backtestx`（回测）、`module/riskx`（风控检查）、`module/orderx`（订单生成） |
| Excludes | 因子计算（→ factor-engine）、因子评估（→ factor-eval）、订单执行（→ orderx）、风险管理（→ riskx） |

## 3. 功能需求

### FR-001: Signal 生成

WHEN factor-eval 输出评估结果（IC、分层收益）AND regime-engine 输出 DecisionCard（action/risk/permission）
THEN 生成 Signal{FactorWeights, Direction, Confidence, InstrumentKey, Timestamp}
AND Direction 为 {LONG, SHORT, FLAT} 三值枚举
AND Confidence 为 [0,1] float，基于 IC 稳定性和 regime permission 计算

### FR-002: 信号组合

WHEN 多个因子产生信号
THEN 按配置的权重策略（等权/IC加权/regime加权）组合为单一信号
AND 权重总和归一化为 1.0

### FR-003: Regime Gate

WHEN regime-engine DecisionCard.permission = DENY
THEN 对应 instrument 的信号 Direction 强制为 FLAT
AND Confidence 设为 0

### FR-004: Signal DTO

Signal 结构：{SignalID, InstrumentKey, Direction, Confidence, FactorWeights[], RegimeDecision, Timestamp, Expiration}

## 4. 接口契约

```go
type SignalFactory interface {
    Generate(ctx context.Context, evalResults []FactorEvalResult, card DecisionCard) (Signal, error)
    Combine(signals []Signal, weights []float64) (Signal, error)
}

type Signal struct {
    SignalID      string
    InstrumentKey InstrumentKey
    Direction     Direction  // LONG | SHORT | FLAT
    Confidence    float64
    FactorWeights map[string]float64
    RegimeAction  string
    Timestamp     time.Time
    Expiration    time.Time
}
```

## 5. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | Regime DENY 必须覆盖所有因子信号为 FLAT |
| BR-002 | 信号权重总和必须归一化为 1.0 |
| BR-003 | Confidence < 阈值（默认 0.3）时 Direction 强制 FLAT |

## 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始基线 | ZoneCNH |
