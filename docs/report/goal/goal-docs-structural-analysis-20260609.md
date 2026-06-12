# docs/goal 结构性审计报告

审计日期：2026-06-09  
审计范围：`docs/goal/` 全量 Markdown 与 `docs/goal/tools/` 工具脚本；`.config/goal/` 仅作为当前运行态样本与规则样本参考。  
审计结论：`66/100`。当前资料已经具备方法论雏形、门禁意识和部分可执行工具，但还没有收敛成一个可严格自动化执行的单一规范体系。

## 1. 总体判断

`docs/goal/` 的主要问题不是内容不足，而是“多套半权威标准并存”。多个文档都声明自己是权威来源，且在流程顺序、状态枚举、ID 格式、Goal/Registry Schema、Matrix/Evidence 字段、工具规则阈值上存在漂移。结果是：人工阅读时大体能理解方向，但 agent 或 CI 工具执行时会选择不同契约，导致“样本通过检查”不等价于“体系一致”。

当前最核心的结构风险：

1. `03-pipeline.md` 声明状态枚举为 SSOT，但 `.config/goal/schema/rules.yaml` 使用另一套更细的状态集合。
2. `07-id-system.md` 声明统一 ID 格式，但 `05-layer-standards.md`、`09-templates.md`、工具脚本仍混用 `vN`、`v1.0`、`P-XXX` 等格式。
3. `02-goal-standard.md`、`09-templates.md`、`15-registry.md` 对 Goal/Registry 字段要求不一致。
4. `README.md`、`03-pipeline.md`、`12-operations.md`、`13-runtime-engine.md`、`16-ci-cd.md` 给出了不同粒度的执行流程，但缺少映射层。
5. 工具能通过当前 `.config/goal` 样本检查，但检查依据主要是 `rules.yaml`，并不会覆盖文档间的契约漂移。

## 2. 审计证据

文档与工具规模：

- `docs/goal/` 下共有 28 个 Markdown 文档。
- `docs/goal/tools/` 下共有 5 个工具脚本。
- 审计对象总量约 6,937 行。

已执行的基础验证：

| 验证项                                                 | 结果 | 说明                                  |
| ------------------------------------------------------ | ---: | ------------------------------------- |
| `bash -n docs/goal/tools/gate-check.sh`                | PASS | Shell 语法通过                        |
| `bash -n docs/goal/tools/evidence-collect.sh`          | PASS | Shell 语法通过                        |
| `bash -n docs/goal/tools/lint-goal.sh`                 | PASS | Shell 语法通过                        |
| `python3 docs/goal/tools/rule-drift-check.py --root .` | PASS | 当前运行态样本符合 `rules.yaml`       |
| `python3 docs/goal/tools/matrix-gen.py --check-only`   | PASS | 当前 Matrix 样本覆盖率 100%           |
| `bash docs/goal/tools/gate-check.sh`                   | PASS | 当前 Gate 样本 PASS=7, FAIL=0, WARN=0 |

注意：这些 PASS 只证明当前样本能被当前工具接受，不证明 `docs/goal/` 内部规范一致。原因是核心检查器读取的是 `.config/goal/schema/rules.yaml`，而该规则文件本身与 `docs/goal/03-pipeline.md` 的状态机定义存在冲突。

## 3. 评分

评分口径：100 分代表可作为自动化 agent/CI 的单一执行规范；80 分以上代表局部漂移但可控；70 分以下代表需要先做结构收敛再扩大使用。

| 维度                   | 分数 | 判断                                                          |
| ---------------------- | ---: | ------------------------------------------------------------- |
| 权威边界与 SSOT        | 60   | 多个文档声明权威，缺少机器可校验的权威映射                    |
| 主流程与状态机         | 64   | 11 层流程清晰，但 SOP、Lite Mode、CI Phase 与主流程未建立映射 |
| Gate 与质量门禁        | 78   | G0-G11 结构完整，阈值与 PASS_WITH_RISK 语义仍有漂移           |
| ID / 版本 / 命名       | 58   | 新旧格式混用，模板与脚本正则不完全一致                        |
| Goal / Registry Schema | 60   | 最小字段、模板字段、registry 字段三套表达                     |
| Matrix / Evidence 追溯 | 66   | 方向正确，字段、阈值、Evidence 协议仍未统一                   |
| 工具 / CI 可执行性     | 66   | 有可运行脚本，但工具校验面窄，规则源与文档源未闭环            |
| 可读性与维护性         | 76   | 文档覆盖充分，但入口过长、历史分析与现行规范混杂              |

