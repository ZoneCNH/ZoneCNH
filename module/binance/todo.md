# module/binance TODO — 生产级可发布差距清单

- **创建日期**：2026-06-27
- **Last-Updated**：2026-06-27
- **来源**：本文件、[`spec/ACCEPTANCE.md`](spec/ACCEPTANCE.md)、[`matrix/TRACEABILITY.md`](matrix/TRACEABILITY.md) 与 [`evidence/2026-06-27/review/ISSUE-BLOCKERS-1268-1279.md`](evidence/2026-06-27/review/ISSUE-BLOCKERS-1268-1279.md) 的当前可验证状态
- **Spec-Version**：v3.9.0
- **Runtime-Anchor**：`/home/binance@0602e78428633a368b0afcd1c578c07ed7144752` + local working tree evidence package `/home/binance/release/evidence/binance/20260627-agent-audit-2/`
- **当前状态**：v0.2.0 可编译可发布，但**不可生产运营**；Code-State **23 Done / 25 Partial / 0 Drifted / 0 Pending**；Evidence-State **1 Done (FR-009) / 43 Pending**；7 PRG Evidence-Pending / Code-Partial-or-Code-Done anchors；FR-031~036、FR-038~044 为 Code-Partial / Evidence-Pending；FR-037 为 Code-Done / Evidence-Pending。

> [COMPUTED, HIGH] 本文件是 spec 层结构性修复（MA-1~MA-4 + MO-2，已完成）之后的**剩余未完成项**清单。完成状态基于 2026-06-27 对 spec 文件和 `/home/binance` runtime 代码的交叉验证；P0-5、P0-10、P1-6、P2-8 以及 legacy mapping 等文档可验证状态已同步为完成，runtime/外部环境项仍保留为未完成或阻塞。
>
> [COMPUTED, MED] 2026-06-27 agent team 再审计发现若干 runtime 代码原语已出现（trace context header、append-only audit DDL、exchangeInfo refresher、FileHistoryStateStore、`cmd/binance-client` 的 `XGO_BINANCE_HISTORY_STATE_FILE` 本地接线、persistent DLQ writer hook、`cmd/binance-server` 的 `XGO_BINANCE_DLQ_FILE` 本地接线），且 FR-037 的 XGO feature flag、canary gate、rollback runbook、env template 与 readiness guard 已补齐本地代码门禁；但 Runtime-Anchor 投影、direct TC、live/evidence 或外部生产演练未闭合的条目仍按“代码原语存在≠验收闭合”同步为部分完成/证据待闭合。
>
> [COMPUTED, HIGH] 2026-06-27 GitHub #1268-#1279 为 `OPEN`；Beads `ZoneCNH-xzcr*` 为 `in_progress` Evidence-Done blocker ownership；账本位于 [`evidence/2026-06-27/review/ISSUE-BLOCKERS-1268-1279.md`](evidence/2026-06-27/review/ISSUE-BLOCKERS-1268-1279.md)。#1269/#1277/#1278/#1279 有本地直接证据 [`evidence/2026-06-27/test/worker-a-runtime-evidence.md`](evidence/2026-06-27/test/worker-a-runtime-evidence.md)，其中 #1278/#1279 的新增 runtime evidence 已归档到 `/home/binance/release/evidence/binance/20260627-agent-audit-2/backfill-progress-restart-evidence.md` 与 `/home/binance/release/evidence/binance/20260627-agent-audit-2/dlq-snapshot-replay-evidence.md`。tracker open state 只表示缺口归属与执行跟踪，不得解读为 Evidence-Done；direct TC、live/external 或合规演练证据仍按下表阻塞。
>
> [COMPUTED, HIGH] 2026-06-27 agent-team sync 已把 Beads `ZoneCNH-xzcr*` 备注和 GitHub #1268-#1279 评论同步到当前 blocker 口径；未关闭任何 issue。`sre/secrets/env/dev.md` 只做 key-family inventory：`redisx`/`kafkax`/`natsx`/`postgresx`/`taosx`/`ossx`/`clickhousex` 配置族存在，未复制任何 secret 值。`/home/binance/release/evidence/binance/20260627-agent-audit-2/status.txt` 为本地 runtime evidence PASS；`issue-repeat-check-10x.log` 对 targeted checks 连续 10/10 PASS。该结果只证明本地证据增强，仍不满足生产 Evidence-Done。
>
> [COMPUTED, HIGH] Issue 拆解与剩余 Evidence blocker 对齐如下；该表是未完成 evidence ownership，不改变下方 TODO 完成率。

