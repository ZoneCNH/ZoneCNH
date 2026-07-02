# 开发工作流

> 从 Spec 到 Ship 的完整管线。定义"设计图完成后怎么施工"。

最后更新：2026-06-21

---

## 分支创建纪律

> 本节操作约束优先级等同于 `CONSTITUTION.md` §0.2。所有 Agent 和人类贡献者必须遵守。
>
> **适用范围**：含源码的模块仓库**必须**使用 `git worktree add` 隔离；纯文档仓库（如 ZoneCNH/ZoneCNH）允许 feature branch 替代 worktree（参见 `CONSTITUTION.md` §0.2.1）。

### 规则

**所有分支必须从 `main` HEAD 创建。**

### 操作步骤

在创建任何 worktree 或 feature branch 之前，必须执行以下前置检查：

本仓库的真实 worktree 路径模板为 `/home/workspace/{module}/.worktree/workspaces/<branch-name>`；下面示例也统一使用该绝对路径模板，避免相对路径与实际规则分叉。这里的 `<branch-name>` 直接使用 Git 分支名本体（仅去掉 `refs/heads/` 前缀），因此 `feat/x` 会自然落盘为 `.worktree/workspaces/feat/x`。该模板仅约束 `git worktree add` 创建的附加 worktree；纯文档仓库的仓库根 checkout 可以直接承载 feature branch，不视为路径违规。

```bash
# 1. 确保本地 main 为最新
git checkout main
git fetch origin
git rebase origin/main

# 2. 从最新 main 创建分支
git checkout -b <branch-name>
# 或通过 worktree
git worktree add /home/workspace/{module}/.worktree/workspaces/<branch-name> -b <branch-name> main
```

**当不在 main worktree 时**（已在其他 worktree 中，无法 `git checkout main`）：

```bash
# 更新本地 main 指针，无需 checkout
git fetch origin
git branch -f main origin/main

# 从最新 main 创建 worktree
git worktree add /home/workspace/{module}/.worktree/workspaces/<branch-name> -b <branch-name> main
```

### 分支来源验证

创建分支后，必须验证其起点确实是 main HEAD：

```bash
# 验证分支起点是 main（返回 0 表示合规）
git merge-base --is-ancestor main <branch-name>

# 查看分支起点 commit
git log --oneline main..HEAD | tail -1
```

### 冲突处理

| 场景                            | 处理                                                                           |
| ------------------------------- | ------------------------------------------------------------------------------ |
| `git rebase origin/main` 冲突   | 解决冲突后 `git rebase --continue`；无法解决则 `git rebase --abort` 并人工介入 |
| main 有未推送的本地提交         | 先 `git push` 确保远程 main 为最新，再 rebase                                  |
| worktree 创建失败（路径已存在） | 清理旧 worktree：`git worktree remove /home/workspace/{module}/.worktree/workspaces/<branch-name>`，或使用不同名称        |

### 禁止行为

| 行为                             | 原因                         |
| -------------------------------- | ---------------------------- |
| 从其他 feature branch 创建新分支 | 污染依赖链，引入未合入的变更 |
| 从旧 commit 创建分支             | 缺少最新修复和变更           |
| 从 detached HEAD 创建分支        | 无法追溯来源                 |
| 跳过 `git fetch && git rebase`   | 本地 main 可能落后于远程     |

### Agent 检查清单

AI 代理在创建分支前必须：

1. [ ] 确认当前不在 main 分支（§0.3，git 操作除外）
2. [ ] 执行 `git fetch origin && git rebase origin/main`（或 `git branch -f main origin/main`）
3. [ ] 确认 main HEAD 与 `origin/main` 一致
4. [ ] 从 main HEAD 创建新分支
5. [ ] 验证分支来源：`git merge-base --is-ancestor main <branch-name>`
6. [ ] 记录创建来源（commit SHA）到 worktree 元数据

---

## 总览

