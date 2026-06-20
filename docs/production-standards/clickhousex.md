# clickhousex

## 1. 模块定位
ZoneCNH 基座层 ClickHouse 客户端模块（Layer L2 基础设施适配器），封装连接管理、原生 batch insert、OLAP 查询和可观测集成，面向分析域（因子回看、收益归因、风险归因）。Status=Approved，Module-Version v1.0.8（Spec v1.0.1）。与 taosx 互补：clickhousex=OLAP 分析查询，taosx=IoT 时序存储。

## 2. 生产职责
- FR-001：`NewClient(cfg)` 创建连接池 + DSN 校验。
- FR-002：`Exec(ctx, sql, args...)` 执行 DDL/DML，支持 context 取消、连接断开恢复。
- FR-003：`Query(ctx, sql, args...)` 返回可迭代 `Rows`，空结果无错误。
- FR-004：`InsertBatch(ctx, table, cols, rows)` 原生 batch insert 协议批量写入。
- FR-005：`Health()` 返回 Ready/Live/Message 健康状态。
- FR-006：`Close()` 幂等关闭连接池，等待进行中查询。
- FR-007/008：`Rows.Next/Scan/Close/ColumnTypes` 行扫描 + ClickHouse 类型映射。

## 3. 边界定义
- 仅依赖 kernel（L0）+ observex（interface-only）+ clickhouse-go 驱动 + shopspring/decimal（BR-001）。
- 禁止直接依赖 configx（SPEC §14.2，CI Gate `go list -deps | grep configx`）。
- 禁止依赖业务域、L2.5 共享层、其他存储扩展（taosx/ossx 等）。
- 所有 Exec/Query/InsertBatch/Ping/HealthCheck/CloseContext 接受 `context.Context`（BR-006）。

## 4. 不负责什么
- 不做 ClickHouse 集群管理、部署编排、分布式查询路由（SPEC §4）。
- 不做数据模型定义（表 schema 由业务层决定）、不自动建表（BR-010）。
- 不做数据压缩（原生支持）、数据迁移或 schema migration。
- 不做 SQL 拼接 DSL（调用方传 raw SQL）、物化视图/字典管理。

## 5. 架构位置
基座层（L2 存储扩展）。依赖方向：kernel + observex(interface) + ClickHouse driver + decimal lib。被 `factor_engine`/`signal-engine`/`backtest_engine`/`risk_engine` 和 `x.go` 组合根消费。observex 实现在 x.go 组装时注入（interface-only import）。

## 6. 生命周期
- `NewClient`：校验 Config（DSN 非空），初始化连接池。
- `Health`：幂等无副作用，连接池可用→Ready/Live=true，不可用→false+Message，部分可用→low pool capacity（FR-005）。
- `Close`：关闭所有连接池，幂等（重复调用返回 nil 不 panic），有进行中查询时等待或超时后强制关闭（FR-006、BR-009）。

## 7. 标准目录结构
```text
clickhousex/
├── go.mod / go.sum / README.md / CHANGELOG.md / LICENSE / Makefile
├── doc.go                  # 包级文档
├── clickhousex.go          # NewClient 工厂
├── client.go               # Client 实现
├── rows.go                 # Rows 实现
├── health.go               # HealthStatus
├── options.go / config.go / errors.go / types.go
├── internal/{codec,pool}/  # 类型转换、连接池
├── testdata/*.golden
├── example_test.go / benchmark_test.go
└── integration_test.go     # //go:build integration
```

## 8. 配置规范
`Config` 结构体：DSN、PoolSize(10)、MaxPoolSize(100)、ConnectTimeout(5s)、QueryTimeout(60s，OLAP 较长)、MaxOpenConns、MaxIdleConns、RetryConfig（默认 3 次指数退避）。连接池大小默认 10 最大 100，可由 Config 覆盖（BR-001）。

## 9. 错误模型
typed sentinel error：`ErrInvalidConfig`/`ErrConnectionLost`/`ErrTableNotFound`/`ErrColumnCountMismatch`/`ErrEmptyColumns`/`ErrTypeMismatch`/`ErrPoolExhausted`。消息格式 `"clickhousex: <operation>: <detail>"`（BR-007），用 `%w` 保留底层错误链。ClickHouse 原生错误在 adapter 边界包装。

## 10. 日志规范
log 事件：`clickhousex.connected`(info)、`clickhousex.disconnected`(warn)、`clickhousex.batch.insert`(info, rows+duration)、`clickhousex.query.error`(error, sql+error)。DSN 不泄露到日志，密码部分用 `***` 替代（SPEC §18、NFR-014）。遵循 observex 全局 logger 注入。

