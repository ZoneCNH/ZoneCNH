# postgresx 完整规格

> 基座 · 存储扩展。PostgreSQL 客户端封装。当前仅骨架。

最后更新：2026-06-07

---

## 1. 定位

`postgresx` 封装 PostgreSQL 客户端，提供统一的连接管理、查询构建、事务、迁移和可观测集成。

### 核心职责

- 连接池管理
- 查询构建器（可选）
- 事务管理
- Schema 迁移
- 健康检查
- 可观测集成（metrics、tracing、logging）
- 与 kernel 生命周期集成

### 明确不做

- 不做 ORM（直接暴露 SQL）
- 不做数据库集群管理
- 不做数据模型定义（业务层决定）

---

## 2. 接口契约

```go
type Client interface {
    Query(ctx context.Context, sql string, args ...any) (Rows, error)
    QueryRow(ctx context.Context, sql string, args ...any) Row
    Exec(ctx context.Context, sql string, args ...any) (Result, error)
    Tx(ctx context.Context, fn func(tx Tx) error) error
    Health() HealthStatus
    Close() error
}

type Tx interface {
    Query(ctx context.Context, sql string, args ...any) (Rows, error)
    QueryRow(ctx context.Context, sql string, args ...any) Row
    Exec(ctx context.Context, sql string, args ...any) (Result, error)
}

type Rows interface {
    Next() bool
    Scan(dest ...any) error
    Close() error
    Err() error
}

type Row interface {
    Scan(dest ...any) error
}

type Result interface {
    RowsAffected() int64
}
```

---

## 3. 目录结构

```
postgresx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── postgresx.go                # Client 工厂
├── client.go
├── tx.go
├── health.go
├── options.go
├── errors.go
├── migrate/
│   ├── migrate.go
│   └── embed.go
├── internal/
│   ├── pool/
│   └── trace/
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
| PostgreSQL 驱动 | |
| stdlib | |

---

## 5. CI Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 测试失败 |
| 覆盖率 | ≥ 80% | 覆盖率不足 |
| 集成测试 | `go test -tags=integration ./...` | PostgreSQL 不可达时 skip |

---

## 6. 测试矩阵

| 测试场景 | 验证点 |
|----------|--------|
| 连接池创建 | 配置正确 → 连接成功 |
| Query/Exec | 基本读写 |
| 事务提交 | Tx 内操作原子提交 |
| 事务回滚 | Tx 内错误 → 自动回滚 |
| 健康检查 | PING 成功/失败 |
| 迁移 | Schema 迁移正确执行 |

---

## 7. 性能预算

| 操作 | 目标 |
|------|------|
| 单次 Query | < 5ms（本地 PostgreSQL） |
| 事务（5 条 SQL） | < 10ms |

---

## 8. 可观测输出

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `postgresx.query.duration` | histogram，查询耗时 |
| metric | `postgresx.query.errors` | counter，查询失败次数 |
| metric | `postgresx.pool.size` | gauge，连接池大小 |
| log | `postgresx.connected` | info，连接成功 |
| log | `postgresx.migration.applied` | info，迁移已应用 |

---

## 9. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 测试覆盖率 ≥ 80%
- [ ] 集成测试可选跳过（无 PostgreSQL 时）
- [ ] CHANGELOG.md 已更新
