# kernel 需求追溯矩阵

> 更新：2026-06-12（Matrix v2.1 — 完整 7 列矩阵）
> 来源：module/kernel/SPEC.md v2.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | lifecycx 组件生命周期管理：有序启动/逆序停止/失败回滚/幂等 Stop | AC-001, AC-002 | TC-001, TC-002, TC-003 | TASK-KERNEL-005 | ✅ 已对齐 |
| FR-002 | errx 结构化错误：ErrorKind/Severity/Error 构造/IsKind 链遍历/AsError/ShouldRetry | AC-003, AC-004 | TC-004, TC-005 | TASK-KERNEL-001 | ✅ 已对齐 |
| FR-003 | healthx 健康检查：HealthStatus 构造/IsHealthy/Aggregate 聚合规则 | AC-005 | TC-007 | TASK-KERNEL-011 | ✅ 已对齐 |
| FR-004 | obsx 可观测抽象：Logger/Metrics/Tracer/Span 接口 + Noop 实现 + SecretString 脱敏 | AC-006, AC-007 | TC-009 | TASK-KERNEL-003 | ✅ 已对齐 |
| FR-005 | retryx 重试策略：RetryPolicy 校验/指数退避 Delay/Jitter/ShouldRetry | AC-008 | TC-006 | TASK-KERNEL-009 | ✅ 已对齐 |
| FR-006 | shutdownx 优雅停机：Hook LIFO 管理/NotifyContext OS 信号 | AC-009, AC-010 | TC-008, TC-016 | TASK-KERNEL-006 | ✅ 已对齐 |
| FR-007 | timex 时钟抽象：Clock 接口/RealClock/FixedClock/FakeClock | AC-011 | TC-015 | TASK-KERNEL-002 | ✅ 已对齐 |
| FR-008 | validx 前置条件校验：Precondition/Invariant/RequireNonEmpty | AC-012 | TC-011 | TASK-KERNEL-008 | ✅ 已对齐 |
| FR-009 | versionx 版本信息：BuildInfo/Compatibility 匹配逻辑 | AC-013 | TC-017 | TASK-KERNEL-007 | ✅ 已对齐 |
| FR-010 | contextx 类型安全上下文：Key[T]/WithValue/Value/DeadlineRemaining | AC-014 | TC-010 | TASK-KERNEL-010 | ✅ 已对齐 |
| FR-011 | syncx 并发控制：SemaphoreLimiter Acquire/Release + WorkerGroup 错误收集 | AC-015, AC-016 | TC-013, TC-014 | TASK-KERNEL-004 | ✅ 已对齐 |
| FR-012 | contracttest 契约测试辅助：AssertJSONFields/AssertErrorKind/AssertHealthStatus | AC-017 | TC-018 | TASK-KERNEL-012 | ✅ 已对齐 |

---

## 2. 业务规则追溯（BR）

