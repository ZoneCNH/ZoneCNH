# 基座模块清单深度分析报告

## 元信息

- 分析日期：2026-06-14
- 工作分支：`docs/foundation-module-list-analysis-20260614`
- 来源提交：`c464d5348256065ea7aca7db08a2f152af4d190d`
- 团队执行：OMX team `omx-context-foundatio-8a1af4ef`
- 产出文件：`docs/report/foundation-module-list-deep-analysis-20260614.md`
- 分析范围：根文档、`module/` 规格索引、基座清单、依赖矩阵、状态跟踪与本仓库内模块规格制品。

## 结论

需要优化迭代，但不需要推倒重做。

当前基座体系的问题不是模块规格缺失，而是“清单口径、状态口径、机器可读依赖矩阵、CI gate 约束”没有收敛到同一个事实源。`module/` 下实际存在 20 个模块目录，并且每个模块都有 `goal.md`、`SPEC.md`、`TRACEABILITY.md`、`IMPLEMENTATION-PLAN.md`。但根文档和治理文件同时出现第一阶段 6 个、17 个、18 个、20 个基座模块口径，且部分状态表与 tracker、依赖矩阵互相矛盾。

建议进行一轮 P0-P2 优化迭代：先冻结模块分类与计数口径，再同步 `README.md`、`ARCHITECTURE.md`、`STATUS.md`、`module/README.md`、`module/FOUNDATION-DEPS.yaml`、`module/FOUNDATION-TRACKER.md`，最后把这些口径纳入 `xlibgate` 或等价 gate 检查，防止再次漂移。

## Agent Team 执行证据

- 运行前检查：`tmux 3.6` 可用，`$TMUX` 存在，`omx --version` 为 `oh-my-codex v0.17.3`。
- 团队上下文：已创建本地运行态 context packet `foundation-module-list-analysis-20260613T213233Z.md`。
- 团队配置：`omx-context-foundatio-8a1af4ef`，`3:explore`，`workspace_mode=worktree`。
- 任务拆分：
  - worker-1：核对 `module/foundation-modules.md`、`module/FOUNDATION-DEPS.yaml`、`module/FOUNDATION-TRACKER.md`。
  - worker-2：核对 `module/README.md` 与各模块 `goal.md`、`SPEC.md`、`TRACEABILITY.md`、任务制品覆盖。
  - worker-3：核对 `README.md`、`ARCHITECTURE.md`、`STATUS.md` 与基座清单、状态、优化方向同步性。
- 完成状态：关闭前 `omx team status` 显示 `phase=complete`，任务总数 3，完成 3，pending/in_progress/failed 均为 0。
- 关闭状态：`omx team shutdown omx-context-foundatio-8a1af4ef` 返回 `Team shutdown complete`，三个 worker worktree 均无 diff 合入。
- 异常处理：worker-3 pane 在启动阶段未进入有效任务 ACK；leader 通过 team API 领取其任务并完成同等范围的根文档证据扫查，任务结果中记录了 `Subagent skip reason`，没有跳过该分析面。

## 核心发现

### 1. 模块数量口径并存，清单 SSOT 不稳定

严重度：High  
优先级：P0

直接证据：

- `module/foundation-modules.md:5` 将 Foundation 第一阶段定义为 6 个基础模块，`module/foundation-modules.md:34-41` 表格也只列出 `kernel`、`configx`、`observex`、`testkitx`、`resiliencx`、`schedulex`。
- `module/README.md:3` 声明本目录维护 20 个基座模块独立规格，`module/README.md:45-66` 列出 20 个模块目标文档。
- 本次复核 `module/` 一级目录，实际模块目录为 20 个：`xlib_standard`、`xlib_harness`、`xlib_evidence`、`kernel`、`configx`、`observex`、`testkitx`、`resiliencx`、`schedulex`、`xlibgate`、`redisx`、`kafkax`、`natsx`、`postgresx`、`taosx`、`ossx`、`clickhousex`、`contracts`、`transportx`、`domainx`。
- `README.md:19-21` 仍称 Foundation v1 规格为 17 个基座模块规格。
- `ARCHITECTURE.md:33-45` 使用 Foundation (20) 口径，但 `ARCHITECTURE.md:121-144` 的规格索引仍称 18 个基座模块，并且表格只列 18 个。
- `STATUS.md:30-45` 与 `STATUS.md:116-135` 使用 18 个模块口径。

