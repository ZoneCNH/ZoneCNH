# 模块宪法

> FoundationX 基座模块的最高治理文件。
>
> 本文件是 AI 代理和人类贡献者在实现、审查或修改任何基座模块时的最高权威参考。
> 当本文件与 `specs/*/SPEC.md`、`module/FOUNDATION-SPEC.md` 或其他文档冲突时，以本文件为准。

最后更新：2026-06-07

---

## 序言

FoundationX 基座层由 16 个模块组成，为量化交易系统提供生命周期管理、配置、可观测、弹性、调度、存储和跨域契约。本宪法规定这些模块必须遵守的不变量，确保系统在演进过程中保持一致性和可维护性。

本宪法的约束对象：
- 所有 16 个基座模块的源码实现
- 所有 `specs/*/SPEC.md` 规格文档
- 所有 AI 代理在基座模块上的代码生成、审查和重构行为
- 所有人类贡献者的 PR 和代码审查

---

## 第一条：设计原则（十三条不变量）

以下十三条原则是系统架构的基石，任何代码变更不得违背。

### 1.1 基座原则

| 编号 | 原则 | 含义 |
|------|------|------|
| P1 | Foundation 先边界后功能 | 先固化 `xlib-standard`、依赖矩阵、Go baseline 和 release gate，再扩大 L1 能力面 |
| P2 | `xlib-standard` 不是运行时依赖 | 它是标准事实源、模板、Gate 和 Evidence 输入，不承载业务运行 |
| P3 | `resiliencx` 只做运行时弹性 | timeout/retry/circuit/bulkhead/rate/fallback 属于它，交易风控属于 `risk-engine` |
| P4 | `testkitx` 只能 test-only | 生产 import graph 不允许出现测试工具包 |

### 1.2 领域原则

| 编号 | 原则 | 含义 |
|------|------|------|
| P5 | 风控是独立引擎 | 策略只能通过 risk-engine 提交订单，不能直接调用 order-engine |
| P6 | 回测与实盘共享代码 | signal-factory / factor-engine / risk-engine 同一套，backtest-engine 只替换数据源和撮合/回放环境 |
| P7 | `contracts` 只定义跨域稳定契约 | 跨域端口、事件协议、DTO 放在 contracts；域内接口留在域内，领域值对象放在 L2.5 |
| P8 | 领域语义沉到 L2.5 | 多域共享的 Price/Qty/Tick/Quote/MacroPoint 等模型统一来自 decimalx / domain-*，避免各域重复定义 |
| P9 | 数据职责不跨域 | 数据域只负责采集、标准化和存储，因子计算在分析域，策略逻辑在决策域 |
| P10 | 执行抽象交易所差异 | order-engine 对上层暴露统一接口，内部适配各交易所 |
| P11 | 反馈通过事件表达 | 执行结果、仓位、PnL、风险暴露以事件反馈决策域，避免执行域反向调用决策内部实现 |
| P12 | x.go 只做组合根 | 不含业务逻辑，仅负责启动、配置加载、依赖组装和生命周期控制 |
| P13 | 域内平级协作 | 同域模块不编号、不分先后，按需协作 |

---

## 第二条：模块边界

### 2.1 每个模块必须声明"拥有"和"不拥有"

每个模块的 SPEC.md 必须包含明确的职责边界：

```text
### 核心职责
- （做什么）

### 明确不做
- （不做什么）
```

### 2.2 边界违规判定

| 违规类型 | 严重性 | 示例 |
|----------|--------|------|
| 反向依赖 | CRITICAL | 数据域 import 分析域 |
| 跨域数据职责 | CRITICAL | 数据域包含因子计算逻辑 |
| 越界职责 | HIGH | `resiliencx` 包含交易风控逻辑 |
| 重复定义 | HIGH | 业务域自定义 Price 类型而非使用 L2.5 |
| 过度抽象 | MEDIUM | 为未来可能的需求创建接口 |

### 2.3 边界仲裁

当两个模块的边界存在争议时，按以下优先级裁定：
1. 本宪法第一条设计原则
2. `specs/*/SPEC.md` 中的"明确不做"声明
3. `ARCHITECTURE.md` 中的依赖拓扑
4. `module/foundation-modules.md` 中的能力需求

---

## 第三条：依赖方向

### 3.1 依赖拓扑（不可违反）

