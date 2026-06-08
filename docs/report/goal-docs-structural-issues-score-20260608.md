# docs/goal/ 结构性内审报告

- 审查日期：2026-06-08
- 审查范围：`docs/goal/**/*.md`、`docs/goal/tools/README.md`
- 审查类型：文档内部一致性、流程结构、状态模型、门禁语义、追溯闭环
- 不包含：代码实现符合度审计、脚本运行正确性审计、外部最佳实践对比

## 总体评价

综合评分：**78 / 100**

结论：`docs/goal/` 已经形成较完整的 Goal 驱动交付体系，主流程、Gate、Registry、Matrix、Evidence 等核心概念都有明确文档承载；但目前存在若干结构性冲突，主要集中在 Matrix 生命周期、双轴状态机、Gate 编号命名空间、最小流程口径和术语索引。若直接作为强约束流程推广，执行者和自动化工具会在“何时生成 Matrix”“哪个字段表达当前状态”“人审是否属于独立 Gate”等关键问题上产生分歧。

建议状态：**可作为方法论草案使用，不建议作为自动化执行协议的最终权威版。**

## 评分细则

| 维度                        | 得分    | 主要扣分点                                                                    |
| --------------------------- | ------- | ----------------------------------------------------------------------------- |
| 主流程与模式分层            | 16 / 20 | Full、Lite、MVA、Quickstart 的最小闭环口径不一致                              |
| 状态机与 Registry 一致性    | 14 / 20 | `current_phase` 与 `pipeline_state` 混用，回退规则会写入语义不稳的 ready 状态 |
| Gate 与质量门禁语义         | 16 / 20 | `H-G1 ~ H-G8` 与 `G0-G11` 唯一 Gate 编号规则冲突                              |
| Matrix / AC / Test 追溯闭环 | 15 / 20 | Matrix DoR 与“Spec 后初始化”冲突；AC 在一处链路中被放到 Test 之后             |
| 导航、术语与工具文档对齐    | 17 / 20 | 工具规则数量、状态数量、锚点、阅读路径存在漂移                                |

## P1 高优先级问题

### P1-01 Matrix 生命周期定义自相矛盾

位置：

- `docs/goal/README.md:25`：Matrix 在 Spec 后可初始化，并随后续阶段更新。
- `docs/goal/06-dod.md:131`：Matrix Coverage 通常在 Spec 后初始化。
- `docs/goal/06-dod.md:137`、`docs/goal/06-dod.md:138`：Matrix Coverage DoR 又要求 `Plan 已完成`、`Tasks 已拆分`。
- `docs/goal/06-dod.md:148`：Matrix 覆盖检查结果可作为 G5 Task Gate 证据。
- `docs/goal/04-gates.md:134`：G5 是 Task Gate。

问题：文档同时要求 Matrix “Spec 后初始化”和“Plan/Tasks 完成后才满足 DoR”。这会让 Matrix 既像早期设计控制面，又像后置审计制品，生命周期不闭合。

影响：执行者可能等到 Tasks 拆完后才建 Matrix，导致 Goal / Spec / AC 的覆盖问题发现过晚；自动化 Gate 也难以判断 G5 之前 Matrix 应处于 `Mapped`、`Linked` 还是 `Verified`。

建议：

- 将 Matrix 拆成两个状态门槛：`Matrix Init DoR` 与 `Matrix Gate DoD`。
- `Matrix Init DoR` 只要求 Goal / Spec / Requirement / AC 已编号。
- `Matrix Gate DoD` 再要求 Plan、Tasks、Prompt、Code、Test、Evidence 链接完整。
- 在 G5 中明确要求的是 “Task 覆盖已 Linked”，不是完整 Evidence 验证。

### P1-02 双轴状态机规则与 Registry 示例冲突

位置：

- `docs/goal/03-pipeline.md:37`：运行态只有一个顶层机器状态 `pipeline_state`，交付层级和阶段内进度分别写入 `current_phase` 与 `phase_status`。
- `docs/goal/03-pipeline.md:41`、`docs/goal/03-pipeline.md:42`、`docs/goal/03-pipeline.md:43`：三字段分工明确。
- `docs/goal/03-pipeline.md:121`：阶段就绪类状态只能在 Gate 已通过时写入同名 `pipeline_state`。
- `docs/goal/15-registry.md:45`：示例写成 `current_phase: design_ready`。
- `docs/goal/15-registry.md:71`：`current_phase` 被解释为“当前所处管线阶段”。

问题：`design_ready` 是 ready 语义，不是 11 个 Phase 枚举之一。它被写入 `current_phase`，破坏了 `current_phase + phase_status + pipeline_state` 的双轴模型。

