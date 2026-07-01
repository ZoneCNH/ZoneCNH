# Binance Traceability Matrix

- [KNOWN] Matrix-Version: v3.9.7
- [KNOWN] Last-Updated: 2026-07-02
- Source-SPEC: `module/binance/spec/SPEC.md` v3.9.7
- State-Model: single-state only
- [KNOWN] Current-State: 22 Done / 15 Partial / 11 Drifted / 0 Pending
- [KNOWN] release_closeable: NO（运行时缺口 58 项未闭合）

## 1. Rule

This matrix is the compact FR/BR/AC/TC projection. It intentionally does not duplicate historical changelog text. History is in `module/binance/CHANGELOG.md`; issue closure is tracked in Beads/GitHub; `module/binance/todo.md` is a read-only local projection and is not a closure SSOT。

**v3.9.7 新增**：FR 状态新增 `Runtime-Gap` 列，引用 `module/binance/RUNTIME-GAP-MATRIX.md`。状态口径遵循 CLAUDE.md §5.1（FR 状态以本表 §2 为权威，仪表盘 §6 从 §2 派生）。

## 2. FR Matrix

| FR | BR | AC | TC / Evidence Anchor | State | Runtime-Gap |
| --- | --- | --- | --- | --- | --- |
| FR-001 | BR-001 | AC-001 | client ingestion tests/e2e history | Done | — |
| FR-002 | BR-001 | AC-001 | bar ingestion tests/e2e history | Done | — |
| FR-003 | BR-003 | AC-002, AC-003 | subject drift check 22/22 PASS + .v1 fix | Done | — |
| FR-004 | BR-002 | AC-001 | server consumer boundary | Partial | GAP-E13, GAP-E31 |
| FR-005 | BR-001 | AC-001 | ClickHouse persistence tests/history | Drifted | GAP-E5, GAP-E30 |
| FR-006a | BR-002 | AC-001 | client CLI/config example | Done | — |
| FR-006b | BR-002 | AC-001 | server CLI/config example | Done | — |
| FR-006c | BR-003 | AC-001 | config schema/examples | Partial | GAP-E29 |
| FR-006d | BR-002 | AC-004 | smoke-only route gate | Done | — |
| FR-007 | BR-001 | AC-001 | query e2e evidence | Done | — |
| FR-007a | BR-001 | AC-001 | replay evidence | Done | — |
| FR-008 | BR-001 | AC-001 | depth ingestion history | Done | — |
| FR-009 | BR-001 | AC-001 | trade ingestion history | Done | — |
| FR-010 | BR-001 | AC-001 | bar persistence/query history | Partial | GAP-E5, GAP-E11 |
| FR-011 | BR-002 | AC-001 | failure injection | Drifted | GAP-E1, GAP-E13, GAP-E15 |
| FR-012 | BR-004 | AC-001 | ExchangeInfo refresh docs/runtime | Partial | GAP-E39, GAP-E40 |
| FR-013 | BR-004 | AC-001 | hot reload evidence | Partial | GAP-E29 |
| FR-014 | BR-002 | AC-001 | graceful shutdown tests/history | Drifted | GAP-E32, GAP-E33 |
| FR-015 | BR-003 | AC-001 | stable identity validation | Drifted | GAP-E1, GAP-E2 (CONSTITUTION §166) |
| FR-016 | BR-005 | AC-001 | metrics scrape evidence | Partial | GAP-E23, GAP-E26 |
| FR-017 | BR-005 | AC-001 | OTel evidence | Partial | GAP-E18, GAP-E19 |
| FR-018 | BR-001 | AC-001 | bars API runtime evidence | Done | — |
| FR-019 | BR-001 | AC-001 | depth API runtime evidence | Done | — |
| FR-020 | BR-001 | AC-001 | funding-rate API runtime evidence | Done | — |
| FR-021 | BR-001 | AC-001 | mark-price API runtime evidence | Done | — |
| FR-022 | BR-003 | AC-001 | instrument identity validation | Done | — |
| FR-023 | BR-005 | AC-001 | retention/archive evidence | Drifted | GAP-E5, GAP-E6, GAP-E7 |
| FR-024 | BR-004 | AC-001 | symbol reload evidence | Partial | GAP-E29 |
| FR-025 | BR-005 | AC-001 | soak/load evidence | Partial | GAP-E17, GAP-E25 |
| FR-026 | BR-002 | AC-001 | restart recovery evidence | Drifted | GAP-E4, GAP-E14 |
| FR-027 | BR-001 | AC-001 | full product-line evidence | Partial | GAP-E32, GAP-E33 |
| FR-028 | BR-003 | AC-001 | error taxonomy evidence | Done | — |
| FR-029 | BR-003 | AC-001 | data quality SLA migration | Partial | GAP-E9, GAP-E10 |
| FR-030 | BR-002 | AC-001 | health/readiness runtime | Drifted | GAP-E41, GAP-E42, GAP-E43 |
| FR-031 | BR-004 | AC-001 | full sync evidence | Partial | GAP-E39, GAP-E40 |
| FR-032 | BR-004 | AC-001 | diff sync evidence | Partial | GAP-E39, GAP-E40 |
| FR-033 | BR-004 | AC-001 | delist simulation | Done | — |
| FR-034 | BR-003 | AC-001 | key stability regression | Done | — |
| FR-035 | BR-003 | AC-001 | delivery metadata evidence | Done | — |
| FR-036 | BR-003 | AC-001 | options metadata evidence | Done | — |
| FR-037 | BR-002 | AC-004 | production `/ingest` disabled | Done | — |
| FR-038 | BR-005 | AC-007 | credential rotation evidence | Drifted | GAP-E37, GAP-E44, GAP-E45 |
| FR-039 | BR-005 | AC-007 | HA/DR doc/evidence | Partial | GAP-E46~GAP-E50 |
| FR-040 | BR-005 | AC-007 | canary exercise evidence | Done | — |
| FR-041 | BR-005 | AC-007 | capacity evidence | Partial | GAP-E41, GAP-E42 |
| FR-042 | BR-005 | AC-007 | soak evidence | Drifted | GAP-E3（todo.md 自爆 t.Skip 空壳） |
| FR-043 | BR-005 | AC-007 | chaos evidence | Drifted | GAP-E3（todo.md 自爆 t.Skip 空壳） |
| FR-044 | BR-005 | AC-007 | security hardening evidence | Drifted | GAP-E37, GAP-E8, GAP-E44, GAP-E45 |