| GitHub | Beads             | 覆盖范围                                                          | 当前判定                                                                                |
| ------ | ----------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| #1268  | `ZoneCNH-xzcr`    | P0/P1/P2 evidence closure epic                                    | Tracker open / Evidence pending，等待所有子项 Evidence-Done |
| #1269  | `ZoneCNH-xzcr.1`  | FR-013/017/025/037 direct TC/live/canary                          | Tracker open / local evidence attached，direct TC/live/canary 待闭合 |
| #1270  | `ZoneCNH-xzcr.2`  | FR-039 tracing OTel/NATS/header E2E                               | Tracker open / Evidence pending，OTel/NATS/live span-chain 待闭合 |
| #1271  | `ZoneCNH-xzcr.3`  | FR-040 quota/backpressure/multi-tenant soak                       | Tracker open / Evidence pending，多租户 soak 待闭合 |
| #1272  | `ZoneCNH-xzcr.4`  | FR-041 audit log lifecycle/admin proof                            | Tracker open / Evidence pending，完整 lifecycle evidence 待闭合 |
| #1273  | `ZoneCNH-xzcr.5`  | redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex external E2E | Tracker open / Evidence pending，外部依赖 E2E 证据未达 Evidence-Done |
| #1274  | `ZoneCNH-xzcr.6`  | FR-001 UM/CM/Options testnet/mainnet live-gated                   | Tracker open / Evidence pending，产品线 credentialed testnet/live 证据未闭合 |
| #1275  | `ZoneCNH-xzcr.7`  | FR-043 cost dashboard/alert/report                                | Tracker open / Evidence pending，dashboard/alert 证据待闭合 |
| #1276  | `ZoneCNH-xzcr.8`  | FR-044 destruction drill/cert/archive                             | Tracker open / Evidence pending，合规销毁演练与证书归档待闭合 |
| #1277  | `ZoneCNH-xzcr.9`  | FR-031~036 ExchangeInfo runtime/direct TC/live                    | Tracker open / local evidence attached，四线 runtime/direct TC/live 待闭合 |
| #1278  | `ZoneCNH-xzcr.10` | Backfill progress restart persistence                             | Tracker open / local evidence attached，本地 file-store restart 与 fake Postgres state-store evidence 已归档；生产持久介质/真实重启归档/live historical capture 待闭合 |
| #1279  | `ZoneCNH-xzcr.11` | DLQ snapshot/replay persistence                                   | Tracker open / local evidence attached，本地 DLQ file writer、JSONL reader 与 admin file-backed replay evidence 已归档；Kafka/NATS/live replay 待闭合 |

---

## 总览

| 优先级      |  总数  | 已完成 | 未完成 | 完成率  |
| ----------- | :----: | :----: | :----: | :-----: |
| P0 本地闭合 |   10   |   10   |   0    |  100%   |
| P1 强烈建议 |   8    |   3    |   5    |   38%   |
| P2 可延后   |   8    |   3    |   5    |   38%   |
| **合计**    | **26** | **16** | **10** | **62%** |

---

## P0 本地代码门禁 — 已完成（0 项未完成；证据待闭合）

### P0-1：FR-013 runtime 分钟限流模型对齐

- **状态**：✅ 已完成（2026-06-27）
- **对应**：FR-013 / Spec-Runtime Drift（CR-1）
- **Runtime 位置**：`/home/binance/internal/server/controlplane/reliability.go`
- **完成内容**：新增 `RecordUsedWeight`（X-MBX-USED-WEIGHT-1M header 解析）+ `HTTPBackoffController`（429 AIMD 指数退避 + 418 IP 封禁 15min 暂停）+ `ClockSkewDetector.CheckMonotonic`（单调性检测）+ `DriftRate`（ms/min 漂移率）
- **验证**：`go build` / `go vet` / `go test` / `boundary-gates.sh 14/14 PASS`

