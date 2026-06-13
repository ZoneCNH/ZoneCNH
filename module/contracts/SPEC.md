# contracts 完整规格

> 基座 · 契约层。跨域稳定端口（MarketDataProvider, MacroDataProvider）、事件协议、DTO 契约、Topic 常量定义。

最后更新：2026-06-14

---

## 1. Metadata

- Status: Approved
- Spec-Version: v1.0.1
- Last-Updated: 2026-06-14
- Owner: ZoneCNH
- Layer: L1 基础能力
- Version: v1.0.1-spec
- Repository: [github.com/ZoneCNH/contracts](https://github.com/ZoneCNH/contracts)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期       | 版本   | 变更内容   | 作者    |
| ---------- | ------ | ---------- | ------- |
| 2026-06-07 | v1.0.0 | 初始版本   | ZoneCNH |
| 2026-06-14 | v1.0.1 | TRACEABILITY §1-§7 完整重建（6 FR + 10 BR + 8 NFR + 7 TC + 15 AC），对齐文档同步，版本升至 v1.0.1-spec | ZoneCNH |

## 2. Summary

`contracts` 定义跨域稳定契约——端口（接口）、事件协议和 DTO。它是域间通信的唯一合法通道，确保数据域、分析域、决策域和执行域之间的接口稳定、可演进。

---

## 3. Problem

量化交易系统由多个领域组成（数据域、分析域、决策域、执行域），域间通信如果没有统一契约，会导致：

- 域间直接依赖具体实现，耦合度过高
- 接口定义散落在各域内部，变更时无法感知影响范围
- 事件协议不统一，消息格式混乱
- DTO 定义重复，同一数据在不同域中有不同表示
- 接口变更无版本管理，breaking change 无法检测

---

## 4. Goals

- 定义跨域稳定端口：`MarketDataProvider`、`MacroDataProvider` 等核心接口
- 定义事件协议：统一的 Event 接口和 Topic 常量
- 定义跨域 DTO：请求/响应/传输对象的标准格式
- 提供契约版本管理机制
- 提供 breaking change 检测能力
- 端口接口保持窄（3-5 个方法），降低实现方负担
- 事件 DTO 不可变（只读字段），保证消息安全性

---

## 5. Non-goals

- 不包含域内接口（留在各域内部）
- 不包含临时适配器
- 不包含通用工具函数（→ `x` 工具包）
- 不包含领域模型全集（领域值对象在 L2.5 领域共享层）
- 不承载业务逻辑实现
- 不做消息队列实现（→ `kafkax`）
- 不做存储实现（→ `redisx`、存储扩展）

---

## 6. Consumers

| 消费者             | 使用方式                                     |
| ------------------ | -------------------------------------------- |
| `market-data`      | 实现 `MarketDataProvider` 接口，发布行情事件 |
| `macro-data`       | 实现 `MacroDataProvider` 接口，发布宏观事件  |
| `factor-engine`    | 消费 `MarketDataProvider` 获取行情数据       |
| `signal-engine`    | 消费因子数据，发布信号事件                   |
| `risk-engine`      | 消费信号和仓位数据，发布风险事件             |
| `order-engine`     | 消费信号事件，发布订单事件                   |
| `execution-engine` | 消费订单事件，发布执行事件                   |
| `x.go`             | 组装端口实现，注入到各域                     |

---

## 7. Functional Requirements

### FR-001: MarketDataProvider

WHEN 调用 `Subscribe(ctx, symbols)` 且 symbols 非空
THEN 返回一个 channel，持续推送 `MarketEvent`，直到 ctx 取消

WHEN 调用 `Subscribe(ctx, symbols)` 且 symbols 为空
THEN 返回错误，不订阅

WHEN 调用 `GetSnapshot(ctx, symbol)` 且 symbol 存在
THEN 返回该 symbol 的最新 `MarketSnapshot`

WHEN 调用 `GetSnapshot(ctx, symbol)` 且 symbol 不存在
THEN 返回错误

WHEN 调用 `GetHistory(ctx, req)` 且时间范围有效
THEN 返回指定时间范围内的 `[]Bar`

WHEN 调用 `GetHistory(ctx, req)` 且时间范围无效（start > end）
THEN 返回错误

### FR-002: MacroDataProvider

WHEN 调用 `GetLatest(ctx, indicator)` 且 indicator 存在
THEN 返回该指标的最新 `MacroPoint`

WHEN 调用 `GetLatest(ctx, indicator)` 且 indicator 不存在
THEN 返回错误

WHEN 调用 `GetHistory(ctx, req)` 且时间范围有效
THEN 返回指定时间范围内的 `[]MacroPoint`

WHEN 调用 `Subscribe(ctx, indicators)` 且 indicators 非空
THEN 返回一个 channel，持续推送 `MacroEvent`，直到 ctx 取消

### FR-003: Event 接口

WHEN 创建任何 Event 实现
THEN 必须实现 `EventID()`、`EventType()`、`Timestamp()`、`Source()` 四个方法
AND `EventID()` 返回全局唯一标识
AND `Timestamp()` 返回事件产生时间
AND `Source()` 返回事件来源标识

WHEN Event 的字段被创建后
THEN 不可修改（只读语义）

### FR-004: Topic 常量

WHEN 定义事件 Topic
THEN 使用 `contracts` 中定义的常量（如 `TopicMarketData`、`TopicSignal`）
AND Topic 名称全局唯一
AND Topic 名称使用点分命名（如 `market.data`、`signal.generated`）

WHEN 新增 Topic
THEN 必须在 `contracts` 中定义常量，不能在域内硬编码字符串

### FR-005: DTO 契约

WHEN 定义跨域 DTO
THEN 必须在 `contracts` 中定义
AND DTO 字段有 JSON tag
AND DTO 不可变（只读字段或 Builder 模式）

WHEN DTO 需要版本演进
THEN 新增字段使用 optional 语义（指针或默认值）
AND 不能删除或重命名已有字段

### FR-006: Breaking Change 检测

WHEN 端口接口的方法签名变更（增删方法、修改参数/返回值）
THEN breaking change 测试应失败
AND 需要版本升级

WHEN DTO 字段删除或类型变更
THEN breaking change 测试应失败
AND 需要版本升级

WHEN 新增可选字段（有默认值）
THEN breaking change 测试应通过
AND 版本为 minor 升级

---

## 8. Business Rules

| 编号   | 规则                                                           |
| ------ | -------------------------------------------------------------- |
| BR-001 | 所有跨域 DTO 必须在 `contracts` 中定义                         |
| BR-002 | 新增契约必须说明消费方、生产方和稳定期                         |
| BR-003 | 契约变更是 breaking change → 需要版本升级                      |
| BR-004 | 端口接口保持窄（3-5 个方法）                                   |
| BR-005 | 事件 DTO 不可变（只读字段）                                    |
| BR-006 | Topic 常量全局唯一，使用点分命名                               |
| BR-007 | 接口实现方必须有编译期检查（`var _ Interface = (*Impl)(nil)`） |
| BR-008 | `contracts` 只依赖 L2.5 领域共享层和 stdlib                    |
| BR-009 | DTO 的 JSON tag 必须使用 snake_case                            |
| BR-010 | 契约版本遵循 semver（breaking change → major）                 |

---

## 9. Interface Contract

### 9.1 数据输入端口

```go
// MarketDataProvider 行情数据端口
type MarketDataProvider interface {
    Subscribe(ctx context.Context, symbols []string) (<-chan MarketEvent, error)
    GetSnapshot(ctx context.Context, symbol string) (*MarketSnapshot, error)
    GetHistory(ctx context.Context, req HistoryRequest) ([]Bar, error)
}

// MacroDataProvider 宏观数据端口
type MacroDataProvider interface {
    GetLatest(ctx context.Context, indicator string) (*MacroPoint, error)
    GetHistory(ctx context.Context, req MacroHistoryRequest) ([]MacroPoint, error)
    Subscribe(ctx context.Context, indicators []string) (<-chan MacroEvent, error)
}
```text

### 9.2 事件协议

```go
// Event 事件基础接口
type Event interface {
    EventID() string
    EventType() string
    Timestamp() time.Time
    Source() string
}

// Topic 常量
const (
    TopicMarketData  = "market.data"
    TopicMacroData   = "macro.data"
    TopicSignal      = "signal.generated"
    TopicOrder       = "order.submitted"
    TopicExecution   = "execution.filled"
    TopicPosition    = "position.updated"
    TopicRisk        = "risk.alert"
    TopicAlternative = "alternative.data"
)
```text

### 9.3 核心 DTO

```go
// MarketEvent 行情事件
type MarketEvent struct {
    EventID   string          `json:"event_id"`
    Symbol    string          `json:"symbol"`
    Price     decimal.Decimal `json:"price"`
    Volume    decimal.Decimal `json:"volume"`
    Timestamp time.Time       `json:"timestamp"`
    Source    string          `json:"source"`
}

// MarketSnapshot 行情快照
type MarketSnapshot struct {
    Symbol    string          `json:"symbol"`
    Bid       decimal.Decimal `json:"bid"`
    Ask       decimal.Decimal `json:"ask"`
    Last      decimal.Decimal `json:"last"`
    Volume    decimal.Decimal `json:"volume"`
    Timestamp time.Time       `json:"timestamp"`
}

// Bar K线数据
type Bar struct {
    Symbol    string          `json:"symbol"`
    Open      decimal.Decimal `json:"open"`
    High      decimal.Decimal `json:"high"`
    Low       decimal.Decimal `json:"low"`
    Close     decimal.Decimal `json:"close"`
    Volume    decimal.Decimal `json:"volume"`
    Timestamp time.Time       `json:"timestamp"`
    Interval  string          `json:"interval"`
}

// HistoryRequest 历史数据请求
type HistoryRequest struct {
    Symbol   string    `json:"symbol"`
    Start    time.Time `json:"start"`
    End      time.Time `json:"end"`
    Interval string    `json:"interval"`
    Limit    int       `json:"limit,omitempty"`
}

// MacroPoint 宏观数据点
type MacroPoint struct {
    Indicator string          `json:"indicator"`
    Value     decimal.Decimal `json:"value"`
    Timestamp time.Time       `json:"timestamp"`
    Source    string          `json:"source"`
}

// MacroEvent 宏观事件
type MacroEvent struct {
    EventID   string      `json:"event_id"`
    Indicator string      `json:"indicator"`
    Point     MacroPoint  `json:"point"`
    Timestamp time.Time   `json:"timestamp"`
    Source    string      `json:"source"`
}

// MacroHistoryRequest 宏观历史请求
type MacroHistoryRequest struct {
    Indicator string    `json:"indicator"`
    Start     time.Time `json:"start"`
    End       time.Time `json:"end"`
    Limit     int       `json:"limit,omitempty"`
}
```text

---

## 10. Data Model

### 10.1 公共错误

```go
var (
    ErrInvalidSymbol     = errors.New("contracts: invalid symbol")
    ErrInvalidIndicator  = errors.New("contracts: invalid indicator")
    ErrInvalidTimeRange  = errors.New("contracts: invalid time range")
    ErrEmptySymbols      = errors.New("contracts: empty symbols list")
    ErrEmptyIndicators   = errors.New("contracts: empty indicators list")
    ErrSymbolNotFound    = errors.New("contracts: symbol not found")
    ErrIndicatorNotFound = errors.New("contracts: indicator not found")
)
```text

### 10.2 版本管理

```go
const (
    ContractVersion = "1.0.0"
)

// VersionInfo 契约版本信息
type VersionInfo struct {
    Version    string    `json:"version"`
    ReleasedAt time.Time `json:"released_at"`
    Changes    []Change  `json:"changes"`
}

type Change struct {
    Type        string `json:"type"`        // breaking, feature, fix
    Description string `json:"description"`
    Affected    string `json:"affected"`    // 受影响的接口/DTO
}
```text

### 10.3 事件 Topic 映射

```go
var TopicEventTypes = map[string]reflect.Type{
    TopicMarketData:  reflect.TypeOf(MarketEvent{}),
    TopicMacroData:   reflect.TypeOf(MacroEvent{}),
    TopicSignal:      reflect.TypeOf(SignalEvent{}),
    TopicOrder:       reflect.TypeOf(OrderEvent{}),
    TopicExecution:   reflect.TypeOf(ExecutionEvent{}),
    TopicPosition:    reflect.TypeOf(PositionEvent{}),
    TopicRisk:        reflect.TypeOf(RiskEvent{}),
    TopicAlternative: reflect.TypeOf(AlternativeEvent{}),
}
```text

---

## 11. Config Schema

`contracts` 自身不加载配置。它的 Go 类型定义是其他模块的编译时依赖。

事件序列化配置（供 `kafkax` 等使用）：

```yaml
events:
  serialization: json          # json / protobuf / avro
  compression: gzip            # none / gzip / snappy / lz4
  max_message_size: 1MB        # 单条消息最大大小
```text

---

## 12. Error Handling

| 错误                   | 调用方处理                             |
| ---------------------- | -------------------------------------- |
| `ErrInvalidSymbol`     | 检查 symbol 格式和是否在支持列表中     |
| `ErrInvalidIndicator`  | 检查 indicator 名称和是否在支持列表中  |
| `ErrInvalidTimeRange`  | 检查 start/end 时间，确保 start < end  |
| `ErrEmptySymbols`      | 传入至少一个 symbol                    |
| `ErrEmptyIndicators`   | 传入至少一个 indicator                 |
| `ErrSymbolNotFound`    | 确认 symbol 已订阅或在交易所支持列表中 |
| `ErrIndicatorNotFound` | 确认 indicator 名称正确                |

**错误消息格式：** `"contracts: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景                             | 预期行为                                     |
| -------------------------------- | -------------------------------------------- |
| Subscribe 传入重复 symbol        | 去重后订阅，不报错                           |
| Subscribe 传入无效 symbol        | 返回 `ErrInvalidSymbol`，不订阅任何 symbol   |
| GetHistory 时间范围过大（>1年）  | 正常返回，由实现方决定是否分页               |
| GetHistory 返回空结果            | 返回空 slice，不报错                         |
| Event channel 已满               | 实现方决定：阻塞或丢弃最旧消息               |
| Event channel 关闭后读取         | 返回零值，channel 关闭信号                   |
| DTO 字段为零值                   | 序列化为零值（如 `""`, `0`），不省略         |
| DTO 字段为 nil（指针类型）       | 序列化为 `null`                              |
| 并发 Subscribe + Unsubscribe     | 实现方需保证并发安全                         |
| breaking change 检测的 mock 实现 | 编译期检查 `var _ = Interface((*mock)(nil))` |

---

## 14. Directory Structure

```text
contracts/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go                      # 包级文档
├── contracts.go                # 版本常量
├── market.go                   # 行情端口和 DTO（MarketDataProvider, MarketEvent, MarketSnapshot, Bar）
├── macro.go                    # 宏观端口和 DTO（MacroDataProvider, MacroPoint, MacroEvent）
├── signal.go                   # 信号 DTO（SignalEvent）
├── order.go                    # 订单 DTO（OrderEvent）
├── execution.go                # 执行 DTO（ExecutionEvent）
├── position.go                 # 仓位 DTO（PositionEvent）
├── risk.go                     # 风险 DTO（RiskEvent）
├── alternative.go              # 另类数据 DTO（AlternativeEvent）
├── events.go                   # 事件基础接口和 Topic 常量
├── ports.go                    # Provider / Consumer 端口汇总
├── errors.go                   # 公共错误变量
├── version.go                  # 版本管理和 breaking change 检测
├── internal/
│   └── validate/               # DTO 校验工具
├── testdata/
│   └── *.golden
├── example_test.go
├── benchmark_test.go
└── breaking_test.go            # breaking change 检测测试
```text

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/contracts

go 1.23
```text

### 15.2 依赖方向

| 可以依赖                                                                          | 禁止依赖                                                 |
| --------------------------------------------------------------------------------- | -------------------------------------------------------- |
| stdlib                                                                            | 所有业务域实现（market-data, signal-engine 等）          |
| L2.5 领域共享层（`decimalx`, `domain-market`, `domain-exchange`, `domain-macro`） | Foundation L1 运行时模块（kernel, configx, observex 等） |
|                                                                                   | 所有存储/中间件扩展（redisx, kafkax 等）                 |

### 15.3 特殊说明

`contracts` 处于依赖拓扑的上层，只被业务域模块 import，不 import 任何 L1 运行时模块。它通过 L2.5 领域共享层获取 `decimal.Decimal` 等领域值对象。

---

## 16. Testing

### 16.1 单元测试

| 测试场景            | 验证点                                                 |
| ------------------- | ------------------------------------------------------ |
| 端口编译期检查      | `var _ MarketDataProvider = (*mockImpl)(nil)` 编译通过 |
| DTO 序列化/反序列化 | JSON round-trip，字段值不变                            |
| 事件 topic 唯一性   | 无重复 topic 常量                                      |
| 事件接口完整性      | 所有 Event 实现满足 Event 接口                         |
| DTO 不可变性        | 创建后字段不可修改                                     |
| 错误格式            | 所有错误符合 `"contracts: <desc>"` 格式                |
| JSON tag            | 所有 DTO 字段有 snake_case JSON tag                    |

### 16.2 Given/When/Then 用例

**TC-001: MarketDataProvider 编译期检查**
Given 定义 mock 实现 `type mockMarket struct{}`
When 编译 `var _ MarketDataProvider = (*mockMarket)(nil)`
Then 编译通过（接口方法已实现）

**TC-002: DTO JSON round-trip**
Given 创建 `MarketEvent{Symbol: "BTCUSDT", Price: 50000}`
When JSON 序列化后反序列化
Then 字段值与原始对象一致

**TC-003: Breaking change 检测**
Given `MarketDataProvider` 接口有 3 个方法
When 删除 `GetHistory` 方法
Then `breaking_test.go` 中的编译期检查失败

**TC-004: Topic 唯一性**
Given 定义了 8 个 Topic 常量
When 检查是否有重复值
Then 无重复

**TC-005: Event 接口完整性**
Given 事件类型实现 Event
When 编译 contract test
Then Topic、Key、OccurredAt 和 Payload 方法均满足接口

**TC-006: 端口接口方法数**
Given 端口接口定义完成
When 运行接口规范检查
Then 每个端口接口包含 3-5 个业务方法

**TC-007: DTO 不可变性**
Given DTO 已创建
When 调用公开方法
Then 不暴露可变内部切片或 map

### 16.3 Benchmark

| 场景              | 目标    |
| ----------------- | ------- |
| DTO JSON 序列化   | < 1μs   |
| DTO JSON 反序列化 | < 1μs   |
| Event 接口调用    | < 100ns |

### 16.4 集成测试

| 场景         | 验证点                                           |
| ------------ | ------------------------------------------------ |
| 跨域数据流   | market-data → contracts DTO → factor-engine      |
| 事件发布消费 | 生产方发布 MarketEvent → 消费方通过 channel 接收 |
| 版本兼容     | 新版本 DTO 可反序列化旧版本数据                  |

---

## 17. Performance Budget

| 操作                 | 目标    | 测量方式                          |
| -------------------- | ------- | --------------------------------- |
| DTO JSON 序列化      | < 1μs   | benchmark test                    |
| DTO JSON 反序列化    | < 1μs   | benchmark test                    |
| Event 接口调用       | < 100ns | benchmark test                    |
| 编译期检查           | < 1s    | `go build`                        |
| breaking change 检测 | < 5s    | `go test -run TestBreakingChange` |

---

## 18. Observability

| 类型   | 名称                          | 说明                                   |
| ------ | ----------------------------- | -------------------------------------- |
| log    | `contracts.subscribe.started` | info，订阅开始，含 symbols/indicators  |
| log    | `contracts.subscribe.error`   | error，订阅失败，含 error              |
| log    | `contracts.event.published`   | debug，事件发布，含 topic 和 event_id  |
| metric | `contracts.event.count`       | counter，事件发布数量（按 topic 分组） |
| metric | `contracts.event.size`        | histogram，事件消息大小                |
| metric | `contracts.subscribe.active`  | gauge，活跃订阅数                      |

---

## 19. Security

| 要求               | 实现方式                                  |
| ------------------ | ----------------------------------------- |
| DTO 不包含敏感数据 | DTO 只包含交易数据，不含密钥、密码        |
| 事件不泄露内部实现 | Event.Source() 使用标识符，不包含内部路径 |
| 序列化安全         | JSON 序列化不执行任意代码                 |

---

## 20. CI Gate

### 20.1 通用 Gate

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

### 20.2 contracts 专属 Gate

| Gate            | 命令                                     | 阻塞条件                            |
| --------------- | ---------------------------------------- | ----------------------------------- |
| breaking change | `go test -run TestBreakingChange ./...`  | 接口/DTO 有破坏性变更但未 bump 版本 |
| 编译期检查      | `go test -run TestCompileCheck ./...`    | 端口接口编译期检查失败              |
| topic 唯一性    | `go test -run TestTopicUniqueness ./...` | Topic 常量有重复                    |
| 新增契约审查    | PR 必须说明消费方、生产方和稳定期        | 未说明                              |

---

## 21. Upgrade Compatibility

| 变更类型                     | 版本升级                  |
| ---------------------------- | ------------------------- |
| 端口接口新增方法             | **major**（实现方需跟进） |
| 端口接口删除/修改方法        | **major**                 |
| DTO 新增可选字段（有默认值） | **minor**                 |
| DTO 删除/修改字段            | **major**                 |
| 新增 Topic 常量              | **minor**                 |
| 删除/重命名 Topic 常量       | **major**                 |
| 新增端口接口                 | **minor**                 |
| 新增 DTO 类型                | **minor**                 |
| Event 接口变更               | **major**                 |

---

## 22. Release DoD

- [ ] 所有端口接口有 godoc 注释
- [ ] 所有 DTO 有 JSON tag（snake_case）
- [ ] 所有 Event 实现满足 Event 接口
- [ ] CHANGELOG.md 已更新（含 breaking changes）
- [ ] breaking change 测试通过
- [ ] 编译期检查测试通过
- [ ] topic 唯一性测试通过
- [ ] 新增契约有消费方/生产方/稳定期说明
- [ ] README.md 包含：模块定位、端口概览、DTO 参考、版本策略
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试

---

## 23. Open Questions

- 端口接口是否需要支持批量操作（如 `Subscribe` 一次订阅多个 topic 的子集）？
- 是否需要支持请求-响应模式的 RPC 端口（除了事件推送）？
- DTO 是否需要支持 protobuf 序列化（除了 JSON）？
- 是否需要定义跨域的命令接口（如 `OrderCommand`、`RiskCommand`）？
- 事件版本是否需要包含在 Event 接口中（如 `EventVersion()`）？
- 是否需要支持事件 schema registry（集中管理事件格式演进）？
