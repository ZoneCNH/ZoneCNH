# optimizer 规格

- Status: Draft
- Spec-Version: v0.1.0
- Last-Updated: 2026-06-30
- Layer: 决策域 · 参数优化
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `../factor_engine/`, `../domain_market/`

> 本文档发布 optimizer 基线。运行时实现为 Pending。

---

## 1. 摘要

optimizer 是决策域的参数优化模块，对策略参数执行 Walk-Forward 优化和过拟合检测。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Walk-Forward 优化、网格搜索/贝叶斯优化、参数稳定性分析、过拟合检测（CSCV/PBO） |
| Depends on | backtest_engine（回测结果）、signal_factory（参数空间） |
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

## 7. Acceptance Criteria Registry

待补充。

## 8. 追溯与测试门禁

待补充。

## 9. 版本记录

待补充。

## 10. 错误处理

待补充。

## 11. 边界情况

待补充。

## 12. 目录结构

待补充。

## 13. 依赖

待补充。

## 14. 测试

待补充。

## 15. 性能预算

待补充。

## 16. 可观测性

待补充。

## 17. 安全

待补充。

## 18. 升级兼容性

待补充。

## 19. 发布 DoD

待补充。

## 20. 待解决问题

待补充。

## 21. 运行时边界

待补充。

## 22. 目录结构补充

待补充。

## 23. 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始基线 | ZoneCNH |
