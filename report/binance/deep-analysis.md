# Binance 模块深度分析报告

- 报告日期：2026-07-01
- 分析范围：`module/binance/` 全量制品
- Spec-Version: v3.9.6
- Runtime-Version: v0.8.0
- 当前状态：48/48 FR Done，release_closeable=YES（PRG-001~007 全 PASS）

---

## 1. 模块定位与职责边界

### 1.1 在 ZoneCNH 架构中的位置

`module/binance` 位于 ZoneCNH 量化交易基础设施的 **数据域**，是 Binance 专属的行情数据采集与服务模块。它承载了从 Binance 交易所到 ZoneCNH 内网的完整数据管道。

```
FoundationX 架构层级：
  基座层（kernel/configx/observex/contracts/redisx/kafkax）
    └─ L2.5 共享层（decimalx/domain_market/domain_exchange/domain_macro）
        └─ 数据域
              ├─ market_data（通用行情）
              ├─ macro_data（宏观数据）
              ├─ alternative_data（另类数据）
              └─ binance ★（Binance 专属行情 C/S 模块）
                    ├─ binance-client（采集进程）
                    └─ binance-server（服务进程）
```

### 1.2 核心职责

| 职责                                       | 归属           | 边界                                   |
| ------------------------------------------ | -------------- | -------------------------------------- |
| Binance WS/REST 行情采集                   | binance-client | 仅公开市场流，不涉及私有交易           |
| Binance 事件 → domain_market envelope 映射 | binance-client | canonical domain 归 domain_market 所有 |
| natsx JetStream 可靠发布                   | binance-client | NATS 为外部基础设施服务                |
| 幂等消费与数据校验                         | binance-server | 幂等键 72h TTL，Redis SetNX            |
| 多引擎持久化（taosx/pg/clickhouse/oss）    | binance-server | 只拥有 Binance 专属存储                |
| Gin REST API 查询服务                      | binance-server | Bearer auth + 限流 1000/min            |
| kafkax 下游广播                            | binance-server | 只负责 fanout，不定义消费策略          |
| 生产就绪治理                               | 全模块         | 13 边界门禁 + 7 生产就绪门禁           |

### 1.3 明确不拥有的职责

- 通用 cross-exchange market_data 语义（归 domain_market）
- 交易下单、策略执行、风险控制
- 跨交易所数据聚合
- 用户账户或私有交易数据
- 旧版 binance-market / Provider 兼容

---

## 2. 架构深度分析

### 2.1 C/S 分布式架构

binance 采用严格的 Client/Server 二进程架构：

```text
┌─ binance-client（采集进程，~17M，MemoryMax 512M）───────────┐
│                                                              │
│  Binance Exchange                                            │
│    │ WS (wss://stream.binance.com)                           │
│    │ REST (https://api.binance.com)                          │
│    ▼                                                         │
│  catalog ──► parser ──► normalizer ──► mapper                │
│    │            │           │             │                  │
│    │ ExchangeInfo│ symbol  │ normalize   │ domain_market     │
│    │ 同步/刷新   │ 解析    │ MarketMsg   │ envelope          │
│                                                              │
│                      ▼                                       │
│              natsx.Publish(                                  │
│                subject: binance.market.{pl}.{et}.v1          │
│                body: domain_market JSON envelope              │
│              )                                               │
└──────────────────────┬───────────────────────────────────────┘
                       │ NATS JetStream
                       │ Stream: BINANCE_MARKET
                       │ Durable Consumer: binance-server
                       ▼
┌─ binance-server（服务进程，~46M，MemoryMax 4G）──────────────┐
│                                                              │
│  natsx.Subscribe(durable) ──► consumer                       │
│    │                                                         │
│    ▼                                                         │
│  processor ──► validation ──► idempotency (redisx SetNX)     │
│                                                              │
│         ┌─────────┬──────────┬──────────┬──────────┐         │
│         ▼         ▼          ▼          ▼          ▼         │
│     taosx    postgresx   redisx     kafkax     ossx         │
│     时序存储  元数据/SQL  热缓存     下游广播    冷归档       │
│                                                              │
│         └─────────┴──────────┴──────────┴──────────┘         │
│                   │                                          │
│         clickhousex (OLAP ETL goroutine)                     │
│                   │                                          │
│                   ▼                                          │
│         Gin REST API (:8090)                                  │
│         ├─ GET /api/v1/market/ticks/:symbol                  │
│         ├─ GET /api/v1/market/bars/:symbol                   │
│         ├─ GET /api/v1/market/depth/:symbol                  │
│         ├─ GET /api/v1/market/funding-rate/:symbol           │
│         ├─ GET /api/v1/market/mark-price/:symbol             │
│         ├─ GET /healthz · /readyz · /metrics                 │
│         └─ POST /ingest（smoke-only, 生产 404）               │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 产品线与事件类型矩阵

| 产品线    | tick | bar | depth | trade | funding_rate | mark_price |
| --------- | :--: | :-: | :---: | :---: | :----------: | :--------: |
| `spot`    |  ✅  | ✅  |  ✅   |  ✅   |     N/A      |    N/A     |
| `um_perp` |  ✅  | ✅  |  ✅   |  ✅   |      ✅      |     ✅     |
| `cm_perp` |  ✅  | ✅  |  ✅   |  ✅   |      ✅      |     ✅     |
| `options` |  ✅  | ✅  |  ✅   |  ✅   |     N/A      |    N/A     |

共 4 产品线 × 6 事件类型 = 24 个数据采集维度，通过 natsx subject `binance.market.{product_line}.{event_type}.v1` 路由。

### 2.3 基础设施依赖拓扑

```text
binance-client ──► NATS JetStream (:4222) ◄── binance-server
                        │
        ┌───────────────┼───────────────┬──────────────┐
        ▼               ▼               ▼              ▼
    Redis (:6379)  PostgreSQL (:5432)  TDengine (:6030)  Kafka (:9092)
    · 幂等去重      · 元数据/Symbol    · 时序/Tick/Bar  · 下游广播
    · 热缓存        · 审计日志         · Depth快照
        │                               │
        ▼                               ▼
    ClickHouse (:9000)              OSS (兼容S3)
    · OLAP分析                      · 冷数据归档
    · ETL聚合                       · SHA256校验
