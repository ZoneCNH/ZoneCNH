# module/binance IMPLEMENTATION PLAN

> 版本：v2.0.0 | 最后更新：2026-06-21
>
> **v2.0.0 架构核心变更**：gRPC bidi stream + 同进程 cs 接口 → natsx JetStream **网络**通信；
> server 获得 Binance 专属全栈存储（taosx + postgresx + redisx + ossx）；
> Gin REST API 作为 market_data 唯一数据接口；client 极简化（删除 spool/checkpoint）。

## 1. Goal

完成 `module/binance` v2.0.0 分布式 C/S 架构：client 仅做采集+natsx 发布；server 做消费+存储+API，可在不同机器独立部署。

## 2. Required Preflight Decisions

进入运行时实现前，以下决策已确认：

1. `binance-market` 已从 active architecture 移除
2. `module/binance/client` 和 `module/binance/server` 是独立二进制，可独立部署
3. `module/binance/server` 拥有 Binance 专属存储（taosx/postgresx/redisx/ossx）
4. `module/domain_market` 拥有 canonical market 语义
5. **C/S 唯一通信通道**：natsx JetStream（网络），Stream=`BINANCE_MARKET`，Retention=7d
6. `module/market_data` 通过 Gin REST API（HTTP）向 server 查询数据，不直连存储
7. 交付语义：JetStream durable consumer + ManualAck（at-least-once）；redisx SetNX（幂等）

### Phase 0: Upstream Contract Closure Gate

| Gate | 验证项 | 验证方式 | 状态 |
|------|--------|----------|:----:|
| G0-1 | natsx JetStream Stream `BINANCE_MARKET` subject 规范已定义（`binance.market.{product_line}.{event_type}`） | `grep -c "binance.market\|BINANCE_MARKET" module/binance/RUNTIME-MAPPING.md` ≥ 5 | ✅ |
| G0-2 | `module/domain_market` 已定义 `ProductLine`(4值)/`InstrumentKey`/`MarketFactEnvelope` | `grep -c "ProductLine\|InstrumentKey\|MarketFactEnvelope" module/domain_market/SPEC.md` ≥ 15 | ✅ |
| G0-3 | `module/market_data` 已确认通过 Gin REST API 调用 binance server，不直连存储 | `module/market_data/SPEC.md` §Consumers 包含 binance REST API 描述 | ✅ |
| G0-4 | BOUNDARY-GATES.md v2.0.0 全部 11 门禁有可执行 CI 脚本 | `grep -c "Suggested check:" module/binance/BOUNDARY-GATES.md` ≥ 9 | ✅ |
| G0-5 | go.mod 中 gin/ossx 为 direct；redisx/kafkax/natsx/postgresx/taosx 从 indirect 升为 direct 的路径已规划 | `module/binance/RUNTIME-MAPPING.md` §Dependencies 表 | ✅ |
| G0-6 | server 存储所有权：taosx/postgresx/redisx/ossx 由 server 独占，BOUNDARY-GATES §7 已文档化 | `grep -c "Server Owns" module/binance/BOUNDARY-GATES.md` ≥ 1 | ✅ |

> **6/6 通过** — v2.0.0 文档基线就绪，可推进运行时实现。

## 3. Recommended PR Sequence

```text
PR-000 Remove binance-market（已完成）
PR-001 module/binance root 文档
PR-002 module/binance/client 文档
PR-003 module/binance/server 文档
PR-004 domain_market 依赖确认
PR-005 natsx JetStream 通信协议确认
PR-006 infra 依赖（redisx/kafkax/taosx/postgresx/ossx）
PR-007 运行时实现
```

## 4. PR-000 Remove binance-market

Scope:

- 从 active architecture/status 移除 `binance-market`
- 移除旧 Provider 引用
- 添加 no-legacy CI gate

Acceptance:

- 任何 active 文档不再引用 `binance-market` 为当前架构
- 新 Binance 工作指向 `module/binance/client` 和 `module/binance/server`

