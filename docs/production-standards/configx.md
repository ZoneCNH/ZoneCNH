# configx

## 1. 模块定位
configx 是 Foundation L1 基础能力层，提供显式、可审计的 Go 配置管理原语。调用方显式选择每种配置源和加载路径；库不执行隐式发现、不创建全局状态、不注册单例、不强依赖任何驱动包或 x.go 模块。Status=Approved，Spec-version v1.1.0，运行时 module-version v1.1.0（已发布，version.go/CHANGELOG/git tag/GitHub Release 全部对齐）。

## 2. 生产职责
- FR-001 Client 生命周期（New/Close，强制校验 ctx+cfg）
- FR-002 Loader+Source 模式（NewLoader().AddSource().Load(ctx)，支持 FailFast）
- FR-003 FileSource（YAML/TOML/JSON/.env 四格式）
- FR-004 EnvSource（prefix+keys / AllEnvSource）
- FR-005 MapSource（字符串 map）
- FR-006 StrictDecode（未知字段/重复 key/类型错误 fail-fast，含 WithAllowUnknownFields / WithMaxDepth）
- FR-007 SecretString 自动脱敏（String/JSON/GoString/Text）
- FR-008 SecretPolicy 密钥检测（默认 7 模式 + CustomMatcher）
- FR-009 Provenance 来源追踪（Source/Priority/OverrideEntry）
- FR-010 EffectiveConfigHash（SHA-256，排除 volatile 字段）
- FR-011 SanitizedManifest（敏感字段自动替换，nil 安全）
- FR-012 HealthCheck（Status/LatencyMs/Metadata）
- FR-013 Metrics（8 标准指标 + NoopMetrics）

## 3. 边界定义
行为约束 BR-001 ~ BR-011：LastWins 合并（后加载覆盖先加载）；Config.Name 必须非空；Config.Timeout ≥ 0；显式加载（无隐式发现，TestNoImplicitConfigDiscovery 验证）；SecretString 全路径脱敏；SecretPolicy 默认 7 模式可扩展；StrictDecode 默认严格；公共错误用 *Error + ErrorKind 枚举（errors.As 可提取 Kind/Op/Cause）；无全局状态（无可变包级单例）；Release 通过全部 CI Gate；所有公开 API 强制 ctx 非 nil。

## 4. 不负责什么
不做隐式配置发现（无 auto-scan、无约定目录）；不做远程配置中心产品（K8s ConfigMap 可通过文件挂载）；不做敏感信息加密存储（→ 环境变量或 secret manager）；不做跨服务配置同步；不做运行时配置热更新（Watch 特性，显式推迟到 v1.1）；不做配置文档自动生成。

## 5. 架构位置
L1 基础能力层。依赖方向：可依赖 stdlib + `gopkg.in/yaml.v3` + `github.com/pelletier/go-toml/v2`；禁止依赖 kernel（NFR-005，foundationx exit 已完成）、observex、resiliencx、schedulex、testkitx、所有业务域实现、所有存储/中间件扩展。消费者：L1 运行时模块（observex/resiliencx/schedulex）通过 `configx.New(ctx, cfg, opts...)` 创建 Client；x.go 组合根创建 Config 注入各模块；存储扩展通过 Loader+FileSource/EnvSource 加载连接配置。

## 6. 生命周期
- 创建：`New(ctx, cfg, opts...)` 校验 cfg → 初始化 Client → metrics `client_created_total`+1；ctx nil 或 Validate 失败返回 error
- 加载：`loader.Load(ctx)` 按序加载所有 Source → LastWins 合并 → 返回 LoadResult；failFast=true 时 Source 失败立即返回
- 运行：Client 就绪，并发安全（sync.RWMutex 保护），可调用 HealthCheck
- 关闭：`client.Close(ctx)` 标记 closed=true → metrics `client_closed_total`+1

## 7. 标准目录结构
```text
configx/
├── go.mod / go.sum / README.md / CHANGELOG.md / LICENSE / Makefile / .golangci.yml (8 linter)
├── pkg/configx/
│   ├── doc.go client.go config.go core.go loader.go source.go
│   ├── source_file.go (YAML/TOML/JSON/Env) source_env.go source_map.go
│   ├── merge.go strict.go secret.go secretpolicy.go provenance.go
│   ├── hash.go manifest.go result.go validation.go health.go
│   ├── metrics.go (8 指标 + NoopMetrics) options.go errors.go version.go
├── internal/ (runtime/ tools/)
├── examples/error-handling/ (5 种错误处理模式)
├── testdata/ testkit/ contracts/ docs/ (3 ADR) scripts/ release/
```