```text
x.go ──→ 基座运行时 / L2.5 / 数据域 / 分析域 / 决策域 / 执行域

数据域 ─┐
分析域 ─┼──→ L2.5 Domain Shared
决策域 ─┤
执行域 ─┘
   │
   ├──→ contracts
   │
   └──→ 基座运行时 Foundation
         L0: kernel
         L1: configx · observex · resiliencx · schedulex
         L1 test-only: testkitx
         扩展: redisx · kafkax · natsx · postgresx · taosx · ossx · clickhousex
```

### 3.2 依赖规则

| 规则 | 说明 |
|------|------|
| 单向下行 | 依赖只能沿箭头方向，不可反向 |
| 同层平级 | 同域同层模块之间不存在编译期依赖 |
| 可选引入 | L1 运行时和存储扩展按需引入，非强制 |
| 禁止循环 | 任何两个模块之间不允许循环依赖 |

### 3.3 基座内部层级

| 层级 | 模块 | 可以依赖 |
|------|------|----------|
| L0 | kernel | stdlib only |
| L1 | configx, observex, resiliencx, schedulex | kernel |
| L1 test-only | testkitx | kernel, observex (interface-only) |
| 门禁 | xlibgate, xlib-standard | 无运行时依赖 |
| 存储扩展 | redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex | kernel, observex (interface-only) |
| 契约 | contracts | L2.5 领域共享层 |

### 3.4 禁止依赖矩阵

| 模块类型 | 禁止依赖 |
|----------|----------|
| L0 (kernel) | 任何非 stdlib 包 |
| L1 运行时 | 其他 L1 模块、业务域、存储扩展 |
| 存储扩展 | configx、业务域、其他存储扩展 |
| 契约 | L1 运行时、业务域实现 |
| 门禁 | 所有运行时模块（仅扫描，不 import） |

---

## 第四条：接口契约

### 4.1 接口定义规则

| 规则 | 说明 |
|------|------|
| 窄接口 | 每个接口 3-5 个方法，不超过 7 个 |
| 编译期检查 | 所有接口必须有 `var _ Interface = (*impl)(nil)` |
| godoc 注释 | 所有公共接口和方法必须有文档注释 |
| 不可变 DTO | 跨域 DTO 字段只读，不提供 setter |
| 返回错误 | 方法签名返回 `error` 作为最后一个返回值 |

### 4.2 接口位置

| 接口类型 | 定义位置 |
|----------|----------|
| 跨域端口 | `contracts/` |
| 域内接口 | 各域内部模块 |
| 基座接口 | 各基座模块自身 |
| L2.5 领域模型 | `decimalx/`, `domain-*/` |

### 4.3 配置接口

所有可配置模块必须提供：

```go
type Config struct {
    // 字段使用 mapstructure tag
    // 提供 Validate() error 方法
    // 提供默认值
}
```

### 4.4 行为规格（WHEN/THEN）

每个模块的 SPEC.md 必须包含行为性规格，不能只有结构性描述。

**必需的行为规格章节：**

| 章节 | 要求 |
|------|------|
| Functional Requirements | 每个公共方法必须有 WHEN/THEN 描述 |
| Business Rules | 模块不变量和校验规则必须显式列出 |
| Error Handling | 错误分类 + 调用方处理指南（不是模块自身故障模式） |
| Acceptance Criteria | 统一验收清单（从 CI Gate + DoD 合并） |

**WHEN/THEN 格式：**

```text
WHEN [条件/输入]
THEN [系统行为/输出]
AND [副作用/状态变更]
```

**示例（configx.Reader.Get）：**

```text
WHEN path 存在于已加载配置中
THEN 返回对应值和 nil error

WHEN path 不存在
THEN 返回零值和 false

WHEN path 存在但类型不匹配
THEN 返回零值和 ErrTypeMismatch
```

**规则：**
- 每个公共导出方法至少 2 个 WHEN/THEN（正常路径 + 异常路径）
- 边界条件必须有独立的 WHEN/THEN
- 不可省略 Error Handling 章节 — 无模块特定要求时写"参见 CONSTITUTION.md 第八条"

---

## 第五条：测试标准

### 5.1 覆盖率要求

| 模块类型 | 最低覆盖率 | 说明 |
|----------|------------|------|
| L0 (kernel) | 90% | 原语层必须高度可靠 |
| L1 运行时 | 80% | 标准覆盖率 |
| 存储扩展 | 80% | 单元测试 + 可选集成测试 |
| 契约 | 80% | 含 breaking change 检测 |
| 门禁 | 80% | 自检通过 |

