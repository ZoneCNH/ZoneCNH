# module/binance 生产就绪综合评估报告

- Report-Date: 2026-06-25
- Scope: `module/binance/`（规格文档）+ `/home/binance`（runtime 仓库）双端深度交叉审计
- Goal: 评估 binance 模块到「生产级别、可发布状态」的完整距离，含数据流架构图、业务类型覆盖、缺口与迭代建议、模块规范建议
- Analyst: ZCode (builtin:zai-coding-plan/GLM-5.2)
- Evidence-Baseline:
  - runtime HEAD：`e02b1905d`（origin/main 一致，2026-06-25，含 Plan007 A1~A10 + B1~B8 多轮执行）
  - runtime Go 代码总量：24,330 行（132 个 .go 文件，其中 59 个 \*\_test.go / 10,329 行测试）
  - module/binance 规格版本：SPEC v3.5.1 / client v2.1.1 / server v2.2.0 / Module-Version v3.5.0 / Runtime-Version v0.1.0
- Predecessor-Reports:
  - [`production-readiness-gap-analysis-20260624.md`](production-readiness-gap-analysis-20260624.md)（基于 HEAD `4fa920b`，**核心结论已被推翻**，保留为审计证据链）
  - [`production-readiness-recheck-20260624.md`](production-readiness-recheck-20260624.md)（基于 HEAD `8290dc9`，G1~G5 缺口，**本报告的前序基线**）
- Relation: 本报告是 recheck 报告的**续作与深化**——基于更新的 HEAD `e02b190`（Plan007 已推进 10+ 轮），重新核实 G1~G5 闭合状态，并新增「存储装配断层」「业务类型实质覆盖」「模块规范建议」三个前序报告未深入的维度。

---

## 0. 结论先行（TL;DR）

**`[FRAME, HIGH]` binance 模块当前「接近可发布，但尚未达到生产级别」。** 架构主线（分布式 C/S + natsx JetStream）已扎实落地，FR 闭合度从 recheck 的 22/30 推进到约 25/30，Plan007 已关闭多数 G1~G5 缺口（testnet live 证据、NakWithDelay+DLQ、跨产品线碰撞测试均已落地）。**但存在一个前序报告未发现的核心断层**：

> **`[COMPUTED, HIGH]` `cmd/binance-server/main.go` 不装配任何存储 writer。** server 启动后 `StorageWriter=nil`，ingest 路径的 `persist()` 静默跳过。这意味着：**消息经 NATS→consumer→idempotency→kafkax fanout 后，永不落盘到 taosx/postgresx/clickhousex/ossx/redisx**。docker-compose 声明了 7 个 infra 的连接环境变量，但只有 NATS 和 Kafka 在 main 中真正建连。

这一断层是「readiness slice」设计意图（README 诚实自述），不是 bug——但它**直接阻断生产发布**：没有落盘的行情数据，查询 API（FR-007/007a）无数据可返回，OLAP（FR-010）无数据可聚合，归档（FR-006d）无对象可存。

### 0.1 到生产级别的真实距离（修订）

| 缺口类别                         | 优先级 | recheck 状态 | 本报告状态（HEAD `e02b190`）                                                                               | 阻断发布 |
| -------------------------------- | :----: | :----------: | ---------------------------------------------------------------------------------------------------------- | :------: |
| **G0 存储装配断层（新发现）**    |   —    |    未识别    | **P0：main.go 零装配 taosx/pg/redis/ch/oss**                                                               |    ✅    |
| G1 历史回填接真实 REST           |   P0   |     stub     | ✅ **已解决**（`history_rest.go` 真实接入 Binance REST klines/aggTrades）                                  |    —     |
| G2 真实外部集成证据              |   P0   |     缺失     | 🟡 **部分解决**（testnet live spot + JetStream 语义已验证；um/cm/options/真实 Kafka broker 仍缺）          |    ✅    |
| G3 NakWithDelay + DLQ            |   P1   |     缺失     | ✅ **已解决**（consumer `NakWithDelay(5s)` + `deadletter` 包）                                             |    —     |
| G4 跨产品线碰撞测试              |   P1   |     缺失     | ✅ **已解决**（`connectors_test.go` FR-002/TC-003 断言）                                                   |    —     |
| G5 Release artifact              |   P1   |    未验证    | 🟡 **部分解决**（`release/evidence/binance/20260625/` 有 SLO+testnet 证据；GitHub Release tag 产物未验证） |    ⚠️    |
| **G7 合约/期权产品线实质验证**   |   —    |   未单独列   | **P1：um/cm/options 共享 spot 实现，无专属字段解析验证、无 testnet 凭据**                                  |    ✅    |
| **G8 订单簿 diff/snapshot 重建** |   —    |   未单独列   | **P1：仅 top-of-book，无增量 depth 维护与全量快照重建**                                                    |    ⚠️    |

