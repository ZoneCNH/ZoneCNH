# ossx Specification

- Status: Implemented / Local Production Candidate
- Spec-Version: v1.2.1
- Last-Updated: 2026-06-19
- Module: `ossx`
- Version: v1.2.1 local candidate（`/home/ossx` branch `ossx`；远端 tag/release 证据待归档）
- Module-Identity: Aliyun OSS 专用 adapter（单 provider；非通用对象存储抽象；非 S3-compatible）
- Public Package: `github.com/ZoneCNH/ossx/pkg/ossx`

> v1.2.1 的关键变化是接口治理收敛：调用方公共能力拆为 `BlobStore` + capability interfaces，adapter SPI 拆为 `StoreAdapter` / `MultipartAdapter` / `PresignAdapter` / `AdapterLifecycle`。本地门禁支持生产候选结论；完整生产放行仍依赖外部 release、live integration、downstream adoption、soak 和四源评分证据。

## 1. 背景

`ossx` 为 ZoneCNH 架构中的 L1 存储基础模块，负责把 Aliyun OSS 暴露为统一、类型化、可测试、可观测的对象存储能力。它不是 S3/MinIO 多 provider 抽象，也不直接承担业务配置、密钥管理或生产编排。

历史上该模块文档存在 S3-compatible、多 provider、旧 `ObjectStorageAdapter` 与 11-method `BlobStore` 残留。v1.2.1 以当前 `/home/ossx` 实现为准，收敛为 Aliyun-only identity 与 split-interface governance。

## 2. 目标

- 提供 Aliyun OSS 单 provider 的 object store core API。
- 支持流式读写，避免全对象内存缓冲。
- 支持 multipart、presign、lifecycle/retention/permission policy、health、close、observability hooks。
- 保持 provider SDK 类型不穿透公共 API。
- 保持公共接口可维护：单个 caller-facing interface 不超过 7 个方法。
- 提供可复现本地验收证据，并明确外部生产放行缺口。

## 3. 非目标

- 不提供 S3-compatible 或 MinIO-compatible adapter。
- 不提供多云 provider 选择、fallback、迁移或复制编排。
- 不直接依赖 `configx`、数据库、消息队列或业务服务。
- 不在日志、metrics、trace、release evidence 中暴露真实凭证、endpoint、AK/SK 或 signed URL。
- 不把本地门禁通过等同于 production release。

## 4. 范围

In scope：

- `pkg/ossx` public API 与 adapter SPI。
- `adapters/aliyun` Aliyun OSS adapter。
- 本地 acceptance、coverage、race、lint、build、secret-scope、dependency isolation。
- release manifest 与 local acceptance evidence。

Out of scope：

- 其他 provider adapter。
- 生产凭证管理与部署编排。
- 下游业务模块改造。
- 真实 production traffic soak。

## 5. 使用者

| 使用者 | 需求 |
| --- | --- |
| 业务模块 | 通过窄接口依赖对象存储能力，避免 provider SDK 泄漏 |
| 平台/组合根 | 构造 `Store`，注入 Aliyun adapter、hooks、policy |
| 测试代码 | 使用 `InMemoryAdapter` 或 fake adapter 验证行为 |
| SRE/Release | 读取 manifest、evidence、CI artifact 判定放行状态 |

## 6. 功能需求

| ID | Requirement | Acceptance |
| --- | --- | --- |
| FR-001 | 构造入口 | `NewBlobStore(cfg Config, adapter StoreAdapter, hooks Hooks) (*Store, error)` 校验配置与 adapter capability，nil hooks 为 no-op |
| FR-002 | Key 与 metadata | Key、prefix、metadata、tags、checksum 类型化并校验 |
| FR-003 | Core object ops | 支持 Put/Get/Delete/Copy/Head/Exists/List |
| FR-004 | Streaming | Put/Get 使用 `io.Reader` / `io.ReadCloser`，adapter 不全量缓冲对象 |
| FR-005 | Multipart | 支持 initiate/upload/list/complete/abort，校验 part number、ETag、part count |
| FR-006 | Presign | 支持受限 operation、TTL 上限、checksum/content constraints、audit masking |
| FR-007 | Policy | lifecycle、retention、permission policy 在构造、write、delete、presign 前执行 |
| FR-008 | Aliyun adapter isolation | Provider SDK 限定在 `adapters/aliyun`；provider error 在边界转换为 typed `*Error` |
| FR-009 | Observability | metrics/tracer/logger/audit hooks 兼容 observex 风格接口并脱敏 |
| FR-010 | Health/Close | health 区分 ready/unreachable/config_error/degraded/closed；close 幂等且 race-safe |

## 7. 边界需求

