# TASK-KERNEL-016

> docs/ + CHANGELOG + CI gates + Release preflight

---

```yaml
task_id: TASK-KERNEL-016
module: kernel
scope: "创建 docs/ 项目文档、CHANGELOG.md、CI 脚本、release preflight"
spec_ref:
  - "module/kernel/SPEC.md#20"
  - "module/kernel/SPEC.md#22"
files:
  - "CHANGELOG.md"
  - "docs/adr/"
  - "docs/design/"
  - "docs/governance/"
  - "docs/spec/"
  - "docs/standard/"
  - "docs/evidence/"
  - "scripts/ci/internal/apisnapshot/"
  - "release/manifest/"
  - "release/dependency/"
  - "release/standard-sync/"
acceptance_criteria:
  - "AC-018: stdlib-only gate 通过"
  - "AC-RELEASE-01: CHANGELOG.md 记录 v1.0.0 变更"
  - "AC-RELEASE-02: make release-preflight 通过"
  - "AC-RELEASE-03: 发布 manifest 已生成"
  - "AC-RELEASE-04: go test -race -count=1 ./... 全部通过"
  - "AC-RELEASE-05: 覆盖率 >= 80%"
  - "AC-RELEASE-06: go vet 无警告"
  - "AC-RELEASE-07: golangci-lint 无错误"
  - "AC-RELEASE-08: gitleaks 无泄露"
depends_on:
  - "TASK-KERNEL-014"
  - "TASK-KERNEL-015"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description |
|---|---|
| §20 | CI Gate |
| §22 | Release DoD |

## Implementation Notes

- CHANGELOG.md 按 SemVer 记录变更
- scripts/ci/ 包含 stdlib-only 检查等 kernel 专属 gate
- release/manifest/ 记录发布版本、依赖、签名
