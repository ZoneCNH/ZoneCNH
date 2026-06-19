# kernel

## 1. 模块定位
kernel 是 Foundation L0 原语层，为 L1 模块提供 stdlib-only 的 Go 基础原语工具包子集（零外部依赖）。包含 12 个独立子包（lifecycx/errx/healthx/obsx/retryx/shutdownx/syncx/timex/validx/versionx/contextx/contracttest），各子包按需引用、互不绑定。Status=Approved，Spec-version v2.0.0，运行时 module-version v1.1.0（已发布）。

## 2. 生产职责
- FR-001 lifecycx：组件有序启动/逆序停止/失败回滚/幂等 Stop
- FR-002 errx：结构化错误（ErrorKind/Severity/Code/Retryable + 错误链 IsKind/AsError/ShouldRetry）
- FR-003 healthx：HealthStatus 构造/IsHealthy/Aggregate 聚合规则（healthy > degraded > unhealthy）
- FR-004 obsx：Logger/Metrics/Tracer/Span 接口 + Noop 实现 + SecretString 脱敏
- FR-005 retryx：RetryPolicy 校验 + 指数退避 Delay + Jitter + ShouldRetry
- FR-006 shutdownx：Hook LIFO 管理 + NotifyContext OS 信号绑定
- FR-007 timex：Clock 接口（RealClock/FixedClock/FakeClock）
- FR-008 validx：Precondition/Invariant/RequireNonEmpty 前置条件校验
- FR-009 versionx：BuildInfo + Compatibility 模块/版本匹配
- FR-010 contextx：类型安全 Key[T]/WithValue/Value/DeadlineRemaining
- FR-011 syncx：SemaphoreLimiter + WorkerGroup 错误收集
- FR-012 contracttest：AssertJSONFields/AssertErrorKind/AssertHealthStatus

## 3. 边界定义
行为约束 BR-001 ~ BR-012：lifecycx 启动顺序=注册顺序、停止=逆序；启动失败必须回滚；未 started 时 Stop 幂等返回 nil；errx.Error 实现 error + Unwrap；IsKind/ShouldRetry 支持 errors.Join 多链；obsx 所有接口有 Noop 零值实现；healthx Metadata nil 序列化为 {}；shutdownx Hook 按 LIFO；contextx Key 必须通过 NewKey 创建；syncx double-release 静默忽略；timex FakeClock 零值接收者安全。

## 4. 不负责什么
不做集中式应用框架（无 App/Module/Deps 抽象）；不做 DI 容器；不做配置解析（→ configx）；不做日志/指标/追踪的具体实现（→ observex，kernel 只定义接口）；不做依赖图/拓扑排序/环检测；不做模块间依赖注入；不做存储、网络、业务 DTO；不做服务发现或远程调用。

## 5. 架构位置
L0 基座核心层（最底层原语）。依赖方向：可依赖 stdlib only；禁止依赖任何 Foundation L1 模块、业务域实现、L2.5 领域共享层、存储/中间件扩展。内部子包间允许有限交叉引用（healthx→timex、retryx→errx、validx→errx、contextx→timex、contracttest→errx+healthx）。上层通过 `github.com/ZoneCNH/kernel/<子包>` 按需 import。

## 6. 生命周期
- FR-001 lifecycx.Manager：Manager.Start(ctx) 按注册顺序启动；失败则逆序 Stop 回滚；Manager.Stop(ctx) 逆序停止，未 started 时幂等返回 nil
- FR-006 shutdownx.Manager：Register(hook) 追加到末尾；Shutdown(ctx) LIFO 执行；NotifyContext 绑定 OS 信号触发 cancel
- 组合根 x.go 使用 lifecycx.Manager 编排组件，shutdownx.Manager 管理停机钩子

