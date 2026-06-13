# contracts 发布版本 v1.0.1 Goal 定位与实现标准

| 字段         | 内容                                           |
| ------------ | ---------------------------------------------- |
| 模块名       | `contracts`                                    |
| 发布版本     | v1.0.1-spec                                   |
| 所属层级     | L1 基础能力 / 契约层                            |
| 稳定级别     | Public API Stable（端口接口）、DTO Stable、Topic 常量 Stable |
| 文档状态     | v1.0.1 规格基线文档                              |
| 发布日期基准 | 2026-06-14                                     |
| 对齐权威源   | CONSTITUTION §P7, ARCHITECTURE.md              |

## 术语约定

本文档中的 **MUST / 必须** 表示 v1.0 发布阻断项；**SHOULD / 应该** 表示推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力。

## v1.0 发布判定原则

1. **稳定优先**：公开端口接口、DTO 字段、Topic 常量一旦进入 v1.0，默认需要向后兼容。
2. **边界清晰**：contracts 只定义跨域稳定契约（端口接口、事件协议、DTO），不承载业务逻辑、消息队列实现或存储。
3. **证据完整**：每个 MUST 能力都必须有编译期检查、单元测试或契约测试证明。
4. **可演进**：v1.0 允许通过 semver 管理变更，breaking change 必须触发 major 版本升级。

## 1. Goal 定位

`contracts` 的 Goal 是为 FoundationX 跨域通信定义和维护稳定契约体系。它是域间通信的唯一合法通道，覆盖：

- **数据端口**：`MarketDataProvider`（行情数据）、`MacroDataProvider`（宏观数据）
- **事件协议**：统一的 `Event` 接口（EventID/EventType/Timestamp/Source）
- **DTO 契约**：`MarketEvent`、`MarketSnapshot`、`Bar`、`MacroPoint`、`MacroEvent` 等跨域传输对象
- **Topic 常量**：点分命名的事件 Topic（`market.data`、`signal.generated` 等）
- **版本管理**：semver 兼容性规则 + Breaking Change 检测
- **公共错误**：`ErrInvalidSymbol`、`ErrSymbolNotFound` 等标准错误变量

核心价值：让数据域、分析域、决策域、执行域之间的接口稳定、可验证、可演进。

### 1.1 为什么需要这个模块

- 量化交易系统由多个领域组成，域间通信需要统一契约防止紧耦合。
- 跨域端口接口需集中定义，变更时才能感知全局影响范围。
- 事件协议和 Topic 命名需统一，避免消息格式混乱和路由冲突。
- DTO 定义需单一事实来源，防止同一数据在不同域中有不同表示。
- 接口变更需版本管理，breaking change 必须可检测、可阻断。

### 1.2 v1.0 要解决的问题

- 统一定义跨域数据端口（MarketDataProvider、MacroDataProvider）。
- 统一事件基础接口（Event）和 Topic 常量命名规范。
- 统一定义跨域 DTO 格式（JSON tag snake_case、不可变语义）。
- 统一契约变更规则：breaking change → major 版本升级。
- 统一公共错误变量，所有错误使用 `"contracts: <desc>"` 格式。

### 1.3 目标用户

- 数据域模块（market-data、macro-data）—— 实现端口接口
- 分析域模块（factor-engine、signal-engine）—— 消费端口接口和 DTO
- 决策域模块（risk-engine）—— 消费信号/仓位事件
- 执行域模块（order-engine、execution-engine）—— 发布订单/执行事件
- x.go —— 组装端口实现并注入各域

## 2. v1.0 核心能力

| 能力域     | v1.0 必须具备的能力                                          | 验收方式           |
| ---------- | ------------------------------------------------------------ | ------------------ |
| 数据端口   | MarketDataProvider（3 方法：Subscribe/GetSnapshot/GetHistory） | 编译期检查通过     |
| 数据端口   | MacroDataProvider（3 方法：GetLatest/GetHistory/Subscribe）   | 编译期检查通过     |
| 事件协议   | Event 接口（EventID/EventType/Timestamp/Source 四方法）       | 接口完整性测试通过 |
| Topic 常量 | 8 个 Topic 常量，全局唯一，点分命名                           | 唯一性测试通过     |
| 核心 DTO   | MarketEvent、MarketSnapshot、Bar、MacroPoint、MacroEvent 等   | JSON round-trip 通过 |
| 版本管理   | VersionInfo/Change 模型 + semver 兼容性规则                   | 版本管理测试通过   |
| BC 检测    | 接口签名变更、DTO 字段变更的自动检测                          | breaking change 测试通过 |
| 公共错误   | 7 个标准错误变量，格式统一 `"contracts: <desc>"`              | 错误格式检查通过   |

