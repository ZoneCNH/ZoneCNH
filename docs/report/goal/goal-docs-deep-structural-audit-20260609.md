# docs/goal 深度结构分析报告

分析日期：2026-06-09
分析范围：`docs/goal/`、`docs/goal/tools/`、`.config/goal/` 样例配置与状态文件
报告目标：识别文档体系问题、结构性问题，并给出可执行评分与修复优先级。

定位说明：`goal-docs-structural-analysis-20260609.md` 是本目录主审计报告；本报告作为工具、`.config/goal` 样例和运行态边界的补充审计，不单独取代主报告结论。

## 1. 总体结论

`docs/goal/` 已经形成完整的 Goal 驱动交付知识库：从 Goal、Spec、Design、Plan、Tasks、Prompt、Code、Test、Review、Release 到 Retrospective 均有覆盖，且配套了 lint、gate、matrix、evidence、rule-drift 等工具。

但当前体系的核心问题不是“缺文档”，而是“权威过多、状态过多、契约未闭合”。机器检查能通过，主要说明当前样例配置与脚本规则一致；它不能证明 28 份顶层 Goal Markdown 文档之间已经形成单一、可执行、无歧义的标准。

综合评分：**66 / 100**

判断：可以作为治理体系草案和人工执行参考；不宜直接宣称为稳定的、完全可机器执行的 Goal Delivery OS。

## 2. 评分明细

| 维度                   | 权重   | 得分   | 主要判断                                                    |
| ---------------------- | ------ | ------ | ----------------------------------------------------------- |
| 覆盖完整度             | 10%    | 84     | 主流程、Gate、ID、Matrix、Evidence、CI、Registry 均有文档。 |
| 权威边界 / SSOT        | 20%    | 58     | 多个文件同时承担“唯一规则源”角色，规则层级未收敛。          |
| 流程与状态机一致性     | 15%    | 62     | README、03、12、13、rules.yaml 的流程粒度不一致。           |
| ID / 版本 / 命名一致性 | 15%    | 57     | Spec、Design、Prompt、Evidence 格式在文档和工具中存在漂移。 |
| Matrix / Evidence 契约 | 15%    | 66     | 有结构和工具，但字段、状态、覆盖阈值和证明深度不一致。      |
| Gate / 质量阈值        | 10%    | 72     | G0-G11 框架清楚，但阈值来源分散，PASS 语义偏弱。            |
| 工具与 CI 可执行性     | 10%    | 76     | 工具可运行且当前样例通过，但校验面窄于文档承诺。            |
| 信息架构与维护性       | 5%     | 70     | 文档体系丰富，但历史分析、愿景文档和规范正文混放。          |

加权得分：**66.05，取整 66 / 100**。

## 3. 验证证据

已执行的验证：

| 命令                                                                                          | 结果                           | 解读                                                                 |
| --------------------------------------------------------------------------------------------- | ------------------------------ | -------------------------------------------------------------------- |
| `bash docs/goal/tools/lint-goal.sh docs/goal`                                                 | 通过，0 error / 0 warning      | 当前 lint 规则未发现问题。                                           |
| `python3 docs/goal/tools/rule-drift-check.py --root .`                                        | 通过                           | `.config/goal/schema/rules.yaml` 与当前样例、CI、脚本常量一致。      |
| `python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml` | 通过，Matrix 覆盖率 100%       | 当前样例矩阵闭合。                                                   |
| `bash docs/goal/tools/gate-check.sh .`                                                        | 通过，PASS=7 / FAIL=0 / WARN=0 | 当前样例 Gate 检查闭合。                                             |
| `bash -n docs/goal/tools/*.sh` 等价分项检查                                                   | 通过                           | Shell 脚本语法无错误。                                               |
| `python3 -m py_compile docs/goal/tools/matrix-gen.py docs/goal/tools/rule-drift-check.py`     | 通过                           | Python 脚本可编译。                                                  |
| `git ls-files .config/goal`                                                                   | 空输出                         | `.config/goal` 当前没有被 Git 跟踪，文档中的“配置中心”边界需要明确。 |

关键限制：以上验证证明“当前样例和脚本一致”，不证明“文档体系自身无冲突”。结构性问题需要通过跨文档比对判断。

## 4. P1 决策级结构问题（原 P0 校准）

### P1-D01：权威源过多，SSOT 没有真正闭合

证据：

- `docs/goal/03-pipeline.md` 声明 Pipeline state enum 是 SSOT。
- `docs/goal/04-gates.md` 声明 G0-G11 是 Gate 权威。
- `.config/goal/schema/rules.yaml` 又声明自己是 Goal 规则 SSOT，并引用 03 / 04 / 07 / 15；但当前 `.config/goal` 未被 Git 跟踪，不能在不说明边界的情况下承担跨人协作权威。
- `docs/goal/24-standard-unification-analysis.md` 已经指出存在多个半权威源，并给出 66/100 的结构统一分。
- `docs/goal/README.md` 将 `docs/goal/` 描述为总览入口，但同时把 `.config/goal/` 作为统一配置中心。

