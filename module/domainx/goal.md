# domainx 1.0 Goal 定位与实现标准

| 字段 | 内容 |
|------|------|
| 模块名 | `domainx` |
| 发布版本 | 1.0.1 |
| 所属层级 | L2.5 领域共享层 / 执行域值对象 |
| 稳定级别 | Public API Stable；SPI N/A（纯值对象，无接口）；Internal 可演进 |
| 文档状态 | v1.0.1 已发布（SPEC + TRACEABILITY §1-§7，覆盖率 100%，所有 FR/BR/NFR/AC Done） |
| 发布日期基准 | 2026-06-16 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项；**MAY / 可以** 表示可选能力。

## 1.0 发布判定原则

1. **类型正确优先**：所有金额/价格字段使用 `decimal.Decimal`，禁止 `float64`
2. **不可变性**：值对象创建后字段只读，getter 不暴露可变内部状态
3. **边界清晰**：只定义值对象和枚举常量，不做状态机、计算逻辑、持久化
4. **证据完整**：每个值对象类型都有构造校验测试、JSON round-trip 测试、并发安全测试
5. **可演进**：字段新增向后兼容（optional 语义），字段删除/重命名走 major 版本

## 1. Goal 定位

`domainx` 的 Goal 是提供执行域共享值对象（Order / Fill / Position / Exposure），确保 `risk-engine`、`order-engine`、`portfolio-engine`、`settlement` 之间使用统一的执行语义类型，消除跨模块类型重复定义和精度丢失。

### 1.1 为什么需要这个模块

- 执行域模块（risk-engine / order-engine / portfolio-engine / settlement）需要在模块间传递订单、成交、持仓和风险敞口数据
- 当前缺少执行域 L2.5 共享层，类型定义可能在各模块重复，导致字段不一致和精度丢失
- 数据域已有 `domain-market`（行情值对象）和 `domain-macro`（宏观值对象），执行域需要同等定位的共享层
- 金额字段使用 `float64` 会在多次传递中累积浮点误差，必须统一使用 `decimal.Decimal`

### 1.2 1.0 要解决的问题

- 统一 Order / Fill / Position / Exposure 四种核心值对象定义
- 统一构造校验规则（正数检查、必填检查）
- 统一 JSON 序列化格式（snake_case，对齐 contracts DTO）
- 统一金额精度（decimal.Decimal）
- 保证不可变性（并发安全）

### 1.3 目标用户

- risk-engine 开发者（Position / Exposure）
- order-engine 开发者（Order / Fill）
- portfolio-engine 开发者（Position / Exposure）
- settlement 开发者（Fill / Position）
- signal-factory 开发者（Order）

## 2. 1.0 发布目标

- MUST 提供 Order 值对象及其构造函数，含 quantity/price/symbol 校验
- MUST 提供 Fill 值对象及其构造函数，含 quantity/price/fee 校验
- MUST 提供 Position 值对象，含 MarketValue() 和 UnrealizedPnL() 计算方法
- MUST 提供 Exposure 值对象，含 NetExposureRatio() 除零保护
- MUST 所有金额字段使用 `decimal.Decimal`
- MUST 所有值对象不可变（私有字段 + 公开 getter）
- MUST JSON tag 使用 snake_case
- MUST 构造时校验，无效输入返回明确错误

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
|------|------|-------------|
| 订单创建 | risk-engine 或 signal-factory 构造 Order 传递给 order-engine | 合法参数返回 Order；非法参数返回明确错误 |
| 成交记录 | order-engine 构造 Fill 传递给 settlement | Fill 包含完整成交信息，fee 非负 |
| 持仓查询 | portfolio-engine 构造 Position 传递给 risk-engine | MarketValue() 和 UnrealizedPnL() 精度正确 |
| 风险敞口 | portfolio-engine 构造 Exposure 传递给 risk-engine | NetExposureRatio() 除零安全 |
| JSON 序列化 | 通过 transportx 传输值对象 | round-trip 后字段值一致 |

## 4. 边界与不做什么

| 不在 domainx 做 | 由谁负责 |
|-----------------|----------|
| 订单状态机流转 | order-engine |
| 风控计算（VaR, margin） | risk-engine |
| 组合计算（PnL 汇总, 归因） | portfolio-engine |
| 结算对账逻辑 | settlement |
| 持久化存储 | postgresx / clickhousex |
| 网络传输协议 | contracts / transportx |

## 5. 测试与证据

| 证据类型 | 要求 |
|----------|------|
| 单元测试 | 14 TC（TC-001~014），覆盖构造校验、方法计算、JSON round-trip、并发安全 |
| 覆盖率 | ≥ 80% |
| Benchmark | Order/Fill 构造 < 500ns，Position 计算 < 100ns，JSON round-trip < 1μs |
| Race 检测 | `go test -race` 零告警 |
| Lint/Vet | `golangci-lint` + `go vet` 零告警 |

## 6. Release DoD

- [x] 6 个 FR 全部实现，14 个 TC 全部通过
- [x] SPEC.md Status 更新为 Approved
- [x] TRACEABILITY.md 所有 FR 标记 Done
- [x] 覆盖率 ≥ 80%
- [x] CHANGELOG.md 记录 v1.0.1
- [x] README.md 含类型概览和快速开始
- [x] 所有公开类型有 godoc 注释

## 变更记录

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-16 | v1.0.1 | 已发布：所有 FR/BR/NFR/AC Done，文档对齐发布状态 |
| 2026-06-14 | v1.0.0 | 初始规格基线 |
