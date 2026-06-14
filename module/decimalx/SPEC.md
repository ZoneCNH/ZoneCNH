# decimalx v1.0.0 Spec

Status: Draft
Spec-Version: v1.0.0-plan
Module-Version: v0.2.0 -> v1.0.0
Layer: L2.5 领域共享
Repository: https://github.com/ZoneCNH/decimalx
Source-Plan: /home/zone/Downloads/0615/ZoneCNH-v1.0.0-goal-execution-plans/decimalx-v1.0.0-goal-execution-plan.md
Last-Updated: 2026-06-15

## 1. 范围

`decimalx` 定义 ZoneCNH 金融域共享的定点十进制与货币值对象。它是 L2.5 数值语义根，向上服务市场数据、交易接口、宏观数据与交易域模型。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | `Decimal`、rounding/context、`Money`、`Currency`、JSON/SQL 数值边界 |
| Depends on | `kernel` 的基础错误/契约能力；不得依赖业务域模块 |
| Excludes | 交易所精度规则、账本/税务/估值、策略计算、通用数学 DSL |

## 3. 功能需求

| ID | 需求 |
| --- | --- |
| FR-DEC-001 | `Decimal` 必须不可变，任何系数导出不得暴露内部可变状态。 |
| FR-DEC-002 | Parse 必须采用稳定语法，拒绝空白、指数和非规范格式。 |
| FR-DEC-003 | 字符串输出必须区分规范输出、固定精度输出与调试输出。 |
| FR-DEC-004 | 加减乘必须精确；除法、量化和舍入必须显式携带 rounding/context。 |
| FR-DEC-005 | JSON 表达必须是带引号十进制字符串，避免 JavaScript/JSON number 精度损失。 |
| FR-DEC-006 | SQL scan 必须拒绝 float 输入，防止静默精度损失。 |
| FR-DEC-007 | `Money` 的币种必须参与等价性与运算校验，跨币种加减必须失败。 |
| FR-DEC-008 | 公开错误必须可用 `errors.Is` 识别并保持兼容。 |

## 4. 非功能需求

- 可审计：同一输入在不同机器、时区与运行时必须得到一致输出。
- 可迁移：v1.0.0 后公共 API 破坏性变更必须进入新主版本。
- 可验证：核心算术、格式化、JSON、SQL、Money/Currency 均需 golden 或 property 测试。

## 5. v1.0.0 发布门禁

| 门禁 | 要求 |
| --- | --- |
| API freeze | 公共 API、错误类型、序列化语义完成兼容测试。 |
| 精度门禁 | 不允许 float64 参与公共 decimal/money 输入输出。 |
| 下游门禁 | `domain-market`、`domain-exchange`、`domain-macro`、`domainx` 可编译采用。 |
| CI 门禁 | 单元测试、race、fuzz/property、staticcheck、govulncheck 通过。 |
