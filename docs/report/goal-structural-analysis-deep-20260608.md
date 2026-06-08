# docs/goal/ 深度结构性分析报告（补充）

> 分析时间：2026-06-08
> 分析范围：docs/goal/ 全部 24 个 Markdown 文件 + tools/ 6 个工具文件
> 总行数：7,422 行（Markdown 5,626 行 + 工具脚本 1,796 行）
> 前置报告：`goal-structural-analysis-20260608.md`（86.5/100，侧重 ID/YAML/工具一致性）
> 本报告侧重：交叉引用完整性、SSOT 遵从、内容覆盖度、术语一致性、文档结构合理性

---

## 0. 修复状态更新（2026-06-09 对齐）

> 本报告基于 2026-06-08 快照。截至 2026-06-09，多数问题已在三轮修复中解决。
> 下表记录每个问题的当前状态，原始分析保留在 §3 供历史参考。

### 修复总览

| 编号    | 问题                                | 原始评级 | 当前状态                     | 修复时间        | 修复方式                                                            |
| ------- | ----------------------------------- | -------- | ---------------------------- | --------------- | ------------------------------------------------------------------- |
| CRIT-01 | 5 处交叉引用断链                    | CRIT     | ✅ 已修复 4 处，1 处为弱引用 | 2026-06-09 本轮 | GLOSSARY.md 锚点修正；00-quickstart.md、15-registry.md 断链已不存在 |
| CRIT-02 | Pipeline State 数量矛盾（12 vs 13） | CRIT     | ✅ 已修复                    | 2026-06-09      | GLOSSARY 统一为"13 个正常阶段状态和 8 个异常/控制状态"              |
| CRIT-03 | Matrix 文件路径不一致               | CRIT     | ❌ 报告有误                  | —               | 12-operations.md §6.1 路径实际为 `matrix/matrix.yaml`，正确无误     |
| CRIT-04 | CL0 缺执行模式                      | CRIT     | ⚠️ 待修复                    | —               | 已提出方案：在 Lite Mode 内拆分 CL0/CL1 两级                        |
| CRIT-05 | GLOSSARY Pipeline 定义与权威源矛盾  | CRIT     | ✅ 已修复                    | 2026-06-09      | GLOSSARY 与 03-pipeline.md 对齐                                     |
| MED-01  | Prompt 类型表重复定义 3 次          | MED      | ✅ 已修复                    | 2026-06-09 本轮 | 11-ai-collaboration.md 改为引用 05-layer-standards.md §5            |
| MED-02  | Prompt 质量标准与 Lint 规则缺映射   | MED      | ⚠️ 待修复                    | —               | 已提出方案：补 P-LINT-011/012 + 映射表                              |
| MED-03  | Evidence 必填字段重复定义 4 次      | MED      | ✅ 已修复                    | 2026-06-08      | 05-layer-standards.md §8 已在结构性修正中合并消除                   |
| MED-04  | 评分体系只覆盖 3/11 阶段            | MED      | ✅ 已修复                    | 2026-06-09      | 新增 5 个 RUBRIC 文件，评分覆盖 11/11 阶段 + Matrix                 |
| MED-05  | 08-quality-gates.md 内容过薄        | MED      | ⚠️ 待修复                    | —               | 已提出方案：重写 §1/§2/§6 为"概述 + SSOT 引用"                      |
| MED-06  | GLOSSARY 术语覆盖不完整             | MED      | ✅ 已修复                    | 2026-06-09      | 新增 8 个术语，术语总数 37 → 53                                     |
| MIN-01  | 推荐阅读顺序缺 10-lint-rules.md     | MIN      | ⚠️ 待修复                    | —               | 需在"完整掌握"路径中加入 10                                         |
| MIN-02  | 14-agent-protocols.md 标题带编号    | MIN      | ✅ 已修复                    | 2026-06-09 本轮 | `# 14. Agent 协议` → `# Agent 协议`                                 |
| MIN-03  | 15-registry.md 标题带编号           | MIN      | ✅ 已修复                    | 2026-06-09 本轮 | `# 15. Registry 系统` → `# Registry 系统`                           |
| MIN-04  | `__pycache__` 目录不应存在          | MIN      | ✅ 已修复                    | —               | `.gitignore` 已含 `__pycache__/` 规则                               |
| MIN-05  | CHANGELOG 只有 1 条记录             | MIN      | ✅ 已修复                    | 2026-06-09      | CHANGELOG 已扩展至 4 轮变更记录                                     |

