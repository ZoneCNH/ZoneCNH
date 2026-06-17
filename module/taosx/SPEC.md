# taosx 规格

- Status: Approved
- Spec-Version: v1.0.1
- Last-Updated: 2026-06-16
- Layer: L2 存储适配器
- Version: v1.0.1
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Approved 与 100.0% 覆盖证据不等同于 factory-grade；BLK-007（SPEC ~77 / tasks 76）关闭前机器事实层保持 factory=false。

---

## 1. 摘要

`taosx` 是 TDengine 的 L2 存储适配器契约模块。v1.0.1 在保持 v1.0.0 公共 API 与适配器边界不变的前提下，交付 Go 侧可审计的配置归一化与脱敏、SQL 执行与查询契约、批量写入与 schemaless 写入契约、健康检查、可注入驱动端口和可选指标端口。

**时序存储边界：taosx vs clickhousex** — taosx 面向 **IoT 时序存储**场景（高频传感器/行情数据写入、时间窗口查询、设备监控），基于 TDengine 的超级表（supertable）模型优化写入吞吐，适合每秒数万点的高频写入和简单时间窗口聚合（如 `INTERVAL(1m)` 均值/最大/最小）。clickhousex 面向 **OLAP 分析查询**场景（复杂聚合、多维分析、即席查询），适合需要对历史数据进行灵活 SQL 分析的分析工作负载。选型指南：高频写入 + 固定窗口查询 → taosx；复杂聚合 + 灵活多维分析 → clickhousex。两者不重叠，按场景组合使用。

v1.0.1 保持 `pkg/taosx` 为公共运行时 API：默认驱动仍显式不可用，真实 TDengine 通过 `WithDriver` 注入或测试适配器接入。发布验证已使用官方 `taosWS` WebSocket driver 在本地 dev 环境执行真实 `SHOW TABLES` 集成测试，并补齐 batch rows / schemaless lines 指标语义与 `pkg/taosx` 100.0% 覆盖证据；核心包仍不内置连接池、STMT 批量写入实现或自动重试策略。

## 2. 目标

- 提供 `New(ctx, Config, ...Option) (Client, error)` 构造函数，创建可关闭的 TDengine 适配器客户端。
- 提供 `Config` 的默认值归一化、字段校验、敏感信息脱敏和 redacted DSN 表示。
- 提供 `Client`/`Driver` 端口，覆盖 `Exec`、`Query`、`WriteBatch`、`SchemalessWrite`、`Health` 和 `Close`。
- 提供 `Rows` 抽象，允许驱动实现按行扫描、返回列信息和关闭查询结果。
- 提供 `Metrics` 端口与 no-op 默认实现，让上层 observability 适配器可以在不引入直接依赖的前提下接入。
- 通过契约测试锁定校验、错误分类、指标回调、健康状态和关闭幂等性。
- 提供显式 opt-in 的 TDengine WebSocket 集成测试，验证官方 `taosWS` driver 可经 `WithDriver` 接入且失败输出不泄漏凭据。

## 3. 非目标

- 不把真实 TDengine 连接做成核心包默认行为；官方 `taosWS` 集成仅作为 env-gated 测试/适配器证据进入发布门禁。
- 不实现连接池、核心包内置生产驱动或凭据管理。
- 不实现 STMT 写入、自动建表、schema migration、流式订阅或业务级时序模型。
- 不在核心包内读取环境变量、配置文件或远程配置中心。
- 不直接依赖 `configx`、`observex`、`resiliencx` 等横切模块；这些能力由调用方在边界外组合。
- 不保证原始 SQL 的注入安全；`taosx` 只拒绝空 SQL，参数化和 SQL DSL 属于上层或具体驱动职责。

## 4. 消费者