### P0-2：FR-017 runtime 分策略缺口检测对齐

- **状态**：✅ 已完成（2026-06-27）
- **对应**：FR-017 / Spec-Runtime Drift（CR-1）
- **Runtime 位置**：`/home/binance/internal/server/quality.go`
- **完成内容**：`observe()` 方法按 event_type 分策略 — trade→trade_id 序列、bar→open_time 序列、depth→updateId 序列（跳跃→快照刷新）、tick→事件驱动仅记录、funding_rate/mark_price→时间间隔、default→时间间隔回退。新增 `extractInt64` 辅助函数 + `lastTradeID`/`lastUpdateID`/`lastBarOpenTime` map
- **验证**：`go test ./internal/server/` PASS（3 个测试已适配新逻辑）

### P0-3：FR-025 runtime P0/P1/P2 三级优先级对齐

- **状态**：✅ 已完成（2026-06-27）
- **对应**：FR-025 / Spec-Runtime Drift（CR-1）
- **Runtime 位置**：`/home/binance/internal/client/throttle.go`
- **完成内容**：新增 `ThrottlePriority`（P0/P1/P2）+ `AllowPriority()` 方法 + `parsePriorityRatio("30:20:50")` + p0/p1/p2 token bucket + Snapshot 新增 P0/P1/P2 字段。旧 80/20 `Allow()` 保留向后兼容
- **验证**：`go test ./internal/client/` PASS

### P0-4：Wire envelope schema version enforcement

- **状态**：✅ 已完成（2026-06-27）
- **对应**：FR-042 / PRG-003
- **Runtime 位置**：`/home/binance/internal/server/server.go`
- **完成内容**：新增 BNC-014 `CodeSchemaVersionIncompatible` reject code + `RejectSchemaVersion` 常量 + `validateSchemaVersion` 函数 major 不匹配时返回 BNC-014（非 BNC-007）
- **验证**：`go test ./internal/server/` PASS（测试已适配 BNC-014）

### P0-5：Release safety net（feature flag + canary + rollback）

- **状态**：✅ 已完成（2026-06-27，本地代码门禁；生产演练证据待闭合）
- **对应**：FR-037 / PRG-003
- **Runtime 位置**：`/home/binance/internal/server/api/feature_flag.go` + `/home/binance/scripts/deploy-canary-gate.sh` + `/home/binance/configs/binance-server.env.example` + `/home/binance/docs/runbooks/plan008-deploy-health-rollback.md`
- **完成内容**：`XGO_BINANCE_FEATURE_ASYNC_COLD_RANGE=false` 默认关闭开关与 `FOUNDATIONX_BINANCE_FEATURE_ASYNC_COLD_RANGE` 兼容读取已接入；`deploy-canary-gate.sh` 已覆盖 `/healthz`、`/readyz`、error-rate、consumer lag 与 rollback command；env template、deploy runbook 与 readiness audit guard 已同步。
- **剩余证据**：真实生产 canary 执行记录与 rollback drill 归档仍属于 Evidence-Pending，不在本地代码门禁内冒充完成。
- **工作量**：本地代码已完成；外部证据另行治理

### P0-8：kafkax retry/DLQ topic contract

- **状态**：✅ 已完成（2026-06-27）
- **对应**：PRG-002
- **Runtime 位置**：`/home/binance/internal/server/kafka_dispatch.go`
- **完成内容**：新增 `DLQTopicForEvent()` + `RetryTopicForEvent()` 函数，构造 `binance.{pl}.{et}.v1.dlq` 和 `binance.{pl}.{et}.v1.retry` topic 名
- **验证**：`go build ./internal/server/` PASS

### P0-10：ADR — order book rebuild 排除决策