## 8. 配置规范
configx 自身 Client 配置（typed config，SPEC §10）：
```yaml
config:
  name: my-service          # 必填，客户端名称（BR-002）
  timeout: 30s              # 必须 ≥ 0（BR-003）
  secret: ${CONFIGX_SECRET} # 可选，敏感凭证，自动脱敏
```
Option 模式：`WithMetrics(metrics Metrics)`、`WithMergeStrategy(strategy)`、`WithFailFast(bool)`、`WithAllowUnknownFields()`、`WithMaxDepth(n)`、`WithSourceName(name)`。Config 通过 `Validate()` 强制校验，`Sanitize()` 返回 SanitizedConfig。

## 9. 错误模型
typed error：不使用 sentinel `ErrXxx`，采用 `ErrorKind` 枚举（12 值：config/validation/connection/unavailable/timeout/auth/conflict/rate_limit/canceled/not_found/already_exists/internal）+ `*Error{Kind, Op, Message, Cause, Retryable}` 结构体。Error() 格式：`"<kind>: <op>: <message>"`。支持 `errors.As` / `errors.Is` / `Unwrap` 链。`IsKind(err, kind)` 类型安全判别。Retryable 字段供调用方决定是否重试。ctx nil → validation；ctx 超时 → timeout(Retryable=true)；ctx 取消 → unavailable。

## 10. 日志规范
configx 通过 Metrics 接口（FR-013）输出结构化指标，不直接 emit 日志。错误消息中绝不包含环境变量值或 SecretString 原始值（FR-007 全路径脱敏）。SanitizedManifest（FR-011）提供安全快照用于日志输出。具体日志格式遵循 observex 全局规范；本模块未定义独立 structured logging 字段规范（SPEC §17 仅定义 Metrics）。

## 11. Metrics
8 标准指标（SPEC §17.1）：`client_created_total`（Counter）/ `client_closed_total`（Counter）/ `client_errors_total`（Counter）/ `client_health_status`（Gauge）/ `client_health_latency_ms`（Gauge）/ `client_requests_total`（Counter）/ `client_request_duration_seconds`（Histogram）/ `client_retries_total`（Counter）/ `client_inflight`（Gauge）。Metrics 接口：`IncCounter / ObserveHistogram / SetGauge`，未配置时使用 NoopMetrics 零开销空实现。

## 12. Tracing
SPEC §17 未定义独立 Tracing 接口。configx 作为配置加载库无长尾请求路径，不强制 trace span。HealthCheck（FR-012）通过 LatencyMs 字段提供延迟观测。Trace span 约定遵循 observex 全局规范（SPEC 未细化）。

## 13. Reliability
- 显式加载（BR-004）：调用方必须显式 AddSource 每个 Source，TestNoImplicitConfigDiscovery 验证无隐式发现路径
- 并发安全：Client 和 Loader 均使用 sync.RWMutex 保护（FR-001/002）
- Load 失败可重试：失败后状态不变，可安全重试（SPEC §12）
- FailFast 模式：WithFailFast(true) 时 Source 失败立即返回不继续加载
- EffectiveConfigHash 可复现：相同配置两次调用返回相同 SHA-256（FR-010）

## 14. Security
- 敏感配置不写日志：SecretString 全格式化脱敏（***）；SanitizedManifest 安全快照
- SecretPolicy 可配置：默认 7 模式（secret/password/passwd/token/_key/credential/auth）+ CustomMatcher；`isSensitiveFieldName` 覆盖 Key/Pass/Credential/Auth/Private 后缀
- 配置文件权限检查：启动时检查（Unix: 不允许 other 可写），过宽则 warning
- 环境变量不泄露：错误消息不含环境变量值
- 依赖安全扫描：CI `govulncheck ./...`
- 静态凭证扫描：CI `gitleaks detect --no-git` 阻塞硬编码凭证
- 不可信输入校验：StrictDecode 默认拒绝未知字段

## 15. Performance SLO
| 操作 | 目标 | 测量 |
| --- | --- | --- |
| 配置加载（1000 个 key） | < 50ms | benchmark test |
| Get 单次调用 | < 100ns | benchmark test |
| 并发 Get（100 goroutine） | 无显著退化 | benchmark test |
| 常驻内存 | < 5MB | profiling |
| 测试覆盖率 | ≥ 80%（实际 97.1%） | go test -coverprofile |

