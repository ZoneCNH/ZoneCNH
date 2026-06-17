# 数据域 CS 模块 Bootstrap SOP

> 从 binance 骨架到 23 个 adapter 的标准化落地手册
>
> 版本: v1.0.0 | 最后更新: 2026-06-17
> 关联: [数据域基础架构报告](../report/data-domain-infrastructure-20260617.md)、[market-data SPEC](../../module/market-data/SPEC.md)、[macro-data SPEC](../../module/macro-data/SPEC.md)
> 分支纪律: 本 SOP 是新增模块的落地参照，所有新模块仍须走 CONSTITUTION §0 分支纪律 + Spec→Code 管线

---

## 一、本 SOP 解决什么问题

数据域有 23 个独立 CS 服务（行情 13 + 宏观 10）。若每个开发者各自设计目录结构、go.mod、边界门禁，会导致：

- 目录结构不一致，code review 难以横向对比
- go.mod 依赖漂移（有的用旧 xlib-standard，有的用细粒度基座）
- 边界门禁缺失或各写各的
- bootstrap 组装逻辑逐字复制

本 SOP 以已落地的 `binance` 为参照，固化一套**可复制的结构清单 + 分步落地流程**，使新增模块的成本 = 实现采集器 + 配置注入，基座组装零差异。

**SOP 定位**：本文件是**文档参照**，不含可执行脚手架代码（避免引入未经验证的占位 .go）。开发者照本清单 `cp -r` binance 后按步骤替换。

---

## 二、角色与前置条件

| 角色 | 模块 | 状态 |
| --- | --- | --- |
| **参照实现** | `binance`（行情 C/S Module） | ✅ 完整可编译 v0.2.0（bootstrap 接入 + build/test/gates 全通过） |
| **行情聚合层** | `market-data`（DownstreamDispatchPort 接收侧） | ✅ Docs Baseline v1.0.0 |
| **宏观聚合层** | `macro-data`（MacroDispatchPort 接收侧） | ✅ Docs Baseline v0.1.0 |
| **跨域端口** | `contracts`（MarketDataProvider + MacroDataProvider §8.1） | ✅ v1.2.0 已定义 |
| **行情领域** | `domain-market`（Tick/Quote/Bar/OrderBook） | ✅ v1.1.0 |
| **宏观领域** | `domain-macro`（MacroPoint 三时间 + revision） | ✅ v1.0.0 |

**新建 adapter 前必须确认**：
- [ ] 对应聚合层 SPEC 已存在（行情→market-data，宏观→macro-data）
- [ ] 对应领域模型已发布（行情→domain-market，宏观→domain-macro）
- [ ] contracts 端口已定义（两者均已就绪）

---

## 三、标准目录结构清单

以下结构从 binance 实测抽取，所有 23 个 adapter **必须遵循**。`{module}` = 适配的交易所/provider 名（如 okx、fred）。

```
{module}/                          # 独立 git 仓库 github.com/ZoneCNH/{module}
├── go.mod                         # §四 统一依赖模板
├── .env.example                   # XGO_{MODULE}_* 占位模板（不含真值）
├── .gitignore                     # 至少含 .env
├── README.md                      # 模块角色 + 架构 + 构建/测试命令
├── cmd/
│   ├── {module}-server/
│   │   └── main.go                # 独立服务入口（§六 bootstrap.Build 接入）
│   └── {module}-smoke/
│       └── main.go                # 同进程端到端冒烟（client+server wire 特例）
├── internal/
│   ├── cs/                        # client/server 共享契约（临时自包含层）
│   │   ├── doc.go                 # ★ 注释标注 "source of truth 在 contracts/domain-*"
│   │   └── types.go               # IngestRequest/IngestResult/RejectCode（待 contracts 替换）
│   ├── client/                    # ★ 采集端（零存储）
│   │   ├── doc.go
│   │   ├── catalog.go             # 订阅/请求管理（行情 stream 注册、宏观 series 调度）
│   │   ├── parser.go              # 原始字节 → provider DTO
│   │   ├── normalize.go           # provider DTO → 领域模型 + Validate（fail-closed）
│   │   ├── mapper.go              # 幂等键生成、产品线/series 防碰撞
│   │   ├── spool.go               # in-memory 状态机（PENDING→SENT→ACKED/REJECTED）
│   │   ├── checkpoint.go          # ★ BR-004: 仅在 durable ACK 后推进
│   │   ├── sender.go              # IngestClient port → 提交 server
│   │   ├── admin.go               # client 侧 admin（health/stream 管理）
│   │   └── {connector}.go         # 交易所/provider 专属采集器（如 spot.go / fred_api.go）
│   ├── server/                    # ★ 验收端（零存储，只校验+dispatch）
│   │   ├── doc.go
│   │   ├── server.go              # IngestServer + IdempotencyStore/Dispatcher 接口
│   │   ├── ingest.go              # 信封校验、ack/reject 分类
│   │   ├── idempotency.go         # in-memory 幂等（CheckAndSet + 冲突检测）
│   │   ├── dispatch.go            # DownstreamDispatcher port（→ market-data/macro-data）
│   │   └── admin.go               # server 侧 admin（healthz/readyz/streams/drain）
│   └── infra/                     # §七 本服务注入适配（瘦身后）
│       └── wiring.go              # 把 bootstrap 返回的 *App 注入 client/server
├── pkg/
│   └── {module}x/                 # ★ 对外契约实现（contracts 端口）
│       ├── doc.go
│       ├── adapter.go             # VenueAdapter / MacroProvider 实现
│       └── version.go             # 版本常量
├── scripts/
│   └── boundary-gates.sh          # §八 CI 边界门禁（9 道，参数化 module 名）
└── test/
    └── e2e/
        └── e2e_test.go            # mock 源 → client → server → sink
```

