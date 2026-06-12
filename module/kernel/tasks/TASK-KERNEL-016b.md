# TASK-KERNEL-016b

> scripts/ + release/：CI 脚本 + Release 预检 + 发布产物

---

```yaml
task_id: TASK-KERNEL-016b
module: kernel
scope: "创建 CI 门禁脚本和 release 发布产物目录"
parent: TASK-KERNEL-016
spec_ref:
  - "module/kernel/SPEC.md#20"
  - "module/kernel/SPEC.md#22"
  - "module/kernel/SPEC.md#BR-009"
files:
  - "scripts/ci/check-stdlib.sh"
  - "scripts/ci/internal/apisnapshot/main.go"
  - "release/manifest/v1.0.0.yaml"
  - "release/dependency/deps.txt"
  - "release/standard-sync/compliance.yaml"
acceptance_criteria:
  - "AC-SCRIPTS-B01: stdlib-only check 脚本可执行"
  - "AC-SCRIPTS-B02: release manifest 含版本/模块/文件清单/签名"
  - "AC-SCRIPTS-B03: make release-preflight 通过"
depends_on:
  - "TASK-KERNEL-014"
estimated_effort: "0.75h"
priority: P1
status: pending
```

## Non-scope

- 不在 release/manifest 中包含绝对路径
- 不在 scripts 中硬编码仓库路径