- **状态**：✅ 已完成（2026-06-27）
- **对应**：MO-4 / #1114 / ADR-003
- **完成内容**：ADR-003 已 Accepted；`FEATURES.md` 已移除"待 ADR"口径，明确 v0.2.0 排除 order book rebuild 状态机，depth 数据以快照形式落库，不做本地重放，未来升级路径由独立 FR/ADR 承接。
- **验证**：`module/binance/design/ADR-003-order-book-rebuild-exclusion.md` 状态为 Accepted；`FEATURES.md` #1114 引用 ADR-003。

---

## P0 已完成（4 项，存档参考）

| #     | 工作项                               | 完成证据                                                                                                       |
| ----- | ------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| P0-6  | taosx data retention lifecycle       | `/home/binance/internal/server/storage/taos_retention.go` 已实现 DeleteRange + archive proof 前置校验          |
| P0-7  | Config schema 字段名统一             | spec 层已完成 — 根 §11.1 `binance.product_lines` 默认 `["spot"]`；client/server §11 引用化对齐根 §11 canonical |
| P0-9  | ClickHouse ReplicatedMergeTree + TTL | dependency contract 层已闭环（`clickhousex` `457d9ff`）                                                        |
| P0-10 | ADR：order book rebuild 排除决策     | ADR-003 Accepted；FEATURES.md #1114 已同步排除口径                                                             |

---

## P1 强烈建议 — 不补全运营风险高（5 项未完成）

### P1-1：分布式 tracing (OpenTelemetry)

- **状态**：⚠️ 部分完成
- **对应**：FR-039 / PRG-005
- **当前**：`TraceContext` 已进入 wire request，server Kafka fanout 已传播 `traceparent`/`tracestate`/`baggage`；仍缺 OTel SDK span、NATS/header 端到端证据、slog trace_id 关联、采样配置和 no-traceparent fallback/direct TC
- **目标**：OTel SDK 埋点 + W3C traceparent header 传播 NATS/Kafka + slog trace_id 关联 + 采样率可配（默认 10%）
- **工作量**：L

### P1-2：资源配额/隔离

- **状态**：⚠️ 部分完成
- **对应**：FR-040 / PRG-004
- **当前**：server admin lifecycle、active catalog scope、Prometheus throttle/backpressure/stream/usage 指标与 P0/P1/P2 throttle anchors 已出现；仍缺 per-consumer-group Kafka 配额、多租户压力/故障隔离 evidence、per-caller API 限流与 ClickHouse 查询超时 direct TC
- **目标**：per-consumer-group Kafka 配额 + per-product-line WS 连接池隔离 + per-caller API 限流 + CH 查询超时 30s + 单线故障不拖垮其他线
- **工作量**：L

### P1-3：Audit log completeness

- **状态**：⚠️ 部分完成
- **对应**：FR-041 / PRG-006
- **当前**：`/home/binance/migrations/003_audit.sql` 已有 `audit_log`、append-only trigger 与 `REVOKE UPDATE, DELETE FROM PUBLIC`；仍缺 admin 写操作字段完整性/幂等性测试、数据生命周期审计保留与 OSS 归档证据、已部署 Postgres 权限验证
- **目标**：admin 写操作审计 + 数据生命周期审计 + append-only postgresx 审计表（`REVOKE UPDATE, DELETE`）+ ≥1 年保留 + OSS 归档
- **工作量**：M

### P1-4：真实外部 E2E

- **状态**：⚠️ 部分完成
- **对应**：Evidence-Done 推进
- **当前**：local gated 测试有（NATS JetStream + Redis mock + 文件 DLQ），真实 Kafka/Redis/TDengine/ClickHouse/OSS 端到端缺
- **目标**：分批推进 — 先 Redis + NATS（local gated 已部分验证），再 TDengine + Kafka，最后 ClickHouse + OSS
- **工作量**：L

### P1-5：UM/CM/Options 产品线 live 验证

- **状态**：❌ 未完成
- **对应**：FR-001 G7
- **当前**：runtime 仅装配 spot，um/cm/options 需 testnet 凭据验证
- **目标**：UM/CM/Options testnet 凭据 + mainnet live 验证（`BINANCE_MAINNET_LIVE` gate）
- **工作量**：M

