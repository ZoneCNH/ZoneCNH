# decimalx Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `decimalx` |
| 层级 | L2.5 领域共享 |
| 仓库 | <https://github.com/ZoneCNH/decimalx> |
| 当前版本 | v1.0.0 |
| 目标版本 | v1.0.0 |
| 状态 | v1.0.0 执行计划已落地，待仓库实现 |
| 计划来源 | `/home/zone/Downloads/0615/ZoneCNH-v1.0.0-goal-execution-plans/decimalx-v1.0.0-goal-execution-plan.md` |
| 最后更新 | 2026-06-15 |

## 目标

`decimalx` 为 ZoneCNH 所有金融域模块提供唯一的高精度定点数值基础，覆盖 `Decimal`、`Money` 和 `Currency` 的公开语义。v1.0.0 的目标是冻结可审计、可复现、无浮点误差传播的数值契约，供 `domain_market`、`domain_exchange`、`domain_macro` 与 `domainx` 复用。

## 非目标

- 不实现交易所精度规则库；交易所规则由 `domain_exchange` 或更上层适配层表达。
- 不实现账本、税务、组合估值或会计规则。
- 不提供通用数学 DSL 或策略计算框架。

## v1.0.0 成功标准

- `Decimal` 不可变；系数导出必须 copy，禁止共享内部 `big.Int` 可变状态。
- Parse 语法稳定；拒绝空白、指数和非规范输入。
- `String`、`Canonical`、`FixedString` 输出可预测且有 golden 测试。
- `Add`、`Sub`、`Mul` 精确；`Quo`、`Quantize` 必须显式接收 rounding/context。
- JSON 使用带引号十进制字符串；SQL scan 明确拒绝 float。
- `Money` 跨币种 `Add` / `Sub` fail-closed。
- 错误类型支持 `errors.Is`，并纳入 API 兼容测试。

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | 当前发布仍为 v0.2.0 | 完成 API freeze 后再 tag v1.0.0 |
| P0 | `Money` / `Currency` 归属需要冻结 | 明确由 `decimalx` 负责公共值对象 |
| P0 | 公开 API 兼容测试不足 | 增加 compile-time、golden、fuzz/property 覆盖 |
| P1 | rounding mode 与 context 证据不足 | 补充 benchmark 与资源边界说明 |

## 下游采用门禁

`domain_market`、`domain_exchange`、`domain_macro` 和 `domainx` 的公开价格、数量、金额、费率与名义价值字段不得使用 `float64` 作为 v1.0.0 公共契约。
