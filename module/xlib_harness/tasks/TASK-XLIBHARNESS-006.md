---
module: xlib_harness
scope: "xlib_harness FR-006 coverage"
spec_ref:
  - "module/xlib_harness/SPEC.md#FR-006"
acceptance_criteria:
  - "FR-006 traceability gate coverage"
files:
  - "/home/xlib_harness/internal/harness/harness.go"
  - "/home/xlib_harness/internal/harness/harness_test.go"
  - "/home/xlib_harness/fixtures/broken-trace/SPEC.md"
  - "/home/xlib_harness/fixtures/broken-trace/TRACEABILITY.md"
priority: P1
status: completed
---

# TASK-XLIBHARNESS-006: FR-006

## Scope

FR-006 追踪矩阵闭环门禁实现与验证。

## Non-scope

- 不修改业务模块追踪矩阵。
- 不替代外部发布门禁。

## Acceptance

- [x] FR-006 traceability gate coverage
- [x] `fixtures/broken-trace` 在 full profile 下稳定失败
- [x] `fixtures/compliant-module` 在 full profile 下稳定通过

## Evidence

- /home/xlib_harness@d90b35124701：`make ci`、`go test -bench=. -run '^$' ./...`、`git diff --check`、pinned `gitleaks` CLI、`xlibgate@v1.0.0` imports/gomod/baseline 均 PASS；coverage total 100.0%；full profile 15 项通过；Release run `27855366871` 与 main CI run `27855396013` 均 PASS。
