# ossx 完整实现清单

- Status: Implemented（远程 `github.com/ZoneCNH/ossx` v1.1.0 已发布）
- Last-Updated: 2026-06-18
- Source: [module/ossx/SPEC.md](./SPEC.md) v1.2.0 · [TRACEABILITY.md](./TRACEABILITY.md) · [ACCEPTANCE.md](./ACCEPTANCE.md)
- Layer: 基座 · 对象存储扩展
- Module-Identity: Aliyun OSS 专用 adapter（单 provider；非通用对象存储抽象 / adapter SPI / S3-compatible）

> 本文档是 ossx **要完整实现的、可勾选的功能清单**，把 SPEC 的 FR/BR 展开成具体的、可验收的功能点。
> 它不是 Why（[goal.md](./goal.md)）、不是规格（[SPEC.md](./SPEC.md)）、不是追溯矩阵（[TRACEABILITY.md](./TRACEABILITY.md)）、不是阶段计划（[IMPLEMENTATION-PLAN.md](./IMPLEMENTATION-PLAN.md)）。
>
> 当前实现事实（2026-06-18）：远程 `github.com/ZoneCNH/ossx` 已发布 **v1.1.0**，FR-001..FR-010 **全部实现**。
> - pkg/ossx：流式 BlobStore + 完整 multipart + presign + 策略 + retry/circuit + observex hooks（stdlib + 本地接口，无 configx）
> - adapters/aliyun：真实 Aliyun OSS adapter（aliyun-oss-go-sdk v3.0.2，SDK 隔离）
> - 24 单元测试 + 5 集成测试（真实 bucket `x-go`，TC-010）全过；61.2% 覆盖
> - `factory=false` 保持：公开 evidence archive（BLK-008）仍待归档

勾选图例：`[ ]` 待实现 · `[x]` 已实现并通过对应 TC · `[~]` 部分实现（备注列注明缺口）

---

## 1. 身份与边界（先决约束）

| 约束             | 要求                                                                                     | 状态 | 依据                   |
| ---------------- | ---------------------------------------------------------------------------------------- | ---- | ---------------------- |
| 单 provider 身份 | 仅 Aliyun OSS；不提供 adapter SPI / S3-compatible / 多 provider 抽象                     | ✅   | SPEC §1, §4            |
| 禁止 configx     | 任何 ossx 包均不得 import `configx`                                                      | ✅   | BR-002                 |
| 禁止 SDK 泄漏    | Aliyun OSS SDK 类型不得出现在公共 API                                                    | ✅   | BR-011                 |
| 禁止 secret 日志 | 凭据/签名/token/签名 URL 绝不记录                                                        | ✅   | BR-009                 |
| 分层边界         | 仅可依赖 stdlib（+ Aliyun SDK 在 adapter 内）；本地重声明 Metrics/Logger/Hooks 兼容 observex | ✅   | BR-003, BR-004, BR-005 |

---

## 2. 功能清单（按 FR 展开）— 全部 ✅

### FR-001 构造与配置 ✅

- [x] `NewBlobStore(cfg, adapter StoreAdapter, hooks Hooks) (BlobStore, error)` 构造入口
- [x] 校验 endpoint/bucket/region/checksum/TTL/生命周期/retention/权限，非法值返回 typed `*Error{Kind:config}`
- [x] nil hooks 视作 no-op（`Hooks.withDefaults()` 填 Noop*）
- [x] 配置由纯 struct 传入（`Config`）；`ConfigFromEnv()` 读 `FOUNDATIONX_OSSX_*`
- [x] 内部注入 Aliyun adapter（`aliyun.NewAdapter`）或 InMemoryAdapter
- [x] TC-001（依赖守卫）、TC-002（配置校验，`TestConfigValidate`）通过

### FR-002 对象身份与元数据 ✅

- [x] `Key`/`Prefix`：`NewKey` 拒绝空/绝对路径/遍历段/非 UTF-8/>1024 字符
- [x] `Metadata` round trip 不泄漏 Aliyun 头部（stdlib-only）
- [x] 拒绝超大 metadata（`MaxMetadataKeys=64`/`MaxMetadataValueLen=2048`）
- [x] `Checksum` 枚举（sha256/md5/crc32），流式 `wrapChecksumVerifier` tee 校验
- [x] content type / tags 字段建模
- [x] TC-003（`TestNewKey`/`TestSanitizedScope`/metadata）通过

### FR-003 基础对象操作 ✅

