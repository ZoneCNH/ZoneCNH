# Context Packet — TASK-XLIB-005

> 最终验收 — 生成库验证、100 次自检、tag v1.0.0
> 工作分支: `feat/xlib-v1-release`

## Current Task

TASK-XLIB-005: 生成库验收、selfcheck-100.sh、最终 gate

## Related Spec

- module/xlib-standard/SPEC.md §22 Release DoD

## Related Requirements

- FR-010: 生成库无模板残留
- FR-014: release final check 通过
- AC-001~AC-007

## Current Scope

1. **selfcheck-100.sh** — 100 次渲染 + 测试脚本
2. **生成库验收** — 临时目录 go test / race / 残留检查
3. **最终 gate** — make ci / release-check / release-final-check

## Out of Scope

- 不创建或推送 git tag
- 不修改已通过验收的标准库 API
- 不扩大生成脚本参数集

## Allowed Files

- `selfcheck-100.sh`

## Prohibited Actions

- 禁止修改 pkg/templatex/ 已验收代码
- 禁止推送 git tag
- 禁止修改生成脚本参数

## Acceptance Criteria

- AC-001: 临时目录生成库 `go test ./...` 通过
- AC-002: 临时目录生成库 `go test -race ./...` 通过
- AC-003: 生成库无 templatex/xlib-standard/foundationx/baselib-template 残留
- AC-004: `selfcheck-100.sh` 100 次全部通过
- AC-005: `make ci` 通过
- AC-006: `make release-check` 通过
- AC-007: `make release-final-check` 通过

## Validation Commands

```bash
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
./selfcheck-100.sh
GOWORK=off make ci
GOWORK=off make release-check
GOWORK=off make release-final-check
```

## Evidence Format

```markdown
- **Evidence ID**: EVID-TEST-TASK-XLIB-005-001
- **Task ID**: TASK-XLIB-005
- **Status**: PASS/FAIL
- **Validation Run**: <命令及输出>
- **Files Changed**: <文件列表>
- **AC Verified**: AC-001~AC-007
- **Timestamp**: <ISO-8601>
- **Verifier**: <agent/human>
```

## Test Case Reference

参见 `module/xlib-standard/TRACEABILITY.md` FR-010 / FR-014 对应 TC。
