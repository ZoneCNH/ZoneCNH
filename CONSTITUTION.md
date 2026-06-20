# FoundationX 宪法

> FoundationX 全系统的最高治理文件。
>
> 本文件是 AI 代理和人类贡献者在实现、审查或修改任何模块或交付流程时的最高权威参考。
> 当本文件与 `module/*/SPEC.md`、`module/FOUNDATION-SPEC.md`、`docs/governance/DEVELOPMENT-WORKFLOW.md` 或其他文档冲突时，以本文件为准。

最后更新：2026-06-16

---

## 第零条：分支纪律（最高优先级）

> 本条优先级高于本文件所有其他条款。任何工作流、Agent 编排或人工操作不得违反。

### 0.1 禁止 main 开发

**严禁**在 `main` 分支上直接进行任何开发工作（包括但不限于：编写代码、编辑文档、运行实验性变更）。

| 操作             | main                           | worktree / feature branch |
| ---------------- | ------------------------------ | ------------------------- |
| 编辑文件         | ❌ 禁止                         | ✅ 必须                    |
| 提交变更         | ❌ 禁止（仅允许 merge/rebase）  | ✅ 必须                    |
| 运行实验         | ❌ 禁止                         | ✅ 必须                    |
| 合并已完成的工作 | ✅ 允许（通过 PR 或 merge）     | —                         |

### 0.2 强制使用 worktree

所有开发工作必须通过 `git worktree` 或 feature branch 进行：

0. **所有分支必须从 `main` HEAD 创建**——禁止从其他 feature branch、旧 commit 或 detached HEAD 拉取新分支。创建前必须先 `git fetch origin && git rebase origin/main`（或 `git pull --rebase`）确保本地 main 为最新。
1. **每个独立任务**必须在独立 worktree 或 feature branch 中执行（纯文档仓库允许 feature branch 替代 worktree；含源码的模块仓库应优先使用 `git worktree add`）
2. **分支/worktree 命名**必须遵循 `{type}/{module}-{description}` 格式（如 `docs/kernel-spec-update`、`feat/kernel-new-api`、`fix/redisx-timeout`），或 `{branch-name}` 格式（如 `feat/v2-foundation-trust-governance-20260615`）
3. **工作完成后**通过 PR 或 merge 合入 main，随后清理 worktree 和 feature branch
4. **禁止**在 main worktree 中堆积未提交变更

### 0.3 Agent 约束

所有 AI 代理（Claude、Codex、Copilot 及任何未来代理）在本仓库工作时：

1. **必须**在开始**编辑文件**前确认当前不在 main 分支（`git checkout main` 等 git 操作不受此约束）
2. **必须**使用 worktree 或 feature branch 隔离开发任务（参见 §0.2.1）
3. **禁止**在 main 上直接 commit
4. **发现** main 上有未提交变更时，**必须**停止并警告人类维护者

### 0.4 例外

仅以下操作允许在 main 上执行：

- `git merge` / `git rebase` 合并已完成的分支
- `git pull` 同步远程更新
- 紧急 hotfix（需事后补充 worktree 流程记录）。hotfix 分支**同样必须从 `main` HEAD 创建**，不得从其他 feature branch 拉取

---

## 序言

FoundationX 由基座层（19 个模块）、L2.5 领域共享层（5 个模块）以及数据域、分析域、决策域、执行域组成。本宪法规定模块实现和交付管线必须遵守的不变量，确保系统在演进过程中保持一致性、可追溯性和可维护性。

本宪法的约束对象：

- 所有基座模块和领域模块的源码实现
- 全系统的交付管线（Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective；Matrix 为横切追溯制品）
- 所有 `module/*/SPEC.md` 规格文档
- 所有 AI 代理的代码生成、审查和重构行为
- 所有人类贡献者的 PR 和代码审查

---

## 第一条：设计原则（十三条不变量）

以下十三条原则是系统架构的基石，任何代码变更不得违背。

### 1.1 基座原则

| 编号 | 原则                           | 含义                                                                                                        |
| ---- | ------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| P1   | Foundation 先边界后功能        | 先固化 `xlib_standard`、依赖矩阵、Go baseline 和 release gate，再扩大 L1 能力面                             |
| P2   | `xlib_standard` 不是运行时依赖 | 它是标准事实源和 Go Reference Template 二类职责（Generator/Harness/Evidence 已拆分至 `xlib_harness` / `xlib_evidence`），不承载业务运行 |
| P3   | `resiliencx` 只做运行时弹性    | timeout/retry/circuit/bulkhead/rate/fallback 属于它，交易风控属于 `risk_engine`                             |
| P4   | `testkitx` 只能 test-only      | 生产 import graph 不允许出现测试工具包                                                                      |

### 1.2 领域原则

