# 🧱 Foundation 规格与状态总览

## Foundation 规格文档（公开投影）

Foundation 模块的详细规格、依赖矩阵、执行跟踪和 ADR 集中在 `module/` 目录：

| 文档                                                                     | 定位                                                              |
| ------------------------------------------------------------------------ | ----------------------------------------------------------------- |
| [`module/foundation-modules.md`](./module/foundation-modules.md)         | Why & What — 模块定位、边界、能力需求、验证标准                   |
| [`module/FOUNDATION-SPEC.md`](./module/FOUNDATION-SPEC.md)               | How & Check — 接口签名、目录结构、CI gate、测试矩阵、Release DoD  |
| [`module/FOUNDATION-V1.md`](./module/FOUNDATION-V1.md)                   | v1 路线图 — 产品定义、一致性修复、Issue 拆分                      |
| [`module/FOUNDATION-DEPS.yaml`](./module/FOUNDATION-DEPS.yaml)           | 机器可读依赖矩阵，CI 可消费                                       |
| [`module/ADR-foundationx-exit.md`](./module/ADR-foundationx-exit.md)     | ADR：foundationx 兼容退出计划                                     |
| [`module/FOUNDATION-TRACKER.md`](./module/FOUNDATION-TRACKER.md)         | 执行跟踪器 — P0/P1/P2 Issue 检查清单                              |
| [`ROADMAP.md`](./ROADMAP.md)                                             | 六阶段交付路线图 — 任务编号、依赖链、验收标准                     |
| [`docs/governance/ROADMAP-RULES.md`](./docs/governance/ROADMAP-RULES.md) | ROADMAP 编写规范 — 状态流转、版本规划、任务拆分、维护原则         |
| [`CONSTITUTION.md`](./CONSTITUTION.md)                                   | 系统宪法 — FoundationX 全系统最高治理文件，覆盖模块实现与交付管线 |
| [`docs/sre/foundation-cicd-plan.md`](./docs/sre/foundation-cicd-plan.md) | SRE CI/CD — 基座层 19 模块 4 阶段部署方案、机器池架构、标准化模板 |

19 个基座模块的独立规格均为 23 节结构：行为规格 WHEN/THEN、接口契约、业务规则、错误处理、边界场景、验收标准、目录结构、CI Gate、测试矩阵、性能预算、可观测输出、发布 DoD。完整索引见 [`module/README.md`](./module/README.md)。`x.go` 负责治理/工具 CLI，`composer` 负责运行时组合根；两者都不作为 `module/` 下的模块规格。

| 层级                  | 模块          | 完整规格                                                         |
| --------------------- | ------------- | ---------------------------------------------------------------- |
| **L0 原语**           | kernel        | [`module/kernel/SPEC.md`](./module/kernel/SPEC.md)               |
| **L1 primitives**     | configx       | [`module/configx/SPEC.md`](./module/configx/SPEC.md)             |
|                       | observex      | [`module/observex/SPEC.md`](./module/observex/SPEC.md)           |
|                       | resiliencx    | [`module/resiliencx/SPEC.md`](./module/resiliencx/SPEC.md)       |
|                       | schedulex     | [`module/schedulex/SPEC.md`](./module/schedulex/SPEC.md)         |
| **L1 Assembly**       | bootstrap     | [`module/bootstrap/SPEC.md`](./module/bootstrap/SPEC.md)         |
| **L1 测试**           | testkitx      | [`module/testkitx/SPEC.md`](./module/testkitx/SPEC.md)           |
| **门禁**              | xlib_standard | [`module/xlib_standard/spec/SPEC.md`](./module/xlib_standard/spec/SPEC.md) |
|                       | xlibgate      | [`module/xlibgate/spec/SPEC.md`](./module/xlibgate/spec/SPEC.md)           |
|                       | xlib_harness  | [`module/xlib_harness/spec/SPEC.md`](./module/xlib_harness/spec/SPEC.md)   |
|                       | xlib_evidence | [`module/xlib_evidence/spec/SPEC.md`](./module/xlib_evidence/spec/SPEC.md) |
| **存储扩展**          | redisx        | [`module/redisx/SPEC.md`](./module/redisx/SPEC.md)               |
|                       | kafkax        | [`module/kafkax/SPEC.md`](./module/kafkax/SPEC.md)               |
|                       | natsx         | [`module/natsx/SPEC.md`](./module/natsx/SPEC.md)                 |
|                       | postgresx     | [`module/postgresx/SPEC.md`](./module/postgresx/SPEC.md)         |
|                       | taosx         | [`module/taosx/SPEC.md`](./module/taosx/SPEC.md)                 |
|                       | ossx          | [`module/ossx/SPEC.md`](./module/ossx/SPEC.md)                   |
|                       | clickhousex   | [`module/clickhousex/SPEC.md`](./module/clickhousex/SPEC.md)     |
| **契约/传输**         | contracts     | [`module/contracts/SPEC.md`](./module/contracts/SPEC.md)         |
|                       | transportx    | [`module/transportx/SPEC.md`](./module/transportx/SPEC.md)       |
| **L2.5 · 领域共享层** | domainx       | [`module/domainx/SPEC.md`](./module/domainx/SPEC.md)             |

### 规格体系与治理文档

