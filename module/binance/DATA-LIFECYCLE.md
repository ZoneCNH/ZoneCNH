# module/binance DATA-LIFECYCLE.md — 数据生命周期正式提案（runtime pending）

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Formal Proposal / Runtime Evidence Pending |
| Module-Version | v3.5.0 |
| Last-Updated | 2026-06-23 |
| Scope | `module/binance` stage2 lifecycle planning |
| Spec-Impact | 已 fold：FR-012~FR-030 已登记到 `SPEC.md`/`TRACEABILITY.md`，相关命名落点已投影到 `NAMING.md`；本文件仍不声明 runtime contract |
| Source Plan | `docs/report/binance/goal-execution-plan-20260622.md` 阶段 2 / AC-3 |

> [COMPUTED, HIGH] FR-012~FR-030 已登记到 `SPEC.md`/`TRACEABILITY.md`，相关命名落点已投影到 `NAMING.md`；本文仍是 lifecycle planning 与 issue closure mapping，不构成 runtime behavior、CI pass、GitHub Release 或 release evidence 完成证明。
>
> 本文件记录 FR-012~FR-030 的正式提案落点和版本影响台账。任一能力翻转为 Done 前，仍必须通过 Spec -> Review -> Matrix -> Tasks -> Plan -> Prompt -> Code 管线、runtime 测试证据、CI/live smoke 和 release gate；不得把下列内容视为 runtime behavior 或 release evidence 已完成。

## 1. 15 个生命周期缺口

| # | 缺口 | 影响 | 建议落点 |
| --- | --- | --- | --- |
| G01 | WebSocket 连接、重连、退避和会话归属没有统一生命周期 | client 侧故障恢复口径不稳定 | FR-012 |
| G02 | listenKey 创建、续租、过期和恢复没有 owner/状态机 | 用户数据流未来扩展容易泄漏状态 | FR-012 |
| G03 | Binance weight/rate-limit 预算没有配置 gate | 运行期容易在 backfill 或重连时触发封禁 | FR-013 |
| G04 | server time 校准与本地 clock skew 没有验收口径 | event_time / receive_time 追溯不可靠 | FR-013 |
| G05 | 实时流暂停、恢复、drain 与优雅关闭未定义 | 发布、扩容和故障处理不可验证 | FR-015 |
| G06 | status API 未绑定 lag、断流、重连、缓存 freshness | L1/L2 状态分层缺少可观测闭环 | FR-014 |
| G07 | 历史 backfill 窗口、分页、边界闭合规则缺失 | 补数会产生重复或断档 | FR-016 |
| G08 | 实时断档检测与 replay 触发条件未定义 | market data 完整性无法证明 | FR-017 |
| G09 | replay 幂等边界与 SetNX/存储写入顺序未固化 | 重放可能污染下游存储 | FR-019 |
| G10 | ossx 归档 retention、manifest、replay 索引未定义 | 冷数据恢复不可审计 | FR-018 |
| G11 | late/out-of-order event 的接收、纠偏、拒绝策略缺失 | K 线、深度和逐笔事实口径可能漂移 | FR-017 |
| G12 | dead-letter / poison message 回放流程未定义 | 下游失败后无法形成运营闭环 | FR-019 |
| G13 | funding-rate、mark-price、index-price 等扩展事件未纳入矩阵治理 | 新事件会绕开 NAMING/RULES/RUNTIME-MAPPING | FR-020 / FR-021 / FR-022 |
| G14 | runtime config hot reload、冻结、回滚边界缺失 | 运维变更无法证明不破坏数据生命周期 | FR-024 |
| G15 | 证据包、traceability、acceptance 与 release gate 未串联 | 文档通过不等于实现可放行 | FR-023 |

## 2. 13 个建议 FR 落点