- `market-data` 采集层：通过 `WriteBatch`/`SchemalessWrite` 将 Tick/Bar/Kline 等行情数据写入 TDengine 超级表，利用高频写入吞吐优势。
- `order-engine`：通过 `Exec`/`Query` 持久化订单执行报告和成交记录，支持历史订单查询。
- `risk-engine`：通过 `Query` 读取历史行情和风控指标，支持回测和实时风控分析。
- `factor-engine`：通过 `WriteBatch` 存储因子计算结果，通过 `Query` 读取历史因子值用于回溯。
- `backtestx`：通过 `Query` 读取回测所需的历史行情、因子和宏观数据。
- `observex` 适配器层：通过注入 `Metrics` 实现采集 `taosx_client_*` 指标，不通过直接依赖接入。
- 上层 orchestration（`x.go`/`maestro`）：在启动时构造 `taosx.Client`，注入 TDengine driver 并将其注入下游模块。

## 5. 功能需求

以下功能需求定义 v1.0.1 必须稳定交付的 TDengine 适配器公共能力。每条 FR 包含 WHEN/THEN 行为规格和对应的验收标准 (AC) 与测试用例 (TC) 映射。

### FR-001: Config.Normalize 默认值补齐

**WHEN** 创建 `Config` 时名称、驱动模式或超时为零值/空值  
**THEN** `Normalize()` 必须将空名称归一化为包名 `taosx`，空驱动模式归一化为 `websocket`，零值超时归一化为 5 秒  
**AC**: AC-TAO-001: 零值字段归一化为预期默认值；负超时由后续 Validate 拒绝
**TC**: TC-001 (Config 默认值 golden)

### FR-002: Config.Validate 校验拒绝

**WHEN** `Config.Validate()` 被调用且 endpoint、database 缺失、驱动模式非法、超时/重试次数为负  
**THEN** 返回 validation error，操作名为 `taosx.Config`，错误消息不包含密码原文  
**AC**: AC-TAO-002: 缺失 endpoint 返回错误；缺失 database 返回错误；非法驱动模式返回错误；负超时返回错误；错误不含密码
**TC**: TC-002 (Config 校验错误), TC-003 (密码脱敏)

### FR-003: New 构造函数

**WHEN** 调用 `New(ctx, config, opts...)` 且无驱动注入  
**THEN** 构造成功，返回非 nil Client；后续操作返回可重试的 unavailable 错误  
**WHEN** 注入自定义 Driver  
**THEN** 构造成功，后续操作委托给注入驱动  
**AC**: AC-TAO-003: 无驱动构造成功，操作返回 unavailable；有驱动构造成功，操作正常执行  
**TC**: TC-004 (默认不可用驱动), TC-005 (驱动注入)

### FR-004: Exec 执行

**WHEN** 调用 `Exec(ctx, statement)` 且 SQL 为空  
**THEN** 返回 validation error，操作名 `taosx.Exec`  
**WHEN** SQL 非空且驱动已注入  
**THEN** 委托给 `Driver.Exec(ctx, statement)`，保留驱动的错误分类和操作名  
**AC**: AC-TAO-004: 空 SQL 拒绝；驱动错误透传；成功返回 ExecResult  
**TC**: TC-006 (空 SQL 拒绝), TC-007 (驱动委托)

### FR-005: Query 查询

**WHEN** 调用 `Query(ctx, query)` 且查询语句为空  
**THEN** 返回 validation error  
**WHEN** 查询非空且驱动已注入  
**THEN** 返回 `Rows` 可读取列信息、按行扫描、关闭；驱动错误时不伪造空结果  
**AC**: AC-TAO-005: 空查询拒绝；Rows 可遍历；驱动错误透传  
**TC**: TC-008 (空查询拒绝), TC-009 (Rows 遍历与关闭)

### FR-006: WriteBatch 批量写入

**WHEN** 调用 `WriteBatch(ctx, batch)` 且 batch 为空或无 points  
**THEN** 返回 validation error  
**WHEN** batch 合法且驱动已注入  
**THEN** 委托给驱动执行；驱动部分失败时返回 partial result 和错误  
**AC**: AC-TAO-006: 空 batch 拒绝；部分失败含 partial result；成功记录写入行数指标  
**TC**: TC-010 (空 batch 拒绝), TC-011 (部分失败 partial result)