> **管线投影声明**（2026-06-27）：本文件定义的 Spec→Code 管线（S1-S6）是 `docs/goal/03-pipeline.md`（Goal 驱动交付管线，canonical 主流程）的 **governance 评分实现投影**。当本文件与 `docs/goal/` 冲突时，以 Goal 管线为准。Gate 判定以 `docs/goal/04-gates.md` G0-G11 为权威裁决；本文件定义的四源评分（claude/codex/copilot/rules）为 Goal Gate G2/G5/G6/G9 的 score 实现机制。详见 `docs/goal/00-authority-map.md` §双管线优先级。

```text
Spec 编写
  ↓
[Spec Team Score: claude + codex + copilot + rules] → pipeline-arbiter（composite_score >= 98 且无红线/低置信度/异常分差/rules 异构分歧）
  ↓ 自动批准：arbiter 通过后自动翻转 SPEC.md 为 Status: Approved
Matrix → [Matrix Team Score: claude + codex + copilot + rules] → arbiter（composite_score >= 98 且无红线/低置信度/异常分差/rules 异构分歧）
  ↓
Tasks → [Tasks Team Score: claude + codex + copilot + rules] → arbiter（composite_score >= 98 且无红线/低置信度/异常分差/rules 异构分歧）
  ↓
Plan → [Plan Team Score: claude + codex + copilot + rules] → arbiter（composite_score >= 98 且无红线/低置信度/异常分差/rules 异构分歧）
  ↓
Prompt → [Prompt Team Score: claude + codex + copilot + rules] → arbiter（composite_score >= 98 且无红线/低置信度/异常分差/rules 异构分歧）
  ↓
Code → [Code Team Score: claude + codex + copilot + rules] → arbiter（composite_score >= 98 且无红线/低置信度/异常分差/rules 异构分歧）
  ↓
Feature 验收                       ← DEFINITION-OF-DONE.md
  ↓
PR / Ship
  ↓
Workflow Retrospective / RSI Review（可选，受宪法 §14 约束）
```

**核心原则**：

1. Spec 做完后按 `Spec → Matrix → Tasks → Plan → Prompt → Code` 推进，不直接编码。
2. **每个阶段都由 agent team 执行**：1 个 executor + 3 个独立 LLM scorer（claude / codex / copilot）+ 1 个 rules scorer + 1 个 pipeline-arbiter。
3. **每个阶段都必须通过结构性评分门禁**：`composite_score = min(claude.score, codex.score, copilot.score, rules.score)`，且 `composite_score >= 98`、无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内，才能进入下一阶段。
4. **唯一门禁**：不再设置 `spec-review` Go/No-Go 或人工批准作为额外门禁。Spec 阶段四源评分 pass 后，arbiter 自动翻转状态为 `Approved`。`spec-review` agent 仅作为额外的对抗性视角参考，不构成独立 gate。
5. **递归自改进必须有界**：普通产物可以自动修复和上游回退；工作流、rubric、agent、arbiter 等受保护文件的自改只能作为元级 Spec 进入同一条管线，并受 `CONSTITUTION.md` 第十四条约束。

详见 `docs/governance/STRUCTURAL-SCORING.md` 和 `docs/governance/scoring/ARBITER-PROTOCOL.md`。

---

## 团队评分体系

### 三 LLM + rules 四源评分

每个阶段产物由三个独立 LLM 平台评分，并额外运行 rules scorer 做机械结构校验。LLM 之间互不可见对方结果，rules 不替代 LLM 判断：

| 评分源      | Scorer 配置目录                               | 模型 / 类型     |
| ----------- | --------------------------------------------- | --------------- |
| Claude Code | `.claude/agents/{stage}-structural-score.md`  | Opus            |
| Codex       | `.codex/agents/{stage}-structural-score.toml` | gpt-5.5 high    |
| Copilot CLI | `.copilot/agents/{stage}-structural-score.md` | Claude Opus 4.7 |
| Rules       | `.github/ci/*` / `scripts/rule-scorer.py`     | deterministic   |

### 评分对象与 Rubric