综合评分：`66/100`。

## 4. P1 结构性问题

### P1-01：SSOT 声明分散，权威层级没有闭合

证据：

- `docs/goal/03-pipeline.md:37` 声明 Pipeline 状态枚举是 SSOT，Registry、Glossary、Runtime、Gate、脚本不得定义新状态。
- `docs/goal/04-gates.md:5` 声明 Gate ID、名称、顺序、阻塞权威由该文档定义。
- `docs/goal/06-dod.md:3` 声明 DoR/DoD 是 SSOT。
- `docs/goal/08-quality-gates.md:3` 又声明 Gate 定义权威在 `04-gates.md`，本文件聚焦 DoR/DoD 与评分。
- `docs/goal/13-runtime-engine.md:3` 声明流程、门禁、ID 的权威分别来自 `03`、`04`、`07`。
- `docs/goal/GLOSSARY.md:32` 定义 SSOT，但未给出全局权威目录。

问题：每份文档都局部正确，但缺少一张“权威面地图”：哪个字段、枚举、阈值、目录、Schema、工具规则由谁定义，谁只能引用。现在读者需要靠上下文猜。

影响：agent、脚本和维护者可能选择不同源作为标准；后续修改容易修一处漏三处。

建议：新增或提升一个 `docs/goal/00-authority-map.md`，将每类契约映射到唯一源，并要求工具规则从权威源生成或校验。

### P1-02：Pipeline 存在多条流程表达，缺少映射关系

证据：

- `docs/goal/README.md:17-21` 给出 11 层主流程：Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective。
- `docs/goal/README.md:120-134` 同时给出最小闭环与增强闭环。
- `docs/goal/03-pipeline.md:9-13` 将 11 层流程定义为主线。
- `docs/goal/12-operations.md:110-125` SOP 写成 Goal review → Spec → Matrix → Tasks → Plan → Prompt → Code → Test → Review → Release → Validate Goal，顺序与主线不同，且 Matrix 被放入阶段序列。
- `docs/goal/13-runtime-engine.md:24-29` Lite Mode 引入 `Goal → Plan → Docs Change → Evidence → Review`、`Goal → Plan → Tasks → Prompt → Code → Test → Evidence → Review`。
- `docs/goal/16-ci-cd.md:40-113` 另有 Phase 0-8 执行阶段。

问题：这些流程可能分别代表“主方法论、轻量模式、CI 实现、运营 SOP”，但文档没有明确层级和映射。

影响：执行者无法判断何时可以跳过 Spec/Design，Matrix 是阶段还是横切制品，Evidence 是阶段还是制品，Plan 与 Tasks 的顺序以哪份文档为准。

建议：保留 `03-pipeline.md` 为唯一主流程；其他流程必须改写为 `mode/profile` 或 `implementation phase`，并逐项映射到主流程阶段。

### P1-03：Pipeline 状态枚举与运行态规则冲突

证据：

- `docs/goal/03-pipeline.md:41-58` 定义正常状态：`INIT`、`CONTEXT_READY`、`GOAL_READY`、`SPEC_READY`、`DESIGN_READY`、`PLAN_READY`、`TASKS_READY`、`EXECUTING`、`VERIFYING`、`REVIEWING`、`RELEASING`、`RETROSPECTING`、`DONE`，以及异常状态。
- `.config/goal/schema/rules.yaml:97-129` 定义另一套状态：`GOAL_DRAFTING`、`GOAL_REVIEWING`、`GOAL_APPROVED`、`SPEC_DRAFTING`、`SPEC_REVIEWING`、`SPEC_APPROVED`、`DESIGNING`、`DESIGN_REVIEWING`、`DESIGN_APPROVED`、`PLANNING`、`PLAN_APPROVED`、`CODING`、`TESTING` 等。
- `docs/goal/tools/rule-drift-check.py` 当前校验的是 `.config/goal/schema/rules.yaml`，不是反向校验 `03-pipeline.md` 的 SSOT。

问题：文档主状态是“阶段就绪态”，运行态规则是“细粒度阶段活动态”。两者可能都合理，但没有命名分层。

影响：`rule-drift-check.py` 通过时，只说明运行态数据符合 `rules.yaml`，并不说明它符合 `03-pipeline.md`。这会制造错误安全感。

