# macro_data 规格

- Status: Approved (Docs Baseline)
- Spec-Version: v0.1.0
- Last-Updated: 2026-07-02
- Last-Created: 2026-06-17
- Layer: 数据域 · 宏观摄取与分发
- Version: v0.1.0-spec
- Related: `module/domain_macro`, `module/contracts`, `module/market_data`

> 本文件发布 macro downstream dispatch port / receiving-side SPEC 的文档基线，不引入运行时代码、依赖或 wire schema。镜像 `module/market_data` 的接收侧设计，适配宏观领域语义（MacroPoint 三时间 + revision + no-lookahead gate）。运行时代码实现进入后续阶段。

---

## 1. 摘要

`macro_data` 是宏观 provider adapter 与内部宏观消费链路之间的接收侧模块。它接收 adapter 已归一化的宏观事件，执行接收侧校验、幂等判定、revision 排序约束、**no-lookahead 可见性门禁**和分发结果表达，并向上游 adapter 返回可审计的 dispatch outcome。

`module/fred`（及 bea/ecb/treasury/…等 10 个宏观 adapter）在采集原始数据后，不直接写入存储、队列或策略入口；它必须通过本规格定义的 macro downstream dispatch port 将归一化事件交给 `macro_data` 接收侧。

`macro_data` 镜像 `market_data`（L3 行情接收侧），但承载宏观领域差异：

| 维度 | market_data（行情） | macro_data（宏观，本模块） |
| --- | --- | --- |
| 领域模型 | `domain_market` MarketFactEnvelope | `domain_macro` MacroPoint |
| 质量门禁 | stale/future/bid<ask | **no-lookahead**（available_at fail-closed） |
| 幂等键 | venue+productLine+instrument+channel+eventTime+seq | provider+series_code+observed_at+revision_version |
| 排序键 | venue+productLine+instrument+channel | provider+series_code（revision_version 单调） |
| 修订语义 | 无（行情不可变） | 有（revision_version / is_preliminary） |
| 下游端口 | `contracts.MarketDataProvider` | `contracts.MacroDataProvider`（§8.1 已定义） |

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | macro downstream dispatch port 语义、接收侧校验、幂等键约束、revision 排序约束、no-lookahead 可见性门禁、ack/reject/failure 分类、分发可观测性要求 |
| Depends on | `module/domain_macro` canonical macro event 语义（MacroPoint 三时间 + revision）；`module/contracts` wire / service contract（MacroDataProvider §8.1 已定义；后续 wire schema 待批准） |
| Consumed by | `module/fred`、`module/bea`、`module/ecb`、`module/treasury`、`module/yield_curve`、`module/uk_cb`、`module/japan_cb`、`module/eastmoney`、`module/jin10`、`module/yahoo` 等宏观 adapter |
| Excludes | provider HTTP API client、provider DTO（FRED/ECB JSON 等）、protobuf/gRPC/REST schema、Kafka/NATS/DB 实现、因子/预测/策略/回测逻辑 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| AcceptedMacroEvent | adapter 已完成来源归一化、时间标注与基础合法性检查后交给 `macro_data` 的事件载荷。它必须引用 `domain_macro` canonical `MacroPoint` 语义，不携带 provider 原始 DTO（FRED/ECB JSON 等）。 |
| MacroDispatchPort | adapter 调用 `macro_data` 接收侧的抽象端口；用于提交单条或批量宏观事件并获取接收结果。镜像 market_data `DownstreamDispatchPort`。 |
| DispatchAck | 接收侧确认事件已被接受，可由后续持久化/队列/消费链路处理。 |
| DispatchReject | 接收侧拒绝事件；通常为不可重试的契约、质量、幂等冲突、排序或 no-lookahead 违规。 |
| DispatchFailure | 接收侧暂时无法完成接收；调用方可按 retry policy 重试。 |
| idempotency_key | 同一 provider、series_code、observed_at、revision_version 与 payload fingerprint 组合出的稳定去重键。 |
| ordering_key | 保证同一 provider + series_code 内 revision 单调递增约束的分区键。 |
| NoLookaheadGate | macro_data 接收侧核心质量门禁：available_at 缺失或晚于决策时间的事件必须被拒绝（fail-closed），防止前视偏差。对齐 `domain_macro` BR-MAC-001/002。 |
| RejectReasonMapping | provider adapter 的 native reject 在 dispatch 适配层映射为 macro_data 统一分类的规则。映射由 adapter 负责，macro_data 接收侧只处理统一分类。 |

