# taosx

## 1. 模块定位
ZoneCNH 基座层 TDengine 时序存储适配器契约模块（Layer L2 存储适配器），v1.0.3。面向 IoT 时序场景（高频传感器/行情写入、时间窗口查询、设备监控），基于 TDengine 超级表（supertable）模型优化写入吞吐。Status=Approved，本地发布候选。与 clickhousex 互补：taosx=IoT 时序存储，clickhousex=OLAP 分析查询。

## 2. 生产职责
- FR-001：`Config.Normalize` 补齐默认值（空名称→taosx、空驱动→websocket、零超时→5s）。
- FR-002：`Config.Validate` 拒绝缺失 endpoint/database、非法驱动模式、负超时/重试。
- FR-003：`New(ctx, config, opts...)` 构造，默认驱动显式不可用，`WithDriver` 注入后委托。
- FR-004/005：`Exec`/`Query` 空输入拒绝，非空委托驱动。
- FR-006/007：`WriteBatch`/`SchemalessWrite` 批量/无模式写入契约。
- FR-008/009/010：`Health`/`Close`（幂等）/`Metrics`（可选 no-op）。

## 3. 边界定义
- 直接 foundation 依赖只允许 `kernel`（BR-001）；驱动/指标/配置通过端口注入。
- 不在核心包内读取环境变量、配置文件或远程配置中心（SPEC §3）。
- 默认驱动必须显式不可用，避免零配置被误认为真实 TDengine 连接（BR-005）。
- 官方 `taosWS` WebSocket 集成必须显式 opt-in（`TAOSX_INTEGRATION=1` + `integration` tag，BR-008）。

## 4. 不负责什么
- 不把真实 TDengine 连接做成核心包默认行为（SPEC §3）。
- 不实现连接池、核心包内置生产驱动或凭据管理。
- 不实现 STMT 写入、自动建表、schema migration、流式订阅或业务级时序模型。
- 不直接依赖 `configx`/`observex`/`resiliencx`；由调用方在边界外组合。
- 不保证原始 SQL 的注入安全；只拒绝空 SQL（BR-006）。

## 5. 架构位置
基座层（L2 存储适配器）。依赖方向：仅 kernel。被 `market-data`采集层、`order-engine`、`risk-engine`、`factor-engine`、`backtestx`、`observex` 适配器层、`x.go`/`maestro` 上层编排消费。生产 driver 由调用方注入，核心包只负责端口契约。

## 6. 生命周期
- `New`：校验 ctx/config/options，默认驱动显式不可用，注入驱动后委托（FR-003）。
- `Close(ctx)`：首次关闭成功，重复幂等返回 nil，关闭后任何操作返回 closed 错误（FR-009）。
- `Health(ctx)`：驱动未注入→degraded（mode=websocket + database 名 + redacted 错误）；注入→委托 Driver.Health 映射 nil→ready、error→degraded/unhealthy（FR-008）。
- Client 构造后可被并发调用；Close 关闭过程中不得 panic（SPEC §12）。

## 7. 标准目录结构
```text
module/taosx/
  SPEC.md / goal.md / TRACEABILITY.md / IMPLEMENTATION-PLAN.md
  tasks/              # 任务拆分制品（TASK-TAOSX-001..006）
  contracts/          # 契约测试（驱动合规验证）
  examples/           # 可运行示例
# runtime repo /home/taosx/.worktree/workspaces/taosx-20260619
#   pkg/taosx (Config/Client/Driver/Rows/Batch/SchemalessPayload/Metrics)
```

## 8. 配置规范
`Config` 结构体：Name、DriverMode(websocket)、Endpoint、Database、Username、Password、Timeout(5s)、MaxRetries(保留字段，不代表自动重试 BR-004)、TLS。`Normalize()` 只补齐安全默认值不连接外部系统；`Validate()` 拒绝空 endpoint/database、非法驱动模式、负超时/重试；`RedactedDSN` 不输出密码（SPEC §11）。

## 9. 错误模型
错误带操作名（`taosx.<Operation>`）+ 分类 + 可脱敏上下文。分类：validation（配置缺失/空 SQL/空 batch/非法协议）、unavailable（驱动未注入）、closed（Close 后操作）、context canceled、deadline exceeded、驱动透传（保留原始 cause）。日志/DSN/状态不得暴露密码（BR-003）。

## 10. 日志规范
模块通过可选 `Metrics` 端口接入 observability；遵循 observex 全局规范。默认 no-op 零配置可用（FR-010）。失败输出不得包含 DSN/用户名/密码（BR-007）。健康状态不含明文密码或完整 DSN（SPEC §14）。

