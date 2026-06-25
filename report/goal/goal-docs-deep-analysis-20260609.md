# Goal 文档体系深度结构分析报告

> 分析时间：2026-06-09 | 分析范围：`docs/goal/` 28 个顶层 Markdown 文档 + `tools/` 6 个常规文件
> 分析方法：逐文件精读 → 交叉引用验证 → 结构一致性检查 → 评分

---

## 1. 总览

| 指标               | 数值                                          |
| ------------------ | --------------------------------------------- |
| 文档文件数         | 28（含 GLOSSARY、CHANGELOG）                  |
| 工具常规文件数     | 6（3 Shell + 2 Python + README）              |
| 其中工具脚本数     | 5                                             |
| 总行数（Markdown） | ~5,614                                        |
| 总行数（工具脚本） | 1,177                                         |
| tools README 行数  | 146                                           |
| 首次编写时间       | 2026-06-08                                    |
| 最近更新           | 2026-06-09                                    |

---

## 2. 评分体系

从 6 个维度评分，每项满分 100：

| 维度             | 分数 | 说明                                                                           |
| ---------------- | ---- | ------------------------------------------------------------------------------ |
| **文档完整性**   | 78   | 覆盖 Goal→Retrospective 全链路，但缺少独立的 Error Code 目录、词汇索引链接不全 |
| **结构一致性**   | 58   | SSOT 声明冲突、章节编号跳跃、模板与管线定义不一致                              |
| **ID/版本体系**  | 52   | 新旧格式并存未定义切换边界，版本号规则散布多文件                               |
| **可执行性**     | 72   | 工具脚本可运行，但脚本文档契约弱、Lint 规则覆盖不全                            |
| **可维护性**     | 65   | CHANGELOG 完整，但 24 号文件（自分析）与主体系混淆、文件编号策略不清晰         |
| **跨文档一致性** | 55   | 状态枚举、Schema 字段、Gate 定义在多文件间存在漂移                             |

**综合评分：63/100**

> 注：`report/goal/goal-docs-structural-analysis-20260609.md` 是本目录主审计报告，本报告作为补充分析保留更细的交叉引用证据；评分差异不代表两个权威结论并存。

---

## 3. 问题清单

### P1 — 阻塞级（影响体系可信度，必须优先修复）

#### P1-1：状态权威边界未映射

| 文件                  | 状态对象              | 实际覆盖                                                         |
| --------------------- | --------------------- | ---------------------------------------------------------------- |
| `03-pipeline.md`      | Pipeline state        | 粗粒度阶段就绪态、执行态和异常态                                 |
| `02-goal-standard.md` | Goal object status    | Goal 生命周期状态                                                |
| `15-registry.md`      | Issue lifecycle       | Registry Issue 的处理状态                                        |
| `rules.yaml` 样例     | Runtime/activity enum | 更细的起草、审查、批准、编码、测试、发布等活动态                 |

**问题**：这些状态不一定应该合并成一个枚举；真正缺失的是状态对象边界和映射关系。`03-pipeline.md` 的状态更像阶段摘要，`02-goal-standard.md` 是 Goal 对象生命周期，`15-registry.md` 是 Issue 工作流，`rules.yaml` 样例偏运行态活动枚举。当前报告和工具容易把它们误读为同一层级的互斥 SSOT。

**修复建议**：定义 `pipeline_state`、`goal_status`、`issue_status`、`phase_state` 四类状态的边界、合法值和转换映射；避免简单地把所有状态收敛到一个文件。

#### P1-2：运营 SOP 与主流程缺少映射

| 文件                | 声明的阶段数  | 具体阶段                                                                                                    |
| ------------------- | ------------- | ----------------------------------------------------------------------------------------------------------- |
| `README.md`         | 11 层         | Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective               |
| `03-pipeline.md`    | 11 层         | 同上                                                                                                        |
| `01-methodology.md` | 11 层         | 同上                                                                                                        |
| `12-operations.md`  | 12 步 SOP     | Goal → Goal Review → Spec → Matrix → Tasks → Plan → Prompt → Code → Test → Review → Release → Validate Goal |

