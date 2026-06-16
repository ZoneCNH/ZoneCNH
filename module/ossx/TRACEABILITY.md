# ossx Traceability Matrix

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: [module/ossx/SPEC.md](./SPEC.md) v1.0.0
Scope: Matrix repair for current `FR/BR -> AC -> TC -> Task -> Evidence -> Status` closure.

---

## 1. Requirement Traceability Matrix

| Requirement | Description | Acceptance Criteria | TC ID(s) | Task | Evidence | Status |
|-------------|-------------|---------------------|-----------|------|----------|--------|
| FR-001 | Construct BlobStore from module-owned config, adapter, and hooks without direct configx coupling | AC-001 | TC-001, TC-002 | TASK-OSSX-000 | SPEC §7 FR-001, §11 Config Schema, §15 Dependencies | Pending |
| FR-002 | Normalize object identity, metadata, content type, tags, and checksum fields | AC-002 | TC-003 | TASK-OSSX-001 | SPEC §7 FR-002, §10 Data Model | Pending |
| FR-003 | Provide Put/Get/Delete/Copy/Head/Exists/List with context cancellation and typed errors | AC-003 | TC-004 | TASK-OSSX-002 | SPEC §7 FR-003, §9 Interface Contract, §12 Error Handling | Pending |
| FR-004 | Support streaming upload/download without whole-object buffering | AC-004 | TC-005 | TASK-OSSX-002 | SPEC §7 FR-004, §17 Performance Budget | Pending |
| FR-005 | Support multipart initiate, part upload, list, complete, abort, and stale cleanup | AC-005 | TC-006 | TASK-OSSX-003 | SPEC §7 FR-005, §17 Performance Budget | Pending |
| FR-006 | Enforce presigned URL operation allowlists, TTL, checksum constraints, and audit masking | AC-006 | TC-007 | TASK-OSSX-004 | SPEC §7 FR-006, §19 Security | Pending |
| FR-007 | Validate checksum, lifecycle, retention, and permission policies before adapter calls | AC-007 | TC-008 | TASK-OSSX-001, TASK-OSSX-004 | SPEC §7 FR-007, §12 Error Handling, §19 Security | Pending |
| FR-008 | Keep adapter SPI stable and isolate S3-compatible provider behavior inside adapter packages | AC-008 | TC-009, TC-010 | TASK-OSSX-005 | SPEC §7 FR-008, §15 Dependencies | Pending |
| FR-009 | Emit metrics, traces, and audit events through injected observex-compatible hooks | AC-009 | TC-011 | TASK-OSSX-006 | SPEC §7 FR-009, §18 Observability | Pending |
| FR-010 | Provide health, readiness, and idempotent close semantics using approved lifecycle conventions | AC-010 | TC-012 | TASK-OSSX-006 | SPEC §7 FR-010, §20 CI Gate | Pending |
| BR-001 | Every public operation MUST accept context.Context or be construction-only | AC-003, AC-004, AC-010 | TC-004, TC-005, TC-012 | TASK-OSSX-002, TASK-OSSX-006 | SPEC §8 BR-001, §9 Interface Contract | Pending |
| BR-002 | ossx MUST NOT directly import or depend on configx | AC-001 | TC-001 | TASK-OSSX-000 | SPEC §8 BR-002, §11 Config Schema, §15 Dependencies | Pending |
| BR-003 | ossx MAY use kernel lifecycle and error primitives only at approved boundaries | AC-010 | TC-012 | TASK-OSSX-000, TASK-OSSX-006 | SPEC §8 BR-003, §15 Dependencies | Pending |
| BR-004 | ossx MAY use observex only through interface-oriented hooks and contracts | AC-009 | TC-011 | TASK-OSSX-006 | SPEC §8 BR-004, §18 Observability | Pending |
| BR-005 | ossx MUST NOT depend on business domains, L2.5 application code, or other storage extensions | AC-001, AC-008 | TC-001, TC-009 | TASK-OSSX-000, TASK-OSSX-005 | SPEC §8 BR-005, §15 Dependencies | Pending |
| BR-006 | List operations MUST enforce bounded page sizes and stable continuation tokens | AC-003 | TC-004 | TASK-OSSX-002 | SPEC §8 BR-006, §7 FR-003 | Pending |
| BR-007 | Multipart abort MUST be idempotent and part validation MUST happen before complete | AC-005 | TC-006 | TASK-OSSX-003 | SPEC §8 BR-007, §7 FR-005 | Pending |
| BR-008 | Presigned URL TTL MUST default to at most 15 minutes and operations MUST be allowlisted | AC-006 | TC-007 | TASK-OSSX-004 | SPEC §8 BR-008, §7 FR-006 | Pending |
| BR-009 | Secrets, credentials, signatures, and tokens MUST never be logged or traced | AC-006, AC-009 | TC-007, TC-011 | TASK-OSSX-004, TASK-OSSX-006 | SPEC §8 BR-009, §18 Observability, §19 Security | Pending |
| BR-010 | Checksum mismatch MUST return a typed error and clean temporary state when safe | AC-007 | TC-008 | TASK-OSSX-001, TASK-OSSX-004 | SPEC §8 BR-010, §12 Error Handling | Pending |
| BR-011 | Adapter-specific SDK types MUST NOT appear in public ossx APIs | AC-008 | TC-009 | TASK-OSSX-005 | SPEC §8 BR-011, §7 FR-008, §15 Dependencies | Pending |
| BR-012 | Every acceptance check MUST have a validation command or evidence note | AC-011 | TC-013 | TASK-OSSX-006 | SPEC §8 BR-012, §20 CI Gate, evidence/2026-06-12-validation.md | Pending |

