# TASK-ALERTX-008

> email + pagerduty 渠道 + Soak harness + AT-007 集成测试

---

```yaml
task_id: TASK-ALERTX-008
module: alertx
scope: "实现 email/pagerduty 通知渠道 + Soak harness（≥10min 内存/goroutine 监控）+ AT-007 横切贯穿集成测试 + CI 工作流 + Makefile + 发布 manifest 工具"
spec_ref:
  - "module/alertx/SPEC.md#FR-004"
  - "module/alertx/SPEC.md#BR-001"
  - "module/alertx/SPEC.md#BR-002"
  - "module/alertx/SPEC.md#15"
  - "module/alertx/SPEC.md#19"
files:
  - "internal/channel/email.go"
  - "internal/channel/pagerduty.go"
  - "testkit/soak_harness.go"
  - "test/at007_integration_test.go"
  - ".github/workflows/ci.yml"
  - "Makefile"
acceptance_criteria:
  - "AC-008: 告警不丢失（CI alert-no-loss-check 通过）；AC-009: 通知幂等（CI notify-idempotent-check 通过）"
  - "email/pagerduty 渠道实现 + 测试通过"
  - "TestAT007_CrossCutting 通过（//go:build integration）：alertx 收事件+通知+trace ID+多模块并发不丢"
  - "Soak harness ≥10min 无内存/goroutine 泄漏（NFR-004）"
  - "CI workflow（ci/release/security/integration）+ Makefile（ci/release-check/release-final-check）就绪"
  - "release manifest 生成工具可用"
depends_on:
  - "TASK-ALERTX-007"
estimated_effort: "5h"
priority: P1
status: pending
```

## Non-scope

- 不实现核心引擎（TASK-001~007 已完成）
- 不实现 Soak 之外的性能优化（Benchmark 守护在 TASK-002/005）
