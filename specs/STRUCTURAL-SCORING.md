# 结构性评分体系

> 管线每个阶段产物的统一评分方法、聚合规则与门禁定义。

最后更新：2026-06-08

---

## 1. 适用范围

| 阶段 | 评分对象 | Rubric |
|------|----------|--------|
| Spec | `specs/{module}/SPEC.md` | `scoring/RUBRIC-spec.md` |
| Matrix | `specs/{module}/TRACEABILITY.md` | `scoring/RUBRIC-matrix.md` |
| Tasks | `specs/{module}/tasks/TASK-*.md` | `scoring/RUBRIC-tasks.md` |
| Plan | `specs/{module}/IMPLEMENTATION-PLAN.md` | `scoring/RUBRIC-plan.md` |
| Prompt | `specs/{module}/TASK-*-PROMPT.md` | `scoring/RUBRIC-prompt.md` |
| Code | 本次 Task diff + 测试 + 验证证据 | `scoring/RUBRIC-code.md` |

---

## 2. 四源并行评分（三 LLM + 一规则引擎）

每个阶段必须由 **三个独立 LLM 平台 + 一个规则引擎** 并行评分：

| 源 | 路径 | 模型/类型 |
|------|------------|------|
| Claude Code | `.claude/agents/{stage}-structural-score.md` | Opus |
| Codex | `.codex/agents/{stage}-structural-score.toml` | gpt-5.5 high |
| Copilot CLI | `.copilot/agents/{stage}-structural-score.md` | Claude Opus 4.7 |
| Rules（异构）| `scripts/rule-scorer.py` | 纯 Python 规则引擎，零 LLM |

三个 LLM 平台必须读取相同 rubric，独立打分，互相不可见对方结果。
规则引擎不读 rubric 文本，按宪法 §14.4 要求作为**异构信号源**打破同源相关性：
若 `abs(rules.score - median(llm_scores)) > 15`，仲裁器记录 `heterogeneous_divergence`
失败并路由 meta-arbiter 诊断（可能是 Goodhart 信号）。

---

## 3. 评分输出格式

每个 scorer 必须输出符合以下 schema 的 JSON 报告，写入：

```text
{state_root}/pipeline/{module}/{stage}/scores/{platform}.json
```

`state_root` 按运行时选择：Claude `.omc/state`，Codex `.omx/state`，Copilot `.copilot/state`。

Schema：

```json
{
  "module": "kernel",
  "stage": "matrix",
  "platform": "claude",
  "scored_at": "2026-06-08T08:50:00Z",
  "score": 97,
  "redline": false,
  "verdict": "Ready-candidate",
  "confidence": "high",
  "dimensions": [
    { "name": "结构完整性", "max": 20, "deducted": 2, "score": 18 }
  ],
  "deductions": [
    { "id": "D1", "severity": "MEDIUM", "points": 2, "rule": "...", "evidence": "...", "fix": "..." }
  ],
  "redlines": [],
  "report_md": "specs/{module}/.../score-claude.md"
}
```

并同步输出可读的 Markdown 报告供人审阅（路径见 `report_md`）。

---

## 4. 仲裁与门禁

仲裁由 `pipeline-arbiter` agent 完成。规则见 `scoring/ARBITER-PROTOCOL.md`。核心：

| 规则 | 阈值 |
|------|------|
| 门禁公式 | `composite_score = min(claude.score, codex.score, copilot.score, rules.score)` 且 `composite_score >= 98` |
| 红线 | 任一评分源 `redline: true` → 阻塞 |
| 置信度 | 任一 LLM 平台 `confidence: low` → 阻塞并重评 |
| 分差 | `max(llm_scores) - min(llm_scores) > 5` → 阻塞并进入评分差异调解 |
| 异构分歧 | `abs(rules.score - median(llm_scores)) > 15` → 阻塞并进入 meta-arbiter 诊断 |

**纯机器门禁，不引入人工**。Confidence 与分差是门禁字段：任一低置信度或平台分差超过阈值，gate 必须 fail 并自动路由重评或修复。

仲裁输出写入：

```text
{state_root}/pipeline/{module}/{stage}/verdict.json
```

```json
{
  "stage": "matrix",
  "scores": { "claude": 97, "codex": 99, "copilot": 98, "rules": 96 },
  "min": 96,
  "max": 99,
  "heterogeneous_divergence": 2,
  "redlines": [],
  "gate": "fail",
  "reason": "min(97) < 98",
  "next_action": "route_to_executor_for_repair"
}
```

