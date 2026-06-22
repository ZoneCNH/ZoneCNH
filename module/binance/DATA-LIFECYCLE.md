# Binance Data Lifecycle 讨论稿

- Status: Draft / Discussion for #879 (non-normative); FR-020 is out of #879 scope and handled by #888 normative fold
- Issue Scope: #879 pre-draft for FR-012~FR-019 and FR-021~FR-024; #880~#887/#889~#892 FR review anchors; #888 tracks FR-020 only
- Source: `docs/report/binance/deep-analysis-20260622-v4.md` §五~§八
- Scope: FR-012 ~ FR-019 and FR-021 ~ FR-024 remain discussion draft; FR-020 is folded into `SPEC.md` / `TRACEABILITY.md` v3.0.0.
- Last-Updated: 2026-06-23

## 0. 为什么先独立成稿

v4 分析提出 13 条新增需求，覆盖实时采集控制面、历史回填、缺口修复、对账、冷数据回热与运维可见性。FR-020 已作为 v3.0.0 MAJOR taxonomy fold 写入 `SPEC.md`、`NAMING.md` 与 `RULES.md`：`event_type` 从 4 类扩展到 6 类，新增 `funding_rate` / `mark_price`，并完成 RULES R2 4 × 6 矩阵重算。

因此本文件只作为 FR-012~FR-019、FR-021~FR-024 的评审入口：先固定数据生命周期闭环和 FR 草案，再由后续 PR fold into root/client/server SPEC、TRACEABILITY、ACCEPTANCE 与任务矩阵。FR-020 的规范化折叠属于 #888，不作为 #879 草案完成条件。

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
3. 新增 `funding_rate` / `mark_price` 已在 v3.0.0 进入 Approved SPEC；后续若 runtime capability 不能覆盖 4 × 6 全矩阵，必须在 RULES/NAMING/TRACEABILITY 中写明适用性例外。

## 2. FR 草案索引

| Issue | FR | Priority | Lifecycle Stage | Draft Requirement | Fold Target |
|---|---|---|---|---|---|
| #880 | FR-012 | P0 | symbol discovery | client 启动拉 spot + futures exchangeInfo，按 allow/deny 过滤；每 6h 刷新目录；新增合约写 `binance_instruments` 并发布 `instruments.changed` | root SPEC §7 + client/SPEC §7 |
| #881 | FR-013 | P0 | websocket ingest | WS 重连退避 `1s,2s,4s,8s,16s,30s...`；单连接 stream 上限 200；ping 3min；listenKey 30min 续期 | client/SPEC §7 |
| #882 | FR-014 | P0 | subscription planning | spot/um_perp/cm_perp 订阅 `1s,1m,5m,15m,1h,4h,1d`；options 订阅 `1m,5m,1h,1d`；其他周期由 clickhousex 重采样 | NAMING §2 + root SPEC §9 |
| #883 | FR-015 | P0 | depth ingest | spot/um_perp/cm_perp 订阅 `@depth20@100ms` + `@depth@1000ms`；options 沿用 `@depth1000`；snapshot/incremental 用 `update_id` 拼合 | root SPEC §9 |
| #884 | FR-016 | P0 | historical backfill | 首次部署或新增 symbol 时 REST 回填：tick=7d、trade=30d、bar(1m)=365d、bar(1h+)=1825d、depth 不回填 | server/SPEC §7 Backfill |
| #885 | FR-017 | P0 | gap detection | server 每 5min 运行 gap detector；trade 用 `aggTrade.a` 连号校验；bar 按窗口期望条数；gap 入 `binance_backfill_jobs` | server/SPEC §7 |
| #886 | FR-018 | P0 | backfill throttle | REST token bucket 感知 spot 1200 weight/min、futures 2400 weight/min；80% 预算保留实时控制面，20% 给回填；优先级 trade > bar > tick | server/SPEC §7 |
| #887 | FR-019 | P0 | replay idempotency | REST 回填幂等键与 WS 一致：trade=`exchange+product_line+symbol+trade_id`，bar=`exchange+product_line+symbol+interval+open_time` | BR-008 extension |
| #888 | FR-020 | P1 | periodic data | um_perp/cm_perp 订阅 `markPriceUpdate`；`fundingInfo` 8h；新增 `binance_funding_rate` / `binance_mark_price`；event_type 扩展为 `funding_rate` / `mark_price` | handled by #888; folded into SPEC / TRACEABILITY / NAMING / RULES v3.0.0 |
| #889 | FR-021 | P1 | reconciliation | 每日 04:00 UTC 按 symbol×1d 对账 taosx OHLCV 与 Binance klines；差异超过 0.01% 写 `binance_reconciliation_alerts` | server/SPEC §7 |
| #890 | FR-022 | P1 | cold rehydration | range query 命中 OSS 归档区时异步 OSS→taosx 回热临时表（24h TTL）；同步返回 202 + `job_id` | FR-007 extension |
| #891 | FR-023 | P2 | operator visibility | 提供 `GET /api/v1/admin/backfill/jobs` 和 `GET /api/v1/admin/backfill/coverage/:symbol`，暴露 coverage 最早可用时间戳 | server/SPEC §7 |
| #892 | FR-024 | P2 | hot reload | 提供 `POST /api/v1/admin/symbols/reload`；重读 postgresx 白黑名单；发布 `symbols.changed`；client 增减 stream 无需重启 | client/SPEC §7 + server/SPEC §7 |

