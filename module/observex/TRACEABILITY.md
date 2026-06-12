# observex 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description      | Acceptance Criteria                          | Test Case / Gate | Task             | Status |
|-------------|------------------|----------------------------------------------|------------------|------------------|--------|
| FR-001      | Logger           | AC-001 | TC-001           | TASK-OBSERVEX-002 | ⬜ (2026-06-12) |
| FR-002      | Meter            | AC-002 | TC-002           | TASK-OBSERVEX-003 | ⬜ (2026-06-12) |
| FR-003      | Tracer           | AC-003 | TC-003           | TASK-OBSERVEX-004 | ⬜ (2026-06-12) |
| FR-004      | Exporter（日志导出）          | AC-004 | TC-004a  | TASK-OBSERVEX-005 | ⬜ (2026-06-12) |
| FR-004      | Exporter（指标导出）          | AC-004 | TC-004b  | TASK-OBSERVEX-005 | ⬜ (2026-06-12) |
| FR-004      | Exporter（Span 导出）         | AC-004 | TC-004c  | TASK-OBSERVEX-005 | ⬜ (2026-06-12) |
| FR-004      | Exporter（不可达降级）        | AC-004 | TC-004   | TASK-OBSERVEX-005 | ⬜ (2026-06-12) |
| FR-004      | Exporter（Shutdown 超时）     | AC-011 | CI Gate (timeout check) | TASK-OBSERVEX-005 | ⬜ (2026-06-12) |
| FR-005      | Redaction        | AC-005 | TC-005, TC-005a  | TASK-OBSERVEX-006 | ⬜ (2026-06-12) |
| FR-006      | Label Policy     | AC-006 | TC-002, TC-007a  | TASK-OBSERVEX-003b | ⬜ (2026-06-12) |
| FR-007      | Health           | AC-007 | TC-006, TC-006a  | TASK-OBSERVEX-007 | ⬜ (2026-06-12) |
| BR-001      | Logger 并发安全  | AC-008                      | CI Gate (`-race`) | TASK-OBSERVEX-002 | ⬜ (2026-06-12) |
| BR-002      | label 基数控制   | AC-009 | TC-002           | TASK-OBSERVEX-003 | ⬜ (2026-06-12) |
| BR-003      | context 传播     | AC-010 | TC-003, TC-003a           | TASK-OBSERVEX-004 | ⬜ (2026-06-12) |
| BR-004      | Shutdown flush   | AC-011 | TC-004           | TASK-OBSERVEX-005 | ⬜ (2026-06-12) |
| BR-005      | With 不变性      | AC-012 | TC-001, CI Gate (`-race`) | TASK-OBSERVEX-002 | ⬜ (2026-06-12) |
| BR-006      | 指标命名规范     | AC-013 | TC-007, CI Gate (metrics-contract-check) | TASK-OBSERVEX-003 | ⬜ (2026-06-12) |
| BR-007      | 日志 secret 脱敏 | AC-014 | TC-005, CI Gate (redaction-leak-check) | TASK-OBSERVEX-006 | ⬜ (2026-06-12) |
| BR-008      | 不直接绑定后端   | AC-015 | CI Gate (import check) | TASK-OBSERVEX-005 | ⬜ (2026-06-12) |

---
