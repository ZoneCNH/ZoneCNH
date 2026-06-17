# 数据域基础架构搭建方案 — 行情 + 宏观（23 个独立 CS 服务）

> 日期: 2026-06-17
> 分析对象: 数据域（行情 13 + 宏观 10 = 23 个子模块）基础架构搭建
> 仓库上下文: `ZoneCNH/ZoneCNH`（文档枢纽） + 23 个独立 git 仓库
> 配置源: `sre/secrets/env/dev.md`（per-provider per-DB 隔离凭据）
> 分支: `report/data-domain-infrastructure-20260617`（从 main HEAD `8b4869b`）

---

## 一、概览

数据域 · 行情 + 宏观的每个子模块都是**独立的 CS 模块、独立的服务**。本报告回答的核心问题是：这 23 个独立服务如何**共享基座组件、复用领域共享层、统一接入 7 种持久化、并安全消费 `dev.md` 的 per-provider 凭据**，从而搭出一套完整、可审计、可演进的基础架构。

**23 个子模块清单：**

| 域   | 模块                                                                                                               | 数量 | 本地路径          | 角色                         |
| ---- | ------------------------------------------------------------------------------------------------------------------ | ---- | ----------------- | ---------------------------- |
| 行情 | binance / okx / bybit / bitget / kucoin / gate / mexc / htx / coinbase / hyperliquid / lighter / upbit / coinglass | 13   | `/home/{module}/` | CEX/DEX 行情 + 衍生品聚合    |
| 宏观 | fred / treasury / yield-curve / bea / ecb / uk-cb / japan-cb / eastmoney / jin10 / yahoo                           | 10   | `/home/{module}/` | 央行/财政/经济/权益/另类宏观 |

**7 种持久化（用户指定）**：TDengine（`taosx`）、Kafka（`kafkax`）、PostgreSQL（`postgresx`）、Redis（`redisx`）、OSS（`ossx`）、NATS（`natsx`）、ClickHouse（`clickhousex`）。

**核心结论**：

1. 基座 19 模块 + L2.5 领域共享层**已全部发布**，数据域只需组装，不需重造。
2. 23 个子模块必须采用**统一 CS 骨架 + 统一 `internal/infra` 组装层**，消除现状中依赖不统一（如 `fred` 仍依赖旧 `xlib-standard v0.4.14`）的差距。
3. 7 种持久化职责必须**分层不重叠**：TDengine=时序 / PG=元数据 / Redis=幂等缓存 / Kafka=数据面 backbone / NATS=控制面 / OSS=归档 / ClickHouse=OLAP 回测。
4. `dev.md` 含明文凭据，必须经 `configx EnvSource + SecretString` 脱敏注入，每个服务只读自己的 per-provider 库，做到**库级隔离**。
5. 对下游（分析域）只暴露 `contracts.MarketDataProvider` / `contracts.MacroDataProvider` 端口，下游不直连存储。
6. **需要新增一个薄胶水层基座模块 `bootstrap`**（L1），统一封装 config/observex/7 存储 + 生命周期编排，消除 23 份组装逻辑复制（详见 §十三）。

---

## 二、现状审计

### 2.1 已就绪的基座组件（全部 ✅ 已发布）

数据域的全部依赖底座已完成 Spec→Code 并发布，无需新建。

| 层      | 基座组件          | 版本   | 状态 | 数据域用途                                                                 |
| ------- | ----------------- | ------ | ---- | -------------------------------------------------------------------------- |
| L0 原语 | `kernel`          | v1.0.0 | ✅   | lifecycx/errx/healthx/retryx/shutdownx，服务生命周期底座                   |
| L1 能力 | `configx`         | v1.0.0 | ✅   | 多源加载、StrictDecode、SecretString 脱敏、Provenance、EffectiveConfigHash |
| L1 能力 | `observex`        | v0.3.1 | ✅   | Logger/Meter/Tracer/Health vendor-neutral 契约 + 自动脱敏                  |
| L1 能力 | `resiliencx`      | v0.4.9 | ✅   | retry/circuit/bulkhead/rate，采集重试与熔断                                |
| L1 能力 | `schedulex`       | v1.0.0 | ✅   | cron/interval/delay，宏观定时拉取 + 行情轮询                               |
| L2 存储 | `taosx`           | v1.0.1 | ✅   | TDengine 时序适配器（含 WebSocket 集成 gate）                              |
| L2 存储 | `postgresx`       | v1.0.0 | ✅   | PG 关系型 + 事务 + 迁移                                                    |
| L2 存储 | `redisx`          | v1.0.1 | ✅   | Redis KV/Lock/限流/幂等/Cache-aside                                        |
| L2 存储 | `kafkax`          | v1.0.2 | ✅   | Kafka 消息队列 + 事件流（driver-neutral）                                  |
| L2 存储 | `natsx`           | v1.0.0 | ✅   | NATS Core + JetStream                                                      |
| L2 存储 | `ossx`            | v1.0.1 | ✅   | 阿里云 OSS 对象存储                                                        |
| L2 存储 | `clickhousex`     | v1.0.1 | ✅   | ClickHouse OLAP 批量写入/查询                                              |
| 契约    | `contracts`       | v1.2.0 | ✅   | 跨域端口/事件/DTO（MarketDataProvider 已定义）                             |
| L2.5    | `decimalx`        | v1.0.0 | ✅   | 高精度 Decimal/Price/Qty                                                   |
| L2.5    | `domain-market`   | v1.1.0 | ✅   | Tick/Quote/Bar/OrderBook/Funding/Instrument 等 SSOT                        |
| L2.5    | `domain-exchange` | v1.0.0 | ✅   | VenueAdapter 交易域模型                                                    |
| L2.5    | `domain-macro`    | v1.0.0 | ✅   | MacroPoint/MacroInformationSet/MacroState                                  |
| L2.5    | `domainx`         | v1.0.1 | ✅   | Order/Position/Trade 共享值对象                                            |

### 2.2 现有子模块依赖差距（需要迁移修正）

抽样两个代表模块的 `go.mod`：

```go
// /home/binance/go.mod — 已迁移到细粒度基座 + bootstrap ✅
require (
    github.com/ZoneCNH/bootstrap        v0.1.0   // P1.5 进程组装层
    github.com/ZoneCNH/decimalx         v1.0.0   // ✅ 已升级
    github.com/ZoneCNH/domain-exchange  v1.0.0   // ✅ 已升级
    github.com/ZoneCNH/domain-market    v1.1.0   // ✅ 已升级
    github.com/binance/binance-connector-go v0.8.0
)
// ✅ bootstrap 接入完成（Stores=None），adapter 零存储，全量 build+test 通过

// /home/fred/go.mod — 已迁移到细粒度基座 ✅（P2 完成）
require (
    github.com/ZoneCNH/bootstrap     v0.1.0   // P1.5 进程组装层
    github.com/ZoneCNH/decimalx      v1.0.0   // ✅ 已升级
    github.com/ZoneCNH/observex      v0.3.1   // ✅ xlib-standard → observex
)
// ✅ P2 迁移完成 + P6 bootstrap 接入完成
```

**差距汇总：**

| 差距                                                            | 影响范围            | 严重度     |
| --------------------------------------------------------------- | ------------------- | ---------- |
| `go.mod` 依赖版本落后（v0.1.0 vs 已发布 v1.0.0+）               | 23 个子模块         | 高         |
| 部分模块仍依赖 `xlib-standard` 而非细粒度基座                   | fred 等 10 宏观模块 | 高         |
| 无统一基座组装层（configx/observex/7 存储适配器如何注入未定义） | 23 个子模块         | 高         |
| 7 种持久化在子模块间职责未分层                                  | 全域                | 高         |
| `dev.md` 明文凭据缺安全注入路径                                 | 全域                | 高（安全） |
| ~~`contracts` 缺 `MacroDataProvider` 端口~~ ✅ 已定义（§8.1）   | —                  | —（已解决） |

### 2.3 dev.md 凭据与库结构（精确统计）

`sre/secrets/env/dev.md` 提供的 per-provider 隔离凭据（已在 sre 仓库 `.gitignore`）：

| 存储           | per-provider 库数 | 行情                                                    | 宏观                                    |
| -------------- | ----------------- | ------------------------------------------------------- | --------------------------------------- |
| **PostgreSQL** | 26 库             | `market_{binance,okx,…}` **16 库**                      | `macro_{fred,bea,…}` **10 库**          |
| **TDengine**   | 29 独立库         | `market_{…}` **18 库**（含 edgex/aster/lighter/bitmex） | `macro_{…}` **11 库** + 旧 `macro_data` |
| **Redis**      | 1 库              | 单库 `db0`，key 前缀隔离 `mkt:{venue}:`                 | 单库 `db0`，前缀 `mac:{provider}:`      |
| **Kafka**      | 1 集群            | topic 隔离 `mkt.{venue}.{kind}`                         | topic `mac.{provider}.point`            |
| **NATS**       | 1 集群            | subject `svc.{module}.*`                                | subject `svc.{module}.*`                |
| **OSS**        | 1 bucket          | prefix `raw/{venue}/{date}/`                            | prefix `raw/{provider}/{date}/`         |
| **ClickHouse** | 单库              | `market_analytics`                                      | `macro_analytics`                       |