| 阶段   | 评分对象                                 | Rubric                                     |
| ------ | ---------------------------------------- | ------------------------------------------ |
| Spec   | `module/{module}/SPEC.md`                | `docs/governance/scoring/RUBRIC-spec.md`   |
| Matrix | `module/{module}/TRACEABILITY.md`        | `docs/governance/scoring/RUBRIC-matrix.md` |
| Tasks  | `module/{module}/tasks/TASK-*.md`        | `docs/governance/scoring/RUBRIC-tasks.md`  |
| Plan   | `module/{module}/IMPLEMENTATION-PLAN.md` | `docs/governance/scoring/RUBRIC-plan.md`   |
| Prompt | `module/{module}/TASK-*-PROMPT.md`       | `docs/governance/scoring/RUBRIC-prompt.md` |
| Code   | 本次 Task diff + 测试 + 验证证据         | `docs/governance/scoring/RUBRIC-code.md`   |

### 仲裁门禁

`pipeline-arbiter` 读取四源 JSON 报告，按以下顺序判定（任一失败即 fail）：

1. 四源齐全
2. 无红线
3. `composite_score = min(claude.score, codex.score, copilot.score, rules.score)`，且 `composite_score >= 98`
4. 任一 LLM 平台 `confidence: low` 直接 fail
5. 三个 LLM 平台分差 `max(score) - min(score) <= 5`
6. rules 与 LLM 中位数异构分歧在阈值内

Confidence、LLM 分差与 rules 异构一致性是 gate 条件，不能用作豁免理由。

### 状态目录

```text
.omx/state/pipeline/{module}/{stage}/
├── scores/
│   ├── claude.json    ├── claude.md
│   ├── codex.json     ├── codex.md
│   ├── copilot.json   ├── copilot.md
│   └── rules.json     └── rules.md
├── verdict.json       # 仲裁结果，gate=pass|fail
└── attempts.json      # 重试计数与升级链
```

### 失败循环（有界自动）

| 尝试次数   | 处理                                                                   |
| ---------- | ---------------------------------------------------------------------- |
| 1-2        | 路由回当前阶段 executor 修复                                           |
| 3          | 路由回上一阶段 executor，重置当前阶段 attempt，记录 `escalation_chain` |

升级链：`code → prompt → plan → tasks → matrix → spec`

推进下一阶段的唯一条件仍是：`composite_score >= 98`、无红线、无低置信度且分差在阈值内。自动修复循环还有独立停止条件：单阶段 3 次失败后必须上游回退；全链路 `max_total_gate_failures = 18` 后必须停止推进，写出 `pipeline_blocked` verdict 和 retrospective，不得无限循环。

---

## 有界递归自改进（RSI）

本工作流支持 recursive self-improvement，但只支持**有界、可审计、不可自授权**的形式。

### 1. 阶段内自修复

每个阶段的 executor 只能修复当前阶段授权产物：

| 阶段   | 可自动修复对象                           |
| ------ | ---------------------------------------- |
| Spec   | `module/{module}/SPEC.md`                |
| Matrix | `module/{module}/TRACEABILITY.md`        |
| Tasks  | `module/{module}/tasks/TASK-*.md`        |
| Plan   | `module/{module}/IMPLEMENTATION-PLAN.md` |
| Prompt | `module/{module}/TASK-*-PROMPT.md`       |
| Code   | 当前 task 指定源码、测试与证据回填       |

每次 `gate=fail` 后，arbiter 必须合并四源扣分账本，生成当前阶段 repair prompt，交回 executor。修复后必须重跑四源评分和仲裁。

### 2. 上游回退

如果同一阶段连续 3 次 `gate=fail`，说明当前产物无法在本阶段局部修好，必须按升级链回到上游阶段：

```text
code -> prompt -> plan -> tasks -> matrix -> spec
```

上游修复后，从该上游阶段重新评分，并重新生成所有受影响下游产物。不得只改下游产物来掩盖上游缺陷。

### 3. 全链路停止条件

每次 arbiter 产生 `gate=fail` 都计入全链路 repair budget。默认上限：

```text
max_stage_attempts = 3
max_total_gate_failures = 18
```

达到全链路上限后，arbiter 必须输出：

```text
.omx/state/pipeline/{module}/pipeline_blocked.json
module/{module}/PIPELINE-RETROSPECTIVE.md
```

