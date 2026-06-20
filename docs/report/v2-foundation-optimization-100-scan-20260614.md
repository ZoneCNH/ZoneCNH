# v2 可信化收敛优化方案：100 轮深度扫描报告

## 执行元数据

- 分析日期：2026-06-14
- 工作分支：`docs/v2-optimization-report-20260614`
- 来源提交：`06eee735af29c4764407c2fd5116334258a38c2fd`
- 输入文档：`.worktree/v2.md`
- 输出文档：`docs/report/v2-foundation-optimization-100-scan-20260614.md`
- 扫描范围：根目录公开投影文档、`module/` 规格库、治理文档、Foundation 依赖矩阵与当前状态文档
- 排除范围：`docs/report/node_modules/**`
- 扫描次数：100

## 证据边界

证据来自本仓库当前文件与 `.worktree/v2.md`。本报告中的文件行号、模块数量、状态判断均以本地仓库为准。

推论来自对 `.worktree/v2.md` 的目标、当前项目文档事实、治理约束与模块边界的交叉分析。

未知项包括 `.worktree/v2.md` 内嵌 GitHub 公开事实的实时状态、各 `/home/{module}` 源码仓库的最新代码状态、外部 CI 与真实生产运行数据。进入跨仓库 PR 前必须重新校验这些外部事实。

## 关键证据索引

| 证据主题 | 本地证据 |
| --- | --- |
| 当前基座模块数 | `module/README.md:3`、`README.md:21` 与 `ARCHITECTURE.md:123` 均声明当前规格库是 20 个基座模块；`STATUS.md:117-136` 给出 20 项基座明细。 |
| xlib_standard 拆分事实 | `README.md:31`、`README.md:61-63`、`ARCHITECTURE.md:173` 与 `ARCHITECTURE.md:445` 均显示 `xlib_standard` 已拆出 `xlib_harness` 与 `xlib_evidence`。 |
| 新增模块投影 | `module/README.md:25-32`、`module/README.md:110-111`、`module/README.md:149`、`ARCHITECTURE.md:135-146` 覆盖 `xlib_harness`、`xlib_evidence` 与 `domainx` 的当前公开投影。 |
| FOUNDATION-DEPS 漂移 | `module/FOUNDATION-DEPS.yaml:20` 之后的模块清单仍停留在旧口径；`module/FOUNDATION-DEPS.yaml:137-138` 的允许依赖仍只显式列出 `testkitx` 与 `xlib_standard`，未覆盖新拆分模块。 |
| xlibgate 当前契约 | `module/xlibgate/SPEC.md:64`、`module/xlibgate/SPEC.md:85`、`module/xlibgate/SPEC.md:89`、`module/xlibgate/SPEC.md:146-164`、`module/xlibgate/SPEC.md:217-221` 说明现有 `check all`、`secret_scan` 与 `l2 release-check` 能力。 |
| xlibgate 兼容约束 | `module/xlibgate/SPEC.md:323`、`module/xlibgate/SPEC.md:338` 与 `module/xlibgate/SPEC.md:344` 固化了当前 CLI 用法与 0/1/2 退出码语义，因此 v2 的扩展退出码应落到 JSON `reason_code`，不能破坏旧契约。 |
| 成熟度语义风险 | `ARCHITECTURE.md:287`、`ARCHITECTURE.md:294-313`、`STATUS.md:54-55`、`STATUS.md:121-136` 大量使用 100% 或完成口径，必须拆成 spec、implementation、release、integration、external CI、downstream adoption、production soak、factory grade。 |
| natsx 未闭环项 | `STATUS.md:129` 与 `STATUS.md:259` 标明 natsx 仍有正式四源 98+ arbiter 归档与生产 TLS 生产级门禁待收敛。 |
| v2 目标锚点 | `.worktree/v2.md:1997`、`.worktree/v2.md:2107-2110`、`.worktree/v2.md:3688`、`.worktree/v2.md:6790-6792`、`.worktree/v2.md:7157`、`.worktree/v2.md:7246`、`.worktree/v2.md:7330`、`.worktree/v2.md:7406`、`.worktree/v2.md:8167` 共同指向 repo-contract、identity、template-residue、release-consistency、maturity 与 xlibgate 自动阻断。 |