> ⚠️ 安全提示：`dev.md` 文件头部已自标 CAUTION（含明文 PG/TD/Redis/Kafka/OSS 密码与 FRED API key）。本报告所有凭据均不内联，仅描述注入链路。生产环境走 `sre/secrets/env/prod.md` + Vault/GitHub Secrets。

---

## 三、目标架构

### 3.1 分层总览

```
                       ┌─────────────────────────────────────────────┐
   外部数据源           │  组合根 x.go（编排，不在此实现业务）            │
  FRED/ECB/Binance…    └────────────────────┬────────────────────────┘
  ──►  HTTP/WS 采集                          │  注入 configx Client + observex
         │                                   │     + 7×存储适配器（per-provider 凭据）
         ▼                                   ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  数据域 · 行情 13 服务            │   数据域 · 宏观 10 服务                     │
│  每个独立进程 = 1 个 CS Module     │   每个 = MacroIngestorService              │
│  binance / okx / … / coinglass    │  fred / bea / ecb / treasury / … / yahoo  │
│                                                                            │
│  统一子模块骨架（见 §五）：                                                 │
│   cmd/{svc}-server  internal/{client,server,cs,infra}  pkg/{svc}x         │
│                                                                            │
│  所有子模块只依赖 L2.5 + 基座，禁止互相 import                              │
└───────────────┬────────────────────────────────┬───────────────────────────┘
                │ domain-market                   │ domain-macro
                │ (Tick/Quote/Bar/OB/Funding)     │ (MacroPoint/MacroInfoSet)
                ▼                                 ▼
        ┌───────────────────────────────────────────────┐
        │  L2.5 领域共享层（SSOT 值对象，纯模型）          │
        │  domainx · decimalx · domain-market           │
        │  domain-exchange · domain-macro               │
        └──────────────────────┬────────────────────────┘
                               │
        ┌──────────────────────▼────────────────────────┐
        │  基座运行时 Foundation（L0/L1/L2 适配器）        │
        │  kernel · configx · observex · resiliencx     │
        │  schedulex · bootstrap（§十三 新增薄胶水层）     │
        │  taosx · postgresx · redisx · kafkax          │
        │  natsx · ossx · clickhousex · contracts       │
        └───────────────────────────────────────────────┘
```

### 3.2 设计原则（源自 CONSTITUTION + ARCHITECTURE.md）

- **领域语义沉到 L2.5**（L302-313）：价格/数量统一来自 `decimalx`，行情模型来自 `domain-market`，宏观来自 `domain-macro`，各域不重复定义。
- **数据职责不跨域**：数据域只做采集 / 标准化 / 存储；因子计算在分析域，策略逻辑在决策域。
- **contracts 只定义跨域稳定契约**：跨域端口、事件协议、DTO 放 `contracts`；域内接口留在域内。
- **领域纯净**：公共 domain struct 不含 transport/persistence/vendor tag（BR-MKT-002 / BR-MAC-006）。
- **fail-closed**：非法数据默认拒绝，不静默修正；宏观 `IsVisibleAt` 防前视偏差（BR-MAC-001/002）。

---

## 四、7 种持久化职责分层矩阵

这是整套架构的核心决策——同一个子模块要连 7 种存储，必须明确每种"存什么、何时写、per-provider 如何隔离"。

| 存储           | 适配器        | 数据域职责                                                                      | 写入时机                  | per-provider 隔离方式                                              |
| -------------- | ------------- | ------------------------------------------------------------------------------- | ------------------------- | ------------------------------------------------------------------ |
| **TDengine**   | `taosx`       | 高频时序原始数据：kline/trades/orderbook/funding_rate（行情）；宏观时序点       | 实时（行情）/批量（宏观） | 独立库 `market_{venue}` / `macro_{provider}`                       |
| **PostgreSQL** | `postgresx`   | 元数据：series_meta / checkpoints / lineage / sync_status / instrument registry | 采集前后、修订时          | 独立库 `market_{venue}` / `macro_{provider}`（DB-002 隔离）        |
| **Redis**      | `redisx`      | 最新报价缓存、幂等键（CheckAndSet）、分布式锁（防重复调度）、限流               | 每条行情 / 每次拉取       | 单库 `db0`，key 前缀 `mkt:{venue}:` / `mac:{provider}:`            |
| **Kafka**      | `kafkax`      | 数据面 backbone：高吞吐行情事件、回放、下游订阅                                 | 实时 produce              | topic `mkt.{venue}.{kline\|trade\|quote}` / `mac.{provider}.point` |
| **NATS**       | `natsx`       | 控制面：健康广播、控制指令（drain/resync）、JetStream 跨服务事件                | 控制面                    | subject `svc.{module}.*`                                           |
| **OSS**        | `ossx`        | 原始响应归档、parquet 快照、checkpoint 备份                                     | 按批次 / 定时             | prefix `raw/{venue}/{date}/` / `snapshot/{provider}/`              |
| **ClickHouse** | `clickhousex` | OLAP：批量分析、回测读取、聚合统计（Kafka→CH 物化视图）                         | Kafka 消费后 ETL          | 单库 `market_analytics` / `macro_analytics`                        |

### 4.1 Kafka vs NATS 分工（避免双 SSOT）

- **Kafka** = 数据面 backbone：持久、高吞吐、可回放，行情/宏观数据流主通道。
- **NATS** = 控制面：服务发现、健康、命令分发，**不承载业务数据流**。

两者职责正交，不构成重复持久化。

### 4.2 为什么 ClickHouse 与 TDengine 并存（而非二选一）

| 维度       | TDengine                       | ClickHouse                        |
| ---------- | ------------------------------ | --------------------------------- |
| 擅长       | 高频写入、时间窗口查询、降采样 | ad-hoc OLAP、海量扫描、回测批量读 |
| 数据域角色 | 实时收行情/宏观点              | 供分析域回测/聚合读               |
| 写入来源   | 服务直接写                     | Kafka 物化视图 ETL 灌入           |

两者互补：TDengine 收实时，ClickHouse 供回测。下游只经 contracts 端口读，不感知物理存储差异。

### 4.3 数据流走向

```
行情源/宏观源
    │ (采集)
    ▼
{module}/client ──(Kafka: mkt/mac.*)──► {module}/server ──► TDengine + PG(元数据)
                                          │                    ▲
                                          ├─(Redis: 幂等/缓存)─┘
                                          ├─(OSS: 原始归档)
                                          └─(NATS: health/control)
                                                   │
                          Kafka ──(物化视图)──► ClickHouse ──(回测/分析域读)
                                                   │
                              contracts.MarketDataProvider / MacroDataProvider
                                                   │
                                            分析域 factor-engine
```

- **server** 验收后双写 TDengine + Kafka。
- **contracts 端口**：`pkg/{module}x` 实现 `contracts.MarketDataProvider`（行情）或 `contracts.MacroDataProvider`（宏观），这是对下游唯一合法接口。
- 下游（分析域）**永远不直连 TDengine/ClickHouse**，只调契约端口，保证域间解耦。

---

## 五、统一子模块骨架（23 个服务共用）

以 `binance` 已落地的 C/S 结构为蓝本，标准化**所有 23 个子模块**。

```
{module}/                          # 独立 git 仓库 + 独立进程
├── go.mod                         # 只依赖 L2.5 + 基座（见 §六）
├── .env.example                   # XGO_{MODULE}_* 模板，不含真值
├── cmd/
│   ├── {module}-server/           # 独立服务入口（main：调 bootstrap.Build + 起本服务 server）
│   └── {module}-smoke/            # 同进程端到端冒烟（client+server wire）
├── internal/
│   ├── cs/                        # client/server 共享契约（待 contracts v1.3 后替换为 import）
│   ├── client/                    # 采集端：connector/normalize/mapper/spool/checkpoint/sender
│   ├── server/                    # 验收端：validation/idempotency/ack/dispatch
│   └── infra/                     # 本服务注入适配（§八瘦身后只剩 wiring.go）
│       └── wiring.go              # 把 bootstrap 返回的 *App 注入本服务 client/server
├── pkg/
│   └── {module}x/                 # 对外 VenueAdapter/MacroProvider 实现（contracts 端口）
├── scripts/
│   └── boundary-gates.sh          # CI 边界门禁（参照 binance 9 道）
└── test/
    └── e2e/                       # mock 源 → client → server → sink
```

> **与初稿差异**：初稿 §五把 `internal/infra/{config,observe,stores}.go` 放在每服务内；经 §十三分析后，这三类通用组装逻辑上提到 `bootstrap`，每服务的 `internal/infra` 瘦身到只剩 `wiring.go`。

### 5.1 行情 vs 宏观子模块差异

