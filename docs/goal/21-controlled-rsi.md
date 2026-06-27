# 受控递归改进

> **本文件是 Controlled RSI 的操作性 SSOT。** `rsi-standard/` 子目录为完整标准参考附录（只读），`26-rsi-full-standard.md` 为指向本文件的索引指针。三者冲突时以本文件为准。

Controlled RSI 基于证据改进工程工作流资产（模板/Prompt/Gate/矩阵字段/检查清单/评估集），不修改产品目标或生产代码。

## 可改进对象

| 对象 | 示例 |
| --- | --- |
| Templates | Goal/Spec/Task/Review 模板 |
| Prompts | Task/Review/Verifier Prompt |
| Gates | 追溯/风险/证据/发布检查 |
| Matrix Fields | 风险/指标/证据/owner 字段 |
| Checklists | 安全/隐私/性能/回滚/观测性 |
| Knowledge Libraries | 失败模式/风险库/决策记录 |
| Eval Datasets | 历史案例评估集 |
| Scorecards | 工作流/交付质量/有效性评分 |

## 禁止自动改动

以下 MUST NOT 由 RSI 自动修改：已批准 Goal 的目标/非目标/成功指标、P0/P1 AC；安全/隐私/资金/权限/数据保留约束；发布 Gate/回滚/事故处理；生产代码与配置、测试标准/证据要求；任何降低审查强度或改变责任归属的规则。

此类变更必须走 CR + Human Approval。

## 改进循环

| 阶段 | 输入 | 输出 |
| --- | --- | --- |
| Observe | 测试失败、评审发现、指标偏差、事故、返工 | 事实清单 |
| Diagnose | 追溯缺口、Prompt 误导、Gate 缺失、模板歧义 | 根因分析 |
| Propose | 模板补丁、Prompt 补丁、Gate 补丁、评估集补充 | 改进提案 |
| Validate | 历史案例回放、规则测试、样例任务验证 | 验证报告 |
| Approve | workflow owner 审核 | 批准/拒绝 |
| Apply | 版本化合入资产 | Workflow Change Log |
| Measure | 缺陷率、返工率、漏检率 | Scorecard |

## 迭代预算与停止条件

首次修改前 MUST 写明：`max_iterations`（默认 3 轮，超限需 Human Approval）、`scope`（允许的资产范围）、`protected_asset_policy`（触碰受保护资产时只能生成 CR）、`validation_command`、`stop_condition`。

MUST 在以下任一条件出现时停止：
- R0-R9 全部通过且验证已记录。
- 需要 Human Approval 或受保护资产同步。
- 剩余问题只能标记为 Hypothesis，缺少仓库证据。
- 新一轮不能提高可执行性/可验证性/可阻断性/可审计性。

## R0-R9 控制 Gate

任一 Gate 无法证明时，改进进入 Backlog 或 Change Request，MUST NOT 直接应用。

| Gate | 证明对象 | 阻断条件 |
| --- | --- | --- |
| R0 Evidence Intake | 有事实来源 | 无失败证据/评审发现/指标偏差/事故记录；Hypothesis 未标记 |
| R1 Scope Classification | 对象分类正确 | 把 Goal/P0 AC/安全/隐私/资金/权限/数据保留约束伪装成模板优化 |
| R2 Protected Asset Check | 不触碰受保护资产 | 需改 Constitution/CI/agent 配置/schema 投影/Release Gate/Rollback/Incident 规则但无 CR |
| R3 Safety Preservation | 不降低约束 | 删除失败测试、降低 Gate、放宽证据、改变责任归属、减少审查源 |
| R4 Evaluation Replay | 历史可回放 | 改动无法用历史样例/当前任务验证 |
| R5 Projection Consistency | 投影与 SSOT 一致 | 配置与 docs/goal/ 新规则漂移且未登记 |
| R6 Approval | 审批明确 | 无 workflow owner 或 Human Approval |
| R7 Rollout Scope | 灰度可控 | 无适用范围/回退边界/版本记录 |
| R8 Rollback | 可回滚 | 无 rollback plan |
| R9 Retrospective | 效果可衡量 | 无后续指标/复盘窗口 |

## RSI Scorecard

每项改进按 0-5 分记录：Impact（缺陷/返工/风险）、Risk（语义/审批/安全边界）、Verifiability（replay/validator/CI）、Maintenance Cost（维护负担）、Safety Preservation（安全/隐私/资金/权限/数据保留）。Auto-allowed 仅适用于低风险、可回滚、R0-R9 均通过的澄清性改进。

## Rollback 与 Replay

- 每个 Patch MUST 有 rollback plan；触碰 Prompt/Template/Gate/Matrix/Checklist 的改进 MUST 先执行 Evaluation Replay。
- `.config/goal/schema/rules.yaml`、`.github/workflows/`、`.claude/agents/`、`.codex/agents/` 是投影面，MUST NOT 由 RSI 自动改写。
- Rollback/Release Gate/Incident/P0 AC/安全/隐私/资金/权限/数据保留约束 MUST NOT 被 RSI 放宽。

## 触发信号

| 信号 | 可能含义 |
| --- | --- |
| 同类 review finding 重复出现 | Review Checklist 或 Prompt 缺少约束 |
| 线上指标失败但测试覆盖声称完整 | Matrix 没连接真实指标 |
| Task 反复返工 | Spec/Task 切分不清或 Prompt 缺上下文 |
| Agent 修改越界文件 | Allowed Files 或执行边界不清 |
| AC 无法验证 | Goal/Spec 验收标准不可测 |
| 发布后回滚困难 | Release Gate 缺少 rollback evidence |
| 指标口径争议 | Observability Contract 缺字段或 owner |

这些信号应进入 Improvement Backlog。

## 必备产物

必须产出：Retrospective Report、Root Cause Analysis、Improvement Backlog、Improvement Matrix、Workflow Change Log、Eval Dataset、Scorecard、Safety Case。

## 不变量

- 不修改目标适配结果，不删除失败证据；不用新指标替代旧指标（除非 CR 映射）。
- 不伪装为自动批准，不让同一 Agent 绕过 builder/reviewer 分离。
- 不降低安全/隐私/资金/权限/数据约束（见[禁止自动改动]），不把流程复杂度转嫁给低风险任务。

## 策略级别

| 级别 | 允许动作 | 例子 |
| --- | --- | --- |
| Auto-allowed | 不改变语义的澄清 | 修正错字、补充说明 |
| Propose-only | 可能影响执行行为 | 新 Gate/约束/字段 |
| Approval-required | 改变版本或评分规则 | 修改门禁阈值 |
| Forbidden | 降低质量/安全/追溯 | 删除测试、放宽 AC |

## 角色边界

| 角色 | 职责 |
| --- | --- |
| Code Agent | 实现，不修改规则 |
| Review / Improvement Agent | 审查缺陷，基于证据提出补丁 |
| Workflow Owner | 批准/拒绝/回滚 |

## 最小可行 RSI

每次中等以上交付后回答：哪个问题实现后才暴露？哪个模板/Prompt/Gate/Matrix 本应提前捕获？有无历史案例验证？补丁是否降低标准？下一个任务如何度量？五项缺一不可进入补丁流程。
