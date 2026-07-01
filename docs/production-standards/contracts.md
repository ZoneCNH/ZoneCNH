# contracts

## 1. 模块定位
contracts 是 Foundation L2.5 共享契约层，定义跨域稳定契约——端口（接口）、事件协议和 DTO。它是域间通信的唯一合法通道，确保数据域、分析域、决策域和执行域之间的接口稳定、可演进。Status=Docs Baseline Approved / Runtime Pending，Spec-version v1.2.0，module-version v1.2.0-spec（文档已批准，运行时待实现）。

## 2. 生产职责
- FR-001 MarketDataProvider 端口（Subscribe/GetSnapshot/GetHistory）
- FR-002 MacroDataProvider 端口（GetLatest/GetHistory/Subscribe）
- FR-003 Event 接口（EventID/EventType/Timestamp/Source 四方法，不可变）
- FR-004 Topic 常量（全局唯一、点分命名 domain.action）
- FR-005 DTO 契约（JSON tag snake_case、不可变、版本演进）
- FR-006 Breaking Change 检测（接口/DTO 变更感知与版本升级）
- FR-007 Module Identity（README H1 与 go.mod module path 必须为 contracts）
- FR-008 Binance C/S ingestion contract（MarketDataService + IngestRequest/IngestAck/IngestReject/IngestResult + RejectCode）

## 3. 边界定义
行为约束 BR-001 ~ BR-010：所有跨域 DTO 必须在 contracts 中定义；新增契约必须说明消费方/生产方/稳定期；契约变更是 breaking change → 需要版本升级；端口接口保持窄（3-5 方法）；事件 DTO 不可变（只读字段）；Topic 常量全局唯一点分命名；接口实现方必须有编译期检查（`var _ Interface = (*Impl)(nil)`）；contracts 只依赖 L2.5 领域共享层和 stdlib；DTO JSON tag 必须 snake_case；契约版本遵循 semver。

## 4. 不负责什么
不拥有传输实现：不做 HTTP client / gRPC server / NATS publisher / Kafka consumer / Retry middleware（→ resiliencx）/ Timeout transport（→ transportx）/ Business workflow logic。治理边界：不是标准源（xlib_standard 定义编码规范）、不是 generator（不生成代码）、不是模板仓库。不包含域内接口、临时适配器、通用工具函数、领域模型全集、业务逻辑实现、消息队列实现（→ kafkax）、存储实现（→ redisx）。

## 5. 架构位置
L2.5 共享契约层。依赖方向：可依赖 stdlib + L2.5 领域共享层（decimalx/domain_market/domain_exchange/domain_macro）；禁止依赖所有业务域实现（market_data/signal-engine 等）、Foundation L1 运行时模块（kernel/configx/observex 等）、所有存储/中间件扩展（redisx/kafkax 等）。处于依赖拓扑上层，只被业务域模块 import，不 import 任何 L1 运行时模块。

## 6. 生命周期
contracts 是纯类型定义模块（编译时依赖），自身无运行时生命周期。消费方（market_data/macro_data/factor_engine 等）实现 Provider 端口接口；x.go 组合根组装端口实现并注入到各域。Subscribe 返回 channel 持续推送事件直到 ctx 取消；GetSnapshot/GetHistory 为同步请求-响应模式。DTO 创建后不可变（只读字段）。

## 7. 标准目录结构
```text
contracts/
├── go.mod / go.sum / README.md / CHANGELOG.md / LICENSE
├── doc.go                      # 包级文档
├── contracts.go                # 版本常量 ContractVersion = "1.0.0"
├── market.go                   # MarketDataProvider, MarketEvent, MarketSnapshot, Bar
├── macro.go                    # MacroDataProvider, MacroPoint, MacroEvent
├── signal.go order.go execution.go position.go risk.go alternative.go  # 各域 DTO
├── events.go                   # Event 接口 + Topic 常量
├── ports.go                    # Provider/Consumer 端口汇总
├── errors.go                   # 公共错误变量（"contracts: <desc>"）
├── version.go                  # 版本管理 + breaking change 检测
├── internal/validate/          # DTO 校验工具
├── testdata/*.golden           # 测试 fixtures
├── example_test.go benchmark_test.go breaking_test.go
```

## 8. 配置规范
contracts 自身不加载配置，其 Go 类型定义是其他模块的编译时依赖。事件序列化配置（供 kafkax 等使用）由消费方定义：`events.serialization: json/protobuf/avro`、`events.compression: none/gzip/snappy/lz4`、`events.max_message_size: 1MB`（SPEC §10）。contracts 模块本身无 Option 模式或构造函数，纯声明式类型导出。

