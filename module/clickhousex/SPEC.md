# clickhousex 规格

- Status: Approved
- Spec-Version: v1.1.0
- Last-Updated: 2026-06-14
- Layer: 基座 · 存储扩展
- Version: v1.0.1
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Approved 与 100.0% 覆盖证据不等同于 factory-grade；机器事实层保持 factory=false。

---

## 1. 摘要

`clickhousex` 封装 ClickHouse 客户端，提供统一的连接管理、批量写入、OLAP 查询和可观测集成。屏蔽 ClickHouse 原生驱动的连接池、batch insert、类型映射差异，为上层分析域模块提供简洁的 OLAP 存储接口。

**时序存储边界：clickhousex vs taosx** — clickhousex 面向 **OLAP 分析查询**场景（聚合计算、多维分析、即席查询、因子回看、收益归因），适合需要复杂 SQL 聚合和灵活查询模式的分析工作负载。taosx 面向 **IoT 时序存储**场景（高频写入、时间窗口查询、设备/传感器数据），基于 TDengine 的超级表模型优化写入吞吐和简单时间窗口聚合。两者互补：高频行情/传感器原始数据写入 → taosx；历史数据分析、因子计算、归因查询 → clickhousex。选型时应根据写入频率、查询复杂度和数据保留策略选择对应模块。

---

## 2. 问题与背景

量化交易系统需要高效执行分析型查询（因子回看、收益归因、风险归因）和存储大量历史数据。直接使用 ClickHouse 原生驱动存在以下问题：

- 连接管理分散，各模块各自维护连接池
- 批量写入需要处理 batch insert 协议、列式格式、错误重试，逻辑复杂
- 查询结果缺少统一的类型映射和错误传播机制
- ClickHouse 特有的类型（Decimal、LowCardinality、Nullable）需要统一处理
- 缺少统一的可观测集成，排查 OLAP 查询延迟困难
- 健康检查逻辑各模块重复实现

---

## 3. 目标

- 提供 `Client` 接口，统一封装 Exec / Query / InsertBatch 操作
- 管理 ClickHouse 连接池，支持配置化调参
- 批量写入支持原生 batch insert 协议，高性能列式写入
- 提供 `Rows` 接口统一查询结果迭代，支持 ClickHouse 特有类型
- 集成 observex 的 metrics / tracing / logging
- 提供 `Health()` 健康检查，与 kernel 生命周期对齐
- 集成测试在 ClickHouse 不可达时自动 skip

---

## 4. 非目标

- 不做 ClickHouse 集群管理或部署编排
- 不做数据模型定义（表 schema 由业务层决定）
- 不做数据压缩（ClickHouse 原生支持）
- 不做数据迁移或 schema migration
- 不做分布式查询路由（由 ClickHouse 集群自行处理）
- 不做 SQL 拼接 DSL（调用方传 raw SQL）
- 不做 ClickHouse 特有功能封装（如物化视图、字典管理）

---

## 5. 消费者

| 消费者            | 使用方式                               |
| ----------------- | -------------------------------------- |
| `factor_engine`   | 写入因子值、查询历史因子               |
| `signal-engine`   | 写入信号日志、查询信号统计             |
| `backtest_engine` | 写入回测结果、查询回测对比             |
| `risk_engine`     | 写入风险指标、查询风险归因             |
| `x.go`（组合根）  | 创建 Client 实例，注入到分析域模块     |
| 运维/监控         | 通过 Health() 检查 ClickHouse 连接状态 |

---

## 6. 功能需求

### FR-001: NewClient

WHEN 调用 `NewClient(cfg Config)` 且配置合法（DSN 非空）
THEN 创建连接池，返回 Client 实例，nil 错误

WHEN 调用 `NewClient(cfg Config)` 且 DSN 为空
THEN 返回 `ErrInvalidConfig`，不创建连接

### FR-002: Exec

WHEN 调用 `Exec(ctx, sql, args...)` 且 SQL 语法正确、连接可用
THEN 执行 SQL，返回 nil

WHEN 调用 `Exec(ctx, sql, args...)` 且 SQL 语法错误
THEN 返回包装后的 ClickHouse 错误，包含 SQL 上下文