`PIPELINE-RETROSPECTIVE.md` 至少包含失败分类、重复扣分项、升级链、最小复现证据、建议的上游改写点。此状态不是 pass，不能进入下一阶段。

### 4. 工作流自身改进

如果 retrospective 证明问题来自工作流、rubric、agent、arbiter 或命令入口本身，不能直接修改受保护文件。必须创建元级改进规格：

```text
docs/governance/improvements/{YYYYMMDD}-{slug}/SPEC.md
```

该元级 Spec 也必须走同一条管线：

```text
Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code
```

并满足同样的 98 分四源门禁。若改动触及 `CONSTITUTION.md` 第十四条的受保护文件，仍必须额外完成 fork、A/B、outer metric 验证和人类批准。`composite_score >= 98` 只是必要条件，不是自我授权。

### 5. 状态记录

RSI 相关状态必须落盘，供下一轮代理恢复：

```text
.omx/state/pipeline/{module}/
├── repair-budget.json
├── failure-taxonomy.json
├── escalation-chain.json
├── pipeline_blocked.json        # 仅阻塞时存在
└── rsi-retrospective.json
```

受保护文件和 outer metrics 不得由普通 executor、scorer 或 arbiter 写入。

---

## 一键工作流入口

```text
Spec → Matrix → Tasks → Plan → Prompt → Code
```

| 平台        | 触发方式                               | 定义文件                                    |
| ----------- | -------------------------------------- | ------------------------------------------- |
| Codex       | `$spec-code-pipeline {module}`         | `.codex/skills/spec-code-pipeline/SKILL.md` |
| Claude Code | `/project:spec-code-pipeline {module}` | `.claude/commands/spec-code-pipeline.md`    |
| Copilot CLI | `/project:spec-code-pipeline {module}` | `.copilot/commands/spec-code-pipeline.md`   |

### 恢复与单阶段执行

```text
$spec-code-pipeline {module} --from matrix
$spec-code-pipeline {module} --stage prompt
```

`--stage` 时必须先验证上游 `verdict.json` 已 `gate=pass`。`--from` 时下游 `scores/` 与 `verdict.json` 必须重新生成。

### 阶段产物与门禁

| 阶段   | Executor         | 团队 Scorer（三 LLM + rules）                              | Gate（唯一）                                                                        |
| ------ | ---------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Spec   | `spec`           | `spec-structural-score` × claude/codex/copilot + `rules`   | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |
| Matrix | `matrix`         | `matrix-structural-score` × claude/codex/copilot + `rules` | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |
| Tasks  | `task-split`     | `tasks-structural-score` × claude/codex/copilot + `rules`  | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |
| Plan   | `task-planner`   | `plan-structural-score` × claude/codex/copilot + `rules`   | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |
| Prompt | `prompt-builder` | `prompt-structural-score` × claude/codex/copilot + `rules` | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |
| Code   | `task-executor`  | `code-structural-score` × claude/codex/copilot + `rules`   | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |

仲裁 agent：`pipeline-arbiter`。门禁纯机器判定，无人工分支。Code 阶段的"测试/lint/race 通过"由 `code-structural-score` 在 rubric 中作为评分维度纳入，不再额外设独立门禁。

---

## 每阶段结构评分硬门禁

Spec / Matrix / Tasks / Plan / Prompt / Code 每个阶段的团队评分（三 LLM + rules 四源）都是正式且**唯一**的门禁。每次阶段产物修订后必须重跑四源评分，仲裁 `gate=pass` 才能进入下一阶段。

下面"第一步…第十步"为流程参考说明，描述各阶段的内容与产物形态。**实际进入下一阶段的判定一律由 `pipeline-arbiter` 完成**：`composite_score = min(四源评分)` 且 `composite_score >= 98`、无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内 → 自动推进，否则自动路由回 executor 或 scorer 修复。`spec-review` agent 与 `Status: Approved` 等历史人工门已不再作为独立 gate，仅作为 scorer 评分时的输入证据保留。

---

## 第一步：Spec 编写与团队评分

Spec 编写完成后，第一件事是让 AI 当审查者，不是开发者。

### 使用方式