## 5. PR-001 Root Module

Scope:

- `module/binance/goal.md`
- root `README.md` / `SPEC.md` v2.0.0
- root `TRACEABILITY.md` v2.0.0
- root `BOUNDARY-GATES.md` v2.0.0
- root `RUNTIME-MAPPING.md` v2.0.0
- root `IMPLEMENTATION-PLAN.md` v2.0.0
- root `DEEP-ANALYSIS.md`（含 §0 分布式约束）

Acceptance:

- root SPEC v2.0.0 描述 natsx 分布式 C/S
- BOUNDARY-GATES 含 cs 包禁止（Gate 5）+ 同进程禁止（Gate 6）+ go.mod 合规（Gate 11）
- 无 gRPC / spool / checkpoint 作为 active 目标

## 6. PR-002 Client Docs

Scope:

- client `README.md` / `SPEC.md` v2.0.0 / `TRACEABILITY.md` v2.0.0
- 归档旧 Task：CLIENT-008（gRPC sender）、CLIENT-009（spool+checkpoint）
- 新增 Task：CLIENT-014（natsx publisher）
- 定义产品线 catalog / parser / mapper / idempotency key / publisher / admin

Acceptance:

- client SPEC v2.0.0 只做采集 + natsx publish，无 spool/checkpoint 目标
- CLIENT-014 natsx publisher 有完整 FR/AC/TC
- client 不涉及任何存储或 server 接口

## 7. PR-003 Server Docs

Scope:

- server `README.md` / `SPEC.md` v1.1.0 / `TRACEABILITY.md` v2.0.0
- 归档旧 Task：SERVER-001（gRPC ingest server）、SERVER-004（ingest ACK）
- 新增 Task：SERVER-010（natsx consumer）/ SERVER-011（redisx idempotency）/ SERVER-012（postgresx catalog）/ SERVER-013（taosx storage）/ SERVER-014（kafkax dispatch）/ SERVER-015（Gin market API）/ SERVER-016（ossx archiver）

Acceptance:

- server 拥有 Binance 专属全栈存储（6 个 infra Task 全覆盖）
- Gin REST API（SERVER-015）作为 market_data 唯一数据接口
- server 不连接 Binance 交易所端点（由 client 负责）

## 8. PR-004 domain_market Dependency

所需外部类型（已在 `module/domain_market/SPEC.md` v1.0.1 定义）：

- `InstrumentKey`（12 字段）
- `ProductLine`（4 值枚举：Spot/FuturesUSDT/FuturesCoin/Options）
- `InstrumentType` / `OptionType` / `PriceKind` / `MarketScope`
- `MarketFactEnvelope`（canonical wrapper，含 `ToTDRow()` / `Tags()` 方法）

Acceptance：Spot/Futures/Options 身份碰撞不可能；client mapper 输出 `*domain_market.MarketFactEnvelope`

## 5. PR-005 natsx Communication Protocol

所需通信规范（已在 `RUNTIME-MAPPING.md` v2.0.0 定义）：

- Stream：`BINANCE_MARKET`，Retention=7d，Storage=file
- Subject 格式：`binance.market.{product_line}.{event_type}`（小写）
- Client Publish：`js.Publish(subj, json)` + 等待 PubAck
- Server Subscribe：durable=`binance-server`，ManualAck，AckWait=30s，MaxDeliver=5
- Payload：`domain_market.MarketFactEnvelope` JSON

> **注**：不再使用 gRPC / proto 定义通信协议。`module/contracts` 保留 Go 接口定义但不作为 wire schema。

## 10. PR-006 Infra Dependencies

