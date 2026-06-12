# configx 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `configx` |
| 发布版本 | 1.0.0 |
| 所属层级 | L1 运行时横切能力 / 配置管理 |
| 稳定级别 | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态 | 1.0 发布基线文档（✅ v1.0.0 已发布） |
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

`configx` 的 Goal 是提供统一、可校验、可追踪、可热更新的配置管理能力。它把本地文件、环境变量、启动参数、远程配置源等输入合并为强类型配置快照，并为所有 xlib 模块提供一致的配置读取、默认值、校验、脱敏、变更事件和回滚语义。

### 1.1 为什么需要这个模块

- 配置是所有运行时模块的入口，如果每个模块自行加载配置，会出现优先级、命名、脱敏和校验规则不一致。
- 生产事故中大量问题源于配置错误，1.0 必须具备 fail-fast、来源可见和变更可追踪能力。
- 动态配置必须有快照、校验和回滚，否则热更新会引入不可控风险。
- 所有 xlib 模块需要统一配置命名空间，便于文档和运维管理。

### 1.2 1.0 要解决的问题

- 统一多源配置加载和优先级合并。
- 统一配置绑定到强类型对象。
- 统一必填项、范围、枚举、格式、依赖关系校验。
- 统一敏感配置脱敏和安全输出。
- 统一配置变更事件、热更新和失败回滚策略。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 支持文件、环境变量、启动参数三类基础配置源。
- MUST 支持远程配置源 SPI，但具体配置中心适配器可独立发布。
- MUST 支持强类型绑定、默认值、校验和启动失败策略。
- MUST 支持配置快照和变更事件，热更新必须先校验后生效。
- MUST 为所有配置项提供来源、最终值脱敏展示和版本信息。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 应用启动 | 服务需要加载 xlib 和业务配置 | 生成 ConfigSnapshot，校验通过后应用启动 |
| 环境隔离 | dev/test/prod 使用不同配置 | Profile 合并明确，最终生效配置可解释 |
| 配置热更新 | 限流阈值或日志级别需要动态调整 | 校验通过后发布变更事件；失败则保留旧快照 |
| 故障排查 | 线上行为与预期不一致 | 可以查看配置来源、覆盖链路和脱敏后的最终值 |
| 配置回滚 | 热更新后业务指标异常，需要快速回退 | 触发回滚后恢复上一快照并发布回滚事件 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 配置源 | FileSource、EnvSource、ArgsSource、RemoteSource SPI | 加载优先级测试通过 |
| 配置合并 | 命名空间、profile、优先级、覆盖链路 | 快照差异测试通过 |
| 强类型绑定 | prefix 绑定对象、类型转换、默认值、枚举 | 绑定异常测试通过 |
| 配置校验 | 必填、范围、正则、跨字段依赖、自定义 Validator | 启动门禁测试通过 |
| 热更新 | watch、diff、validate、publish、rollback | 热更新集成测试通过 |
| 脱敏展示 | password、secret、token、key 等字段自动脱敏 | 安全快照测试通过 |
| 配置文档 | 从配置模型生成配置参考 | 文档生成测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供配置加载、合并、绑定、校验、快照、热更新和变更通知。
- 定义 xlib 模块配置命名规范和统一读取方式。
- 提供远程配置源 SPI。
- 为 observex 输出配置加载和刷新观测信息。

### 5.2 明确非目标

- 不替代配置中心产品。
- 不管理密钥生命周期，只负责读取后脱敏和安全暴露。
- 不决定业务配置值是否合理，只执行声明式校验。
- 不负责配置发布审批流程。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 无外部依赖（foundationx exit 已完成，kernel 不再被依赖）；可选接入 observex 输出日志和指标。 |
| 下游依赖 | observex、resiliencx、schedulex、redisx、kafkax 等模块通过 configx 获取配置。 |
| 分层约束 | configx 不能依赖具体存储扩展模块；远程源通过 SPI 接入。 |
| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| ConfigProvider | 统一配置读取入口 | get/bind/snapshot 语义稳定 |
| ConfigSource SPI | 配置源扩展点 | 加载结果、优先级、版本字段稳定 |
| ConfigSnapshot | 不可变配置快照 | 字段可追加，不得改变来源链路语义 |
| ConfigChangeEvent | 热更新事件 | 事件类型、diff、version 稳定 |
| ConfigValidator | 校验扩展点 | Violation 结构稳定 |