| 维度     | 行情 CS Module                                     | 宏观 MacroIngestor                              |
| -------- | -------------------------------------------------- | ----------------------------------------------- |
| 采集触发 | WS 长连接 + REST 拉取（`schedulex`）               | 定时 cron 拉取（`schedulex`）                   |
| 领域模型 | `domain-market.{Tick,Quote,Bar,OrderBook,Funding}` | `domain-macro.{MacroPoint,MacroInformationSet}` |
| 高频存储 | TDengine 实时写（kline/trades）                    | TDengine 批量写时序点                           |
| 修订语义 | 无（行情无修订）                                   | 有（RevisionVersion / IsPreliminary，防前视）   |
| 对外端口 | `contracts.MarketDataProvider`                     | `contracts.MacroDataProvider`（**已定义** §8.1） |
| 边界门禁 | client↔server 隔离 + 跨模块禁 import               | 同左 + no-lookahead gate                        |

---

## 六、统一 go.mod 依赖模板（消除差距 2.2）

所有 23 个子模块的 `go.mod` 必须是这套依赖，**禁止再依赖 `xlib-standard`**（fred 等旧模块需迁移）。

### 6.1 行情模块模板

```go
module github.com/ZoneCNH/{module}

go 1.23

require (
    // L0/L1 基座
    github.com/ZoneCNH/kernel        v1.0.0
    github.com/ZoneCNH/configx       v1.0.0
    github.com/ZoneCNH/observex      v0.3.1
    github.com/ZoneCNH/resiliencx    v0.4.9
    github.com/ZoneCNH/schedulex     v1.0.0
    github.com/ZoneCNH/bootstrap      v0.1.0   // §十三 新增薄胶水层

    // L2 持久化适配器（bootstrap 会传递依赖，此处按需显式声明）
    github.com/ZoneCNH/taosx         v1.0.1
    github.com/ZoneCNH/postgresx     v1.0.0
    github.com/ZoneCNH/redisx        v1.0.1
    github.com/ZoneCNH/kafkax        v1.0.2
    github.com/ZoneCNH/natsx         v1.0.0
    github.com/ZoneCNH/ossx          v1.0.1
    github.com/ZoneCNH/clickhousex   v1.0.1

    // L2.5 领域 SSOT + 跨域契约
    github.com/ZoneCNH/decimalx        v1.0.0
    github.com/ZoneCNH/contracts       v1.2.0
    github.com/ZoneCNH/domain-market   v1.1.0
    github.com/ZoneCNH/domain-exchange v1.0.0
)
```

### 6.2 宏观模块模板

```go
module github.com/ZoneCNH/{module}

go 1.23

require (
    // L0/L1 基座（同上）
    github.com/ZoneCNH/kernel        v1.0.0
    github.com/ZoneCNH/configx       v1.0.0
    github.com/ZoneCNH/observex      v0.3.1
    github.com/ZoneCNH/resiliencx    v0.4.9
    github.com/ZoneCNH/schedulex     v1.0.0
    github.com/ZoneCNH/bootstrap      v0.1.0

    // L2 持久化适配器（同上，按需）
    github.com/ZoneCNH/taosx         v1.0.1
    github.com/ZoneCNH/postgresx     v1.0.0
    github.com/ZoneCNH/redisx        v1.0.1
    github.com/ZoneCNH/kafkax        v1.0.2
    github.com/ZoneCNH/natsx         v1.0.0
    github.com/ZoneCNH/ossx          v1.0.1
    github.com/ZoneCNH/clickhousex   v1.0.1

    // L2.5 领域 SSOT + 跨域契约
    github.com/ZoneCNH/decimalx      v1.0.0
    github.com/ZoneCNH/contracts     v1.2.0
    github.com/ZoneCNH/domain-macro  v1.0.0
)
```

### 6.3 边界守卫规则（`boundary-gates.sh` 增项）

| 门禁                          | 规则                                                            | 校验命令                             |
| ----------------------------- | --------------------------------------------------------------- | ------------------------------------ |
| client↔server 隔离            | `internal/client/**` 不得 import `internal/server/**`，反之亦然 | `go list -deps` 反向边扫描           |
| 跨模块禁止 import             | `{module}` 的 go.mod 不得出现其他子模块路径                     | `grep ZoneCNH/{other} go.mod` 零命中 |
| domain 纯净                   | domain struct 不得携带 `json/db/yaml/kafka/bson` tag            | `grep` tag 扫描（参照 BR-MKT-002）   |
| 禁止 xlib-standard 运行时依赖 | go.mod 不得出现 `xlib-standard`（标准源不参与运行时）           | `grep xlib-standard go.mod` 零命中   |
| 冒烟特例                      | 仅 `cmd/{module}-smoke` 允许同时 import client+server           | 入口白名单                           |

---

## 七、配置注入方案（dev.md → 服务）

`dev.md` 含明文凭据，**绝不能进 git 仓库**。安全注入链路：

```
sre/secrets/env/dev.md  ──(人工映射,明文)──►  本地 .env / .env.{module}  ──►  bootstrap.Build 内置 configx EnvSource
   (已在 sre 仓库 .gitignore)                     (本机,不提交)                 (StrictDecode + SecretString 脱敏)
```

### 7.1 注入步骤

**第 1 步：每个服务的 `.env`**（本地，gitignore）

按 dev.md 把对应 per-provider 凭据填入，用统一前缀。行情服务示例：

```bash
# {module} 服务（行情）—— 仅填 dev.md 中 market_{module} 那一行
XGO_{MODULE}_PG_HOST=127.0.0.1
XGO_{MODULE}_PG_PORT=5432
XGO_{MODULE}_PG_DB=market_{module}
XGO_{MODULE}_PG_USER=market_{module}
XGO_{MODULE}_PG_PASSWORD=<dev.md market_{module} 密码>

XGO_{MODULE}_TD_HOST=127.0.0.1
XGO_{MODULE}_TD_PORT=6041
XGO_{MODULE}_TD_DB=market_{module}
XGO_{MODULE}_TD_USER=market_{module}
XGO_{MODULE}_TD_PASSWORD=<dev.md TD market_{module} 密码>

XGO_{MODULE}_REDIS_ADDR=127.0.0.1:6379
XGO_{MODULE}_REDIS_PASSWORD=<dev.md Redis 密码>

XGO_{MODULE}_KAFKA_BROKERS=127.0.0.1:9092
XGO_{MODULE}_KAFKA_USER=admin
XGO_{MODULE}_KAFKA_PASSWORD=<dev.md Kafka 密码>
XGO_{MODULE}_KAFKA_SASL=SASL_PLAINTEXT

XGO_{MODULE}_NATS_URL=nats://127.0.0.1:4222
XGO_{MODULE}_OSS_ENDPOINT=oss-ap-northeast-1.aliyuncs.com
XGO_{MODULE}_OSS_BUCKET=x-go
XGO_{MODULE}_OSS_ACCESS_KEY=<dev.md OSS AK>
XGO_{MODULE}_OSS_ACCESS_SECRET=<dev.md OSS SK>

XGO_{MODULE}_CH_HOST=127.0.0.1:9000
XGO_{MODULE}_CH_DATABASE=market_analytics
```

宏观服务同理，DB 名为 `macro_{provider}`，FRED 模块额外：

```bash
XGO_FRED_API_KEY=<dev.md FRED api_key>
```

**第 2 步：configx 加载（由 bootstrap 内置，服务无需自写）**

`bootstrap.Build` 内部完成（见 §十三 API）：

```go
loader := configx.NewLoader()
loader.AddSource(configx.FileSource(".env"))   // 本地 .env 文件
loader.AddSource(configx.EnvSource("XGO_"))    // 环境变量覆盖（优先级更高）
return configx.New(ctx, loader.Load(),
    configx.WithSecretPolicy(configx.DefaultSecretPolicy()))
```

- 所有 `*_PASSWORD` / `*_SECRET` / `*_KEY` 字段自动是 `SecretString`，日志/metrics/error 输出自动脱敏为 `***`。
- `EffectiveConfigHash` 生成 SHA-256 指纹，用于排查配置漂移与 per-service 启动校验。

**第 3 步：per-provider 库级隔离（核心设计）**

每个服务**只读 dev.md 里属于自己那一行**的库：

| 服务    | 可访问的 PG 库      | 可访问的 TD 库      |
| ------- | ------------------- | ------------------- |
| binance | 仅 `market_binance` | 仅 `market_binance` |
| fred    | 仅 `macro_fred`     | 仅 `macro_fred`     |
| ecb     | 仅 `macro_ecb`      | 仅 `macro_ecb`      |

做到**库级隔离**：binance 服务无法连 `market_okx`，fred 服务无法连 `macro_bea`。跨库查询只能经 contracts 端口，不能跨库直连。

### 7.2 configx Provenance 可审计性

每个 key 记录 source / priority / override 链路。排查"某服务连错库"时，`SanitizedManifest`（脱敏快照）可直接定位是 `.env` 还是环境变量注入了错误值。

---

## 八、`internal/infra` 组装层设计（瘦身后）