WHEN 调用 `Exec(ctx, sql, args...)` 且连接不可用
THEN 返回 `ErrConnectionLost`，触发重连

WHEN ctx 被取消
THEN 中断执行，返回 `ctx.Err()`

### FR-003: Query

WHEN 调用 `Query(ctx, sql, args...)` 且查询成功
THEN 返回 `Rows` 实例，可迭代结果集，nil 错误

WHEN 调用 `Query(ctx, sql, args...)` 且查询失败
THEN 返回 nil `Rows`，包含具体错误

WHEN 查询结果为空
THEN 返回空 `Rows`（`Next()` 首次调用返回 false），nil 错误

### FR-004: InsertBatch

WHEN 调用 `InsertBatch(ctx, table, cols, rows)` 且 rows 非空、cols 非空
THEN 使用原生 batch insert 协议批量写入，返回 nil

WHEN 调用 `InsertBatch(ctx, table, cols, rows)` 且 rows 为空
THEN 返回 nil（空操作）

WHEN 调用 `InsertBatch(ctx, table, cols, rows)` 且 cols 为空
THEN 返回 `ErrEmptyColumns`

WHEN 调用 `InsertBatch(ctx, table, cols, rows)` 且某行的列数与 cols 不匹配
THEN 返回 `ErrColumnCountMismatch`，包含行号

WHEN 调用 `InsertBatch(ctx, table, cols, rows)` 且 table 不存在
THEN 返回 `ErrTableNotFound`（不自动建表）

WHEN 批量写入过程中部分行失败
THEN 返回首个错误，包含行号和失败原因

### FR-005: Health

WHEN 调用 `Health()` 且连接池可用
THEN 返回 `HealthStatus{Ready: true, Live: true}`

WHEN 调用 `Health()` 且连接池不可用
THEN 返回 `HealthStatus{Ready: false, Live: false, Message: "connection pool exhausted"}`

WHEN 连接池部分可用
THEN 返回 `HealthStatus{Ready: true, Live: true, Message: "low pool capacity"}`

### FR-006: Close

WHEN 调用 `Close()`
THEN 关闭所有连接池，释放资源，返回 nil

WHEN 调用 `Close()` 且有正在执行的查询
THEN 等待查询完成或超时后强制关闭

WHEN 重复调用 `Close()`
THEN 幂等，第二次调用返回 nil

### FR-007: Rows.Next / Rows.Scan / Rows.Close

WHEN 调用 `Next()` 且有下一行
THEN 返回 true，内部游标前进

WHEN 调用 `Next()` 且无更多行
THEN 返回 false

WHEN 调用 `Scan(dest...)` 且列数与 dest 数匹配
THEN 将当前行数据写入 dest，处理 ClickHouse 类型映射，返回 nil

WHEN 调用 `Scan(dest...)` 且列数不匹配
THEN 返回 `ErrColumnCountMismatch`

WHEN 调用 `Scan(dest...)` 且 ClickHouse 类型无法映射到 Go 类型
THEN 返回 `ErrTypeMismatch`，包含列名和类型信息

WHEN 调用 `Close()` 且迭代未完成
THEN 释放底层资源，返回 nil

### FR-008: Rows.ColumnTypes

WHEN 调用 `ColumnTypes()`
THEN 返回列类型信息切片，包含列名、ClickHouse 类型、Nullable 标志

---

## 7. 行为约束

