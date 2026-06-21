# xlib_standard

## 1. 模块定位
xlib_standard 是 Foundation 的**标准事实源（Standard Source）**，承载 xlib 体系的唯一标准源：标准文档（`docs/standard/`）、可编译可渲染可验证的 Go Reference Template、Generator（`render_template.sh`）、17 个 CI Gate 和 Evidence Runtime（release manifest + goalcli 证据 CLI）。Status=Approved（SPEC v1.0.0），模块版本 v1.0.1（GitHub Release 已发布），Layer=基座·标准事实源（L1 工程标准）。解决下游基础库重复定义 Config/Error/Health/Metrics/Client/Version 导致的兼容性断裂问题。

## 2. 生产职责
- FR-001 Config 标准（Validate/Sanitize）
- FR-002 Error 标准（NewError/WrapError/IsKind，9 种 ErrorKind）
- FR-003 Health 标准（healthy/unhealthy/degraded）
- FR-004 Metrics 标准（NoopMetrics + 5 个 P0 指标，低基数 label）
- FR-005 Client 标准（New/Close 幂等）
- FR-006 Version 标准
- FR-007/008 公共 API 模板（可编译可 vet）
- FR-009/010 Generator 渲染（无模板残留）
- FR-011/012 CI gate + boundary gate
- FR-013/014 release manifest + final check
- FR-015 Evidence Runtime CLI（goalcli）
- FR-016 L2 下游仓库模板（12 文件）

## 3. 边界定义
- 仅承载标准源文档规范与可执行交付物（模板代码、渲染脚本、CI 门禁、发布证据生成）
- 配置由调用方显式传入，不得读取隐式环境配置（BR-001）
- 库代码不得调用 `log.Fatal`/`os.Exit`（BR-006）
- metrics label 仅允许低基数键 `op`、`kind`、`status`（BR-003）

## 4. 不负责什么
- 不承载业务运行（不实现交易、行情、风控、订单、仓位逻辑）
- 不替代下游模块的业务测试、集成测试或生产配置
- 不引入数据库、消息队列、外部网络调用或运行时平台依赖
- 不提供跨语言模板（仅覆盖 Go module）

## 5. 架构位置
基座层（L1 工程标准），是 xlib 体系的根。依赖方向：仅允许 Go 标准库，不得为模板生成/边界检查/release manifest 引入新外部运行时依赖。下游通过 Generator 生成 kernel/configx 等基础库骨架；xlibgate 消费其 Gate/Evidence 标准执行门禁。目录根：`xlib_standard/`（go.mod、pkg/templatex、cmd/goalcli、internal、templates/l2、scripts、contracts）。

## 6. 生命周期
Spec=Approved（2026-06-09），Plan=Approved（6 子任务），Code/Test=Completed，Release=Released（v1.0.1，tag 指向 main commit `26792dc`）。模板仓库不维护运行时状态，可生成状态只允许出现在渲染输出目录、release manifest 目录和临时测试目录。健康检查由 FR-003 定义（healthy/unhealthy/degraded），nil context 返回 unhealthy。

## 7. 标准目录结构
```text
xlib_standard/
├── go.mod / go.sum / README.md / SPEC.md / TRACEABILITY.md / Makefile / .golangci.yml
├── pkg/templatex/        # Go Reference Template（config/client/errors/health/metrics/version）
├── cmd/goalcli/          # Evidence Runtime CLI（audit/dashboard/fact/schema-check/traceability/governance/debt/adoption/selfimproving）
├── internal/             # sanitize/validation/xlibfacts/goalruntime/debtcheck/releasequality/releasemanifest
├── templates/l2/         # L2 下游仓库模板（12 文件）
├── scripts/              # render_template.sh/check_boundary.sh/generate_manifest.sh/release_check.sh
├── contracts/            # 跨域契约（4）+ 内部治理 schema（12）
├── testdata/ examples/ testkit/
```

## 8. 配置规范
Config 结构体（Name、Timeout、Secret）由调用方显式传入。Validate 校验必填字段与负数 timeout/retry。Sanitize 将 secret/token/key/password 类字段替换为 `***`（保留非敏感配置用于诊断）。渲染参数仅允许 `--module-path`、`--package-name`、`--out`、`--module-name`；脚本不得从生产环境文件或私有 secret 目录读取默认值。