| FR | 建议标题 | Landing doc | Bump | Dependencies | 覆盖缺口 |
| --- | --- | --- | --- | --- | --- |
| FR-012 | Stream session lifecycle | `SPEC.md` client runtime / `client/IMPLEMENTATION-PLAN.md` | MINOR v2.4.0 | FR-001, FR-003 | G01, G02 |
| FR-013 | Rate-limit, retry budget, and clock-skew guard | `SPEC.md` config/errors / `ACCEPTANCE.md` | MINOR v2.4.0 | FR-001, FR-004 | G03, G04 |
| FR-014 | Status and lag control API | `SPEC.md` Gin/status / `TRACEABILITY.md` | MINOR v2.4.0 | FR-007, FR-009 | G06 |
| FR-015 | Operational pause/resume/drain | `SPEC.md` runtime control / `BOUNDARY-GATES.md` | MINOR v2.4.0 | FR-003, FR-004, FR-009 | G05 |
| FR-016 | Backfill window planning | `SPEC.md` history lifecycle / `server/IMPLEMENTATION-PLAN.md` | MINOR v2.5.0 | FR-006a, FR-006d | G07 |
| FR-017 | Gap detection and replay trigger | `SPEC.md` history lifecycle / `RUNTIME-MAPPING.md` | MINOR v2.5.0 | FR-004, FR-005, FR-006a | G08, G11 |
| FR-018 | Archive retention and replay manifest | `SPEC.md` ossx lifecycle / `server/tasks/TASK-BINANCE-SERVER-016-ossx-archiver.md` | MINOR v2.5.0 | FR-006d | G10 |
| FR-019 | Backfill concurrency and idempotency gates | `ACCEPTANCE.md` / `TRACEABILITY.md` | MINOR v2.5.0 | FR-005, FR-011, FR-016, FR-017 | G09, G12 |
| FR-020 | Funding-rate event support | `SPEC.md` event taxonomy / `NAMING.md` | MAJOR v3.0.0 | FR-001, FR-003, FR-006a, FR-009 | G13 |
| FR-021 | Mark-price and index-price event support | `SPEC.md` event taxonomy / `NAMING.md` | MAJOR v3.0.0 | FR-001, FR-003, FR-006a, FR-009 | G13 |
| FR-022 | Event-type matrix expansion governance | `RULES.md` / `NAMING.md` / `RUNTIME-MAPPING.md` | MAJOR v3.0.0 | FR-020, FR-021 | G13 |
| FR-023 | Governance evidence bundle | `ACCEPTANCE.md` / `TRACEABILITY.md` / `docs/report/binance/` | MINOR v3.1.0 | boundary gates, CI evidence | G15 |
| FR-024 | Runtime config hot reload | `STANDARD.md` / `SPEC.md` | MINOR v3.1.0 | FR-014, FR-015 | G14 |

## 3. Review checklist

- [x] Confirm whether FR-012 through FR-015 are the minimum set for the next realtime-control SPEC bump.
- [x] Confirm whether historical backfill and replay work should stay in v2.5.x or split across implementation milestones.
- [x] Confirm whether event-type expansion must be a v3.0.0 major bump because it changes the 4 × 4 canonical matrix.
- [x] Confirm whether `STANDARD.md` should be created in stage 6 before FR-024 lands.

## 4. Review outcome

[COMPUTED, HIGH] 2026-06-22 review closed the planning checklist for this lifecycle proposal: FR-012 through FR-015 are the next realtime-control SPEC bump candidate set; FR-016 through FR-019 stay grouped as the v2.5.x historical lifecycle candidate set; FR-020 through FR-022 remain a v3.0.0 MAJOR candidate because they change the canonical event matrix; `STANDARD.md` is required before FR-024 can be promoted into SPEC.

[FRAME, HIGH] This outcome approves only the issue split, dependency order, bump class, and document landing plan, and records that `SPEC.md`/`TRACEABILITY.md` now carry FR-012~FR-030. It does not approve runtime behavior, does not mark runtime evidence complete, and does not mark any release DoD item done. `NAMING.md` may carry the proposal as Pending projection, but runtime status remains Pending until implementation evidence exists.

## 5. Open questions

1. Should late/out-of-order policy be event-type specific, or should the first SPEC update define one conservative module-wide default?
2. Should replay evidence be attached to every release, or only to releases that touch backfill, ossx, Kafka, or TAOS writes?
3. Should funding-rate and mark/index price be separate event types, or grouped under a future derived-market event family?

## 6. Issue 原始诉求 → 现有 FR 覆盖映射（2026-06-23 补齐）

> [COMPUTED, HIGH] 2026-06-23 全量 issue 核查发现：GitHub issue #880~#892（R-01~R-13）的标题语义是 2026-06-22 早期提案，本提案 §4 review 已将它们重组为更合理的 FR-012~024 落点。本节逐条映射 issue 原始诉求 → 现有 FR 覆盖关系，并对未覆盖项声明落点，确保每条 issue 的实质能力都有 FR 承接。

