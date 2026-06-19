---
scope: "xlib-harness FR-006 coverage"
spec_ref:
  - "module/xlib-harness/SPEC.md#FR-006"
acceptance_criteria:
  - "FR-006 traceability gate coverage"
files:
  - "/home/xlib-harness/internal/harness/harness.go"
  - "/home/xlib-harness/internal/harness/harness_test.go"
  - "/home/xlib-harness/fixtures/broken-trace/SPEC.md"
  - "/home/xlib-harness/fixtures/broken-trace/TRACEABILITY.md"
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

- /home/xlib-harness@aa83306685a9：`make ci`、`go test -bench=. ./...`、`git diff --check`、secret pattern scan 均 PASS；coverage total 100.0%。
