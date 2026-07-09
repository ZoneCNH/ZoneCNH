# Binance Subscription Governance — 实施计划

> 基于 `knowledge/streams.md` 的 13 章设计文档对齐。
> 更新：2026-07-09

## 总体进度

```
��███████░░░░░░░░░░░░ 30%  — 综合完成度
├── ████████░░░░░░░░░░ 40%  — 访问控制（Symbol/Stream/Feature/Strategy 四级）
├── ████░░░░░��░░░░░░░░ 20%  — 订阅管理
├── ████░░░░░░░░��░░░░░ 25%  — 连接治理
├── ██░░░░░░░░░░░░░░░░ 15%  — 速率治理
├── ░░░░░░░░░░░░░��░░░░  0%  — 资源治理（自适应白名单）
└── ░░░░░░���░░░░░░░░░░��  0%  — 防封禁引擎
```

---

## 分章进度

| § | 章节 | 状态 | 剩余工作 |
|---|------|------|---------|
| §1 | Symbol Whitelist | ✅ 已完成 | — |
| §2 | Stream Whitelist | ⚠️ 类型已定义 | `streamConfig()` 接入 StreamType 过滤 |
| §3 | OrderBook Whitelist | ✅ 已完成 | — |
| §3+ | DepthLevel 分级 | ❌ 未实现 | L0–L4 深度档位枚举 |
| §4 | Feature Whitelist | ⚠️ per-symbol 维度 | per-module ACL 维度 |
| §5 | 策略白名单 | ❌ 未实现 | Strategy ACL |
| §6 | IP 封禁原因 | ✅ 已分析 | — |
| §7 | Reconnect Manager | ❌ 未实现 | 中央重连队列 |
| §8 | Subscription Pool | ❌ 未实现 | FanOut + 引用计数 |
| §9 | Connection Pool | ⚠️ per-line | per-stream-type 聚合 |
| §10 | Rate Limiter | ⚠️ 基础节流 | Weight / Adaptive / Burst |
| §11 | 自适应白名单 | ❌ 未实现 | CPU/Memory/Latency 感知 |
| §12 | Anti-Ban Engine | ❌ 未实现 | 统一防封禁协调 |
| §13 | 配置文件拆分 | ⚠️ 部分完成 | 7/10 文件未创建 |

---

## P0 — Stream 白名单接入（§2）

### 背景
`StreamType` 位掩码已定义（8 种流类型）、`whitelist.yaml` 已配置、`Entry.AllowedStreams` 字段已就绪。但 `streamConfig()` 仍未读取 `AllowedStreams`，每个 symbol 仍获取全部 13 个 stream。

### 动作
- [ ] `stream_control.go:340 streamConfig()` 中插入 per-symbol `AllowedStreams` 过滤
- [ ] 添加 `suffixToStreamType` 映射函数（suffix → StreamType）
- [ ] 为无白名单的 symbol 默认 `StreamAll`
- [ ] 集成 `WhitelistProvider.StreamWhitelist()` 到 `SpotConnector`

### 文件
- `internal/client/stream_control.go`
- `internal/client/spot.go`（注入 StreamMaskProvider）

### 预估
~30 行代码，1 小时。

---

## P1 — Reconnect Manager（§7）

### 背景
当前每个 `SpotConnector` 独立重连（jitter 退避）。Binance 在 100 connector 同时重连时封 IP。需要中央 `ReconnectQueue` 串行化重连。

### 动作
- [ ] 实现 `ReconnectQueue`：全局队列 + Worker 池
- [ ] 速率控制：每秒恢复 `reconnectRate` 个连接（默认 2）
- [ ] 支持指数退避 `[1s, 2s, 4s, 8s, 16s, 32s]`（可配置）
- [ ] 创建 `configs/reconnect.yaml`

### 文件
- 新增 `internal/client/reconnect_queue.go`
- 新增 `internal/client/reconnect_queue_test.go`
- 新增 `configs/reconnect.yaml`

### 预估
~150 行代码，3 小时。

---

## P1 — Rate Limiter 补全（§10）

### 背景
当前 `ThrottleManager` 仅有基础节流。缺少 REST Weight 感知、Adaptive 退避、Burst 控制。