| 文档                                                                                 | 定位                                                        |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------------- |
| [`docs/product/product-spec.md`](./docs/product/product-spec.md)                     | 产品规格 — Vision、Users、Goals、MVP Scope                  |
| [`docs/testing/test-strategy.md`](./docs/testing/test-strategy.md)                   | 测试策略 — 覆盖率、格式、工具、CI 集成                      |
| [`docs/testing/acceptance-tests.md`](./docs/testing/acceptance-tests.md)             | 验收测试 — 端到端验收场景和检查清单                         |
| [`docs/ai/agent-rules.md`](./docs/ai/agent-rules.md)                                 | AI 代理规则 — 编码、测试、安全、禁止事项                    |
| [`docs/ai/prompt-templates.md`](./docs/ai/prompt-templates.md)                       | Prompt 模板 — 审查、拆分、实现、自查、修复                  |
| [`docs/ai/code-review-rules.md`](./docs/ai/code-review-rules.md)                     | 代码审查规则 — AI 代理审查标准和流程                        |
| [`GLOSSARY.md`](./GLOSSARY.md)                                                       | 术语表 — 系统核心概念和缩写定义                             |
| [`docs/governance/DEFINITION-OF-READY.md`](./docs/governance/DEFINITION-OF-READY.md) | Spec Ready — spec 可以进入开发的前置条件                    |
| [`docs/governance/DEFINITION-OF-DONE.md`](./docs/governance/DEFINITION-OF-DONE.md)   | Spec Done — 模块实现完成的验收条件                          |
| [`docs/governance/TRACEABILITY.md`](./docs/governance/TRACEABILITY.md)               | 需求追踪 — FR → AC → TC → 实现全覆盖                        |
| [`docs/governance/anti-requirements.md`](./docs/governance/anti-requirements.md)     | 反需求 — 明确不做之事，防止范围蔓延                         |
| [`module/ADR-TEMPLATE.md`](./module/ADR-TEMPLATE.md)                                 | ADR 模板 — 架构决策记录标准格式                             |
| [`docs/governance/TASK-TEMPLATE.md`](./docs/governance/TASK-TEMPLATE.md)             | Task 模板 — AI 代理任务拆分标准格式                         |
| [`docs/governance/LIFECYCLE.md`](./docs/governance/LIFECYCLE.md)                     | 规格生命周期 — 六态状态机、流转规则、CI 集成                |
| [`docs/governance/SPEC-TEMPLATE.md`](./docs/governance/SPEC-TEMPLATE.md)             | 23 节结构模板 — 新建模块规格时复制本文件                    |
| [`docs/governance/AGENT-SPEC-TEMPLATE.md`](./docs/governance/AGENT-SPEC-TEMPLATE.md) | Agent Spec 模板 — 五层规格体系第五层，AI 代理角色/约束/协作 |

## Foundation 第一阶段闭环

这 6 个基础模块可以构成第一阶段最小闭环：`kernel` 提供 L0 原语，`configx` / `observex` / `resiliencx` / `schedulex` 提供 L1 primitives 横切能力，`testkitx` 只服务测试期。`bootstrap` 位于这些 primitives 之上，是面向进程入口的 L1 Assembly，不并入 primitives 闭环。

`xlib_standard` 是独立 Go module，承担标准事实源和 Go Reference Template 二类职责（Generator/Harness/Evidence 已拆分至 `xlib_harness` / `xlib_evidence`），不作为其他模块的运行时 import 依赖。

| 模块            | 层级              | 拥有                                                                                                                                                                | 不拥有                                                     |
| --------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `xlib_standard` | 标准源            | 标准事实源、Go Reference Template（Generator/Harness/Evidence 已拆分至 xlib_harness / xlib_evidence）                                                               | 业务运行、运行时 import 依赖、模块实现身份                 |
| `kernel`        | L0 原语           | 12 子包轻量工具集：lifecycx/errx/healthx/obsx/retryx/shutdownx/syncx/timex/validx/versionx/contextx/contracttest（stdlib-only）                                     | 配置解析、观测后端、存储、网络、业务 DTO、全局可变单例     |
| `configx`       | L1 primitive      | explicit source、merge、decode、validate、sanitize、provenance、config hash                                                                                         | secret backend、全局配置中心、自动发现、业务配置结构体     |
| `observex`      | L1 primitive 契约 | logger、metrics、tracer、field、redactor、label policy、health schema、noop、memory recorder                                                                        | Prometheus/Otel/Zap 直接绑定、alert routing、业务监控规则  |
| `resiliencx`    | L1 primitive 策略 | timeout、retry、circuit breaker、bulkhead、rate limiter、fallback、Compose、InstrumentStrategy、recovered panic（budget/classifier/idempotency hint 为 v1.2+ 演进） | 交易风控、订单风险、交易所 SDK、调度、存储后端             |
| `schedulex`     | L1 primitive 调度 | cron/interval/delay trigger、OverlapPolicy（Skip/Queue/Replace）、MisfirePolicy（Skip/RunOnce/CatchUp）、jitter、EventSink、Locker interface、Clock 注入            | 分布式锁实现、exactly-once、业务任务语义                   |
| `testkitx`      | L1 test-only      | FakeConfig/FakeLogger/FakeMeter/FakeTracer/FakeClock/FakeBreaker、Eventually、GoldenUpdate、BoundaryCheck、GoroutineLeakCheck、contract test                        | production import、真实外部系统、L2/L3/chaos/soak 测试替代 |

### `resiliencx` 身份修复

`resiliencx` 必须回到 operational resilience：对不稳定外部依赖、任务、数据源、交易所 API、消息处理和调度任务提供可组合故障控制策略。

