# TASK-REDISX-000

> Package contract, typed Options, Codec, shared errors, and dependency guard.

---

```yaml
task_id: TASK-REDISX-000
module: redisx
scope: "Define package skeleton, typed Options, New/Close contract surface, Codec SPI, shared error model, and dependency guard without implementing Redis command breadth."
spec_ref:
  - "module/redisx/SPEC.md#FR-002"
  - "module/redisx/SPEC.md#FR-011"
  - "module/redisx/SPEC.md#BR-007"
  - "module/redisx/SPEC.md#BR-010"
  - "module/redisx/SPEC.md#NFR-001"
files:
  - "go.mod"
  - "doc.go"
  - "options.go"
  - "codec.go"
  - "errors_test.go"
acceptance_criteria:
  - "AC-002-1: Options validation, New/Close contract, pool/timeout fields, TLS field, Codec defaulting, and lifecycle hook shape are compile-tested."
  - "AC-011-1: JSON Codec and custom Codec SPI classify Encode/Decode failures without leaking full keys."
  - "AC-BR-010: Static dependency guard rejects direct imports of configx, observex, resiliencx, contracts, or business modules."
non_scope:
  - "Do not implement KeyBuilder, KV, Cache, Pipeline, Locker, Counter, RateLimitHelper, Pub/Sub, or Health behavior beyond interfaces required for compilation."
  - "Do not edit SPEC.md, TRACEABILITY.md, goal.md, or module/README.md as part of this implementation task."
  - "Do not add direct runtime dependencies beyond stdlib, github.com/ZoneCNH/kernel, and the Redis client library."
test_plan:
  - "TC-002-1: Unit/contract tests validate Options defaults, invalid Options, New/Close shape, and lifecycle hook compile contract."
  - "TC-011-1: Unit tests validate JSON Codec, custom Codec, Encode/Decode errors, and redacted error output."
  - "TC-BR-007: Static/unit checks confirm errors and hook payloads do not include complete key or connection string values."
  - "TC-BR-010: Static dependency guard scans production Go imports for forbidden modules."
  - "TC-NFR-001: Compile test covers all public interfaces introduced by this task."
depends_on: []
estimated_effort: "1d"
priority: P0
status: done
```

---

## Purpose

Establish the package contract so later tasks can implement Redis behavior against a stable surface.

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
| --- | --- | --- |
| FR-002 | typed Options、New/Close 与连接生命周期 | AC-002-1 |
| FR-011 | JSON 默认 Codec 与自定义 Codec SPI | AC-011-1 |
| BR-007 | 错误分类与敏感信息脱敏 | AC-BR-007 |
| BR-010 | 依赖边界：stdlib/kernel/Redis client only | AC-BR-010 |
| NFR-001 | 单元与契约测试覆盖所有公开能力 | AC-NFR-001 |

## Scope

- Define `Options`, `Codec`, shared errors, constructor signatures, and public interface placeholders needed by dependent tasks.
- Add dependency guard coverage for forbidden direct imports.
- Add compile and unit tests for Options, Codec, and shared error behavior.

## Non-Scope

- Do not implement Redis command behavior beyond contracts required by this task.
- Do not introduce config parsing, metrics clients, circuit breaker clients, or domain adapters.
- Do not edit governance documents in this implementation task.

## Files

| File | Responsibility |
| --- | --- |
| `go.mod` | Module path and allowed direct dependencies |
| `doc.go` | Package documentation and public dependency boundary |
| `options.go` | `Options`, validation, defaults, constructor signatures |
| `codec.go` | Default JSON Codec and Codec SPI |
| `errors_test.go` | Error classification, redaction, and dependency guard tests |

## Test Plan

| Test Case | Type | Same-task test file |
| --- | --- | --- |
| TC-002-1 | Unit/Contract | `errors_test.go` |
| TC-011-1 | Unit | `errors_test.go` |
| TC-BR-007 | Unit/Static | `errors_test.go` |
| TC-BR-010 | Static | `errors_test.go` |
| TC-NFR-001 | Compile/Unit | `errors_test.go` |

## Implementation Notes

- Public errors must support `errors.Is` or stable error codes.
- Keep all forbidden integration modules outside production imports.
- Every key-like value in errors must use pattern or redacted representation.

## Done Evidence

- `go test ./...`
- dependency guard output
- `git diff --check`
