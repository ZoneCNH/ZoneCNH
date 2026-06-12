# TASK-OSSX-002: BlobStore basic and streaming operations

```yaml
task_id: TASK-OSSX-002
title: BlobStore basic and streaming operations
module: ossx
status: pending
priority: high
scope: Implement core BlobStore operations, streaming semantics, and typed error mapping.
spec_ref:
  - module/ossx/SPEC.md#FR-003
  - module/ossx/SPEC.md#FR-004
  - module/ossx/SPEC.md#BR-006
depends_on:
  - TASK-OSSX-001
files:
  - module/ossx/blobstore.go
  - module/ossx/stream.go
  - module/ossx/errors.go
  - module/ossx/blobstore_test.go
  - module/ossx/stream_test.go
acceptance_criteria:
  - Put/Get/Delete/Copy/Head/Exists/List satisfy fake-adapter contract.
  - Streaming tests prove cancellation and close error behavior.
  - List operations enforce bounded pages and stable continuation tokens.
validation:
  - go test ./module/ossx/... -run "TestBlobStore|TestStream|TestList"
```

## Non-scope

- Do not implement multipart lifecycle, presign policy, concrete S3-compatible adapters, or observability release gates.
- Do not add provider SDK types to public BlobStore interfaces or bypass adapter error translation.
- Do not expand the task to production credentials, external buckets, or implementation tasks outside the listed files.

## Prompt

Use `module/ossx/prompt/PROMPT-OSSX-002.md` for the implementation handoff.