| 编号 | 规则 | 违反时 |
| --- | --- | --- |
| BR-001 | 连接池大小默认 10，最大 100，通过 Config 配置 | 配置校验拒绝，返回 `ErrInvalidConfig` |
| BR-002 | 批量写入使用原生 batch insert 协议，不使用拼接 SQL | CI Gate 阻断：`golangci-lint` 检测 `fmt.Sprintf` 拼接 SQL |
| BR-003 | Exec / Query 的 args 使用参数化绑定，禁止 SQL 拼接 | 返回 `clickhousex: exec: invalid args`；SQL 注入扫描阻断 |
| BR-004 | 连接断开后自动重试 3 次（指数退避），超过后返回 `ErrConnectionLost` | 重试耗尽后返回 `ErrConnectionLost`，触发调用方感知 |
| BR-005 | Health() 必须是幂等的、无副作用的 | 行为违规——多次调用结果不一致或产生副作用时 CI Gate 健康检查测试失败 |
| BR-006 | 所有操作必须接受 `context.Context`，支持取消和超时 | 编译失败：接口签名不含 `context.Context` 参数 |
| BR-007 | 错误消息格式：`"clickhousex: <operation>: <detail>"` | CI Gate 错误格式检查失败；返回的错误不符合约定 |
| BR-008 | 可观测指标必须包含 table 标签（写入操作）或 query 标签（查询操作） | 可观测面板缺失维度——指标缺少 table/query 标签 |
| BR-009 | Close() 必须是幂等的，多次调用不 panic | 运行时 panic——`TC-007` 幂等 Close 测试失败 |
| BR-010 | InsertBatch 不自动建表，表不存在时返回明确错误 | 返回 `ErrTableNotFound`，包含表名 |
| BR-011 | ClickHouse Nullable 类型映射到 Go 指针类型 | 返回 `ErrTypeMismatch`——Scan 到非指针类型时拒绝 |
| BR-012 | ClickHouse Decimal 类型映射到 `shopspring/decimal` 或 `apd.Decimal` | 返回 `ErrTypeMismatch`——精度丢失时拒绝，提示使用 decimal.Decimal |

---


### Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion |
|-------|-----------|----------|
| AC-001 | FR-001 | TC-005 | TASK-CLICKHOUSEX-001 | ⬜ | |
| AC-002 | FR-001 | TC-005 | TASK-CLICKHOUSEX-001 | ⬜ | |
| AC-003 | FR-002 | TC-001, TC-002 | TASK-CLICKHOUSEX-002 | ⬜ | |
| AC-004 | FR-002 | TC-001, TC-002 | TASK-CLICKHOUSEX-002 | ⬜ | |
| AC-023 | FR-002 | TC-001, TC-002 | TASK-CLICKHOUSEX-002 | ⬜ | |
| AC-005 | FR-003 | TC-001 | TASK-CLICKHOUSEX-003 | ⬜ | |
| AC-006 | FR-003 | TC-001 | TASK-CLICKHOUSEX-003 | ⬜ | |
| AC-007 | FR-004 | TC-001, TC-003 | TASK-CLICKHOUSEX-004 | ⬜ | |
| AC-008 | FR-004 | TC-001, TC-003 | TASK-CLICKHOUSEX-004 | ⬜ | |
| AC-009 | FR-004 | TC-001, TC-003 | TASK-CLICKHOUSEX-004 | ⬜ | |
| AC-010 | FR-004 | TC-001, TC-003 | TASK-CLICKHOUSEX-004 | ⬜ | |
| AC-011 | FR-004 | TC-001, TC-003 | TASK-CLICKHOUSEX-004 | ⬜ | |
| AC-016 | FR-005 | TC-006 | TASK-CLICKHOUSEX-005 | ⬜ | |
| AC-017 | FR-005 | TC-006 | TASK-CLICKHOUSEX-005 | ⬜ | |
| AC-022 | FR-005 | TC-006 | TASK-CLICKHOUSEX-005 | ⬜ | |
| AC-015 | FR-006 | TC-007 | TASK-CLICKHOUSEX-005 | ⬜ | |
| AC-012 | FR-007 | TC-001, TC-004 | TASK-CLICKHOUSEX-003 | ⬜ | |
| AC-013 | FR-007 | TC-001, TC-004 | TASK-CLICKHOUSEX-003 | ⬜ | |
| AC-014 | FR-007 | TC-001, TC-004 | TASK-CLICKHOUSEX-003 | ⬜ | |

## 8. 接口契约

### 8.1 Client / Rows

```go
type Client interface {
    Exec(ctx context.Context, sql string, args ...any) error
    Query(ctx context.Context, sql string, args ...any) (Rows, error)
    InsertBatch(ctx context.Context, table string, cols []string, rows [][]any) error
    Health() HealthStatus
    Close() error
}

type Rows interface {
    Next() bool
    Scan(dest ...any) error
    Close() error
    Err() error
    ColumnTypes() []ColumnType
}

type ColumnType struct {
    Name     string
    Type     string // ClickHouse 原生类型名
    Nullable bool
}

type HealthStatus struct {
    Ready   bool
    Live    bool
    Message string
}
```text

### 8.2 Config