---

## 2. Acceptance Criteria Registry

| AC | Covers | Verifiable Result | Evidence |
|----|--------|-------------------|----------|
| AC-001 | FR-001, BR-002, BR-005 | Construction validates module-owned config, supports nil hooks, projects `foundationx.oss` values into `ossx.Config` or options, and dependency guards reject direct `configx` or peer storage imports | TC-001, TC-002 |
| AC-002 | FR-002 | Key, metadata, content type, tag, and checksum models normalize safe values, reject unsafe values, and avoid provider header leakage | TC-003 |
| AC-003 | FR-003, BR-001, BR-006 | Basic object operations honor context cancellation, map stable typed errors, and return bounded list pages with continuation tokens | TC-004 |
| AC-004 | FR-004, BR-001 | Streaming upload and download paths avoid whole-object buffering, close resources deterministically, and surface partial read/write failures | TC-005 |
| AC-005 | FR-005, BR-007 | Multipart lifecycle validates parts and checksums, completes only valid part sets, aborts idempotently, and supports stale cleanup | TC-006 |
| AC-006 | FR-006, BR-008, BR-009 | Presigned URL generation enforces operation allowlists, maximum TTL, checksum constraints, and secret masking | TC-007 |
| AC-007 | FR-007, BR-010 | Checksum, lifecycle, retention, and permission policies reject unsupported or contradictory values before adapter calls | TC-008 |
| AC-008 | FR-008, BR-005, BR-011 | Public interfaces expose no provider SDK types, and S3-compatible behavior stays isolated in `adapters/s3` | TC-009, TC-010 |
| AC-009 | FR-009, BR-004, BR-009 | Injected hooks emit sanitized metrics, traces, and audit events; no-op hooks work; hook failures follow policy | TC-011 |
| AC-010 | FR-010, BR-001, BR-003 | Health and close use approved lifecycle conventions, distinguish readiness states, and keep close idempotent | TC-012 |
| AC-011 | BR-012 | Goal, Spec, Matrix, Plan, Task, Prompt, and Evidence artifacts trace every acceptance check and record unavailable implementation checks as not applicable | TC-013 |

---

## 3. Test Case Reverse Trace

| TC ID(s) | Validates Requirements | Primary Acceptance Criteria | Task | Evidence Source |
|-----------|------------------------|-----------------------------|------|-----------------|
| TC-001 | FR-001, BR-002, BR-005 | AC-001 | TASK-OSSX-000 | SPEC §16 dependency guard |
| TC-002 | FR-001 | AC-001 | TASK-OSSX-000 | SPEC §16 config validation |
| TC-003 | FR-002 | AC-002 | TASK-OSSX-001 | SPEC §16 key and metadata validation |
| TC-004 | FR-003, BR-001, BR-006 | AC-003 | TASK-OSSX-002 | SPEC §16 basic object operation contract |
| TC-005 | FR-004, BR-001 | AC-004 | TASK-OSSX-002 | SPEC §16 streaming behavior |
| TC-006 | FR-005, BR-007 | AC-005 | TASK-OSSX-003 | SPEC §16 multipart lifecycle |
| TC-007 | FR-006, BR-008, BR-009 | AC-006 | TASK-OSSX-004 | SPEC §16 presign policy |
| TC-008 | FR-007, BR-010 | AC-007 | TASK-OSSX-001, TASK-OSSX-004 | SPEC §16 policy validation |
| TC-009 | FR-008, BR-005, BR-011 | AC-008 | TASK-OSSX-005 | SPEC §16 adapter SPI guard |
| TC-010 | FR-008 | AC-008 | TASK-OSSX-005 | SPEC §16 S3-compatible adapter contract |
| TC-011 | FR-009, BR-004, BR-009 | AC-009 | TASK-OSSX-006 | SPEC §16 observability hooks |
| TC-012 | FR-010, BR-001, BR-003 | AC-010 | TASK-OSSX-006 | SPEC §16 health and close behavior |
| TC-013 | BR-012 | AC-011 | TASK-OSSX-006 | SPEC §16 traceability validation |