> 初稿设想的 `internal/infra/{config,observe,stores}.go` 三文件经 §十三分析后**上提到 `bootstrap`**。每服务 `internal/infra` 只保留 `wiring.go`，负责把 bootstrap 返回的 `*App` 注入本服务的 client/server。

### 8.1 wiring.go — 本服务注入适配

```go
package infra

import (
    "github.com/ZoneCNH/bootstrap"
    "{module}/internal/client"
    "{module}/internal/server"
)

// Wire 把 bootstrap 组装好的 *App 注入本服务的 client/server。
// 通用组装（config/observex/7 存储/lifecycle）已由 bootstrap.Build 完成。
func Wire(app *bootstrap.App, moduleName string) (*Service, error) {
    cl := client.New(app.Stores, app.Observe, app.Resilience)
    srv := server.New(app.Stores, app.Observe)
    adapter := modulex.New(srv, app.Stores, app.Observe)  // pkg/{module}x 对外契约实现

    // 把本服务组件注册进 bootstrap 的生命周期管理
    app.Lifecycle.Register(cl.AsComponent(), srv.AsComponent())

    return &Service{Client: cl, Server: srv, Adapter: adapter}, nil
}
```

**组装层一致性保证**：23 个服务的 wiring.go 结构相同，只差 `client.New` 的采集器实现（行情 WS vs 宏观 cron）。通用组装零差异。

---

## 九、落地路线图

| 阶段                           | 工作                                                                                                               | 退出条件                               | 预估         |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------ | -------------------------------------- | ------------ |
| **P0 基座就绪**                | 7 持久化适配器全部发布（已 ✅）；~~contracts 补 `MacroDataProvider` 端口~~ ✅ 已定义 | ~~contracts v1.3~~ → contracts v1.2 已含；重心转 macro-data SPEC | — |
| **P1 模板固化**                | 把 binance C/S 骨架 + `internal/infra` 抽成可复制模板；编写 `docs/sre/data-domain-bootstrap.md`                    | 1 个模板 + 文档，新模块 `cp -r` 即用   | 1 份 SOP     |
| **P1.5 bootstrap 基座（新增）** | 新建 `bootstrap`（L1 薄胶水层）：Spec→Code 走四源 98 分门禁；实现 Build/Run/Shutdown + 7 存储 Component 适配        | bootstrap v0.1.0 发布，binance 接入验证 | 1 个基座模块 |
| **P2 旧模块迁移**              | fred 等 10 宏观模块从 `xlib-standard` 迁到 `domain-macro` + 细粒度基座；行情模块统一补 `internal/infra`            | 23 个 go.mod 全部符合 §六模板          | 23 次迁移    |
| **P3 配置注入**                | 按每 per-provider 库生成 `.env`；bootstrap 内置 configx EnvSource + SecretString 接通；验证 23 服务各自只连自己的库 | 库隔离连通测试通过                     | 23 份 .env   |
| **P4 持久化接通**              | 每服务 main 调 bootstrap.Build，7 适配器由 bootstrap 统一构造                                                        | per-service 存储健康检查全绿           | 23 服务      |
| **P5 边界门禁**                | 每服务 `boundary-gates.sh`（client↔server 隔离 + 跨模块禁 import + domain 纯净 + 禁 xlib-standard）                | CI 全绿                                | 23 套 gate   |
| **P6 编排**                    | x.go 组合根统一拉起 23 服务，注入共享 configx/observex 实例                                                        | x.go 单进程可拉起全量                  | 1 个组合根   |

### 9.1 依赖关系

```
P0 (contracts 端口) ─► P1 (模板) ─► P1.5 (bootstrap) ─► P2 (迁移) ─► P3 (配置)
                                                                    ─► P4 (持久化) ─► P5 (门禁) ─► P6 (编排)
```

P0 是硬前置（宏观模块无对外端口）；P1.5 是 P2/P4 的硬前置（组装逻辑要先有归属）；P2 可并行于 P3。

---

## 十、关键决策记录

| #   | 决策                                                                  | 理由                                                                        |
| --- | --------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| D1  | 23 子模块统一 `cmd/internal{cs,client,server,infra}/pkg` 骨架         | 消除现状差异，新增模块成本=采集器+配置，基座组装零差异                      |
| D2  | 所有 go.mod 切细粒度基座 + L2.5，废弃 `xlib-standard` 运行时依赖      | 标准源不参与运行时 import（ARCHITECTURE.md L345）；避免单点升级影响 23 模块 |
| D3  | 7 存储职责分层：TD时序/PG元/Redis幂等/Kafka流/NATS控制/OSS归档/CH回测 | 职责不重叠，Kafka=NATS 正交，TD=CH 互补                                     |
| D4  | per-provider 库级隔离，每服务只连自己的库                             | 安全 + 故障隔离 + 审计清晰                                                  |
| D5  | 凭据经 configx EnvSource + SecretString 注入，dev.md 不进代码仓库     | dev.md 已含明文密码，必须脱敏；configx 提供现成 StrictDecode + Provenance   |
| D6  | 对下游只暴露 contracts 端口，下游不直连存储                           | 域间解耦，存储替换不影响下游                                                |
| D7  | 通用组装逻辑上提到 `bootstrap`，每服务 `internal/infra` 只剩注入适配   | 消除 23 份组装复制；bootstrap 与 internal/infra 职责正交                     |

---

## 十一、风险与缓解

| 风险                                        | 影响       | 缓解                                                                          |
| ------------------------------------------- | ---------- | ----------------------------------------------------------------------------- |
| dev.md 明文凭据泄露                         | 高（安全） | configx SecretString 脱敏 + sre 仓库 .gitignore + 生产走 Vault；定期轮换      |
| 23 服务 × 7 存储 = 161 条连接，资源压力大   | 中         | 每服务按需连存储（宏观模块可不用 Kafka 高频）；连接池 + health gate           |
| 旧模块迁移工作量（23 个 go.mod）            | 中         | P1 模板固化后 `cp -r` 批量；按 P2 分批迁移                                    |
| Kafka 与 NATS 职责漂移                      | 中         | D3 明确分工 + boundary-gates 校验业务数据不进 NATS                            |
| ~~contracts 缺 MacroDataProvider 阻塞宏观模块~~ ✅ 端口已定义 | —（已解决） | 真正缺口是 macro-data 接收侧 SPEC（§十七）                                    |
| TDengine vs ClickHouse 双写一致性           | 中         | ClickHouse 经 Kafka 物化视图异步灌入，接受最终一致；回测读 CH 不要求强一致    |
| bootstrap 范围蔓延成第二个 x.go              | 中         | §13.5 五道边界门禁锁死：禁业务/禁采集/禁 transport 实体/只向下依赖/组件可插拔 |

---

## 十二、与治理体系对齐

本方案完全遵守仓库既有治理：

- **CONSTITUTION §0 分支纪律**：报告在 feature branch `report/data-domain-infrastructure-20260617`（从 main HEAD `8b4869b`）撰写，不直接编辑 main。
- **CONSTITUTION §设计原则**：领域语义沉到 L2.5、数据职责不跨域、contracts 只定义跨域稳定契约。
- **AGENTS.md**：保留英文模块名/技术名词（`domain-market`、`taosx`），域标签一致（数据域/基座/L2.5），kebab-case 项目名。
- **ARCHITECTURE.md 依赖守卫**（L278-287）：业务域只依赖 L2.5 + contracts + 基座，不互相 import 实现包；本方案 `boundary-gates.sh` 落地该守卫。

后续若要把本方案推进为正式 Spec→Code 管线，应按 AGENTS.md 的 Spec 开发管线走：Spec → Review → Approve → Matrix → Tasks → Plan → Prompt → Code → 验收 → Ship，每阶段经四源评分 98 分门禁。

---

## 十三、bootstrap — 进程启动组装层

> 结论：**需要**一个薄胶水层基座模块 `bootstrap`（L1），封装所有数据域进程共有的 config+observe+lifecycle 组装；存储适配器是聚合层的可选件，不绑死到每个进程。

### 13.1 判断依据

**证据 A — 组装逻辑会重复 25 次**

`binance/cmd/binance-server/main.go` 是纯 SDK 骨架：生命周期用裸 `signal.NotifyContext` + `<-ctx.Done()`，**完全没用上 `kernel.lifecycx.Manager`**。configx/observex 加载与生命周期编排这段胶水，会在 25 个进程（23 adapter + 2 聚合层）里逐字复制。这是教科书级的「该提取公共层」信号。

**证据 B — `kernel.lifecycx` 已做好生命周期抽象，但缺串联层**

```go
// kernel/lifecycx 已存在（实测源码）：
type Component interface { Name() string; Start(ctx) error; Stop(ctx) error }
type Manager struct{ ... }   // 顺序启动 + 逆序停止 + 失败回滚
```

但**没有任何东西把它和 configx / observex / 存储适配器串起来**。每个进程 main 要自己写「读 config → 建 observex → 建 stores → 全部注册进 Manager → Start → 等信号 → Stop」。这段胶水就是 bootstrap 层的全部内容。