判断：

第一阶段 6 个模块是合理的阶段性边界；20 个模块是当前 `module/` 规格库的事实；18 个和 17 个口径缺少明确分类说明。继续保留这些未解释的数字，会让后续状态表、依赖 gate 和发布统计不可验证。

建议：

- 明确一个顶层口径：建议以 `module/README.md` 为规格清单 SSOT，定义“20 个 Foundation 规格模块”。
- 同时允许派生口径，但必须命名清楚：例如“6 个第一阶段核心运行时模块”、“18 个已纳入发布状态表的模块”、“2 个质量/证据辅助模块”。如果 18 或 17 没有业务含义，应删除。
- 在 `README.md`、`ARCHITECTURE.md`、`STATUS.md` 中统一引用同一套分类表，不再手写不同清单。

### 2. 机器可读依赖矩阵与当前模块清单不同步

严重度：High  
优先级：P0

直接证据：

- `module/FOUNDATION-DEPS.yaml:20-127` 覆盖核心模块、`xlib_standard`、`xlibgate`、7 个存储扩展、`contracts`、`transportx`，但没有覆盖 `xlib_harness`、`xlib_evidence`、`domainx`。
- `module/FOUNDATION-DEPS.yaml:11-15` 仍写着 `testkitx` 当前 `go.mod` 是 1.24 且需要降级到 1.23；但 `module/FOUNDATION-TRACKER.md:52-66` 已将 Go baseline 整改标为完成，并写明 `testkitx` 已降级到 1.23。
- `module/FOUNDATION-DEPS.yaml:208-256` 的约束主要覆盖第一阶段 6 个模块，没有针对 `postgresx` 的 `foundationx` 退出约束；而 `module/FOUNDATION-TRACKER.md:230-240` 明确记录 `postgresx` 仍存在 `foundationx` 依赖迁移问题。

判断：

`FOUNDATION-DEPS.yaml` 已经承担机器可读依赖矩阵角色，但它既不是 6 个核心模块清单，也不是 20 个规格模块清单。它的实际作用更像“已纳入依赖 gate 的模块子集”。这个角色如果不显式命名，会导致人读文档与机器 gate 的覆盖面发生偏差。

建议：

- 为 `FOUNDATION-DEPS.yaml` 增加 `scope` 或拆分 section：`core_runtime`、`governance_gate`、`storage_extensions`、`contracts_transport`、`domain_boundary`、`spec_only_quality_artifacts`。
- 对未纳入依赖检查的模块写明原因；如果 `xlib_harness`、`xlib_evidence`、`domainx` 属于 Foundation 规格模块，就应被矩阵显式包含，哪怕依赖边为空。
- 将 `postgresx -> foundationx` 禁止项纳入矩阵或 gate 规则，避免 tracker 中的高优先级问题停留在人工说明层。
- 清理 `testkitx` Go baseline 过期备注，让 YAML 与 tracker 保持同一事实。

### 3. 状态跟踪存在互相矛盾的完成度

严重度：High  
优先级：P0

直接证据：

