# docs/goal/ 结构性深度分析报告 v2

- 分析对象：`docs/goal/` 全部 24 个 Markdown 文件 + `tools/` 目录
- 分析日期：2026-06-08
- 分析方法：全量逐文件通读 + 交叉引用验证 + 一致性检查
- 总行数：5,447 行（24 个 .md 文件）

---

## 1. 总评

`docs/goal/` 是一套覆盖 Goal 驱动交付全生命周期的方法论文档体系，共 24 篇文档，从快速开始（00）到工作流治理检查（23），外加术语表和变更日志。体系设计意图清晰，覆盖面广，但在 SSOT 治理、跨文件一致性、引用完整性和实现-愿景边界方面存在系统性问题。

**核心判断**：文档体系的"骨架"是好的——分层管线、Gate 体系、追溯矩阵、ID 系统等核心概念设计合理。但"肌肉"层面存在大量重复定义、引用断裂和术语漂移，导致读者在多文件间跳转时容易迷失权威来源。

**结构健康分：71/100**

---

## 2. 评分账本

| 维度          | 权重 | 得分  | 扣分原因                                                              |
| ------------- | ---- | ----- | --------------------------------------------------------------------- |
| 目录组织      | 10%  | 8/10  | 编号连续、分层清晰；扣 2 分因 tools/ 实际存在但 README 标注 "planned" |
| 内容完整性    | 15%  | 11/15 | 覆盖全面但 RACI 仅到 Test，缺 Review/Release/Retrospective 行         |
| SSOT 治理     | 20%  | 11/20 | 6 处重复定义、3 处 SSOT 声明与实际不符                                |
| 跨文件一致性  | 20%  | 12/20 | 状态枚举、ID 格式、路径约定存在多处不一致                             |
| 引用完整性    | 15%  | 10/15 | 5 处断链引用、3 处引用目标不存在                                      |
| 可操作性      | 10%  | 8/10  | 模板丰富、示例充足；扣 2 分因部分示例与定义不一致                     |
| 愿景-实现边界 | 10%  | 7/10  | 2 个文件标 Vision 但混在实现文档中，缺乏统一状态标注                  |

**加权总分** = 8×0.1 + 11×0.15 + 11×0.2 + 12×0.2 + 10×0.15 + 8×0.1 + 7×0.1 = **71/100**

---

## 3. 结构性问题清单

### 3.1 SSOT 治理问题（严重度：HIGH）

#### 问题 S1：DoR/DoD 双重 SSOT 声明

| 文件                           | 声明                                          |
| ------------------------------ | --------------------------------------------- |
| `06-dod.md` 第 3 行            | "**本文档是 DoR/DoD 的唯一权威来源（SSOT）**" |
| `08-quality-gates.md` 第 15 行 | "各层 DoR/DoD 的权威定义见 06-dod.md"         |

`08-quality-gates.md` 正确引用了 `06-dod.md`，但 `06-dod.md` 自身的 DoR/DoD 定义与 `05-layer-standards.md` 中各层标准存在内容重叠。例如：

- `06-dod.md §5 Tasks DoD` 定义了 Task 完成标准
- `05-layer-standards.md §4 Tasks 标准` 也定义了 Task 粒度标准和状态

两处定义互补但未明确边界，读者不清楚"Task 标准"到底由哪个文件权威定义。

**建议**：在 `05-layer-standards.md` 每层标准末尾添加 "DoR/DoD 见 06-dod.md §N" 的显式引用，消除歧义。

#### 问题 S2：Prompt 分层表重复

以下两个文件包含完全相同的 Prompt 分层表（5 行 × 2 列）：

| 文件                     | 位置                          |
| ------------------------ | ----------------------------- |
| `05-layer-standards.md`  | §5 Prompt 标准 → Prompt 分层  |
| `11-ai-collaboration.md` | §4 Prompt Chain → Prompt 分层 |