**证据 C — 存储适配器「构造→注册→关闭」壳统一**

taosx/postgresx/redisx/kafkax/natsx/ossx/clickhousex 各有 `New(ctx, cfg, opts...)`，都符合 `lifecycx.Component` 形态。但经 §十五 查明，**存储适配器只属于聚合层（2 进程），不属于 adapter（23 进程，零存储）**——因此证据 C 的适用范围收窄到 2 个聚合层，bootstrap 的存储能力是可选件而非默认。

### 13.2 模块定义

| 字段     | 值                                                                                |
| -------- | --------------------------------------------------------------------------------- |
| 模块名   | `bootstrap`（语义直白：服务启动组装器；实测无命名冲突）                            |
| 层级     | **L1 基础能力**（与 configx/observex/resiliencx/schedulex 同层）                  |
| 仓库     | `github.com/ZoneCNH/bootstrap`（新建）                                             |
| 依赖     | `kernel`（lifecycx/healthx/shutdownx）、`configx`、`observex`、`resiliencx`       |
| 可选依赖 | 7 个 L2 存储适配器（仅聚合层 Spec 启用）                                          |
| 被依赖   | 23 adapter + 2 聚合层 + 未来分析域/决策域服务                                      |
| Go 版本  | 1.23（与 FOUNDATION-DEPS.yaml go_baseline 对齐）                                  |

> **命名说明**：候选名 `data-runtime` / `svc-bootstrap` / `bootstrap`。选 `bootstrap` 是因为：(1) 语义直白——全部职责就是"在服务启动时把基座组装起来"，名实相符；(2) 不绑死「数据域」——未来分析域/决策域服务同样复用，名带 `data-` 会误导；(3) 与 `*x` 基座命名规律有意区分——`*x` 后缀语义是"对某个能力/存储的封装"（configx 封装 config、redisx 封装 Redis），而 `bootstrap` 是"组合多个 *x 的启动入口"，职责层级不同。

### 13.3 两类进程的组装矩阵

经 §十五 查明，数据域有两类进程，存储职责完全不同：

| 组装项 | adapter（23 进程） | 聚合层（2 进程） | bootstrap 角色 |
| --- | --- | --- | --- |
| configx（连接配置 + API key/凭据） | ✅ | ✅ | 必封装 |
| observex（Logger/Meter/Tracer/Health） | ✅ | ✅ | 必封装 |
| lifecycx.Manager（采集/接收生命周期） | ✅ | ✅ | 必封装 |
| **7 存储适配器** | ❌ **零存储** | ✅ 全部 | **可选**（Stores 位掩码） |
| DownstreamDispatcher（dispatch port client） | ✅（adapter 独有） | — | adapter 自己实现 |
| 接收侧校验/幂等/排序 | — | ✅（聚合层独有） | 聚合层自己实现 |

**核心**：bootstrap 封装的"通用组装"是 **config + observe + lifecycle 三件套**（25 个进程都要），存储适配器是**聚合层专属的可选件**。

### 13.4 公开 API（拟）

```go
package bootstrap

// Spec 描述一个进程的标准组件清单。
type Spec struct {
    Module    string          // 进程名，如 "binance" / "market-data"
    Stores    StoreSet        // 位掩码；adapter 传 None（零存储），聚合层传 All
    Logger    observex.Logger // 可选注入，否则按 config 自建
    Hooks     []func(*App) error  // 可选 hook（注册自定义组件）
}

// App 是组装后的运行时句柄。
type App struct {
    Config     *configx.Client
    Observe    *Observe           // Logger/Meter/Tracer/Health
    Stores     *Stores            // 启用的存储适配器子集（adapter 时为 nil）
    Resilience *resiliencx.Policy // 默认弹性策略
    Lifecycle  *lifecycx.Manager  // 统一 Start/Stop
}

// Build 是唯一入口：读 config → 建 observex → 建 stores（按 Spec）→ 注册 Manager。
func Build(ctx context.Context, spec Spec) (*App, error)

func (a *App) Run(ctx context.Context) error       // 阻塞 + 信号捕获 + 逆序关闭
func (a *App) Shutdown(ctx context.Context) error
```

**两类进程的 main 对比**：

```go
// adapter（binance）— 零存储，只采集+校验，不落库
func main() {
    app, _ := bootstrap.Build(ctx, bootstrap.Spec{
        Module: "binance",
        Stores: bootstrap.None,           // ★ 零存储（adapter 不碰存储）
    })
    defer app.Shutdown(ctx)

    cl := binanceclient.New(app.Observe, app.Resilience)  // 采集器
    srv := server.New(app.Observe)                         // 接收侧校验（不落库）
    app.Lifecycle.Register(cl.AsComponent(), srv.AsComponent())
    app.Run(ctx)
}

// 聚合层（market-data）— 全存储，唯一写存储者
func main() {
    app, _ := bootstrap.Build(ctx, bootstrap.Spec{
        Module: "market-data",
        Stores: bootstrap.All,           // ★ 全存储
    })
    defer app.Shutdown(ctx)

    receiver := receiver.New(app.Stores, app.Observe)      // 唯一写存储者
    app.Lifecycle.Register(receiver.AsComponent())
    app.Run(ctx)
}
```

服务 main 从 ~150 行裸胶水降到 **5-8 行**。

### 13.5 边界守卫（防 bootstrap 层腐败）

bootstrap 层最大的风险是**范围蔓延**——一旦它开始「帮」服务做 admin HTTP、做采集调度、做 normalize，就会变成第二个 x.go。必须用边界门禁锁死：

| 门禁              | 规则                                                                    | 校验                 |
| ----------------- | ----------------------------------------------------------------------- | -------------------- |
| 禁业务语义        | bootstrap 不得 import domain-market / domain-macro / domainx / contracts | `grep` go.mod 零命中 |
| 禁采集逻辑        | bootstrap 不得 import 任何数据域子模块（binance/fred/…）                 | go.mod 零命中        |
| 禁 transport 实体 | bootstrap 不起 HTTP/gRPC server（仅组装 Component，不起监听）            | 源码无 `net.Listen`  |
| 依赖方向          | bootstrap 只向下依赖 kernel/configx/observex/resiliencx/存储，不向上     | 依赖图扫描           |
| adapter 零存储    | adapter 进程的 `Spec.Stores` 必须为 `None`；`app.Stores` 为 nil          | adapter 不碰存储（§十五） |
| 聚合层独占存储    | 仅 market-data/macro-data 的 `Spec.Stores` 可非 None                     | 存储写入职责归聚合层 |
| 组件可插拔        | Spec.Stores 位掩码控制，未启用的存储不构造不连接                        | 单测验证             |

### 13.6 在分层里的位置

```
┌─ 数据域进程 main（23 adapter + 2 聚合层）──────────────────────────┐
│  app, _ := bootstrap.Build(ctx, Spec{Module, Stores})             │  ← 5-8 行
│  srv := server.New(app.Observe, app.Stores, ...)                  │
│  app.Run(ctx)                                                     │
└──────────────────────────┬────────────────────────────────────────┘
                           │ 调用
                ┌──────────▼──────────┐
                │  bootstrap (L1 新增) │  ← config+observe+lifecycle（必选）
                │                      │    + 7 stores（聚合层可选）
                └──────────┬──────────┘
                           │ 依赖
   ┌───────────────────────▼────────────────────────┐
   │  kernel.lifecycx  configx  observex  resiliencx │
   │  taosx postgresx redisx kafkax natsx ossx       │  ← 现有基座，不动
   │  clickhousex                                     │
   └─────────────────────────────────────────────────┘
```

`bootstrap` 是 **L1 横切能力**，与 configx/observex 平级，不穿透到 L2.5 业务语义层。

### 13.7 与 §五骨架、§八组装层的关系

| 层                                    | 职责                                                           | 现状                             |
| ------------------------------------- | -------------------------------------------------------------- | -------------------------------- |
| `bootstrap`（L1 基座，新建）           | 跨所有进程的通用组装（config+observe+lifecycle+stores 可选）   | **本节新增**                     |
| `internal/infra`（§八，每服务内）     | 本服务专有的注入适配（把 app.Stores/Observe 接到 client/server） | 保留，但瘦身到只剩 wiring.go |
| `cmd/{module}-server/main`（§五骨架） | 调 bootstrap.Build + 起本服务 server                            | 瘦身到 ~8 行                     |

**关键变化**：§八原本设想的 `internal/infra/{config,observe,stores}.go` 三个文件**上提到 bootstrap**，每个进程的 `internal/infra` 只剩 `wiring.go`。adapter 的 wiring.go 不含 stores（无存储），聚合层的才含。

### 13.8 决策记录

| #   | 决策                                                  | 理由                                                                                          |
| --- | ----------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| D8  | 新建 `bootstrap`（L1 薄胶水层），不做重型服务基座      | 证据 A/B 证明 config+observe+lifecycle 在 25 进程重复；存储适配器是聚合层可选件，职责收窄      |
| D9  | bootstrap 禁 import 业务域和领域层                     | 保证它可被数据域+分析域+决策域所有进程复用，不绑死数据域                                       |
| D10 | 每服务 `internal/infra` 保留但瘦身                    | bootstrap 管「通用组装」，internal/infra 管「本服务注入」，职责正交                            |