## 3. Acceptance Criteria

| AC | Requirement | State |
| --- | --- | --- |
| AC-001 | local runtime tests pass for claimed local behavior | Done（规格口径） |
| AC-002 | spec-runtime drift check passes | Done |
| AC-003 | active docs and runtime use `.v1` market subject suffix | Done |
| AC-004 | `/ingest` remains smoke-only and unavailable in production | Done |
| AC-005 | root SPEC stays under 1000 lines | Done |
| AC-006 | root TRACEABILITY stays under 200 lines | Done |
| AC-007 | issue closure requires issue-level evidence | Drifted（GAP-E58：issue 已 close ≠ 运行时缺口已修复） |

## 4. Production Readiness Gates

release_closeable 判定公式：

```
release_closeable = Code-Done FR / Total FR ≥ 90% AND Drifted FR = 0 AND Pending FR = 0 AND PRG-001~007 全 PASS AND 远程 CI PASS AND release tag 已发布 AND HA/DR 部署文档存在
```

**当前状态（v3.9.7）：`release_closeable: NO`**

降级原因：
- Done FR = 12 / 48 = 25%（远低于 90% 阈值）
- Drifted FR = 13（需为 0）
- PRG-004/005/006 实际为 Partial/Drifted

| PRG | Gate | v3.9.6 声称 | v3.9.7 实际 | Evidence |
| --- | --- | --- | --- | --- |
| PRG-001 | remote CI current run | PASS | PASS | ubuntu-latest 已迁移 |
| PRG-002 | release promotion | PASS | PASS | v0.8.0 已发布 |
| PRG-003 | production readiness | PASS | **FAIL** | PRG-004/005/006 实际非 PASS |
| PRG-004 | observability | PASS | **Partial** | GAP-E18/E19/E23/E26 |
| PRG-005 | security | PASS | **Drifted** | GAP-E8/E37/E44/E45 |
| PRG-006 | resilience | PASS | **Drifted** | todo.md 自爆 131 个 t.Skip()；GAP-E3 |
| PRG-007 | issue sync | PASS | **Partial** | issue 已 close 但 GAP-E58 运行时缺口未闭合 |

## 5. Issue Projection

Beads and GitHub issues are the current P10 tracking SSOT。The retired local projection is archived at `module/binance/evidence/2026-06-28/todo-archived.md` and is not used for closure state。

**v3.9.7 新增**：`module/binance/RUNTIME-GAP-MATRIX.md` 提供 GAP-E → GitHub Issue 反向追溯。

## 6. Summary

> 仪表盘 FR 实现状态从 §2 派生（CLAUDE.md §5.1）。

| Metric | Value |
| --- | --- |
| FR total | 48 |
| Done | 22 |
| Partial | 15 |
| Drifted | 11 |
| Pending | 0 |
| Runtime Gaps (GAP-E) | 58（13 P0/P1 + 26 P2 + 19 P3） |
| GitHub P10 open | 0（issue 层面）；58（运行时层面，GAP-E58） |
| Beads P10 open | 0（同上） |
| release_closeable | **NO** |