## 7. 标准目录结构
```text
kernel/
├── go.mod / go.sum / README.md / CHANGELOG.md / Makefile / LICENSE
├── lifecycx/ errx/ healthx/ obsx/ retryx/ shutdownx/
├── syncx/ timex/ validx/ versionx/ contextx/ contracttest/
│   └── (每个子包: <pkg>.go / <pkg>_test.go / example_test.go)
├── internal/testutil/
├── contracts/ (api_docs_test.go / golden_behavior_test.go / public_api/ / golden/ / consumers/xgo/)
├── examples/ (12 子包对应示例目录)
├── docs/ (adr/ design/ governance/ spec/ standard/ evidence/)
├── scripts/ci/internal/apisnapshot/
└── release/ (manifest/ dependency/ standard-sync/)
```

## 8. 配置规范
kernel 本身无配置。各子包通过构造函数参数或结构体字段接收配置：
- lifecycx：`NewManager(components...)` 构造参数
- retryx：`RetryPolicy{MaxAttempts, BaseDelay, MaxDelay}` 结构体字段，含 `Validate()` 校验（MaxAttempts<=0 / BaseDelay<0 / BaseDelay>MaxDelay 返回 ErrorKindValidation）
- shutdownx：`NewManager(hooks...)` 构造参数
- syncx：`NewSemaphoreLimiter(n)`（n<=0 默认容量 1）
- versionx：`NewBuildInfo(module, version, commit, buildTime, goVersion)`

## 9. 错误模型
typed error：`errx.Error{Kind, Code, Severity, Op, Message, Cause, Retryable}`，实现 error + Unwrap 接口。ErrorKind 预定义 12 值（config/validation/connection/unavailable/timeout/auth/conflict/rate_limit/canceled/not_found/already_exists/internal）。Severity 四级（info/warning/error/critical）。聚合错误用 `errors.Join`，walkErrors 支持 Unwrap() []error 多链遍历。消息格式：`"<kind>: <op>: <message>"` 或 `"<kind>/<code>: <op>: <message>"`。

## 10. 日志规范
kernel 通过 obsx 子包定义日志接口（不触发具体行为），由 observex 提供 implementation。obsx.Logger 接口：`Debug/Info/Warn/Error(ctx, msg, ...Field)`，Field 为键值对。子包内部保持纯逻辑无副作用，日志由调用方负责。敏感数据使用 obsx.SecretString（String()/GoString()/MarshalJSON 返回 "***"，仅 Reveal() 可访问原始值）。

## 11. Metrics
obsx.Metrics 接口：`Count(ctx, name, delta int64, ...Field)` 和 `Observe(ctx, name, value float64, ...Field)`，含 context 和 Field 标签。NoopMetrics 零值实现所有方法静默成功。kernel 子包不直接 emit 指标，由消费方注入实现；具体 metric 命名遵循 observex 全局规范（SPEC 未细化子包内部 metric）。

## 12. Tracing
obsx.Tracer 接口：`Start(ctx, name, ...Field) (context.Context, Span)`。obsx.Span 接口：`End()` / `RecordError(error)` / `SetFields(...Field)`。NoopTracer/NoopSpan 零值实现。Trace span 约定遵循 observex 全局规范；kernel 仅定义 Span 接口契约，不强制 span 命名规则（SPEC 未细化）。

## 13. Reliability
- FR-005 retryx：DefaultRetryPolicy() = {MaxAttempts:3, BaseDelay:100ms, MaxDelay:2s}；Delay(attempt) 指数退避且 MaxDelay 上限 + 溢出保护（达 maxDuration 一半停止加倍）；DelayWithJitter fraction 钳位到 [-1,1]；ShouldRetry 遍历错误链检查 Retryable 标记
- FR-006 shutdownx：LIFO Hook 保证资源释放顺序；并发 Register + Shutdown 加锁保护
- BR-002：lifecycx 启动失败必须回滚已启动 Component

## 14. Security
- 敏感数据不泄露到日志：obsx.SecretString 自动脱敏（String()/GoString()/JSON 均返回 "***"）
- 错误消息不含原始凭证：errx.Error 只含 kind/op/message
- 无硬编码密钥：全仓 gitleaks detect --no-git 零命中（NFR-008 已验证）
- Sanitizer 接口约束：实现者必须保证 Sanitize() 不泄露原始值