| 编号 | 原则                           | 含义                                                                                             |
| ---- | ------------------------------ | ------------------------------------------------------------------------------------------------ |
| P5   | 风控是独立引擎                 | 策略只能通过 risk_engine 提交订单，不能直接调用 order_engine                                     |
| P6   | 回测与实盘共享代码             | signal_factory / factor_engine / risk_engine 同一套，backtest_engine 只替换数据源和撮合/回放环境 |
| P7   | `contracts` 只定义跨域稳定契约 | 跨域端口、事件协议、DTO 放在 contracts；域内接口留在域内，领域值对象放在 L2.5                    |
| P8   | 领域语义沉到 L2.5              | 多域共享的 Price/Qty/Tick/Quote/MacroPoint 等模型统一来自 decimalx / domain-\*，避免各域重复定义 |
| P9   | 数据职责不跨域                 | 数据域只负责采集、标准化和存储，因子计算在分析域，策略逻辑在决策域                               |
| P10  | 执行抽象交易所差异             | order_engine 对上层暴露统一接口，内部适配各交易所                                                |
| P11  | 反馈通过事件表达               | 执行结果、仓位、PnL、风险暴露以事件反馈决策域，避免执行域反向调用决策内部实现                    |
| P12  | x.go 只做组合根                | 不含业务逻辑，仅负责启动、配置加载、依赖组装和生命周期控制                                       |
| P13  | 域内平级协作                   | 同域模块不编号、不分先后，按需协作                                                               |

---

## 第二条：模块边界

### 2.1 每个模块必须声明"拥有"和"不拥有"

每个模块的 SPEC.md 必须包含明确的职责边界：

````text
### 核心职责
- （做什么）

### 明确不做
- （不做什么）
```text

**Non-goals 质量要求：** 每项"不做什么"必须命名一项**具体的排除职责**并指明**由谁负责**（委派方）。

- 有效：`不做因子计算（→ factor_engine）`——命名了排除项（因子计算），指明了委派方（factor_engine）。
- 有效：`不替代 L2/L3/chaos/soak 测试（由各模块自行组织或由 xlib_harness / xlibgate 在 CI 管线中协调）`——命名了排除的测试层，指明了委派方。
- 无效：`不承载业务模型`——未命名具体模型，未指明由谁负责。等效于"不做其他模块的事"。
- 无效：`不进入生产依赖路径`——未命名具体依赖，未指明生产代码由谁维护。

**与 ISA 的关系：** Non-goals 与 ISA"不做什么"服务于同一目的（防范围蔓延），但在不同层次：

| 维度 | ISA 不做什么 | SPEC Non-goals |
|------|-------------|----------------|
| 生命周期 | 任务级，完成后关闭 | 模块级，永久有效 |
| 粒度 | 单次实现的排除项 | 模块范围的排除项 |
| 评审对象 | 具体变更的评审者 | 模块维护者和依赖方 |
| 变更触发 | 每项新任务 | 模块职责变更时 |

两者共享同一验证标准：排除项是否具体、委派方是否明确。两者均防止同一类对话——"这不算 X，所以可以做。"

### 2.2 边界违规判定

| 违规类型     | 严重性   | 示例                                 |
| ------------ | -------- | ------------------------------------ |
| 反向依赖     | CRITICAL | 数据域 import 分析域                 |
| 跨域数据职责 | CRITICAL | 数据域包含因子计算逻辑               |
| 越界职责     | HIGH     | `resiliencx` 包含交易风控逻辑        |
| 重复定义     | HIGH     | 业务域自定义 Price 类型而非使用 L2.5 |
| 过度抽象     | MEDIUM   | 为未来可能的需求创建接口             |

### 2.3 边界仲裁

当两个模块的边界存在争议时，按以下优先级裁定：

1. 本宪法第一条设计原则
2. `module/*/SPEC.md` 中的"明确不做"声明
3. `ARCHITECTURE.md` 中的依赖拓扑
4. `module/foundation-modules.md` 中的能力需求

### 2.4 本地代码目录

模块代码仓库的本地工作目录统一为 `/home/{module}`，其中 `{module}` 必须与 GitHub 仓库名一致，例如 `/home/kernel`、`/home/x.go`。本仓库 `ZoneCNH/ZoneCNH` 只保存公开架构说明、规格和索引，不得内嵌模块源码树、vendor 源码或从 `/home/{module}` 复制出的实现文件。

### 2.5 模块增殖约束（奥卡姆剃刀）

**如无必要，勿增实体。** 系统复杂度只能以可验证的价值回报为对价增长。

**新增模块必须同时满足以下三项条件，缺一不可：**

| 条件     | 含义                                                                                   |
| -------- | -------------------------------------------------------------------------------------- |
| 必要性   | 现有模块无法通过扩展（新增接口方法、新增配置项、新增可选依赖）满足需求                 |
| 唯一性   | 新模块的职责不被任何现有模块覆盖，且不可拆解为现有模块的职责扩展                       |
| 净收益   | 新模块消除的复杂度 **大于** 其引入的复杂度（以依赖边增量、接口方法数、跨模块调用链深度综合评估） |

**绝对禁止：**

- 禁止为"未来可能需要"创建模块（YAGNI）
- 禁止为单一配置项或单一导出函数创建独立模块
- 禁止在职责已被现有模块覆盖的领域创建功能等效的新模块

违反本条的模块新增提案，须经 §第十二条修正程序审批。

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
```text

### 3.2 依赖规则

| 规则     | 说明                                |
| -------- | ----------------------------------- |
| 单向下行 | 依赖只能沿箭头方向，不可反向        |
| 同层平级 | 同域同层模块之间不存在编译期依赖    |
| 可选引入 | L1 运行时和存储扩展按需引入，非强制 |
| 禁止循环 | 任何两个模块之间不允许循环依赖      |

### 3.3 基座内部层级

| 层级          | 模块                                                       | 可以依赖                          |
| ------------- | ---------------------------------------------------------- | --------------------------------- |
| L0            | kernel                                                     | stdlib only                       |
| L1            | configx, observex, resiliencx, schedulex                   | kernel                            |
| L1 test-only  | testkitx                                                   | kernel, observex (interface-only) |
| 标准源 / 门禁 | xlib_standard, xlibgate                                    | 无运行时依赖                      |
| 存储扩展      | redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex | kernel, observex (interface-only) |
| 契约          | contracts                                                  | L2.5 领域共享层                   |

### 3.4 禁止依赖矩阵

| 模块类型      | 禁止依赖                                                  |
| ------------- | --------------------------------------------------------- |
| L0 (kernel)   | 任何非 stdlib 包                                          |
| L1 运行时     | 其他 L1 模块、业务域、存储扩展                            |
| 存储扩展      | configx、业务域、其他存储扩展（存储间不得互依）           |
| 契约          | L1 运行时、业务域实现（contracts 只定义接口，不依赖实现） |
| 标准源 / 门禁 | 所有运行时模块（仅扫描，不 import）                       |

---

## 第四条：接口契约

### 4.1 接口定义规则

| 规则       | 说明                                            |
| ---------- | ----------------------------------------------- |
| 窄接口     | 每个接口 3-5 个方法，不超过 7 个                |
| 编译期检查 | 所有接口必须有 `var _ Interface = (*impl)(nil)` |
| godoc 注释 | 所有公共接口和方法必须有文档注释                |
| 不可变 DTO | 跨域 DTO 字段只读，不提供 setter                |
| 返回错误   | 方法签名返回 `error` 作为最后一个返回值         |

### 4.2 接口位置

| 接口类型      | 定义位置                 |
| ------------- | ------------------------ |
| 跨域端口      | `contracts/`             |
| 域内接口      | 各域内部模块             |
| 基座接口      | 各基座模块自身           |
| L2.5 领域模型 | `decimalx/`, `domain-*/` |

### 4.3 配置接口

所有可配置模块必须提供：

```go
type Config struct {
    // 字段使用 mapstructure tag
    // 提供 Validate() error 方法
    // 提供默认值
}
```text

### 4.4 行为规格（WHEN/THEN）

每个模块的 SPEC.md 必须包含行为性规格，不能只有结构性描述。

**必需的行为规格章节：**

| 章节                    | 要求                                              |
| ----------------------- | ------------------------------------------------- |
| Functional Requirements | 每个公共方法必须有 WHEN/THEN 描述                 |
| Business Rules          | 模块不变量和校验规则必须显式列出                  |
| Error Handling          | 错误分类 + 调用方处理指南（不是模块自身故障模式） |
| Acceptance Criteria     | 统一验收清单（从 CI Gate + DoD 合并）             |

**WHEN/THEN 格式：**

```text
WHEN [条件/输入]
THEN [系统行为/输出]
AND [副作用/状态变更]
```text

**示例（configx.Reader.Get）：**

```text
WHEN path 存在于已加载配置中
THEN 返回对应值和 nil error

