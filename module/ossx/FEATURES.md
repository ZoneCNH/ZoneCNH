# ossx 功能实现状态

- Status: Local Production Candidate（本地生产候选）
- Last-Updated: 2026-06-19
- Source: [SPEC.md](./SPEC.md) v1.2.1 · [TRACEABILITY.md](./TRACEABILITY.md) · [ACCEPTANCE.md](./ACCEPTANCE.md)
- Implementation: `/home/ossx` branch `ossx`
- Module-Identity: Aliyun OSS 专用 adapter（单 provider；非通用对象存储抽象；非 S3-compatible）

> 当前实现已经完成 Aliyun OSS 单 provider 的核心功能与本地质量门禁，但生产放行仍取决于外部 CI、真实集成、下游接入和 soak 证据。

## 1. 能力总览

| 能力 | 状态 | 说明 |
| --- | --- | --- |
| 构造入口 | 完成 | `NewBlobStore(cfg, adapter StoreAdapter, hooks Hooks) (*Store, error)` |
| 核心对象操作 | 完成 | `Put` / `Get` / `Delete` / `Copy` / `Head` / `Exists` / `List` |
| Multipart | 完成 | `MultipartStarter` capability 提供 initiate/upload/list/complete/abort |
| Presign | 完成 | `Presigner` capability 提供 TTL、operation allowlist、audit masking |
| Policy | 完成 | lifecycle、retention、permission policy validation/enforcement |
| Health/Close | 完成 | `HealthChecker` / `StoreCloser` capability，close 幂等 |
| Observability | 完成 | observex-compatible hooks；metric/log/audit 标签脱敏 |
| Aliyun adapter | 完成 | provider SDK 与错误转换隔离在 `adapters/aliyun` |
| Release/production evidence | 部分完成 | 本地证据完整；外部 release/live/downstream/soak 证据未闭合 |

## 2. 公共 API

`Store` 是具体实现类型，调用方可按需要依赖窄接口：

```go
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

接口治理结论：`BlobStore` 保持 7 methods，其余能力拆分为独立 capability 接口；`NewBlobStore` 返回 `*Store`，因此调用方仍能拿到完整能力，但不需要依赖臃肿接口。

## 3. Adapter SPI

Adapter SPI 是 provider adapter 的实现边界，不是推荐的业务调用接口：

| SPI | 用途 |
| --- | --- |
| `StoreAdapter` | Put/Get/Head/Delete/Copy/List core object operations |
| `MultipartAdapter` | Multipart lifecycle |
| `PresignAdapter` | Provider-backed signed URL |
| `AdapterLifecycle` | Health probe 与 Close |

`NewBlobStore` 会校验 adapter 是否同时实现这些 capability，缺失时返回 `ErrorKindConfig`。这比旧的单一大接口更符合生产接口治理，也便于后续测试替身和 provider adapter 演进。

## 4. 实现文件

| 文件 | 说明 | 状态 |
| --- | --- | --- |
| `pkg/ossx/blobstore.go` | `Store`、核心 API、policy、retry/circuit、observability glue | 完成 |
| `pkg/ossx/store.go` | split adapter SPI | 完成 |
| `pkg/ossx/multipart.go` | multipart session wrapper | 完成 |
| `pkg/ossx/presign.go` | presign validation 与 adapter delegation | 完成 |
| `pkg/ossx/inmemory.go` | 测试与本地 adapter | 完成 |
| `adapters/aliyun/oss.go` | Aliyun OSS provider adapter | 完成 |
| `.github/workflows/ci.yml` | CI/CD 与 release-preflight 声明 | 本地已配置，外部 artifact 待归档 |
| `release/manifest/latest.json` | release metadata | v1.2.1 本地候选 |
| `release/evidence/local-acceptance.md` | 本地验收证据 | v1.2.1 本地候选 |

## 5. 本地验证状态

| 验证 | 状态 |
| --- | --- |
| secret-scope script | 通过 |
| dependency isolation scan | 通过 |
| API governance tests | 通过 |
| `go test -race ./...` | 通过 |
| `pkg/ossx` coverage | 100.0% |
| `go vet ./...` | 通过 |
| `go build ./...` | 通过 |
| `golangci-lint` | 通过（本机可用时） |
| release manifest JSON | 通过 |

## 6. 生产放行缺口

| 缺口 | 影响 |
| --- | --- |
| `v1.2.1` tag / GitHub Release / release-tag CI artifact 未归档 | 不能证明远端 release 产物与本地代码一致 |
| Gitleaks/xlibgate artifact 未归档 | 不能完成安全和边界门禁闭环 |
| 真实 Aliyun 集成 artifact 未归档 | 不能证明当前版本在真实 OSS 后端下通过 |
| 下游接入证据缺失 | 不能证明 API 可被实际业务模块采用 |
| soak / failure profile 缺失 | 不能证明长时间与异常场景稳定性 |

## 7. 结论

功能层面，`ossx` 已具备 Aliyun OSS 单 provider 的完整本地候选能力；治理层面，尚未达到完整生产级发布标准。后续工作应优先补外部证据，而不是继续扩大代码功能面。
