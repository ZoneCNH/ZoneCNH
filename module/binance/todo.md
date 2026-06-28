# Binance P10 Issue Projection (2026-06-28)

[COMPUTED, HIGH] This file is a read-only projection of the current Binance P10 tracker state.
[COMPUTED, HIGH] Closure SSOTs are Beads and GitHub Issues; editing this file does not close or claim any issue.
[COMPUTED, HIGH] release_closeable=NO until every P10 issue has issue-level evidence and the release gates are satisfied.
[COMPUTED, HIGH] 2026-06-28 P10 fix round: all 43 issues have deliverables attached. Phase 1 (16 issues) fully closed with evidence; Phase 2-6 (27 issues) have scaffolding/plans/scripts created, pending live infrastructure validation.

## Summary

| Metric                              | Value    |
| ----------------------------------- | -------- |
| GitHub P10 issues                   | 43 open  |
| Beads P10 issues                    | 43 open  |
| Projection rows                     | 43       |
| Deliverables created                | 43       |
| Phase 1 fully closed (evidence attached) | 16  |
| Phase 2-6 deliverables created (pending live validation) | 27 |
| Issue-level evidence still required | 27       |
| Closeable now                       | 16       |

## Tracker Selectors

[COMPUTED, HIGH] GitHub current P10 set is open issues with label `p10`.
[COMPUTED, HIGH] Beads current P10 set is open issues whose title starts with `[P10-`; all 43 matching Beads rows currently have `labels=null`, so labels are not a valid Beads selector for this alignment.

## Current Projection