## 16. 测试标准
测试覆盖率 97.1%（NFR-001 目标 ≥ 80%），8 packages、93+ 测试函数、6 Benchmark。测试类型：单元测试（12 files）、Boost 测试（7 files）、Fuzz 测试、Property 测试、Golden 测试、Precedence 测试、Benchmark。AC-001 ~ AC-005 + TC-001 ~ TC-009 全部 Verified（2026-06-18）。重点 TC：TC-001 LastWins 合并、TC-002 StrictDecode、TC-003 SecretString 脱敏、TC-008 nil context 拒绝、TC-009 Release DoD 门禁。

## 17. Chaos
configx 为配置加载库，主要外部交互为文件系统读取（含 NFS/网络挂载场景）。混沌维度（SPEC §12）：配置文件读取超时（NFS/网络挂载）→ ctx 超时返回错误；超大配置文件（>10MB）→ 正常解析；并发 Load 竞态 → Loader.mu 保护；配置加载失败重试 → 状态不变可安全重试。网络故障/依赖崩溃/慢响应类混沌不适用（无网络/进程交互）。

## 18. Contract
公开接口契约由 SPEC §8 严格定义（Client/Config/Loader/Source/Option 模式）。Source interface：`Name() / Kind() / Load(ctx) (Map, error)`。数据模型 §9：Value/Map/LoadResult/SourceReport/SecretString/SecretPolicy/Provenance。升级兼容性（SPEC §20）：新增 Source 类型/Option = minor；Source 接口变更/Metrics 指标名变更 = major；Config 新增必填字段 = minor（带默认值）。

## 19. CI Gate
通用 Gate：`GOWORK=off go build ./...` / `GOWORK=off go test ./... -race -count=1` / `GOWORK=off go test ./... -coverprofile=coverage.out`（≥ 80%）/ `go vet ./...` / `golangci-lint run ./...`（8 linter: govet/ineffassign/staticcheck/errcheck/gosec/unconvert/unparam/misspell）/ `go mod tidy && git diff --exit-code` / `gitleaks detect --no-git` / `govulncheck ./...`。
专属 Gate：不依赖 kernel（`go list -deps | grep kernel`）、无全局状态（源码静态检查）、显式加载（TestNoImplicitConfigDiscovery）。

## 20. Release Gate
ACCEPTANCE §5 DoD 全部完成（2026-06-18）：[x] FEATURES/ACCEPTANCE 与 SPEC/TRACEABILITY 一致；[x] AC/TC 与运行时测试名一致；[x] go test/-race/vet/coverage 通过（total 94.0% / pkg/configx 98.5%）；[x] 外部服务依赖有测试替身（无外部依赖）；[x] 安全检查通过（check_secrets.sh / check_boundary.sh / check-no-global-state.sh / check_contracts.sh 全 PASS）；[x] 版本号/标签/CHANGELOG 一致（release/manifest/latest.json checks 全 passed）。

## 21. Versioning
semver。运行时 module-version v1.1.0（已发布）。go.mod：`module github.com/ZoneCNH/configx`，`go 1.23`，依赖 `gopkg.in/yaml.v3 v3.0.1` + `github.com/pelletier/go-toml/v2 v2.3.1`。版本基线：v1.0.0 git tag 曾与 version.go=v0.1.3 漂移，已修复；此后 version.go/CHANGELOG/git tag 严格同步。v1.1.0 完整交付 5 项 MUST（ArgsSource/RemoteSource SPI/Bind/ConfigSnapshot+ChangeEvent+Watch+Rollback/DocGen）。

## 22. 兼容性策略
向后兼容（SPEC §20）：新增 Source 类型/Option/LoaderOption = minor；Source 接口变更 = major；Config 新增必填字段 = minor（带默认值）；SecretPolicy 模式变更 = minor；Metrics 指标名变更 = major。边界情况（SPEC §12）：空配置文件/纯注释文件返回空 Map 不报错；环境变量空字符串视为设置空值；点分路径中间节点不存在自动创建；nil Client 调用 Close/HealthCheck 返回 validation error 不 panic。

## 23. Failover
Load 失败可安全重试（状态不变）。FailFast=false 时某 Source 失败不阻断后续 Source 加载（默认聚合错误）。ctx 超时/取消返回 Retryable=true 错误，调用方可重试。HealthCheck（FR-012）返回 Status（healthy/degraded/unhealthy）供上游决策。EffectiveConfigHash 用于检测配置漂移，相同 hash = 配置一致。无进程级 config singleton（BR-009），Client 实例独立隔离。

