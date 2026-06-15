# ossx Specification

## 1. Metadata

- Module: `module/ossx`
- Status: Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-14
- Version: v1.0.0
- Owner: platform storage maintainers
- Related:
  - `CONSTITUTION.md`
  - `ARCHITECTURE.md`
  - `module/kernel`
  - `module/observex`

## 2. Summary

`ossx` provides the platform object-storage extension. It defines a stable BlobStore API, object metadata model, streaming semantics, multipart lifecycle, presigned URL policy, adapter SPI, and observability hooks while keeping storage-provider SDKs outside the public API.

## 3. Problem

HAI services need object storage without coupling business code to cloud SDKs, provider-specific errors, ad hoc checksum handling, or direct configuration loaders. Existing documentation did not fully close Goal -> Spec -> Matrix -> Task traceability and contained dependency wording that could permit direct `configx` usage.

## 4. Goals

- Provide a small storage API that covers common object and multipart operations.
- Preserve Constitution layering by depending only on `kernel` and `observex` interface contracts.
- Accept configuration as module-owned structs or options supplied by the composition root.
- Capture every requirement in traceability, task, prompt, and evidence artifacts.

## 5. Non-goals

- 不做业务领域的上传工作流编排（由各业务服务自行实现）
- 不在公开 API 暴露云厂商 SDK 类型（provider SDK 类型封装在 `adapters/s3/` 等 adapter/internal 层）
- 不做配置加载或配置解析（Config 由调用方 / composition root 构造后传入）
- 不做跨云迁移编排（由平台运维层或独立迁移工具负责）

## 6. Consumers

- L2/L3 services that need BlobStore operations.
- Background jobs that need streaming or multipart upload.
- Platform adapters that bind S3-compatible storage to ossx contracts.
- Tests and examples that use fake adapters for deterministic validation.

## 7. Functional Requirements

### FR-001: Construction and configuration

WHEN a caller constructs `NewBlobStore(cfg Config, adapter ObjectStorageAdapter, hooks Hooks)`, THEN ossx MUST validate module-owned configuration, accept nil hooks as no-op hooks, and avoid importing or requiring `configx`.

Acceptance criteria:
- Invalid endpoint, bucket, region, checksum, or TTL settings return typed configuration errors.
- Configuration can be supplied by plain structs or options from the composition root.
- A dependency guard proves no ossx package imports `configx`.

### FR-002: Object identity and metadata

WHEN a caller passes object keys, metadata, content type, tags, and checksum fields, THEN ossx MUST normalize keys, reject unsafe keys, preserve user metadata, and represent checksum algorithms explicitly.

Acceptance criteria:
- Empty keys, absolute paths, traversal segments, and oversized metadata are rejected.
- Metadata round trips without leaking provider-specific headers.
- Checksum algorithms are enumerated and validation is deterministic.

### FR-003: Basic object operations

WHEN a caller invokes Put, Get, Delete, Copy, Head, Exists, or List, THEN ossx MUST translate the operation to the adapter, apply context cancellation, and return typed module errors.

Acceptance criteria:
- Not-found, conflict, permission, validation, timeout, and provider errors map to stable errors.
- List returns bounded pages and continuation tokens.
- Delete is idempotent for missing objects unless policy requires strict delete.

### FR-004: Streaming upload and download

WHEN a caller uploads or downloads using streams, THEN ossx MUST avoid buffering whole objects, close streams deterministically, propagate cancellation, and surface partial-write or partial-read errors.

Acceptance criteria:
- Upload streams do not read beyond context cancellation.
- Download readers expose close errors when the provider reports them.
- Tests verify large stream behavior without allocating whole payloads.

### FR-005: Multipart lifecycle

WHEN a caller performs multipart upload, THEN ossx MUST support initiate, upload part, list parts, complete, abort, and stale multipart cleanup semantics.

Acceptance criteria:
- Part numbers, part sizes, ETags, and checksums are validated.
- Abort is idempotent and safe after partial failure.
- Complete verifies all required parts before publishing the object.

### FR-006: Presigned URL policy

WHEN a caller requests a presigned GET or PUT URL, THEN ossx MUST enforce operation allowlists, max TTL, checksum constraints, and audit logging without exposing secrets.

Acceptance criteria:
- TTL cannot exceed 15 minutes unless a future spec explicitly changes the limit.
- Only configured operations can be presigned.
- Credentials, signatures, and tokens are masked in logs and traces.

### FR-007: Checksum, lifecycle, and permission policy validation

WHEN a caller configures checksum, lifecycle, retention, or permission policies, THEN ossx MUST validate them before adapter calls and return actionable typed errors.