### FR-007: SchemalessWrite 无模式写入

**WHEN** 调用 `SchemalessWrite(ctx, payload)` 且 lines 为空或协议非法  
**THEN** 返回 validation error  
**WHEN** payload 合法且驱动已注入  
**THEN** 成功写入并记录 `taosx_client_schemaless_lines` 指标  
**AC**: AC-TAO-007: 空 lines 拒绝；非法协议拒绝；成功路径记录指标  
**TC**: TC-012 (空 lines 拒绝), TC-013 (协议校验)

### FR-008: Health 健康检查

**WHEN** 调用 `Health(ctx)` 且驱动未注入  
**THEN** 返回 degraded 状态，含 mode=`websocket`、database 名和 redacted 错误信息  
**WHEN** 驱动已注入  
**THEN** 委托给 `Driver.Health(ctx)`，映射 nil→ready、error→degraded/unhealthy  
**AC**: AC-TAO-008: 默认驱动返回 degraded；注入驱动透传健康状态；调用不 panic；错误信息不含密码  
**TC**: TC-014 (默认 degraded), TC-015 (驱动健康透传)

### FR-009: Close 关闭

**WHEN** 调用 `Close(ctx)` 首次  
**THEN** 关闭客户端，释放资源，返回 nil  
**WHEN** 重复调用 `Close(ctx)`  
**THEN** 幂等返回 nil  
**WHEN** 关闭后调用任何操作  
**THEN** 返回 closed 错误  
**AC**: AC-TAO-009: 首次关闭成功；重复关闭幂等；关闭后操作返回 closed  
**TC**: TC-016 (关闭幂等), TC-017 (关闭后操作拒绝)

### FR-010: Metrics 可选指标

**WHEN** 未注入 `Metrics` 实现  
**THEN** 使用 no-op 实现，所有指标调用为零开销  
**WHEN** 注入 `Metrics` 实现  
**THEN** 记录 `taosx_client_request_total`、`taosx_client_duration_seconds`、`taosx_client_error_total`、`taosx_client_health_status`、`taosx_client_batch_rows` 等指标  
**AC**: AC-TAO-010: 未注入时零开销；注入后正确记录；指标名统一 `taosx_client_*` 前缀
**TC**: TC-018 (no-op 零开销), TC-019 (指标记录)

### Acceptance Criteria Registry

| AC 编号 | 对应 FR | 验收条件 |
| ------- | ------- | -------- |
| AC-TAO-001 | FR-001 | Config 零值字段归一化为预期默认值（空名称→taosx，空驱动→websocket，零超时→5s）；负超时由 Validate 拒绝 |
| AC-TAO-002 | FR-002 | 缺失 endpoint/database/非法驱动模式/负超时均返回 validation error；错误消息不含密码原文 |
| AC-TAO-003 | FR-003 | 无驱动构造成功，后续操作返回 unavailable 错误；有驱动构造成功，操作正常执行 |
| AC-TAO-004 | FR-004 | 空 SQL 返回 validation error；驱动错误透传；成功返回 ExecResult |
| AC-TAO-005 | FR-005 | 空查询返回 validation error；Rows 可遍历且可关闭；驱动错误不伪造空结果 |
| AC-TAO-006 | FR-006 | 空 batch 或无 points 返回 validation error；部分失败含 partial result 和错误；成功记录写入行数指标 |
| AC-TAO-007 | FR-007 | 空 lines 或非法协议返回 validation error；成功路径记录 `taosx_client_schemaless_lines` 指标 |
| AC-TAO-008 | FR-008 | 默认驱动返回 degraded 状态；注入驱动透传健康状态；调用不 panic；错误信息不含密码 |
| AC-TAO-009 | FR-009 | 首次关闭成功；重复关闭幂等返回 nil；关闭后操作返回 closed 错误 |
| AC-TAO-010 | FR-010 | 未注入 Metrics 时零开销；注入后正确记录指标；指标名统一 `taosx_client_*` 前缀 |

## 6. 行为约束