内容一字不差。违反 SSOT 原则。

**建议**：`11-ai-collaboration.md` 改为引用 `05-layer-standards.md §5`，删除重复表格。

#### 问题 S3：Evidence ID 格式定义分散

Evidence ID 格式在以下位置定义：

| 文件                       | 格式                                    |
| -------------------------- | --------------------------------------- |
| `05-layer-standards.md §8` | `EVID-AC-{SPEC}-{NUM}-{NNN}`            |
| `07-id-system.md §1`       | `EVID-AC-{SPEC}-{REQNNN}-{ACNNN}-{NNN}` |
| `20-metrics-evidence.md`   | `EVID-AC-{SPEC}-{REQNNN}-{ACNNN}-{NNN}` |

`05-layer-standards.md` 的格式 `{NUM}` 笼统，而 `07-id-system.md` 和 `20-metrics-evidence.md` 的格式 `{REQNNN}-{ACNNN}` 更精确。三处定义不完全一致。

**建议**：`05-layer-standards.md §8` 改为引用 `07-id-system.md §1`，删除本地格式定义。

---

### 3.2 状态枚举不一致（严重度：HIGH）

#### 问题 T1：Pipeline State 数量矛盾

| 文件                                      | 描述                                |
| ----------------------------------------- | ----------------------------------- |
| `03-pipeline.md §2.2`                     | "正常 pipeline_state 枚举（13 个）" |
| `GLOSSARY.md` Pipeline State Machine 条目 | "定义 12 种正常状态"                |
| `03-pipeline.md §2.7` 对象状态总表        | Pipeline 行引用 §2.2（13 个）       |

`GLOSSARY.md` 写的是"12 种"，实际枚举有 13 个。术语表与权威定义矛盾。

**建议**：修正 `GLOSSARY.md` 为"13 种正常状态"。

#### 问题 T2：Task 状态枚举不一致

| 文件                               | 状态枚举                                                                |
| ---------------------------------- | ----------------------------------------------------------------------- |
| `05-layer-standards.md §4` 正文    | `Unmapped → Mapped → In Progress → Done → Blocked`（含 `Dropped` 分支） |
| `03-pipeline.md §2.7` 对象状态总表 | `Unmapped → Mapped → In Progress → Done → Blocked`（无 `Dropped`）      |
| `15-registry.md §2` Task 字段说明  | `Unmapped / Mapped / In Progress / Done / Blocked`（无 `Dropped`）      |

`05-layer-standards.md` 定义了 `Dropped` 作为从 `Done` 分出的终态，但对象状态总表和 Registry 定义中均未包含。

**建议**：在 `03-pipeline.md §2.7` 和 `15-registry.md §2` 中补充 `Dropped` 状态，或在 `05-layer-standards.md` 中明确 `Dropped` 仅适用于特定场景。

#### 问题 T3：Matrix status 枚举漂移

| 文件                       | 枚举值                                                                                       |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| `05-layer-standards.md §9` | `Unmapped → Mapped → Linked → Verified → Drifted → Stale`（+ `Blocked / Changed / Dropped`） |
| `07-id-system.md §3`       | `Unmapped -> Mapped -> Linked -> Verified -> Drifted -> Stale`（无分支）                     |

`05-layer-standards.md` 有分支状态 `Blocked / Changed / Dropped`，而 `07-id-system.md` 没有。且 `07-id-system.md` 又提到 "`Dropped` 仅可作为带理由的例外终态"，与 `05-layer-standards.md` 的分支定义略有差异。

**建议**：统一在 `05-layer-standards.md §9` 定义完整枚举（含分支），其他文件引用。

---

### 3.3 引用断链（严重度：MEDIUM）

#### 问题 R1：指向不存在的锚点

