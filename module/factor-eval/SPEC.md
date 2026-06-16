# factor-eval 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 分析域 · 因子评估
- Module-Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `../factor-engine/`, `../domain-market/`

> 本文档发布 factor-eval 基线。运行时实现为 Pending。

---

## 1. 摘要

factor-eval 是分析域的因子评估模块，对 factor-engine 产出的因子执行 IC/RankIC 分析、分层回测和稳定性评估。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | IC/RankIC 计算、分层回测（quantile portfolio）、因子换手率分析、因子衰减曲线、评估报告生成 |
| Depends on | factor-engine（因子数据）、feature-store（PIT 特征查询）、domain-market |
| Consumed by | signal-factory（信号权重参考）、backtestx（回测因子表现） |
| Excludes | 见上下游模块职责边界 |

## 3. 功能需求

### FR-001: IC 计算

WHEN WHEN 接收因子时间序列
THEN 计算 Pearson IC 和 RankIC

### FR-002: 分层回测

WHEN WHEN 因子值排序分组
THEN 执行 quantile portfolio 回测，输出各层收益

### FR-003: 换手率分析

WHEN WHEN 因子值变化
THEN 计算 turnover rate = |new_weight - old_weight|

### FR-004: 衰减分析

WHEN WHEN 因子 IC 时间序列可用
THEN 计算 IC decay curve

### FR-005: 评估报告

WHEN WHEN 评估完成
THEN 输出 FactorEvalReport{IC_mean, IC_IR, top_bottom_spread, turnover, decay}


## 4. 接口契约

```go
type FactorEvaluator interface {
    Evaluate(ctx context.Context, factorName string, features []Feature) (FactorEvalReport, error)
}
type FactorEvalReport struct {
    FactorName       string
    IC_Mean          float64
    IC_IR            float64
    RankIC_Mean      float64
    TopBottomSpread  float64
    Turnover         float64
    Decay            []float64
    QuantileReturns  []float64
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
