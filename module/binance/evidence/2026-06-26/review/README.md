# module/binance review

审查记录与裁决。Gate 级 review 状态见 `.config/goal/gates/`。

## 审查记录模板

```yaml
review_id: REV-<task-id>-YYYYMMDD-NNN
task_id: TASK-xxx
reviewer: <agent-or-human>
date: YYYY-MM-DD
verdict: APPROVE | REJECT | CHANGES_REQUESTED
findings:
  - severity: P0 | P1 | P2
    description: ...
    resolution: ...
risk_accepted: [RISK-xxx]
evidence_id: EVID-xxx
```

## 与 `.config/goal/gates/` 的关系

G9 Review Gate 的终态裁决记录在 `.config/goal/gates/state.yaml`。本目录为模块本地审查记录投影。
