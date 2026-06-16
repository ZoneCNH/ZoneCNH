# factor-engine 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 分析域 · 因子计算引擎
- Module-Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/market-data`, `module/domain-market`, `module/feature-store`

> 本文件发布 factor-engine 文档基线。运行时实现为 Pending，等待 upstream market-data 和 domain-market 契约稳定。

---

## 1. 摘要

`factor-engine` 是分析域的因子计算引擎。它消费 `market-data` 输出的 canonical `MarketEventEnvelope`，基于注册的因子定义执行因子计算，并将 `FactorOutput` 写入 `feature-store`。它是连接数据域与分析域的核心计算层。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Factor 接口定义、FactorRegistry 注册/发现、因子计算编排管线、FactorOutput DTO、因子计算可观测性 |
| Depends on | `module/market-data`（MarketEventEnvelope 输入）、`module/domain-market`（canonical ProductLine/InstrumentKey 类型）、`module/feature-store`（输出写入） |
| Consumed by | `module/factor-eval`（因子评估）、`module/signal-factory`（信号生成） |
| Excludes | 特征存储实现（→ feature-store）、因子评估/回测（→ factor-eval / backtestx）、数据采集（→ market-data）、信号生成（→ signal-factory） |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| Factor | 一个可注册的因子计算单元，接收 MarketEventEnvelope 和历史数据，输出标量或向量值 |
| FactorRegistry | 因子注册与发现机制，按名称/标签索引已注册因子 |
| FactorOutput | 因子计算结果，包含因子名、值、时间戳、标的标识和计算元数据 |
| ComputePipeline | 因子计算编排管线：输入校验 → 因子选择 → 并行计算 → 结果聚合 → 输出写入 |
| WarmupPeriod | 因子计算前需要的最小历史数据窗口（如 MA60 需要 60 根 Bar） |

## 4. 功能需求

### FR-001: Factor 接口

WHEN 定义因子
THEN 必须实现 `Factor` 接口：`Name() string`、`InputTypes() []EventType`、`Warmup() int`、`Compute(ctx, []MarketEventEnvelope) (float64, error)`
AND `Name()` 返回全局唯一因子名
AND `InputTypes()` 声明需要的 MarketEventEnvelope 事件类型（trade/kline/bookTicker/depth）
AND `Warmup()` 返回最小预热数据条数
AND `Compute()` 接收历史窗口、返回标量因子值

### FR-002: FactorRegistry

WHEN 注册因子
THEN 通过 `Register(factor Factor)` 将因子加入全局注册表
AND 按 `Name()` 去重，重复注册返回错误
AND 支持 `ListByTags(tags []string) []Factor` 按标签查询

WHEN 查找因子
THEN `Get(name string) (Factor, bool)` 返回因子实例和存在标志

### FR-003: ComputePipeline

WHEN 启动因子计算管线
THEN 按顺序执行：输入校验 → 因子选择（按配置的因子列表）→ 并行计算 → 结果聚合 → 输出写入 feature-store
AND 并行度由配置控制（默认 `GOMAXPROCS`）
AND 单因子计算超时由 context deadline 控制

### FR-004: Input Validation

WHEN 接收 MarketEventEnvelope
THEN 校验 EventTime/ReceivedAt/Symbol/Venue 必填字段非空
AND InstrumentKey 必须通过 `ProductLine.IsValid()` 校验
AND EventTime 不得为零值或超过 future tolerance
AND 质量标签 `IsReliable=false` 时拒绝计算，记录 metric

### FR-005: FactorOutput

WHEN 因子计算完成
THEN 输出 `FactorOutput{FactorName, Value, Timestamp, InstrumentKey, ProductLine, EventType, ComputeMetadata}`
AND `Timestamp` 为计算执行时间（非事件时间）
AND `ComputeMetadata` 包含 warmup_status、input_count、compute_latency_us

### FR-006: Warmup 管理

WHEN 因子声明 `Warmup() > 0`
THEN 管线在积累足够历史数据前不输出该因子的计算结果
AND warmup 状态通过 `FactorOutput.ComputeMetadata.WarmupComplete` 标记

### FR-007: 可观测性

WHEN 任一因子计算完成
THEN 必须可按 factor_name/product_line/instrument/outcome 维度统计
AND metrics 包含：compute_latency、compute_count、validation_reject_count、warmup_pending_count

### FR-008: Module Identity

WHEN 下游模块引用 factor-engine
THEN Go module path 必须为 `github.com/ZoneCNH/factor-engine`
AND README H1 必须为 `# factor-engine`

