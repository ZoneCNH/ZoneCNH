# TASK-OSSX-001: Object identity metadata checksum and policy model

```yaml
task_id: TASK-OSSX-001
title: Object identity metadata checksum and policy model
module: ossx
status: pending
priority: high
scope: Implement key, metadata, checksum, lifecycle, and permission policy value types.
spec_ref:
  - module/ossx/SPEC.md#FR-002
  - module/ossx/SPEC.md#FR-007
  - module/ossx/SPEC.md#BR-010
depends_on:
  - TASK-OSSX-000
files:
  - module/ossx/object.go
  - module/ossx/key.go
  - module/ossx/metadata.go
  - module/ossx/checksum.go
  - module/ossx/object_test.go
acceptance_criteria:
  - Unsafe keys and oversized metadata are rejected.
  - Checksum and policy validation return typed errors.
  - Metadata round trips without provider-specific headers.
validation:
  - go test ./module/ossx/... -run "Test(Key|Metadata|Checksum|Policy)"
```

## Prompt

Use `module/ossx/prompt/PROMPT-OSSX-001.md` for the implementation handoff.
