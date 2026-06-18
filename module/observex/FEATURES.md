# observex 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.3.1
- Module-State: 已发布
- Layer: L0 观测
- Runtime-Repo: /home/observex
- Source: goal.md, SPEC.md, DESIGN.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/, prompt/

> 本清单用于约束 observex 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | vendor-neutral 的日志、指标、追踪与健康观测契约 |
| 文档目录 | module/observex |
| 运行时代码目录 | /home/observex |
| Go 基线 | 1.23 |
| 允许依赖 | kernel |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Logger — Info/Debug/With 调用，输出结构化 JSON，level 过滤正确，With 返回新实例不变，并发无 data race | AC-001 / TC-001 / go test ./... -run TestLogger | ✅ | TRACEABILITY.md |
| FR-002 | Meter — Counter/Histogram/Gauge 记录正确，ForbiddenLabels 拒绝并返回 ErrLabelForbidden | AC-002 / TC-002 / go test ./... -run TestMeter | ✅ | TRACEABILITY.md |
| FR-003 | Tracer — Start/End/RecordError，span 创建/结束正确，子 span 继承 trace_id，跨 goroutine 上下文传播 | AC-003 / TC-003 / go test ./... -run TestTracer | ✅ | TRACEABILITY.md |
| FR-004 | Exporter — ExportLogs/Metrics/Spans/Shutdown，正常导出返回 nil，不可达时返回错误不 panic，Shutdown flush 缓冲区 | AC-004, AC-011 / TC-004, TC-009, TC-010, TC-011, TC-014 / go test ./... -run TestExporter | ✅ | TRACEABILITY.md |
| FR-005 | Redaction — 字段名匹配 secret 模式，值替换为 ***，嵌套 map 递归脱敏，redact.Check 检测泄露 | AC-005 / TC-005, TC-012 / go test ./... -run TestRedaction | ✅ | TRACEABILITY.md |
| FR-006 | Label Policy — label 在 Allowed/Forbidden 列表，AllowedLabels 通过，ForbiddenLabels 拒绝，独立 checker 返回正确判定 | AC-006 / TC-002, TC-015 / go test ./... -run TestLabelPolicy | ✅ | TRACEABILITY.md |
| FR-007 | Health — health.JSON()，已初始化输出符合 schema，未初始化 ready=false，exporter 不可达 component live=false | AC-007 / TC-006, TC-013 / go test ./... -run TestHealth | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
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

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-OBSERVEX-000 | TASK-OBSERVEX-000 | module/observex/tasks/TASK-OBSERVEX-000.md | - | tasks/TASK-OBSERVEX-000.md |
| TASK-OBSERVEX-001 | TASK-OBSERVEX-001 | module/observex/tasks/TASK-OBSERVEX-001.md | - | tasks/TASK-OBSERVEX-001.md |
| TASK-OBSERVEX-002 | TASK-OBSERVEX-002 | module/observex/tasks/TASK-OBSERVEX-002.md | - | tasks/TASK-OBSERVEX-002.md |
| TASK-OBSERVEX-003 | TASK-OBSERVEX-003 | module/observex/tasks/TASK-OBSERVEX-003.md | - | tasks/TASK-OBSERVEX-003.md |
| TASK-OBSERVEX-003B | TASK-OBSERVEX-003b | module/observex/tasks/TASK-OBSERVEX-003b.md | - | tasks/TASK-OBSERVEX-003b.md |
| TASK-OBSERVEX-004 | TASK-OBSERVEX-004 | module/observex/tasks/TASK-OBSERVEX-004.md | - | tasks/TASK-OBSERVEX-004.md |
| TASK-OBSERVEX-005 | TASK-OBSERVEX-005 | module/observex/tasks/TASK-OBSERVEX-005.md | - | tasks/TASK-OBSERVEX-005.md |
| TASK-OBSERVEX-006 | TASK-OBSERVEX-006 | module/observex/tasks/TASK-OBSERVEX-006.md | - | tasks/TASK-OBSERVEX-006.md |
| TASK-OBSERVEX-007 | TASK-OBSERVEX-007 | module/observex/tasks/TASK-OBSERVEX-007.md | - | tasks/TASK-OBSERVEX-007.md |
| TASK-OBSERVEX-008 | TASK-OBSERVEX-008 | module/observex/tasks/TASK-OBSERVEX-008.md | - | tasks/TASK-OBSERVEX-008.md |
| TASK-OBSERVEX-009 | TASK-OBSERVEX-009 | module/observex/tasks/TASK-OBSERVEX-009.md | - | tasks/TASK-OBSERVEX-009.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/observex/goal.md |
| SPEC.md | 存在 | module/observex/SPEC.md |
| DESIGN.md | 存在 | module/observex/DESIGN.md |
| TRACEABILITY.md | 存在 | module/observex/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/observex/IMPLEMENTATION-PLAN.md |
| tasks/ | 11 个 Markdown 文件 | module/observex/tasks |
| prompt/ | 11 个 Markdown 文件 | module/observex/prompt |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/observex 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
