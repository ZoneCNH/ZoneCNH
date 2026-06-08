# 开发工作流

> 从 Spec 到 Ship 的完整管线。定义"设计图完成后怎么施工"。

最后更新：2026-06-08

---

## 总览

```text
Spec 编写
  ↓
[Spec Team Score: claude + codex + copilot] → pipeline-arbiter（composite_score >= 98 且无红线/低置信度/异常分差）
  ↓ 自动批准：arbiter 通过后自动翻转 SPEC.md 为 Status: Approved
Matrix → [Matrix Team Score: claude + codex + copilot + rules] → arbiter（composite_score >= 98 且无红线/低置信度/异常分差）
  ↓
Tasks → [Tasks Team Score: claude + codex + copilot + rules] → arbiter（composite_score >= 98 且无红线/低置信度/异常分差）
  ↓
Plan → [Plan Team Score: claude + codex + copilot + rules] → arbiter（composite_score >= 98 且无红线/低置信度/异常分差）
  ↓
Prompt → [Prompt Team Score: claude + codex + copilot + rules] → arbiter（composite_score >= 98 且无红线/低置信度/异常分差）
  ↓
Code → [Code Team Score: claude + codex + copilot + rules] → arbiter（composite_score >= 98 且无红线/低置信度/异常分差）
  ↓
Feature 验收                       ← DEFINITION-OF-DONE.md
  ↓
PR / Ship
  ↓
Workflow Retrospective / RSI Review（可选，受宪法 §14 约束）
```

**核心原则**：

1. Spec 做完后按 `Spec → Matrix → Tasks → Plan → Prompt → Code` 推进，不直接编码。
2. **每个阶段都由 agent team 执行**：1 个 executor + 3 个独立平台 scorer（claude / codex / copilot）+ 1 个 pipeline-arbiter。
3. **每个阶段都必须通过结构性评分门禁**：`composite_score = min(claude.score, codex.score, copilot.score, rules.score)`，且 `composite_score >= 98`、无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内，才能进入下一阶段。
4. **唯一门禁**：不再设置 `spec-review` Go/No-Go 或人工批准作为额外门禁。Spec 阶段三平台 pass 后，arbiter 自动翻转状态为 `Approved`。`spec-review` agent 仅作为额外的对抗性视角参考，不构成独立 gate。
5. **递归自改进必须有界**：普通产物可以自动修复和上游回退；工作流、rubric、agent、arbiter 等受保护文件的自改只能作为元级 Spec 进入同一条管线，并受 `CONSTITUTION.md` 第十四条约束。

详见 `specs/STRUCTURAL-SCORING.md` 和 `specs/scoring/ARBITER-PROTOCOL.md`。

---

## 团队评分体系

### 三平台并行评分

每个阶段产物由三个独立平台并行评分，互不可见对方结果：

| 平台 | Scorer 配置目录 | 模型 |
|------|-----------------|------|
| Claude Code | `.claude/agents/{stage}-structural-score.md` | Opus |
| Codex | `.codex/agents/{stage}-structural-score.toml` | gpt-5.5 high |
| Copilot CLI | `.copilot/agents/{stage}-structural-score.md` | Claude Opus 4.7 |

### 评分对象与 Rubric

| 阶段 | 评分对象 | Rubric |
|------|----------|--------|
| Spec | `specs/{module}/SPEC.md` | `specs/scoring/RUBRIC-spec.md` |
| Matrix | `specs/{module}/TRACEABILITY.md` | `specs/scoring/RUBRIC-matrix.md` |
| Tasks | `specs/{module}/tasks/TASK-*.md` | `specs/scoring/RUBRIC-tasks.md` |
| Plan | `specs/{module}/IMPLEMENTATION-PLAN.md` | `specs/scoring/RUBRIC-plan.md` |
| Prompt | `specs/{module}/TASK-*-PROMPT.md` | `specs/scoring/RUBRIC-prompt.md` |
| Code | 本次 Task diff + 测试 + 验证证据 | `specs/scoring/RUBRIC-code.md` |