### 动作
- [ ] `RateLimiter` 支持 `Weight`、`Window`、`Burst`、`Delay`
- [ ] Binance `429` 响应自动 Adaptive 降速
- [ ] Priority Queue（高优先 REST 先行）
- [ ] 创建 `configs/rate_limit.yaml`

### 文件
- 新增 `internal/client/rate_limiter.go`
- 修改 `internal/client/throttle.go`
- 新增 `configs/rate_limit.yaml`

### 预估
~200 行代码，4 小时。

---

## P2 — Subscription Pool（§8）

### 背景
Binance 组合流 (`/stream?streams=btcusdt@trade/btcusdt@ticker/...`) 已经实现了 per-product-line 共享。但文档期望进一步按 stream-type 分池（Ticker 池 / Trade 池 / Depth 池），让多个策略可以独立订阅不同层面的数据。

### 动作
- [ ] 实现 `SubscriptionPool`：per stream-type 引用计数 + FanOut
- [ ] 策略通过 `Subscribe(symbol, streamType)` 申请而非直接建 WS
- [ ] FanOut dispatcher 复制事件给所有订阅者
- [ ] 创建 `configs/connection_pool.yaml`

### 文件
- 新增 `internal/client/subscription_pool.go`
- 新增 `configs/connection_pool.yaml`

### 预估
~250 行代码，5 小时。

---

## P2 — DepthLevel 分级（§3 扩展）

### 背景
文档期望 L0–L4 深度分级（None/10/20/100/Full）。当前 `OrderbookFeatures` 只有开/关语义，缺档位控制。

### 动作
- [ ] 新增 `DepthLevel` 枚举：`None, L1(10), L2(20), L3(100), L4(Full)`
- [ ] `Entry.DepthLevel` 字段
- [ ] `Book.TopN(depthLevel)` 根据档位截断
- [ ] `whitelist.yaml` 添加 `depth_level` 字段

### 文件
- `pkg/whitelistclient/cache.go`（新增 DepthLevel 类型）
- `internal/client/orderbook/book.go`（TopN 档位适配）
- `configs/whitelist.yaml`（新增字段）

### 预估
~50 行新增，1 小时。

---

## P3 — 剩余配置文件（§13）

### 状态
| 文件 | 状态 |
|------|------|
| `whitelist.yaml` | ✅ 已创建（合并 symbols + streams + orderbook）|
| `features.yaml` | ❌ |
| `strategy_acl.yaml` | ❌ |
| `rate_limit.yaml` | ❌ |
| `reconnect.yaml` | ❌ |
| `connection_pool.yaml` | ❌ |
| `anti_ban.yaml` | ❌ |
| `adaptive.yaml` | ❌ |

### 动作
- [ ] 创建 7 个配置文件骨架（YAML schema + 默认值 + 文档注释）
- [ ] 每个文件配对应的 Go 加载代码

### 预估
~150 行配置 + ~100 行 Go，2 小时。

---

## P3 — 自适应白名单（§11）

### 背景
CPU >80% → 自动关闭 DOGE Depth；Latency >100ms → 关闭 Depth100；Memory >90% → 卸载 OrderBook。

### 动作
- [ ] 实现 `AdaptiveManager`：定期采样 CPU/Memory/Latency
- [ ] 阈值触发降级：`cpuDegradeThreshold`, `memDegradeThreshold`, `latencyDegradeThreshold`
- [ ] 降级策略：关闭低优先级 symbol 的深度 stream / OrderBook 功能位
- [ ] 恢复策略：资源恢复正常后逐步重新启用
- [ ] 创建 `configs/adaptive.yaml`

### 文件
- 新增 `internal/client/adaptive_manager.go`
- 新增 `configs/adaptive.yaml`

### 预估
~300 行，6 小时。

---

## P3 — Anti-Ban Engine（§12）

### 背景
统一协调防止 IP 封禁。当前各组件独立运行，无全局视图。

### 动作
- [ ] 实现 `AntiBanEngine`：监控 `[连接数, 重连率, Burst, REST 权重, IP 封禁信号]`
- [ ] 集成 `ReconnectQueue` + `RateLimiter` + `ConnectionPool`
- [ ] 全局决策：当检测到封禁风险时降级（暂停低优先级 symbol、降低重连速率）
- [ ] 创建 `configs/anti_ban.yaml`

