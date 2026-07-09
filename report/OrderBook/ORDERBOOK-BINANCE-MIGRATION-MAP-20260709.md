# Binance OrderBook 迁移映射草案

> 日期：2026-07-09
> 状态：Draft / 非正式迁移图
> 目标：把 binance 当前 OrderBook runtime 拆成“通用候选”“Binance adapter 保留”“暂不迁移”“前置硬化”四类
> 约束：本文不迁移代码，不创建 runtime repo

---

## 0. 迁移原则

不得 big-bang rewrite。[FRAME, HIGH]

binance 当前实现先作为首个 conformance target，而不是直接复制成 `orderbook` 模块。[FRAME, HIGH]

通用代码迁移前必须先完成 Contract/Gate、Replay fixture 和 Boundary Gate。[FRAME, HIGH]

任何依赖 Binance REST/WS 私有语义的代码必须保留在 binance adapter 层。[FRAME, HIGH]

---

## 1. 文件映射

| Binance 文件 | 当前职责 | 迁移分类 | 候选目标 | 说明 |
| --- | --- | --- | --- | --- |
| `internal/client/orderbook/state.go` | 4 状态枚举与转换矩阵。[COMPUTED, HIGH] | 通用候选 | `pkg/sync/state.go` | 可扩展为对外 10 状态语义。[INFERRED, HIGH] |
| `internal/client/orderbook/book.go` | Book、BookLevel、Snapshot、TopN、mutation。[COMPUTED, HIGH] | 通用候选 | `pkg/builder/book.go` | 需替换 float price key 为 decimal canonical rule。[INFERRED, HIGH] |
| `internal/client/orderbook/align.go` | snapshot + buffer 9 步对齐、sequence validation。[COMPUTED, HIGH] | 拆分迁移 | `pkg/sync/align.go` + adapter `SequencePolicy` | Binance U/u/pu 规则必须下沉到 adapter policy。[FRAME, HIGH] |
| `internal/client/orderbook/manager.go` | per-symbol manager、dispatch、TopN、incremental、rebuild。[COMPUTED, HIGH] | 部分通用 | `pkg/sync/manager.go` | 当前混合 manager、publish、feature/depth policy，需拆分。[INFERRED, HIGH] |
| `internal/client/orderbook/rest.go` | RESTSnapshot、SnapshotFetcher、DepthMode。[COMPUTED, HIGH] | contract 候选 | `pkg/adapter/snapshot.go` | `SnapshotFetcher` 可演进为 `SnapshotLoader`。[FRAME, HIGH] |
| `internal/client/orderbook/topn.go` | TopNUpdate、IncrementalEvent。[COMPUTED, HIGH] | schema 输入 | `pkg/event/book_event.go` | 不应把 TopNUpdate 当作唯一通用 schema。[INFERRED, HIGH] |
| `internal/client/orderbook/persist.go` | FilePersistor、persist loop、fast recovery。[COMPUTED, HIGH] | 暂不首迁 | `pkg/storage` 或 adapter | 首版 contract 可先只定义 evidence/replay fixture。[INFERRED, MED] |
| `internal/client/orderbook/health.go` | HealthMonitor、checksum sample、drift detection。[COMPUTED, HIGH] | 通用候选 | `pkg/quality/health.go` | REST diff sampling 的 fetcher 仍属 adapter 注入。[FRAME, HIGH] |
| `internal/client/runtime.go` | OrderBookManager 装配、白名单同步、NATS consumer。[COMPUTED, HIGH] | Binance 保留 | binance runtime | 控制面和 NATS 转发不进通用 core。[FRAME, HIGH] |
| `internal/client/admin.go` | health/snapshot admin handler。[COMPUTED, HIGH] | Binance 保留 | binance runtime | API 形态属于 binance 进程控制面。[FRAME, HIGH] |
| `pkg/whitelistclient/*` | whitelist, StreamType, DepthLevel, Capability。[COMPUTED, HIGH] | Binance 保留 / 输入 | future resource policy | 不应直接迁移为 orderbook PolicyManager。[INFERRED, HIGH] |
| `internal/client/stream_control.go` | stream URL、stream config、connector control。[COMPUTED, HIGH] | 前置硬化 | binance runtime | combined stream 分片先在 binance 修。[FRAME, HIGH] |

---

## 2. 迁移阶段

### Phase M0：前置硬化

