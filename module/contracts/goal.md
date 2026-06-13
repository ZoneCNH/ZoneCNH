# contracts 发布版本 1.0.1 Goal 定位与实现标准

| 字段         | 内容                                           |
| ------------ | ---------------------------------------------- |
| 模块名       | `contracts`                                    |
| 发布版本     | 1.0.1-spec                                     |
| 所属层级     | 稳定契约层 / 跨模块跨服务兼容性                |
| 稳定级别     | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态     | 1.0.1 规格基线文档                              |
| 发布日期基准 | 2026-06-14                                     |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`contracts` 的 Goal 是定义并维护 xlib 体系长期稳定演进所需的契约体系，覆盖 API 契约、事件契约、错误码契约、数据模型契约、配置契约、兼容性规则、版本演进规则和契约测试输入。它的核心价值是让跨模块、跨服务、跨语言、跨版本协作具备明确边界和可验证兼容性。

### 1.1 为什么需要这个模块

- 基座模块 1.0 发布后需要长期兼容，契约必须被显式管理。
- API、事件、错误码和配置项如果无版本规则，会导致上下游同时发布和强耦合。
- 消息事件和外部 API 需要支持新增字段、废弃字段、兼容消费者。
- 契约测试需要稳定输入，避免只靠人工评审发现破坏性变更。

### 1.2 1.0 要解决的问题

- 统一契约类型：API、Event、Error、Data、Config、Observation。
- 统一契约版本、状态、Owner、兼容性声明。
- 统一向后兼容和破坏性变更规则。
- 统一契约测试和 diff 检查。
- 统一废弃、迁移和移除流程。

### 1.3 目标用户

- 模块 Owner
- 业务服务 Owner
- 架构治理人员
- 测试工程师
- 集成方 / SDK 维护者

## 2. 1.0 发布目标

- MUST 定义 ContractDescriptor 标准模型。
- MUST 支持 API、Event、ErrorCode、Config、DataModel 五类契约登记。
- MUST 提供兼容性规则：新增可选字段允许，删除/重命名/类型收窄为破坏性变更。
- MUST 提供契约 diff 和契约测试输入格式。
- MUST 与 testkitx 集成，发布前识别破坏性变更。

## 3. 核心场景

| 场景       | 说明                            | 1.0 期望结果                          |
| ---------- | ------------------------------- | ------------------------------------- |
| API 升级   | 服务接口新增响应字段            | 判断为兼容变更，契约版本 minor 增加   |
| 事件演进   | Kafka 事件 payload 新增可选字段 | 旧消费者可继续消费，契约测试通过      |
| 错误码治理 | redisx 新增错误码               | 检查错误码段和分类不冲突              |
| 配置变更   | configx 废弃旧配置项            | 标记 deprecated，给出替代项和移除版本 |

## 4. 能力范围

| 能力域     | 1.0 必须具备的能力                                        | 验收方式           |
| ---------- | --------------------------------------------------------- | ------------------ |
| 契约模型   | ContractDescriptor、version、owner、status、compatibility | 模型测试通过       |
| API 契约   | 请求/响应、状态码、错误码、认证、分页                     | API diff 测试通过  |
| 事件契约   | topic/subject、Envelope、payload schema、headers          | 事件兼容测试通过   |
| 错误契约   | 错误码段、分类、可重试、用户消息                          | 错误码冲突测试通过 |
| 配置契约   | 配置项、默认值、动态性、敏感性、废弃信息                  | 配置契约测试通过   |
| 兼容性检查 | diff、破坏性判定、迁移建议                                | 兼容性测试通过     |
| 契约发布   | 契约包、版本、变更日志、签名/校验和                       | 发布测试通过       |

## 5. 职责边界

### 5.1 模块内职责

- 定义契约模型和契约目录。
- 提供兼容性规则和破坏性变更判定。
- 提供契约测试输入和 diff 结果模型。
- 维护 xlib 模块公开契约和版本状态。

### 5.2 明确非目标

- 不实现具体业务 API。
- 不替代接口文档站点，但可为其提供输入。
- 不允许用自然语言说明代替机器可检查契约。
- 不绕过模块 Owner 直接修改契约。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束                                                                                                                                                                                          |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 上游依赖 | 依赖 xlib-standard 的规则；依赖 kernel 的基础模型（Result/XError 等）。                                                                                                                       |
| 下游依赖 | 所有运行时模块 MUST 向 contracts 登记契约：configx、observex、resiliencx、schedulex、xlibgate、redisx、kafkax、natsx、postgresx、taosx、ossx、clickhousex；testkitx SHOULD 登记测试工具契约。 |
| 分层约束 | contracts 管契约，不管实现；实现模块必须反向证明符合契约。                                                                                                                                    |

## 7. 对外契约

### 7.1 公开能力面

| 契约                | 定位           | 1.0 稳定承诺             |
| ------------------- | -------------- | ------------------------ |
| ContractDescriptor  | 契约元数据     | 核心字段稳定             |
| CompatibilityReport | 兼容性检查结果 | 结果分类稳定             |
| ContractDiff        | 契约差异模型   | diff 类型稳定            |
| ContractRegistry    | 契约登记接口   | 登记和查询语义稳定       |
| ContractTestSpec    | 契约测试输入   | 测试字段稳定             |
| MessageEnvelope     | 消息信封基线   | 共享字段稳定，模块可扩展 |

