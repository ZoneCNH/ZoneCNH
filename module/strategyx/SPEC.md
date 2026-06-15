# strategyx 完整规格

> 决策域 · 策略工厂。策略定义 DSL、策略注册表、参数优化、策略版本管理、信号生成规则。

最后更新：2026-06-14

---

## 1. Metadata

- Status: Review
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-14
- Owner: ZoneCNH
- Layer: 决策域 · 策略工厂
- Version: v0.1.0-draft
- Repository: [github.com/ZoneCNH/strategyx](https://github.com/ZoneCNH/strategyx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期       | 版本         | 变更内容 | 作者    |
| ---------- | ------------ | -------- | ------- |
| 2026-06-14 | v0.1.0-draft | 初始版本 | ZoneCNH |
| 2026-06-14 | v0.1.0-draft | FR-008 Module Identity (README H1 + go.mod 校验) | ZoneCNH |

## 2. Summary

`strategyx` 是决策域的策略工厂，负责策略定义、注册、版本管理、参数优化和信号生成规则。它将因子输入转化为交易信号，是分析域（因子）到执行域（订单）之间的决策桥梁。

---

## 3. Problem

量化策略开发中的痛点：

- 策略定义散落在各脚本中，无统一接口和注册机制
- 策略参数硬编码，无法在运行时调整
- 策略版本无管理，回滚困难
- 信号生成规则不透明，难以审计和调试
- 多策略并行时缺乏协调机制（信号冲突、资金分配）

---

## 4. Goals

- 统一策略接口：所有策略实现相同的 Strategy 接口
- 策略注册表：按名称发现和加载策略
- 参数管理：可配置参数 + 运行时热更新
- 版本管理：策略变更可追溯、可回滚
- 信号输出：标准化信号格式（symbol, side, qty, confidence, reason）
- 策略组合：多策略信号合并、冲突解决、资金分配

---

## 5. Non-goals

- 不做因子计算（→ factor-engine）
- 不做回测执行（→ backtestx）
- 不做风控（→ riskx）
- 不做订单管理（→ orderx）
- 不实现具体策略逻辑（由策略开发者实现）

---

## 6. Consumers

| 消费者       | 使用方式                              |
| ------------ | ------------------------------------- |
| maestro      | 编排 workflow 中加载和运行策略        |
| backtestx    | 加载策略进行回测                     |
| signal-factory | 消费策略生成的信号                  |
| optimizer    | 读取策略参数进行优化                 |

---

## 7. Functional Requirements

### FR-001: Strategy Interface

WHEN 定义策略
THEN 必须实现 Strategy 接口：
  AND Name() string — 策略唯一标识
  AND Version() string — 策略版本
  AND Init(ctx, params) error — 初始化参数
  AND OnSignal(ctx, factors Factors, portfolio Portfolio) (*Signal, error) — 生成交易信号
AND Signal 必须包含：symbol, side(BUY/SELL/NEUTRAL), qty, confidence(0-1), reason

### FR-002: Strategy Registry

WHEN 注册策略
THEN 通过 strategy.Register(name, factory) 注册
AND 名称全局唯一（重复注册报错）
AND 支持运行时注册和卸载
WHEN 查询 registry.List()
THEN 返回所有已注册策略的 (name, version, status)

### FR-003: Parameter Management

WHEN 策略初始化
THEN 参数通过 configx 注入（不可变快照）
AND 支持参数描述：name, type, default, min, max, description
WHEN 参数热更新
THEN 新参数仅对新信号生效（已发出的信号不受影响）
AND 参数变更记录到 audit log

### FR-004: Strategy Versioning

WHEN 策略变更
THEN 遵循语义化版本：major（信号逻辑改变）、minor（参数新增）、patch（修复）
AND 每个版本保留独立的代码路径（旧版本不退市）
AND backtestx 可通过 version 参数回放特定版本的策略

### FR-005: Signal Output

WHEN 策略生成信号
THEN 信号格式必须包含：
  - signalID: 全局唯一
  - strategy: 策略名称 + 版本
  - timestamp: 信号生成时间
  - symbol: 交易标的
  - side: BUY / SELL / NEUTRAL
  - quantity: 建议数量（可为 0）
  - confidence: 0.0-1.0
  - reason: 人类可读的信号原因
AND confidence < threshold 的信号标记为 WEAK

### FR-006: Strategy Composition

WHEN 多个策略同时产生信号
THEN 信号合并策略：PRIORITY（按优先级）、WEIGHTED（按权重加权）、UNANIMOUS（全部同意才生效）
AND 资金分配策略：EQUAL（等分）、PROPORTIONAL（按置信度比例）、KELLY（凯利公式）
WHEN 信号冲突（同一 symbol 同时有 BUY 和 SELL）
THEN 按合并策略解决冲突并记录冲突日志

### FR-007: Strategy Warm-up

WHEN 策略需要历史数据预热（如均线策略需要前 N 根 K 线）
THEN 调用 strategy.WarmUp(ctx, data) → ready
AND WarmUp 完成后才进入 Ready 状态
AND WarmUp 超时时标记为 Degraded

---

### FR-008: Module Identity

WHEN downstream consumer reads `strategyx` `README.md`
THEN the H1 heading MUST be `# strategyx`
AND MUST NOT be `# xlib-standard`

WHEN module documentation references the `strategyx` Go module path
THEN it MUST use `github.com/ZoneCNH/strategyx`
AND MUST NOT use `github.com/ZoneCNH/xlib-standard`

WHEN `go.mod` declares the module name
THEN it MUST be `module github.com/ZoneCNH/strategyx`

### Acceptance Criteria

| AC 编号 | 对应 FR | 验收条件 |
| ------- | ------- | -------- |
| AC-STX-001 | FR-001 | Strategy 接口实现 Name/Version/Init/OnSignal 四个方法；Signal 包含 symbol, side, qty, confidence, reason；confidence 范围 0-1 |
| AC-STX-002 | FR-002 | strategy.Register 注册策略名称全局唯一，重复注册报错；registry.List 返回 (name, version, status)；支持运行时注册和卸载 |
| AC-STX-003 | FR-003 | 参数通过 configx 注入（不可变快照）；参数描述含 name/type/default/min/max/description；热更新仅对新信号生效；变更记录 audit log |
| AC-STX-004 | FR-004 | 策略版本遵循 semver（major=信号逻辑改变，minor=参数新增，patch=修复）；旧版本不退市；backtestx 可通过 version 参数回放指定版本 |
| AC-STX-005 | FR-005 | Signal 包含 signalID(全局唯一)/strategy/timestamp/symbol/side/qty/confidence/reason；confidence < threshold 标记 WEAK |
| AC-STX-006 | FR-006 | 信号合并策略 PRIORITY/WEIGHTED/UNANIMOUS 正确执行；资金分配 EQUAL/PROPORTIONAL/KELLY 正确计算；冲突信号按策略解决并记录日志 |
| AC-STX-007 | FR-007 | WarmUp 完成后进入 Ready 状态；WarmUp 超时标记为 Degraded |
| AC-STX-008 | FR-008 | README H1 为 `# strategyx`；Go module path 为 `github.com/ZoneCNH/strategyx`；go.mod 声明 `module github.com/ZoneCNH/strategyx` |

## 8. Business Rules

| 编号   | 规则                                     | 违反后果 |
| ------ | ---------------------------------------- | -------- |
| BR-001 | 策略名称全局唯一                         | 注册失败 |
| BR-002 | 信号 confidence 必须为 0.0-1.0          | 拒绝信号 |
| BR-003 | 策略未完成 WarmUp 前不得生成信号          | 跳过策略 |
| BR-004 | 资金分配比例之和必须为 1.0               | 拒绝分配 |
| BR-005 | Strategy 接口变更时需要 major 版本升级   | 旧版本不可用 |

---

## 9. Interface Contract

```go
type Strategy interface {
    Name() string
    Version() string
    Params() []ParamDef
    Init(ctx context.Context, params Params) error
    WarmUp(ctx context.Context, data DataFeed) error
    OnSignal(ctx context.Context, factors Factors, portfolio Portfolio) (*Signal, error)
}

type Registry interface {
    Register(name string, factory StrategyFactory) error
    Unregister(name string) error
    Get(name string, version string) (Strategy, error)
    List() []StrategyInfo
}

type Composer interface {
    Compose(ctx context.Context, signals []Signal, method ComposeMethod) (*CompositeSignal, error)
    Allocate(signals []Signal, capital decimal.Decimal, method AllocMethod) ([]Allocation, error)
}

type Signal struct {
    SignalID   string
    Strategy   string
    Version    string
    Timestamp  time.Time
    Symbol     string
    Side       Side
    Quantity   decimal.Decimal
    Confidence decimal.Decimal
    Reason     string
}
```

---

## 10. Data Model

| 模型            | 字段 |
| --------------- | ---- |
| StrategyInfo    | name, version, status(INIT/READY/DEGRADED/STOPPED), paramCount |
| ParamDef        | name, type, default, min, max, description |
| Signal          | signalID, strategy, version, timestamp, symbol, side, quantity, confidence, reason |
| CompositeSignal | signals[], method, mergedSide, mergedQty, mergedConfidence |
| Allocation      | strategy, symbol, side, qty, capitalAllocated |
| Factors         | map[string]FactorValue — 因子名 → 因子值 |

---

## 11. Config Schema

```yaml
strategyx:
  composer:
    default_method: weighted     # priority / weighted / unanimous
    default_alloc: proportional  # equal / proportional / kelly
  signal:
    min_confidence: 0.5
    max_signals_per_tick: 50
  warmup:
    default_timeout: 30s
```

---

## 12. Error Handling

| 错误                  | 处理方式                     |
| --------------------- | ---------------------------- |
| 策略 Init 失败         | 标记 DEGRADED，不生成信号    |
| WarmUp 超时            | 标记 DEGRADED，可降级运行    |
| OnSignal panic        | 捕获 + 恢复，跳过该策略      |
| 信号冲突无法解决       | 输出 NEUTRAL + 冲突日志      |

---

## 13. Edge Cases

| 场景                       | 预期行为                         |
| -------------------------- | -------------------------------- |
| 空策略注册表               | List() 返回空列表，不报错        |
| 单策略多版本同时注册       | 各自独立，通过 version 区分       |
| 信号 quantity 为 0        | NEUTRAL 信号（不交易）           |
| 所有策略返回 NEUTRAL       | Composer 输出复合 NEUTRAL         |

---

## 14. Directory Structure

```text
strategyx/
├── go.mod
├── go.sum
├── README.md
├── strategy.go        # Strategy 接口
├── registry.go        # Registry 实现
├── composer.go        # Composer 实现
├── signal.go          # Signal 类型定义
├── params.go          # 参数管理
├── version.go         # 版本管理
├── errors.go          # 错误定义
├── examples/
│   ├── macross.go     # 示例：均线交叉策略
│   └── grid.go        # 示例：网格策略
└── example_test.go
```

---

## 15. Dependencies

| 可以依赖                             | 禁止依赖                   |
| ------------------------------------ | -------------------------- |
| kernel, configx, observex, contracts | 风控决策（→ riskx）       |
| domainx (decimal)                    | 订单执行（→ orderx）      |
| stdlib                               | 交易所 SDK                |

---

## 16. Testing

| 测试场景            | 验证点                           |
| ------------------- | -------------------------------- |
| 策略注册/发现        | 注册成功，重名报错               |
| 信号生成             | 格式完整，confidence 在范围内    |
| 策略组合             | 冲突解决正确，分配比例和为 1     |
| WarmUp               | 超时 → DEGRADED                 |
| 参数热更新           | 旧信号不受影响                   |

---

## 17. Performance Budget

| 操作              | 目标     |
| ----------------- | -------- |
| OnSignal 调用     | < 10ms   |
| Compose (10 信号) | < 1ms    |
| Registry.List     | < 100μs  |

---

## 18. Observability

| 信号   | 指标                                  |
| ------ | ------------------------------------- |
| Metric | strategyx.signal.count (by strategy)  |
| Metric | strategyx.signal.confidence_avg       |
| Metric | strategyx.composer.conflict_count    |
| Metric | strategyx.strategy.status           |
| Log    | strategy init, warmup, signal, error |

---

## 19. Security

| 要求               | 实现方式                     |
| ------------------ | ---------------------------- |
| 策略代码隔离       | 每个策略独立 package         |
| 无外部网络访问     | 策略层不直接访问交易所 API   |

---

## 20. CI Gate

| Gate   | 命令                               | 阻塞条件       |
| ------ | ---------------------------------- | -------------- |
| 编译   | `go build ./...`                   | 编译失败       |
| 测试   | `go test ./... -race -count=1`     | 测试失败       |
| 覆盖率 | `go test -coverprofile=...`        | < 80%          |

---

## 21. Upgrade Compatibility

| 变更类型             | 版本升级 |
| -------------------- | -------- |
| 新增 Composer 方法   | minor    |
| Strategy 接口新增方法| major    |
| Signal 新增字段      | minor    |

---

## 22. Release DoD

- [ ] Strategy 接口完整定义
- [ ] Registry 注册/发现/卸载完整实现
- [ ] Composer 三种合并策略 + 三种分配策略
- [ ] 示例策略（均线交叉 + 网格）
- [ ] 覆盖率 ≥ 80%

---

## 23. Open Questions

- 是否需要支持策略热加载（plugin 模式）？
- 是否需要策略市场（策略模板库）？
- 信号是否应包含建议的止损/止盈价格？
