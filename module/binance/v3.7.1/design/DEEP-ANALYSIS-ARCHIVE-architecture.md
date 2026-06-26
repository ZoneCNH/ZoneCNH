> [ARCHIVED 2026-06-22] DEEP-ANALYSIS.md 拆分产物。原 §1-§2 + 附录A：架构评估与目标设计。
>
> 活跃版本见 `SPEC.md` §4.1 分布式约束。

# 深度架构分析 — 架构篇

> 分析日期：2026-06-21 | 状态：**已归档**

## 1. 当前架构评估

### 1.1 现状概览

```
Binance Exchange (WS/REST) → binance/client (采集器)
  catalog → parser → normalize → mapper
  → idempotency key → SQLite spool → checkpoint → gRPC sender
       │ contracts.MarketDataService gRPC bidi stream
       ▼
  binance/server (接入受理)
  ingest → validation → idempotent acceptance → ACK/Reject → downstream dispatch
       │ downstream dispatch port
       ▼
  market_data (交易所中立管线)
```

### 1.2 当前架构特征

| 维度 | 现状 | 评估 |
|------|------|------|
| Client-Server 通信 | gRPC bidi stream | 强类型，但需 protoc + proto 生成 |
| Client 持久化 | SQLite spool + checkpoint | 单机可靠，但无分布式容灾 |
| Server 幂等 | in-memory map (骨架首版) | 进程重启丢失，不可生产 |
| Server 存储 | 无 — 纯 handoff 到 market_data | 不符合"服务端存储"目标 |
| Web 接口 | Gin admin | 仅运维面，无业务 API |
| 基础设施依赖 | bootstrap + domain_market/exchange | 6 个目标模块全为 indirect |
| 产品线覆盖 | 仅 Spot (骨架) | 4 条全需补全 |

### 1.3 与目标的差距

| # | 目标要求 | 当前状态 | GAP |
|---|---------|---------|-----|
| G1 | natsx client→server 通信 | gRPC bidi stream | 需替换 |
| G2 | redisx 缓存/锁/幂等 | in-memory | 需新增 |
| G3 | kafkax 事件发布 | 直接 dispatch port | 需新增 |
| G4 | postgresx 元数据/配置 | SQLite spool | 需新增 |
| G5 | taosx 时序行情存储 | 不存储 | 需新增 |
| G6 | ossx 历史归档 | 无 | 需新增 |
| G7 | Server 处理+存储 | 仅验证+幂等+转发 | 需重构 |
| G8 | Gin web API 给 market_data | 仅 admin 端点 | 需新增 |
| G9 | Client 仅采集+同步 | spool/checkpoint/sender 全套 | 需简化 |

**结论：SPEC v1.0.1 → v2.0.0 重大架构升级。**

## 2. 目标架构设计

### 2.1 全景架构图

```
                      Binance Exchange
                REST API ─┴─ WebSocket Streams
    Spot / USDⓈ-M / COIN-M / Options
              ▼
┌─ binance/client (极简采集) ──────────────────────────┐
│  catalog → parser → normalize → mapper               │
│  → natsx Publisher (JetStream at-least-once)         │
│  observex | Gin admin (:8081)                        │
└────────────────────┬─────────────────────────────────┘
                     │ natsx JetStream
                     │ subject: binance.market.{pl}.{et}
                     ▼
┌─ binance/server (富服务端) ──────────────────────────┐
│  natsx Consumer → validation + idempotency (redisx)  │
│  → Processing Pipeline (enrich/aggregate/derive)     │
│  → postgresx | taosx | kafkax | ossx                │
│  Gin Web API (:8080) → market_data HTTP 查询         │
│  observex                                            │
└──────────┬──────────┬───────────────────────────────┘
    Gin REST API   kafkax → 下游消费者
```

### 2.2 关键架构决策

| # | 决策 | 理由 |
|---|------|------|
| AD-1 | natsx JetStream 替代 gRPC | 无需 protoc；at-least-once + 持久化；运维简单 |
| AD-2 | Client 不再持有 spool/checkpoint | JetStream 提供持久化和重投 |
| AD-3 | Server 负责全量存储 | market_data 从 owner 变为 consumer |
| AD-4 | redisx 幂等存储 + 热缓存 | 高性能 KV；TTL 自动过期 |
| AD-5 | taosx 时序行情主存储 | TDengine 超级表；写入 10万+/s |
| AD-6 | postgresx 元数据/配置 | 关系型适合 catalog/配置/审计 |
| AD-7 | kafkax 跨域事件发布 | 解耦 server 与下游消费者 |
| AD-8 | ossx 历史归档 | 对象存储成本低；冷数据长期保存 |
| AD-9 | Gin REST API → market_data | 标准 HTTP，无客户端依赖 |

## 附录 A: 与旧架构对比

| 维度 | 旧架构 (v1.0.1) | 新架构 (v2.0.0) |
|------|----------------|-----------------|
| C/S 通信 | gRPC bidi stream | natsx JetStream |
| Client 职责 | 采集+spool+checkpoint+send | 仅采集+natsx publish |
| Server 职责 | validate+idempotency+ACK+dispatch | validate+idempotency+process+store+cache+API+dispatch+archive |
| 幂等存储 | in-memory / SQLite | redisx(主) + postgresx(备) |
| 行情存储 | 无 | taosx 时序主存储 |
| 元数据存储 | 无 | postgresx |
| 事件发布 | direct dispatch port | kafkax |
| 历史归档 | 无 | ossx |
| Web API | Gin admin only | Gin REST API |
| 可观测 | observex 已规划 | observex 全覆盖 |
| 产品线 | 仅 Spot | 完整 4 产品线 |