```text
agent team:
  - spec-structural-score (Claude)
  - spec-structural-score (Codex)
  - spec-structural-score (Copilot)
  - spec-structural-score (rules)
  - pipeline-arbiter
optional evidence:
  - spec-review（只读对抗性参考报告，不构成独立门禁）
```

### 审查重点

1. 是否有模糊需求
2. 是否有互相冲突的要求
3. 是否缺少 Non-goals
4. 是否缺少边界情况
5. 是否缺少验收标准
6. 是否缺少测试用例
7. 是否有安全、权限或数据风险
8. 是否可以进入开发

### 输出

- Blocking issues
- Non-blocking suggestions
- Missing edge cases
- Missing test cases
- Recommended spec edits
- **参考性 Ready 风险判断**

### 目标

```text
Spec 是否足够清楚？
AI 是否会误解？
需求是否能被测试？
还有没有没决定的问题？
```

---

## 第二步：解决 Open Questions

Spec 里的未定问题必须分级处理。

### 分级格式

```markdown
## Open Questions

### Blocking（阻塞开发）
- 数据是否需要持久化？

### Non-blocking（不阻塞开发）
- 完成任务是否自动沉到底部？

### Future（未来考虑）
- 是否支持标签？
```

### 处理规则

- **Blocking** 问题必须在开发前解决
- **Non-blocking** 问题可以在开发中解决
- **Future** 问题记录备忘，不承诺解决时间

### 决策记录

解决后把决定写回 Spec 的 §23 或新增 Decisions 节：

```markdown
## Decisions

- MVP 使用 localStorage 持久化
- 删除任务不需要确认弹窗
- 允许重复任务标题
```

---

## 第三步：批准 Spec

Spec 状态必须流转到 `Approved` 才能进入开发。

### 状态流转（详见 LIFECYCLE.md）

```text
Draft → Review → Approved → Implemented
                 ↑
              Changed ──→ Review
```

### 操作

1. 解决所有 Blocking Open Questions
2. Spec team-scoring 产出 Claude / Codex / Copilot + rules 四源结构评分
3. `pipeline-arbiter` 判定 `composite_score >= 98`、无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内
4. Arbiter pass 后自动修改 Metadata：`Status: Draft` → `Status: Approved`，并更新 `Last-Updated` 日期

### 禁止

- ❌ Draft 状态直接进入开发
- ❌ 有 Blocking Open Questions 时批准

---

## 第四步：生成模块级 Traceability Matrix

建立 `module/{module}/TRACEABILITY.md` 模块级需求追踪表，**防止 AI 漏功能，也防止 AI 乱加功能。**

### 格式

```markdown
| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
|---|---|---|---|---|---|
| FR-001 | Create Task | AC-001 | TC-001 | TASK-001 | ⬜ |
| FR-002 | Reject Empty | AC-002 | TC-002 | TASK-001 | ⬜ |
```

### 生成方式

```text
Agent(subagent_type="matrix", prompt="根据 module/{module}/SPEC.md 生成或校验 module/{module}/TRACEABILITY.md")
```

### 校验规则

- 每个 FR 必须有 ≥1 AC
- 每个 AC 必须有 ≥1 TC
- 每个 TC 必须映射回 ≥1 FR
- 不允许无需求支撑的 TC（范围蔓延）
- 不允许无测试覆盖的需求（盲区）

---

## 第五步：拆分 Task

Spec 是功能合同，Task 是 AI 能执行的小任务。

### 粒度原则

```text
❌ TASK-001: 实现任务管理系统
✅ TASK-001: 定义 Task 数据模型和校验规则
✅ TASK-002: 实现任务 storage/service
✅ TASK-003: 实现新增任务表单
✅ TASK-004: 实现任务列表展示
```

### 拆分规则（详见 TASK-TEMPLATE.md）

| 规则            | 说明                                |
| --------------- | ----------------------------------- |
| 上限            | 一个 task 最多 5 个文件、3 个 FR    |
| 下限            | 一个 task 至少 1 个 FR + 1 个 AC    |
| 测试同体        | 实现文件和测试文件必须在同一个 task |
| 不跨模块        | 一个 task 只涉及一个模块            |
| 必须有 spec_ref | 不允许无规格的自由发挥              |

