# .worktree/1.md 深度分析报告

- 日期：2026-06-20
- 分析对象：`/home/ZoneCNH/.worktree/1.md`
- 报告位置：`docs/report/worktree-1-deep-analysis-20260620.md`
- 分析基准：`origin/main` 的隔离 worktree，HEAD `df2bf8c`
- 权威锚点：`CONSTITUTION.md`、`ARCHITECTURE.md`、`module/FOUNDATION-DEPS.yaml`

## 结论摘要

`.worktree/1.md` 是一份方向有价值但尚不能作为架构执行指令的风险备忘录。它准确抓住了两个真实问题：模块增长可能快于边界冻结，以及 AI 生成代码容易把“可复用模块”推向“横向泄漏层”。但文稿中段仍保留“Constitution Layer 缺失”“新增 `infra` / `runtimex` / `archlint`”等旧判断，这些判断与当前仓库已经存在的最高治理文件和依赖拓扑冲突，也与文稿后段“不要新增 layer”的收敛结论冲突。

当前最小正确动作不是新增模块，而是把 `.worktree/1.md` 改写为一份“强化现有 Constitution-Gated Architecture 与门禁证据链”的治理报告。所有新增模块建议都应降级为待证假设，除非能满足 `CONSTITUTION.md` 对模块增殖的必要性、唯一性和净收益证明。

## 关键判断

| 优先级 | 判断 | 处理建议 |
| --- | --- | --- |
| P0 | “Constitution Layer 缺失”是事实错误 | 删除或改写为“现有 Constitution 需要被门禁化执行” |
| P0 | 文稿同时主张“不新增 layer”和新增 `infra` / `runtimex` / `archlint` | 保留“不新增 layer”，删除新增模块路线 |
| P1 | `infra` 层建议证据不足，且会冲击现有 storage extension 模型 | 改为针对 redisx/kafkax/natsx/clickhousex 的重复逻辑审计 |
| P1 | “kernel 正在膨胀”需要源码级证据 | 改成可验证检查项，而不是先移动职责 |
| P1 | transportx 风险判断方向正确，但边界表述过度收缩 | 保留禁止业务/具体 SDK/工作流，避免误删 transport 运行时语义 |
| P2 | bootstrap 的约束大多已经由当前架构定义 | 从“重新定位”改成“验证实现是否越界” |
| P2 | Shared Domain 小节部分过时 | 对齐当前 `domainx`、`decimalx`、`domain-market`、`domain-exchange`、`domain-macro` 拓扑 |

## 分级问题

### P0：把已存在的最高治理文件误判为缺失

`.worktree/1.md` 在 141-177 行仍称需要新增 `Constitution Layer（缺失）`，并在 268-293 行建议新建 `docs/constitution/`。这与仓库现状冲突。

证据：

- `CONSTITUTION.md` 已声明自身是最高治理文件，冲突时优先级高于其他文档。
- `CONSTITUTION.md` 已包含分支纪律、设计原则、模块增殖约束、依赖拓扑和受控递归改进规则。
- `ARCHITECTURE.md` 已定义代码依赖、业务流向、运行时装配三类视图分离，并明确 `x.go` 是 composition root。
- `module/FOUNDATION-DEPS.yaml` 已机器可读地定义模块层级、允许依赖、禁止边界和特殊规则。

影响：

如果按文稿中段执行，会产生第二套宪法目录或第二套层级命名，破坏现有治理权威，增加未来维护者判断“到底听哪个文件”的成本。

建议：

把相关章节改为：

> 最高治理文件已经存在，问题不是缺少 Constitution，而是 Constitution / Architecture / Foundation-Deps 的门禁执行和证据回填还需要更强绑定。

### P0：新增 layer 路线与文稿自身收敛结论冲突

`.worktree/1.md` 的 375-446 行建议新增 `module/infra`、`module/runtimex`、`module/archlint`；513-534 行继续主张 `infra -> redisx/kafkax/...`。但 570-631 行又明确指出未来六个月应冻结架构、不新增 layer，并在 631 行要求不要用 `infra` / `runtimex` 替换现有边界。

