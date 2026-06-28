# Binance Traceability Matrix

- Matrix-Version: v3.9.6
- Last-Updated: 2026-06-28
- Source-SPEC: `module/binance/spec/SPEC.md` v3.9.6
- State-Model: single-state only
- Current-State: 23 Done / 25 Partial / 0 Drifted / 0 Pending
- release_closeable: NO

## 1. Rule

This matrix is the compact FR/BR/AC/TC projection. It intentionally does not duplicate historical changelog text. History is in `module/binance/CHANGELOG.md`; issue closure is tracked in Beads/GitHub; `module/binance/todo.md` is a read-only local projection and is not a closure SSOT.

## 2. FR Matrix

| FR | BR | AC | TC / Evidence Anchor | State |
| --- | --- | --- | --- | --- |
| FR-001 | BR-001 | AC-001 | client ingestion tests/e2e history | Done |
| FR-002 | BR-001 | AC-001 | bar ingestion tests/e2e history | Done |
| FR-003 | BR-003 | AC-002, AC-003 | subject drift check | Done |
| FR-004 | BR-002 | AC-001 | server consumer boundary | Done |
| FR-005 | BR-001 | AC-001 | ClickHouse persistence tests/history | Done |
| FR-006a | BR-002 | AC-001 | client CLI/config example | Done |
| FR-006b | BR-002 | AC-001 | server CLI/config example | Done |
| FR-006c | BR-003 | AC-001 | config schema/examples | Done |
| FR-006d | BR-002 | AC-004 | smoke-only route gate | Done |
| FR-007 | BR-001 | AC-001 | query e2e evidence needed | Partial |
| FR-007a | BR-001 | AC-001 | replay evidence needed | Partial |
| FR-008 | BR-001 | AC-001 | depth ingestion history | Done |
| FR-009 | BR-001 | AC-001 | trade ingestion history | Done |
| FR-010 | BR-001 | AC-001 | bar persistence/query history | Done |
| FR-011 | BR-002 | AC-001 | failure injection needed | Partial |
| FR-012 | BR-004 | AC-001 | ExchangeInfo refresh docs/runtime | Done |
| FR-013 | BR-004 | AC-001 | hot reload evidence needed | Partial |
| FR-014 | BR-002 | AC-001 | graceful shutdown tests/history | Done |
| FR-015 | BR-003 | AC-001 | stable identity validation | Done |
| FR-016 | BR-005 | AC-001 | metrics scrape evidence needed | Partial |
| FR-017 | BR-005 | AC-001 | OTel evidence needed | Partial |
| FR-018 | BR-001 | AC-001 | bars API runtime evidence | Done |
| FR-019 | BR-001 | AC-001 | depth API runtime evidence | Done |
| FR-020 | BR-001 | AC-001 | funding-rate API runtime evidence | Done |
| FR-021 | BR-001 | AC-001 | mark-price API runtime evidence | Done |
| FR-022 | BR-003 | AC-001 | instrument identity validation | Done |
| FR-023 | BR-005 | AC-001 | retention/archive evidence needed | Partial |
| FR-024 | BR-004 | AC-001 | symbol reload evidence needed | Partial |
| FR-025 | BR-005 | AC-001 | soak/load evidence needed | Partial |
| FR-026 | BR-002 | AC-001 | restart recovery evidence needed | Partial |
| FR-027 | BR-001 | AC-001 | full product-line evidence needed | Partial |
| FR-028 | BR-003 | AC-001 | error taxonomy evidence needed | Partial |
| FR-029 | BR-003 | AC-001 | data quality SLA migration | Done |
| FR-030 | BR-002 | AC-001 | health/readiness runtime | Done |
| FR-031 | BR-004 | AC-001 | full sync evidence needed | Partial |
| FR-032 | BR-004 | AC-001 | diff sync evidence needed | Partial |
| FR-033 | BR-004 | AC-001 | delist simulation needed | Partial |
| FR-034 | BR-003 | AC-001 | key stability regression needed | Partial |
| FR-035 | BR-003 | AC-001 | delivery metadata evidence needed | Partial |
| FR-036 | BR-003 | AC-001 | options metadata evidence needed | Partial |
| FR-037 | BR-002 | AC-004 | production `/ingest` disabled | Done |
| FR-038 | BR-005 | AC-007 | credential rotation evidence needed | Partial |
| FR-039 | BR-005 | AC-007 | HA/DR doc/evidence needed | Partial |
| FR-040 | BR-005 | AC-007 | canary exercise evidence needed | Partial |
| FR-041 | BR-005 | AC-007 | capacity evidence needed | Partial |
| FR-042 | BR-005 | AC-007 | soak evidence needed | Partial |
| FR-043 | BR-005 | AC-007 | chaos evidence needed | Partial |
| FR-044 | BR-005 | AC-007 | security hardening evidence needed | Partial |

## 3. Acceptance Criteria

| AC | Requirement | State |
| --- | --- | --- |
| AC-001 | local runtime tests pass for claimed local behavior | Partial |
| AC-002 | spec-runtime drift check passes | Done |
| AC-003 | active docs and runtime use `.v1` market subject suffix | Done |
| AC-004 | `/ingest` remains smoke-only and unavailable in production | Done |
| AC-005 | root SPEC stays under 1000 lines | Done |
| AC-006 | root TRACEABILITY stays under 200 lines | Done |
| AC-007 | issue closure requires issue-level evidence | Partial |

## 4. Production Readiness Gates

release_closeable 判定公式：

```
release_closeable = Code-Done FR / Total FR ≥ 90% AND Drifted FR = 0 AND Pending FR = 0 AND PRG-001~007 全 PASS AND 远程 CI PASS AND release tag 已发布 AND HA/DR 部署文档存在
```

当前状态：`release_closeable: NO`（23/48 Done ≈ 47.9% < 90%，25 Partial，PRG-001~007 均 Open）。

| PRG | Gate | State | Blocking evidence |
| --- | --- | --- | --- |
| PRG-001 | remote CI current run | Open | current P10 run id |
| PRG-002 | release promotion | Open | issue-bound release evidence |
| PRG-003 | production readiness | Open | PRG 7/7 proof |
| PRG-004 | observability | Open | metrics/OTel/dashboard/alert evidence |
| PRG-005 | security | Open | scan/mTLS/pentest evidence |
| PRG-006 | resilience | Open | soak/chaos/canary evidence |
| PRG-007 | issue sync | PASS | 43 GitHub + 43 Beads closures（all closed） |

## 5. Issue Projection

Beads and GitHub issues are the current P10 tracking SSOT. The retired local projection is archived at `module/binance/evidence/2026-06-28/todo-archived.md` and is not used for closure state.

## 6. Summary

| Metric | Value |
| --- | --- |
| FR total | 48 |
| Done | 23 |
| Partial | 25 |
| Drifted | 0 |
| Pending | 0 |
| GitHub P10 open | 0 |
| Beads P10 open | 0 |
| release_closeable | NO |
