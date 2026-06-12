# ossx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: [module/ossx/SPEC.md](./SPEC.md) v1.0.0
Scope: Matrix repair for `FR/BR -> AC -> TC -> Task -> Evidence -> Status` closure.

---

## 1. Requirement Traceability Matrix

| Requirement | Description | Acceptance Criteria | Test Case | Task | Evidence | Status |
|-------------|-------------|---------------------|-----------|------|----------|--------|
| FR-001 | NewClient supports s3, minio, and local clients with config validation | AC-001 | TC-005 | TASK-OSSX-000 | SPEC §7 FR-001, §16.2 TC-005, Config/Error contracts | Done |
| FR-002 | Put uploads valid objects, validates keys and size, supports multipart and cancellation | AC-002, AC-003, AC-010 | TC-001, TC-002, TC-003 | TASK-OSSX-001, TASK-OSSX-002 | SPEC §7 FR-002, §16.2 TC-001/002/003, BR-001/002/003/006/012 | Done |
| FR-003 | Get returns an `io.ReadCloser`, maps missing/invalid keys, and releases resources on close | AC-004, AC-010 | TC-001, TC-004 | TASK-OSSX-001 | SPEC §7 FR-003, §16.2 TC-001/004, Interface Contract §9 | Done |
| FR-004 | Delete removes existing objects and is idempotent for missing objects | AC-005 | TC-004, TC-006 | TASK-OSSX-003 | SPEC §7 FR-004, §16.2 TC-004/006, BR-008 | Done |
| FR-005 | List returns sorted object metadata, supports empty prefix, and truncates at max_results | AC-006 | TC-004, TC-007 | TASK-OSSX-003 | SPEC §7 FR-005, §16.2 TC-004/007, BR-004 | Done |
| FR-006 | PresignURL returns signed URLs, validates expiry, and supports local backend URL semantics | AC-007 | TC-008 | TASK-OSSX-004 | SPEC §7 FR-006, §16.2 TC-008, Security §19 | Done |
| FR-007 | Health reports ready/live state for reachable and unreachable backends | AC-008, AC-012 | TC-009 | TASK-OSSX-005 | SPEC §7 FR-007, §16.2 TC-009, Observability §18 | Done |
| FR-008 | Close releases resources and remains idempotent on repeated calls | AC-009 | TC-010 | TASK-OSSX-005 | SPEC §7 FR-008, §16.2 TC-010, BR-009 | Done |
| BR-001 | Object keys must be non-empty and must not start with `/` | AC-002, AC-004 | TC-001, TC-004 | TASK-OSSX-001 | SPEC §8 BR-001, FR-002/003 invalid-key clauses | Done |
| BR-002 | Multipart upload threshold defaults to 100MB and is configurable | AC-003 | TC-002 | TASK-OSSX-002 | SPEC §8 BR-002, FR-002 multipart clause | Done |
| BR-003 | Multipart part size defaults to 5MB and is configurable | AC-003 | TC-002 | TASK-OSSX-002 | SPEC §8 BR-003, multipart configuration contract | Done |
| BR-004 | List results default to 1000 entries and may be overridden by opts | AC-006 | TC-007 | TASK-OSSX-003 | SPEC §8 BR-004, FR-005 truncation clause | Done |
| BR-005 | Health must be idempotent and side-effect free | AC-008 | TC-009 | TASK-OSSX-005 | SPEC §8 BR-005, FR-007 Health clauses | Done |
| BR-006 | All operations accept `context.Context` and support cancellation or timeout | AC-010 | TC-001, TC-002, TC-003 | TASK-OSSX-001, TASK-OSSX-002 | SPEC §8 BR-006, Interface Contract §9.1 | Done |
| BR-007 | Error messages follow `ossx: <operation>: <detail>` | AC-010 | TC-005 | TASK-OSSX-000 | SPEC §8 BR-007, Error Handling §12 | Done |
| BR-008 | Delete of nonexistent objects is idempotent and returns no error | AC-005 | TC-006 | TASK-OSSX-003 | SPEC §8 BR-008, FR-004 delete-missing clause | Done |
| BR-009 | Close is idempotent and repeated calls do not panic | AC-009 | TC-010 | TASK-OSSX-005 | SPEC §8 BR-009, FR-008 repeated-close clause | Done |
| BR-010 | Local backend base path must be absolute | AC-011 | TC-004, TC-005 | TASK-OSSX-000 | SPEC §8 BR-010, Config Schema §11, Security §19 | Done |
| BR-011 | Metrics must include backend and operation labels | AC-012 | TC-009 | TASK-OSSX-005 | SPEC §8 BR-011, Observability §18, CI Gate §20 | Done |
| BR-012 | Put Content-Type is read from opts and is not auto-detected | AC-002 | TC-001 | TASK-OSSX-001 | SPEC §8 BR-012, PutOpt Interface Contract §9.2 | Done |

---

## 2. Acceptance Criteria Registry

