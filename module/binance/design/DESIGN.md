# module/binance DESIGN

- Design-ID: DESIGN-binance-v1
- Source-Goal: module/binance/goal/goal.md
- Source-Spec: module/binance/spec/SPEC.md
- Status: Implemented
- Last-Updated: 2026-06-30

## 1. Modules

```text
module/binance
├── client/   ← Binance 交易所侧采集器（独立进程）
└── server/   ← 内网处理 + 存储 + API（独立进程）
```

| Module | Role | Runtime-Repo |
|--------|------|-------------|
| binance-client | 连接 Binance，解析交易所原生数据，映射到 domain_market envelope，通过 natsx JetStream 发布 | /home/workspace/binance/cmd/binance-client/ |
| binance-server | 订阅 natsx JetStream，校验与去重，写入存储，提供 Gin REST API，通过 kafkax 广播 | /home/workspace/binance/cmd/binance-server/ |

## 2. Interfaces

| Interface | Type | Provider | Consumer |
|-----------|------|----------|----------|
| natsx JetStream (BINANCE_MARKET) | Async Pub/Sub | binance-client | binance-server |
| Gin REST :8080 | Sync HTTP | binance-server | market_data / downstream |
| kafkax topics | Async Pub/Sub | binance-server | external consumers |
| redisx SetNX | Sync KV | redisx | binance-server (idempotency) |
| taosx WriteBatch | Sync TSDB | binance-server | taosx |
| postgresx upsert | Sync SQL | binance-server | postgresx |
| clickhousex ETL | Batch OLAP | binance-server | clickhousex |
| ossx PutObject | Sync Object | binance-server | ossx |

## 3. Data Flow

```text
Binance Exchange (WS/REST)
  → binance-client catalog → parser → normalize → mapper
  → natsx.Publish(subject: binance.market.*.*.v1)
  → natsx JetStream
  → binance-server consumer → validation → idempotency (redisx)
  → processor → [taosx | postgresx | redisx cache | kafkax | ossx]
  → Gin REST API → market_data
```

## 4. Dependencies

| Dependency | Direction | Constraint |
|------------|-----------|------------|
| domain_market | client+server → domain_market | Canonical types only; no domain logic in binance |
| natsx | client+server → natsx | JetStream pub/sub; NATS is external service |
| redisx | server → redisx | SetNX idempotency + hot cache |
| postgresx | server → postgresx | Metadata + audit |
| taosx | server → taosx | Time-series storage |
| clickhousex | server → clickhousex | OLAP analytics |
| kafkax | server → kafkax | Downstream broadcast |
| ossx | server → ossx | Cold storage archive |

## 5. ADR

| ADR | Decision | Status |
|-----|----------|--------|
| ADR-001 | 占位声明：早期架构决策已并入 SPEC §1-§6（wire 边界/产品线/catalog 基础模型），编号保留不回溯（见 [ADR-001-placeholder.md](ADR-001-placeholder.md)） | Accepted（占位） |
| ADR-002 | Wire boundary: natsx subject + domain_market envelope JSON; no local proto/gRPC ingest schema | Superseded by ADR-007 |
| ADR-003 | Order book rebuild exclusion | Superseded by ADR-011 |
| ADR-004 | FR-024 vs FR-036 architecture decision | Accepted |
| ADR-005 | Symbol 采集分级体系：CatalogEntry 加 Tier/SymbolPriority/Collection/QuoteVolumeUSD 字段 + classifyTier 三层降级 + 白名单 MVP（见 [ADR-005](ADR-005-symbol-tier-classification.md)、[TIER-DESIGN-DETAILS](TIER-DESIGN-DETAILS.md)） | Proposed |
| ADR-007 | internal/wire 迁移到 contracts canonical（方案 C：canonical 富化 + boundary codec），删除 internal/wire，新增 internal/ingestcodec（见 [ADR-007](ADR-007-wire-to-contracts-migration.md)） | Accepted |
| ADR-009 | User data stream (private flow) scope exclusion（见 [ADR-009](ADR-009-user-data-stream-scope.md)） | Accepted |
| ADR-010 | Platform change risk register: CM→UM 迁移 / Options 重构期 / 时间戳单位变更（见 [ADR-010](ADR-010-platform-change-risks.md)） | Accepted（监控中） |
| ADR-011 | Order book rebuild 纳入决策：supersede ADR-003，启动 v4.0.0 MAJOR 升级（见 [ADR-011](ADR-011-order-book-rebuild-inclusion.md)） | Accepted |

## 6. Risks

| Risk | Level | Mitigation |
|------|-------|------------|
| client/server 耦合回流 | Medium | boundary-gates.sh CI 检查 |
| 跨产品线身份碰撞 | High | product_line prefix in instrument identity |
| JetStream 消息丢失 | High | durable consumer + ManualAck + NakWithDelay |
| 存储装配断层 | Medium | main.go production readiness gates (PRG-001~007) |
| CM Perp → UM 架构迁移 | Medium | ADR-010 R-P1 监控中；公开行情流待确认 |
| Options 系统重构期事件名变更 | Medium | ADR-010 R-P2 监控中；定期检查 eapi changelog |
| 现货 CSV 时间戳 ms→μs 变更（2025-01-01） | Medium | ADR-010 R-P3；backfill 代码需分段处理 |

## 7. Reference Design Docs

| 文档 | 用途 |
|------|------|
| [EVENT-TYPE-MAPPING.md](EVENT-TYPE-MAPPING.md) | 事件类型语义分类框架：四问判据（Q1 ID/Q2 快照/Q3 传输层/Q4 非权威）+ 20 种 Binance 原生事件逐一归类 + canonical 命名对齐 Binance 原生（snake_case）+ 5 个 planned canonical 类型 + 误映射后果登记 + 四产品线覆盖矩阵 |
| [SEQUENCE-CONTINUITY-STRATEGY.md](SEQUENCE-CONTINUITY-STRATEGY.md) | 序号连续性校验策略（强制/间接/自愈/不适用）+ depthUpdate 8 步重建算法 + z/l 累计量交叉校验 |
| [ORDER-BOOK-STATE-MACHINE.md](ORDER-BOOK-STATE-MACHINE.md) | Order book 状态机设计：4 状态（UNINITIALIZED/BUFFERING/ALIGNED/REBUILDING）+ 转换矩阵 + 对齐算法 + 序号校验 + 持久化恢复 + 并发模型 + staleness 语义 + 市场差异 + options 待确认 checklist |
| [ORDER-BOOK-IMPLEMENTATION-PLAN.md](../plan/ORDER-BOOK-IMPLEMENTATION-PLAN.md) | Order book 实现 task 分解：11 个 task（OB-001~011）+ 依赖图 + 3 phase 实现顺序 + 前置条件 + 风险登记 |
| [HISTORICAL-DATA-SYNC-STRATEGY.md](HISTORICAL-DATA-SYNC-STRATEGY.md) | 历史数据同步起始时间策略 + REST 窗口限制 + 时间戳单位变更 + depth 无回溯声明 |
