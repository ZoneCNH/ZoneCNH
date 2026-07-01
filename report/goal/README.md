# Goal 报告治理入口

适用日期：2026-06-09

## 目录用途

`report/goal/` 保存 `docs/goal/` 体系的结构性审计、补充分析、执行账本和后续复评分证据。本目录只承载诊断、计划、关闭证据和历史报告，不替代 `docs/goal/` 与 `.config/goal/` 的规范权威。

## 当前状态

- 已按 `.worktree/todo.md` 完成 agent team 修复与验收。
- 最新复评分：`96/100`，已达到 `90+` 目标。
- P1 canonical GDR 问题已关闭；P2/P3 残余项已改为可验证自测或明确边界。

## 阅读顺序

1. `README.md`：确认目录用途、报告关系、基线分数和当前工作区风险。
2. `goal-docs-structural-analysis-20260609.md`：主审计报告，作为当前修复队列的第一来源。
3. `goal-docs-deep-structural-audit-20260609.md`：补充深审报告，强化 SSOT、状态、ID、配置、证据和工具问题。
4. `goal-docs-deep-analysis-20260609.md`：补充深析报告，提供跨文档证据、schema、Matrix 与信息架构细节。
5. `ISSUE-LEDGER.md`：按 canonical GDR ID 查看问题来源、阶段、影响文件和验收证据。
6. `goal-docs-fix-verification-20260609.md`：查看本轮 agent team 修复验收与 `96/100` 复评分。

## 现有报告关系

| 报告                                          | 角色     | 当前分数 | 用途                                                      |
| --------------------------------------------- | -------- | -------- | --------------------------------------------------------- |
| `goal-docs-structural-analysis-20260609.md`   | 主报告   | `66/100` | 作为 canonical 修复队列的主来源，覆盖 P1/P2/P3 结构问题。 |
| `goal-docs-deep-structural-audit-20260609.md` | 补充深审 | `66/100` | 补强主报告中的 SSOT、状态机、ID、配置、证据和工具风险。   |
| `goal-docs-deep-analysis-20260609.md`         | 补充深析 | `63/100` | 补充跨文档矛盾、schema 投影、Matrix 策略和信息架构证据。  |
| `goal-docs-fix-verification-20260609.md`      | 关闭验证 | `96/100` | 记录 agent team 修复结果、验收命令、输出摘要和残余风险。  |

## 当前基线分数

- 主基线：`66/100`，来自 `goal-docs-structural-analysis-20260609.md`。
- 补充基线：`63/100` 与 `66/100`，作为复评分时的风险下限和交叉证据。
- 最新复评分：`96/100`，并且无 P1 未关闭项。

复评分维度：

- P1 canonical GDR 问题关闭情况。
- 权威源、配置控制面和运行态边界是否清晰。
- 流程、状态、Gate、SOP、runtime、CI 与 lite/full 模式是否一致。
- ID、schema、Matrix、evidence 是否可追溯、可验证。
- 工具是否验证文档契约，而不只是样例或局部规则。
- 信息架构、历史材料、适配器、quickstart 与模板是否分层。
- dirty/untracked 状态是否已解决，或已被明确记录为外部风险。

## 编号规则

修复执行统一使用 `GDR-*` canonical issue。原报告中的 `P1-*`、`P2-*`、`P3-*`、`P1-D*`、`F-*` 只作为来源引用，不能作为后续执行主键。

验收入口：

- 看哪份报告：先看主报告，再看两份补充报告。
- 按哪个编号修：按 `ISSUE-LEDGER.md` 中的 canonical GDR ID 修复。
- 修完如何验收：在 ledger 中补充影响文件、验收证据和验证命令，再进入 Phase 6 复评分。

## 当前 dirty/untracked 注意事项

