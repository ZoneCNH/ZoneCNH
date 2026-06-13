# observex 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description      | Acceptance Criteria                          | Test Case / Gate | Task             | Status |
|-------------|------------------|----------------------------------------------|------------------|------------------|--------|
| FR-001      | Logger           | AC-001 | TC-001           | TASK-OBSERVEX-002 | ⬜ |
| FR-002      | Meter            | AC-002 | TC-002           | TASK-OBSERVEX-003 | ⬜ |
| FR-003      | Tracer           | AC-003 | TC-003           | TASK-OBSERVEX-004 | ⬜ |
| FR-004      | Exporter         | AC-004, AC-011 | TC-004, TC-009, TC-010, TC-011, TC-014 | TASK-OBSERVEX-005 | ⬜ |
| FR-005      | Redaction        | AC-005 | TC-005, TC-012  | TASK-OBSERVEX-006 | ⬜ |
| FR-006      | Label Policy     | AC-006 | TC-002, TC-015  | TASK-OBSERVEX-003b | ⬜ |
| FR-007      | Health           | AC-007 | TC-006, TC-013  | TASK-OBSERVEX-007 | ⬜ |
| BR-001      | Logger 并发安全  | AC-008                      | CI Gate (`-race`) | TASK-OBSERVEX-002 | ⬜ |
| BR-002      | label 基数控制   | AC-009 | TC-002           | TASK-OBSERVEX-003 | ⬜ |
| BR-003      | context 传播     | AC-010 | TC-003, TC-008           | TASK-OBSERVEX-004 | ⬜ |
| BR-004      | Shutdown flush   | AC-011 | TC-004           | TASK-OBSERVEX-005 | ⬜ |
| BR-005      | With 不变性      | AC-012 | TC-001, CI Gate (`-race`) | TASK-OBSERVEX-002 | ⬜ |
| BR-006      | 指标命名规范     | AC-013 | TC-007, CI Gate (metrics-contract-check) | TASK-OBSERVEX-003 | ⬜ |
| BR-007      | 日志 secret 脱敏 | AC-014 | TC-005, CI Gate (redaction-leak-check) | TASK-OBSERVEX-006 | ⬜ |
| BR-008      | 不直接绑定后端   | AC-015 | CI Gate (import check) | TASK-OBSERVEX-005 | ⬜ |

---

## §3 非功能需求追溯（NFR）

| Requirement | Description | 目标值 | 验证方式 | Task | Status |
| --- | --- | --- | --- | --- | --- |
| NFR-001 | 结构化日志写入延迟 | < 5us | Benchmark | - | Pending |
| NFR-002 | metrics 记录延迟 | < 1us | Benchmark | - | Pending |
| NFR-003 | trace span 创建+传播 | < 10us | Benchmark | - | Pending |
| NFR-004 | 常驻内存（noop模式） | < 1MB | Profiling | - | Pending |
| NFR-005 | 单元测试覆盖率 | >= 80% | go tool cover | - | Pending |
| NFR-006 | race 检测通过 | 零 data race | go test -race | - | Pending |
| NFR-007 | vet 检查通过 | 零警告 | go vet | - | Pending |
| NFR-008 | lint 检查通过 | 零错误 | golangci-lint | - | Pending |
| NFR-009 | Secret 扫描通过 | 零命中 | gitleaks | - | Pending |
| NFR-010 | 无直接依赖Prometheus/Zap | 编译期保证 | go list -deps | - | Pending |