WHEN path 不存在
THEN 返回零值和 false

WHEN path 存在但类型不匹配
THEN 返回零值和 ErrTypeMismatch
```text

**规则：**

- 每个公共导出方法至少 2 个 WHEN/THEN（正常路径 + 异常路径）
- 边界条件必须有独立的 WHEN/THEN
- 不可省略 Error Handling 章节 — 无模块特定要求时写"参见 CONSTITUTION.md 第八条"

---

## 第五条：测试标准

### 5.1 覆盖率要求

| 模块类型    | 最低覆盖率   | 说明                       |
| ----------- | ------------ | -------------------------- |
| L0 (kernel) | 100%         | 原语层必须高度可靠，零遗漏 |
| L1 运行时   | 80%          | 标准覆盖率                 |
| 存储扩展    | 80%          | 单元测试 + 可选集成测试    |
| 契约        | 80%          | 含 breaking change 检测    |
| 门禁        | 80%          | 自检通过                   |

### 5.2 测试分类

| 类型     | 标签          | 运行条件       | 阻塞级别      |
| -------- | ------------- | -------------- | ------------- |
| 单元测试 | 无            | 始终运行       | 必须通过      |
| 集成测试 | `integration` | 外部服务可达时 | 不可达时 skip |
| 基准测试 | `benchmark`   | PR 附带结果    | 建议          |
| 竞态测试 | `-race`       | 始终运行       | 必须通过      |

### 5.3 测试命名

```go
func TestFunctionName_Scenario_ExpectedBehavior(t *testing.T) {
    // Arrange — 准备测试数据
    // Act      — 执行被测函数
    // Assert   — 验证结果
}
```text

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
```text

| 部分          | 说明     | 示例                         |
| ------------- | -------- | ---------------------------- |
| `foundationx` | 固定前缀 | `foundationx`                |
| `<module>`    | 模块名   | `redisx`                     |
| `<operation>` | 操作名   | `get`, `set`, `query`        |
| `<measure>`   | 度量类型 | `duration`, `errors`, `size` |

### 6.2 必需的可观测输出

| 类型   | 每个模块必须提供                           |
| ------ | ------------------------------------------ |
| metric | 操作耗时（histogram）、错误计数（counter） |
| log    | 连接成功/失败、关键状态变更                |
| health | 健康检查接口实现                           |

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