Acceptance criteria:
- Unsupported checksum algorithms fail before upload.
- Lifecycle windows and retention settings reject negative or contradictory values.
- Permission policy validation runs before presign and write operations.

### FR-008: Adapter SPI and S3-compatible adapter

WHEN an adapter is implemented, THEN it MUST satisfy the module SPI without leaking SDK types, and the S3-compatible adapter MUST isolate provider-specific behavior inside `adapters/s3`.

Acceptance criteria:
- Public ossx interfaces use only ossx, standard library, kernel, or observex-interface types.
- S3-compatible adapter tests cover MinIO-compatible behavior with fake or integration-gated clients.
- Provider errors are translated at the adapter boundary.

### FR-009: Observability and audit hooks

WHEN ossx performs an operation, THEN it MUST emit metrics, traces, and audit events through injected observex-compatible interfaces while supporting no-op defaults.

Acceptance criteria:
- Operation name, result, latency, object size, and sanitized key scope are observable.
- Secrets, signed URLs, credentials, and raw metadata values are not logged.
- Hook failures do not corrupt object operation results unless policy says fail-closed.

### FR-010: Health, lifecycle, and graceful close

WHEN a service starts, checks readiness, or shuts down, THEN ossx MUST provide health and close semantics that use kernel lifecycle conventions and adapter capabilities.

Acceptance criteria:
- Health checks distinguish configuration errors, provider unreachability, and degraded adapter state.
- Close is idempotent and drains in-flight multipart bookkeeping where possible.
- Readiness can be tested without writing objects unless configured to perform active probes.

### Acceptance Criteria Registry

| AC 编号 | 对应 FR | 验收条件 |
| ------- | ------- | -------- |
| AC-OSS-001 | FR-001 | 无效 endpoint/bucket/region/checksum/TTL 返回类型化配置错误；可通过纯 struct 或 options 传入配置；依赖守卫证明无 ossx 包导入 configx |
| AC-OSS-002 | FR-002 | 空 key/绝对路径/遍历段/超大 metadata 被拒绝；metadata round trip 不泄露 provider 头部；checksum 枚举确定且校验确定性 |
| AC-OSS-003 | FR-003 | not-found/conflict/permission/validation/timeout/provider 错误映射为稳定错误；List 返回有界分页+continuation token；Delete 对缺失对象幂等 |
| AC-OSS-004 | FR-004 | 上传流不超出 context 取消边界；下载流暴露 close 错误；大流测试不分配完整 payload |
| AC-OSS-005 | FR-005 | Part number/size/ETag/checksum 校验通过；Abort 幂等且部分失败安全；Complete 验证所有必需 part 后发布对象 |
| AC-OSS-006 | FR-006 | TTL 不超过 15 分钟；仅已配置操作可 presign；凭据/签名/token 在日志和 trace 中脱敏 |
| AC-OSS-007 | FR-007 | 不支持的 checksum 算法上传前失败；lifecycle/retention 负值或矛盾值被拒绝；权限策略在 presign 和 write 前校验 |
| AC-OSS-008 | FR-008 | 公共接口仅使用 ossx/stdlib/kernel/observex 类型；S3 适配器隔离在 adapters/s3；provider 错误在适配器边界转换 |
| AC-OSS-009 | FR-009 | 操作名/结果/延迟/对象大小/sanitized key 可观测；secret/签名URL/凭据/原始 metadata 不被记录；hook 失败不破坏操作结果（除非 fail-closed 策略） |
| AC-OSS-010 | FR-010 | 健康检查区分配置错误/provider 不可达/降级状态；Close 幂等并排空 in-flight multipart；readiness 可无写操作测试 |

## 8. Business Rules