---

## 4. Task Closure Registry

> `module/ossx/tasks/` 当前包含 7 个物理任务文件。以下状态表示实现交付状态；当前分支完成治理闭合与移交准备，代码实现仍待后续任务执行。

| Task | Closure Scope | Covered Requirements | Verification Evidence | Status |
|------|---------------|----------------------|-----------------------|--------|
| TASK-OSSX-000 | Skeleton, construction, config validation, dependency guards | FR-001, BR-002, BR-003, BR-005, BR-012 | tasks/TASK-OSSX-000.md, prompt/PROMPT-OSSX-000.md, TC-001, TC-002 | Pending |
| TASK-OSSX-001 | Object identity, metadata, checksum, and policy model validation | FR-002, FR-007, BR-010 | tasks/TASK-OSSX-001.md, prompt/PROMPT-OSSX-001.md, TC-003, TC-008 | Pending |
| TASK-OSSX-002 | BlobStore basic operations, streaming, list bounds, context propagation | FR-003, FR-004, BR-001, BR-006 | tasks/TASK-OSSX-002.md, prompt/PROMPT-OSSX-002.md, TC-004, TC-005 | Pending |
| TASK-OSSX-003 | Multipart lifecycle, validation, completion, abort, stale cleanup | FR-005, BR-007 | tasks/TASK-OSSX-003.md, prompt/PROMPT-OSSX-003.md, TC-006 | Pending |
| TASK-OSSX-004 | Presigned URL and permission policy enforcement with sanitized audit evidence | FR-006, FR-007, BR-008, BR-009, BR-010 | tasks/TASK-OSSX-004.md, prompt/PROMPT-OSSX-004.md, TC-007, TC-008 | Pending |
| TASK-OSSX-005 | Adapter SPI and S3-compatible adapter isolation | FR-008, BR-005, BR-011 | tasks/TASK-OSSX-005.md, prompt/PROMPT-OSSX-005.md, TC-009, TC-010 | Pending |
| TASK-OSSX-006 | Observability, health, close, release evidence, and traceability closure | FR-009, FR-010, BR-001, BR-003, BR-004, BR-009, BR-012 | tasks/TASK-OSSX-006.md, prompt/PROMPT-OSSX-006.md, TC-011, TC-012, TC-013 | Pending |

---

## 5. Coverage Dashboard

| Dimension | Coverage | Evidence |
|-----------|----------|----------|
| Functional Requirements | 10/10 FR rows mapped to AC, TC, Task, Evidence, Status | FR-001 through FR-010 in §1 |
| Business Rules | 12/12 BR rows mapped to AC, TC, Task, Evidence, Status | BR-001 through BR-012 in §1 |
| Acceptance Criteria | 11 AC IDs registered and reverse-linked | AC-001 through AC-011 in §2 |
| Test Cases | 13/13 SPEC test cases reverse-linked | TC-001 through TC-013 in §3 |
| Task Closure | 7/7 physical task files mapped | TASK-OSSX-000 through TASK-OSSX-006 in §4 |
| CI Traceability Gate | Strict traceability check target | `TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh` |

---

## §3 非功能需求追溯（NFR）

| Requirement | Description | 目标值 | 验证方式 | Task | Status |
| --- | --- | --- | --- | --- | --- |
| NFR-001 | Put/Get 延迟（1MB） | < 50ms | Benchmark | - | Pending |
| NFR-002 | 流式上传 100MB | < 5s | Benchmark | - | Pending |
| NFR-003 | List 操作（1000 objects） | < 1s | Benchmark | - | Pending |
| NFR-004 | 常驻内存（空闲） | < 10MB | Profiling | - | Pending |
| NFR-005 | 单元测试覆盖率 | >= 80% | go tool cover | - | Pending |
| NFR-006 | race 检测通过 | 零 data race | go test -race | - | Pending |
| NFR-007 | vet 检查通过 | 零警告 | go vet | - | Pending |
| NFR-008 | lint 检查通过 | 零错误 | golangci-lint | - | Pending |
| NFR-009 | Secret 扫描通过 | 零命中 | gitleaks | - | Pending |
| NFR-010 | Adapter类型隔离 | 编译期保证 | go build | - | Pending |

## 6. Change History

| Date | Version | Change |
|------|---------|--------|
| 2026-06-12 | 2.1 | Replaced stale 8-FR matrix with current 10-FR/12-BR/13-TC/7-task handoff traceability. |
| 2026-06-12 | 2.0 | Repaired ossx matrix to cover every SPEC FR/BR with AC, TC, Task, Evidence and closed Status. |
| 2026-06-09 | 1.0 | Initial module matrix migrated from global governance traceability table. |
