# ossx Spec

- Status: Implemented Locally
- Spec-Version: v1.3.0
- Last-Updated: 2026-06-30
- Layer: 基座 · 对象存储扩展
- Version: v1.2.1 local-production-candidate（代码位于 `/home/workspace/ossx` branch `ossx`；远端 release/tag 待归档）
- Module-Identity: Aliyun OSS 专用 adapter（单 provider；非通用对象存储抽象；不承诺多 provider 或 S3-compatible SPI）
- Public Module: `github.com/ZoneCNH/ossx/pkg/ossx`

## 1. Goal

`ossx` 为 ZoneCNH 体系提供 Aliyun OSS 专用对象存储能力，用于基础设施层对象读写、列举、multipart、presign、健康检查和受控关闭。v1.2.1 目标是完成生产候选级实现、接口治理、本地质量门禁和 `dev.md` 驱动的真实 Aliyun OSS 集成验证。

## 2. Scope

- Aliyun OSS bucket 的对象写入、读取、元数据查询、删除和列举。
- Multipart upload 生命周期。
- Presigned GET/PUT URL 生成。
- Strict delete 语义。
- Health、Close 和并发生命周期安全。
- 指标、错误摘要和测试输出脱敏。
- 本地 coverage/race/vet/build/lint/secret gate/live integration 验证。

## 3. Non-Goals

- 不提供多云对象存储抽象。
- 不承诺 S3-compatible adapter SPI。
- 不承诺业务域策略、交易、行情、因子或风控逻辑。
- 不在仓库中保存 AK/SK、bucket、endpoint 或 signed URL。

## 4. Module Identity

`ossx` 是 foundation 层对象存储扩展，位于应用域之下。模块边界必须保持 Aliyun OSS 专用，避免向上吸收业务含义，也避免向外暴露过宽 adapter SPI。

## 5. Architecture

```text
pkg/ossx public API
  ├─ Store / BlobStore
  ├─ capability interfaces: MultipartStarter, Presigner, HealthChecker, StoreCloser
  ├─ policy/config/error/observability helpers
  └─ adapter SPI: StoreAdapter, MultipartAdapter, PresignAdapter, AdapterLifecycle

adapters/aliyun
  └─ Aliyun OSS SDK binding with strict delete, multipart, presign, health, close
```

## 6. Functional Requirements

| ID | Requirement | Status |
| --- | --- | --- |
| FR-001 | 从显式配置构造 Aliyun OSS store | Complete Locally |
| FR-002 | Put/Get/Head/Delete 对象 | Complete Locally |
| FR-003 | Prefix + pagination list | Complete Locally |
| FR-004 | Multipart start/upload/complete/abort | Complete Locally |
| FR-005 | Presigned GET/PUT URL | Complete Locally |
| FR-006 | Strict delete 在缺失对象时返回可分类错误 | Complete Locally |
| FR-007 | 错误分类和脱敏输出 | Complete Locally |
| FR-008 | Public API 和 adapter SPI 受治理测试约束 | Complete Locally |
| FR-009 | 指标、日志和测试输出不泄露 secret | Complete Locally |
| FR-010 | 使用 `dev.md` 执行真实 Aliyun OSS 集成测试 | Complete Locally |

## 7. Behavioral Requirements

| ID | Requirement | Status |
| --- | --- | --- |
| BR-001 | 缺少必要配置时 fail fast | Complete Locally |
| BR-002 | 不输出 AK/SK、bucket、endpoint、signed query | Complete Locally |
| BR-003 | closed store 的后续操作返回稳定错误 | Complete Locally |
| BR-004 | strict delete 先 Head 后 Delete | Complete Locally |
| BR-005 | non-strict delete 允许幂等删除 | Complete Locally |
| BR-006 | multipart abort/complete 失败可观测 | Complete Locally |
| BR-007 | presign 只通过 capability 暴露 | Complete Locally |
| BR-008 | Health/Close 只依赖 adapter lifecycle | Complete Locally |
| BR-009 | 并发 Close 与操作不出现数据竞争 | Complete Locally |
| BR-010 | integration test 默认跳过，显式环境变量才运行 | Complete Locally |
| BR-011 | live integration 只读取本地 `dev.md` 派生环境变量 | Complete Locally |
| BR-012 | release manifest 不把本地候选误标为完整生产发布 | Complete Locally |

## 8. Public API Contract

