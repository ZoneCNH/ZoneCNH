# Agent 三平台兼容性报告

> 基于 `14-agent-protocols.md` §0 要求：Agent 定义漂移时 MUST 生成 Change Request。本报告是对 Claude Code / Copilot CLI / Codex CLI 三平台 `goal-*` Agent 投影的一阶兼容性审计。

生成日期：2026-06-12
审计范围：`.claude/agents/goal-*.md`、`.copilot/agents/goal-*.md`、`.codex/agents/goal-*.toml`

---

## 1. Agent 存在性矩阵

| Agent                 | Claude Code | Copilot CLI | Codex CLI |
| --------------------- | ----------- | ----------- | --------- |
| goal-spec             | ✅ 348 行    | ✅ 63 行     | ✅ 51 行   |
| goal-matrix           | ✅ 253 行    | ✅ 64 行     | ✅ 53 行   |
| goal-reviewer         | ✅ 284 行    | ✅ 70 行     | ✅ 59 行   |
| goal-prompt-builder   | ✅ 451 行    | ✅ 63 行     | ✅ 52 行   |
| goal-evidence         | ✅ 430 行    | ✅ 81 行     | ✅ 69 行   |
| goal-architect        | ✅           | ❌           | ❌         |
| goal-context-recovery | ✅           | ❌           | ❌         |
| goal-governance       | ✅           | ❌           | ❌         |
| goal-lint             | ✅           | ❌           | ❌         |
| goal-planner          | ✅           | ❌           | ❌         |

**关键发现**：5 个核心 Agent 三平台同步，5 个辅助 Agent 仅 Claude Code 实现。按 `14-agent-protocols.md` 设计，Copilot/Codex 只需覆盖核心 5 个（spec / matrix / reviewer / prompt-builder / evidence），其余为可选的 Claude 专属能力——此差异符合设计，非漂移。

---

## 2. 文档引用一致性

### 幻影引用（已修复）

| 平台  | Agent               | 幻影引用                 | 实际文件              | 修复      |
| ----- | ------------------- | ------------------------ | --------------------- | --------- |
| Codex | goal-spec           | `02-goal-schema.md`      | `02-goal-standard.md` | ✅ 已修复  |
| Codex | goal-spec           | `07-human-approval.md`   | → `06-dod.md`         | ✅ 已修复  |
| Codex | goal-spec           | `09-tasks-and-prompt.md` | `09-templates.md`     | ✅ 已修复  |
| Codex | goal-prompt-builder | `09-tasks-and-prompt.md` | `09-templates.md`     | ✅ 已修复  |

### Copilot 引用验证

Copilot 5 个 Agent 的 13 个文档引用 **全部有效**，无幻影引用。

### Claude 引用基准

Claude 端 `goal-spec.md` 引用 19 个真实文档，可作为权威引用基准。

---

## 3. 结构差异分析

### 3.1 Agent 定义字段

| 字段              | Claude (.md)        | Copilot (.md)       | Codex (.toml) |
| ----------------- | ------------------- | ------------------- | ------------- |
| name              | ✅ YAML frontmatter  | ✅ YAML frontmatter  | ✅ TOML key    |
| description       | ✅                   | ✅                   | ✅             |
| model             | ✅ opus              | ❌                   | ✅ gpt-5.5     |
| tools             | ✅ list              | ❌ (平台默认)        | ❌ (平台默认)  |
| platform metadata | ❌                   | ✅                   | ❌             |
| system prompt     | ✅ 完整              | ✅ 投影              | ✅ 投影        |

**发现**：

- Claude 端明确指定 model 和 tools；Copilot 依赖平台默认——符合设计（`14-agent-protocols.md` 明确此为"平台投影"）。
- Codex 端 model 为 `gpt-5.5`，与 Claude 端的 `opus` 不同——这是跨平台预期的模型差异，不影响规则语义。

### 3.2 权威顺序声明

三平台均以相同顺序声明权威层级：

1. CONSTITUTION.md
2. docs/goal/00-authority-map.md
3. docs/goal/ (核心文档集)
4. .config/goal/schema/rules.yaml

**结论**：Codex/Copilot 一致（CONSTITUTION.md 于首位），Claude 此前缺失（已于 2026-06-12 补入 5 个 Agent）✅

### 3.3 MUST / MUST NOT 约束