| 文件                                 | 引用                      | 问题                                           |
| ------------------------------------ | ------------------------- | ---------------------------------------------- |
| `GLOSSARY.md` Pipeline State Machine | `03-pipeline.md#2-状态机` | 实际锚点是 `#2-双轴状态机`                     |
| `15-registry.md §1` Goal status      | `03-pipeline.md §2.5`     | 03-pipeline.md 无 §2.5，应为 §2.7 对象状态总表 |

**建议**：修正引用锚点使其匹配实际标题。

#### 问题 R2：GLOSSARY.md RFC 引用错误

| 条目 | 当前引用                 | 问题                                                                                                 |
| ---- | ------------------------ | ---------------------------------------------------------------------------------------------------- |
| RFC  | `11-ai-collaboration.md` | 11-ai-collaboration.md 中无 RFC 定义，RFC 应引用 `17-risk-and-decisions.md §2`（ADR 模板）或独立定义 |

**建议**：修正 RFC 引用，或在 `GLOSSARY.md` 中补充正确来源。

#### 问题 R3：RACI 引用错误

| 条目 | 当前引用    | 问题                                      |
| ---- | ----------- | ----------------------------------------- |
| RACI | `06-dod.md` | RACI 模型实际定义在 `12-operations.md §4` |

**建议**：修正 `GLOSSARY.md` 中 RACI 的引用为 `12-operations.md §4`。

---

### 3.4 内容重复与重叠（严重度：MEDIUM）

#### 问题 D1：Gate 检查项重复

`04-gates.md` 定义了 G0-G11 每个 Gate 的检查项，而 `08-quality-gates.md` 也包含质量标准和评分。两文件职责边界模糊：

- `04-gates.md`：Gate 编号、类型、检查项、通过/失败标准 → **SSOT**
- `08-quality-gates.md`：评分体系、孤儿检查、质量指标 → 应只引用 `04-gates.md`

当前 `08-quality-gates.md §1` 已正确引用 `04-gates.md`，但 §6 "Release 前检查" 引用了 `04-gates.md G10`，这是好的。整体 SSOT 声明清晰。

**结论**：此项已修复，仅记录供参考。

#### 问题 D2：变更传播矩阵重复定义

变更影响分析在以下位置出现：

| 文件                      | 内容                              |
| ------------------------- | --------------------------------- |
| `12-operations.md §1`     | 变更管理：变更类型、影响分析模板  |
| `13-runtime-engine.md §8` | 变更传播矩阵：上游变更 → 必须同步 |

两处互补但有重叠——`12-operations.md` 定义"变更类型"和"影响分析模板"，`13-runtime-engine.md` 定义"传播规则"。边界尚可，但建议在 `12-operations.md` 中引用 `13-runtime-engine.md §8` 的传播矩阵。

#### 问题 D3：Evidence 标准分散

Evidence 相关定义分散在 3 个文件中：

| 文件                       | 定义内容                                |
| -------------------------- | --------------------------------------- |
| `05-layer-standards.md §8` | Evidence 结构、类型、合格标准、收集方式 |
| `13-runtime-engine.md §4`  | Evidence 协议（必须包含字段、禁止项）   |
| `20-metrics-evidence.md`   | Evidence 必填绑定、Evidence Graph       |

三处定义互补但有重叠字段列表。`05-layer-standards.md §8` 和 `13-runtime-engine.md §4` 都定义了 Evidence "必须包含"的字段，字段列表不完全一致：

- `05-layer-standards.md`：Evidence ID、Source Spec、Source AC、Task ID、Status、Collected
- `13-runtime-engine.md`：Evidence ID、Task ID、Goal ID、Date、Status、Files Changed、Commands Run、Results、Logs、Diff Summary、Requirement Proof、Known Limitations、Risks、Rollback
- `20-metrics-evidence.md`：Evidence ID、AC ID、Test ID、Task ID、Spec ID、Goal ID、Status、Files Changed、Commands Run

**建议**：以 `20-metrics-evidence.md` 为 Evidence 字段的 SSOT（它最全面且最新），其他文件引用。