## 4. macro downstream dispatch port 契约

### 4.1 端口语义

`MacroDispatchPort` 是文档级端口名称，不是本任务要新增的代码接口。后续实现可用本语义映射为进程内接口、消息总线生产者或 RPC client，但不得改变以下语义：

```text
Dispatch(ctx, AcceptedMacroEvent) -> DispatchOutcome
DispatchBatch(ctx, []AcceptedMacroEvent) -> []DispatchOutcome
```

### 4.2 输入字段要求

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| provider | 是 | 宏观数据来源提供者，例如 FRED、ECB、BEA；取值归属由上游 contract 冻结。 |
| series_code | 是 | 宏观序列标识（如 `GDP`、`CPIAUCSL`、`DGS10`）；不得使用 provider 私有内部 ID 作为唯一键，须经 adapter 归一化。 |
| observed_at | 是 | 经济指标的观测时间点（数据所属时期）；`domain_macro` FR-MAC-001 三时间之一。 |
| released_at | 是 | 数据发布时间（官方公布时间）；`domain_macro` FR-MAC-001 三时间之一。 |
| available_at | 是 | **数据可用时间**（可被回测/策略合法消费的时间）；`domain_macro` FR-MAC-001 三时间之一。**缺失或晚于决策时间时必须拒绝**（no-lookahead gate）。 |
| revision_version | 是 | 修订版本号，非负整数；`domain_macro` FR-MAC-005。同一 series_code+observed_at 多版本用于 deterministic ordering。 |
| is_preliminary | 是 | 是否初值（vs final）；`domain_macro` FR-MAC-002。preliminary 不得覆盖 final，除非 revision_version 更高且可见。 |
| value | 是 | 指标数值；引用 `decimalx.Decimal` 语义（`domain_macro` FR-MAC-007 精度 ADR）。 |
| payload | 是 | 引用 `domain_macro` canonical `MacroPoint` 语义的载荷，不允许 FRED/ECB 原始 DTO。 |
| idempotency_key | 是 | 稳定去重键；重复提交必须产生可审计 outcome。 |
| ordering_key | 是 | 同一排序域内事件必须可串行化处理（provider+series_code）。 |
| source | 是 | 上游 adapter 标识（如 `"fred"`），用于指标分组、审计追踪和多 adapter 来源区分。 |

> 以上共 12 个字段。与 market_data 的 12 字段一一对应，但宏观侧以 provider/series_code/三时间/revision 替代行情侧的 venue/productLine/instrument/channel/seq。

#### 4.2.1 跨模块字段命名映射

`macro_data` 接收侧字段使用 snake_case；在下游实现中，字段命名必须与 `domain_macro` Go 类型、`contracts` JSON tag 保持一致。以下为各方命名对照：

| 概念 | macro_data (接收侧字段) | domain_macro (Go 字段) | contracts (JSON tag) | fred (示例 adapter) |
| --- | --- | --- | --- | --- |
| 数据提供者 | provider | (**domain_macro 内部**) | source (**MacroPoint.Source**) | provider |
| 序列代码 | series_code | SeriesCode | indicator (**MacroPoint.Indicator**) | series_id |
| 观测时间 | observed_at | ObservedAt | (**contracts MacroPoint.Timestamp**) | realtime_start |
| 发布时间 | released_at | ReleasedAt | — | (**adapter 内部**) |
| 可用时间 | available_at | AvailableAt | — | (**adapter 设置**) |
| 修订版本 | revision_version | RevisionVersion | — | (**adapter 设置**) |
| 是否初值 | is_preliminary | IsPreliminary | — | (**adapter 设置**) |
| 指标数值 | value | Value | value (**MacroPoint.Value**) | value |
| 事件载荷 | payload (MacroPoint) | MacroPoint | point (**MacroEvent.Point**) | MacroPoint |
| 幂等键 | idempotency_key | (**macro_data 内部**) | — | idempotency_key |
| 排序键 | ordering_key | (**macro_data 内部**) | — | — |
| 来源适配器 | source | (**macro_data 内部**) | — | — |