| 依赖 | 版本 | 用途 | 当前 go.mod 状态 |
|------|------|------|-----------------|
| `github.com/ZoneCNH/natsx` | v1.0.0 | JetStream publish/subscribe | indirect → 需升 direct |
| `github.com/ZoneCNH/redisx` | v1.0.0 | idempotency + cache + rate limit | indirect → 需升 direct |
| `github.com/ZoneCNH/kafkax` | v1.0.0 | 下游广播 | indirect → 需升 direct |
| `github.com/ZoneCNH/postgresx` | v1.0.0 | 元数据目录 | indirect → 需升 direct |
| `github.com/ZoneCNH/taosx` | v1.0.0 | 主时序存储 | indirect → 需升 direct |
| `github.com/gin-gonic/gin` | v1.10.x | REST API | **缺失 → 需新增** |
| `github.com/ZoneCNH/ossx` | v1.0.0 | 冷存储归档 | **缺失 → 需新增** |

## 11. PR-007 Runtime Implementation

运行时目录布局：

```text
github.com/ZoneCNH/binance/
  cmd/
    binance-client/    ← 独立进程（可不同机器部署）
    binance-server/    ← 独立进程（可不同机器部署）
  internal/
    client/
      catalog/         ← 产品线目录
      parser/          ← symbol 解析
      connector/       ← WebSocket 采集
      normalizer/      ← 原始事件规范化
      mapper/          ← canonical 映射
      idempotency/     ← 幂等键生成
      publisher/       ← natsx JetStream 发布 ← 替代 spool+checkpoint+sender
      admin/           ← HTTP 管理端点
    server/
      consumer/        ← natsx durable consumer（入口）
      processor/       ← 验证 + 幂等检查 pipeline
      storage/
        idempotency/   ← redisx SetNX
        timeseries/    ← taosx 写入/查询
        catalog/       ← postgresx 元数据
        archiver/      ← ossx 冷存储归档
      dispatch/        ← kafkax 下游广播
      cache/           ← redisx 深度快照缓存
      api/             ← Gin REST /v1/market/*
      admin/           ← HTTP 管理端点
```

**实现顺序**（按依赖拓扑）：

1. domain_market 依赖确认（`go get github.com/ZoneCNH/domain_market`）
2. infra 依赖升级（`go mod` 升 direct + 新增 gin/ossx）
3. client：catalog → parser → connector → normalizer → mapper → idempotency → publisher → admin
4. server：consumer → processor（validation）→ redisx idempotency → taosx storage → kafkax dispatch → postgresx catalog → redisx cache → Gin API → ossx archiver → admin
5. 集成测试：client（独立进程）→ natsx JetStream → server（独立进程）→ Gin API → market_data（mock）
6. CI boundary gates：cs 包禁止 + 同进程禁止 + go.mod 合规

**关键删除**（v2.0.0 移除）：

```text
internal/cs/               ← 删除（同进程接口，违反分布式约束）
internal/client/spool/     ← 删除（JetStream 替代本地持久化）
internal/client/checkpoint/← 删除（JetStream durable consumer 替代）
internal/client/sender/    ← 删除（publisher/ 替代 gRPC sender）
```

## 12. Done Definition

v2.0.0 完成条件：

- [ ] `internal/cs` 包已删除
- [ ] client 和 server 各自独立编译为二进制，无跨进程 import
- [ ] BOUNDARY-GATES 11 门禁全部 CI PASS（含 cs 包禁止/同进程禁止/go.mod 合规）
- [ ] natsx client→server 端到端集成测试通过（两个独立进程，消息经 JetStream 传递）
- [ ] server redisx 幂等：重投消息不重复写入 taosx
- [ ] server taosx：WriteBatch 吞吐 ≥ 10万 TPS
- [ ] server kafkax：处理成功后广播到下游 topic
- [ ] server Gin API：GET /v1/market/ticks 返回 taosx 数据；GET /v1/market/depth 返回 redisx 快照
- [ ] server ossx：归档后 taosx 数据正确删除（先写冷再删热）
- [ ] market_data 通过 HTTP 调用 Gin API 获取数据（不直连 binance 存储）
- [ ] 无 `binance-market` active 引用