`riskx` 才负责 trading risk，二者不能混用。

`xlib_standard` v1.0.1 已发布（tag v1.0.1, PR #121），标准源和 Go Reference Template 职责已完整落地。Generator / Harness Gate / Evidence Runtime 职责已于 PR #233 拆分至 `xlib_harness` 和 `xlib_evidence`。

`resiliencx` v1.0.2 已发布，围绕 timeout、retry、circuit、bulkhead、rate limit、fallback、Compose、InstrumentStrategy 和 recovered panic 完成运行时契约校准；GitHub Release Check 27777166525 与本地 release-check / release-final-check 均通过。

| 边界     | `kernel.retryx`                        | `resiliencx`                                      |
| -------- | -------------------------------------- | ------------------------------------------------- |
| 层级     | L0 primitive                           | L1 runtime policy                                 |
| 主要职责 | backoff、retry marker、简单 retry loop | timeout、retry、circuit、bulkhead、rate、fallback |
| 观测     | 不负责完整 metrics                     | 输出 policy events，交给 `observex` 记录          |
| 状态     | 尽量无状态                             | circuit breaker / limiter 可有状态                |
| 依赖     | stdlib only                            | 可依赖 `kernel`，观测通过接口注入                 |
| 使用场景 | 基础库内部轻量重试                     | 外部 API、交易所、数据源、消息、任务执行          |

### Foundation 依赖矩阵

| From \ To  | kernel    | configx | observex       | testkitx   | resiliencx | schedulex | x.go | business |
| ---------- | --------- | ------- | -------------- | ---------- | ---------- | --------- | ---- | -------- |
| kernel     | -         | 禁止    | 禁止           | 禁止       | 禁止       | 禁止      | 禁止 | 禁止     |
| configx    | 允许      | -       | 禁止           | test-only  | 禁止       | 禁止      | 禁止 | 禁止     |
| observex   | 允许      | 禁止    | -              | test-only  | 禁止       | 禁止      | 禁止 | 禁止     |
| resiliencx | 允许      | 允许    | interface-only | test-only  | -          | 禁止      | 禁止 | 禁止     |
| schedulex  | 允许/可选 | 禁止    | interface-only | test-only  | 禁止       | -         | 禁止 | 禁止     |
| testkitx   | 允许      | test    | test           | -          | test       | test      | 禁止 | 禁止     |
| x.go       | 允许      | 允许    | 允许           | 禁止(prod) | 允许       | 允许      | -    | 允许     |

## 状态总览

> **公开投影口径**：架构矩阵中的进度是 Spec→Code 管线投影；release/factory 以 `.foundationx/status/index.json` + `.foundationx/blockers.json` 和 GitHub Release 实际证据为准。2026-06-24 核查确认 `natsx` GitHub Release `v1.0.2` 已发布；`v1.0.3` 仍为 tag-only；release 证据按 `v1.0.2` 计入，不从 tag-only `v1.0.3` 推断。
> **分层口径**：主表只保留当前事实层与已发布投影；历史命名仅进入下方兼容映射与迁移说明，不再在主叙事重复出现。