## 执行结论

`.worktree/v2.md` 的主张是正确的：FoundationX 下一步不应继续扩大功能面，而应先做 `Trust Alignment`，把公开叙述、规格、依赖矩阵、发布证据、成熟度口径和机器门禁收敛到一个可信事实源。

但 v2 的方案生成时间早于当前仓库的部分事实。当前项目已经进入 20 个基座模块视角：`xlib_standard` 已拆出 `xlib_harness` 与 `xlib_evidence`，新增 `domainx`，并且 `module/README.md` 明确自己是模块规格库 SSOT。优化方案必须以当前 20 模块事实为基准，而不是回到 v2 早期的 17/18 模块假设。

最重要的落地点不是再写一组 Markdown 状态表，而是建立：

- 一个机器可读事实源：建议采用 `.foundationx/repo-contract.json` 作为模块事实契约；
- 一组 xlibgate 门禁：身份、模板残留、发布一致性、成熟度维度、依赖边界、证据索引、fleet 状态生成；
- 一组生成型投影：`README.md`、`ARCHITECTURE.md`、`STATUS.md` 只展示由事实源生成或校验过的公开状态；
- 一套 20 模块收敛队列：先修本仓库事实漂移，再推进跨仓库发布与生产硬化。

## 当前项目事实校准

| 扫描面 | 当前事实 | 对 v2 的修正 |
| --- | --- | --- |
| 模块数量 | `module/README.md` 声明当前基座规格库为 20 个模块，且 `rg --files module -g 'SPEC.md'` 也返回 20 个规格。 | v2 中的 17/18 模块口径必须升级为 20 模块口径。 |
| xlib_standard | `README.md` 与 `ARCHITECTURE.md` 已把 Generator、Harness、Evidence 拆到 `xlib_harness` 与 `xlib_evidence`。 | v2 中对 xlib_standard 的“标准+模板+门禁+证据”合体叙述必须拆分。 |
| xlibgate | `module/xlibgate/SPEC.md` 已有 `check` 与 `l2` 命令组，退出码当前定义为 0/1/2。 | v2 的 0-4 退出码不能直接替换，应保持兼容并把细分原因放到 JSON `reason_code`。 |
| domainx | `module/domainx/SPEC.md` 已成为 L2.5 共享领域模型层。 | v2 的 contracts/transportx 边界方案应加入 domainx，否则 contracts 会承载过多领域模型职责。 |
| FOUNDATION-DEPS | `module/FOUNDATION-DEPS.yaml` 仍含旧 xlib_standard 职责与缺失模块。 | 这是当前最优先修复的本仓库事实漂移点。 |
| 状态语义 | `STATUS.md` 与根文档仍大量使用 100% 或完成状态。 | 需要按 spec、implementation、release、live integration、external CI、downstream adoption、production soak、factory grade 拆分成熟度。 |
| 治理门禁 | `CONSTITUTION.md` 与治理文档要求分支纪律、Spec 管线、四源评分与可追溯证据。 | v2 优化必须作为文档/门禁收敛工程推进，不能绕过 Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code。 |

## 100 轮扫描登记