## 15. Performance SLO
| 操作 | 目标 | 测量 |
| --- | --- | --- |
| errx.NewError 构造 | < 100ns | BenchmarkNewError |
| errx.IsKind 5 层链遍历 | < 1μs | BenchmarkIsKind |
| healthx.Aggregate 10 元素 | < 10μs | BenchmarkAggregate |
| retryx.Delay 计算 | < 100ns | BenchmarkDelay |
| 常驻内存（全子包导入） | < 5MB | profiling |

## 16. 测试标准
核心库包覆盖率 ≥ 100%（make coverage-threshold，排除 examples/scripts）。AC-001 ~ AC-018 + TC-001 ~ TC-018 全部 Verified（2026-06-18）。重点 TC：TC-002 启动失败回滚、TC-005 errors.Join 多链 IsKind、TC-009 SecretString 脱敏、TC-012 stdlib-only CI gate、TC-013/014 syncx 并发安全。测试类型以单元测试为主 + 契约测试（contracts/）。

## 17. Chaos
kernel 为 stdlib-only 纯逻辑库，无外部依赖、无网络/进程交互，不适用网络故障/依赖崩溃/慢响应类混沌测试。并发安全通过 `go test -race -count=1` 验证（TC-013/014 syncx、TC-008 shutdownx 并发）。具体混沌维度遵循 README 全局规范，本模块待定义（SPEC 未细化）。

## 18. Contract
公开接口契约由 §8 接口契约（SPEC §8.1-8.13）严格定义。contracts/ 目录维护 API 快照（public_api/）、golden 行为（golden/）、消费者导入测试（consumers/xgo/minimal_import_test.go）。BR-009 强制 kernel 不 import 任何非 stdlib 包。公开接口删除/签名变更 = major 版本；ErrorKind 新增值 = minor；bug 修复 = patch（SPEC §20 升级兼容性）。

## 19. CI Gate
通用 Gate：`go build ./...` / `go test ./... -race -count=1` / `make coverage-threshold`（核心包 100%）/ `go vet ./...` / `golangci-lint run` / `go mod tidy && git diff --exit-code go.mod go.sum` / `gitleaks detect --no-git` / `go test -bench=. -benchmem -count=3`。
kernel 专属 Gate：`scripts/check-stdlib-only.sh`（stdlib-only）、contracts API 快照对比、`contracts/golden_behavior_test.go`（golden 行为）、`make examples`（示例运行 + 输出漂移）。

## 20. Release Gate
ACCEPTANCE §5 DoD：[x] FEATURES/ACCEPTANCE 与 SPEC/TRACEABILITY 一致；[x] AC/TC 与运行时测试名/证据一致（`.config/goal/evidence/kernel-acceptance-20260618/`）；[x] go test / -race / vet / coverage-threshold 全绿（14 包 100.0%）；[x] 四源 arbiter gate=pass + BLK-011 resolved；[x] 安全检查通过；[x] 版本/标签/CHANGELOG 一致（v1.1.0 GitHub Release 2026-06-18）。SPEC §21 另列发布 DoD：godoc/ example_test.go / stdlib-only / API 快照 / golden / 消费者导入 / make release-preflight。

## 21. Versioning
semver。运行时 module-version v1.1.0（已发布）。go.mod：`module github.com/ZoneCNH/kernel`，`go 1.23`。升级兼容性：公开接口删除/签名变更 = major；新增公开类型/函数 = patch/minor；ErrorKind 新增值 = minor；bug 修复/内部重构 = patch。VersionInfo 类型别名已 deprecated，使用 BuildInfo。

## 22. 兼容性策略
向后兼容：公开接口签名稳定，删除/变更走 major 版本（SPEC §20）。versionx.Compatibility.CompatibleWith(info) 支持 Module + Major 匹配；Major 为空时仅校验 Module。边界情况：errx nil *Error 的 Error() 返回 ""；retryx Delay attempt<=0 / BaseDelay<=0 返回 0；syncx SemaphoreLimiter n<=0 默认容量 1、double-release 静默忽略；contextx 零值 Key 调用 contextKey() panic。