| 域                    | 组件                                                            | 版本         | 状态      | Spec→Code 投影 | 说明                                                                                                                                                                                                                                                                                                                                                                             |
| --------------------- | --------------------------------------------------------------- | ------------ | --------- | -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **基座**              |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| 基座                  | [kernel](https://github.com/ZoneCNH/kernel)                     | v1.0.0       | ✅ 已发布 | Spec→Code 完成 | L0 原语 / 12 子包轻量工具集：lifecycx/errx/healthx/obsx/retryx/shutdownx/syncx/timex/validx/versionx/contextx/contracttest，stdlib-only，v1.0.0 已发布                                                                                                                                                                                                                           |
| 基座                  | [configx](https://github.com/ZoneCNH/configx)                   | v1.1.0       | ✅ 已发布 | Spec→Code 完成 | 显式配置加载、多源合并（YAML/TOML/JSON/.env/Env/Map/Args）、StrictDecode、SecretString 脱敏、SecretPolicy、Provenance、EffectiveConfigHash、SanitizedManifest、HealthCheck、Metrics、Bind() 强类型绑定、ConfigSnapshot/ChangeEvent/Watch 热更新与回滚、RemoteSource SPI、配置文档自动生成；96.5% 覆盖率；v1.1.0 GitHub Release 已发布，version.go 与 git tag 与 CHANGELOG 已对齐 |
| 基座                  | [observex](https://github.com/ZoneCNH/observex)                 | v0.3.4       | ✅ 已发布 | Spec→Code 完成 | vendor-neutral 日志、指标、追踪、健康、字段和 label policy 契约；Labels 改为 type alias（v0.3.4）；redisx/kafkax/clickhousex MetricClient* 已对齐；v1.0.0 误置 tag/Release 已清理（2026-06-19）                                                                                                                                                                                                                                                                                    |
| 基座                  | [testkitx](https://github.com/ZoneCNH/testkitx)                 | v0.4.0       | ✅ 已发布 | Spec→Code 完成 | Fake / Fixture / Golden / Contract / Leak / Boundary / Manifest 测试工具包；test-only；禁止生产导入；factory grade 不适用                                                                                                                                                                                                                                                        |
| 基座                  | [resiliencx](https://github.com/ZoneCNH/resiliencx)             | v1.0.2       | ✅ 已发布 | Spec→Code 完成 | 运行时弹性策略库：timeout/retry/circuit/bulkhead/rate/fallback、Compose、InstrumentStrategy、panic recovery；v1.0.2 GitHub Release 已发布，Release Check 27777166525 通过                                                                                                                                                                                                        |
| 基座                  | [schedulex](https://github.com/ZoneCNH/schedulex)               | v1.0.0       | ✅ 已发布 | Spec→Code 完成 | cron/interval/delay 调度、OverlapPolicy（Skip/Queue/Replace）、MisfirePolicy（Skip/RunOnce/CatchUp）、EventSink、Locker、Clock 注入；98.2% 覆盖，release-check 通过                                                                                                                                                                                                              |
| 基座                  | [bootstrap](https://github.com/ZoneCNH/bootstrap)               | v0.2.0       | ✅ 已发布 | Spec→Code 完成 | L1 Assembly 通用进程组装层：位于 L1 primitives 之上、`composer` 入口之下，统一组装 configx/observex/resiliencx/lifecycx + 7 存储 adapter 可选构造（StoreSet 位掩码）+ 信号捕获；不承载业务语义、service listener、domain contracts；✅ GitHub Release v0.2.0 已发布；BLK-009 resolved ✅；factory-ready                                                                              |
| 基座                  | [xlibgate](https://github.com/ZoneCNH/xlibgate)                 | v1.0.0       | ✅ 已发布 | Spec→Code 完成 | check / l2 / trust 三组门禁；全管线评分 100                                                                                                                                                                                                                                                                                                                                      |
| 基座                  | [xlib_standard](https://github.com/ZoneCNH/xlib-standard)       | v1.0.1       | ✅ 已发布 | Spec→Code 完成 | 标准事实源、Go Reference Template；Generator/Harness/Evidence 已拆分；v1.0.1 GitHub Release 与 release-preflight 已通过，不参与运行时 import                                                                                                                                                                                                                                     |
| 基座                  | [xlib_harness](https://github.com/ZoneCNH/xlib-harness)         | v0.1.1       | ✅ 已发布 | Spec→Code 完成 | 模块生成器与门禁执行器：generate/scaffold、spec-lint、boundary-check、traceability-gate；✅ v0.1.1 发布基线已通过 go test/race/vet/coverage/benchmark/CLI smoke 验收                                                                                                                                                                                                             |
| 基座                  | [xlib_evidence](https://github.com/ZoneCNH/xlib-evidence)       | v0.2.4       | ✅ 已发布 | Spec→Code 完成 | 证据收集与发布运行时：collect-coverage、generate-manifest、validate-manifest、remote-evidence、report；/home/xlib_evidence 本地 go test/race/vet/build/coverage 100.0% 通过；✅ CI/CD workflow 已部署；✅ GitHub Release v0.2.4 已发布，release evidence assets 已归档                                                                                                           |
| 基座                  | [redisx](https://github.com/ZoneCNH/redisx)                     | v1.1.0       | ✅ 已发布 | Spec→Code 完成 | Redis L2 adapter：KV/TTL/Hash/List/Pipeline/Cache-aside/Lock/RateLimit/Pool/Persistence restart recovery；PR #19、release-preflight、GitHub Release v1.1.0 与 dev Redis 集成验证通过                                                                                                                                                                                             |
| 基座                  | [kafkax](https://github.com/ZoneCNH/kafkax)                     | v1.1.0       | ✅ 已发布 | Spec→Code 完成 | Kafka L2 adapter — 消息队列、事件流（v1.0.0 已发布，driver-neutral API + kafka-go 生产驱动，真实 broker gates）                                                                                                                                                                                                                                                                  |
| 基座                  | [natsx](https://github.com/ZoneCNH/natsx)                       | v1.0.2 release / v1.0.3 tag / Spec v1.2.0 | ✅ 已发布 | Spec→Code 完成 | NATS L2 adapter：Core NATS / JetStream、Drain/reconnect/degraded health、canonical `FOUNDATIONX_NATS_*` 配置和真实 dev auth live gate 已验证；repair-slice 20/20；GitHub Release v1.0.2 已发布，v1.0.3 保留为 tag-only 事实；PR #17 已合并并实现 FR-009/010 JetStream IngestAdapter runtime 适配器；BLK-001/BLK-002 resolved；factory-ready                                                                                                                                       |
| 基座                  | [postgresx](https://github.com/ZoneCNH/postgresx)               | v1.0.0       | ✅ 已发布 | Spec→Code 完成 | PostgreSQL — 关系型存储、事务、迁移；live integration 通过；BLK-006 open（52.4% coverage + Docker integration skip）；非 factory                                                                                                                                                                                                                                                 |
| 基座                  | [taosx](https://github.com/ZoneCNH/taosx)                       | v1.0.3       | 🟡 候选   | Spec→Code 完成 | TDengine L2 adapter contract；本地发布候选已通过 release-check、integration 与 taosx-coverage-check 100.0%；TDengine dev live gate 已通过且保持显式 opt-in；未执行外部 tag/GitHub Release；非 factory                                                                                                                                                                            |
| 基座                  | [ossx](https://github.com/ZoneCNH/ossx)                         | v1.2.1       | ✅ 已发布 | Spec→Code 完成 | Aliyun OSS L2 adapter；真实 adapters/aliyun + 流式 SPI + 完整 multipart + presign + 策略 + retry/circuit + observex hooks；pkg/ossx 100.0% 覆盖；本地实盘 integration 5/5（bucket x-go）；BLK-010 resolved ✅（PR #8 merged）；factory-ready                                                                                                                                     |
| 基座                  | [clickhousex](https://github.com/ZoneCNH/clickhousex)           | v1.0.8       | ✅ 已发布 | Spec→Code 完成 | ClickHouse — OLAP 查询、批量写入；v1.0.8 GitHub Release 已发布，v1.0.3–v1.0.8 发布线已合并入 main；100.0% 覆盖率、真实 live 集成 + 60s soak 已复验；branch/tag Actions quality/lint/integration/secret-scan/trust/release-check 已通过；foundation gate 与版本元数据已对齐；BLK-003 resolved；非 factory                                                                         |
| 基座                  | [contracts](https://github.com/ZoneCNH/contracts)               | v1.2.0       | ✅ 已发布 | Spec→Code 完成 | 跨域稳定端口/事件/DTO 契约（含 §8.4 Binance C/S ingestion contract）；spec-only；✅ GitHub Release v1.2.0 已发布                                                                                                                                                                                                                                                                 |
| 基座                  | [transportx](https://github.com/ZoneCNH/transportx)             | v1.1.1-spec  | ✅ 已发布 | Spec→Code 完成 | 应用通信底座规格基线；✅ GitHub Release v1.1.1-spec 已发布                                                                                                                                                                                                                                                                                                                       |
| **L2.5 · 领域共享层** |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| L2.5                  | [domainx](https://github.com/ZoneCNH/domainx)                   | v1.0.1       | ✅ 已有   | Spec→Code 完成 | 领域共享值对象基线：Order/Position/Trade/Portfolio/ExecutionReport 与 OrderState/OrderType/OrderSide 枚举（8 FR，8 TC，6 tasks）；公开 v1.0.1 GitHub Release/tag 已观测并完成 release 对账；factory grade；live/soak N/A（纯值对象库）                                                                                                                                           |
| L2.5                  | [decimalx](https://github.com/ZoneCNH/decimalx)                 | v1.0.0       | ✅ 已有   | Spec→Code 完成 | 高精度十进制类型（Decimal/Price/Qty/Ratio/Money）；v1.0.0 GitHub Release 已发布；8 FR Done；factory grade；live/soak N/A（纯值对象库）                                                                                                                                                                                                                                           |
| L2.5                  | [domain_market](https://github.com/ZoneCNH/domain_market)       | v1.1.0       | ✅ 已有   | Spec→Code 完成 | 市场数据域模型（Tick/Quote/Bar/OrderBook）+ canonical 类型（ProductLine/InstrumentKey/MarketFactEnvelope）+ Binance C/S ingestion 语义 §10.1；v1.1.0；factory grade；live/soak N/A（纯值对象库）                                                                                                                                                                                 |
| L2.5                  | [domain_exchange](https://github.com/ZoneCNH/domain_exchange)   | v1.0.0       | ✅ 已有   | Spec→Code 完成 | 交易域模型（VenueAdapter 13 方法接口）；v1.0.0 GitHub Release 已发布；7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                                                                                                                                                                                                                      |
| L2.5                  | [domain_macro](https://github.com/ZoneCNH/domain_macro)         | v1.0.0       | ✅ 已有   | Spec→Code 完成 | 宏观数据域模型（MacroPoint/MacroState）；v1.0.0 GitHub Release 已发布；7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                                                                                                                                                                                                                     |
| **数据域 · 行情**     |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| 数据域                | [market_data](https://github.com/ZoneCNH/market_data)           | v1.1.0       | ✅ 已发布 | ████ 85%       | Receiver（DownstreamDispatchPort，18 测试）+ DualWriteSink（TD+Kafka 双写，6 测试）；v1.1.0 released                                                                                                                                                                                                                                                                             |
| 数据域                | [binance](https://github.com/ZoneCNH/binance)                   | v0.8.0 / spec v3.9.6 | ✅ 已发布 | 48 Done / 0 Partial / 0 Drifted / 0 Pending | Binance Market Data C/S Module；Runtime-Anchor `/home/binance@b2d9d83`；deep-review 37/37 fixed (PR #229)；coverage ~73.7%；production release v0.8.0 |
| 数据域                | [okx](https://github.com/ZoneCNH/okx)                           | -            | ✅ 已有   | ███░ 80%       | OKX CEX SDK                                                                                                                                                                                                                                                                                                                                                                      |
| 数据域                | [bybit](https://github.com/ZoneCNH/bybit)                       | -            | ✅ 已有   | ███░ 80%       | Bybit CEX SDK                                                                                                                                                                                                                                                                                                                                                                    |
| 数据域                | [bitget](https://github.com/ZoneCNH/bitget)                     | -            | ✅ 已有   | ███░ 80%       | Bitget CEX SDK                                                                                                                                                                                                                                                                                                                                                                   |
| 数据域                | [kucoin](https://github.com/ZoneCNH/kucoin)                     | -            | ✅ 已有   | ███░ 80%       | KuCoin CEX SDK                                                                                                                                                                                                                                                                                                                                                                   |
| 数据域                | [gate](https://github.com/ZoneCNH/gate)                         | -            | ✅ 已有   | ███░ 80%       | Gate CEX SDK                                                                                                                                                                                                                                                                                                                                                                     |
| 数据域                | [mexc](https://github.com/ZoneCNH/mexc)                         | -            | ✅ 已有   | ███░ 80%       | MEXC CEX SDK                                                                                                                                                                                                                                                                                                                                                                     |
| 数据域                | [htx](https://github.com/ZoneCNH/htx)                           | -            | ✅ 已有   | ███░ 80%       | HTX CEX SDK                                                                                                                                                                                                                                                                                                                                                                      |
| 数据域                | [coinbase](https://github.com/ZoneCNH/coinbase)                 | -            | ✅ 已有   | ███░ 80%       | Coinbase CEX SDK                                                                                                                                                                                                                                                                                                                                                                 |
| 数据域                | [hyperliquid](https://github.com/ZoneCNH/hyperliquid)           | -            | ✅ 已有   | ███░ 80%       | Hyperliquid DEX SDK                                                                                                                                                                                                                                                                                                                                                              |
| 数据域                | [lighter](https://github.com/ZoneCNH/lighter)                   | -            | ✅ 已有   | ███░ 80%       | Lighter DEX SDK                                                                                                                                                                                                                                                                                                                                                                  |
| 数据域                | [upbit](https://github.com/ZoneCNH/upbit)                       | -            | ✅ 已有   | ███░ 80%       | Upbit CEX SDK                                                                                                                                                                                                                                                                                                                                                                    |
| 数据域                | [coinglass](https://github.com/ZoneCNH/coinglass)               | -            | ✅ 已有   | ███░ 80%       | 衍生品聚合数据                                                                                                                                                                                                                                                                                                                                                                   |
| **数据域 · 宏观**     |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| 数据域                | [fred](https://github.com/ZoneCNH/fred)                         | -            | ✅ 已有   | ███░ 80%       | 美联储 FRED                                                                                                                                                                                                                                                                                                                                                                      |
| 数据域                | [treasury](https://github.com/ZoneCNH/treasury)                 | -            | ✅ 已有   | ███░ 80%       | 美国财政部                                                                                                                                                                                                                                                                                                                                                                       |
| 数据域                | [yield_curve](https://github.com/ZoneCNH/yield_curve)           | -            | ✅ 已有   | ███░ 80%       | 收益率曲线                                                                                                                                                                                                                                                                                                                                                                       |
| 数据域                | [bea](https://github.com/ZoneCNH/bea)                           | -            | ✅ 已有   | ███░ 80%       | 美国经济分析局                                                                                                                                                                                                                                                                                                                                                                   |
| 数据域                | [ecb](https://github.com/ZoneCNH/ecb)                           | -            | ✅ 已有   | ███░ 80%       | 欧洲央行                                                                                                                                                                                                                                                                                                                                                                         |
| 数据域                | [uk_cb](https://github.com/ZoneCNH/uk_cb)                       | -            | ✅ 已有   | ███░ 80%       | 英国央行                                                                                                                                                                                                                                                                                                                                                                         |
| 数据域                | [japan_cb](https://github.com/ZoneCNH/japan_cb)                 | -            | ✅ 已有   | ███░ 80%       | 日本央行                                                                                                                                                                                                                                                                                                                                                                         |
| 数据域                | [eastmoney](https://github.com/ZoneCNH/eastmoney)               | -            | ✅ 已有   | ███░ 80%       | 东方财富 A 股                                                                                                                                                                                                                                                                                                                                                                    |
| 数据域                | [jin10](https://github.com/ZoneCNH/jin10)                       | v0.2.0       | ✅ 已有   | ███░ 80%       | 金十数据 SDK：openapi（宏观数据）+ flash（实时快讯）                                                                                                                                                                                                                                                                                                                             |
| 数据域                | [yahoo](https://github.com/ZoneCNH/yahoo)                       | -            | ✅ 已有   | ███░ 80%       | Yahoo Finance                                                                                                                                                                                                                                                                                                                                                                    |
| **数据域 · 另类**     |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| 数据域                | [alternative_data](https://github.com/ZoneCNH/alternative_data) | -            | 🔨 已创建 | ░░░░ 5%        | 链上、社交情绪、新闻 NLP                                                                                                                                                                                                                                                                                                                                                         |
| **分析域**            |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| 分析域                | [factor_engine](https://github.com/ZoneCNH/factor_engine)       | -            | 🔨 已创建 | ░░░░ 5%        | 从原始数据计算 alpha 因子                                                                                                                                                                                                                                                                                                                                                        |
| 分析域                | [feature_store](https://github.com/ZoneCNH/feature_store)       | -            | 🔨 已创建 | ░░░░ 5%        | 因子版本管理、IC 评估                                                                                                                                                                                                                                                                                                                                                            |
| 分析域                | [factor_eval](https://github.com/ZoneCNH/factor_eval)           | -            | 🔨 已创建 | ░░░░ 5%        | IC/IR/换手率评估                                                                                                                                                                                                                                                                                                                                                                 |
| 分析域                | [market_regime](https://github.com/ZoneCNH/market_regime)       | v0.2.0       | 🔨 已创建 | ████████ 70%   | 市场状态识别（S1-S7）；BarWindow 滑动窗口、domain_market 适配器、Subscriber 消费者层，12 tests PASS；composer wire-up 待推进                                                                                                                                                                                                                                                          |
| 分析域                | [macro_regime](https://github.com/ZoneCNH/macro_regime)         | v0.2.0       | 🔨 已创建 | ████████ 70%   | 宏观经济体制识别（M1-M7）；MacroInformationSet mapper+ClassifyFromSet 便利方法，13 tests PASS；composer wire-up 待推进                                                                                                                                                                                                                                                                |
| 分析域                | [regime_engine](https://github.com/ZoneCNH/regime_engine)       | v1.0.0       | 🔨 已创建 | ████ 60%       | M×S 联合决策引擎，P0 DTO 桥接完成（RegimeSnapshot+RegimeCard→DecisionCard），13 tests PASS                                                                                                                                                                                                                                                                                       |
| 分析域                | [ms_brain](https://github.com/ZoneCNH/ms_brain)                 | -            | ✅ 已有   | -              | M×S 系统架构分析体系                                                                                                                                                                                                                                                                                                                                                             |
| 分析域                | [flowx](https://github.com/ZoneCNH/flowx)                       | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%        | 数据流管线引擎 — 实时流式 ETL、窗口聚合、背压控制（7 FR, SPEC draft）                                                                                                                                                                                                                                                                                                            |
| **决策域**            |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| 决策域                | [signal_factory](https://github.com/ZoneCNH/signal_factory)     | -            | 🔨 已创建 | ░░░░ 5%        | 多因子信号生成、过滤、评分                                                                                                                                                                                                                                                                                                                                                       |
| 决策域                | [backtestx](https://github.com/ZoneCNH/backtestx)               | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%        | 回测引擎 — 事件驱动回测、Walk-Forward、蒙特卡洛（7 FR, SPEC draft）                                                                                                                                                                                                                                                                                                              |
| 决策域                | [strategyx](https://github.com/ZoneCNH/strategyx)               | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%        | 策略工厂 — 策略注册、参数管理、信号组合（7 FR, SPEC draft）                                                                                                                                                                                                                                                                                                                      |
| 决策域                | [maestro](https://github.com/ZoneCNH/maestro)                   | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%        | 工作流编排引擎 — DAG 工作流、状态机、错误恢复（9 FR, SPEC draft）                                                                                                                                                                                                                                                                                                                |
| 决策域                | [optimizer](https://github.com/ZoneCNH/optimizer)               | -            | 🔨 已创建 | ░░░░ 5%        | 参数搜索、Walk-forward 验证                                                                                                                                                                                                                                                                                                                                                      |
| **执行域**            |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| 执行域                | [riskx](https://github.com/ZoneCNH/riskx)                       | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%        | 风控引擎 — 事前风控、回撤控制、熔断机制（7 FR, SPEC draft）                                                                                                                                                                                                                                                                                                                      |
| 执行域                | [orderx](https://github.com/ZoneCNH/orderx)                     | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%        | 订单管理器 — 订单生命周期、SOR、状态机（7 FR, SPEC draft）                                                                                                                                                                                                                                                                                                                       |
| 执行域                | [positionx](https://github.com/ZoneCNH/positionx)               | v0.1.0-draft | 🔨 已创建 | ░░░░ 5%        | 仓位管理器 — 实时仓位追踪、PnL、敞口监控（7 FR, SPEC draft）                                                                                                                                                                                                                                                                                                                     |
| 执行域                | [settlement](https://github.com/ZoneCNH/settlement)             | -            | 🔨 已创建 | ░░░░ 5%        | PnL 计算、交易所对账                                                                                                                                                                                                                                                                                                                                                             |
| **入口**              |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| 入口                  | [composer](https://github.com/ZoneCNH/composer)                 | v0.2.0       | ✅ 已有   | ███░ 80%       | 运行时组合根，25 进程编排                                                                                                                                                                                                                                                                                                                                                          |
| **横切**              |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| 横切                  | [alertx](https://github.com/ZoneCNH/alertx)                     | v1.0.0       | ✅ 已发布 | █████ 100%     | 告警引擎：规则 DSL + 去重 + 分级 + 通知 + 双订阅；✅ v1.0.0 spec→code 全链 pass；AT-007 横切贯穿                                                                                                                                                                                                                                                                                                                                                           |
| 横切                  | [observex](https://github.com/ZoneCNH/observex)                 | v0.3.4       | ✅ 已发布 | █████ 100%     | 可观测性（同时归属基座，提供底层 metrics/tracing/logging）；Labels type alias；redisx/kafkax/clickhousex 已对齐                                                                                                                                                                                                                                                                                                                       |
| **独立**              |                                                                 |              |           |                |                                                                                                                                                                                                                                                                                                                                                                                  |
| 独立                  | [module](./module/README.md)                                    | -            | ✅ 已有   | -              | 项目技术规范、接口定义与 Goal 适配模块索引                                                                                                                                                                                                                                                                                                                                       |
| 治理                  | [docs/governance](./docs/governance/README.md)                  | -            | ✅ 已有   | -              | Spec → Code 交付治理、模板、门禁与评分规则                                                                                                                                                                                                                                                                                                                                       |

### 历史兼容映射（仅供迁移）

| 历史名 | 当前名 | 说明 |
| --- | --- | --- |
| backtest_engine | backtestx | 决策域历史占位名，仅保留迁移引用 |
| risk_engine | riskx | 执行域历史占位名，仅保留迁移引用 |
| order_engine | orderx | 执行域历史占位名，仅保留迁移引用 |
| portfolio_engine | positionx | 执行域历史占位名，仅保留迁移引用 |

## 本地开发路径

> 所有模块代码仓库统一位于 `/home/{module}/`，其中 `{module}` 与 GitHub 仓库名一一对应。本地路径仅用于开发时快速定位代码，不参与运行时。

| 域                | 模块            | 本地路径                 |
| ----------------- | --------------- | ------------------------ |
| **基座**          |                 |                          |
| 基座              | kernel          | `/home/kernel/`          |
| 基座              | configx         | `/home/configx/`         |
| 基座              | observex        | `/home/observex/`        |
| 基座              | testkitx        | `/home/testkitx/`        |
| 基座              | resiliencx      | `/home/resiliencx/`      |
| 基座              | schedulex       | `/home/schedulex/`       |
| 基座              | xlibgate        | `/home/xlibgate/`        |
| 基座              | xlib_standard   | `/home/xlib-standard/`   |
| 基座              | redisx          | `/home/redisx/`          |
| 基座              | kafkax          | `/home/kafkax/`          |
| 基座              | natsx           | `/home/natsx/`           |
| 基座              | postgresx       | `/home/postgresx/`       |
| 基座              | clickhousex     | `/home/clickhousex/`     |
| 基座              | taosx           | `/home/taosx/`           |
| 基座              | ossx            | `/home/ossx/`            |
| 基座              | contracts       | `/home/contracts/`       |
| 基座              | transportx      | `/home/transportx/`      |
| **L2.5**          |                 |                          |
| L2.5              | domainx         | `/home/domainx/`         |
| L2.5              | decimalx        | `/home/decimalx/`        |
| L2.5              | domain_market   | `/home/domain_market/`   |
| L2.5              | domain_exchange | `/home/domain_exchange/` |
| L2.5              | domain_macro    | `/home/domain_macro/`    |
| **数据域 · 行情** |                 |                          |
| 数据域            | binance         | `/home/binance/`         |
| 数据域            | okx             | `/home/okx/`             |
| 数据域            | bybit           | `/home/bybit/`           |
| 数据域            | bitget          | `/home/bitget/`          |
| 数据域            | coinbase        | `/home/coinbase/`        |
| 数据域            | gate            | `/home/gate/`            |
| 数据域            | kucoin          | `/home/kucoin/`          |
| 数据域            | mexc            | `/home/mexc/`            |
| 数据域            | htx             | `/home/htx/`             |
| 数据域            | upbit           | `/home/upbit/`           |
| 数据域            | hyperliquid     | `/home/hyperliquid/`     |
| 数据域            | lighter         | `/home/lighter/`         |
| 数据域            | coinglass       | `/home/coinglass/`       |
| **数据域 · 宏观** |                 |                          |
| 数据域            | fred            | `/home/fred/`            |
| 数据域            | treasury        | `/home/treasury/`        |
| 数据域            | bea             | `/home/bea/`             |
| 数据域            | ecb             | `/home/ecb/`             |
| 数据域            | uk_cb           | `/home/uk_cb/`           |
| 数据域            | japan_cb        | `/home/japan_cb/`        |
| 数据域            | eastmoney       | `/home/eastmoney/`       |
| 数据域            | jin10           | `/home/jin10/`           |
| 数据域            | yahoo           | `/home/yahoo/`           |
| 数据域            | yield_curve     | `/home/yield_curve/`     |
| **分析域**        |                 |                          |
| 分析域            | flowx           | `/home/flowx/`           |
| **决策域**        |                 |                          |
| 决策域            | backtestx       | `/home/backtestx/`       |
| 决策域            | strategyx       | `/home/strategyx/`       |
| 决策域            | maestro         | `/home/maestro/`         |
| **执行域**        |                 |                          |
| 执行域            | riskx           | `/home/riskx/`           |
| 执行域            | orderx          | `/home/orderx/`          |
| 执行域            | positionx       | `/home/positionx/`       |
| **入口**          |                 |                          |
| 入口              | composer        | `/home/composer/`        |

> 完整仓库 URL 映射见上方状态总览表。分析域（flowx）、决策域（backtestx/strategyx/maestro）、执行域（riskx/orderx/positionx）模块 SPEC 已发布（v0.1.0-draft）。

## 建议实现顺序

```text
Foundation P0: 基础闭环校准 ← kernel + configx + observex + testkitx + resiliencx + schedulex
               1. resiliencx 从标准模板身份改回运行时弹性策略库
               2. xlib_standard 固定为标准事实源 / Go Reference Template（Generator / Harness Gate / Evidence Runtime 已拆分至 xlib_harness / xlib_evidence）
               3. configx / observex 迁移到 kernel，或标注 foundationx 兼容期
               4. 统一 Foundation Go baseline
               5. 用 xlibgate / 脚本执行依赖矩阵、testkitx 边界和 release evidence

Phase 0: 领域共享层 ← domainx + decimalx + domain_market + domain_exchange + domain_macro
         ✅ 已完成 (v0.1.0)，所有上层模块已依赖此层

Phase 1: 分析域   ← factor_engine + feature_store + factor_eval
         先固化 MarketDataProvider / FactorInput / FactorOutput；
         退出条件是 market provider → factor_engine → factor_eval 可跑通

Phase 2: 决策域   ← signal_factory + backtestx + optimizer
         先固化 SignalIntent / PortfolioTarget；
         退出条件是 signal → backtestx → factor feedback 可跑通

Phase 3: 执行域   ← riskx + orderx + positionx
         先固化 RiskDecision / OrderIntent / ExecutionReport；
         退出条件是 signal → riskx → paper orderx → position update 可跑通

Phase 4: 平台化   ← settlement + alertx + alternative_data
         先固化 PositionSnapshot / PnLReport / ExposureEvent；
         生产化运维能力；执行反馈以事件回到决策域

Phase 5: 入口验收 ← composer
         只补最终 wiring 和生命周期，验证完整闭环，不新增业务逻辑
```