影响：

当 ID、状态、阈值、字段或 Gate 语义冲突时，没有一个明确的裁决路径。后续维护者不知道应修改文档、`.config/goal/schema/rules.yaml`，还是工具脚本。

建议：

1. 先裁决权威路线：`docs-first`（Markdown 规范为权威，`rules.yaml` 由规范生成/校验）或 `rules-first`（机器规则为权威，Markdown 引用解释）。
2. 无论选择哪条路线，都保留 `docs/goal/README.md` 作为人类入口和导航索引。
3. 03 / 04 / 07 / 15 只声明本领域裁决范围或引用统一裁决源，避免互相竞争 SSOT。
4. `24-standard-unification-analysis.md` 从主规范索引中移出，放入 `docs/report/goal/` 或标记为历史审计。

### P1-D02：Pipeline 状态机存在“双状态机”漂移

证据：

- `docs/goal/03-pipeline.md` 使用粗粒度阶段态：`INIT`、`CONTEXT_READY`、`GOAL_READY`、`SPEC_READY`、`DESIGN_READY`、`PLAN_READY`、`TASKS_READY`、`EXECUTING`、`VERIFYING`、`REVIEWING`、`RELEASING`、`RETROSPECTING`、`DONE`，并定义一组异常态。
- `.config/goal/schema/rules.yaml` 使用更细的活动/审批态：`GOAL_DRAFTING`、`GOAL_REVIEWING`、`GOAL_APPROVED`、`SPEC_DRAFTING`、`SPEC_REVIEWING`、`SPEC_APPROVED`、`DESIGNING`、`PLAN_APPROVED`、`CODING`、`TESTING` 等。
- `.config/goal/pipeline/state.yaml` 当前是未入库的本地样例/运行态文件，不能直接作为项目级契约。
- `docs/goal/13-runtime-engine.md` 又引入 change level、runtime mode、STALE / NEEDS_REPLAN 等传播规则。

影响：

文档读者会以为 03 是状态机权威，但实际运行样例走的是 `rules.yaml` 细粒度状态。工具、Agent 和人工流程很容易在“阶段状态”和“对象状态”之间混用。

建议：

1. 不要直接把所有状态合并为一个枚举；先区分 `pipeline_state`、`phase_state`、`goal_status`、`issue_status` 和运行态派生标记。
2. 将 `03-pipeline.md` 的粗粒度阶段态与 `rules.yaml` 的细粒度活动态建立映射表。
3. 将 STALE / NEEDS_REPLAN 作为派生标记或异常转移原因，避免混入 Pipeline 主状态。

### P1-D03：ID 与版本格式未统一

证据：

- `docs/goal/07-id-system.md` 定义 `SPEC-<domain>-vN`、`DESIGN-<domain>-vN`、`PROMPT-<task-id>-NNN`。
- `docs/goal/05-layer-standards.md` 定义 `SPEC-<domain>-v<major>.<minor>`、`DESIGN-<domain>-v<major>.<minor>`，Prompt 示例又使用 `P-XXX`。
- `docs/goal/09-templates.md` 同时出现 `SPEC-<domain>-v1` 与 `DESIGN-<domain>-v1.0`。
- `docs/goal/tools/matrix-gen.py` 的正则只识别 `SPEC-...-v\d+`，不识别 `v1.0`。
- `.config/goal/schema/rules.yaml` 中 Evidence ID pattern 与 `docs/goal/tools/evidence-collect.sh` 的生成逻辑需要保持严格同步。

影响：

同一个对象在不同层使用不同 ID 语法，Matrix、Evidence、Prompt 和 Gate 的自动校验会出现假阴性或假阳性。尤其是 `v1` 与 `v1.0` 混用，会让文档看似合理、工具却无法识别。

建议：

1. 统一版本格式：选择 `v1` 或 `v1.0`，并一次性同步 05、07、09、tools、rules.yaml。
2. 禁止模板中出现旧格式占位符，例如 `P-XXX`。
3. 增加 ID 格式 lint：对 Spec、Design、Task、Prompt、Test、Evidence 全部做正则校验。

## 5. P1 结构性问题

### P1-01：主流程顺序在文档间不一致

证据：

- `docs/goal/README.md` 和 `docs/goal/03-pipeline.md` 定义主流程为：Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective。
- `docs/goal/12-operations.md` 的标准操作流写成：Goal → Goal Review → Spec → Matrix → Tasks → Plan → Prompt → Code → Test → Review → Release → Validate Goal。
- README 和 03 明确 Matrix 是横切制品，不是主流程阶段；12 把 Matrix 放入主流程。

