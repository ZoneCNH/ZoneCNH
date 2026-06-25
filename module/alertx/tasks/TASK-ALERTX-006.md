# TASK-ALERTX-006

> 双订阅：observex 导出流 + 业务事件订阅

---

```yaml
task_id: TASK-ALERTX-006
module: alertx
scope: "实现双订阅：observex Exporter 接口消费（LogEntry/MetricPoint/SpanData）+ 业务域 AlertEvent envelope 订阅 + 事件归一化为评估输入"
spec_ref:
  - "module/alertx/SPEC.md#FR-001"
  - "module/alertx/SPEC.md#5"
  - "module/alertx/ADR-001-foundations.md#D2"
files:
  - "internal/subscribe/observex_subscriber.go"
  - "internal/subscribe/business_subscriber.go"
  - "internal/subscribe/normalizer.go"
  - "internal/subscribe/normalizer_test.go"
acceptance_criteria:
  - "双订阅架构落地：observex 导出流 + 业务 contracts.AlertEvent 订阅（ADR-001 D2）"
  - "事件归一化为 RuleEvaluator.Evaluate 的统一 Event 输入"
  - "TestSubscribe_ObservexInterrupt 通过（EC-007：observex 中断时 health 标 degraded，业务侧继续）"
  - "TestRuleEvaluator_UnknownMetric 通过（EC-005：未知 metric 运行时不匹配）"
  - "-race 通过"
depends_on:
  - "TASK-ALERTX-002"
estimated_effort: "3h"
priority: P1
status: pending
```

## Non-scope

- 不实现规则评估逻辑（TASK-002，本 task 只做事件归一化输入）
- 不实现通知（TASK-005）