## 3. 核心场景

| 场景         | 说明                                   | v1.0 期望结果                               |
| ------------ | -------------------------------------- | ------------------------------------------- |
| 数据订阅     | 分析域通过 MarketDataProvider 订阅行情 | Subscribe 返回 channel 持续推送 MarketEvent |
| 快照获取     | 策略需要当前最新行情                   | GetSnapshot 返回 MarketSnapshot 或错误      |
| 事件发布     | 信号引擎发布 SignalEvent               | Topic 常量匹配，Event 接口完整实现          |
| 版本升级     | DTO 新增可选字段                       | breaking change 测试通过，minor 版本升级    |
| 破坏性检测   | 端口接口删除方法                       | breaking change 测试失败，阻断发布          |
| 跨域数据流   | market-data → contracts DTO → factor-engine | 数据通过 contracts DTO 传输，无紧耦合     |

## 4. 职责边界

### 4.1 模块内职责

- 定义跨域稳定端口接口（MarketDataProvider、MacroDataProvider）。
- 定义 Event 基础接口和 Topic 常量。
- 定义跨域 DTO 结构体（含 JSON tag、不可变语义）。
- 定义公共错误变量和版本管理模型。
- 提供 breaking change 检测能力。
- 维护 semver 兼容性规则。

### 4.2 明确非目标

- 不包含域内接口（留在各域内部）。
- 不包含临时适配器。
- 不包含通用工具函数（→ `x` 工具包）。
- 不包含领域模型全集（领域值对象在 L2.5 领域共享层：`decimalx`、`domain-market`、`domain-exchange`、`domain-macro`）。
- 不承载业务逻辑实现。
- 不做消息队列实现（→ `kafkax`）。
- 不做存储实现（→ `redisx`、存储扩展）。
- **不做契约治理平台**：不包含 ContractDescriptor、ContractRegistry、CompatibilityReport 等治理系统概念。contracts 自身是一个 Go 包，被其他模块 import 使用，而非一个独立的契约注册中心。

## 5. 依赖关系与分层约束

| 依赖类型 | 约束                                                                                       |
| -------- | ------------------------------------------------------------------------------------------ |
| 上游依赖 | stdlib + L2.5 领域共享层（`decimalx`、`domain-market`、`domain-exchange`、`domain-macro`） |
| 下游依赖 | 数据域、分析域、决策域、执行域模块 import contracts 获取端口接口和 DTO 定义                |
| 分层约束 | contracts 处于依赖拓扑上层，只被 import，不 import 任何 L1 运行时模块或存储/中间件扩展     |

> 对齐 CONSTITUTION P7：`contracts` 只定义跨域稳定契约——跨域端口、事件协议、DTO 放在 contracts；域内接口留在域内，领域值对象放在 L2.5。

## 6. 对外契约

| 契约                  | 定位           | v1.0 稳定承诺                         |
| --------------------- | -------------- | ------------------------------------ |
| `MarketDataProvider`  | 行情数据端口   | 3 个方法签名稳定                     |
| `MacroDataProvider`   | 宏观数据端口   | 3 个方法签名稳定                     |
| `Event`               | 事件基础接口   | 4 个方法（EventID/EventType/Timestamp/Source）稳定 |
| Topic 常量            | 事件 Topic     | 8 个常量名称和值稳定                 |
| 核心 DTO              | 跨域传输对象   | 字段名和类型稳定，JSON tag snake_case |
| 公共错误              | 标准错误变量   | 错误变量名和消息格式稳定             |
| `VersionInfo` / `Change` | 版本管理模型 | 字段结构稳定                         |

## 7. 可观测契约

contracts 自身是编译时依赖，无运行时。观测由消费者模块负责：