影响：

Plan 与 Tasks 的先后顺序直接影响任务拆分、依赖规划和 Prompt 构造。Matrix 是否为阶段也会影响 Gate 的触发时机。

建议：

将 `12-operations.md` 改为运行手册视角：Matrix 可以在 Spec 后初始化，但不作为主流程阶段；Tasks 应从 Plan 拆出，或明确“初始任务草案”和“计划后任务冻结”的双阶段语义。

### P1-02：Matrix 覆盖率与 Release 条件存在多套阈值

证据：

- `docs/goal/05-layer-standards.md` 要求 Release 前 Matrix 100% 为 `Verified` 或 `Dropped`，且 Dropped 必须有原因。
- `docs/goal/08-quality-gates.md` 给出 Traceability ≥95%、AC Test Coverage ≥90%、Critical Requirement Test Coverage 100%。
- `.config/goal/schema/rules.yaml` 的 Matrix `coverage_threshold` 为 95。
- `docs/goal/tools/matrix-gen.py` 和 `docs/goal/tools/gate-check.sh` 当前也按 95% 终态覆盖率校验。

影响：

Release 到底要求 95% 还是 100%，取决于读的是标准层、质量门禁层还是工具层。这会削弱 Gate 作为裁决机制的可信度。

建议：

将阈值拆成两个概念：

- Gate pass threshold：允许 ≥95% 作为阶段推进下限。
- Release hard condition：P0/P1 或 Critical rows 必须 100% 终态。

然后在 rules.yaml 中显式编码两者。

### P1-03：工具校验面窄于文档承诺

证据：

- `docs/goal/10-lint-rules.md` 描述了 Goal、Spec、Matrix、Prompt、Code 多类 lint 规则，数量明显多于脚本实际实现。
- `docs/goal/tools/README.md` 只列出当前实现的 11 条 lint 规则。
- `docs/goal/tools/lint-goal.sh` 当前主要做关键词、基础字段和敏感信息检查，没有执行完整 YAML schema、状态枚举、ID 格式和跨文件追溯校验。
- `docs/goal/tools/rule-drift-check.py` 能验证 `rules.yaml` 与样例、CI、脚本常量的一致性，但不能证明所有规范文档互相一致。

影响：

当前“lint 通过”容易被误解成“Goal 体系通过结构审查”。实际它只是通过了有限规则集。

建议：

1. 在工具 README 中把“已实现规则”和“规划规则”分开。
2. 将 `10-lint-rules.md` 的每条规则标注为 `implemented`、`manual` 或 `planned`。
3. 增加 docs consistency checker，专门扫描旧 ID、旧路径、旧状态枚举和冲突阈值。

### P1-04：`.config/goal` 的版本边界不清

证据：

- `docs/goal/README.md` 和 `docs/goal/15-registry.md` 将 `.config/goal/` 作为统一配置中心。
- `docs/goal/12-operations.md` 又写到 Goal runtime state、Registry、Matrix、Evidence 存储在本地 `.config/goal/`，不在 repo。
- 当前 `git ls-files .config/goal` 为空，说明 `.config/goal` 没有被 Git 跟踪。
- 工具和文档却依赖 `.config/goal/schema/rules.yaml`、`.config/goal/matrix/matrix.yaml`、`.config/goal/gates/state.yaml`、`.config/goal/pipeline/state.yaml`。

影响：

如果 `.config/goal` 是本地运行态，就不应承担跨人协作的规则权威；如果它是项目配置中心，就应明确哪些文件入库、哪些文件本地生成。

建议：

将 `.config/goal` 分层：

- 版本化：`schema/rules.yaml`、registry schema、matrix schema、gate schema、示例模板。
- 本地运行态：pipeline run state、attempts、临时 evidence、agent scratch。
- 交付证据：需要随 PR 提交的 matrix snapshot、evidence summary、gate verdict。

### P1-05：Evidence 证明深度不足以支撑高分 Gate

证据：

- `docs/goal/13-runtime-engine.md` 要求 Evidence 必须包含命令、输出、文件引用、风险和时间。
- `docs/goal/tools/evidence-collect.sh` 会生成 Evidence 文件，但许多证明区域仍是 TODO 模板。
- `docs/goal/tools/gate-check.sh` 主要检查字段是否存在，不验证命令是否真的运行、输出是否对应、文件引用是否存在、风险是否关闭。

影响：

Evidence 文件可以“字段完整但证明不足”。在高风险任务中，这会让 Gate PASS 变成格式 PASS，而不是事实 PASS。

建议：