| BR | Description | 违反后果 | 验证方式 | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | lifecycx: 启动顺序=注册顺序，停止=逆序 | 启动顺序错乱导致资源依赖错误 | TC-001 验证顺序断言 | TASK-KERNEL-005 | ✅ |
| BR-002 | lifecycx: 启动失败必须回滚已启动 Component | 未回滚导致资源泄漏 | TC-002 验证回滚执行 | TASK-KERNEL-005 | ✅ |
| BR-003 | lifecycx: 未 started 时 Stop 幂等返回 nil | 非幂等导致调用方需额外状态 | TC-003 验证幂等 | TASK-KERNEL-005 | ✅ |
| BR-004 | errx: Error 必须实现 error + Unwrap 接口 | errors.Is/As 不可用 | AC-004 编译+测试验证 | TASK-KERNEL-001 | ✅ |
| BR-005 | errx: IsKind/ShouldRetry 支持 errors.Join 多链 | 组合错误丢失分类 | TC-005 多链 IsKind | TASK-KERNEL-001 | ✅ |
| BR-006 | obsx: 所有接口必须有 Noop 零值实现 | 消费者被迫依赖具体 SDK | AC-006 Noop 免 panic | TASK-KERNEL-003 | ✅ |
| BR-007 | healthx: Metadata nil 时 JSON 序列化为 {} | JSON 契约不一致 | TC-007 MarshalJSON 验证 | TASK-KERNEL-011 | ✅ |
| BR-008 | shutdownx: Hook 按 LIFO 顺序执行 | 资源释放顺序错误 | TC-008 LIFO 断言 | TASK-KERNEL-006 | ✅ |
| BR-009 | kernel 不 import 任何非 stdlib 包 | 破坏 L0 定位 | TC-012 CI gate `go list -deps` | TASK-KERNEL-016 | ✅ |
| BR-010 | contextx: Key 必须通过 NewKey 创建，零值 panic | 键冲突导致值覆盖 | TC-010 Key 唯一性测试 | TASK-KERNEL-010 | ✅ |
| BR-011 | syncx: SemaphoreLimiter double-release 静默忽略 | 设计选择，简化调用方 | TC-013 双重 Release 测试 | TASK-KERNEL-004 | ✅ |
| BR-012 | timex: FakeClock 零值接收者安全 | nil panic 污染测试 | TC-015 nil 调用测试 | TASK-KERNEL-002 | ✅ |

---

## 3. 非功能需求追溯（NFR）

| NFR | Description | 目标值 | 验证方式 | Task | Status |
|-----|-------------|--------|----------|------|--------|
| NFR-001 | errx.NewError 构造性能 | < 100ns | Benchmark `BenchmarkNewError` | TASK-KERNEL-001 | ✅ |
| NFR-002 | errx.IsKind 5层链遍历性能 | < 1μs | Benchmark `BenchmarkIsKind` | TASK-KERNEL-001 | ✅ |
| NFR-003 | healthx.Aggregate 10元素 | < 10μs | Benchmark `BenchmarkAggregate` | TASK-KERNEL-011 | ✅ |
| NFR-004 | retryx.Delay 计算性能 | < 100ns | Benchmark `BenchmarkDelay` | TASK-KERNEL-009 | ✅ |
| NFR-005 | 常驻内存（全子包导入） | < 5MB | Profiling `go test -memprofile` | TASK-KERNEL-016 | ✅ |
| NFR-006 | 测试覆盖率 | ≥ 100% | `go tool cover -func` | TASK-KERNEL-016 | ✅ |
| NFR-007 | 敏感数据不泄露到日志 | SecretString 三层保护 | TC-009 String/JSON/gob 脱敏 | TASK-KERNEL-003 | ✅ |
| NFR-008 | 无硬编码密钥 | 全仓扫描零命中 | `gitleaks detect --no-git` | TASK-KERNEL-016 | ✅ |

---

## 4. TC → FR 反向追溯

| TC | FR/BR | 子包 | Given/When/Then 场景 |
|----|-------|------|----------------------|
| TC-001 | FR-001 | lifecycx | 正常启动停止：A.Start→B.Start→B.Stop→A.Stop |
| TC-002 | FR-001 | lifecycx | 启动失败回滚：B.Start失败→A.Stop回滚→errors.Join |
| TC-003 | FR-001 | lifecycx | 未启动时Stop：返回nil（幂等） |
| TC-004 | FR-002 | errx | 错误链遍历：IsKind(KindTimeout)穿透双层wrap |
| TC-005 | FR-002 | errx | errors.Join多链：IsKind匹配Join中任一条 |
| TC-006 | FR-005 | retryx | 指数退避：Delay(3)≈BaseDelay×2² |
| TC-007 | FR-003 | healthx | Aggregate聚合：优先级unhealthy>degraded>healthy |
| TC-008 | FR-006 | shutdownx | LIFO顺序：后注册Hook先执行 |
| TC-009 | FR-004 | obsx | SecretString脱敏：String()/JSON()返回"***" |
| TC-010 | FR-010 | contextx | Key唯一性：同名字不同NewKey不冲突 |
| TC-011 | FR-008 | validx | 前置条件：RequireNonEmpty空值返回validation错误 |
| TC-012 | BR-009 | CI | stdlib-only gate：`go list -deps`无外部依赖 |
| TC-013 | FR-011 | syncx | SemaphoreLimiter：Acquire/Release并发安全 |
| TC-014 | FR-011 | syncx | WorkerGroup：错误收集+cancel传播 |
| TC-015 | FR-007 | timex | FakeClock：Advance(d)后Now()前进d |
| TC-016 | FR-006 | shutdownx | NotifyContext：SIGTERM→cancel传播 |
| TC-017 | FR-009 | versionx | Compatibility：模块/版本匹配正确 |
| TC-018 | FR-012 | contracttest | 断言匹配通过，不匹配Fatalf |

