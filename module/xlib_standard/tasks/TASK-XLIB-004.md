# TASK-XLIB-004

> PR-5：release 标准 — release manifest、semver 兼容矩阵

---

```yaml
task_id: TASK-XLIB-004
module: xlib_standard
scope: "实现 release manifest 生成和 semver 兼容矩阵"
spec_ref:
  - "module/xlib_standard/SPEC.md#21"
  - "module/xlib_standard/SPEC.md#22"
  - "module/xlib_standard/goal.md#11"
files:
  - "release/manifest/ (目录)"
  - "SEMANTIC-VERSIONING.md"
  - ".gitignore"

files_change:
- "release/manifest/ (目录)"
  - "SEMANTIC-VERSIONING.md"
  - ".gitignore"
acceptance_criteria:
  - "AC-001: release_check.sh 生成 release/manifest/latest.json 和 latest.json.sha256"
  - "AC-002: manifest 包含 module_path/package_name/version/commit/tree_sha/go_version/contracts_sha256/gates/generated_at"
  - "AC-003: manifest 不包含 goal_runtime/score/debt/branch_governance/agent_review/downstream_matrix/docker_runtime"
  - "AC-004: .gitignore 包含 release/manifest/latest.json 和 release/manifest/latest.json.sha256"
  - "AC-005: SEMANTIC-VERSIONING.md 包含 ErrorKind/Metrics/Generator 参数的兼容性矩阵"
depends_on:
  - "TASK-XLIB-002"
  - "TASK-XLIB-008"
estimated_effort: "1h"
priority: P0
status: pending
```

---

## Scope

- 实现 release manifest 生成和 checksum 输出。
- 更新 `.gitignore`，忽略生成的 release manifest 文件。
- 编写 `SEMANTIC-VERSIONING.md` 的兼容矩阵。

## Non-scope

- 不发布 tag、不推送远端、不执行生产发布。
- 不把 governance score、agent review、docker runtime 或 downstream matrix 写入 manifest。
- 不改变前序标准库 API。

## Acceptance

- `GOWORK=off make release-check` 生成 `release/manifest/latest.json` 与 `.sha256`。
- manifest 包含标准字段且不包含治理运行时字段。
- `SEMANTIC-VERSIONING.md` 覆盖 ErrorKind、Metrics 与 Generator 参数兼容性。

## Requirements Covered

| Requirement | Description           | Acceptance Criteria     |
| ----------- | --------------------- | ----------------------- |
| FR-013      | release manifest      | manifest 生成且字段完整 |
| FR-014      | release final check   | checksum 校验通过       |
| §21         | Upgrade Compatibility | 兼容性矩阵文档          |
| §22         | Release DoD           | 发布完成定义            |

## Test Plan

```bash
# 验收命令
GOWORK=off make release-check
test -f release/manifest/latest.json
test -f release/manifest/latest.json.sha256
cat release/manifest/latest.json | python3 -m json.tool  # 验证 JSON 合法
grep "goal_runtime" release/manifest/latest.json  # 应无输出
```

## Implementation Notes

1. release_check.sh 按 goal.md §11.1 生成 manifest
2. manifest 字段按 goal.md §11.2 定义
3. .gitignore 按 goal.md §11.3 更新
4. SEMANTIC-VERSIONING.md 按 §21.1 记录 breaking changes