### 文件
- 新增 `internal/client/anti_ban_engine.go`
- 修改 `internal/client/spot.go`（注册 connector 到引擎）
- 新增 `configs/anti_ban.yaml`

### 预估
~400 行，8 小时。

---

## 实施路线图

```
Phase 1 (本周)
├── ✅ Section 1-3 基础完成 + OrderbookFeatures + StreamType + whitelist.yaml
├── [ ] P0: streamConfig 接入 StreamType（~1h）
└── [ ] P1: Reconnect Manager（~3h）

Phase 2 (下周)
├── [ ] P1: Rate Limiter 补全（~4h）
├── [ ] P2: Subscription Pool（~5h）
└── [ ] P2: DepthLevel 分级（~1h）

Phase 3 (未来)
├── [ ] P3: 剩余配置文件（~2h）
├── [ ] P3: 自适应白名单（~6h）
└── [ ] P3: Anti-Ban Engine（~8h）
```

---

## Phase 4 — 验收标准

### 4.1 访问控制验收

| # | 验收项 | 验证方法 | 门禁 |
|---|--------|---------|------|
| AC-1 | `Entry.Enabled=false` 的 symbol 不建立 WS 连接 | 启动 client，检查 `blocked` symbol 的 stream URL 中不存在 | 自动化 |
| AC-2 | `AllowedStreams=Trade|Ticker` 的 symbol URL 仅含 `@trade`+`@ticker` | 检查 `streamConfig()` 输出 | 自动化 |
| AC-3 | `AllowedStreams=0` 等同于 `StreamAll`（向后兼容） | 旧 API 响应无此字段 → 全流 | 自动化 |
| AC-4 | `OrderbookEnabled=false` 的 symbol 不调用 `SubscribeWithFeatures` | 检查 subscribe loop 跳过计数 | 自动化 |
| AC-5 | `OrderbookFeatures=1` 的 symbol 仅订阅 depth，不 persist/checksum | 检查 `persistAll()` / `checksumSample()` 跳过 | 自动化 |
| AC-6 | `whitelist.yaml` 加载后分组优先级正确（blocked < basic < liquid < core） | 同 symbol 在多个组中，最高组生效 | 自动化 |
| AC-7 | 环境变量 `FOUNDATIONX_BINANCE_STREAM_SYMBOLS` 降级链：server → env → 全量 | `WhitelistProvider` nil/error → 使用 env → env 空 → 全量 | 自动化 |

### 4.2 连接治理验收

| # | 验收项 | 验证方法 | 门禁 |
|---|--------|---------|------|
| AC-10 | `ReconnectQueue` 限制同时重连数为 `reconnectRate`（默认 2/s） | 模拟 10 连接断开，观察重连间隔 | 集成测试 |
| AC-11 | 重连指数退避 `[1s, 2s, 4s, 8s, 16s, 32s]` 生效 | 模拟连续断连，检查退避时间 | 集成测试 |
| AC-12 | `ReconnectQueue` 关闭时优雅退出（不丢 inflight 请求） | ctx cancel → 队列排空 → 退出 | 单元测试 |
| AC-13 | Connection Pool per-stream-type 聚合（Ticker/Trade/Depth 分池） | 检查连接数 ≤ 池上限 | 集成测试 |

### 4.3 速率治理验收

| # | 验收项 | 验证方法 | 门禁 |
|---|--------|---------|------|
| AC-20 | REST `Weight` 感知：不同 endpoint 不同权重 | `/depth` weight=50, `/ticker` weight=1 | 单元测试 |
| AC-21 | Window 限流：每分钟 `maxWeight` 不超 | 模拟 60s 窗口限流 | 单元测试 |
| AC-22 | Binance `429` 响应自适应降速 | 模拟 429 → 自动降低 `maxWeight` | 集成测试 |
| AC-23 | Burst 控制：瞬时允许超出基础速率但 < `burstLimit` | 模拟 burst 请求 | 单元测试 |
| AC-24 | Priority Queue：高优先级 REST（如 admin）优先于低优先级 | admin token 请求先于 backfill | 单元测试 |