> **命名约束**: Go 代码中 struct 字段使用 PascalCase（domain_macro 拥有），JSON 序列化、配置、注册表和 `macro_data` 接收侧字段使用 snake_case；模块、仓库、目录和公开文档链接继续使用 `macro_data`；事件 topic literal 保留 `macro.data`。实现时必须从 domain_macro import 对应类型，不得在 macro_data 内部重新定义同名类型。

### 4.3 输出结果

| Outcome | 可重试 | 语义 |
| --- | --- | --- |
| DispatchAck | 否 | 事件被接收侧接受；重复提交同一 idempotency_key 可返回幂等 ack。 |
| DispatchReject | 否 | 事件违反契约、质量门禁、no-lookahead、幂等冲突或 revision 排序不可恢复；adapter 不得无限重试。 |
| DispatchFailure | 是 | 接收侧内部暂时不可用、背压或下游依赖不可用；adapter 可按退避策略重试。 |

### 4.4 拒绝原因分类

| Reject Reason | 触发条件 | 对标 market_data |
| --- | --- | --- |
| contract_violation | 缺少必填字段、series_code 格式非法、payload 类型不匹配。 | contract_violation（同） |
| quality_rejected | value 非法（NaN/Inf）、observed_at 为零、数据质量标签不可靠。 | quality_rejected（同） |
| **lookahead_violation** | **available_at 缺失、为零，或晚于决策时间（no-lookahead gate fail-closed）。** | ❌ **宏观独有**（行情无此门禁） |
| idempotency_conflict | 同一 idempotency_key 对应不同 payload fingerprint。 | idempotency_conflict（同） |
| ordering_violation | 同一 ordering_key 下 revision_version 倒退、跳跃或 preliminary 非法覆盖 final。 | ordering_violation（同，但宏观侧是 revision 而非 sequence） |
| unsupported_series | series_code 尚未纳入 `macro_data` 接收侧支持矩阵。 | unsupported_channel（行情侧叫 channel） |
| unauthorized | adapter 凭证无效或权限不足；由上游 adapter 验证并映射。 | unauthorized（同） |
| rate_limited | 上游 adapter 或接收侧自身频率超限。 | rate_limited（同） |
| server_unavailable | 接收侧内部依赖（持久化、队列）不可用；adapter 应退避重试。**产出: DispatchFailure（非 DispatchReject），可重试。** | server_unavailable（同） |

> 以上共 9 种 reject reason（比 market_data 8 种多 1 种 `lookahead_violation`，这是宏观领域独有的 no-lookahead 门禁产物）。provider adapter 的 dispatch 适配层负责将 provider-native 分类映射为上述 9 种中的对应项。

#### 4.4.1 provider-native reject 到 macro_data 映射规则（示例：fred）

| fred adapter 分类 | macro_data outcome / reason | 说明 |
| --- | --- | --- |
| retryable | DispatchFailure | 不映射到 reject reason；转 failure 让 adapter 重试 |
| terminal_validation | DispatchReject（子类: contract_violation / quality_rejected / ordering_violation / unsupported_series） | 按具体子类细分 |
| lookahead | DispatchReject / lookahead_violation | **宏观独有**：available_at 缺失或未来数据 |
| terminal_conflict | DispatchReject / idempotency_conflict | 直接映射 |
| unauthorized | DispatchReject / unauthorized | 直接映射（如 FRED api_key 无效） |
| rate_limited | DispatchReject / rate_limited | 直接映射（FRED 120 req/min） |
| server_unavailable | DispatchFailure | fred 侧不可用，adapter 应重试 |

> 其他 provider（bea/ecb/treasury/…）的 native reject 映射规则在各 adapter SPEC 中分别定义，但必须映射到 macro_data 的 9 种统一分类。

## 5. 功能需求

