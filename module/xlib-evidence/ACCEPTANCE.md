# xlib-evidence 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.1.0
- Module-State: 本地验收通过，待发布
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
| 覆盖率证据 | cd /home/xlib-evidence && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/xlib-evidence && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 / BR-002 | 覆盖率数据被结构化收集；覆盖率低于 80% 拒绝发布 / TC-001: go test -run 'Test(ParseGoCoverageProfile\|CoverageValidateRejectsThresholdAndPercentTamper\|NewCoverageNormalizesTime)' | ✅ | TRACEABILITY.md |
| AC-002 | FR-002 / BR-001 | 门禁全绿时生成 manifest，含 version/commit/gates/coverage/hash / TC-002: go test -run TestNewManifestNormalizesSortsAndValidates | ✅ | TRACEABILITY.md |
| AC-003 | FR-003 / BR-003 | manifest hash 校验通过；篡改检测失败 / TC-003: go test -run TestManifestValidateRejectsFailedGateLowCoverageAndTamper | ✅ | TRACEABILITY.md |
| AC-004 | FR-004 | 远程查询返回结构化 evidence manifest / TC-004: go test -run 'Test(ClientFetchManifest\|ManifestHandler)' | ✅ | TRACEABILITY.md |
| AC-005 | FR-005 / BR-004 | evidence 报告可渲染；存储不可变追加 / TC-005: go test -run 'Test(ReportsRenderValidatedManifest\|StoreAppendEnforcesHashChain)' | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001 | go test -run 'Test(ParseGoCoverageProfile\|CoverageValidateRejectsThresholdAndPercentTamper\|NewCoverageNormalizesTime)' — 覆盖率解析、80% 边界和时间归一化 | ✅ | TRACEABILITY.md |
| TC-002 | FR-002, BR-001 | go test -run TestNewManifestNormalizesSortsAndValidates — 全部门禁通过→manifest 生成且 hash 有效 | ✅ | TRACEABILITY.md |
| TC-003 | FR-003, BR-003 | go test -run TestManifestValidateRejectsFailedGateLowCoverageAndTamper — 合法 manifest 通过；篡改 manifest 拒绝 | ✅ | TRACEABILITY.md |
| TC-004 | FR-004 | go test -run 'Test(ClientFetchManifest\|ManifestHandler)' — HTTP endpoint 返回 JSON 证据 | ✅ | TRACEABILITY.md |
| TC-005 | FR-005, BR-004 | go test -run 'Test(ReportsRenderValidatedManifest\|StoreAppendEnforcesHashChain)' — 报告渲染且 evidence 追加不可变 | ✅ | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | collect-coverage: 模块执行 go test -cover→覆盖率报告被收集并结构化存储 | AC-001 / TC-001 / go test -run 'Test(ParseGoCoverageProfile\|CoverageValidateRejectsThresholdAndPercentTamper\|NewCoverageNormalizesTime)' | ✅ | TRACEABILITY.md |
| FR-002 | generate-manifest: 模块通过所有门禁→生成 Release Manifest(version/commit/gates/coverage/hash) | AC-002 / TC-002 / go test -run TestNewManifestNormalizesSortsAndValidates | ✅ | TRACEABILITY.md |
| FR-003 | validate-manifest: CI 检查 manifest→验证完整性、hash 与内容一致性 | AC-003 / TC-003 / go test -run TestManifestValidateRejectsFailedGateLowCoverageAndTamper | ✅ | TRACEABILITY.md |
| FR-004 | remote-evidence: 远程查询模块证据→返回结构化 manifest JSON | AC-004 / TC-004 / go test -run 'Test(ClientFetchManifest\|ManifestHandler)' | ✅ | TRACEABILITY.md |
| FR-005 | evidence-report: 聚合多模块证据→生成跨模块统一报告 | AC-005 / TC-005 / go test -run 'Test(ReportsRenderValidatedManifest\|StoreAppendEnforcesHashChain)' | ✅ | TRACEABILITY.md |
| BR-001 | manifest必须包含门禁全绿证据 | TC-002 / TestNewManifestNormalizesSortsAndValidates | ✅ | TRACEABILITY.md |
| BR-002 | 覆盖率低于80%不得发布 | TC-001 / 覆盖率边界测试(79.99%拒绝, 80.00%通过) | ✅ | TRACEABILITY.md |
| BR-003 | manifest不可事后篡改(hash链校验) | TC-003 / TestManifestValidateRejectsFailedGateLowCoverageAndTamper | ✅ | TRACEABILITY.md |
| BR-004 | evidence存储必须不可变追加 | TC-005 / TestStoreAppendEnforcesHashChain | ✅ | TRACEABILITY.md |
| NFR-001 | Performance | manifest生成延迟 < 1s / benchmark: go test -bench=BenchmarkManifestGen -run '^$' | ✅ | TRACEABILITY.md |
| NFR-002 | Performance | 20模块证据聚合 < 5s / benchmark: go test -bench=BenchmarkMultiModuleAggregate -run '^$' | ✅ | TRACEABILITY.md |
| NFR-003 | Security | manifest hash完整性校验(防篡改) / TC-003: 篡改检测 | ✅ | TRACEABILITY.md |
| NFR-004 | Security | 不读取密钥/不连接远程服务(remote optional) / rg -n "os\\.Getenv\|TOKEN\|SECRET\|PASSWORD\|Redis\|Postgres\|postgres\|redis" --glob '*.go' . 无匹配 | ✅ | TRACEABILITY.md |
| NFR-005 | Dependency | 禁止依赖存储/网络后端(observex/configx/resiliencx/schedulex/Redis/Postgres) / go list -deps ./... 与 go list -m all | ✅ | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [x] 运行时代码仓库 /home/xlib-evidence 通过 go test、go test -race、go vet 与覆盖率门槛。
- [x] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] v0.1.0 tag/release 待 runtime 源码提交后重建，当前未作为已发布证据。

## 6. 当前验收证据

- 2026-06-18 本地验收已执行：go test ./...、go test ./... -race -count=1、go vet ./... 全部通过。
- 覆盖率 total 89.8% >= 80.0%；BenchmarkManifestGen 8845 ns/op，BenchmarkMultiModuleAggregate 209324 ns/op。
- go list -m all 仅返回 github.com/ZoneCNH/xlib-evidence；禁止依赖扫描与凭证/外部服务关键字扫描无匹配。
- README 与 CI workflow 已对齐本地验收口径；release workflow 与 v0.1.0 tag/release 待 runtime 源码提交后重建。
