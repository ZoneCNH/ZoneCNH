# macro_regime 规格

- Status: Docs Baseline Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Layer: 分析域 · 宏观体制 (M 引擎)
- Version: v1.0.0-spec
- Related: `CONSTITUTION.md`, `module/macro_regime/TRACEABILITY.md`

> 本文档发布 `macro_regime` 文档基线，不引入运行时代码、依赖或 wire schema。运行时实现与 `TC-MACRO_REGIME-001`~`TC-MACRO_REGIME-005` 测试进入后续阶段。

## 1. 摘要

`macro_regime` 是分析域的 M 引擎，分析宏观数据流，输出 M1-M7 宏观体制及体制转换概率，并为 `regime_engine` 提供稳定输入。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | M1-M7 宏观体制分类器、宏观指标管线、regime transition 检测 |
| Depends on | `macro_data`（`MacroPoint`）、`domain_macro`、`flowx`（数据管线） |
| Consumed by | `regime_engine`（M 分类输入） |
| Excludes | 交易执行、订单风控、仓位管理、存储与队列实现 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| MacroObservation | 一条进入体制模型的宏观观察值。 |
| RegimeState | 当前宏观体制状态，取值范围为 M1-M7。 |
| TransitionProbability | 当前观测条件下从当前体制转移到其他体制的概率。 |
| MacroFeatureWindow | 用于生成体制特征的时间窗口。 |

## 4. 功能需求

| ID | 需求 | WHEN | THEN |
| --- | --- | --- | --- |
| FR-001 | M 分类 | 宏观数据流可用 | 必须输出 M1-M7 体制分类与 `transition_probability`。 |
| FR-002 | Transition 检测 | 宏观指标变化 | 必须检测 regime transition 并计算概率。 |

## 5. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed，缺失或异常宏观点不得静默修正。 |
| BR-002 | 输出不可变，下游只能读取已冻结体制结果。 |
| BR-003 | 不得使用 lookahead 数据回写历史体制或概率。 |

## 6. 非功能需求

| ID | 类别 | 需求 |
| --- | --- | --- |
| NFR-001 | 可审计性 | 每次体制判断必须可追溯到输入窗口与特征来源。 |
| NFR-002 | 一致性 | 同一输入窗口重复运行必须产出等价结果。 |
| NFR-003 | 可观测性 | 至少暴露体制分布、转移概率与输入窗口覆盖情况。 |
| NFR-004 | 边界纯净 | 文档与后续 public API 不得泄露执行、存储或 vendor DTO 细节。 |

## 7. Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| --- | --- | --- | --- | --- |
| AC-MACRO_REGIME-001 | FR-001 | M 分类口径可独立描述并复现。 | 文档引用检查 | Baseline Published |
| AC-MACRO_REGIME-002 | FR-002 | Transition 检测与概率输出已被明确约束。 | 文档引用检查 | Baseline Published |

## 8. 追溯与测试门禁

| 门禁 | 要求 | 当前状态 |
| --- | --- | --- |
| Traceability Gate | `module/macro_regime/TRACEABILITY.md` 已包含 FR/BR/AC/TC 映射，且 AC ID 与本 SPEC 对齐。 | Baseline Published |
| Test Gate | 后续实现必须覆盖体制分类、transition 检测、fail-closed 与无 lookahead 路径。 | Pending |
| Boundary Gate | 本 SPEC 不定义运行时代码、wire schema、数据库表或队列 topic。 | Baseline Published |

## 9. 版本记录

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-21 | v1.0.0 | 从占位符扩充为完整文档基线，补齐边界、FR、BR、NFR、AC 与测试门禁 | ZoneCNH |

## 10. 错误处理

待补充。

## 11. 边界情况

待补充。

## 12. 目录结构

待补充。

## 13. 依赖

| 依赖 | 用途 |
| --- | --- |
| （待补充） | |

## 14. 测试

待补充。

## 15. 性能预算

待补充。

## 16. 可观测性

待补充。

## 17. 安全

待补充。

## 18. CI 门禁

待补充。

## 19. 升级兼容性

待补充。

## 20. 发布 DoD

待补充。

## 21. 待解决问题

待补充。

## 22. 运行时边界

待补充。

## 23. 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-21 | v1.0.0 | 从占位符扩充为完整文档基线，补齐边界、FR、BR、NFR、AC 与测试门禁 | ZoneCNH |
