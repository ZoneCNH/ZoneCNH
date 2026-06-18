# observex 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.3.1
- Module-State: 已发布
- Layer: L0 观测
- Runtime-Repo: /home/observex
- Source: goal.md, SPEC.md, DESIGN.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/, prompt/

> 本清单用于验收 observex 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/observex/FEATURES.md && test -f module/observex/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/observex | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/observex && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/observex && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/observex && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/observex && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/observex && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | 所有等级输出结构化 JSON；level 过滤正确；With 不变性；并发无 data race / TC-001 | ✅ | TRACEABILITY.md |
| AC-002 | FR-002 | Counter / Histogram / Gauge 记录正确；ForbiddenLabels 被拒绝 / TC-002 | ✅ | TRACEABILITY.md |
| AC-003 | FR-003 | span 创建/结束正确；子 span 继承 trace_id；跨 goroutine 上下文传播 / TC-003 | ✅ | TRACEABILITY.md |
| AC-004 | FR-004 | ExportLogs / Metrics / Spans 正常返回 nil；不可达时返回错误不 panic；Shutdown flush / TC-004, TC-009, TC-010, TC-011, TC-014 | ✅ | TRACEABILITY.md |
| AC-005 | FR-005 | secret 字段替换为 ***；redact.Check 检测泄露 / TC-005, TC-012 | ✅ | TRACEABILITY.md |
| AC-006 | FR-006 | AllowedLabels 通过；ForbiddenLabels 拒绝；独立 checker 正确判定 / TC-002, TC-015 | ✅ | TRACEABILITY.md |
| AC-007 | FR-007 | 已初始化输出符合 schema；未初始化 ready=false；exporter 不可达 component live=false / TC-006, TC-013 | ✅ | TRACEABILITY.md |
| AC-008 | BR-001 | -race 测试零 data race / CI Gate (-race) | ✅ | TRACEABILITY.md |
| AC-009 | BR-002 | ForbiddenLabels 拒绝返回 ErrLabelForbidden；counter 递增 / TC-002 | ✅ | TRACEABILITY.md |
| AC-010 | BR-003 | 跨 goroutine 保持同一 trace_id；丢失上下文创建新 trace 记录 warn / TC-003, TC-008 | ✅ | TRACEABILITY.md |
| AC-011 | BR-004 | Shutdown 后数据已发送；超时返回 ErrShutdownFailed / TC-004, TC-014 | ✅ | TRACEABILITY.md |
| AC-012 | BR-005 | 并发 With 后原实例不变；-race 零 data race / TC-001；CI Gate (-race) | ✅ | TRACEABILITY.md |
| AC-013 | BR-006 | 不合规命名返回 ErrLabelForbidden；metrics contract check 通过 / TC-007；CI Gate (metrics-contract-check) | ✅ | TRACEABILITY.md |
| AC-014 | BR-007 | secret 值不出现在日志输出中；redaction leak check 通过 / TC-005；CI Gate (redaction-leak-check) | ✅ | TRACEABILITY.md |
| AC-015 | BR-008 | import graph 无直接 Prometheus / OTel / Zap 绑定；import check 通过 / CI Gate (import check) | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001, BR-005 | go test ./... -run TestLoggerImmutability | - | TRACEABILITY.md |
| TC-002 | FR-002, FR-006, BR-002 | go test ./... -run TestLabelPolicy | - | TRACEABILITY.md |
| TC-003 | FR-003, BR-003 | go test ./... -run TestTracerPropagation | - | TRACEABILITY.md |
| TC-004 | FR-004, BR-004 | go test ./... -run TestExporterDegradation | - | TRACEABILITY.md |
| TC-005 | FR-005, BR-007 | go test ./... -run TestRedaction | - | TRACEABILITY.md |
| TC-006 | FR-007 | go test ./... -run TestHealthSchema | - | TRACEABILITY.md |
| TC-007 | BR-006 | go test ./... -run TestMetricsNaming | - | TRACEABILITY.md |
| TC-008 | BR-003 | go test ./... -run TestTracerContextLost | - | TRACEABILITY.md |
| TC-009 | FR-004 | go test ./... -run TestExportLogs | - | TRACEABILITY.md |
| TC-010 | FR-004 | go test ./... -run TestExportMetrics | - | TRACEABILITY.md |
| TC-011 | FR-004 | go test ./... -run TestExportSpans | - | TRACEABILITY.md |
| TC-012 | FR-005 | go test ./... -run TestRedactCheck | - | TRACEABILITY.md |
| TC-013 | FR-007 | go test ./... -run TestHealthUninitialized | - | TRACEABILITY.md |
| TC-014 | FR-004 | go test ./... -run TestExporterShutdownTimeout | - | TRACEABILITY.md |
| TC-015 | FR-006 | go test ./... -run TestLabelPolicyChecker | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Logger — Info/Debug/With 调用，输出结构化 JSON，level 过滤正确，With 返回新实例不变，并发无 data race | AC-001 / TC-001 / go test ./... -run TestLogger | ✅ | TRACEABILITY.md |
| FR-002 | Meter — Counter/Histogram/Gauge 记录正确，ForbiddenLabels 拒绝并返回 ErrLabelForbidden | AC-002 / TC-002 / go test ./... -run TestMeter | ✅ | TRACEABILITY.md |
| FR-003 | Tracer — Start/End/RecordError，span 创建/结束正确，子 span 继承 trace_id，跨 goroutine 上下文传播 | AC-003 / TC-003 / go test ./... -run TestTracer | ✅ | TRACEABILITY.md |
| FR-004 | Exporter — ExportLogs/Metrics/Spans/Shutdown，正常导出返回 nil，不可达时返回错误不 panic，Shutdown flush 缓冲区 | AC-004, AC-011 / TC-004, TC-009, TC-010, TC-011, TC-014 / go test ./... -run TestExporter | ✅ | TRACEABILITY.md |
| FR-005 | Redaction — 字段名匹配 secret 模式，值替换为 ***，嵌套 map 递归脱敏，redact.Check 检测泄露 | AC-005 / TC-005, TC-012 / go test ./... -run TestRedaction | ✅ | TRACEABILITY.md |
| FR-006 | Label Policy — label 在 Allowed/Forbidden 列表，AllowedLabels 通过，ForbiddenLabels 拒绝，独立 checker 返回正确判定 | AC-006 / TC-002, TC-015 / go test ./... -run TestLabelPolicy | ✅ | TRACEABILITY.md |
| FR-007 | Health — health.JSON()，已初始化输出符合 schema，未初始化 ready=false，exporter 不可达 component live=false | AC-007 / TC-006, TC-013 / go test ./... -run TestHealth | ✅ | TRACEABILITY.md |
| BR-001 | Logger 实现必须并发安全 | — / -race 测试，CI gate 阻塞，禁止合并 | ✅ | TRACEABILITY.md |
| BR-002 | Meter 必须控制 label 基数 | TC-002 / 返回 ErrLabelForbidden，指标丢弃，递增 counter | ✅ | TRACEABILITY.md |
| BR-003 | Tracer 必须从 context 传播 trace_id / span_id | TC-003, TC-008 / 创建新 trace_id，记录 warn 日志 | ✅ | TRACEABILITY.md |
| BR-004 | Exporter.Shutdown 必须 flush 缓冲区 | TC-004 / 返回 ErrShutdownFailed，写入本地退避文件 | ✅ | TRACEABILITY.md |
| BR-005 | With 返回新实例，不修改原 Logger | TC-001 / -race 测试，CI gate 阻塞 | ✅ | TRACEABILITY.md |
| BR-006 | 指标命名符合 foundationx___ | TC-007 / 返回 ErrLabelForbidden，CI gate 阻塞 | ✅ | TRACEABILITY.md |
| BR-007 | 日志 secret 字段必须自动脱敏 | TC-005 / secret 值出现在日志输出，CI gate 阻塞 | ✅ | TRACEABILITY.md |
| BR-008 | 不直接绑定 Prometheus / OTel / Zap | — / CI gate 阻塞，代码审查拒绝 | ✅ | TRACEABILITY.md |
| NFR-001 | 性能 | 结构化日志写入延迟 < 5us / Benchmark | ✅ | TRACEABILITY.md |
| NFR-002 | 性能 | metrics 记录延迟 < 1us / Benchmark | ✅ | TRACEABILITY.md |
| NFR-003 | 性能 | trace span 创建+传播 < 10us / Benchmark | ✅ | TRACEABILITY.md |
| NFR-004 | 性能 | 常驻内存（noop 模式）< 1MB / Profiling | ✅ | TRACEABILITY.md |
| NFR-005 | 质量 | 单元测试覆盖率 >= 80% / go tool cover | ✅ | TRACEABILITY.md |
| NFR-006 | 安全 | race 检测通过（零 data race） / go test -race | ✅ | TRACEABILITY.md |
| NFR-007 | 质量 | vet 检查通过（零警告） / go vet | ✅ | TRACEABILITY.md |
| NFR-008 | 质量 | lint 检查通过（零错误） / golangci-lint | ✅ | TRACEABILITY.md |
| NFR-009 | 安全 | Secret 扫描通过（零命中） / gitleaks | ✅ | TRACEABILITY.md |
| NFR-010 | 架构 | 无直接依赖 Prometheus / Zap / go list -deps | ✅ | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/observex 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- 若 SPEC/TRACEABILITY 缺少 AC 或 TC，必须先补齐追溯矩阵，再执行发布验收。