**一句话定位**：bootstrap 是 L1 通用进程组装层——所有数据域进程（无论 adapter 还是聚合层）共用它组装 config/observe/lifecycle；存储适配器是聚合层专属的可选件，按 `Stores` 位掩码启用。它不碰业务语义、不碰采集、不碰领域模型。

---

## 十四、数据域内部端到端数据流

> `DATAFLOW.md` 已完整定义**分析域→决策域→执行域**的下游流（三引擎：market_engine→S / macro_engine→M / regime_engine→DecisionCard），但**数据域内部**（从交易所 API 到 contracts 端口）的端到端流仍是黑盒。本节补齐这一段。
>
> ⚠️ 本节经 §十五 修正：行情 adapter **不直写存储**，归一化事件经 DownstreamDispatchPort 交给 market-data 接收侧统一落库。

### 14.1 端到端数据流总图

```
┌─ 外部源 ──────────────────────────────────────────────────────────────────────┐
│  行情：Binance WS（@trade/@bookTicker/@kline）  宏观：FRED/ECB REST API（cron）  │
└──────┬─────────────────────────────────────────────────────────────────────────┘
       │ 原始帧/响应
       ▼
┌─ adapter/client 采集端（行情 WS 长连 / 宏观 cron 拉取）★ 零存储 ───────────────┐
│                                                                                │
│  ① catalog    订阅/请求管理（行情 stream 注册、宏观 series 调度）                │
│      ↓                                                                         │
│  ② parser     原始字节 → provider DTO（Binance JSON / FRED JSON）               │
│      ↓                                                                         │
│  ③ normalize  provider DTO → 领域模型（domain-market.Tick/Quote/Bar 或          │
│              domain-macro.MacroPoint），含 Validate（fail-closed 质量门禁）      │
│      ↓                                                                         │
│  ④ mapper     幂等键生成（symbol+ts+seq）、产品线防碰撞                          │
│      ↓                                                                         │
│  ⑤ spool      in-memory 状态机（PENDING→SENT→ACKED/REJECTED），                 │
│              BR-004: checkpoint 仅在 durable ACK 后推进                          │
│      ↓ AcceptedEvent                                                           │
│  ⑥ sender ─── DownstreamDispatchPort ─────────────────────────────────────►    │
└────────────────────────────────────────────────────────────────────────────────┘
                                              │ 归一化事件（Payload []byte）
                    ┌─────────────────────────▼──────────────────────────┐
                    │  market-data / macro-data 接收侧（聚合层）★ 唯一写存储 │
                    │                                                     │
                    │  ⑦ validation    信封校验（symbol/ts/价格边界）       │
                    │      ↓                                              │
                    │  ⑧ idempotency   CheckAndSet（Redis），冲突检测       │
                    │      ↓                                              │
                    │  ⑨ durable ACK   写 PG（lineage/sync_status）        │
                    │      ↓  ACK 回灌 adapter spool，推进 checkpoint     │
                    │  ⑩ dispatch      DownstreamDispatcher（双写）         │
                    └──────┬──────────────────────────┬───────────────────┘
                           │                          │
              ┌────────────▼──────────┐    ┌──────────▼───────────────────────┐
              │  TDengine（实时时序）   │    │  Kafka（数据面 backbone）          │
              │  kline/trades/OB/funding│   │  topic: mkt.{venue}.{kind}        │
              │  → 供在线查询/监控       │    │       mac.{provider}.point        │
              └────────────┬──────────┘    └──────────┬───────────────────────┘
                           │                          │ 物化视图 ETL
                           │              ┌───────────▼───────────┐
                           │              │  ClickHouse（OLAP）    │
                           │              │  → 供回测/分析域批量读  │
                           │              └───────────┬───────────┘
                           │                          │
              ┌────────────▼──────────────────────────▼────────────────┐
              │  contracts 端口（pkg/{module}x 实现）                     │
              │  MarketDataProvider / MacroDataProvider                 │
              │  ↑ 对下游唯一合法接口；下游不直连 TD/CH                    │
              └────────────┬────────────────────────────────────────────┘
                           │
                           ▼  → 喂给 DATAFLOW.md 的分析域三引擎
                 market_engine（→ S State）/ macro_engine（→ M State）
```

**与初稿（§十四 旧版）的关键差异**：采集端（①-⑥）属 adapter，零存储；落库（⑦-⑩）属聚合层，唯一写存储者。两级结构——采集与落库解耦。

### 14.2 7 种持久化在流中的精确位置

| 流阶段 | 写入存储 | 写什么 | 同步/异步 | 失败处理 |
| --- | --- | --- | --- | --- |
| ③ normalize 后 | （无写） | 领域模型仅在内存 | — | Validate 失败 → 丢弃 + metrics |
| ⑤ spool 暂存 | （in-memory） | 待 ACK 事件 | 同步 | 重启丢失（首版；durable 版写 OSS） |
| ⑥ dispatch 交付 | （无写） | AcceptedEvent 经端口交付聚合层 | 同步 | 聚合层不可用 → adapter 退避重试 |
| ⑧ idempotency | **Redis** | 幂等键 CheckAndSet | 同步 | 冲突 → Reject，不重复入库 |
| ⑨ durable ACK | **PostgreSQL** | lineage / sync_status / checkpoint 元数据 | 同步 | 失败 → 不 ACK，adapter 重发 |
| ⑩ dispatch-时序 | **TDengine** | kline/trades/orderbook/funding 超表 | 同步双写 | 失败 → 重试（resiliencx），超限进死信 |
| ⑩ dispatch-流 | **Kafka** | 标准化事件（供下游订阅 + 回放） | 同步双写 | 失败 → 同上 |
| 归档（定时） | **OSS** | 原始响应 parquet、checkpoint 备份 | 异步批次 | 失败 → 重试，不阻塞主流程 |
| 控制面 | **NATS** | health 广播、drain/resync 指令 | 异步 | 失败 → 降级，不影响数据流 |
| ETL（下游） | **ClickHouse** | Kafka 消费 → 物化视图聚合 | 异步 | 最终一致，不阻塞采集 |

**同步关键路径（决定采集延迟）**——全部在聚合层：

```
adapter dispatch 交付 → 聚合层(validation + idempotency + PG ACK) → 双写(TD + Kafka)
```

聚合层内 4 个同步写（Redis 幂等 + PG 元数据 + TD 时序 + Kafka 流）是延迟敏感的；OSS / NATS / ClickHouse 全部异步旁路。adapter 的同步路径止于 dispatch 交付调用。

### 14.3 行情流 vs 宏观流的差异

| 维度 | 行情流（13 adapter） | 宏观流（10 adapter） |
| --- | --- | --- |
| 触发 | WS 长连接推送 + REST 补齐 | schedulex cron 定时拉取 |
| 频率 | 毫秒级（@trade 高频） | 分钟~天级（经济数据发布） |
| normalize 目标 | `domain-market.{Tick,Quote,Bar,OrderBook,Funding}` | `domain-macro.MacroPoint`（含三时间 + 修订版本） |
| 质量门禁 | stale/future gate、bid<ask 校验 | **no-lookahead gate**（IsVisibleAt / AvailableAt fail-closed） |
| 幂等键 | symbol+ts+seq | seriesCode+observedAt+revisionVersion |
| 修订语义 | 无（行情不可变） | 有（RevisionVersion / IsPreliminary，final 覆盖 preliminary） |
| 聚合层 | market-data（已 spec） | macro-data（待建，§十七） |
| Kafka topic | `mkt.{venue}.{kind}` | `mac.{provider}.point` |

### 14.4 双写一致性与回放策略

**TD + Kafka 双写**发生在聚合层（非 adapter），需明确一致性边界：

```
aggregate.dispatch(event):
  1. beginTxn
  2. td.Write(event)        ← 时序库，实时查询用
  3. kafka.Produce(event)   ← 流库，下游订阅 + 回放用
  4. commitTxn / markACK
```

| 场景 | TDengine | Kafka | 一致性策略 |
| --- | --- | --- | --- |
| 正常 | ✅ 写入 | ✅ 写入 | 双写成功才 ACK |
| TD 成功 Kafka 失败 | ✅ | ❌ | 重试 Kafka；超限 → 死信队列 + OSS 存原始事件 |
| TD 失败 | ❌ | — | 整体失败，不 ACK，adapter 重发（幂等键保证不重复） |
| ClickHouse | — | 消费 Kafka | **最终一致**（物化视图异步灌入，可容忍延迟） |

**回放能力**：Kafka 是唯一的可回放源。当 TDengine 需要重建（schema 变更、数据修复），从 Kafka topic 重放即可；ClickHouse 同理。这保证 TDengine 和 ClickHouse 都不是"数据源头"，Kafka 才是——符合 D3。