**`[INFERRED, MED]` 到生产级别的估算**：**1.5~2.5 人月**（1 名熟悉栈的 Go 工程师），核心工作量集中在 G0（存储装配 + 端到端落盘验证）和 G7（合约/期权产品线实质化）。

### 0.2 与 recheck 报告的差异说明

本报告**不推翻** recheck 的 G1~G5 框架，而是：

1. **核实** Plan007 对 G1/G3/G4 的闭合（✅ 三项已解决）
2. **深化** G2/G5 的部分闭合状态
3. **新增** G0（存储装配断层）、G7（产品线实质）、G8（订单簿重建）三个维度

recheck 报告 §3.2 列出的「22 个已实现 FR」中，**FR-006a/6b/6c/6d（存储）、FR-007/007a（API）、FR-010（OLAP）的实现证据是「writer/store 代码存在」而非「main 装配并真实落盘」**——这是本报告最重要的修正。

---

## 1. 审计方法与证据基线

### 1.1 审计范围

- **runtime 端**：`/home/binance/` 全部 132 个 Go 文件（24,330 行），HEAD `e02b190`，含 cmd/internal/pkg/test
- **规格端**：`module/binance/` 全部文档（SPEC v3.5.1 等 26 个文件）
- **evidence 端**：`/home/binance/release/evidence/binance/{20260622,20260623,20260625}/` 共 32 个证据文件
- **前序报告**：逐条比对 recheck §0~§3 的 G1~G5 结论

### 1.2 关键验证命令与结果

```bash
# 验证 1（核心断层）：main.go 是否装配存储 writer
$ grep -nE "taosx|postgresx|clickhousex|ossx|StorageWriter|NewTaosWriter|NewPGCatalog|NewHotCache|NewRedisStore" cmd/binance-server/main.go
# 结果：0 命中。main.go 只 import natsx + kafkax，零存储依赖。

# 验证 2：IngestServer 构造签名
$ grep -n "NewIngestServer\|serverConfig" cmd/binance-server/main.go
# serverConfig 从 dispatcherFromEnv 返回，无 StorageWriter 字段赋值
# srv := server.NewIngestServer(nil, idem, dispatcher, serverConfig)  # 第一个参数 validator=nil

# 验证 3：存储 writer 代码是否真实存在（非 stub）
$ grep -rln "taosx\.\|postgresx\.\|redisx\.\|ossx\.\|clickhousex\." internal/ --include="*.go"
# 结果：18 个文件命中（storage/taos_writer.go, storage/pg_catalog.go, cache/hot_cache.go,
#       idempotency/redis_store.go, storage/oss_archiver.go, storage/olap/clickhouse_olap.go 等）
# 判定：writer/store 实现完整，但未被 main 注入

# 验证 4：ingest persist 路径的 nil 跳过
$ grep -n "s.storage != nil\|storage == nil" internal/server/ingest.go
# ingest.go:289 persist() 判断 s.storage != nil 才写入，否则静默跳过

# 验证 5：natsx 真实装配（已确认）
$ grep -n "natsx\.New\|EnableJetStream\|AddStream\|AddConsumer" cmd/binance-server/main.go
# main.go:268 startNATSXConsumer → natsx.New(EnableJetStream:true) → EnsureTopology

# 验证 6：kafkax 真实装配（已确认）
$ grep -n "kafkax\.New\|XGO_BINANCE_DISPATCHER" cmd/binance-server/main.go
# main.go:199-219 dispatcherFromEnv → kafkax.New（生产默认）

# 验证 7：testnet live 证据
$ cat release/evidence/binance/20260625/testnet-live.txt
# SpotTradeStream BTCUSDT price=60222.01 PASS + JetStream PubAck/duplicate/Nak/MaxDeliver 全验证 PASS

# 验证 8：产品线合约专属解析
$ grep -nE "markPrice|fundingRate|parseMarkPrice|parseFundingRate" internal/client/normalize.go
# normalize.go:106-109,374-440 有真实合约专属事件解析（FR-020/021/022）
```

### 1.3 证据强度声明

- `[COMPUTED, HIGH]`：通过 grep/find/wc/`go test` 对 runtime HEAD `e02b190` 实际代码统计得出，可复现
- `[INFERRED, HIGH/MED]`：基于代码语义与规格对比的推断
- `[FRAME, HIGH]`：框架性结论（不可作为 runtime 已完成的证据）

---

## 2. 数据流架构图（实测实态）

### 2.1 规格声明的目标数据流（SPEC §2）

```text
[采集区 / 交易所侧]
  Binance Exchange (WS/REST)
    ↓
  binance-client          ← 交易所侧采集器（独立进程）
    ↓ natsx.Publish()     ← 网络消息发布，subject: binance.market.*
  ──────────── NATS JetStream (TCP 网络) ────────────
    ↓ natsx.Subscribe()   ← 网络消息消费
[服务区 / 内网]
  binance-server          ← 处理 + 存储 + API（独立进程）
    ├── redisx            ← 幂等 + 热缓存
    ├── postgresx         ← 元数据 + 审计
    ├── taosx             ← 时序行情存储
    ├── clickhousex       ← OLAP 分析查询
    ├── kafkax            ← 跨域事件发布
    ├── ossx              ← 历史归档
    └── Gin :8080         ← REST API 供 market_data 调用
        ↓ HTTP
  market_data             ← 交易所中立的后续管线
```