## 11. Metrics 规范
冻结指标命名（BR-008）：`clickhousex.query.duration`(histogram,table)、`clickhousex.write.duration`(histogram,table)、`clickhousex.write.rows`(counter,table)、`clickhousex.write.bytes`(counter,table)、`clickhousex.pool.{active,idle,exhausted}`(gauge/counter)。写入操作必须含 table 标签，查询操作含 query 标签。

## 12. Tracing 规范
span：`clickhousex.exec`、`clickhousex.query`、`clickhousex.insert_batch`。Tracer span 创建、结束与错误记录路径已覆盖（NFR-017）。通过 interface 接收 observex.Tracer，具体实现在 x.go 注入。

## 13. Reliability 规范
- 连接断开后自动重试 3 次（指数退避），超过后返回 `ErrConnectionLost`（BR-004）。
- `RetryConfig` 默认 3 次，retryable connection failures、wait cancellation、retry-delay clamping 已覆盖（AC-021）。
- Health 幂等无副作用（BR-005）、Close 幂等不 panic（BR-009）。
- 集成测试在 ClickHouse 不可达时自动 skip（NFR-018）。

## 14. Security 规范
- DSN 不泄露到日志（密码 `***` 替代，NFR-014）。
- SQL 注入防护：Exec/Query args 使用参数化绑定，禁止 SQL 拼接（BR-003）。
- 批量写入用原生 batch insert 协议，不拼接 value SQL（BR-002）。
- 错误消息不泄露连接详情；连接凭据不硬编码，通过 Config 注入（SPEC §18）。

## 15. Performance SLO
v1.0.8 已归档 benchmark：Exec `1474 ns/op`、QueryRowsScan `1672 ns/op`、InsertBatch(client path) `2013 ns/op`、HealthCheck `485.4 ns/op`。SPEC §16 目标：单次 Exec < 10ms、InsertBatch 10000 行 < 1s、单次 OLAP 查询 < 100ms、复杂聚合 < 1s、池获取 < 1ms、常驻内存 < 5MB。

## 16. 测试标准
AC-001..AC-026（26 条验收）+ TC-001..TC-007 Given/When/Then。v1.0.8 覆盖率 100.0%（`go tool cover -func`）。必跑：`go test -race ./...`、`go vet`、`go build`、`golangci-lint`、gitleaks、`go mod tidy`。集成测试 `go test -tags=integration` + 真实 ClickHouse live（`CLICKHOUSEX_RUN_INTEGRATION=1`）+ 60s soak。

## 17. Chaos 标准
SPEC §12/§15 边界场景：DSN 格式错误、ClickHouse 不可达（不 panic）、批量写入空 rows/cols、查询结果为空、并发 Close 幂等、连接池耗尽（阻塞→超时 `ErrPoolExhausted`）、ctx 超时、大结果集逐行迭代、Nullable Scan 非指针、Decimal 精度丢失、batch insert 部分失败（返回首个错误+行号）。连接断开→恢复由 BR-004 retry 覆盖。

## 18. Contract 标准
`Client` interface：Exec/Query/InsertBatch/Health/Close。`Rows` interface：Next/Scan/Close/Err/ColumnTypes。`ColumnType`：Name/Type/Nullable。`HealthStatus`：Ready/Live/Message。类型映射表锁定（SPEC §9.2）：UInt/Int/Float/String/DateTime/Decimal/Nullable(T)→*T/LowCardinality(T)→T/Array(T)→[]T。Client interface 变更=major，新增方法=minor。

## 19. CI Gate
通用：`go build`、`go test -race -count=1`、覆盖率 < 80% 阻断、`go vet`、`golangci-lint`、`go mod tidy`、`gitleaks detect --no-git`、benchmark 附 PR comment。专属：`go test -tags=integration`（不可达 skip，可达必过）、`go list -deps | grep configx`（无匹配）。v1.0.8 branch/tag/main CI 全绿。

## 20. Release Gate
SPEC §21 DoD：godoc 注释、示例代码、CHANGELOG、README、覆盖率 ≥ 80%、race 通过、benchmark 无 > 10% 回退、vet/lint/gitleaks 通过、公共 API 无破坏性变更（或 bump major）、所有 FR/Edge Case 有测试、集成测试无环境正确 skip、类型映射表有测试。v1.0.8 已通过 PR #6 合并入 main，GitHub Release 已发布。

