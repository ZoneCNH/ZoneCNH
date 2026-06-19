# ossx 追溯矩阵

- Last-Updated: 2026-06-19
- Source: [module/ossx/SPEC.md](./SPEC.md) v1.2.1
- Scope: FR/BR -> AC -> TC -> Task -> Evidence -> Status closure for v1.2.1 local production candidate

本矩阵记录 `ossx` v1.2.1 的需求、验收标准、测试和证据闭环。当前所有本地实现与本地验证项已闭合；完整生产放行仍被外部 CI/CD、下游接入、soak 和四源评分证据阻塞。

## 1. FR Matrix

| FR | Requirement | AC | TC | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | 构造 Aliyun OSS store | AC-OSS-001 | TC-001 | config and constructor tests | Complete Locally |
| FR-002 | Put/Get/Head/Delete | AC-OSS-002 | TC-002 | store unit tests; live integration | Complete Locally |
| FR-003 | List objects | AC-OSS-003 | TC-003 | list behavior tests | Complete Locally |
| FR-004 | Multipart lifecycle | AC-OSS-004 | TC-004 | multipart tests | Complete Locally |
| FR-005 | Presigned GET/PUT | AC-OSS-005 | TC-005 | presign tests; host-only integration assertion | Complete Locally |
| FR-006 | Strict delete | AC-OSS-006 | TC-006 | strict delete unit and live integration tests | Complete Locally |
| FR-007 | Error classification | AC-OSS-007 | TC-007 | invalid config, not found, closed store tests | Complete Locally |
| FR-008 | API / SPI governance | AC-OSS-008 | TC-009 | interface-count and capability tests | Complete Locally |
| FR-009 | Observability sanitization | AC-OSS-009 | TC-008 | sanitization tests; secret scope gate | Complete Locally |
| FR-010 | dev.md live integration | AC-OSS-010 | TC-010 | integration command with values withheld | Complete Locally |

## 2. BR Matrix

| BR | Requirement | Evidence | Status |
| --- | --- | --- | --- |
| BR-001 | Missing config fails fast | config tests | Complete Locally |
| BR-002 | No secret values in output | secret-scope check; integration output review | Complete Locally |
| BR-003 | Closed store returns stable errors | close tests; race tests | Complete Locally |
| BR-004 | Strict delete performs Head before Delete | strict delete tests | Complete Locally |
| BR-005 | Non-strict delete remains idempotent | delete behavior tests | Complete Locally |
| BR-006 | Multipart failures are observable | multipart error tests | Complete Locally |
| BR-007 | Presign exposed only as capability | API governance tests | Complete Locally |
| BR-008 | Health/Close use lifecycle capability | lifecycle tests | Complete Locally |
| BR-009 | Close is race-safe | `go test -race ./...` | Complete Locally |
| BR-010 | Integration tests are opt-in | integration skip tests / tag behavior | Complete Locally |
| BR-011 | dev.md is the only local secret source | script and docs alignment | Complete Locally |
| BR-012 | Release manifest stays honest | `release/manifest/latest.json` | Complete Locally |

## 3. Acceptance Criteria Matrix

| AC | Description | FR | TC | Status |
| --- | --- | --- | --- | --- |
| AC-OSS-001 | Construct store from validated config | FR-001 | TC-001 | Complete Locally |
| AC-OSS-002 | Execute core object operations | FR-002 | TC-002 | Complete Locally |
| AC-OSS-003 | List by prefix and page | FR-003 | TC-003 | Complete Locally |
| AC-OSS-004 | Complete multipart lifecycle | FR-004 | TC-004 | Complete Locally |
| AC-OSS-005 | Generate presigned GET/PUT | FR-005 | TC-005 | Complete Locally |
| AC-OSS-006 | Enforce strict delete missing-object behavior | FR-006 | TC-006 | Complete Locally |
| AC-OSS-007 | Return classifiable errors | FR-007 | TC-007 | Complete Locally |
| AC-OSS-008 | Keep public interface bounded | FR-008 | TC-009 | Complete Locally |
| AC-OSS-009 | Sanitize observability output | FR-009 | TC-008 | Complete Locally |
| AC-OSS-010 | Run live Aliyun integration from dev.md | FR-010 | TC-010 | Complete Locally |

## 4. Test Matrix

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

## 5. Task Matrix

| Task | Scope | Evidence | Status |
| --- | --- | --- | --- |
| TASK-OSSX-000 | Repo and module identity audit | docs and manifest alignment | Complete Locally |
| TASK-OSSX-001 | Public API surface reduction | interface governance tests | Complete Locally |
| TASK-OSSX-002 | Adapter capability split | constructor and SPI tests | Complete Locally |
| TASK-OSSX-003 | Strict delete and Aliyun lifecycle | unit + live integration + race | Complete Locally |
| TASK-OSSX-004 | Secret scope and integration env policy | `secret-scope-check.sh` | Complete Locally |
| TASK-OSSX-005 | 100% `pkg/ossx` coverage | cover profile | Complete Locally |
| TASK-OSSX-006 | Release manifest/docs update | `local-production-candidate` manifest | Complete Locally |

## 6. NFR Matrix

| NFR | Requirement | Evidence | Status |
| --- | --- | --- | --- |
| NFR-001 | Release-tag CI | `v1.2.1` tag CI artifact | Blocked External |
| NFR-002 | Secret scanning / xlibgate | release CI Gitleaks and xlibgate artifacts | Blocked External |
| NFR-003 | Interface governance | governance tests | Complete Locally |
| NFR-004 | Live Aliyun integration | local `dev.md` integration pass; CI artifact pending | Complete Locally / External Artifact Pending |
| NFR-005 | Downstream adoption | downstream module evidence | Blocked External |
| NFR-006 | Production soak | production-equivalent soak report | Blocked External |
| NFR-007 | Four-source scorer / arbiter | claude/codex/copilot/rules + arbiter pass | Blocked External |

## 7. Remaining Work

- Tag and push v1.2.1, then archive release-tag CI.
- Archive Gitleaks and xlibgate output from release CI.
- Run live Aliyun integration in controlled CI and archive pass/fail summary without secrets.
- Integrate one downstream module and record adoption evidence.
- Run production-equivalent soak and record SLO data.
- Run four-source scorer and arbiter, then update this matrix from local candidate to production release only if all gates pass.

## 8. Revision History

| Version | Date | Change |
| --- | --- | --- |
| v3.4 | 2026-06-19 | Aligned v1.2.1 local production candidate evidence and external blockers |
| v3.3 | 2026-06-19 | Added dev.md live integration and API governance closure |
| v3.2 | 2026-06-18 | Baseline production-readiness traceability |