证据：

- `CONSTITUTION.md` 的模块增殖约束要求新模块必须证明必要性、唯一性和净收益，禁止 future-only module、单配置/单函数 module、等价 module。
- `module/FOUNDATION-DEPS.yaml` 已存在 L0、L1 primitives、L1 assembly、storage extensions、contracts、transportx、xlib governance、x.go composition root 等拓扑。
- `ARCHITECTURE.md` 已将 bootstrap、transportx、storage extensions、governance modules 分别定位。

影响：

新增 `infra` / `runtimex` / `archlint` 会把“边界治理问题”错误转化为“模块扩张问题”。这会制造新的依赖层、迁移成本和命名冲突，也会削弱当前 `xlibgate` / `FOUNDATION-DEPS.yaml` 的治理地位。

建议：

保留文稿后段的收敛方向，删除新增 layer 方案。若未来确需新增模块，必须先给出：

- 当前模块无法承载该职责的具体证据。
- 至少两个以上现有模块出现同构重复或边界无法表达的证据。
- 新模块不会与 `bootstrap`、`resiliencx`、`transportx`、`xlibgate` 形成职责重叠的证明。
- 对 `FOUNDATION-DEPS.yaml` 的最小变更方案。

### P1：`infra` 层判断应降级为审计假设

文稿认为 redisx/kafkax/natsx/clickhousex 会重复实现 config、retry、tracing、metrics、health、lifecycle，因此需要新增 `infra`。这个风险合理，但当前报告没有给出源码级重复证据。

证据：

- `module/FOUNDATION-DEPS.yaml` 已把 redisx/kafkax/natsx/clickhousex 等定位为 storage extensions。
- storage extensions 的允许依赖和特殊约束已经存在，不是无治理状态。
- `bootstrap` 的允许依赖已经覆盖这些可选 adapter，用于装配而不是让 adapter 横向互相依赖。

影响：

如果未证明重复就新增 `infra`，会把 adapter 的实现规范问题升级成层级重构，成本高且容易违反模块增殖约束。

建议：

改成一个证据驱动的审计任务：

| 检查项 | 目标 |
| --- | --- |
| storage adapter 是否互相 import | 验证是否出现横向耦合 |
| retry/health/metrics/tracing 是否重复定义接口 | 判断是否需要抽取到既有 primitives |
| adapter 是否硬编码配置解析 | 判断是否违反 configx/bootstrap 边界 |
| adapter 是否自行管理全局生命周期 | 判断是否越过 bootstrap/lifecycx |

只有当审计证明现有 primitives 无法承载重复职责时，才讨论新增模块。

### P1：kernel 缩小建议需要源码级证明

`.worktree/1.md` 的 315-371 行认为 kernel 包含 lifecycle、retry、obs、health、validation、shutdown 后会成为 super-foundation，并建议移动 retry/obs/validation 等职责。这个担忧可以作为风险，但不能直接作为重构结论。

证据：

- 当前治理文件把 kernel 定位为 L0、stdlib-only、无隐藏 goroutine 的最小基础层。
- `CONSTITUTION.md` 和 `FOUNDATION-DEPS.yaml` 已明确 kernel 的禁止依赖与特殊约束。
- kernel 是否膨胀，应通过包数量、导入图、跨包依赖、公共 API 面、实现复杂度和非标准库依赖来判断，而不是仅从名称判断。

影响：

如果仅因为包名看起来接近运行时能力就移动职责，可能破坏 L0 的稳定性，并把已有基础能力拆到更高层，导致反向依赖或重复实现。

建议：

把“kernel 应缩小”改成门禁问题：

- kernel 是否仍然 stdlib-only。
- kernel 内包之间是否保持低耦合。
- kernel 是否出现配置解析、具体日志/指标/追踪 backend、网络监听、存储、业务 DTO。
- kernel 是否启动隐藏 goroutine 或持有进程级 runtime 状态。

若这些检查不失败，不应启动 kernel 拆分。

