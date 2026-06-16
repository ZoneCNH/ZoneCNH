# testkitx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: module/testkitx/SPEC.md v1.0.0

---

## §1 功能需求追溯 (FR)

| Requirement   | Description                                   | Acceptance Criteria   | Test Case   | Task              | Status   |
| ------------- | --------------------------------------------- | --------------------- | ----------- | ----------------- | -------- |
| FR-001        | FakeConfig：内存配置源，支持测试注入          | AC-001                | TC-001      | TASK-TESTKITX-001 | ⬜        |
| FR-002        | FakeLogger：记录日志到内存供断言              | AC-002                | TC-002      | TASK-TESTKITX-002 | ⬜        |
| FR-003        | FakeMeter：记录 metrics 到内存供断言          | AC-003                | TC-003      | TASK-TESTKITX-003 | ⬜        |
| FR-004        | FakeTracer：记录 spans 到内存供断言           | AC-004                | TC-004      | TASK-TESTKITX-004 | ⬜        |
| FR-005        | FakeClock：可控制时间的时钟                   | AC-005                | TC-005      | TASK-TESTKITX-005 | ⬜        |
| FR-006        | FakeBreaker：可控制熔断状态                   | AC-006                | TC-006      | TASK-TESTKITX-005 | ⬜        |
| FR-007        | Eventually：轮询条件直到满足或超时            | AC-007                | TC-007      | TASK-TESTKITX-006 | ⬜        |
| FR-008        | GoldenUpdate：环境变量控制的 golden file 更新 | AC-008                | TC-008      | TASK-TESTKITX-007 | ⬜        |
| FR-009        | BoundaryCheck：生产包 import 边界扫描         | AC-009                | TC-009      | TASK-TESTKITX-008 | ⬜        |
| FR-010        | GoroutineLeakCheck：goroutine 泄漏检测        | AC-010                | TC-010      | TASK-TESTKITX-009 | ⬜        |

---


| Requirement   | Description                                                                 | 违反后果                                | 验证方式                                                     | Task                                                                                          | Status   |
| ------------- | --------------------------------------------------------------------------- | --------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------------------- | -------- |
| BR-001        | 所有 fake 必须实现对应接口，编译期检查 `var _ Interface = (*FakeImpl)(nil)` | fake 与真实接口脱节，contract test 失败 | CI Gate: `go build ./...`                                    | TASK-TESTKITX-001, TASK-TESTKITX-002, TASK-TESTKITX-003, TASK-TESTKITX-004, TASK-TESTKITX-005 | ⬜        |
| BR-002        | fake 行为必须确定性，不引入 `time.Now()` 或 `math.Rand()`                   | 测试不稳定，CI 随机失败                 | CI Gate: `go test -race -count=1 ./...`                      | TASK-TESTKITX-005                                                                             | ⬜        |
| BR-003        | Eventually 使用 `testing.T` 而非 `panic`，失败时输出清晰诊断                | 测试崩溃无诊断，排查困难                | TC-007                                                       | TASK-TESTKITX-006                                                                             | ⬜        |
| BR-004        | GoldenUpdate() 只在 `GOLDEN_UPDATE=1` 环境变量下返回 true                   | CI 误更新 golden 文件，golden 失效      | TC-008 + CI Gate: golden update guard                        | TASK-TESTKITX-007                                                                             | ⬜        |
| BR-005        | 生产 import graph 中不能出现 testkitx（go list 验证）                       | 生产二进制膨胀，测试工具泄露            | CI Gate: `no-production-import`                              | TASK-TESTKITX-008                                                                             | ⬜        |
| BR-006        | testkitx 是唯一允许依赖所有 Foundation L1 模块的包（仅 go test）            | 依赖图混乱，模块边界失效                | CI Gate: `go mod tidy && git diff --exit-code go.mod go.sum` | TASK-TESTKITX-000                                                                             | ⬜        |
| BR-007        | golden 文件不泄露 secret（更新时自动检查）                                  | secret 提交到仓库                       | CI Gate: `gitleaks detect --no-git`                          | TASK-TESTKITX-007                                                                             | ⬜        |

---

## §3 非功能需求追溯 (NFR)

