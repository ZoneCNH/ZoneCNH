# ossx 验收清单

- Status: Local Production Candidate（本地生产候选；完整生产放行待外部证据）
- Last-Updated: 2026-06-19
- Source: [SPEC.md](./SPEC.md) v1.2.1 · [TRACEABILITY.md](./TRACEABILITY.md) · [FEATURES.md](./FEATURES.md)
- Code Source: `/home/ossx` branch `ossx`
- Public Module: `github.com/ZoneCNH/ossx/pkg/ossx`

> 本文档回答"ossx 是否达到生产级应用"。截至 2026-06-19，本地代码、测试、接口治理和文档证据支持 **本地生产候选**；但缺少 release-tag CI、Gitleaks/xlibgate 归档、真实 Aliyun 集成归档、下游接入和生产 soak 证据，因此不能声明完整生产级放行。

## 1. 总体判定

| 维度 | 判定 | 证据 |
| --- | --- | --- |
| 核心功能 | 本地通过 | Put/Get/Delete/Copy/Head/Exists/List、multipart、presign、policy、health、observability 均有本地测试覆盖 |
| 公共 API 治理 | 本地通过 | `BlobStore` 拆为 7-method 核心接口；multipart/presign/health/close 为独立 capability 接口 |
| Adapter 边界 | 本地通过 | `StoreAdapter`、`MultipartAdapter`、`PresignAdapter`、`AdapterLifecycle` 分层；provider SDK 限定在 `adapters/aliyun` |
| 严格删除语义 | 本地通过 | `StrictNotFound` 路径先 Head 再 Delete，避免 provider 幂等删除吞掉缺失对象 |
| 并发生命周期 | 本地通过 | Aliyun adapter close 状态使用 atomic，race 测试覆盖 |
| 本地质量门禁 | 本地通过 | secret-scope、依赖隔离、race、coverage、vet、build、lint |
| 外部生产证据 | 未完成 | release-tag CI、Gitleaks/xlibgate、live integration、downstream adoption、production soak 缺归档 |

## 2. 本地门禁

以下命令以 `/home/ossx` 为工作目录：

| Gate | 命令 | 期望 |
| --- | --- | --- |
| Secret scope | `scripts/secret-scope-check.sh` | 只允许 `.env.example` 与文档中的占位变量，不泄露真实凭证 |
| 依赖隔离 | `GOWORK=off go list -deps ./...` + 禁止项扫描 | 不出现 `configx`、AWS/S3、Redis/MySQL/Postgres/NATS/Kafka 依赖 |
| API governance | `GOWORK=off go test ./pkg/ossx -run 'TestPublicInterfacesStayWithinGovernanceLimit|TestNewBlobStoreRejectsMissingAdapterCapabilities|TestSPISurface' -count=1` | 公共接口不超过 7 个方法；adapter capability 缺失会失败 |
| Race | `GOWORK=off go test -race ./... -count=1` | 全包 race 通过 |
| Coverage | `GOWORK=off go test ./pkg/ossx -count=1 -covermode=atomic -coverprofile=/tmp/ossx-pkg.cover` | `pkg/ossx` total 100.0% |
| Static checks | `GOWORK=off go vet ./...` | 通过 |
| Build | `GOWORK=off go build ./...` | 通过 |
| Lint | `golangci-lint run --allow-parallel-runners ./...` | 通过（本机存在 golangci-lint 时） |
| Manifest JSON | `jq . release/manifest/latest.json >/dev/null` | JSON 合法 |

## 3. 验收状态

| ID | 验收项 | 状态 | 证据 |
| --- | --- | --- | --- |
| AC-OSS-001 | 构造与配置校验 | 本地通过 | `NewBlobStore` 返回 `*Store`；nil hooks 为 no-op；adapter capability 校验 |
| AC-OSS-002 | Key/metadata/checksum 模型 | 本地通过 | key、metadata、checksum 分支覆盖 |
| AC-OSS-003 | 基础对象操作 | 本地通过 | Put/Get/Delete/Copy/Head/Exists/List 覆盖 |
| AC-OSS-004 | 流式读写 | 本地通过 | adapter SPI 使用 `io.Reader` / `io.ReadCloser` |
| AC-OSS-005 | Multipart | 本地通过 | initiate/upload/list/complete/abort 覆盖 |
| AC-OSS-006 | Presign | 本地通过 | TTL、operation allowlist、audit masking 覆盖 |
| AC-OSS-007 | lifecycle/retention/permission policy | 本地通过 | policy validate 与 enforcement 覆盖 |
| AC-OSS-008 | Aliyun adapter 隔离 | 本地通过 | provider SDK 限定 `adapters/aliyun`；adapter SPI 拆分 |
| AC-OSS-009 | Observability 与审计脱敏 | 本地通过 | metrics/tracer/logger no-op 与标签脱敏覆盖 |
| AC-OSS-010 | Health/Close 生命周期 | 本地通过 | health 状态、close 幂等、atomic race 覆盖 |

## 4. 仍阻塞完整生产放行的证据

| Blocker | 当前状态 | 需要补齐的证据 |
| --- | --- | --- |
| Release-tag CI | 未归档 | `v1.2.1` tag 触发的 GitHub Actions 全绿日志、release-preflight、post-release-smoke |
| Gitleaks / xlibgate | 本地缺完整工具证据 | secret scan 与 boundary gate 的 CI artifact |
| Live Aliyun integration | 本地无凭证时只能编译/跳过 | 真实 bucket 的 credentialed integration pass artifact，且不泄露 endpoint/AK/SK |
| Downstream adoption | 未完成 | 至少一个下游模块接入 `ossx` 的 PR/commit 与回归证据 |
| Production soak | 未完成 | 限流、超时、重试、provider 故障、multipart abort 等场景的时长与结果归档 |
| 四源评分门禁 | 未完成 | Claude/Codex/Copilot/rules scorer + arbiter `composite_score >= 98` 证据 |

## 5. 结论

`ossx` 可以作为本地生产候选进入受控集成或预发布验证；不能作为已经完成生产放行的模块对外声明。生产级结论必须等第 4 节证据补齐后再翻转。