### 仲裁门禁

`pipeline-arbiter` 读取三平台 JSON 报告，按以下顺序判定（任一失败即 fail）：

1. 三平台齐全
2. 无红线
3. `composite_score = min(claude.score, codex.score, copilot.score, rules.score)`，且 `composite_score >= 98`
4. 任一平台 `confidence: low` 直接 fail
5. 三平台分差 `max(score) - min(score) <= 5`

Confidence 与平台分差是 gate 条件，不能用作豁免理由。

### 状态目录

```text
.omx/state/pipeline/{module}/{stage}/
├── scores/
│   ├── claude.json    ├── claude.md
│   ├── codex.json     ├── codex.md
│   └── copilot.json   └── copilot.md
├── verdict.json       # 仲裁结果，gate=pass|fail
└── attempts.json      # 重试计数与升级链
```

### 失败循环（有界自动）

| 尝试次数 | 处理 |
|----------|------|
| 1-2 | 路由回当前阶段 executor 修复 |
| 3 | 路由回上一阶段 executor，重置当前阶段 attempt，记录 `escalation_chain` |

升级链：`code → prompt → plan → tasks → matrix → spec`

推进下一阶段的唯一条件仍是：`composite_score >= 98`、无红线、无低置信度且分差在阈值内。自动修复循环还有独立停止条件：单阶段 3 次失败后必须上游回退；全链路 `max_total_gate_failures = 18` 后必须停止推进，写出 `pipeline_blocked` verdict 和 retrospective，不得无限循环。

---

## 有界递归自改进（RSI）

本工作流支持 recursive self-improvement，但只支持**有界、可审计、不可自授权**的形式。

### 1. 阶段内自修复

每个阶段的 executor 只能修复当前阶段授权产物：

| 阶段 | 可自动修复对象 |
|------|----------------|
| Spec | `specs/{module}/SPEC.md` |
| Matrix | `specs/{module}/TRACEABILITY.md` |
| Tasks | `specs/{module}/tasks/TASK-*.md` |
| Plan | `specs/{module}/IMPLEMENTATION-PLAN.md` |
| Prompt | `specs/{module}/TASK-*-PROMPT.md` |
| Code | 当前 task 指定源码、测试与证据回填 |