影响：状态文件会同时出现 `current_phase: DESIGN`、`current_phase: design_ready`、`pipeline_state: DESIGN_READY` 等多种表达，导致 agent、lint、CI、Registry 查询难以统一解析。

建议：

- Registry 示例改为：

```yaml
pipeline_state: DESIGN_READY
current_phase: DESIGN
phase_status: READY
```

- `15-registry.md` 明确 `current_phase` 只能使用 `03-pipeline.md` 的 11 个大写 Phase。
- 为 `current_phase`、`phase_status`、`pipeline_state` 增加一张反例表，禁止 `*_ready` 写入 `current_phase`。

### P1-03 回退规则会把失败后的流程退回到“已通过”语义状态

位置：

- `docs/goal/03-pipeline.md:95`：状态转换规则从 `SPEC_READY` 到 `DESIGN_READY` 需要 Design Gate PASS。
- `docs/goal/03-pipeline.md:155`：`Review FAIL: design` 回到 `pipeline_state: DESIGN_READY` 并更新 Design / Plan。
- `docs/goal/03-pipeline.md:160`：Spec / Design 变更影响 Plan 时回到 `DESIGN_READY` 或 `PLAN_READY`，并记录 `needs_replan`。

问题：`DESIGN_READY`、`PLAN_READY` 在状态机中表示相应 Gate 已通过后的机器状态，但回退规则又把失败或变更后的流程写回这些 ready 状态。

影响：Gate 状态会失真。失败后的 Design 如果仍处于 `DESIGN_READY`，下游工具可能误判 Design Gate 仍有效，从而继续推进到 Plan 或 Tasks。

建议：

- 回退后保留当前 `pipeline_state`，通过 `blockers[]` / `gate_failures[]` / `phase_status: CHANGES_REQUESTED` 表达失败。
- 若必须回退机器状态，应退回上一个仍然有效的已通过状态，例如 Design 失败退回 `SPEC_READY`，并将 `current_phase: DESIGN`、`phase_status: CHANGES_REQUESTED`。
- `needs_replan` 应作为 blocker 或 Plan 修订标记，不应与 `PLAN_READY` 同时出现。

### P1-04 Acceptance Criteria 在追溯链路中的方向不一致

位置：

- `docs/goal/03-pipeline.md:31`：Matrix 串联 `Goal → Spec → Requirement → AC → Task → Prompt → Code → Test → Evidence`。
- `docs/goal/01-methodology.md:143`：闭环写成 `Goal → Spec → Requirement → Task → Prompt → Code → Test → Acceptance Criteria → Goal`。
- `docs/goal/tools/README.md:61`、`docs/goal/tools/README.md:74`：Evidence 需要绑定 Task + AC + Test。

问题：主模型中 AC 是 Requirement 的下游契约、Test 的验证目标；但 `01-methodology.md` 的闭环把 AC 放在 Test 之后，像是测试完成后的结论。

影响：AC 可能被误用为事后验收记录，而不是开发前的验收约束；这会削弱需求可追溯性和测试设计质量。

建议：

- 将闭环统一为 `Goal → Spec → Requirement → Acceptance Criteria → Task → Prompt → Code → Test → Evidence → Goal`。
- 若想表达“测试结果反证 AC 是否满足”，应画成回边，不应把 AC 放在 Test 之后作为顺序节点。

## P2 中优先级问题

### P2-01 最小流程存在多个互不等价版本

位置：

- `docs/goal/README.md:112`：最小闭环为 `Goal → Plan → Tasks → Code → Test → Review`。
- `docs/goal/00-quickstart.md:32`：10 分钟闭环为 `Goal → Task → DoD → Code → Test → Done`。
- `docs/goal/00-quickstart.md:245`、`docs/goal/00-quickstart.md:248`：不同规模下又出现 `Goal → Task → DoD → Evidence → Review` 与 `Goal → Task → DoD → Code → Test → Evidence → Review`。
- `docs/goal/17-risk-and-decisions.md:161`、`docs/goal/17-risk-and-decisions.md:192`：MVA 执行循环为 `Goal → Task → Evidence → Review` 或 `Goal → Task → DoD → Evidence → Review`。
- `docs/goal/13-runtime-engine.md:27`：Lite Mode 包含 `Goal → Plan → Tasks → Prompt → Code → Test → Review`。

问题：这些流程可能都合理，但当前没有统一命名为不同 profile，也没有说明每个 profile 的必选制品、可省略制品和升级条件。

影响：用户会按入口文档选择不同流程，导致 Plan、Prompt、Evidence、Review 在“最小合规”中的地位不稳定。