| 约束                                | Claude  | Copilot | Codex   |
| ----------------------------------- | ------- | ------- | ------- |
| 不可确认内容标为 Hypothesis/BLOCKED | ✅       | ✅       | ✅       |
| 保留已批准 Goal 核心约束            | ✅       | ✅       | ✅       |
| 明确 Gate 输入/输出/阻断/证据       | ✅       | ✅       | ✅       |
| 自行批准 G0-G11                     | ✅ 禁止  | ✅ 禁止  | ✅ 禁止  |
| 放宽 Gate 或删除失败证据            | ✅ 禁止  | ✅ 禁止  | ✅ 禁止  |
| 把 vision 转成已批准规则            | ✅ 禁止  | ✅ 禁止  | ✅ 禁止  |
| 以本角色修改生产代码                | ✅ 禁止  | ✅ 禁止  | ✅ 禁止  |

**结论**：MUST/MUST NOT 语义等价 ✅

### 3.4 工具集逐 Agent 比较

仅 Claude 端通过 frontmatter `tools:` 字段声明 Agent 可用工具集（硬约束，平台执行）。Codex/Copilot 不声明工具，等效约束通过 `MUST NOT` 散文实现（软约束）。

| Agent               | Claude tools                        | 关键限制                          | Codex/Copilot 等效      |
| ------------------- | ----------------------------------- | --------------------------------- | ----------------------- |
| goal-spec           | Read, Write, Edit, Bash, Grep, Glob | 全能力（起草 + 验证）             | MUST NOT 修改生产代码   |
| goal-matrix         | Read, Write, Grep, Glob             | 无 Bash（无法运行 matrix-gen.py） | MUST NOT 伪造 Verified  |
| goal-reviewer       | Read, Grep, Glob, Bash              | **无 Write/Edit（强制只读）**     | MUST NOT 审批自身修改物 |
| goal-prompt-builder | Read, Write, Grep, Glob             | 无 Bash（无法运行验证）           | MUST NOT 写生产代码     |
| goal-evidence       | Read, Write, Bash, Grep, Glob       | 全能力（收集 + 验证）             | MUST NOT 删除失败证据   |

**漂移风险**：`goal-reviewer` 无 Write 权限是 Claude 端最关键的硬约束——Codex/Copilot 无等价机制层保护。`goal-matrix` 和 `goal-prompt-builder` 缺少 Bash 意味着无法执行 `matrix-gen.py --check-only` 或验证命令——Claude 端同样存在此缺口。

### 3.5 语义差异详情

以下差异为历史记录；G10（3.5.1）和 Matrix Verified（3.5.2）已于 2026-06-12 v2 修复轮中统一。

**3.5.1 G10 Release Gate 阻断条件 (7 vs 8)** ✅ 已修复

| 平台    | 阻断条件数 | 额外条件                                                      |
| ------- | :--------: | ------------------------------------------------------------- |
| Claude  | 7          | —                                                             |
| Copilot | 8          | Agent 绕过 pipeline-arbiter、单任务单 writer 或 worktree 隔离 |
| Codex   | 8          | 同 Copilot                                                    |

Claude `goal-reviewer.md` G10 清单曾经缺少 "Agent 隔离违规" 阻断条件。**已于 2026-06-12 修复**：Claude 端补入第 8 项 "Agent 不得绕过 pipeline-arbiter、单任务单 writer 或 worktree 隔离"，三平台 G10 阻断条件统一为 8 项。

**3.5.2 Matrix Verified 状态定义 (2 链路 vs 4 链路)** ✅ 已修复

| 平台    | Verified 条件                                                                                              |
| ------- | ---------------------------------------------------------------------------------------------------------- |
| Claude  | Code + Test + Evidence + Gate 四链路（M-LINT-008: "必须同时满足 Code + Test + Evidence + Gate（四链路）"） |
| Copilot | Code + Test + Evidence + Gate 四链路                                                                       |
| Codex   | Code + Test + Evidence + Gate 四链路                                                                       |

**已于 2026-06-12 修复**：Claude M-LINT-008 从 Code+Test 统一为四链路，三平台 Verified 定义一致。

**3.5.3 Claude 独有功能组件未投影** → 已降级为 LOW（通过精简文档索引缓解）

以下仅在 Claude Agent 内联 prose 中定义，Codex/Copilot 未覆盖：

- Prompt Chain 7 步编排、PromptOps 版本管理（goal-prompt-builder）
- Failure Budget 管理、AutoResearch 协议（goal-evidence）
- Evidence 类型分类（TEST/REVIEW/EXECUTION/MEASUREMENT）及禁止字段（goal-evidence）
- 评分体系（Goal/Spec 满分 100）、Lint 规则完整清单（goal-spec/reviewer）

