# TASK-XLIB-005

> 最终验收 — 生成库验证、100 次自检、tag

---

```yaml
task_id: TASK-XLIB-005
module: xlib-standard
scope: "生成库验收、100 次自检脚本、tag v1.0.0"
spec_ref:
  - "module/xlib-standard/SPEC.md#22"
  - "module/xlib-standard/goal.md#12"
  - "module/xlib-standard/goal.md#13"
files:
  - "selfcheck-100.sh"
acceptance_criteria:
  - "AC-001: 临时目录生成库 GOWORK=off go test ./... 通过"
  - "AC-002: 临时目录生成库 GOWORK=off go test -race ./... 通过"
  - "AC-003: 生成库无 templatex/xlib-standard/foundationx/baselib-template 残留"
  - "AC-004: selfcheck-100.sh 100 次全部通过"
  - "AC-005: GOWORK=off make ci 通过"
  - "AC-006: GOWORK=off make release-check 通过"
  - "AC-007: GOWORK=off make release-final-check 通过"
depends_on:
  - "TASK-XLIB-000"
  - "TASK-XLIB-001"
  - "TASK-XLIB-002"
  - "TASK-XLIB-008"
  - "TASK-XLIB-004"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Scope

- 验证生成库不含模板残留并通过普通测试与 race 测试。
- 创建并执行 `selfcheck-100.sh`。
- 执行最终 `ci`、`release-check` 与 `release-final-check` gate。

## Non-scope

- 不创建或推送 git tag。
- 不修改已通过验收的标准库 API。
- 不扩大生成脚本参数集。

## Acceptance

- 临时目录生成库 `GOWORK=off go test ./...` 和 `GOWORK=off go test -race ./...` 通过。
- 生成库不包含 templatex、xlib-standard、foundationx 或 baselib-template 残留。
- `./selfcheck-100.sh`、`GOWORK=off make ci`、`GOWORK=off make release-check`、`GOWORK=off make release-final-check` 全部通过。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-010 | 生成库无模板残留 | 生成库不包含 templatex、xlib-standard、foundationx 或 baselib-template 残留 |
| FR-014 | release final check | release-final-check 通过 |
| §22 | Release DoD | 所有 AC 通过 |
| goal.md §12 | 生成库验收 | 临时目录测试通过 |
| goal.md §13 | 最终验收命令 | 100 次自检通过 |

## Test Plan

```bash
# 验收命令
tmp="$(mktemp -d)"
scripts/render_template.sh \
  --module-path github.com/ZoneCNH/kernel \
  --package-name kernel \
  --out "$tmp/kernel"
cd "$tmp/kernel"
GOWORK=off go test ./...
GOWORK=off go test -race ./...
! grep -R "templatex" "$tmp/kernel" --exclude-dir=.git
! grep -R "xlib-standard" "$tmp/kernel" --exclude-dir=.git
cd -
rm -rf "$tmp"

# 100 次自检
./selfcheck-100.sh

# 最终门控
GOWORK=off make ci
GOWORK=off make release-check
GOWORK=off make release-final-check
```

## Implementation Notes

1. 按 goal.md §12 实现生成库验收流程
2. 创建 selfcheck-100.sh 脚本，100 次渲染 + 测试
3. 按 goal.md §13 执行最终验收
4. 全部通过后 tag v1.0.0