- [x] `Put`/`Get`/`Delete`/`Copy`/`Head`/`Exists`/`List` 全实现
- [x] Delete 对缺失对象幂等（`StrictNotFound` 可关闭）
- [x] List 有界分页 + continuation token（max≤1000）
- [x] 所有操作接受 `context.Context` 并传播取消
- [x] 错误映射为稳定 typed `*Error`（15 ErrorKind）
- [x] retry/circuit 包装（`blobStore.run`）
- [x] TC-004（`TestBlobStoreCRUD`/`TestList`/`TestCopy`）通过

### FR-004 流式上传/下载 ✅

- [x] 流式 SPI：`PutObject(ctx, key, body io.Reader, ...)` / `GetObject(ctx, key) (io.ReadCloser, ...)`
- [x] Put 不缓冲整对象（adapter 直接读 io.Reader）
- [x] Get 返回真实 `io.ReadCloser`，close 由调用方负责
- [x] context 取消传播（`TestStreamingContextCancellation`）
- [x] 大 payload 测试不分配完整对象缓冲（`TestStreamingPutGetRoundTripLargePayload` 5MB）
- [x] TC-005 通过

### FR-005 分片上传生命周期 ✅

- [x] `Multipart(ctx) (MultipartSession, error)` 入口
- [x] Initiate/UploadPart/ListParts/Complete/Abort 全实现
- [x] part number/size/ETag 校验；Complete 要求连续 part 号
- [x] Abort 幂等；IdempotencyGuard 防 double-complete（BR-007）
- [x] Aliyun adapter 真实 multipart（`InitiateMultipartUpload`/`UploadPart`/`ListUploadedParts`/`CompleteMultipartUpload`/`AbortMultipartUpload`）
- [x] TC-006 通过（`TestMultipartNotImplemented` 全生命周期 + 集成测试）

### FR-006 预签名 URL 策略 ✅

- [x] `Presign(ctx, key, op, opts)` 真实签名委托 adapter（`bucket.SignURL`）
- [x] 操作 allowlist 强制（默认 GET/PUT）
- [x] TTL ≤ 15min 双重强制（Config.Validate + Presign）
- [x] 审计脱敏：`AuditEvent` 不含签名 URL/凭据（`TestPresignAuditMasked`）
- [x] TC-007 通过

### FR-007 策略校验 ✅

- [x] checksum 算法在上传前校验（`validateChecksumAlgo`）
- [x] lifecycle 策略：`LifecyclePolicy{Enabled, MinDays, StorageClass}` 负值/缺 StorageClass 拒绝
- [x] retention 策略：`RetentionPolicy{Mode, MaxDays}` 负值拒绝；delete 前 `validateRetentionDelete`
- [x] permission 策略：`PermissionPolicy{AllowedPrefixes, DeniedPrefixes}` 写/presign 前校验
- [x] TC-008 通过（`TestPermissionPolicy*`/`TestRetentionPolicy*`/`TestConfigValidateLifecycle*`）

### FR-008 Aliyun OSS adapter 隔离 ✅

- [x] `adapters/aliyun/` 包封装 Aliyun OSS SDK（v3.0.2）
- [x] adapter 实现 `ossx.StoreAdapter`（`var _ ossx.StoreAdapter = (*Adapter)(nil)`）
- [x] Aliyun 错误在边界翻译为 typed `*Error`（`translateError`/`mapServiceError`）
- [x] 公共接口仅使用 ossx/stdlib 类型
- [x] `InMemoryAdapter` + 集成测试 fake/integration-gated 真实 Aliyun
- [x] TC-009（`TestSPISurface`）、TC-010（集成测试 5/5）通过

### FR-009 可观测性与审计 ✅

- [x] `Hooks{Metrics, Tracer, Logger}` observex 兼容接口（nil-safe Noop* 默认）
- [x] 事件字段：operation/result/latency/size/sanitized key scope
- [x] 排除：原始 secret/签名/凭据/完整签名 URL（`SanitizedScope` + labels 不含敏感）
- [x] hook 失败不破坏操作结果
- [x] `AuditEvent` 类型 + `emitAudit`（presign 审计）
- [x] TC-011 通过（`TestHooksHistogramEmitted`/`TestHooksNilSafe`/`TestPresignAuditMasked`）

### FR-010 健康/生命周期/优雅关闭 ✅

- [x] `Health(ctx) HealthReport` 三态：ready/unreachable/config_error/degraded/closed
- [x] `Close(ctx)` 幂等（`sync.Once`）
- [x] readiness 无写操作（`Health` 调 `GetBucketInfo`）
- [x] TC-012 通过（`TestHealthAndClose` + 集成 `TestIntegrationHealth`）

---

## 3. 文件交付清单（远程 `/home/ossx`）

