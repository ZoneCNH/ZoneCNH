# PLAN-TESTKITX-OVERVIEW

> testkitx 实现总览：架构拓扑、任务依赖图、实现阶段划分
>
> 目标 spec：`module/testkitx/SPEC.md` v1.0.0
> 追溯矩阵：`module/testkitx/TRACEABILITY.md` v1.1 (100/100)
> 任务集合：`module/testkitx/tasks/TASK-TESTKITX-000.md` ~ `-010.md` (11 个 task，全部已评分 100/100)

最后更新：2026-06-12

---

## 1. 模块定位

`testkitx` 是 Foundation L1 test-only 工具包，为所有 Foundation 模块提供统一测试基础设施：

- **Fake 实现**：FakeConfig / FakeLogger / FakeMeter / FakeTracer / FakeClock / FakeBreaker / FakeExporter
- **测试辅助**：Eventually 轮询断言、GoldenUpdate golden file 管理、BoundaryCheck 生产边界扫描、GoroutineLeakCheck goroutine 泄漏检测
- **Contract 测试**：确保 fake 实现与真实接口一致
- **硬约束**：禁止进入生产依赖图（BR-005）

---

## 2. 架构概览

```text
testkitx/
├── go.mod                          # module github.com/ZoneCNH/testkitx
├── doc.go                          # 包文档
├── errors.go                       # 公共错误定义
├── testkitx.go                     # 顶层导出
│
├── fake_config.go                  # FakeConfig: 内存配置源
├── fake_logger.go                  # FakeLoggerImpl: 日志记录 + 断言
├── fake_meter.go                   # FakeMeterImpl: metrics 记录 + 断言
├── fake_tracer.go                  # FakeTracerImpl: span 记录 + 断言
├── fake_clock.go                   # FakeClock: 可控时间
├── fake_breaker.go                 # FakeBreaker: 可控熔断状态
├── fake_exporter.go                # FakeExporterImpl: 遥测验证
│
├── assert.go                       # 统一 assert API → 被 fake_* 的断言方法引用
├── eventually.go                   # Eventually: 轮询条件断言
├── golden.go                       # GoldenUpdate: golden file 管理
├── fixture.go                      # fixture loader: JSON/golden 格式加载
├── boundary.go                     # BoundaryCheck: 生产 import 边界扫描
├── leak.go                         # GoroutineLeakCheck: goroutine 泄漏检测
├── contract.go                     # contract test harness
├── hash.go                         # contract hash helper
│
├── internal/
│   └── spy/                        # spy 实现（内部使用）
├── contract/
│   ├── logger_test.go              # TestContract_Logger_Interface
│   ├── meter_test.go               # TestContract_Meter_Interface
│   ├── tracer_test.go              # TestContract_Tracer_Interface
│   ├── config_test.go              # TestContract_Config_Reader
│   ├── breaker_test.go             # TestContract_Breaker_Interface
│   ├── concurrent_test.go          # TestContract_Logger_Concurrent
│   ├── cardinality_test.go         # TestContract_Meter_LabelCardinality
│   └── fingerprint_test.go         # TestContract_Config_Fingerprint
├── testdata/
│   └── *.golden
├── *_test.go                       # 各 fake 的单元测试
├── example_test.go                 # 组合示例
├── benchmark_test.go               # 性能基准
├── README.md                       # 模块文档
└── CHANGELOG.md                    # 变更日志
```

### 文件归属映射