| ID | 约束 | 说明 |
| --- | --- | --- |
| BR-001 | 直接 foundation 依赖只允许 `kernel`。 | 以 `module/FOUNDATION-DEPS.yaml` 为准；当前核心实现不需要额外 Zone 模块依赖。 |
| BR-002 | 所有外部操作必须接受 `context.Context`。 | 构造、执行、查询、写入、健康检查和关闭都受调用方上下文控制。 |
| BR-003 | 错误必须可分类且可脱敏。 | 操作名使用 `taosx.<Operation>`，日志/DSN/状态不得暴露密码。 |
| BR-004 | `MaxRetries` 是配置契约保留字段，不代表核心 client 自动重试。 | 重试策略应由驱动适配器或上层 resilience 组合实现。 |
| BR-005 | 默认驱动必须显式不可用。 | 避免误导用户以为默认构造能连接真实 TDengine。 |
| BR-006 | 真实集成测试必须显式 opt-in 且凭据脱敏。 | 只在 `TAOSX_INTEGRATION=1` 与 `integration` build tag 同时存在时运行；失败输出不得泄漏 DSN 或密码。 |

## 7. 公共 API 契约与使用示例

```go
type Client interface {
	Exec(context.Context, Statement) (ExecResult, error)
	Query(context.Context, Query) (Rows, error)
	WriteBatch(context.Context, Batch) (WriteResult, error)
	SchemalessWrite(context.Context, SchemalessPayload) (WriteResult, error)
	Health(context.Context) HealthStatus
	Close(context.Context) error
}

type Driver interface {
	Exec(context.Context, Statement) (ExecResult, error)
	Query(context.Context, Query) (Rows, error)
	WriteBatch(context.Context, Batch) (WriteResult, error)
	SchemalessWrite(context.Context, SchemalessPayload) (WriteResult, error)
	Health(context.Context) error
	Close(context.Context) error
}

type Config struct {
	Name       string
	DriverMode DriverMode
	Endpoint   string
	Database   string
	Username   string
	Password   string
	Timeout    time.Duration
	MaxRetries int
	TLS        bool
}
```

典型使用：

```go
cfg := taosx.Config{
	Endpoint: "tdengine.example.internal:6041",
	Database: "market",
	Username: "root",
	Password: os.Getenv("TAOSX_PASSWORD"),
}

client, err := taosx.New(ctx, cfg, taosx.WithDriver(driver))
if err != nil {
	return err
}
defer func() {
	_ = client.Close(context.Background())
}()

rows, err := client.Query(ctx, taosx.Query{SQL: "SELECT ts, price FROM ticks"})
if err != nil {
	return err
}
defer rows.Close()
```

## 8. CI 门禁

| 门禁 | 命令 / 检查 | 阻断条件 |
|------|-------------|----------|
| 单元测试 | `go test ./pkg/taosx` | 任一测试失败 |
| Race 检测 | `go test -race ./pkg/taosx ./contracts` | data race 检出 |
| 覆盖率门禁 | `go test ./pkg/taosx -coverprofile=/tmp/taosx.cover` → `go tool cover -func=/tmp/taosx.cover` | `pkg/taosx` 覆盖率 < 100.0% |
| 契约测试 | `go test ./contracts` | 契约违反 |
| 示例测试 | `go test ./examples/...` | 示例不可运行 |
| 全量测试 | `go test ./...` | 任一包失败 |
| 静态分析 | `staticcheck ./...` | staticcheck 报错 |
| 漏洞扫描 | `govulncheck ./...` | 已知漏洞检出 |
| 边界检查 | `./scripts/check_boundary.sh` | 未批准 Zone 模块依赖引入 |
| 契约合规 | `./scripts/check_contracts.sh` | 契约不符合 |
| 依赖差异 | `./scripts/check_dependency_diff.sh` | 依赖漂移 |
| 集成测试 (opt-in) | `TAOSX_INTEGRATION=1 go test -tags=integration ./pkg/taosx -run TestTDengineWebSocketIntegration -count=1` | env-gated，失败阻塞 release |
| 格式检查 | `git diff --check` | 空白/格式违规 |
| 凭据泄漏 | grep password/secret/token 失败输出 | 凭据泄露 |

