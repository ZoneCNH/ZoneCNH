# TASK-OSSX-003: Multipart lifecycle

```yaml
task_id: TASK-OSSX-003
title: Multipart lifecycle
module: ossx
status: pending
priority: medium
scope: Implement multipart initiate, part upload, list, complete, abort, and stale cleanup semantics.
spec_ref:
  - module/ossx/SPEC.md#FR-005
  - module/ossx/SPEC.md#BR-007
depends_on:
  - TASK-OSSX-002
files:
  - module/ossx/multipart.go
  - module/ossx/multipart_test.go
  - module/ossx/internal/multipart/state.go
acceptance_criteria:
  - Part numbers, sizes, ETags, and checksums are validated.
  - Abort is idempotent after partial failure.
  - Complete rejects missing or inconsistent parts.
validation:
  - go test ./module/ossx/... -run TestMultipart
```

## Prompt

Use `module/ossx/prompt/PROMPT-OSSX-003.md` for the implementation handoff.
