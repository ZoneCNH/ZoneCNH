# Binance Traceability Matrix

- [KNOWN] Matrix-Version: v4.1.0
- [KNOWN] Last-Updated: 2026-07-10（runtime implementation/evidence 双口径对齐审计）
- Source-SPEC: `module/binance/spec/SPEC.md` v4.1.0
- State-Model: single-state only
- [COMPUTED, HIGH] Current-State: 13 Done / 52 Partial / 0 Drifted / 0 Pending
- [COMPUTED, HIGH] Spec-release-closeable: NO（canonical Matrix 仍有 52 个 Partial）
- [COMPUTED, HIGH] Runtime-release-closeable: NO（2026-07-10 audit：外部 durable/fanout/query E2E、正式 tag/release notes 与 rollback evidence 尚未绑定同一最终 commit）

> [COMPUTED, HIGH] 上述旧 implementation/external ledger 提交与当前 runtime 审计基线 `b20f6d44f8b246149c7a9f9c06a4dc27bc7b49ef` 不同，不得用于提升当前 RC 状态。

## 1. Rule

This matrix is the compact FR/BR/AC/TC projection. It intentionally does not duplicate historical changelog text. History is in `module/binance/CHANGELOG.md`; issue closure is tracked in Beads/GitHub; `module/binance/todo.md` is a read-only local projection and is not a closure SSOT.

## 2. FR Matrix

| FR | BR | AC | TC / Evidence Anchor | State |
| --- | --- | --- | --- | --- |
| FR-001 | BR-001 | AC-001 | client ingestion tests/e2e history | Done |
| FR-002 | BR-001 | AC-001 | bar ingestion tests/e2e history | Done |
| FR-003 | BR-003 | AC-002, AC-003 | current RC NATS external gate blocked | Partial |
| FR-004 | BR-002 | AC-001 | consumer code exists; JetStream ManualAck/redelivery current-RC evidence needed | Partial |
| FR-005 | BR-001 | AC-001 | current RC durable persistence/readback evidence needed | Partial |
| FR-006a | BR-002 | AC-001 | client CLI/config example | Done |
| FR-006b | BR-002 | AC-001 | server CLI/config example | Done |
| FR-006c | BR-003 | AC-001 | config schema/examples | Done |
| FR-006d | BR-002 | AC-004 | smoke-only route gate | Done |
| FR-007 | BR-001 | AC-001 | query e2e evidence needed | Partial |
| FR-007a | BR-001 | AC-001 | replay evidence needed | Partial |
| FR-008 | BR-001 | AC-001 | depth ingestion history | Done |
| FR-009 | BR-001 | AC-001 | trade ingestion history | Done |
| FR-010 | BR-001 | AC-001 | current RC persistence/query readback needed | Partial |
| FR-011 | BR-002 | AC-001 | failure injection needed | Partial |
| FR-012 | BR-004 | AC-001 | Candidate Catalog/Admission separation and current-RC refresh evidence needed | Partial |
| FR-013 | BR-004 | AC-001 | hot reload evidence needed | Partial |
| FR-014 | BR-002 | AC-001 | active history/drain recovery is not closed | Partial |
| FR-015 | BR-003 | AC-001 | request/payload/instrument identity validation incomplete | Partial |
| FR-016 | BR-005 | AC-001 | metrics scrape evidence needed | Partial |
| FR-017 | BR-005 | AC-001 | OTel evidence needed | Partial |
| FR-018 | BR-001 | AC-001 | current RC bars API external readback needed | Partial |
| FR-019 | BR-001 | AC-001 | orderbook incomplete; current RC depth API evidence needed | Partial |
| FR-020 | BR-001 | AC-001 | independent funding stream/history path is not implemented | Partial |
| FR-021 | BR-001 | AC-001 | current RC mark-price storage/query evidence needed | Partial |
| FR-022 | BR-003 | AC-001 | strong identity wire validation incomplete | Partial |
| FR-023 | BR-005 | AC-001 | retention/archive evidence needed | Partial |
| FR-024 | BR-004 | AC-001 | symbol reload evidence needed | Partial |
| FR-025 | BR-005 | AC-001 | soak/load evidence needed | Partial |
| FR-026 | BR-002 | AC-001 | retry/restart fixed; interval-set reconciliation and state-load fail-closed evidence needed | Partial |
| FR-027 | BR-001 | AC-001 | full product-line evidence needed | Partial |
| FR-028 | BR-003 | AC-001 | error taxonomy evidence needed | Partial |
| FR-029 | BR-003 | AC-001 | coverage/gap/reconcile capability matrix incomplete | Partial |
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
| FR-042 | BR-005 | AC-007 | historical soak is not bound to current RC | Partial |
| FR-043 | BR-005 | AC-007 | historical chaos evidence is not bound to current RC | Partial |
| FR-044 | BR-005 | AC-007 | current RC security scan/pentest and credential-incident closure needed | Partial |
| FR-045 | BR-009 | AC-001 | fail-open/update/reconnect current-RC E2E needed | Partial |
| FR-046 | BR-009 | AC-001 | whitelist 表 + version SSOT + sync_log + first_seen_at 列（migration 016） | Done |
| FR-047 | BR-009 | AC-001 | GET /internal/whitelist；POST /internal/whitelist/refresh（GC-5b 审核态反馈 #452） | Done |
| FR-048 | BR-009 | AC-001 | current RC NATS version-push evidence needed | Partial |
| FR-049 | BR-009 | AC-001 | 下游消费方 SDK（GC-5c 真正 fail-open #449：degraded 态 + OnDegraded + IsFailOpen） | Done |
| FR-050 | BR-009 | AC-001 | true Catalog Added/Updated/Removed propagation incomplete | Partial |
| FR-051 | BR-009 | AC-001 | Options capability/hot update fixed; live admission and capacity evidence incomplete | Partial |

