# 组合根设计 — 数据域进程编排

> 日期: 2026-06-17
> 分析对象: P6 编排 — 如何用 bootstrap 拉起 23 adapter + 2 聚合层
> 关联: [数据域基础架构报告 §十三](data-domain-infrastructure-20260617.md)、[Bootstrap SOP](../sre/data-domain-bootstrap.md)、[bootstrap SPEC](../../module/bootstrap/SPEC.md)
> 分支: `docs/p6-composition-root-design-20260617`

---

## 一、问题

数据域有 25 个进程（23 adapter + market_data + macro_data）。当前各进程可独立编译，但缺少一个**组合根（Composition Root）**来：

1. 统一拉起全部进程
2. 注入共享配置（configx）和可观测（observex）
3. 管理进程拓扑（启动顺序、依赖关系、健康聚合）
4. 统一信号处理与优雅关闭

> ⚠️ **重要澄清**：`github.com/ZoneCNH/x.go` 仓库实际上是 **xlib_standard 标准源仓库**（module `github.com/ZoneCNH/xlib_standard`），不是组合根应用。ARCHITECTURE.md 里的"x.go 组合根"指的是**未来要建的组合根**，当前不存在。

---

## 二、组合根定位

```
┌─ composer（组合根应用，待建）──────────────────────────────────┐
│                                                                │
│  cmd/composer/main.go                                          │
│    ├─ 加载全局配置（dev.md → configx）                          │
│    ├─ 按 Spec 清单构造进程拓扑                                  │
│    ├─ 逐进程 bootstrap.Build（注入 config/observe/lifecycle）    │
│    ├─ 注入各进程的 adapter/receiver                             │
│    ├─ 启动顺序控制（聚合层先于 adapter）                         │
│    ├─ 健康聚合（聚合 25 进程 /health → 全局状态）                │
│    └─ 信号处理（SIGTERM → 逆序 Stop）                           │
│                                                                │
│  拉起 25 个进程：                                                │
│    行情 13: binance/okx/.../coinglass（bootstrap.Stores=None）   │
│    宏观 10: fred/bea/.../yahoo（bootstrap.Stores=None）          │
│    行情聚合 1: market_data（bootstrap.Stores=All + Receiver）    │
│    宏观聚合 1: macro_data（bootstrap.Stores=All + Receiver）     │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**组合根不实现业务逻辑**——它只做组装和编排。业务逻辑在各 adapter 和聚合层内。

---

## 三、进程拓扑与启动顺序

```
启动顺序（自底向上）：

Phase 1: 基础设施
  TDengine / PostgreSQL / Redis / Kafka / NATS / OSS / ClickHouse
  （外部服务，组合根只做健康探测，不启动）

Phase 2: 聚合层（先启动，监听 dispatch port）
  market_data Receiver（bootstrap.Stores=All）
  macro_data Receiver（bootstrap.Stores=All）

Phase 3: Adapter（后启动，向聚合层 dispatch）
  binance / okx / ... / coinglass（bootstrap.Stores=None）
  fred / bea / ... / yahoo（bootstrap.Stores=None）

关闭顺序（逆序）：

