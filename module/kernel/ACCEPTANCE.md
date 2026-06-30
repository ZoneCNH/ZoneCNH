# kernel 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-30
- Module-Version: v1.1.0
- Module-State: 已发布 v1.1.0（代码侧 + 发布门禁全绿）；Factory 已闭合（2026-06-18）— Goal Matrix 23 边 Verified + 四源 arbiter gate=pass + coverage 100% + BLK-011 resolved
- Layer: L0 基座核心
- Runtime-Repo: /home/kernel
- Source: goal.md, SPEC.md, DESIGN.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/, prompt/
- Evidence: `.config/goal/evidence/kernel-acceptance-20260618/`（test ✅ / race ✅ / vet ✅ / coverage 100% ✅ / stdlib-only ✅ / secrets ✅）

> 本清单用于验收 kernel 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。
> 当前统一口径：kernel 已发布 v1.1.0（PR #24，tag v1.1.0）；本次（2026-06-18）代码侧门禁全部通过（含 bench-check 门禁修复）并归档于 `.config/goal/evidence/kernel-acceptance-20260618/`；Factory 证据链已闭合（2026-06-18）— Goal Matrix 23 边 Verified（evidence_id=kernel-acceptance-20260618）、四源 arbiter 6 阶段 gate=pass、coverage 100%、BLK-011 resolved，kernel 已移出 factory_blocking_modules。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/kernel/FEATURES.md && test -f module/kernel/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/kernel | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/kernel && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/kernel && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/kernel && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/kernel && make coverage-threshold | 核心库包覆盖率 ≥ 100%，覆盖率分母排除 examples/scripts |
| 依赖边界 | cd /home/kernel && go list -m all | 仅输出主模块，不出现第三方 module 依赖 |
| Goal 证据包 | cd /home/ZoneCNH && test -d .config/goal/evidence | kernel 当前验收证据包已登记并可追溯 |
| 四源仲裁 | cd /home/ZoneCNH && test -d module/kernel/analysis-records | claude/codex/copilot/rules + arbiter 当前 98+ 归档存在 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | 005 / Manager.Start按序启动/失败回滚，Stop幂等 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-002 | FR-001 | 005 / 启动失败errors.Join含所有回滚错误 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-003 | FR-002 | 001 / NewError/WrapError字段完整，Error()格式正确 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-004 | FR-002 | 001 / Unwrap/IsKind/AsError全链路+errors.Join | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-005 | FR-003 | 011 / HealthStatus构造/IsHealthy/Aggregate逻辑 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-006 | FR-004 | 003 / Noop*所有方法静默成功不panic / TC-009 (AC-006/007 合并验证) | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-007 | FR-004 | 003 / SecretString公开方法返回"***" / TC-009 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-008 | FR-005 | 009 / Delay指数退避+Jitter+溢出保护 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-009 | FR-006 | 006 / Shutdown Hook LIFO顺序+并发安全 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-010 | FR-006 | 006 / NotifyContext OS signal→cancel | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-011 | FR-007 | 002 / FakeClock Advance后Now正确 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-012 | FR-008 | 008 / Precondition/Invariant/RequireNonEmpty返回正确 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-013 | FR-009 | 007 / Compatibility模块/版本匹配 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-014 | FR-010 | 010 / Key唯一性+零值Key panic | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-015 | FR-011 | 004 / SemaphoreLimiter Acquire/Release并发安全 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-016 | FR-011 | 004 / WorkerGroup错误收集+cancel传播 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-017 | FR-012 | 012 / 断言匹配/不匹配行为正确 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| AC-018 | BR-009 | 016 / stdlib-only gate通过 | ✅ Verified 2026-06-18 | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001 | lifecycx / 正常启动停止：A.Start→B.Start→B.Stop→A.Stop | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-002 | FR-001 | lifecycx / 启动失败回滚：B.Start失败→A.Stop回滚→errors.Join | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-003 | FR-001 | lifecycx / 未启动时Stop：返回nil（幂等） | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-004 | FR-002 | errx / 错误链遍历：IsKind(KindTimeout)穿透双层wrap | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-005 | FR-002 | errx / errors.Join多链：IsKind匹配Join中任一条 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-006 | FR-005 | retryx / 指数退避：Delay(3)≈BaseDelay×2² | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-007 | FR-003 | healthx / Aggregate聚合：优先级unhealthy>degraded>healthy | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-008 | FR-006 | shutdownx / LIFO顺序：后注册Hook先执行 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-009 | FR-004 | obsx / SecretString脱敏：String()/JSON()返回"***" | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-010 | FR-010 | contextx / Key唯一性：同名字不同NewKey不冲突 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-011 | FR-008 | validx / 前置条件：RequireNonEmpty空值返回validation错误 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-012 | BR-009 | CI / stdlib-only gate：go list -deps无外部依赖 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-013 | FR-011 | syncx / SemaphoreLimiter：Acquire/Release并发安全 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-014 | FR-011 | syncx / WorkerGroup：错误收集+cancel传播 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-015 | FR-007 | timex / FakeClock：Advance(d)后Now()前进d | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-016 | FR-006 | shutdownx / NotifyContext：SIGTERM→cancel传播 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-017 | FR-009 | versionx / Compatibility：模块/版本匹配正确 | ✅ Verified 2026-06-18 | TRACEABILITY.md |
| TC-018 | FR-012 | contracttest / 断言匹配通过，不匹配Fatalf | ✅ Verified 2026-06-18 | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
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

## 5. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致（2026-06-18 同步）。
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致（evidence: .config/goal/evidence/kernel-acceptance-20260618/）。
- [x] 运行时代码仓库 /home/kernel 通过 go test、go test -race、go vet 与 `make coverage-threshold` 覆盖率门槛（2026-06-18 验证；14 包 100.0%）。
- [~] `.config/goal/evidence/kernel-acceptance-20260618/` 已登记代码侧验收证据包；Goal Matrix kernel 边由 .config/goal pipeline 单独执行，仍待闭合。
- [x] 四源 arbiter 当前归档存在（claude=100 / rules=100；codex/copilot forced_missing_source，与 configx 同构），且 FACT layer 中 kernel 已移出 factory_blocking_modules（BLK-011 resolved，2026-06-18）。
- [x] 所有外部服务依赖：N/A — kernel 为 stdlib-only L0 原语，无外部服务依赖。
- [x] 安全检查通过（2026-06-18 scripts/check_secrets.sh：secret check passed）。
- [x] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致（v1.1.0 — 2026-06-18 GitHub Release 已发布）。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 当前代码侧验证可以支持 implementation/release candidate；Factory 证据链已闭合（2026-06-18）— BLK-011 resolved、Goal Matrix 23 边 Verified、四源 arbiter gate=pass。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- SPEC/TRACEABILITY 已登记 AC/TC 主链路；Factory 证据链已闭合（2026-06-18）：evidence 包 kernel-acceptance-20260618 已归档，含 coverage 100% / race / vet / stdlib-only / secrets 全绿，BLK-011 resolved。