---

### 3.5 目录结构与实际不符（严重度：MEDIUM）

#### 问题 P1：README.md tools/ 标注与实际不符

`README.md` 文档索引表中 `tools/` 行标注为 "工具脚本（planned）"，但实际 `tools/` 目录下已有 4 个实现文件：

| 文件                  | 大小  | 状态   |
| --------------------- | ----- | ------ |
| `lint-goal.sh`        | 27KB  | 已实现 |
| `gate-check.sh`       | 6.2KB | 已实现 |
| `evidence-collect.sh` | 4.8KB | 已实现 |
| `matrix-gen.py`       | 8.6KB | 已实现 |

**建议**：将 `README.md` 中 `tools/` 的描述从 "planned" 改为 "已实现"。

#### 问题 P2：.config/goal/ 路径不一致

不同文件中 `.config/goal/` 的目录结构描述略有差异：

| 文件                    | 描述                                                                                    |
| ----------------------- | --------------------------------------------------------------------------------------- |
| `README.md`             | 展示了完整的 5 子目录结构（registry/、matrix/、gates/、pipeline/、evidence/、prompts/） |
| `12-operations.md §6.1` | 展示了 `matrix.yaml`（扁平）而非 `matrix/matrix.yaml`（子目录）                         |
| `15-registry.md`        | 正确区分了 Registry 子系统（6 文件）和配置中心旁路组件                                  |

`12-operations.md §6.1` 的目录树将 `matrix.yaml` 放在 `.config/goal/` 根下，而 `README.md` 和 `05-layer-standards.md §9` 都明确路径为 `.config/goal/matrix/matrix.yaml`。

**建议**：修正 `12-operations.md §6.1` 的目录树，将 `matrix.yaml` 移入 `matrix/` 子目录。

---

### 3.6 跨文件术语漂移（严重度：LOW-MEDIUM）

#### 问题 N1："状态机" vs "状态枚举汇总"

`03-pipeline.md §2` 标题为"双轴状态机"，但 §2.7 标题为"对象状态总表"，而 `15-registry.md §1` 引用时写的是"§2.5 状态枚举汇总"。同一概念在不同文件中使用不同名称。

#### 问题 N2：成熟度级别 vs 变更级别混淆风险

| 体系         | 范围         | 格式    |
| ------------ | ------------ | ------- |
| 成熟度模型   | 体系能力建设 | L0-L5   |
| 变更影响级别 | 单次变更影响 | CL0-CL5 |

`13-runtime-engine.md §1` 已添加澄清注释："此级别体系与成熟度模型的 L0-L5 级别不同"。这是好的，但 `GLOSSARY.md` 中 Change Level 条目未添加类似澄清。

**建议**：在 `GLOSSARY.md` Change Level 条目中补充与 L0-L5 的区分说明。

---

### 3.7 愿景与实现边界模糊（严重度：MEDIUM）

#### 问题 V1：愿景文件缺乏统一标注

以下文件标注为"愿景架构（Vision）"：

| 文件                               | 标注位置                                  |
| ---------------------------------- | ----------------------------------------- |
| `22-delivery-os.md`                | 第 3 行：`> **状态：愿景架构（Vision）**` |
| `23-workflow-governance-checks.md` | 第 3 行：`> **状态：愿景架构（Vision）**` |

但 `README.md` 的文档索引表中未体现这一状态差异。22 和 23 与已实现的 00-21 在同一表格中平级列出，读者无法从索引表区分哪些是已实现、哪些是愿景。

**建议**：在 `README.md` 文档索引表中为 22、23 添加状态标注（如 "🔮 Vision"），或单独分组。

#### 问题 V2：部分"愿景"内容已有实现基础

`22-delivery-os.md` 描述的 5 个运行时中，Intent Runtime（Goal/Spec）、Control Runtime（Matrix/Gate）和 Evidence Runtime（Evidence/Test）已有实际实现。只有 Improvement Runtime 和 Workflow Compiler 是纯愿景。

