# ossx 功能实现状态

- Status: Local Production Candidate（本地生产候选）
- Last-Updated: 2026-06-30
- Source: [SPEC.md](./SPEC.md) v1.2.1 · [TRACEABILITY.md](./TRACEABILITY.md) · [ACCEPTANCE.md](./ACCEPTANCE.md)
- Implementation: `/home/workspace/ossx` branch `ossx`
- Module-Identity: Aliyun OSS 专用 adapter（单 provider；非通用对象存储抽象；不承诺 S3-compatible SPI）

`ossx` 已实现 Aliyun OSS 对象存储核心能力，并通过本地质量门禁与 `dev.md` 驱动的 live integration test。当前状态适合受控集成和预发布验证；完整生产发布仍依赖外部 CI/CD、下游接入、soak 和评分归档证据。

## 1. 能力总览

| 能力 | 状态 | 说明 |
| --- | --- | --- |
| Store 构造与配置 | Complete Locally | 支持 endpoint、region、bucket、protocol、AK/SK、strict delete 等配置校验 |
| 核心对象操作 | Complete Locally | Put/Get/Head/Delete/List 已实现并测试 |
| Multipart upload | Complete Locally | Start/UploadPart/Complete/Abort 通过 `MultipartStarter` capability 暴露 |
| Presign | Complete Locally | Presigned GET/PUT 通过 `Presigner` capability 暴露，测试不输出 signed URL |
| Policy / 严格删除 | Complete Locally | strict delete 缺失对象前置 `HeadObject`，可观测失败 |
| Health / Close | Complete Locally | 通过 `HealthChecker` 与 `StoreCloser` capability 暴露 |
| Observability | Complete Locally | 指标和错误摘要脱敏，不泄露 secret、bucket、endpoint 或 query token |
| Aliyun adapter | Complete Locally | 单 provider 专用实现；并发关闭状态已通过 race 验证 |
| Release evidence | Partial | release manifest 为 `local-production-candidate`；远端 release-tag 证据未归档 |

## 2. 公共 API

```go
type BlobStore interface {
    PutObject(ctx context.Context, key string, body io.Reader, size int64, opts PutOptions) error
    GetObject(ctx context.Context, key string) (io.ReadCloser, ObjectInfo, error)
    HeadObject(ctx context.Context, key string) (ObjectInfo, error)
    DeleteObject(ctx context.Context, key string) error
    ListObjects(ctx context.Context, prefix string, opts ListOptions) (ListResult, error)
    Health(ctx context.Context) error
    Close() error
}

type MultipartStarter interface { StartMultipartUpload(...) (MultipartUpload, error) }
type Presigner interface { PresignGet(...); PresignPut(...) }
type HealthChecker interface { Health(context.Context) error }
type StoreCloser interface { Close() error }
```

Adapter SPI 保持 Aliyun OSS 专用和能力化拆分：

```go
type StoreAdapter interface {
    PutObject(...)
    GetObject(...)
    HeadObject(...)
    DeleteObject(...)
    ListObjects(...)
    Health(...)
    Close(...)
}

type MultipartAdapter interface { StartMultipartUpload(...) (MultipartUpload, error) }
type PresignAdapter interface { PresignGet(...); PresignPut(...) }
type AdapterLifecycle interface { Health(context.Context) error; Close() error }
```

## 3. 已完成验收点

| FR | 状态 | 说明 |
| --- | --- | --- |
| FR-001 | Complete Locally | Aliyun OSS store 构造、配置和 adapter 注入 |
| FR-002 | Complete Locally | Put/Get/Head/Delete/List 对象能力 |
| FR-003 | Complete Locally | 分页 list 与 prefix 策略 |
| FR-004 | Complete Locally | Multipart lifecycle |
| FR-005 | Complete Locally | Presigned GET/PUT |
| FR-006 | Complete Locally | Strict delete 与 not-found 语义 |
| FR-007 | Complete Locally | 错误分类与脱敏 |
| FR-008 | Complete Locally | Public API 与 SPI 治理 |
| FR-009 | Complete Locally | Observability sanitization |
| FR-010 | Complete Locally | `dev.md` live Aliyun integration 本地验证 |

## 4. 本地证据

| Evidence | 状态 |
| --- | --- |
| `GOWORK=off go test ./pkg/ossx -count=1 -covermode=atomic -coverprofile=/tmp/ossx-pkg.cover` | Pass，`pkg/ossx` coverage 100.0% |
| `GOWORK=off go test -race ./... -count=1` | Pass |
| `GOWORK=off go vet ./...` | Pass |
| `GOWORK=off go build ./...` | Pass |
| `golangci-lint run --allow-parallel-runners ./...` | Pass |
| `./scripts/secret-scope-check.sh` | Pass |
| `OSSX_LIVE_INTEGRATION=1 GOWORK=off go test -tags integration ./adapters/aliyun -count=1 -timeout 180s` | Pass locally with values derived from `dev.md`; no secret values printed |
| `release/manifest/latest.json` | Valid JSON, `version=v1.2.1`, `status=local-production-candidate` |

## 5. 未完成生产放行证据

| Evidence | 状态 | 说明 |
| --- | --- | --- |
| Release-tag CI | Blocked External | 需要 `v1.2.1` tag 的远端 CI 成功记录 |
| Gitleaks / xlibgate | Blocked External | 需要 release-tag CI 附带的 secret gate 和 xlibgate 归档 |
| Aliyun integration CI artifact | Blocked External | 需要受控 CI 环境的 live integration artifact |
| Downstream adoption | Blocked External | 需要真实下游模块接入和验证 |
| Production soak | Blocked External | 需要生产等价环境 soak 数据 |
| Four-source scorer / arbiter | Blocked External | 需要 claude/codex/copilot/rules scorer 与 arbiter pass |

## 6. 结论

`ossx` 功能实现已满足本地生产候选标准，可进入受控集成 / 预发布；在外部生产证据闭合前，不应声明完整生产发布。