以下状态来自 2026-06-09 worker-1 复核与主工作树收尾复核。复核前目标 worker worktree 的 `git status --short --untracked-files=all` 无输出；主工作树存在 3 个分支纪律文档变更，它们不属于本轮 Goal GDR 修复范围，已单独标记为外部治理变更并保持原样。本次 Goal 收尾只声明本节列出的报告/工具说明/自测文件修改。新增 Goal 控制面、权威文档和报告制品已经进入 Git 跟踪面。`.worktree/` 是父级工作区的本地执行目录，不是目标 worker worktree 内的仓内目录。

| 状态                     | 路径                                                      | 注意事项                                                                                                             |
| ------------------------ | --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| clean baseline           | worker repo root                                          | worker-1 复核开始时 `git status --short --untracked-files=all` 无输出。                                              |
| scoped edit              | `report/goal/README.md`                              | 本次补录报告入口的当前 Git/ignore 边界。                                                                             |
| scoped edit              | `report/goal/ISSUE-LEDGER.md`                        | 本次补录 residual 项的复核结论。                                                                                     |
| scoped edit              | `report/goal/goal-docs-fix-verification-20260609.md` | 本次补录修复验收证据。                                                                                               |
| scoped edit              | `docs/goal/tools/README.md`                               | 为 `GDR-FIXTURE-01` 增加负例 fixture 覆盖契约，未新增依赖。                                                          |
| scoped edit              | `docs/goal/tools/self-test.sh`                            | 为 `GDR-FIXTURE-01` 提供正向基线与负向 fixture 自测入口，未新增依赖。                                                |
| external governance edit | `CLAUDE.md`                                               | 当前主工作树存在分支创建纪律补充；不纳入本轮 Goal GDR 验收面。                                                       |
| external governance edit | `CONSTITUTION.md`                                         | 当前主工作树存在分支创建纪律补充；不纳入本轮 Goal GDR 验收面。                                                       |
| external governance edit | `docs/governance/DEVELOPMENT-WORKFLOW.md`                 | 当前主工作树存在分支创建纪律补充；不纳入本轮 Goal GDR 验收面。                                                       |
| tracked                  | `.config/goal/schema/rules.yaml`                          | `git ls-files --error-unmatch .config/goal/schema/rules.yaml` 通过，控制面 schema 已在跟踪面内。                     |
| tracked                  | `docs/goal/00-authority-map.md`                           | `git ls-files --error-unmatch docs/goal/00-authority-map.md` 通过，权威映射已在跟踪面内。                            |
| tracked                  | `report/goal/README.md`                              | 报告目录入口已在跟踪面内。                                                                                           |
| tracked                  | `report/goal/goal-docs-fix-verification-20260609.md` | 修复验收报告已在跟踪面内。                                                                                           |
| not ignored              | `.config/goal/schema/rules.yaml`                          | `git check-ignore -v .config/goal/schema/rules.yaml` 无输出，符合控制面可审查边界。                                  |
| ignored                  | `.config/goal/runtime/cache.json`                         | 被 `.gitignore:30:.config/goal/**/runtime/` 忽略；runtime 缓存保持忽略符合预期。                                     |
| ignored local            | `/home/workspace/ZoneCNH/.worktree/todo.md`                         | `git -C /home/workspace/ZoneCNH check-ignore -v .worktree/todo.md` 命中 `.gitignore:38:.worktree/`；本地执行 TODO 保持不入库。 |

## 文件生命周期

- 正式审计报告保留原文，不覆盖、不重写。
- `README.md` 是报告目录入口；`ISSUE-LEDGER.md` 是 canonical 执行账本。
- 后续执行计划、复评分报告和关闭证据可以追加新文件，但必须引用 canonical GDR ID。
- 历史分析只能作为诊断证据，不能覆盖 `docs/goal/` 或 `.config/goal/` 中当前权威规范。

## 关闭规则

关闭任何 GDR 问题时必须同时记录：

- canonical GDR ID。
- 被关闭的原始来源 ID。
- 影响文件。
- 验收证据。
- 至少一个验证命令或明确的不可验证原因。

不能只用叙述性说明关闭问题。
