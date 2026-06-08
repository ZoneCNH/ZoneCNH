# resiliencx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-09
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description    | Acceptance Criteria | Test Case      | Status |
| ----------- | -------------- | ------------------- | -------------- | ------ |
| FR-001      | Timeout        | AC-001              | TC-001         | ⬜     |
| FR-002      | Retry          | AC-002              | TC-001         | ⬜     |
| FR-003      | CircuitBreaker | AC-003, AC-004      | TC-002, TC-003 | ⬜     |
| FR-004      | Bulkhead       | AC-005              | TC-004         | ⬜     |
| FR-005      | RateLimiter    | AC-006              | TC-005         | ⬜     |
| FR-006      | Fallback       | AC-007              | TC-006         | ⬜     |
| BR-004      | 熔断器并发安全 | -                   | -race test     | ⬜     |

---
