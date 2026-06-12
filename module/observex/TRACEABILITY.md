# observex 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description      | Acceptance Criteria                          | Test Case / Gate | Task             | Status |
|-------------|------------------|----------------------------------------------|------------------|------------------|--------|
| FR-001      | Logger           | 所有日志等级输出符合结构化格式（JSON）；level 过滤正确；With 返回新实例且原实例不变 | TC-001           | TASK-OBSERVEX-002 | ⬜     |
| FR-002      | Meter            | Counter/Histogram/Gauge 记录正确；label policy 检查集成并拒绝 ForbiddenLabels | TC-002           | TASK-OBSERVEX-003 | ⬜     |
| FR-003      | Tracer           | span 创建/结束正确；RecordError 记录错误；子 span 继承父 trace_id | TC-003           | TASK-OBSERVEX-004 | ⬜     |
| FR-004      | Exporter         | ExportLogs/Metrics/Spans 正常导出返回 nil；exporter 不可达时返回错误但不 panic；Shutdown 后 buffer 已 flush | TC-004, TC-004a  | TASK-OBSERVEX-005 | ⬜     |
| FR-005      | Redaction        | secret 字段值被替换为 `***`；redact.Check 检测文本中泄露的 secret 值 | TC-005, TC-005a  | TASK-OBSERVEX-006 | ⬜     |
| FR-006      | Label Policy     | AllowedLabels 通过；ForbiddenLabels 返回 ErrLabelForbidden；独立 checker 返回正确判定 | TC-002, TC-007a  | TASK-OBSERVEX-003 | ⬜     |
| FR-007      | Health           | 已初始化时输出符合 schema 的四字段 JSON；未初始化时输出默认健康状态；exporter 不可达时 ready=false | TC-006, TC-006a  | TASK-OBSERVEX-007 | ⬜     |
| BR-001      | Logger 并发安全  | `-race` 测试零 data race                      | CI Gate (`-race`) | TASK-OBSERVEX-002 | ⬜     |
| BR-002      | label 基数控制   | ForbiddenLabels 被拒绝并返回 ErrLabelForbidden；observex.label.forbidden counter 递增 | TC-002           | TASK-OBSERVEX-003 | ⬜     |
| BR-003      | context 传播     | 跨 goroutine 保持同一 trace_id；丢失上下文时创建新 trace 并记录 warn | TC-003           | TASK-OBSERVEX-004 | ⬜     |
| BR-004      | Shutdown flush   | Shutdown 后数据已发送；超时时返回 ErrShutdownFailed | TC-004           | TASK-OBSERVEX-005 | ⬜     |
| BR-005      | With 不变性      | 并发 With 调用后原实例不变；`-race` 测试零 data race | TC-001, CI Gate (`-race`) | TASK-OBSERVEX-002 | ⬜     |
| BR-006      | 指标命名规范     | 不合规命名返回 ErrLabelForbidden；CI Gate metrics contract check 通过 | TC-007, CI Gate (metrics-contract-check) | TASK-OBSERVEX-003 | ⬜     |
| BR-007      | 日志 secret 脱敏 | secret 值不出现在日志输出中；CI Gate redaction leak check 通过 | TC-005, CI Gate (redaction-leak-check) | TASK-OBSERVEX-006 | ⬜     |
| BR-008      | 不直接绑定后端   | import graph 中无 Prometheus/Otel/Zap 编译期绑定；CI Gate import check 通过 | CI Gate (import check) | TASK-OBSERVEX-005 | ⬜     |

---