## 9. 数据与错误模型

### 数据模型

核心数据模型包括 `Config`、`Statement`、`Query`、`Rows`、`Batch`、`Point`、`SchemalessPayload`、`WriteResult`、`HealthStatus` 和错误分类。所有模型由调用方显式构造，不在包内读取环境变量。

### 错误处理

错误必须带操作名、分类和可脱敏上下文。配置错误归类为 validation，默认驱动错误归类为 unavailable，关闭后的操作归类为 closed，驱动透传错误必须保留原始 cause 供调用方诊断。

| 错误类型 | 分类 | 触发条件 |
|----------|------|----------|
| 配置缺失 | validation | endpoint/database 为空、驱动模式非法、超时/重试次数为负 |
| 空 SQL/Query | validation | Exec/Query 收到空字符串或空 batch |
| 驱动未注入 | unavailable | 操作用到未注入驱动的默认实例 |
| ctx 取消 | context canceled | 操作前或操作中 ctx 被取消 |
| 超时 | deadline exceeded | 操作超过 Config.Timeout |
| 关闭后操作 | closed | Close() 后调用任何 Client 方法 |
| 驱动透传 | 保留原始 cause | 驱动返回的错误，携带驱动诊断信息 |

## 10. 边界情况

- **空 SQL/Query/Batch**：`Exec(ctx, "")`、`Query(ctx, "")`、`WriteBatch(ctx, empty)` → 返回 validation error，不委托给驱动。
- **驱动未注入时调用操作**：`Exec`/`Query`/`WriteBatch`/`SchemalessWrite` → 返回 unavailable 错误；`Health` → 返回 degraded 状态。
- **ctx 已取消时调用**：操作必须检测 `ctx.Err()`，驱动委托前或委托中取消 → 返回 context error wrapped with operation name。
- **WriteBatch 部分成功**：驱动写入 N 行中 M 行失败 (M < N) → WriteResult.RowsAffected = N-M，error 包含部分失败详情。
- **SchemalessWrite 协议非法**：lines 格式不符合 InfluxDB Line Protocol 或 OpenTSDB Telnet → 返回 validation error。
- **重复 Close**：第二次及后续 `Close(ctx)` 调用 → 幂等返回 nil，不 panic，不重复释放资源。
- **Close 后操作**：`Close` 完成后调用任何 Client 方法 → 返回 closed 错误，操作名如 `taosx.Exec`。
- **并发读写**：多个 goroutine 同时调用同一 Client 的 `Exec`/`Query`/`WriteBatch`/`SchemalessWrite` → 驱动必须线程安全；Client 层不做额外序列化。
- **Config.RedactedDSN 脱敏**：RedactedDSN 不得包含密码明文；即使 Password 为空，输出也不应暗示凭据结构。
- **TLS=true 但驱动不支持**：驱动在 `Open` 时检测 → 返回 configuration error，操作名 `taosx.New`。
- **超时触发**：操作超过 `Config.Timeout` → ctx deadline exceeded，wrapped with operation name；不重试除非调用方注入 retry middleware。
- **Config 零值字段**：`Normalize()` 后空 Name→`"taosx"`，空 DriverMode→`"websocket"`，零 Timeout→`5s`；Validate 在 Normalize 后执行。

## 11. 配置契约

`Config.Normalize` 只补齐安全默认值，不连接外部系统。`Config.Validate` 必须拒绝空 endpoint、空 database、非法 driver mode、负 timeout 和负 retry count。`Config.RedactedDSN` 不得输出密码。

## 12. 并发与生命周期

`Client` 构造后可被并发调用。`Close` 必须幂等；关闭过程中不得产生 panic。关闭完成后，执行、查询、批量写入、schemaless 写入和健康检查必须返回可分类状态。

## 13. 性能预算