建议：拆成两个显式枚举：`pipeline_state` 使用 `03-pipeline.md` 的粗粒度状态；`phase_state` 或 `workflow_step` 使用细粒度活动态。工具必须校验两者映射关系。

### P1-04：ID 与版本格式没有统一落地

证据：

- `docs/goal/07-id-system.md:11-32` 定义新格式：`SPEC-<domain>-vN`、`DESIGN-<domain>-vN`、`PLAN-<goal-id>-vN`、`PROMPT-<task-id>-NNN`、`EVID-<test-id>-NNN`。
- `docs/goal/05-layer-standards.md:15-17` 使用 `SPEC-<domain>-v<major>.<minor>`。
- `docs/goal/05-layer-standards.md:87-89` 使用 `DESIGN-<domain>-v<major>.<minor>`。
- `docs/goal/05-layer-standards.md:116-118` 使用 `PLAN-<goal-id>-v<major>.<minor>`。
- `docs/goal/05-layer-standards.md:204-206` 仍保留 `P-XXX`。
- `docs/goal/09-templates.md:91-97` 使用 `DESIGN-<domain>-v1.0`。
- `docs/goal/tools/matrix-gen.py:24-28` 的正则只接受部分 `v\d+` 风格 ID，并硬编码默认 Goal ID。
- `docs/goal/12-operations.md:51-59` 定义文档版本 `v0.1`、`v1.0`、`v2.0`，但未与 ID 版本区分。

问题：ID 版本、文档版本、语义版本混在一起；模板、标准、脚本未统一。

影响：自动生成 Matrix、Evidence、Prompt 时容易出现合法性分歧；旧格式可能继续扩散。

建议：以 `07-id-system.md` 为唯一 ID 规范；将文档成熟度版本另命名为 `document_version` 或 `lifecycle_version`；删除或迁移 `P-XXX`、`v1.0` 示例。

### P1-05：Goal / Registry / Template Schema 不一致

证据：

- `docs/goal/02-goal-standard.md:180-186` 要求 Goal 最小字段包括 `id`、`name`、`context`、`objective`、`success_metrics`、`scope_in/out`、`constraints`、`acceptance_criteria`、`owner`、`priority`、`status`。
- `docs/goal/09-templates.md:217-245` Goal YAML 使用 `scope.in/out` 等字段，但没有覆盖 `owner`、`priority`、`status` 等最小字段。
- `docs/goal/15-registry.md:29-48` Registry 示例使用 `goal_id`、`title`、`status: active`、`north_star`、`pipeline_state`、`current_phase`、`phase_status` 等字段。
- `docs/goal/15-registry.md:56-70` Task Registry 使用 `status: In Progress`。
- `docs/goal/15-registry.md:114-130` Release Registry 使用 `status: ready_for_pr`。

问题：Goal 文档对象、Goal 模板对象、Registry 运行对象是三套字段模型；状态命名也分别使用标题式、下划线式、小写式。

影响：无法从模板稳定生成 Registry；无法用一份 schema 校验 Goal 是否满足 DoR；agent 会在字段转换中丢信息。

建议：定义一个 canonical schema，再声明 `template view`、`registry view`、`report view` 的映射。所有示例必须从 schema 派生。

### P1-06：Matrix 与 Evidence 契约未完全闭合

证据：

- `docs/goal/03-pipeline.md:31` 声明 Matrix 是横切制品，不作为主流程阶段。
- `docs/goal/06-dod.md:129-149` 定义 Matrix Coverage DoR/DoD。
- `docs/goal/05-layer-standards.md:291-348` 定义 Matrix 字段、质量标准和生命周期，并在 `05-layer-standards.md:337` 要求 Release 前 100% Verified 或 Dropped with drop_reason。
- `docs/goal/08-quality-gates.md:185-195` 定义 Traceability Coverage ≥95%、AC Test Coverage ≥90%、Critical Req Test Coverage 100%。
- `docs/goal/tools/matrix-gen.py:100-144` 生成字段为 `goal_id`、`spec_id`、`requirement_id`、`acceptance_criteria`、`task_id`、`prompt_id`、`code_module`、`test_case`、`evidence_ids`、`status`、`risk`。
- `docs/goal/tools/gate-check.sh:80-105` Evidence Gate 要求 `Evidence ID`、`Acceptance Criteria ID`、`Test ID`、`Task ID`、`Spec ID`、`Goal ID`、`Date`、`Status`、`Files Changed`、`Commands Run`。
- `docs/goal/13-runtime-engine.md:115-135` Evidence Protocol 还要求 Results、Logs、Diff Summary、Requirement Proof、Known Limitations、Risks、Rollback 等语义字段。