## 9. 错误模型
公共错误变量（sentinel var，SPEC §9.1）：`ErrInvalidSymbol` / `ErrInvalidIndicator` / `ErrInvalidTimeRange` / `ErrEmptySymbols` / `ErrEmptyIndicators` / `ErrSymbolNotFound` / `ErrIndicatorNotFound`。错误消息格式统一：`"contracts: <desc>"`（NFR-008 CI Gate 强制检查）。错误包装使用 `%w` 保留底层错误链。Binance ingestion 使用 RejectCode 枚举（retryable/terminal_validation/terminal_conflict/unauthorized/rate_limited/server_unavailable/contract_violation/quality_rejected/ordering_violation/unsupported_channel）分类拒绝原因。

## 10. 日志规范
SPEC §17 定义 3 个 log 点：`contracts.subscribe.started`（info，订阅开始含 symbols/indicators）、`contracts.subscribe.error`（error，订阅失败含 error）、`contracts.event.published`（debug，事件发布含 topic 和 event_id）。Event.Source() 使用标识符，不包含内部路径（安全要求）。具体日志 implementation 由消费方注入（contracts 不依赖 observex）。

## 11. Metrics
SPEC §17 定义 3 个 metric：`contracts.event.count`（counter，事件发布数量按 topic 分组）、`contracts.event.size`（histogram，事件消息大小）、`contracts.subscribe.active`（gauge，活跃订阅数）。metrics 由消费方实现注入；contracts 自身不 emit 指标（纯类型定义层）。

## 12. Tracing
SPEC 未定义独立 Tracing 接口。contracts 作为纯类型定义层无请求路径，不强制 trace span。事件流（Subscribe channel 推送）的 tracing 由消费方（market_data 等）通过 observex 实现。Event.EventID() 提供全局唯一标识可用于日志关联，但不等同于 trace span。

## 13. Reliability
- BR-007：接口实现方必须有编译期检查（`var _ Interface = (*Impl)(nil)`），运行时 panic 风险前置到编译期
- FR-006：Breaking Change 检测（接口方法增删/DTO 字段删除/类型变更触发 major 版本升级）
- 事件 DTO 不可变（BR-005）：防止并发消费时非确定性行为
- Subscribe 传入重复 symbol 去重后订阅不报错；GetHistory 返回空结果返回空 slice 不报错
- retry/timeout/circuit breaker 不在 contracts 范围（→ resiliencx / transportx）

## 14. Security
- DTO 不包含敏感数据：只包含交易数据，不含密钥/密码
- 事件不泄露内部实现：Event.Source() 使用标识符，不包含内部路径
- 序列化安全：JSON 序列化不执行任意代码
- IngestRequest.Source 不得包含密钥、主机路径或环境特定 token
- IngestRequest.SourceMetadata 不得包含 secrets（至少含 stream_id 和 connector_version）
- Secret 扫描 CI Gate（NFR-004 gitleaks detect）

## 15. Performance SLO
| 操作 | 目标 | 测量 |
| --- | --- | --- |
| DTO JSON 序列化 | < 1μs | benchmark test |
| DTO JSON 反序列化 | < 1μs | benchmark test |
| Event 接口调用 | < 100ns | benchmark test |
| 编译期检查 | < 1s | go build |
| breaking change 检测 | < 5s | go test -run TestBreakingChange |
| Benchmark 回退阈值 | ≤ 10% | CI Benchmark 对比（NFR-006） |

## 16. 测试标准
单元测试覆盖率 ≥ 80%（NFR-001）。测试类型：编译期检查（var _ Interface = (*Impl)(nil)）、DTO JSON round-trip、Topic 唯一性、Event 接口完整性、DTO 不可变性、错误格式检查、JSON tag snake_case、Breaking change 检测、Module Identity。TC-001 ~ TC-009 已登记（运行时 Pending）。Benchmark 3 项（DTO 序列化/反序列化/Event 调用）。集成测试：跨域数据流、事件发布消费、版本兼容。

## 17. Chaos
contracts 为纯类型定义层，无运行时进程/网络/存储交互，不适用网络故障/依赖崩溃/慢响应类混沌测试。可靠性通过编译期保证（BR-007 接口实现检查）+ breaking change 检测（FR-006）+ DTO 不可变性（BR-005）静态保证。并发消费场景的确定性由事件 DTO 不可变性保证。具体混沌维度遵循 README 全局规范，本模块待定义（SPEC 未细化）。

