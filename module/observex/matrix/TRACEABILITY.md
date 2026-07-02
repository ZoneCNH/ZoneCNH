# observex 需求追溯矩阵

> 更新：2026-06-29
> 来源：module/observex/SPEC.md v1.0.1
> 规范：docs/governance/TRACEABILITY.md

Last-Updated: 2026-06-30

---

## §1 功能需求追溯（FR）

| FR ID | Requirement | AC ID(s) | TC ID(s) | Task | Verification | Status |
| ----- | ----------- | -------- | -------- | ---- | ------------ | ------ |
| FR-001 | Logger — Info/Debug/With 调用，输出结构化 JSON，level 过滤正确，With 返回新实例不变，并发无 data race | AC-001 | TC-001 | TASK-OBSERVEX-001 | `go test ./... -run TestLogger` | ✅ |
| FR-002 | Meter — Counter/Histogram/Gauge 记录正确，ForbiddenLabels 拒绝并返回 ErrLabelForbidden | AC-002 | TC-002 | TASK-OBSERVEX-002 | `go test ./... -run TestMeter` | ✅ |
| FR-003 | Tracer — Start/End/RecordError，span 创建/结束正确，子 span 继承 trace_id，跨 goroutine 上下文传播 | AC-003 | TC-003 | TASK-OBSERVEX-003 | `go test ./... -run TestTracer` | ✅ |
| FR-004 | Exporter — ExportLogs/Metrics/Spans/Shutdown，正常导出返回 nil，不可达时返回错误不 panic，Shutdown flush 缓冲区 | AC-004, AC-011 | TC-004, TC-009, TC-010, TC-011, TC-014 | TASK-OBSERVEX-004 | `go test ./... -run TestExporter` | ✅ |
| FR-005 | Redaction — 字段名匹配 secret 模式，值替换为 ***，嵌套 map 递归脱敏，redact.Check 检测泄露 | AC-005 | TC-005, TC-012 | TASK-OBSERVEX-005 | `go test ./... -run TestRedaction` | ✅ |
| FR-006 | Label Policy — label 在 Allowed/Forbidden 列表，AllowedLabels 通过，ForbiddenLabels 拒绝，独立 checker 返回正确判定 | AC-006 | TC-002, TC-015 | TASK-OBSERVEX-006 | `go test ./... -run TestLabelPolicy` | ✅ |
| FR-007 | Health — health.JSON()，已初始化输出符合 schema，未初始化 ready=false，exporter 不可达 component live=false | AC-007 | TC-006, TC-013 | TASK-OBSERVEX-007 | `go test ./... -run TestHealth` | ✅ |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Verification | Status |
| ----- | ---- | -------- | ---- | ------------ | ------ |
| BR-001 | Logger 实现必须并发安全 | — | TASK-OBSERVEX-001 | -race 测试，CI gate 阻塞，禁止合并 | ✅ |
| BR-002 | Meter 必须控制 label 基数 | TC-002 | TASK-OBSERVEX-002 | 返回 ErrLabelForbidden，指标丢弃，递增 counter | ✅ |
| BR-003 | Tracer 必须从 context 传播 trace_id / span_id | TC-003, TC-008 | TASK-OBSERVEX-003 | 创建新 trace_id，记录 warn 日志 | ✅ |
| BR-004 | Exporter.Shutdown 必须 flush 缓冲区 | TC-004 | TASK-OBSERVEX-004 | 返回 ErrShutdownFailed，写入本地退避文件 | ✅ |
| BR-005 | With 返回新实例，不修改原 Logger | TC-001 | TASK-OBSERVEX-001 | -race 测试，CI gate 阻塞 | ✅ |
| BR-006 | 指标命名符合 foundationx_<module>_<op>_<measure> | TC-007 | TASK-OBSERVEX-006 | 返回 ErrLabelForbidden，CI gate 阻塞 | ✅ |
| BR-007 | 日志 secret 字段必须自动脱敏 | TC-005 | TASK-OBSERVEX-005 | secret 值出现在日志输出，CI gate 阻塞 | ✅ |
| BR-008 | 不直接绑定 Prometheus / OTel / Zap | — | TASK-OBSERVEX-008 | CI gate 阻塞，代码审查拒绝 | ✅ |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Verification | Status |
| ------ | -------- | ----------- | ---- | ------------ | ------ |
| NFR-001 | 性能 | 结构化日志写入延迟 < 5us | TASK-OBSERVEX-008 | Benchmark | ✅ |
| NFR-002 | 性能 | metrics 记录延迟 < 1us | TASK-OBSERVEX-008 | Benchmark | ✅ |
| NFR-003 | 性能 | span 创建+结束 < 2us | TASK-OBSERVEX-008 | Benchmark | ✅ |
| NFR-004 | 性能 | 常驻内存（全量 exporter + 100 goroutine 并发写入）< 10MB | TASK-OBSERVEX-008 | Profiling | ✅ |
| NFR-005 | 质量 | 单元测试覆盖率 >= 80% | TASK-OBSERVEX-008 | `go tool cover` | ✅ |
| NFR-006 | 安全 | race 检测通过（零 data race） | TASK-OBSERVEX-008 | `go test -race` | ✅ |
| NFR-007 | 质量 | vet 检查通过（零警告） | TASK-OBSERVEX-008 | `go vet` | ✅ |
| NFR-008 | 质量 | lint 检查通过（零错误） | TASK-OBSERVEX-008 | `golangci-lint` | ✅ |
| NFR-009 | 安全 | Secret 扫描通过（零命中） | TASK-OBSERVEX-008 | `gitleaks` | ✅ |
| NFR-010 | 架构 | 无直接依赖 Prometheus / Zap | TASK-OBSERVEX-008 | `go list -deps` | ✅ |