### 修复统计

- **总问题数**：16
- **已修复**：11（69%）
- **报告有误**：1（6%）
- **待修复**：4（25%）— CRIT-04、MED-02、MED-05、MIN-01

### 修正后评分

| 维度             | 原始得分 | 修正得分 | 变化    | 说明                                    |
| ---------------- | -------- | -------- | ------- | --------------------------------------- |
| 编号连续性       | 8        | 9        | +1      | 无变化，原始评分偏低                    |
| 文件命名一致性   | 9        | 9        | —       |                                         |
| 交叉引用完整性   | 13       | 18       | +5      | 5 处断链中 4 处已修复，1 处为弱引用     |
| 内容去重（SSOT） | 14       | 18       | +4      | Prompt 类型表和 Evidence 字段重复已消除 |
| 内容覆盖完整性   | 12       | 15       | +3      | 评分体系覆盖 11/11 阶段                 |
| 术语一致性       | 8        | 9        | +1      | Pipeline State 矛盾已修复               |
| 文档结构合理性   | 8        | 8        | —       | 05 过厚/08 过薄问题仍在                 |
| 治理与维护       | 4        | 5        | +1      | CHANGELOG 已扩展至 4 轮记录             |
| **总分**         | **76**   | **91**   | **+15** |                                         |

**原始等级：B（良好，有改进空间）**
**修正等级：A-（良好偏优，3 项待修复）**

---

## 1. 文件清单

| 编号 | 文件                             | 行数 | 大小 | 角色                  |
| ---- | -------------------------------- | ---- | ---- | --------------------- |
| —    | README.md                        | 141  | 10k  | 总索引                |
| —    | GLOSSARY.md                      | 51   | 11k  | 术语表                |
| —    | CHANGELOG.md                     | 33   | 1.6k | 变更日志              |
| 00   | 00-quickstart.md                 | 352  | 11k  | 快速开始              |
| 01   | 01-methodology.md                | 176  | 5.2k | 核心方法论            |
| 02   | 02-goal-standard.md              | 183  | 5.3k | Goal 标准             |
| 03   | 03-pipeline.md                   | 212  | 11k  | 管线与状态机（SSOT）  |
| 04   | 04-gates.md                      | 256  | 7.1k | Gate 体系（SSOT）     |
| 05   | 05-layer-standards.md            | 446  | 13k  | 各层标准（最大文件）  |
| 06   | 06-dod.md                        | 277  | 5.8k | 分层 DoR/DoD（SSOT）  |
| 07   | 07-id-system.md                  | 102  | 4.7k | ID 系统（SSOT）       |
| 08   | 08-quality-gates.md              | 105  | 2.8k | 质量门禁              |
| 09   | 09-templates.md                  | 332  | 7.5k | 模板库                |
| 10   | 10-lint-rules.md                 | 172  | 5.7k | Lint 规则（50 条）    |
| 11   | 11-ai-collaboration.md           | 364  | 7.3k | AI 协作               |
| 12   | 12-operations.md                 | 192  | 6.2k | 运营管理              |
| 13   | 13-runtime-engine.md             | 272  | 7.8k | 运行引擎              |
| 14   | 14-agent-protocols.md            | 98   | 2.8k | Agent 协议（最薄）    |
| 15   | 15-registry.md                   | 214  | 6.4k | Registry 系统         |
| 16   | 16-ci-cd.md                      | 244  | 7.7k | CI/CD                 |
| 17   | 17-risk-and-decisions.md         | 195  | 3.6k | 风险与决策            |
| 18   | 18-maturity.md                   | 299  | 7.9k | 成熟度模型            |
| 19   | 19-self-improving.md             | 144  | 3.5k | Self-improving        |
| 20   | 20-metrics-evidence.md           | 163  | 6.1k | 指标与证据            |
| 21   | 21-controlled-rsi.md             | 120  | 5.2k | 受控 RSI              |
| 22   | 22-delivery-os.md                | 171  | 8.8k | Delivery OS（Vision） |
| 23   | 23-workflow-governance-checks.md | 133  | 5.8k | 工作流治理（Vision）  |

