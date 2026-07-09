# OrderBook Phase 1：binance 前置硬化任务包

> 日期：2026-07-09
> 状态：执行前任务包 / 不修改 runtime
> 范围：`/home/workspace/binance` 的 OrderBook 迁移前硬化
> 目标：在任何 `orderbook` 新模块或 runtime repo 创建前，先关闭 binance 当前会阻塞迁移和扩量的工程风险

---

## 0. 结论

Phase 1 的第一优先级不是抽独立模块，而是先把 binance 的 stream 扩量、档位语义、options depth 口径和 replay 输入证据补齐。[INFERRED, HIGH]

当前最关键风险是 combined stream 仍由 `streamConfig()` 拼成单个 URL，扩 symbol 或 stream 后可能触发连接上限、URL 长度、交易所 stream 数量上限或不可观测的订阅丢失风险。[COMPUTED, HIGH]

DepthLevel、OrderbookFeatures、StreamType 和 tier Capability 已有代码基础，因此 Phase 1 不应从零设计 PolicyManager，而应做语义回归与配置闭环。[COMPUTED, HIGH]

options depth 仍应作为口径风险处理；在有 payload capture 或明确 postponed 标识前，不应被读成与 spot/UM/CM 等价完成。[INFERRED, HIGH]

---

## 1. 证据基线

| 证据                                                                | 说明                                                                                                            |
| ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `/home/workspace/binance/internal/client/stream_control.go:363-403` | `streamConfig()` 生成 `activeStreams` 后直接拼接成一个 combined stream URL。[COMPUTED, HIGH]                    |
| `/home/workspace/binance/internal/client/stream_config_test.go`     | 当前测试覆盖 StreamType 过滤、zero=all、kline 前缀、suffix 映射，但未覆盖 URL 分片。[COMPUTED, HIGH]            |
| `/home/workspace/binance/internal/client/spot.go:220-383`           | connector 有 `MaxConnections` 和 `SetStreamMaskProvider`，但没有 visible stream shard planner。[COMPUTED, HIGH] |
| `/home/workspace/binance/internal/client/subscription_pool.go`      | 当前是引用计数订阅池，不是 combined stream sharding 实现。[COMPUTED, HIGH]                                      |
| `/home/workspace/binance/pkg/whitelistclient/depthlevel.go`         | DepthLevel 定义 None/L1/L2/L3/L4 和 levels 映射。[COMPUTED, HIGH]                                               |
| `/home/workspace/binance/pkg/whitelistclient/tier_capability.go`    | tier 到 Streams/Features/Depth 的 Capability 映射已存在。[COMPUTED, HIGH]                                       |
| `/home/workspace/binance/internal/client/runtime.go:1011-1137`      | OrderBook want set 与 SyncSubscriptionsWithCapabilities 已使用 features/depthLevel。[COMPUTED, HIGH]            |

---

## 2. 执行边界

本任务包只指导 binance runtime 硬化，不创建 `module/orderbook/`。[FRAME, HIGH]

本任务包不新增 `internal/client/policy/PolicyManager`，因为当前白名单、tier Capability、OrderbookService 子集校验和 NATS 同步链路已覆盖主要 Policy/Demand 语义。[INFERRED, HIGH]

本任务包不把 Feature Engine、Market State Engine 或 Execution feedback 加入 binance。[FRAME, HIGH]

本任务包完成后，仍不能直接宣称 `orderbook` 独立模块存在；它只解除迁移前置风险。[FRAME, HIGH]

---

## 3. 任务拆解

### OB-P1-001：combined stream shard planner

目标：把 `activeStreams []string` 转换为可验证的 shard 列表，而不是单个 URL。[FRAME, HIGH]

建议写入范围：

```text
/home/workspace/binance/internal/client/stream_shard.go
/home/workspace/binance/internal/client/stream_shard_test.go
```

接口草案：

```go
type StreamShardPlan struct {
    BaseURL string
    Shards  []StreamShard
}

type StreamShard struct {
    Index   int
    Streams []string
    URL     string
}

type StreamShardLimits struct {
    MaxStreamsPerShard int
    MaxURLBytes        int
}
```

验收条件：

