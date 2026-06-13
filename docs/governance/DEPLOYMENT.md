# 部署清单

> Feature 做完后、PR 前的 RC 检查，以及部署后的 Smoke Test。

最后更新：2026-06-13

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
```

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
```

---

## 统一 CI/CD 与部署控制面

全局规则：

- 本仓库直接声明的 CI/CD job 必须运行在 self-hosted runner，精确标签为 `[self-hosted, Linux, X64, homepage]`。
- 普通文档、测试、治理类 job 使用业务仓库 profile 标签 `homepage`。
- 部署执行必须通过 `ZoneCNH/sre` reusable workflow；部署 profile 标签由 SRE 仓库内部承接，本仓库不得直接声明。
- 部署控制面权威仓库为 `ZoneCNH/sre`；本仓库只引用，不复制、不收纳 `sre/` 源码。
- 本仓 `release.yml` 只生成并预检 `release/manifest/release-manifest.json` 与 `release/manifest/sre-deploy-contract.json`，不执行真实机器部署。
- SRE 部署合同必须固定 `execution_plane.repository=ZoneCNH/sre`、`workflow=ZoneCNH/sre/.github/workflows/deploy-contract.yml@main`、`runner_pool=sre/`、`remote_execution_allowed_in_this_repo=false`。
- `.gitignore` 必须保留 `sre/`，并由 `.github/ci/deploy-policy-guard.sh` 防止误提交。

业务仓库新增部署时，只允许调用 SRE reusable workflow：

```yaml
jobs:
  deploy:
    uses: ZoneCNH/sre/.github/workflows/deploy-contract.yml@main
    with:
      release_ref: ${{ github.sha }}
      environment: staging
      target: homepage
      target_pool: sre/homepage
      manifest_path: release/manifest/release-manifest.json
      evidence_path: release/manifest/goal-release-gate.json
      dry_run: false
```

部署 workflow 规则：

- 禁止 `pull_request` 触发部署。
- 本仓 `release.yml` 必须先运行 `bash .github/ci/generate-release-manifest.sh`，再运行 `bash .github/ci/deploy-contract-preflight.sh`，预检通过后才允许调用 SRE reusable workflow。
- 必须配置 GitHub Environment；生产部署只能走 `production` 环境审批，真实部署只允许在受保护环境审批后进入 SRE 执行面。
- 必须配置 `concurrency`，避免同一 target/environment 并发发布。
- 禁止在业务仓库 workflow 中内联 `ssh`、`scp`、`rsync`、`kubectl`、`helm`、`systemctl` 或 `docker compose`。
- smoke 和 rollback 必须通过 SRE 仓库的 `deploy/smoke.sh`、`deploy/rollback.sh` 入口承接。

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
```

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
    runs-on: [self-hosted, Linux, X64, homepage]

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
```

仓库全局 CI/CD 禁止 GitHub-hosted runner。本仓库直接 job 统一使用 `[self-hosted, Linux, X64, homepage]`；本仓 release 只做 manifest、contract 和 preflight，真实部署必须调用 SRE 发布入口并以 `sre/` 机器池为目标。

### CI 的作用

```text
防止 AI 写出本地没跑过的代码
防止后续 task 破坏前面功能
防止 review 靠感觉
```

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
```

### 从 Diff 生成 Changelog

```markdown
请根据当前 diff 生成 changelog entry。

要求：
- 按 Added / Changed / Fixed / Known Limitations 分类
- 引用相关 Spec 和 Task
- 不夸大功能
- 不写未实现的内容
```

---

## 文档同步

每做完一个 Feature，至少检查：

```text
README.md
module/{module}/SPEC.md
module/{module}/tasks/TASK-*.md
CHANGELOG.md
.env.example
```

### 同步 Prompt

```markdown
请检查当前实现是否需要更新文档。

参考：
- README.md
- module/
- CHANGELOG.md
- .env.example

输出：
1. 需要更新的文档
2. 更新原因
3. 建议修改内容
4. 不要修改代码
```

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
```

### 重构后验收

```markdown
请确认本次重构没有改变 Spec 行为。

输出：
- Behavior unchanged?
- Tests affected
- Risks
- Files changed
- Any accidental feature changes
```

---

## 相关文档

| 文档                                         | 用途         |
| -------------------------------------------- | ------------ |
| `docs/governance/DEVELOPMENT-WORKFLOW.md`    | 完整管线总览 |
| `docs/governance/DEFINITION-OF-DONE.md`      | 完成验收条件 |
| `docs/governance/CODING-SESSION-PROTOCOL.md` | 编码会话协议 |