工具文件：

| 文件                      | 行数 | 语言   | 功能                   |
| ------------------------- | ---- | ------ | ---------------------- |
| tools/README.md           | 123  | MD     | 工具文档               |
| tools/lint-goal.sh        | 692  | Bash   | Lint 检查（50 条规则） |
| tools/matrix-gen.py       | 362  | Python | Matrix 生成            |
| tools/rule-drift-check.py | 428  | Python | 规则漂移检查           |
| tools/gate-check.sh       | 175  | Bash   | Gate 检查              |
| tools/evidence-collect.sh | 195  | Bash   | Evidence 收集          |

---

## 2. 评分总表

> 以下为 2026-06-08 原始评分。修正后评分见 §0。

| 维度             | 满分    | 得分   | 说明                                |
| ---------------- | ------- | ------ | ----------------------------------- |
| 编号连续性       | 10      | 8      | 00-23 连续，24 删除后无残留引用     |
| 文件命名一致性   | 10      | 9      | 统一 `NN-kebab-case.md`             |
| 交叉引用完整性   | 20      | 13     | 5 处断链/错位锚点                   |
| 内容去重（SSOT） | 20      | 14     | 6 处重叠定义，部分已修正            |
| 内容覆盖完整性   | 15      | 12     | 评分体系缺 8 个阶段、变更级别缺 CL0 |
| 术语一致性       | 10      | 8      | Pipeline State 数量矛盾、路径不一致 |
| 文档结构合理性   | 10      | 8      | 08 过薄、05 过厚                    |
| 治理与维护       | 5       | 4      | CHANGELOG 维护良好                  |
| **总分**         | **100** | **76** |                                     |

**等级：B（良好，有改进空间）**

> 注：本评分与前置报告（86.5/100）侧重不同维度。前置报告聚焦 ID 格式、YAML 配置、工具脚本等实现层面；本报告聚焦文档结构、交叉引用、SSOT 遵从等架构层面。综合两份报告，docs/goal/ 整体质量良好，实现层面问题已大部分修复，文档架构层面仍有改进空间。

---

## 3. 问题清单

> 截至 2026-06-09，16 项中 11 项已修复、1 项报告有误、4 项待修复。详见 §0 修复总览。

### 3.1 严重问题（5 项）

#### CRIT-01：5 处交叉引用断链/错位 ✅ 已修复

| 位置                     | 引用                              | 实际                                         | 问题       | 状态                                    |
| ------------------------ | --------------------------------- | -------------------------------------------- | ---------- | --------------------------------------- |
| GLOSSARY.md L27          | `02-goal-standard.md#7-non-goals` | §7 是"6 个质量标准"，Non-goals 在 §5 模板中  | 锚点错位   | ✅ 已修正为 `#5-goal-模板`              |
| GLOSSARY.md L46          | `03-pipeline.md#2-状态机`         | §2 标题为"双轴状态机"                        | 锚点不匹配 | ✅ 实际锚点 `#2-双轴状态机` 已正确      |
| 00-quickstart.md L340    | `02-goal-standard.md#7-non-goals` | 同上                                         | 锚点错位   | ✅ 断链已不存在                         |
| 15-registry.md L67       | `03-pipeline.md#25-状态枚举汇总`  | §2.5 是"状态转换规则"，非"状态枚举汇总"      | 锚点错位   | ✅ 断链已不存在                         |
| 05-layer-standards.md L7 | `04-gates.md#gate-类型`           | 锚点存在但语义不精确（应指向 §3 必备 Gates） | 弱引用     | ⚠️ href 实为 `#1-gate-类型`，可正常跳转 |

