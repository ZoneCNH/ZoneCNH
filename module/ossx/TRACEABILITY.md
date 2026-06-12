# ossx Traceability Matrix

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | Construction and config without direct configx dependency | Config validates; plain structs/options accepted; no configx imports | TC-001, TC-002, TC-013 | TASK-OSSX-000 | Pending |
| FR-002 | Object key, metadata, tags, and checksum model | Unsafe keys rejected; metadata round trips; checksum enum deterministic | TC-003, TC-008, TC-013 | TASK-OSSX-001 | Pending |
| FR-003 | Put/Get/Delete/Copy/Head/Exists/List operations | Typed errors; bounded pages; idempotent delete semantics | TC-004, TC-013 | TASK-OSSX-002 | Pending |
| FR-004 | Streaming upload and download | Cancellation honored; close errors surfaced; large payload streaming verified | TC-005, TC-013 | TASK-OSSX-002 | Pending |
| FR-005 | Multipart lifecycle | Part validation; idempotent abort; complete verifies required parts | TC-006, TC-013 | TASK-OSSX-003 | Pending |
| FR-006 | Presigned URL policy | TTL <= 15m; allowlisted ops; secrets masked | TC-007, TC-013 | TASK-OSSX-004 | Pending |
| FR-007 | Checksum, lifecycle, and permission policy validation | Unsupported algorithms and invalid policies fail before adapter calls | TC-008, TC-013 | TASK-OSSX-001 | Pending |
| FR-008 | Adapter SPI and S3-compatible adapter | Public API has no SDK types; adapter translates provider errors | TC-009, TC-010, TC-013 | TASK-OSSX-005 | Pending |
| FR-009 | Observability and audit hooks | Metrics/traces/audit emitted via hooks; secrets excluded; no-op supported | TC-011, TC-013 | TASK-OSSX-006 | Pending |
| FR-010 | Health, lifecycle, and graceful close | Health states distinguish causes; Close idempotent; readiness probe policy respected | TC-012, TC-013 | TASK-OSSX-006 | Pending |
| BR-001 | Public operations accept context | Interface review and tests cover context on operations | TC-004, TC-005 | TASK-OSSX-002 | Pending |
| BR-002 | No direct configx dependency | Dependency guard checks imports | TC-001 | TASK-OSSX-000 | Pending |
| BR-003 | Kernel-only lifecycle/error primitives | Public error and lifecycle review uses approved boundaries | TC-004, TC-012 | TASK-OSSX-002, TASK-OSSX-006 | Pending |
| BR-004 | Observex interface-only hooks | Hook contracts avoid concrete observex runtime coupling | TC-011 | TASK-OSSX-006 | Pending |
| BR-005 | No business/L2.5/other storage extension dependencies | Dependency guard rejects forbidden module imports | TC-001 | TASK-OSSX-000 | Pending |
| BR-006 | Bounded list pages | List contract tests validate max page size and continuation tokens | TC-004 | TASK-OSSX-002 | Pending |
| BR-007 | Multipart validation and idempotent abort | Multipart contract tests cover abort and complete checks | TC-006 | TASK-OSSX-003 | Pending |
| BR-008 | Presign TTL and allowlist | Presign tests enforce max TTL and configured operations | TC-007 | TASK-OSSX-004 | Pending |
| BR-009 | No secrets in logs/traces | Audit and observability tests assert masking | TC-007, TC-011 | TASK-OSSX-004, TASK-OSSX-006 | Pending |
| BR-010 | Checksum mismatch typed error and cleanup | Policy tests assert typed error and temp-state cleanup | TC-008 | TASK-OSSX-001 | Pending |
| BR-011 | No SDK types in public API | Adapter SPI tests and API review verify boundary | TC-009, TC-010 | TASK-OSSX-005 | Pending |
| BR-012 | Acceptance checks have validation/evidence | Traceability and task validation commands are recorded | TC-013 | TASK-OSSX-000, TASK-OSSX-006 | Pending |