> 已于 2026-06-12 为 10 个 Copilot/Codex Agent 添加 8 文档精简索引，降低跨平台文档发现成本。剩余差异为设计空间——Codex/Copilot 通过外部文档引用间接覆盖。

---

### 3.6 逐 Agent 字段级比较

#### 3.6.1 goal-spec

| 字段          | Claude                                                                              | Codex                                                                                    | Copilot                                                                          |
| ------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| name          | goal-spec                                                                           | goal-spec                                                                                | goal-spec                                                                        |
| description   | "Goal 驱动交付体系的项目规格专家。基于 docs/goal/ 体系，编写 Goal、Spec、Matrix..." | "Goal Delivery OS 的 Goal/Spec/Design/Plan/Task 编写代理，负责在不绕过 Gate 的前提下..." | "Goal Delivery OS 的 Goal/Spec/Design/Plan/Task 编写代理（Copilot 平台投影）..." |
| model         | opus                                                                                | gpt-5.5                                                                                  | (平台默认)                                                                       |
| tools         | [Read,Write,Edit,Bash,Grep,Glob]                                                    | (平台默认)                                                                               | (平台默认)                                                                       |
| system prompt | 完整内联 (348行)                                                                    | 投影 developer_instructions (39行)                                                       | 投影 Markdown (48行)                                                             |
| 权威文档数    | 19 个 docs/goal/\*.md                                                               | 10 个 (含 CONSTITUTION)                                                                  | 9 个 (含 CONSTITUTION)                                                           |
| 独有内容      | 评分体系表, Lint规则清单, 管线全景, 工具链, 孤儿检查, 变更级别CL0-CL5, 审查流程     | MUST/MUST NOT 散文, 4处已修正的幽灵引用                                                  | platform/goal_role/writes 元数据, 追加 "仅作为机器校验投影" 限定语               |

> 漂移项 D-01/D-02(已修复): Codex 引用了不存在的 `02-goal-schema.md` 和 `09-tasks-and-prompt.md`。Claude 原缺 `CONSTITUTION.md` (已修复)。

#### 3.6.2 goal-matrix

| 字段          | Claude                                                                          | Codex                                                                                                                    | Copilot                                                      |
| ------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------ |
| name          | goal-matrix                                                                     | goal-matrix                                                                                                              | goal-matrix                                                  |
| description   | "追溯矩阵管理器 — 从 Spec/Tasks 生成 Traceability Matrix..."                    | "Goal Delivery OS 的横向追溯矩阵代理，维护 canonical edge graph 并执行 Matrix 覆盖、孤儿和 release-critical edge 检查。" | "Goal Delivery OS 的横向追溯矩阵代理（Copilot 平台投影）..." |
| model         | sonnet                                                                          | gpt-5.5                                                                                                                  | (平台默认)                                                   |
| tools         | [Read,Write,Grep,Glob]                                                          | (平台默认)                                                                                                               | (平台默认)                                                   |
| 权威文档数    | 5 个 (含 CONSTITUTION)                                                          | 6 个 (含 CONSTITUTION+rules.yaml)                                                                                        | 6 个 (含 CONSTITUTION+rules.yaml)                            |
| Verified 定义 | M-LINT-008: "Code + Test"                                                       | "Code/Test/Evidence/Gate 四链路"                                                                                         | 同 Codex                                                     |
| 独有内容      | Matrix 生命周期, 派生展示字段表, 风险字段定义, 孤儿检查报告模板, 覆盖率报告模板 | MUST NOT "使用旧 row/table model"                                                                                        | platform/goal_role/writes 元数据                             |

> 漂移项 D-05(已修复): Verified 条件 Claude=2链 vs Codex/Copilot=4链——已于 2026-06-12 统一为四链路。Claude 矩阵 Agent 无 Bash 工具（无法执行 matrix-gen.py，已知设计限制）。

#### 3.6.3 goal-reviewer