```

---

## 3. 功能需求全景分析

### 3.1 FR 分布

| 功能域               | FR 编号                         |  数量  |     状态      |
| -------------------- | ------------------------------- | :----: | :-----------: |
| 采集与发布（Client） | FR-001, 002, 008, 009, 027      |   5    |     Done      |
| NATS 通信契约        | FR-003                          |   1    |     Done      |
| 消费与去重（Server） | FR-004, 005                     |   2    |     Done      |
| 配置与 CLI           | FR-006a, 006b, 006c, 006d       |   4    |     Done      |
| 存储（6 引擎）       | taosx/pg/redis/clickhouse/oss   |   5    |     Done      |
| API 查询             | FR-007, 007a, 018~021           |   6    |     Done      |
| 可靠性与容错         | FR-011, 025, 026                |   3    |     Done      |
| 身份与治理           | FR-015, 022, 009, 012           |   4    |     Done      |
| 可观测性             | FR-014, 016, 017, 028, 029, 030 |   6    |     Done      |
| 生命周期管理         | FR-013, 023, 024                |   3    |     Done      |
| 产品线目录           | FR-031~036                      |   6    |     Done      |
| 生产就绪             | FR-037~044                      |   8    |     Done      |
| **合计**             |                                 | **48** | **100% Done** |

### 3.2 关键设计决策 (ADR)

| ADR     | 决策                                                                            | 理由                                                 |
| ------- | ------------------------------------------------------------------------------- | ---------------------------------------------------- |
| ADR-002 | Wire boundary: natsx subject + domain_market envelope JSON；禁止本地 proto/gRPC | 保持契约外部化，不重复定义 canonical domain          |
| ADR-003 | Order book rebuild 明确排除当前版本                                             | 增量 order book 状态机复杂度高，depth 以快照形式落库 |
| ADR-004 | FR-024 hot reload 采用全量重连而非增量 diff                                     | 增量 stream add/remove diff 归 FR-036 自建实现       |

---

## 4. 数据流与契约分析

### 4.1 NATS 消息契约

```
Subject Pattern: binance.market.{product_line}.{event_type}.v1

允许值:
  product_line ∈ {spot, um_perp, cm_perp, options}
  event_type  ∈ {tick, bar, depth, trade, funding_rate, mark_price}

控制主题:
  binance.control.instruments.changed
  binance.control.symbols.changed

强制 v1 版本后缀（drift-check 22/22 PASS）
```

### 4.2 幂等模型

```
幂等键 = exchange + product_line + instrument_key + event_type + timestamp + sequence

处理逻辑:
  SetNX(幂等键, 72h TTL)
    ├─ 成功 → 首次消息 → 写入所有存储 → ManualAck
    ├─ 失败 + 同 payload → 重复消息 → Ack 跳过副作用
    └─ 失败 + 不同 payload → 冲突 → Terminal Reject + 记录冲突
```

### 4.3 At-Least-Once 交付保证

```
Publisher: 等待 PubAck 确认
Consumer:  ManualAck 模式
  处理成功 → msg.Ack()
  处理失败 → msg.NakWithDelay(5s)
  重试上限 → MaxDeliver=5
  超限后   → deadletter 包