每次 `gate=fail` 后，arbiter 必须合并三平台扣分账本，生成当前阶段 repair prompt，交回 executor。修复后必须重跑四源评分和仲裁。

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
specs/{module}/PIPELINE-RETROSPECTIVE.md
```

`PIPELINE-RETROSPECTIVE.md` 至少包含失败分类、重复扣分项、升级链、最小复现证据、建议的上游改写点。此状态不是 pass，不能进入下一阶段。

### 4. 工作流自身改进

如果 retrospective 证明问题来自工作流、rubric、agent、arbiter 或命令入口本身，不能直接修改受保护文件。必须创建元级改进规格：

```text
specs/workflow-improvement/{YYYYMMDD}-{slug}/SPEC.md
```

该元级 Spec 也必须走同一条管线：

```text
Spec -> Matrix -> Tasks -> Plan -> Prompt -> Code
```

并满足同样的 98 分三平台门禁。若改动触及 `CONSTITUTION.md` 第十四条的受保护文件，仍必须额外完成 fork、A/B、outer metric 验证和人类批准。`composite_score >= 98` 只是必要条件，不是自我授权。

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

| 平台 | 触发方式 | 定义文件 |
|------|----------|----------|
| Codex | `$spec-code-pipeline {module}` | `.codex/skills/spec-code-pipeline/SKILL.md` |
| Claude Code | `/project:spec-code-pipeline {module}` | `.claude/commands/spec-code-pipeline.md` |
| Copilot CLI | `/project:spec-code-pipeline {module}` | `.copilot/commands/spec-code-pipeline.md` |

### 恢复与单阶段执行

```text
$spec-code-pipeline {module} --from matrix
$spec-code-pipeline {module} --stage prompt
```

`--stage` 时必须先验证上游 `verdict.json` 已 `gate=pass`。`--from` 时下游 `scores/` 与 `verdict.json` 必须重新生成。

### 阶段产物与门禁

| 阶段 | Executor | 团队 Scorer (并行 × 3) | Gate（唯一） |
|------|----------|-----------------------|--------------|
| Spec | `spec` | `spec-structural-score` × claude/codex/copilot | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |
| Matrix | `matrix` | `matrix-structural-score` × 3 | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |
| Tasks | `task-split` | `tasks-structural-score` × 3 | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |
| Plan | `task-planner` | `plan-structural-score` × 3 | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |
| Prompt | `prompt-builder` | `prompt-structural-score` × 3 | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |
| Code | `task-executor` | `code-structural-score` × 3 | `composite_score >= 98` 且无红线、无 LLM 低置信度、无异常 LLM 分差或 rules 异构分歧 |

仲裁 agent：`pipeline-arbiter`（三平台均有等价实现）。门禁纯机器判定，无人工分支。Code 阶段的"测试/lint/race 通过"由 `code-structural-score` 在 rubric 中作为评分维度纳入，不再额外设独立门禁。

---

## 每阶段结构评分硬门禁

Spec / Matrix / Tasks / Plan / Prompt / Code 每个阶段的团队评分（claude / codex / copilot 三平台）都是正式且**唯一**的门禁。每次阶段产物修订后必须重跑四源评分，仲裁 `gate=pass` 才能进入下一阶段。

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
2. Spec team-scoring 产出 Claude / Codex / Copilot 四源结构评分
3. `pipeline-arbiter` 判定 `composite_score >= 98`、无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内
4. Arbiter pass 后自动修改 Metadata：`Status: Draft` → `Status: Approved`，并更新 `Last-Updated` 日期

### 禁止

- ❌ Draft 状态直接进入开发
- ❌ 有 Blocking Open Questions 时批准

---

## 第四步：生成 Traceability Matrix

建立需求追踪表，**防止 AI 漏功能，也防止 AI 乱加功能。**

### 格式

```markdown
| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
|---|---|---|---|---|---|
| FR-001 | Create Task | AC-001 | TC-001 | TASK-001 | ⬜ |
| FR-002 | Reject Empty | AC-002 | TC-002 | TASK-001 | ⬜ |
```

### 生成方式

```text
Agent(subagent_type="matrix", prompt="根据 specs/{module}/SPEC.md 生成或校验 Traceability Matrix")
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

| 规则 | 说明 |
|------|------|
| 上限 | 一个 task 最多 5 个文件、3 个 FR |
| 下限 | 一个 task 至少 1 个 FR + 1 个 AC |
| 测试同体 | 实现文件和测试文件必须在同一个 task |
| 不跨模块 | 一个 task 只涉及一个模块 |
| 必须有 spec_ref | 不允许无规格的自由发挥 |

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
Agent(subagent_type="task-split", prompt="根据 specs/{module}/SPEC.md 和 specs/{module}/TRACEABILITY.md 拆分 Task")
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
Agent(subagent_type="task-planner", prompt="根据 specs/{module}/SPEC.md、specs/{module}/TRACEABILITY.md 和 specs/{module}/tasks/ 生成 IMPLEMENTATION-PLAN.md")
```

### 输出

`specs/{module}/IMPLEMENTATION-PLAN.md` 至少包含：

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
Agent(subagent_type="prompt-builder", prompt="根据 specs/{module}/IMPLEMENTATION-PLAN.md 和当前 ready task 生成 TASK-{MODULE}-{NNN}-PROMPT.md")
```

### 输出

`specs/{module}/TASK-{MODULE}-{NNN}-PROMPT.md` 至少包含：

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
更新 Traceability Matrix
  ↓
实现 TASK-{NNN+1}
```

### 开发 Prompt

```markdown
请实现 TASK-{MODULE}-{NNN}。

