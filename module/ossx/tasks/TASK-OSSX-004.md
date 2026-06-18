# TASK-OSSX-004: Presigned URL policy and audit masking

```yaml
task_id: TASK-OSSX-004
title: Presigned URL policy and audit masking
module: ossx
status: pending
priority: medium
scope: Implement presigned GET/PUT policy enforcement and audit-safe output.
spec_ref:
  - module/ossx/SPEC.md#FR-006
  - module/ossx/SPEC.md#BR-008
  - module/ossx/SPEC.md#BR-009
depends_on:
  - TASK-OSSX-002
files:
  - module/ossx/presign.go
  - module/ossx/presign_policy.go
  - module/ossx/presign_test.go
  - module/ossx/audit_test.go
acceptance_criteria:
  - TTL over 15 minutes is rejected.
  - Only allowlisted presign operations succeed.
  - Logs and audit output mask signatures, tokens, and credentials.
validation:
  - go test ./module/ossx/... -run "TestPresign|TestAuditMasking"
```

## Non-scope

- Do not implement BlobStore core IO, multipart upload, the concrete Aliyun adapter, or release evidence closure.
- Do not log, persist, or expose raw signatures, tokens, credentials, or Aliyun OSS SDK request objects.
- Do not widen presign operations or TTL limits beyond the spec and traceability matrix.

## Prompt

Use `module/ossx/prompt/PROMPT-OSSX-004.md` for the implementation handoff.