```

---

## 5. 生产就绪状态

### 5.1 Production Readiness Gates (PRG)

| Gate    | 内容                      | 状态 | 证据摘要                                |
| ------- | ------------------------- | :--: | --------------------------------------- |
| PRG-001 | Remote CI (ubuntu-latest) |  ✅  | 已从 self-hosted 迁移，CI 正常触发      |
| PRG-002 | Release tag + notes       |  ✅  | v0.8.0 tag + GitHub Release 存在        |
| PRG-003 | PRG 7/7 全 PASS           |  ✅  | 聚合门禁                                |
| PRG-004 | Observability 基础设施    |  ✅  | Jaeger/Grafana/Loki/AlertManager 全在线 |
| PRG-005 | 安全扫描                  |  ✅  | OTel SDK v1.44.0, govulncheck 清洁      |
| PRG-006 | 韧性测试                  |  ✅  | Soak 2min PASS, Chaos 5/5 PASS          |
| PRG-007 | Issue 同步                |  ✅  | 43 GitHub + 43 Beads 全关闭             |

### 5.2 边界门禁（13/13 PASS）

```
Gate §2  · No legacy binance-market           ✅
Gate §3  · Client 禁止 import Server internal  ✅
Gate §4  · Server 禁止 import Client internal  ✅
Gate §5  · No cs package as runtime dep        ✅
Gate §6  · No same-process C/S communication   ✅
Gate §7  · Server owns Binance storage only    ✅
Gate §8  · Wire contract externality           ✅
Gate §9  · Domain-Market semantic source       ✅
Gate §10 · Admin surface boundary              ✅
Gate §11 · go.mod dependency compliance        ✅
```

---

## 6. 可观测性体系

### 6.1 Prometheus 指标清单（9 指标）

| Metric                                  | 类型      | 语义                                       | 告警阈值                        |
| --------------------------------------- | --------- | ------------------------------------------ | ------------------------------- |
| `binance_ingest_events_total`           | counter   | 接受事件总数（按 product_line/event_type） | 5min 无增长 → 数据流中断        |
| `binance_ingest_rejected_total`         | counter   | 拒绝事件数（按 reject_code）               | reject rate > 5% → 数据质量下降 |
| `binance_dispatch_latency_seconds`      | histogram | kafkax 分发延迟                            | P99 > 1s → 下游积压             |
| `binance_storage_write_latency_seconds` | histogram | taosx 写入延迟                             | P99 > 500ms → 落盘瓶颈          |
| `binance_idempotency_hits_total`        | counter   | 幂等命中数                                 | 突增 → 上游重发异常             |
| `binance_deadletter_total`              | counter   | dead-letter 入队数                         | 5min > 0 → 持久化故障           |
| `binance_natsx_consumer_lag`            | gauge     | NATS consumer 积压                         | > 1000 → 消费跟不上             |
| `binance_stream_active`                 | gauge     | 活跃 stream 数（按 product_line）          | 突降 → 连接断开                 |
| `binance_event_stale_total`             | counter   | 过期事件数（EventTime 超阈值）             | rate > 1% → 时钟/网络问题       |

### 6.2 SLO 目标

| SLO               | 目标    | 关联指标                                  |
| ----------------- | ------- | ----------------------------------------- |
| 事件接受可用性    | ≥ 99.9% | ingest_events_total / (accepted+rejected) |
| Dispatch 延迟 P99 | ≤ 1s    | dispatch_latency_seconds                  |
| 落盘延迟 P99      | ≤ 500ms | storage_write_latency_seconds             |
| Dead-letter 率    | ≤ 0.1%  | deadletter_total / ingest_events_total    |

### 6.3 可观测性基础设施

```
Jaeger (:16686)      ─► 分布式追踪
Grafana (:3000)      ─► 仪表盘可视化和告警
Loki (:3100)         ─► 日志聚合
AlertManager (:9093) ─► 告警路由
OTel Collector (:4318) ─► 遥测采集
```

---

## 7. 部署架构

### 7.1 部署拓扑

```text
开发机（交叉编译）
  make build-linux-amd64
  → bin/binance-server-linux-amd64 (46M)
  → bin/binance-client-linux-amd64 (17M)
       │ scp
       ▼
jp1 (84.247.154.45) /opt/binance/
  ├─ bin/binance-server
  ├─ bin/binance-client
  ├─ secrets/prod.env (chmod 600)
  └─ logs/

systemd:
  binance-server.service  · GIN :8090 · admin :8081 · MemoryMax 4G
  binance-client.service  · admin :8082 · MemoryMax 512M · after=server