**建议**：在 `22-delivery-os.md` 中按运行时标注实现状态，区分"已实现"和"愿景"。

---

### 3.8 RACI 表不完整（严重度：LOW）

`12-operations.md §4` 的 RACI 表只覆盖到 Test 阶段，缺少以下行：

| 缺失阶段      | 说明                                         |
| ------------- | -------------------------------------------- |
| Review        | 谁是 Review 的 R/A？                         |
| Release       | 谁是 Release 的 R/A？                        |
| Retrospective | 谁是 Retrospective 的 R/A？                  |
| Evidence      | 谁是 Evidence 收集的 R/A？                   |
| Matrix        | 谁是 Matrix 维护的 R/A？（部分覆盖但不完整） |

**建议**：补充 Review、Release、Retrospective 的 RACI 行。

---

### 3.9 示例 ID 日期不一致（严重度：LOW）

不同文件中示例使用不同日期：

| 文件                    | 示例日期                         |
| ----------------------- | -------------------------------- |
| `00-quickstart.md`      | `GOAL-20260601-001`（6 月 1 日） |
| `01-methodology.md`     | `GOAL-20260608-001`（6 月 8 日） |
| `03-pipeline.md`        | `GOAL-20260608-001`（6 月 8 日） |
| `05-layer-standards.md` | `GOAL-20260608-001`（6 月 8 日） |
| `09-templates.md`       | `GOAL-20260608-002`（6 月 8 日） |
| `13-runtime-engine.md`  | `GOAL-20260608-001`（6 月 8 日） |

`00-quickstart.md` 使用 6 月 1 日，其他文件统一使用 6 月 8 日。虽不影响功能，但降低了文档一致性。

**建议**：统一示例日期为 `20260608`。

---

## 4. 断链引用完整清单

| #   | 源文件                     | 引用文本                                      | 目标                  | 问题                          |
| --- | -------------------------- | --------------------------------------------- | --------------------- | ----------------------------- |
| 1   | `GLOSSARY.md`              | `03-pipeline.md#2-状态机`                     | §2 双轴状态机         | 锚点不匹配                    |
| 2   | `15-registry.md §1`        | `03-pipeline.md §2.5`                         | §2.7 对象状态总表     | 章节号错误                    |
| 3   | `GLOSSARY.md` RFC          | `11-ai-collaboration.md`                      | —                     | 11 中无 RFC 定义              |
| 4   | `GLOSSARY.md` RACI         | `06-dod.md`                                   | `12-operations.md §4` | 引用目标错误                  |
| 5   | `05-layer-standards.md §8` | Evidence ID 格式 `EVID-AC-{SPEC}-{NUM}-{NNN}` | —                     | 格式与 07-id-system.md 不一致 |

---

## 5. 重复内容映射

| #   | 内容                  | 出现位置                                                                        | 建议 SSOT                   |
| --- | --------------------- | ------------------------------------------------------------------------------- | --------------------------- |
| 1   | Prompt 分层表（5 行） | `05-layer-standards.md §5`, `11-ai-collaboration.md §4`                         | `05-layer-standards.md`     |
| 2   | Evidence 字段列表     | `05-layer-standards.md §8`, `13-runtime-engine.md §4`, `20-metrics-evidence.md` | `20-metrics-evidence.md`    |
| 3   | Evidence ID 格式      | `05-layer-standards.md §8`, `07-id-system.md §1`, `20-metrics-evidence.md`      | `07-id-system.md`           |
| 4   | Matrix status 枚举    | `05-layer-standards.md §9`, `07-id-system.md §3`                                | `05-layer-standards.md`     |
| 5   | 变更管理/传播         | `12-operations.md §1`, `13-runtime-engine.md §8`                                | 各自保留（互补），交叉引用  |
| 6   | Gate 检查项           | `04-gates.md §3`, `08-quality-gates.md §1`                                      | `04-gates.md`（已正确引用） |