| 文件 | 归属 Task | 说明 |
|------|-----------|------|
| `go.mod` | TASK-000 | 模块骨架 |
| `doc.go` | TASK-000 | 包文档 |
| `errors.go` | TASK-000 | 公共错误（所有 fake 引用） |
| `testkitx.go` | TASK-000 | 顶层导出聚合 |
| `fake_config.go` | TASK-001 | FakeConfig 实现 |
| `fake_config_test.go` | TASK-001 | FakeConfig 单元测试 |
| `fake_logger.go` | TASK-002 | FakeLoggerImpl 实现 |
| `fake_logger_test.go` | TASK-002 | FakeLoggerImpl 单元测试 |
| `fake_meter.go` | TASK-003 | FakeMeterImpl 实现 |
| `fake_meter_test.go` | TASK-003 | FakeMeterImpl 单元测试 |
| `fake_tracer.go` | TASK-004 | FakeTracerImpl 实现 |
| `fake_tracer_test.go` | TASK-004 | FakeTracerImpl 单元测试 |
| `fake_clock.go` | TASK-005 | FakeClock 实现 |
| `fake_breaker.go` | TASK-005 | FakeBreaker 实现 |
| `fake_clock_test.go` | TASK-005 | FakeClock 单元测试 |
| `fake_breaker_test.go` | TASK-005 | FakeBreaker 单元测试 |
| `fake_exporter.go` | TASK-005 | FakeExporterImpl（与 Tracer/Meter 相关） |
| `assert.go` | TASK-006 | 统一 assert API（Eventually 等引用） |
| `eventually.go` | TASK-006 | Eventually 轮询断言 |
| `eventually_test.go` | TASK-006 | Eventually 单元测试 |
| `golden.go` | TASK-007 | GoldenUpdate 实现 |
| `golden_test.go` | TASK-007 | GoldenUpdate 单元测试 |
| `fixture.go` | TASK-007 | fixture loader（与 golden 协同） |
| `boundary.go` | TASK-008 | BoundaryCheck 实现 |
| `boundary_test.go` | TASK-008 | BoundaryCheck 单元测试 |
| `leak.go` | TASK-009 | GoroutineLeakCheck 实现 |
| `leak_test.go` | TASK-009 | GoroutineLeakCheck 单元测试 |
| `contract.go` | TASK-004 | contract test harness（Tracer 后实现） |
| `hash.go` | TASK-007 | contract hash helper（golden 协同） |
| `contract/*_test.go` | TASK-004 | contract 测试用例 |
| `testdata/*.golden` | TASK-007 | golden 测试数据 |
| `example_test.go` | TASK-010 | 组合示例 |
| `benchmark_test.go` | TASK-010 | 性能基准 |
| `README.md` | TASK-010 | 模块文档 |
| `CHANGELOG.md` | TASK-010 | 变更日志 |

**文件无冲突**：所有文件由唯一的 task 负责，不存在两个 task 同时修改同一文件的情况。

---

## 3. 任务依赖拓扑 (DAG)

```text
TASK-TESTKITX-000 (骨架: go.mod, doc.go, errors.go, testkitx.go)
 │
 ├──▶ TASK-TESTKITX-001 (FakeConfig)          ──┐
 ├──▶ TASK-TESTKITX-002 (FakeLogger)          ──┤
 ├──▶ TASK-TESTKITX-003 (FakeMeter)           ──┤
 ├──▶ TASK-TESTKITX-004 (FakeTracer)          ──┤
 ├──▶ TASK-TESTKITX-005 (FakeClock+Breaker)   ──┤
 ├──▶ TASK-TESTKITX-006 (Eventually)          ──┤
 ├──▶ TASK-TESTKITX-007 (GoldenUpdate)        ──┤
 ├──▶ TASK-TESTKITX-008 (BoundaryCheck)       ──┤
 └──▶ TASK-TESTKITX-009 (GoroutineLeakCheck)  ──┤
                                                  │
                                          ┌───────┘
                                          ▼
                                 TASK-TESTKITX-010 (文档 + Release DoD)
                                          │
                                          ▼
                                    全门禁通过
```

**关键约束：**

- TASK-001~009 全部依赖 TASK-000（需要 go.mod 和公共错误定义）
- TASK-001~009 之间**相互独立**，可并行实现
- TASK-010 依赖 TASK-001~009 **全部完成**（需要所有代码就绪后才能做文档、覆盖率验证）
- TASK-004（FakeTracer）额外产出 contract test harness（`contract.go`, `contract/*_test.go`），需在所有 fake 实现后执行 contract 测试

---

## 4. 实现阶段划分

### Phase 0: 骨架 (P0)