必须先完成 combined stream shard planner、DepthLevel/StreamType/Capability 语义回归、options depth 口径和 replay fixture input。[FRAME, HIGH]

交付物见 `ORDERBOOK-BINANCE-PHASE1-HARDENING-PLAN-20260709.md`。[COMPUTED, HIGH]

### Phase M1：Contract extraction

只抽 contract，不迁移 runtime。[FRAME, HIGH]

候选内容：

```text
SnapshotLoader
DiffSubscriber
SequencePolicy
ExchangeSemantics
Snapshot
DiffEvent
SequenceResult
AlignResult
```

验收：Binance adapter 能以 wrapper 形式满足 contract，但现有 runtime 仍在 binance 内运行。[FRAME, HIGH]

### Phase M2：Fixture and gate extraction

先建立 fixture 和 gate，再迁移 core。[FRAME, HIGH]

候选内容：

```text
snapshot_fixture.json
diff_fixture.json
gap_fixture.json
expected_book_hash.json
expected_quality_timeline.json
```

验收：同一 fixture 可在 binance 当前实现和 future orderbook core 中复用。[FRAME, HIGH]

### Phase M3：Builder / BookHash extraction

迁移 BookBuilder、mutation、BookHash canonicalization。[FRAME, HIGH]

阻断条件：若 price canonicalization 仍依赖 float parse，必须先修正为 decimal canonical rule。[INFERRED, HIGH]

### Phase M4：Sync manager extraction

迁移对齐、gap、rebuild、state manager 的通用部分。[FRAME, HIGH]

Binance `SequencePolicy`、REST snapshot loader、WS diff subscriber 留在 binance adapter。[FRAME, HIGH]

### Phase M5：Output compatibility bridge

binance 继续输出当前 NATS/Kafka contract，同时内部调用 orderbook core。[FRAME, HIGH]

验收：binance FR-052~061 既有验收不回退。[FRAME, HIGH]

---

## 3. 保留在 Binance 的职责

Binance REST endpoint、WS stream suffix、spot/UM/CM/options 产品线差异必须保留在 binance adapter。[FRAME, HIGH]

白名单 server API、NATS 版本推送、catalog/exchangeInfo 控制面必须保留在 binance。[COMPUTED, HIGH]

`OrderbookFeatures`、`StreamType`、`DepthLevel` 和 tier Capability 可作为资源治理输入，但不应原样变成 `orderbook` 的全局 PolicyManager。[INFERRED, HIGH]

combined stream sharding 应先在 binance 修复，再决定是否抽象为通用 venue stream planner。[INFERRED, HIGH]

---

## 4. 首批不迁移项

| 不迁移项 | 原因 |
| --- | --- |
| NATS/Kafka publishing | 发布拓扑属于 binance runtime 和下游 contract。[FRAME, HIGH] |
| admin HTTP handlers | 进程控制面，不是 core orderbook contract。[FRAME, HIGH] |
| whitelistclient | binance 白名单控制面已有语义，不应重复 PolicyManager。[INFERRED, HIGH] |
| FilePersistor | 首版先用 replay fixture/evidence，storage 后置。[INFERRED, MED] |
| Feature Engine | 分析域职责，非 binance 采集层职责。[INFERRED, HIGH] |
| Market State / Execution feedback | 消费方或专用模块职责。[INFERRED, HIGH] |

---

## 5. 风险与检查点

| 风险 | 检查点 |
| --- | --- |
| 把 Binance 私有语义带进通用 core。[INFERRED, HIGH] | Boundary Gate + adapter semantics fixture |
| 迁移后 BookHash 与 binance 当前 book 不一致。[INFERRED, HIGH] | Replay Determinism Gate |
| 下游 TopN/Incremental contract 回退。[INFERRED, HIGH] | binance FR-058/059 regression |
| resource policy 重复实现。[INFERRED, HIGH] | 禁止新增 PolicyManager |
| options depth 被误宣称完成。[INFERRED, HIGH] | options postponed/not_applicable evidence |

---

## 6. 最小验收

迁移前最低验收条件如下。[FRAME, HIGH]

```text
binance shard planner tests pass
DepthLevel / Capability semantics tests pass
Binance replay fixture exists
BookHash canonicalization rule approved
Boundary Gate draft approved
Adapter Contract draft approved
```

---

[RULES I BROKE]：无