### P1-6：ADR — FR-024 vs FR-036 架构路径裁决

- **状态**：✅ 已完成（2026-06-27）
- **对应**：MO-3 / ADR-004
- **完成内容**：ADR-004 已 Accepted；FR-036 裁决为自建增量 stream add/remove diff，不依赖 FR-024 升级；FR-024 保持 catalog reload + full reconnect/no-restart 边界。
- **验证**：`module/binance/design/ADR-004-fr024-vs-fr036-architecture.md` 状态为 Accepted；`SPEC.md` / `client/SPEC.md` / `FEATURES.md` 已同步 FR-024/FR-036 边界。

---

## P1 已完成（3 项，存档参考）

| #    | 工作项                            | 完成证据                                                                                                                                                                                                                                                                                              |
| ---- | --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| P1-6 | ✅ ADR：FR-024 vs FR-036 架构路径 | ADR-004 Accepted；FR-036 自建增量 diff，FR-024 保持 full reconnect/no-restart 边界                                                                                                                                                                                                                    |
| P1-7 | 双态模型补充 Code-Drifted 规则    | `spec/ACCEPTANCE.md` + `spec/FEATURES.md` + `matrix/TRACEABILITY.md` 已引入 Code-Drifted 第四态                                                                                                                                                                                                       |
| P1-8 | FR-013/017/025 状态复核           | 三个 FR 从 active Code-Drifted 调整为 Code-Partial，统计更新为 Code-State **23 Done / 25 Partial / 0 Drifted / 0 Pending**；Evidence-State **1 Done (FR-009) / 43 Pending**，Code-Pending 为无；FR-031~036、FR-038~044 保持 Code-Partial / Evidence-Pending；FR-037 为 Code-Done / Evidence-Pending。 |

---

## P2 可延后 — 有替代手段（5 项未完成）

### P2-1：Cost observability

- **状态**：❌ 未完成
- **对应**：FR-043
- **当前**：`internal/server/metrics/metrics.go` 已有 cost/usage/stream/rate-limit/gap Prometheus 指标 anchors；仍缺 dashboard、AlertManager 成本预算告警、usage report 与生产 evidence。
- **目标**：存储容量/带宽 per-product-line Prometheus 指标 + 成本告警（AlertManager）
- **替代**：可用外部监控暂替
- **工作量**：M

### P2-2：Data compliance & destruction

- **状态**：⚠️ 部分完成
- **对应**：FR-044
- **当前**：`docs/runbooks/data-lifecycle-destruction.md` 与 audit/data lifecycle 迁移 anchors 已出现；仍缺跨环境销毁演练、不可逆删除 proof、`certificate_of_destruction` 归档与合规审计 evidence。
- **目标**：`data_classification` 标注 + 合规保留期 + 不可逆销毁 + `certificate_of_destruction`
- **替代**：可用手动流程暂替
- **工作量**：M

### P2-3：FR-031~036 ExchangeInfo sync runtime 实现

- **状态**：⚠️ 部分完成（代码原语已出现，投影保持 Code-Partial / Evidence-Pending）
- **对应**：FR-031~036
- **当前**：exchangeInfo refresher/catalog reload/admin auth 等 runtime 原语已出现；FR-031~036 官方投影仍为 Code-Partial / Evidence-Pending，因为 Runtime-Anchor、direct TC、live/evidence 未闭合。
- **目标**：四产品线 exchangeInfo 发现 + 持久化 + 6h diff-only 刷新 + sync_tier 分级 + 白名单选择性同步 + admin auth + tier-aware 连接拓扑
- **工作量**：L

### P2-6：Backfill progress 持久化

- **状态**：⚠️ 部分完成
- **对应**：#1117
- **当前**：本地 file-store restart 与 fake Postgres state-store evidence 已归档；仍缺生产持久介质、真实重启归档与 live historical capture。
- **目标**：持久化到 postgresx（`catalog_exchange_info_snapshots` 表已规划），重启后恢复
- **工作量**：M

### P2-7：DLQ 持久化 wiring