| # | 扫描面 | 结论 | 方案落点 |
| --- | --- | --- | --- |
| 1 | 任务边界 | 用户要求深度分析 v2 并保存报告，不要求直接改模块源码。 | 本次只产出优化方案报告，避免跨仓库无授权修改。 |
| 2 | 分支纪律 | 当前已在功能分支工作，符合禁止 main 直接编辑的治理要求。 | 后续任何落地 PR 继续从 main HEAD 派生。 |
| 3 | 最高权威 | `CONSTITUTION.md` 高于 AGENTS 与普通文档。 | 优化方案不得破坏分支纪律、模块边界、Spec 管线。 |
| 4 | 仓库性质 | 本仓库是个人主页、架构索引和规格库，不是模块源码仓库。 | 报告只规划本仓库事实源、投影与跨仓库执行顺序。 |
| 5 | v2 主线 | v2 主题是 Trust Alignment，不是功能扩张。 | 将优化目标定义为可信化收敛。 |
| 6 | v2 风险 | v2 多次指出公开事实、README、release、manifest、evidence、maturity 漂移。 | 建立机器事实源和门禁。 |
| 7 | v2 不变量 | xlib_standard/xlibgate 到 kernel 到 L1/L2 的方向必须保持。 | 依赖矩阵先修正，再让 xlibgate 检查。 |
| 8 | v2 文件格式 | v2 早期提 `.repo-contract.yaml`，后期转为 `.foundationx/repo-contract.json`。 | 采用 JSON 作为 Go stdlib 友好的默认契约。 |
| 9 | v2 输出 | v2 要求 status、blockers、evidence、release manifest 可机器读取。 | 定义 contract、blockers、evidence-index、status.generated 四类文件。 |
| 10 | v2 stop condition | v2 的停止条件是事实一致并可由机器阻断漂移。 | 把最终验收定义为 xlibgate 和生成投影同时通过。 |
| 11 | 模块规格数量 | 当前 `module/` 下有 20 个 `SPEC.md`。 | 所有状态表、依赖矩阵与 fleet 输出必须为 20 行。 |
| 12 | 根 README | 根 README 已称 20 个基座模块。 | v2 旧模块数不得继续作为公开口径。 |
| 13 | ARCHITECTURE | 架构文档也列出 20 个模块和新分层。 | 优化方案以 ARCHITECTURE 当前分层为架构基准。 |
| 14 | STATUS | STATUS 的基座表也是 20 项。 | 生成状态时优先保持 20 项完整性。 |
| 15 | module/README | module/README 声明自己是模块规格 SSOT。 | 根 README/ARCH/STATUS 应作为投影，而非并列事实源。 |
| 16 | FOUNDATION-DEPS | 依赖矩阵仍是 18 模块级别。 | P0 必须补齐 xlib_harness、xlib_evidence、domainx。 |
| 17 | FOUNDATION-SPEC | Foundation 旧 spec 是六模块初始规划。 | 标注历史或阶段一，避免被误当当前完整事实。 |
| 18 | FOUNDATION-V1 | Foundation V1 已声明自己是初始规划文档。 | 保留为历史，但不能驱动当前模块清单。 |
| 19 | FOUNDATION-TRACKER | Tracker 声称 20/20 完成。 | 用来校准完成事实，但仍需和 DEPS/STATUS 自动一致。 |
| 20 | foundation-modules | 旧模块说明仍带六模块和旧 xlib_standard 口径。 | 修正文档定位与 Markdown code fence。 |
| 21 | xlib_standard | 当前应只承载标准、模板、约束和参考事实。 | 删除 generator、harness gate、evidence runtime 职责语言。 |
| 22 | xlib_harness | 当前为 Draft，负责生成与脚手架/格式/traceability gate。 | 通过评分门禁升为 Approved 后纳入 release lane。 |
| 23 | xlib_evidence | 当前为 Draft，负责证据运行时和 release manifest。 | 补齐 manifest/hash-chain/evidence-index 规格与任务。 |
| 24 | xlibgate | 当前已有 check/l2 基线，但缺少 v2 的身份与模板残留检查。 | 在 v1.0.2 上增量加 check identity/template-residue/release-consistency。 |
| 25 | xlibgate CLI | 当前退出码 0/1/2 是已批准契约。 | 不直接采用 v2 0-4；新增 JSON status code 兼容扩展。 |
| 26 | xlibgate JSON | v2 需要机器报告。 | 每个 check 输出统一 schema：status、findings、reason_code、evidence。 |
| 27 | xlibgate offline | v2 强调 release consistency 可 offline。 | release 检查默认读取本地 manifest/tag projection，不依赖网络。 |
| 28 | xlibgate fleet | v2 需要 fleet status generation。 | 增加 `xlibgate fleet status` 或 `xlibgate check all --fleet` 方案。 |
| 29 | xlib_harness 边界 | harness 不执行 evidence，不定义 standard。 | 与 xlib_standard/xlib_evidence 的边界写入 DEPS。 |
| 30 | xlib_evidence 边界 | evidence 不执行 gate，只收集与验证证据。 | xlibgate 负责判定，xlib_evidence 负责证据包。 |
| 31 | kernel | kernel 是基础抽象层，不能反向依赖 L1/L2。 | import-boundary gate 把 kernel 反向依赖列为红线。 |
| 32 | configx | configx 属 L1 配置基础设施。 | 允许上层读取配置，不允许 configx 了解业务域。 |
| 33 | observex | observex 应保持 vendor-neutral interface。 | 禁止写死 provider 或把观测语义变成业务逻辑。 |
| 34 | resiliencx | 当前 docs 允许 operational runtime 角色。 | 明确它不是 risk_engine，不能承载交易决策。 |
| 35 | schedulex | 调度基础设施应保持通用。 | 禁止和交易周期/策略语义耦合。 |
| 36 | testkitx | testkitx 是测试专用。 | xlibgate 检查生产代码 import testkitx 为阻断项。 |
| 37 | contracts | contracts 是跨域稳定契约。 | 保持 DTO/event/port，避免传输实现和业务流程。 |
| 38 | transportx | transportx 是通信机制。 | 不拥有 domain DTO，不变成 contracts 的替代。 |
| 39 | domainx | domainx 是 L2.5 共享领域模型。 | DEPS 与 contracts 边界必须纳入 domainx。 |
| 40 | L2 存储模块 | storage 扩展只依赖允许基础层。 | import-boundary gate 读取 FOUNDATION-DEPS。 |
| 41 | 100% 语义 | 当前文档有多个 100%，含义不同。 | 拆分成熟度维度，避免单一百分比误导。 |
| 42 | spec maturity | Spec Approved 不等于发布完成。 | 单列 `spec_status`。 |
| 43 | implementation maturity | 实现完成不等于集成完成。 | 单列 `implementation_status`。 |
| 44 | release maturity | tag/release/manifest 是独立事实。 | 单列 `release_status` 与 manifest hash。 |
| 45 | live integration | 真实服务集成不同于 mock。 | 单列 `live_integration_status`。 |
| 46 | external CI | 外部 CI 与本地测试不同。 | 单列 `external_ci_status`。 |
| 47 | downstream adoption | 被下游模块使用才说明可复用。 | 单列 `downstream_adoption_status`。 |
| 48 | production soak | 生产或准生产运行需要时间窗口。 | 单列 `production_soak_status`。 |
| 49 | factory grade | factory grade 是最高综合等级。 | 定义 factory gate 必须满足的组合条件。 |
| 50 | blockers | v2 要求 blockers 可机器读取。 | 每模块维护 `.foundationx/blockers.json`。 |
| 51 | redisx | 当前已发布，但需 release consistency 与 manifest 校准。 | L2 manifest + status generated 对齐。 |
| 52 | kafkax | 当前已发布，但需真实发布事实一致。 | 加 tag/release/manifest 三方一致检查。 |
| 53 | clickhousex | 当前 v1.0.1 完成度高。 | 用作 L2 evidence-index 参考样本。 |
| 54 | natsx | 当前唯一公开基座 blocker 是正式四源仲裁和生产 TLS gate。 | P1/P2 高优先处理。 |
| 55 | postgresx | 当前 release/live 集成完成，但 production soak/adoption 仍应拆维度。 | 避免用 v1.0 完成覆盖所有成熟度。 |
| 56 | taosx | 当前 v1.0.1。 | 纳入 L2 manifest consistency。 |
| 57 | ossx | 当前 v1.0.1，真实 Aliyun OSS evidence 已列。 | 纳入 evidence-index 样板。 |
| 58 | contracts L2.5 | 当前应和 domainx 协同。 | contracts 只引用 domainx 模型，不复制业务语义。 |
| 59 | transportx v1.1.1 | 当前为 spec baseline。 | 标记 release lane 与 implementation maturity 分离。 |
| 60 | domainx v1.0.0 | 当前 Approved 共享领域模型。 | 写入 FOUNDATION-DEPS 并加入生成状态。 |
| 61 | README 投影 | README 是公开简介，不能成为手工事实源。 | 由 status.generated 校验核心状态块。 |
| 62 | ARCHITECTURE 投影 | ARCHITECTURE 是架构说明，包含状态表。 | 状态表由事实源生成或自动校验。 |
| 63 | STATUS 投影 | STATUS 是当前状态看板。 | 变成 generated projection 或至少有 generated block。 |
| 64 | module/README SSOT | 当前已声明 module/README 是规格库索引。 | 作为人读索引，事实仍从每模块 contract 汇总。 |
| 65 | FOUNDATION-DEPS SSOT | 目前承担依赖矩阵角色，但自身漂移。 | 修复后由 xlibgate 消费。 |
| 66 | FOUNDATION-TRACKER | Tracker 是完成账本，不适合长期手工同步。 | 用 status.generated 替代长期人工摘要。 |
| 67 | 历史文档 | 旧六模块文档容易误导。 | 加历史横幅并说明当前 SSOT。 |
| 68 | Markdown 格式 | 旧文档存在 code fence 风险。 | 增加 markdown lint 或简单 fence check。 |
| 69 | 文档引用 | 当前多处交叉引用模块状态。 | 加 drift check 保持同一模块状态一致。 |
| 70 | 报告目录 | docs/report 已有历史分析报告。 | 新报告保留独立日期文件，不覆盖旧证据。 |
| 71 | Spec 管线 | 任何模块重大变更应走 Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code。 | xlibgate 新能力先写 SPEC/TRACEABILITY/TASK。 |
| 72 | 四源评分 | 98 分门禁是治理要求。 | harness/evidence Draft 升级必须四源评分通过。 |
| 73 | branch gate | main 禁止直接编辑。 | PR 队列按主题拆小。 |
| 74 | protected workflow | 改治理或评分机制本身也要走管线。 | 不在本报告直接修改管线规则。 |
| 75 | traceability | 需求、AC、TC 必须闭合。 | 每个 xlibgate 新 check 都要有 FR/AC/TC。 |
| 76 | evidence | 完成声明必须有验证命令或证据文件。 | release status 不再只靠文字描述。 |
| 77 | Definition of Done | Done 包含测试、审查、证据、文档。 | factory gate 对齐 DoD。 |
| 78 | Definition of Ready | 进入实现前需边界明确。 | P0 先完成事实源和 contract schema。 |
| 79 | arbitration | scorer/arbiter 不能被单一 LLM 替代。 | status 变更需保留 arbiter verdict 链接。 |
| 80 | recursion limit | 有界递归自改进最多三次。 | xlibgate/fleet 方案避免无限修文档。 |
| 81 | CI 入口 | SRE CI/CD 计划仍 pending。 | 将 trust gates 接入 CI 作为 P3/P4。 |
| 82 | fleet scan | v2 需要跨仓库 fleet 检查。 | 先在本仓库生成 20 模块 registry，再拓展到 `/home/{module}`。 |
| 83 | security | v2 提到 secret redaction。 | xlibgate 新增 secret-redaction check。 |
| 84 | release tag | tag、GitHub release、manifest 必须一致。 | release-consistency check 三方比对。 |
| 85 | template residue | 拷贝模板身份残留是 v2 重点风险。 | template-residue check 扫 README/go.mod/module path。 |
| 86 | identity | 模块 identity 漂移会污染公开主页。 | identity check 比对 contract、go.mod、README、SPEC。 |
| 87 | evidence index | 证据散落难验证。 | 每模块维护 evidence-index，root 聚合。 |
| 88 | downstream smoke | 下游采用才证明接口稳定。 | 设置 downstream smoke matrix。 |
| 89 | offline mode | 网络依赖会导致 gate 不稳定。 | 默认 offline，本地证据不足时输出 unknown。 |
| 90 | JSON schema | Go 标准库读 JSON 成本最低。 | contract 与 gate report 统一 JSON schema。 |
| 91 | rollout order | 先修事实源，再修 gate，再修投影。 | 避免在不可信事实上生成漂亮文档。 |
| 92 | PR 拆分 | 单 PR 改所有模块风险高。 | P0 文档事实 PR、P1 xlibgate PR、P2 模块 PR。 |
| 93 | rollback | 生成型投影可能误改公开页面。 | 保留手工块与 generated block 分界。 |
| 94 | compatibility | xlibgate exit code 是公共契约。 | 通过 JSON reason_code 扩展，不破坏 CLI。 |
| 95 | adoption | 模块接受 contract 需要迁移成本。 | 先引入 warn mode，再切 release/factory blocking。 |
| 96 | ownership | 每个模块要有事实责任边界。 | contract 中记录 owner、status、known_gaps。 |
| 97 | metrics | 单一 100% 无法驱动改进。 | 用维度状态与 blockers 替代总分崇拜。 |
| 98 | acceptance | 完成条件必须可运行。 | `xlibgate all --fleet --factory` 通过才算收敛。 |
| 99 | residual unknown | 外部 repo 与 GitHub 实时事实未本次验证。 | 跨仓库执行前重新拉取和检查。 |
| 100 | no omission guard | 100 轮已覆盖输入、现状、边界、计划、风险、验收。 | 本报告作为下一步执行 backlog 与验收基线。 |