## 18. Contract
**§18 是 contracts 模块的核心**。公开接口契约由 SPEC §8 严格定义：
- §8.1 数据输入端口：MarketDataProvider（3 方法）、MacroDataProvider（3 方法）、AlternativeDataProvider（2 方法）
- §8.2 事件协议：Event 接口（EventID/EventType/Timestamp/Source）+ 9 个 Topic 常量（market.data/macro.data/alt.data/signal.generated/order.submitted/execution.filled/position.updated/risk.alert/alternative.data）
- §8.3 核心 DTO：MarketEvent/MarketSnapshot/Bar/HistoryRequest/MacroPoint/MacroEvent/MacroHistoryRequest
- §8.4 Binance C/S ingestion wire contract：MarketDataService.Ingest(stream) + IngestRequest（11 必填字段）/IngestResult/IngestAck/IngestReject/RejectCode（10 值枚举）
- §8.4.1 字段约束表 + §8.4.2 生产者/消费者 + §8.4.3 与 MarketDataProvider 关系
- §8.4 命名约定：contracts JSON tag (snake_case) ↔ domain_market Go field (PascalCase) ↔ market_data doc field (camelCase)

## 19. CI Gate
通用 Gate：`go build ./...` / `go test ./... -race -count=1` / 覆盖率（`go test -coverprofile` ≥ 80%）/ `go vet ./...` / `golangci-lint run` / `go mod tidy && git diff --exit-code` / `gitleaks detect --no-git` / `go test -bench=. -benchmem -count=3`。
专属 Gate：`go test -run TestBreakingChange`（breaking change 检测）、`go test -run TestCompileCheck`（编译期检查）、`go test -run TestTopicUniqueness`（Topic 唯一性）、PR 必须说明消费方/生产方/稳定期（新增契约审查）。

## 20. Release Gate
ACCEPTANCE §5 DoD（当前全部 Pending，运行时待实现）：[ ] FEATURES/ACCEPTANCE 与 SPEC/TRACEABILITY 一致；[ ] AC/TC 与运行时测试一致；[ ] go test/-race/vet/coverage 通过；[ ] 外部服务依赖有测试替身；[ ] 安全检查通过；[ ] 版本号/标签/CHANGELOG 一致。SPEC §21 另列发布 DoD：godoc 注释 / JSON tag snake_case / Binance C/S ingestion contract defined / Event 接口满足 / breaking change 测试 / 编译期检查 / topic 唯一性 / 新增契约三方说明。

## 21. Versioning
semver。module-version v1.2.0-spec（文档基线）。ContractVersion = "1.0.0"（运行时常量）。go.mod：`module github.com/ZoneCNH/contracts`，`go 1.23`。升级兼容性（SPEC §20）：端口接口新增/删除/修改方法 = major；DTO 删除/修改字段 = major；DTO 新增可选字段 = minor；新增 Topic 常量/端口接口/DTO 类型 = minor；删除/重命名 Topic 常量 = major；Event 接口变更 = major。VersionInfo 记录 Version/ReleasedAt/Changes（type=breaking/feature/fix）。

## 22. 兼容性策略
向后兼容（SPEC §20）：新增可选字段（有默认值）使用 optional 语义（指针或默认值），不能删除或重命名已有字段。breaking change 检测（FR-006）通过 `breaking_test.go` 编译期检查感知接口/DTO 变更。版本兼容测试：新版本 DTO 可反序列化旧版本数据（SPEC §15.4）。边界情况（SPEC §12）：GetHistory 时间范围过大由实现方决定分页；Event channel 已满由实现方决定阻塞或丢弃；DTO 字段为零值序列化为零值不省略。

## 23. Failover
contracts 为纯类型定义层，无运行时故障需 failover。Subscribe channel 关闭后读取返回零值（channel 关闭信号）。GetHistory 返回空 slice 不报错。reject 语义通过 RejectCode 分类（retryable/server_unavailable 允许重试；terminal_validation/terminal_conflict/unauthorized 不重试），供 adapter 决策重试策略。breaking change 检测阻止不兼容版本发布，保证消费方编译稳定性。

## 24. Backpressure
contracts 为纯类型定义层，无持续流量需 backpressure。Subscribe channel 满时由实现方决定阻塞或丢弃最旧消息（SPEC §12 边界情况）。IngestRequest.OrderingKey（可选分区键 "{source}:{product_line}:{instrument}:{channel}"）供 server 保证同 key 内顺序。事件 DTO 不可变（BR-005）防止并发消费时数据竞争。具体 backpressure 策略由消费方实现（market_data/kafkax 等）。