| Requirement   | Description              | 目标值                | 验证方式                                                                                              | Task                                                                                          | Status   |
| ------------- | ------------------------ | --------------------- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | -------- |
| NFR-001       | fake 初始化性能          | < 1ms                 | Benchmark: `go test -bench=. -benchmem -count=3 ./...`                                                | TASK-TESTKITX-001, TASK-TESTKITX-002, TASK-TESTKITX-003, TASK-TESTKITX-004, TASK-TESTKITX-005 | ⬜        |
| NFR-002       | 单元测试覆盖率           | ≥ 80%                 | CI Gate: `go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | TASK-TESTKITX-001 ~ TASK-TESTKITX-010                                                         | ⬜        |
| NFR-003       | 并发安全                 | `-race` 测试通过      | CI Gate: `go test ./... -race -count=1`                                                               | TASK-TESTKITX-001 ~ TASK-TESTKITX-009                                                         | ⬜        |
| NFR-004       | 不进入生产二进制         | `go list` 无 testkitx | CI Gate: `no-production-import`                                                                       | TASK-TESTKITX-008                                                                             | ⬜        |
| NFR-005       | golden 文件不泄露 secret | gitleaks 扫描通过     | CI Gate: `gitleaks detect --no-git`                                                                   | TASK-TESTKITX-007                                                                             | ⬜        |

---

## §4 TC→FR 反向追溯

| Test Case          | 覆盖需求        | 验证机制                                            |                |
| ------------------ | --------------- | --------------------------------------------------- |                |
| TC-001             | FR-001          | `go test -run TestFakeConfig`                       |                |
| TC-002             | FR-002          | `go test -run TestFakeLogger`                       |                |
| TC-003             | FR-003          | `go test -run TestFakeMeter`                        |                |
| TC-004             | FR-004          | `go test -run TestFakeTracer`                       |                |
| TC-005             | FR-005          | `go test -run TestFakeClock`                        |                |
| TC-006             | FR-006          | `go test -run TestFakeBreaker`                      |                |
| TC-007             | FR-007, BR-003  | `go test -run TestEventually`                       |                |
| TC-008             | FR-008, BR-004  | `GOLDEN_UPDATE=1 go test -run TestGolden`           |                |
| TC-009             | FR-009, BR-005  | `go test -run TestBoundaryCheck`                    |                |
| TC-010             | FR-010          | `go test -run TestGoroutineLeakCheck`               |                |
| CI: compile        | BR-001          | `go build ./...`                                    |                |
| CI: race           | BR-002, NFR-003 | `go test ./... -race -count=1`                      |                |
| CI: golden-guard   | BR-004          | 检查 `GOLDEN_UPDATE` 不在 CI 中设置                 |                |
| CI: no-prod-import | BR-005, NFR-004 | `go list -deps ...                                  | grep testkitx` |
| CI: deps           | BR-006          | `go mod tidy && git diff --exit-code go.mod go.sum` |                |
| CI: gitleaks       | BR-007, NFR-005 | `gitleaks detect --no-git`                          |                |
| CI: coverage       | NFR-002         | `go tool cover -func=.coverage/cover.out`           |                |
| Benchmark          | NFR-001         | `go test -bench=. -benchmem -count=3 ./...`         |                |

---

## §5 全局 AC 注册表

| AC 编号   | 所属 FR/BR     | 验证标准                                                                                  | 验证方法             |
| --------- | -------------- | ----------------------------------------------------------------------------------------- | -------------------- |
| AC-001    | FR-001         | FakeConfig 实现 `configx.Reader` 接口，`Get(key)` 返回注入值，key 不存在返回 nil          | TC-001               |
| AC-002    | FR-002         | FakeLogger 实现 `observex.Logger` 接口，`AssertLogged`/`AssertNoErrors`/`Entries` 可用    | TC-002 + CI: compile |
| AC-003    | FR-003         | FakeMeter 实现 `observex.Meter` 接口，`AssertCounterValue`/`AssertHistogramRecorded` 可用 | TC-003 + CI: compile |
| AC-004    | FR-004         | FakeTracer 实现 `observex.Tracer` 接口，`AssertSpanCount`/`AssertTraceID` 可用            | TC-004 + CI: compile |
| AC-005    | FR-005         | FakeClock `Now()` 返回可控时间，`Advance(d)` 推进，`Set(t)` 设置                          | TC-005               |
| AC-006    | FR-006         | FakeBreaker 可设置 Closed/Open/Half-Open，`Execute` 受状态控制                            | TC-006               |
| AC-007    | FR-007, BR-003 | fn 在 timeout 内返回 true → 通过；超时仍 false → fail + 清晰诊断                          | TC-007               |
| AC-008    | FR-008, BR-004 | `GOLDEN_UPDATE=1` → `GoldenUpdate()` 返回 true；未设置 → false                            | TC-008               |
| AC-009    | FR-009, BR-005 | 生产包依赖 testkitx → fail + 依赖路径；不依赖 → pass                                      | TC-009               |
| AC-010    | FR-010         | 测试后无新增 goroutine → pass；有泄漏 → fail + 堆栈                                       | TC-010               |

---

## §6 覆盖率仪表盘

| 指标        | 当前值       | 目标   |
| ----------- | ------------ | ------ |
| FR 覆盖率   | 10/10 (100%) | 100%   |
| BR 覆盖率   | 7/7 (100%)   | 100%   |
| NFR 覆盖率  | 5/5 (100%)   | 100%   |
| AC 闭合率   | 10/10 (100%) | 100%   |
| TC 闭合率   | 10/10 (100%) | 100%   |
| Task 映射率 | 11/11 (100%) | 100%   |

---

## §7 变更历史

| 日期       | 变更内容                                                                                           | 作者    |
| ---------- | -------------------------------------------------------------------------------------------------- | ------- |
| 2026-06-09 | 初始版本（迁移自全局矩阵）                                                                         | ZoneCNH |
| 2026-06-12 | v1.1 完整重写：补 Task 列、补 BR-003/004/006/007、新增 NFR 表、新增 AC 注册表、新增 TC→FR 反向追溯 | ZoneCNH |