**问题**：`12-operations.md` 更像操作手册而不是主方法论，但它没有说明与 11 层主流程的映射。差异包括：加入 Goal Review、Matrix、Validate Goal；省略 Design 和 Retrospective；把 Tasks 放在 Plan 之前；把 Matrix 作为步骤，而 `03-pipeline.md` 把 Matrix 定义为横切制品。

**修复建议**：将 SOP 标注为 operations profile，并逐项映射到主流程阶段；Matrix 可作为 Spec 后初始化的横切制品，Validate Goal 可映射到 Release/Retrospective 的验收动作。

#### P1-3：Goal Schema 投影视图不一致

| 定义位置                   | 对象视图          | 关键差异                                                          |
| -------------------------- | ----------------- | ----------------------------------------------------------------- |
| `02-goal-standard.md`      | Goal 标准字段     | 包含 `owner`、`priority`、`status` 等最小字段                     |
| `09-templates.md` YAML     | Goal 编写模板     | 包含 `target_users`、`scope`、`constraints`，但缺少部分最小字段   |
| `15-registry.md`           | Registry 运行视图 | 包含 `goal_id`、`pipeline_state`、`current_phase`、`phase_status` |

**问题**：Goal 文档对象、模板对象、Registry 行对象可能本来就是三种投影视图，但文档没有说明字段映射和必填性。当前读者无法判断模板缺少 `owner`、`priority`、`status` 是简化视图、遗漏，还是由 Registry 补齐。

**修复建议**：先定义 canonical Goal schema，再声明 `template view`、`registry view`、`report view` 的字段映射、派生字段和不可丢字段。

#### P1-4：Matrix Schema 多源不一致

`05-layer-standards.md` §9 用 prose 定义了 Matrix 字段和质量准则；`09-templates.md` 给出了较短的 YAML 示例；`rules.yaml` 样例包含 `goal_id`、`spec_id`、`requirement_id`、`acceptance_criteria`、`task_id`、`prompt_id`、`code_module`、`test_case`、`evidence_ids`、`status`、`risk` 等机器字段，并设置覆盖率阈值。

**问题**：不是完全没有 Matrix Schema，而是机器 schema、模板示例、标准层 prose 没有明确主从关系。`15-registry.md` 不包含 Matrix 也未必错误，因为 Matrix 可以是横切制品而非 Registry，但这种边界应被写清。

**修复建议**：选择一个机器可解析 schema 作为 Matrix canonical schema；`09-templates.md` 从它派生示例，`05-layer-standards.md` 只描述语义和质量准则，工具校验回指同一 schema。

---

### P2 — 重要级（影响可用性和维护效率）

#### P2-1：ID 新旧格式切换边界未定义

`07-id-system.md` 定义了新格式（如 `GOAL-YYYYMMDD-NNN`、`SPEC-<domain>-vN`、`DESIGN-<domain>-vN`、`PROMPT-<task-id>-NNN`），并保留历史格式的识别规则与迁移对照。但未定义：

- 何时开始强制使用新格式？
- 混合使用的过渡期有多长？
- 工具是“兼容读取旧格式、输出新格式”，还是“新旧格式同时有效”？
- 哪些对象的 ID 应由 `rules.yaml` 正则、lint 脚本和 Matrix 工具共同裁决？

当前 `tools/lint-goal.sh` 没有完整执行 `07-id-system.md` 的 ID 语法，也没有实现新旧格式过渡校验；`tools/matrix-gen.py` 只做了部分 ID 抽取与 Matrix 行检查。因此问题不是“旧格式会被现有 lint 日期校验误报”，而是“文档承诺、机器正则、脚本校验之间没有形成同一张兼容矩阵”。

**修复建议**：在 `07-id-system.md` 中增加“过渡策略”章节，明确新制品必须输出新格式、历史制品可兼容读取的边界；再把每类 ID 的 canonical regex、兼容 regex、输出 regex 映射到 `rules.yaml`、`lint-goal.sh` 和 `matrix-gen.py`。

#### P2-2：Lint 规则覆盖不全