[FRAME, HIGH] 术语归一：`funding-rate` / `mark-price` 的 runtime `event_type` 值分别按 snake_case 记录为 `funding_rate` / `mark_price`；R-06 的 runtime gap detector 结果进入 `binance_backfill_jobs` 队列；#880/#892 的热重载入口以 `symbols/reload` 管理；本讨论稿保持 non-normative，任何 Done 翻转须通过 Fold 前门禁、runtime evidence 和 release evidence 门禁。

| Issue | 原始诉求 | 现有 FR 覆盖 | 覆盖判定 | 未覆盖落点 |
| --- | --- | --- | --- | --- |
| #880 R-01 | FR-012 Symbol Discovery & Filtering（exchangeInfo 拉取 + allow/deny + 6h 刷新 + instruments.changed） | FR-012 Stream Session Lifecycle（未含 catalog discovery） | ⚠️ 部分覆盖 | 并入 FR-012：catalog discovery 是 stream session 前置；`instruments.changed` subject 见 §7 |
| #881 R-02 | FR-013 WebSocket Connection Policy（重连退避 + stream 上限 + keepalive + listenKey 续期） | FR-013 Rate-limit/retry/clock-skew guard | ✅ 覆盖 | — |
| #882 R-03 | FR-014 Bar Interval Subscription Set（1s/1m/5m/15m/1h/4h/1d 枚举） | 未单列 FR | ⚠️ 未覆盖 | 并入 NAMING §2 订阅周期集枚举（见 §7） |
| #883 R-04 | FR-015 Depth Snapshot Tier（@depth20@100ms + @depth@1000ms 增量 + update_id 拼合） | FR-015 Pause/Resume/Drain（未含 depth tier） | ⚠️ 部分覆盖 | 并入 FR-015 depth 订阅档位定义（见 §7） |
| #884 R-05 | FR-016 Historical Backfill on Cold Start（REST 拉历史 + 默认深度） | FR-016 Backfill Window Planning | ✅ 覆盖 | — |
| #885 R-06 | FR-017 Gap Detection & Fill（5min detector + trade 连号 + bar 窗口 + backfill_jobs 队列） | FR-017 Gap Detection and Replay | ✅ 覆盖 | — |
| #886 R-07 | FR-018 Backfill Throttle & Priority（token bucket + 80/20 配额 + 优先级） | FR-018 Archive Manifest（未含 throttle） | ❌ 未覆盖 | 新增 FR-025 Backfill Throttle & Priority（见 §7） |
| #887 R-08 | FR-019 Backfill Idempotency Key Strategy（trade/bar key 维度） | FR-019 Backfill Concurrency and Idempotency Gates | ✅ 覆盖 | — |
| #888 R-09 | FR-020 Funding Rate / Mark Price Stream + event_type 4→6 | FR-020 Funding-rate + FR-021 Mark-price + FR-022 Event-type Matrix | ✅ 覆盖 | — |
| #889 R-10 | FR-021 Daily Reconciliation Job（04:00 UTC 对账 + tolerance） | FR-021 Mark-price（未含 reconciliation） | ❌ 未覆盖 | 新增 FR-026 Daily Reconciliation Job（见 §7） |
| #890 R-11 | FR-022 Cold Data Rehydration（OSS→taosx 回热 + 202 + job_id） | FR-022 Event-type Matrix（未含 rehydration） | ❌ 未覆盖 | 新增 FR-027 Cold Data Rehydration（见 §7） |
| #891 R-12 | FR-023 Backfill Progress API（jobs + coverage 查询） | FR-023 Evidence Bundle（未含 progress API） | ❌ 未覆盖 | 新增 FR-028 Backfill Progress API（见 §7） |
| #892 R-13 | FR-024 Symbol Subscription Hot Reload（reload endpoint + stream diff） | FR-024 Runtime Config Hot Reload | ✅ 覆盖 | — |

## 7. 已登记落点声明（FR-025~030 + NAMING/subject 补充）

> [FRAME, HIGH] 以下为历史讨论稿到当前 `SPEC.md`/`TRACEABILITY.md` 的落点对齐声明。FR-025~FR-030 已登记；runtime/release evidence 仍 Pending，不得据此关闭功能实现或发布 DoD。
>
> [COMPUTED, HIGH] 追溯闭环口径：FR-012~FR-030 的 FR/AC/TC 已登记于 `SPEC.md`/`TRACEABILITY.md`；本讨论稿保持 non-normative，runtime evidence 仍为 Pending（L1/local 证据已采集，L2/L3/live/release 未闭合）。

