# TASK-OSSX-005: Aliyun OSS adapter

```yaml
task_id: TASK-OSSX-005
title: Aliyun OSS adapter
module: ossx
status: pending
priority: medium
scope: Implement the Aliyun OSS adapter that isolates the Aliyun OSS SDK behind ossx typed contracts.
spec_ref:
  - module/ossx/SPEC.md#FR-008
  - module/ossx/SPEC.md#BR-011
depends_on:
  - TASK-OSSX-002
files:
  - module/ossx/adapter.go
  - module/ossx/adapters/aliyun/oss.go
  - module/ossx/adapters/aliyun/oss_test.go
  - module/ossx/adapters/aliyun/oss_integration_test.go
  - module/ossx/internal/testkit/fake_store.go
acceptance_criteria:
  - Public APIs contain no Aliyun OSS SDK types.
  - Adapter translates Aliyun OSS errors into ossx typed errors.
  - Aliyun OSS tests can run against fake or integration-gated Aliyun OSS backend.
validation:
  - go test ./module/ossx/... -run "TestAdapter|TestOss"
```

## Non-scope

- Do not redesign public BlobStore contracts, multipart lifecycle semantics, presign policy, or observability hooks.
- Do not expose Aliyun OSS SDK types or Aliyun-specific errors beyond the adapter boundary.
- Do not require live cloud credentials; external compatibility checks must remain fake-backed or explicitly gated.

## Prompt

Use `module/ossx/prompt/PROMPT-OSSX-005.md` for the implementation handoff.
