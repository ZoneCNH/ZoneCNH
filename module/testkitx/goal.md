# testkitx 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `testkitx` |
| 发布版本 | 1.0.0 |
| 所属层级 | 测试期证据层 / 质量闭环 |
| 稳定级别 | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态 | 1.0 发布基线文档 |
| 发布日期基准 | 2026-06-09 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`testkitx` 的 Goal 是为 xlib 模块和业务接入方提供统一测试工具、测试夹具、契约测试、集成测试环境、故障注入和测试证据采集能力。它的核心价值是让 1.0 发布不是口头声明，而是可以通过自动化证据证明模块稳定、兼容、可回归。

### 1.1 为什么需要这个模块

- 基础库一旦发布 1.0，被大量业务依赖后修复成本很高，必须在发布前建立证据。
- 存储和消息扩展依赖外部系统，仅靠单元测试无法证明真实可用。
- 契约模块需要自动化验证上下游兼容性。
- 故障场景如超时、重试、熔断、网络抖动需要统一注入和验证工具。

### 1.2 1.0 要解决的问题

- 统一测试夹具、Fake、Mock、Stub、Fixture 的使用方式。
- 提供真实依赖集成测试能力。
- 提供契约测试工具和兼容性断言。
- 提供故障注入能力，验证 resiliencx 和外部依赖封装。
- 产出可归档的测试证据包。

### 1.3 目标用户

- 模块开发者
- 测试工程师
- CI/CD 平台维护者
- 架构评审人员
- 业务接入团队

## 2. 1.0 发布目标

- MUST 提供测试基类、断言工具、FakeClock、FakeIdGenerator、FixtureBuilder。
- MUST 提供 Redis、Kafka、NATS、PostgreSQL、ClickHouse、TAOS、OSS/MinIO 的集成测试环境接入规范。
- MUST 提供契约测试断言，至少覆盖 API、事件、错误码和配置契约。
- MUST 提供故障注入：延迟、超时、连接失败、部分失败、重复消息、乱序消息。
- MUST 能生成测试证据包：用例清单、环境信息、覆盖范围、失败详情、兼容性结果。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 模块发布 | redisx 准备发布 1.0 | 运行 testkitx 集成测试并生成证据包 |
| 契约变更 | kafkax 事件 Envelope 新增字段 | 通过契约测试确认旧消费者兼容 |
| 故障验证 | postgresx 查询超时或连接池耗尽 | 注入故障并验证错误码、重试、观测数据 |
| 业务接入 | 业务团队接入 ossx | 使用标准 Fixture 和 Fake 对象编写稳定测试 |
| 分布式锁竞争 | schedulex 或 redisx 在多实例下执行分布式任务 | 通过 FaultInjector 模拟锁竞争、过期和续期失败 |
| 故障恢复 | postgresx 或 kafkax 连接中断后恢复 | 注入连接断开故障，验证重连、重试和状态恢复 |
| 消息顺序性 | kafkax 顺序消费场景 | 注入乱序消息，验证消费者处理顺序和幂等性 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 测试基础设施 | TestContext、TestResource、Fixture、Scenario、EvidenceCollector | 单测和自测通过 |
| Fake/Stub | FakeClock、FakeIdGenerator、FakeConfig、FakeLogger、FakeTracer | 确定性测试通过 |
| 集成环境 | 容器化依赖或外部依赖描述符、生命周期管理 | CI 集成测试通过 |
| 契约测试 | API schema、event schema、error code、config schema 兼容性断言 | 契约破坏测试通过 |
| 故障注入 | 延迟、超时、断连、错误响应、重复消费、慢查询 | 故障场景测试通过 |
| 证据包 | 测试结果、环境、依赖版本、覆盖能力、报告归档 | 证据包 schema 测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供测试工具、夹具、测试资源生命周期管理。
- 提供外部依赖集成测试标准和适配。
- 提供契约测试和兼容性断言。
- 提供测试证据采集和报告结构。

### 5.2 明确非目标

- 不作为生产运行时依赖。
- 不替代业务测试框架本身。
- 不负责业务用例完整性，只提供工具和证据标准。
- 不托管外部中间件集群。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 依赖 kernel；可选依赖 configx/observex 的测试替身。 |
| 下游依赖 | 所有 xlib 模块的测试工程可以依赖 testkitx。 |
| 分层约束 | testkitx 不得进入生产 artifact；必须有依赖隔离和打包检查。 |