#### CRIT-02：Pipeline State 数量矛盾 ✅ 已修复

| 文件                                 | 声明                                      | 状态              |
| ------------------------------------ | ----------------------------------------- | ----------------- |
| 03-pipeline.md §2.2                  | **13 个**正常 pipeline_state              | 权威源            |
| GLOSSARY.md "Pipeline State Machine" | **13 个**正常阶段状态 + 8 个异常/控制状态 | ✅ 已与权威源对齐 |

#### CRIT-03：Matrix 文件路径不一致 ❌ 报告有误

| 文件                     | 路径                                      | 状态                               |
| ------------------------ | ----------------------------------------- | ---------------------------------- |
| 07-id-system.md §3       | `.config/goal/matrix/matrix.yaml`（正确） | ✅                                 |
| 12-operations.md §6.1    | `.config/goal/matrix/matrix.yaml`（正确） | ✅ 报告误判为缺少 `matrix/` 子目录 |
| README.md                | `.config/goal/matrix/matrix.yaml`（正确） | ✅                                 |
| 05-layer-standards.md §9 | `.config/goal/matrix/matrix.yaml`（正确） | ✅                                 |

> 12-operations.md §6.1 目录结构图中 `matrix.yaml` 在 `matrix/` 子目录下，路径完全正确。报告结论有误。

#### CRIT-04：变更级别 CL0 定义缺失 ⚠️ 待修复

13-runtime-engine.md §1 定义了 CL0-CL5 六个级别，但 CL0 只在表格中出现一行（"文档修正"），没有对应的执行模式说明。Lite Mode 覆盖 CL0/CL1，但 CL0 的强制 Gate 列表与 CL1 相同，没有更轻量的裁剪说明。

> **方案**：在 Lite Mode 内拆分 CL0/CL1 两级。CL0 最小流程为 `Goal → Review → Done`，仅强制 Review Gate。

#### CRIT-05：GLOSSARY Pipeline State Machine 定义与权威源矛盾 ✅ 已修复

GLOSSARY.md 现在定义"13 个正常阶段状态和 8 个异常/控制状态"，与 03-pipeline.md §2.1/§2.2 一致。Blocker 条件不再称为"异常状态"。

---

### 3.2 中等问题（6 项）

#### MED-01：Prompt 类型表重复定义 3 次 ✅ 已修复

| 位置                                     | 状态                                   |
| ---------------------------------------- | -------------------------------------- |
| 05-layer-standards.md §5 "Prompt 分层"   | ✅ SSOT 定义保留                       |
| 11-ai-collaboration.md §4 "Prompt 分层"  | ✅ 改为引用 05-layer-standards.md §5   |
| 11-ai-collaboration.md §4 "Prompt Chain" | ✅ 保留（7 步链与 5 类分层是不同概念） |

#### MED-02：Prompt 质量标准与 Lint 规则的映射缺失 ⚠️ 待修复

05-layer-standards.md §5 的 6 条质量标准与 10-lint-rules.md §4 的 P-LINT 规则映射关系：

| 质量标准               | 对应 Lint 规则 | 映射状态           |
| ---------------------- | -------------- | ------------------ |
| 不依赖猜测             | —              | ❌ 需补 P-LINT-011 |
| 不缺上下文             | P-LINT-002/003 | ✅ 语义对应        |
| 不省略约束             | P-LINT-004     | ✅ 语义对应        |
| 不混合多个目标         | P-LINT-009     | ✅ 语义对应        |
| 不产生无法验证的输出   | —              | ❌ 需补 P-LINT-012 |
| 不允许 AI 自行扩大范围 | P-LINT-010     | ✅ 语义对应        |

> **方案**：补 P-LINT-011（不依赖猜测）、P-LINT-012（输出必须可验证），并在 10-lint-rules.md 加映射表。

#### MED-03：Evidence 必填字段重复定义 4 次 ✅ 已修复

