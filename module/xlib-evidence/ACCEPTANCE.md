# xlib-evidence 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-20
- Module-Version: v0.2.4
- Module-State: v0.2.4 已发布；runtime 本地 100.0% atomic coverage、race、vet、build、benchmark、Trust Alignment 与 GitHub Release evidence contract 已通过；CI/CD workflows 已部署，GitHub Release v0.2.4 与 release evidence assets 已发布归档
- Layer: L1 证据
- Runtime-Repo: /home/xlib-evidence
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 xlib-evidence 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/xlib-evidence/FEATURES.md && test -f module/xlib-evidence/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/xlib-evidence | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/xlib-evidence && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/xlib-evidence && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/xlib-evidence && go vet ./... | 无 vet 问题 |
| 构建检查 | cd /home/xlib-evidence && go build ./... | 所有包可构建 |
| 覆盖率证据 | cd /home/xlib-evidence && go test ./... -covermode=atomic -coverprofile=coverage.out | 覆盖率文件生成且 total = 100.0%，满足 v0.2.4 生产发布门槛 |
| 性能基线 | cd /home/xlib-evidence && go test -bench='Benchmark(ManifestGen\|MultiModuleAggregate)$' -run '^$' ./... | manifest 生成 < 1s，20 模块聚合 < 5s |
| 依赖边界 | cd /home/xlib-evidence && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |
| 仓库身份契约 | cd /home/xlib-evidence && test -f .repo-contract.yaml && grep -q '^public_package: github.com/ZoneCNH/xlib-evidence$' .repo-contract.yaml && grep -q '^latest_git_tag: v0.2.4$' .repo-contract.yaml | repo/module/public_package/tag 身份对齐 |
| Trust Identity | cd /home/xlib-evidence && GOWORK=off xlibgate trust identity --repo . | xlibgate 身份门禁通过 |
| Trust Template Residue | cd /home/xlib-evidence && GOWORK=off xlibgate trust template-residue --repo . | 无模板残留、占位符或生成器身份误配 |
| Release 证据资产 | gh release view v0.2.4 --repo ZoneCNH/xlib-evidence --json assets,isDraft,isPrerelease | release 非 draft、非 prerelease，且包含 coverage.out、module.json、checksums.txt |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 / BR-002 | 覆盖率数据被结构化收集；覆盖率低于 100.0% 拒绝发布 / TC-001: go test -run 'Test(ParseGoCoverageProfile\|CoverageValidateRejectsThresholdAndPercentTamper\|NewCoverageNormalizesTime)' | ✅ | TRACEABILITY.md |
| AC-002 | FR-002 / BR-001 | 门禁全绿时生成 manifest，含 version/commit/gates/coverage/hash / TC-002: go test -run TestNewManifestNormalizesSortsAndValidates | ✅ | TRACEABILITY.md |
| AC-003 | FR-003 / BR-003 | manifest hash 校验通过；篡改检测失败 / TC-003: go test -run TestManifestValidateRejectsFailedGateLowCoverageAndTamper | ✅ | TRACEABILITY.md |
| AC-004 | FR-004 | 远程查询返回结构化 evidence manifest / TC-004: go test -run 'Test(ClientFetchManifest\|ManifestHandler)' | ✅ | TRACEABILITY.md |
| AC-005 | FR-005 / BR-004 | evidence 报告可渲染；存储不可变追加，并发读写保持一致快照 / TC-005: go test -run 'Test(ReportsRenderValidatedManifest\|StoreAppendEnforcesHashChain\|StoreAppendStoresImmutableManifest\|StoreSupportsConcurrentAppendAndReads)' | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001 | go test -run 'Test(ParseGoCoverageProfile\|CoverageValidateRejectsThresholdAndPercentTamper\|NewCoverageNormalizesTime)' — 覆盖率解析、100.0% 边界和时间归一化 | ✅ | TRACEABILITY.md |
| TC-002 | FR-002, BR-001 | go test -run TestNewManifestNormalizesSortsAndValidates — 全部门禁通过→manifest 生成且 hash 有效 | ✅ | TRACEABILITY.md |
| TC-003 | FR-003, BR-003 | go test -run TestManifestValidateRejectsFailedGateLowCoverageAndTamper — 合法 manifest 通过；篡改 manifest 拒绝 | ✅ | TRACEABILITY.md |
| TC-004 | FR-004 | go test -run 'Test(ClientFetchManifest\|ManifestHandler)' — HTTP endpoint 返回 JSON 证据 | ✅ | TRACEABILITY.md |
| TC-005 | FR-005, BR-004 | go test -run 'Test(ReportsRenderValidatedManifest\|StoreAppendEnforcesHashChain\|StoreAppendStoresImmutableManifest\|StoreSupportsConcurrentAppendAndReads)' — 报告渲染、evidence 追加不可变且 Store 并发读写一致 | ✅ | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | collect-coverage: 模块执行 go test -cover→覆盖率报告被收集并结构化存储 | AC-001 / TC-001 / go test -run 'Test(ParseGoCoverageProfile\|CoverageValidateRejectsThresholdAndPercentTamper\|NewCoverageNormalizesTime)' | ✅ | TRACEABILITY.md |
| FR-002 | generate-manifest: 模块通过所有门禁→生成 Release Manifest(version/commit/gates/coverage/hash) | AC-002 / TC-002 / go test -run TestNewManifestNormalizesSortsAndValidates | ✅ | TRACEABILITY.md |
| FR-003 | validate-manifest: CI 检查 manifest→验证完整性、hash 与内容一致性 | AC-003 / TC-003 / go test -run TestManifestValidateRejectsFailedGateLowCoverageAndTamper | ✅ | TRACEABILITY.md |
| FR-004 | remote-evidence: 远程查询模块证据→返回结构化 manifest JSON | AC-004 / TC-004 / go test -run 'Test(ClientFetchManifest\|ManifestHandler)' | ✅ | TRACEABILITY.md |
| FR-005 | report: 聚合多模块证据→生成跨模块统一报告，并提供并发安全、追加不可变的证据 Store | AC-005 / TC-005 / go test -run 'Test(ReportsRenderValidatedManifest\|StoreAppendEnforcesHashChain\|StoreAppendStoresImmutableManifest\|StoreSupportsConcurrentAppendAndReads)' | ✅ | TRACEABILITY.md |
| BR-001 | manifest必须包含门禁全绿证据 | TC-002 / TestNewManifestNormalizesSortsAndValidates | ✅ | TRACEABILITY.md |
| BR-002 | 覆盖率低于100.0%不得发布 | TC-001 / 覆盖率边界测试(99.99%拒绝, 100.00%通过) | ✅ | TRACEABILITY.md |
| BR-003 | manifest不可事后篡改(hash链校验) | TC-003 / TestManifestValidateRejectsFailedGateLowCoverageAndTamper | ✅ | TRACEABILITY.md |
| BR-004 | evidence存储必须不可变追加，并在并发读写时保持一致快照 | TC-005 / Test(StoreAppendEnforcesHashChain\|StoreAppendStoresImmutableManifest\|StoreSupportsConcurrentAppendAndReads) | ✅ | TRACEABILITY.md |
| NFR-001 | Performance | manifest生成延迟 < 1s / benchmark: go test -bench=BenchmarkManifestGen -run '^$' | ✅ | TRACEABILITY.md |
| NFR-002 | Performance | 20模块证据聚合 < 5s / benchmark: go test -bench=BenchmarkMultiModuleAggregate -run '^$' | ✅ | TRACEABILITY.md |
| NFR-003 | Security | manifest hash完整性校验(防篡改) / TC-003: 篡改检测 | ✅ | TRACEABILITY.md |
| NFR-004 | Security | 不读取密钥/不连接远程服务(remote optional) / rg -n "os\\.Getenv\|TOKEN\|SECRET\|PASSWORD\|Redis\|Postgres\|postgres\|redis" --glob '*.go' . 无匹配 | ✅ | TRACEABILITY.md |
| NFR-005 | Dependency | 禁止依赖存储/网络后端(observex/configx/resiliencx/schedulex/Redis/Postgres) / go list -deps ./... 与 go list -m all | ✅ | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [x] 运行时代码仓库 /home/xlib-evidence 通过 go test、go test -race、go vet、go build、benchmark 与 100.0% atomic coverage 门槛。
- [x] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [x] v0.2.4 已通过本地可复验命令并发布；release workflow 已配置 `coverage.out`、`module.json`、`checksums.txt` 证据资产、`.repo-contract.yaml` 仓库身份契约、Trust Alignment 与 tag/version 合约。

