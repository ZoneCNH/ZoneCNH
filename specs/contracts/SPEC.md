# contracts 完整规格

> 基座 · 契约层。跨域稳定端口、事件协议、DTO 契约。

最后更新：2026-06-07

---

## 1. 定位

`contracts` 定义跨域稳定契约——端口（接口）、事件协议和 DTO。它是域间通信的唯一合法通道。

### 核心职责

- 跨域端口定义（Provider / Consumer 接口）
- 事件协议（Event Topic、Event DTO）
- 跨域 DTO（请求/响应/传输对象）
- 契约版本管理
- 契约稳定性保证（breaking change 检测）

### 明确不做

- 不包含域内接口（留在各域内部）
- 不包含临时适配器
- 不包含通用工具函数
- 不包含领域模型全集（领域值对象在 L2.5）
- 不承载业务逻辑实现

---

## 2. 接口契约

### 2.1 数据输入端口

```go
type MarketDataProvider interface {
    Subscribe(ctx context.Context, symbols []string) (<-chan MarketEvent, error)
    GetSnapshot(ctx context.Context, symbol string) (*MarketSnapshot, error)
    GetHistory(ctx context.Context, req HistoryRequest) ([]Bar, error)
}

type MacroDataProvider interface {
    GetLatest(ctx context.Context, indicator string) (*MacroPoint, error)
    GetHistory(ctx context.Context, req MacroHistoryRequest) ([]MacroPoint, error)
    Subscribe(ctx context.Context, indicators []string) (<-chan MacroEvent, error)
}
```

### 2.2 事件协议

```go
type Event interface {
    EventID() string
    EventType() string
    Timestamp() time.Time
    Source() string
}

const (
    TopicMarketData = "market.data"
    TopicMacroData  = "macro.data"
    TopicSignal     = "signal.generated"
    TopicOrder      = "order.submitted"
    TopicExecution  = "execution.filled"
    TopicPosition   = "position.updated"
    TopicRisk       = "risk.alert"
)
```

### 2.3 契约约束

- 所有跨域 DTO 必须在 `contracts` 中定义
- 新增契约必须说明消费方、生产方和稳定期
- 契约变更是 breaking change → 需要版本升级
- 端口接口保持窄（3-5 个方法）
- 事件 DTO 不可变（只读字段）

---

## 3. 目录结构

```
contracts/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── contracts.go                # 版本常量
├── market.go                   # 行情端口和 DTO
├── macro.go                    # 宏观端口和 DTO
├── signal.go                   # 信号 DTO
├── order.go                    # 订单 DTO
├── execution.go                # 执行 DTO
├── position.go                 # 仓位 DTO
├── risk.go                     # 风险 DTO
├── events.go                   # 事件基础接口和 topic 常量
├── ports.go                    # Provider / Consumer 端口
├── internal/
│   └── validate/
├── testdata/
│   └── *.golden
├── example_test.go
└── breaking_test.go
```

---

## 4. 依赖

| 可以依赖 | 禁止依赖 |
|----------|----------|
| L2.5 领域共享层（decimalx, domain-*） | 所有业务域实现 |
| stdlib | Foundation L1 运行时模块 |

---

## 5. CI Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 测试失败 |
| 覆盖率 | ≥ 80% | 覆盖率不足 |
| breaking change | `go test -run TestBreakingChange ./...` | 接口/DTO 有破坏性变更但未 bump 版本 |
| 新增契约审查 | PR 必须说明消费方、生产方和稳定期 | 未说明 |

---

## 6. 测试矩阵

| 测试场景 | 验证点 |
|----------|--------|
| 端口编译期检查 | `var _ MarketDataProvider = (*mockImpl)(nil)` |
| DTO 序列化/反序列化 | JSON round-trip |
| 事件 topic 唯一性 | 无重复 topic |
| breaking change 检测 | 接口方法签名变更 → 测试失败 |
| 版本兼容 | 新版本 DTO 可反序列化旧版本数据 |

---

## 7. 发布 DoD

- [ ] 所有端口接口有 godoc 注释
- [ ] 所有 DTO 有 JSON tag
- [ ] CHANGELOG.md 已更新（含 breaking changes）
- [ ] breaking change 测试通过
- [ ] 新增契约有消费方/生产方/稳定期说明
- [ ] 测试覆盖率 ≥ 80%