```go
type Config struct {
    DSN            string        // ClickHouse 连接字符串
    PoolSize       int           // 连接池大小，默认 10
    MaxPoolSize    int           // 最大连接池大小，默认 100
    ConnectTimeout time.Duration // 连接超时，默认 5s
    QueryTimeout   time.Duration // 查询超时，默认 60s（OLAP 查询较长）
    MaxOpenConns   int           // 最大打开连接数
    MaxIdleConns   int           // 最大空闲连接数
}
```text

### 8.3 用法示例

```go
client, err := clickhousex.NewClient(clickhousex.Config{
    DSN:      "clickhouse://user:pass@host:9000/db",
    PoolSize: 20,
})
if err != nil {
    return err
}
defer client.Close()

// 执行 DDL
err = client.Exec(ctx, `
    CREATE TABLE IF NOT EXISTS factor_values (
        ts DateTime64(3),
        symbol String,
        factor String,
        value Float64
    ) ENGINE = MergeTree()
    ORDER BY (ts, symbol, factor)
`)

// 批量写入
cols := []string{"ts", "symbol", "factor", "value"}
rows := [][]any{
    {time.Now(), "BTCUSDT", "momentum_1d", 0.05},
    {time.Now(), "ETHUSDT", "momentum_1d", 0.03},
}
err = client.InsertBatch(ctx, "factor_values", cols, rows)

// OLAP 查询
rs, err := client.Query(ctx,
    "SELECT factor, avg(value) FROM factor_values WHERE ts > ? GROUP BY factor",
    startTime)
defer rs.Close()
for rs.Next() {
    var factor string
    var avgValue float64
    rs.Scan(&factor, &avgValue)
}
```text

---

## 9. 数据模型

### 9.1 公共错误

```go
var (
    ErrInvalidConfig       = errors.New("clickhousex: invalid config")
    ErrConnectionLost      = errors.New("clickhousex: connection lost")
    ErrTableNotFound       = errors.New("clickhousex: table not found")
    ErrColumnCountMismatch = errors.New("clickhousex: column count mismatch")
    ErrEmptyColumns        = errors.New("clickhousex: empty columns")
    ErrTypeMismatch        = errors.New("clickhousex: type mismatch")
    ErrPoolExhausted       = errors.New("clickhousex: connection pool exhausted")
)
```text

### 9.2 类型映射表

| ClickHouse 类型     | Go 类型                         |
| ------------------- | ------------------------------- |
| UInt8/16/32/64      | uint/uint8/uint16/uint32/uint64 |
| Int8/16/32/64       | int/int8/int16/int32/int64      |
| Float32/64          | float32/float64                 |
| String              | string                          |
| DateTime/DateTime64 | time.Time                       |
| Date                | time.Time                       |
| Decimal             | decimal.Decimal                 |
| Nullable(T)         | *T                              |
| LowCardinality(T)   | T                               |
| Array(T)            | []T                             |

---

## 10. 配置模式

```yaml
clickhousex:
  dsn: "clickhouse://user:pass@host:9000/db"  # ClickHouse 连接字符串
  pool_size: 10                                 # 初始连接池大小
  max_pool_size: 100                            # 最大连接池大小
  connect_timeout: 5s                           # 连接超时
  query_timeout: 60s                            # 查询超时（OLAP 查询较长）
  max_open_conns: 50                            # 最大打开连接数
  max_idle_conns: 10                            # 最大空闲连接数
  retry_count: 3                                # 连接重试次数
  retry_backoff: 100ms                          # 重试基础退避时间
```text

---

## 11. 错误处理

| 错误                     | 调用方处理                                           |
| ------------------------ | ---------------------------------------------------- |
| `ErrInvalidConfig`       | 检查 DSN 和配置参数，修复后重试                      |
| `ErrConnectionLost`      | 检查 ClickHouse 服务状态，等待后重试                 |
| `ErrTableNotFound`       | 先建表再写入，不能重试                               |
| `ErrColumnCountMismatch` | 检查 cols 和 rows 列数是否匹配                       |
| `ErrEmptyColumns`        | 传入非空 cols 切片                                   |
| `ErrTypeMismatch`        | 检查 Go 类型与 ClickHouse 列类型是否兼容             |
| `ErrPoolExhausted`       | 增大 max_pool_size 或减少并发                        |
| ClickHouse 原生错误      | 包装为 `clickhousex: <op>: <native_err>`，保留错误链 |

