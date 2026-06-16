# optimizer 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 决策域 · 参数优化
- Module-Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `../factor-engine/`, `../domain-market/`

> 本文档发布 optimizer 基线。运行时实现为 Pending。

---

## 1. 摘要

optimizer 是决策域的参数优化模块，对策略参数执行 Walk-Forward 优化和过拟合检测。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Walk-Forward 优化、网格搜索/贝叶斯优化、参数稳定性分析、过拟合检测（CSCV/PBO） |
| Depends on | backtest-engine（回测结果）、signal-factory（参数空间） |
| Consumed by | strategyx（参数注册）、策略研发 |
| Excludes | 见上下游模块职责边界 |

## 3. 功能需求

### FR-001: Walk-Forward

WHEN WHEN 优化参数
THEN IS 训练→OOS 验证→滚动窗口前移

### FR-002: 过拟合检测

WHEN WHEN 优化完成
THEN PBO < 0.1 且 CSCV 通过


## 4. 接口契约

```go
type Optimizer interface {
    Optimize(ctx context.Context, config OptimizeConfig) (OptimalParams, error)
}
type OptimalParams struct {
    Parameters    map[string]float64
    IS_Sharpe     float64
    OOS_Sharpe    float64
    PBO           float64
    CSCV_Pass     bool
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
