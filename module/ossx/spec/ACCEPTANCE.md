# ossx 生产级验收清单

- Status: Local Production Candidate（本地生产候选；完整生产放行待外部证据）
- Last-Updated: 2026-06-30
- Source: [SPEC.md](./SPEC.md) v1.2.1 · [TRACEABILITY.md](./TRACEABILITY.md) · [FEATURES.md](./FEATURES.md)
- Code Source: `/home/workspace/ossx` branch `ossx`
- Public Module: `github.com/ZoneCNH/ossx/pkg/ossx`

本清单记录 `ossx` 是否达到生产级应用的验收状态。当前结论是：代码、接口治理、本地质量门禁和 `dev.md` 驱动的 Aliyun OSS 真实集成测试已经支撑 **本地生产候选**；但完整生产发布仍缺 release-tag CI、Gitleaks/xlibgate、集成 CI 制品、下游接入、生产 soak 和四源 scorer/arbiter 归档证据，因此不得标记为完全生产放行。

## 1. 总体判定

| 维度 | 判定 | 证据 |
| --- | --- | --- |
| 核心对象能力 | 本地通过 | Put/Get/Head/Delete/List、multipart、presign、health、close 已由单元和集成测试覆盖 |
| Public API 治理 | 本地通过 | `BlobStore` 收敛为 7 方法接口；可选能力通过 capability interface 暴露 |
| Adapter 边界 | 本地通过 | Aliyun OSS 专用 adapter；不承诺多 provider 或 S3-compatible SPI |
| 删除语义 | 本地通过 | strict delete 在删除前执行 `HeadObject`，缺失对象返回可观测错误 |
| 并发生命周期 | 本地通过 | Aliyun adapter 使用原子关闭状态并通过 race 测试 |
| 本地质量门禁 | 本地通过 | secret scope、coverage、race、vet、build、lint、manifest JSON 均通过 |
| 真实云集成 | 本地通过 | `/home/workspace/ZoneCNH/sre/secrets/env/dev.md` 注入环境变量后运行 integration test；输出不打印密钥或签名 URL |
| 外部生产证据 | 未完成 | release-tag CI、远端 secret gate、下游接入、soak、四源评分仍需归档 |

## 2. 本地门禁

| Gate | 命令 / 证据 | 期望 |
| --- | --- | --- |
| Secret scope | `./scripts/secret-scope-check.sh` | 仅允许 `/home/workspace/ZoneCNH/sre/secrets/env/dev.md` 作为本地凭证来源；禁止提交密钥值 |
| Dependency isolation | `GOWORK=off go list -deps ./...` 加 forbidden dependency scan | 不依赖策略、交易、市场数据、因子等业务域 |
| API governance | `GOWORK=off go test ./pkg/ossx -run 'TestPublicInterfacesStayWithinGovernanceLimit|TestNewBlobStoreRejectsMissingAdapterCapabilities|TestSPISurface' -count=1` | 公共接口和 SPI 维持小面、显式能力边界 |
| Unit coverage | `GOWORK=off go test ./pkg/ossx -count=1 -covermode=atomic -coverprofile=/tmp/ossx-pkg.cover` | `pkg/ossx` statement coverage = 100.0% |
| Race | `GOWORK=off go test -race ./... -count=1` | 无数据竞争 |
| Static | `GOWORK=off go vet ./...`; `GOWORK=off go build ./...`; `golangci-lint run --allow-parallel-runners ./...` | 无 vet/build/lint 问题 |
| Manifest | `jq . release/manifest/latest.json >/dev/null` | release manifest 为合法 JSON，状态为 `local-production-candidate` |
| Live integration | `OSSX_LIVE_INTEGRATION=1 GOWORK=off go test -tags integration ./adapters/aliyun -count=1 -timeout 180s` | 使用 `dev.md` 派生环境变量，本地通过且不输出密钥或签名 URL |

## 3. Acceptance Criteria

| ID | 状态 | 验收标准 | 证据 |
| --- | --- | --- | --- |
| AC-OSS-001 | 本地通过 | 可通过配置构造 Aliyun OSS store | 构造、配置校验、缺失 capability 测试 |
| AC-OSS-002 | 本地通过 | 支持对象写入、读取、元数据查询和删除 | `pkg/ossx` 单元测试与 Aliyun integration test |
| AC-OSS-003 | 本地通过 | 支持分页列举对象 | list 行为测试 |
| AC-OSS-004 | 本地通过 | 支持 multipart 上传生命周期 | multipart 单元测试与 adapter capability 校验 |
| AC-OSS-005 | 本地通过 | 支持 presigned GET/PUT URL | presign 单元测试；integration 只校验 host，不打印 signed URL |
| AC-OSS-006 | 本地通过 | 支持 strict delete 缺失对象语义 | strict delete 单元测试与 live integration 测试 |
| AC-OSS-007 | 本地通过 | 失败路径返回可分类错误 | config、adapter、not-found、closed store 测试 |
| AC-OSS-008 | 本地通过 | 指标和日志不泄露 secret、bucket、endpoint 或 signed query | sanitization 测试与 secret scope gate |
| AC-OSS-009 | 本地通过 | 并发 close/read/write 不产生 race | `go test -race ./...` |
| AC-OSS-010 | 本地通过 | 本地质量门禁满足生产候选要求 | coverage/race/vet/build/lint/manifest gates |

## 4. 生产放行阻塞项

| Blocker | 状态 | 解除条件 |
| --- | --- | --- |
| Release-tag CI | 外部阻塞 | 创建并推送 `v1.2.1` tag，归档 GitHub Actions 成功记录 |
| Gitleaks / xlibgate | 外部阻塞 | 在 release-tag CI 中归档 secret scan 与 xlibgate 通过证据 |
| Aliyun integration CI artifact | 外部阻塞 | 在受控 CI 环境运行 live integration 并归档日志摘要，仍不得输出密钥或 signed URL |
| Downstream adoption | 外部阻塞 | 至少一个真实下游模块接入 `ossx` 并通过验证 |
| Production soak | 外部阻塞 | 在生产等价环境运行约定时长 soak 并归档错误率、延迟和重试数据 |
| Four-source scorer / arbiter | 外部阻塞 | 归档 claude/codex/copilot/rules scorer 与 arbiter pass 证据 |

## 5. 结论

`ossx` 已达到 **本地生产候选**：本地实现、测试、接口治理和真实 Aliyun OSS 集成验证完整；但由于外部发布和运行证据尚未归档，当前不得声明为完全生产级发布，也不得在模块索引中标记为 `factory=true`。