### 拆分顺序

```text
接口定义（contracts）
  ↓
Data Model + Validation
  ↓
Service / Storage
  ↓
UI Components（如有）
  ↓
Integration
  ↓
Tests 补全
  ↓
Review + Polish
```

### 使用方式

```text
Agent(subagent_type="task-split", prompt="根据 module/{module}/SPEC.md 和 module/{module}/TRACEABILITY.md 拆分 Task")
```

### 输出格式

每个 Task 包含：

1. Task ID
2. Goal（一句话目标）
3. Scope（做什么）
4. Non-scope（不做什么）
5. Requirements covered（FR/BR 编号）
6. Files likely to change
7. Acceptance criteria
8. Test plan
9. Depends on（前置 task）
10. Priority（P0/P1/P2）

---

## 第六步：生成 Implementation Plan

Task 拆分后，先生成实现顺序，不直接编码。

### 使用方式

```text
Agent(subagent_type="task-planner", prompt="根据 module/{module}/SPEC.md、module/{module}/TRACEABILITY.md 和 module/{module}/tasks/ 生成 IMPLEMENTATION-PLAN.md")
```

### 输出

`module/{module}/IMPLEMENTATION-PLAN.md` 至少包含：

1. Task 执行顺序
2. 依赖关系和阻塞点
3. 每个 Task 的目标文件范围
4. 每个 Task 的验证命令
5. 高风险实现点
6. 回滚或修复策略

### 门禁

- 不允许跳过前置依赖 Task
- 不允许一次计划跨多个模块
- 不允许把 Spec 外功能塞进执行顺序

---

## 第七步：生成 Task Prompt

编码前，为当前 ready task 生成单任务 Context Packet。

### 使用方式

```text
Agent(subagent_type="prompt-builder", prompt="根据 module/{module}/IMPLEMENTATION-PLAN.md 和当前 ready task 生成 TASK-{MODULE}-{NNN}-PROMPT.md")
```

### 输出

`module/{module}/TASK-{MODULE}-{NNN}-PROMPT.md` 至少包含：

1. 当前 Task ID 和目标
2. Spec / Matrix / Task / Plan 引用
3. 可改文件范围
4. 不可做事项
5. 验收标准
6. 必跑验证命令
7. 完成后需要回填的证据

### 门禁

- 一个 Prompt 只服务一个 Task
- Prompt 不得扩大 Task scope
- Prompt 必须引用 Requirement / Acceptance Criteria / Test Case ID

---

## 第八步：按 Task 编码

### 执行顺序

按 `IMPLEMENTATION-PLAN.md` 选择第一个 ready task。默认一次只执行一个 Task。

### 每个 Task 的执行循环

```text
实现 TASK-{NNN}
  ↓
自查（对照 spec）
  ↓
修复 Required fixes
  ↓
测试（lint + typecheck + test）
  ↓
Code Review
  ↓
修复 Review issues
  ↓
更新 Task 状态为 Done
  ↓
更新 module/{module}/TRACEABILITY.md
  ↓
实现 TASK-{NNN+1}
```

### 开发 Prompt

```markdown
请实现 TASK-{MODULE}-{NNN}。

上下文：
- Spec: module/{module}/SPEC.md
- Task: module/{module}/tasks/TASK-{MODULE}-{NNN}.md
- Agent Rules: AGENTS.md

限制：
- 只实现当前 task
- 不实现后续 task
- 不做 spec 外功能
- 不引入新依赖（除非 task 明确要求）
- 不修改无关文件

完成后输出：
1. 修改文件清单
2. 实现说明
3. 覆盖的 Requirement IDs
4. 新增测试
5. 如何运行测试
6. 风险或假设
```

### 自查 Prompt

```markdown
请根据 module/{module}/SPEC.md 检查当前实现。

不要写新功能。

输出：
1. Requirement coverage table
2. Acceptance criteria result
3. Test coverage result
4. Deviations from spec
5. Required fixes
6. Suggested improvements
```

### Review Prompt

