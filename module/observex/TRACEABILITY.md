# observex 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-09
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description      | Acceptance Criteria         | Test Case  | Status |
| ----------- | ---------------- | --------------------------- | ---------- | ------ |
| FR-001      | Logger           | DoD: 所有 FR 有测试         | TC-001     | ⬜     |
| FR-002      | Meter            | DoD: label policy check     | TC-002     | ⬜     |
| FR-003      | Tracer           | DoD: 所有 FR 有测试         | TC-003     | ⬜     |
| FR-004      | Exporter         | DoD: 所有 FR 有测试         | TC-004     | ⬜     |
| FR-005      | Redaction        | DoD: redaction leak check   | TC-005     | ⬜     |
| FR-006      | Label Policy     | DoD: label policy check     | TC-002     | ⬜     |
| FR-007      | Health           | DoD: 所有 FR 有测试         | TC-006     | ⬜     |
| BR-001      | Logger 并发安全  | -                           | -race test | ⬜     |
| BR-005      | With 不变性      | -                           | TC-001     | ⬜     |
| BR-006      | 指标命名规范     | DoD: metrics contract check | TC-007     | ⬜     |
| BR-007      | 日志 secret 脱敏 | DoD: redaction leak check   | TC-005     | ⬜     |

---