### P1：transportx 边界风险成立，但不能过度收缩

文稿在 450-482 行指出 transportx 可能变成框架层，这个风险成立。问题在于它将 transportx 限定为 protocol/codec/framing/stream/auth transport，可能过度排除当前规范中合理的 transport 运行时语义。

证据：

- 当前架构把 `transportx` 定位为应用通信抽象、请求响应契约、codec、middleware、error mapping、timeout/cancellation/trace/idempotency propagation 等。
- 当前治理同时禁止 concrete broker/client/protocol SDK、business semantics、domain model、workflow engine、service mesh、API gateway 等进入 transportx。

影响：

正确边界不是“transportx 不能有任何 runtime 语义”，而是“transportx 只能拥有通信抽象所需的 runtime 语义，不能拥有业务、工作流、具体 SDK 和跨进程编排”。

建议：

将文稿表述改为：

> transportx 允许通信抽象所必需的生命周期、超时、取消、追踪传播和错误映射；禁止业务 DTO、订单/行情/账户语义、具体 broker/client SDK、服务发现、工作流编排和 API gateway 职责。

### P2：bootstrap 的建议基本已被当前架构覆盖

`.worktree/1.md` 的 486-509 行要求 bootstrap 只做 wiring、assembly、startup、dependency graph，不做 runtime/business/infra governance。这与当前架构基本一致。

证据：

- `ARCHITECTURE.md` 明确 bootstrap 是 L1 assembly，只负责 Build/Run/Shutdown 的 process entry assembly。
- 当前拓扑要求 bootstrap 不承载 business semantics、domain contracts、HTTP/gRPC listener、cross-process orchestration。
- `FOUNDATION-DEPS.yaml` 已明确 bootstrap 的允许依赖和 x.go composition-root 规则。

建议：

这一节应从“架构建议”改为“实现审计清单”：

- bootstrap 不 import L2.5 shared domain。
- bootstrap 不 import business domain。
- bootstrap 不定义业务配置 schema。
- bootstrap 不 `net.Listen`。
- bootstrap 不定义跨进程协议和 domain contracts。

### P2：Shared Domain 小节需要对齐当前拓扑

`.worktree/1.md` 的 538-566 行建议拆出 `domain-market`、`domain-exchange`、`domain-account`、`domain-order`。该方向反映了共享领域语义需要提前治理，但命名与当前拓扑不完全一致。

证据：

- 当前架构已经使用 `domainx`、`decimalx`、`domain-market`、`domain-exchange`、`domain-macro` 等 L2.5 shared domain 形态。
- `CONSTITUTION.md` 要求共享领域语义进入 L2.5，并防止策略、执行、订单等模块各自定义相同概念。

建议：

保留“共享领域语义要提前冻结”的判断，但不要把示例模块当成新增任务。应先对齐现有 L2.5 模块和实际重复语义，再决定是否需要补充新 shared domain。

## 证据、推论与未知

### 已有证据

- 最高治理文件已存在：`CONSTITUTION.md`。
- 架构拓扑已存在：`ARCHITECTURE.md`。
- 机器可读依赖矩阵已存在：`module/FOUNDATION-DEPS.yaml`。
- `.worktree/1.md` 自身后段已收敛到“不新增 layer、冻结现有拓扑、强化边界”的方向。

### 合理推论

- `.worktree/1.md` 可能经历过局部修订，前中段旧方案没有完全清理，导致“新增 layer”和“不新增 layer”并存。
- 文稿的真正价值不在新增模块，而在把 AI 编码下的依赖越界风险转成门禁、审计和证据回填。
- 现有治理体系的问题更可能是执行强度不足，而不是文件或模块数量不足。

### 当前未知

- 未对 `/home/{module}` 下各独立模块源码执行完整 import graph 审计。
- 未运行 `xlibgate` 或等价依赖门禁验证。
- 未验证 redisx/kafkax/natsx/clickhousex 是否实际重复实现 retry/health/metrics/tracing/lifecycle。
- 未验证 kernel 当前公共 API 面是否已经超过 L0 基础层可接受范围。