## 完整优化方案

### P0：冻结事实源，修复本仓库漂移

目标：先让本仓库能一致回答“当前 FoundationX 到底有哪些模块、每个模块处于什么状态、哪些字段是事实、哪些只是投影”。

交付物：

- 新增或规划 `.foundationx/repo-contract.json` schema，字段至少包括 `repo`、`identity`、`release`、`maturity`、`boundaries`、`known_gaps`、`evidence`。
- 修复 `module/FOUNDATION-DEPS.yaml`：补齐 `xlib_harness`、`xlib_evidence`、`domainx`；修正 `xlib_standard` 职责；移除或更新 testkitx Go baseline 与 foundationx compatibility 的陈旧备注。
- 给 `module/FOUNDATION-SPEC.md`、`module/FOUNDATION-V1.md`、`module/foundation-modules.md` 加历史/阶段一定位，避免它们与当前 20 模块事实竞争。
- 将 `STATUS.md` 中的单一完成度拆成成熟度维度：spec、implementation、release、live integration、external CI、downstream adoption、production soak、factory grade。

验收：

- 20 个模块在 module 索引、DEPS、STATUS、README、ARCHITECTURE 中数量一致。
- `xlib_standard` 不再被描述为 generator/harness/evidence 的合体。
- 旧文档明确标注历史状态，不再被下游误用为当前 SSOT。