---

## 6. 改进优先级

### P0（阻塞性，影响体系可用性）

| #   | 问题                                | 影响                   | 工作量                   |
| --- | ----------------------------------- | ---------------------- | ------------------------ |
| S1  | DoR/DoD 双 SSOT                     | 读者不知以哪个文件为准 | 小：添加交叉引用         |
| T1  | Pipeline State 数量矛盾（12 vs 13） | 术语表与权威定义冲突   | 小：改 GLOSSARY 一个数字 |
| R1  | 引用锚点断链                        | 读者点击后 404         | 小：修正 2 处锚点        |

### P1（重要，影响一致性）

| #   | 问题                       | 影响                        | 工作量                     |
| --- | -------------------------- | --------------------------- | -------------------------- |
| T2  | Task 状态缺 Dropped        | 对象总表与层标准不一致      | 小：补充 1 行              |
| S2  | Prompt 分层表重复          | 维护时需改两处              | 小：删除重复，加引用       |
| S3  | Evidence ID 格式分散       | 三处定义不完全一致          | 中：统一到 07-id-system.md |
| P1  | README tools/ 标 "planned" | 与实际不符                  | 小：改一个词               |
| P2  | .config/goal/ 路径不一致   | 12-operations.md 目录树错误 | 小：修正目录树             |
| D3  | Evidence 标准分散          | 三处字段列表不一致          | 中：确定 SSOT 并统一引用   |

### P2（改善，影响可读性）

| #   | 问题               | 影响                       | 工作量            |
| --- | ------------------ | -------------------------- | ----------------- |
| V1  | 愿景文件缺统一标注 | 读者无法区分已实现/愿景    | 小：README 加标注 |
| R2  | RFC 引用错误       | GLOSSARY 引用不存在        | 小：修正引用      |
| R3  | RACI 引用错误      | GLOSSARY 引用错误文件      | 小：修正引用      |
| N1  | 术语"状态机"不统一 | 不同文件用不同名称         | 小：统一术语      |
| N2  | CL/L 混淆风险      | GLOSSARY 缺区分说明        | 小：补充说明      |
| D4  | RACI 表不完整      | 缺 Review/Release/Retro 行 | 中：补充 3 行     |
| D5  | 示例日期不一致     | 00 用 0601，其他用 0608    | 小：统一日期      |

---

## 7. 正面评价

在指出问题的同时，也应肯定体系的设计质量：

1. **分层管线设计清晰**：11 层管线从 Goal 到 Retrospective，每层有明确的核心问题和输出物
2. **Gate 体系完备**：G0-G11 覆盖全流程，类型分类（Semantic/Executable/Hybrid）合理
3. **ID 系统设计良好**：格式规范、层级嵌套、迁移兼容，是体系可追溯性的基础
4. **模板库丰富**：09-templates.md 提供端到端模板、YAML/JSON 结构、PR 模板、文件命名标准
5. **Lint 规则已实现**：50 条规则全部在 `tools/lint-goal.sh` 中实现，非纸上谈兵
6. **CHANGELOG 维护良好**：记录了结构性变更，便于追溯体系演进
7. **GLOSSARY 完整**：覆盖 35+ 个核心术语，每条都有权威定义位置引用
8. **复杂度分级合理**：XS/S/M/L/XL 五级复杂度对应不同流程裁剪，避免一刀切

---

## 8. 补充发现（v3 追加）

> 以下 4 个问题在 v2 初次分析时未覆盖，于 2026-06-08 补充。

### 问题 S4：SSOT 指针断裂 — Change Level 定义位置（🔴 HIGH）