Phase 3: Adapter 先停（停止采集，drain spool）
Phase 2: 聚合层后停（完成 in-flight dispatch，flush 存储）
Phase 1: 基础设施（外部管理，不关）
```

**关键约束**：聚合层必须先于 adapter 启动——adapter 的 dispatch port 需要聚合层已就绪，否则 dispatch 失败（DispatchFailure，adapter 退避重试）。

---

## 四、依赖注入拓扑

每个进程经 `bootstrap.Build` 获得基础组装（config/observe/lifecycle），然后由组合根注入业务组件：

```go
// 组合根伪代码（设计参考，不实现）
func main() {
    ctx := context.Background()

    // Phase 2: 聚合层
    mdApp := bootstrap.Build(ctx, bootstrap.Spec{
        Module: "market_data",
        Stores: bootstrap.All,
    })
    mdReceiver := dispatch.NewReceiver(
        mdApp.SinkPort(),          // 生产 SinkPort（双写 TD+Kafka，待实现）
        mdApp.IdempotencyStore(),  // Redis
        mdApp.OrderingTracker(),   // Redis
    )
    mdApp.Lifecycle.Register(mdReceiver.AsComponent())

    macApp := bootstrap.Build(ctx, bootstrap.Spec{
        Module: "macro_data",
        Stores: bootstrap.All,
    })
    // macro_data Receiver 同理（镜像 market_data）

    // Phase 3: Adapter
    for _, adapter := range adapterList {
        app := bootstrap.Build(ctx, bootstrap.Spec{
            Module: adapter.Name,
            Stores: bootstrap.None,   // adapter 零存储
        })
        client := adapter.NewClient(app.Observe)
        server := adapter.NewServer(app.Observe, mdReceiver)  // 注入 dispatch port
        app.Lifecycle.Register(client.AsComponent(), server.AsComponent())
    }

    // 信号处理
    waitForSignal()
    // 逆序 Shutdown
}
```

---

## 五、配置拓扑

组合根加载全局配置后，为每个进程生成 per-provider 子配置：

```
composer 配置树:
  global:
    tdengine: {host, port, ...}
    postgresql: {host, port, ...}
    redis: {host, port, ...}
    kafka: {brokers, ...}
    nats: {url, ...}
    oss: {endpoint, bucket, ...}
    clickhouse: {host, port, ...}

  adapters:
    binance:
      api_key: <XGO_BINANCE_API_KEY>
      dispatch_target: market_data:9090
    fred:
      api_key: <XGO_FRED_API_KEY>
      dispatch_target: macro_data:9090
    ...

  aggregates:
    market_data:
      stores: [td, pg, redis, kafka]
    macro_data:
      stores: [td, pg, redis, kafka]
```

聚合层用 `bootstrap.Stores=All` 获取 7 存储连接；adapter 用 `bootstrap.Stores=None` 只获取 config/observe。per-provider 凭据经 gen-env.sh 生成。

---

## 六、健康聚合

组合根暴露 `/health` 聚合 25 进程状态：

```json
{
  "status": "ready",
  "processes": {
    "market_data": "ready",
    "macro_data": "ready",
    "binance": "ready",
    "fred": "degraded",
    "okx": "ready"
  },
  "summary": { "ready": 24, "degraded": 1, "down": 0 }
}
```

- adapter down → `degraded`（数据域部分可用）
- 聚合层 down → `down`（数据域不可用，下游无数据）

---

## 七、部署形态

### 7.1 开发态：单进程（composer）

```bash
# gen-env 生成全部 .env
./docs/sre/tools/gen-env.sh fred
./docs/sre/tools/gen-env.sh binance
# ...

# composer 拉起全部 25 进程（goroutine）
go run cmd/composer/main.go
```

组合根在开发态用 goroutine 模拟多进程（单二进制内并发），便于本地调试。

### 7.2 生产态：多容器（Docker Compose / K8s）

```yaml
# docker-compose.yml（示意）
services:
  market_data:
    build: ./market_data
    stores: all
  macro_data:
    build: ./macro_data
    stores: all
  binance:
    build: ./binance
    depends_on: [market_data]
  fred:
    build: ./fred
    depends_on: [macro_data]
  # ... 23 adapter