- **状态**：⚠️ 部分完成
- **对应**：#1118
- **当前**：本地 DLQ `FileWriter`、JSONL reader、admin file-backed replay endpoint evidence 已归档；仍缺 Kafka/NATS/live replay 证据。
- **目标**：修改 `ingest.go` dispatch 的 dead letter 处理，加 FileWriter 作为持久 backend + replay 流程（读取 JSONL → 重新 Publish → 消费重处理）
- **工作量**：S

### P2-8：五处状态一致性 CI gate

- **状态**：✅ 已完成（2026-06-27）
- **对应**：MO-1
- **完成内容**：新增 `.github/ci/binance-status-consistency-check.sh` 并接入 `.github/workflows/docs-ci.yml`，校验 `README.md`、`FEATURES.md`、`ACCEPTANCE.md`、`TRACEABILITY.md`、`prompt/README.md` 的 FR Code 统计，并校验 Drifted FR 列表、TRACEABILITY §1 摘要与 §6 仪表盘一致。
- **验证**：`bash -n .github/ci/binance-status-consistency-check.sh` PASS；`bash .github/ci/binance-status-consistency-check.sh` PASS。

---

## P2 已完成（3 项，存档参考）

| #    | 工作项                 | 完成证据                                                                                                                                                                                           |
| ---- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| P2-4 | 退役文件物理隔离/精简  | 4 文件添加 DEPRECATED 横幅 + 精简（842→95 行）                                                                                                                                                     |
| P2-5 | Appendix D AC-BNC 迁移 | 迁移到 `docs/migrations/ac-bnc-legacy-mapping.md`，根 SPEC Appendix D 替换为指针                                                                                                                   |
| P2-8 | 五处状态一致性 CI gate | `.github/ci/binance-status-consistency-check.sh` + `.github/workflows/docs-ci.yml` 已覆盖 README/FEATURES/ACCEPTANCE/TRACEABILITY/prompt README Code 统计、Drifted FR 与 TRACEABILITY §1/§6 一致性 |

---

## 推进策略

### Phase 0：Spec-Runtime Drift 修复（本地已完成，证据待闭合）

本地代码对齐已完成；这 3 项原对应 IP 封禁、数据漏检、回填/实时争抢风险，direct TC/live evidence 未归档前仍不得升级为生产 Evidence-Done。

| 步骤 | 工作                                                                                                                         | Runtime 文件                                        |
| ---- | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| 0.1  | ✅ 对齐 FR-013：分钟滑动窗口 + 418/429 退避 + clock skew；direct TC/live evidence 待归档                                     | `internal/server/controlplane/reliability.go`       |
| 0.2  | ✅ 对齐 FR-017：按 event_type 分策略缺口检测；direct TC/live evidence 待归档                                                 | `internal/server/quality.go`                        |
| 0.3  | ✅ 对齐 FR-025：分钟 weight + P0/P1/P2 优先级；direct TC/live evidence 待归档                                                | `internal/client/throttle.go`                       |
| 0.4  | ✅ 状态复核：FR-013/017/025 从 active Code-Drifted 调整为 Code-Partial；Code-Done/Evidence-Done 依赖 direct TC/live evidence | `ACCEPTANCE.md` + `FEATURES.md` + `TRACEABILITY.md` |

### Phase 1：生产级门禁补全（本地代码项已完成，生产证据待闭合）

| 步骤 | 工作                                                        | 对应 PRG         |
| ---- | ----------------------------------------------------------- | ---------------- |
| 1.1  | ✅ schema version server 校验；兼容矩阵 evidence 待归档     | PRG-003 / FR-042 |
| 1.2  | ✅ feature flag 通用框架 + canary health gate 本地代码门禁  | PRG-003 / FR-037 |
| 1.3  | ✅ kafkax DLQ topic contract；持久化 replay evidence 待归档 | PRG-002          |
| 1.4  | ✅ ADR：order book rebuild 排除                             | MO-4 / ADR-003   |

### Phase 2：运维治理补全（P1-1/2/3/4/5，4-6 周）