| FR | 标题 | Landing | Bump | 覆盖 issue / Beads |
| --- | --- | --- | --- | --- |
| FR-025 | Backfill Throttle & Priority（token bucket: spot 1200/futures 2400 weight/min；80% 实时 / 20% 回填；priority trade>bar>tick） | `server/SPEC.md` §7 throttle | MINOR | #886 |
| FR-026 | Daily Reconciliation Job（04:00 UTC；symbol×1d 比对 taosx OHLCV vs Binance /api/v3/klines；tolerance 0.01%；入 binance_reconciliation_alerts） | `server/SPEC.md` §7 reconciliation | MINOR | #889 |
| FR-027 | Cold Data Rehydration（/api/v1/market/ticks/:symbol/range 命中 OSS 归档区 → async OSS→taosx 回热 24h TTL；202 + job_id 轮询） | `SPEC.md` FR-007 扩展 | MINOR | #890 |
| FR-028 | Backfill Progress API（GET /api/v1/admin/backfill/jobs + /coverage/:symbol 返回 (pl, symbol, et) 最早时间戳） | `server/SPEC.md` §7 admin API | MINOR | #891 |
| FR-029 | Data Quality & Freshness SLA（event_time→persist P95/P99、stale alert、schema drift evidence） | `SPEC.md` / `TRACEABILITY.md` / runtime evidence | MINOR | Beads P2-2 |
| FR-030 | Options Chain Raw Field Pass-through（strike/expiry/option_type/mark/IV 原始字段透传；Greeks 归分析域） | `SPEC.md` / `TRACEABILITY.md` / NAMING subject matrix | MINOR | Beads P2-4 |
| NAMING §2 | 订阅周期集枚举：spot/um_perp/cm_perp = 1s,1m,5m,15m,1h,4h,1d；options = 1m,5m,1h,1d；其他周期下游 clickhousex 重采样 | `NAMING.md` §2 | PATCH | #882 |
| NAMING subject | `instruments.changed`（symbol 目录变更）+ `symbols.changed`（订阅白黑名单热重载） | `NAMING.md` §3 | MINOR | #880, #892 |
| FR-015 扩展 | depth 订阅档位：spot/um_perp/cm_perp = @depth20@100ms + @depth@1000ms 增量；options = @depth1000；update_id 拼合 | `SPEC.md` §9 | MINOR | #883 |

[FRAME, HIGH] 本节声明后，issue #880~#892 与 Beads P2-2/P2-4 的规格层落点都有明确 FR 承接（已覆盖 6 项 + FR-025~FR-030 + NAMING/FR 扩展）。runtime evidence 和 release evidence 未闭合；后续只能按 `/home/binance` runtime 测试、CI/live smoke 与 release evidence 关闭实现项。

## 8. 版本与影响矩阵（runtime pending）

| 切面 | v4/v5 影响 | Bump 判定 | 当前状态 | 关闭证据 |
| --- | --- | --- | --- | --- |
| event_type | 4 -> 6，新增 `funding_rate`、`mark_price` | runtime 接口、存储或 fanout 暴露时按 MAJOR 处理 | Pending | `NAMING.md` / `RUNTIME-MAPPING.md` / `SPEC.md` 同步更新 + event matrix 测试 |
| tables | `binance_backfill_jobs`、reconciliation alerts、coverage、archive/rehydration metadata、quality/gap metrics | 仅内部表为 MINOR；对外查询合同变化按 MAJOR 评估 | Pending | schema migration、repository 测试、回填/对账集成证据 |
| topics/subjects | NATS 4x4 baseline 保持；Kafka topic 需版本化；新增 `instruments.changed` / `symbols.changed` | subject/topic 扩展默认 MINOR；event matrix 变化按 MAJOR | Pending | subject mapping、boundary gate、fanout integration evidence |
| metrics | stream lag、retry、gap、backfill、reconciliation、quality、coverage 指标 | MINOR | Pending | metrics contract、alert rule、smoke/test evidence |
| version ledger | FR-012~019 v2.4/v2.5；FR-020~022 v3.0 MAJOR；FR-023~030 v3.x staged；全部仍为 proposal / evidence pending | Proposal only | Pending | Spec -> Code artifacts、CI、release evidence |