问题：Matrix 覆盖率、Release 阈值、Evidence 最小字段、Evidence 完整字段在多个位置定义，且工具只校验其中一部分。

影响：Gate PASS 可能只代表字段存在，不代表 Evidence 足以支撑验收；Release Gate 的 100% 要求与 95% Matrix 覆盖阈值容易混淆。

建议：将 Matrix 分为 `minimum readiness`、`release blocking` 两套阈值；Evidence 分为 `required metadata` 与 `required proof sections`，工具必须分别校验。

### P1-07：`.config/goal` 的仓库边界与持久化策略不清

证据：

- `docs/goal/README.md:29-53` 将 `.config/goal/` 描述为统一配置中心。
- `docs/goal/README.md:65-76` 将 `.config/goal/` 纳入 Goal 方法、状态、门禁、证据边界。
- `docs/goal/12-operations.md:133-159` 又说明 Runtime State、Registry、Matrix、Evidence、Context Package under local `.config/goal/`，不进入仓库。
- `docs/goal/12-operations.md:186-192` 讨论 Registry YAML Merge Commit、Evidence files immutable append-only。
- 当前 `git ls-files .config/goal` 为空，但本地 `.config/goal/` 存在完整样本。

问题：`.config/goal` 到底是 repo-tracked schema/config、local runtime state，还是两者混合，没有明确分层。

影响：CI 是否能运行、团队如何共享 Registry、Evidence 是否可审计、规则文件是否应提交，都无法从文档确定。

建议：拆分为 `docs/goal/schema/` 或 `.config/goal/schema/` 的可提交规则样本，以及 `.config/goal/runtime/` 的本地运行态；明确哪些文件 tracked，哪些文件 ignored。

## 5. P2 问题

### P2-01：Gate 阈值语义需要分层

`docs/goal/04-gates.md:177-181` 的 G7 Test Gate 要求测试通过且覆盖率 ≥80%；`docs/goal/08-quality-gates.md:185-195` 又要求 Traceability Coverage ≥95%、AC Test Coverage ≥90%、Critical Req Test Coverage 100%；`docs/goal/tools/gate-check.sh:108-153` Matrix 覆盖率按 95% 判断。建议明确：代码覆盖、AC 覆盖、Traceability 覆盖、Release 阻塞覆盖分别是什么，不要共用“coverage”。

### P2-02：PASS_WITH_RISK 缺少状态转换语义

`docs/goal/03-pipeline.md:105-109` 说明 `WAIVED` 不是 Gate 结果，映射为 `PASS_WITH_RISK` 或 `BLOCKED`；`docs/goal/04-gates.md:245-252` 定义 Gate result。缺失的是：`PASS_WITH_RISK` 是否允许进入下一阶段、需要何种 owner、何时必须清零。

### P2-03：工具实现校验面偏窄

`docs/goal/tools/lint-goal.sh` 主要依赖文本匹配；`docs/goal/tools/rule-drift-check.py:46-81` 使用自定义简化 YAML 解析器；`docs/goal/tools/evidence-collect.sh:31-40` 默认取 `HEAD~1` diff，`docs/goal/tools/evidence-collect.sh:47-75` 只保留测试输出末尾。建议增加 fixture 测试，并用结构化 YAML/Markdown parser 或明确限制输入格式。

### P2-04：`24-standard-unification-analysis.md` 是有价值的历史分析，但与现行状态混杂

`docs/goal/24-standard-unification-analysis.md:7-25` 已经指出多标准并存并给出 66/100；但该文件仍放在主文档编号序列中，且部分工具阈值判断已经过时。建议移到 `docs/report/goal/` 或标记为历史审计，不要让它继续作为编号规范文档出现。

### P2-05：CI/CD 文档耦合具体项目

`docs/goal/16-ci-cd.md:137-153` 引入 x.go 规则，适合作为适配器示例，不适合作为 Goal 通用规范主体。建议迁移到 project adapter 或附录。

### P2-06：Quickstart 入口过长

`docs/goal/00-quickstart.md` 约 358 行，对“快速开始”而言承担了过多解释、命令和模板职责。建议压缩为 5 分钟路径，把深层说明链接到后续章节。

### P2-07：模板路径示例与仓库边界冲突