### v4.1.0 Order Book FR-052~061（四线当前均为 Partial）

| FR | BR | AC | Evidence | State |
| --- | --- | --- | --- | --- |
| FR-052 | BR-001 | AC-OB-001 | Options explicit-whitelist path exists; four-line live generation/freshness evidence remains | Partial |
| FR-053 | BR-001 | AC-OB-002 | four-line snapshot mode evidence incomplete | Partial |
| FR-054 | BR-001 | AC-OB-003~005 | alignment race/apply-error/Options sequence evidence incomplete | Partial |
| FR-055 | BR-001 | AC-OB-006 | rebuild generation and disconnect trigger incomplete | Partial |
| FR-056 | BR-001 | AC-OB-007 | persisted recovery lacks age/bridge/checksum validation | Partial |
| FR-057 | BR-001 | AC-OB-008 | disconnect freshness cannot be proven | Partial |
| FR-058 | BR-001 | AC-OB-009 | stale output/pooled-book lifecycle evidence incomplete | Partial |
| FR-059 | BR-001 | AC-OB-010 | rebuild markers can be dropped | Partial |
| FR-060 | BR-001 | AC-OB-011 | four-line on-demand snapshot evidence incomplete | Partial |
| FR-061 | BR-005 | AC-OB-012 | checksum sampling config/concurrency and Options coverage incomplete | Partial |

> **Options 当前边界**：显式订单簿白名单、REST snapshot 与 full-incremental manager 路径已接入；ADR-011 §7.4 的 live alignment、重连、合约 churn、容量与 checksum checklist 未闭合，因此 FR-052~061 仍为 Partial。

## 3. Acceptance Criteria

| AC | Requirement | State |
| --- | --- | --- |
| AC-001 | local runtime tests pass for claimed local behavior | Done |
| AC-002 | spec-runtime drift check passes | Done |
| AC-003 | active docs and runtime use `.v1` market subject suffix | Done |
| AC-004 | `/ingest` remains smoke-only and unavailable in production | Done |
| AC-005 | root SPEC stays under 1000 lines | Done |
| AC-006 | root TRACEABILITY stays under 200 lines | Done |
| AC-007 | issue closure requires issue-level evidence | Done |

## 4. Production Readiness Gates

规格口径的 `release_closeable_spec` 判定公式：

```
release_closeable_spec = Code-Done FR / Total FR ≥ 90% AND Drifted FR = 0 AND Pending FR = 0 AND PRG-001~007 gates PASS
```

CI 门禁投影（`release_closeable_spec` 的等价投影，供一致性门禁消费）：`release_closeable: NO`（Code-Done 13/65，且存在 52 个 Partial）。[COMPUTED, HIGH]

