> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](13-supreme-clause.md) · [↑ 目录](README.md) · [下一节 →](15-delivery-pipeline.md)

---

## 第十四条：管线自改约束（Anti-Goodhart）

> 适用于 Spec → Code 四源评分管线本身。目的是防止 RSI（递归自我改进）退化为 mode collapse 与 Goodhart 优化。

### 14.1 受保护文件清单

以下文件构成**评分系统根权限**。任何 agent（包括 `spec`、`task-executor`、`pipeline-arbiter`、所有 scorer）一律**禁止写入**：

| 类别       | 路径                                                                                                                     |
| ---------- | ------------------------------------------------------------------------------------------------------------------------ |
| Rubric     | `docs/governance/scoring/RUBRIC-*.md`                                                                                    |
| 评分方法论 | `docs/governance/STRUCTURAL-SCORING.md`                                                                                  |
| 仲裁协议   | `docs/governance/scoring/ARBITER-PROTOCOL.md`                                                                            |
| Agent 配置 | `.claude/agents/`、`.codex/agents/`、`.copilot/agents/` 下所有文件                                                       |
| 工作流入口 | `.claude/commands/spec-code-pipeline.md`、`.codex/skills/spec-code-pipeline/`、`.copilot/commands/spec-code-pipeline.md` |
| 外部指标   | `.omc/state/outer-metrics/`、`.omx/state/outer-metrics/`、`.copilot/state/outer-metrics/` 下所有文件                     |
| 本宪法     | `CONSTITUTION.md`                                                                                                        |

scorer 的 `min ≥ 98` 仲裁结果**不构成**修改上述文件的授权。

### 14.2 外部指标不可篡改

`{state_root}/outer-metrics/{module}.json` 只能由以下来源写入，其中 Claude 使用 `.omc/state`，Codex 使用 `.omx/state`，Copilot 使用 `.copilot/state`：

- CI 流水线（GitHub Actions、外部检查）
- 生产观测系统（实际运行数据）
- Git 历史的机械统计（`git log`、`git blame`）
- 人类维护者的手动登记

任何 LLM agent、scorer、arbiter、executor 均**只读**外部指标，禁止写入或修改。

### 14.3 RSI 合法形式

若需修改 §14.1 中的受保护文件，必须走 **outer-metric 验证的 RSI 流程**：

1. **Fork**：在新分支或新版本目录（`docs/governance/scoring/v{N+1}/`）创建候选 rubric / agent。
2. **A/B**：在至少 3 个真实模块上并行运行旧版与新版评分。
3. **Outer 验证**：以 `outer-metrics/` 中的真实指标（bug 数、返工次数、CI 失败率）评判，**不以 scorer 自身分数评判**。
4. **人类批准**：A/B 结果由人类维护者审阅并批准（这是宪法层面唯一的人工门）。
5. **合并**：批准后才能合并到主版本，旧版本作为历史归档。

未走该流程的任何受保护文件改动一律视为宪法违反，应被代码审查阻塞。

普通阶段产物允许自动修复和上游回退，但评分体系本身的 RSI 不得由当前评分结果自我授权。工作流、rubric、agent、arbiter、命令入口或本宪法的改进必须先作为 `docs/governance/improvements/{YYYYMMDD}-{slug}/SPEC.md` 通过同一条 Spec → Matrix → Tasks → Plan → Prompt → Code 管线，再进入本节的 fork、A/B、outer metric 与人类批准流程。

### 14.4 Goodhart 防线

- 任一 scorer 平台连续 N 个模块的评分与 outer metric 相关系数低于 0.6，必须冻结该 scorer 并触发 §14.3 RSI 流程。
- 任一阶段的"平均通过分数"持续上升但 outer metric 退化，视为 Goodhart 早期信号，必须冻结该阶段评分体系并触发 §14.3。
- 四源 `min ≥ 98` 不豁免本条款，只是必要条件。

### 14.5 同源相关性披露

`claude`、`codex`、`copilot` 三平台底层模型存在训练数据重叠，"独立评分"是工程近似，**不是统计独立**。本宪法承认此局限并要求：

- 任何新加入的平台必须公开模型族系与训练数据假设。
- `rules` 是当前要求的异构第四源；鼓励继续引入不同模型族、不同语料、静态分析器或生产反馈作为补充。
- 当前门禁已扩展为 `claude/codex/copilot/rules` 四源共识；长期目标是继续强化异构多源共识。

### 14.6 例外条款

§14.1 受保护文件清单本身的修订必须走 §14.3 RSI 流程，但 §14.2 至 §14.5 的条款只能由 §第十二条修正程序修改。这是为了防止"通过 RSI 自我废除 Anti-Goodhart 约束"。

### 14.7 与 §19 的关系

§14 管"评分体系本身的 RSI"（受保护文件清单、outer metric 验证）。§19 管"交付流程的 CRI"（模板、Gate、Prompt 的改进）。两者互补：

- §14 的改进必须走 fork/A/B/outer-metric/人类批准
- §19 的改进按风险分级审批
- 两者都禁止自证成功

---
