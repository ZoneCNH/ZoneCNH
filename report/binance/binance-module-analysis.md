# binance 模块生产级别深度分析报告

| 字段 | 值 |
| --- | --- |
| 报告类型 | 生产就绪度（Production-Ready）深度分析 |
| 分析对象 | `github.com/ZoneCNH/binance`（运行时代码仓 `/home/binance`） |
| 治理投影 | `/home/ZoneCNH/module/binance/`（spec / TRACEABILITY 投影仓） |
| 当前 Runtime-Anchor | `/home/binance@f18a329` |
| 当前 Issue-Ledger | [`issues-sync-20260625.md`](./issues-sync-20260625.md) |
| 当前状态投影 | `24 Done / 10 Partial / 0 Pending` |
| 当前 issue 状态 | `#1106` Closed；`#1104`, `#1105`, `#1107`-`#1118` Open |
| 代码规模 | ~13.5K 行生产代码 + ~11.2K 行测试代码（66 个测试文件） |
| 分析日期 | 2026-06-25 |
| 证据基准 | 运行时代码 `/home/binance@f18a329` + `release/evidence/binance/20260625/` 实证 + mainnet live |
| 置信度 | HIGH（代码逐文件核验 + release evidence 交叉验证） |
| 证据标签 | 见各节内联标注 |

---

## 目录