### 5.2 测试分类

| 类型 | 标签 | 运行条件 | 阻塞级别 |
|------|------|----------|----------|
| 单元测试 | 无 | 始终运行 | 必须通过 |
| 集成测试 | `integration` | 外部服务可达时 | 不可达时 skip |
| 基准测试 | `benchmark` | PR 附带结果 | 建议 |
| 竞态测试 | `-race` | 始终运行 | 必须通过 |

### 5.3 测试命名

```go
func TestFunctionName_Scenario_ExpectedBehavior(t *testing.T) {
    // Arrange — 准备测试数据
    // Act      — 执行被测函数
    // Assert   — 验证结果
}
```

### 5.4 禁止事项

- 禁止测试依赖执行顺序
- 禁止测试共享可变状态
- 禁止 sleep 等待（使用 channel 或 retry）
- 禁止测试中硬编码时间（使用 `FakeClock`）

---

## 第六条：可观测性

### 6.1 Metrics 命名规范

```text
foundationx_<module>_<operation>_<measure>
```

| 部分 | 说明 | 示例 |
|------|------|------|
| `foundationx` | 固定前缀 | `foundationx` |
| `<module>` | 模块名 | `redisx` |
| `<operation>` | 操作名 | `get`, `set`, `query` |
| `<measure>` | 度量类型 | `duration`, `errors`, `size` |

### 6.2 必需的可观测输出

| 类型 | 每个模块必须提供 |
|------|------------------|
| metric | 操作耗时（histogram）、错误计数（counter） |
| log | 连接成功/失败、关键状态变更 |
| health | 健康检查接口实现 |

### 6.3 Label Policy

- 不得将高基数字段（如 request ID、user ID）作为 metric label
- 必须使用 `observex` 定义的标准 label（如 `status`, `operation`）
- 自定义 label 必须在 SPEC.md 中声明

### 6.4 Redaction

- 日志中不得出现敏感数据明文
- 必须使用 `observex.Redactor` 处理 API key、token、密码
- 配置值中的敏感字段必须标记为 `sensitive`

---

## 第七条：命名规范

### 7.1 Go 命名

| 元素 | 规范 | 示例 |
|------|------|------|
| 包名 | 小写单词，无下划线 | `redisx`, `configx` |
| 接口 | 方法名动词或名词 | `Client`, `Locker`, `Provider` |
| 结构体 | PascalCase | `MarketSnapshot`, `StreamConfig` |
| 函数/方法 | PascalCase (exported), camelCase (unexported) | `NewClient`, `parseConfig` |
| 常量 | PascalCase 或 UPPER_SNAKE | `TopicMarketData` |
| 错误 | `errors.New("module: description")` | `errors.New("redisx: connection refused")` |

### 7.2 模块命名

| 模式 | 说明 | 示例 |
|------|------|------|
| `<name>x` | 基座扩展模块 | `redisx`, `kafkax`, `configx` |
| `domain-<name>` | L2.5 领域模型 | `domain-market`, `domain-exchange` |
| `<name>-engine` | 分析/决策引擎 | `risk-engine`, `factor-engine` |
| `<exchange>` | 数据域采集器 | `binance`, `okx` |

### 7.3 文件命名

| 类型 | 规范 | 示例 |
|------|------|------|
| Go 源码 | snake_case | `client.go`, `health_check.go` |
| 测试文件 | `<source>_test.go` | `client_test.go` |
| 规格文档 | `SPEC.md` | `specs/redisx/SPEC.md` |
| 变更日志 | `CHANGELOG.md` | 每个模块根目录 |

---

## 第八条：错误处理

### 8.1 错误定义

```go
// 模块级哨兵错误
var ErrNotFound = errors.New("redisx: key not found")
var ErrConnectionClosed = errors.New("redisx: connection closed")

// 错误包装
if err != nil {
    return fmt.Errorf("redisx: get %q: %w", key, err)
}
```

### 8.2 错误规则

| 规则 | 说明 |
|------|------|
| 哨兵错误 | 可编程处理的错误定义为包级变量 |
| 错误包装 | 使用 `%w` 包装底层错误，保留链 |
| 错误消息格式 | `"module: operation context"` |
| 不要静默吞掉 | 所有错误必须显式处理或向上传播 |
| 不要 panic | 除非不可恢复的初始化失败 |