| 字段         | Claude                                                                          | Codex                                                                                                        | Copilot                                                                             |
| ------------ | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| name         | goal-reviewer                                                                   | goal-reviewer                                                                                                | goal-reviewer                                                                       |
| description  | "审查者 — 以对抗性视角审查 Goal/Spec/Matrix/Design/Plan 等制品..."              | "Goal Delivery OS 的 Gate / Review / Release 对抗性审查代理，负责阻断缺证据、缺风险闭环或绕过 Gate 的交付。" | "Goal Delivery OS 的 Gate / Review / Release 对抗性审查代理（Copilot 平台投影）..." |
| model        | opus                                                                            | gpt-5.5                                                                                                      | (平台默认)                                                                          |
| tools        | [Read,Grep,Glob,Bash] — 无 Write/Edit (强制只读)                                | (平台默认)                                                                                                   | (平台默认)                                                                          |
| G0-G11 Gate  | 全部覆盖, 含具体检查重点和对抗性准则表                                          | 全部覆盖, 含 G10 阻断8项                                                                                     | 同 Codex                                                                            |
| G10 阻断条件 | 7 项                                                                            | 8 项 (多 "Agent 隔离违规")                                                                                   | 同 Codex                                                                            |
| 独有内容     | 对抗性审查准则表(假设/质疑模式), Go/No-Go 判定规则, DoR/DoD 审查表, 7层评分标准 | MUST NOT "审批自己刚修改的受保护制品", "把 Hypothesis 当作事实"                                              | platform/goal_role/writes 元数据                                                    |

> 漂移项 D-04(已修复): G10 阻断条件 Claud=7 vs Codex/Copilot=8——已于 2026-06-12 统一为 8 项。Claude Reviewer 无 Write 权限(硬约束)—Codex/Copilot 无等价机制（已知平台差异）。

#### 3.6.4 goal-prompt-builder

| 字段        | Claude                                                                                                                                                         | Codex                                                                                                       | Copilot                                                                        |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| name        | goal-prompt-builder                                                                                                                                            | goal-prompt-builder                                                                                         | goal-prompt-builder                                                            |
| description | "Context Package 构建器 — 从 Task spec 和关联制品生成结构化 Prompt..."                                                                                         | "Goal Delivery OS 的 Context Package / Prompt 构建代理，为单个 Task 生成可执行、可验证、可审计的编码输入。" | "Goal Delivery OS 的 Context Package / Prompt 构建代理（Copilot 平台投影）..." |
| model       | sonnet                                                                                                                                                         | gpt-5.5 (reasoning=medium)                                                                                  | (平台默认)                                                                     |
| tools       | [Read,Write,Grep,Glob]                                                                                                                                         | (平台默认)                                                                                                  | (平台默认)                                                                     |
| 权威文档数  | 6 个 (含 CONSTITUTION)                                                                                                                                         | 6 个 (含 CONSTITUTION+rules.yaml)                                                                           | 6 个 (含 CONSTITUTION+rules.yaml)                                              |
| 独有内容    | Context Package 10组件, Prompt Chain 7步, PromptOps 版本管理(文件树+prompt-meta.yaml), CL0-CL5变更检测表, 执行模式详细定义(Lite/Standard/Full), P-LINT-001~010 | 执行模式(Lite/Standard/Full 简述), MUST NOT 约束                                                            | platform/goal_role/writes 元数据                                               |

> 漂移项 D-02(已修复): Codex 引用了不存在的 `09-tasks-and-prompt.md`。Claude prompt-builder 无 Bash 工具。

#### 3.6.5 goal-evidence

| 字段          | Claude                                                                                                                                                               | Codex                                                                                                          | Copilot                                                              |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| name          | goal-evidence                                                                                                                                                        | goal-evidence                                                                                                  | goal-evidence                                                        |
| description   | "证据收集与验证器 — 收集、验证和管理 Evidence Protocol..."                                                                                                           | "Goal Delivery OS 的 Evidence 收集与验证代理，维护 Evidence Bundle、No Evidence No Done 和 Release 证据闭环。" | "Goal Delivery OS 的 Evidence 收集与验证代理（Copilot 平台投影）..." |
| model         | sonnet                                                                                                                                                               | gpt-5.5                                                                                                        | (平台默认)                                                           |
| tools         | [Read,Write,Bash,Grep,Glob]                                                                                                                                          | (平台默认)                                                                                                     | (平台默认)                                                           |
| 权威文档数    | 5 个 (含 CONSTITUTION)                                                                                                                                               | 7 个 (含 CONSTITUTION+rules.yaml)                                                                              | 7 个 (含 CONSTITUTION+rules.yaml)                                    |
| Evidence 分类 | 4类型(TEST/REVIEW/EXECUTION/MEASUREMENT) + 禁止字段(conclusion/recommendation/approval)                                                                              | 未分类                                                                                                         | 未分类                                                               |
| 独有内容      | Failure Budget 配置(max_retry/backoff/types), AutoResearch 4步协议, Evidence 必需字段(9字面+15Bundle), Evidence 收集/验证/一致性检查流程, 覆盖率/完整性/趋势报告模板 | Evidence Bundle 10字段 + Release Bundle 8字段(更结构化的字段定义)                                              | 同 Codex                                                             |