| 编号 | 规则 | 违反时 |
| --- | --- | --- |
| BR-001 | Every public operation MUST accept `context.Context` or be construction-only. | 编译失败——接口签名不含 context.Context；TC-004 测试失败 |
| BR-002 | ossx MUST NOT directly import or depend on `configx`. | CI Gate: go list -deps 检测到 configx import → 阻断 |
| BR-003 | ossx MAY use `kernel` lifecycle and error primitives only at approved boundaries. | 超出批准边界 → 代码审查拒绝 |
| BR-004 | ossx MAY use `observex` only through interface-oriented hooks and contracts. | 直接依赖 observex 实现 → CI Gate import check 阻断 |
| BR-005 | ossx MUST NOT depend on business domains, L2.5 application code, or other storage extensions. | 循环依赖或层级破坏 → CI Gate dependency guard 阻断 |
| BR-006 | List operations MUST enforce bounded page sizes and stable continuation tokens. | 无界列表 → 内存溢出或超时 |
| BR-007 | Multipart abort MUST be idempotent and part validation MUST happen before complete. | 部分上传残留 → 存储泄漏；非幂等 abort → 资源无法清理 |
| BR-008 | Presigned URL TTL MUST default to at most 15 minutes and operations MUST be allowlisted. | 安全风险 → 超额 TTL 或未授权操作 → Presign 校验拒绝 |
| BR-009 | Secrets, credentials, signatures, and tokens MUST never be logged or traced. | 凭据泄露 → CI Gate gitleaks 或 secret scan 阻断 |
| BR-010 | Checksum mismatch MUST return a typed error and clean temporary state when safe. | 数据损坏 → 返回 typed checksum error；临时对象残留 |
| BR-011 | Adapter-specific SDK types MUST NOT appear in public ossx APIs. | SDK 类型泄露 → TC-009 adapter SPI 测试失败 |
| BR-012 | Every acceptance check MUST have a validation command or evidence note. | 验收证据缺失 → CI Gate traceability check 阻断 |


## 9. Interface Contract

```go
package ossx

type BlobStore interface {
    Put(ctx context.Context, key Key, body io.Reader, opts PutOptions) (ObjectInfo, error)
    Get(ctx context.Context, key Key, opts GetOptions) (ObjectReader, error)
    Delete(ctx context.Context, key Key, opts DeleteOptions) error
    Copy(ctx context.Context, source Key, target Key, opts CopyOptions) (ObjectInfo, error)
    Head(ctx context.Context, key Key) (ObjectInfo, error)
    Exists(ctx context.Context, key Key) (bool, error)
    List(ctx context.Context, prefix Prefix, opts ListOptions) (ListPage, error)
    Multipart(ctx context.Context) MultipartSession
    Presign(ctx context.Context, key Key, op PresignOperation, opts PresignOptions) (PresignedURL, error)
    Health(ctx context.Context) HealthReport
    Close(ctx context.Context) error
}
```

The exact names may change during implementation, but the implemented API must preserve these semantics and trace any naming change back to this section.

## 10. Data Model

Core models:

- `Config`: endpoint, region, bucket, addressing style, TLS policy, checksum policy, timeout policy, multipart limits, presign policy, and health-check policy.
- `Key` and `Prefix`: normalized object path values with traversal protection.
- `ObjectInfo`: key, size, content type, user metadata, tags, checksum, ETag, storage class, version, and timestamps.
- `ObjectReader`: `io.ReadCloser` plus metadata and checksum verification result.
- `MultipartUpload`: upload ID, key, initiated time, policy, uploaded parts, and expiration.
- `AuditEvent`: operation, result, sanitized key scope, actor fields supplied by caller, and correlation IDs.

## 11. Config Schema

```yaml
foundationx:
  oss:
    endpoint: "https://storage.example.internal"
    region: "us-east-1"
    bucket: "hai-artifacts"
    path_style: false
    timeouts:
      connect: "5s"
      operation: "30s"
    checksum:
      required: true
      algorithms: ["sha256"]
    multipart:
      min_part_size: "8MiB"
      max_parts: 10000
    presign:
      max_ttl: "15m"
      allowed_operations: ["GET", "PUT"]
```

The external namespace is `foundationx.oss` only at the composition-root configuration boundary. Only the composition root outside `module/ossx` may use an external configuration loader such as `configx`; it must project those values into `ossx.Config` or constructor options before calling ossx. The ossx module itself must not import `configx`, configuration-loader packages, or repository-global config registries.

## 12. Error Handling

| 错误类型 | 触发条件 | 处理方式 |
| --- | --- | --- |
| `ErrInvalidConfig` | endpoint/bucket/region 为空或非法 | 构造时拒绝，不访问存储 |
| `ErrNotFound` | 对象不存在 | 可处理状态，调用方决定重试或跳过 |
| `ErrConflict` | 对象已存在或版本冲突 | 返回冲突错误，含对象 key |
| `ErrPermission` | 权限不足 | 返回权限错误，不重试 |
| `ErrChecksumMismatch` | 校验和不匹配 | 返回 typed error，清理临时状态 |
| `ErrTimeout` | context deadline 或操作超时 | 返回超时错误 |
| `ErrCancelled` | context 取消 | 返回取消错误，清理进行中操作 |
| `ErrProviderFailure` | 后端存储不可达 | 适配器翻译后返回 |
| `ErrClosed` | BlobStore 已关闭 | 返回稳定错误，幂等 |

Provider 特定错误由适配器在公开边界前翻译为 typed ossx 错误。

## 13. Edge Cases