这些未知决定了报告不能直接得出“新增 infra/runtimex/archlint”或“拆 kernel”的结论。

## 建议改写结构

建议把 `.worktree/1.md` 改写为以下结构：

1. **问题定义**：模块化已经有了，风险是边界执行和证据链不足。
2. **权威锚点**：以 `CONSTITUTION.md`、`ARCHITECTURE.md`、`FOUNDATION-DEPS.yaml` 为唯一治理基线。
3. **冻结拓扑**：不另起 L0-L8，不新增 layer，不把 audit label 升级成 module。
4. **风险清单**：kernel、bootstrap、transportx、storage extensions、L2.5 shared domain、x.go composition root。
5. **门禁矩阵**：把每个风险改写成可执行检查，而不是立即重构。
6. **不做事项**：不新增 `infra`、不新增 `runtimex`、不新增 `archlint`、不新建第二套 constitution 目录。
7. **证据计划**：import graph、API 面、重复接口、adapter 横向依赖、xlibgate 结果。
8. **收敛结论**：当前阶段目标是 Constitution-Gated Architecture 的执行闭环，不是模块宇宙扩张。

## 可执行门禁草案

| 边界 | 必须保持 | 禁止信号 |
| --- | --- | --- |
| kernel | stdlib-only、低耦合、无隐藏 goroutine | config parsing、storage/network/backend、business DTO、具体 log/metric/tracing backend |
| bootstrap | Build/Run/Shutdown、装配 L1 primitives 与可选 adapter | business import、domain contracts、HTTP/gRPC listener、workflow orchestration |
| storage extensions | 具体 adapter 封装，依赖 kernel 和注入接口 | adapter 横向 import、重复 governance interface、全局 lifecycle owner |
| transportx | 通信抽象、codec、middleware、错误映射、传播语义 | 具体 broker/client SDK、业务 DTO、domain model、service mesh/API gateway |
| L2.5 shared domain | 跨业务稳定语义 | 策略或执行私有逻辑、运行时装配、adapter 细节 |
| x.go | composition root 和 wiring | 业务规则、领域模型、协议细节、底层 adapter 实现 |
| xlib governance | 标准、证据、门禁、评分 | runtime dependency、业务依赖、框架能力 |

## 对 `.worktree/1.md` 的保留与删除建议

### 应保留

- “模块化已经有了，层级执行还要更强”的核心判断。
- AI 编码导致边界泄漏的风险描述。
- 对 kernel/bootstrap/transportx/storage/shared domain 的风险枚举。
- “Architecture Freeze / 不新增 layer / Constitution-Gated Architecture”的收敛方向。
- 将架构治理落到门禁、证据和依赖矩阵的思路。

### 应删除或降级

- `Constitution Layer（缺失）`。
- 新建 `docs/constitution/` 的建议。
- `module/infra`、`module/runtimex`、`module/archlint` 作为当前行动项。
- 未经 import graph 和源码重复证据支持的“kernel 必须拆分”。
- 把 transportx 简化为纯 codec/protocol 层的过窄定义。

### 应补充

- 引用现有 `CONSTITUTION.md`、`ARCHITECTURE.md`、`FOUNDATION-DEPS.yaml`。
- 明确哪些是证据、哪些是推论、哪些仍未知。
- 把每个风险变成可执行检查项。
- 加入“不新增模块，除非满足 Constitution 模块增殖证明”的硬约束。

## 最终结论

`.worktree/1.md` 不应作为新增架构层或新增模块的依据。它应被收敛为一份架构治理风险报告：用现有 Constitution、Architecture 和 Foundation-Deps 冻结拓扑，通过 xlibgate/evidence/import graph 等机制证明边界是否被违反。

最小后续动作是清理文稿内部冲突，而不是创建 `infra`、`runtimex` 或 `archlint`。如果要推进实际修复，应先做只读源码审计，拿到重复逻辑、非法依赖或边界越界证据，再按 `CONSTITUTION.md` 的模块增殖约束决定是否需要结构性调整。
