# TASK-ALERTX-002

> 规则引擎核心：DSL 解析 + 评估器 + 热加载

---

```yaml
task_id: TASK-ALERTX-002
module: alertx
scope: "实现 YAML 规则 DSL 解析器（condition 表达式）+ RuleEvaluator 接口实现 + RuleStore 热加载（fsnotify/轮询）"
spec_ref:
  - "module/alertx/SPEC.md#FR-001"
  - "module/alertx/SPEC.md#FR-007"
  - "module/alertx/SPEC.md#BR-003"
  - "module/alertx/SPEC.md#BR-004"
files:
  - "pkg/alertx/evaluator.go"
  - "pkg/alertx/rule.go"
  - "internal/config/rule_parser.go"
  - "internal/config/rule_parser_test.go"
acceptance_criteria:
  - "AC-001: 合法 YAML 加载为 []contracts.AlertRule；非法 DSL 返回 ErrRuleInvalid 阻塞启动"
  - "AC-007: 规则文件变更触发热加载；校验通过原子替换；校验失败保留旧规则"
  - "AC-010: 零 SuppressWindow 规则被拒绝（用全局默认）"
  - "AC-011: DSL 校验失败阻塞启动（退出码非零）"
  - "TestRuleEvaluator_LoadValid/LoadInvalid/EvaluateMatch 通过"
  - "TestRuleReload_HotReload/ConcurrentWithEval 通过（-race）"
depends_on:
  - "TASK-ALERTX-001"
estimated_effort: "4h"
priority: P0
status: pending
```

## Non-scope

- 不实现去重抑制（TASK-003）/通知（TASK-005）
- 不实现订阅源归一化（TASK-006）