```

### 7.2 扩容策略

| 组件           | 方式               | 注意事项                                           |
| -------------- | ------------------ | -------------------------------------------------- |
| binance-server | 水平扩展（多实例） | consumer group 一致                                |
| binance-client | 单实例（每产品线） | 多实例需 symbol 分片                               |
| infra          | 各自扩容           | TDengine cluster / Redis cluster / Kafka partition |

---

## 8. 安全控制

| 控制面   | 措施                                            |
| -------- | ----------------------------------------------- |
| 凭据管理 | configx.SecretString，自动遮蔽日志/JSON         |
| API 认证 | Bearer token，未设置时 fail-closed (401)        |
| API 限流 | 1000 req/min per-IP，超限返回 429               |
| 漏洞扫描 | govulncheck 每次 release + CI，零 HIGH/CRITICAL |
| 密钥扫描 | gitleaks detect --no-git                        |
| TLS/mTLS | NFR 要求，生产部署前启用                        |
| 数据销毁 | destruction-drill.sh 不可逆销毁演练             |

---

## 9. 能力边界与已知限制

| 限制               | 说明                                          | 处理                            |
| ------------------ | --------------------------------------------- | ------------------------------- |
| Order book rebuild | 当前仅 top-of-book + depth 快照               | ADR-003 明确排除                |
| ClickHouse ETL     | 进程内内存窗口聚合                            | 多实例需改为 taosx 聚合源       |
| Hot reload         | 全量重连（非增量 diff）                       | ADR-004 已接受                  |
| 端到端 100K TPS    | 无专用压测环境                                | 降级为 SLO benchmark 24/24 PASS |
| Options ticker     | WS 字段名待 mainnet 实样确认                  | REST fixture 替代校验           |
| 分布式 tracing     | trace context 已进 wire，完整 span-chain 待补 | FR-039 已登记                   |
| Dead-letter replay | 持久写入已实现，file-backed replay 待补       | FileWriter + env 接线已存在     |

---

## 10. 制品清单总览

| 制品           | 路径                        | 版本     |
| -------------- | --------------------------- | -------- |
| Goal           | `goal/goal.md`              | v0.8.0   |
| Spec           | `spec/SPEC.md`              | v3.9.6   |
| Features       | `spec/FEATURES.md`          | v3.9.6   |
| Acceptance     | `spec/ACCEPTANCE.md`        | v3.9.6   |
| Traceability   | `matrix/TRACEABILITY.md`    | v3.9.6   |
| Design         | `design/DESIGN.md`          | v1       |
| Plan           | `plan/PLAN.md`              | v3.9.6   |
| Boundary Gates | `gate/BOUNDARY-GATES.md`    | v2.2.5   |
| Operations     | `gate/OPERATIONS.md`        | v3.9.0   |
| Security       | `gate/SECURITY.md`          | v3.9.0   |
| Observability  | `gate/OBSERVABILITY.md`     | v3.9.0   |
| Config Schema  | `design/CONFIG-SCHEMA.md`   | -        |
| Deploy         | `deploy/DEPLOY.md`          | v0.8.0   |
| Tasks (Root)   | `tasks/` (8 tasks)          | Done     |
| Tasks (Client) | `tasks/client/` (14 tasks)  | Done     |
| Tasks (Server) | `tasks/server/` (16 tasks)  | Done     |
| CI Workflow    | `ci-workflow.yaml`          | -        |
| ADR            | `design/ADR-00{2,3,4}-*.md` | Accepted |

---

## 11. 结论

### 11.1 总体评估

`module/binance` 已达到 **L3 Production** 级别。48 个功能需求全部 Done，7 个生产就绪门禁全 PASS，13 个边界门禁全 PASS。模块拥有完整的文档制品链（Goal→Spec→Matrix→Plan→Tasks→Evidence），在 FoundationX 模块中处于 Pipeline 成熟度的第一梯队。

### 11.2 前端机会

当前缺失前端可视化层。以下为前端设计的主要切入点：

1. **实时监控仪表盘** — 将 9 个 Prometheus 指标和 4 个 SLO 可视化
2. **行情数据浏览器** — 通过 REST API 查询和可视化 tick/bar/depth 等数据
3. **系统健康面板** — client/server 状态、stream 状态、consumer lag
4. **告警管理** — 阈值配置与告警历史
5. **Admin 控制台** — 热重载、deadletter 管理、配置查看

详细前端设计方案见 [`frontend-design.md`](frontend-design.md)。

---

_[RULES I BROKE]: 无。本报告为 [KNOWN] + [COMPUTED] 混合，基于 SPEC/TRACEABILITY/DESIGN/GATE/DEPLOY 6 类制品的当前 v3.9.6 口径。_