| Action  | GitHub | Beads        | Evidence class                        | Deliverable                                                                                              | Closeable |
| ------- | ------ | ------------ | ------------------------------------- | -------------------------------------------------------------------------------------------------------- | --------- |
| A-1     | #1293  | ZoneCNH-5k4j | local-doc + local-runtime             | `internal/wire/doc.go` role clarification + SPEC note                                                    | ✅ YES    |
| A-2/E-5 | #1291  | ZoneCNH-lk5q | local-runtime                         | main.go 383→47 lines, `pkg/binancecfg/config.go`, `internal/server/assembly/assembly.go`                 | ✅ YES    |
| A-3/B-1 | #1294  | ZoneCNH-z31g | local-runtime + boundary              | Smoke-only /ingest gate in assembly.go, boundary-gates.sh §16 (15 gates)                                 | ✅ YES    |
| A-4/B-3 | #1303  | ZoneCNH-5cv5 | local-doc + local-runtime             | Subject `.v1` versioning verified, drift check PASS                                                      | ✅ YES    |
| B-2     | #1295  | ZoneCNH-886q | local-doc                             | client/SPEC §14 fixed to monorepo `internal/client/` layout                                              | ✅ YES    |
| C-1/G-3 | #1299  | ZoneCNH-o6ge | local-doc                             | SPEC 225 lines, parameter tables in design/                                                              | ✅ YES    |
| C-2/G-2 | #1297  | ZoneCNH-k2ml | local-doc                             | 4 retired files physically deleted                                                                       | ✅ YES    |
| C-3     | #1289  | ZoneCNH-87x7 | local-doc                             | SPEC.md 225 lines (< 1000 target)                                                                        | ✅ YES    |
| C-4     | #1298  | ZoneCNH-l7um | local-doc                             | AC/TC namespace clean, no coordination notes                                                             | ✅ YES    |
| D-1     | #1290  | ZoneCNH-9iaw | local-doc                             | Dual-state model abolished, single-state (Done/Partial/Drifted/Pending)                                  | ✅ YES    |
| D-2/G-1 | #1300  | ZoneCNH-32qf | local-doc                             | TRACEABILITY.md 114 lines (< 200 target), history migrated                                               | ✅ YES    |
| D-3     | #1302  | ZoneCNH-5gfo | local-doc                             | release_closeable formula documented, current=NO (23/48 ≈ 47.9%)                                         | ✅ YES    |
| D-4/G-5 | #1292  | ZoneCNH-bgj0 | tracker projection                    | todo.md is read-only projection, archived at evidence/2026-06-28/todo-archived.md                        | ✅ YES    |
| G-4     | #1296  | ZoneCNH-obwk | local-doc                             | BOUNDARY-GATES §20 migrated to docs/governance/boundary-gates-template.md                                | ✅ YES    |
| G-6     | #1301  | ZoneCNH-s1k2 | external CI                           | Status consistency CI gate enhanced (release_closeable + dual-state + FR ratio)                          | ✅ YES    |
| E-6     | #1331  | ZoneCNH-1l30 | local-runtime                         | `scripts/spec-runtime-drift-check.sh` exists, 22 checks PASS                                             | ✅ YES    |
| E-1     | #1306  | ZoneCNH-o1bm | local-runtime + remote CI             | FR closure plan: `docs/plans/fr-closure/e1-p0-core-fr.md`                                                | ⏳ PLAN   |
| E-2     | #1321  | ZoneCNH-kmvd | production evidence                   | FR closure plan: `docs/plans/fr-closure/e2-p1-production-fr.md`                                          | ⏳ PLAN   |
| E-3     | #1328  | ZoneCNH-s9v2 | local-runtime                         | FR closure plan: `docs/plans/fr-closure/e3-p2-exchangeinfo-fr.md`                                        | ⏳ PLAN   |
| E-4     | #1327  | ZoneCNH-s3hd | security/compliance                   | FR closure plan: `docs/plans/fr-closure/e4-p2-compliance-fr.md`                                          | ⏳ PLAN   |
| F-1     | #1323  | ZoneCNH-2gt4 | remote CI                             | `.github/workflows/binance-ci.yml` (self-hosted runners, 10 workflows)                                   | ⏳ CI RUN |
| F-2     | #1326  | ZoneCNH-pp3h | release evidence                      | `docs/release/v0.2.0-release-notes.md` + `v0.2.0-checklist.md`                                           | ⏳ TAG    |
| F-3     | #1325  | ZoneCNH-aqbf | production readiness                  | 7 PRG templates: `docs/prg/prg-001~007.md`                                                               | ⏳ PRG    |
| F-4     | #1316  | ZoneCNH-laf5 | HA/DR evidence                        | 7 HA/DR docs: `docs/deployment/{nats,redis,postgres,tdengine,kafka,minio-oss,ha-dr-summary}-ha.md`      | ⏳ DEPLOY |
| F-5/J-1 | #1309  | ZoneCNH-9ls5 | security runbook                      | `docs/runbooks/credential-rotation.md` (9 credential types)                                              | ⏳ REVIEW |
| F-6     | #1320  | ZoneCNH-3ej4 | production exercise                   | `scripts/deploy-canary.sh` + `deploy-canary-gate.sh`                                                     | ⏳ DRILL  |
| F-7     | #1318  | ZoneCNH-4nc8 | capacity evidence                     | `docs/capacity-planning.md` (9 components, 30/90/365d projection)                                        | ⏳ REVIEW |
| H-1     | #1312  | ZoneCNH-bppf | runtime tests                         | `test/depth/depth_test.go` (25 FRs × 5 subtests) + `run.sh`                                              | ⏳ TEST   |
| H-2     | #1317  | ZoneCNH-a2te | coverage CI                           | `scripts/coverage-check.sh` (98% gate) + `docs/evidence-templates/coverage-evidence.md`                  | ⏳ RUN    |
| H-4     | #1305  | ZoneCNH-qhos | soak evidence                         | `test/soak/soak_test.go` (30min, 4 product lines) + `run.sh`                                             | ⏳ RUN    |
| H-5     | #1304  | ZoneCNH-4b1b | chaos evidence                        | `test/chaos/chaos_test.go` (5 scenarios) + `run.sh`                                                      | ⏳ RUN    |
| I-1     | #1322  | ZoneCNH-nron | metrics runtime                       | `internal/server/metrics/cost.go` + `audit.go` (FR-043/044 full metrics)                                 | ✅ CODE   |
| I-2     | #1311  | ZoneCNH-mxmd | observability external                | `docs/observability/tracing-setup.md` + `configs/otel-collector.yaml`                                    | ⏳ SCREEN |
| I-3     | #1324  | ZoneCNH-2kjq | observability artifact                | `docs/observability/grafana-dashboard.json` (10 panels)                                                  | ⏳ IMPORT |
| I-4     | #1315  | ZoneCNH-xgrq | alert validation                      | `docs/observability/alerts.yaml` (9 alert rules)                                                         | ⏳ LOAD   |
| I-5     | #1319  | ZoneCNH-og7z | logging runtime                       | `docs/observability/logging.yaml` (Loki Promtail, 5 scrape jobs)                                         | ⏳ DEPLOY |
| J-2     | #1329  | ZoneCNH-fbff | security runtime                      | Admin Bearer token + TLS + mTLS in `admin.go`, env config                                                | ✅ CODE   |
| J-3     | #1310  | ZoneCNH-klgj | remote security CI                    | `.github/workflows/secrets-scan.yml` (gitleaks)                                                          | ⏳ CI RUN |
| J-4     | #1314  | ZoneCNH-l2oa | remote vulnerability CI               | `.github/workflows/vuln-scan.yml` (govulncheck)                                                          | ⏳ CI RUN |
| J-5     | #1308  | ZoneCNH-hjp4 | security doc                          | `docs/security/network-isolation.md` (3-zone, 14 policies)                                               | ⏳ REVIEW |
| J-6     | #1313  | ZoneCNH-w47o | data governance                       | `migrations/005_data_classification.sql` + `taos_ddl.sql` TAG                                            | ✅ CODE   |
| J-7     | #1307  | ZoneCNH-ckpf | compliance exercise                   | `scripts/destruction-drill.sh` (DRY_RUN support)                                                         | ⏳ DRILL  |
| J-8     | #1330  | ZoneCNH-dvf9 | penetration evidence                  | `test/security/api_security_test.go` (6 test types) + `run.sh`                                           | ⏳ RUN    |

## Stop Condition

[COMPUTED, HIGH] Phase 1 (16 issues: A-1~A-4, B-2, C-1~C-4, D-1~D-4, G-4, G-6, E-6) deliverables complete with evidence attached; ready for issue closure.
[COMPUTED, HIGH] Phase 2-6 (27 issues: E-1~E-4, F-1~F-7, H-1~H-5, I-1~I-5, J-2~J-8) have code/doc/script deliverables created; pending live infrastructure validation (CI run, soak test, chaos test, canary drill, destruction drill, penetration test, OTel screenshot, Grafana import).
[COMPUTED, HIGH] release_closeable=NO (Code-Done 23/48 ≈ 47.9% < 90%, PRG open, no release tag, no remote CI evidence).
