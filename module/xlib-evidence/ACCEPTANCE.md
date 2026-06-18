# xlib-evidence 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.1.0
- Module-State: 已发布
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
| AC-001 | FR-001 / BR-002 | 覆盖率数据被结构化收集; 覆盖率<80%拒绝发布 / TC-001: CoverageReport正确, 边界值测试 | ✅ | TRACEABILITY.md |
| AC-002 | FR-002 / BR-001 | 门禁全绿时生成manifest,含version/commitSHA/gates/coverage / TC-002: manifest生成且hash有效 | ✅ | TRACEABILITY.md |
| AC-003 | FR-003 / BR-003 | manifest hash校验通过; 篡改检测失败 / TC-003: 合法通过/篡改拒绝 | ✅ | TRACEABILITY.md |
| AC-004 | FR-004 | 远程查询返回结构化证据(覆盖率/门禁历史/manifest) / TC-004: HTTP JSON证据返回 | ✅ | TRACEABILITY.md |
| AC-005 | FR-005 / BR-004 | 多模块聚合报告含全部模块状态; evidence不可变追加 / TC-005: 统合报告列出全部状态 | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001 | go test -run TestCollectCoverage — mock覆盖率输出→CoverageReport正确 | - | TRACEABILITY.md |
| TC-002 | FR-002, BR-001 | go test -run TestGenerateManifest — 全部门禁通过→manifest生成且hash有效 | - | TRACEABILITY.md |
| TC-003 | FR-003, BR-003 | go test -run TestValidateManifest — 合法manifest通过; 篡改manifest拒绝 | - | TRACEABILITY.md |
| TC-004 | FR-004 | go test -run TestRemoteEvidence — HTTP endpoint返回JSON证据 | - | TRACEABILITY.md |
| TC-005 | FR-005, BR-004 | go test -run TestEvidenceReport — 3模块输入→统合报告列出全部状态 | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | collect-coverage: 模块执行go test -cover→覆盖率报告被收集并结构化存储 | AC-001 / TC-001 / go test -run TestCollectCoverage | ✅ | TRACEABILITY.md |
| FR-002 | generate-manifest: 模块通过所有门禁→生成Release Manifest(version/commitSHA/gates/coverage) | AC-002 / TC-002 / go test -run TestGenerateManifest | ✅ | TRACEABILITY.md |
| FR-003 | validate-manifest: CI检查manifest→验证完整性/签名/内容一致性 | AC-003 / TC-003 / go test -run TestValidateManifest | ✅ | TRACEABILITY.md |
| FR-004 | remote-evidence: 远程查询模块证据→返回结构化证据(覆盖率/门禁历史/manifest) | AC-004 / TC-004 / go test -run TestRemoteEvidence | ✅ | TRACEABILITY.md |
| FR-005 | evidence-report: 聚合多模块证据→生成跨模块统一报告 | AC-005 / TC-005 / go test -run TestEvidenceReport | ✅ | TRACEABILITY.md |
| BR-001 | manifest必须包含门禁全绿证据 | TC-002 / 生成manifest前校验门禁结果; gate-results fixture全绿→manifest生成 | ✅ | TRACEABILITY.md |
| BR-002 | 覆盖率低于80%不得发布 | TC-001 / 覆盖率边界测试(79.99%拒绝, 80.00%通过) | ✅ | TRACEABILITY.md |
| BR-003 | manifest不可事后篡改(hash链校验) | TC-003 / hash校验golden; 合法manifest通过/篡改manifest拒绝 | ✅ | TRACEABILITY.md |
| BR-004 | evidence存储必须不可变追加 | TC-005 / append-only存储验证; 已写入evidence不可覆盖 | ✅ | TRACEABILITY.md |
| NFR-001 | Performance | manifest生成延迟 < 1s / benchmark: go test -bench=BenchmarkManifestGen | ✅ | TRACEABILITY.md |
| NFR-002 | Performance | 20模块证据聚合 < 5s / benchmark: go test -bench=BenchmarkMultiModuleAggregate | ✅ | TRACEABILITY.md |
| NFR-003 | Security | manifest hash完整性校验(防篡改) / TC-003: 篡改检测 | ✅ | TRACEABILITY.md |
| NFR-004 | Security | 不读取密钥/不连接远程服务(remote optional) / code audit: grep for credential/env access | ✅ | TRACEABILITY.md |
| NFR-005 | Dependency | 禁止依赖存储/网络后端(observex/configx/resiliencx/schedulex/Redis/Postgres) / go mod graph audit | ✅ | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/xlib-evidence 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- SPEC/TRACEABILITY 已登记 AC/TC 主链路；当前主要缺口是 /home/xlib-evidence 最新测试、race/vet、覆盖率与 evidence schema/release 证据需要归档。