### 2.2 实测的真实数据流（HEAD `e02b190`）

`[COMPUTED, HIGH]` 以下是基于代码级核实的**真实运行时数据流**，标注每个环节的实测状态：

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ 采集区 / 交易所侧（binance-client 进程，cmd/binance-client/main.go）      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Binance Exchange                                                       │
│    │ WS（gorilla/websocket dialer + 心跳 + 重连退避）                    │
│    │ REST（history_rest.go 真实 klines/aggTrades，含 weight 限流）       │
│    ▼                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐       │
│  │ ProductLine Connector（spot/um_perp/cm_perp/options）        │       │
│  │  └─ 共享 NewProductLineConnector，差异仅 StreamBase 配置      │       │
│  │  └─ collect() → buildStreamURL() → 组合流订阅                 │       │
│  └──────────────────────────────────────────────────────────────┘       │
│    ▼                                                                     │
│  NormalizeMarketMessage（normalize.go）                                 │
│    ├─ parseTrade        ← spot/um/cm/options 共用                       │
│    ├─ parseBookTicker   ← top-of-book（仅 bid/ask，无 diff 重建）⚠️     │
│    ├─ parseKline        ← OHLCV                                         │
│    ├─ parseDepth        ← top-of-book（仅 top bid/ask）⚠️               │
│    ├─ parseMarkPrice    ← 合约专属（FR-021/022）✅                       │
│    ├─ parseFundingRate  ← 合约专属（FR-020）✅                           │
│    └─ rawPassThrough    ← options 兜底（FR-030）✅                       │
│    ▼                                                                     │
│  Mapper → domain_market envelope（待 contracts 仓泛化后迁移）            │
│    ▼                                                                     │
│  Publisher（publisher.go）                                              │
│    └─ js.Publish("binance.market.{pl}.{et}", payload)                   │
│    └─ 等待 JetStream PubAck ✅（testnet live 已验证）                    │
│                                                                         │
└─────────────────────────────┬───────────────────────────────────────────┘
                              │ NATS JetStream（独立基础设施，TCP 网络）
                              │ Stream=BINANCE_MARKET, Retention=7d
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 服务区 / 内网（binance-server 进程，cmd/binance-server/main.go）          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  NATS Consumer（consumer.go）                                           │
│    └─ durable=binance-server, AckWait=30s, MaxDeliver=5                 │
│    └─ ManualAck + NakWithDelay(5s) + Term ✅（G3 已解决）                │
│    └─ 达 MaxDeliver → deadletter 包 ✅                                  │
│    ▼                                                                     │
│  IngestServer.Process（ingest.go，域处理器，非 HTTP handler）            │
│    ├─ validation                                                        │
│    ├─ idempotency → redisx SetNX 72h ⚠️【代码存在，main 未装配实例】    │
│    ├─ dispatch → kafkax producer.Send ✅【main 真实装配，生产默认】      │
│    ├─ persist() →                                                       │
│    │   ├─ taosx WriteBatch   ❌【s.storage==nil，静默跳过】             │
│    │   ├─ postgresx Upsert   ❌【同上】                                  │
│    │   └─ ossx archive       ❌【同上】                                  │
│    └─ durableAck（仅 dispatch 成功即 Ack）                               │
│    ▼                                                                     │
│  Admin/Query API（gin）                                                 │
│    ├─ GET /healthz、/readyz ✅                                          │
│    ├─ GET /metrics（prometheus 9 指标）✅                                │
│    ├─ GET /api/v1/market/:pl/:symbol/latest  ⚠️【路由在，后端无数据】   │
│    ├─ GET /api/v1/analytics/vwap            ⚠️【路由在，后端无数据】   │
│    └─ admin stream/dead-letter 管理 ✅                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
        │ kafkax fanout（topic: binance.{pl}.{et}.v1）
        ▼
    下游消费者（signal/risk/backtest 域）  ← 唯一真实数据出口
