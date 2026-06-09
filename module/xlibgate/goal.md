# xlibgate 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `xlibgate` |
| 发布版本 | 1.0.0 |
| 所属层级 | 基座治理入口层 / 模块装配与统一接入 |
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

`xlibgate` 的 Goal 是作为 xlib 基座能力的统一治理入口，负责模块发现、初始化、装配、能力开关、版本兼容检查、全局策略分发和启动期诊断。它让业务侧以一个稳定入口使用 xlib，而不是直接理解每个模块的初始化顺序和兼容关系。

### 1.1 为什么需要这个模块

- xlib 模块数量多，业务如果逐个初始化会导致顺序、依赖、版本和配置问题。
- 1.0 需要一个统一入口暴露基座能力状态，方便启动诊断和治理。
- 模块启用/禁用、策略下发、兼容性检查应在启动期统一处理。
- 业务需要稳定门面，而底层模块可以独立演进。

### 1.2 1.0 要解决的问题

- 统一模块注册、能力发现和生命周期管理。
- 统一检查模块版本和 xlib-standard 兼容性。
- 统一读取配置并装配 observex、resiliencx、schedulex、扩展模块。
- 统一暴露健康状态、能力清单、启动诊断和模块依赖图。
- 统一处理能力开关和全局策略。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 架构治理人员

## 2. 1.0 发布目标

- MUST 提供 XlibGate bootstrap 入口。
- MUST 支持模块注册、依赖拓扑排序、初始化、健康检查、关闭。
- MUST 支持版本兼容性检查，发现不兼容时 fail-fast。
- MUST 支持能力开关和 profile 装配。
- MUST 输出启动诊断报告，包含模块版本、状态、配置摘要和依赖图。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 应用接入 | 新服务接入 xlib 基座 | 通过 XlibGate 一次性初始化所需模块 |
| 启动失败 | redisx 配置缺失或版本不兼容 | 启动期明确失败模块和原因 |
| 能力治理 | 某环境禁用 schedulex 或启用 debug 观测 | 通过配置开关统一生效 |
| 运行诊断 | SRE 需要查看基座模块状态 | 暴露模块健康状态和能力清单 |
| 模块版本升级 | redisx 从 1.0 升级到 1.1，但 kafkax 依赖 redisx 1.0 API | 启动期检测到版本冲突并给出明确的升级路径建议 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 启动入口 | bootstrap、Builder、profile、module scan | 启动集成测试通过 |
| 模块注册 | ModuleDescriptor、依赖声明、能力声明 | 拓扑排序测试通过 |
| 生命周期 | initialize、start、health、stop、close | 生命周期测试通过 |
| 兼容性检查 | 模块版本、标准版本、API/SPI 范围 | 不兼容阻断测试通过 |
| 能力开关 | 按模块和能力启停，支持 profile | 开关测试通过 |
| 策略分发 | 配置、观测、弹性等全局策略传递 | 策略生效测试通过 |
| 诊断报告 | 启动报告、依赖图、健康状态 | 报告快照测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供 xlib 统一初始化和模块生命周期治理。
- 提供模块能力注册和查询。
- 提供版本兼容性检查和启动诊断。
- 提供统一配置和策略下发入口。

### 5.2 明确非目标

- 不是 API Gateway，不处理 HTTP 路由或流量转发。
- 不承载业务服务发现和服务治理全部能力。
- 不替代具体模块能力实现。
- 不替代容器编排平台或运维平台。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 依赖 kernel、configx、observex、resiliencx；可选接入 schedulex 及各扩展模块。 |
| 下游依赖 | 业务服务通过 xlibgate 获取模块实例和能力状态。 |
| 分层约束 | xlibgate 可以协调模块，但不得把所有模块实现代码内聚到自身。 |
| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| XlibGate | 统一入口 | bootstrap/start/stop/health 语义稳定 |
| XlibModule | 模块生命周期接口 | 状态机稳定 |
| ModuleDescriptor | 模块元数据 | name/version/capabilities/dependencies 字段稳定 |
| CapabilityRegistry | 能力注册表 | 查询和获取语义稳定 |
| StartupReport | 启动诊断报告 | 核心字段稳定 |