## 21. Versioning
semver。Client interface 变更=major；Config 新增可选字段=patch/minor，必填=minor（带默认值）；新增 Client 方法=minor；类型映射变更=major；错误变量新增=minor 删除=major；bugfix=patch。v1.0.8 为复验发布，客户端 API 与 FR/BR/NFR 覆盖范围与 v1.0.7 一致。

## 22. 兼容性策略
SPEC §20 升级兼容性矩阵。v1.0.8 已合并 v1.0.3–v1.0.8 发布线入 main。下游只允许依赖已发布的 Client/Rows/Config 入口。Config 新增字段保留旧调用方编译兼容性。类型映射变更（影响现有 Scan 行为）必须 bump major。

## 23. Failover 策略
连接断开→自动重试 3 次指数退避→超过返回 `ErrConnectionLost`（BR-004，触发调用方感知）。ClickHouse 临时不可达→Exec 返回 `ErrConnectionLost`，恢复后 Exec 成功自动重连（TC-002）。模块不内置集群故障转移，由 ClickHouse 集群自行处理分布式查询路由。

## 24. Backpressure 策略
连接池耗尽→阻塞等待空闲连接→超时返回 `ErrPoolExhausted`。调用方可增大 `MaxPoolSize`（默认 100）或减少并发。大结果集查询 Rows 逐行迭代，不一次性加载到内存（SPEC §12）。`MaxOpenConns`/`MaxIdleConns` 可由 Config 调参。

## 25. 审计要求
可观测指标必须含 table/query 标签（BR-008）。log 事件记录连接、断开、批量写入完成（rows+duration）、查询失败（sql+error）。错误消息包含操作名和错误类型，不包含 DSN/密码（NFR-014）。span 覆盖 exec/query/insert_batch 用于调用链追溯。

## 26. 熵减规则
全局：禁止 util dumping、hidden abstraction、cyclic dependency。模块特有（BR-002/003）：批量写入必须用原生 batch insert 协议禁止拼接 SQL、Exec/Query args 必须参数化绑定禁止 SQL 拼接。新增依赖不得越过 FOUNDATION-DEPS.yaml 登记边界，禁止直接依赖 configx。

## 27. AI Coding Constraints
全局：AI 不允许新增未注册模块、绕过 contracts、动态扩展目录。模块特有：AI 不得用 `fmt.Sprintf` 拼接 SQL（CI Gate golangci-lint 阻断）、不得在公开 API 暴露 clickhouse-go 驱动类型（adapter SPI 隔离）、不得直接 import configx、不得自动建表（BR-010）。类型映射变更必须 bump major。

## 28. Forbidden Patterns
- `fmt.Sprintf` 拼接 SQL（golangci-lint 阻断）。
- 直接依赖 configx（CI Gate 阻断）。
- 公开 API 暴露 provider SDK 类型。
- InsertBatch 自动建表（必须返回 `ErrTableNotFound`）。
- Close 不幂等或 panic。
- 错误消息泄露 DSN/密码/连接详情。
- 全局可变状态、shared singleton chaos、runtime reflection abuse。

## 29. Production Ready Checklist
- [x] v1.0.8 tag/GitHub Release 已发布（PR #6 合并入 main）
- [x] FR-001..008、BR-001..012、AC-001..026 由 TRACEABILITY + v1.0.8 evidence 闭合
- [x] 覆盖率 100.0% / race / vet / build / lint / gitleaks / Trust Alignment 通过
- [x] 真实 ClickHouse live 集成测试 + 60s live soak 通过
- [x] benchmark/profile 归档（Exec/Query/InsertBatch/HealthCheck）
- [ ] 生产时长多小时 soak —— factory 前缺口
- [ ] 外部消费方 rollout —— factory 前缺口
- [ ] 100000 行真实规模 + 复杂聚合 benchmark（NFR-003/005）—— factory 前缺口
- [ ] Factory-grade 声明（BLK-003 已 resolved，但 factory 证据仍待补）

## 30. Roadmap
- v1.0.8（已发布）：复验 release gate，合并 v1.0.3–v1.0.8 入 main，闭合完整客户端 API + live 集成 + soak + benchmark。
- v1.x：补生产时长 soak、外部消费方 rollout、大规模/复杂查询 benchmark、factory 归档证据。
- 开放问题（SPEC §22）：异步 insert、Decimal Go 库选型、压缩传输、动态扩缩容、分布式表查询、批量写入部分重试。