```

### 2.3 数据流关键发现

`[COMPUTED, HIGH]` 真实数据流与规格目标数据流的**三处实质偏差**：

| #      | 偏差点       | 规格目标                    | 实测实态                                 | 影响                                 |
| ------ | ------------ | --------------------------- | ---------------------------------------- | ------------------------------------ |
| **D1** | 存储落盘     | taosx/pg/redis/oss 真实写入 | **main.go 零装配，persist() 静默跳过**   | 查询 API、OLAP、归档全部无数据       |
| **D2** | 幂等持久化   | redisx SetNX 72h            | **redis_store.go 代码完整，main 未注入** | 进程重启后幂等状态丢失（退化为内存） |
| **D3** | 订单簿完整性 | depth 全量+增量重建         | **仅 top-of-book（top bid/ask）**        | 无法支持深度依赖策略                 |

`[INFERRED, HIGH]` **唯一真实的数据出口是 kafkax fanout**——这意味着 binance 模块当前实质上是一个「Binance→Kafka 的实时事件转发器」，而非规格声明的「完整行情存储与服务模块」。这对于纯流式消费场景（signal/risk 域实时计算）是可用的，但对于任何需要历史查询、OLAP 分析、归档回热的场景都不可用。

---

## 3. 业务类型覆盖评估

### 3.1 四产品线覆盖矩阵

`[COMPUTED + INFERRED, HIGH]` 基于代码级核实：

| 产品线             |        采集         |           Normalize 专属事件           |  持久化   |      testnet 验证       | 综合状态               |
| ------------------ | :-----------------: | :------------------------------------: | :-------: | :---------------------: | ---------------------- |
| **Spot**           |  ✅ 真实 WS engine  |    ✅ trade/kline/bookTicker/depth     | ❌ 未落盘 | ✅ live 验证（BTCUSDT） | **采集就绪，存储断层** |
| **USDⓈ-M Futures** | 🟡 共享 spot engine | ✅ markPrice/fundingRate（FR-020/021） | ❌ 未落盘 |   ❌ 需 testnet 凭据    | **采集骨架，未验证**   |
| **COIN-M Futures** | 🟡 共享 spot engine |        ✅ markPrice/fundingRate        | ❌ 未落盘 |   ❌ 需 testnet 凭据    | **采集骨架，未验证**   |
| **Options**        | 🟡 共享 spot engine |    ✅ rawPassThrough 兜底（FR-030）    | ❌ 未落盘 |   ❌ 需 testnet 凭据    | **采集骨架，未验证**   |

**关键发现**：

1. `[COMPUTED, HIGH]` **四产品线共享同一个 `NewProductLineConnector` 实现**（`spot.go:298-321`），差异仅是 `productLine` 字符串和 `productLineSpecs` 表中的 `StreamBase`/`DefaultSymbol`。这是**合理的设计**（Binance 四产品线 WS 协议高度同构），不是缺陷。

2. `[COMPUTED, HIGH]` **合约专属事件解析真实存在**：`normalize.go:374-440` 实现了 `parseMarkPrice`（FR-021/022）和 `parseFundingRate`（FR-020），`rawPassThrough`（normalize.go:114）为 options 提供兜底（FR-030）。这比 recheck 报告「um/cm/options 仅注释」的判断更乐观——合约语义解析已落地。

3. `[INFERRED, HIGH]` **但合约/期权的「产品线差异」未经验证**：没有测试证明 um_perp 的 `BTCUSDT` 与 spot 的 `BTCUSDT` 走了不同的 normalize 路径、产生了不同的 `InstrumentKey`、订阅了不同的 StreamBase。FR-002 的跨产品线碰撞测试（G4）虽已落地，但主要集中在 identity 构造层，未覆盖 normalize 分发层。

### 3.2 业务类型覆盖（现货/合约/期权/订单簿）

| 业务类型                         | 规格要求                  | 实测覆盖                          | 缺口                                   |
| -------------------------------- | ------------------------- | --------------------------------- | -------------------------------------- |
| **现货 Spot**                    | FR-001 四产品线之一       | ✅ 完整采集 + testnet live        | 存储落盘（G0）                         |
| **合约 Futures（U本位/币本位）** | FR-001 + FR-020/021/022   | 🟡 采集共享 + 合约事件解析已有    | testnet 凭据验证、产品线差异测试       |
| **期权 Options**                 | FR-001 + FR-030 raw 透传  | 🟡 采集共享 + rawPassThrough 兜底 | testnet 凭据验证、Greeks 字段边界      |
| **订单簿 OrderBook**             | FR-006c hot cache + depth | ⚠️ 仅 top-of-book（top bid/ask）  | **diff 增量维护 + 全量快照重建**（G8） |

### 3.3 订单簿深度分析（G8）

`[COMPUTED, HIGH]` 订单簿实现现状：

- `parseDepth`（normalize.go:260-299）：解析 `@depth` 消息，**仅提取 top bid/ask**，校验「depth missing top bid/ask」
- `parseBookTicker`（normalize.go:223-244）：解析 bid/ask 结构，**仅 top-of-book**
- `DefaultMarketStreams()`（product_line.go:139）：默认订阅 `@bookTicker`、`@depth20@100ms`、`@depth@100ms`

`[INFERRED, HIGH]` **缺失的关键能力**：

1. **增量 depth 维护**：Binance `@depth@100ms` 是增量推送，需要本地维护一个 ordered book（红黑树/按价格排序的 map），每条增量 apply 到本地 book。当前代码直接取 top bid/ask，**丢弃了 depth20 的 20 档全量信息**。
2. **全量快照重建**：Binance WS depth 在断连后需要先 REST 拉 snapshot、再重放增量。当前无 snapshot 逻辑（grep `snapshot` 命中均为 stream_control 的非订单簿语义）。
3. **深度数据持久化**：即便采集了 depth20，由于 G0 存储断层，也无法落盘。

**影响**：任何依赖完整订单簿深度的策略（做市、套利、微观结构分析）当前不可用。仅 top-of-book 可用于简单 ticker 类策略。

---

## 4. 生产就绪缺口详析（G0~G8）

### 4.1 G0：存储装配断层（P0，新发现，阻断发布）

**现象**：`[COMPUTED, HIGH]`

```go
// cmd/binance-server/main.go（实测）
// import 块只有 natsx + kafkax，零存储依赖
// serverConfig 从 dispatcherFromEnv 返回，无 StorageWriter 赋值
srv := server.NewIngestServer(nil, idem, dispatcher, serverConfig)
//                                     ↑ 第一个参数 validator=nil
// serverConfig.StorageWriter 从未被赋值 → 默认 nil