`10-lint-rules.md` 定义了 5 类 Lint 规则（G/S/M/P/C-LINT），总计约 38 条规则。但工具实现面窄于文档承诺：

| Lint 类别       | 规则数 | 对应文档的 Schema 定义                                           |
| --------------- | ------ | ---------------------------------------------------------------- |
| G-LINT (Goal)   | 7      | `02-goal-standard.md`、`09-templates.md`                         |
| S-LINT (Spec)   | 8      | `05-layer-standards.md` §3                                       |
| M-LINT (Matrix) | 8      | `05-layer-standards.md` §9、`09-templates.md`、`rules.yaml` 样例 |
| P-LINT (Prompt) | 10     | `11-ai-collaboration.md`                                         |
| C-LINT (Code)   | 5      | `10-lint-rules.md` 内联                                          |

**问题**：

- Matrix 不是完全无 Schema，而是 prose、模板样例、`rules.yaml` 机器字段之间主从关系不清
- D-LINT（Design）、T-LINT（Tasks）、R-LINT（Test）完全缺失
- `tools/lint-goal.sh` 实现了部分 Goal / Spec / Matrix / Prompt 检查和敏感信息扫描，但没有完整覆盖 S/M/P/C-LINT，也没有执行 YAML schema、状态枚举、ID 兼容矩阵和跨文件追溯校验

**修复建议**：补齐缺失的 Lint 类别，或在 `10-lint-rules.md` 中明确标注哪些规则有工具实现、哪些是手动检查。

#### P2-3：`24-standard-unification-analysis.md` 定位混乱

该文件是 2026-06-08 编写的自分析报告，包含：

- 8 维度评分（66/100）
- 9 个统一需求（P0: 5 个，P1: 3 个，P2: 1 个）
- 最小可执行修复包

**问题**：

- 文件编号为 `24-`，暗示它是规范文档的一部分，但内容是分析报告
- 它与 `report/goal/` 下的分析报告功能重叠
- 其中的修复建议大部分未被执行（从 CHANGELOG 看只完成了部分）
- 读者无法判断它是否仍然有效（哪些已修复、哪些仍待处理）

**修复建议**：将 `24-standard-unification-analysis.md` 移到 `report/goal/` 归档，在原位置保留重定向引用。

#### P2-4：Gate 定义与 DoD 检查项重叠但不一致

`04-gates.md` 定义了 G0-G11 共 12 个 Gate，每个 Gate 有独立的检查项。`06-dod.md` 定义了各阶段的 Ready/Done 标准。两者在功能上高度重叠（Gate 检查 ≈ DoD 验证），但：

- Gate 使用 PASS/PASS_WITH_RISK/FAIL/BLOCKED 四态结果
- DoD 使用 ✓/✗ 二态检查
- 两者的检查项集合不完全一致（Gate 有安全检查，DoD 没有；DoD 有文档检查，Gate 没有）

**修复建议**：统一 Gate 和 DoD 的检查项，或明确 Gate 是 DoD 的超集（Gate = DoD + 安全/合规检查）。

#### P2-5：`11-ai-collaboration.md` 内容过载

该文件 358 行，包含：

- AI 编程控制点
- Context Package 标准（10 元素）
- PromptOps 概念
- Prompt Chain（7 步）
- 主 Prompt 模板
- Review Prompt 模板
- AI 输出验收协议
- Code Boundary
- Non-goals 传播
- Prompt→Code 执行周期

这些内容横跨 Prompt 设计、Code 质量、Review 流程三个领域，与 `05-layer-standards.md`（Prompt/Code 层标准）、`06-dod.md`（Prompt/Code Done 标准）、`10-lint-rules.md`（P-LINT/C-LINT）存在大量重叠。

**修复建议**：将 `11-ai-collaboration.md` 拆分为 Prompt 设计指南（保留）和 Code 质量标准（移到 `05-layer-standards.md`）。

---

### P3 — 改善级（提升体验，非阻塞）

#### P3-1：GLOSSARY 术语表链接不完整

`GLOSSARY.md` 定义了 53 个术语，但大部分术语的"权威定义"链接指向 `docs/goal/` 内部文件的章节标题。问题是：章节标题可能变更，且没有自动化验证链接有效性。