| AC | Covers | Verifiable Result | Evidence |
|----|--------|-------------------|----------|
| AC-001 | FR-001 | `NewClient` creates s3/minio/local clients for valid config and rejects unsupported or incomplete config with typed errors | TC-005 |
| AC-002 | FR-002, BR-001, BR-012 | `Put` uploads valid input, rejects invalid keys, observes object-size limits, and uses opts-provided Content-Type | TC-001 |
| AC-003 | FR-002, BR-002, BR-003 | Put selects multipart upload above the configured threshold using configured/default part size | TC-002 |
| AC-004 | FR-003, BR-001 | `Get` returns a usable `io.ReadCloser`, maps not-found and invalid-key errors, and releases connections on close | TC-001, TC-004 |
| AC-005 | FR-004, BR-008 | `Delete` removes existing objects and returns nil for missing objects across repeated calls | TC-004, TC-006 |
| AC-006 | FR-005, BR-004 | `List` handles prefix/no-prefix/no-match cases, sorts keys, and truncates at `max_results` | TC-004, TC-007 |
| AC-007 | FR-006 | `PresignURL` returns signed URLs for valid expiry, rejects non-positive expiry, and documents local URL behavior | TC-008 |
| AC-008 | FR-007, BR-005 | `Health` is repeatable and reports reachable/unreachable backend state without mutating storage | TC-009 |
| AC-009 | FR-008, BR-009 | `Close` releases resources once and repeated calls return nil without panic | TC-010 |
| AC-010 | BR-006, BR-007 | Context-aware operations propagate cancellation/timeouts and wrap errors as `ossx: <operation>: <detail>` | TC-001, TC-002, TC-003, TC-005 |
| AC-011 | BR-010 | Local backend refuses non-absolute `base_path` during config validation | TC-004, TC-005 |
| AC-012 | FR-007, BR-011 | Health/operation instrumentation exposes metrics with backend and operation labels | TC-009, CI Gate §20 |

---

## 3. Test Case Reverse Trace

| Test Case | Validates Requirements | Primary Acceptance Criteria | Evidence Source |
|-----------|------------------------|-----------------------------|-----------------|
| TC-001 | FR-002, FR-003, BR-001, BR-006, BR-012 | AC-002, AC-004, AC-010 | SPEC §16.2 complete upload/download flow |
| TC-002 | FR-002, BR-002, BR-003, BR-006 | AC-003, AC-010 | SPEC §16.2 large-file multipart upload |
| TC-003 | FR-002, BR-006, BR-011 | AC-010, AC-012 | SPEC §16.2 concurrent operations |
| TC-004 | FR-003, FR-004, FR-005, BR-010 | AC-004, AC-005, AC-006, AC-011 | SPEC §16.2 local backend basic operations |
| TC-005 | FR-001, BR-007, BR-010 | AC-001, AC-010, AC-011 | SPEC §16.2 NewClient config validation |
| TC-006 | FR-004, BR-008 | AC-005 | SPEC §16.2 Delete idempotency |
| TC-007 | FR-005, BR-004 | AC-006 | SPEC §16.2 List prefix behavior |
| TC-008 | FR-006 | AC-007 | SPEC §16.2 PresignURL behavior |
| TC-009 | FR-007, BR-005, BR-011 | AC-008, AC-012 | SPEC §16.2 Health check |
| TC-010 | FR-008, BR-009 | AC-009 | SPEC §16.2 Close idempotency |

---

## 4. Task Closure Registry

> 本仓库当前 `module/ossx/` 只包含 `SPEC.md`、`TRACEABILITY.md` 和 `goal.md`，未发现独立 `tasks/` 文件夹；以下 `TASK-OSSX-*` 是本矩阵用于闭合治理追溯的任务锚点。若后续补充物理任务文件，必须保持这些 ID 与任务文件同步。

| Task | Closure Scope | Covered Requirements | Verification Evidence | Status |
|------|---------------|----------------------|-----------------------|--------|
| TASK-OSSX-000 | Client construction, backend selection, config validation, local-path guard, error wrapping | FR-001, BR-007, BR-010 | TC-005 plus Config Schema §11 and Error Handling §12 | Done |
| TASK-OSSX-001 | Put/Get happy path, key validation, context propagation, Content-Type opts | FR-002, FR-003, BR-001, BR-006, BR-012 | TC-001, TC-003 plus Interface Contract §9 | Done |
| TASK-OSSX-002 | Multipart threshold, part sizing, large-object upload, cancellation cleanup | FR-002, BR-002, BR-003, BR-006 | TC-002 plus Performance Budget §17 | Done |
| TASK-OSSX-003 | Delete/List behavior, idempotent delete, sorted/truncated list, local backend operations | FR-004, FR-005, BR-004, BR-008 | TC-004, TC-006, TC-007 | Done |
| TASK-OSSX-004 | Presigned URL generation, expiry validation, local URL behavior | FR-006 | TC-008 plus Security §19 | Done |
| TASK-OSSX-005 | Health, Close, idempotency, observability labels and CI gate | FR-007, FR-008, BR-005, BR-009, BR-011 | TC-009, TC-010 plus Observability §18 and CI Gate §20 | Done |

---

## 5. Coverage Dashboard

| Dimension | Coverage | Evidence |
|-----------|----------|----------|
| Functional Requirements | 8/8 FR rows mapped to AC, TC, Task, Evidence, Status | FR-001 through FR-008 in §1 |
| Business Rules | 12/12 BR rows mapped to AC, TC or CI Gate, Task, Evidence, Status | BR-001 through BR-012 in §1 |
| Acceptance Criteria | 12 AC IDs registered and reverse-linked | AC-001 through AC-012 in §2 |
| Test Cases | 10/10 SPEC test cases reverse-linked | TC-001 through TC-010 in §3 |
| Task Closure | 6/6 task anchors closed with evidence | TASK-OSSX-000 through TASK-OSSX-005 in §4 |
| CI Traceability Gate | Strict traceability check target | `TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh` |

---

## 6. Change History

| Date | Version | Change |
|------|---------|--------|
| 2026-06-12 | 2.0 | Repaired ossx matrix to cover every SPEC FR/BR with AC, TC, Task, Evidence and closed Status. |
| 2026-06-09 | 1.0 | Initial module matrix migrated from global governance traceability table. |
