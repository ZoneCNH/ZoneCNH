# kernel 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.0
- Module-State: 已发布（代码侧）；代码侧验收 2026-06-18 全部通过；Factory 验收仍由 BLK-011 阻塞
- Layer: L0 基座核心
- Runtime-Repo: /home/kernel
- Source: goal.md, SPEC.md, DESIGN.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/, prompt/
- Evidence: `.config/goal/evidence/kernel-acceptance-20260618/`（test ✅ / race ✅ / vet ✅ / coverage 100% ✅ / stdlib-only ✅ / secrets ✅）

> 本清单用于约束 kernel 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。
> 当前统一口径：本清单表示代码侧 implementation/release candidate 范围；本次（2026-06-18）代码侧验收全部通过并归档于 `.config/goal/evidence/kernel-acceptance-20260618/`；Factory 验收仍需 Goal Matrix Verified、四源 98+ arbiter 归档闭合。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | 错误、生命周期、时间、ID、健康、结果类型等零依赖核心契约 |
| 文档目录 | module/kernel |
| 运行时代码目录 | /home/kernel |
| Go 基线 | 1.23 |
| 允许依赖 | 无 |
| 禁止依赖 | 禁止依赖任何本仓库其它模块或非标准库运行时依赖 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | lifecycx 组件生命周期管理：有序启动/逆序停止/失败回滚/幂等 Stop | AC-001, AC-002 / TC-001, TC-002, TC-003 / TASK-KERNEL-005 | ✅ | TRACEABILITY.md |
| FR-002 | errx 结构化错误：ErrorKind/Severity/Error 构造/IsKind 链遍历/AsError/ShouldRetry | AC-003, AC-004 / TC-004, TC-005 / TASK-KERNEL-001 | ✅ | TRACEABILITY.md |
| FR-003 | healthx 健康检查：HealthStatus 构造/IsHealthy/Aggregate 聚合规则 | AC-005 / TC-007 / TASK-KERNEL-011 | ✅ | TRACEABILITY.md |
| FR-004 | obsx 可观测抽象：Logger/Metrics/Tracer/Span 接口 + Noop 实现 + SecretString 脱敏 | AC-006, AC-007 / TC-009 / TASK-KERNEL-003 | ✅ | TRACEABILITY.md |
| FR-005 | retryx 重试策略：RetryPolicy 校验/指数退避 Delay/Jitter/ShouldRetry | AC-008 / TC-006 / TASK-KERNEL-009 | ✅ | TRACEABILITY.md |
| FR-006 | shutdownx 优雅停机：Hook LIFO 管理/NotifyContext OS 信号 | AC-009, AC-010 / TC-008, TC-016 / TASK-KERNEL-006 | ✅ | TRACEABILITY.md |
| FR-007 | timex 时钟抽象：Clock 接口/RealClock/FixedClock/FakeClock | AC-011 / TC-015 / TASK-KERNEL-002 | ✅ | TRACEABILITY.md |
| FR-008 | validx 前置条件校验：Precondition/Invariant/RequireNonEmpty | AC-012 / TC-011 / TASK-KERNEL-008 | ✅ | TRACEABILITY.md |
| FR-009 | versionx 版本信息：BuildInfo/Compatibility 匹配逻辑 | AC-013 / TC-017 / TASK-KERNEL-007 | ✅ | TRACEABILITY.md |
| FR-010 | contextx 类型安全上下文：Key[T]/WithValue/Value/DeadlineRemaining | AC-014 / TC-010 / TASK-KERNEL-010 | ✅ | TRACEABILITY.md |
| FR-011 | syncx 并发控制：SemaphoreLimiter Acquire/Release + WorkerGroup 错误收集 | AC-015, AC-016 / TC-013, TC-014 / TASK-KERNEL-004 | ✅ | TRACEABILITY.md |
| FR-012 | contracttest 契约测试辅助：AssertJSONFields/AssertErrorKind/AssertHealthStatus | AC-017 / TC-018 / TASK-KERNEL-012 | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | lifecycx: 启动顺序=注册顺序，停止=逆序 | 启动顺序错乱导致资源依赖错误 / TC-001 验证顺序断言 / TASK-KERNEL-005 | ✅ | TRACEABILITY.md |
| BR-002 | lifecycx: 启动失败必须回滚已启动 Component | 未回滚导致资源泄漏 / TC-002 验证回滚执行 / TASK-KERNEL-005 | ✅ | TRACEABILITY.md |
| BR-003 | lifecycx: 未 started 时 Stop 幂等返回 nil | 非幂等导致调用方需额外状态 / TC-003 验证幂等 / TASK-KERNEL-005 | ✅ | TRACEABILITY.md |
| BR-004 | errx: Error 必须实现 error + Unwrap 接口 | errors.Is/As 不可用 / AC-004 编译+测试验证 / TASK-KERNEL-001 | ✅ | TRACEABILITY.md |
| BR-005 | errx: IsKind/ShouldRetry 支持 errors.Join 多链 | 组合错误丢失分类 / TC-005 多链 IsKind / TASK-KERNEL-001 | ✅ | TRACEABILITY.md |
| BR-006 | obsx: 所有接口必须有 Noop 零值实现 | 消费者被迫依赖具体 SDK / AC-006 Noop 免 panic / TASK-KERNEL-003 | ✅ | TRACEABILITY.md |
| BR-007 | healthx: Metadata nil 时 JSON 序列化为 {} | JSON 契约不一致 / TC-007 MarshalJSON 验证 / TASK-KERNEL-011 | ✅ | TRACEABILITY.md |
| BR-008 | shutdownx: Hook 按 LIFO 顺序执行 | 资源释放顺序错误 / TC-008 LIFO 断言 / TASK-KERNEL-006 | ✅ | TRACEABILITY.md |
| BR-009 | kernel 不 import 任何非 stdlib 包 | 破坏 L0 定位 / TC-012 CI gate go list -deps / TASK-KERNEL-016 | ✅ | TRACEABILITY.md |
| BR-010 | contextx: Key 必须通过 NewKey 创建，零值 panic | 键冲突导致值覆盖 / TC-010 Key 唯一性测试 / TASK-KERNEL-010 | ✅ | TRACEABILITY.md |
| BR-011 | syncx: SemaphoreLimiter double-release 静默忽略 | 设计选择，简化调用方 / TC-013 双重 Release 测试 / TASK-KERNEL-004 | ✅ | TRACEABILITY.md |
| BR-012 | timex: FakeClock 零值接收者安全 | nil panic 污染测试 / TC-015 nil 调用测试 / TASK-KERNEL-002 | ✅ | TRACEABILITY.md |
| NFR-001 | errx.NewError 构造性能 | < 100ns / Benchmark BenchmarkNewError / TASK-KERNEL-001 | ✅ | TRACEABILITY.md |
| NFR-002 | errx.IsKind 5层链遍历性能 | < 1μs / Benchmark BenchmarkIsKind / TASK-KERNEL-001 | ✅ | TRACEABILITY.md |
| NFR-003 | healthx.Aggregate 10元素 | < 10μs / Benchmark BenchmarkAggregate / TASK-KERNEL-011 | ✅ | TRACEABILITY.md |
| NFR-004 | retryx.Delay 计算性能 | < 100ns / Benchmark BenchmarkDelay / TASK-KERNEL-009 | ✅ | TRACEABILITY.md |
| NFR-005 | 常驻内存（全子包导入） | < 5MB / Profiling go test -memprofile / TASK-KERNEL-016（执行: 016c） | ✅ | TRACEABILITY.md |
| NFR-006 | 核心库包测试覆盖率 | ≥ 100% / make coverage-threshold（排除 examples/scripts） / TASK-KERNEL-016（执行: 016c） | ✅ | TRACEABILITY.md |
| NFR-007 | 敏感数据不泄露到日志 | SecretString 三层保护 / TC-009 String/JSON/gob 脱敏 / TASK-KERNEL-003 | ✅ | TRACEABILITY.md |
| NFR-008 | 无硬编码密钥 | 全仓扫描零命中 / gitleaks detect --no-git / TASK-KERNEL-016（执行: 016c） | ✅ | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-KERNEL-000 | TASK-KERNEL-000 | module/kernel/tasks/TASK-KERNEL-000.md | ✅ Delivered | tasks/TASK-KERNEL-000.md |
| TASK-KERNEL-001 | TASK-KERNEL-001 | module/kernel/tasks/TASK-KERNEL-001.md | ✅ Delivered | tasks/TASK-KERNEL-001.md |
| TASK-KERNEL-002 | TASK-KERNEL-002 | module/kernel/tasks/TASK-KERNEL-002.md | ✅ Delivered | tasks/TASK-KERNEL-002.md |
| TASK-KERNEL-003 | TASK-KERNEL-003 | module/kernel/tasks/TASK-KERNEL-003.md | ✅ Delivered | tasks/TASK-KERNEL-003.md |
| TASK-KERNEL-004 | TASK-KERNEL-004 | module/kernel/tasks/TASK-KERNEL-004.md | ✅ Delivered | tasks/TASK-KERNEL-004.md |
| TASK-KERNEL-005 | TASK-KERNEL-005 | module/kernel/tasks/TASK-KERNEL-005.md | ✅ Delivered | tasks/TASK-KERNEL-005.md |
| TASK-KERNEL-006 | TASK-KERNEL-006 | module/kernel/tasks/TASK-KERNEL-006.md | ✅ Delivered | tasks/TASK-KERNEL-006.md |
| TASK-KERNEL-007 | TASK-KERNEL-007 | module/kernel/tasks/TASK-KERNEL-007.md | ✅ Delivered | tasks/TASK-KERNEL-007.md |
| TASK-KERNEL-008 | TASK-KERNEL-008 | module/kernel/tasks/TASK-KERNEL-008.md | ✅ Delivered | tasks/TASK-KERNEL-008.md |
| TASK-KERNEL-009 | TASK-KERNEL-009 | module/kernel/tasks/TASK-KERNEL-009.md | ✅ Delivered | tasks/TASK-KERNEL-009.md |
| TASK-KERNEL-010 | TASK-KERNEL-010 | module/kernel/tasks/TASK-KERNEL-010.md | ✅ Delivered | tasks/TASK-KERNEL-010.md |
| TASK-KERNEL-011 | TASK-KERNEL-011 | module/kernel/tasks/TASK-KERNEL-011.md | ✅ Delivered | tasks/TASK-KERNEL-011.md |
| TASK-KERNEL-012 | TASK-KERNEL-012 | module/kernel/tasks/TASK-KERNEL-012.md | ✅ Delivered | tasks/TASK-KERNEL-012.md |
| TASK-KERNEL-013 | TASK-KERNEL-013 | module/kernel/tasks/TASK-KERNEL-013.md | ✅ Delivered | tasks/TASK-KERNEL-013.md |
| TASK-KERNEL-014 | TASK-KERNEL-014 | module/kernel/tasks/TASK-KERNEL-014.md | ✅ Delivered | tasks/TASK-KERNEL-014.md |
| TASK-KERNEL-015 | TASK-KERNEL-015 | module/kernel/tasks/TASK-KERNEL-015.md | ✅ Delivered | tasks/TASK-KERNEL-015.md |
| TASK-KERNEL-015A | TASK-KERNEL-015a | module/kernel/tasks/TASK-KERNEL-015a.md | ✅ Delivered | tasks/TASK-KERNEL-015a.md |
| TASK-KERNEL-015B | TASK-KERNEL-015b | module/kernel/tasks/TASK-KERNEL-015b.md | ✅ Delivered | tasks/TASK-KERNEL-015b.md |
| TASK-KERNEL-015C | TASK-KERNEL-015c | module/kernel/tasks/TASK-KERNEL-015c.md | ✅ Delivered | tasks/TASK-KERNEL-015c.md |
| TASK-KERNEL-016 | TASK-KERNEL-016 | module/kernel/tasks/TASK-KERNEL-016.md | ✅ Delivered | tasks/TASK-KERNEL-016.md |
| TASK-KERNEL-016A | TASK-KERNEL-016a | module/kernel/tasks/TASK-KERNEL-016a.md | ✅ Delivered | tasks/TASK-KERNEL-016a.md |
| TASK-KERNEL-016B | TASK-KERNEL-016b | module/kernel/tasks/TASK-KERNEL-016b.md | ✅ Delivered | tasks/TASK-KERNEL-016b.md |
| TASK-KERNEL-016C | TASK-KERNEL-016c | module/kernel/tasks/TASK-KERNEL-016c.md | ✅ Delivered | tasks/TASK-KERNEL-016c.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/kernel/goal.md |
| SPEC.md | 存在 | module/kernel/SPEC.md |
| DESIGN.md | 存在 | module/kernel/DESIGN.md |
| TRACEABILITY.md | 存在 | module/kernel/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/kernel/IMPLEMENTATION-PLAN.md |
| tasks/ | 23 个 Markdown 文件 | module/kernel/tasks |
| prompt/ | 17 个 Markdown 文件 | module/kernel/prompt |

## 6. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖（2026-06-18 14 个核心库包 100.0%）。
- [x] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖（go test -race / go vet / check_secrets / stdlib-only gate）。
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC（TRACEABILITY.md v2.3）。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖（stdlib-only check passed）。
- [x] 运行时代码仓库 /home/kernel 的 lint、typecheck、test、race、`make coverage-threshold` 验证证据已归档（.config/goal/evidence/kernel-acceptance-20260618/）。
- [~] `.config/goal/evidence/kernel-acceptance-20260618/` 已归档代码侧证据；Goal Matrix Verified 与四源 98+ arbiter 仍由 .config/goal pipeline 单独执行（BLK-011 open）。
- [x] 发布说明、版本标签与本目录登记状态一致（v1.0.0 — 2026-06-12 GitHub Release）。
