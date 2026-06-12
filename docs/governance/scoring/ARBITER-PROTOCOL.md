# 仲裁协议

> 评分聚合与门禁判定规则。**首选**由确定性脚本 `scripts/arbiter.py` 执行；LLM `pipeline-arbiter` agent 仅作为协议文档参考与兜底（必须输出与脚本相同的 verdict）。

最后更新：2026-06-08

---

## 0. 推荐执行方式

```bash
python3 scripts/arbiter.py <module> <stage> --runtime <claude|codex|copilot>
# 默认读取 SPEC_PIPELINE_RUNTIME；未设置时写入 .omc/state/pipeline/<module>/<stage>/{verdict,attempts}.json
# 退出码 0=pass，1=fail
```

确定性脚本与本协议算法 1:1 对应，单元测试覆盖 13 个分支
（`scripts/tests/test_arbiter.py`）。LLM agent 不再担任 gate 判定者，
仅在脚本不可用或需要诊断时输出参考意见。

## 1. 输入

仲裁器读取：

```text
{state_root}/pipeline/{module}/{stage}/scores/claude.json
{state_root}/pipeline/{module}/{stage}/scores/codex.json
{state_root}/pipeline/{module}/{stage}/scores/copilot.json
{state_root}/pipeline/{module}/{stage}/scores/rules.json
```

四个文件均必须存在；缺一报错并 `gate=fail`，原因 `missing_score_source`。

`state_root` 按运行时选择：Claude `.omc/state`，Codex `.omx/state`，Copilot `.copilot/state`。

`claude` / `codex` / `copilot` 是 LLM scorer 输出。`rules` 是 `scripts/rule-scorer.py`
输出的纯机械规则评分，作为宪法 §14.4 要求的异构信号源，用于打破 LLM 同源相关性。

---

## 2. 门禁判定算法

按顺序执行，**任一规则失败即 `gate=fail`**：

1. **四源齐全**：缺任一源 → fail（`missing_score_source`）。
2. **无红线**：任一源 `redline: true` → fail，记录红线列表。
3. **综合分门禁**：`composite_score = min(claude.score, codex.score, copilot.score, rules.score)`，且 `composite_score >= 98` → 否则 fail。
4. **置信度门禁**：任一 LLM 源 `confidence: low` → fail（`low_confidence_score`）。`rules` 源的 `confidence` 仅作诊断，不参与 gate（规则引擎在 code 阶段允许 low/medium）。
5. **分差门禁**：`max(llm_scores) - min(llm_scores) <= 5`（仅三 LLM 源参与）→ 否则 fail（`score_spread_too_large`）。
6. **异构一致性**：`abs(rules.score - median(llm_scores)) <= 15` → 否则 fail（`heterogeneous_divergence`），提示 LLM 与规则严重分歧，需输出 blocker 诊断或进入元级 RSI。

全部通过 → `gate=pass`。

**纯机器判定，无人工放行分支**。Confidence、平台分差、异构一致性是 gate 条件，写入 `verdict.json` 供自动路由使用。

---

## 3. 输出 Schema

写入 `{state_root}/pipeline/{module}/{stage}/verdict.json`：

```json
{
  "module": "kernel",
  "stage": "matrix",
  "arbitrated_at": "2026-06-08T09:00:00Z",
  "scores": {
    "claude":  { "score": 97, "redline": false, "confidence": "high" },
    "codex":   { "score": 99, "redline": false, "confidence": "high" },
    "copilot": { "score": 98, "redline": false, "confidence": "high" },
    "rules":   { "score": 96, "redline": false, "confidence": "high" }
  },
  "composite_score": 96,
  "score_range": { "min": 96, "max": 99, "spread": 3, "llm_spread": 2 },
  "heterogeneous_divergence": 2,
  "redlines": [],
  "gate": "fail",
  "reasons": ["composite_score(96) < 98"],
  "next_action": "route_to_executor_for_repair",
  "attempt": 1,
  "repair_budget": {
    "stage_attempt": 1,
    "total_gate_failures": 4,
    "max_stage_attempts": 3,
    "max_total_gate_failures": 18
  }
}
```

