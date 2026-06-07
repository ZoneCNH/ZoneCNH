# clickhousex 完整规格

> 基座 · 存储扩展。ClickHouse 客户端封装。当前仅骨架。

最后更新：2026-06-07

---

## 1. 定位

`clickhousex` 封装 ClickHouse 客户端，提供统一的连接管理、批量写入、OLAP 查询和可观测集成。ClickHouse 用于分析型查询和历史数据存储。

### 核心职责

- 连接池管理
- 批量写入（Batch Insert）
- OLAP 查询
- 健康检查
- 可观测集成（metrics、tracing、logging）
- 与 kernel 生命周期集成

### 明确不做

- 不做 ClickHouse 集群管理
- 不做数据模型定义（业务层决定）
- 不做数据压缩（ClickHouse 原生支持）

---

## 2. 接口契约

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
```

---

## 3. 目录结构

```
clickhousex/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── clickhousex.go              # Client 工厂
├── client.go
├── health.go
├── options.go
├── errors.go
├── internal/
│   ├── codec/
│   └── pool/
├── testdata/
├── example_test.go
├── benchmark_test.go
└── integration_test.go
```

---

## 4. 依赖

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | configx |
| observex（interface-only） | 所有业务域 |
| ClickHouse 驱动 | |
| stdlib | |

---

## 5. CI Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 测试失败 |
| 覆盖率 | ≥ 80% | 覆盖率不足 |
| 集成测试 | `go test -tags=integration ./...` | ClickHouse 不可达时 skip |

---

## 6. 测试矩阵

| 测试场景 | 验证点 |
|----------|--------|
| 连接创建 | 配置正确 → 连接成功 |
| Exec | SQL 执行成功 |
| Query | 查询返回正确结果 |
| InsertBatch | 批量写入正确性 |
| 健康检查 | 连接状态正确反映 |

---

## 7. 性能预算

| 操作 | 目标 |
|------|------|
| 单次查询 | < 100ms（OLAP 查询） |
| 批量写入 10000 行 | < 1s |

---

## 8. 可观测输出

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `clickhousex.query.duration` | histogram，查询耗时 |
| metric | `clickhousex.write.duration` | histogram，写入耗时 |
| metric | `clickhousex.write.rows` | counter，写入行数 |
| log | `clickhousex.connected` | info，连接成功 |

---

## 9. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 测试覆盖率 ≥ 80%
- [ ] 集成测试可选跳过（无 ClickHouse 时）
- [ ] CHANGELOG.md 已更新