### P1：扩展 xlibgate 为可信化门禁

目标：把 v2 的人工审查点变成可运行 gate。

新增检查：

- `identity`：比对 repo name、module path、README title、SPEC title、contract identity。
- `template-residue`：扫描模板残留、错误仓库名、复制痕迹、默认占位符。
- `release-consistency --offline`：比对 contract release、manifest、CHANGELOG、tag projection 与 evidence。
- `maturity --factory`：按多维成熟度判定是否达到 factory grade。
- `import-boundary`：读取 `module/FOUNDATION-DEPS.yaml`，阻断非法依赖方向。
- `testkit-prod-import`：阻断生产代码 import testkitx。
- `secret-redaction`：检查 release/evidence 文档是否泄漏密钥、账号、私有端点。
- `fleet-status`：聚合 20 模块生成 `.foundationx/status/index.json` 与 `status.generated.json`。

兼容策略：

- 保持 `module/xlibgate/SPEC.md` 当前退出码契约：`0=pass`、`1=fail`、`2=error`。
- v2 中更细的退出码语义进入 JSON `reason_code`，例如 `CONTRACT_PARSE_ERROR`、`IDENTITY_MISMATCH`、`RELEASE_DRIFT`、`FACTORY_GATE_BLOCKED`。

验收：

- 每个新增 check 都有 FR、AC、TC 与 golden fixture。
- `xlibgate check all --release` 能发现 identity、release、maturity、secret、boundary 类问题。
- `xlibgate` 输出可被 STATUS/README 生成器消费。