```

生产态每个进程独立容器，组合根退化为 Docker Compose/K8s 编排 + 共享配置注入。

---

## 八、组合根仓库建议

| 方案 | 优点 | 缺点 |
| --- | --- | --- |
| **新建 `github.com/ZoneCNH/composer`** | 职责清晰，不污染 xlib_standard | 多一个仓库 |
| 复用 `x.go` 仓库（改名） | 复用现有 CI/CD | x.go 是 xlib_standard 标准源，混入组合根会模糊职责 |
| 放进 ZoneCNH/ZoneCNH | 文档仓库 + 可执行 | 文档仓库混入 Go 代码 |

**建议**：新建 `github.com/ZoneCNH/composer`。它依赖 bootstrap + 各 adapter/market_data，是一个纯组装应用，不拥有业务逻辑。

---

## 九、前置依赖

| 依赖 | 状态 | 说明 |
| --- | --- | --- |
| bootstrap v0.1.0 | ✅ 已发布 | Build/Run/Shutdown + Stores 位掩码 |
| bootstrap Stores=All 路径 | ⚠️ stub | stores.go 有聚合层构造但 ossx 跳过，需补全 |
| market_data Receiver | ✅ 已合并 | PR #7（pkg/dispatch/receiver.go） |
| macro_data Receiver | ❌ 待实现 | 镜像 market_data Receiver |
| SinkPort 生产实现 | ❌ 待实现 | 双写 TD+Kafka（P4 存储双写） |
| 各 adapter 可启动 | ⚠️ 部分 | binance 有完整 main.go，其余 adapter 仍需接入 bootstrap |

**P6 的真正阻塞项**是 SinkPort 生产实现（P4 存储双写）和各 adapter 的 bootstrap 接入。组合根本身的设计已由本文档定义。

---

## 十、P6 实施路线

| 阶段 | 工作 | 前置 |
| --- | --- | --- |
| P6.1 | 新建 composer 仓库 + go.mod + cmd/main.go 骨架 | bootstrap v0.1.0 ✅ |
| P6.2 | 实现进程拓扑 + 启动顺序 + 信号处理 | P6.1 |
| P6.3 | 接入 market_data Receiver + 2 个示范 adapter（binance + fred） | P6.2 + Receiver ✅ |
| P6.4 | 健康聚合 + 配置拓扑 | P6.3 |
| P6.5 | 接入全部 25 进程 | P6.4 + 全部 adapter bootstrap 接入 |

P6.1-P6.3 可在 SinkPort 为 stub（RecordingSink）时完成；P6.5 需要全部前置就绪。

---

## 十一、决策记录

| # | 决策 | 理由 |
| --- | --- | --- |
| P6-D1 | 新建 composer 仓库，不复用 x.go | x.go 是 xlib_standard 标准源，组合根是应用，职责不同 |
| P6-D2 | 开发态单进程 goroutine，生产态多容器 | 开发态便于调试，生产态用容器编排 |
| P6-D3 | 聚合层先于 adapter 启动 | adapter dispatch 需要聚合层就绪 |
| P6-D4 | 组合根不实现业务逻辑 | 只做组装和编排，业务在各进程内 |

---

## 十二、与现有架构对齐

- **ARCHITECTURE.md L9**: "x.go 是组合根，不是业务链路终点" — 本设计遵循，composer 不含业务逻辑
- **ARCHITECTURE.md L145**: 入口域 = "启动、配置加载、依赖组装、生命周期控制" — composer 恰好做这 4 件事
- **bootstrap SPEC §4.2**: "不内置 admin HTTP / metrics endpoint" — 健康聚合由 composer 做，不在 bootstrap 内
- **Bootstrap SOP §五**: adapter main.go = `bootstrap.Build + app.Run` — composer 是这个模式的编排层

---

## 附：已就绪 vs 待建

| 组件 | 状态 | PR/Release |
| --- | --- | --- |
| bootstrap v0.1.0 | ✅ 已发布 | github.com/ZoneCNH/bootstrap |
| market_data Receiver | ✅ 已合并 | PR #7 (market_data) |
| macro_data Receiver | ❌ 待实现 | 镜像 market_data |
| SinkPort 生产实现 | ❌ 待实现 | P4 存储双写 |
| composer 组合根 | ❌ 待建 | 本文档定义设计 |
| 23 adapter bootstrap 接入 | ⚠️ 待做 | 各 adapter main.go 改用 bootstrap.Build |

---

*设计文档结束。composer 组合根的实施（P6.1-P6.5）依赖 SinkPort 生产实现 + 各 adapter bootstrap 接入。*