建议：

- 在 `README.md` 或 `13-runtime-engine.md` 定义唯一 profile 表：`MVA`、`Lite`、`Standard`、`Full`。
- 每个 profile 明确必选制品、可选制品、强制 Gate、适用规模。
- 其他文档只引用 profile，不再各自发明最小链路。

### P2-02 人工审批 Gate 编号与 G0-G11 唯一 Gate 命名空间冲突

位置：

- `docs/goal/04-gates.md:5`：`G0-G11` 是 Gate 编号、名称、顺序和阻塞语义的权威来源。
- `docs/goal/04-gates.md:10`：任何 check/profile 都不得新增独立 Gate 编号。
- `docs/goal/08-quality-gates.md:9`：评分、孤儿检查、质量指标、人审审批、模块 profile 只能作为 `G0-G11` 的证据输入。
- `docs/goal/13-runtime-engine.md:222`、`docs/goal/13-runtime-engine.md:226` 到 `docs/goal/13-runtime-engine.md:233`：定义 `H-G1 ~ H-G8` 审批门禁。

问题：`H-G1 ~ H-G8` 使用了 Gate-like 编号，且标题为“审批门禁”，容易被理解为独立 Gate 系列。

影响：门禁体系会从一个权威编号空间扩展为两个编号空间，破坏 `04-gates.md` 对 Gate 顺序和阻塞语义的唯一性约束。

建议：

- 将 `H-G1 ~ H-G8` 改名为 `H-CHK-1 ~ H-CHK-8`、`Approval Check A1 ~ A8` 或 `Approval Evidence`。
- 每个人审项映射到 `G0-G11` 中的具体 Gate，例如 Spec Freeze 属于 G2/G3 证据，Release Approval 属于 G10 证据。

### P2-03 工具文档与 Lint 权威规则数量漂移

位置：

- `docs/goal/tools/README.md:86`：工具 README 写“检查规则（38 条）”。
- `docs/goal/10-lint-rules.md:161`：权威规则文档写“全部 50 条规则已实现”。
- `docs/goal/10-lint-rules.md:170` 到 `docs/goal/10-lint-rules.md:172`：新增 Registry / Config、Gate / Pipeline、Evidence 等规则族。

问题：工具入口仍停留在旧的 38 条规则口径，没有反映 50 条规则和新增规则族。

影响：读者会低估 lint 覆盖范围，也可能误以为 Registry、Gate、Pipeline、Evidence 的结构校验尚未纳入工具。

建议：

- 更新 `docs/goal/tools/README.md` 的规则数量和规则族列表。
- 在工具 README 中引用 `10-lint-rules.md` 的分组表，避免重复维护数字。

### P2-04 Glossary 与权威文档存在术语漂移

位置：

- `docs/goal/GLOSSARY.md:32`：`SSOT` 的定义位置标为“本文档”。
- `docs/goal/GLOSSARY.md:46`：`Pipeline State Machine` 写“12 种正常状态和 8 种异常状态”。
- `docs/goal/03-pipeline.md:42`、`docs/goal/03-pipeline.md:53`：管线状态机实际定义为 13 个正常状态。
- `docs/goal/GLOSSARY.md:47`：Gate Review 结果写成“通过/拒绝/条件通过”。
- `docs/goal/04-gates.md:254`：Gate 结果枚举为 `PASS_WITH_RISK` 等机器值。

问题：Glossary 本应降低歧义，但当前它在状态数量、Gate 结果名称和 SSOT 归属上与权威文档不完全一致。

影响：新读者可能从术语表继承旧口径，自动化实现也可能按“12 正常状态”或中文 Gate 结果建模。

建议：

- Glossary 的“定义位置”改成真实 SSOT 文档，而不是泛称“本文档”。
- 状态机条目改为“13 个正常 `pipeline_state`，阻塞与异常写入 blocker / evidence”。
- Gate Review 条目同时列出中文说明和机器枚举：`PASS / PASS_WITH_RISK / FAIL`。

### P2-05 Change Level 权威指向不一致

位置：

- `docs/goal/03-pipeline.md:147`：对象状态总表将 `Change Level | CL0-CL5` 指向 `17-risk-and-decisions.md`。
- `docs/goal/GLOSSARY.md:43`：Glossary 将 Change Level 指向 `13-runtime-engine.md`。

问题：同一概念的权威来源在两个索引表中不一致。

影响：CL 级别影响审批、风险和回退策略，权威位置不一致会让后续修改分叉。

建议：