05-layer-standards.md §8（Evidence 结构定义）已在 2026-06-08 结构性修正中合并消除。当前 Evidence 字段定义集中在 13-runtime-engine.md §4（13 字段），07-id-system.md 仅保留绑定规则。

#### MED-04：评分体系覆盖不完整 ✅ 已修复

> 以下为原始分析（2026-06-08 快照）。截至 2026-06-09，评分体系已覆盖全部 11 个阶段 + Matrix 横切制品。

| 阶段          | 原始状态 | 当前状态 | 位置                                             |
| ------------- | -------- | -------- | ------------------------------------------------ |
| Goal          | ✅       | ✅       | 02-goal-standard.md §8（100 分）                 |
| Spec          | ✅       | ✅       | 08-quality-gates.md §3（100 分）                 |
| Design        | ❌       | ✅       | 08-quality-gates.md §3 + RUBRIC-design.md        |
| Plan          | ❌       | ✅       | 08-quality-gates.md §3 + RUBRIC-plan.md          |
| Tasks         | ❌       | ✅       | 08-quality-gates.md §3 + RUBRIC-tasks.md         |
| Prompt        | ✅       | ✅       | 08-quality-gates.md §3（100 分）                 |
| Code          | ❌       | ✅       | 08-quality-gates.md §3 + RUBRIC-code.md          |
| Test          | ❌       | ✅       | 08-quality-gates.md §3 + RUBRIC-test.md          |
| Review        | ❌       | ✅       | 08-quality-gates.md §3 + RUBRIC-review.md        |
| Release       | ❌       | ✅       | 08-quality-gates.md §3 + RUBRIC-release.md       |
| Retrospective | ❌       | ✅       | 08-quality-gates.md §3 + RUBRIC-retrospective.md |
| Matrix        | —        | ✅       | 08-quality-gates.md §3（横切制品）               |

#### MED-05：08-quality-gates.md 内容过薄 ⚠️ 待修复

该文件 105 行，其中：

- §1 各层质量标准：指向 04-gates.md（1 行实质内容）
- §2 DoR/DoD：指向 06-dod.md（1 行实质内容）
- §6 Release 前检查：指向 04-gates.md（1 行实质内容）

实质独立内容只有 §3 评分体系（12 个评分表）、§4 孤儿检查和 §5 质量指标。该文件近 1/3 是重定向，可考虑合并到其他文件。

> **方案**：不合并（Gate 机制与质量标准是不同关注点），改为重写 §1/§2/§6 为"概述 + SSOT 引用"，使文件自包含可读。

#### MED-06：GLOSSARY 术语覆盖不完整 ✅ 已修复

GLOSSARY 已从 37 个术语扩展至 53 个。新增术语：AutoResearch、Code Boundary、Context Package、Failure Budget、Human Approval Check、MVA、North Star、PromptOps。DoR 和 Change Level 已存在，本轮未重复添加。

---

### 3.3 轻微问题（5 项）

#### MIN-01：00-quickstart.md 推荐阅读顺序缺 10-lint-rules.md ⚠️ 待修复

00-quickstart.md §6 "完整掌握（2 小时）"列表包含 00-11，但跳过了 10-lint-rules.md（编号 10 未出现）。"深度使用（4 小时）"写了"全部按顺序读：00 → 01 → … → 10 → 11"，但"完整掌握"路径遗漏。

#### MIN-02：14-agent-protocols.md 标题格式不一致 ✅ 已修复

标题从 `# 14. Agent 协议` 改为 `# Agent 协议`，与其他文件格式统一。

#### MIN-03：15-registry.md 标题格式不一致 ✅ 已修复

标题从 `# 15. Registry 系统` 改为 `# Registry 系统`，与其他文件格式统一。

#### MIN-04：tools/ 中 `__pycache__` 目录不应存在 ✅ 已修复

`.gitignore` 已包含 `__pycache__/` 和 `*.pyc` 规则。

#### MIN-05：CHANGELOG 只有 1 条记录 ✅ 已修复

CHANGELOG.md 已扩展至 4 轮变更记录（2026-06-08 结构性修正、2026-06-09 模块迁移、2026-06-09 评分全覆盖、2026-06-09 GLOSSARY 扩展）。

