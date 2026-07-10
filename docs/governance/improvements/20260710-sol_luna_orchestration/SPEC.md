# CRI 改进规格：Sol/Luna 分层编排与证据升级闸门

- **日期**：2026-07-10 `[COMPUTED, HIGH]`
- **关联 Beads**：`ZoneCNH-3qyb` `[COMPUTED, HIGH]`
- **候选分支**：`feat/sol_luna_orchestration` `[COMPUTED, HIGH]`
- **状态**：候选实现与隔离 E2E 已验收，尚未合并为主分支事实 `[COMPUTED, HIGH]`
- **风险级别**：§19 R2 中风险；改变 Codex 默认模型与通用任务路由 `[INFERRED, HIGH]`
- **§14 分类**：未修改 §14.1 保护文件，不以当前评分系统自证成功 `[COMPUTED, HIGH]`

## 1. 问题与证据

[COMPUTED, HIGH] 变更前的项目配置只保留 `service_tier` 与 feature flags，没有声明 root 模型、推理档位或 agent 并发边界。

[COMPUTED, HIGH] 当前 collaboration `spawn_agent` 调用模式没有 model 或 reasoning 参数，因此仅凭子线程名称不能证明 executor 使用 Luna。

[COMPUTED, HIGH] 本会话已通过显式 `codex exec -m gpt-5.6-luna -c 'model_reasoning_effort="xhigh"'` 启动多个 executor；其启动头显示 `gpt-5.6-luna / xhigh`。这证明外部 CLI 路由可用，不证明任意原生 collaboration 子线程都是 Luna。

[FRAME, HIGH] 需要一个保护区外的外层编排器，把“模型选择、并行写隔离、便宜验收、Luna 重试、Sol 升级、最终事务应用”变成机器可执行协议。

## 2. 人工授权边界

[COMPUTED, HIGH] 用户在本会话要求“应用在当前系统，自动实现”，并明确指定 Sol 为 Orchestrator、Luna 为 Executors、3–5 路并行以及证据升级闸门。

[INFERRED, MED] 该请求构成对本候选实现的明确人工授权；会话本身不能独立证明用户在组织权限系统中的“工程 Owner”身份，因此最终合并仍保留 PR 审阅证据。

[FRAME, HIGH] 授权范围包括项目配置、保护区外编排脚本、测试、工作流说明和本次 CRI 追溯制品；不包括修改评分 rubric、arbiter、受保护 agent 或 outer metrics。

## 3. 目标

- `FR-001` `[FRAME, HIGH]` 新 Codex 会话默认使用 `gpt-5.6-sol` 与 `xhigh`。
- `FR-002` `[FRAME, HIGH]` 可拆为 3–5 个互斥写范围的任务，由 Sol 先生成严格结构化计划，再并行启动同数量 Luna。
- `FR-003` `[FRAME, HIGH]` 每个 Luna 只能在独立 detached worktree 和声明的写范围内工作，并输出结构化证据。
- `FR-004` `[FRAME, HIGH]` 明确失败先由 Luna 有界重试；只有证据缺失、证据冲突、范围重叠或重试耗尽才调用 Sol 升级裁决。
- `FR-005` `[FRAME, HIGH]` task patch 先在独立 integration worktree 合并并运行全局 cheap checks；通过后才向父 worktree 一次性应用 combined patch。
- `FR-006` `[FRAME, HIGH]` 运行前与最终应用前都校验父 worktree clean 且 HEAD 未变化。
- `FR-007` `[FRAME, HIGH]` 模型调用、检查、重试、patch、门禁和清理结果写入 `.omx/state/orchestration/<run_id>/`。

## 4. 非目标

- `[FRAME, HIGH]` 不修改 `.claude/agents/`、`.codex/agents/`、`.copilot/agents/`、评分 rubric、arbiter、Spec→Code skill、outer metrics 或 `CONSTITUTION.md`。
- `[FRAME, HIGH]` 不替代 Spec→Code 的四源评分与正式 Gate；本改进只增加前置通用编排与 cheap gate。
- `[FRAME, HIGH]` 不把 `agents.max_threads` 当作外层 subprocess 并发证明；外层入口由 `--workers` 独立约束为 3–5。
- `[FRAME, HIGH]` 不声称已经量化节省 token 或生成成本；该收益需要后续真实运行数据。

## 5. 设计

```text
request
  -> Sol/xhigh 严格 JSON 计划
  -> 3–5 个 Luna/xhigh detached worktree 并行执行
  -> task cheap checks + scope/evidence gate
       -> 明确失败：Luna 有界重试
       -> 缺证据/冲突/重叠/耗尽：Sol 只读升级
  -> integration worktree 合并全部 task patch
  -> global cheap checks
       -> 明确失败：Luna integration repair
       -> 仍缺证据或耗尽：Sol 只读升级
  -> 父 worktree HEAD/clean 二次校验
  -> 一次性应用 combined patch
```