### P2：20 模块收敛队列

| 模块 | 优先动作 | 验收口径 |
| --- | --- | --- |
| xlib_standard | 固化标准、模板、schema、governance 事实源职责。 | 不再包含 generator/harness/evidence runtime。 |
| xlib_harness | Draft -> Approved；补 Matrix/Tasks；明确 generate/check 边界。 | 通过四源评分且无 runtime 依赖。 |
| xlib_evidence | Draft -> Approved；固化 manifest、hash-chain、evidence-index。 | 能被 xlibgate release/factory gate 消费。 |
| xlibgate | 实现 v2 trust checks 与 fleet status。 | check/l2/fleet 统一 JSON 输出并保留退出码兼容。 |
| kernel | 校验反向依赖与基础抽象边界。 | 无 L1/L2 反向依赖。 |
| configx | 校验配置边界与 current release fact。 | 不包含业务域逻辑。 |
| observex | 校验 vendor-neutral observability 约束。 | provider-specific 逻辑不污染接口层。 |
| resiliencx | 保持 operational runtime，禁止风险决策语义。 | 文档和依赖矩阵一致。 |
| schedulex | 保持通用调度基础设施。 | 无交易策略/业务周期耦合。 |
| testkitx | 强化测试专用边界。 | 生产代码 import testkitx 被 gate 阻断。 |
| redisx | 补齐 release consistency 与 evidence-index。 | manifest/tag/status 一致。 |
| kafkax | 补齐 release consistency 与 evidence-index。 | release lane 状态可机器验证。 |
| clickhousex | 作为 L2 evidence 样板。 | 复用到 storage 模块模板。 |
| natsx | 完成正式四源 98+ 仲裁与生产 TLS gate。 | 消除 STATUS 中唯一明确 base blocker。 |
| postgresx | 拆分 release、live integration、production soak、adoption。 | 不再用单一 100% 表示全部成熟度。 |
| taosx | 对齐 v1.0.1 release manifest。 | storage fleet status 一致。 |
| ossx | 保留真实 Aliyun OSS evidence 样板。 | evidence-index 可复用。 |
| contracts | 只承载稳定 DTO/event/port 契约。 | 不拥有 transport 实现和业务流程。 |
| transportx | 只承载通信机制与跨进程语义。 | 不复制 domain DTO。 |
| domainx | 纳入 DEPS 与 contracts 边界。 | 不引入状态机、风险规则、持久化或 RPC。 |