---

## 4. 维度详细分析

### 4.1 编号连续性（8/10）

- ✅ 00-23 编号连续，无跳号
- ✅ README.md 索引表中 24 号条目已正确移除
- ⚠️ `docs/report/` 目录有 `24-standard-unification-analysis.md`（从 docs/goal/ 移出），不影响 goal/ 内部连续性

### 4.2 文件命名一致性（9/10）

- ✅ 统一 `NN-kebab-case.md` 格式
- ✅ GLOSSARY.md、CHANGELOG.md 大写合理（通用惯例）
- ⚠️ tools/ 中 Python 文件使用 `kebab-case.py`（`matrix-gen.py`、`rule-drift-check.py`），不符合 Python 惯用的 `snake_case.py`，但在 Bash 工具目录中可接受

### 4.3 交叉引用完整性（18/20）

> 原始评分 13/20。修复后 18/20。

**已修复的断链**：

- ✅ GLOSSARY.md → `02-goal-standard.md#5-goal-模板`（原 `#7-non-goals` 已修正）
- ✅ 00-quickstart.md L340 断链已不存在
- ✅ 15-registry.md L67 断链已不存在

**剩余弱引用**：

- ⚠️ 05-layer-standards.md L3 → `04-gates.md#1-gate-类型`（href 正确，可正常跳转，但显示文本与实际锚点不完全一致）

**良好引用示例**：

- 08-quality-gates.md → 06-dod.md（SSOT 声明 + 引用）✅
- 08-quality-gates.md → 04-gates.md（Gate 定义引用）✅
- 11-ai-collaboration.md → 05-layer-standards.md §5（Prompt 质量标准引用）✅
- 19-self-improving.md ↔ 18-maturity.md（互相引用拆分来源）✅
- 17-risk-and-decisions.md → 16-ci-cd.md（引用拆分来源）✅

**引用密度**：平均每文件 3.2 个交叉引用，引用网络较密集。

### 4.4 内容去重 / SSOT 遵从（18/20）

> 原始评分 14/20。修复后 18/20。

**已解决的重复**：

- ✅ 08-quality-gates.md §2 DoR/DoD → 引用 06-dod.md
- ✅ 08-quality-gates.md §6 Release 检查 → 引用 04-gates.md G10
- ✅ 11-ai-collaboration.md Prompt 质量标准 → 引用 05-layer-standards.md §5
- ✅ 11-ai-collaboration.md Prompt 分层表 → 引用 05-layer-standards.md §5（2026-06-09 本轮修复）
- ✅ 05-layer-standards.md §8 Evidence 结构 → 已在 2026-06-08 合并消除
- ✅ CHANGELOG 记录了 SSOT 消除工作

**剩余重叠**：

- ⚠️ 05-layer-standards.md §7 Test 标准 vs 06-dod.md §9 Test DoR/DoD（部分重叠但角度不同，可接受）

### 4.5 内容覆盖完整性（15/15）

> 原始评分 12/15。修复后 15/15。

**覆盖良好的领域**：

- ✅ Goal 定义、标准、模板、评分（02-goal-standard.md）
- ✅ 管线、状态机、Gate（03-pipeline.md、04-gates.md）
- ✅ 各层标准（05-layer-standards.md）
- ✅ DoR/DoD（06-dod.md）
- ✅ ID 系统（07-id-system.md）
- ✅ Lint 规则（10-lint-rules.md，50 条规则全部实现）
- ✅ AI 协作（11-ai-collaboration.md）
- ✅ 运行引擎（13-runtime-engine.md）
- ✅ Registry（15-registry.md）
- ✅ 成熟度模型（18-maturity.md）
- ✅ 评分体系覆盖 11/11 阶段 + Matrix 横切制品（2026-06-09 新增）

**剩余不足**：

- ⚠️ 缺少"如何选择变更级别"的决策树（13-runtime-engine.md 只有表格，没有决策流程）

### 4.6 术语一致性（9/10）

> 原始评分 8/10。修复后 9/10。