**修复建议**：增加链接有效性检查脚本，或使用相对路径引用。

#### P3-2：CHANGELOG 格式与版本管理不一致

`CHANGELOG.md` 使用简单的日期+条目格式，而 `12-operations.md` 定义了版本管理规范（v0.1→v2.0）。两者格式不统一。

**修复建议**：将 CHANGELOG 对齐到 `12-operations.md` 的版本管理规范。

#### P3-3：工具脚本缺少错误处理文档

`tools/` 目录的脚本缺少：

- 错误码定义
- 失败场景说明
- 与 CI/CD 集成的退出码约定

**修复建议**：在 `tools/README.md` 中增加错误处理章节。

#### P3-4：章节编号跳跃 — `05-layer-standards.md` §7→§9

`05-layer-standards.md` 的章节结构：

- §1-§2：概览
- §3：Spec
- §4：Design
- §5：Plan
- §6：Tasks
- §7：Prompt
- **§8 缺失**
- §9：Matrix 作为横切制品

§8 缺失未说明原因。可能原计划用于 Code/Test 层标准，但被移除或合并到其他章节。这破坏了文档的编号连续性，也暗示该文件经历过未记录的重组。

**修复建议**：补齐 §8（Code/Test 层标准）或重新编号。

---

## 4. 核心发现

### 4.1 SSOT（单一事实来源）问题

最严重的问题。系统中存在多处 SSOT 声明冲突：

| 制品        | 声明位置                   | 冲突方                                  |
| ----------- | -------------------------- | --------------------------------------- |
| 管线状态    | `03-pipeline.md`           | `02-goal-standard.md`、`15-registry.md` |
| Goal Schema | `02-goal-standard.md`      | `09-templates.md`、`15-registry.md`     |
| 矩阵定义    | `05-layer-standards.md` §9 | `09-templates.md`（无完整 Schema）      |
| 版本管理    | `12-operations.md`         | `CHANGELOG.md`（使用不同格式）          |

根因：文档是分批次编写的（从 CHANGELOG 看，核心框架 06-08，补充和修复 06-09），每次编写时都声明了 SSOT，但未回溯检查已有声明。

### 4.2 运营 SOP 与主流程粒度漂移

11 层管线是核心架构定义，但 `12-operations.md` 的 12 步 SOP 采用了操作手册粒度：Goal、Goal Review、Spec、Matrix、Tasks、Plan、Prompt、Code、Test、Review、Release、Validate Goal。它没有把 `Evidence` 作为独立阶段；真正的问题是 SOP 加入了 Goal Review、Matrix、Validate Goal，省略 Design 和 Retrospective，并改变了 Plan / Tasks 顺序。如果不写清映射关系，日常执行者会把操作步骤误当成主方法论阶段。

### 4.3 状态枚举碎片化

至少 4 处定义了不同的状态机：

1. `03-pipeline.md`：13 个正常态 + 8 个异常态
2. `02-goal-standard.md`：Goal 6 态
3. `15-registry.md`：Issue 5 态
4. `04-gates.md`：Gate 结果 4 态（PASS/PASS_WITH_RISK/FAIL/BLOCKED）

这些状态机之间的映射关系未定义。例如：当 Gate 结果为 `FAIL` 时，Goal 状态应转为哪个？Issue 状态如何跟随？

### 4.4 工具-文档契约薄弱

`tools/` 目录有 6 个常规文件，其中 5 个脚本（`lint-goal.sh`、`gate-check.sh`、`evidence-collect.sh`、`matrix-gen.py`、`rule-drift-check.py`）和 1 个 README。当前契约问题是：

- `lint-goal.sh` 实现基础字段、关键词、部分 Spec / Matrix / Prompt 和敏感信息检查，但不等同于完整 G/S/M/P/C-LINT
- `matrix-gen.py` 可生成和检查矩阵，但与 `09-templates.md` 示例、`rules.yaml` 机器字段之间的主从关系未说明
- `evidence-collect.sh` 可生成 Evidence 模板，但证明深度、命令输出和 artifact 校验语义仍偏弱
- `gate-check.sh` 是轻量 readiness / evidence / matrix 检查器，不是完整 G0-G11 Gate 引擎
- `rule-drift-check.py` 检查规则漂移但检查范围未文档化