```markdown
请作为严格代码审查者 review 当前 diff。

参考：module/{module}/SPEC.md

重点检查：
1. 是否满足 spec
2. 是否实现了 task scope 外的内容
3. 是否漏掉 edge cases
4. 是否有类型问题
5. 是否有安全问题
6. 是否有过度设计
7. 是否需要补测试
8. 是否破坏现有功能

输出：
- Must fix
- Should fix
- Nice to have
- Accepted
```

---

## 第九步：Feature 验收

当一个模块的所有 Task 都完成后，做完整验收。

### 验收标准（详见 DEFINITION-OF-DONE.md）

- [ ] 所有 Functional Requirements 已实现
- [ ] 所有 Business Rules 已遵循
- [ ] 所有 Error Handling 已实现
- [ ] 所有 Edge Cases 已处理
- [ ] 所有 Test Cases 已通过
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果符合 Performance Budget
- [ ] CI Gate 全部通过
- [ ] 追溯矩阵更新完成
- [ ] 无硬编码 secret
- [ ] 公共接口有 godoc 注释

### 验收 Prompt

```markdown
请根据 module/{module}/SPEC.md 对当前功能做完整验收。

检查：
1. 所有 Functional Requirements 是否实现
2. 所有 Acceptance Criteria 是否通过
3. 所有 Test Cases 是否覆盖
4. 是否存在 spec 外功能
5. 是否有已知 bug
6. 是否有安全问题
7. 是否可以标记为 Implemented

输出：
- Pass / Fail
- Requirement coverage table
- Missing items
- Required fixes
- Final recommendation
```

### 状态流转

验收通过后：

```text
Spec Status: Approved → Implemented
Traceability Matrix: 所有 Status → ✅
```

---

## 第十步：PR / Ship

PR 描述应引用 Spec：

```markdown
# PR: Implement {module}

## Related Spec
- module/{module}/SPEC.md

## Requirements Covered
- FR-001, FR-002, FR-003...

## Changes
- {变更清单}

## Verification
- go build ./...
- go test ./... -race
- golangci-lint run

## Acceptance Criteria
| AC | Status |
|---|---|
| AC-001 | ✅ |
| AC-002 | ✅ |
```

---

## Agent 清单

### 执行类（每阶段一个 executor）

| Agent            | 步骤   | 用途                                        | 模型             | 可写代码   |
| ---------------- | ------ | ------------------------------------------- | ---------------- | ---------- |
| `spec`           | Spec   | 编写或修订项目 spec，补齐 23 节结构与追溯链 | opus / gpt-5.5   | 否         |
| `spec-review`    | Review | 对抗性审查 spec，作为结构评分证据与参考     | opus / gpt-5.5   | 否         |
| `matrix`         | Matrix | 生成或校验需求追溯矩阵                      | sonnet / gpt-5.5 | 否         |
| `task-split`     | Tasks  | 将 Approved Spec 拆成可执行 Task            | sonnet / gpt-5.5 | 否         |
| `task-planner`   | Plan   | 生成实现顺序、依赖、验证命令和风险计划      | opus / gpt-5.5   | 否         |
| `prompt-builder` | Prompt | 为单个 Task 生成 Context Packet             | sonnet / gpt-5.5 | 否         |
| `task-executor`  | Code   | 按单个 Task 编写代码与测试                  | sonnet / gpt-5.5 | 是         |

### 评分类（每阶段三平台并行）

| Agent                     | 阶段   | 平台                     |
| ------------------------- | ------ | ------------------------ |
| `spec-structural-score`   | Spec   | claude / codex / copilot |
| `matrix-structural-score` | Matrix | claude / codex / copilot |
| `tasks-structural-score`  | Tasks  | claude / codex / copilot |
| `plan-structural-score`   | Plan   | claude / codex / copilot |
| `prompt-structural-score` | Prompt | claude / codex / copilot |
| `code-structural-score`   | Code   | claude / codex / copilot |

### 仲裁类

| Agent              | 用途                                                  |
| ------------------ | ----------------------------------------------------- |
| `pipeline-arbiter` | 汇总四源评分，按 `ARBITER-PROTOCOL.md` 输出 gate 判定 |