```
release_closeable = Code-Done FR / Total FR ≥ 90% AND Drifted FR = 0 AND Pending FR = 0 AND PRG-001~007 gates PASS
```

当前规格状态：`release_closeable_spec: NO`（65 FR 中 13 Done、52 Partial）。runtime 发布状态还必须满足同一最终 commit 的外部 durable/fanout/query E2E、正式 release tag/release notes、部署前检查和 rollback evidence；本轮 `release_closeable_runtime: NO`。[COMPUTED, HIGH]

| PRG | Gate | State | Evidence |
| --- | --- | --- | --- |
| PRG-001 | remote CI current run | BLOCKED | [COMPUTED, HIGH] 当前 RC 无归档的远程 CI 成功证据 |
| PRG-002 | release promotion | BLOCKED | [COMPUTED, HIGH] 当前 RC 无 tag/release notes/artifact digest |
| PRG-003 | production readiness | BLOCKED | [COMPUTED, HIGH] PRG-001~007 未全通过 |
| PRG-004 | observability | BLOCKED | [COMPUTED, HIGH] 外部可观测证据未绑定当前 RC |
| PRG-005 | security | BLOCKED | [COMPUTED, HIGH] 当前 RC 的 security/lint 证据未闭合 |
| PRG-006 | resilience | BLOCKED | [COMPUTED, HIGH] 外部耐久性、故障注入与 rollback 未绑定当前 RC |
| PRG-007 | issue sync | BLOCKED | [COMPUTED, HIGH] Beads epic `ZoneCNH-7i1p` 仍为 in_progress |

## 5. Issue Projection & Evidence GAP-E Mapping

### 5.1 Issue Tracking

Beads and GitHub issues are the current P10 tracking SSOT. The retired local projection is archived at `module/binance/evidence/2026-06-28/todo-archived.md` and is not used for closure state.

### 5.2 Evidence → GAP-E Bidirectional Reference（修复 #369）

本矩阵与 `evidence/` 层实现**双向链接**：
- **evidence/ 层** → 追踪运行时缺口修复进度（见 `../evidence/README-GAP-E-INDEX.md`）
- **本矩阵** → 展示规格口径的 FR 完成状态（与 GAP-E 正交）

| GAP-E 范畴 | 涵盖范围 | Evidence 位置 | 状态 |
| --- | --- | --- | --- |
| **P0 CRITICAL** | GAP-E1, E6, E25 | `../evidence/2026-07-02/tier-gap-cross-reference.md` | GAP-E1 ✅ Fixed（PR #425），GAP-E6 ✅ Fixed（PR #425），GAP-E25 Open |
| **P1 HIGH** | GAP-E2~E4, E7~E24, E26~E28, E32, E37 | `../evidence/2026-06-30/release/`, `../evidence/2026-07-03/` | Open（分阶段推进） |
| **P2 MEDIUM** | GAP-E5, E8, E9, E13~E23, E29~E31, E33~E36, E39~E42, E46~E50 | 原 E2E 报告已于 #1652 归档清理，待补运行时证据 | Open（运行时验证）|
| **P3 LOW** | GAP-E11, E15, E16, E21, E22, E35, E38, E43, E51~E56 | `../evidence/2026-06-30/release/alignment-summary.md` | Planning |
| **Meta** | GAP-E57（evidence 无引用）→ **Closed**；GAP-E58（issue≠修复） | `../evidence/README-GAP-E-INDEX.md`（本文件新增） | Done |

详见 `../evidence/README-GAP-E-INDEX.md` 完整映射表。

## 6. Summary

| Metric | Value |
| --- | --- |
| FR total | 65 |
| Done | 13 |
| Partial | 52 |
| Drifted | 0 |
| Pending | 0 |
| GitHub P10 open | 0 |
| Beads P10 open | 0 |
| release_closeable | NO（当前矩阵含 52 个 Partial） |
| release_closeable_spec | NO |
| release_closeable_runtime | NO |

> **运行时缺口投影**：历史 GAP-E 修复记录保留在本文件；本轮不从历史记录自动推导 runtime release。当前矩阵含 52 个 Partial，且 runtime `release_closeable_runtime=NO`。
>
> `release_closeable_spec=NO`：当前 Code-Done FR / Total FR = 13/65，52 个 FR 仍缺功能或当前 RC 证据；runtime `release_closeable_runtime=NO`。