`confidence`、`score_range.spread`、`heterogeneous_divergence` 同时用于诊断与 gate 判定。
`heterogeneous_divergence = abs(rules.score - median(llm_scores))`，过大表示 LLM 与规则引擎严重分歧（可能 Goodhart 信号）。

---

## 4. 路由规则

| `gate`                 | `next_action`                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------- |
| pass                   | `advance_to_next_stage`；若为 spec 阶段，同时自动翻转 SPEC.md 为 `Status: Approved` |
| fail（红线）           | `route_to_executor_for_repair`，附带所有红线证据                                    |
| fail（分数 < 98）      | `route_to_executor_for_repair`，附带三平台扣分账本合集                              |
| fail（评分源缺失）     | `route_to_missing_score_source`                                                     |
| fail（低置信度）       | `route_to_low_confidence_scorer_for_rerun`                                          |
| fail（分差过大）       | `route_to_scorers_for_reconciliation`                                               |
| fail（异构分歧）       | `route_to_meta_arbiter_for_diagnosis`，附 LLM vs rules 对照表                       |
| fail（全链路预算耗尽） | `pipeline_blocked_for_retrospective`                                                |

普通阶段产物全部为自动路由。不存在通过 `request_human_review` 将 fail 改成 pass 的人工分支。若 retrospective 证明需要修改受保护的评分体系或工作流文件，必须另走 `CONSTITUTION.md` §14 的元级 RSI 流程。

---

## 5. 失败循环（有界自动）

仲裁器维护尝试计数：

```text
{state_root}/pipeline/{module}/{stage}/attempts.json
```

| 尝试次数   | 处理                                                                       |
| ---------- | -------------------------------------------------------------------------- |
| 1-2        | 路由回当前阶段 executor 修复，重跑四源评分 + 仲裁                          |
| 3          | 自动路由回上一阶段 executor（`escalation=upstream`），重置当前阶段 attempt |
| 上游再失败 | 继续向上路由，直到 spec                                                    |
| spec 失败  | 由 spec executor 重写 SPEC.md 后继续评分，但仍计入全链路预算               |

升级链：

```text
code → prompt → plan → tasks → matrix → spec
```

预算：

```text
max_stage_attempts = 3
max_total_gate_failures = 18
```

推进下一阶段的唯一条件：四源仲裁 `gate=pass`。自动修复循环的停止条件：达到 `max_total_gate_failures` 后，仲裁器必须输出 `pipeline_blocked_for_retrospective`，并写入：

```text
{state_root}/pipeline/{module}/pipeline_blocked.json
module/{module}/PIPELINE-RETROSPECTIVE.md
```

`PIPELINE-RETROSPECTIVE.md` 不授予进入下一阶段的权限；它只用于后续人工审阅或创建 `docs/governance/improvements/{YYYYMMDD}-{slug}/SPEC.md` 元级改进规格。

---

## 6. 不可豁免

`gate=pass` 是进入下一阶段的**唯一**条件。任何 agent 或脚本都不得：

- 直接改写 `verdict.json` 让 fail 变 pass。
- 跳过任一评分源的评分。
- 在 attempt 未达成 pass 前推进到下一阶段。

普通产物内的红线类问题（凭证、Constitution 违反、跨模块写入）由 scorer 自动识别报告，仲裁器自动 fail，并按有界 repair routing 修复。若修复需要修改受保护文件或解释/变更宪法规则，必须进入元级 RSI 流程。

受保护文件（rubric、scorer、arbiter、工作流入口、outer metrics、宪法）不得通过普通 repair routing 修改。相关改动必须按 `CONSTITUTION.md` §14 进入元级 RSI 流程。
