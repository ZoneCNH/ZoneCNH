# xlib_evidence 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-20
- Module-Version: v0.2.4
- Module-State: v0.2.4 已发布；runtime 本地 100.0% 覆盖率、并发 Store 防护、仓库身份契约、CI/CD workflow 已部署，GitHub Release v0.2.4 与 release evidence assets 已闭合
- Layer: L1 证据
- Runtime-Repo: /home/xlib_evidence
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 xlib_evidence 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | 验收证据、覆盖率、产物与审计记录的结构化归档 |
| 文档目录 | module/xlib_evidence |
| 运行时代码目录 | /home/xlib_evidence |
| Go 基线 | 1.23 |
| 允许依赖 | 无 |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | collect-coverage: 模块执行go test -cover→覆盖率报告被收集并结构化存储 | AC-001 / TC-001 / `go test -run 'Test(ParseGoCoverageProfile|CoverageValidateRejectsThresholdAndPercentTamper|NewCoverageNormalizesTime)'` | ✅ | TRACEABILITY.md |
| FR-002 | generate-manifest: 模块通过所有门禁→生成Release Manifest(version/commitSHA/gates/coverage) | AC-002 / TC-002 / `go test -run TestNewManifestNormalizesSortsAndValidates` | ✅ | TRACEABILITY.md |
| FR-003 | validate-manifest: CI检查manifest→验证完整性/签名/内容一致性 | AC-003 / TC-003 / `go test -run TestManifestValidateRejectsFailedGateLowCoverageAndTamper` | ✅ | TRACEABILITY.md |
| FR-004 | remote-evidence: 远程查询模块证据→返回结构化证据(覆盖率/门禁历史/manifest) | AC-004 / TC-004 / `go test -run 'Test(ClientFetchManifest|ManifestHandler)'` | ✅ | TRACEABILITY.md |
| FR-005 | report: 聚合多模块证据→生成跨模块统一报告，并提供并发安全、追加不可变的证据 Store | AC-005 / TC-005 / `go test -run 'Test(ReportsRenderValidatedManifest|StoreAppendEnforcesHashChain|StoreAppendStoresImmutableManifest|StoreSupportsConcurrentAppendAndReads)'` | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | manifest必须包含门禁全绿证据 | TC-002 / `TestNewManifestNormalizesSortsAndValidates` | ✅ | TRACEABILITY.md |
| BR-002 | 覆盖率低于100.0%不得发布 | TC-001 / 覆盖率边界测试(99.99%拒绝, 100.00%通过) | ✅ | TRACEABILITY.md |
| BR-003 | manifest不可事后篡改(hash链校验) | TC-003 / `TestManifestValidateRejectsFailedGateLowCoverageAndTamper` | ✅ | TRACEABILITY.md |
| BR-004 | evidence存储必须不可变追加，并在并发读写时保持一致快照 | TC-005 / `Test(StoreAppendEnforcesHashChain|StoreAppendStoresImmutableManifest|StoreSupportsConcurrentAppendAndReads)` | ✅ | TRACEABILITY.md |
| NFR-001 | Performance | manifest生成延迟 < 1s / benchmark: `go test -bench=BenchmarkManifestGen -run '^$'` | ✅ | TRACEABILITY.md |
| NFR-002 | Performance | 20模块证据聚合 < 5s / benchmark: `go test -bench=BenchmarkMultiModuleAggregate -run '^$'` | ✅ | TRACEABILITY.md |
| NFR-003 | Security | manifest hash完整性校验(防篡改) / TC-003: 篡改检测 | ✅ | TRACEABILITY.md |
| NFR-004 | Security | 不读取密钥/不连接远程服务(remote optional) / `rg -n "os\\.Getenv|TOKEN|SECRET|PASSWORD|Redis|Postgres|postgres|redis" --glob '*.go' .` 无匹配 | ✅ | TRACEABILITY.md |
| NFR-005 | Dependency | 禁止依赖存储/网络后端(observex/configx/resiliencx/schedulex/Redis/Postgres) / `go list -deps ./...` 与 `go list -m all` | ✅ | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-EVIDENCE-001 | 实现覆盖率收集 | `coverage.go` / `coverage_test.go` | ✅ | IMPLEMENTATION-PLAN.md |
| TASK-EVIDENCE-002 | 实现 Release Manifest 生成 | `manifest.go` / `manifest_test.go` | ✅ | IMPLEMENTATION-PLAN.md |
| TASK-EVIDENCE-003 | 实现 Manifest 验证 | `manifest.go` / `manifest_test.go` | ✅ | IMPLEMENTATION-PLAN.md |
| TASK-EVIDENCE-004 | 实现远程证据查询 | `remote.go` / `remote_test.go` | ✅ | IMPLEMENTATION-PLAN.md |
| TASK-EVIDENCE-005 | 实现多模块统一报告 | `report.go` / `report_test.go` | ✅ | IMPLEMENTATION-PLAN.md |
| TASK-XLIBEVIDENCE-001 | TASK-XLIBEVIDENCE-001: FR-001 | `coverage.go` / `coverage_test.go` | ✅ | tasks/TASK-XLIBEVIDENCE-001.md |
| TASK-XLIBEVIDENCE-002 | TASK-XLIBEVIDENCE-002: FR-002 | `manifest.go` / `manifest_test.go` | ✅ | tasks/TASK-XLIBEVIDENCE-002.md |
| TASK-XLIBEVIDENCE-003 | TASK-XLIBEVIDENCE-003: FR-004 | `remote.go` / `remote_test.go` | ✅ | tasks/TASK-XLIBEVIDENCE-003.md |
| TASK-XLIBEVIDENCE-003B | TASK-XLIBEVIDENCE-003b: FR-003 | `manifest.go` / `manifest_test.go` | ✅ | tasks/TASK-XLIBEVIDENCE-003b.md |
| TASK-XLIBEVIDENCE-004 | TASK-XLIBEVIDENCE-004: FR-005 | `report.go` / `report_test.go` | ✅ | tasks/TASK-XLIBEVIDENCE-004.md |
| TASK-XLIBEVIDENCE-005 | TASK-XLIBEVIDENCE-005: FR-001 | `.github/workflows/ci.yml` / `.github/workflows/release.yml` / `FEATURES.md` / `ACCEPTANCE.md` | ✅ | tasks/TASK-XLIBEVIDENCE-005.md |
| TASK-XLIBEVIDENCE-006 | 仓库身份契约与 Trust Alignment 可执行性修复 | `.repo-contract.yaml` / `.github/workflows/ci.yml` / `.github/workflows/release.yml` | ✅ | runtime v0.2.4 release |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/xlib_evidence/goal.md |
| SPEC.md | 存在 | module/xlib_evidence/SPEC.md |
| TRACEABILITY.md | 存在 | module/xlib_evidence/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/xlib_evidence/IMPLEMENTATION-PLAN.md |
| tasks/ | 6 个 Markdown 文件 | module/xlib_evidence/tasks |

## 6. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [x] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [x] 运行时代码仓库 /home/xlib_evidence 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [x] v0.2.4 本地生产验收已通过并发布到 GitHub Release；runtime 发布包包含根级 `FEATURES.md`、`ACCEPTANCE.md`、`.repo-contract.yaml`、CI docs contract、Trust Alignment 与 release evidence assets。