### 14.5 热温冷数据分层

| 层 | 存储 | 保留期 | 访问模式 | 消费者 |
| --- | --- | --- | --- | --- |
| 热 | Redis（最新报价）+ TDengine（近期时序） | 分钟~天 | 低延迟点查 | 在线监控、策略实时读 |
| 温 | Kafka（可回放事件流） | 7~30 天（按 retention） | 顺序消费 | 分析域 factor-engine、ClickHouse ETL |
| 冷 | ClickHouse（聚合 OLAP）+ OSS（原始归档） | 月~年 | 批量扫描 | 回测 backtest-engine、审计 |

> 对齐 `DATAFLOW.md` 决策日志存储策略（热 7 天 → 温 30 天 → 冷归档 365 天），数据域采用同样的三级分层。

### 14.6 与 DATAFLOW.md 的衔接点

数据域的出口 = 分析域的入口。本节 §14.1 底部的 `contracts.MarketDataProvider / MacroDataProvider` 正是 `DATAFLOW.md` 顶部"数据域"黑盒的展开：

```
DATAFLOW.md 已定义（下游）：          本报告补齐（上游）：
                                      ┌─ 数据域内部流（§14）─────────┐
                                      │ 交易所 → adapter → 聚合层 →    │
                                      │  TD+Kafka → contracts 端口    │
                                      └───────────────┬───────────────┘
                                                      │
market_engine 输入: Bar/Tick/OrderBook ◄──────────────┤ MarketDataProvider
macro_engine  输入: MacroPoint[] ◄────────────────────┘ MacroDataProvider
（经质量门禁）                                          （经 PIT/no-lookahead）
```

两个文件合起来构成完整的"交易所 → 决策"数据链路：本报告负责**采集→标准化→持久化→端口**，DATAFLOW.md 负责**端口→状态识别→决策→执行**。

---

## 十五、架构修正：market-data 接收侧聚合层

> ⚠️ 本节修正 §十四 的一个架构事实。经查 `module/market-data/SPEC.md`，行情数据的接收侧存在一个**独立的 dispatch 聚合层**，13 个 adapter 不直写存储。

### 15.1 事实

`module/market-data`（L3 行情摄取与分发，v1.0.0-spec Docs Baseline）定义了 **DownstreamDispatchPort**：

> `module/binance` 在采集 Binance 原始数据后，**不直接写入存储、队列或策略入口**；它必须通过 downstream dispatch port 将归一化事件交给 `market-data` 接收侧。

binance 已对齐该契约（`internal/server/server.go:136-137`）：

```go
// DownstreamDispatcher sends accepted events to module/market-data.
type DownstreamDispatcher interface {
    Dispatch(ctx context.Context, events []AcceptedMarketEvent) (DispatchOutcome, error)
}
```

### 15.2 修正后的行情数据流

§十四 中"server dispatch 直接双写 TD+Kafka"的表述需修正。实际是**两级结构**：

```
binance/okx/… adapter（13）
  client 采集 + server 验收（校验/幂等/排序键/ack-reject 分类）
     │
     ▼  DownstreamDispatchPort（归一化事件）
market-data 接收侧（聚合层，唯一写存储者）
     │
     ├─► TDengine（时序双写）
     ├─► Kafka（流双写）
     ├─► PG（lineage/sync_status 元数据）
     └─► Redis（缓存/幂等聚合）
              │
              ▼  contracts.MarketDataProvider
          分析域 market_engine（→ S State）
```

**关键变化**：
- adapter 的 server 只做**接收侧校验**（validation/idempotency/排序键），不做最终落库。
- 真正的 TD+Kafka 双写发生在 **market-data 接收侧**，由它统一执行。
- 这保证 23 个 adapter 的落库逻辑**零差异**——全部委托给 market-data，adapter 不各自实现持久化。

### 15.3 对 §十四 同步路径的修正

| 原 §14.2 表述 | 修正 |
| --- | --- |
| ⑩ dispatch-时序：TDengine，由 adapter server 双写 | TDengine 双写由 **market-data 接收侧**执行，adapter 只 Dispatch |
| ⑩ dispatch-流：Kafka，由 adapter server 双写 | 同上，Kafka 双写在 market-data |
| 同步关键路径 4 写全在 adapter | 4 写下沉到 market-data 接收侧；adapter 的同步路径止于 Dispatch 调用 |

### 15.4 修正后的职责分层

| 层 | 职责 | 落库？ |
| --- | --- | --- |
| adapter client（13） | 采集、normalize、质量门禁、spool/checkpoint | ❌ |
| adapter server（13） | 接收侧校验、幂等判定、排序键、ack/reject 分类 | ❌ |
| **market-data 接收侧** | **唯一写存储者**：TD+Kafka 双写、PG 元数据、Redis 缓存 | ✅ |
| contracts 端口 | 对下游（分析域）暴露 MarketDataProvider | ❌ |

这是比 §十四更准确的架构——**采集与落库解耦**，adapter 不知道存储细节，market-data 不知道交易所细节。

---

## 十六、可观测性设计

> bootstrap 组装 `observex` 后，每个数据域服务自动获得统一的日志/指标/追踪/健康能力。本节定义数据域服务的标准可观测输出。

### 16.1 标准指标（observex Meter）

每个数据域服务必须暴露以下指标（label policy 统一，防 Prometheus 高基数）：

| 指标 | 类型 | label | 含义 |
| --- | --- | --- | --- |
| `data_ingest_events_total` | Counter | module, kind, result(ack/reject/fail) | 接收事件总数 |
| `data_ingest_latency_ms` | Histogram | module, kind | normalize→ACK 端到端延迟 |
| `data_dispatch_lag_ms` | Histogram | module, store(td/kafka/pg) | dispatch 到各存储的写入延迟 |
| `data_spool_depth` | Gauge | module | 待 ACK 的 spool 深度（背压信号） |
| `data_stale_rejected_total` | Counter | module, reason(stale/future/dirty) | 质量门禁拒绝数 |
| `data_store_health` | Gauge | module, store | 存储连通健康（1=ok/0=down） |
| `data_idempotency_conflicts_total` | Counter | module | 幂等冲突数（重复事件） |

**label 基数控制**（observex 内建 label policy）：
- `kind` 固定枚举：kline/trade/quote/orderbook/funding（行情）/point（宏观），不开放任意值。
- **禁止** symbol 进 label（高基数），symbol 只进日志/trace。
- `module` 固定 23 个服务名。

### 16.2 标准日志（observex Logger）

| 事件 | level | 必含字段 |
| --- | --- | --- |
| 服务启动/关闭 | INFO | module, version, config_hash |
| 采集连接建立/断开 | INFO/WARN | module, stream, venue |
| 质量门禁拒绝 | WARN | module, reason, symbol, event_time |
| dispatch 失败 | ERROR | module, store, error, retry_count |
| 幂等冲突 | WARN | module, idempotency_key |
| 存储健康翻转 | WARN/ERROR | module, store, old_state, new_state |

所有含 `*_PASSWORD` / `*_KEY` / `*_SECRET` 的字段经 configx SecretString 自动脱敏为 `***`。

### 16.3 健康检查（observex Health）

每个服务暴露统一 `/health` JSON（bootstrap 组装时注册）：

```json
{
  "status": "ready",
  "module": "binance",
  "version": "v0.2.0",
  "components": {
    "tdengine": "ok",
    "postgres": "ok",
    "redis": "ok",
    "kafka": "degraded",
    "nats": "ok"
  },
  "config_hash": "sha256:..."
}
```

NATS 控制面订阅 `svc.{module}.health`，编排层（x.go）聚合 23 服务的健康状态。

### 16.4 分布式追踪（observex Tracer）

行情/宏观事件跨进程链路：`adapter client → adapter server → market-data 接收侧 → 存储`。trace_id 经 context 传播，确保一条 @trade 事件从交易所到落库可完整串联（解决 observex §2 描述的"跨 3 模块需人工拼接日志行"问题）。

---

## 十七、宏观聚合层缺口（macro-data 待建）

> 经查 `module/`：行情侧有 `market-data`（L3 接收侧聚合 spec）；宏观侧 **`macro-data` 聚合层 SPEC 缺失**。
>
> ⚠️ **核实修正**：`contracts` 已完整定义 `MacroDataProvider` 端口（SPEC §8.1 / FR-002，三方法签名齐全），**端口无需补**。真正的缺口是 `macro-data` 模块的**接收侧 SPEC 文档**（镜像 market-data）。

### 17.1 核实后的缺口矩阵

| 模块 | SPEC 文档 | 运行时代码 | 端口（contracts） | 状态 |
| --- | --- | --- | --- | --- |
| `contracts` | ✅ v1.2.0 | spec-only（仅 go.mod） | ✅ MacroDataProvider **已定义**（§8.1） | 端口就绪，待实现 |
| `market-data` | ✅ v1.0.0（DownstreamDispatchPort） | spec-only（无 /home/market-data） | ✅ MarketDataProvider 已定义 | 接收侧规格就绪，待实现 |
| `macro-data` | **❌ 不存在**（module/macro-data/ 无） | — | ✅ 端口已在 contracts，**无接收侧实现者** | **聚合层 SPEC 缺失** |