| 文件 | 承载功能 | 状态 |
| ---- | -------- | ---- |
| `pkg/ossx/store.go` | 导出 StoreAdapter 流式 SPI | ✅ |
| `pkg/ossx/config.go` | Config + Policy + Validate/Sanitize | ✅ |
| `pkg/ossx/env.go` | ConfigFromEnv（FOUNDATIONX_OSSX_*） | ✅ |
| `pkg/ossx/errors.go` | typed *Error + 15 ErrorKind + Is() | ✅ |
| `pkg/ossx/object.go` | Key/Metadata/Checksum/ObjectInfo | ✅ |
| `pkg/ossx/blobstore.go` | 流式 BlobStore + retry/circuit + policy | ✅ |
| `pkg/ossx/multipart.go` | 完整 multipart + 类型定义 | ✅ |
| `pkg/ossx/presign.go` | 真实 presign + 审计脱敏 | ✅ |
| `pkg/ossx/policy.go` | lifecycle/retention/permission 校验 | ✅ |
| `pkg/ossx/observability.go` | observex 兼容 Hooks + AuditEvent | ✅ |
| `pkg/ossx/retry.go` | retry + circuit（本地，resiliencx 语义） | ✅ |
| `pkg/ossx/helpers.go` | checksum 流式校验 + 辅助 | ✅ |
| `pkg/ossx/inmemory.go` | InMemoryAdapter（完整 storeAdapter） | ✅ |
| `pkg/ossx/doc.go` | Aliyun-only 包文档 | ✅ |
| `adapters/aliyun/oss.go` | 真实 Aliyun adapter | ✅ |
| `adapters/aliyun/oss_integration_test.go` | 双层门禁集成测试 | ✅ |
| `README.md` / `CHANGELOG.md` | Aliyun-only + v1.1.0 | ✅ |

---

## 4. 测试覆盖清单（TC-001 ~ TC-013）

| TC | 验证内容 | 状态 | 测试函数 |
| -- | -------- | ---- | -------- |
| TC-001 | 依赖守卫：无 configx | ✅ | `dependency_guard`（stdlib-only 由 go.mod 证明） |
| TC-002 | 配置校验全字段 | ✅ | `TestConfigValidate` |
| TC-003 | key/metadata 校验 | ✅ | `TestNewKey`/`TestSanitizedScope` |
| TC-004 | 基础操作契约 | ✅ | `TestBlobStoreCRUD`/`TestList`/`TestCopy` |
| TC-005 | 流式取消/close/大 payload | ✅ | `TestStreaming*`（3 个） |
| TC-006 | 分片全生命周期 | ✅ | `TestMultipartNotImplemented` + 集成 `TestIntegrationMultipart` |
| TC-007 | presign TTL/allowlist/脱敏 | ✅ | `TestPresign` + 集成 `TestIntegrationPresign` |
| TC-008 | 策略校验 checksum/lifecycle/retention/permission | ✅ | `TestPermissionPolicy*`/`TestRetentionPolicy*`/`TestConfigValidateLifecycle*` |
| TC-009 | 公开 API 无 SDK 类型 | ✅ | `TestSPISurface` |
| TC-010 | Aliyun adapter 契约 | ✅ | 集成测试 5/5（真 bucket x-go） |
| TC-011 | 可观测性 metrics/traces/audit + no-op | ✅ | `TestHooksHistogramEmitted`/`TestHooksNilSafe`/`TestPresignAuditMasked` |
| TC-012 | 健康 + 幂等关闭 | ✅ | `TestHealthAndClose` + 集成 `TestIntegrationHealth` |
| TC-013 | 追溯闭合 Goal→Spec→Matrix→Task→Evidence | ✅ | `TestTraceabilityClosure` |

---

## 5. 实现状态总览

| 维度 | 状态 |
| ---- | ---- |
| SPEC | Implemented（v1.2.0） |
| 远程实现 | v1.1.0 已发布（pkg/ossx + adapters/aliyun，22 文件 +3206 行） |
| Factory | **false**（公开 evidence archive BLK-008 仍待归档；真实 adapter + 集成证据已齐备） |
| FR 进度 | FR-001..FR-010 **全部 ✅** |
| TC 进度 | TC-001..TC-013 **全部 ✅**（24 单测 + 5 集成） |
| 覆盖率 | 61.2% statements（pkg/ossx） |
| 阻塞 | 无 open 实现阻塞；BLK-008（evidence archive）待归档 |

> v1.1.0 是完整实现里程碑。剩余 factory 翻转条件：归档公开 API docs + quickstart + integration evidence + release manifest（BLK-008）。
