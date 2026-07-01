# fred 对接 ms_brain 深度分析报告

## 元数据

| 字段 | 值 |
| --- | --- |
| 日期 | 2026-06-22 |
| 分析对象 | `/home/workspace/ms_brain/` 与 `module/fred/` |
| 输出目标 | 补充 `fred` 模块对 `ms_brain` 的下游消费契约 |
| 变更范围 | `module/fred/README.md`、`SPEC.md`、`FEATURES.md`、`ACCEPTANCE.md`、`TRACEABILITY.md`、`IMPLEMENTATION-PLAN.md` |
| 密钥处理 | 只引用 `sre/secrets/env/dev.md` 路径和键名约束，不读取或复制 secret 值 |

## 结论

1. [COMPUTED][HIGH] `/home/workspace/ms_brain` 是宏观状态驱动的加密资产决策系统，其 L1 宏观层、L3 决策矩阵、L4 PIT 记忆层都需要稳定的宏观数据、发布日历、修订版本和 no-lookahead 查询能力。
2. [COMPUTED][HIGH] `fred` 应承担 provider 数据服务职责：FRED/相关宏观序列采集、PIT 历史、修订扫描、发布日历、freshness/degrade 元数据和跨存储事件投递。
3. [COMPUTED][HIGH] `fred` 不应实现 `ms_brain` 的 M/S 状态机、TradePermission、仓位折扣、事件 override 或策略解释逻辑；这些属于下游决策系统。
4. [COMPUTED][HIGH] 本次已把 `ms_brain` 消费画像补入 `module/fred/` 的规格、功能、验收、追溯和实施计划，并新增 `FR-015`、`BR-009`、`AC-009`、`TC-009`。

## 关键证据

| 证据 | 文件 | 对 `fred` 的含义 |
| --- | --- | --- |
| `ms_brain` 使用 M1-M7 宏观叙事、S1-S7 市场状态和 7x7 决策矩阵 | `/home/workspace/ms_brain/README.md` | `fred` 只供给宏观数据和版本，不承接策略矩阵 |
| L1 宏观层包含 LGIP、事件引擎；L4 记忆层要求 PIT | `/home/workspace/ms_brain/README.md` | `fred` 必须支持 PIT/as-of、发布日历和修订事件 |
| 工程状态显示框架文档完成，`framework/` 下暂无可运行代码 | `/home/workspace/ms_brain/README.md` | 当前只能先做 contract fixture，不能声称真实下游 runtime 已通过 |
| `data_sources.yaml` 声明 FRED 源、`FRED_API_KEY`、`pit_enabled: true`、`DFII10`、`T10YIE`、`DFF` 和 freshness/degrade | `/home/workspace/ms_brain/framework/config/data_sources.yaml` | `fred` 需输出 freshness/degrade 元数据和 PIT 版本字段 |
| LGIP 校验报告引用 `BAMLH0A0HYM2`、`T10Y2Y`、`ICSA` 等宏观序列 | `/home/workspace/ms_brain/framework/validation_report_LGIP_v2.1.md` | 这些序列应进入初始 contract fixture |
| `global_macro.yaml` 引用 `FYFSGDA188S`、`FDHBFRBN`、事件驱动/月度/季度/日度调度 | `/home/workspace/ms_brain/framework/config/global_macro.yaml` | `fred` 需支持财政类低频序列和 release-lag 口径 |
| PIT 架构文档说明修订会造成前视偏差，并要求 `observed_at <= trading_time` 查询 | `/home/workspace/ms_brain/framework/06_data_cortex/PIT_ARCHITECTURE.md` | `fred` 的 as-of 查询必须以可获得时间过滤 |
| TAOS PIT spec 要求 append-only revision、vintage query 和 FRED/ALFRED adapter | `/home/workspace/ms_brain/framework/06_data_cortex/02_data_specification_PIT.md` | `fred` 的 TDengine/TAOS 写入应保留 revision 和 vintage |
| 事件系统覆盖 FOMC/CPI/NFP、Before/During/After tag 和 ReduceOnly override | `/home/workspace/ms_brain/specs/market_state_engine/14_事件系统_日历_外生冲击与覆盖规则.md` | `fred` 只输出事件日历和风险标签输入，不输出策略 override 决策 |

## 同步对象与周期