## 2.1 #879 草案元数据

| FR | Motivation | Landing | Impact | Version / Dependencies |
|---|---|---|---|---|
| FR-012 | symbol 目录必须可发现、过滤和热更新，避免静态列表漂移 | root SPEC §7 + client/SPEC §7 | catalog/control-plane | proposed MINOR; depends postgresx catalog |
| FR-013 | 长连接采集需要统一重连、限流和 stream 上限 | client/SPEC §7 | websocket reliability | proposed MINOR; depends natsx publish path |
| FR-014 | 订阅周期必须按 product_line 固定，避免不可用 interval 进入 runtime | NAMING §2 + root SPEC §9 | subscription planner | proposed MINOR; depends product_line matrix |
| FR-015 | depth 需要区分 partial 与 diff 语义，避免快照拼合错误 | root SPEC §9 | order book ingest | proposed MINOR; depends exchange update_id semantics |
| FR-016 | 新 symbol 和首次部署需要历史覆盖基线 | server/SPEC §7 Backfill | storage completeness | proposed MINOR; depends REST rate budget |
| FR-017 | gap detector 是回填触发源，避免静默缺口 | server/SPEC §7 | data quality | proposed MINOR; depends taosx/postgresx jobs |
| FR-018 | 回填限速必须保护实时链路预算 | server/SPEC §7 | operational safety | proposed MINOR; depends Binance weight model |
| FR-019 | REST 回填与 WS 实时链路必须共用幂等键 | BR-008 extension | duplicate prevention | proposed MINOR; depends FR-017/FR-018 |
| FR-021 | 日级对账提供跨源一致性检查 | server/SPEC §7 | reconciliation alerts | proposed MINOR; depends FR-016/FR-017 |
| FR-022 | 冷数据命中时需要可审计回热流程 | FR-007 extension | archive query UX | proposed MINOR; depends ossx archive layout |
| FR-023 | operator 需要覆盖率和回填 job 可见性 | server/SPEC §7 | admin visibility | proposed MINOR; depends auth/status/pagination contract |
| FR-024 | symbol 变更应可热加载，避免重启 client/server | client/SPEC §7 + server/SPEC §7 | control-plane operations | proposed MINOR; depends symbols.changed contract |

## 3. 评审风险清单

- #880：`instruments.changed` / `symbols.changed` 必须使用控制面命名空间，避免和 market data subject 混用；catalog 写入归属需在 server 侧定稿。
- #881：`listenKey` 只适用于 user-data stream；public market stream 不应继承该要求。
- #882/#883：interval、partial depth、diff depth、snapshot 与 update_id 语义必须按 product_line 分表确认，不能用单行规则覆盖全部产品。
- #884~#887：回填 source API、gap key、限速权重和幂等键必须按 event_type × product_line 固定，depth 无历史回填要显式标为 unsupported。
- #888：`funding_rate` / `mark_price` 命名层已按 4 × 6 全矩阵保留；runtime 若仅支持 futures 产出，必须以 capability/status 标识暂不产出的产品线。
- #889~#892：对账、回热、进度 API、热重载都需要 auth/status/pagination/rollback/compatibility 合同后才能进入 Approved SPEC。

## 4. Fold 前门禁

- FR-012~FR-019 可作为 P0 两阶段进入 SPEC：先实时控制面，再历史生命周期。
- FR-020 已和 event_type 6 值矩阵、Kafka topic、taosx 超表、AC/TC 一起折叠进 v3.0.0；后续只允许补 runtime capability/status 证据，不得回退命名矩阵。
- FR-021~FR-024 依赖前置生命周期锚点，不应先于 FR-012~FR-019 合入 Approved SPEC。
- fold PR 必须同步更新 `SPEC.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`client/SPEC.md`、`server/SPEC.md` 和相应任务状态。
