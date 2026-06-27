# AC-BNC 遗留编号映射（v2.0.0 历史遗物）

> 迁移自 `module/binance/spec/SPEC.md` Appendix D（v3.9.0 迁移）。本文件是 v2.0.0 时期的验收口径快照，仅覆盖 FR-001~FR-011 共 18 条 AC。当前模块已扩展至 44 FR / 130 AC，完整 AC 注册表维护于 `module/binance/matrix/TRACEABILITY.md §5`，实现状态见 `module/binance/spec/ACCEPTANCE.md §2` 与 `module/binance/matrix/TRACEABILITY.md §6`。

> **弃用声明**：本 Registry 是 v2.0.0 时期的验收口径快照，仅覆盖 FR-001~FR-011 共 18 条 AC（编号 AC-BNC-001 ~ AC-BNC-018）。当前模块已扩展至 44 FR / 130 AC（AC-001 ~ AC-130），完整 AC 注册表单点维护于 `module/binance/matrix/TRACEABILITY.md §5`，实现状态见 `module/binance/spec/ACCEPTANCE.md §2` 与 `module/binance/matrix/TRACEABILITY.md §6`。
>
> **编号映射**：AC-BNC-001→AC-001、AC-BNC-002→AC-002、…、AC-BNC-018→AC-018（一一对应）。AC-019~AC-130 为 v2.1.0 后扩展，无对应 AC-BNC 编号。
>
> 以下内容为历史存档，Status 列的 `Approved` 仅表示需求已批准纳入规格，**不代表 runtime 实现已完成**。

| AC ID      | FR/BR Ref            | Criterion                                                                                                    | Verification                          | Status   |
| ---------- | -------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------- | -------- |
| AC-BNC-001 | FR-001               | Spot / USDⓈ-M / COIN-M / Options 四产品线 connector 均可独立启停，配置禁用时不订阅对应 stream                | TC-001, integration test              | Approved |
| AC-BNC-002 | FR-002               | parser 对 Spot `BTCUSDT` 与 USDⓈ-M `BTCUSDT` 输出不同 `InstrumentKey`，product_line/settlement/expiry 维度不碰撞 | TC-002, TC-003                        | Approved |
| AC-BNC-003 | FR-003               | client 调用 `js.Publish(subj, jsonPayload)` 成功后必须收到 JetStream PubAck；Stream=`BINANCE_MARKET` Retention=7d | TC-004, BOUNDARY-GATES.md §3-§4       | Approved |
| AC-BNC-004 | FR-004, BR-004       | server 仅在 redisx + taosx + postgresx + kafkax handoff 全部成功后调用 `msg.Ack()`，失败路径走 `NakWithDelay` | TC-006（非 boundary gate）            | Approved |
| AC-BNC-005 | FR-005, BR-008       | redisx SetNX 首次成功进入 storage/fanout；重复 key 同 payload 返回 idempotent ACK；payload 冲突返回 terminal_conflict | TC-007, TC-008                        | Approved |
| AC-BNC-006 | FR-006a              | taosx WriteBatch 写入 tick/bar/depth 到对应超级表子表；失败时不 Ack 并 NakWithDelay(5s)                       | TC-009, TC-011                        | Approved |
| AC-BNC-007 | FR-006b              | postgresx 通过 `ON CONFLICT DO UPDATE` 幂等 upsert `binance_instruments` 表，不可达时返回 error              | TC-010                                | Approved |
| AC-BNC-008 | FR-006c              | redisx 热缓存 SET(tick, 60s) / SET(depth, 5s) 成功；失败时降级到 taosx 直查，不阻塞主管线                    | TC-023                                | Approved |
| AC-BNC-009 | FR-006d, FR-008      | ossx 归档路径 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet`；ETag 校验通过才删 taosx 热数据 | TC-016, TC-017                        | Approved |
| AC-BNC-010 | FR-007               | `GET /api/v1/market/{ticks,bars,depth,trades}/:symbol` 走 redisx 热缓存优先，cache miss 回退 taosx；无效 token 返回 401，超限返回 429 | TC-012, TC-013, TC-014, TC-015        | Approved |
| AC-BNC-011 | FR-007a, FR-010      | clickhousex analytics API（vwap/top-movers/correlation/volume-profile）通过 OLAP 查询返回结果；不可达返回 503，实时 API 不受影响 | TC-024, TC-025, TC-026                | Approved |
| AC-BNC-012 | FR-008               | server storage 全部成功后 kafkax Send 到 `binance.{product_line}.{event_type}.v1`，key=symbol；handoff 完成前不得 Ack | TC-018, TC-019                        | Approved |
| AC-BNC-013 | FR-009, BR-002, BR-003 | CI boundary gate 拦截 client→server internal import / server→client internal import / `internal/cs` 引用 / `binance-market` 引用 | TC-020, TC-021, TC-022                | Approved |
| AC-BNC-014 | FR-010               | ETL scheduler 每 5 分钟从 taosx 聚合 1m_ohlcv/5m_vwap/15m_stats 写入 clickhousex；失败时跳过本批次不阻塞热路径 | TC-025, TC-026                        | Approved |
| AC-BNC-015 | FR-011               | redisx SetNX 分布式锁竞选 coordinator；成功者启动 ETL+归档，每 10s 续期 lease；失败时主动 Del 或 lease 过期由 standby 接管 | TC-027, TC-028                        | Approved |
| AC-BNC-016 | BR-005, BR-006, BR-007 | 模块不定义 canonical domain enum、不引入 `github.com/ZoneCNH/strategy`、不定义本地 proto/wire schema       | CI ownership/wire-contract gate       | Approved |
| AC-BNC-017 | §19 Security         | 配置文件无明文凭据；所有 Secret 通过环境变量注入；日志/admin 端点不暴露 API Key/Signature；gitleaks 零命中    | CI gitleaks gate                      | Approved |
| AC-BNC-018 | §17 Performance      | natsx PubAck P99 < 10ms、server consumer process P99 < 50ms、Gin /api/v1/market/ticks (redisx hit) P99 < 5ms | `go test -bench` + httptest benchmark | Approved |

> Coverage：18 条 AC 覆盖 FR-001..FR-011（11/11）+ BR-002/BR-003/BR-004/BR-005/BR-006/BR-007/BR-008（7/9，其余 BR-001/BR-009 已由 §16 TC + §19 Admin Boundary 覆盖）+ §17/§19 NFR。