## 5. 行为约束

| ID | 规则 | 违反后果 |
| --- | --- | --- |
| BR-001 | 因子 `Name()` 必须全局唯一 | `Register()` 返回 `ErrDuplicateFactor` |
| BR-002 | 输入数据 `IsReliable=false` 时不得计算 | 拒绝并记录 `factor_engine.validation_reject` metric |
| BR-003 | 因子计算不得修改输入 MarketEventEnvelope | 不可变约束，违反复核失败 |
| BR-004 | 因子输出必须写入 feature-store（不得直接暴露给策略层） | 数据流边界违反 |
| BR-005 | 因子计算不得依赖未来数据（no lookahead） | 回测验证失败 |

## 6. 非功能需求

| ID | 需求 | 目标值 | 验证方式 |
| --- | --- | --- | --- |
| NFR-001 | 单因子计算延迟 | < 100μs | Benchmark |
| NFR-002 | 100 因子并发计算延迟 | < 1ms | Benchmark |
| NFR-003 | 测试覆盖率 | >= 80% | `go tool cover -func` |
| NFR-004 | 无硬编码密钥 | 全仓扫描零命中 | gitleaks |

## 7. 接口契约

```go
// Factor 因子计算单元
type Factor interface {
    Name() string
    InputTypes() []EventType
    Warmup() int
    Compute(ctx context.Context, history []MarketEventEnvelope) (float64, error)
}

// FactorRegistry 因子注册表
type FactorRegistry interface {
    Register(factor Factor) error
    Get(name string) (Factor, bool)
    ListByTags(tags []string) []Factor
    Names() []string
}

// FactorOutput 因子计算结果
type FactorOutput struct {
    FactorName      string
    Value           float64
    Timestamp       time.Time
    InstrumentKey   InstrumentKey
    ProductLine     ProductLine
    EventType       EventType
    ComputeMetadata ComputeMetadata
}

type ComputeMetadata struct {
    WarmupComplete bool
    InputCount     int
    ComputeLatency time.Duration
    Error          string // empty on success
}
```

## 8. 数据模型

| 模型 | 字段 |
| --- | --- |
| FactorConfig | name, tags[], input_types[], warmup, enabled |
| FactorOutput | factor_name, value, timestamp, instrument_key, product_line, event_type, compute_metadata |
| ComputeMetadata | warmup_complete, input_count, compute_latency_us, error |
| PipelineStatus | state(RUNNING/STOPPED), active_factors, total_computed, error_rate |

## 9. 配置模式

```yaml
factor_engine:
  parallelism: 0  # 0 = GOMAXPROCS
  compute_timeout: 100ms
  future_tolerance: 5s
  feature_store:
    batch_size: 100
    flush_interval: 1s
  metrics:
    export_interval: 15s
```

## 10. 错误处理

| 错误 | 处理方式 |
| --- | --- |
| ErrDuplicateFactor | `Register()` 返回错误，不覆盖已有因子 |
| ErrInvalidInput | 跳过该条数据，emit `validation_reject` metric |
| ErrComputeTimeout | context 取消，该因子本轮计算标记为失败 |
| ErrFeatureStoreWrite | 重试 3 次指数退避 → 告警 |
| ErrWarmupNotComplete | 不输出该因子结果，pipeline 继续运行 |

## 11. 边界情况

| 场景 | 预期行为 |
| --- | --- |
| 因子列表为空 | Pipeline 正常启动，无计算执行 |
| 1000 因子并发 | 由 parallelism 控制并发度，不超过配置值 |
| MarketEventEnvelope 为 nil | 校验拒绝，记录 metric |
| feature-store 不可用 | 指数退避重试，不丢数据（缓存或阻塞） |
| 同一 symbol 多产品线 | 分别独立计算，不混合 |

