# Evidence — TASK-XLIB-003

```yaml
evidence_id: EVID-XLIB-003
acceptance_criteria_id: AC-003
test_id: TC-XLIB-003
task_id: TASK-XLIB-003
spec_id: SPEC-XLIB-STD-001
goal_id: GOAL-XLIB-STD-001
date: "2026-06-09"
status: PENDING
files_changed:
  - module/xlib-standard/tasks/TASK-XLIB-003.md
  - module/xlib-standard/prompt/PROMPT-XLIB-003.md
commands_run:
  - "GOWORK=off go test ./..."
  - "GOWORK=off go test -race ./..."
```

## 验收结果

| AC | 描述 | 结果 |
|----|------|------|
| AC-003-1 | pkg/templatex/ 11 个文件 | PENDING |
| AC-003-2 | 公共 API 全部存在 | PENDING |
| AC-003-3 | go test 通过 | PENDING |

## 说明

Task spec 和 Prompt 已生成。核心包实现需在上游 xlib-standard 仓库的 `feat/xlib-v1-packages` 分支执行。