| 类型   | 名称                          | 说明                                   |
| ------ | ----------------------------- | -------------------------------------- |
| log    | `contracts.subscribe.started` | info，订阅开始，含 symbols/indicators  |
| log    | `contracts.subscribe.error`   | error，订阅失败，含 error              |
| log    | `contracts.event.published`   | debug，事件发布，含 topic 和 event_id  |
| metric | `contracts.event.count`       | counter，事件发布数量（按 topic 分组） |
| metric | `contracts.event.size`        | histogram，事件消息大小                |
| metric | `contracts.subscribe.active`  | gauge，活跃订阅数                      |

## 8. 错误模型

| 错误                   | 调用方处理                             |
| ---------------------- | -------------------------------------- |
| `ErrInvalidSymbol`     | 检查 symbol 格式和是否在支持列表中     |
| `ErrInvalidIndicator`  | 检查 indicator 名称和是否在支持列表中  |
| `ErrInvalidTimeRange`  | 检查 start/end 时间，确保 start < end  |
| `ErrEmptySymbols`      | 传入至少一个 symbol                    |
| `ErrEmptyIndicators`   | 传入至少一个 indicator                 |
| `ErrSymbolNotFound`    | 确认 symbol 已订阅或在交易所支持列表中 |
| `ErrIndicatorNotFound` | 确认 indicator 名称正确                |

**错误消息格式：** `"contracts: <desc>"`
**错误包装：** 使用 `%w` 保留底层错误链。

## 9. 安全、稳定性与兼容性要求

- DTO 不包含敏感数据（密钥、密码、个人身份信息）。
- 事件不泄露内部实现细节（Event.Source() 使用标识符，不含内部路径）。
- 序列化安全（JSON 序列化不执行任意代码）。
- 所有跨域 DTO 必须在 contracts 中定义，不得在域内重复定义。
- 新增契约必须说明消费方、生产方和稳定期。
- 契约版本遵循 semver：breaking change → major，新增可选字段 → minor。

## 10. 测试证据要求

| 测试类型     | 必须覆盖内容                                                | 发布门禁  |
| ------------ | ----------------------------------------------------------- | --------- |
| 编译期检查   | `var _ MarketDataProvider = (*impl)(nil)` 编译通过           | MUST 通过 |
| 单元测试     | DTO JSON round-trip 序列化/反序列化                          | MUST 通过 |
| 单元测试     | Topic 常量唯一性检查                                        | MUST 通过 |
| 单元测试     | Event 接口完整性检查                                        | MUST 通过 |
| 单元测试     | DTO 不可变性检查                                            | MUST 通过 |
| BC 检测测试  | 接口方法增删/DTO 字段变更检测                                | MUST 通过 |
| 单元测试     | 错误格式统一 `"contracts: <desc>"`                           | MUST 通过 |

## 11. v1.0.1 发布验收清单

- [x] 所有端口接口有 godoc 注释（SPEC §9 已定义）
- [x] 所有 DTO 有 JSON tag（snake_case）
- [x] Event 接口定义完整（EventID/EventType/Timestamp/Source）
- [x] Topic 常量 8 个，全局唯一，点分命名
- [x] breaking change 检测逻辑和测试设计完成
- [x] SPEC.md 23 节结构完整，通过结构评分
- [x] TRACEABILITY.md 覆盖率 100%（6 FR + 10 BR + 8 NFR + 7 TC + 16 AC）
- [x] Tasks 拆分完成（5 个原子任务，测试同体，TC 引用完整）
- [x] 所有 FR 有 WHEN/THEN 行为规格
- [x] 所有 BR 有违反后果说明

## 12. Definition of Done

- 公开端口接口冻结并记录兼容性说明。
- DTO 字段和 JSON tag 冻结。
- Topic 常量集冻结。
- SPEC、Matrix、Tasks 制品通过治理评分门禁（目标 100 分）。
- README、CHANGELOG 完成（待 TASK-CONTRACTS-004 实现）。

## 13. v1.0 后演进方向

- 支持 protobuf 序列化（除 JSON 外）。
- 支持请求-响应模式的 RPC 端口（除事件推送外）。
- 支持事件 schema registry（集中管理事件格式演进）。
- 考虑跨域命令接口（如 `OrderCommand`、`RiskCommand`）。
- 端口接口考虑批量操作支持。