### 4.4 资源治理验收

| # | 验收项 | 验证方法 | 门禁 |
|---|--------|---------|------|
| AC-30 | CPU > `cpuDegradeThreshold`（默认 80%）→ 关闭低优先级 symbol 的 `Depth20`/`DepthFull` | 模拟 CPU 压力 | 集成测试 |
| AC-31 | Memory > `memDegradeThreshold`（默认 90%）→ 卸载 OrderBook（仅保留 Ticker/Trade） | 模拟内存压力 | 集成测试 |
| AC-32 | Latency > `latencyDegradeThreshold`（默认 100ms）→ 关闭 `Depth100`，保留 `Ticker` | 模拟 WS 延迟 | 集成测试 |
| AC-33 | 资源恢复正常后自动逐步恢复（`recoveryCooldown` 默认 60s） | 释放压力，观察恢复 | 集成测试 |
| AC-34 | 降级事件记录到 audit log（`degrade_reason`, `symbol`, `feature`, `timestamp`） | 检查 audit 字段 | 自动化 |

### 4.5 防封禁引擎验收

| # | 验收项 | 验证方法 | 门禁 |
|---|--------|---------|------|
| AC-40 | 检测到 `reconnectRate > 10/s` 时触发全局降级（暂停所有低优先级重连） | 模拟连接风暴 | 集成测试 |
| AC-41 | 检测到 `REST 429` 频率 > 5/min 时降低 `maxWeight` | 模拟持续 429 | 集成测试 |
| AC-42 | 检测到 `总连接数 > connectionLimit` 时拒绝新连接 + 关闭低优先级现有连接 | 模拟超限 | 集成测试 |
| AC-43 | 降级恢复采用 `linearRecovery`：每 30s 恢复 1 个 symbol，避免二次风暴 | 观察恢复速率 | 集成测试 |

### 4.6 运维验收

| # | 验收项 | 验证方法 | 门禁 |
|---|--------|---------|------|
| AC-50 | `/health` 端点报告所有治理组件��态 | `curl /health` → `{subscription_governance: {whitelist, reconnect, rate_limit, circuit_breaker: "ok"}}` | 自动化 |
| AC-51 | Prometheus metrics 暴露治理指标 | `curl /metrics` → `binance_whitelist_cache_age_seconds` 等 | 自动化 |
| AC-52 | `whitelist.yaml` 热加载（SIGHUP 或 file watch） | 修改文件 → 30s 内生效 | 集成测试 |
| AC-53 | 所有 10 个配置文件均具有 schema 验证 | 无效 YAML → 启动失败 + 明确错误信息 | 单元测试 |

### 4.7 测试覆盖门禁

| # | 验收项 | 门禁 |
|---|--------|------|
| T-1 | `pkg/whitelistclient/` 单元测试覆盖率 ≥ 90% | CI gate |
| T-2 | `internal/client/` 核心治理路径集成���试 ≥ 80% | CI gate |
| T-3 | `-race` 全部通过（无数据竞争） | CI gate |
| T-4 | `golangci-lint` 0 issues | CI gate |
| T-5 | 每个新文件 ≥ 1 个测试文件对应 | review gate |

### 4.8 性能验收

| # | 验收项 | 目标 |
|---|--------|------|
| P-1 | `StreamType.Has()` 调用 < 10ns（位操作） | benchmark |
| P-2 | `OrderbookFeatures.Has()` 调用 < 10ns | benchmark |
| P-3 | `ReconnectQueue.Enqueue()` < 1μs（无锁竞争时） | benchmark |
| P-4 | `RateLimiter.Allow()` < 1μs | benchmark |
| P-5 | `CircuitBreakerClient.Probe()` fail-fast < 1μs（Open 状态） | benchmark |

---

## 关联 PR

| PR | 仓库 | 内容 |
|----|------|------|
| [#464](https://github.com/ZoneCNH/binance/pull/464) | binance | OrderbookFeatures + StreamType |
| [#1735](https://github.com/ZoneCNH/ZoneCNH/pull/1735) | ZoneCNH | CI 审计报告 |