### P3：生成公开投影

目标：减少手工维护 README、ARCHITECTURE、STATUS 的漂移。

建议投影链路：

```text
module/*/SPEC.md
module/FOUNDATION-DEPS.yaml
.foundationx/repo-contract.json
.foundationx/blockers.json
.foundationx/evidence-index.json
        |
        v
xlibgate fleet status
        |
        v
.foundationx/status/index.json
status.generated.json
        |
        v
README.md / ARCHITECTURE.md / STATUS.md generated blocks
```

验收：

- 手工编辑公开状态块会被 drift check 发现。
- 状态生成失败时不允许发布 factory-grade 声明。
- 所有 unknown 状态明确标注为 unknown，而不是默认为 pass。

### P4：跨仓库发布与生产硬化

目标：把本仓库可信事实推广到 `/home/{module}` 与 GitHub release 流程。

执行顺序：

- 先对 20 个模块引入 contract warn mode；
- 再对 release lane 启用 blocking mode；
- 最后对 factory gate 启用 blocking mode；
- natsx 优先处理正式四源仲裁与生产 TLS gate；
- postgresx、ossx、clickhousex 的真实集成证据作为样板；
- downstream smoke 覆盖 x.go、foundation_example、关键 L2 消费链。

验收：

- 每个模块 release 都能追溯到 manifest、evidence-index、arbiter verdict。
- downstream smoke 失败时 factory grade 自动降级或阻断。
- 生产 soak 未达标时仍可 release-dev，但不得宣称 production-ready/factory-grade。

## Gate 设计