| 步骤 | 工作                                                          | 对应 FR        |
| ---- | ------------------------------------------------------------- | -------------- |
| 2.1  | OTel SDK 埋点 + W3C traceparent direct TC                     | FR-039         |
| 2.2  | Kafka quotas + 多租户压力验证 + per-caller 限流 + CH 查询超时 | FR-040         |
| 2.3  | Admin 写操作 append-only 审计 evidence                        | FR-041         |
| 2.4  | 真实外部 E2E（Kafka → Redis → TDengine → ClickHouse → OSS）   | Evidence-Done  |
| 2.5  | UM/CM/Options testnet + mainnet live                          | FR-001 G7      |
| 2.6  | ✅ ADR：FR-024 vs FR-036 架构路径                             | MO-3 / ADR-004 |

### Phase 3：Evidence-Done 推进（持续，8-12 周）

1. 先补 FR-013/017/025 direct TC/live evidence 与 FR-037 生产 canary/rollback drill evidence，再按证据把 remaining Partial 推进到 Code-Done/Evidence-Done
2. 按 FR 依赖顺序推进：FR-001~009（核心链路）→ FR-006a-e（存储）→ FR-012~015（实时控制）→ 其余
3. 外部 E2E 分批：Redis + NATS → TDengine + Kafka → ClickHouse + OSS
4. 每关闭一个 Evidence-Done，同步更新 `spec/ACCEPTANCE.md` §4 + `matrix/TRACEABILITY.md`

### Phase 4：P2 可延后项（有替代手段时按需推进）

| 步骤 | 工作                                                            |
| ---- | --------------------------------------------------------------- |
| 4.1  | FR-031~036 ExchangeInfo sync Runtime-Anchor/direct TC 闭合      |
| 4.2  | Backfill progress 本地 env 接线 + restart evidence              |
| 4.3  | DLQ 持久化本地 env 接线 + file-backed replay                    |
| 4.4  | ✅ 五处状态一致性 CI gate                                       |
| 4.5  | Cost observability dashboard/alert evidence (FR-043)            |
| 4.6  | Data compliance destruction drill/certificate evidence (FR-044) |

---

## 关键约束

> [COMPUTED, HIGH] 本 TODO 清单中仍需 `/home/binance` runtime 或外部环境继续闭合的项包括 P1-1~P1-5、P2-1~P2-3、P2-6、P2-7 及相关 Evidence/PRG；其中 P1-1、P1-2、P1-3、P2-1、P2-2、P2-3、P2-6、P2-7 已从旧“未实现或未接线”口径修正为“runtime 代码原语与本地 env 接线已出现但验收证据未闭合”；FR-037 的本地代码门禁已闭合，但真实生产 canary / rollback drill 归档证据仍按 Evidence-Pending 治理。本次主仓同步已完成 P0-5、P0-10、P1-6、P2-8、prompt 状态投影、legacy mapping 与 agent team 再审计口径同步。
>
> [COMPUTED, HIGH] 2026-06-27 本轮同步已将 `prompt/README.md` 与模块规格/验收/矩阵文档统一到 Code-State **23 Done / 25 Partial / 0 Drifted / 0 Pending**、Evidence-State **1 Done (FR-009) / 43 Pending**；FR-013/017/025 后续按 direct TC/live/evidence closure 推进，不再按 unresolved runtime migration 表述。
>
> [COMPUTED, HIGH] 本地 P0 代码门禁完成不等于生产级可发布；必须补齐 production canary / rollback drill、direct TC、live/evidence、外部 E2E/CI/dashboard/credential/multi-tenant/destruction 等证据后，才可声明"生产级可发布"。P1 项完成后才可声明"生产级可运营"。P2 项可延后但有替代手段时不应无限期搁置。
>
> [COMPUTED, HIGH] 每完成一项，更新本文件状态列（❌/⚠️/✅/⛔）+ `spec/FEATURES.md` 实现投影 + `spec/SPEC.md` 边界说明 + `spec/ACCEPTANCE.md` §4 + `matrix/TRACEABILITY.md` + `README.md` + `prompt/README.md` + `CHANGELOG.md`；涉及 spec 边界时同步 `spec/SPEC.md`。