| ID | 需求 | WHEN | THEN |
| --- | --- | --- | --- |
| FR-MACD-001 | dispatch-port | provider adapter 完成事件归一化后提交事件 | 必须调用 macro downstream dispatch port，不得绕过 `macro_data` 直写存储、队列或策略入口。 |
| FR-MACD-002 | canonical-input | 接收侧读取事件载荷 | 载荷必须引用 `domain_macro` canonical `MacroPoint` 语义（含 ObservedAt/ReleasedAt/AvailableAt 三时间 + RevisionVersion/IsPreliminary），不允许 FRED/ECB 原始 DTO 泄漏。 |
| FR-MACD-003 | idempotency | 接收同一 idempotency_key | 相同 payload fingerprint 返回幂等 ack；不同 fingerprint 返回 reject。 |
| FR-MACD-004 | revision-ordering | 接收同一 ordering_key（provider+series_code）的带 revision 事件 | 必须检测 revision_version 倒退、跳跃和重复，并返回明确 outcome。preliminary 不得覆盖 final 除非 revision 更高。 |
| FR-MACD-005 | no-lookahead-gate | available_at 缺失、为零或晚于决策时间 | **必须 fail-closed，返回 lookahead_violation reject**，且记录原因。对齐 `domain_macro` BR-MAC-001/002。 |
| FR-MACD-006 | quality-gate | observed_at、released_at、value 不合法 | 必须 fail-closed，返回 reject，且记录原因分类。 |
| FR-MACD-007 | retry-classification | 接收侧无法完成处理 | 必须区分不可重试 reject 与可重试 failure。 |
| FR-MACD-008 | batch-semantics | 批量提交事件 | 必须逐条返回 outcome，不允许整批成功掩盖单条失败。 |
| FR-MACD-009 | observability | 任一 dispatch 调用完成 | 必须可按 provider/series_code/outcome/reason 统计。 |
| FR-MACD-010 | downstream-port | 实现 `contracts.MacroDataProvider` | macro_data 是 MacroDataProvider 的唯一实现者，向下游（分析域 macro_engine）提供 GetLatest/GetHistory/Subscribe。 |

## 6. 行为约束

| ID | 规则 |
| --- | --- |
| BR-MACD-001 | `macro_data` 不拥有 provider adapter；FRED/ECB 原始响应只能停留在各 adapter 边界内。 |
| BR-MACD-002 | `macro_data` 不拥有 canonical macro entity；领域语义归 `module/domain_macro`。 |
| BR-MACD-003 | `macro_data` 不拥有跨进程 wire schema；protobuf/gRPC/REST schema 归 `module/contracts`。 |
| BR-MACD-004 | 接收侧对 contract、quality、**no-lookahead**、idempotency 与 revision ordering 问题 fail-closed，不做静默修正。 |
| BR-MACD-005 | adapter 不得将 DispatchFailure 当作成功；必须按 retry policy 或上游 backpressure 处理。 |
| BR-MACD-006 | 文档批准前不得新增运行时代码、依赖、存储表或队列 topic。 |
| BR-MACD-007 | **no-lookahead 是宏观数据域的第一安全门禁**：任何缺失 available_at 的点不得进入下游，违反则回测结果不可信（对齐 domain_macro BR-MAC-001）。 |

## 7. 非功能需求

| ID | 类别 | 需求 |
| --- | --- | --- |
| NFR-MACD-001 | 可审计性 | 每个 outcome 必须包含 outcome、reason、idempotency_key、ordering_key、revision_version 与 retryable 分类。 |
| NFR-MACD-002 | 稳定性 | v0.1.0 后 outcome 分类、幂等语义与 no-lookahead 规则不得破坏性变更；变更需迁移说明。 |
| NFR-MACD-003 | 可观测性 | 指标维度至少包含 provider、series_code、outcome、reason。 |
| NFR-MACD-004 | 边界纯净 | 本模块文档与后续 public API 不得暴露 vendor DTO、transport tag 或 storage tag。 |
| NFR-MACD-005 | 回测安全 | no-lookahead gate 必须有独立测试覆盖：available_at 缺失/未来/等于决策时间的边界 case 全部 fail-closed。 |

