# ossx 追溯矩阵

- Last-Updated: 2026-06-30
- Source: [module/ossx/SPEC.md](./SPEC.md) v1.2.1
- Scope: FR/BR -> AC -> TC -> Task -> Evidence -> Status closure for v1.2.1 local production candidate

本矩阵记录 `ossx` v1.2.1 的需求、验收标准、测试和证据闭环。当前所有本地实现与本地验证项已闭合；完整生产放行仍被外部 CI/CD、下游接入、soak 和四源评分证据阻塞。

## §1 FR 功能需求追溯

| FR | Requirement | AC | TC | Task | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| FR-001 | 构造 Aliyun OSS store | AC-OSS-001 | TC-001 | TASK-OSSX-001 | config and constructor tests | Complete Locally |
| FR-002 | Put/Get/Head/Delete | AC-OSS-002 | TC-002 | TASK-OSSX-003 | store unit tests; live integration | Complete Locally |
| FR-003 | List objects | AC-OSS-003 | TC-003 | TASK-OSSX-003 | list behavior tests | Complete Locally |
| FR-004 | Multipart lifecycle | AC-OSS-004 | TC-004 | TASK-OSSX-003 | multipart tests | Complete Locally |
| FR-005 | Presigned GET/PUT | AC-OSS-005 | TC-005 | TASK-OSSX-003 | presign tests; host-only integration assertion | Complete Locally |
| FR-006 | Strict delete | AC-OSS-006 | TC-006 | TASK-OSSX-003 | strict delete unit and live integration tests | Complete Locally |
| FR-007 | Error classification | AC-OSS-007 | TC-007 | TASK-OSSX-005 | invalid config, not found, closed store tests | Complete Locally |
| FR-008 | API / SPI governance | AC-OSS-008 | TC-009 | TASK-OSSX-001 | interface-count and capability tests | Complete Locally |
| FR-009 | Observability sanitization | AC-OSS-009 | TC-008 | TASK-OSSX-004 | sanitization tests; secret scope gate | Complete Locally |
| FR-010 | dev.md live integration | AC-OSS-010 | TC-010 | TASK-OSSX-004 | integration command with values withheld | Complete Locally |

## §2 BR 业务规则追溯

| BR | Requirement | Task | Evidence | Status |
| --- | --- | --- | --- | --- |
| BR-001 | Missing config fails fast | TASK-OSSX-002 | config tests | Complete Locally |
| BR-002 | No secret values in output | TASK-OSSX-004 | secret-scope check; integration output review | Complete Locally |
| BR-003 | Closed store returns stable errors | TASK-OSSX-005 | close tests; race tests | Complete Locally |
| BR-004 | Strict delete performs Head before Delete | TASK-OSSX-003 | strict delete tests | Complete Locally |
| BR-005 | Non-strict delete remains idempotent | TASK-OSSX-003 | delete behavior tests | Complete Locally |
| BR-006 | Multipart failures are observable | TASK-OSSX-003 | multipart error tests | Complete Locally |
| BR-007 | Presign exposed only as capability | TASK-OSSX-001 | API governance tests | Complete Locally |
| BR-008 | Health/Close use lifecycle capability | TASK-OSSX-001 | lifecycle tests | Complete Locally |
| BR-009 | Close is race-safe | TASK-OSSX-005 | `go test -race ./...` | Complete Locally |
| BR-010 | Integration tests are opt-in | TASK-OSSX-004 | integration skip tests / tag behavior | Complete Locally |
| BR-011 | dev.md is the only local secret source | TASK-OSSX-004 | script and docs alignment | Complete Locally |
| BR-012 | Release manifest stays honest | TASK-OSSX-006 | `release/manifest/latest.json` | Complete Locally |

## §3 NFR 非功能需求追溯

| NFR | Requirement | Task | Evidence | Status |
| --- | --- | --- | --- | --- |
| NFR-001 | Release-tag CI | TASK-OSSX-006 | `v1.2.1` tag CI artifact | Blocked External |
| NFR-002 | Secret scanning / xlibgate | TASK-OSSX-004 | release CI Gitleaks and xlibgate artifacts | Blocked External |
| NFR-003 | Interface governance | TASK-OSSX-001 | governance tests | Complete Locally |
| NFR-004 | Live Aliyun integration | TASK-OSSX-004 | local `dev.md` integration pass; CI artifact pending | Complete Locally / External Artifact Pending |
| NFR-005 | Downstream adoption | TASK-OSSX-006 | downstream module evidence | Blocked External |
| NFR-006 | Production soak | TASK-OSSX-006 | production-equivalent soak report | Blocked External |
| NFR-007 | Four-source scorer / arbiter | TASK-OSSX-006 | claude/codex/copilot/rules + arbiter pass | Blocked External |

## §4 TC -> FR 反向追溯