## 12. 目录结构

```text
factor-engine/
├── factor.go        # Factor 接口
├── registry.go      # FactorRegistry 实现
├── pipeline.go      # ComputePipeline
├── output.go        # FactorOutput DTO
├── config.go        # 配置加载
├── errors.go        # 错误定义
├── internal/
│   ├── factors/     # 内置因子实现
│   └── metrics.go   # 可观测性
└── factor_test.go
```

## 13. 依赖

| 允许依赖 | 禁止依赖 |
| --- | --- |
| kernel, configx, observex, contracts | 交易所 SDK |
| domain-market（canonical 类型） | 策略/回测引擎 |
| feature-store（写入接口） | 数据库实现 |
| market-data（MarketEventEnvelope） | vendor DTO |

## 14. 测试

| 测试场景 | 验证点 |
| --- | --- |
| Factor Register/Duplicate | 注册成功，重复注册返回 ErrDuplicateFactor |
| Factor Compute | 正确计算因子值 |
| Input Validation | IsReliable=false 时拒绝 |
| Warmup | warmup 完成前不输出 |
| Concurrent Compute | 100 因子并发，无 race |
| FeatureStore Write Error | 重试 + 告警 |

## 15. 性能预算

| 操作 | 目标 |
| --- | --- |
| 单因子 Compute | < 100μs |
| 100 因子并发 Compute | < 1ms |
| Factor Register | < 1μs |
| Pipeline 启动 | < 100ms |

## 16. 可观测性

| 信号 | 指标 |
| --- | --- |
| Metric | factor_engine.compute_latency_us |
| Metric | factor_engine.compute_total |
| Metric | factor_engine.validation_reject_total |
| Metric | factor_engine.warmup_pending |
| Metric | factor_engine.feature_store_write_errors |
| Trace | factor_name, instrument_key, pipeline_run_id |

## 17. 安全

| 要求 | 实现方式 |
| --- | --- |
| 无密钥泄露 | 不读取环境变量、不连接远程服务 |
| 不可变输入 | Factor.Compute 不得修改 MarketEventEnvelope |
| Fail-closed | 输入非法时拒绝计算 |

## 18. CI 门禁

| Gate | 命令 | 阻塞条件 |
| --- | --- | --- |
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 测试失败 |
| 覆盖率 | `go test -coverprofile=...` | < 80% |
| vet | `go vet ./...` | vet 错误 |
| lint | `golangci-lint run` | lint 错误 |
| secret | `gitleaks detect --no-git` | 泄露 secret |

## 19. 升级兼容性

| 变更类型 | 版本升级 |
| --- | --- |
| Factor 接口新增方法 | minor |
| Factor 接口删除/修改方法 | major |
| FactorOutput 新增可选字段 | minor |
| FactorOutput 删除/重命名字段 | major |
| 新增内置因子 | minor |

## 20. 发布 DoD

- [ ] Factor 接口完整实现且通过单元测试
- [ ] FactorRegistry Register/Get/ListByTags 全部验证
- [ ] ComputePipeline 输入校验 → 并行计算 → 输出写入全链路测试
- [ ] Warmup 管理正确
- [ ] 覆盖率 ≥ 80%
- [ ] CHANGELOG.md 已更新

## 21. 待解决问题

- 是否支持有状态因子（如 EMA 需要前一时刻值）？
- 因子计算是否支持 GPU 加速？
- 是否支持跨 instrument 的截面因子（如行业中性化）？

## 22. 消费者

| 消费者 | 使用方式 |
| --- | --- |
| factor-eval | 消费 FactorOutput 进行 IC/分层回测评估 |
| signal-factory | 消费 FactorOutput 生成交易信号 |
| feature-store | 接收 FactorOutput 写入，管理版本和血缘 |

## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始文档基线：Factor 接口、FactorRegistry、ComputePipeline、FactorOutput | ZoneCNH |
