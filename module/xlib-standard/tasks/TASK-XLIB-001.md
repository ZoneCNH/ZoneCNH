# TASK-XLIB-001

> PR-2：文档对齐 — 重写 README、standard.md、INDEX.md

---

```yaml
task_id: TASK-XLIB-001
module: xlib-standard
scope: "重写 README.md 和 docs/ 目录，确保只描述 4 项职责，docs 只保留 9 个文件"
spec_ref:
  - "module/xlib-standard/SPEC.md#2"
  - "module/xlib-standard/SPEC.md#4"
  - "module/xlib-standard/goal/1.md#5"
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
acceptance_criteria:
  - "AC-001: README.md 只描述 4 项职责（定义标准、提供模板、生成库、最小 gate）"
  - "AC-002: README.md 不出现 Goal Runtime / Evidence Runtime / Agent Runtime / Debt Governance"
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

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| §2 Summary | 模块定位描述 | README 只描述 4 项职责 |
| §5 Non-goals | 不做运行时 | README 不出现运行时引用 |
| goal/1.md §5 | PR-2 文档要求 | docs 只保留 9 个文件 |

## Test Plan

```bash
# 验收命令
grep -c "Goal Runtime" README.md  # 应为 0
grep -c "Evidence Runtime" README.md  # 应为 0
ls docs/*.md | wc -l  # 应为 9
grep -c "module-path" docs/generation.md  # 应 > 0
grep -c "enable-governance" docs/generation.md  # 应为 0
```

## Implementation Notes

1. README.md 按 goal/1.md §5.1 格式重写
2. docs/ 按 goal/1.md §5.2 只保留 9 个文件
3. docs/standard.md 按 goal/1.md §5.3 包含 12 章
4. docs/generation.md 按 goal/1.md §5.4 只支持 4 个参数