---

## 相关文档

### 流水线文档

| 文档                                         | 用途                                                    |
| -------------------------------------------- | ------------------------------------------------------- |
| `docs/workflow/README.md`                    | **工作流统一入口** — 双管线导航、阶段对应表             |
| `docs/governance/PRE-DEVELOPMENT.md`         | 开发前准备 — 实现策略、Task 拆分、追溯矩阵              |
| `docs/governance/CODING-SESSION-PROTOCOL.md` | 编码会话协议 — Context Packet、Plan-first、自查、Review |
| `docs/governance/SPEC-DRIFT-PROTOCOL.md`     | Spec Drift 处理 — 代码与 Spec 不一致时的协议            |
| `docs/governance/TESTING-STRATEGY.md`        | 测试策略 — 从 Spec 生成测试、优先级、验收               |
| `docs/governance/PR-TEMPLATE.md`             | PR/Issue/Branch/Commit 模板和命名规则                   |
| `docs/governance/DEPLOYMENT.md`              | 部署清单 — RC 检查、Smoke Test、CI 配置、Changelog      |
| `docs/governance/REVIEW-STRATEGY.md`         | 审查策略 — 每层轻审查、转换点强审查、高风险点反审查     |

### 治理文档

| 文档                                          | 用途                   |
| --------------------------------------------- | ---------------------- |
| `docs/governance/SPEC-TEMPLATE.md`            | 23 节 spec 模板        |
| `docs/governance/TASK-TEMPLATE.md`            | Task spec 模板         |
| `docs/governance/LIFECYCLE.md`                | Spec 状态流转规则      |
| `docs/governance/TRACEABILITY.md`             | 需求追踪矩阵规范       |
| `docs/governance/DEFINITION-OF-READY.md`      | 进入开发的前置条件     |
| `docs/governance/DEFINITION-OF-DONE.md`       | 完成验收条件           |
| `docs/governance/STRUCTURAL-SCORING.md`       | 四源评分体系与统一红线 |
| `docs/governance/scoring/ARBITER-PROTOCOL.md` | 仲裁算法、门禁、升级链 |
| `docs/governance/scoring/RUBRIC-*.md`         | 各阶段评分维度与红线   |
| `CONSTITUTION.md`                             | 最高治理权威           |

---

## 快速通道（小型模块）

> 适用于满足以下全部条件的模块，可跳过部分阶段或降低评分门禁。

### 准入条件（三条全部满足）

| # | 条件 | 验证方式 |
|---|------|---------|
| 1 | **单一接口**：暴露 ≤3 个公开方法/函数 | `grep -c "^func \|^type .* interface"` |
| 2 | **无运行时依赖**：不依赖任何其他 ZoneCNH 模块（stdlib 除外） | `go list -m all` 无内部 import |
| 3 | **纯 library**：无可执行入口（无 `cmd/`、无 `main` 包），无 server/client 进程 | `test ! -d cmd/ && test ! -f main.go` |

### 快速通道简化的内容

| 正常管线 | 快速通道 | 说明 |
|---------|---------|------|
| S3-Design（G3 Gate） | **跳过** | 无架构决策可记录时跳过 |
| S2-Matrix 评分 | **单源评分**（rules only） | 小型模块追溯链简单，规则引擎即可验证 |
| 门禁分数 | **≥90**（正常 ≥98） | 降低准入门槛但不取消 |
| 红线检查 | **不变** | 安全/凭证/宪法违规红线仍强制 |

### 快速通道流程

```text
Goal → Spec → [单源 Matrix check] → Tasks → Plan → Prompt → Code
         └─ composite ≥90（仅 rules 源）
```

### 申请流程

1. 模块负责人在 `module/{module}/SPEC.md` 元数据中声明 `Fast-Track: true`
2. 附带准入条件验证证据（3 条检查输出）
3. CI gate 自动检测 `Fast-Track` 标记并切换门禁阈值

### 退出快速通道

当模块不再满足任一准入条件时（如新增接口 >3 方法或引入内部依赖），必须在下一个 Spec 版本中移除 `Fast-Track` 标记，并补走被跳过的阶段。