| 域 | 采集 adapter | 接收侧聚合层 | 状态 |
| --- | --- | --- | --- |
| 行情 | binance/okx/…（13） | `market-data`（DownstreamDispatchPort） | ✅ Docs Baseline |
| 宏观 | fred/bea/ecb/…（10） | **`macro-data`（SPEC 缺失）** | ❌ 待建 SPEC |

### 17.2 影响

若不补 `macro-data`，10 个宏观 adapter 要么：
- (a) 各自直写存储 → 违反 §十五 的"采集与落库解耦"原则，10 份落库逻辑复制；或
- (b) 复用行情的 `market-data` → 语义不符（MacroPoint ≠ MarketEvent，质量门禁不同：no-lookahead vs stale gate）。

### 17.3 建议

新建 `macro-data`（L3 宏观摄取与分发），镜像 `market-data` 的接收侧设计：

| 维度 | market-data（行情） | macro-data（宏观，拟建） |
| --- | --- | --- |
| 端口 | DownstreamDispatchPort | MacroDispatchPort |
| 事件 | AcceptedMarketEvent（Tick/Quote/Bar/OB） | AcceptedMacroEvent（MacroPoint） |
| 质量门禁 | stale/future/bid<ask | **no-lookahead**（IsVisibleAt/AvailableAt） |
| 排序键 | symbol+ts+seq | seriesCode+observedAt+revisionVersion |
| 落库 | TD+Kafka+PG+Redis | 同（per-provider macro_* 库） |

这应纳入 P0 前置（contracts 端口已就绪，只差 macro-data 接收侧 SPEC），否则宏观 adapter 无法按统一架构落地。

### 17.4 修正后的完整模块清单

数据域实际是 **行情 13 adapter + 1 聚合 + 宏观 10 adapter + 1 聚合（待建）+ 另类**：

```
行情：13 adapter（binance…coinglass） → market-data（1 聚合层）→ 存储
宏观：10 adapter（fred…yahoo）       → macro-data（1 聚合层，待建）→ 存储
另类：alternative-data（已规划）
```

---

## 十八、实施顺序与验收门禁

### 18.1 修正后的落地顺序（P0-P6 + P1.5）

```
P0  contracts 端口已就绪（MacroDataProvider §8.1）；macro-data 接收侧聚合层 SPEC（§十七）
 │
 ├─► P1  CS 模板固化（adapter 骨架 + internal/infra 瘦身版）
 │
 ├─► P1.5  bootstrap 薄胶水层（§十三）
 │
 ├─► P2  旧模块迁移（23 go.mod 切细粒度基座，废弃 xlib-standard）
 │        ├─ 行情 13：迁 domain-market + 经 market-data dispatch
 │        └─ 宏观 10：迁 domain-macro + 待 macro-data 落地
 │
 ├─► P3  配置注入（dev.md → .env → bootstrap configx EnvSource）
 │
 ├─► P4  持久化接通（market-data/macro-data 接收侧落库，非 adapter）
 │
 ├─► P5  边界门禁（23 套 boundary-gates.sh）
 │
 └─► P6  编排（x.go 组合根 + bootstrap 拉起 23 服务）
```

### 18.2 每阶段验收门禁

| 阶段 | 门禁 | 验证方式 |
| --- | --- | --- |
| P0 | MacroDataProvider 已在 contracts v1.2（✅ 就绪）；macro-data 接收侧 SPEC Approved | 四源评分 ≥98 + arbiter pass |
| P1 | CS 模板可 `cp -r` 新建模块，boundary-gates 全绿 | 新建 1 个空壳模块跑通门禁 |
| P1.5 | bootstrap v0.1.0 发布，binance 接入后 main ≤10 行 | bootstrap 5 道边界门禁全绿 |
| P2 | 23 个 go.mod 零 `xlib-standard`，全依赖 v1.0+ | `grep xlib-standard` 零命中 |
| P3 | 23 服务各自只连自己的 per-provider 库 | 库隔离连通测试（跨库连接被拒） |
| P4 | market-data 接收侧 TD+Kafka 双写成功才 ACK | 双写一致性测试（§14.4 场景表） |
| P5 | 23 服务 boundary-gates CI 全绿 | client↔server 隔离 + 跨模块禁 import |
| P6 | x.go 单进程拉起 23 服务，健康检查全 ready | /health 聚合 23 服务 status=ready |

### 18.3 与治理管线对齐

本方案推进为正式实现时，每个模块（bootstrap / macro-data / 23 adapter 迁移）都必须走 AGENTS.md 的 Spec→Code 管线：

```
Spec → Matrix → Tasks → Plan → Prompt → Code
每阶段四源评分 composite_score = min(claude, codex, copilot, rules) ≥ 98 + 无红线
```

`bootstrap` 和 `macro-data` 作为受保护的新基座/聚合层模块，其 SPEC/RUBRIC 改进还须遵守 CONSTITUTION §14（受控递归改进），进入 `docs/governance/improvements/{date}-{slug}/SPEC.md`。

---

## 十九、决策记录总表（D1-D14）

| # | 决策 | 章节 |
| --- | --- | --- |
| D1 | 23 子模块统一 CS 骨架 | §五 |
| D2 | go.mod 切细粒度基座，废弃 xlib-standard | §六 |
| D3 | 7 存储职责分层，Kafka=数据面/NATS=控制面正交，TD=CH 互补 | §四 |
| D4 | per-provider 库级隔离 | §七 |
| D5 | 凭据经 configx EnvSource + SecretString 注入 | §七 |
| D6 | 对下游只暴露 contracts 端口 | §四/§十四 |
| D7 | 通用组装逻辑上提到 bootstrap | §十三 |
| D8 | 新建 bootstrap（L1 薄胶水层），不做重型基座 | §十三 |
| D9 | bootstrap 禁 import 业务域和领域层 | §十三 |
| D10 | 每服务 internal/infra 保留但瘦身 | §十三 |
| **D11** | **行情 adapter 经 market-data 接收侧落库，不直写存储（修正 §十四）** | **§十五** |
| **D12** | **宏观侧需新建 macro-data 聚合层，镜像 market-data 设计** | **§十七** |
| **D13** | **数据域标准指标 label 禁 symbol（高基数），kind 固定枚举** | **§十六** |
| **D14** | **TD+Kafka 双写一致性由 market-data/macro-data 接收侧统一保证，非各 adapter** | **§十五** |


---

## 附：关键文件引用

| 文档         | 路径                                       | 用途                                                          |
| ------------ | ------------------------------------------ | ------------------------------------------------------------- |
| 配置源       | `sre/secrets/env/dev.md`                   | per-provider per-DB 凭据（明文，需脱敏注入）                  |
| 架构权威     | `ARCHITECTURE.md`                          | 分层、依赖拓扑、状态总览（L363-410 数据域清单）               |
| 治理权威     | `CONSTITUTION.md`                          | §0 分支纪律、设计原则、CRI                                    |
| 依赖矩阵     | `module/FOUNDATION-DEPS.yaml`              | 机器可读依赖边守卫                                            |
| **数据流**   | **`DATAFLOW.md`**                          | **分析域→决策域→执行域下游流（本报告 §十四 补齐数据域上游）** |
| 跨域契约     | `module/contracts/SPEC.md`                 | MarketDataProvider + **MacroDataProvider 已定义**（§8.1）     |
| **行情聚合** | **`module/market-data/SPEC.md`**           | **DownstreamDispatchPort 接收侧（唯一写存储者，§十五）**      |
| **宏观聚合** | **`module/macro-data/`（待建，§十七）**    | **宏观接收侧聚合层缺口**                                      |
| 配置约定     | `module/configx/SPEC.md`                   | SecretString / EnvSource / Provenance                         |
| 可观测       | `module/observex/SPEC.md`                  | Logger/Meter/Tracer/Health 接口（§十六）                      |
| 生命周期     | `/home/kernel/lifecycx/lifecycx.go`        | Component/Manager（bootstrap 的编排基础，已存在）              |
| 行情领域     | `module/domain-market/SPEC.md`             | Tick/Quote/Bar SSOT                                           |
| 宏观领域     | `module/domain-macro/SPEC.md`              | MacroPoint / no-lookahead 语义                                |
| C/S 模板     | `/home/binance/`（cmd/internal/pkg）       | 已落地的行情 CS 参考实现                                      |
| 宏观参考     | `/home/fred/`                              | 宏观模块结构（✅ P2 迁移 + bootstrap 接入完成）                 |

---

_报告结束（19 节）。下一步建议优先级：**P0**（macro-data 接收侧聚合层 SPEC；contracts 端口已就绪）→ **P1**（CS 模板）→ **P1.5**（bootstrap 薄胶水层）→ P2-P6。每阶段走 Spec→Code 四源 98 分门禁。_