- `module/FOUNDATION-TRACKER.md:131-149` 对 `testkitx` 有重复状态段：一处写“管线就绪，5 PRs 合入”但 `code/` 阶段仍未勾选，另一处写 PR #1 合入且 implementation/code 阶段已完成。
- `module/FOUNDATION-TRACKER.md:182-199` 的 `xlibgate` CI Gate CLI 实现任务仍未勾选；但 `STATUS.md:118-119` 将 `xlib_standard` 与 `xlibgate` 都标为 100%。
- `STATUS.md:55` 和 `STATUS.md:132` 将 `clickhousex` 标为 v1.0.1、100%；但 `STATUS.md:57` 仍写 blocking issue 为 `clickhousex` 需要 implementation/release closure，`STATUS.md:259` 也保留同类风险描述。
- `module/FOUNDATION-TRACKER.md:323-329` 统计 19 个 issue、16 个完成；`module/FOUNDATION-TRACKER.md:354-379` 的建议执行顺序又混合了已完成项与未完成项。

判断：

状态表不能同时表达“100% 完成”和“仍是 blocker”。这类冲突会直接削弱发布、验收和后续模块优先级排序的可信度。

建议：

- 将 tracker 改成单一状态账本：每个 issue 只保留一个当前状态、一个 owner/证据链接、一个验收命令。
- `STATUS.md` 只消费 tracker 的已验收状态，不手写独立完成度。
- 对 `xlibgate` 和 `clickhousex` 做一次闭环复核：若已完成，删除 blocker；若未完成，降低 `STATUS.md` 完成度并给出剩余验收条件。

### 4. 规格覆盖基本完整，但索引与任务制品命名不一致

严重度：Medium  
优先级：P1

直接证据：

- `module/README.md:9-16` 已明确 `module/` 为模块规格事实源，根文档只做全局索引。
- 本次复核 20 个模块目录均存在 `goal.md`、`SPEC.md`、`TRACEABILITY.md`、`IMPLEMENTATION-PLAN.md`。
- worker-2 复核发现：20 个模块均无 `tasks.md`，其中 18 个模块使用 `tasks/` 目录；`xlib_harness` 与 `xlib_evidence` 的 `tasks/` 链接目标缺失。
- `ARCHITECTURE.md:125-144` 的规格索引表只列 18 个模块，遗漏 `xlib_harness` 与 `xlib_evidence`，但 `ARCHITECTURE.md:33-45` 已将它们纳入 Foundation (20) 叙述。

判断：

规格主干制品覆盖很好，说明不需要大规模重写 spec。问题集中在索引、任务目录命名和根文档投影。

建议：

- 选择一种任务制品约定：如果采用目录制，统一写 `tasks/`；不要在审查口径中再要求 `tasks.md`。
- 为 `xlib_harness`、`xlib_evidence` 补齐任务目录，或在 `module/README.md` 明确它们当前没有任务拆分。
- 用脚本或 gate 校验“module 目录列表、module/README 清单、ARCHITECTURE 表格、STATUS 表格”四者一致。

### 5. 文档格式与陈旧说明会放大误读

严重度：Medium  
优先级：P1

直接证据：