| Task | 内容 | 文件数 | 预估 | 阻塞 |
|------|------|--------|------|------|
| TASK-000 | go.mod + doc.go + errors.go + testkitx.go | 4 | 0.5h | 无 |

**验证门禁**：`go build ./...` 编译通过

---

### Phase 1: 核心 Fake 实现 (P0)

Task 之间无依赖，可并行实现。

| Task | 内容 | FR | 文件数 | 预估 |
|------|------|-----|--------|------|
| TASK-001 | FakeConfig | FR-001 | 2 | 1h |
| TASK-002 | FakeLoggerImpl | FR-002 | 2 | 1h |
| TASK-003 | FakeMeterImpl | FR-003 | 2 | 1h |
| TASK-004 | FakeTracerImpl + contract harness | FR-004 | 2 + contract/ | 2h |
| TASK-005 | FakeClock + FakeBreaker | FR-005, FR-006 | 5 | 1h |

**验证门禁**：
- 每 task：`go test -run TestFakeXXX -race -count=1` 通过
- 编译期接口检查：`var _ Interface = (*FakeImpl)(nil)` 编译通过

---

### Phase 2: 测试辅助工具 (P0/P1)

Task 之间无依赖，可并行实现。

| Task | 内容 | FR | 优先级 | 文件数 | 预估 |
|------|------|-----|--------|--------|------|
| TASK-006 | Eventually + assert API | FR-007 | P0 | 3 | 1h |
| TASK-007 | GoldenUpdate + fixture loader | FR-008 | P1 | 4 | 1h |
| TASK-008 | BoundaryCheck | FR-009 | P1 | 2 | 1h |
| TASK-009 | GoroutineLeakCheck | FR-010 | P1 | 2 | 1h |

**验证门禁**：
- 每 task：对应 `go test -run TestXXX -race -count=1` 通过

---

### Phase 3: 文档与发布 (P1)

| Task | 内容 | 依赖 | 文件数 | 预估 |
|------|------|------|--------|------|
| TASK-010 | README + CHANGELOG + example + Release DoD | 001~009 全部 | 4 | 2h |

**验证门禁（全量 CI Gate）**：
- `go build ./...` 编译通过
- `go test ./... -race -count=1` 全部测试通过，无 data race
- `go vet ./...` 无警告
- `golangci-lint run` 无错误
- 覆盖率 >= 80%
- `go mod tidy && git diff --exit-code go.mod go.sum` 依赖整洁
- `gitleaks detect --no-git` secret 扫描通过
- `go test ./contract/... -race -count=1` contract 测试通过
- `go list -deps ... | grep testkitx` no-production-import 检查

---

## 5. 需求覆盖矩阵

| FR | 描述 | Task | 状态 |
|----|------|------|------|
| FR-001 | FakeConfig | TASK-001 | 待实现 |
| FR-002 | FakeLogger | TASK-002 | 待实现 |
| FR-003 | FakeMeter | TASK-003 | 待实现 |
| FR-004 | FakeTracer | TASK-004 | 待实现 |
| FR-005 | FakeClock | TASK-005 | 待实现 |
| FR-006 | FakeBreaker | TASK-005 | 待实现 |
| FR-007 | Eventually | TASK-006 | 待实现 |
| FR-008 | GoldenUpdate | TASK-007 | 待实现 |
| FR-009 | BoundaryCheck | TASK-008 | 待实现 |
| FR-010 | GoroutineLeakCheck | TASK-009 | 待实现 |

| BR | 描述 | 涉及 Task |
|----|------|-----------|
| BR-001 | 接口编译期检查 | TASK-001~005 |
| BR-002 | 确定性行为 | TASK-005 |
| BR-003 | Eventually 使用 testing.T | TASK-006 |
| BR-004 | GoldenUpdate 环境变量控制 | TASK-007 |
| BR-005 | 生产 import 不含 testkitx | TASK-008 |
| BR-006 | 唯一可依赖所有 L1 的包 | TASK-000 |
| BR-007 | golden 文件不泄露 secret | TASK-007 |