## 9. 错误模型
Error 模型：kind（9 种稳定枚举：validation/timeout/unavailable/internal 等）、message、cause。NewError/WrapError 保持 `errors.Is`/`errors.Unwrap` 可穿透；deadline cause 归一为 timeout kind，canceled cause 归一为 unavailable kind。所有公共错误返回调用方，不退出进程。错误消息稳定、短句化、可测试；优先断言 kind 而非文本。

## 10. 日志规范
模板仅定义 metrics 接口和 no-op 实现，不强制日志后端。Release manifest 是发布可观测证据，记录 gate 结果与 generated_at。其他运行时日志（若下游启用）遵循 observex 全局规范。（SPEC 未细化运行时 logging，本模块为标准源不承载业务运行时日志）

## 11. Metrics
P0 指标名必须稳定且与 contract 一致，label 仅允许低基数键 `op`、`kind`、`status`，不得包含 ID/路径/用户输入/动态 module path。提供 `NoopMetrics` 默认实现，所有指标方法无副作用且不 panic。具体后端由下游模块注入（`WithMetrics(metrics)`）。

## 12. Tracing
SPEC 未定义独立 Trace span 约定。模板通过 metrics 接口和健康状态构造提供可观测骨架；如下游启用分布式追踪，遵循 observex 全局 OpenTelemetry 规范，本模块不强制 span 语义。

## 13. Reliability
Client.Close 多次调用幂等且不 panic。New 收到 nil context 返回 validation 错误，canceled context 返回 unavailable 错误，无效 config 返回错误。模板初始化轻量，不做网络调用。kind 匹配和健康状态构造为常数级操作。无 retry/backpressure/circuit breaker 运行时逻辑（非业务运行时模块）。

## 14. Security
脚本和模板不得提交 secret/API key/账户 ID/私有端点/生产配置。Sanitize 脱敏覆盖 secret/token/key/password 类字段，保留诊断信息。security gate 扫描常见凭证模式（secret-check）。boundary gate 拦截 `x.go/internal`、`/home/k8s/secrets/env`、`foundationx`、`baselib-template`、`templatex`、`xlib_standard` 非法引用。

## 15. Performance SLO
模板库初始化必须轻量，不做网络调用。NoopMetrics、kind 匹配、健康状态构造应为常数级操作。`make ci` 适合本地开发 gate，渲染 smoke test 不依赖外部服务。（SPEC 未定义具体 P99/availability 数值——本模块为标准源/工具，非在线服务）