`BlobStore` 是核心 7 方法接口：

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
```

Optional capabilities:

- `MultipartStarter`
- `Presigner`
- `HealthChecker`
- `StoreCloser`

Adapter capabilities:

- `StoreAdapter`
- `MultipartAdapter`
- `PresignAdapter`
- `AdapterLifecycle`

## 9. Data Models

- `ObjectInfo`: key、size、etag、last modified、content type、metadata。
- `PutOptions`: content type、metadata、cache control 等写入选项。
- `ListOptions` / `ListResult`: prefix、marker/continuation、limit、objects。
- `MultipartUpload`: upload id、part upload、complete、abort。
- `Config`: endpoint、region、bucket、protocol、access key id/secret、strict delete。

## 10. Configuration

本地 live integration 使用 `/home/workspace/ZoneCNH/sre/secrets/env/dev.md` 作为凭证来源，由命令运行时派生环境变量；文档、测试日志和 release manifest 不得包含具体 secret 值。

## 11. Errors

错误必须可分类、可观测、可脱敏。not found、invalid config、closed store、adapter capability missing、multipart failure、presign failure 必须能在调用方侧区分。

## 12. Observability

日志和指标只允许记录脱敏 key、operation、status、duration 和错误类别。禁止记录 AK/SK、bucket、endpoint、authorization header、signed query 或完整 signed URL。

## 13. Security

- 密钥不得提交到仓库。
- `secret-scope-check.sh` 必须阻止旧路径、示例密钥和 signed URL 泄露。
- integration test 输出只能确认必要字段存在，不打印值。
- release 证据中允许记录命令和 pass/fail，不允许记录 secret。

## 14. Dependencies

`ossx` 不得依赖业务域模块。依赖边界仅允许 Go 标准库、Aliyun OSS SDK 和基础测试 / lint 工具链。

## 15. Acceptance Tests

| TC | Covers | Evidence |
| --- | --- | --- |
| TC-001 | Config validation | `pkg/ossx` config tests |
| TC-002 | Object core operations | `pkg/ossx` store tests + Aliyun integration |
| TC-003 | List pagination | list tests |
| TC-004 | Multipart lifecycle | multipart tests |
| TC-005 | Presign | presign tests and host-only integration assertion |
| TC-006 | Strict delete | strict delete unit and live integration tests |
| TC-007 | Error classification | error-path tests |
| TC-008 | Observability sanitization | sanitization tests |
| TC-009 | API governance | interface-count and SPI tests |
| TC-010 | Race safety | `GOWORK=off go test -race ./... -count=1` |
| TC-011 | Coverage | `pkg/ossx` 100.0% statement coverage |
| TC-012 | Static gates | vet/build/golangci-lint |
| TC-013 | Secret scope | `./scripts/secret-scope-check.sh` |

## 16. Non-Functional Requirements

| ID | Requirement | Status |
| --- | --- | --- |
| NFR-001 | Release-tag CI artifact | Blocked External |
| NFR-002 | Gitleaks / xlibgate release evidence | Blocked External |
| NFR-003 | Interface governance regression tests | Complete Locally |
| NFR-004 | Live Aliyun integration | Complete Locally; CI artifact pending |
| NFR-005 | Downstream adoption evidence | Blocked External |
| NFR-006 | Production soak evidence | Blocked External |
| NFR-007 | Four-source scorer / arbiter evidence | Blocked External |

## 17. CI/CD and Release Evidence

Local evidence for v1.2.1:

- `./scripts/secret-scope-check.sh`
- `GOWORK=off go test ./pkg/ossx -count=1 -covermode=atomic -coverprofile=/tmp/ossx-pkg.cover`
- `go tool cover -func=/tmp/ossx-pkg.cover`
- `GOWORK=off go test -race ./... -count=1`
- `GOWORK=off go vet ./...`
- `GOWORK=off go build ./...`
- `golangci-lint run --allow-parallel-runners ./...`
- `jq . release/manifest/latest.json >/dev/null`
- `OSSX_LIVE_INTEGRATION=1 GOWORK=off go test -tags integration ./adapters/aliyun -count=1 -timeout 180s`

## 18. Production Blockers

Full production release remains blocked until these are archived:

- `v1.2.1` release-tag CI pass.
- Gitleaks and xlibgate artifacts from release CI.
- Aliyun live integration artifact from controlled CI.
- Downstream adoption evidence.
- Production-equivalent soak evidence.
- Four-source scorer and arbiter pass.

## 19. Compatibility

v1.2.1 intentionally narrows public interfaces. Callers should depend on `BlobStore` for core object operations and assert optional capabilities only where needed.

## 20. Rollout

1. Merge local v1.2.1 implementation.
2. Tag and push release candidate.
3. Archive release-tag CI and security gate evidence.
4. Run controlled live integration CI.
5. Adopt in one downstream module.
6. Run production-equivalent soak.
7. Promote from `local-production-candidate` to production only after all blockers close.

## 21. Definition of Done

Local DoD is complete when all local gates pass and docs/manifest state is consistent. Production DoD additionally requires all external blockers in section 18.

## 22. Open Questions

- Which downstream module will provide first adoption evidence?
- What soak duration and SLO thresholds should be used for final production promotion?
- Where should four-source scorer artifacts be archived for this module?

## 23. Revision History

| Version | Date | Change |
| --- | --- | --- |
| v1.2.1 | 2026-06-19 | Local production candidate: 100% `pkg/ossx` coverage, API governance, dev.md live integration, release manifest update |
| v1.2.0 | 2026-06-19 | Earlier production-readiness audit baseline |
| v1.1.0 | 2026-06-18 | Initial Aliyun OSS adapter readiness pass |