## 11. Metrics 规范
可选 `Metrics` 端口，默认 no-op 零开销。注入后记录 `taosx_client_request_total`、`taosx_client_duration_seconds`、`taosx_client_error_total`、`taosx_client_health_status`、`taosx_client_batch_rows`、`taosx_client_schemaless_lines`（FR-010）。指标名统一 `taosx_client_*` 前缀，只记录低基数标签（NFR-003）。

## 12. Tracing 规范
SPEC 未定义独立 Trace span 约定；通过 Metrics/Logger 端口由调用方接入 observex tracer。遵循 observex 全局 span 规范（SPEC未细化）。

## 13. Reliability 规范
- `MaxRetries` 是配置契约保留字段，不代表核心 client 自动重试（BR-004）；重试策略由驱动适配器或上层 resilience 组合。
- `Close` 必须幂等，关闭过程不得 panic，关闭后操作返回可分类 closed 错误（FR-009、NFR-002）。
- Client 构造后可被并发调用，Client 层不做额外序列化，驱动必须线程安全（SPEC §10）。
- 真实集成测试失败阻塞外部 release（BR-008）。

## 14. Security 规范
- 错误/状态/日志/测试失败输出/示例均不得暴露真实密码、API key、私有 endpoint 或账户信息（NFR-004）。
- 示例凭据必须用环境变量或占位符表达。
- `Config.RedactedDSN` 即使 Password 为空也不应暗示凭据结构（SPEC §10）。
- 官方 taosWS 集成测试凭据脱敏，输出不记录 endpoint/用户名/密码（BR-008）。

## 15. Performance SLO
核心包本地校验路径性能预算（SPEC §13）：Config.Normalize+Validate < 5μs、New() 无驱动 < 50μs、Exec/Query 空输入拒绝 < 500ns、WriteBatch 空 batch 拒绝 < 1μs、Health() 默认驱动 < 1μs、Close 重复幂等 < 500ns、No-op Metrics 零分配（`allocs/op = 0`）。驱动委托路径延迟由注入驱动决定，不在核心包预算内。

## 16. 测试标准
AC-TAO-001..010 + TC-001..TC-019 覆盖 Config 归一化/校验/脱敏、New 默认不可用/驱动注入、Exec/Query 空输入拒绝/委托、WriteBatch/SchemalessWrite、Health degraded/透传、Close 幂等/拒绝、Metrics no-op/记录。`pkg/taosx` 覆盖率 100.0%（`make taosx-coverage-check`）、`go test -race`、契约测试 `./contracts`、`staticcheck`/`govulncheck`、`check_boundary.sh`/`check_dependency_diff.sh`。

## 17. Chaos 标准
SPEC §10 边界场景：空 SQL/Query/Batch、驱动未注入、ctx 取消、WriteBatch 部分成功（N-M 行 + 错误详情）、SchemalessWrite 协议非法、重复 Close、Close 后操作、并发读写、TLS=true 驱动不支持、超时触发、Config 零值字段。真实 TDengine 故障/连接断开由驱动适配器处理（核心包不内置）。

## 18. Contract 标准
`Client` interface：Exec/Query/WriteBatch/SchemalessWrite/Health/Close。`Driver` interface：同 Client 操作 + Health(ctx) error + Close(ctx) error。`Config`/`Statement`/`Query`/`Rows`/`Batch`/`Point`/`SchemalessPayload`/`WriteResult`/`HealthStatus` 数据模型。`Option`：`WithDriver`/`WithMetrics`。v1.0.3 不改变 v1.0.0 公共构造入口与核心接口语义（NFR-006）。

## 19. CI Gate
单元 `go test ./pkg/taosx`、Race `go test -race ./pkg/taosx ./contracts`、覆盖率门禁 `make taosx-coverage-check`（< 100.0% 阻断）、契约 `go test ./contracts`、示例 `go test ./examples/...`、全量 `go test ./...`、`make release-check`、`staticcheck`/`govulncheck`、`check_boundary.sh`/`check_contracts.sh`/`check_dependency_diff.sh`、集成默认防护（未 opt-in pass/skip）、live opt-in（`TAOSX_INTEGRATION=1`）、`git diff --check`、凭据泄漏 grep。

## 20. Release Gate
SPEC §19 + ACCEPTANCE §5 DoD：FEATURES/ACCEPTANCE 与 SPEC/TRACEABILITY 一致、AC/TC 与 runtime 测试名/证据一致、runtime 通过 go test/race/vet/覆盖率门槛、外部服务依赖有本地替身或 live-gate 证据、安全检查无凭证泄漏、版本号/发布标签/CHANGELOG 一致。v1.0.3 本地发布候选：源码 worktree `taosx` @ `d46af01`，release evidence hash `c78f9de861cf83434140fc0e0e051e91af71736ec2d22f0ce1c0cf74c9a87f61`。