## 24. Backpressure
配置加载为一次性操作，无持续流量需 backpressure。并发保护：Client 和 Loader 均使用 sync.RWMutex 保护并发 Load + HealthCheck（SPEC §12）。超大配置文件（>10MB）正常解析无内存溢出保护门禁（SPEC 未定义上限）。HealthCheck LatencyMs 用于观测健康检查延迟。Retryable 字段供调用方决定重试策略。

## 25. 审计要求
Provenance 来源追踪（FR-009）：每个 key 记录 Source/Priority/OverrideEntry 链路，`Provenance.Snapshot()` 返回全量拷贝按 key 排序。EffectiveConfigHash（FR-010）提供 SHA-256 配置指纹用于审计比对（排除 volatile 字段，可复现）。SanitizedManifest（FR-011）生成安全快照用于审计日志。SourceReport 记录每个 Source 的 Name/Kind/Path/Loaded/Error/LoadedAt/ValueKeys。metrics `client_created_total` / `client_closed_total` 记录生命周期审计点。

## 26. 熵减规则
全局 Entropy Rules + 模块特有禁项：
- BR-009：无全局状态（无包级 `var Client` / 无进程级 config singleton / 无 init() 副作用）
- BR-004：显式加载（调用方必须显式 AddSource，无隐式文件扫描/约定目录发现）
- 禁止 util dumping（pkg/configx 按职责切分 20+ 文件）
- 禁止 hidden abstraction（公开接口 §8 严格定义）
- 禁止 sentinel error 变量（统一 *Error + ErrorKind 枚举）

## 27. AI Constraints
全局 AI Constraints + 模块特有约束：
- 禁止新增未注册 Source 类型（内置 7 种 Source 固定，新增走 SPEC + FR 流程）
- 禁止绕过 contracts（公开 API 变更须保持向后兼容，Source 接口变更走 major）
- 禁止动态扩展目录（pkg/configx 结构固定）
- 禁止引入 kernel 依赖（NFR-005，foundationx exit 已完成）
- 禁止创建全局状态（BR-009）
- AI 生成代码必须通过 8 linter + coverage ≥ 80% + 无隐式发现测试

## 28. Forbidden Patterns
- 禁止 global mutable state（无包级 var Client，BR-009）
- 禁止 shared singleton chaos（Client 由 New 显式创建，非单例）
- 禁止 init() 副作用（BR-009 源码静态检查）
- 禁止隐式配置发现（BR-004 TestNoImplicitConfigDiscovery 阻断）
- 禁止 sentinel error 变量（BR-008 统一 *Error + ErrorKind）
- 禁止错误消息泄露环境变量值/SecretString 原始值（BR-005）

## 29. Production Ready Checklist
- [x] observability ready（8 Metrics 指标 + NoopMetrics + HealthCheck，FR-012/013 已交付）
- [x] contract ready（Source/Client/Loader 接口契约 + SanitizedManifest + EffectiveConfigHash，AC-001~005 Verified）
- [x] audit ready（Provenance 来源追踪 + SourceReport + gitleaks 零泄露）
- [x] security ready（SecretString 全路径脱敏 + SecretPolicy 7 模式 + govulncheck + StrictDecode）
- [x] explicit loading ready（显式 AddSource，TestNoImplicitConfigDiscovery Verified，BR-004）
- [x] ci gate ready（8 linter + coverage 97.1% + race + vet + boundary + no-global-state + contracts 全 PASS）
- [~] resilience ready（FailFast/重试/并发安全已交付；Watch 文件监控推迟到 v1.1，TASK-CONFIGX-007 显式标记）

## 30. Roadmap
- v1.0.0（2026-06-07）：初始版本
- v1.0.0（2026-06-12）：完整重写，基于实际 v1.0.0 代码（97.1% 覆盖率），对齐 Client/Loader/Source/SecretString/Provenance/StrictDecode 真实 API
- v1.1.0（2026-06-18）：已发布，完整交付 5 项 MUST（ArgsSource、RemoteSource SPI、Bind()、ConfigSnapshot/ChangeEvent/Watch/Rollback、配置文档自动生成）
- Future（OQ-001~004 待评估）：运行时配置热更新（Watch）、配置版本管理、远程配置源（etcd/consul/vault）、配置模板