## 16. 测试标准
三层测试：公共 API 单元测试（TC-001~018，pkg/templatex/*_test.go）、模板集成测试（TC-019~022，go vet/go test 零警告）、生成库 smoke test（TC-023/024）。最小验证命令：`GOWORK=off go test ./...`、`-race`、`make ci`、`make release-check`、`make release-final-check`。覆盖 38 AC（AC-000~037）。

## 17. Chaos
SPEC 未定义 chaos 测试维度。本模块为标准源/CLI 工具集，无在线服务需注入网络/依赖故障。边界情况由 §13 Edge Cases 覆盖（nil context、canceled context、负数 timeout、模板占位符缺失、release manifest checksum 不匹配）。

## 18. Contract
公共接口：`Config.Validate`、`Config.Sanitize`、`New(ctx, cfg, ...opts)`、`Client.Close(ctx)`、`HealthCheck(ctx)`、`Metrics`、`NoopMetrics`、`WithMetrics`、`Option`、`NewError`、`WrapError`、`IsKind`、`VersionInfo`。接口保持小表面积，测试优先断言 kind、状态、结构字段。contracts/ 含跨域契约 4 件（errors/health/config/metrics）+ 内部治理 schema 12 件。

## 19. CI Gate
`make ci` 串联 17 个 gate：doctor-hooks-local、fmt、vet、lint、test、race、boundary、architecture、domain、secret-check、security、security-debt、contracts、governance-check、debt、score、rules-verify。任一失败必须非零退出。release-check 串联 ci、integration、dependency-check、standard-impact-check、docs-check、score-check、governance-check、p1/p2-runtime-check、debt-evidence、fact-audit、evidence、release-evidence-hash/check/checksum-check。

## 20. Release Gate
DoD：模板测试通过、生成库测试通过、边界检查通过、合约检查通过、安全检查通过、release manifest 生成、checksum 校验通过、最终检查通过。发布证据必须可复现并可由 CI 重新生成。`make release-final-check` 校验 manifest checksum，并要求 `make ci` 与 release check 均已通过。

## 21. Versioning
破坏性接口变更（ErrorKind 增删、Config 字段类型变更、Metrics label 变更）必须：①在兼容矩阵记录；②在 release manifest 体现版本 bump；③提供迁移脚本或回滚说明；④经下游消费者确认后合入。先修复 xlib_standard 标准源，再用于生成 kernel 等下游。当前已发布 v1.0.1（tag `v1.0.1`→`26792dc`）。

## 22. 兼容性策略
先修复并验证 xlib_standard 标准源，再用于生成下游基础库。每次下游采用前必须重新运行渲染 smoke test、边界检查、生成库测试。破坏性接口变更进入 semver 兼容矩阵并在 release manifest 体现。本 SPEC 为 v1.0.0 可执行交付整理稿留存视图；当前快照审计入口为 README/ANALYSIS/FR-DETAIL/TRACEABILITY。

## 23. Failover
非业务运行时模块，无服务级 failover。失败模式表现为：渲染脚本失败（参数缺失）、boundary gate 命中非法引用、release manifest checksum 不匹配、release-final-check 阻断发布。处理方式为修复源因后重新跑 gate，无自动恢复语义。

## 24. Backpressure
非流式/在线服务，无 backpressure 语义。渲染与 gate 为批处理命令，资源约束体现在：evidence 文件超大时正常解析（内存 < 2x 文件大小）、并发运行多个实例时各独立无状态冲突、子检查超时标记 error 后继续执行。

## 25. 审计要求
Release manifest 是发布审计核心证据，记录 module_path、package_name、version、commit、tree_sha、go_version、contracts_sha256、gates、generated_at；不得包含 goal runtime/score/debt/branch governance/agent review/downstream matrix/docker runtime 字段。goalcli audit 输出 G0-G11 gate 状态审计报告；goalcli fact 输出 fact-audit 证据；goalcli traceability 生成 FR→Code 追溯矩阵；goalcli governance 输出远端治理状态。

## 26. 熵减规则
- 生成库不得残留 `templatex`、`xlib_standard`、`foundationx`、`baselib-template`（FR-010）
- boundary gate 拦截 6 类非法引用（FR-012）
- metrics label 低基数（禁止 ID/路径/动态 module path）
- 错误消息稳定短句化，禁止冗长散文式描述

## 27. AI Constraints
- AI 不允许新增未注册模块（Generator 参数受限）
- 不得绕过 contracts 定义公共 API
- 不得动态扩展目录结构（模板目录树固定）
- 渲染脚本只接受 4 个固定参数，禁止读取隐式环境配置

## 28. Forbidden Patterns
- 库代码调用 `log.Fatal`/`os.Exit`（BR-006）
- 读取隐式环境配置（BR-001）
- metrics label 使用高基数键（BR-003）
- release manifest 写入非 schema 字段（FR-013）
- 模板占位符未替换（BR-004）

## 29. Production Ready Checklist
- [x] 模板测试通过（AC-020/021，go vet/go test 零警告）
- [x] 生成库独立性（AC-022/023，无模板残留可独立构建）
- [x] 17 个 CI gate 全通过（AC-024）
- [x] boundary gate 6 类非法引用（AC-025）
- [x] release manifest 生成且 checksum 校验（AC-026/027）
- [x] goalcli 全子命令（AC-028~036）
- [x] L2 模板 12 文件（AC-037）
- [x] v1.0.1 已发布（tag→main commit，release-preflight 通过）

## 30. Roadmap
- v1.0.0 初始版本：52 FR，17 CI Gate，Go Reference Template（2026-06-12）
- v1.0.1 发布对齐：release-preflight、GitHub Release/tag、main checks（2026-06-18）
- 待评估（OQ）：多语言模板（非 Go）、Generator 交互式 prompt、goalcli CI 集成插件模式