## 8. Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| --- | --- | --- | --- | --- |
| AC-MACD-001 | FR-MACD-001, BR-MACD-001 | fred SPEC 可明确以 macro downstream dispatch port 作为宏观事件交付边界，禁止直写下游。 | 文档引用检查 | Baseline |
| AC-MACD-002 | FR-MACD-002, BR-MACD-002 | 接收侧输入字段只引用 `MacroPoint` canonical 语义（三时间 + revision），不包含 FRED/ECB DTO 名称或原始响应字段。 | 边界扫描 | Baseline |
| AC-MACD-003 | FR-MACD-003, FR-MACD-004 | 幂等键与 revision 排序键规则已形成后续单元测试基线。 | 任务基线检查 | Baseline |
| AC-MACD-004 | FR-MACD-005, FR-MACD-006, BR-MACD-004, BR-MACD-007 | reject/failure 分类清晰区分 retryable；**no-lookahead gate 独立可测**。 | TRACEABILITY 检查 | Baseline |
| AC-MACD-005 | FR-MACD-008, FR-MACD-009, NFR-MACD-001, NFR-MACD-003 | 批量 outcome 与观测维度覆盖 provider/series_code/outcome/reason。 | TRACEABILITY 检查 | Baseline |
| AC-MACD-006 | FR-MACD-010 | macro_data 是 `contracts.MacroDataProvider`（§8.1 已定义）的唯一实现者。 | 编译期 `var _ contracts.MacroDataProvider` | Baseline |
| AC-MACD-007 | BR-MACD-006 | 本次闭环只更新 markdown 文档，不新增运行时代码或依赖。 | `git diff --check` + 文件列表检查 | Baseline |

## 9. 后续实现门禁

| 门禁 | 要求 | 当前状态 |
| --- | --- | --- |
| Contract Gate | `module/contracts` 已定义 `MacroDataProvider`（§8.1，三方法签名齐全）。 | ✅ 已就绪 — contracts v1.2.0 |
| Domain Gate | `module/domain_macro` 批准 `MacroPoint`（三时间 + revision + IsPreliminary）、`MacroInformationSet` 语义。 | Docs baseline present — domain_macro v1.0.0 SPEC 已定义，运行时冻结待发布 |
| Adapter Gate | 各宏观 adapter SPEC（fred/bea/ecb/…）引用本 dispatch port。 | Pending — 待各 adapter SPEC 补充引用 |
| Reject Mapping Gate | provider-native reject classification 到 macro_data §4.4.1 的映射规则已文档化。 | Baseline（fred 示例已给出；其他 provider 待补） |
| Naming Mapping Gate | 跨模块字段命名映射表（§4.2.1）已纳入 SPEC。 | Baseline Published（本次新增） |
| No-lookahead Test Gate | 后续实现必须覆盖 available_at 缺失/未来/边界 case 的 fail-closed。 | Pending — 无运行时代码 |
| Test Gate | 后续实现必须覆盖幂等、revision 排序、quality fail-closed、retry classification 与 batch partial failure。 | Pending — 无运行时代码 |

## 10. 发布状态与运行时边界

| 项目 | 状态 | 说明 |
| --- | --- | --- |
| MacroDispatchPort SPEC | Baseline | 本 SPEC 已定义端口语义、输入字段、outcome、reject reason、FR/BR/NFR/AC 与后续实现门禁。 |
| Receiving-side SPEC | Baseline | 接收侧 fail-closed、idempotency、revision ordering、no-lookahead gate、batch outcome 与 observability 语义已可被宏观 adapter 引用。 |
| Runtime implementation | Pending | 本次不新增 Go 源码、依赖、wire schema、存储表、队列 topic 或运行时测试声明。 |
| Canonical domain dependency | External / Docs baseline present | `MacroPoint`（三时间 + revision）语义由 `module/domain_macro` 拥有，docs-only 类型定义已存在；运行时冻结待 domain_macro 发布。 |
| Cross-module naming alignment | Baseline Published | §4.2.1 已建立跨模块字段命名映射表。 |
| Provider reject mapping | Baseline（fred 示例） | §4.4.1 已建立 fred-native → macro_data reject 映射规则；其他 provider 待补。 |
| Downstream port | External / Ready | `contracts.MacroDataProvider`（§8.1）已定义，macro_data 是其唯一实现者。 |

### 10.1 Runtime Pending → Published 推进检查清单

在将本模块状态从 `Runtime Pending` 转为 `Published` 之前，必须逐项确认：

- [x] **Contract Gate 通过**: `module/contracts/SPEC.md` §8.1 已定义 `MacroDataProvider`（GetLatest/GetHistory/Subscribe），三方法签名齐全。
- [ ] **Domain Gate 通过**: `module/domain_macro` 运行时发布 `MacroPoint` Go struct（ObservedAt/ReleasedAt/AvailableAt/RevisionVersion/IsPreliminary/SeriesCode/Value）。当前 docs baseline，运行时待冻结。
- [ ] **Adapter Gate 通过**: 至少 1 个宏观 adapter（fred）SPEC 引用 macro downstream dispatch port，且不再将下游交付语义留空。
- [ ] **Reject Mapping 验证**: fred-native → macro_data 9 种 reject 映射规则实现。
- [ ] **Naming Mapping 验证**: dispatch 实现 import `domain_macro` MacroPoint 类型，不重新定义。
- [ ] **No-lookahead Test Gate 通过**: available_at 缺失/为零/晚于决策时间的 case 全部返回 lookahead_violation reject。
- [ ] **Test Gate 通过**: 幂等、revision 排序、quality、retry classification、batch partial failure 测试。

