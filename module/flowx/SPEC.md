# flowx 规格

- Status: Spec Approved / Tasks Pending
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Layer: 分析域 · 工作流引擎
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `orderx`, `positionx`, `riskx`

> 公开投影 caveat：Status=Review 与矩阵覆盖证据不等同于 factory-grade；四源评分通过前机器事实层保持 factory=false。

---

## 1. 摘要

`flowx` 是分析域的数据流管线引擎，负责实时流式数据处理、因子计算编排、窗口聚合、数据路由和背压控制。它是连接数据域（market_data、macro_data）与分析域（factor_engine、feature_store）的数据管道层。

定位三角：

```text
contracts 定义"传什么数据"
flowx 定义"怎么处理数据流"
kafkax / natsx 是"用什么传"
```

---

## 2. 问题与背景

量化交易系统需要处理多个实时数据流（行情、宏观、另类数据），每条数据流需要经过不同的处理管线（清洗、聚合、因子计算、特征提取），当前缺少统一的流处理抽象：

- 数据管线定义散落在各模块，无法复用和组合
- 窗口聚合逻辑重复实现
- 背压策略不一致，导致高峰期数据丢失或 OOM
- 数据路由规则硬编码，新增数据源需改代码
- 管线状态不可观测，故障排查困难

---

## 3. 目标

- 定义 DAG 数据流管线（Source → Transform → Window → Sink）
- 定义窗口类型：Tumbling、Sliding、Session
- 定义数据路由规则（按 symbol、exchange、dataType 分流）
- 定义背压策略：Block、Drop、Spill
- 定义管线状态可观测（lag、throughput、error rate）
- 管线支持热更新（不丢数据的前提下切换拓扑）

---

## 4. 非目标

- 不替代 Kafka Streams / Flink 等通用流处理框架
- 不实现分布式流处理集群（单进程内管线）
- 不定义因子计算公式（→ factor_engine）
- 不存储历史数据（→ taosx / clickhousex）
- 不定义数据采集协议（→ market_data）

---

## 5. 消费者

| 消费者          | 使用方式                           |
| --------------- | ---------------------------------- |
| factor_engine   | 消费管线输出的因子数据             |
| feature_store   | 消费管线输出的特征数据             |
| market_regime   | 消费管线输出的市场环境分类数据     |
| signal_factory  | （已移除 — signal_factory 输入来自 factor_eval + regime_engine，不走 flowx 管道） |
| observex        | 消费管线 metrics 和 traces         |

---

## 6. 功能需求

### FR-001: Pipeline DAG

WHEN 创建 Pipeline
THEN 必须定义 Source、Transform（0-N）、Window（0-1）和 Sink（1-N）四类节点
AND 节点间通过有向边连接
AND 检测循环依赖并在创建时报错

### FR-002: Source

WHEN 配置 Source 节点
THEN 支持的数据源类型包括：Kafka Topic、NATS Subject、gRPC Stream、WebSocket feed、CSV replay
AND Source 必须声明输出的数据类型（如 `MarketEvent`、`MacroPoint`）

### FR-003: Transform

WHEN 配置 Transform 节点
THEN 支持的操作类型包括：Filter、Map、FlatMap、KeyBy、Join、Enrich
AND Transform 函数签名：`func(ctx context.Context, in T) (out U, err error)`
AND Filter 返回 false 时丢弃该条数据

### FR-004: Window

WHEN 配置 Window 节点
THEN 支持 Tumbling（固定大小、不重叠）、Sliding（固定大小+步长、可重叠）、Session（按 gap 超时切分）
AND Window 内聚合函数包括：Count、Sum、Avg、Min、Max、First、Last
AND Window 触发策略：事件时间 + watermark + 允许迟到（lateness）

### FR-005: Sink

WHEN 配置 Sink 节点
THEN 支持的 Sink 类型包括：Kafka Topic、NATS Subject、gRPC Push、InMemory Channel、CSV write
AND Sink 必须返回 DeliveryReceipt（at-least-once 保证）
AND 至少一个 Sink 必须标注为 primary