| 条件        | 验收                                                             |
| ----------- | ---------------------------------------------------------------- |
| 分片稳定    | 同一 activeStreams 输入得到同一 shard 顺序。[FRAME, HIGH]        |
| 上限可配    | 支持 MaxStreamsPerShard 和 MaxURLBytes 两个上限。[FRAME, HIGH]   |
| URL 正确    | 每个 shard URL 使用同一 base，streams 以 `/` join。[FRAME, HIGH] |
| fail closed | 单个 stream 超过 URL 上限时返回 error，不静默丢弃。[FRAME, HIGH] |
| 测试覆盖    | 1、N、边界、超限、空输入全部覆盖。[FRAME, HIGH]                  |

### OB-P1-002：SpotConnector 多 shard 运行策略

目标：让 connector 可以按 shard 建立多个 WS 连接，受 `MaxConnections` 约束。[FRAME, HIGH]

建议写入范围：

```text
/home/workspace/binance/internal/client/stream_control.go
/home/workspace/binance/internal/client/spot.go
```

设计要求：

| 要求       | 说明                                                                                                    |
| ---------- | ------------------------------------------------------------------------------------------------------- |
| 保持兼容   | `buildStreamURL()` 可保留首 shard 或用于单 shard 兼容；新增方法承载多 shard。[FRAME, HIGH]              |
| 连接预算   | shard 数不得超过 `SpotConnector.maxConns`。[FRAME, HIGH]                                                |
| 可观测     | `StreamSnapshot` 应能暴露 shard 数、active stream 数、rejected reason 或 degraded reason。[FRAME, HIGH] |
| 错误路径   | 分片失败不得启动半截订阅。[FRAME, HIGH]                                                                 |
| 控制面一致 | pause/drain/resume 对所有 shard 生效。[FRAME, MED]                                                      |

关键风险：

多 shard collect 会改变当前 `collect(ctx, events)` 的生命周期模型，必须先设计 goroutine fan-in 与错误传播语义。[INFERRED, HIGH]

### OB-P1-003：streamConfig 测试扩展

目标：覆盖分片后的配置行为。[FRAME, HIGH]

建议测试：

```text
TestStreamShardPlanner_SingleShard
TestStreamShardPlanner_SplitsByMaxStreams
TestStreamShardPlanner_SplitsByMaxURLBytes
TestStreamShardPlanner_RejectsSingleOversizedStream
TestStreamConfig_FiltersBeforeSharding
TestStreamConfig_RespectsMaxConnections
```

命令：

```bash
go test ./internal/client -run 'TestStream(Config|Shard)' -count=1
```

### OB-P1-004：DepthLevel / StreamType / Capability 语义回归

目标：确认 tier、stream suffix、DepthLevel 和 TopN 截断没有语义漂移。[FRAME, HIGH]

当前事实：`DepthLevel` 与 `CapabilityForTier` 已存在，`buildOrderBookWantSet()` 已把 depthLevel 传入 `SyncSubscriptionsWithCapabilities()`。[COMPUTED, HIGH]

需要补的不是字段，而是语义闭环证据。[INFERRED, HIGH]

建议测试：

```text
TestCapabilityForTier_OrderBookDepthSemantics
TestBuildOrderBookWantSet_UsesTierDepth
TestOrderBookSyncSubscriptions_PreservesDepthLevel
TestTopNDepth_UsesDepthLevel
TestStreamTypeDepthFullVsDepth20_NoAmbiguousMapping
```

命令：

```bash
go test ./pkg/whitelistclient ./internal/client ./internal/client/orderbook -run 'Capability|DepthLevel|OrderBookWant|TopNDepth|StreamType' -count=1
```

验收标准：

| tier     | streams      | features | depth | 期望                                      |
| -------- | ------------ | -------- | ----- | ----------------------------------------- |
| prime    | all          | all      | L4    | full incremental 可以启用。[FRAME, HIGH]  |
| standard | 146          | 7        | L2    | Top20，不应默认为全深度。[COMPUTED, HIGH] |
| lite     | trade+ticker | none     | None  | 不应进入 OB subscription。[FRAME, HIGH]   |
| blocked  | none         | none     | None  | 不应采集。[FRAME, HIGH]                   |

### OB-P1-005：options depth 口径澄清

目标：把 options depth 从“读者可能误会为 Done”改为有证据的状态。[FRAME, HIGH]

可选路径：