上下文：
- Spec: specs/{module}/SPEC.md
- Task: specs/{module}/tasks/TASK-{MODULE}-{NNN}.md
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
请根据 specs/{module}/SPEC.md 检查当前实现。

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

参考：specs/{module}/SPEC.md

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
请根据 specs/{module}/SPEC.md 对当前功能做完整验收。

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
- specs/{module}/SPEC.md

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

| Agent | 步骤 | 用途 | 模型 | 可写代码 |
|-------|------|------|------|----------|
| `spec` | Spec | 编写或修订项目 spec，补齐 23 节结构与追溯链 | opus / gpt-5.5 | 否 |
| `spec-review` | Review | 对抗性审查 spec，作为结构评分证据与参考 | opus / gpt-5.5 | 否 |
| `matrix` | Matrix | 生成或校验需求追溯矩阵 | sonnet / gpt-5.5 | 否 |
| `task-split` | Tasks | 将 Approved Spec 拆成可执行 Task | sonnet / gpt-5.5 | 否 |
| `task-planner` | Plan | 生成实现顺序、依赖、验证命令和风险计划 | opus / gpt-5.5 | 否 |
| `prompt-builder` | Prompt | 为单个 Task 生成 Context Packet | sonnet / gpt-5.5 | 否 |
| `task-executor` | Code | 按单个 Task 编写代码与测试 | sonnet / gpt-5.5 | 是 |

### 评分类（每阶段三平台并行）

| Agent | 阶段 | 平台 |
|-------|------|------|
| `spec-structural-score` | Spec | claude / codex / copilot |
| `matrix-structural-score` | Matrix | claude / codex / copilot |
| `tasks-structural-score` | Tasks | claude / codex / copilot |
| `plan-structural-score` | Plan | claude / codex / copilot |
| `prompt-structural-score` | Prompt | claude / codex / copilot |
| `code-structural-score` | Code | claude / codex / copilot |

### 仲裁类

| Agent | 用途 |
|-------|------|
| `pipeline-arbiter` | 汇总四源评分，按 `ARBITER-PROTOCOL.md` 输出 gate 判定 |

---

## 相关文档

### 流水线文档

| 文档 | 用途 |
|------|------|
| `specs/PRE-DEVELOPMENT.md` | 开发前准备 — 实现策略、Task 拆分、追溯矩阵 |
| `specs/CODING-SESSION-PROTOCOL.md` | 编码会话协议 — Context Packet、Plan-first、自查、Review |
| `specs/SPEC-DRIFT-PROTOCOL.md` | Spec Drift 处理 — 代码与 Spec 不一致时的协议 |
| `specs/TESTING-STRATEGY.md` | 测试策略 — 从 Spec 生成测试、优先级、验收 |
| `specs/PR-TEMPLATE.md` | PR/Issue/Branch/Commit 模板和命名规则 |
| `specs/DEPLOYMENT.md` | 部署清单 — RC 检查、Smoke Test、CI 配置、Changelog |
| `specs/REVIEW-STRATEGY.md` | 审查策略 — 每层轻审查、转换点强审查、高风险点反审查 |

### 治理文档

| 文档 | 用途 |
|------|------|
| `specs/SPEC-TEMPLATE.md` | 23 节 spec 模板 |
| `specs/TASK-TEMPLATE.md` | Task spec 模板 |
| `specs/LIFECYCLE.md` | Spec 状态流转规则 |
| `specs/TRACEABILITY.md` | 需求追踪矩阵规范 |
| `specs/DEFINITION-OF-READY.md` | 进入开发的前置条件 |
| `specs/DEFINITION-OF-DONE.md` | 完成验收条件 |
| `specs/STRUCTURAL-SCORING.md` | 四源评分体系与统一红线 |
| `specs/scoring/ARBITER-PROTOCOL.md` | 仲裁算法、门禁、升级链 |
| `specs/scoring/RUBRIC-*.md` | 各阶段评分维度与红线 |
| `CONSTITUTION.md` | 最高治理权威 |