---

## §4 TC → FR 反向追溯

| TC ID | Covers FR(s) | Command |
| ----- | ------------ | ------- |
| TC-001 | FR-001, BR-005 | `go test ./... -run TestLoggerImmutability` |
| TC-002 | FR-002, FR-006, BR-002 | `go test ./... -run TestLabelPolicy` |
| TC-003 | FR-003, BR-003 | `go test ./... -run TestTracerPropagation` |
| TC-004 | FR-004, BR-004 | `go test ./... -run TestExporterDegradation` |
| TC-005 | FR-005, BR-007 | `go test ./... -run TestRedaction` |
| TC-006 | FR-007 | `go test ./... -run TestHealthSchema` |
| TC-007 | BR-006 | `go test ./... -run TestMetricsNaming` |
| TC-008 | BR-003 | `go test ./... -run TestTracerContextLost` |
| TC-009 | FR-004 | `go test ./... -run TestExportLogs` |
| TC-010 | FR-004 | `go test ./... -run TestExportMetrics` |
| TC-011 | FR-004 | `go test ./... -run TestExportSpans` |
| TC-012 | FR-005 | `go test ./... -run TestRedactCheck` |
| TC-013 | FR-007 | `go test ./... -run TestHealthUninitialized` |
| TC-014 | FR-004 | `go test ./... -run TestExporterShutdownTimeout` |
| TC-015 | FR-006 | `go test ./... -run TestLabelPolicyChecker` |

---

## §5 全局 AC 注册表

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| ----- | --------- | --------- | ------------ | ------ |
| AC-001 | FR-001 | 所有等级输出结构化 JSON；level 过滤正确；With 不变性；并发无 data race | TC-001 | ✅ |
| AC-002 | FR-002 | Counter / Histogram / Gauge 记录正确；ForbiddenLabels 被拒绝 | TC-002 | ✅ |
| AC-003 | FR-003 | span 创建/结束正确；子 span 继承 trace_id；跨 goroutine 上下文传播 | TC-003 | ✅ |
| AC-004 | FR-004 | ExportLogs / Metrics / Spans 正常返回 nil；不可达时返回错误不 panic；Shutdown flush | TC-004, TC-009, TC-010, TC-011, TC-014 | ✅ |
| AC-005 | FR-005 | secret 字段替换为 ***；redact.Check 检测泄露 | TC-005, TC-012 | ✅ |
| AC-006 | FR-006 | AllowedLabels 通过；ForbiddenLabels 拒绝；独立 checker 正确判定 | TC-002, TC-015 | ✅ |
| AC-007 | FR-007 | 已初始化输出符合 schema；未初始化 ready=false；exporter 不可达 component live=false | TC-006, TC-013 | ✅ |
| AC-008 | BR-001 | -race 测试零 data race | CI Gate (`-race`) | ✅ |
| AC-009 | BR-002 | ForbiddenLabels 拒绝返回 ErrLabelForbidden；counter 递增 | TC-002 | ✅ |
| AC-010 | BR-003 | 跨 goroutine 保持同一 trace_id；丢失上下文创建新 trace 记录 warn | TC-003, TC-008 | ✅ |
| AC-011 | BR-004 | Shutdown 后数据已发送；超时返回 ErrShutdownFailed | TC-004, TC-014 | ✅ |
| AC-012 | BR-005 | 并发 With 后原实例不变；-race 零 data race | TC-001；CI Gate (`-race`) | ✅ |
| AC-013 | BR-006 | 不合规命名返回 ErrLabelForbidden；metrics contract check 通过 | TC-007；CI Gate (metrics-contract-check) | ✅ |
| AC-014 | BR-007 | secret 值不出现在日志输出中；redaction leak check 通过 | TC-005；CI Gate (redaction-leak-check) | ✅ |
| AC-015 | BR-008 | import graph 无直接 Prometheus / OTel / Zap 绑定；import check 通过 | CI Gate (import check) | ✅ |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 7 | 7 | 100% |
| BR | 8 | 8 | 100% |


| NFR | 10 | 10 | 100% |
| AC | 15 | 15 | 100% |
| TC | 15 | 15 | 100% |
| **合计** | **55** | **55** | **100%** |

> 说明：全部 FR/BR/NFR/AC/TC 标记 Done。Task 总数 = TASK-OBSERVEX-001~008 共 8 项。

---

## §7 变更历史

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-06-29 | v2.1 | Goal 管线对齐：§1 FR/§2 BR/§3 NFR 表新增 Task 列（TASK-OBSERVEX-001~008）；§6 覆盖率仪表盘标准化为 Done/覆盖率格式；更新 Last-Updated |
| 2026-06-16 | v2.0 | 标准化为 §1-§7 结构：拆分 FR/BR 表；新增 §4 TC→FR 反向追溯、§5 AC 注册表、§6 覆盖率仪表盘、§7 变更历史 |
| 2026-06-12 | v1.0 | 初始版本：7 FR + 8 BR + 10 NFR（迁移自 docs/governance/TRACEABILITY.md） |