- `module/foundation-modules.md:9-19` 与 `module/foundation-modules.md:183-186` 存在代码围栏闭合写成 ```text 的情况。
- `ARCHITECTURE.md:17-50`、`ARCHITECTURE.md:54-78`、`ARCHITECTURE.md:82-91` 也存在同类围栏标记问题。
- `module/foundation-modules.md:3` 更新时间为 2026-06-07，而 `module/README.md:5` 与 `module/FOUNDATION-TRACKER.md:7` 已更新到 2026-06-14；该文件仍含第一阶段说明，容易被误读为全量清单。

判断：

这些不是架构缺陷，但会影响 GitHub 渲染和读者对“第一阶段 6 个”与“全量 20 个”的区分。

建议：

- 修正错误代码围栏。
- 将 `module/foundation-modules.md` 标题或开头改为“第一阶段核心运行时模块清单”，并显式链接到 `module/README.md` 的全量 20 模块清单。
- 给所有根文档状态块增加“数据来源：module/README.md + FOUNDATION-DEPS.yaml + FOUNDATION-TRACKER.md”。

## 优化迭代路线

### P0：统一清单和状态事实源

目标：让任何读者和 gate 都得到同一个模块分类答案。

建议改动：

- 在 `module/README.md` 固化 Foundation 模块分类表。
- 将 `README.md` 的 17 模块说法改为当前有效口径。
- 将 `ARCHITECTURE.md` 中 Foundation (20)、18 模块规格表和 SRE CI/CD 计划口径统一。
- 将 `STATUS.md` 的 18 模块统计改成明确分类，或补入缺失的 `xlib_harness`、`xlib_evidence`。
- 清理 tracker 中 `testkitx`、`xlibgate`、`clickhousex` 的完成度冲突。

验收条件：

- `rg "17 个基座|18 模块|18 个基座|Foundation \\(20\\)" README.md ARCHITECTURE.md STATUS.md module/README.md module/FOUNDATION-TRACKER.md` 的结果都能被同一分类解释。
- 20 个 `module/*/SPEC.md` 均能从 `module/README.md` 和至少一个根文档索引入口到达。

### P1：让依赖矩阵覆盖全量 Foundation 分类

目标：让 `FOUNDATION-DEPS.yaml` 不再是隐式子集。

建议改动：

- 在 YAML 中显式声明矩阵覆盖范围。
- 纳入或显式排除 `xlib_harness`、`xlib_evidence`、`domainx`。
- 同步 Go baseline 注释与 tracker 事实。
- 增加 `postgresx` 的 `foundationx` 禁止约束或迁移验收项。

验收条件：

- YAML 中的模块集合与文档中的分类集合可机械比对。
- tracker 中仍打开的依赖问题能映射到 YAML 约束或 gate 检查。

### P2：把一致性检查纳入 gate

目标：防止清单和状态再次漂移。

建议改动：

- 在 `xlibgate` 或仓库脚本中增加：
  - 模块目录数与 `module/README.md` 清单一致性检查。
  - `ARCHITECTURE.md`、`STATUS.md` 表格覆盖检查。
  - `FOUNDATION-DEPS.yaml` 模块覆盖检查。
  - Go baseline 与禁止依赖检查。
- 将检查命令写入 tracker 和后续 PR 验收说明。

验收条件：

- 本仓库可以通过一个轻量命令发现 17/18/20 这类口径漂移。
- 状态文档不再靠人工记忆同步。

### P3：沉淀长期分类规则

目标：降低未来新增基座模块时的决策成本。

建议规则：

- `core_runtime`：第一阶段 6 个运行时基础模块。
- `governance_quality`：`xlib_standard`、`xlibgate`、`xlib_harness`、`xlib_evidence`。
- `foundation_extensions`：存储与基础设施适配模块。
- `boundary_contracts`：`contracts`、`transportx`。
- `domain_shared`：`domainx`，需要明确它是 Foundation 扩展还是 L2.5 共享域。

## 风险与边界

- 本次分析只基于 `/home/ZoneCNH` 仓库内文档和规格制品，没有进入 `/home/{module}` 独立代码仓库复核实现代码。
- 因用户目标是“深度分析”和“报告保存文档”，本次没有直接修复 `README.md`、`ARCHITECTURE.md`、`STATUS.md` 或 YAML；整改应作为后续独立 PR 执行。
- `worker-3` 原 pane 未正常完成任务启动，但对应根文档分析面已由 leader 按同一任务范围完成并通过 team API 入账；团队最终任务计数为 3/3 完成。

## 最终判断

基座模块清单需要优化迭代。优先级最高的不是新增模块或重写规格，而是把“20 个规格模块、6 个第一阶段核心模块、18/17 个历史或派生口径”整理成唯一可追溯分类，并让状态表、依赖矩阵和 gate 一起消费这个分类。完成这轮迭代后，现有基座规格体系可以继续作为后续模块实现与治理管线的基础。