| 对象 | 初始锚点 | 建议周期 | 需要字段 |
| --- | --- | --- | --- |
| 实际利率/通胀/政策利率 | `DFII10`、`T10YIE`、`DFF` | 日度刷新，按发布日历修订扫描 | `reference_date`、`released_at`、`available_at`、`vintage_at`、`data_version` |
| 信用/周期/就业确认 | `BAMLH0A0HYM2`、`T10Y2Y`、`ICSA` | 日度或周度刷新，发布后补扫修订 | 同上，外加 `quality_reasons[]` |
| 财政与流动性补充 | `FYFSGDA188S`、`FDHBFRBN` | 月度/季度，按 lag 窗口重扫 | `source_component`、`release_lag_days`、`revision_num` |
| 发布日历与修订事件 | FOMC、CPI、NFP、release metadata | 事件驱动 + 日度校验 | `event_type`、`starts_at`、`ends_at`、`importance`、`revision_delta` |

## 数据清洗与处理要求

1. [COMPUTED][HIGH] 历史数据必须按 PIT 追加写入，不允许覆盖旧 revision；`as_of` 查询只能返回查询时点已经可获得的数据。
2. [COMPUTED][HIGH] 所有 FRED provider DTO 必须先归一化到 `domain_macro`，再出域给 API、Kafka、ClickHouse 或下游 SDK。
3. [COMPUTED][HIGH] 清洗必须统一缺失值、单位、频率、时区、发布延迟和修订编号，并把异常原因写入 `quality_reasons[]` 或等价质量字段。
4. [COMPUTED][HIGH] freshness/degrade 不应由下游自行推断；`fred` 应输出每个 series 或数据包的 freshness 状态、降级原因和缓存/权威来源。

## 数据缺口与解决方案

| 缺口 | 影响 | 解决方案 |
| --- | --- | --- |
| `ms_brain` 目前主要是文档/spec/YAML，缺真实消费进程 | 无法做端到端 runtime 证明 | 先在 `/home/workspace/fred` 建 `MsBrainContract` fixture；待 `ms_brain` runtime 落地后补 E2E |
| `FDHBFRBN` 可能涉及 FRED 与 Treasury.gov 组合来源 | 单一 FRED provider 可能不能完全覆盖财政口径 | 在 `fred` 契约中保留 `source_component`，必要时由上层聚合器或扩展 provider 补齐 |
| `domain_macro` 实际包路径和字段未在本次证明 | 可能导致实现期字段返工 | 编码前先锁定领域共享层类型，并将 `released_at/available_at/vintage_at/data_version` 设为强制字段 |
| 旧 `/home/workspace/fred` 边界脚本仍有 `Stores=None` 历史口径 | 与七类存储目标冲突 | 阶段 1 更新 boundary gate，允许目标 adapter，禁止直接 infra connection |
| dev FRED 凭证和七类基础设施未在本次验证 | 集成验收不能宣称通过 | 只标记文档契约 Ready；runtime 集成保持 Pending/Not-tested |

## 已补充到 module/fred 的内容

| 文件 | 补充内容 |
| --- | --- |
| `README.md` | 新增 `ms_brain` 消费画像和边界说明 |
| `SPEC.md` | 新增 `FR-015`、`BR-009`、`AC-009`、`TC-009`、初始数据契约和开放问题 |
| `FEATURES.md` | 投影 `FR-015`、`BR-009` 和 `ms_brain` 消费契约完成度 |
| `ACCEPTANCE.md` | 新增 `V-011`、`AC-009`、`TC-009` 和 `MsBrainContract` 验收入口 |
| `TRACEABILITY.md` | 将 `FR-015/BR-009/AC-009/TC-009` 接入 G-SC-005 |
| `IMPLEMENTATION-PLAN.md` | 新增 `C-006`、integration profile 和 `FRED-TASK-007` |

## 后续迭代

1. 在 `/home/workspace/fred` 增加 `ms_brain` integration profile fixture，至少覆盖 `DFII10`、`T10YIE`、`DFF`、`BAMLH0A0HYM2`、`T10Y2Y`、`ICSA`、`FYFSGDA188S`、`FDHBFRBN`。
2. 为 PIT/as-of 查询增加 no-lookahead 单测，使用 revision fixture 证明查询不会暴露未来 vintage。
3. 为发布日历和修订事件增加 Kafka schema fixture，并验证 NATS 控制面不替代 durable event。
4. 对 `freshness/degrade` 增加质量降级测试，覆盖缓存命中、权威存储回放、provider 延迟和缺口告警。
