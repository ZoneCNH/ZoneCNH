# TASK-REDISX-001

> KeyBuilder and namespace isolation.

---

```yaml
task_id: TASK-REDISX-001
module: redisx
scope: "Implement KeyBuilder, Key, key pattern redaction, namespace/env/service/version/entity/id validation, and Options-only key configuration."
spec_ref:
  - "module/redisx/SPEC.md#9"
test_cases:
  - "TC-001"
  - "TC-002"
  - "TC-003"
files:
  - "key.go"
  - "key_test.go"
  - "options.go"
  - "doc.go"
acceptance_criteria:
  - "AC-001-1: KeyBuilder outputs deterministic raw keys and redacted key patterns while rejecting empty, unsafe, overlong, and naked business keys."
  - "AC-BR-001: Business code cannot construct accepted keys without namespace/env/service/version/entity/id or purpose structure."
  - "AC-BR-002: Key defaults and validation are derived from typed Options only."
non_scope:
  - "Do not implement Redis network operations."
  - "Do not parse environment variables, config files, or config center values."
  - "Do not add dependencies beyond the package boundary established in TASK-REDISX-000."
test_plan:
  - "TC-001-1: Unit tests cover legal keys, illegal segments, version changes, pattern redaction, and deterministic output."
  - "TC-BR-001: Unit tests reject naked keys and unsafe business identifiers."
  - "TC-BR-002: Unit tests show key configuration comes from typed Options."
depends_on:
  - "TASK-REDISX-000"
estimated_effort: "1d"
priority: P0
status: pending
```

---

## Purpose

Make Key construction governable before any Redis command implementation accepts input.

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| --- | --- | --- |
| FR-001 | KeyBuilder 与命名空间隔离 | AC-001-1 |
| BR-001 | Key namespace/env/service/version/entity/id 不变量 | AC-BR-001 |
| BR-002 | 配置只通过 typed Options 注入 | AC-BR-002 |

## Scope

- Implement `Key`, `KeyParts`, `KeyBuilder`, validation rules, and redacted pattern generation.
- Wire namespace, environment, service, and key version from `Options`.
- Cover invalid segment and unsafe key paths.

## Non-Scope

- Do not implement KV, Cache, Pipeline, Locker, Counter, RateLimitHelper, Pub/Sub, or Health.
- Do not read configuration from outside `Options`.
- Do not allow accepted APIs to use complete raw business keys for observability.

## Files

| File | Responsibility |
| --- | --- |
| `key.go` | KeyBuilder implementation and validation |
| `key_test.go` | KeyBuilder behavior and edge cases |
| `options.go` | Options fields used by KeyBuilder |
| `doc.go` | Package documentation for key rules |

## Test Plan

| Test Case | Type    | Description        |
| --------- | ------- | ------------------ |
| TC-001    | Compile | KV 接口签名完整性编译验证 |
| TC-002    | Compile | Locker 接口签名完整性编译验证 |
| TC-003    | Compile | Pipeline 接口签名完整性编译验证 |

## Non-Scope

- 不直接 import `configx`、`observex`、`resiliencx` 或 `contracts`。
- 不实现业务缓存模型、业务领域 DTO 或跨模块注册逻辑。
- 直接依赖边界保持为 `kernel` + Redis client library `github.com/redis/go-redis/v9`。

## Implementation Notes

- `Key.Raw` is for Redis operations only; `Key.Pattern` is for logs, metrics, and trace tags.
- Reject empty segment, whitespace-only segment, path traversal markers, control characters, and segments over the configured max length.
- Key version changes must alter raw key and pattern deterministically.

## Done Evidence

- `go test ./...`
- KeyBuilder unit test output
- `git diff --check`
