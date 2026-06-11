# TASK-XLIB-002

> PR-3：骨架代码 — Makefile、scripts、CI

---

```yaml
task_id: TASK-XLIB-002
module: xlib-standard
scope: "重写 Makefile、scripts/、.github/，确保只有最小 gate 集和标准脚本"
spec_ref:
  - "module/xlib-standard/SPEC.md#20"
  - "module/xlib-standard/goal.md#6"
files:
  - "Makefile"
  - "scripts/render_template.sh"
  - "scripts/check_rendered_template.sh"
  - "scripts/check_boundary.sh"
  - "scripts/check_contracts.sh"
  - "scripts/check_security.sh"
  - "scripts/release_check.sh"
  - "scripts/release_final_check.sh"
  - ".github/workflows/ci.yml"

files_change:
- "Makefile"
  - "scripts/render_template.sh"
  - "scripts/check_rendered_template.sh"
  - "scripts/check_boundary.sh"
  - "scripts/check_contracts.sh"
  - "scripts/check_security.sh"
  - "scripts/release_check.sh"
  - "scripts/release_final_check.sh"
  - ".github/workflows/ci.yml"
acceptance_criteria:
  - "AC-001: Makefile 包含 fmt/vet/lint/test/race/contracts/boundary/render-smoke/security/ci/release-check/release-final-check targets"
  - "AC-002: scripts/ 目录只有 7 个脚本"
  - "AC-003: render_template.sh 只接受 --module-path/--package-name/--out/--module-name 参数"
  - "AC-004: check_boundary.sh 检查 6 项（x.go/internal、/home/k8s/secrets/env、foundationx、baselib-template、templatex、xlib-standard）"
  - "AC-005: CI workflow 执行 GOWORK=off make ci 和 GOWORK=off make release-check"
depends_on:
  - "TASK-XLIB-000"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Scope

- 重写 `Makefile`、`scripts/*.sh` 和 `.github/workflows/ci.yml`，提供最小 gate 集。
- 实现 `render_template.sh` 的 4 参数渲染入口。
- 实现 boundary、contracts、security、release check 与 final check 脚本。

## Non-scope

- 不增加 governance runtime 或 agent runtime 检查项。
- 不引入 Docker、devcontainer 或外部 CI 依赖。
- 不扩大模板 API 到非标准库职责。

## Acceptance

- `Makefile` 包含 fmt/vet/lint/test/race/contracts/boundary/render-smoke/security/ci/release-check/release-final-check targets。
- `scripts/` 目录只有 7 个脚本。
- `GOWORK=off make ci` 和 `GOWORK=off make release-check` 可由 CI 执行。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §20.1 | 17 个 CI gate | Makefile 包含全部 gate targets |
| §20.2 | CI 配置 | workflow 执行 make ci |
| FR-009 | render_template.sh | 只接受 4 个参数 |
| FR-011 | 17 个 gate | make ci 全通过 |
| FR-012 | boundary gate | 检查 6 项非法引用 |

## Test Plan

```bash
# 验收命令
make -n fmt  # 应成功
make -n ci  # 应列出所有 gate
ls scripts/*.sh | wc -l  # 应为 7
scripts/render_template.sh --help 2>&1 | grep -c "enable-governance"  # 应为 0
```

## Implementation Notes

1. Makefile 按 goal.md §6.1 重写
2. scripts 按 goal.md §6.2 只保留 7 个
3. render_template.sh 按 goal.md §6.3-§6.4 实现 7 步
4. check_boundary.sh 按 goal.md §6.5 检查 6 项
5. check_contracts.sh 按 goal.md §6.6 检查 3 个 contract
6. check_security.sh 按 goal.md §6.7 检查 5 类密钥
7. CI 按 goal.md §6.8 配置