### FR-006: Data Routing

WHEN 数据经过 KeyBy 或路由节点
THEN 支持按 symbol、exchange、dataType、自定义 key function 分流
AND 路由规则变更不丢数据（drain old route → apply new route）

### FR-007: Backpressure

WHEN Sink 消费慢于 Source 生产
THEN 应用配置的背压策略：Block（阻塞上游）、Drop（丢弃最旧/最新）、Spill（溢写到磁盘）
AND 背压触发时 emit `flowx.backpressure` metric
AND Spill 模式下磁盘满时降级为 Drop

### FR-008: Pipeline Lifecycle

WHEN Pipeline 启动
THEN 按拓扑顺序依次启动节点（Source → Transform → Window → Sink）
AND 任意节点启动失败时回滚已启动节点
AND 支持 Pause/Resume/Stop 操作

### FR-009: Hot Reload

WHEN Pipeline 拓扑变更（增删节点、修改路由）
THEN 执行 Drain-Then-Apply：先停止旧拓扑上游 → 等待 in-flight 数据处理完 → 启动新拓扑
AND 热更新期间数据不丢不重（通过 offset checkpoint）

---

### FR-010: Module Identity

WHEN downstream consumer reads `flowx` `README.md`
THEN the H1 heading MUST be `# flowx`
AND MUST NOT be `# xlib_standard`

WHEN module documentation references the `flowx` Go module path
THEN it MUST use `github.com/ZoneCNH/flowx`
AND MUST NOT use `github.com/ZoneCNH/xlib-standard`

WHEN `go.mod` declares the module name
THEN it MUST be `module github.com/ZoneCNH/flowx`

### Acceptance Criteria

| AC 编号 | 对应 FR | 验收条件 |
| ------- | ------- | -------- |
| AC-FLX-001 | FR-001 | Pipeline DAG 定义 Source/Transform/Window/Sink 四类节点；检测循环依赖并在创建时报错 |
| AC-FLX-002 | FR-002 | Source 支持 Kafka/NATS/gRPC/WebSocket/CSV 五种数据源类型；Source 声明输出数据类型 |
| AC-FLX-003 | FR-003 | Transform 支持 Filter/Map/FlatMap/KeyBy/Join/Enrich 操作；函数签名为 `func(ctx, T) (U, error)`；Filter 返回 false 时丢弃数据 |
| AC-FLX-004 | FR-004 | Window 支持 Tumbling/Sliding/Session 三种类型；聚合函数包含 Count/Sum/Avg/Min/Max/First/Last；触发策略基于事件时间+watermark+lateness |
| AC-FLX-005 | FR-005 | Sink 支持 Kafka/NATS/gRPC/InMemory/CSV 五种类型；返回 DeliveryReceipt（at-least-once）；至少一个 Sink 标注为 primary |
| AC-FLX-006 | FR-006 | 数据路由支持 symbol/exchange/dataType/自定义 key 分流；路由规则变更不丢数据（drain old → apply new） |
| AC-FLX-007 | FR-007 | 背压策略 Block/Drop/Spill 正确执行；触发时 emit `flowx.backpressure` metric；Spill 磁盘满降级为 Drop |
| AC-FLX-008 | FR-008 | Pipeline 按拓扑顺序启动（Source→Transform→Window→Sink）；启动失败回滚；支持 Pause/Resume/Stop |
| AC-FLX-009 | FR-009 | 热更新执行 Drain-Then-Apply；热更新期间数据不丢不重（offset checkpoint） |
| AC-FLX-010 | FR-010 | README H1 为 `# flowx`；Go module path 为 `github.com/ZoneCNH/flowx`；go.mod 声明 `module github.com/ZoneCNH/flowx` |

## 7. 行为约束

