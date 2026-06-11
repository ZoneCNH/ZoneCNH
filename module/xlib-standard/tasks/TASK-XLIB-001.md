# TASK-XLIB-001

> PR-2：文档对齐 — 重写 README、standard.md、INDEX.md

---

```yaml
task_id: TASK-XLIB-001
module: xlib-standard
scope: "重写 README.md 和 docs/ 目录，确保只描述 xlib 标准源职责（Standard Source / Go Reference Template / Generator / Harness Gate / Evidence Runtime），docs 只保留 9 个文件"
spec_ref:
  - "module/xlib-standard/SPEC.md#2"
  - "module/xlib-standard/SPEC.md#4"
  - "module/xlib-standard/goal.md#5"
files:
  - "README.md"
  - "docs/standard.md"
  - "docs/api.md"
  - "docs/config.md"
  - "docs/errors.md"
  - "docs/health.md"
  - "docs/metrics.md"
  - "docs/testing.md"
  - "docs/generation.md"
  - "docs/release.md"

files_change:
- "README.md"
  - "docs/standard.md"
  - "docs/api.md"
  - "docs/config.md"
  - "docs/errors.md"
  - "docs/health.md"
  - "docs/metrics.md"
  - "docs/testing.md"
  - "docs/generation.md"
  - "docs/release.md"
acceptance_criteria:
  - "AC-001: README.md 描述五类职责（Standard Source / Go Reference Template / Generator / Harness Gate / Evidence Runtime）"
  - "AC-002: README.md 不出现 Goal Runtime / Agent Runtime / Debt Governance"
  - "AC-003: docs/ 目录只有 9 个 .md 文件"
  - "AC-004: docs/standard.md 包含 12 章（目的/非目标/仓库结构/公共API/Config/Error/Health/Metrics/Testing/Generator/Gate/Release）"
  - "AC-005: docs/generation.md 只出现 4 个参数（--module-path/--package-name/--out/--module-name）"
depends_on:
  - "TASK-XLIB-000"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Scope

- 重写 `README.md`、`INDEX.md` 和 `docs/*.md`，描述 xlib-standard 的五类职责（标准事实源、Go Reference Template、Generator、Harness Gate、Evidence Runtime）。
- 将 `docs/standard.md` 对齐为 12 章结构。
- 将 `docs/generation.md` 限定为 4 个生成参数。

## Non-scope

- 不恢复 Goal Runtime、Agent Runtime 或 Debt Governance 文档。
- Evidence Runtime（release manifest 生成）是五角色之一，README 中应描述其在标准源中的职责。
- 不新增 docs 目录外的产品说明页。
- 不改变标准库实现代码。

## Acceptance

- `README.md` 描述五类职责，且不出现运行时治理词汇（Goal Runtime / Agent Runtime / Debt Governance）。
- `docs/` 目录只有 9 个 Markdown 文件。
- `docs/generation.md` 不出现 `enable-governance`。

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §2 Summary | 模块定位描述 | README 描述五类职责 |
| §5 Non-goals | 不做运行时 | README 不出现运行时引用 |
| goal.md §5 | PR-2 文档要求 | docs 只保留 9 个文件 |

## Test Plan

```bash
# 验收命令
grep -c "Goal Runtime" README.md  # 应为 0
grep -c "Evidence Runtime" README.md  # 应包含（五角色之一）
ls docs/*.md | wc -l  # 应为 9
grep -c "module-path" docs/generation.md  # 应 > 0
grep -c "enable-governance" docs/generation.md  # 应为 0
```

## Implementation Notes

1. README.md 按 goal.md §5.1 格式重写
2. docs/ 按 goal.md §5.2 只保留 9 个文件
3. docs/standard.md 按 goal.md §5.3 包含 12 章
4. docs/generation.md 按 goal.md §5.4 只支持 4 个参数