- 确定 CL0-CL5 的唯一 SSOT。
- 若 `13-runtime-engine.md` 定义运行时审批，`17-risk-and-decisions.md` 定义风险使用方式，应在两个文件中拆清“枚举定义”和“应用规则”。

## P3 低优先级问题

### P3-01 阅读路径和索引信息未随文档规模更新

位置：

- `docs/goal/00-quickstart.md:23`：长期使用建议“读完全部 01-11”。
- `docs/goal/README.md:92`：`tools/` 仍标注为“planned”。
- `docs/goal/CHANGELOG.md:24`：也记录 README 将 tools 条目标为 planned。

问题：当前文档已经扩展到 00-23，且 `tools/` 已包含多个脚本和 README。入口文档仍保留旧规模描述。

影响：导航可信度下降，读者可能跳过 12-23 中的运行时、Registry、CI、风险、指标和治理文档。

建议：

- 将长期阅读路径改为分层路径：基础 00-11、运行治理 12-20、愿景扩展 21-23。
- 去掉 `tools/` 的 planned 标注，改成“已提供轻量脚本；以 10-lint-rules.md 为规则权威”。

### P3-02 状态机锚点链接疑似过期

位置：

- `docs/goal/13-runtime-engine.md:3`：链接到 `03-pipeline.md#2-状态机`。
- `docs/goal/04-gates.md:3`：同样链接到 `03-pipeline.md#2-状态机`。
- `docs/goal/01-methodology.md:19`：同样链接到 `03-pipeline.md#2-状态机`。
- `docs/goal/03-pipeline.md:35`：实际标题是 `## 2. 双轴状态机`。

问题：多个文件链接的锚点仍使用旧标题，实际渲染时可能无法跳转到正确章节。

影响：不影响模型本身，但会降低审查和执行时的定位效率。

建议：

- 将相关链接统一改为 `03-pipeline.md#2-双轴状态机`。
- 后续若标题可能变化，优先链接到文件并在链接文本中标注章节名，减少锚点漂移成本。

### P3-03 BLOCKED 术语仍被描述成状态

位置：

- `docs/goal/03-pipeline.md:65`：阻塞与异常不是 `pipeline_state` 枚举成员。
- `docs/goal/03-pipeline.md:112`：出现 blocker 时保留原 `pipeline_state`，在 `blockers[]` 记录原因。
- `docs/goal/18-maturity.md:232`：故障排查标题为“状态卡在 BLOCKED”。

问题：`BLOCKED` 在部分文档中仍被自然语言描述为“状态”，与 `03-pipeline.md` 的 blocker 条件模型不一致。

影响：轻微但高频。读者和工具实现可能重新把 `BLOCKED` 当作顶层状态。

建议：

- 改为“流程被 blocker 阻塞”或“`blockers[]` 未清理”。
- 若 Gate 文件允许 `status: BLOCKED`，需要明确这是 Gate 记录状态，不是 `pipeline_state`。

## 优点

- 主流程 SSOT 已经清晰落在 `03-pipeline.md`，并明确 Matrix 是横切制品而非主流程阶段。
- Gate 权威集中在 `04-gates.md`，`08-quality-gates.md` 也明确 check/metric 不能新增 Gate 编号。
- ID、Registry、DoR/DoD、Lint、Evidence、CI、治理文档已有分工，具备发展成自动化协议的基础。
- `10-lint-rules.md` 已把 Registry / Config、Gate / Pipeline、Evidence 纳入规则族，说明文档体系已经开始约束自身漂移。

## 修复优先级建议

1. 先修 `03-pipeline.md`、`15-registry.md`、`06-dod.md`：统一双轴状态机和 Matrix 生命周期。
2. 再修 `13-runtime-engine.md`、`04-gates.md`、`08-quality-gates.md`：把 `H-G*` 降级为 approval check / evidence，并映射到 G0-G11。
3. 然后修 `README.md`、`00-quickstart.md`、`17-risk-and-decisions.md`：定义唯一 profile 表，删除互相竞争的“最小闭环”。
4. 最后修 `GLOSSARY.md`、`tools/README.md` 和过期锚点：作为结构收口，防止后续读者继承旧口径。

## 审查结论

`docs/goal/` 的主要问题不是缺少内容，而是多个局部文档在迭代后保留了旧口径。当前最需要的不是继续新增章节，而是做一次“权威源收敛”：每个关键概念只保留一个 SSOT，其他文件只引用、解释或提供 profile 变体。

若完成上述 P1 和 P2 修复，预计结构评分可从 **78/100** 提升到 **90+/100**；若再补齐工具文档、Glossary 和锚点漂移，可进入 **95/100** 左右的稳定执行协议状态。
