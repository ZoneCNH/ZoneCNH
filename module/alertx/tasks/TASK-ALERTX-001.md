# TASK-ALERTX-001

> 契约对接层：alertx 本地类型 + contracts v1.6.0 对接

---

```yaml
task_id: TASK-ALERTX-001
module: alertx
scope: "建立 alertx 仓骨架（go.mod/cmd/pkg/internal 目录）+ 对接 contracts.AlertEvent/AlertRule 类型 + version.go + 基础 errors.go/options.go"
spec_ref:
  - "module/alertx/SPEC.md#8"
  - "module/alertx/SPEC.md#9"
  - "module/alertx/SPEC.md#13"
  - "module/alertx/SPEC.md#14"
files:
  - "go.mod"
  - "pkg/alertx/version.go"
  - "pkg/alertx/errors.go"
  - "pkg/alertx/options.go"
acceptance_criteria:
  - "go.mod module 路径为 github.com/ZoneCNH/alertx，依赖 contracts v1.6.0-alert（本地 replace 指向 /home/contracts）"
  - "version.go Version = v1.0.0"
  - "errors.go 定义 sentinel errors：ErrRuleInvalid/ErrChannelUnknown/ErrSuppressWindowZero/ErrNotifyFailed/ErrRuleLoadFailed/ErrStoreUnavailable"
  - "go build ./... 编译通过"
  - "go vet ./... 零警告"
depends_on: []
estimated_effort: "1h"
priority: P0
status: pending
```

## Non-scope

- 不实现规则引擎/去重/通知逻辑（TASK-002~005）
- 不写业务测试（仅 build/vet 通过即可）