### 4.5 文件编号策略不一致

文件编号 00-23 + 24（自分析）+ GLOSSARY + CHANGELOG。编号策略不清晰：

- 为什么 00 是 quickstart？（通常 00 是索引或概述）
- 为什么 24 是自分析？（应该独立于规范编号）
- 为什么 GLOSSARY 和 CHANGELOG 没有编号？（可以接受，但需要说明）

---

## 5. 改进建议（优先级排序）

### Phase 1：止血（1-2 天）

| 编号 | 任务                                                                 | 影响      |
| ---- | -------------------------------------------------------------------- | --------- |
| F-1  | 统一 SSOT 声明：每类对象只保留一个裁决源，其他文件引用或声明投影视图 | 解决 P1-1 |
| F-2  | 对齐 `12-operations.md` SOP 到 11 层管线                             | 解决 P1-3 |
| F-3  | 修复 `05-layer-standards.md` §8 缺失                                 | 解决 P1-2 |
| F-4  | 统一 Goal Schema 到 `09-templates.md`                                | 解决 P1-4 |
| F-5  | 明确 Matrix canonical schema，并让模板、prose 和工具回指同一来源     | 解决 P1-4 |

### Phase 2：加固（3-5 天）

| 编号 | 任务                                                              | 影响      |
| ---- | ----------------------------------------------------------------- | --------- |
| F-6  | 定义 ID 格式过渡策略                                              | 解决 P2-1 |
| F-7  | 标注 Lint 规则的工具实现状态                                      | 解决 P2-2 |
| F-8  | 将 `24-standard-unification-analysis.md` 移到 `report/goal/` | 解决 P2-3 |
| F-9  | 统一 Gate 和 DoD 检查项                                           | 解决 P2-4 |
| F-10 | 拆分 `11-ai-collaboration.md`                                     | 解决 P2-5 |

### Phase 3：完善（持续）

| 编号 | 任务                           | 影响         |
| ---- | ------------------------------ | ------------ |
| F-11 | 工具脚本与文档 Schema 对齐验证 | 解决 §4.4    |
| F-12 | 统一版本管理格式               | 解决 P3-2    |
| F-13 | 建立跨文档引用检查自动化       | 防止漂移复发 |

---

## 6. 与已有分析报告的对比

`report/goal/goal-docs-structural-analysis-20260609.md` 是本目录主审计报告，给出 66/100；本报告在事实校准后给出 63/100，定位为补充证据和细化建议。两份报告不应被理解为并列权威。

| 维度         | 已有报告             | 本报告                            | 差异原因                      |
| ------------ | -------------------- | --------------------------------- | ----------------------------- |
| 发现的问题数 | 7 P1 + 8 P2 + 4 P3   | 5 P1 + 5 P2 + 3 P3                | 本报告更严格定义 P1（阻塞级） |
| SSOT 问题    | 提及                 | 深入分析了 4 处冲突的具体字段差异 | 本报告更细致                  |
| 管线阶段数   | 已覆盖流程和状态漂移 | 补充 SOP 与主流程的具体映射差异   | 细化已有发现                  |
| §8 缺失      | 已覆盖               | 保留章节连续性证据                | 细化已有发现                  |
| 工具契约     | 提及                 | 细化到每个脚本的具体缺陷          | 更具体                        |

---

## 7. 结论

Goal 文档体系已经覆盖从 Goal 到 Retrospective 的完整链路，但在快速推进过程中积累了结构性债务：

- **SSOT 冲突**是最核心的问题，需要立即统一
- **管线阶段数不一致**影响日常执行
- **Schema 定义缺失**影响工具链自动化

CHANGELOG 显示 2026-06-09 已有部分修复动作，`24-standard-unification-analysis.md` 也已识别若干同类问题。后续应先完成 Phase 1 的权威边界和映射修复，再决定是否推进工具增强。

---

> 分析深度：逐文件精读 + 交叉引用验证