| Gate | 名称 | 通过条件 | 阻断对象 |
| --- | --- | --- | --- |
| G0 | inventory parity | 20 个模块在 README、ARCHITECTURE、STATUS、module/README、FOUNDATION-DEPS 中一致。 | 文档发布 |
| G1 | contract completeness | 每个模块有 identity、release、maturity、boundaries、known_gaps。 | release 状态提升 |
| G2 | xlibgate trust checks | identity、template、release、boundary、secret、maturity 全部通过。 | release/factory gate |
| G3 | generated projections | 公开投影由 status.generated 或 equivalent 校验。 | README/STATUS 手工漂移 |
| G4 | evidence closure | manifest、evidence-index、arbiter verdict、test report 可追溯。 | release-l2 |
| G5 | adoption and soak | downstream smoke 与 production soak 达到声明等级。 | factory-grade |

## 风险与控制

| 风险 | 影响 | 控制方案 |
| --- | --- | --- |
| 破坏 xlibgate 退出码兼容 | CI 与下游脚本误判。 | 保持 0/1/2，扩展 JSON reason_code。 |
| 同时维护 YAML 与 JSON 事实源 | 产生新的双事实源漂移。 | 明确 YAML 负责依赖矩阵，JSON 负责模块事实契约；互相引用但不重复字段。 |
| 旧六模块文档继续被引用 | 公开状态误导。 | 加历史横幅与当前 SSOT 链接。 |
| 单一 100% 继续扩散 | maturity 被误解为 production-ready。 | 拆维度并禁用总分替代事实。 |
| 外部 GitHub 实时事实变化 | 报告依据过期。 | 跨仓库 PR 前重新 fetch 与 release 验证。 |
| factory gate 过早 blocking | 阻塞正常开发。 | warn mode -> release blocking -> factory blocking 分阶段推进。 |

## 推荐 PR 队列

| PR | 主题 | 主要文件 | 验收 |
| --- | --- | --- | --- |
| PR-1 | 本仓库事实源校准 | `module/FOUNDATION-DEPS.yaml`、历史 Foundation 文档、`STATUS.md` | 20 模块一致，旧 xlib_standard 职责清除。 |
| PR-2 | xlibgate trust check spec | `module/xlibgate/SPEC.md`、TRACEABILITY、TASKS | 新 check 有 FR/AC/TC，退出码兼容。 |
| PR-3 | xlib_harness / xlib_evidence 升级 | 两个模块的 SPEC/MATRIX/TASKS | Draft -> Approved，边界闭合。 |
| PR-4 | generated status 方案 | `.foundationx/*` schema、生成脚本或 xlibgate fleet spec | status.generated 可稳定产生。 |
| PR-5 | L2 release consistency | storage/messaging/object 模块投影与 evidence | manifest/tag/status 一致。 |
| PR-6 | production hardening | natsx、postgresx、downstream smoke | blocker 清零，soak/adoption 维度明确。 |

## 立即可执行清单

- 先改 `module/FOUNDATION-DEPS.yaml`，因为它是当前最明显的 20 模块事实漂移点。
- 再改旧 Foundation 文档的定位和 code fence，降低误读成本。
- 然后把 `STATUS.md` 的 100% 语义改为多维 maturity。
- 接着扩展 `module/xlibgate/SPEC.md`，但不要破坏既有退出码。
- 最后把 generated status 接入 README、ARCHITECTURE、STATUS。

## 最终验收标准

本轮优化全部完成的 stop condition：

- 20 模块清单在所有公开投影中一致；
- `xlib_standard`、`xlib_harness`、`xlib_evidence`、`xlibgate` 四者职责无重叠；
- `module/FOUNDATION-DEPS.yaml` 与每模块 contract 均能被 xlibgate 消费；
- release、maturity、evidence、blocker 均有机器可读表示；
- `xlibgate check all --release` 阻断身份、模板、发布、依赖、secret 漂移；
- `xlibgate check all --factory` 或等价 fleet gate 阻断未达 production soak/downstream adoption 的 factory-grade 声明；
- README、ARCHITECTURE、STATUS 中的公开状态不再靠手工同步维持一致。