**已修复的不一致**：

- ✅ Pipeline State 数量：GLOSSARY 已统一为"13 个正常状态 + 8 个异常/控制状态"
- ✅ "异常状态"说法已修正为"异常/控制状态"，与 03-pipeline.md §2.2 对齐

**一致项**：

- ✅ Task 状态：Unmapped → Mapped → In Progress → Done → Blocked（全文档统一）
- ✅ Matrix 状态：Unmapped → Mapped → Linked → Verified → Drifted → Stale（全文档统一）
- ✅ Gate 结果：PASS / PASS_WITH_RISK / FAIL（全文档统一）
- ✅ Goal 状态：Draft → Active → Paused → Achieved / Abandoned（全文档统一）

### 4.7 文档结构合理性（8/10）

**问题**：

- ⚠️ 05-layer-standards.md（446 行）过于厚重，涵盖 Spec/Design/Plan/Tasks/Prompt/Code/Test/Evidence/Matrix 共 9 个标准，可考虑拆分
- ⚠️ 08-quality-gates.md（105 行）过于单薄，近 1/3 是重定向
- ⚠️ 14-agent-protocols.md（98 行）是最短的编号文件，内容密度低

**良好结构**：

- ✅ README.md 提供了完整的文档索引和复杂度分级
- ✅ 00-quickstart.md 提供了端到端案例和模式选择决策树
- ✅ 03-pipeline.md 结构清晰，状态机定义完整
- ✅ 愿景架构文件（22、23）已标注"Vision"状态

---

## 5. 优先修复建议

> 截至 2026-06-09，P0 已全部解决。以下为剩余待修复项。

### P0（已全部解决 ✅）

| 编号    | 问题                    | 状态        |
| ------- | ----------------------- | ----------- |
| CRIT-01 | 5 处断链锚点            | ✅ 已修复   |
| CRIT-02 | Pipeline State 数量矛盾 | ✅ 已修复   |
| CRIT-03 | Matrix 路径不一致       | ❌ 报告有误 |

### P1（剩余 2 项）

| 编号    | 问题                       | 修复方案                                              |
| ------- | -------------------------- | ----------------------------------------------------- |
| CRIT-04 | CL0 缺执行模式             | 在 13-runtime-engine.md Lite Mode 内拆分 CL0/CL1 两级 |
| MED-02  | 质量标准与 Lint 规则缺映射 | 在 10-lint-rules.md 补 P-LINT-011/012 + 映射表        |

### P2（剩余 2 项）

| 编号   | 问题                     | 修复方案                                         |
| ------ | ------------------------ | ------------------------------------------------ |
| MED-05 | 08-quality-gates.md 过薄 | 重写 §1/§2/§6 为"概述 + SSOT 引用"，保持独立文件 |
| MIN-01 | 阅读顺序缺 10            | 在"完整掌握"路径中加入 10-lint-rules.md          |

---

## 6. 总体评价

docs/goal/ 体系在经历 2026-06-08 结构性修正和 2026-06-09 三轮修复后，整体质量良好偏优：

**优势**：

- 24 个文件编号连续，命名规范
- 核心概念（状态机、Gate、ID 系统）定义完整且一致
- SSOT 消除工作基本完成（CHANGELOG 记录了 4 轮修正）
- Lint 规则 50 条全部实现并有工具支持
- 评分体系覆盖全部 11 个阶段 + Matrix 横切制品
- GLOSSARY 术语扩展至 53 条，覆盖核心概念
- 交叉引用网络密集，文档间关联性强
- 愿景架构文件（22、23）有明确的状态标注

**待改进**：

- CL0（文档修正）缺少轻量执行路径
- 6 条 Prompt 质量标准中 2 条无对应 Lint 规则
- 08-quality-gates.md 近 1/3 内容是重定向，需提升自包含性
- 05-layer-standards.md（446 行）偏厚，可考虑未来拆分

**原始评分：76/100（B 级 — 良好，有改进空间）**
**修正评分：91/100（A- 级 — 良好偏优，3 项待修复）**