### 8.3 错误分类

| 分类 | 处理方式 | 示例 |
|------|----------|------|
| 可重试 | 返回错误 + `Retryable()` 方法 | 网络超时 |
| 不可重试 | 直接返回错误 | 参数校验失败 |
| 致命 | 返回错误 + 日志 fatal | 配置不可用 |

---

## 第九条：安全要求

### 9.1 密钥管理

- **禁止**硬编码 API key、密码、token 到源码
- **必须**使用环境变量或配置注入
- **必须**在启动时校验必需密钥存在
- **必须**支持密钥轮换

### 9.2 输入校验

| 输入源 | 校验要求 |
|--------|----------|
| 配置文件 | schema 校验 + 类型检查 |
| 环境变量 | 类型转换 + 范围检查 |
| API 参数 | 边界检查 + 注入防护 |
| 消息队列 | 反序列化校验 |

### 9.3 数据保护

- 日志中敏感字段必须 redact
- 配置导出时敏感字段必须 mask
- 传输中数据必须 TLS 加密
- 存储中敏感数据必须加密

### 9.4 依赖安全

- 所有第三方依赖必须在 `go.sum` 中有校验和
- 定期运行 `govulncheck` 扫描已知漏洞
- 新增依赖必须在 PR 中说明必要性

---

## 第十条：变更管理

### 10.1 变更分类

| 分类 | 定义 | 审批要求 |
|------|------|----------|
| PATCH | Bug 修复、文档更新、测试补充 | 1 人审批 |
| MINOR | 新增功能、新增接口方法 | 1 人审批 + SPEC 更新 |
| MAJOR | 接口签名变更、DTO 结构变更 | 2 人审批 + 迁移方案 + 版本 bump |

### 10.2 Breaking Change 定义

以下变更视为 breaking change：

- 删除或重命名公共接口方法
- 修改公共接口方法签名
- 删除或重命名公共结构体字段
- 修改公共结构体字段类型
- 删除公共常量或错误变量
- 修改事件 Topic 名称
- 修改配置 schema 的必填字段

### 10.3 Breaking Change 流程

```text
1. 在 SPEC.md 中标记为 DEPRECATED
2. 提供迁移指南
3. 保留至少一个 MINOR 版本周期
4. 下一个 MAJOR 版本中移除
```

### 10.4 版本号规则

遵循 Semantic Versioning：

```text
v<MAJOR>.<MINOR>.<PATCH>

v0.x.x  — 初始开发，API 不稳定
v1.0.0  — 首个稳定 API 承诺
```

---

## 第十一条：代码审查

### 11.1 审查清单

每个 PR 必须检查：

- [ ] 不违背第一条十三条设计原则
- [ ] 不引入循环依赖或反向依赖
- [ ] 接口签名符合第四条
- [ ] 测试覆盖率符合第五条
- [ ] 可观测输出符合第六条
- [ ] 命名符合第七条
- [ ] 错误处理符合第八条
- [ ] 安全要求符合第九条
- [ ] breaking change 已按第十条处理

### 11.2 审查严重性

| 级别 | 含义 | 处理 |
|------|------|------|
| CONSTITUTION | 违背本宪法 | **阻塞** — 必须修复 |
| CRITICAL | 安全漏洞或数据丢失风险 | **阻塞** — 必须修复 |
| HIGH | Bug 或重大质量问题 | **警告** — 应修复 |
| MEDIUM | 可维护性问题 | **建议** — 考虑修复 |
| LOW | 风格或次要建议 | **可选** |

### 11.3 AI 代理审查规则

AI 代理在生成或审查代码时：
1. **必须**先读取目标模块的 `specs/*/SPEC.md`
2. **必须**检查本宪法第一条设计原则
3. **必须**验证依赖方向符合第三条
4. **不得**生成违反本宪法的代码
5. **不得**自动 approve 违宪的变更

---

## 第十二条：修正程序

### 12.1 修正条件

本宪法的修正需要满足：
1. 明确的问题陈述（为什么现有条款不够）
2. 影响分析（对现有模块的影响）
3. 迁移方案（如涉及 breaking change）

### 12.2 修正流程

```text
1. 提出修正案 → 修改本文件
2. 更新受影响的 specs/*/SPEC.md
3. 更新 ARCHITECTURE.md（如涉及拓扑变更）
4. 更新 FOUNDATION-DEPS.yaml（如涉及依赖变更）
5. 同步 README.md
```

