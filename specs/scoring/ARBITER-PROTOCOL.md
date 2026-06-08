# 仲裁协议

> 三平台评分聚合与门禁判定规则。`pipeline-arbiter` agent 必须严格遵守本协议。

最后更新：2026-06-08

---

## 1. 输入

仲裁器读取：

```text
.omx/state/pipeline/{module}/{stage}/scores/claude.json
.omx/state/pipeline/{module}/{stage}/scores/codex.json
.omx/state/pipeline/{module}/{stage}/scores/copilot.json
```

三个文件均必须存在；缺一报错并 `gate=fail`，原因 `missing_platform_score`。

---

## 2. 门禁判定算法

按顺序执行，**任一规则失败即 `gate=fail`**：

1. **三平台齐全**：缺平台 → fail（`missing_platform_score`）。
2. **无红线**：任一平台 `redline: true` → fail，记录红线列表。
3. **综合分门禁**：`composite_score = min(claude.score, codex.score, copilot.score)`，且 `composite_score >= 98` → 否则 fail。
4. **置信度门禁**：任一平台 `confidence: low` → fail（`low_confidence_score`）。
5. **分差门禁**：`max(score) - min(score) <= 5` → 否则 fail（`score_spread_too_large`）。

全部通过 → `gate=pass`。

**纯机器判定，无人工分支**。Confidence 与平台分差是 gate 条件，写入 `verdict.json` 供自动路由使用。

---

## 3. 输出 Schema

写入 `.omx/state/pipeline/{module}/{stage}/verdict.json`：

```json
{
  "module": "kernel",
  "stage": "matrix",
  "arbitrated_at": "2026-06-08T09:00:00Z",
  "scores": {
    "claude":  { "score": 97, "redline": false, "confidence": "high" },
    "codex":   { "score": 99, "redline": false, "confidence": "high" },
    "copilot": { "score": 98, "redline": false, "confidence": "high" }
  },
  "composite_score": 97,
  "score_range": { "min": 97, "max": 99, "spread": 2 },
  "redlines": [],
  "gate": "fail",
  "reasons": ["composite_score(97) < 98"],
  "next_action": "route_to_executor_for_repair",
  "attempt": 1
}
```

`confidence` 与 `score_range.spread` 字段同时用于诊断与 gate 判定。

---

## 4. 路由规则

| `gate` | `next_action` |
|--------|---------------|
| pass | `advance_to_next_stage`；若为 spec 阶段，同时自动翻转 SPEC.md 为 `Status: Approved` |
| fail（红线） | `route_to_executor_for_repair`，附带所有红线证据 |
| fail（分数 < 98） | `route_to_executor_for_repair`，附带三平台扣分账本合集 |
| fail（平台缺失） | `route_to_missing_platform_scorer` |
| fail（低置信度） | `route_to_low_confidence_scorer_for_rerun` |
| fail（分差过大） | `route_to_scorers_for_reconciliation` |

全部为自动路由。不存在 `request_human_review` 或任何人工分支。

---

## 5. 失败循环（全自动）

仲裁器维护尝试计数：

```text
.omx/state/pipeline/{module}/{stage}/attempts.json
```

| 尝试次数 | 处理 |
|----------|------|
| 1-2 | 路由回当前阶段 executor 修复，重跑三平台评分 + 仲裁 |
| 3+ | 自动路由回上一阶段 executor（`escalation=upstream`），重置 attempt |
| 上游再失败 | 继续向上路由，直到 spec |
| spec 失败 | 由 spec executor 重写 SPEC.md 后继续循环，无次数上限 |

升级链（**全自动循环，无人工接管**）：

```text
code → prompt → plan → tasks → matrix → spec → spec → spec ...
```

终止条件唯一：三平台仲裁 `gate=pass`，自动推进下一阶段。

---

## 6. 不可豁免

`gate=pass` 是进入下一阶段的**唯一**条件。任何 agent 或脚本都不得：

- 直接改写 `verdict.json` 让 fail 变 pass。
- 跳过任一平台的评分。
- 在 attempt 未达成 pass 前推进到下一阶段。

红线类问题（凭证、Constitution 违反、跨模块写入）由 scorer 自动识别报告，仲裁器自动 fail，executor 自动修复，全流程无人工介入。