| 元素      | 规范                                          | 示例                                       |
| --------- | --------------------------------------------- | ------------------------------------------ |
| 包名      | 小写单词，无下划线                            | `redisx`, `configx`                        |
| 接口      | 方法名动词或名词                              | `Client`, `Locker`, `Provider`             |
| 结构体    | PascalCase                                    | `MarketSnapshot`, `StreamConfig`           |
| 函数/方法 | PascalCase (exported), camelCase (unexported) | `NewClient`, `parseConfig`                 |
| 常量      | PascalCase 或 UPPER_SNAKE                     | `TopicMarketData`                          |
| 错误      | `errors.New("module: description")`           | `errors.New("redisx: connection refused")` |

### 7.2 模块命名

| 模式            | 说明          | 示例                               |
| --------------- | ------------- | ---------------------------------- |
| `<name>x`       | 基座扩展模块  | `redisx`, `kafkax`, `configx`      |
| `domain-<name>` | L2.5 领域模型 | `domain_market`, `domain_exchange` |
| `<name>-engine` | 分析/决策引擎 | `risk_engine`, `factor_engine`     |
| `<exchange>`    | 数据域采集器  | `binance`, `okx`                   |

### 7.3 文件命名

| 类型     | 规范               | 示例                           |
| -------- | ------------------ | ------------------------------ |
| Go 源码  | snake_case         | `client.go`, `health_check.go` |
| 测试文件 | `<source>_test.go` | `client_test.go`               |
| 规格文档 | `SPEC.md`          | `module/redisx/SPEC.md`        |
| 变更日志 | `CHANGELOG.md`     | 每个模块根目录                 |

### 7.4 数据域跨层命名

| 层面 | 规范 | macro_data 示例 |
| --- | --- | --- |
| 模块 / 仓库 / 路径 / 公开文档链接 | kebab-case | `macro_data` |
| JSON / YAML / 配置 / Goal registry / 接收侧字段 | snake_case | `macro_data`, `series_code`, `available_at` |
| Go 导出类型 / 接口 / 常量名 | PascalCase | `MacroDataProvider`, `TopicMacroData` |
| Topic literal / 事件通道值 | dot.case | `macro.data` |

规则：

- `macro_data` 只表示模块、仓库、目录和公开文档链接，不得作为配置键或接收侧字段名。
- `macro_data` 是宏观数据域在 JSON/YAML/config/registry/receiver 字段中的 canonical token；字段名使用 `series_code`、`observed_at`、`released_at`、`available_at`、`revision_version`、`is_preliminary`、`idempotency_key`、`ordering_key`。
- Go 类型和导出标识保留 PascalCase；不得为了对齐 snake_case 而重命名 `MacroDataProvider`、`TopicMacroData` 等 Go symbol。
- Topic 字符串保留 dot.case；`macro.data` 不得替换为 `macro_data`。
- 禁止在文档、配置和注册表中新增 `macroData`、`macrodata`、`Macrodata` 等漂移写法。

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
```text

### 8.2 错误规则

| 规则         | 说明                           |
| ------------ | ------------------------------ |
| 哨兵错误     | 可编程处理的错误定义为包级变量 |
| 错误包装     | 使用 `%w` 包装底层错误，保留链 |
| 错误消息格式 | `"module: operation context"`  |
| 不要静默吞掉 | 所有错误必须显式处理或向上传播 |
| 不要 panic   | 除非不可恢复的初始化失败       |

### 8.3 错误分类

| 分类     | 处理方式                      | 示例         |
| -------- | ----------------------------- | ------------ |
| 可重试   | 返回错误 + `Retryable()` 方法 | 网络超时     |
| 不可重试 | 直接返回错误                  | 参数校验失败 |
| 致命     | 返回错误 + 日志 fatal         | 配置不可用   |

---

## 第九条：安全要求

### 9.1 密钥管理

- **禁止**硬编码 API key、密码、token 到源码
- **必须**使用环境变量或配置注入
- **必须**在启动时校验必需密钥存在
- **必须**支持密钥轮换

### 9.2 输入校验

| 输入源   | 校验要求               |
| -------- | ---------------------- |
| 配置文件 | schema 校验 + 类型检查 |
| 环境变量 | 类型转换 + 范围检查    |
| API 参数 | 边界检查 + 注入防护    |
| 消息队列 | 反序列化校验           |

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

| 分类   | 定义                         | 审批要求                        |
| ------ | ---------------------------- | ------------------------------- |
| PATCH  | Bug 修复、文档更新、测试补充 | 1 人审批                        |
| MINOR  | 新增功能、新增接口方法       | 1 人审批 + SPEC 更新            |
| MAJOR  | 接口签名变更、DTO 结构变更   | 2 人审批 + 迁移方案 + 版本 bump |

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
```text

### 10.4 版本号规则

遵循 Semantic Versioning：

```text
v<MAJOR>.<MINOR>.<PATCH>

v0.x.x  — 初始开发，API 不稳定
v1.0.0  — 首个稳定 API 承诺
```text

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

| 级别         | 含义                   | 处理                |
| ------------ | ---------------------- | ------------------- |
| CONSTITUTION | 违背本宪法             | **阻塞** — 必须修复 |
| CRITICAL     | 安全漏洞或数据丢失风险 | **阻塞** — 必须修复 |
| HIGH         | Bug 或重大质量问题     | **警告** — 应修复   |
| MEDIUM       | 可维护性问题           | **建议** — 考虑修复 |
| LOW          | 风格或次要建议         | **可选**            |

### 11.3 AI 代理审查规则

