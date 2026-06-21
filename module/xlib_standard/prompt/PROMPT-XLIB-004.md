# Context Packet — TASK-XLIB-004

> PR-5：release 标准 — release manifest、semver 兼容矩阵
> 工作分支: `feat/xlib-v1-release`

## Current Task

TASK-XLIB-004: release manifest 生成和 semver 兼容矩阵

## Related Spec

- module/xlib_standard/SPEC.md §21 Release DoD, §22 Upgrade Compatibility

## Related Requirements

- FR-013: release manifest 字段完整
- FR-014: release final check checksum 通过
- AC-001~AC-005

## Current Scope

1. **release/manifest/** — release_check.sh 生成 `latest.json` + `latest.json.sha256`
2. **SEMANTIC-VERSIONING.md** — ErrorKind / Metrics / Generator 参数兼容性矩阵
3. **.gitignore** — 忽略 `release/manifest/latest.json*`

## Out of Scope

- 不发布 tag、不推送远端
- 不把 governance score、agent review、docker runtime 写入 manifest
- 不改变前序标准库 API

## Allowed Files

- `release/manifest/` (目录)
- `SEMANTIC-VERSIONING.md`
- `.gitignore`

## Prohibited Actions

- 禁止引入新依赖
- 禁止修改 pkg/templatex/
- 禁止发布 git tag

## Acceptance Criteria

- AC-001: `release_check.sh` 生成 `release/manifest/latest.json` 和 `.sha256`
- AC-002: manifest 包含 module_path/package_name/version/commit/tree_sha/go_version/contracts_sha256/gates/generated_at
- AC-003: manifest 不包含 goal_runtime/score/debt/branch_governance/agent_review/downstream_matrix/docker_runtime
- AC-004: `.gitignore` 包含 release manifest 路径
- AC-005: `SEMANTIC-VERSIONING.md` 覆盖 ErrorKind / Metrics / Generator 兼容性

## Validation Commands

```bash
GOWORK=off make release-check
test -f release/manifest/latest.json
test -f release/manifest/latest.json.sha256
cat release/manifest/latest.json | python3 -m json.tool
grep "goal_runtime" release/manifest/latest.json  # 应无输出
```

## Evidence Format

```markdown
- **Evidence ID**: EVID-TEST-TASK-XLIB-004-001
- **Task ID**: TASK-XLIB-004
- **Status**: PASS/FAIL
- **Validation Run**: <命令及输出>
- **Files Changed**: <文件列表>
- **AC Verified**: AC-001~AC-005
- **Timestamp**: <ISO-8601>
- **Verifier**: <agent/human>
```

## Test Case Reference

参见 `module/xlib_standard/TRACEABILITY.md` FR-013 / FR-014 对应 TC。
