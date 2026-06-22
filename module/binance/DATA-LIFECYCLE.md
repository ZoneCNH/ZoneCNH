# Binance Data Lifecycle 讨论稿

- Status: Draft / Discussion
- Source: `docs/report/binance/deep-analysis-20260622-v4.md` §五~§八
- Scope: FR-012 ~ FR-024 only; do not fold into `SPEC.md` / `TRACEABILITY.md` until review accepts the lifecycle gates and event taxonomy change.
- Last-Updated: 2026-06-22

## 0. 为什么先独立成稿

v4 分析提出 13 条新增需求，覆盖实时采集控制面、历史回填、缺口修复、对账、冷数据回热与运维可见性。若直接写入 `SPEC.md`，其中 FR-020 会把 `event_type` 从 4 类扩展到 6 类（新增 `funding` / `mark_price`），触发 RULES R2 矩阵重算和 MAJOR bump。

因此本文件只作为评审入口：先固定数据生命周期闭环和 FR 草案，再由后续 PR fold into root/client/server SPEC、TRACEABILITY、ACCEPTANCE 与任务矩阵。

## 1. 生命周期闭环

```text
symbol discovery
  -> subscription planning
  -> websocket ingest
  -> idempotent normalize/publish
  -> server validation/persist/fanout
  -> gap detection
  -> backfill/replay
  -> reconciliation
  -> archive/rehydration
  -> operator visibility/hot reload
```

生命周期必须满足三条约束：

1. 实时链路和 REST 回填使用同一幂等键，避免双写。
2. 回填和对账不得挤占实时控制面的限速预算。
3. 新增 `funding` / `mark_price` 只有在 event_type 6 值矩阵、topic、表、AC/TC 同步定稿后才能进入 Approved SPEC。

## 2. FR 草案索引

| FR | Priority | Lifecycle Stage | Draft Requirement | Fold Target |
|---|---|---|---|---|
| FR-012 | P0 | symbol discovery | client 启动拉 spot + futures exchangeInfo，按 allow/deny 过滤；每 6h 刷新目录；新增合约写 `binance_instruments` 并发布 `instruments.changed` | root SPEC §7 + client/SPEC §7 |
| FR-013 | P0 | websocket ingest | WS 重连退避 `1s,2s,4s,8s,16s,30s...`；单连接 stream 上限 200；ping 3min；listenKey 30min 续期 | client/SPEC §7 |
| FR-014 | P0 | subscription planning | spot/um_perp/cm_perp 订阅 `1s,1m,5m,15m,1h,4h,1d`；options 订阅 `1m,5m,1h,1d`；其他周期由 clickhousex 重采样 | NAMING §2 + root SPEC §9 |
| FR-015 | P0 | depth ingest | spot/um_perp/cm_perp 订阅 `@depth20@100ms` + `@depth@1000ms`；options 沿用 `@depth1000`；snapshot/incremental 用 `update_id` 拼合 | root SPEC §9 |
| FR-016 | P0 | historical backfill | 首次部署或新增 symbol 时 REST 回填：tick=7d、trade=30d、bar(1m)=365d、bar(1h+)=1825d、depth 不回填 | server/SPEC §7 Backfill |
| FR-017 | P0 | gap detection | server 每 5min 运行 gap detector；trade 用 `aggTrade.a` 连号校验；bar 按窗口期望条数；gap 入 `binance_backfill_jobs` | server/SPEC §7 |
| FR-018 | P0 | backfill throttle | REST token bucket 感知 spot 1200 weight/min、futures 2400 weight/min；80% 预算保留实时控制面，20% 给回填；优先级 trade > bar > tick | server/SPEC §7 |
| FR-019 | P0 | replay idempotency | REST 回填幂等键与 WS 一致：trade=`exchange+product_line+symbol+trade_id`，bar=`exchange+product_line+symbol+interval+open_time` | BR-008 extension |
| FR-020 | P1 | periodic data | um_perp/cm_perp 订阅 `markPriceUpdate`；`fundingInfo` 8h；新增 `binance_funding` / `binance_mark_price`；event_type 扩展为 `funding` / `mark_price` | NAMING §2 + RULES R2/R3 |
| FR-021 | P1 | reconciliation | 每日 04:00 UTC 按 symbol×1d 对账 taosx OHLCV 与 Binance klines；差异超过 0.01% 写 `binance_reconciliation_alerts` | server/SPEC §7 |
| FR-022 | P1 | cold rehydration | range query 命中 OSS 归档区时异步 OSS→taosx 回热临时表（24h TTL）；同步返回 202 + `job_id` | FR-007 extension |
| FR-023 | P2 | operator visibility | 提供 `GET /api/v1/admin/backfill/jobs` 和 `GET /api/v1/admin/backfill/coverage/:symbol`，暴露 coverage 最早可用时间戳 | server/SPEC §7 |
| FR-024 | P2 | hot reload | 提供 `POST /api/v1/admin/symbols/reload`；重读 postgresx 白黑名单；发布 `symbols.changed`；client 增减 stream 无需重启 | client/SPEC §7 + server/SPEC §7 |

## 3. Fold 前门禁

- FR-012~FR-019 可作为 P0 两阶段进入 SPEC：先实时控制面，再历史生命周期。
- FR-020 必须和 event_type 6 值矩阵、Kafka topic、taosx 超表、AC/TC 一起评审；不得只改命名文档。
- FR-021~FR-024 依赖前置生命周期锚点，不应先于 FR-012~FR-019 合入 Approved SPEC。
- fold PR 必须同步更新 `SPEC.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`client/SPEC.md`、`server/SPEC.md` 和相应任务状态。