## 25. 审计要求
Topic 常量全局唯一（BR-006 TC-004 验证）保证消息路由可审计。Event.EventID() 全局唯一标识 + Event.Source() 来源标识用于事件溯源。VersionInfo + Change 记录每次契约变更的类型/描述/影响范围（审计追踪）。RejectCode 分类拒绝原因供 adapter 审计。新增契约必须说明消费方/生产方/稳定期（BR-002 PR 审查 Gate）。Module Identity（FR-007）确保模块边界可审计（README H1 + go.mod module path）。

## 26. 熵减规则
全局 Entropy Rules + 模块特有禁项：
- BR-001：所有跨域 DTO 必须在 contracts 中定义（禁止散落各域）
- BR-008：contracts 只依赖 L2.5 领域共享层和 stdlib（禁止循环依赖）
- 禁止 util dumping（按域切分 market.go/macro.go/signal.go 等独立文件）
- 禁止 hidden abstraction（端口接口 §8 严格定义，3-5 方法窄接口）
- 禁止传输实现混入（§4.2 明确 MUST NOT own HTTP/gRPC/NATS/Kafka）

## 27. AI Constraints
全局 AI Constraints + 模块特有约束：
- 禁止新增未注册 Topic 常量（9 Topic 固定，新增走 SPEC + FR-004 流程）
- 禁止绕过 contracts（跨域 DTO 必须在 contracts 定义，BR-001）
- 禁止动态扩展目录（文件结构按域切分固定）
- 禁止引入传输实现（§4.2 MUST NOT own，违反治理边界）
- 禁止接口超过 5 方法（BR-004 窄接口）
- AI 生成 DTO 必须有 snake_case JSON tag（BR-009）+ 不可变字段（BR-005）

## 28. Forbidden Patterns
- 禁止 global mutable state（contracts 为纯声明式类型导出，无可变状态）
- 禁止可变 DTO 字段（BR-005 事件 DTO 只读）
- 禁止接口实现无编译期检查（BR-007 `var _ Interface = (*Impl)(nil)` 强制）
- 禁止 Topic 非点分命名/重复（BR-006 domain.action 全局唯一）
- 禁止 DTO JSON tag 非 snake_case（BR-009）
- 禁止传输实现混入（HTTP/gRPC/NATS/Kafka client，§4.2）
- 禁止依赖 L1 运行时模块（BR-008 循环依赖风险）

## 29. Production Ready Checklist
- [~] contract ready（§8 接口契约文档完整定义，SPEC v1.2.0-spec Docs Baseline Approved；运行时实现 Pending）
- [~] breaking change detection ready（FR-006 + breaking_test.go 设计完成；运行时 Pending）
- [~] compile-time check ready（BR-007 var _ Interface 模式定义；运行时 Pending）
- [~] topic uniqueness ready（FR-004 + 9 Topic 常量定义；TC-004 运行时 Pending）
- [~] module identity ready（FR-007 README H1 + go.mod module path 约束；TC-008 运行时 Pending）
- [~] binance ingestion contract ready（FR-008 §8.4 完整 DTO + RejectCode 10 值定义；TC-009 运行时 Pending）
- [ ] ci gate ready（通用 8 Gate + 专属 4 Gate 定义完成；ACCEPTANCE §6 登记运行时 Pending，/home/workspace/contracts 实现待归档）
- [ ] release dod ready（ACCEPTANCE §5 DoD 6 项全部 Pending，运行时证据待归档）

## 30. Roadmap
- v1.0.0（2026-06-07）：初始版本
- v1.0.1-spec（2026-06-14）：TRACEABILITY §1-§7 完整重建（6 FR + 10 BR + 8 NFR + 7 TC + 15 AC），FR-006 去测试化 + BR 违反后果列
- v1.1.0-spec（2026-06-14）：§5 边界声明重构（OWN/MUST NOT OWN/governance boundary）+ FR-007 Module Identity
- v1.2.0-spec（2026-06-17）：§8.4 Binance C/S ingestion wire contract（MarketDataService + IngestRequest + IngestAck + IngestReject + RejectCode），FR-008，TC-009，DoD 条目
- Future（SPEC §22 待解决问题）：端口批量操作、请求-响应 RPC 端口、protobuf 序列化、跨域命令接口、EventVersion()、事件 schema registry
