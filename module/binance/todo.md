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

## 关联 PR

| PR | 仓库 | 内容 |
|----|------|------|
| [#464](https://github.com/ZoneCNH/binance/pull/464) | binance | OrderbookFeatures + StreamType |
| [#1735](https://github.com/ZoneCNH/ZoneCNH/pull/1735) | ZoneCNH | CI 审计报告 |