### 7.2 1.0 逻辑接口基线

```text
ConfigProvider
  get(key, type): Optional<T>
  require(key, type): T
  bind(prefix, class): T
  snapshot(): ConfigSnapshot
  subscribe(prefix, listener): Subscription

ConfigSource
  name(): string
  priority(): int
  load(profile): ConfigDocument
  watch(listener): Optional<Watcher>

ConfigSnapshot
  version: string
  profile: string
  values: map<string, ConfigValue>
  sources: list<SourceRef>
  diff(previous): ConfigDiff
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| foundationx.config.enabled | 是否启用 configx | true | Stable |
| foundationx.config.profile | 当前环境 profile | default；生产必须显式设置 | Stable |
| foundationx.config.locations | 本地配置文件位置 | 按平台默认 | Stable |
| foundationx.config.fail-fast | 启动校验失败是否阻断 | true | Stable |
| foundationx.config.mask-patterns | 敏感字段匹配规则 | password,secret,token,key | Stable |
| foundationx.config.watch.enabled | 是否启用热更新 | false | Stable |
| foundationx.config.refresh.timeout | 配置刷新超时 | 5s | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出配置源加载成功/失败、profile、快照版本、配置项数量。
- MUST 对配置值做脱敏后再打印。
- MUST 在热更新失败时输出失败原因和回滚结果。
- SHOULD 输出配置 diff 摘要，但不得输出敏感值。
- MUST 在配置变更时输出审计日志，包含变更来源、操作者、变更项、旧值脱敏、新值脱敏。
- MUST 日志字段包含 traceId、requestId、source、profile。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| foundationx_config_load_total | Counter | source,status,profile | 配置加载次数 |
| foundationx_config_load_duration_ms | Timer | source,status | 配置加载耗时 |
| foundationx_config_refresh_total | Counter | status,reason | 配置刷新次数 |
| foundationx_config_validation_errors_total | Counter | field,rule | 配置校验失败数 |
| foundationx_config_active_snapshot | Gauge | profile,version | 当前配置快照版本标记 |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- SHOULD 为远程配置源加载创建 span。
- MUST 在 ConfigChangeEvent 中附带 requestId 或 operator 信息，如果来源可用。
- MAY 输出 CONFIG_LOADED、CONFIG_REFRESHED、CONFIG_ROLLED_BACK 诊断事件。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| CONFIG_SOURCE_UNAVAILABLE | 配置文件不存在、远程源不可达 | 启动阶段按 fail-fast 决定是否阻断；刷新阶段保留旧快照 |
| CONFIG_BIND_FAILED | 类型转换失败、枚举不合法 | 返回明确字段路径，启动阻断 |
| CONFIG_VALIDATION_FAILED | 必填缺失、范围非法、跨字段冲突 | 启动或刷新阻断 |
| CONFIG_REFRESH_REJECTED | 新配置校验失败 | 不生效，发布失败事件 |
| CONFIG_SECRET_EXPOSED | 检测到敏感值尝试明文输出 | 阻断输出并记录安全告警 |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 对 ConfigSnapshot 的展示接口默认脱敏。
- MUST 禁止在普通日志中输出完整连接串和密钥。
- SHOULD 支持配置项标注 sensitive、dynamic、deprecated。
- MUST 远程配置源加载默认要求 TLS；如使用明文传输，必须在文档中声明风险并提供配置开关。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | 多源合并、优先级、类型绑定、默认值、校验规则 | MUST 通过 |
| 集成测试 | 文件 + 环境变量 + 启动参数组合加载 | MUST 通过 |
| 热更新测试 | watch、diff、校验失败回滚、监听器异常隔离 | MUST 通过 |
| 安全测试 | 敏感字段脱敏、日志泄漏扫描 | MUST 通过 |
| 兼容性测试 | 配置项废弃和新增不破坏旧配置 | MUST 通过 |

## 13. 1.0 发布验收清单

- 所有 xlib 运行时模块均可通过 configx 读取配置。
- 配置错误可以在启动期被定位到字段级。
- 热更新失败不会污染当前有效配置。
- 配置文档可自动或半自动生成。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 提供主流配置中心适配器。
- 支持配置灰度和按租户配置。
- 支持配置 schema 导出和 IDE 提示。