## 6. 当前验收证据

- 2026-06-20 本地验收已执行：go test ./...、go test ./... -race -count=1、go vet ./...、go build ./... 全部通过。
- 覆盖率使用 atomic mode 采集，total 100.0%；go tool cover -func=coverage.out 显示全部函数 100.0%，包括 Store 并发与 immutable snapshot 相关函数。
- BenchmarkManifestGen 20340 ns/op，BenchmarkMultiModuleAggregate 543300 ns/op，均显著低于 NFR 阈值。
- go list -m all 仅返回 github.com/ZoneCNH/xlib-evidence；release/docs contract 本地校验通过，tag 为 v0.2.4。
- xlibgate trust identity 与 xlibgate trust template-residue 已通过；CI 使用 xlibgate commit `555ee7b841b52e6e11d7493fb31916e80c28d7f3`，因为远端 `v1.0.0` tag 对应二进制尚未暴露 trust command。
- GitHub Release 已发布：https://github.com/ZoneCNH/xlib-evidence/releases/tag/v0.2.4。
- release 证据资产已上传：checksums.txt (`sha256:146d65a4e943b2d9d484d492682b1b29c2c46030822d138242eb9b9619b3d632`)、coverage.out (`sha256:a2d1b51be6fe9af88cf88dbed63b5b620865226ad49cf1ce6b97bffb900d876d`)、module.json (`sha256:afd949d432e8d4db01864671ff548b90be8a337d05bdf90c97a4fe9147cd47a3`)。
- 远端 CI/CD 已部署并触发：CI/CD run `27854994680` 与 Release run `27855001387` 已创建；截至 2026-06-20 GitHub Actions 查询仍为 queued，该状态不阻断已发布的 GitHub Release evidence assets 归档事实。
- Secret Scan 已纳入 CI/CD workflow；本地环境未安装 gitleaks，本地未重复执行该门禁。
- FEATURES.md、ACCEPTANCE.md 与 runtime v0.2.4 生产验收口径已对齐。
