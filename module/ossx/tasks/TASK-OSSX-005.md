# TASK-OSSX-005: Adapter SPI and S3-compatible adapter

```yaml
task_id: TASK-OSSX-005
title: Adapter SPI and S3-compatible adapter
module: ossx
status: pending
priority: medium
scope: Implement adapter boundary and an S3-compatible adapter that hides SDK types.
spec_ref:
  - module/ossx/SPEC.md#FR-008
  - module/ossx/SPEC.md#BR-011
depends_on:
  - TASK-OSSX-002
files:
  - module/ossx/adapter.go
  - module/ossx/adapters/s3/s3.go
  - module/ossx/adapters/s3/s3_test.go
  - module/ossx/adapters/s3/minio_compat_test.go
  - module/ossx/internal/testkit/fake_store.go
acceptance_criteria:
  - Public APIs contain no provider SDK types.
  - Adapter translates provider errors into ossx typed errors.
  - S3-compatible tests can run against fake or gated MinIO-compatible backend.
validation:
  - go test ./module/ossx/... -run "TestAdapter|TestS3"
```

## Non-scope

- Do not redesign public BlobStore contracts, multipart lifecycle semantics, presign policy, or observability hooks.
- Do not expose provider SDK types or provider-specific errors beyond the adapter boundary.
- Do not require live cloud credentials; external compatibility checks must remain fake-backed or explicitly gated.

## Prompt

Use `module/ossx/prompt/PROMPT-OSSX-005.md` for the implementation handoff.
