---
module: xlib-harness
scope: "xlib-harness public docs and secret scan release contract"
spec_ref:
  - "module/xlib-harness/SPEC.md#NFR-005"
  - "module/xlib-harness/SPEC.md#AC-007"
acceptance_criteria:
  - "Code repository FEATURES.md and ACCEPTANCE.md exist and match the released evidence baseline"
  - "CI/CD secret scan uses a license-free pinned open-source CLI"
files:
  - "/home/xlib-harness/FEATURES.md"
  - "/home/xlib-harness/ACCEPTANCE.md"
  - "/home/xlib-harness/.github/workflows/ci.yml"
  - "/home/xlib-harness/.github/workflows/release.yml"
priority: P1
status: completed
---

# TASK-XLIBHARNESS-007: Public Docs And Secret Scan Contract

## Scope

补齐代码仓库公开功能文档与验收文档，并将 CI/CD 密钥扫描从 license-gated action 固定为开源 `gitleaks` CLI。

## Non-scope

- 不引入新的 CI/CD 供应商。
- 不改变 xlib-harness 既有 profile、fixture 或 Go API 行为。

## Acceptance

- [x] `/home/xlib-harness/FEATURES.md` 记录 v0.1.6 功能、覆盖率、CI/CD 与发布证据。
- [x] `/home/xlib-harness/ACCEPTANCE.md` 记录 v0.1.6 验收门禁、性能基线、覆盖率与总体评分。
- [x] `ci.yml` 与 `release.yml` 校验 `README.md`、`FEATURES.md`、`ACCEPTANCE.md` 和 workflow 文件存在。
- [x] CI/CD secret scan 使用 pinned `github.com/zricethezav/gitleaks/v8@v8.30.1` CLI，Release 与 main CI 均通过。

## Evidence

- /home/xlib-harness@d90b35124701：tag `v0.1.6` 已发布；Release run `27855366871` PASS；main CI run `27855396013` PASS。
- 本地验收：`make ci` PASS；`go test ./... -count=1 -covermode=count -coverprofile=/tmp/xlib-harness-v016.cover` PASS；`go tool cover -func=/tmp/xlib-harness-v016.cover` total 100.0%；`go test -bench=. -run '^$' ./...` PASS；pinned `gitleaks` CLI PASS；`xlibgate@v1.0.0` imports/gomod/baseline PASS；`git diff --check` PASS。
