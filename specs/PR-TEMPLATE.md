# PR 模板

> PR 描述应引用 Spec，保持代码变更 ↔ Spec ↔ Task ↔ Test 的一致性。

最后更新：2026-06-08

---

## PR 模板

放到 `.github/pull_request_template.md`：

```markdown
# Summary

Briefly describe what this PR changes.

## Related Spec

- SPEC-XXX:

## Related Tasks

- TASK-XXX:

## Requirements Covered

- FR-XXX
- AC-XXX
- TC-XXX

## Changes

- 
- 
- 

## Out of Scope

- 
- 
- 

## Verification

- [ ] go build ./...
- [ ] go test ./... -race
- [ ] golangci-lint run
- [ ] Manual QA completed

## Acceptance Criteria

| AC | Status | Notes |
|---|---|---|
| AC-001 | Pass / Fail | |
| AC-002 | Pass / Fail | |

## Screenshots / Notes

Add screenshots or notes if UI changed.

## Risks

- 
```text

### 这个模板的作用

强迫保持：

```text
代码变更 ↔ Spec ↔ Task ↔ Test
```text

的一致性。

---

## Issue 模板

如果用 GitHub / Linear / Jira，每个 Task 可以变成一个 Issue。

```markdown
# TASK-{NNN}: {任务标题}

## Spec

SPEC-{NNN}: {spec 标题}

## Goal

{一句话目标}

## Scope

- {做什么 1}
- {做什么 2}

## Non-scope

- {不做什么 1}
- {不做什么 2}

## Requirements

- FR-XXX
- FR-XXX

## Acceptance Criteria

- [ ] {验收条件 1}
- [ ] {验收条件 2}
- [ ] Tests added or updated
- [ ] Typecheck passes
- [ ] Lint passes

## Test Plan

- {测试项 1}
- {测试项 2}
```text

---

## Branch 命名规则

每个 Task 一个 branch。

```text
feature/task-002-create-task-flow
feature/task-003-task-list
fix/task-002-validation-error
test/task-009-task-crud-tests
refactor/task-011-task-feature-cleanup
```text

**不要一个 branch 混多个大功能。**

好的：`feature/task-002-create-task-flow`
差的：`feature/build-app`

---

## Commit 规则

Commit 也引用 Task ID。

```text
feat(task-002): add create task form
test(task-002): cover empty task validation
fix(task-002): trim title before saving
docs(task-002): update task implementation notes
```text

### 为什么

```text
哪个 commit 对应哪个 spec？
哪个 task 改了哪些文件？
哪个需求被实现了？
```text

全部可追溯。

---

## 相关文档

| 文档 | 用途 |
|------|------|
| `specs/DEVELOPMENT-WORKFLOW.md` | 完整管线总览 |
| `specs/TASK-TEMPLATE.md` | Task spec 模板 |
| `specs/DEPLOYMENT.md` | 部署清单 |