### 7.2 1.0 逻辑接口基线

```text
ContractDescriptor
  id
  type: API | EVENT | ERROR | CONFIG | DATA | OBSERVATION
  name
  version
  owner
  status: draft | stable | deprecated | removed
  schemaRef
  compatibility: backward | forward | none
  since
  deprecatedSince?
  removeAfter?

CompatibilityReport
  compatible: boolean
  level: patch | minor | major
  breakingChanges: list<BreakingChange>
  warnings: list<Warning>

MessageEnvelope (baseline for cross-module message compatibility)
  eventId: string          — 全局唯一消息标识
  schemaVersion: string    — 消息 schema 版本
  traceId: string          — 分布式追踪 ID
  payload: T               — 业务载荷
  headers: Map<string, string> — 扩展头信息

  Modules extend MessageEnvelope with domain-specific fields:
    kafkax EventEnvelope<T>:  + eventType, source, occurredAt, idempotencyKey
    natsx NatsMessageEnvelope: + subject, messageId

  All message modules MUST include the 5 baseline fields.
  Module-specific fields MUST NOT conflict with baseline field names.

Compatibility rules:
  Add optional field -> compatible
  Add required field -> breaking
  Remove field -> breaking
  Rename field -> breaking
  Widen enum with tolerant consumer -> compatible with warning
  Narrow type/range -> breaking
```

## 8. 配置契约

| 配置项                                 | 含义                    | 默认值 / 要求            | 稳定性 |
| -------------------------------------- | ----------------------- | ------------------------ | ------ |
| foundationx.contracts.enabled          | 是否启用契约检查        | true                     | Stable |
| foundationx.contracts.registry         | 契约目录位置            | contracts/               | Stable |
| foundationx.contracts.fail-on-breaking | 破坏性变更是否阻断      | true                     | Stable |
| foundationx.contracts.allow-draft      | 是否允许 draft 契约发布 | false for stable release | Stable |
| foundationx.contracts.report.dir       | 契约报告输出目录        | build/contract-report    | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出契约加载、diff 检查、兼容性结果和失败原因。
- MUST 对破坏性变更输出 contractId、oldVersion、newVersion、changeType。
- SHOULD 输出 deprecated 契约使用告警。

### 9.2 指标

| 指标名                                   | 类型    | 标签            | 说明             |
| ---------------------------------------- | ------- | --------------- | ---------------- |
| foundationx_contracts_total              | Gauge   | type,status     | 契约数量         |
| foundationx_contracts_check_total        | Counter | type,status     | 契约检查次数     |
| foundationx_contracts_breaking_total     | Counter | type,changeType | 破坏性变更数量   |
| foundationx_contracts_deprecated_total   | Gauge   | type            | 废弃契约数量     |
| foundationx_contracts_report_duration_ms | Timer   | status          | 契约报告生成耗时 |

### 9.3 Trace / 诊断事件

- SHOULD 为发布期契约检查创建 span。
- MAY 将契约检查报告 ID 写入发布流水线 trace。

## 10. 错误模型与失败策略

| 错误类别                  | 典型原因                       | 1.0 处理策略              |
| ------------------------- | ------------------------------ | ------------------------- |
| CONTRACT_NOT_FOUND        | 引用的契约不存在               | 发布阻断                  |
| CONTRACT_SCHEMA_INVALID   | 契约 schema 格式非法           | 发布阻断                  |
| CONTRACT_BREAKING_CHANGE  | 检测到破坏性变更               | 发布阻断或要求 major 版本 |
| CONTRACT_VERSION_CONFLICT | 同一契约版本重复发布但内容不同 | 发布阻断                  |
| CONTRACT_DEPRECATED_USAGE | 仍在使用废弃契约               | 告警或按门禁策略处理      |

## 11. 安全、稳定性与兼容性要求

- MUST 对契约中的示例数据做脱敏，不得包含真实密钥、身份证件、手机号等敏感信息。
- MUST 为外部暴露 API 契约标注认证和权限要求。
- SHOULD 支持契约包校验和，避免发布物被篡改。

## 12. 测试证据要求

| 测试类型     | 必须覆盖内容                                                                          | 发布门禁  |
| ------------ | ------------------------------------------------------------------------------------- | --------- |
| 单元测试     | ContractDescriptor、version、status、diff 类型                                        | MUST 通过 |
| 兼容性测试   | 新增/删除/重命名/类型变化/枚举变化                                                    | MUST 通过 |
| 集成测试     | 与 testkitx 证据包和 kafkax 事件契约集成                                              | MUST 通过 |
| 消息信封测试 | kafkax EventEnvelope 和 natsx NatsMessageEnvelope 均包含 MessageEnvelope 5 个基线字段 | MUST 通过 |
| 发布测试     | 契约包生成、报告生成、版本冲突检测                                                    | MUST 通过 |
| 安全测试     | 契约示例数据敏感信息扫描                                                              | MUST 通过 |

## 13. 1.0 发布验收清单

- 所有 1.0 Public API、事件、错误码、配置项都有契约登记。
- 破坏性变更可自动识别。
- 废弃契约必须有替代方案和移除版本。
- 契约报告可作为发布门禁证据。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 支持多语言 SDK 生成。
- 支持契约注册中心和在线浏览。
- 支持消费者驱动契约测试增强。