| 契约依赖 | MUST 向 contracts 登记测试工具契约、测试证据格式契约和错误码契约。 |
## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| TestContext | 测试上下文和资源注册 | 1.x 内稳定 |
| TestResource | 外部依赖生命周期抽象 | 启动、健康检查、关闭语义稳定 |
| ContractAssert | 契约兼容性断言 | 断言结果模型稳定 |
| FaultInjector | 故障注入扩展点 | 故障类型枚举稳定，可追加 |
| EvidenceReport | 测试证据包模型 | 核心字段稳定 |

### 7.2 1.0 逻辑接口基线

```text
TestContext
  register(resource: TestResource)
  fixture(name): Fixture
  evidence(): EvidenceCollector

TestResource
  start(): ResourceHandle
  health(): HealthState
  stop(): void

ContractAssert
  assertBackwardCompatible(oldContract, newContract): CompatibilityResult
  assertErrorCodesUnique(codes): Result

FaultInjector
  injectLatency(target, duration)
  injectTimeout(target)
  injectDuplicateMessage(target, count)
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| foundationx.test.enabled | 测试工具开关 | 仅测试环境 true | Stable |
| foundationx.test.resources.mode | 集成资源模式 | container / external / disabled | Stable |
| foundationx.test.evidence.dir | 证据包输出目录 | build/xlib-evidence | Stable |
| foundationx.test.timeout | 测试资源启动超时 | 60s | Stable |
| foundationx.test.keep-resources | 失败后是否保留资源 | false | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出测试资源启动、健康检查、关闭和失败原因。
- MUST 输出证据包生成路径。
- SHOULD 对故障注入开始和恢复输出诊断日志。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| foundationx_test_resource_start_total | Counter | resource,status | 测试资源启动次数 |
| foundationx_test_resource_start_duration_ms | Timer | resource,status | 测试资源启动耗时 |
| foundationx_test_contract_assert_total | Counter | contractType,status | 契约断言次数 |
| foundationx_test_fault_injection_total | Counter | faultType,target,status | 故障注入次数 |

### 9.3 Trace / 诊断事件

- MAY 为长耗时集成测试资源启动创建 span。
- MAY 将测试证据中的 traceId 与失败用例关联。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| TEST_RESOURCE_START_FAILED | 容器镜像缺失、端口冲突、外部依赖不可达 | 测试失败并输出资源诊断 |
| TEST_CONTRACT_BROKEN | 新旧契约不兼容 | 发布门禁阻断 |
| TEST_EVIDENCE_WRITE_FAILED | 证据目录不可写 | 测试失败，不允许无证据通过 |
| TEST_FAULT_INJECTION_UNSUPPORTED | 目标资源不支持指定故障 | 跳过或失败由用例声明决定 |

## 11. 安全、稳定性与兼容性要求

- MUST 禁止把测试密钥打包进入生产 artifact。
- MUST 对测试证据中的连接串和凭据脱敏。
- SHOULD 支持测试资源网络隔离，避免误连生产环境。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 自举测试 | testkitx 自身 Fixture、Fake、Evidence、ContractAssert | MUST 通过 |
| 资源测试 | 所有已发布扩展模块的外部依赖生命周期：Redis、PostgreSQL、Kafka、NATS、ClickHouse、TAOS、OSS/MinIO | MUST 通过 |
| 故障注入测试 | 延迟、超时、断连、重复消息 | MUST 通过 |
| 打包隔离测试 | 生产包不包含 testkitx | MUST 通过 |
| 报告测试 | 证据包 schema 和归档结构 | MUST 通过 |

## 13. 1.0 发布验收清单

- 所有 1.0 模块能够声明自己的 testkitx 证据包位置。
- 契约破坏可以被自动化发现。
- 所有已发布扩展模块（Redis、PostgreSQL、Kafka、NATS、ClickHouse、TAOS、OSS/MinIO）的集成测试可在 CI 中重复运行。
- 生产构建中 testkitx 依赖被明确排除。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 扩展更多故障注入类型，例如网络分区和磁盘满。
- 生成质量趋势报告。
- 与发布平台联动形成证据门禁。
