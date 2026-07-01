# testkitx 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-30
- Module-Version: v1.0.0
- Module-State: Release Candidate — 运行时验收通过（2026-06-18）；factory=false（四源评分未达 98，见 SPEC caveat）
- Layer: L0 测试工具
- Runtime-Repo: /home/workspace/testkitx
- Source: goal.md, SPEC.md, TRACEABILITY.md, tasks/, prompt/

> 本清单用于约束 testkitx 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。
>
> **实现完成状态（2026-06-18 归档）**：10 个 FR（FR-001~010）全部有运行时代码 + 单元/契约测试覆盖；FR-007 `Eventually` 补 `eventually_test.go`（0%→100%）。BR-001~007 / NFR-001~005 由 CI testkitx-gates（no-production-import / contract / golden-update-guard / coverage-threshold / deps-tidy / gitleaks）+ `go test -race` 覆盖。全仓 build/vet/race exit=0，总覆盖率 **92.6%**。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | 只供测试使用的断言、时钟、契约、仿真与集成测试工具 |
| 文档目录 | module/testkitx |
| 运行时代码目录 | /home/workspace/testkitx |
| Go 基线 | 1.23 |
| 允许依赖 | kernel, configx, observex, resiliencx, schedulex |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | FakeConfig：内存配置源，支持测试注入 | AC-001 / TC-001 / TASK-TESTKITX-001 / ✅ | ✅ | TRACEABILITY.md |
| FR-002 | FakeLogger：记录日志到内存供断言 | AC-002 / TC-002 / TASK-TESTKITX-002 / ✅ | ✅ | TRACEABILITY.md |
| FR-003 | FakeMeter：记录 metrics 到内存供断言 | AC-003 / TC-003 / TASK-TESTKITX-003 / ✅ | ✅ | TRACEABILITY.md |
| FR-004 | FakeTracer：记录 spans 到内存供断言 | AC-004 / TC-004 / TASK-TESTKITX-004 / ✅ | ✅ | TRACEABILITY.md |
| FR-005 | FakeClock：可控制时间的时钟 | AC-005 / TC-005 / TASK-TESTKITX-005 / ✅ | ✅ | TRACEABILITY.md |
| FR-006 | FakeBreaker：可控制熔断状态 | AC-006 / TC-006 / TASK-TESTKITX-005 / ✅ | ✅ | TRACEABILITY.md |
| FR-007 | Eventually：轮询条件直到满足或超时 | AC-007 / TC-007 / TASK-TESTKITX-006 / ✅ | ✅ | TRACEABILITY.md |
| FR-008 | GoldenUpdate：环境变量控制的 golden file 更新 | AC-008 / TC-008 / TASK-TESTKITX-007 / ✅ | ✅ | TRACEABILITY.md |
| FR-009 | BoundaryCheck：生产包 import 边界扫描 | AC-009 / TC-009 / TASK-TESTKITX-008 / ✅ | ✅ | TRACEABILITY.md |
| FR-010 | GoroutineLeakCheck：goroutine 泄漏检测 | AC-010 / TC-010 / TASK-TESTKITX-009 / ✅ | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | 所有 fake 必须实现对应接口，编译期检查 var _ Interface = (*FakeImpl)(nil) | fake 与真实接口脱节，contract test 失败 / CI Gate: go build ./... / TASK-TESTKITX-001, TASK-TESTKITX-002, TASK-TESTKITX-003, TASK-TESTKITX-004, TASK-TESTKITX-005 / ✅ | ✅ | TRACEABILITY.md |
| BR-002 | fake 行为必须确定性，不引入 time.Now() 或 math.Rand() | 测试不稳定，CI 随机失败 / CI Gate: go test -race -count=1 ./... / TASK-TESTKITX-005 / ✅ | ✅ | TRACEABILITY.md |
| BR-003 | Eventually 使用 testing.T 而非 panic，失败时输出清晰诊断 | 测试崩溃无诊断，排查困难 / TC-007 / TASK-TESTKITX-006 / ✅ | ✅ | TRACEABILITY.md |
| BR-004 | GoldenUpdate() 只在 GOLDEN_UPDATE=1 环境变量下返回 true | CI 误更新 golden 文件，golden 失效 / TC-008 + CI Gate: golden update guard / TASK-TESTKITX-007 / ✅ | ✅ | TRACEABILITY.md |
| BR-005 | 生产 import graph 中不能出现 testkitx（go list 验证） | 生产二进制膨胀，测试工具泄露 / CI Gate: no-production-import / TASK-TESTKITX-008 / ✅ | ✅ | TRACEABILITY.md |
| BR-006 | testkitx 是唯一允许依赖所有 Foundation L1 模块的包（仅 go test） | 依赖图混乱，模块边界失效 / CI Gate: go mod tidy && git diff --exit-code go.mod go.sum / TASK-TESTKITX-000 / ✅ | ✅ | TRACEABILITY.md |
| BR-007 | golden 文件不泄露 secret（更新时自动检查） | secret 提交到仓库 / CI Gate: gitleaks detect --no-git / TASK-TESTKITX-007 / ✅ | ✅ | TRACEABILITY.md |
| NFR-001 | fake 初始化性能 | < 1ms / Benchmark: go test -bench=. -benchmem -count=3 ./... / TASK-TESTKITX-001, TASK-TESTKITX-002, TASK-TESTKITX-003, TASK-TESTKITX-004, TASK-TESTKITX-005 / ✅ | ✅ | TRACEABILITY.md |
| NFR-002 | 单元测试覆盖率 | ≥ 80% / CI Gate: go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out / TASK-TESTKITX-001 ~ TASK-TESTKITX-010 / ✅ | ✅ | TRACEABILITY.md |
| NFR-003 | 并发安全 | -race 测试通过 / CI Gate: go test ./... -race -count=1 / TASK-TESTKITX-001 ~ TASK-TESTKITX-009 / ✅ | ✅ | TRACEABILITY.md |
| NFR-004 | 不进入生产二进制 | go list 无 testkitx / CI Gate: no-production-import / TASK-TESTKITX-008 / ✅ | ✅ | TRACEABILITY.md |
| NFR-005 | golden 文件不泄露 secret | gitleaks 扫描通过 / CI Gate: gitleaks detect --no-git / TASK-TESTKITX-007 / ✅ | ✅ | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-TESTKITX-000 | TASK-TESTKITX-000 | module/testkitx/tasks/TASK-TESTKITX-000.md | ✅ | tasks/TASK-TESTKITX-000.md |
| TASK-TESTKITX-001 | TASK-TESTKITX-001 | module/testkitx/tasks/TASK-TESTKITX-001.md | ✅ | tasks/TASK-TESTKITX-001.md |
| TASK-TESTKITX-002 | TASK-TESTKITX-002 | module/testkitx/tasks/TASK-TESTKITX-002.md | ✅ | tasks/TASK-TESTKITX-002.md |
| TASK-TESTKITX-003 | TASK-TESTKITX-003 | module/testkitx/tasks/TASK-TESTKITX-003.md | ✅ | tasks/TASK-TESTKITX-003.md |
| TASK-TESTKITX-004 | TASK-TESTKITX-004 | module/testkitx/tasks/TASK-TESTKITX-004.md | ✅ | tasks/TASK-TESTKITX-004.md |
| TASK-TESTKITX-005 | TASK-TESTKITX-005 | module/testkitx/tasks/TASK-TESTKITX-005.md | ✅ | tasks/TASK-TESTKITX-005.md |
| TASK-TESTKITX-006 | TASK-TESTKITX-006 | module/testkitx/tasks/TASK-TESTKITX-006.md | ✅ | tasks/TASK-TESTKITX-006.md |
| TASK-TESTKITX-007 | TASK-TESTKITX-007 | module/testkitx/tasks/TASK-TESTKITX-007.md | ✅ | tasks/TASK-TESTKITX-007.md |
| TASK-TESTKITX-008 | TASK-TESTKITX-008 | module/testkitx/tasks/TASK-TESTKITX-008.md | ✅ | tasks/TASK-TESTKITX-008.md |
| TASK-TESTKITX-009 | TASK-TESTKITX-009 | module/testkitx/tasks/TASK-TESTKITX-009.md | ✅ | tasks/TASK-TESTKITX-009.md |
| TASK-TESTKITX-010 | TASK-TESTKITX-010 | module/testkitx/tasks/TASK-TESTKITX-010.md | ✅ | tasks/TASK-TESTKITX-010.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在（宽平台部分 superseded） | module/testkitx/goal.md |
| SPEC.md | 存在 | module/testkitx/SPEC.md |
| TRACEABILITY.md | 存在 | module/testkitx/TRACEABILITY.md |
| plan/ | 1 个 OVERVIEW + 11 个 PLAN 文件 | module/testkitx/plan |
| tasks/ | 11 个 Markdown 文件 | module/testkitx/tasks |
| prompt/ | 11 个 Markdown 文件 | module/testkitx/prompt |

## 6. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [x] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [x] 运行时代码仓库 /home/workspace/testkitx 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [x] 发布说明、版本标签与本目录登记状态一致。