| 指标 | 目标 | 测量方法 |
|------|------|----------|
| `Config.Normalize` + `Validate` | < 5μs | benchmark 空配置到校验完成 |
| `New()` 无驱动构造 | < 50μs | 不含网络调用，仅 struct 初始化 |
| `Exec` 空 SQL 拒绝 | < 500ns | 不委托驱动，本地校验路径 |
| `Query` 空查询拒绝 | < 500ns | 不委托驱动，本地校验路径 |
| `WriteBatch` 空 batch 拒绝 | < 1μs | 不委托驱动，本地校验路径 |
| `Health()` 默认驱动 | < 1μs | 无驱动时本地返回 degraded |
| `Close()` 首次 | < 10ms | 驱动 Close 耗时取决于实现 |
| `Close()` 重复（幂等） | < 500ns | 已关闭时快速返回 |
| No-op Metrics 调用 | 零分配 | `BenchmarkNoopMetrics` 验证 `allocs/op = 0` |

> 注：涉及驱动委托的操作（Exec/Query/WriteBatch/SchemalessWrite 成功路径）延迟由注入驱动决定，不在核心包性能预算内。核心包仅保证本地校验路径（空输入拒绝、默认驱动错误返回）的性能。

## 14. 可观测性

指标端口只记录低基数标签。`Metrics` 实现不得成为核心依赖；默认 no-op 实现必须零配置可用。健康检查状态不得包含明文密码或完整 DSN。

## 15. 安全与脱敏

错误、状态、日志、测试失败输出和示例均不得暴露真实密码、API key、私有 endpoint 或账户信息。示例凭据必须使用环境变量或占位符表达。

## 16. 依赖边界

核心包直接 Zone 依赖仅允许 `kernel`。真实 TDengine driver、指标后端、配置中心和重试组件都必须通过端口注入或测试边界接入。

## 17. 目录结构

```text
module/taosx/
  SPEC.md             # 本规格文档
  goal.md             # Goal 驱动制品
  TRACEABILITY.md     # 追溯矩阵 (FR/BR/NFR/TC/AC)
  IMPLEMENTATION-PLAN.md
  tasks/              # 任务拆分制品
  contracts/          # 契约测试 (驱动合规验证)
  examples/           # 可运行示例
```

## 18. 兼容性与迁移

### 兼容性

v1.0.1 不改变 v1.0.0 的公共构造入口和核心接口语义。新增字段、方法或错误分类必须保留旧调用方的编译兼容性，破坏性变更必须进入后续 major 版本。

### 迁移策略

从 v1.0.0 升级到 v1.0.1 的调用方只需重新运行验证命令。已注入自定义 driver、metrics 或测试适配器的项目不需要调整构造方式。

## 19. 发布证据与测试矩阵

### 发布证据

发布证据必须包含单元测试、契约测试、示例测试、race 检查、覆盖率报告、边界检查、依赖差异检查、Docker 或本地 TDengine 集成测试、`git diff --check` 输出和无凭据泄漏检查。

### 测试矩阵

测试矩阵覆盖配置归一化、校验失败、默认不可用驱动、注入驱动成功路径、错误分类、关闭幂等性、Rows 行为、批量写入、schemaless 写入、健康状态、指标回调和并发安全。

## 20. 回滚策略

如 v1.0.1 发布后出现回归，调用方可回退到 v1.0.0 tag。回滚不需要数据迁移，因为核心包不持久化状态、不写 schema、不管理连接池。

## 21. 运行手册

运行方必须在外部配置 TDengine endpoint、database、username、password、timeout 和 driver。生产 driver 由调用方注入，核心包只负责端口契约、配置校验、错误分类和脱敏。

## 22. 验收状态

本规格状态为 Approved。进入 release_ready 前，必须确认 TRACEABILITY 中 FR-001 到 FR-010 与 BR-001 到 BR-006 的测试证据均为通过状态。

## 23. 开放问题

- 是否将官方 TDengine driver 包装器独立为 `taosx-driver-taosws` 仓库。
- 是否在后续版本提供 STMT 批量写入端口。
- 是否增加面向超级表 schema 管理的独立契约。
