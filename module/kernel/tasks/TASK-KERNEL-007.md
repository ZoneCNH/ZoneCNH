# TASK-KERNEL-007

> versionx 子包：版本信息与兼容性判断

---

```yaml
task_id: TASK-KERNEL-007
module: kernel
scope: "实现 versionx 子包：BuildInfo、Compatibility、VersionInfo 别名"
spec_ref:
  - "module/kernel/SPEC.md#FR-009"
  - "module/kernel/SPEC.md#9.9"
  - "module/kernel/SPEC.md#10.4"
  - "module/kernel/SPEC.md#10.5"
files:
  - "versionx/versionx.go"
  - "versionx/versionx_test.go"
  - "versionx/example_test.go"
acceptance_criteria:
  - "AC-013: Compatibility.CompatibleWith 模块/版本匹配正确"
  - "AC-VERSIONX-01: NewBuildInfo 返回含全部字段的 BuildInfo"
  - "AC-VERSIONX-02: Compatibility.Major 为空时仅校验 Module"
  - "AC-VERSIONX-03: go test -race -count=1 ./versionx/... 通过"
depends_on:
  - "TASK-KERNEL-000"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| FR-009 | 版本信息 |

## Non-scope

- 不包含 semver 解析库
- 不包含运行时版本检查

## Implementation Notes

- BuildInfo 字段通过 ldflags 在构建时注入
- VersionInfo 是 `type VersionInfo = BuildInfo`（类型别名，已 deprecated）
- CompatibleWith 仅做 Module + Major 字符串匹配