### 行情 vs 宏观子结构差异

| 文件 | 行情 adapter | 宏观 adapter |
| --- | --- | --- |
| `client/{connector}.go` | `spot.go`（WS 长连 + REST） | `fred_api.go`（REST cron 拉取） |
| `client/normalize.go` 目标 | `domain-market.Tick/Quote/Bar` | `domain-macro.MacroPoint`（三时间 + revision） |
| `cs/types.go` 事件类型 | trade/quote/bar | point（宏观只有点） |
| `server/dispatch.go` 目标 | `market-data` DownstreamDispatchPort | `macro-data` MacroDispatchPort |
| `pkg/{module}x` 实现 | `contracts.MarketDataProvider` | `contracts.MacroDataProvider` |
| 质量门禁 | stale/future/bid<ask | **no-lookahead**（AvailableAt fail-closed） |

---

## 四、go.mod 依赖模板

> 详见 [基础架构报告 §六](../report/data-domain-infrastructure-20260617.md#六统一-gomod-依赖模板消除差距-22)。要点：

**所有 adapter 的 go.mod 必须包含**：
- `kernel` / `configx` / `observex` / `resiliencx` / `schedulex`（L0/L1 基座）
- `bootstrap`（L1 组装层，P1.5 发布后）+ `Stores: None`（**adapter 零存储**）
- 领域 SSOT：行情 `domain-market` + `domain-exchange` / 宏观 `domain-macro`
- `contracts`（跨域端口）
- `decimalx`（精度）

**禁止**：
- ❌ `xlib-standard`（标准源不参与运行时 import）
- ❌ 任何 L2 存储适配器（`taosx`/`postgresx`/`redisx`/`kafkax`/`natsx`/`ossx`/`clickhousex`）——adapter 零存储，存储归聚合层
- ❌ 其他 adapter 模块（`okx` 不得 import `binance`）

---

## 五、bootstrap 组装接入（adapter 零存储）

> `bootstrap`（L1 薄胶水层，[报告 §十三](../report/data-domain-infrastructure-20260617.md#十三bootstrap--进程启动组装层)）封装 config+observe+lifecycle。adapter 的 `Spec.Stores` **必须为 `None`**。

`cmd/{module}-server/main.go` 标准形态：

```go
package main

func main() {
    ctx := context.Background()
    app, err := bootstrap.Build(ctx, bootstrap.Spec{
        Module: "{module}",
        Stores: bootstrap.None,           // ★ adapter 零存储
    })
    if err != nil { log.Fatal(err) }
    defer app.Shutdown(ctx)

    // internal/infra/wiring.go 负责注入
    svc := infra.Wire(app)                // → 返回 *Service{Client, Server, Adapter}

    app.Lifecycle.Register(svc.Client.AsComponent(), svc.Server.AsComponent())
    app.Run(ctx)                          // bootstrap 管信号 + 逆序 Stop
}
```

**binance 已接入 bootstrap**（v0.2.0）：main.go 使用 `bootstrap.Build(Stores=None)` + `app.Run(ctx)`。其余 22 adapter 已批量接入同形态。binance 是 golden path 参照（PR #7 + #8）。

> bootstrap 发布前（P1.5 前）的过渡方案：adapter main.go 仍可用裸 `signal.NotifyContext`，但 configx + observex 的加载逻辑应集中在 `internal/infra/config.go`（临时），bootstrap 发布后上提。

---

## 六、`internal/infra/wiring.go` 标准形态

bootstrap 组装好 `*App`（config+observe+lifecycle）后，wiring.go 负责把 App 注入本服务的 client/server/adapter：

```go
package infra

func Wire(app *bootstrap.App) *Service {
    cl := client.New(app.Observe, app.Resilience)     // 采集器
    srv := server.New(app.Observe)                      // 验收端（零存储）
    adapter := modulex.New(srv, app.Observe)            // pkg/{module}x 对外契约

    return &Service{Client: cl, Server: srv, Adapter: adapter}
}

type Service struct {
    Client  *client.Client
    Server  *server.IngestServer
    Adapter *modulex.Adapter
}
```

**关键**：wiring.go 不含 config/observe/stores 构造（已由 bootstrap 完成），只做注入映射。adapter 的 wiring.go **不含任何 stores 引用**（零存储）。

---

## 七、配置注入（dev.md → adapter）

> 详见 [基础架构报告 §七](../report/data-domain-infrastructure-20260617.md#七配置注入方案devmd--服务)。

### 7.1 `.env.example` 标准模板

```bash
# {module} adapter 环境变量模板
# 复制为 .env 后填入实际值（.env 已在 .gitignore 中）

# ---- 交易所/Provider API（按需）----
XGO_{MODULE}_API_KEY=
XGO_{MODULE}_API_SECRET=
XGO_{MODULE}_MODE=testnet              # 行情：testnet/mainnet

# ---- Dispatch 目标（聚合层）----
XGO_{MODULE}_DISPATCH_TARGET=market-data   # 行情；宏观用 macro-data
XGO_{MODULE}_DISPATCH_ADDR=:9090            # 聚合层接收侧地址

# ---- 可观测（bootstrap 统一加载）----
XGO_{MODULE}_LOG_LEVEL=info
XGO_{MODULE}_METRICS_ADDR=:9091
```

> 注意：adapter **不持有任何存储凭据**（PG/TD/Redis/Kafka/OSS/CH）。存储凭据属于聚合层（market-data/macro-data）的 .env，不属于 adapter。

### 7.2 configx 加载

bootstrap.Build 内部完成（adapter 无需自写 config 加载）。所有 `*_PASSWORD`/`*_SECRET`/`*_KEY` 自动 SecretString 脱敏。

---

## 八、boundary-gates.sh 标准 9 道

从 binance `scripts/boundary-gates.sh` 抽取，参数化为通用模板。所有 adapter **必须包含**这 9 道（或等价）：

| 门禁 | 规则 | 说明 |
| --- | --- | --- |
| §2 no-legacy | 无遗留模块引用（如 binance-market） | 历史迁移清理 |
| §3 client-no-server | `internal/client/**` 不 import `internal/server/**` | C/S 隔离 |
| §4 server-no-client | `internal/server/**` 不 import `internal/client/**` | C/S 隔离 |
| §4b server-cmd-no-client | `cmd/{module}-server` 不 import client | server 入口纯净 |
| §5 no-storage-query-strategy | 不 import storage/query/strategy | 边界纯净 |
| §6 no-local-proto | 无 .proto 文件（wire schema 归 contracts） | 契约归一 |
| §7 no-canonical-ssot-claim | 不声明自己是 canonical SSOT（归 domain-*） | 领域归一 |
| §8 no-xlib-standard | go.mod 无 `xlib-standard` | 标准源不参与运行时 |
| §9 no-storage-adapter | go.mod 无 L2 存储适配器 | **adapter 零存储**（§十五 核心） |

> §8、§9 是相对 binance 现版的新增门禁（报告 §十三/§十五 修正后的要求）。

**适配方法**：`cp binance/scripts/boundary-gates.sh`，把脚本内 `binance` / `binance-market` / `ZoneCNH/binance` 全局替换为 `{module}` / `{module}-market`（如适用）/ `ZoneCNH/{module}`。

---

## 九、分步落地流程（新增 adapter 的 SOP）

以新增一个行情 adapter（如 `okx`）为例：

### Step 0 — 前置确认

- [ ] market-data SPEC 存在（✅）
- [ ] domain-market v1.1.0 发布（✅）
- [ ] contracts MarketDataProvider 定义（✅ §8.1）
- [ ] 从 main HEAD 创建 feature branch

### Step 1 — 复制骨架

```bash
cp -r /home/binance /home/{module}        # 复制结构（不含 .git）
cd /home/{module}
```

### Step 2 — 全局替换标识

```bash
# 替换模块名（注意大小写）
find . -type f -not -path './.git/*' | xargs sed -i \
  -e 's/ZoneCNH\/binance/ZoneCNH\/{module}/g' \
  -e 's/binance-server/{module}-server/g' \
  -e 's/binance-smoke/{module}-smoke/g' \
  -e 's/binancex/{module}x/g'
```

### Step 3 — go.mod 对齐模板

- 按报告 §六.1（行情）/ §六.2（宏观）模板重写 go.mod
- 确认无 xlib-standard、无存储适配器
- 升级依赖到已发布版本（domain-market v1.1.0 等）

### Step 4 — 实现采集器（唯一真正的工作）

| 行情 | 宏观 |
| --- | --- |
| `client/{connector}.go`：交易所 WS/REST | `client/{connector}.go`：provider REST cron |
| `client/parser.go`：交易所 JSON → DTO | `client/parser.go`：provider JSON → DTO |
| `client/normalize.go`：DTO → domain-market | `client/normalize.go`：DTO → domain-macro（**含 AvailableAt 标注**） |
| `client/mapper.go`：symbol 防碰撞 | `client/mapper.go`：seriesCode 防碰撞 |

**这是新增模块唯一需要从零编写的部分**——其余结构、门禁、组装全部复用。

### Step 5 — 接入 bootstrap（P1.5 后）

- `cmd/{module}-server/main.go` 改为 §五 标准形态
- `internal/infra/wiring.go` 按 §六 实现
- bootstrap P1.5 前：临时用裸 signal + internal/infra/config.go

### Step 6 — 边界门禁

- `cp scripts/boundary-gates.sh`，全局替换 binance → {module}
- 补 §8（no-xlib-standard）、§9（no-storage-adapter）两道
- `./scripts/boundary-gates.sh` 全过

### Step 7 — 验证

```bash
go build ./...
go test ./... -race -count=1
./scripts/boundary-gates.sh
```

### Step 8 — 走 Spec→Code 管线

按 AGENTS.md：Spec → Matrix → Tasks → Plan → Prompt → Code，每阶段四源 98 分门禁。

---

## 十、宏观 adapter 额外注意事项

宏观 adapter（fred/bea/ecb/…）相对行情 adapter 的增量要求：

| 项 | 行情 | 宏观增量 |
| --- | --- | --- |
| normalize 输出 | domain-market 类型 | domain-macro.MacroPoint（**必须设 AvailableAt**） |
| 质量门禁 | stale/future | **+ no-lookahead**（AvailableAt fail-closed，对齐 BR-MAC-001） |
| dispatch 目标 | market-data | macro-data（MacroDispatchPort，PR #687） |
| revision 语义 | 无 | RevisionVersion / IsPreliminary 标注 |
| e2e 测试 | mock WS | mock REST + cron 触发 |

**宏观第一红线**：normalize 阶段必须为每个 MacroPoint 设置 AvailableAt。缺失 AvailableAt 的点会被 macro-data 接收侧的 no-lookahead gate 拒绝（`lookahead_violation`）。adapter 有责任从 provider 响应推断 AvailableAt（如 FRED 的 `realtime_start`），缺失时不得提交。

---

## 十一、自检清单（落地前 Checklist）

新增 adapter 提交 PR 前，逐项确认：

- [ ] 目录结构符合 §三（cmd/internal{cs,client,server,infra}/pkg/scripts/test）
- [ ] go.mod 符合 §四（无 xlib-standard、无存储适配器、无其他 adapter）
- [ ] client 不 import server，server 不 import client（§八 §3/§4）
- [ ] cs/types.go 有 "source of truth 在 contracts/domain-*" 注释（§八 §7）
- [ ] **adapter 零存储**：go.mod 无 taosx/postgresx/redisx/kafkax/natsx/ossx/clickhousex（§八 §9）
- [ ] .env.example 不含存储凭据（仅 API key + dispatch 目标）
- [ ] boundary-gates.sh 9 道全过（含 §8/§9 新增）
- [ ] `go build ./...` + `go test ./... -race` 通过
- [ ] 宏观 adapter：normalize 输出含 AvailableAt（§十）
- [ ] 走 Spec→Code 管线

---

## 附：参照文件

| 文件 | 用途 |
| --- | --- |
| `/home/binance/` | 已落地的行情 C/S 参照实现（2971 行） |
| `/home/binance/scripts/boundary-gates.sh` | 9 道边界门禁参照脚本 |
| `/home/binance/internal/cs/types.go` | 临时自包含契约层参照 |
| `module/market-data/SPEC.md` | 行情聚合层 DownstreamDispatchPort |
| `module/macro-data/SPEC.md` | 宏观聚合层 MacroDispatchPort |
| `../report/data-domain-infrastructure-20260617.md` | 数据域基础架构报告（§五骨架/§六go.mod/§七配置/§十三bootstrap/§十五聚合层） |
| `module/contracts/SPEC.md` | MarketDataProvider + MacroDataProvider（§8.1） |

---

*SOP 结束。新增模块按 §九 分步流程落地；唯一从零编写的是采集器（Step 4），其余复用。*