AI 代理在生成或审查代码时：

1. **必须**先读取目标模块的 `module/*/SPEC.md`
2. **必须**检查本宪法第一条设计原则
3. **必须**验证依赖方向符合第三条
4. **不得**生成违反本宪法的代码
5. **不得**自动 approve 违宪的变更

---

## 第十二条：修正程序

### 12.1 修正条件

本宪法的修正需要满足：

1. 明确的问题陈述（为什么现有条款不够）
2. 影响分析（对现有模块和交付管线的影响）
3. 迁移方案（如涉及 breaking change）

### 12.2 修正流程

```text
1. 提出修正案 → 修改本文件
2. 更新受影响的 module/*/SPEC.md
3. 更新 ARCHITECTURE.md（如涉及拓扑变更）
4. 更新 FOUNDATION-DEPS.yaml（如涉及依赖变更）
5. 更新受影响的 `module/*` 规格或 `docs/governance/` 治理文档（如涉及 §15-§19）
6. 同步 README.md
```

### 12.3 修正记录

| 日期       | 条款    | 变更内容                                 | 理由                                                          |
| ---------- | ------- | ---------------------------------------- | ------------------------------------------------------------- |
| 2026-06-07 | 全文    | 初始版本（§1-§14）                       | 建立基座模块治理框架                                          |
| 2026-06-08 | §15-§19 | 新增交付管线治理条款                     | 将交付方法论提升为宪法约束                                    |
| 2026-06-09 | §0      | 新增第零条：分支纪律（最高优先级）       | 禁止 main 开发，强制 worktree 隔离                            |
| 2026-06-10 | §0.2    | 补充分支创建规则                         | 所有分支必须从 main HEAD 创建，禁止从 feature branch 拉新分支 |
| 2026-06-12 | §2.4    | 新增本地代码目录条款                     | 模块代码统一存放于 /home/{module}，禁止内嵌源码树             |
| 2026-06-12 | §5      | P0 修复 — resiliencx 测试覆盖率验证 100% | 验证全包通过，解除阻断                                        |
| 2026-06-12 | §4.4    | xlib_standard SPEC Release 状态同步      | v1.0.0 已发布（tag v1.0.0），更新 Lifecycle State             |
| 2026-06-16 | §2.5    | 新增模块增殖约束（奥卡姆剃刀）           | 如无必要勿增实体；新增模块须满足必要性/唯一性/净收益三条件   |

---

## 第十三条：最高条款

### 13.1 效力层级

当文档之间存在冲突时，按以下优先级裁定：

```text
本宪法 (CONSTITUTION.md)
  ↓
模块规格 (module/*/SPEC.md)
  ↓
交付治理文档 (docs/governance/DEVELOPMENT-WORKFLOW.md, TRACEABILITY.md, LIFECYCLE.md 等)
  ↓
架构文档 (ARCHITECTURE.md)
  ↓
模块详情 (module/foundation-modules.md, FOUNDATION-SPEC.md)
  ↓