> 以上全部满足后，本模块状态可推进为 `Published`。

---

## 11. 与 market_data 的镜像关系

本模块严格镜像 `module/market_data` 的接收侧设计，以下为映射对照：

| market_data（行情） | macro_data（宏观，本模块） | 差异说明 |
| --- | --- | --- |
| L3 行情摄取与分发 | L3 宏观摄取与分发 | 同层 |
| DownstreamDispatchPort | MacroDispatchPort | 端口镜像 |
| AcceptedMarketEvent | AcceptedMacroEvent | 载荷镜像 |
| 12 字段（venue/productLine/instrument/channel/eventTime/receivedAt/sourceSequence/payload/quality/idempotencyKey/orderingKey/source） | 12 字段（provider/series_code/observed_at/released_at/available_at/revision_version/is_preliminary/value/payload/idempotency_key/ordering_key/source） | 行情时间语义 → 宏观三时间 + revision |
| 8 种 reject reason | 9 种 reject reason（多 `lookahead_violation`） | 宏观独有 no-lookahead 门禁 |
| MarketFactEnvelope | MacroPoint | 领域载荷 |
| stale/future gate | no-lookahead gate（available_at fail-closed） | 核心质量门禁差异 |
| sequence 排序 | revision_version 排序 | 排序语义差异 |
| `contracts.MarketDataProvider` | `contracts.MacroDataProvider` | 下游端口（均已在 contracts §8.1 定义） |
| Consumed by binance 等 13 adapter | Consumed by fred 等 10 adapter | 消费者 |

**镜像原则**：macro_data 不重新发明接收侧架构，而是复用 market_data 已验证的 dispatch port / outcome / reject / fail-closed 模式，仅替换领域语义层（MacroPoint + 三时间 + revision + no-lookahead）。这保证两个聚合层的运维体验一致（相同的 outcome 分类、可观测维度、retry 语义），同时尊重领域差异。

---

## 12. 数据流位置（对齐数据域基础架构报告 §十四/§十五）

```
宏观 provider（FRED/ECB/… 10 adapter）
  采集 + normalize（MacroPoint）+ no-lookahead 标注（available_at）
     │
     ▼  MacroDispatchPort（AcceptedMacroEvent）
macro_data 接收侧（唯一写存储者）
     │
     ├─► validation（series_code/三时间/value 校验）
     ├─► no-lookahead gate（available_at fail-closed）★ 宏观独有
     ├─► idempotency（Redis CheckAndSet，key=series_code+observed_at+revision_version）
     ├─► revision ordering（revision_version 单调，preliminary 不覆盖 final）
     ├─► durable ACK（PG lineage/sync_status）
     └─► dispatch 双写
           ├─► TDengine（macro_{provider} 时序点）
           └─► Kafka（topic: mac.{provider}.point）
                  │
                  ▼ 物化视图 ETL
           ClickHouse（macro_analytics，供回测）
     │
     ▼  contracts.MacroDataProvider
分析域 macro_engine（→ M State）
```

与 market_data 的数据流对称：adapter 采集（零存储）→ 聚合层落库（唯一写存储者）→ contracts 端口 → 下游。

---

## 13. 错误处理

待补充。

## 14. 边界情况

待补充。

## 15. 目录结构

待补充。

## 16. 依赖

| 依赖 | 用途 |
| --- | --- |
| （待补充） | |

## 17. 测试

待补充。

## 18. 性能预算

待补充。

## 19. 可观测性

待补充。

## 20. 安全

待补充。

## 21. CI 门禁

待补充。

## 22. 待解决问题

待补充。

## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0 | 初始文档基线：macro downstream dispatch port、接收侧 SPEC、FR/BR/NFR/AC、no-lookahead gate、与 market_data 镜像关系、后续实现门禁 | ZoneCNH |
