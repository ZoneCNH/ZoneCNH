# TASK-ALERTX-004

> 分级 + 生命周期状态机

---

```yaml
task_id: TASK-ALERTX-004
module: alertx
scope: "实现 severity 分级路由逻辑 + firing/pending/resolved/suppressed 生命周期状态机 + AlertStore 接口（内存实现）"
spec_ref:
  - "module/alertx/SPEC.md#FR-003"
  - "module/alertx/SPEC.md#FR-005"
  - "module/alertx/SPEC.md#BR-006"
files:
  - "pkg/alertx/severity.go"
  - "pkg/alertx/lifecycle.go"
  - "internal/store/memory_store.go"
  - "internal/store/memory_store_test.go"
acceptance_criteria:
  - "AC-003: critical 路由 paging 渠道；warning 通知不 paging；info 仅日志"
  - "AC-005: 状态机 firing→suppressed→resolved 正确流转；抖动 pending 窗口生效；ResolvedAt 记录"
  - "AC-013: critical 必须尝试 paging，不因渠道失败降级为 warning"
  - "TestSeverityRouting_CriticalPages 通过"
  - "TestLifecycle_FiringToResolved 通过"
  - "TestAlertStore_MemoryExhaustion 通过（达上限拒绝+dropped counter）"
depends_on:
  - "TASK-ALERTX-003"
estimated_effort: "3h"
priority: P0
status: pending
```

## Non-scope

- 不实现通知发送（TASK-005）
- 不实现 alertx 进程入口（TASK-007）