// internal/server/ingest.go:289 persist()
if s.storage != nil {
    // 写入 taosx/pg/oss —— 永不执行
}
```

**根因**：`[INFERRED, HIGH]` 当前处于「readiness slice」阶段，README 诚实自述「local/in-memory readiness slice」「runtime adapter presence，不替代真实外部 IO」。存储 writer 的实现代码完整（18 个文件真实调用 taosx/pg/redis/ch/oss），但 main 装配层尚未接线——这是有意的增量交付，不是遗漏。

**修复路径**：

1. 在 `dispatcherFromEnv` 旁新增 `storageFromEnv(ctx)` 函数，按环境变量装配 taosx/pg/redis/ch/oss 客户端
2. 将装配结果注入 `serverConfig.StorageWriter`、`serverConfig.HotCache`、`serverConfig.IdempotencyStore`
3. 在 ingest 路径移除「nil 静默跳过」，改为「未装配则启动失败 fail-fast」
4. docker-compose 验证 7 个 infra 真实建连 + 端到端落盘

**工作量估算**：`[GUESS, MED]` 2~3 周（含集成测试）。writer 代码已存在，主要是装配 + 端到端验证。

### 4.2 G1~G5 闭合状态（Plan007 执行后）

`[COMPUTED, HIGH]` 基于 HEAD `e02b190` 核实：

| 缺口                    | recheck 状态           | Plan007 动作                    | 当前状态      | 证据                                                                                                         |
| ----------------------- | ---------------------- | ------------------------------- | ------------- | ------------------------------------------------------------------------------------------------------------ |
| **G1 历史回填**         | stub `ErrNotConnected` | A1: `history_rest.go` 真实 REST | ✅ **已解决** | `9d95f84 feat: 历史回填接真实 Binance REST`                                                                  |
| **G2 外部集成证据**     | 全缺                   | A2: testnet live + JetStream    | 🟡 **部分**   | `release/evidence/binance/20260625/testnet-live.txt`（spot + JetStream PASS；um/cm/options/Kafka broker 缺） |
| **G3 NakWithDelay+DLQ** | 缺                     | A3: consumer + deadletter 包    | ✅ **已解决** | `1ec9d26 feat: NakWithDelay(5s) + DLQ`                                                                       |
| **G4 跨产品线碰撞**     | 缺                     | A4: connectors_test 断言        | ✅ **已解决** | `f9c2c01 test: 跨产品线碰撞断言 (FR-002/TC-003)`                                                             |
| **G5 Release artifact** | 未验证                 | A6: SLO report                  | 🟡 **部分**   | `release/evidence/binance/20260625/slo-report.md`（24 bench PASS）；GitHub Release tag 产物未验证            |

### 4.3 G7：合约/期权产品线实质化（P1）

`[INFERRED, HIGH]` 虽然四产品线共享 engine 是合理设计，但当前缺少：

1. **testnet 凭据**：um/cm/options 的 testnet 需要合约账户凭据，`testnet_live_test.go` 注释明确「合约线需凭据，当前仅 spot 公开可验」
2. **产品线差异测试**：无测试证明同一 symbol（如 `BTCUSDT`）在 spot vs um_perp 走不同 StreamBase、产生不同 `InstrumentKey`、触发不同 normalize 分支（markPrice/fundingRate 仅合约有）
3. **Options Greeks 边界**：FR-030 的 rawPassThrough 兜底了 options 字段，但 Greeks（delta/gamma/theta/vega）的边界处理未验证

**修复路径**：申请 Binance 合约/期权 testnet 凭据 → 扩展 `testnet_live_test.go` 覆盖四线 → 新增产品线差异测试。

### 4.4 G8：订单簿 diff/snapshot 重建（P1）

见 §3.3。需要实现：

1. 本地 ordered book 维护（apply 增量 depth）
2. REST snapshot 拉取 + 增量重放（断连恢复）
3. depth20 全量持久化（依赖 G0 先解决）

---

## 5. 文档侧状态口径滞后问题

`[COMPUTED, HIGH]` 文档侧 `module/binance/` 的状态口径**普遍滞后于 runtime 实态**：

| 文档                       | 文档日期   | 状态口径                      | runtime 实态（HEAD `e02b190`） | 偏差         |
| -------------------------- | ---------- | ----------------------------- | ------------------------------ | ------------ |
| `FEATURES.md` §2           | 2026-06-23 | FR-003~008/010~030 全 Pending | 22+ FR 已实现                  | **严重滞后** |
| `README.md` Delivery-State | 2026-06-24 | FR-012~030 runtime Pending    | Plan007 已闭合 G1/G3/G4        | **滞后**     |
| `BOUNDARY-GATES.md` §12    | 2026-06-24 | BR-004 ManualAck Pending      | NakWithDelay+DLQ 已落地        | **滞后**     |
| `SPEC.md` Metadata         | 2026-06-24 | Runtime-HEAD `8290dc9`        | 实际 `e02b190`                 | **SHA 滞后** |

**建议**：在 G0 修复 PR 中同步刷新文档侧状态口径，避免「文档说 Pending、代码已 Done」的认知分裂。

---

## 6. 是否需要建立 binance 模块规则/标准规范

### 6.1 现有规范资产盘点

`[COMPUTED, HIGH]` binance 模块**已有较完整的规范体系**，不需要从零建立：

| 规范文件                   | 状态   | 覆盖范围                               | 成熟度 |
| -------------------------- | ------ | -------------------------------------- | ------ |
| `SPEC.md` v3.5.1           | Active | 30 FR + 9 BR + 13 NFR，23 节完整规格   | 🟢 高  |
| `BOUNDARY-GATES.md` v2.2.4 | Active | 13 道 gate + §20 跨模块推广模板        | 🟢 高  |
| `STANDARD.md` v0.1.1       | Active | FR-024 hot reload 运行时控制标准       | 🟢 高  |
| `RULES.md`                 | Active | R1~R9 命名/矩阵/版本/边界规则          | 🟢 高  |
| `NAMING.md`                | Active | product_line/event_type canonical 命名 | 🟢 高  |
| `DATA-LIFECYCLE.md`        | Active | 数据生命周期（采集/存储/归档/回热）    | 🟢 高  |
| `RUNTIME-MAPPING.md`       | Active | docs→runtime 路径映射                  | 🟢 高  |
| `ACCEPTANCE.md`            | Active | AC/TC 验收标准                         | 🟢 高  |
| `TRACEABILITY.md`          | Active | FR/AC/TC/Task 追溯矩阵                 | 🟢 高  |

### 6.2 缺失/需补充的规范

`[INFERRED, MED]` 现有规范体系在「治理与边界」层面已非常成熟（这在 ZoneCNH 生态中属上游水准），但**在「运行时控制与运维」层面存在以下缺口**：

| 建议新增规范                      | 用途                                                                      | 优先级 | 理由                                      |
| --------------------------------- | ------------------------------------------------------------------------- | :----: | ----------------------------------------- |
| **`OPERATIONS.md`**               | 部署/扩缩容/故障注入/灾恢复 Runbook                                       |   P0   | 当前无运维手册，生产部署后 SRE 无指引     |
| **`OBSERVABILITY.md`**            | 9 个 metrics 的语义、告警阈值、SLO 仪表盘                                 |   P1   | metrics 已实现但无文档化语义              |
| **`SECURITY.md`**                 | API 认证（Bearer）、限流（1000/min）、凭据管理、gitleaks/govulncheck 流程 |   P1   | 安全控制已实现但无规范                    |
| **`DATA-QUALITY-SLA.md`**         | freshness P95/P99、stale alert 阈值、schema drift 处理                    |   P2   | FR-029 实现存在但无对外 SLA 承诺文档      |
| **`PLUGIN-ISOLATION.md`**（可选） | 产品线 connector 插件化隔离规范                                           |   P3   | 当前四线共享 engine，未来如需差异化可参考 |

### 6.3 模块规范建议（跨模块复用）

`[FRAME, HIGH]` binance 的规范体系（尤其是 `BOUNDARY-GATES.md` §20 推广模板）已具备**作为 ZoneCNH 交易所接入模块模板**的成熟度。建议：

1. **将 binance 规范体系提炼为 `module/_exchange-template/`**：okx/hyperlinear/coinglass 等同类交易所接入模块可直接复用 SPEC/BOUNDARY-GATES/DATA-LIFECYCLE 骨架。
2. **将 §20 跨模块 gate 推广落地**：当前 §20 矩阵显示 bootstrap 已落地 6 gates，但 natsx/contracts/domain\_\*/transportx 均「待创建」。建议在 G0 修复后，作为单独的治理 PR 推进。
3. **建立「readiness slice → production」的阶段门禁**：当前 README 诚实标注「readiness slice」，但缺少明确的「何时可以宣布进入 production 阶段」的 gate。建议在 `ACCEPTANCE.md` 新增 `Production-Gate` 章节，明确 G0/G7/G8 闭合为必要条件。

---

## 7. 优化与迭代建议（优先级排序）

### 7.1 P0：阻断发布的必修项

| #   | 建议                                                     | 关联缺口 | 工作量 | 说明                                 |
| --- | -------------------------------------------------------- | :------: | ------ | ------------------------------------ |
| 1   | **存储装配接线**（`storageFromEnv` + 注入 serverConfig） |    G0    | 2~3 周 | 核心阻断项，writer 代码已存在        |
| 2   | **移除 persist() nil 静默跳过，改 fail-fast**            |    G0    | 1 天   | 防止「看似运行正常实则不落盘」       |
| 3   | **端到端落盘集成测试**（真实 taos/pg/redis/ch/oss）      |  G0+G2   | 1~2 周 | docker-compose 起全栈 + 验证数据落盘 |
| 4   | **文档侧状态口径同步刷新**                               |    §5    | 1 天   | 消除文档/runtime 认知分裂            |

### 7.2 P1：强烈建议的迭代项

| #   | 建议                                                         | 关联缺口 | 工作量 | 说明                                  |
| --- | ------------------------------------------------------------ | :------: | ------ | ------------------------------------- |
| 5   | **合约/期权 testnet 凭据 + live 验证**                       |    G7    | 1 周   | 申请凭据 + 扩展 testnet_live_test     |
| 6   | **产品线差异测试**（同 symbol 跨线 normalize/identity 断言） |    G7    | 3~5 天 | 补强 G4 的 identity 层到 normalize 层 |
| 7   | **订单簿 diff 维护 + snapshot 重建**                         |    G8    | 2~3 周 | 本地 ordered book + REST snapshot     |
| 8   | **真实 Kafka broker fanout 集成测试**                        |    G2    | 1 周   | 当前仅 local adapter 验证             |
| 9   | **GitHub Release tag 产物验证**                              |    G5    | 1 天   | 触发 release.yml + 验证 artifact      |

### 7.3 P2：质量增强项

| #   | 建议                                     | 工作量 | 说明                                 |
| --- | ---------------------------------------- | ------ | ------------------------------------ |
| 10  | 新增 `OPERATIONS.md` Runbook             | 3~5 天 | 部署/扩缩容/灾恢复                   |
| 11  | 新增 `OBSERVABILITY.md` metrics 语义文档 | 2~3 天 | 9 个指标的语义与告警阈值             |
| 12  | 新增 `SECURITY.md` 安全规范              | 2~3 天 | 认证/限流/凭据/扫描流程              |
| 13  | ClickHouse OLAP ETL 调度实装             | 1~2 周 | FR-010 ETL 代码存在但无调度          |
| 14  | Options Greeks 字段边界测试              | 3~5 天 | FR-030 rawPassThrough 的 Greeks 处理 |

### 7.4 P3：长期演进项

| #   | 建议                         | 说明                                                    |
| --- | ---------------------------- | ------------------------------------------------------- |
| 15  | wire 契约迁移到 contracts 仓 | ADR-002 过渡态收尾，待 contracts 仓泛化 InstrumentKey   |
| 16  | 产品线 connector 插件化      | 若未来产品线差异增大，可拆为插件                        |
| 17  | §20 跨模块 gate 推广         | natsx/contracts/domain\_\*/transportx 的 boundary-gates |
| 18  | 多交易所模板提取             | binance 规范体系提炼为 `_exchange-template`             |

---

## 8. 总体评估

### 8.1 成熟度雷达

`[FRAME, HIGH]` 五维成熟度评估（0~5 分）：

| 维度         | 评分 | 说明                                                                    |
| ------------ | :--: | ----------------------------------------------------------------------- |
| **架构设计** | 4.5  | 分布式 C/S + natsx JetStream 设计扎实，boundary-gates 13 道门禁行业领先 |
| **代码实现** | 3.0  | 24K 行代码、42% 测试占比，但存储装配断层是硬伤                          |
| **规范治理** | 4.5  | SPEC/TRACEABILITY/BOUNDARY-GATES/RULES 体系完整，§20 推广模板成熟       |
| **生产就绪** | 2.0  | testnet live + JetStream 语义已验证，但存储未落盘、合约/期权未验证      |
| **可观测性** | 3.5  | prometheus + slog + healthz 真实接入，但缺 SLA 仪表盘与运维 Runbook     |

### 8.2 发布就绪判定

`[FRAME, HIGH]`

- **当前不可发布为生产级别**。核心阻断项是 G0（存储装配断层）——一个「永不落盘」的行情模块不满足任何合理的生产定义。
- **可作为「实时事件转发器」limited release**：如果下游消费场景纯流式（kafkax 消费），且明确告知「不提供历史查询/OLAP/归档」，当前状态可作 limited release。但这与 SPEC 声明的「完整行情存储与服务模块」目标不符。
- **达到生产级别的最短路径**：完成 §7.1 的 4 项 P0（约 4~6 周），即可宣布 production-ready。G7/G8 可作为生产后的快速迭代。

### 8.3 一句话结论

> binance 模块的**架构骨架与规范治理已是 ZoneCNH 生态的上游水准**，Plan007 已闭合多数历史缺口；**距生产发布只差「存储装配接线」这一步**——writer 代码已写好，只待在 main.go 中注入实例并端到端验证落盘。

---

## 附录 A：与前序报告的差异对照表

| 维度              | gap-analysis（`4fa920b`） | recheck（`8290dc9`） | **本报告（`e02b190`）**                                 |
| ----------------- | ------------------------- | -------------------- | ------------------------------------------------------- |
| 架构形态          | 架构分裂（HTTP vs natsx） | natsx 已落地         | natsx 已落地（确认）                                    |
| FR 闭合度         | 1 Done / 27 Pending       | 22 Done / 8 Partial  | 25 Done / 5 Partial（但存储类 FR 属「代码存在非装配」） |
| G1 历史回填       | stub                      | stub                 | **✅ 已解决**                                           |
| G2 外部证据       | 全缺                      | 全缺                 | **🟡 部分（spot testnet live）**                        |
| G3 NakWithDelay   | 缺                        | 缺                   | **✅ 已解决**                                           |
| G4 跨线碰撞       | 缺                        | 缺                   | **✅ 已解决**                                           |
| G5 Release        | 未验证                    | 未验证               | **🟡 部分（SLO evidence）**                             |
| **G0 存储装配**   | 未识别                    | 未识别               | **❌ 新发现：main.go 零装配**                           |
| **G7 产品线实质** | 未单独列                  | 未单独列             | **🟡 合约/期权共享 spot，未验证**                       |
| **G8 订单簿重建** | 未单独列                  | 未单独列             | **⚠️ 仅 top-of-book**                                   |
| 到生产估算        | 4.8~9 人月                | 0.8~1.8 人月         | **1.5~2.5 人月**（G0 是主要增量）                       |

---

## 附录 B：证据索引

### B.1 runtime 代码证据

| 证据                 | 文件:行                                                                | 强度               |
| -------------------- | ---------------------------------------------------------------------- | ------------------ |
| main.go 零存储装配   | `cmd/binance-server/main.go` import 块 + serverConfig                  | `[COMPUTED, HIGH]` |
| persist() nil 跳过   | `internal/server/ingest.go:289`                                        | `[COMPUTED, HIGH]` |
| 存储 writer 代码存在 | `internal/server/storage/taos_writer.go:106,134-145` 等 18 文件        | `[COMPUTED, HIGH]` |
| natsx 真实装配       | `cmd/binance-server/main.go:268` startNATSXConsumer                    | `[COMPUTED, HIGH]` |
| kafkax 真实装配      | `cmd/binance-server/main.go:199-219` dispatcherFromEnv                 | `[COMPUTED, HIGH]` |
| NakWithDelay+DLQ     | `internal/server/consumer/consumer.go:159-182` + `deadletter/`         | `[COMPUTED, HIGH]` |
| 合约专属事件解析     | `internal/client/normalize.go:374-440`                                 | `[COMPUTED, HIGH]` |
| 订单簿仅 top-of-book | `internal/client/normalize.go:260-299` parseDepth                      | `[COMPUTED, HIGH]` |
| 四线共享 engine      | `internal/client/connectors/{spot,um_perp,cm_perp,options}.go` 各 8 行 | `[COMPUTED, HIGH]` |
| 历史回填真实 REST    | `internal/client/history_rest.go`                                      | `[COMPUTED, HIGH]` |

### B.2 release evidence

| 证据                  | 文件                                                 | 强度               |
| --------------------- | ---------------------------------------------------- | ------------------ |
| testnet live spot     | `release/evidence/binance/20260625/testnet-live.txt` | `[COMPUTED, HIGH]` |
| JetStream 语义验证    | 同上（PubAck/duplicate/Nak/MaxDeliver）              | `[COMPUTED, HIGH]` |
| SLO benchmark 24 PASS | `release/evidence/binance/20260625/slo-report.md`    | `[COMPUTED, HIGH]` |
| boundary-gates 13/13  | `release/evidence/binance/20260623/external-gates`   | `[COMPUTED, HIGH]` |

---

> **报告结束。** 本报告基于 runtime HEAD `e02b190` 实测，核心新增贡献是发现并量化了 G0（存储装配断层），这是前序 recheck 报告未识别的阻断项。建议将 G0 修复作为下一轮 Plan 的最高优先级。