### 12.3 修正记录

| 日期 | 条款 | 变更内容 | 理由 |
|------|------|----------|------|
| 2026-06-07 | 全文 | 初始版本 | 建立基座模块治理框架 |

---

## 第十三条：最高条款

### 13.1 效力层级

当文档之间存在冲突时，按以下优先级裁定：

```text
本宪法 (CONSTITUTION.md)
  ↓
模块规格 (specs/*/SPEC.md)
  ↓
架构文档 (ARCHITECTURE.md)
  ↓
模块详情 (module/foundation-modules.md, FOUNDATION-SPEC.md)
  ↓
其他文档
```

### 13.2 适用范围

本宪法适用于 `github.com/ZoneCNH` 下所有基座层模块（16 个），以及 L2.5 领域共享层（4 个）中涉及基座契约的部分。

本宪法不直接约束业务域模块（数据域、分析域、决策域、执行域），但业务域模块必须遵守第三条依赖方向和第七条 contracts 规则。

### 13.3 解释权

本宪法的解释权归项目维护者所有。AI 代理在遇到宪法条款的歧义时，应向人类维护者请求澄清，而非自行解释。

---

## 附录 A：模块清单

| 层级 | 模块 | 规格 | 仓库 |
|------|------|------|------|
| L0 | kernel | [SPEC](./specs/kernel/SPEC.md) | [kernel](https://github.com/ZoneCNH/kernel) |
| L1 | configx | [SPEC](./specs/configx/SPEC.md) | [configx](https://github.com/ZoneCNH/configx) |
| L1 | observex | [SPEC](./specs/observex/SPEC.md) | [observex](https://github.com/ZoneCNH/observex) |
| L1 | resiliencx | [SPEC](./specs/resiliencx/SPEC.md) | [resiliencx](https://github.com/ZoneCNH/resiliencx) |
| L1 | schedulex | [SPEC](./specs/schedulex/SPEC.md) | [schedulex](https://github.com/ZoneCNH/schedulex) |
| L1 test-only | testkitx | [SPEC](./specs/testkitx/SPEC.md) | [testkitx](https://github.com/ZoneCNH/testkitx) |
| 门禁 | xlib-standard | [SPEC](./specs/xlib-standard/SPEC.md) | [xlib-standard](https://github.com/ZoneCNH/xlib-standard) |
| 门禁 | xlibgate | [SPEC](./specs/xlibgate/SPEC.md) | [xlibgate](https://github.com/ZoneCNH/xlibgate) |
| 存储扩展 | redisx | [SPEC](./specs/redisx/SPEC.md) | [redisx](https://github.com/ZoneCNH/redisx) |
| 存储扩展 | kafkax | [SPEC](./specs/kafkax/SPEC.md) | [kafkax](https://github.com/ZoneCNH/kafkax) |
| 存储扩展 | natsx | [SPEC](./specs/natsx/SPEC.md) | [natsx](https://github.com/ZoneCNH/natsx) |
| 存储扩展 | postgresx | [SPEC](./specs/postgresx/SPEC.md) | [postgresx](https://github.com/ZoneCNH/postgresx) |
| 存储扩展 | taosx | [SPEC](./specs/taosx/SPEC.md) | [taosx](https://github.com/ZoneCNH/taosx) |
| 存储扩展 | ossx | [SPEC](./specs/ossx/SPEC.md) | [ossx](https://github.com/ZoneCNH/ossx) |
| 存储扩展 | clickhousex | [SPEC](./specs/clickhousex/SPEC.md) | [clickhousex](https://github.com/ZoneCNH/clickhousex) |
| 契约 | contracts | [SPEC](./specs/contracts/SPEC.md) | [contracts](https://github.com/ZoneCNH/contracts) |

## 附录 B：与 CLAUDE.md 的关系

`CLAUDE.md` 是 Claude Code 的工作指南，规定仓库级别的操作约定（文档同步、提交格式、安全红线）。本宪法是模块级别的治理文件，规定模块实现的技术标准。

两者互补：
- `CLAUDE.md` 管"怎么编辑这个仓库"
- 本宪法管"怎么实现基座模块"

当两者冲突时，`CLAUDE.md` 中的安全条款（不提交凭证等）优先；技术条款以本宪法为准。