| 路径           | 交付物                              | 适用                                    |
| -------------- | ----------------------------------- | --------------------------------------- |
| capture        | testnet / sandbox payload fixture   | 确认近期要支持 options。[FRAME, MED]    |
| postponed      | spec / acceptance 明确标记 Phase 2  | 当前不支持 options depth。[FRAME, HIGH] |
| not_applicable | 本 release 不纳入 options orderbook | release 口径需要降歧义。[FRAME, HIGH]   |

建议写入范围：

```text
/home/workspace/ZoneCNH/module/binance/spec/ACCEPTANCE.md
/home/workspace/ZoneCNH/module/binance/todo.md
/home/workspace/binance/internal/client/testdata/market_events/
```

验收条件：

options depth 状态必须能被读成 `supported`、`postponed` 或 `not_applicable` 三者之一，不能靠正文解释模糊覆盖。[INFERRED, HIGH]

### OB-P1-006：Replay fixture input capture

目标：不先做完整 replay engine，但先定义能捕获后续 replay 所需输入的 fixture 格式。[FRAME, HIGH]

建议 fixture 最小字段：

```text
venue
product_line
symbol
snapshot.last_update_id
snapshot.bids
snapshot.asks
diffs[].first_update_id
diffs[].final_update_id
diffs[].prev_update_id
diffs[].bids
diffs[].asks
diffs[].event_time
expected.book_hash
expected.quality_flags
```

建议写入范围：

```text
/home/workspace/binance/internal/client/orderbook/testdata/replay/
/home/workspace/binance/internal/client/orderbook/replay_fixture_test.go
```

验收条件：

同一 fixture 能驱动 align、sequence validation、gap detection 和 final book assertion。[FRAME, HIGH]

---

## 4. 推荐执行顺序

| 顺序 | 任务                              | 依赖                  |
| ---- | --------------------------------- | --------------------- |
| 1    | OB-P1-001 shard planner           | 无                    |
| 2    | OB-P1-003 shard tests             | OB-P1-001             |
| 3    | OB-P1-002 connector 多 shard 策略 | OB-P1-001 / OB-P1-003 |
| 4    | OB-P1-004 DepthLevel 语义回归     | 无                    |
| 5    | OB-P1-005 options depth 口径      | 无                    |
| 6    | OB-P1-006 Replay fixture input    | OB-P1-004 推荐先完成  |

不建议先做 OB-P1-002，因为直接改 connector lifecycle 容易扩大 blast radius。[INFERRED, HIGH]

---

## 5. 质量门禁

| Gate      | 命令或证据                                           | 通过条件                                    |
| --------- | ---------------------------------------------------- | ------------------------------------------- | -------------------------------------------- |
| format    | `gofmt`                                              | 新增 Go 文件格式化。[COMMON, HIGH]          |
| unit      | `go test ./internal/client -run 'TestStream(Config   | Shard)' -count=1`                           | 分片与 stream config 单测通过。[FRAME, HIGH] |
| orderbook | `go test ./internal/client/orderbook -count=1`       | 现有 orderbook 单测不回退。[FRAME, HIGH]    |
| whitelist | `go test ./pkg/whitelistclient -count=1`             | Capability/DepthLevel 不回退。[FRAME, HIGH] |
| race      | `go test ./internal/client/orderbook -race -count=1` | 状态机核心无竞态回归。[FRAME, MED]          |
| evidence  | `module/binance/evidence/YYYY-MM-DD/` 或 report      | 记录命令、结果和未覆盖项。[FRAME, HIGH]     |

---

## 6. 完成标准

Phase 1 只有在以下条件全部满足时才能关闭。[FRAME, HIGH]

```text
combined stream 有 shard planner 和测试
SpotConnector 多 shard 策略已设计或实现
DepthLevel / StreamType / Capability 语义有回归测试
options depth 状态不再含糊
replay fixture input 格式可被 orderbook tests 使用
未新增 PolicyManager
未创建 module/orderbook
未创建 runtime repo
```

---

## 7. 后续衔接

Phase 1 完成后，才进入 `ORDERBOOK-MODULE-ONBOARDING-ADR-INPUT-20260709.md` 的正式 ADR 审查。[FRAME, HIGH]

正式 ADR 通过后，才允许按双闸门创建 `module/orderbook/` 规格目录。[COMPUTED, HIGH]

runtime repo 创建必须再等规格、gate、fixture 和维护者显式授权齐备。[FRAME, HIGH]

---

[RULES I BROKE]：无