| 编号   | 规则                                       | 违反后果 |
| ------ | ------------------------------------------ | -------- |
| BR-001 | Source 节点必须声明输出数据类型            | 编译失败 |
| BR-002 | 至少一个 Sink 必须标注为 primary           | Pipeline 创建失败 |
| BR-003 | DAG 中不得有循环依赖                       | Pipeline 创建失败 |
| BR-004 | Sink at-least-once 语义不可降级为 at-most-once | 拒绝启动 |
| BR-005 | 背压策略必须显式配置，不允许隐式默认       | 拒绝启动 |

---

## 8. 接口契约

```go
// Pipeline 数据流管线
type Pipeline interface {
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
    Pause(ctx context.Context) error
    Resume(ctx context.Context) error
    Status() PipelineStatus
}

// Source 数据源
type Source interface {
    Name() string
    OutputType() reflect.Type
    Run(ctx context.Context, emit func(any)) error
}

// Transform 数据变换
type Transform interface {
    Name() string
    Apply(ctx context.Context, input any) (any, error)
}

// Window 窗口聚合
type Window interface {
    Name() string
    Type() WindowType // Tumbling, Sliding, Session
    Size() time.Duration
    Slide() time.Duration // 仅 Sliding
    Gap() time.Duration   // 仅 Session
    Aggregator() Aggregator
}

// Sink 数据输出
type Sink interface {
    Name() string
    Primary() bool
    Write(ctx context.Context, batch []any) ([]DeliveryReceipt, error)
}
```

---

## 9. 数据模型

| 模型              | 字段                                                                 |
| ----------------- | -------------------------------------------------------------------- |
| PipelineSpec      | name, sources[], transforms[], windows[], sinks[], edges[]           |
| PipelineStatus    | state(RUNNING/PAUSED/STOPPED), lagMs, throughputPerSec, errorRate    |
| DeliveryReceipt   | messageId, offset, status(ACK/NACK), error, latencyMs                |
| WindowType        | enum: TUMBLING, SLIDING, SESSION                                     |
| BackpressurePolicy| enum: BLOCK, DROP_OLDEST, DROP_NEWEST, SPILL_TO_DISK                 |

---

## 10. 配置模式

```yaml
flowx:
  default_backpressure: block
  spill_dir: /var/tmp/flowx
  max_spill_bytes: 10737418240  # 10 GB
  checkpoint_interval: 10s
  watermark_lateness: 5s
  metrics_export_interval: 15s
```

---

## 11. 错误处理

| 错误                        | 处理方式                                   |
| --------------------------- | ------------------------------------------ |
| Source 连接断开             | 指数退避重连，max 5 min 间隔              |
| Transform 执行超时          | 跳过该条数据，emit error metric            |
| Sink 写入失败               | 重试 3 次 → DLQ                            |
| DAG 拓扑非法                | Pipeline 创建失败，返回详细错误信息        |
| Watermark 迟到超过 lateness | 丢弃，emit late-data metric                |

---

## 12. 边界情况

| 场景                       | 预期行为                                 |
| -------------------------- | ---------------------------------------- |
| Source 生产速度远超 Sink    | 背压触发，按配置策略处理                 |
| Spill 磁盘满               | 降级为 DROP_NEWEST + alert               |
| 热更新中 Source 数据到达    | 旧拓扑继续消费，新拓扑从 checkpoint 恢复  |
| Window 内无数据             | 不上抛（skip empty windows）             |
| 两条相同 offset 的数据      | dedup by offset，只处理第一条            |

---

## 13. 目录结构

```text
flowx/
├── go.mod
├── go.sum
├── README.md
├── pipeline.go        # Pipeline 接口和默认实现
├── source.go          # Source 接口
├── transform.go       # Transform 接口
├── window.go          # Window 接口和聚合器
├── sink.go            # Sink 接口
├── dag.go             # DAG 校验和拓扑排序
├── backpressure.go    # 背压策略
├── checkpoint.go      # Offset checkpoint
├── route.go           # 数据路由
├── errors.go          # 错误定义
├── internal/
│   ├── kafka_source.go
│   ├── nats_source.go
│   └── memory_sink.go
└── example_test.go
```