| 场景 | 预期行为 |
| --- | --- |
| 空 payload / 零字节对象 | 策略允许时有效 |
| 超大对象 | 必须使用 streaming 或 multipart 路径 |
| multipart complete 期间取消 | 保留足够状态以重试或 abort |
| 重复 delete/abort/close/health | 安全幂等 |
| Unicode key 遍历歧义 | 一致规范化并拒绝歧义路径 |

## 14. Directory Structure

```text
module/ossx/
  doc.go
  config.go
  blobstore.go
  object.go
  multipart.go
  presign.go
  adapter.go
  observability.go
  health.go
  adapters/s3/
  internal/
  tasks/
  prompt/
  evidence/
```

## 15. Dependencies

Allowed dependencies:

- Standard library.
- `module/kernel` for approved lifecycle, context, and typed error conventions.
- `module/observex` interface contracts or minimal local interfaces compatible with observex.
- Provider SDKs only inside adapter implementation packages such as `adapters/s3`.

Forbidden dependencies:

- Direct `configx` imports from any ossx package.
- Business-domain, L2.5, UI, or workflow modules.
- Other storage extensions such as natsx, kafkax, redisx, mysqlx, or pgx.
- Provider SDK types in public ossx APIs.

## 16. Testing

- **TC-001:** Dependency guard verifies ossx does not import configx or other storage extensions.
- **TC-002:** Config validation covers endpoint, bucket, region, timeout, checksum, multipart, and presign settings.
- **TC-003:** Key and metadata validation rejects unsafe paths and oversized metadata.
- **TC-004:** Basic object operation contract covers Put/Get/Delete/Copy/Head/Exists/List with typed errors.
- **TC-005:** Streaming tests cover cancellation, close errors, and large payload behavior.
- **TC-006:** Multipart tests cover initiate, upload part, list parts, complete, abort, and stale cleanup.
- **TC-007:** Presign tests enforce TTL, operation allowlist, checksum constraints, and secret masking.
- **TC-008:** Policy validation tests cover checksum, lifecycle, retention, and permission errors.
- **TC-009:** Adapter SPI tests prove public APIs do not expose provider SDK types.
- **TC-010:** S3-compatible adapter contract tests run with fake or gated MinIO-compatible backends.
- **TC-011:** Observability tests verify metrics, traces, audit events, and no-op hook behavior.
- **TC-012:** Health and close tests verify readiness states and idempotent shutdown.
- **TC-013:** Traceability validation checks Goal -> Spec -> Matrix -> Task -> Evidence closure.

## 17. Performance Budget

- Put/Get streaming paths must not buffer complete objects in memory.
- List operations must cap page size and avoid unbounded result accumulation.
- Multipart upload must respect configured part-size and concurrency limits.
- Hook emission must add bounded overhead and fail safely according to policy.

## 18. Observability

Metrics, traces, and audit events MUST include operation, result, latency, payload size where available, adapter name, and sanitized key scope. They MUST exclude raw secrets, signatures, credentials, full signed URLs, and unrestricted metadata values.

## 19. Security

- Presigned URL generation must be least-privilege by operation and TTL.
- Credentials must be supplied by adapter configuration and never returned from public APIs.
- Object keys must be sanitized before logging.
- Checksum and permission policy failures must fail closed.

## 20. CI Gate

Required checks:

```bash
git diff --check
bash .github/ci/spec-lint.sh
TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh
bash .github/ci/task-spec-validate.sh
go test ./module/ossx/...
go list -deps ./module/ossx/... | grep -v configx
```

If implementation code does not exist yet, Go checks may be recorded as not applicable with evidence. Once code exists, Go checks are required for release.

## 21. Upgrade Compatibility

Public API changes after first implementation require a compatibility note, migration guidance, and traceability updates. Adapter-only changes may remain internal if public behavior and error contracts are unchanged.

## 22. Release DoD

- Goal, SPEC, TRACEABILITY, PLAN, tasks, prompts, and evidence are present.
- All FR and BR rows map to TC and task IDs.
- Dependency guard prevents direct configx imports.
- Targeted tests and CI gates pass or have documented pre-implementation not-applicable evidence.
- Release notes identify adapter support and known limitations.

## 23. Open Questions

### Non-blocking

| ID | 问题 | 状态 |
| --- | --- | --- |
| OQ-001 | Which S3-compatible backend will be the first integration target for gated tests? | 待确认 |
| OQ-002 | Should checksum verification be mandatory for all reads or configurable per bucket policy? | 待确认 |
| OQ-003 | Which observex hook shape should become the shared interface once observex stabilizes? | 待确认 |