**错误消息格式：** `"clickhousex: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 12. 边界情况

| 场景                      | 预期行为                                         |
| ------------------------- | ------------------------------------------------ |
| DSN 格式错误              | NewClient 返回 `ErrInvalidConfig`                |
| ClickHouse 不可达         | NewClient 返回连接错误，不 panic                 |
| 批量写入空 rows           | InsertBatch 返回 nil（空操作）                   |
| 批量写入空 cols           | InsertBatch 返回 `ErrEmptyColumns`               |
| 查询结果为空              | 返回空 Rows，`Next()` 返回 false，无错误         |
| 并发调用 Close            | 幂等，不 panic                                   |
| 连接池耗尽                | 阻塞等待空闲连接，超时后返回 `ErrPoolExhausted`  |
| ctx 超时                  | 当前操作中断，返回 `ctx.Err()`                   |
| 大结果集查询              | Rows 逐行迭代，不一次性加载到内存                |
| Nullable 列 Scan 到非指针 | 返回 `ErrTypeMismatch`                           |
| Decimal 精度丢失          | 返回 `ErrTypeMismatch`，提示使用 decimal.Decimal |
| batch insert 部分失败     | 返回首个错误，包含行号                           |

---

## 13. 目录结构

```text
clickhousex/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go                      # 包级文档
├── clickhousex.go              # Client 工厂函数 NewClient
├── client.go                   # Client 实现
├── rows.go                     # Rows 实现
├── health.go                   # HealthStatus
├── options.go                  # Option 模式配置
├── errors.go                   # 公共错误变量
├── config.go                   # Config 结构体
├── types.go                    # ClickHouse 类型映射
├── internal/
│   ├── codec/                  # 类型转换（Go ↔ ClickHouse）
│   └── pool/                   # 连接池实现
├── testdata/
│   └── *.golden
├── example_test.go
├── benchmark_test.go
└── integration_test.go         //go:build integration
```text

---

## 14. 依赖

### 14.1 go.mod

```text
module github.com/ZoneCNH/clickhousex