| TC | Command / Test | Covers | Status |
| --- | --- | --- | --- |
| TC-001 | Config and constructor tests | FR-001, BR-001 | Pass Locally |
| TC-002 | Store object operation tests | FR-002 | Pass Locally |
| TC-003 | List tests | FR-003 | Pass Locally |
| TC-004 | Multipart tests | FR-004, BR-006 | Pass Locally |
| TC-005 | Presign tests | FR-005, BR-007 | Pass Locally |
| TC-006 | Strict delete tests | FR-006, BR-004, BR-005 | Pass Locally |
| TC-007 | Error-path tests | FR-007 | Pass Locally |
| TC-008 | Sanitization tests | FR-009, BR-002 | Pass Locally |
| TC-009 | API governance tests | FR-008 | Pass Locally |
| TC-010 | `OSSX_LIVE_INTEGRATION=1 GOWORK=off go test -tags integration ./adapters/aliyun -count=1 -timeout 180s` | FR-010 | Pass Locally |
| TC-011 | `GOWORK=off go test ./pkg/ossx -count=1 -covermode=atomic -coverprofile=/tmp/ossx-pkg.cover` | Local coverage | Pass Locally, 100.0% |
| TC-012 | race/vet/build/lint | Static and race gates | Pass Locally |
| TC-013 | `./scripts/secret-scope-check.sh` | Secret boundary | Pass Locally |

## §5 全局 AC 注册表

| AC | Description | FR | TC | Task | Status |
| --- | --- | --- | --- | --- | --- |
| AC-OSS-001 | Construct store from validated config | FR-001 | TC-001 | TASK-OSSX-001 | Complete Locally |
| AC-OSS-002 | Execute core object operations | FR-002 | TC-002 | TASK-OSSX-003 | Complete Locally |
| AC-OSS-003 | List by prefix and page | FR-003 | TC-003 | TASK-OSSX-003 | Complete Locally |
| AC-OSS-004 | Complete multipart lifecycle | FR-004 | TC-004 | TASK-OSSX-003 | Complete Locally |
| AC-OSS-005 | Generate presigned GET/PUT | FR-005 | TC-005 | TASK-OSSX-003 | Complete Locally |
| AC-OSS-006 | Enforce strict delete missing-object behavior | FR-006 | TC-006 | TASK-OSSX-003 | Complete Locally |
| AC-OSS-007 | Return classifiable errors | FR-007 | TC-007 | TASK-OSSX-005 | Complete Locally |
| AC-OSS-008 | Keep public interface bounded | FR-008 | TC-009 | TASK-OSSX-001 | Complete Locally |
| AC-OSS-009 | Sanitize observability output | FR-009 | TC-008 | TASK-OSSX-004 | Complete Locally |
| AC-OSS-010 | Run live Aliyun integration from dev.md | FR-010 | TC-010 | TASK-OSSX-004 | Complete Locally |

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 10 | 10 | 100% |
| BR (业务规则) | 12 | 12 | 100% |


| NFR (非功能需求) | 7 | 3 | 42.9% |
| AC (验收标准) | 10 | 10 | 100% |
| TC (测试用例) | 13 | 13 | 100% |
| **合计** | **52** | **48** | **92.3%** |

> 说明：NFR-001/002/005/006/007 标记为 Blocked External，未计入 Done。NFR-003 Complete Locally、NFR-004 Complete Locally / External Artifact Pending 计入 Done。Task 总数 = TASK-OSSX-000~006 共 7 项（含 TASK-OSSX-000 Repo identity audit）。

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线对齐：§1 FR 表新增 Task 列（TASK-OSSX-001~005）；§2 BR 表新增 Task 列（TASK-OSSX-001~006）；§3 NFR 表新增 Task 列；AC 注册表新增 Task 列；新增 §6 覆盖率仪表盘；新增 §7 变更历史；更新 Last-Updated |
| 2026-06-19 | v3.4 — Aligned v1.2.1 local production candidate evidence and external blockers |
| 2026-06-19 | v3.3 — Added dev.md live integration and API governance closure |
| 2026-06-18 | v3.2 — Baseline production-readiness traceability |

## Task Matrix

| Task | Scope | Evidence | Status |
| --- | --- | --- | --- |
| TASK-OSSX-000 | Repo and module identity audit | docs and manifest alignment | Complete Locally |
| TASK-OSSX-001 | Public API surface reduction | interface governance tests | Complete Locally |
| TASK-OSSX-002 | Adapter capability split | constructor and SPI tests | Complete Locally |
| TASK-OSSX-003 | Strict delete and Aliyun lifecycle | unit + live integration + race | Complete Locally |
| TASK-OSSX-004 | Secret scope and integration env policy | `secret-scope-check.sh` | Complete Locally |
| TASK-OSSX-005 | 100% `pkg/ossx` coverage | cover profile | Complete Locally |
| TASK-OSSX-006 | Release manifest/docs update | `local-production-candidate` manifest | Complete Locally |

## Remaining Work

- Tag and push v1.2.1, then archive release-tag CI.
- Archive Gitleaks and xlibgate output from release CI.
- Run live Aliyun integration in controlled CI and archive pass/fail summary without secrets.
- Integrate one downstream module and record adoption evidence.
- Run production-equivalent soak and record SLO data.
- Run four-source scorer and arbiter, then update this matrix from local candidate to production release only if all gates pass.