---

## 14. 依赖

| 可以依赖                             | 禁止依赖                         |
| ------------------------------------ | -------------------------------- |
| kernel, configx, observex, contracts | 业务域实现（factor_engine 等）   |
| kafkax, natsx (adapter 接口)         | 具体交易所 SDK                   |
| stdlib                               | 因子计算逻辑                     |

---

## 15. 测试

| 测试场景              | 验证点                             |
| --------------------- | ---------------------------------- |
| Pipeline DAG 创建     | 节点连接正确，循环检测触发错误     |
| 背压策略              | 每种策略在 Sink 慢时正确触发       |
| 热更新                | 拓扑变更不丢数据                   |
| Window 聚合           | Tumbling/Sliding/Session 语义正确  |
| Source 重连           | 指数退避，最终恢复                 |
| Spill 降级            | 磁盘满时降级为 Drop + alert       |

---

## 16. 性能预算

| 操作               | 目标       |
| ------------------ | ---------- |
| 单条 Transform     | < 100μs    |
| Window 聚合        | < 1ms      |
| Pipeline 启动      | < 1s       |
| 热更新耗时         | < 5s       |
| 吞吐量             | > 100K msg/s per pipeline |

---

## 17. 可观测性

| 信号   | 指标                                  |
| ------ | ------------------------------------- |
| Metric | flowx.pipeline.lag_ms                |
| Metric | flowx.pipeline.throughput            |
| Metric | flowx.pipeline.error_rate            |
| Metric | flowx.backpressure.active            |
| Metric | flowx.source.reconnect_count         |
| Trace  | pipeline_id, node_id, message_id      |
| Log    | pipeline lifecycle, error, backpressure |

---

## 18. 安全

| 要求               | 实现方式                         |
| ------------------ | -------------------------------- |
| 数据不落地（默认） | Spill 仅在显式开启时写磁盘       |
| 数据脱敏           | Transform 中敏感字段 redact      |
| 无密钥泄露         | 不记录 payload 到日志            |

---

## 19. CI 门禁

| Gate    | 命令                                   | 阻塞条件       |
| ------- | -------------------------------------- | -------------- |
| 编译    | `go build ./...`                       | 编译失败       |
| 测试    | `go test ./... -race -count=1`         | 测试失败       |
| 覆盖率  | `go test -coverprofile=...`            | < 80%          |
| vet     | `go vet ./...`                         | vet 错误       |
| lint    | `golangci-lint run`                    | lint 错误      |
| secret  | `gitleaks detect --no-git`             | 泄露 secret    |

---

## 20. 升级兼容性

| 变更类型               | 版本升级  |
| ---------------------- | --------- |
| Pipeline 接口新增方法  | minor     |
| Source/Sink 接口变更   | major     |
| 新增 Window 类型       | minor     |
| 背压策略新增           | minor     |
| 删除/修改已有接口方法  | major     |

---

## 21. 发布 DoD

- [ ] Pipeline 接口完整实现且通过单元测试
- [ ] 三种 Window 类型全部验证
- [ ] 背压四种策略全部测试
- [ ] 热更新不丢数据验证通过
- [ ] 覆盖率 ≥ 80%
- [ ] CHANGELOG.md 已更新
- [ ] godoc 完整

---

## 22. 待解决问题

- 是否支持多 Pipeline 间的数据 Join？
- 是否支持分布式 Pipeline（跨进程）？
- 是否支持 Protobuf 序列化（除 JSON 外）？
- Window 状态是否需要持久化到外部存储？


## 23. 变更历史

| 日期       | 版本         | 变更内容 | 作者    |
| ---------- | ------------ | -------- | ------- |
| 2026-06-14 | v0.1.0-draft | 初始版本 | ZoneCNH |
| 2026-06-14 | v0.1.0-draft | FR-010 Module Identity (README H1 + go.mod 校验) | ZoneCNH |