## 23. Failover
lifecycx 启动失败自动回滚（BR-002）：第 k 个 Component.Start 失败时，逆序 Stop 前 k-1 个已启动 Component，返回 errors.Join(第k错误, 所有回滚错误)。Shutdown 失败继续执行剩余 Hook（errors.Join 聚合，含 hook 名称）。timex FakeClock 零值接收者安全，防测试 nil panic。retryx 溢出保护防止指数退避溢出。

## 24. Backpressure
syncx.SemaphoreLimiter 提供容量限制：Acquire(ctx) 满时阻塞等待，ctx 取消时返回 ctx.Err()。syncx.WorkerGroup.Go/TryGo：首个错误触发 cancel，Wait() 收集所有错误；closed 后 TryGo 返回 false（静默忽略）。retryx.MaxDelay 上限约束指数退避增长。shutdownx 并发 Register + Shutdown 加锁保护，Shutdown 快照后追加的 hook 不执行。

## 25. 审计要求
versionx.BuildInfo 记录构建元数据（Module/Version/Commit/BuildTime/GoVersion）用于发布审计。obsx.SecretString 防止敏感数据泄露到日志/JSON。errx.Error 含 Op 操作名字段用于错误定位审计。release/manifest/ 维护发布产物清单。无硬编码密钥（gitleaks 全仓扫描零命中，NFR-008）。

## 26. 熵减规则
全局 Entropy Rules + 模块特有禁项（SPEC §7 + BR-009）：
- BR-009：kernel 不 import 任何非 stdlib 包（CI stdlib-only gate 阻断），违反破坏 L0 定位
- 禁止 util dumping（12 子包按职责切分，无 utils 包）
- 禁止 hidden abstraction（各子包独立、互不强制绑定）
- 禁止 cyclic dependency（子包依赖图为 DAG：validx/retryx→errx、healthx/contextx→timex、contracttest→errx+healthx）

## 27. AI Constraints
全局 AI Constraints + 模块特有约束：
- 禁止新增未注册子包（12 子包清单固定，新增需走 SPEC + FR 流程）
- 禁止绕过 contracts（公开 API 变更必须更新 contracts/public_api/ 快照 + golden）
- 禁止动态扩展目录（examples/docs/scripts 结构固定）
- 禁止引入第三方依赖（违反 BR-009 + L0 定位）
- AI 生成代码必须通过 stdlib-only gate + coverage 100%

## 28. Forbidden Patterns
- 禁止 global mutable state（lifecycx/shutdownx Manager 状态由实例持有，非全局）
- 禁止 shared singleton chaos（Noop 实现为零值 struct，非单例）
- 禁止 runtime reflection abuse（contextx Key 基于 sentinel 指针唯一性，非反射）
- 禁止跨层污染（L0 不得 import L1/L2.5/业务域）
- 禁止 silent panic（contextx 零值 Key 显式 panic 带消息；其余路径返回 error）

## 29. Production Ready Checklist
- [x] observability ready（obsx 接口 + Noop + SecretString 脱敏，FR-004 已交付）
- [x] resilience ready（retryx 指数退避 + lifecycx 回滚 + shutdownx LIFO，FR-001/005/006 已交付）
- [x] contract ready（contracts/ API 快照 + golden + 消费者导入测试，AC-018 Verified）
- [x] audit ready（versionx.BuildInfo + gitleaks 零命中 + Op 字段定位）
- [x] rollback ready（lifecycx 启动失败自动回滚，BR-002 Verified）
- [x] Factory 已闭合（2026-06-18：Goal Matrix 23 边 Verified、四源 arbiter gate=pass、coverage 100%、BLK-011 resolved）
- [~] Goal Matrix pipeline 边由 .config/goal 单独执行（代码侧证据已归档）

## 30. Roadmap
- v1.0.0（2026-06-07）：初始版本
- v1.1.0（2026-06-18）：已发布，Factory 证据链闭合，14 核心库包 coverage 100%
- v2.0.0（2026-06-12）：从集中式 App/Module/Deps 框架重写为 12 子包轻量工具集
- Resolved：errx 支持 errors.Join 多错误链；healthx 聚合规则已实现
- Non-blocking：子包内部不使用日志（保持纯逻辑无副作用）；不新增 configx 子包（由独立 configx 模块负责）