其他文档
```

### 13.2 适用范围

本宪法适用于 `github.com/ZoneCNH` 下：

- **模块实现**：所有基座层模块（19 个）和 L2.5 领域共享层（5 个）
- **交付管线**：数据域、分析域、决策域、执行域的功能开发（Bug 修复和配置变更可走轻量流程，但仍需满足 §15.2 D1 和 D6）

§1-§14 约束模块实现质量；§15-§19 约束交付流程质量。两者互补，不可互相豁免。

### 13.3 解释权

本宪法的解释权归项目维护者所有。AI 代理在遇到宪法条款的歧义时，应向人类维护者请求澄清，而非自行解释。

---

## 第十四条：管线自改约束（Anti-Goodhart）

> 适用于 Spec → Code 四源评分管线本身。目的是防止 RSI（递归自我改进）退化为 mode collapse 与 Goodhart 优化。

### 14.1 受保护文件清单

以下文件构成**评分系统根权限**。任何 agent（包括 `spec`、`task-executor`、`pipeline-arbiter`、所有 scorer）一律**禁止写入**：

| 类别       | 路径                                                                                                                     |
| ---------- | ------------------------------------------------------------------------------------------------------------------------ |
| Rubric     | `docs/governance/scoring/RUBRIC-*.md`                                                                                    |
| 评分方法论 | `docs/governance/STRUCTURAL-SCORING.md`                                                                                  |
| 仲裁协议   | `docs/governance/scoring/ARBITER-PROTOCOL.md`                                                                            |
| Agent 配置 | `.claude/agents/`、`.codex/agents/`、`.copilot/agents/` 下所有文件                                                       |
| 工作流入口 | `.claude/commands/spec-code-pipeline.md`、`.codex/skills/spec-code-pipeline/`、`.copilot/commands/spec-code-pipeline.md` |
| 外部指标   | `.omc/state/outer-metrics/`、`.omx/state/outer-metrics/`、`.copilot/state/outer-metrics/` 下所有文件                     |
| 本宪法     | `CONSTITUTION.md`                                                                                                        |

scorer 的 `min ≥ 98` 仲裁结果**不构成**修改上述文件的授权。

### 14.2 外部指标不可篡改

`{state_root}/outer-metrics/{module}.json` 只能由以下来源写入，其中 Claude 使用 `.omc/state`，Codex 使用 `.omx/state`，Copilot 使用 `.copilot/state`：

- CI 流水线（GitHub Actions、外部检查）
- 生产观测系统（实际运行数据）
- Git 历史的机械统计（`git log`、`git blame`）
- 人类维护者的手动登记

任何 LLM agent、scorer、arbiter、executor 均**只读**外部指标，禁止写入或修改。

### 14.3 RSI 合法形式

若需修改 §14.1 中的受保护文件，必须走 **outer-metric 验证的 RSI 流程**：

1. **Fork**：在新分支或新版本目录（`docs/governance/scoring/v{N+1}/`）创建候选 rubric / agent。
2. **A/B**：在至少 3 个真实模块上并行运行旧版与新版评分。
3. **Outer 验证**：以 `outer-metrics/` 中的真实指标（bug 数、返工次数、CI 失败率）评判，**不以 scorer 自身分数评判**。
4. **人类批准**：A/B 结果由人类维护者审阅并批准（这是宪法层面唯一的人工门）。
5. **合并**：批准后才能合并到主版本，旧版本作为历史归档。

未走该流程的任何受保护文件改动一律视为宪法违反，应被代码审查阻塞。

普通阶段产物允许自动修复和上游回退，但评分体系本身的 RSI 不得由当前评分结果自我授权。工作流、rubric、agent、arbiter、命令入口或本宪法的改进必须先作为 `docs/governance/improvements/{YYYYMMDD}-{slug}/SPEC.md` 通过同一条 Spec → Matrix → Tasks → Plan → Prompt → Code 管线，再进入本节的 fork、A/B、outer metric 与人类批准流程。

### 14.4 Goodhart 防线

- 任一 scorer 平台连续 N 个模块的评分与 outer metric 相关系数低于 0.6，必须冻结该 scorer 并触发 §14.3 RSI 流程。
- 任一阶段的"平均通过分数"持续上升但 outer metric 退化，视为 Goodhart 早期信号，必须冻结该阶段评分体系并触发 §14.3。
- 四源 `min ≥ 98` 不豁免本条款，只是必要条件。

### 14.5 同源相关性披露

`claude`、`codex`、`copilot` 三平台底层模型存在训练数据重叠，"独立评分"是工程近似，**不是统计独立**。本宪法承认此局限并要求：

- 任何新加入的平台必须公开模型族系与训练数据假设。
- `rules` 是当前要求的异构第四源；鼓励继续引入不同模型族、不同语料、静态分析器或生产反馈作为补充。
- 当前门禁已扩展为 `claude/codex/copilot/rules` 四源共识；长期目标是继续强化异构多源共识。

### 14.6 例外条款

§14.1 受保护文件清单本身的修订必须走 §14.3 RSI 流程，但 §14.2 至 §14.5 的条款只能由 §第十二条修正程序修改。这是为了防止"通过 RSI 自我废除 Anti-Goodhart 约束"。

### 14.7 与 §19 的关系

§14 管"评分体系本身的 RSI"（受保护文件清单、outer metric 验证）。§19 管"交付流程的 CRI"（模板、Gate、Prompt 的改进）。两者互补：

- §14 的改进必须走 fork/A/B/outer-metric/人类批准
- §19 的改进按风险分级审批
- 两者都禁止自证成功

---

## 第十五条：交付管线

> 适用于所有新功能开发。Bug 修复、文档更新、配置变更可走轻量流程，但仍需满足 D1（有来源）和 D6（有测试）。

### 15.1 管线模型

```text
Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
```

主流程每层必须产出一个具体制品，作为下一层的输入契约。Matrix 是横切追溯制品，必须在 Spec、Design、Plan、Tasks、Code、Test、Review、Release 之间持续更新，不作为主流程阶段。

### 15.2 管线七律

| 编号   | 原则                | 含义                                        |
| ------ | ------------------- | ------------------------------------------- |
| D1     | 无 Goal 不开始      | 任何代码变更必须追溯到已批准的 Goal         |
| D2     | 无 Spec 不拆解      | Goal 必须转化为可测试的 Spec 才能进入 Tasks |
| D3     | 无 Matrix 不开工    | 追溯矩阵必须建立才能开始编码                |
| D4     | 无 Task 不生成      | Prompt 必须引用具体 Task，不得开放式生成    |
| D5     | 无 Prompt 不交给 AI | AI 编码必须有结构化上下文和约束             |
| D6     | 无 Test 不完成      | 每条验收标准必须有对应测试                  |
| D7     | 无 Metrics 不算成功 | 上线后必须验证 Goal 达成                    |

### 15.3 变更传播

需求变更必须流经完整链条（Goal/Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release），并同步更新 Matrix 和 Evidence，禁止直接跳到代码修改。

### 15.4 实现细节

本条款的详细流程、制品模板和 Agent 编排规则见 `docs/governance/DEVELOPMENT-WORKFLOW.md`。

---

## 第十六条：追溯与门禁

### 16.1 统一制品 ID

| 前缀   | 制品        | 示例             |
| ------ | ----------- | ---------------- |
| G-     | Goal        | G-001            |
| S-     | Spec        | S-001            |
| M-     | Matrix edge | M-001            |
| T-     | Task        | TASK-REDISX-000  |
| P-     | Prompt      | P-001            |
| C-     | Code Module | CsvExportService |
| TC-    | Test Case   | TC-001           |

### 16.2 追溯覆盖要求

- 每个 Goal 必须有 Spec 覆盖
- 每个 P0 验收标准必须有 Test 覆盖
- 每个 Task 必须有 Goal 来源
- 每个 Code 变更必须有 Matrix 映射

### 16.3 孤儿检测

- 无 Goal 来源的 Task = 范围蔓延，必须标记或删除
- 无 Matrix 映射的 Code = 孤儿代码，必须标记或删除
- 无 Test 的 AC = 不可验证，不得标记完成

### 16.4 门禁

每层之间必须有质量门禁（DoR/DoD）。门禁可渐进增强（Shadow → Advisory → Enforced），但不可绕过。

### 16.5 实现细节

本条款的详细追溯矩阵和门禁规则见 `docs/governance/TRACEABILITY.md`、`docs/governance/DEFINITION-OF-READY.md`、`docs/governance/DEFINITION-OF-DONE.md`、`docs/governance/LIFECYCLE.md`。

---

## 第十七条：AI 辅助交付

### 17.1 Prompt 质量标准

AI 编码 Prompt 必须包含：

| 必需项      | 说明                 |
| ----------- | -------------------- |
| Task ID     | 本次执行的 Task 引用 |
| Spec 引用   | 相关需求上下文       |
| Matrix edge | 覆盖的追溯 edge      |
| 输入输出    | 明确的 I/O 契约      |
| 约束条件    | 不可违反的规则       |
| 禁止项      | 明确不得做的事情     |
| 测试要求    | 必须生成的测试       |

### 17.2 代码边界

Prompt 必须声明允许修改的文件/模块和禁止修改的文件/模块。Code Review 必须验证 AI 未越界。

### 17.3 输出验证

AI 生成的代码必须经过：

1. **自检**：是否只改了当前 Task 需要的内容
2. **矩阵检查**：是否覆盖所有 AC
3. **边界检查**：是否引入不必要依赖或破坏旧接口
4. **安全检查**：是否有安全问题

### 17.4 与 §11.3 的关系

§11.3 规定 AI 代理的审查规则（读 SPEC、检查设计原则、验证依赖方向）。本条款规定 AI 编码的输入质量标准。两者共同约束 AI 辅助交付的全链路。

---

## 第十八条：制品完成层级

### 18.1 四级 Done

| 层级   | 名称         | 含义     | 验证方式   |
| ------ | ------------ | -------- | ---------- |
| L1     | Code Done    | 代码写完 | 编译通过   |
| L2     | Test Done    | 测试通过 | 全量测试绿 |
| L3     | Release Done | 功能上线 | 部署成功   |
| L4     | Goal Done    | 目标达成 | 指标验证   |

### 18.2 Done 规则

- Code Done ≠ Test Done ≠ Release Done ≠ Goal Done
- PR 合并至少需要 Test Done
- 功能完成需要 Goal Done
- 不得将 Code Done 宣告为功能完成

### 18.3 Goal 验证

每个 Goal 必须定义可观测的成功指标。上线后必须回看指标，验证 Goal 是否真正达成。

### 18.4 实现细节

本条款的详细 DoD 清单见 `docs/governance/DEFINITION-OF-DONE.md`。

---

## 第十九条：受控递归改进（CRI）

> 适用于交付流程的改进（模板、Gate、Prompt、Spec 格式等）。评分体系本身的 RSI 由 §14 管辖。

### 19.1 CRI 七原则

| 编号   | 原则     | 含义                                 |
| ------ | -------- | ------------------------------------ |
| R1     | 证据驱动 | 基于真实缺陷和指标改进，不凭感觉     |
| R2     | 有界     | 改进交付系统，不改业务目标和成功标准 |
| R3     | 可追溯   | 每次改进可追溯到问题和根因           |
| R4     | 可验证   | 每次改进有验证方式                   |
| R5     | 可回滚   | 坏的改进可以撤销                     |
| R6     | 人工审批 | 高风险变更必须人工批准               |
| R7     | 价值导向 | 改进必须减少真实失败，不是增加仪式   |

### 19.2 改进对象边界

| 对象    | CRI 可做     | CRI 不可做        |
| ------- | ------------ | ----------------- |
| Goal    | 提出澄清建议 | 自动改目标        |
| Metrics | 建议补充指标 | 自动降低目标值    |
| Spec    | 建议补充边界 | 删除已批准需求    |
| Matrix  | 发现缺口     | 把缺口标记为 Done |
| Test    | 建议新增测试 | 删除失败测试      |
| Prompt  | 优化模板     | 诱导绕过约束      |
| Code    | 生成修复建议 | 自动合并生产代码  |
| Gate    | 建议增强     | 自动削弱          |

### 19.3 审批分级

| 风险    | 示例                        | 审批要求        |
| ------- | --------------------------- | --------------- |
| R0 高   | 修改 Release Gate、权限规则 | 必须人工审批    |
| R1 中高 | 修改 CI 阻断规则            | Tech Lead 审批  |
| R2 中   | 修改 Prompt/Spec 模板       | 工程 Owner 审批 |
| R3 低   | 增加模板示例                | 可自动或轻审批  |

### 19.4 改进记录

所有 CRI 改进必须作为 `docs/governance/improvements/{YYYYMMDD}-{slug}/SPEC.md` 通过同一条 Spec → Matrix → Tasks → Plan → Prompt → Code 管线，确保改进本身可追溯、可验证、可回滚。

---

## 附录 A：模块清单

| 层级           | 模块          | 规格                                   | 仓库                                                      |
| -------------- | ------------- | -------------------------------------- | --------------------------------------------------------- |
| L0 原语        | kernel        | [SPEC](./module/kernel/SPEC.md)        | [kernel](https://github.com/ZoneCNH/kernel)               |
| L1 运行时      | configx       | [SPEC](./module/configx/SPEC.md)       | [configx](https://github.com/ZoneCNH/configx)             |
| L1 运行时      | observex      | [SPEC](./module/observex/SPEC.md)      | [observex](https://github.com/ZoneCNH/observex)           |
| L1 运行时      | resiliencx    | [SPEC](./module/resiliencx/SPEC.md)    | [resiliencx](https://github.com/ZoneCNH/resiliencx)       |
| L1 运行时      | schedulex     | [SPEC](./module/schedulex/SPEC.md)     | [schedulex](https://github.com/ZoneCNH/schedulex)         |
| L1 test-only   | testkitx      | [SPEC](./module/testkitx/SPEC.md)      | [testkitx](https://github.com/ZoneCNH/testkitx)           |
| 标准源         | xlib_standard | [SPEC](./module/xlib_standard/SPEC.md) | [xlib_standard](https://github.com/ZoneCNH/xlib_standard) |
| 门禁           | xlibgate      | [SPEC](./module/xlibgate/SPEC.md)      | [xlibgate](https://github.com/ZoneCNH/xlibgate)           |
| 门禁           | xlib_harness  | [SPEC](./module/xlib_harness/SPEC.md)  | [xlib_harness](https://github.com/ZoneCNH/xlib_harness)   |
| 门禁           | xlib_evidence | [SPEC](./module/xlib_evidence/SPEC.md) | [xlib_evidence](https://github.com/ZoneCNH/xlib_evidence) |
| 存储扩展       | redisx        | [SPEC](./module/redisx/SPEC.md)        | [redisx](https://github.com/ZoneCNH/redisx)               |
| 存储扩展       | kafkax        | [SPEC](./module/kafkax/SPEC.md)        | [kafkax](https://github.com/ZoneCNH/kafkax)               |
| 存储扩展       | natsx         | [SPEC](./module/natsx/SPEC.md)         | [natsx](https://github.com/ZoneCNH/natsx)                 |
| 存储扩展       | postgresx     | [SPEC](./module/postgresx/SPEC.md)     | [postgresx](https://github.com/ZoneCNH/postgresx)         |
| 存储扩展       | taosx         | [SPEC](./module/taosx/SPEC.md)         | [taosx](https://github.com/ZoneCNH/taosx)                 |
| 存储扩展       | ossx          | [SPEC](./module/ossx/SPEC.md)          | [ossx](https://github.com/ZoneCNH/ossx)                   |
| 存储扩展       | clickhousex   | [SPEC](./module/clickhousex/SPEC.md)   | [clickhousex](https://github.com/ZoneCNH/clickhousex)     |
| 契约           | contracts     | [SPEC](./module/contracts/SPEC.md)     | [contracts](https://github.com/ZoneCNH/contracts)         |
| 契约/传输      | transportx    | [SPEC](./module/transportx/SPEC.md)    | [transportx](https://github.com/ZoneCNH/transportx)       |
| 领域共享       | domainx       | [SPEC](./module/domainx/SPEC.md)       | [domainx](https://github.com/ZoneCNH/domainx)             |
| 组合根         | x.go          | [SPEC](./module/xgo/SPEC.md)           | [x.go](https://github.com/ZoneCNH/x.go)                   |

## 附录 B：与 CLAUDE.md 的关系

`CLAUDE.md` 是 Claude Code 的工作指南，规定仓库级别的操作约定（文档同步、提交格式、安全红线）。本宪法是系统级别的治理文件，规定模块实现和交付管线的技术标准。

两者互补：

- `CLAUDE.md` 管"怎么编辑这个仓库"
- 本宪法管"怎么实现模块"（§1-§14）和"怎么交付功能"（§15-§19）

当两者冲突时，`CLAUDE.md` 中的安全条款（不提交凭证等）优先；技术条款以本宪法为准。
````


## 附录：L2.5 领域共享 v1.0.0 收口边界

截至 2026-06-15，L2.5 领域共享层按以下五个模块收口 v1.0.0 执行计划：

| 模块 | 归属边界 | 发布依赖 |
| --- | --- | --- |
| `decimalx` | Decimal、Money、Currency、rounding/context、JSON/SQL 数值边界 | 第一优先级 |
| `domain_market` | Tick、Quote、Bar、OrderBook、Instrument、Funding、OpenInterest、LongShortRatio、MarketDataQuality | `decimalx` |
| `domain_macro` | MacroPoint、MacroInformationSet、revision、freshness、no-lookahead visibility | `decimalx` 精度 ADR |
| `domainx` | Order、Trade、Position、Portfolio、ExecutionReport、OrderSide、OrderType、OrderState | `decimalx`，并与 `domain_market` 边界对齐 |
| `domain_exchange` | Exchange SPI、VenueCapability、RateLimitPolicy、ExchangeError、Registry | `decimalx`、`domain_market`、`domainx` |

L2.5 公共规则：公开金融数值字段不得使用 public `float64` 表示价格、数量、金额、费率或名义价值；领域共享层不得暴露 transport DTO、provider 原始响应、HTTP/WS/Kafka/TDengine 细节或数据库 ORM tag；跨模块重复语义必须收敛到唯一 SSOT。