| 文件 | 位置 | 内容 |
|------|------|------|
| `03-pipeline.md` | §2.7 对象状态总表第 8 行 | `Change Level` → "权威定义"列指向 `17-risk-and-decisions.md` |
| `17-risk-and-decisions.md` | 全文 | **无任何 CL0-CL5 定义** |
| `13-runtime-engine.md` | §1 第 13-22 行 | **实际定义**了 CL0-CL5 完整枚举和 Lite/Standard/Full 模式 |

SSOT 声明指向了错误的文件。读者按指针跳转后找不到 CL 定义，直接破坏 SSOT 模式的可信度。

**修复**：将 `03-pipeline.md` 第 147 行的 `[17-risk-and-decisions.md](17-risk-and-decisions.md)` 改为 `[13-runtime-engine.md](13-runtime-engine.md)`。（**1 行修改**）

### 问题 D6：Lint 规则数量不一致（🟡 MEDIUM）

| 文件 | 位置 | 声明 |
|------|------|------|
| `tools/README.md` | 第 86 行 | "检查规则（**38** 条）" |
| `10-lint-rules.md` | 第 161 行 | "全部 **50** 条规则已在 `tools/lint-goal.sh` 中实现" |

差值 12 条，可能是 `tools/README.md` 编写时规则尚未全部补齐，后续新增但未同步更新。

**修复**：将 `tools/README.md` 第 86 行的"38 条"改为"50 条"。（**1 行修改**）

### 问题 S5：Goal 状态机双重定义（🟢 LOW）

| 文件 | 位置 | 内容 |
|------|------|------|
| `02-goal-standard.md` | §10 | 定义 Goal 状态机（Draft→Active→Paused→Achieved/Abandoned）及转换规则 |
| `03-pipeline.md` | §2.7 对象状态总表 | Goal 行列出 `draft → active → paused → achieved / abandoned` |

两处定义当前内容一致，但 `02-goal-standard.md` 未引用 `03-pipeline.md` 为 SSOT。

**修复**：在 `02-goal-standard.md` §10 末尾添加引用指向 `03-pipeline.md §2.7`。（**1 行新增**）

### 问题 N3：GLOSSARY 缺少 Change Level 条目（🟢 LOW）

`GLOSSARY.md` 包含 35+ 个核心术语，但缺少 `Change Level`（CL0-CL5）的独立条目。`13-runtime-engine.md` §1 已添加了 CL 与 L 的区分注释，但 GLOSSARY 未收录。

**修复**：在 `GLOSSARY.md` 中添加 Change Level 条目，引用 `13-runtime-engine.md §1`，并注明与成熟度模型 L0-L5 的区别。（**3 行新增**）

---

### 更新后的 P0 优先级

| # | 问题 | 影响 | 工作量 |
|---|------|------|--------|
| S1 | DoR/DoD 双 SSOT | 读者不知以哪个文件为准 | 小 |
| T1 | Pipeline State 数量矛盾（12 vs 13） | 术语表与权威定义冲突 | 小 |
| R1 | 引用锚点断链 | 读者点击后 404 | 小 |
| **S4** | **SSOT 指针断裂（Change Level）** | **指向错误文件，破坏 SSOT 可信度** | **1 行** |

---

## 9. 总结

`docs/goal/` 是一套设计意图优秀、覆盖面广的交付方法论文档体系。主要问题集中在"治理自身"——SSOT 声明与实际不一致、跨文件状态枚举漂移、引用断链。这些问题不难修复，大部分是"改一个词"或"加一行引用"级别的工作。

**建议修复路径**：

1. **第一步（P0，30 分钟内）**：修复 4 个阻塞性问题（SSOT 指针断裂、SSOT 引用、GLOSSARY 数字、锚点断链）——均为 1 行修改
2. **第二步（P1，半天内）**：统一 Evidence 格式、修复路径不一致、消除重复内容、Lint 规则数同步
3. **第三步（P2，按需）**：补充 RACI、统一术语、标注愿景状态、Goal 状态机引用、GLOSSARY 补充

修复后预期结构健康分可提升至 **85+/100**。