| ID | Boundary Requirement |
| --- | --- |
| BR-001 | `ossx` 不直接依赖 `configx` |
| BR-002 | `ossx` 不依赖 Redis/MySQL/Postgres/NATS/Kafka 等业务基础设施 |
| BR-003 | Provider SDK 类型不得出现在 `pkg/ossx` public API |
| BR-004 | Adapter 负责 provider error translation，store 层对外只返回 typed `*Error` 或 wrapped typed error |
| BR-005 | List 必须分页并有 max bound |
| BR-006 | Multipart complete 必须校验 part 顺序与数量 |
| BR-007 | Presigned URL 不得进入日志、metrics、trace label |
| BR-008 | Delete strict mode 对缺失对象返回 `ErrNotFound`，不得被 provider 幂等删除吞掉 |
| BR-009 | Close 后操作返回 closed typed error |
| BR-010 | public interface governance：单个 caller-facing interface 不超过 7 methods |

## 8. 公共接口

```go
type Store struct {
    // unexported fields
}

func NewBlobStore(cfg Config, adapter StoreAdapter, hooks Hooks) (*Store, error)

type BlobStore interface {
    Put(ctx context.Context, key Key, body io.Reader, opts PutOptions) (ObjectInfo, error)
    Get(ctx context.Context, key Key, opts GetOptions) (ObjectReader, error)
    Delete(ctx context.Context, key Key, opts DeleteOptions) error
    Copy(ctx context.Context, source Key, target Key, opts CopyOptions) (ObjectInfo, error)
    Head(ctx context.Context, key Key) (ObjectInfo, error)
    Exists(ctx context.Context, key Key) (bool, error)
    List(ctx context.Context, prefix Prefix, opts ListOptions) (ListPage, error)
}

type MultipartStarter interface {
    Multipart(ctx context.Context) (MultipartSession, error)
}

type Presigner interface {
    Presign(ctx context.Context, key Key, op PresignOperation, opts PresignOptions) (PresignedURL, error)
}

type HealthChecker interface {
    Health(ctx context.Context) HealthReport
}

type StoreCloser interface {
    Close(ctx context.Context) error
}
```

`Store` 实现上述所有 caller-facing capability。业务调用方应依赖其实际需要的最小接口；组合根可持有 `*Store`。

## 9. Adapter SPI

```go
type StoreAdapter interface {
    Name() string
    PutObject(ctx context.Context, key string, body io.Reader, size int64, opts PutAdapterOptions) (ObjectInfo, error)
    GetObject(ctx context.Context, key string) (io.ReadCloser, ObjectInfo, error)
    HeadObject(ctx context.Context, key string) (ObjectInfo, error)
    DeleteObject(ctx context.Context, key string, strict bool) error
    CopyObject(ctx context.Context, source, target string, opts CopyAdapterOptions) (ObjectInfo, error)
    ListObjects(ctx context.Context, prefix string, max int, continuation string) (ListPage, error)
}

type MultipartAdapter interface {
    InitiateMultipart(ctx context.Context, key string, opts PutAdapterOptions) (UploadID, error)
    UploadPart(ctx context.Context, id UploadID, partNumber int, body io.Reader, size int64) (PartETag, error)
    ListParts(ctx context.Context, id UploadID) ([]PartETag, error)
    CompleteMultipart(ctx context.Context, id UploadID, parts []PartETag) (ObjectInfo, error)
    AbortMultipart(ctx context.Context, id UploadID) error
}

type PresignAdapter interface {
    PresignURL(ctx context.Context, key string, op PresignOperation, ttlSeconds int64, opts PresignAdapterOptions) (PresignedURL, error)
}

type AdapterLifecycle interface {
    Health(ctx context.Context) error
    Close(ctx context.Context) error
}
```

Adapter SPI 为 provider adapter 与组合根服务，不是业务层抽象。`NewBlobStore` 会验证 adapter 具备完整 capability，缺失时返回 config typed error。

## 10. 数据模型

核心类型包括 `Key`、`Prefix`、`ObjectInfo`、`PutOptions`、`GetOptions`、`DeleteOptions`、`CopyOptions`、`ListOptions`、`ListPage`、`ObjectReader`、`MultipartSession`、`UploadID`、`PartETag`、`PresignedURL`、`PresignOptions`、`HealthReport`、`Hooks`。

数据模型必须使用 stdlib 与 `ossx` 自有类型；不得暴露 Aliyun SDK 类型。

## 11. 配置

`Config` 由模块自有结构承载。`ConfigFromEnv()` 可读取 `FOUNDATIONX_OSSX_*` 约定变量作为组合根便利函数，但模块不得直接依赖 `configx`。

关键配置包括 bucket/region/endpoint、timeout、retry、circuit breaker、policy、presign max TTL、list max page size、checksum behavior。

## 12. 错误模型

对外错误使用 typed `*Error` 与 `ErrorKind`，覆盖 config、key、metadata、checksum、not_found、conflict、permission、timeout、cancelled、provider_failure、closed、unavailable、rate_limit 等类别。

Provider error 必须在 adapter 边界转换；retry classification 依赖 `ErrorKind` 与 `Retryable` 标记。

## 13. 目录结构

```text
ossx/
  pkg/ossx/
    blobstore.go
    store.go
    multipart.go
    presign.go
    config.go
    errors.go
    observability.go
    retry.go
    inmemory.go
  adapters/aliyun/
    oss.go
    oss_integration_test.go
  release/
    manifest/latest.json
    evidence/local-acceptance.md
```