---

## 5. 全局 AC 注册表

| AC | 所属 FR/BR | Task | 验收条件摘要 |
|----|-----------|------|-------------|
| AC-001 | FR-001 | 005 | Manager.Start按序启动/失败回滚，Stop幂等 |
| AC-002 | FR-001 | 005 | 启动失败errors.Join含所有回滚错误 |
| AC-003 | FR-002 | 001 | NewError/WrapError字段完整，Error()格式正确 |
| AC-004 | FR-002 | 001 | Unwrap/IsKind/AsError全链路+errors.Join |
| AC-005 | FR-003 | 011 | HealthStatus构造/IsHealthy/Aggregate逻辑 |
| AC-006 | FR-004 | 003 | Noop*所有方法静默成功不panic | TC-009 (AC-006/007 合并验证) |
| AC-007 | FR-004 | 003 | SecretString公开方法返回"***" | TC-009 |
| AC-008 | FR-005 | 009 | Delay指数退避+Jitter+溢出保护 |
| AC-009 | FR-006 | 006 | Shutdown Hook LIFO顺序+并发安全 |
| AC-010 | FR-006 | 006 | NotifyContext OS signal→cancel |
| AC-011 | FR-007 | 002 | FakeClock Advance后Now正确 |
| AC-012 | FR-008 | 008 | Precondition/Invariant/RequireNonEmpty返回正确 |
| AC-013 | FR-009 | 007 | Compatibility模块/版本匹配 |
| AC-014 | FR-010 | 010 | Key唯一性+零值Key panic |
| AC-015 | FR-011 | 004 | SemaphoreLimiter Acquire/Release并发安全 |
| AC-016 | FR-011 | 004 | WorkerGroup错误收集+cancel传播 |
| AC-017 | FR-012 | 012 | 断言匹配/不匹配行为正确 |
| AC-018 | BR-009 | 016 | stdlib-only gate通过 |

---

## 6. 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 12 | FR-001 ~ FR-012 |
| FR 有 AC 覆盖 | 12/12 (100%) | |
| FR 有 TC 覆盖 | 12/12 (100%) | |
| FR 有 Task 分配 | 12/12 (100%) | |
| BR 总数 | 12 | BR-001 ~ BR-012 |
| BR 有 TC 覆盖 | 11/12 (92%) | BR-011 由代码逻辑保证 |
| BR 有 Task 分配 | 12/12 (100%) | |
| NFR 总数 | 8 | NFR-001 ~ NFR-008 |
| AC 总数 | 18 | AC-001 ~ AC-018 |
| TC 总数 | 18 | TC-001 ~ TC-018 |
| Task 总数 | 23 | TASK-KERNEL-000 ~ 016（含 015a/015b/015c 示例子任务 + 016a/016b/016c 发布子任务） |
| Prompt 总数 | 17 | PROMPT-KERNEL-000 ~ 016 |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-12 | v2.1 | 完整重写：7列矩阵 + BR行 + NFR行 + TC反向追溯 + AC注册表 + 覆盖率仪表盘 |
| 2026-06-12 | v2.0 | 从旧集中式 FR 重写为 12 子包 FR |
| 2026-06-08 | v1.0 | 初始版本 |
