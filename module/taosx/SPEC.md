# taosx 完整规格

> 基座 · 存储扩展。TDengine 时序数据库客户端封装。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: L1 存储扩展
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/taosx](https://github.com/ZoneCNH/taosx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [kernel](../kernel/SPEC.md), [observex](../observex/SPEC.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`taosx` 封装 TDengine 客户端，提供统一的连接管理、批量写入、时序查询和可观测集成。屏蔽 TDengine 原生驱动的连接池、STMT 写入、错误码差异，为上层数据域模块提供简洁的存储接口。

---

## 3. Problem

量化交易系统需要高效存储和查询大量时序数据（行情快照、K 线、因子值、信号日志）。直接使用 TDengine 原生驱动存在以下问题：

- 连接管理分散，各模块各自维护连接池，资源浪费
- 批量写入需要处理 STMT 绑定、自动建表、错误重试，逻辑复杂
- 查询结果迭代缺少统一的错误传播机制
- 缺少统一的可观测集成，排查写入/查询延迟困难
- 健康检查逻辑各模块重复实现

---

## 4. Goals

- 提供 `Client` 接口，统一封装 Exec / Query / InsertBatch 操作
- 管理 TDengine 连接池，支持配置化调参
- 批量写入支持 STMT 模式，自动处理绑定和错误
- 提供 `Rows` 接口统一查询结果迭代
- 集成 observex 的 metrics / tracing / logging
- 提供 `Health()` 健康检查，与 kernel 生命周期对齐
- 集成测试在 TDengine 不可达时自动 skip

---

## 5. Non-goals

- 不做 TDengine 集群管理或部署编排
- 不做数据模型定义（超级表 schema 由业务层决定）
- 不做数据压缩（TDengine 原生支持）
- 不做数据迁移或 schema migration
- 不做实时流式订阅（TDengine 的 subscription 功能）
- 不做 SQL 拼接 DSL（调用方传 raw SQL）

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `market-data` | 写入行情快照、K 线数据 |
| `factor-engine` | 写入因子值、查询历史因子 |
| `signal-engine` | 写入信号日志 |
| `x.go`（组合根） | 创建 Client 实例，注入到数据域模块 |
| 运维/监控 | 通过 Health() 检查 TDengine 连接状态 |

---

## 7. Functional Requirements

### FR-001: NewClient

WHEN 调用 `NewClient(cfg Config)` 且配置合法（DSN 非空）
THEN 创建连接池，返回 Client 实例，nil 错误

WHEN 调用 `NewClient(cfg Config)` 且 DSN 为空
THEN 返回 `ErrInvalidConfig`，不创建连接

### FR-002: Exec

WHEN 调用 `Exec(ctx, sql, args...)` 且 SQL 语法正确、连接可用
THEN 执行 SQL，返回 nil

WHEN 调用 `Exec(ctx, sql, args...)` 且 SQL 语法错误
THEN 返回包装后的 TDengine 错误，包含 SQL 上下文

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

WHEN 调用 `InsertBatch(ctx, table, rows)` 且 rows 非空
THEN 使用 STMT 模式批量写入，返回 nil

WHEN 调用 `InsertBatch(ctx, table, rows)` 且 rows 为空
THEN 返回 nil（空操作）

WHEN 调用 `InsertBatch(ctx, table, rows)` 且 table 不存在
THEN 返回 `ErrTableNotFound`（不自动建表，由业务层负责）

WHEN 批量写入过程中部分行失败
THEN 返回首个错误，已成功的行不回滚（TDengine 不支持事务回滚）

### FR-005: Health

WHEN 调用 `Health()` 且连接池可用
THEN 返回 `HealthStatus{Ready: true, Live: true}`

WHEN 调用 `Health()` 且连接池不可用
THEN 返回 `HealthStatus{Ready: false, Live: false, Message: "connection pool exhausted"}`

WHEN 连接池部分可用（有空闲连接但少于阈值）
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
THEN 将当前行数据写入 dest，返回 nil

WHEN 调用 `Scan(dest...)` 且列数不匹配
THEN 返回 `ErrColumnCountMismatch`

WHEN 调用 `Close()` 且迭代未完成
THEN 释放底层资源，返回 nil

---

## 8. Business Rules

| 编号 | 规则 |
|------|------|
| BR-001 | 连接池大小默认 10，最大 100，通过 Config 配置 |
| BR-002 | 批量写入使用 STMT 模式，不使用拼接 SQL |
| BR-003 | Exec / Query 的 args 使用参数化绑定，禁止 SQL 拼接 |
| BR-004 | 连接断开后自动重试 3 次（指数退避），超过后返回 `ErrConnectionLost` |
| BR-005 | Health() 必须是幂等的、无副作用的 |
| BR-006 | 所有操作必须接受 `context.Context`，支持取消和超时 |
| BR-007 | 错误消息格式：`"taosx: <operation>: <detail>"` |
| BR-008 | 可观测指标必须包含 table 标签（写入操作）或 sql 标签（查询操作） |
| BR-009 | Close() 必须是幂等的，多次调用不 panic |
| BR-010 | InsertBatch 不自动建表，表不存在时返回明确错误 |

---

## 9. Interface Contract

### 9.1 Client / Rows / Row

```go
type Client interface {
    Exec(ctx context.Context, sql string, args ...any) error
    Query(ctx context.Context, sql string, args ...any) (Rows, error)
    InsertBatch(ctx context.Context, table string, rows []Row) error
    Health() HealthStatus
    Close() error
}

type Rows interface {
    Next() bool
    Scan(dest ...any) error
    Close() error
    Err() error
}

type Row map[string]any

type HealthStatus struct {
    Ready   bool
    Live    bool
    Message string
}
```text

### 9.2 Config

```go
type Config struct {
    DSN           string        // TDengine 连接字符串
    PoolSize      int           // 连接池大小，默认 10
    MaxPoolSize   int           // 最大连接池大小，默认 100
    ConnectTimeout time.Duration // 连接超时，默认 5s
    QueryTimeout   time.Duration // 查询超时，默认 30s
}
```text

### 9.3 用法示例

```go
client, err := taosx.NewClient(taosx.Config{
    DSN:      "root:taosdata@tcp(host:6030)/db",
    PoolSize: 20,
})
if err != nil {
    log.Fatal(err)
}
defer client.Close()

// 执行 SQL
err = client.Exec(ctx, "CREATE STABLE IF NOT EXISTS kline (ts TIMESTAMP, close FLOAT) TAGS (symbol BINARY(32))")

// 批量写入
rows := []taosx.Row{
    {"ts": time.Now(), "close": 100.5, "symbol": "BTCUSDT"},
}
err = client.InsertBatch(ctx, "kline_BTCUSDT", rows)

// 查询
rs, err := client.Query(ctx, "SELECT ts, close FROM kline_BTCUSDT WHERE ts > ?", startTime)
defer rs.Close()
for rs.Next() {
    var ts time.Time
    var close float64
    rs.Scan(&ts, &close)
}
```text

---

## 10. Data Model

### 10.1 公共错误

```go
var (
    ErrInvalidConfig       = errors.New("taosx: invalid config")
    ErrConnectionLost      = errors.New("taosx: connection lost")
    ErrTableNotFound       = errors.New("taosx: table not found")
    ErrColumnCountMismatch = errors.New("taosx: column count mismatch")
    ErrPoolExhausted       = errors.New("taosx: connection pool exhausted")
    ErrBatchPartialFail    = errors.New("taosx: batch insert partial failure")
)
```text

### 10.2 健康状态枚举

```go
type PoolState int

const (
    PoolHealthy   PoolState = iota // 连接池充足
    PoolLow                        // 连接池低水位
    PoolExhausted                  // 连接池耗尽
)
```text

---

## 11. Config Schema

```yaml
taosx:
  dsn: "root:taosdata@tcp(host:6030)/db"  # TDengine 连接字符串
  pool_size: 10                             # 初始连接池大小
  max_pool_size: 100                        # 最大连接池大小
  connect_timeout: 5s                       # 连接超时
  query_timeout: 30s                        # 查询超时
  retry_count: 3                            # 连接重试次数
  retry_backoff: 100ms                      # 重试基础退避时间
```text

---

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| `ErrInvalidConfig` | 检查 DSN 和配置参数，修复后重试 |
| `ErrConnectionLost` | 检查 TDengine 服务状态，等待后重试 |
| `ErrTableNotFound` | 先建表再写入，不能重试 |
| `ErrColumnCountMismatch` | 检查 Row 字段数与表列数是否匹配 |
| `ErrPoolExhausted` | 增大 max_pool_size 或减少并发 |
| `ErrBatchPartialFail` | 检查错误详情，重试失败的行 |
| TDengine 原生错误 | 包装为 `taosx: <op>: <native_err>`，保留错误链 |

**错误消息格式：** `"taosx: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| DSN 格式错误 | NewClient 返回 `ErrInvalidConfig` |
| TDengine 不可达 | NewClient 返回连接错误，不 panic |
| 批量写入空 rows | InsertBatch 返回 nil（空操作） |
| 查询结果为空 | 返回空 Rows，`Next()` 返回 false，无错误 |
| 并发调用 Close | 幂等，不 panic |
| 连接池耗尽 | 阻塞等待空闲连接，超时后返回 `ErrPoolExhausted` |
| ctx 超时 | 当前操作中断，返回 `ctx.Err()` |
| 大结果集查询 | Rows 逐行迭代，不一次性加载到内存 |
| STMT 绑定类型不匹配 | 返回类型转换错误，包含字段名和期望类型 |
| TDengine 自动建表冲突 | 返回原生错误，不重试 |

---

## 14. Directory Structure

```text
taosx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go                      # 包级文档
├── taosx.go                    # Client 工厂函数 NewClient
├── client.go                   # Client 实现
├── rows.go                     # Rows 实现
├── health.go                   # HealthStatus
├── options.go                  # Option 模式配置
├── errors.go                   # 公共错误变量
├── config.go                   # Config 结构体
├── internal/
│   ├── codec/                  # 类型转换（Go ↔ TDengine）
│   └── pool/                   # 连接池实现
├── testdata/
│   └── *.golden
├── example_test.go
├── benchmark_test.go
└── integration_test.go         //go:build integration
```text

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/taosx

go 1.23
```text

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | configx |
| observex（interface-only） | 所有业务域 |
| TDengine 客户端库 | 所有 L2.5 领域共享层 |
| stdlib | 其他存储扩展（redisx, clickhousex 等） |

### 15.3 特殊说明

taosx 通过接口接收 `observex.Logger` / `observex.Meter` / `observex.Tracer`，但只 import interface 定义所在的包。具体实现在 `x.go` 组装时注入。

---

## 16. Testing

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| NewClient 合法配置 | 返回 Client，nil 错误 |
| NewClient 空 DSN | 返回 `ErrInvalidConfig` |
| Exec 正常 SQL | 返回 nil |
| Exec 语法错误 | 返回包装错误 |
| Query 有结果 | Rows 可迭代 |
| Query 无结果 | 空 Rows，无错误 |
| InsertBatch 正常写入 | 返回 nil |
| InsertBatch 空 rows | 返回 nil |
| InsertBatch 表不存在 | 返回 `ErrTableNotFound` |
| Scan 列数不匹配 | 返回 `ErrColumnCountMismatch` |
| Close 幂等 | 多次调用不 panic |
| Health 连接正常 | Ready=true, Live=true |
| Health 连接异常 | Ready=false, Live=false |

### 16.2 Given/When/Then 用例

**TC-001: 正常写入和查询**
Given TDengine 可用，表已创建
When InsertBatch 写入 100 行
Then 返回 nil
When Query 查询这些行
Then 返回 100 行结果

**TC-002: 连接断开恢复**
Given Client 已创建
When TDengine 临时不可达
Then Exec 返回 `ErrConnectionLost`
When TDengine 恢复
Then Exec 成功，自动重连

**TC-003: 大批量写入**
Given 10000 行数据
When 调用 InsertBatch
Then 使用 STMT 模式批量写入，< 1s 完成

**TC-004: NewClient 配置校验**
Given DSN 或 endpoint 缺失
When 创建 NewClient
Then 返回配置错误且不建立连接

**TC-005: Health 检查**
Given TDengine 连接正常
When 调用 Health
Then 返回 healthy；连接失败时返回 unhealthy

**TC-006: Close 幂等**
Given client 已关闭
When 再次调用 Close
Then 返回 nil 且不 panic

### 16.3 Benchmark

| 场景 | 目标 |
|------|------|
| 单次 Exec | < 5ms |
| InsertBatch 1000 行 | < 50ms |
| Query 返回 1000 行 | < 100ms |
| 连接池获取连接 | < 1ms |

### 16.4 集成测试

| 场景 | 验证点 |
|------|--------|
| 完整写入-查询流程 | InsertBatch → Query → 数据一致 |
| 连接池压力测试 | 100 并发写入，无连接泄漏 |
| 健康检查 | TDengine 停止后 Health() 反映状态 |
| 大文件写入 | 100 万行写入不 OOM |

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 单次 Exec | < 5ms | benchmark test |
| InsertBatch 1000 行 | < 50ms | benchmark test |
| InsertBatch 10000 行 | < 500ms | benchmark test |
| Query 返回 1000 行 | < 100ms | benchmark test |
| 连接池获取连接 | < 1ms | benchmark test |
| 常驻内存（空闲） | < 5MB | profiling |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `taosx.query.duration` | histogram，查询耗时，标签：table |
| metric | `taosx.write.duration` | histogram，写入耗时，标签：table |
| metric | `taosx.write.rows` | counter，写入行数，标签：table |
| metric | `taosx.pool.active` | gauge，活跃连接数 |
| metric | `taosx.pool.idle` | gauge，空闲连接数 |
| metric | `taosx.pool.exhausted` | counter，连接池耗尽次数 |
| log | `taosx.connected` | info，连接成功 |
| log | `taosx.disconnected` | warn，连接断开 |
| log | `taosx.batch.insert` | info，批量写入完成，含 rows + duration |
| log | `taosx.query.error` | error，查询失败，含 sql + error |
| span | `taosx.exec` | 单次 Exec 的 tracing span |
| span | `taosx.query` | 单次 Query 的 tracing span |
| span | `taosx.insert_batch` | 批量写入的 tracing span |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| DSN 不泄露到日志 | 日志中 DSN 脱敏，密码部分用 `***` 替代 |
| SQL 注入防护 | 参数化绑定，禁止 SQL 拼接 |
| 错误消息不泄露连接详情 | 错误消息包含操作名和错误类型，不包含 DSN |
| 连接凭据不硬编码 | 通过 Config 或环境变量注入 |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `go test ./... -coverprofile=cover.out && go tool cover -func=cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 20.2 taosx 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 集成测试 | `go test -tags=integration ./...` | TDengine 不可达时 skip，可达时必须通过 |
| 无直接依赖 configx | `go list -deps ./... \| grep configx` | 不应依赖 configx |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| Client interface 变更 | **major**（所有消费方需同步更新） |
| Config 新增可选字段 | patch / minor |
| Config 新增必填字段 | **minor**（带默认值） |
| 新增 Client 方法 | **minor**（不影响现有实现） |
| 错误变量变更 | **minor**（新增错误为 minor，删除为 major） |
| 修复 bug | **patch** |

---

## 22. Release DoD

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
- [ ] 集成测试在无 TDengine 环境下正确 skip

---

## 23. Open Questions

- STMT 模式是否需要支持自动建表（当前设计不支持，BR-010）？如果支持，需要明确 schema 来源。
- 连接池是否需要支持动态扩缩容（运行时根据负载调整）？
- 是否需要支持 TDengine 的订阅功能（实时推送）？当前 Non-goal 排除。
- 批量写入失败时是否需要支持部分重试（只重试失败的行）？
- 是否需要支持多数据库（跨库查询）？