## 14. 依赖策略

- `pkg/ossx` 可依赖 Go stdlib 与模块内包。
- Aliyun SDK 只能出现在 `adapters/aliyun`。
- 禁止 `pkg/ossx` 依赖 `configx` 或业务基础设施模块。
- 禁止引入 AWS/S3 SDK 作为当前版本依赖。

## 15. 测试矩阵

| ID | Test Case | Status |
| --- | --- | --- |
| TC-001 | config validation 与 nil hooks | 本地通过 |
| TC-002 | key/metadata/checksum validation | 本地通过 |
| TC-003 | Put/Get streaming core path | 本地通过 |
| TC-004 | Delete strict missing object | 本地通过 |
| TC-005 | Copy/Head/Exists/List pagination | 本地通过 |
| TC-006 | Multipart lifecycle | 本地通过 |
| TC-007 | Presign validation 与 audit masking | 本地通过 |
| TC-008 | Policy enforcement | 本地通过 |
| TC-009 | Adapter provider error translation | 本地通过 |
| TC-010 | Aliyun adapter gated integration | 编译/无凭证 skip；真实 artifact 待归档 |
| TC-011 | Retry/circuit behavior | 本地通过 |
| TC-012 | Health/Close lifecycle | 本地通过 |
| TC-013 | Public interface governance | 本地通过 |

## 16. 性能与可靠性

- Put/Get 必须保持 streaming-first。
- Retry 与 circuit breaker 仅重试 timeout、connection、unavailable、rate_limit 等可恢复错误。
- Strict delete 必须先 Head 缺失对象，确保语义可见。
- 当前版本缺少 production soak 与真实故障注入归档，因此可靠性只能判定为本地候选。

## 17. 可观测性

Hooks 包括 metrics、tracer、logger、audit。所有 label 与字段必须脱敏，不记录 signed URL、AK/SK、真实 credential 或未净化 key。

## 18. 安全

- `.env.example` 仅允许占位符。
- secret-scope check 阻止真实凭证进入仓库。
- Gitleaks/xlibgate 外部 artifact 是生产放行必要证据。
- Release evidence 不得包含真实 endpoint、AK/SK 或 signed URL。

## 19. CI 与质量门禁

本地生产候选门禁：

```text
scripts/secret-scope-check.sh
GOWORK=off go test ./pkg/ossx -run 'TestPublicInterfacesStayWithinGovernanceLimit|TestNewBlobStoreRejectsMissingAdapterCapabilities|TestSPISurface' -count=1
GOWORK=off go test -race ./... -count=1
GOWORK=off go test ./pkg/ossx -count=1 -covermode=atomic -coverprofile=/tmp/ossx-pkg.cover
go tool cover -func=/tmp/ossx-pkg.cover
GOWORK=off go vet ./...
GOWORK=off go build ./...
golangci-lint run --allow-parallel-runners ./...
```

生产放行还需要 release-tag CI artifact。

## 20. Release 与证据

`release/manifest/latest.json` 与 `release/evidence/local-acceptance.md` 记录本地候选证据。`factory=false` 必须保持，直到以下证据补齐：

- `v1.2.1` tag + GitHub Release。
- GitHub Actions release-tag 全绿。
- Gitleaks/xlibgate artifact。
- 真实 Aliyun integration artifact。
- 下游接入与 production soak artifact。
- 四源 scorer + arbiter `composite_score >= 98`。

## 21. Rollout

推荐顺序：

1. 作为本地候选进入受控预发布环境。
2. 以非生产凭证跑真实 Aliyun integration artifact。
3. 接入一个下游模块验证 API ergonomics。
4. 补 production soak 与 failure profile。
5. 归档 release-tag CI 与四源评分后再翻转生产结论。

## 22. 风险与开放问题

| ID | 问题 | 状态 |
| --- | --- | --- |
| OQ-001 | release-tag CI artifact 尚未归档 | Open |
| OQ-002 | Gitleaks/xlibgate artifact 尚未归档 | Open |
| OQ-003 | live Aliyun integration artifact 尚未归档 | Open |
| OQ-004 | downstream adoption 与 soak 缺失 | Open |
| OQ-005 | observex 正式接口是否需要替换当前 compatible hooks | Open |

## 23. 变更历史

| Date | Version | Change | Author |
| --- | --- | --- | --- |
| 2026-06-19 | v1.2.1 | 收敛为本地生产候选：拆分 public capability interfaces 与 adapter SPI；去除 S3/旧 11-method 接口残留；明确外部生产证据缺口 | ZoneCNH |
| 2026-06-19 | v1.2.0 | release-grade test hardening、CI/CD pipeline 与 local evidence 初版 | ZoneCNH |
| 2026-06-18 | v1.1.0 | 身份收敛为 Aliyun OSS 专用 adapter；完成真实 Aliyun adapter、multipart、presign、policy、retry/circuit、hooks | ZoneCNH |