`gate=pass` 才允许进入下一阶段。`gate=fail` 自动路由回当前阶段 executor 修复；修复循环受第 7 节 attempt 与全链路 repair budget 限制。

---

## 5. 红线统一定义

任一条件触发即视为红线（独立于分数）：

1. 产物缺失或为空壳（关键章节不存在）。
2. 上游追溯断裂（无法回到 Spec 的 FR/BR/AC/TC）。
3. 违反 `CONSTITUTION.md` 硬约束。
4. 出现凭证、密钥、敏感数据。
5. 跨模块或越权写入。
6. Scope 蔓延（产物包含 Spec 外功能）。
7. 验证手段缺失或不可执行。

各阶段 rubric 可在此基础上补充阶段特定红线。

---

## 6. 严重级别

| 级别 | 含义 | 典型扣分 |
|------|------|----------|
| REDLINE | 触发红线 | 无论分数仲裁失败 |
| CRITICAL | 阻塞下游 | 8-15 |
| HIGH | 重大返工风险 | 4-7 |
| MEDIUM | 应在本阶段修复 | 2-3 |
| LOW | 可读性/格式 | 1 |

---

## 7. 有界失败循环

同一阶段连续 3 次仲裁失败自动路由到上游阶段重新生成产物：

- Code 失败 3 次 → 自动回 Prompt
- Prompt 失败 3 次 → 自动回 Plan
- 一路向上直到 Spec
- Spec 失败时由 `spec` executor 重写后继续重跑评分，但仍计入全链路 repair budget

默认限制：

```text
max_stage_attempts = 3
max_total_gate_failures = 18
```

推进下一阶段的唯一条件是四源仲裁 `gate=pass`。自动修复循环还有独立停止条件：达到 `max_total_gate_failures` 后，arbiter 必须输出 `pipeline_blocked`，生成 retrospective，并停止自动推进；不得用无限重写 Spec 的方式绕过结构性缺陷。

阻塞状态必须写入：

```text
{state_root}/pipeline/{module}/pipeline_blocked.json
specs/{module}/PIPELINE-RETROSPECTIVE.md
```

---

## 8. 唯一门禁

每个阶段的进入下一阶段的**唯一**条件：四源仲裁 `gate=pass`。

- 不再设置 `spec-review` Go/No-Go 作为额外门禁。
- 不再设置 `Status: Approved` 作为额外门禁；Spec 阶段四源 pass 后由 arbiter 自动将 SPEC.md 状态翻转为 `Approved`。
- `spec-review` agent 仍可在 Spec 阶段作为额外的对抗性视角，但其结论只作为 scorer 的输入证据，不构成独立 gate。

---

## 9. Anti-Goodhart 约束（宪法 §14）

本评分体系本身受 `CONSTITUTION.md` 第十四条约束：

- **受保护文件清单**（见宪法 §14.1）：`specs/scoring/RUBRIC-*.md`、本文件、`ARBITER-PROTOCOL.md`、`.claude/agents/`、`.codex/agents/`、`.copilot/agents/`、`.omc/state/outer-metrics/`、`.omx/state/outer-metrics/`、`.copilot/state/outer-metrics/`、`CONSTITUTION.md`。所有 LLM agent **只读**。
- **外部指标只读**（宪法 §14.2）：三套运行时的 `outer-metrics/` 由 CI / 生产观测 / git 历史 / 人类维护者写入；任何 scorer、arbiter、executor 均不得写入。
- **合法 RSI 流程**（宪法 §14.3）：修改受保护文件必须经过 fork → A/B → outer-metric 评判 → 人类批准。
- **Goodhart 防线**（宪法 §14.4）：scorer 评分与 outer metric 相关性低于阈值时自动冻结，触发 RSI 审议。

普通阶段产物的 RSI 是自动修复；评分体系、rubric、agent、arbiter、工作流入口等受保护文件的 RSI 是元级改进流程。后者必须先创建 `specs/workflow-improvement/{YYYYMMDD}-{slug}/SPEC.md` 并通过同一条管线，再执行宪法 §14.3 的 fork、A/B、outer metric 与人类批准。

`composite_score >= 98` 仅是必要条件，不构成自我授权修改评分体系的依据。