go 1.23
```text

### 14.2 依赖方向

| 可以依赖                         | 禁止依赖                       |
| -------------------------------- | ------------------------------ |
| kernel（L0 原语）                | configx                        |
| observex（interface-only）       | 所有业务域                     |
| ClickHouse 驱动（clickhouse-go） | 所有 L2.5 领域共享层           |
| decimal 库（shopspring/decimal） | 其他存储扩展（taosx, ossx 等） |
| stdlib                           |                                |

### 14.3 特殊说明

clickhousex 通过接口接收 `observex.Logger` / `observex.Meter` / `observex.Tracer`，但只 import interface 定义所在的包。具体实现在 `x.go` 组装时注入。

---

## 15. 测试

### 15.1 单元测试

| AC     | 测试场景               | 验证点                        |
| ------ | ---------------------- | ----------------------------- |
| AC-001 | NewClient 合法配置     | 返回 Client，nil 错误         |
| AC-002 | NewClient 空 DSN       | 返回 `ErrInvalidConfig`       |
| AC-003 | Exec 正常 SQL          | 返回 nil                      |
| AC-004 | Exec 语法错误          | 返回包装错误                  |
| AC-005 | Query 有结果           | Rows 可迭代                   |
| AC-006 | Query 无结果           | 空 Rows，无错误               |
| AC-007 | InsertBatch 正常写入   | 返回 nil                      |
| AC-008 | InsertBatch 空 rows    | 返回 nil                      |
| AC-009 | InsertBatch 空 cols    | 返回 `ErrEmptyColumns`        |
| AC-010 | InsertBatch 列数不匹配 | 返回 `ErrColumnCountMismatch` |
| AC-011 | InsertBatch 表不存在   | 返回 `ErrTableNotFound`       |
| AC-012 | Scan 列数不匹配        | 返回 `ErrColumnCountMismatch` |
| AC-013 | Scan Nullable 到非指针 | 返回 `ErrTypeMismatch`        |
| AC-014 | ColumnTypes 返回正确   | 列名、类型、Nullable 标志正确 |
| AC-015 | Close 幂等             | 多次调用不 panic              |
| AC-016 | Health 连接正常        | Ready=true, Live=true         |
| AC-017 | Health 连接异常        | Ready=false, Live=false       |
| AC-018 | 连接池配置校验         | 默认 PoolSize=10, Max=100     |
| AC-019 | 原生 batch insert 协议 | 使用 ClickHouse 原生协议写入  |
| AC-020 | 参数化绑定防 SQL 注入  | args 使用占位符绑定           |
| AC-021 | 连接重试 3 次指数退避  | 断开后自动重连                |
| AC-022 | Health 幂等无副作用    | 多次调用结果一致              |
| AC-023 | context 取消/超时      | 操作中断，返回 ctx.Err()      |
| AC-024 | 错误消息格式           | "clickhousex: <op>: <detail>" |
| AC-025 | 可观测指标标签完整     | table/query 标签正确          |
| AC-026 | Decimal 类型映射       | Decimal → decimal.Decimal     |

### 15.2 Given/When/Then 用例

**TC-001: 正常写入和查询**
Given ClickHouse 可用，表已创建
When InsertBatch 写入 100 行
Then 返回 nil
When Query 查询这些行
Then 返回 100 行结果

**TC-002: 连接断开恢复**
Given Client 已创建
When ClickHouse 临时不可达
Then Exec 返回 `ErrConnectionLost`
When ClickHouse 恢复
Then Exec 成功，自动重连

**TC-003: 大批量写入**
Given 100000 行数据
When 调用 InsertBatch
Then 使用 batch insert 协议，< 1s 完成

**TC-004: Nullable 类型处理**
Given 表有 Nullable(Int32) 列
When 查询该列为 NULL 的行
Then Scan 到 *int32 类型，值为 nil

**TC-005: NewClient 配置校验**
Given DSN 缺失或格式非法
When 创建 NewClient
Then 返回配置错误且不建立连接

**TC-006: Health 检查**
Given ClickHouse 连接正常
When 调用 Health
Then 返回 healthy；连接失败时返回 unhealthy

**TC-007: Close 幂等**
Given client 已关闭
When 再次调用 Close
Then 返回 nil 且不 panic

### 15.3 Benchmark

| 场景                 | 目标    |
| -------------------- | ------- |
| 单次 Exec            | < 10ms  |
| InsertBatch 10000 行 | < 1s    |
| Query 返回 10000 行  | < 500ms |
| 连接池获取连接       | < 1ms   |

### 15.4 集成测试

| 场景                  | 验证点                              |
| --------------------- | ----------------------------------- |
| 完整写入-查询流程     | InsertBatch → Query → 数据一致      |
| 连接池压力测试        | 100 并发写入，无连接泄漏            |
| 健康检查              | ClickHouse 停止后 Health() 反映状态 |
| 大数据量写入          | 100 万行写入不 OOM                  |
| Nullable/Decimal 类型 | 类型映射正确                        |
| OLAP 聚合查询         | GROUP BY + 聚合函数正确执行         |

---

## 16. 性能预算

| 操作                  | 目标    | 测量方式       |
| --------------------- | ------- | -------------- |
| 单次 Exec             | < 10ms  | benchmark test |
| InsertBatch 10000 行  | < 1s    | benchmark test |
| InsertBatch 100000 行 | < 10s   | benchmark test |
| 单次 OLAP 查询        | < 100ms | benchmark test |
| 复杂聚合查询          | < 1s    | benchmark test |
| 连接池获取连接        | < 1ms   | benchmark test |
| 常驻内存（空闲）      | < 5MB   | profiling      |

---

## 17. 可观测性

| 类型   | 名称                         | 说明                                   |
| ------ | ---------------------------- | -------------------------------------- |
| metric | `clickhousex.query.duration` | histogram，查询耗时，标签：table       |
| metric | `clickhousex.write.duration` | histogram，写入耗时，标签：table       |
| metric | `clickhousex.write.rows`     | counter，写入行数，标签：table         |
| metric | `clickhousex.write.bytes`    | counter，写入字节数，标签：table       |
| metric | `clickhousex.pool.active`    | gauge，活跃连接数                      |
| metric | `clickhousex.pool.idle`      | gauge，空闲连接数                      |
| metric | `clickhousex.pool.exhausted` | counter，连接池耗尽次数                |
| log    | `clickhousex.connected`      | info，连接成功                         |
| log    | `clickhousex.disconnected`   | warn，连接断开                         |
| log    | `clickhousex.batch.insert`   | info，批量写入完成，含 rows + duration |
| log    | `clickhousex.query.error`    | error，查询失败，含 sql + error        |
| span   | `clickhousex.exec`           | 单次 Exec 的 tracing span              |
| span   | `clickhousex.query`          | 单次 Query 的 tracing span             |
| span   | `clickhousex.insert_batch`   | 批量写入的 tracing span                |

---

## 18. 安全

| 要求                   | 实现方式                                 |
| ---------------------- | ---------------------------------------- |
| DSN 不泄露到日志       | 日志中 DSN 脱敏，密码部分用 `***` 替代   |
| SQL 注入防护           | 参数化绑定，禁止 SQL 拼接                |
| 错误消息不泄露连接详情 | 错误消息包含操作名和错误类型，不包含 DSN |
| 连接凭据不硬编码       | 通过 Config 或环境变量注入               |

---

## 19. CI 门禁

### 19.1 通用 Gate

| Gate        | 命令                                                                                                               | 阻塞条件                 |
| ----------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| 编译        | `go build ./...`                                                                                                   | 编译失败                 |
| 测试        | `go test ./... -race -count=1`                                                                                     | 任何测试失败或 data race |
| 覆盖率      | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80%           |
| vet         | `go vet ./...`                                                                                                     | 任何 vet 错误            |
| lint        | `golangci-lint run`                                                                                                | 任何 lint 错误           |
| 依赖检查    | `go mod tidy && git diff --exit-code go.mod go.sum`                                                                | go.mod 不整洁            |
| Secret 扫描 | `gitleaks detect --no-git`                                                                                         | 泄露 secret              |
| Benchmark   | `go test -bench=. -benchmem -count=3 ./...`                                                                        | 结果附在 PR comment      |

### 19.2 clickhousex 专属 Gate

| Gate               | 命令                              | 阻塞条件                                 |                  |
| ------------------ | --------------------------------- | ---------------------------------------- |                  |
| 集成测试           | `go test -tags=integration ./...` | ClickHouse 不可达时 skip，可达时必须通过 |                  |
| 无直接依赖 configx | `go list -deps ./... \            | grep configx`                            | 不应依赖 configx |

---

## 20. 升级兼容性

| 变更类型              | 版本升级                                    |
| --------------------- | ------------------------------------------- |
| Client interface 变更 | **major**（所有消费方需同步更新）           |
| Config 新增可选字段   | patch / minor                               |
| Config 新增必填字段   | **minor**（带默认值）                       |
| 新增 Client 方法      | **minor**（不影响现有实现）                 |
| 类型映射变更          | **major**（影响现有 Scan 行为）             |
| 错误变量变更          | **minor**（新增错误为 minor，删除为 major） |
| 修复 bug              | **patch**                                   |

---

## 21. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试
- [ ] 集成测试在无 ClickHouse 环境下正确 skip
- [ ] ClickHouse 类型映射表有对应测试覆盖

---

## 22. 待解决问题

- 是否需要支持 ClickHouse 的异步 insert（`async_insert`）模式？当前设计使用同步 batch insert。
- Decimal 类型使用哪个 Go 库？`shopspring/decimal` 还是标准库 `math/big`？
- 是否需要支持 ClickHouse 的压缩传输（`zstd`/`lz4`）？原生驱动是否默认启用？
- 连接池是否需要支持动态扩缩容？
- 是否需要支持 ClickHouse 的分布式表查询（跨分片聚合）？
- 批量写入失败时是否需要支持部分重试？


## 23. 变更历史

| 日期       | 版本   | 变更内容   | 作者    |
| ---------- | ------ | ---------- | ------- |
| 2026-06-07 | v1.0.0 | 初始版本                                                              | ZoneCNH |
| 2026-06-14 | v1.0.1 | 完整追溯矩阵（§1-§7）、AC 编号体系（AC-001~AC-026）、覆盖率 100%、Status → Approved | ZoneCNH |