## 21. Versioning
semver。v1.0.3 不改变 v1.0.0 公共构造入口与核心接口语义（NFR-006）。新增字段/方法/错误分类保留旧调用方编译兼容性，破坏性变更进后续 major。从 v1.0.2 升级只需重新运行验证命令，已注入 driver/metrics/测试适配器的项目不需调整构造方式（SPEC §18）。

## 22. 兼容性策略
v1.0.3 保持 v1.0.0 公共 API 与适配器边界不变。核心包不持久化状态、不写 schema、不管理连接池，因此回滚不需要数据迁移。Config 零值字段经 Normalize 补齐默认值，Validate 在 Normalize 后执行（SPEC §10）。

## 23. Failover 策略
核心包不内置自动重试（BR-004）；`MaxRetries` 仅为配置契约保留字段。重试/故障转移由驱动适配器或上层 `resiliencx` 组合实现。默认驱动显式不可用→操作返回 unavailable 错误、Health 返回 degraded（BR-005、FR-008）。回滚可退到上一已验证候选或 tag（当前 v1.0.2），无需数据迁移（SPEC §20）。

## 24. Backpressure 策略
核心包不内置连接池（SPEC §3），连接并发由注入驱动管理。WriteBatch 部分失败返回 partial result（RowsAffected=N-M）+ 错误详情（FR-006）。Client 构造后可被并发调用，Client 层不做额外序列化，驱动必须线程安全（SPEC §10）。空 batch/空 lines 在本地校验路径快速拒绝（< 1μs）。

## 25. 审计要求
Metrics 端口记录 request_total/duration_seconds/error_total/health_status/batch_rows/schemaless_lines（FR-010）。Health 状态包含 mode/database 名/redacted 错误，不含密码（FR-008）。错误带 `taosx.<Operation>` 操作名用于追溯（BR-003）。集成测试输出不记录 endpoint/用户名/密码/完整 DSN（BR-007/008）。

## 26. 熵减规则
全局：禁止 util dumping、hidden abstraction、cyclic dependency。模块特有：核心包不内置连接池/STMT/自动建表/schema migration（SPEC §3），驱动/指标/配置通过端口注入避免运行时耦合。默认驱动显式不可用避免零配置误导。原始 SQL 只做空值校验不声明注入防护（BR-006）。

## 27. AI Coding Constraints
全局：AI 不允许新增未注册模块、绕过 contracts、动态扩展目录。模块特有：AI 不得把真实 TDengine 连接做成默认行为、不得在核心包读环境变量/配置文件、不得声明对 configx/observex/resiliencx 的直接依赖（BR-001）、不得把真实集成测试放入默认测试路径（BR-007）。MaxRetries 不得实现为核心 client 自动重试（BR-004）。

## 28. Forbidden Patterns
- 默认驱动可用（误导用户以为能连真实 TDengine）。
- 核心包读环境变量/配置文件/远程配置中心。
- 直接依赖 configx/observex/resiliencx（超出 kernel 边界）。
- 真实集成测试进入默认测试路径或输出含 DSN/凭据。
- 把 MaxRetries 实现为核心 client 自动重试。
- 自动建表、schema migration、连接池内置。
- 全局可变状态、shared singleton chaos、runtime reflection abuse。

## 29. Production Ready Checklist
- [x] FR-001..010、BR-001..008、AC-TAO-001..010、TC-001..019 由 TRACEABILITY 闭合
- [x] `pkg/taosx` 覆盖率 100.0% / race / vet / 契约 / 示例 / staticcheck / govulncheck 通过
- [x] `make release-check` + `make taosx-coverage-check` + `make integration` 通过
- [x] 本地发布候选证据归档（commit d46af01, hash c78f9de8...）
- [x] dev live TDengine WebSocket run 通过（2026-06-19，market_binance dev 配置）
- [ ] 外部 push/tag/GitHub Release —— 本地发布候选，未对外发布
- [ ] 远端 CI / 发布制品证据
- [ ] Factory-grade 声明（外部发布证据补齐前保持非 factory）

## 30. Roadmap
- v1.0.3（本地候选）：Config 归一化/脱敏、SQL/Query/WriteBatch/SchemalessWrite 契约、Health/幂等 Close/Metrics 端口、CI/release 门禁接入、dev live gate。
- v1.x：外部发布（tag/GitHub Release/远端 CI）、factory-grade 声明。
- 开放问题（SPEC §23）：taosWS driver 是否独立为 `taosx-driver-taosws` 仓库、是否提供 STMT 批量写入端口、是否增加超级表 schema 管理契约。
