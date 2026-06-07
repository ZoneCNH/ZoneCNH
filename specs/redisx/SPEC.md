# redisx 完整规格

> 基座 · 存储扩展。Redis 客户端封装。当前仅骨架。

最后更新：2026-06-07

---

## 1. 定位

`redisx` 封装 Redis 客户端，提供统一的连接管理、序列化、健康检查和可观测集成。

### 核心职责

- 连接池管理
- 统一序列化/反序列化
- 健康检查（PING）
- 可观测集成（metrics、tracing、logging）
- 分布式锁（可选，供 schedulex 使用）
- 与 kernel 生命周期集成

### 明确不做

- 不做 Redis 集群管理
- 不做 Redis 数据结构抽象（直接暴露 Redis 命令）
- 不做缓存策略（业务层决定）

---

## 2. 接口契约

```go
type Client interface {
    Get(ctx context.Context, key string) (string, error)
    Set(ctx context.Context, key string, value any, ttl time.Duration) error
    Del(ctx context.Context, keys ...string) error
    Exists(ctx context.Context, keys ...string) (int64, error)
    Expire(ctx context.Context, key string, ttl time.Duration) error
    HGet(ctx context.Context, key, field string) (string, error)
    HSet(ctx context.Context, key string, values ...any) error
    LPush(ctx context.Context, key string, values ...any) error
    LRange(ctx context.Context, key string, start, stop int64) ([]string, error)
    Subscribe(ctx context.Context, channels ...string) (<-chan Message, error)
    Pipeline() Pipeline
    Health() HealthStatus
    Close() error
}

type Pipeline interface {
    Get(key string) *StringCmd
    Set(key string, value any, ttl time.Duration) *StatusCmd
    Exec(ctx context.Context) ([]Cmder, error)
}

type Locker interface {
    Acquire(ctx context.Context, key string, ttl time.Duration) (bool, error)
    Release(ctx context.Context, key string) error
}
```

---

## 3. 目录结构

```
redisx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── redisx.go                   # Client 工厂
├── client.go
├── pipeline.go
├── locker.go
├── health.go
├── options.go
├── errors.go
├── internal/
│   ├── pool/
│   └── codec/
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
| redis 客户端库 | |
| stdlib | |

---

## 5. CI Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 测试失败 |
| 覆盖率 | ≥ 80% | 覆盖率不足 |
| 集成测试 | `go test -tags=integration ./...` | Redis 不可达时 skip |

---

## 6. 测试矩阵

| 测试场景 | 验证点 |
|----------|--------|
| 连接池创建 | 配置正确 → 连接成功 |
| 连接失败 | Redis 不可达 → 返回错误 |
| Get/Set | 基本读写 |
| Pipeline | 批量操作原子性 |
| 分布式锁 | Acquire/Release 正确性 |
| 健康检查 | PING 成功/失败 |

---

## 7. 性能预算

| 操作 | 目标 |
|------|------|
| 单次 Get/Set | < 1ms（本地 Redis） |
| Pipeline 100 命令 | < 5ms |

---

## 8. 可观测输出

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `redisx.command.duration` | histogram，命令耗时 |
| metric | `redisx.command.errors` | counter，命令失败次数 |
| metric | `redisx.pool.size` | gauge，连接池大小 |
| log | `redisx.connected` | info，连接成功 |
| log | `redisx.disconnected` | warn，连接断开 |

---

## 9. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 测试覆盖率 ≥ 80%
- [ ] 集成测试可选跳过（无 Redis 时）
- [ ] CHANGELOG.md 已更新