`docs/goal/09-templates.md:302-315` 示例使用 `docs/goals/`、`docs/module/`、`docs/matrix/`、`docs/tasks/`、`docs/plans/`、`docs/prompts/`；而 `docs/goal/README.md:65-76` 定义了当前边界。建议删除旧路径或明确为 legacy layout。

### P2-08：状态大小写和命名风格不统一

`docs/goal/02-goal-standard.md:163-178` 使用 `Partially Validated`，`docs/goal/20-metrics-evidence.md:45-65` 使用 `partially_achieved`、`Partially Achieved`，`docs/goal/15-registry.md:32` 使用 `active`，`docs/goal/15-registry.md:120` 使用 `ready_for_pr`。建议每个对象只允许一种 machine value，展示文本另行映射。

## 6. P3 维护性问题

1. `docs/goal/05-layer-standards.md` 章节编号从 7 跳到 9，缺少 `## 8`。
2. 多处文档同时解释 Matrix 的横切性质，内容重复但细节不一致。
3. `GLOSSARY.md` 只有术语解释，没有反向链接到具体权威字段。
4. `CHANGELOG.md` 与主文档编号体系没有明确对应，难以追踪某次标准变更影响了哪些契约。

## 7. 建议收敛路线

### Phase 0：冻结权威面

目标：停止新增并行标准。

动作：

1. 建立 `docs/goal/00-authority-map.md`。
2. 声明每类契约的唯一权威：流程、状态、ID、Gate、Schema、Matrix、Evidence、目录布局、工具规则。
3. 把 `24-standard-unification-analysis.md` 移出编号规范序列或改为历史报告。

验收：

- 任一字段、状态、阈值都能追溯到唯一权威文档。
- 所有非权威文档只引用，不重新定义。

### Phase 1：统一状态、ID、Schema

目标：消除 P1-03、P1-04、P1-05。

动作：

1. 将 `pipeline_state` 与 `phase_state` 分层，补充映射表。
2. 以 `07-id-system.md` 统一所有模板和脚本正则。
3. 定义 Goal canonical schema，并让 `09-templates.md` 与 `15-registry.md` 映射到该 schema。

验收：

- `P-XXX`、`v1.0` 这类旧 ID 示例不再出现在现行模板中。
- `rules.yaml` 与 `03-pipeline.md` 不再存在状态冲突。
- Goal 模板能无损转换为 Registry 条目。

### Phase 2：让工具校验文档契约

目标：工具 PASS 代表体系一致，而不只是样本符合规则。

动作：

1. `rule-drift-check.py` 增加文档源反查：校验 `rules.yaml` 是否符合 `03`、`04`、`07`。
2. `gate-check.sh` 区分 Metadata completeness 与 Proof completeness。
3. 为 Matrix/Evidence/Goal schema 增加最小 fixture。

验收：

- 工具能捕获“文档 SSOT 与 rules.yaml 不一致”。
- Gate PASS 能说明 Evidence 既有必填元数据，也有验收证明内容。

### Phase 3：重整入口和适配器

目标：降低使用成本，避免通用规范混入项目特例。

动作：

1. 压缩 `00-quickstart.md`。
2. 将 x.go 内容移到项目适配器文档。
3. 明确 Lite Mode、Standard Mode、Full Mode 与主流程的映射。
4. 明确 `.config/goal` 哪些 tracked，哪些 local-only。

验收：

- 新读者能在 5 分钟内知道从哪里开始。
- CI、Runtime、Docs 三层边界清楚。

## 8. 目标分数

按上述路线修复后，合理目标：

| 阶段                       | 预期分数 |
| -------------------------- | -------: |
| 修复 P1-01 到 P1-07        | 80-84    |
| 补齐工具反查与 fixture     | 85-89    |
| 清理入口、适配器、历史文档 | 90+      |

达到 90+ 的判定标准：一个 agent 只读取权威地图、主流程、ID、Gate、Schema 和工具 README，就能稳定执行同一套 Goal 管线，不需要在文档间猜测。

## 9. 最终结论

`docs/goal/` 当前适合作为“Goal 驱动交付体系的设计草案和人工操作指南”，但不适合作为“严格 agent/CI 自动执行规范”。核心修复方向不是继续补更多章节，而是减少权威面、统一枚举和 Schema、让工具反向校验文档契约。

当前评分：`66/100`。建议在进入更大规模自动化前，优先完成 P1 收敛。