1. Evidence schema 增加 machine-verifiable 字段，例如 command exit code、artifact path、changed files hash。
2. gate-check 至少校验文件引用存在、命令块非空、状态为 PASS 时无未关闭 P0/P1 risk。
3. Evidence collector 支持显式传入验证命令，避免依赖语言栈猜测。

## 6. P2 维护性问题

### P2-01：规范正文、愿景文档和审计报告混在一个索引层

证据：

- `docs/goal/22-delivery-os.md` 标注为愿景架构，尚未完全实现。
- `docs/goal/23-workflow-governance-checks.md` 也标注为愿景架构，尚未完全实现。
- `docs/goal/24-standard-unification-analysis.md` 是结构审计报告，却出现在 README 的主文档索引中。

影响：

读者难以区分“当前必须遵守的规范”“未来设计方向”和“历史审计结论”。

建议：

建立三层目录或索引标记：

- `current/` 或主索引：当前权威规范。
- `vision/`：未来架构与实验性方案。
- `report/`：审计、评分、回顾。

### P2-02：通用 Goal 体系中混入 x.go 项目特例

证据：

- `docs/goal/16-ci-cd.md` 中包含 x.go 专属路径、模块边界和 DoD。

影响：

Goal 体系如果要作为通用治理标准，项目特例会污染通用规则；如果它只服务 x.go，则 README 应明确范围。

建议：

将 x.go 专属内容移到项目适配层，例如 `docs/goal/adapters/x-go.md`，通用 CI/CD 文档只保留抽象规则。

### P2-03：模板目录示例存在旧路径

证据：

- `docs/goal/09-templates.md` 的仓库结构示例包含 `docs/goals/`、`docs/module/`、`docs/matrix/` 等路径。
- 当前 README 明确 Goal 体系文档在 `docs/goal/`，运行状态在 `.config/goal/`。

影响：

新执行者按模板落地时，可能创建一套平行目录，进一步增加规则漂移。

建议：

模板中的路径全部改为当前边界：`docs/goal/`、`.config/goal/`、`module/`、`docs/governance/`。

## 7. 工具状态解读

当前工具链是有价值的，但定位应调整为“样例一致性与基础门禁”，不是“完整结构审查”。

可保留的能力：

- `rule-drift-check.py`：适合作为 `rules.yaml` 与脚本常量之间的漂移检查。
- `matrix-gen.py --check-only`：适合验证现有 Matrix 行是否终态、是否缺任务 / 测试 / Evidence。
- `gate-check.sh`：适合做轻量 PR 门禁。
- `lint-goal.sh`：适合做基础文档和敏感信息检查。

需要补强的能力：

- 跨文档冲突扫描：旧 ID、旧状态、旧路径、旧阈值。
- YAML schema validation：Registry、Matrix、Gate、Pipeline、Evidence。
- Evidence factual validation：命令输出、文件引用、exit code、artifact 是否存在。
- ID grammar validation：所有对象统一用 rules.yaml 正则校验。

## 8. 推荐修复顺序

### 第 1 步：冻结规则权威裁决

目标：在 `docs-first` 与 `rules-first` 中选择一条权威路线，并写明冲突时的裁决顺序。
验收：README 是人类入口；03 / 04 / 07 / 15 不再互相宣称独立 SSOT，而是引用选定裁决源或声明各自对象边界。

### 第 2 步：统一 ID 与状态

目标：一次性修正 05、07、09、tools、rules.yaml 中的 Spec、Design、Prompt、Evidence ID。
验收：新增 ID lint；新制品必须输出新格式，历史格式只允许兼容读取和迁移，不再作为新模板示例。

### 第 3 步：统一 Pipeline 与 Matrix 语义

目标：主流程只有一条；Matrix 是横切制品；Plan / Tasks 顺序明确。
验收：README、03、12 的流程图一致。

### 第 4 步：拆分配置与运行态

目标：说明 `.config/goal` 哪些文件必须入库，哪些文件必须本地生成。
验收：`git ls-files .config/goal` 的结果与文档声明一致。

### 第 5 步：补齐工具能力

目标：让工具覆盖文档承诺，而不是只覆盖当前样例。
验收：`10-lint-rules.md` 中每条规则都有 implementation status；planned 规则不会被误当成已执行。

## 9. 结论

当前 `docs/goal/` 的价值在于体系覆盖面完整，已经具备从目标到交付证据的治理蓝图；最大风险在于规则没有收敛为单一机器契约。若继续在现有结构上添加文档，会进一步增加治理熵。

本轮建议先做“规则收敛”，再做“工具增强”。在权威源、状态机、ID 格式和 Matrix / Evidence 契约统一之前，不建议把该体系标记为 90 分以上或作为强制执行标准推广。
