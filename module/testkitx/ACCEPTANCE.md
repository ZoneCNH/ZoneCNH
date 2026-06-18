# testkitx 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.0
- Module-State: Release Candidate（门禁未达 98，factory=false；见 SPEC caveat）
- Layer: L0 测试工具
- Runtime-Repo: /home/testkitx
- Source: goal.md, SPEC.md, TRACEABILITY.md, tasks/, prompt/

> 本清单用于验收 testkitx 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/testkitx/FEATURES.md && test -f module/testkitx/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/testkitx | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/testkitx && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/testkitx && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/testkitx && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/testkitx && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/testkitx && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | FakeConfig 实现 configx.Reader 接口，Get(key) 返回注入值，key 不存在返回 nil / TC-001 | - | TRACEABILITY.md |
| AC-002 | FR-002 | FakeLogger 实现 observex.Logger 接口，AssertLogged/AssertNoErrors/Entries 可用 / TC-002 + CI: compile | - | TRACEABILITY.md |
| AC-003 | FR-003 | FakeMeter 实现 observex.Meter 接口，AssertCounterValue/AssertHistogramRecorded 可用 / TC-003 + CI: compile | - | TRACEABILITY.md |
| AC-004 | FR-004 | FakeTracer 实现 observex.Tracer 接口，AssertSpanCount/AssertTraceID 可用 / TC-004 + CI: compile | - | TRACEABILITY.md |
| AC-005 | FR-005 | FakeClock Now() 返回可控时间，Advance(d) 推进，Set(t) 设置 / TC-005 | - | TRACEABILITY.md |
| AC-006 | FR-006 | FakeBreaker 可设置 Closed/Open/Half-Open，Execute 受状态控制 / TC-006 | - | TRACEABILITY.md |
| AC-007 | FR-007, BR-003 | fn 在 timeout 内返回 true → 通过；超时仍 false → fail + 清晰诊断 / TC-007 | - | TRACEABILITY.md |
| AC-008 | FR-008, BR-004 | GOLDEN_UPDATE=1 → GoldenUpdate() 返回 true；未设置 → false / TC-008 | - | TRACEABILITY.md |
| AC-009 | FR-009, BR-005 | 生产包依赖 testkitx → fail + 依赖路径；不依赖 → pass / TC-009 | - | TRACEABILITY.md |
| AC-010 | FR-010 | 测试后无新增 goroutine → pass；有泄漏 → fail + 堆栈 / TC-010 | - | TRACEABILITY.md |
| AC-TKX-001 | FR-001 | FakeConfig(values) 返回 configx.Reader；Get(key) 返回对应值；key 不存在返回 nil | - | SPEC.md |
| AC-TKX-002 | FR-002 | FakeLogger() 返回 (*FakeLoggerImpl, observex.Logger)；AssertLogged 断言指定 level 包含文本；AssertNoErrors 断言无 Error 日志；Entries 返回全部条目 | - | SPEC.md |
| AC-TKX-003 | FR-003 | FakeMeter() 返回 (*FakeMeterImpl, observex.Meter)；AssertCounterValue 断言计数器值；AssertHistogramRecorded 断言直方图有记录 | - | SPEC.md |
| AC-TKX-004 | FR-004 | FakeTracer() 返回 (*FakeTracerImpl, observex.Tracer)；AssertSpanCount 断言 span 数量；AssertTraceID 断言 trace_id 已传播 | - | SPEC.md |
| AC-TKX-005 | FR-005 | FakeClock(at) Now() 返回 at；Advance(d) 后 Now() 返回 at+d；Set(t) 后 Now() 返回 t | - | SPEC.md |
| AC-TKX-006 | FR-006 | FakeBreaker(initial) 返回 resiliencx.Breaker，状态为 initial | - | SPEC.md |
| AC-TKX-007 | FR-007 | Eventually 在 timeout 内 fn 返回 true 则测试通过；超时仍 false 则测试失败并输出诊断 | - | SPEC.md |
| AC-TKX-008 | FR-008 | GOLDEN_UPDATE=1 时 GoldenUpdate() 返回 true；未设置时返回 false | - | SPEC.md |
| AC-TKX-009 | FR-009 | BoundaryCheck 检测到生产包依赖 testkitx 时测试失败报告路径；无依赖时通过 | - | SPEC.md |
| AC-TKX-010 | FR-010 | GoroutineLeakCheck 检测到泄漏时失败报告堆栈；无泄漏时通过 | - | SPEC.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001 | go test -run TestFakeConfig | - | TRACEABILITY.md |
| TC-002 | FR-002 | go test -run TestFakeLogger | - | TRACEABILITY.md |
| TC-003 | FR-003 | go test -run TestFakeMeter | - | TRACEABILITY.md |
| TC-004 | FR-004 | go test -run TestFakeTracer | - | TRACEABILITY.md |
| TC-005 | FR-005 | go test -run TestFakeClock | - | TRACEABILITY.md |
| TC-006 | FR-006 | go test -run TestFakeBreaker | - | TRACEABILITY.md |
| TC-007 | FR-007, BR-003 | go test -run TestEventually | - | TRACEABILITY.md |
| TC-008 | FR-008, BR-004 | GOLDEN_UPDATE=1 go test -run TestGolden | - | TRACEABILITY.md |
| TC-009 | FR-009, BR-005 | go test -run TestBoundaryCheck | - | TRACEABILITY.md |
| TC-010 | FR-010 | go test -run TestGoroutineLeakCheck | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | FakeConfig：内存配置源，支持测试注入 | AC-001 / TC-001 / TASK-TESTKITX-001 / ⬜ | - | TRACEABILITY.md |
| FR-002 | FakeLogger：记录日志到内存供断言 | AC-002 / TC-002 / TASK-TESTKITX-002 / ⬜ | - | TRACEABILITY.md |
| FR-003 | FakeMeter：记录 metrics 到内存供断言 | AC-003 / TC-003 / TASK-TESTKITX-003 / ⬜ | - | TRACEABILITY.md |
| FR-004 | FakeTracer：记录 spans 到内存供断言 | AC-004 / TC-004 / TASK-TESTKITX-004 / ⬜ | - | TRACEABILITY.md |
| FR-005 | FakeClock：可控制时间的时钟 | AC-005 / TC-005 / TASK-TESTKITX-005 / ⬜ | - | TRACEABILITY.md |
| FR-006 | FakeBreaker：可控制熔断状态 | AC-006 / TC-006 / TASK-TESTKITX-005 / ⬜ | - | TRACEABILITY.md |
| FR-007 | Eventually：轮询条件直到满足或超时 | AC-007 / TC-007 / TASK-TESTKITX-006 / ⬜ | - | TRACEABILITY.md |
| FR-008 | GoldenUpdate：环境变量控制的 golden file 更新 | AC-008 / TC-008 / TASK-TESTKITX-007 / ⬜ | - | TRACEABILITY.md |
| FR-009 | BoundaryCheck：生产包 import 边界扫描 | AC-009 / TC-009 / TASK-TESTKITX-008 / ⬜ | - | TRACEABILITY.md |
| FR-010 | GoroutineLeakCheck：goroutine 泄漏检测 | AC-010 / TC-010 / TASK-TESTKITX-009 / ⬜ | - | TRACEABILITY.md |
| BR-001 | 所有 fake 必须实现对应接口，编译期检查 var _ Interface = (*FakeImpl)(nil) | fake 与真实接口脱节，contract test 失败 / CI Gate: go build ./... / TASK-TESTKITX-001, TASK-TESTKITX-002, TASK-TESTKITX-003, TASK-TESTKITX-004, TASK-TESTKITX-005 / ⬜ | - | TRACEABILITY.md |
| BR-002 | fake 行为必须确定性，不引入 time.Now() 或 math.Rand() | 测试不稳定，CI 随机失败 / CI Gate: go test -race -count=1 ./... / TASK-TESTKITX-005 / ⬜ | - | TRACEABILITY.md |
| BR-003 | Eventually 使用 testing.T 而非 panic，失败时输出清晰诊断 | 测试崩溃无诊断，排查困难 / TC-007 / TASK-TESTKITX-006 / ⬜ | - | TRACEABILITY.md |
| BR-004 | GoldenUpdate() 只在 GOLDEN_UPDATE=1 环境变量下返回 true | CI 误更新 golden 文件，golden 失效 / TC-008 + CI Gate: golden update guard / TASK-TESTKITX-007 / ⬜ | - | TRACEABILITY.md |
| BR-005 | 生产 import graph 中不能出现 testkitx（go list 验证） | 生产二进制膨胀，测试工具泄露 / CI Gate: no-production-import / TASK-TESTKITX-008 / ⬜ | - | TRACEABILITY.md |
| BR-006 | testkitx 是唯一允许依赖所有 Foundation L1 模块的包（仅 go test） | 依赖图混乱，模块边界失效 / CI Gate: go mod tidy && git diff --exit-code go.mod go.sum / TASK-TESTKITX-000 / ⬜ | - | TRACEABILITY.md |
| BR-007 | golden 文件不泄露 secret（更新时自动检查） | secret 提交到仓库 / CI Gate: gitleaks detect --no-git / TASK-TESTKITX-007 / ⬜ | - | TRACEABILITY.md |
| NFR-001 | fake 初始化性能 | < 1ms / Benchmark: go test -bench=. -benchmem -count=3 ./... / TASK-TESTKITX-001, TASK-TESTKITX-002, TASK-TESTKITX-003, TASK-TESTKITX-004, TASK-TESTKITX-005 / ⬜ | - | TRACEABILITY.md |
| NFR-002 | 单元测试覆盖率 | ≥ 80% / CI Gate: go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out / TASK-TESTKITX-001 ~ TASK-TESTKITX-010 / ⬜ | - | TRACEABILITY.md |
| NFR-003 | 并发安全 | -race 测试通过 / CI Gate: go test ./... -race -count=1 / TASK-TESTKITX-001 ~ TASK-TESTKITX-009 / ⬜ | - | TRACEABILITY.md |
| NFR-004 | 不进入生产二进制 | go list 无 testkitx / CI Gate: no-production-import / TASK-TESTKITX-008 / ⬜ | - | TRACEABILITY.md |
| NFR-005 | golden 文件不泄露 secret | gitleaks 扫描通过 / CI Gate: gitleaks detect --no-git / TASK-TESTKITX-007 / ⬜ | - | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/testkitx 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- 若 SPEC/TRACEABILITY 缺少 AC 或 TC，必须先补齐追溯矩阵，再执行发布验收。