---

## 6. 交叉风险矩阵

| 风险 | 概率 | 影响 | 涉及 Task | 缓解措施 |
|------|------|------|-----------|----------|
| observex/configx/resiliencx 接口定义不确定 | Medium | High | 001~005 | 先阅读对应模块的 SPEC.md 和接口定义，确认方法签名 |
| Fake 接口方法遗漏 | Low | Medium | 001~005 | 编译期 `var _ Interface = (*FakeImpl)(nil)` 自动检测 |
| 并发 data race | Medium | High | 001~005 | `sync.RWMutex` / `sync.Mutex` 保护共享状态；`-race` CI gate |
| Eventually 测试不稳定（flaky） | Medium | Low | 006 | 合理默认 timeout=5s, interval=100ms；测试使用极短 timeout |
| golden file 路径错误 | Low | Low | 007 | 使用 `t.Name()` 生成路径，测试前验证文件存在 |
| BoundaryCheck 误报（自身依赖） | Low | Low | 008 | 处理自身依赖不报违规（Edge Case） |
| GoroutineLeakCheck 误报 | Low | Low | 009 | 允许少量 runtime goroutine 差异 |
| 覆盖率不达标（<80%） | Medium | Medium | 010 | 在 TASK-010 中集中补充边界场景测试 |

---

## 7. 里程碑

| 里程碑 | 完成标志 | 预估累计时间 |
|--------|----------|-------------|
| M0: 骨架就绪 | `go build ./...` 通过 | 0.5h |
| M1: 核心 Fake 就绪 | 5 个 Fake 全部通过单元测试 + 编译期检查 | 6.5h |
| M2: 辅助工具就绪 | Eventually/Golden/Boundary/Leak 全部通过测试 | 10.5h |
| M3: 发布就绪 | 全部 CI gate 通过，文档完整 | 12.5h |

---

## 8. 汇总验证命令

```bash
# Phase 0
go build ./...

# Phase 1 (per fake)
go test -run TestFakeConfig -race -count=1 ./...
go test -run TestFakeLogger -race -count=1 ./...
go test -run TestFakeMeter -race -count=1 ./...
go test -run TestFakeTracer -race -count=1 ./...
go test -run TestFakeClock -race -count=1 ./...
go test -run TestFakeBreaker -race -count=1 ./...

# Phase 2 (per helper)
go test -run TestEventually -race -count=1 ./...
go test -run TestGolden -race -count=1 ./...
go test -run TestBoundaryCheck -race -count=1 ./...
go test -run TestGoroutineLeakCheck -race -count=1 ./...

# Phase 3 (全量)
go build ./...
go test ./... -race -count=1
go vet ./...
golangci-lint run
mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out
go mod tidy && git diff --exit-code go.mod go.sum
gitleaks detect --no-git
go test ./contract/... -race -count=1
go test -bench=. -benchmem -count=3 ./...
```

---

## 9. 与 Spec/Matrix 一致性声明

- 本计划覆盖 SPEC.md 全部 10 个 FR、7 个 BR、5 个 NFR
- 不引入 SPEC.md 和 TRACEABILITY.md 之外的 Task
- 不跨模块（所有文件在 `module/testkitx/` 内）
- Task 数量 = 11，与 TRACEABILITY.md §1 FR 表 Task 列一致
- 依赖拓扑为 `TASK-000 → TASK-001~009 → TASK-010`，无循环依赖

---

## 10. 参考文件

| 文件 | 用途 |
|------|------|
| `module/testkitx/SPEC.md` | 23 节完整规格，FR/BR 定义 |
| `module/testkitx/TRACEABILITY.md` | 需求追溯矩阵 v1.1 |
| `module/testkitx/tasks/TASK-TESTKITX-*.md` | 11 个 Task spec |
| `docs/governance/TASK-TEMPLATE.md` | Task spec 模板规范 |
| `docs/governance/scoring/RUBRIC-plan.md` | Plan 阶段评分 Rubric |
| `CONSTITUTION.md` | FoundationX 最高治理文件 |