[FRAME, HIGH] 所有 `codex exec` 使用 argv、`shell=False`、`-a never`、`--ephemeral`、显式 model、显式 `xhigh`、JSON Schema 和有界 timeout。

[FRAME, HIGH] runtime registered worktree 统一放在 primary worktree 下的 `.worktree/workspaces/runtime/sol_luna/<run_id>/`，调用 worktree 只承载忽略的 `.omx` 证据。

## 6. 需求验收

- `AC-001` `[FRAME, HIGH]` `codex --strict-config doctor --json` 能加载 `gpt-5.6-sol`，且没有未知配置键。
- `AC-002` `[FRAME, HIGH]` `python3 scripts/sol_luna_orchestrator.py probe` 同时确认 Sol、Luna 支持 `xhigh`。
- `AC-003` `[FRAME, HIGH]` 单元测试覆盖 3–5 边界、safe-check allowlist、结构化 schema、timeout=124、证据门禁和 Luna 重试。
- `AC-004` `[FRAME, HIGH]` integration 失败路径不写父 worktree；成功路径只调用一次父 patch apply。
- `AC-005` `[FRAME, HIGH]` task 与 integration 的明确 `fail` 在次数未耗尽时先重试 Luna。
- `AC-006` `[FRAME, HIGH]` 静态范围检查证明没有修改 §14.1 保护文件。
- `AC-007` `[FRAME, HIGH]` 一个隔离的端到端 smoke 能观测到 Sol 规划、3 个 Luna 并行、cheap checks、integration 和 combined patch。
- `AC-008` `[FRAME, HIGH]` `AGENTS.md` 与 `docs/workflow/README.md` 说明入口、失败路由、证据位置及与正式 Gate 的边界。

## 7. 风险与控制

| 风险 | 控制 | 置信度 |
|------|------|--------|
| 模型 slug 或 `xhigh` 不可用 | 每次 run 先读取 bundled catalog，失败即停止 | `[COMPUTED, HIGH]` |
| 并行任务互相覆盖 | 计划阶段拒绝 scope overlap；每 task 独立 worktree | `[FRAME, HIGH]` |
| 测试失败却升级昂贵模型 | 明确失败先 Luna 重试；仅四类证据问题回 Sol | `[FRAME, HIGH]` |
| 集成失败污染父 workspace | 所有 patch 先进入 integration worktree，父 workspace 最后一次性应用 | `[FRAME, HIGH]` |
| 用户运行期间修改父 workspace | 最终 apply 前重新验证 clean 与初始 HEAD | `[FRAME, HIGH]` |
| schema 或命令挂死 | strict JSON Schema；模型 1800 秒、cheap check 900 秒、git 60 秒 timeout | `[FRAME, HIGH]` |
| 与正式评分门禁混淆 | 文档声明 cheap gate 不写 `verdict.json`，不替代四源评分 | `[FRAME, HIGH]` |

## 8. §14 与 §19 合规

[COMPUTED, HIGH] 本候选不修改 §14.1 保护文件，因此不触发评分系统 RSI 的三模块 A/B 与 outer-metric 前置条件。

[FRAME, HIGH] 若未来修改 protected agent、rubric、arbiter、Spec→Code 入口或 outer metrics，必须另起改进并完整执行 §14.3 的 Fork → 三模块 A/B → outer metrics → 人工批准。

[COMPUTED, HIGH] 本目录包含 Matrix、Tasks、Plan、Prompt 和 Evidence，使本次 §19 CRI 自身可追溯；代码实现位于 `scripts/sol_luna_orchestrator.py`。

## 9. 回滚

[FRAME, HIGH] 回滚时删除 `.codex/config.toml` 新增的 model/agents 键、移除编排脚本与测试、撤销两处文档章节并删除本改进目录。回滚必须通过独立 PR 或已审阅反向补丁，随后重跑配置、测试和 diff 门禁。

## 10. 决策记录

| 日期 | 决策 | 依据 |
|------|------|------|
| 2026-07-10 | Extra High 映射为 `xhigh`，不使用 Luna 不支持的 `ultra` | 本地 bundled model catalog `[COMPUTED, HIGH]` |
| 2026-07-10 | 外部 CLI 是 executor 模型硬路由入口 | 当前 collaboration schema 不含 model/effort 字段 `[COMPUTED, HIGH]` |
| 2026-07-10 | cheap gate 是正式 Gate 前置层 | 避免修改 §14.1 保护评分系统 `[FRAME, HIGH]` |
| 2026-07-10 | 父 worktree 采用事务式 combined patch | 失败路径必须无部分写入 `[FRAME, HIGH]` |