### 7.2 1.0 逻辑接口基线

```text
XlibGate
  bootstrap(config): XlibRuntime
  health(): HealthReport
  capabilities(): CapabilityRegistry
  shutdown(): void

XlibModule
  descriptor(): ModuleDescriptor
  initialize(ModuleContext)
  start()
  health(): HealthState
  stop()

ModuleDescriptor
  name
  version
  standardVersion
  dependencies
  capabilities
  stability

StartupReport
  modules: list<ModuleStatus>
  dependencies: DependencyGraph
  configSummary: ConfigDigest
  duration: Duration
  status: SUCCESS | PARTIAL | FAILED

ModuleStatus
  name: string
  version: string
  state: INITIALIZED | FAILED | SKIPPED
  duration: Duration
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| foundationx.gate.enabled | 是否启用 xlibgate | true | Stable |
| foundationx.gate.fail-fast | 模块初始化失败是否阻断启动 | true | Stable |
| foundationx.gate.modules.enabled | 启用模块列表 | 按依赖自动 + 显式声明 | Stable |
| foundationx.gate.modules.disabled | 禁用模块列表 | empty | Stable |
| foundationx.gate.compatibility.strict | 是否严格版本兼容检查 | true | Stable |
| foundationx.gate.startup-report.enabled | 是否输出启动报告 | true | Stable |
| foundationx.gate.health.enabled | 是否暴露健康状态 | true | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出模块发现、依赖排序、初始化开始/成功/失败、关闭结果。
- MUST 输出版本兼容检查结果。
- MUST 输出启动诊断报告摘要，敏感配置脱敏。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| foundationx_gate_module_state | Gauge | module,state | 模块状态 |
| foundationx_gate_startup_duration_ms | Timer | status | 基座启动耗时 |
| foundationx_gate_module_init_total | Counter | module,status | 模块初始化次数 |
| foundationx_gate_compatibility_errors_total | Counter | module,reason | 兼容性错误数 |
| foundationx_gate_capabilities_total | Gauge | type | 已注册能力数量 |

### 9.3 Trace / 诊断事件

- MUST 为整体启动创建 bootstrap span，并为每个模块初始化创建子 span。
- SHOULD 输出 MODULE_INITIALIZED、MODULE_FAILED、COMPATIBILITY_REJECTED 诊断事件。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| GATE_MODULE_NOT_FOUND | 配置启用的模块不存在 | 启动阻断 |
| GATE_DEPENDENCY_MISSING | 模块依赖缺失或被禁用 | 启动阻断 |
| GATE_COMPATIBILITY_FAILED | 模块版本或标准版本不兼容 | 启动阻断 |
| GATE_MODULE_INIT_FAILED | 模块初始化失败 | 按 fail-fast 处理 |
| GATE_CAPABILITY_CONFLICT | 多个模块注册同名不可兼容能力 | 启动阻断 |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 对启动报告中的配置、连接串和凭据脱敏。
- MUST 1.0 不对外暴露管理接口，启动报告和模块清单仅限进程内访问。1.1 引入管理端点时 MUST 增加访问控制。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | 依赖拓扑、模块状态机、能力冲突、版本检查 | MUST 通过 |
| 集成测试 | 装配 configx、observex、resiliencx、redisx 示例 | MUST 通过 |
| 失败测试 | 模块缺失、版本不兼容、初始化异常 | MUST 通过 |
| 观测测试 | 启动报告、日志、指标、Trace | MUST 通过 |

## 13. 1.0 发布验收清单

- 业务服务可以通过一个入口完成 xlib 初始化。
- 启动失败能明确定位模块和原因。
- 模块版本不兼容会在启动期被发现。
- 所有能力注册可查询、可诊断。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 支持插件热加载或按需加载。
- 支持运行时能力治理 API。
- 支持可视化依赖图导出。
