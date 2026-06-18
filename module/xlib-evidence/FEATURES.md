# xlib-evidence 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.1.0
- Module-State: 已发布
- Layer: L1 证据
- Runtime-Repo: /home/xlib-evidence
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 xlib-evidence 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | 验收证据、覆盖率、产物与审计记录的结构化归档 |
| 文档目录 | module/xlib-evidence |
| 运行时代码目录 | /home/xlib-evidence |
| Go 基线 | 1.23 |
| 允许依赖 | 无 |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | collect-coverage: 模块执行go test -cover→覆盖率报告被收集并结构化存储 | AC-001 / TC-001 / go test -run TestCollectCoverage | ✅ | TRACEABILITY.md |
| FR-002 | generate-manifest: 模块通过所有门禁→生成Release Manifest(version/commitSHA/gates/coverage) | AC-002 / TC-002 / go test -run TestGenerateManifest | ✅ | TRACEABILITY.md |
| FR-003 | validate-manifest: CI检查manifest→验证完整性/签名/内容一致性 | AC-003 / TC-003 / go test -run TestValidateManifest | ✅ | TRACEABILITY.md |
| FR-004 | remote-evidence: 远程查询模块证据→返回结构化证据(覆盖率/门禁历史/manifest) | AC-004 / TC-004 / go test -run TestRemoteEvidence | ✅ | TRACEABILITY.md |
| FR-005 | evidence-report: 聚合多模块证据→生成跨模块统一报告 | AC-005 / TC-005 / go test -run TestEvidenceReport | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | manifest必须包含门禁全绿证据 | TC-002 / 生成manifest前校验门禁结果; gate-results fixture全绿→manifest生成 | ✅ | TRACEABILITY.md |
| BR-002 | 覆盖率低于80%不得发布 | TC-001 / 覆盖率边界测试(79.99%拒绝, 80.00%通过) | ✅ | TRACEABILITY.md |
| BR-003 | manifest不可事后篡改(hash链校验) | TC-003 / hash校验golden; 合法manifest通过/篡改manifest拒绝 | ✅ | TRACEABILITY.md |
| BR-004 | evidence存储必须不可变追加 | TC-005 / append-only存储验证; 已写入evidence不可覆盖 | ✅ | TRACEABILITY.md |
| NFR-001 | Performance | manifest生成延迟 < 1s / benchmark: go test -bench=BenchmarkManifestGen | ✅ | TRACEABILITY.md |
| NFR-002 | Performance | 20模块证据聚合 < 5s / benchmark: go test -bench=BenchmarkMultiModuleAggregate | ✅ | TRACEABILITY.md |
| NFR-003 | Security | manifest hash完整性校验(防篡改) / TC-003: 篡改检测 | ✅ | TRACEABILITY.md |
| NFR-004 | Security | 不读取密钥/不连接远程服务(remote optional) / code audit: grep for credential/env access | ✅ | TRACEABILITY.md |
| NFR-005 | Dependency | 禁止依赖存储/网络后端(observex/configx/resiliencx/schedulex/Redis/Postgres) / go mod graph audit | ✅ | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-EVIDENCE-001 | 实现覆盖率收集 | FR-001 / AC-001 | - | IMPLEMENTATION-PLAN.md |
| TASK-EVIDENCE-002 | 实现 Release Manifest 生成 | FR-002 / AC-002 | - | IMPLEMENTATION-PLAN.md |
| TASK-EVIDENCE-003 | 实现 Manifest 验证 | FR-003 / AC-003 | - | IMPLEMENTATION-PLAN.md |
| TASK-EVIDENCE-004 | 实现远程证据查询 | FR-004 / AC-004 | - | IMPLEMENTATION-PLAN.md |
| TASK-EVIDENCE-005 | 实现多模块统一报告 | FR-005 / AC-005 | - | IMPLEMENTATION-PLAN.md |
| TASK-XLIBEVIDENCE-001 | TASK-XLIBEVIDENCE-001: FR-001 | module/xlib-evidence/tasks/TASK-XLIBEVIDENCE-001.md | - | tasks/TASK-XLIBEVIDENCE-001.md |
| TASK-XLIBEVIDENCE-002 | TASK-XLIBEVIDENCE-002: FR-002 | module/xlib-evidence/tasks/TASK-XLIBEVIDENCE-002.md | - | tasks/TASK-XLIBEVIDENCE-002.md |
| TASK-XLIBEVIDENCE-003 | TASK-XLIBEVIDENCE-003: FR-004 | module/xlib-evidence/tasks/TASK-XLIBEVIDENCE-003.md | - | tasks/TASK-XLIBEVIDENCE-003.md |
| TASK-XLIBEVIDENCE-003B | TASK-XLIBEVIDENCE-003b: FR-003 | module/xlib-evidence/tasks/TASK-XLIBEVIDENCE-003b.md | - | tasks/TASK-XLIBEVIDENCE-003b.md |
| TASK-XLIBEVIDENCE-004 | TASK-XLIBEVIDENCE-004: FR-005 | module/xlib-evidence/tasks/TASK-XLIBEVIDENCE-004.md | - | tasks/TASK-XLIBEVIDENCE-004.md |
| TASK-XLIBEVIDENCE-005 | TASK-XLIBEVIDENCE-005: FR-001 | module/xlib-evidence/tasks/TASK-XLIBEVIDENCE-005.md | - | tasks/TASK-XLIBEVIDENCE-005.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/xlib-evidence/goal.md |
| SPEC.md | 存在 | module/xlib-evidence/SPEC.md |
| TRACEABILITY.md | 存在 | module/xlib-evidence/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/xlib-evidence/IMPLEMENTATION-PLAN.md |
| tasks/ | 6 个 Markdown 文件 | module/xlib-evidence/tasks |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/xlib-evidence 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