> 漂移项(Hypothesis LOW): Claude 的 Failure Budget、AutoResearch、Evidence 类型分类未在 Codex/Copilot 中出现——可能是通过引用文档间接覆盖，也可能是有意省略。

## 4. 详细度不对称

| 维度                          | Claude      | Copilot | Codex                  |
| ----------------------------- | ----------- | ------- | ---------------------- |
| 平均行数/Agent                | 353         | 68      | 57                     |
| 状态文件路径表                | ✅ 11 行     | ❌       | ❌                      |
| 权威文档索引表                | ✅ 20+ 文档  | ❌       | ❌                      |
| 管线全景图                    | ✅           | ❌       | ❌                      |
| 工作流步骤                    | ✅ 详细      | ✅ 简述  | ✅ 简述                 |
| 执行模式 (Lite/Standard/Full) | ✅           | ❌       | ✅ (仅 prompt-builder)  |

**评估**：详细度不对称是设计结果——Claude Code 端为"完整定义"，Copilot/Codex 端为"平台投影"。此模式符合 `14-agent-protocols.md` 设计，但存在风险：

- **风险**：Copilot/Codex Agent 在缺乏完整文档索引的情况下，可能无法发现适用的权威文档。
- **缓解**：权威顺序层 3 已列出核心文档清单，Agent 应能据此追溯。

---

## 5. 运行时验证

### 5.1 Copilot CLI Smoke Test

| 测试项                       | 结果                    |
| ---------------------------- | ----------------------- |
| lint-goal.sh (docs/goal/)    | 0 ERRORS, 0 WARNINGS ✅  |
| goal-validate.py (strict)    | PASS ✅                  |
| matrix-gen.py (--check-only) | 100% coverage ✅         |
| self-test.sh                 | 45/45 PASS ✅            |
| 跨路径执行 (/tmp → lint)     | 0 ERRORS ✅              |
| Python 3.14 + yaml           | OK ✅                    |

### 5.2 Rule Drift Check

```
[PASS] All 10 rule-drift checks passed
[PASS] No stale executable rule literals
[PASS] Gate IDs and status vocabularies match rules.yaml
```

---

## 6. 发现总结

| Severity | 数量  | 描述                                                                                                                                                                             |
| -------- | ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| HIGH     | 5     | 4 处 Codex 幻影文档引用 + 1 处 Claude 端 CONSTITUTION.md 缺失（均已修复）                                                                                                        |
| MEDIUM   | 3→1→0 | G10 阻断条件 7 vs 8 项（✅ 已修复）；Matrix Verified 定义 Code+Test vs 四链路（✅ 已修复）；Claude 独有功能组件未投影（✅ 迁移为 LOW——已通过精简文档索引缓解跨平台文档发现成本）    |
| LOW      | 1     | Copilot/Codex 缺少完整文档索引表（✅ 已修复，10 个 Agent 均已添加 8 文档精简索引）                                                                                                |

---

## 7. 建议

1. **已执行**：修复 Codex 端 4 处幻影文档引用
2. **已执行**：补入 `CONSTITUTION.md` 引用到 5 个 Claude Agent 的权威文档表
3. **已执行**：统一 G10 Release Gate 阻断条件为 8 项（Claude 端补入 Agent 隔离检查）
4. **已执行**：统一 Matrix Verified 定义为 Code+Test+Evidence+Gate 四链路
5. **已执行**：为 Copilot/Codex Agent 添加精简版文档索引（8 个核心文档 + 角色描述），降低 Agent 在跨平台执行时的文档发现成本
6. **已执行**：建立 CI 检查——扫描所有 Agent 定义中的 `docs/goal/*.md` 引用，验证目标文件存在（通过 `preflight` + `rule-drift-check.py`）
7. **无需操作**：辅助 Agent（architect / context-recovery / governance / lint / planner）仅在 Claude Code 端存在，符合设计

---

## 验证记录

- [x] 幻影引用修复验证（`grep -oh 'docs/goal/[^ )]*,]*\.md' .codex/agents/*.toml \| sort -u \| while read d; do [ -f "$d" ] && echo "OK $d" \|\| echo "PHANTOM $d"; done`）
- [x] Copilot 引用全量验证
- [x] rule-drift-check.py 10/10 PASS
- [x] Copilot CLI smoke 45/45 PASS
