# 部署清单

> Feature 做完后、PR 前的 RC 检查，以及部署后的 Smoke Test。

最后更新：2026-06-08

---

## Release Candidate 检查

Feature 做完后，进入 PR 前，做一次 RC 检查。

### RC Checklist

```markdown
# Release Candidate Checklist

## Spec

- [ ] Spec status is Approved or Implemented
- [ ] No unresolved Blocking Open Questions
- [ ] Traceability Matrix is complete

## Code

- [ ] Scope matches Spec
- [ ] No unrelated file changes
- [ ] No obvious dead code
- [ ] No unnecessary dependencies
- [ ] No hardcoded secrets

## Tests

- [ ] Unit tests pass
- [ ] Component tests pass
- [ ] E2E tests pass, if applicable
- [ ] Typecheck passes
- [ ] Lint passes
- [ ] Build passes

## UX

- [ ] Empty state works
- [ ] Error state works
- [ ] Loading state works, if applicable
- [ ] Keyboard interaction works
- [ ] Basic accessibility is acceptable

## Docs

- [ ] README updated
- [ ] .env.example updated, if needed
- [ ] Changelog updated
- [ ] Spec status updated
```text

---

## 部署 Checklist

```markdown
# Deployment Checklist

## Build

- [ ] Production build passes
- [ ] Typecheck passes
- [ ] Tests pass
- [ ] No debug logs
- [ ] No unused mock data

## Environment

- [ ] Required env vars documented
- [ ] `.env.example` updated
- [ ] No secrets committed
- [ ] Production env configured

## Security

- [ ] No hardcoded API keys
- [ ] No sensitive logs
- [ ] Auth checked, if applicable
- [ ] Input validation checked
- [ ] Error messages safe

## Smoke Test

- [ ] App loads
- [ ] Core flow works
- [ ] Error state works
- [ ] Refresh works
- [ ] No console errors

## Rollback

- [ ] Previous version available
- [ ] Migration reversible, if applicable
- [ ] Known limitations documented
```text

---

## Smoke Test Spec

部署后快速确认核心功能没有坏。

```markdown
# Smoke Test

## ST-001: App loads

1. Open app URL
2. Confirm homepage renders

Expected:
- Page loads without blank screen
- No critical console error

## ST-002: Core flow

1. Execute primary user action
2. Confirm expected result

Expected:
- Action completes successfully
- Data appears correctly

## ST-003: Error state

1. Trigger a known error condition
2. Confirm error handling

Expected:
- Error message displayed
- App does not crash

## ST-004: Persistence

1. Create data
2. Refresh page

Expected:
- Data persists (if persistence is in MVP)
```text

---

## CI 配置

Spec 做完后，项目骨架完成时就应该加 CI。

### GitHub Actions 示例

```yaml
name: CI

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  check:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Build
        run: go build ./...

      - name: Test
        run: go test ./... -race

      - name: Lint
        uses: golangci/golangci-lint-action@v4
```text

### CI 的作用

```text
防止 AI 写出本地没跑过的代码
防止后续 task 破坏前面功能
防止 review 靠感觉
```text

---

## Changelog 格式

```markdown
# Changelog

## 2026-06-08

### Added

- Implemented SPEC-001 Task CRUD
- Added task creation flow
- Added task validation
- Added empty state
- Added task tests

### Changed

- Updated task feature architecture

### Fixed

- Fixed whitespace-only task validation

### Known Limitations

- No cloud sync
- No authentication
```text

### 从 Diff 生成 Changelog

```markdown
请根据当前 diff 生成 changelog entry。

要求：
- 按 Added / Changed / Fixed / Known Limitations 分类
- 引用相关 Spec 和 Task
- 不夸大功能
- 不写未实现的内容
```text

---

## 文档同步

每做完一个 Feature，至少检查：

```text
README.md
specs/{module}/SPEC.md
specs/{module}/tasks/TASK-*.md
CHANGELOG.md
.env.example
```text

### 同步 Prompt

```markdown
请检查当前实现是否需要更新文档。

参考：
- README.md
- specs/
- CHANGELOG.md
- .env.example

输出：
1. 需要更新的文档
2. 更新原因
3. 建议修改内容
4. 不要修改代码
```text

---

## 什么时候该重构

不要在每个小 task 都重构。推荐在这些节点重构：

- 一个核心流程跑通后
- 一个 Feature 完成后
- 测试补齐后
- 进入下一个大功能前
- 发现重复模式超过 2-3 次后

### 重构 Prompt

```markdown
请对当前 task feature 做小范围重构。

目标：
- 保持外部行为不变
- 保持所有测试通过
- 降低重复
- 提高可读性
- 不改变 public API
- 不引入新依赖
- 不实现新功能

请先输出重构计划，不要直接改代码。
```text

### 重构后验收

```markdown
请确认本次重构没有改变 Spec 行为。

输出：
- Behavior unchanged?
- Tests affected
- Risks
- Files changed
- Any accidental feature changes
```text

---

## 相关文档

| 文档 | 用途 |
|------|------|
| `specs/DEVELOPMENT-WORKFLOW.md` | 完整管线总览 |
| `specs/DEFINITION-OF-DONE.md` | 完成验收条件 |
| `specs/CODING-SESSION-PROTOCOL.md` | 编码会话协议 |
