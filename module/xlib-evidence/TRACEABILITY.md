# xlib-evidence TRACEABILITY

## §1 FR Traceability

| FR ID | Requirement | AC ID(s) | TC ID(s) | Verification | Status |
|-------|-------------|----------|----------|-------------|--------|
| FR-001 | collect-coverage: 模块执行`go test -cover`→覆盖率报告被收集并结构化存储 | AC-001 | TC-001 | `go test -run TestCollectCoverage` | ✅ |
| FR-002 | generate-manifest: 模块通过所有门禁→生成Release Manifest(version/commitSHA/gates/coverage) | AC-002 | TC-002 | `go test -run TestGenerateManifest` | ✅ |
| FR-003 | validate-manifest: CI检查manifest→验证完整性/签名/内容一致性 | AC-003 | TC-003 | `go test -run TestValidateManifest` | ✅ |
| FR-004 | remote-evidence: 远程查询模块证据→返回结构化证据(覆盖率/门禁历史/manifest) | AC-004 | TC-004 | `go test -run TestRemoteEvidence` | ✅ |
| FR-005 | evidence-report: 聚合多模块证据→生成跨模块统一报告 | AC-005 | TC-005 | `go test -run TestEvidenceReport` | ✅ |

## §2 BR Traceability

| BR ID | Rule | TC ID(s) | Verification | Status |
|-------|------|----------|--------------|--------|
| BR-001 | manifest必须包含门禁全绿证据 | TC-002 | 生成manifest前校验门禁结果; gate-results fixture全绿→manifest生成 | ✅ |
| BR-002 | 覆盖率低于80%不得发布 | TC-001 | 覆盖率边界测试(79.99%拒绝, 80.00%通过) | ✅ |
| BR-003 | manifest不可事后篡改(hash链校验) | TC-003 | hash校验golden; 合法manifest通过/篡改manifest拒绝 | ✅ |
| BR-004 | evidence存储必须不可变追加 | TC-005 | append-only存储验证; 已写入evidence不可覆盖 | ✅ |

## §3 NFR Traceability

| NFR ID | Category | Requirement | Verification | Status |
|--------|----------|-------------|-------------|--------|
| NFR-001 | Performance | manifest生成延迟 < 1s | benchmark: `go test -bench=BenchmarkManifestGen` | ✅ |
| NFR-002 | Performance | 20模块证据聚合 < 5s | benchmark: `go test -bench=BenchmarkMultiModuleAggregate` | ✅ |
| NFR-003 | Security | manifest hash完整性校验(防篡改) | TC-003: 篡改检测 | ✅ |
| NFR-004 | Security | 不读取密钥/不连接远程服务(remote optional) | code audit: grep for credential/env access | ✅ |
| NFR-005 | Dependency | 禁止依赖存储/网络后端(observex/configx/resiliencx/schedulex/Redis/Postgres) | `go mod graph` audit | ✅ |

## §4 TC→FR Reverse Traceability

| TC ID | Covers FR(s) | Command |
|-------|-------------|---------|
| TC-001 | FR-001 | `go test -run TestCollectCoverage` — mock覆盖率输出→CoverageReport正确 |
| TC-002 | FR-002, BR-001 | `go test -run TestGenerateManifest` — 全部门禁通过→manifest生成且hash有效 |
| TC-003 | FR-003, BR-003 | `go test -run TestValidateManifest` — 合法manifest通过; 篡改manifest拒绝 |
| TC-004 | FR-004 | `go test -run TestRemoteEvidence` — HTTP endpoint返回JSON证据 |
| TC-005 | FR-005, BR-004 | `go test -run TestEvidenceReport` — 3模块输入→统合报告列出全部状态 |

## §5 AC Registry

| AC ID | FR/BR Ref | Criterion | Verification | Status |
|-------|-----------|-----------|-------------|--------|
| AC-001 | FR-001 / BR-002 | 覆盖率数据被结构化收集; 覆盖率<80%拒绝发布 | TC-001: CoverageReport正确, 边界值测试 | ✅ |
| AC-002 | FR-002 / BR-001 | 门禁全绿时生成manifest,含version/commitSHA/gates/coverage | TC-002: manifest生成且hash有效 | ✅ |
| AC-003 | FR-003 / BR-003 | manifest hash校验通过; 篡改检测失败 | TC-003: 合法通过/篡改拒绝 | ✅ |
| AC-004 | FR-004 | 远程查询返回结构化证据(覆盖率/门禁历史/manifest) | TC-004: HTTP JSON证据返回 | ✅ |
| AC-005 | FR-005 / BR-004 | 多模块聚合报告含全部模块状态; evidence不可变追加 | TC-005: 统合报告列出全部状态 | ✅ |
