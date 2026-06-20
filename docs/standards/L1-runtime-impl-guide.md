# L1 运行时层实现规范

> **效力层级**：`CONSTITUTION.md` §1-§6 > 本文档 > `go-coding-standards.md`

---

## 1. 层定义

| 属性 | 要求 |
|------|------|
| 可依赖 | `kernel`（L0） |
| 禁止依赖 | 其他 L1、业务域、存储扩展 |
| 测试覆盖率 | **≥ 80%**（CONSTITUTION §5.1） |

**L1 模块**：`configx`、`observex`、`resiliencx`、`schedulex`、`testkitx`（test-only）

**存储扩展**（L1 同层，不得互依）：`redisx`、`kafkax`、`natsx`、`postgresx`、`taosx`、`ossx`、`clickhousex`

---

## 2. 依赖约束（CONSTITUTION §3.4）

```bash
# 验证：输出非空则违规
go mod graph | grep "github.com/ZoneCNH/configx " \
  | grep -E "observex|resiliencx|redisx|contracts"
```

---

## 3. Config 结构体规范（CONSTITUTION §4.3）

```go
type Config struct {
    Addr        string              `mapstructure:"addr"         validate:"required"`
    PoolSize    int                 `mapstructure:"pool_size"`
    Password    kernel.SecretString `mapstructure:"password"`     // 敏感字段必须用 SecretString
    DialTimeout time.Duration       `mapstructure:"dial_timeout"`
}

func (c *Config) Validate() error {
    if c.Addr == ""          { return fmt.Errorf("redisx: addr required") }
    if c.PoolSize    <= 0    { c.PoolSize = 10 }
    if c.DialTimeout <= 0    { c.DialTimeout = 5 * time.Second }
    return nil
}

func DefaultConfig() Config {
    return Config{PoolSize: 10, DialTimeout: 5 * time.Second}
}
```

---

## 4. 健康检查（CONSTITUTION §6.2 强制）

```go
var _ healthx.HealthChecker = (*Client)(nil) // 编译期检查

func (c *Client) HealthCheck(ctx context.Context) healthx.HealthStatus {
    ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
    defer cancel()
    if err := c.Ping(ctx); err != nil {
        return healthx.HealthStatus{Status: healthx.Unhealthy, Message: err.Error()}
    }
    return healthx.HealthStatus{
        Status:  healthx.Healthy,
        Details: map[string]any{"pool_idle": c.pool.IdleConns()},
    }
}
```

---

## 5. 生命周期接入（lifecycx.Component）

```go
var _ lifecycx.Component = (*Client)(nil)

func (c *Client) Name() string { return "redisx" }

func (c *Client) Start(ctx context.Context) error {
    c.ctx, c.cancel = context.WithCancel(context.Background())
    if err := c.pool.Open(ctx); err != nil {
        return fmt.Errorf("redisx: start: %w", err)
    }
    c.wg.Add(1)
    go func() { defer c.wg.Done(); c.heartbeatLoop(c.ctx) }()
    return nil
}

func (c *Client) Stop(ctx context.Context) error {
    c.cancel()
    done := make(chan struct{})
    go func() { c.wg.Wait(); close(done) }()
    select {
    case <-done:       return c.pool.Close(ctx)
    case <-ctx.Done(): return fmt.Errorf("redisx: stop timeout")
    }
}
```

---

## 6. 可观测性规范（CONSTITUTION §6.1/§6.3/§6.4）

```go
// Metrics 命名：foundationx_<module>_<operation>_<measure>
const MetricGetDuration = "foundationx_redisx_get_duration_seconds"

// Label 只用低基数枚举，禁止高基数字段（key/user_id）
metrics.Record("...", map[string]string{"status": "ok", "operation": "get"})

// 敏感字段必须脱敏（CONSTITUTION §6.4）
logger.Info("connecting", obsx.String("password", observex.Redact(string(c.cfg.Password))))
```

---

## 7. 存储扩展专属规则

- **配置由外部注入**：存储扩展内部禁止调用 `configx`
- **重试用 kernel/retryx**：不得引入 `resiliencx`
- **存储间不得互依**：`redisx` 禁止 import `kafkax`

```go
// Good：配置注入
func NewClient(cfg Config) (*Client, error) {
    if err := cfg.Validate(); err != nil { return nil, err }
    return &Client{cfg: cfg}, nil
}
```

---

## 8. 禁止事项

| 禁止 | 原因 |
|------|------|
| import 其他 L1 | 同层平级（CONSTITUTION §3.2） |
| import 业务域 | 依赖方向（CONSTITUTION §3.1） |
| `testkitx` 进生产 | test-only（CONSTITUTION P4） |
| 高基数 Metric label | 爆炸 Prometheus（CONSTITUTION §6.3） |
| 直接打印 SecretString | 泄露（CONSTITUTION §6.4） |
| 覆盖率 < 80% | CONSTITUTION §5.1 |

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [`L0-kernel-impl-guide.md`](./L0-kernel-impl-guide.md) | L0 原语层 |
| [`go-coding-standards.md`](./go-coding-standards.md) | 通用 Go 规范 |
| [`CONSTITUTION.md`](../../CONSTITUTION.md) §3-§6 | 依赖/接口/测试/可观测 |
