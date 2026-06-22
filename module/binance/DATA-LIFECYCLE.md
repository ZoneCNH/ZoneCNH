# module/binance DATA-LIFECYCLE.md — 数据生命周期讨论稿

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Discussion Draft |
| Doc-Version | v0.1.0 |
| Last-Updated | 2026-06-22 |
| Scope | `module/binance` stage2 lifecycle planning |
| Spec-Impact | 无；本讨论稿不修改 `SPEC.md`，不产生 runtime contract |
| Source Plan | `docs/report/binance/goal-execution-plan-20260622.md` 阶段 2 / AC-3 |

> 本文件用于把后续实时控制面、历史补偿、event-type 扩展与治理证据拆成可评审的 FR 落点。它不是 SPEC change；在评审通过并形成对应 issue/PR 前，不应把下列内容视为已批准接口。

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

[COMPUTED, HIGH] 2026-06-22 review closed the planning checklist for this discussion draft: FR-012 through FR-015 are the next realtime-control SPEC bump candidate set; FR-016 through FR-019 stay grouped as the v2.5.x historical lifecycle candidate set; FR-020 through FR-022 remain a v3.0.0 MAJOR candidate because they change the canonical event matrix; `STANDARD.md` is required before FR-024 can be promoted into SPEC.

[FRAME, HIGH] This outcome approves only the issue split, dependency order, bump class, and document landing plan. It does not approve runtime behavior, does not update `SPEC.md`, does not change `TRACEABILITY.md`, and does not mark any release DoD item done.

## 5. Open questions

1. Should late/out-of-order policy be event-type specific, or should the first SPEC update define one conservative module-wide default?
2. Should replay evidence be attached to every release, or only to releases that touch backfill, ossx, Kafka, or TAOS writes?
3. Should funding-rate and mark/index price be separate event types, or grouped under a future derived-market event family?