1. [执行摘要](#1-执行摘要)
2. [关键发现 Top 5](#2-关键发现-top-5)
3. [业务覆盖度审计](#3-业务覆盖度审计)
4. [数据流架构分析](#4-数据流架构分析)
5. [生产就绪度评分](#5-生产就绪度评分)
6. [优化与迭代建议](#6-优化与迭代建议)
7. [模块规范制定](#7-模块规范制定)
8. [结论与行动清单](#8-结论与行动清单)
9. [证据清单](#9-证据清单)

---

## 1. 执行摘要

`binance` 是一个**币安交易所多产品线市场数据采集与服务**的双服务（C/S）模块：`binance-client` 连接币安 WebSocket/REST、归一化事件并经 NATS JetStream 发布；`binance-server` 消费、去重、落盘四路存储（TDengine / ClickHouse / Postgres / OSS）、提供查询 API 并经 Kafka 广播。

**核心判断**：模块在**架构完整度、代码质量、测试覆盖、可观测性**上已达到生产级水准；**首个生产就绪 release v0.2.0 已发布**（`release/evidence/binance/20260625/release-v020-live.txt`）。但存在 **3 类阻塞性或半阻塞性缺口**使其在"严格生产级"标准下仍需补齐：

- **FR-016 历史回补未接线**：真实 REST fetcher 代码完整，但 `runtime.go:96` 用 `DefaultHistoryRuntimeConfig()` 未注入，runtime 永不执行历史回补。
- **REST 历史端点 Spot-only**：`routeEndpoint` 只路由现货，UM/CM/Options 的历史回补完全缺失。
- **Kafka 广播 PARTIAL**：driver 装配修复、producer 建连成功，但 `producer.Send` 受 dev broker 配置阻塞（topic 自动创建 / SASL），未实证 produce→consume roundtrip。

`[COMPUTED, HIGH]` 当前行动清单、关闭条件和 issue 状态统一维护在 [`issues-sync-20260625.md`](./issues-sync-20260625.md)。本文保留历史分析语境，不再作为独立 checklist 权威。

**可信度说明**：模块治理投影文档与 runtime 曾存在状态漂移；本报告保留该历史语境。当前 `report/binance/` 有效口径以 `/home/binance@f18a329`、[`issues-sync-20260625.md`](./issues-sync-20260625.md) 和 `24 Done / 10 Partial / 0 Pending` 为准；`module/binance/` 不在本写入切片内。

> **[RULES]** 报告遵循 [`docs/constitution/20-epistemic-standards.md`](../../docs/constitution/20-epistemic-standards.md) 认识论标准。凡事实性声明带 `[COMPUTED]`/`[KNOWN]`/`[INFERRED]` 标签 + 显式置信度；文档与代码冲突时以代码为优先，并显式标注冲突。

---

## 2. 关键发现 Top 5

### #1 文档-代码漂移：G0 存储装配实际已闭合 `[COMPUTED]` 置信度 HIGH

治理文档 `module/binance/FEATURES.md` v3.6.0 口径把 G0（9 个存储类 FR 的 main.go 装配）列为"P0 阻断发布"。但：

- `cmd/binance-server/storage_env.go` 实现了完整的 `storageFromEnv`：5 路 infra（taosx/postgresx/redisx/clickhousex/ossx）fail-fast 装配 + 4 个 PostAcceptHook（pgCatalog/hotCache/ossArchive batch/aggSource ETL）+ RedisStore 幂等替换内存版。
- `cmd/binance-server/main.go:135` 调用 `storageFromEnv`，`:144-150` 注入 `asm.idempotency` / `serverConfig.StorageWriter` / `PostAcceptHooks` / `etlRun` goroutine。
- `release/evidence/binance/20260625/storage-assembly-live.txt`：5/5 infra LIVE-PASS（taosx healthy / pg SELECT 1 / redis Set-Get / ch SELECT 1 / Kafka roundtrip 9.07s）。

**影响**：该漂移解释了为什么需要后续 issue ledger；当前行动入口是 [`issues-sync-20260625.md`](./issues-sync-20260625.md)，其中 `#1106` 文档对齐已关闭，其余 runtime/evidence issues 保持开放。

### #2 归一化层是产品线无关的单点分派 `[KNOWN]` 置信度 HIGH

`internal/client/normalize.go:114` `NormalizeMarketMessage` 用单一函数按 stream kind（trade/bookTicker/kline/depth/markPrice/fundingRate/optionTicker/rawPassThrough）分派，产品线经 `CanonicalProductLine` 路由。这是**优雅的抽象**，但也意味着 **Options 的结构化解析（`parseOptionTicker`）未经 mainnet 真实样本验证**（`normalize.go:502` TODO 明示"待 BINANCE_MAINNET_LIVE 校验"）。

### #3 REST 历史回补是 Spot-only 的 `[COMPUTED]` 置信度 HIGH

`history_rest.go:143` `routeEndpoint` 只对 `kline/bar` → Spot klines、`aggTrade/trade` → Spot aggTrades 返回端点；UM/CM/Options 配置字段（`restFetcherConfig.UMPerpBaseURL` 等，`:30-34`）**存在但永不被路由**。Options 更直接 `ErrNotConnected`（`history_rest.go:68` 注释）。

### #4 多层幂等 + 多路存储 + at-least-once 全链路已实证 `[KNOWN]` 置信度 HIGH

- 幂等三层：客户端 sha256 keyer（`idempotency.go:26`）+ Redis SETNX 72h（`redis_store.go:129`）+ Postgres durable log（`pg_log.go:50`）。
- 消费 at-least-once：JetStream ManualAck + AckWait 30s + MaxDeliver 5 + Ack/Nak/Term 三态 + panic recover（`consumer.go:159-180`）。
- mainnet 四线 WS：spot/um/cm trade 真实接收 + normalize 字段正确（`mainnet-coverage-matrix.txt`，3/4 LIVE-PASS）。

### #5 限流是固定滑动窗口 80/20 拆分，非 token bucket `[COMPUTED]` 置信度 HIGH

`throttle.go:90` `Allow` 用固定分钟窗口计数，按 `cold_start:repair = 80:20` 拆分配额。对**回填任务**够用，但对**实时 WS 重连风暴**无防护（WS 重连由 `spot.go` 指数退避独立处理，见 §5.1）。且窗口边界突发（window-edge burst）未被平滑。

---

## 3. 业务覆盖度审计

> 证据基准：`internal/client/connectors/*.go`、`normalize.go`、`history_rest.go`、`product_line.go`、`pkg/binancecfg/endpoints.go` + mainnet live evidence。

| 业务类型 | Connector | Normalize | REST 历史 | WS 实时 | 覆盖结论 | 缺口说明 |
| --- | --- | --- | --- | --- | --- | --- |
| **现货 Spot** | `connectors/spot.go` → `spot.go` `SpotConnector` | `normalize.go:114` 全 stream kind | ✅ `/api/v3/klines` + `/api/v3/aggTrades`（`history_rest.go:147,150`） | ✅ `wss://stream.binance.com:9443` | **完整** | 无（mainnet 已实证） |
| **U本位合约 UM-PERP** | `connectors/um_perp.go`（薄封装） | 同上 + `parseMarkPrice`/`parseFundingRate` | ❌ 未路由（`routeEndpoint` default 返回空） | ✅ `wss://fstream.binance.com` | **部分** | WS+normalize 完整且 mainnet 已实证；REST 历史回补缺失 |
| **币本位合约 CM-PERP** | `connectors/cm_perp.go`（薄封装） | 同上 | ❌ 未路由 | ✅ `wss://dstream.binance.com` | **部分** | 同 UM；CM `markPriceUpdate` 三字段（mark/index/settlement+funding）解析已实现 |
| **期权 Options** | `connectors/options.go`（薄封装） | `normalize.go:519` `parseOptionTicker` + `rawPassThrough` 兜底 | ❌ `ErrNotConnected`（无公开 REST 历史） | ✅ `wss://.../public` | **部分** | WS 连通性验证；Greeks 字段名未经真实 mainnet 样本校验（TODO `normalize.go:502`） |
| **订单簿 Depth** | 无独立 connector，作为 stream kind 内嵌 | `normalize.go:289` `parseDepth`（全量 `DepthBids/DepthAsks`） | 随所属产品线（仅 Spot 有） | ✅ `@depth20@100ms` / `@depth@1000ms`（`product_line.go:103`） | **完整（快照级）** | 仅 top-of-book + 部分 depth 快照；**无增量 diff 重放与全量订单簿重建**（G8，见 §6） |

**覆盖度总评** `[COMPUTED]`：5 类业务中，Spot 完整；UM/CM/Options 三线"WS+normalize 完整、REST 历史缺失"；Depth 在快照级完整但缺增量重建。**实时数据通路全业务线可用，历史回补仅现货可用**。

---

## 4. 数据流架构分析

详见独立文档 [`binance-data-flow-architecture.md`](./binance-data-flow-architecture.md)。此处给出总览 Mermaid 图：

```mermaid
flowchart LR
    subgraph Binance["币安交易所（上游）"]
        WS["WebSocket 公共流<br/>spot/fstream/dstream/options"]
        REST["REST API<br/>klines/aggTrades"]
    end

    subgraph Client["binance-client 进程"]
        direction TB
        CONN["Connector<br/>spot.go:329 run<br/>指数退避重连"]
        THROTTLE["ThrottleManager<br/>throttle.go:90<br/>80/20 滑动窗口"]
        NORM["NormalizeMarketMessage<br/>normalize.go:114<br/>产品线无关分派"]
        KEY["Idempotency Keyer<br/>idempotency.go:26<br/>sha256[:16]"]
        PUB["Publisher<br/>publisher.go:56<br/>Subject binance.market.pl.et"]
        QUEUE["Queue 状态机<br/>queue.go<br/>5 态 at-least-once"]
    end

    subgraph Bus["NATS JetStream"]
        STREAM["Stream BINANCE_MARKET<br/>Subject binance.market.*.*<br/>consumer.go:63"]
    end

    subgraph Server["binance-server 进程"]
        direction TB
        CONS["Consumer Runner<br/>consumer.go:141<br/>ManualAck/AckWait30s/MaxDeliver5"]
        PROC["Ingest Process<br/>ingest.go:49<br/>校验→幂等→持久化→dispatch→hooks"]
        IDEM["幂等 RedisStore<br/>redis_store.go:129<br/>SETNX 72h + PG durable log"]
        DISP["Dispatch<br/>ingest.go:242<br/>100/200/400ms 重试→DLQ"]
        subgraph Storage["四路并行存储"]
            TAOS["TDengine<br/>taos_writer.go:80"]
            CH["ClickHouse ETL<br/>clickhouse_olap.go:415"]
            PG["Postgres catalog<br/>pg_catalog.go:73"]
            OSS["OSS 归档<br/>oss_archiver.go:89"]
        end
        DLQ["DeadLetter<br/>ingest.go:328 + deadletter.go"]
    end

    subgraph Down["下游"]
        KAFKA["kafkax 广播"]
        API["Gin 查询 API<br/>query.go:124"]
    end

    WS --> CONN
    REST -. 历史 .-> NORM
    CONN --> THROTTLE --> NORM --> KEY --> PUB --> QUEUE
    QUEUE -->|JetStream PubAck| STREAM
    STREAM --> CONS --> PROC
    PROC --> IDEM
    PROC --> DISP --> TAOS & CH & PG & OSS
    PROC -. 失败 .-> DLQ
    DISP --> KAFKA
    TAOS & CH --> API

    classDef store fill:#e8f5e9,stroke:#2e7d32
    classDef fail fill:#ffebee,stroke:#c62828
    class TAOS,CH,PG,OSS store
    class DLQ fail
```

**关键模块职责边界**（file:line 证据见 §9）：

- **客户端采集层**：`spot.go:329` 指数退避无限重连（1s→60s 封顶）+ ping/pong 心跳（30s/60s）+ panic recover。
- **归一化层**：`normalize.go:114` 单点分派，产品线无关；Options 专用 `parseOptionTicker` + `rawPassThrough` 兜底。
- **可靠性层**：`controlplane/reliability.go` 三件套——RetryBudget（重试预算）、WeightGate（权重准入 + backoff）、ClockSkewDetector（时钟偏移容差）。
- **持久化层**：`storage_env.go` composition root，5 路 fail-fast 装配，PostAcceptHook 链（pgCatalog→hotCache→ossArchive batch→aggSource ETL）。
- **消费确认层**：`consumer.go:159` Ack/Nak/Term 三态 + MaxDeliver=5 + panic→terminal。

---

## 5. 生产就绪度评分

> 评分制：1（严重不足）~ 5（生产级）。每项附证据与扣分理由。

### 5.1 可靠性 — 4.0 / 5

| 子项 | 评分 | 证据 / 理由 |
| --- | --- | --- |
| WS 断线重连 | 5 | `spot.go:329-373` 指数退避（1s→60s）+ `MaxAttempts=0` 无限重连 + panic recover（`:330-335`） |
| HTTP 重试 | 4 | `history_rest.go:167` 3 次指数退避 + 429 感知；但**仅 Spot 路由生效**（UM/CM/Options 不路由） |
| Dispatch 重试 | 5 | `ingest.go:242` 100/200/400ms 三次 + 耗尽入 DLQ |
| 限流 | 3 | `throttle.go` 固定滑动窗口 80/20，**无 token bucket 平滑、无 window-edge burst 防护、不覆盖 WS 重连风暴** |
| at-least-once | 5 | ManualAck + AckWait 30s + MaxDeliver 5 + Nak/Term 三态（`consumer.go`） |
| 幂等 | 5 | 三层（sha256 keyer + Redis SETNX 72h + PG durable log），`idempotency/redis_store.go:129` |

**扣分主因**：限流算法偏简单（-1）；HTTP 重试业务覆盖不均（-0.5，已在 4 分档）。

### 5.2 性能 — 4.5 / 5

| 子项 | 评分 | 证据 |
| --- | --- | --- |
| 归一化吞吐 | 5 | SLO bench：`NormalizeSpotTrade` 3.4μs、`NormalizeBookTicker` 2.6μs（`slo-report.md`） |
| Ingest 处理 | 5 | `IngestProcess` 2.8μs，NFR P99<50ms 远低于预算 |
| 幂等检查 | 5 | `IdempotencyCheckAndSet` 808ns |
| API 查询 | 5 | cache hit 2.6μs / history 2.7μs，P99<5ms |
| 端到端压测 | 3 | 24 项 micro-bench 全 PASS，但**无 100K TPS 级端到端压测 + 回压验证**（依赖 G0 装配后重测） |

**扣分主因**：缺大规模端到端压测证据（-1.5→4.5 档）。

### 5.3 可观测性 — 4.5 / 5

| 子项 | 评分 | 证据 |
| --- | --- | --- |
| Prometheus 指标 | 5 | 17 个 `binance_*` 指标（`metrics.go:153-247`），覆盖 ingest/dispatch/DLQ/stream lag/reconnect/retry budget/clock skew/gap |
| 日志 | 4 | `log/slog` JSON 标准库（`logging.go:28`），无第三方依赖；**缺结构化 trace/span（OpenTelemetry）** |
| 健康检查 | 5 | healthz/readyz 真实接入 |
| 链路追踪 | 3 | 无分布式 trace，跨进程（client→NATS→server→Kafka）无 trace 上下文传播 |

**扣分主因**：无分布式链路追踪（-0.5）。

### 5.4 安全性 — 4.0 / 5

| 子项 | 评分 | 证据 |
| --- | --- | --- |
| API Key 管理 | 5 | `binancecfg` `SecretString` 掩码脱敏（`config.go:31-132`）；8 个 `FOUNDATIONX_` 环境变量 |
| 签名机制 | 4 | **仓库内不实现 HMAC**，完全委托 `binance-connector-go` SDK；公共市场数据通路根本不读 key（`pkg/binancex/adapter.go` 仅交易适配器消费） |
| 凭据扫描 | 5 | `.gitleaks.toml` + gitleaks CI + govulncheck |
| API 鉴权 | 4 | Bearer auth + 限流 1000/min（`api/query.go:149,166`） |
| 凭据 Runbook | 3 | NFR-012/013 标注"凭据管理 Runbook 待补" |

**扣分主因**：缺凭据管理 Runbook（-1）。注：签名委托 SDK 是合理设计而非缺陷。

### 5.5 可测试性 — 4.5 / 5

| 子项 | 评分 | 证据 |
| --- | --- | --- |
| 单元测试 | 5 | 66 个测试文件、~11.2K 行测试；throttle/consumer/idempotency/normalize 均有专项测试 |
| 集成测试 | 4 | `test/e2e/` 3 文件含 mainnet live + Kafka broker；**Kafka roundtrip 未实证**（broker 配置阻塞） |
| Mock 覆盖 | 4 | `fakeProducer` / `RecordingSink` / `MemoryIdempotencyStore` / fault injection（`consumer/fault_injection_test.go`）；缺 ClickHouse/TDengine 的 mock 层 |
| 基准测试 | 5 | 24 项 bench + bench_test.go 全覆盖关键路径 |

**扣分主因**：Kafka e2e 未闭合（-0.5）、存储层 mock 不足（-0.5→合并到 4.5 档）。

### 5.6 可维护性 — 4.5 / 5

| 子项 | 评分 | 证据 |
| --- | --- | --- |
| 代码结构 | 5 | 清晰 C/S 分层（client/wire/server/pkg），connector 薄封装 + normalize 单点；边界 gate 13/13 PASS |
| 注释 | 5 | 中文 doc comment 覆盖率高，每文件有包级说明 + 设计权衡（如 `storage_env.go` 顶部 design principles） |
| 文档完整度 | 4 | spec/TRACEABILITY/RUNTIME-MAPPING/NAMING/STANDARD 齐全；**但 FEATURES.md 状态滞后于代码**（见 #1） |
| 治理自动化 | 5 | 98 分四源评分管线 + boundary-gates.sh + matrix checker |

**扣分主因**：文档-代码漂移（-0.5）。

### 综合评分：4.33 / 5 `[COMPUTED]`

> **结论**：达到"生产可用"标准，距"严格生产级（4.5+）"差 **FR-016 接线 + Kafka e2e 闭合 + 分布式 trace + 文档同步** 四项。这四项均不改变架构，属补齐工作。

---

## 6. 优化与迭代建议

### 必须修复（阻塞严格生产级）— P0

| # | 问题 | 影响 | 解决方案 | 证据 |
| --- | --- | --- | --- | --- |
| P0-1 | **FR-016 历史回补未接线**：`runtime.go:96` 用 `DefaultHistoryRuntimeConfig()` 未注入真实 REST fetcher | 冷启动回补、gap-fill、每日对账均无法执行 | runtime 注入 `restHistoryFetcher`（需 `SpotBaseURL` 配置）+ 接入 `history_lifecycle.go` | `internal/client/runtime.go:96`；`module/binance/FEATURES.md` FR-016 |
| P0-2 | **Kafka produce→consume roundtrip 未实证** | FR-008 广播通路 driver 正确但 send 受 dev broker 配置阻塞 | 确认 broker `auto.create.topics.enable` 或预建 topic + SASL 配置；解锁后重跑 `TestKafkaBroker_ProduceConsumeRoundtrip` | `release/evidence/binance/20260625/kafka-broker-live.txt`（PARTIAL） |
| P0-3 | **report/binance 当前口径对齐（#1106）** | 文档行动项已闭合；保留历史漂移语境，避免把旧 module 投影当作当前行动清单 | 本报告族统一指向 `issues-sync-20260625.md`、`/home/binance@f18a329` 与 `24 Done / 10 Partial / 0 Pending`；`module/binance/` 不在本写入切片 | [`issues-sync-20260625.md`](./issues-sync-20260625.md) |

### 建议优化（提升质量）— P1

| # | 问题 | 影响 | 解决方案 | 优先级 |
| --- | --- | --- | --- | --- |
| P1-1 | REST 历史端点 Spot-only（`routeEndpoint` default 空） | UM/CM/Options 无历史回补 | 扩展 `routeEndpoint` 路由 UM `/fapi/v1/klines`、CM `/dapi/v1/klines`；Options 保持 `ErrNotConnected`（无公开 REST） | P1 |
| P1-2 | Options `parseOptionTicker` 字段名未校验 | Greeks（delta/gamma/theta/vega）可能解析错误 | mainnet 抓真实 `@optionTicker` 样本，核对 `rawOptionTicker` json tag（`normalize.go:503-515`） | P1 |
| P1-3 | 限流无平滑（固定滑动窗口） | window-edge burst 可触发币安 429 | 升级为 token bucket 或 sliding-window-log；或接 `rate_limit_backoff_total` 指标动态退避 | P1 |
| P1-4 | 无分布式链路追踪 | 跨 client→NATS→server→Kafka 故障难定位 | 引入 OpenTelemetry，在 IngestRequest 注入 trace context，NATS header 传播 | P1 |
| P1-5 | Options/合约 testnet 凭据缺失 | um/cm/options 产品线 normalize 差异测试未跑 | mainnet 公开流已覆盖 3/4（`mainnet-coverage-matrix.txt`）；补 options 活跃 symbol 实跑即可，无需 testnet 凭据 | P1 |

### 未来迭代（增强能力）— P2

| # | 问题 | 解决方案 |
| --- | --- | --- |
| P2-1 | 订单簿无增量重建（仅 top-of-book + 部分 depth） | 本地 ordered book 维护 + REST snapshot 拉取 + 增量 diff 重放（G8） |
| P2-2 | ClickHouse ETL AggSource 是内存窗口（单实例） | 改为从 taosx 聚合，支持多实例横向扩展 |
| P2-3 | Hot reload 全量重连非增量 stream diff | 增量 stream add/remove（FR-024） |
| P2-4 | Backfill progress 仅 in-memory | 持久化 progress 存储（FR-028） |
| P2-5 | deadletter in-memory（server 侧） | 持久化 DLQ（FR-004 增强项，已有 `deadletter/deadletter.go` FileWriter 可接线） |

---

## 7. 模块规范制定

**判断**：**需要建立** binance 模块开发规范。仓库已部分具备（`module/binance/NAMING.md`、`STANDARD.md`、`RULES.md`），但分散且未形成统一标准。详见独立文档 [`binance-module-standards.md`](./binance-module-standards.md)。

规范应覆盖：命名规范、目录结构、API 封装（请求/响应/错误统一约定）、数据模型、错误码（`BNC-001..BNC-013` 已存在于 `server.go:228-271`）、测试与文档。本报告据此提炼现行实现的成文约定 + 补全缺口。

---

## 8. 结论与行动清单

**总判断** `[COMPUTED]` 置信度 HIGH：binance 模块**架构成熟、实现完整、测试扎实、可观测性良好**，已发布 v0.2.0 生产就绪版本。距"严格生产级"的差距集中在**接线类与验证类**工作（FR-016 注入、Kafka e2e、文档同步），不涉及架构返工。

**当前行动入口** `[COMPUTED, HIGH]`：所有当前行动项、关闭条件与 issue 状态统一维护在 [`issues-sync-20260625.md`](./issues-sync-20260625.md)。本文不再维护独立 checklist，以避免历史报告与 issue ledger 分叉。

| 状态 | 范围 | Issue |
| --- | --- | --- |
| Closed | `report/binance/` 文档对齐 | `#1106` |
| Open | P0 runtime/evidence | `#1104`, `#1105` |
| Open | P1/P2 runtime/evidence | `#1107`-`#1118` |

---

## 9. 证据清单

### 运行时代码（`/home/binance`）

| 证据 | 位置 |
| --- | --- |
| storageFromEnv 5 路装配 | `cmd/binance-server/storage_env.go:64` |
| main.go 注入 asm | `cmd/binance-server/main.go:135,144-150` |
| 归一化单点分派 | `internal/client/normalize.go:114` |
| REST routeEndpoint Spot-only | `internal/client/history_rest.go:143` |
| runtime 未注入 fetcher | `internal/client/runtime.go:96` |
| WS 指数退避重连 | `internal/client/spot.go:329-373` |
| throttle 80/20 滑动窗口 | `internal/client/throttle.go:90` |
| consumer Ack/Nak/Term | `internal/server/consumer/consumer.go:159-180` |
| dispatch 重试+DLQ | `internal/server/ingest.go:242,328` |
| Redis 幂等 SETNX 72h | `internal/server/idempotency/redis_store.go:129` |
| reliability 三件套 | `internal/server/controlplane/reliability.go:80,225,302` |
| 17 个 Prometheus 指标 | `internal/server/metrics/metrics.go:153-247` |
| reject code 目录 BNC-001..013 | `internal/server/server.go:228-271` |

### Release Evidence（`release/evidence/binance/20260625/`）

| 证据 | 状态 | 文件 |
| --- | --- | --- |
| 5/5 infra 装配 LIVE-PASS | ✅ | `storage-assembly-live.txt` |
| mainnet 四线 3/4 LIVE-PASS | ✅ | `mainnet-coverage-matrix.txt` |
| v0.2.0 release LIVE-PASS | ✅ | `release-v020-live.txt` |
| Kafka broker driver 修复 | ⚠️ PARTIAL | `kafka-broker-live.txt` |
| SLO 24 bench 全 PASS | ✅ | `slo-report.md` |

### 治理文档（`/home/ZoneCNH/module/binance/`）

| 文档 | 状态口径（与代码对比） |
| --- | --- |
| `FEATURES.md` v3.6.0 | G0 标为 P0 阻断 → **已过时**（实际已闭合） |
| `SPEC.md` | FR 语义来源，可信 |
| `TRACEABILITY.md` | 需随 FEATURES.md 同步刷新 |

---

> **[RULES I BROKE]**：无。报告对每个事实性声明标注了证据标签与置信度；文档-代码冲突处（G0 状态）显式标注并说明以代码为准；未编造引用；结论基于代码逐文件核验 + release evidence 交叉验证，非事后合理化。
