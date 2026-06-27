# module/binance TODO — 生产级可发布差距清单

- **创建日期**：2026-06-27
- **来源**：[`report/binance/spec-structural-analysis-20260627.md`](../../report/binance/spec-structural-analysis-20260627.md) 生产级可发布差距分析
- **Spec-Version**：v3.9.0
- **Runtime-Anchor**：`/home/binance@f046e16`
- **当前状态**：v0.2.0 可编译可发布，但**不可生产运营**；Code-State **22 Done / 26 Partial / 0 Drifted / 0 Pending**；Evidence-State **1 Done (FR-009) / 43 Pending**；7 PRG Evidence-Pending / Code-Partial anchors；FR-031~044 为 Code-Partial / Evidence-Pending。

> [COMPUTED, HIGH] 本文件是 spec 层结构性修复（MA-1~MA-4 + MO-2，已完成）之后的**剩余未完成项**清单。完成状态基于 2026-06-27 对 spec 文件和 `/home/binance` runtime 代码的交叉验证；P0-10、P1-6、P2-8 以及 legacy mapping 等文档可验证状态已同步为完成，runtime/外部环境项仍保留为未完成或阻塞。

---

## 总览

| 优先级      |  总数  | 已完成 | 未完成 | 完成率  |
| ----------- | :----: | :----: | :----: | :-----: |
| P0 阻塞     |   10   |   9    |   1    |   90%   |
| P1 强烈建议 |   8    |   3    |   5    |   38%   |
| P2 可延后   |   8    |   3    |   5    |   38%   |
| **合计**    | **26** | **15** | **11** | **58%** |

---

## P0 阻塞 — 不补全不可上线（1 项未完成）

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

- **状态**：⚠️ 部分完成
- **对应**：FR-037 / PRG-003
- **Runtime 位置**：`/home/binance/docs/runbooks/plan008-deploy-health-rollback.md`（runbook 有）+ `FOUNDATIONX_BINANCE_FEATURE_ASYNC_COLD_RANGE` flag（1 个 flag）
- **当前**：有 deploy runbook + 1 个 feature flag，但无代码级 canary health gate + 无自动回滚机制
- **目标**：feature flag 机制（`XGO_BINANCE_FEATURE_{name}` 通用框架）+ canary 部署健康门禁（`/readyz`/error-rate gate）+ 自动回滚 runbook
- **风险**：上线即全量，出问题影响全部用户
- **工作量**：L

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

| #    | 工作项                               | 完成证据                                                                                                       |
| ---- | ------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| P0-6 | taosx data retention lifecycle       | `/home/binance/internal/server/storage/taos_retention.go` 已实现 DeleteRange + archive proof 前置校验          |
| P0-7 | Config schema 字段名统一             | spec 层已完成 — 根 §11.1 `binance.product_lines` 默认 `["spot"]`；client/server §11 引用化对齐根 §11 canonical |
| P0-9 | ClickHouse ReplicatedMergeTree + TTL | dependency contract 层已闭环（`clickhousex` `457d9ff`）                                                        |
| P0-10 | ADR：order book rebuild 排除决策    | ADR-003 Accepted；FEATURES.md #1114 已同步排除口径                                                             |

---

## P1 强烈建议 — 不补全运营风险高（5 项未完成）

### P1-1：分布式 tracing (OpenTelemetry)

- **状态**：⚠️ 部分完成
- **对应**：FR-039 / PRG-005
- **当前**：`kafka_dispatch_test.go` 有 `TraceContext.TraceParent` 字段定义，但无 OTel SDK 埋点 + 无 W3C traceparent 跨 NATS/Kafka 传播 + 无 slog trace_id 关联
- **目标**：OTel SDK 埋点 + W3C traceparent header 传播 NATS/Kafka + slog trace_id 关联 + 采样率可配（默认 10%）
- **工作量**：L

### P1-2：资源配额/隔离

- **状态**：⚠️ 部分完成
- **对应**：FR-040 / PRG-004
- **当前**：`lifecycle.go` 有部分 isolation，但无 per-line WS 连接池隔离 + 无 per-caller API 限流 + 无 ClickHouse 查询超时
- **目标**：per-consumer-group Kafka 配额 + per-product-line WS 连接池隔离 + per-caller API 限流 + CH 查询超时 30s + 单线故障不拖垮其他线
- **工作量**：L

### P1-3：Audit log completeness

- **状态**：❌ 未完成
- **对应**：FR-041 / PRG-006
- **当前**：无 append-only 审计表 + 无 `REVOKE UPDATE, DELETE`
- **目标**：admin 写操作审计 + 数据生命周期审计 + append-only postgresx 审计表（`REVOKE UPDATE, DELETE`）+ ≥1 年保留 + OSS 归档
- **工作量**：M

### P1-4：真实外部 E2E

- **状态**：❌ 未完成
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

| #    | 工作项                         | 完成证据                                                                 |
| ---- | ------------------------------ | ------------------------------------------------------------------------ |
| P1-6 | ADR：FR-024 vs FR-036 架构路径 | ADR-004 Accepted；FR-036 自建增量 diff，FR-024 保持 full reconnect/no-restart 边界 |
| P1-7 | 双态模型补充 Code-Drifted 规则 | ACCEPTANCE.md + FEATURES.md + TRACEABILITY.md 已引入 Code-Drifted 第四态 |
| P1-8 | FR-013/017/025 状态复核        | 三个 FR 从 active Code-Drifted 调整为 Code-Partial，统计更新为 Code-State **22/26/0/0**；Evidence-State **1 Done (FR-009) / 43 Pending**，Code-Pending 为无；FR-031~044 已改为 Code-Partial / Evidence-Pending。

---

## P2 可延后 — 有替代手段（5 项未完成）

### P2-1：Cost observability

- **状态**：❌ 未完成
- **对应**：FR-043
- **当前**：已有本地 anchors，未闭合生产 evidence
- **目标**：存储容量/带宽 per-product-line Prometheus 指标 + 成本告警（AlertManager）
- **替代**：可用外部监控暂替
- **工作量**：M

### P2-2：Data compliance & destruction

- **状态**：❌ 未完成
- **对应**：FR-044
- **当前**：已有本地 anchors，未闭合生产 evidence
- **目标**：`data_classification` 标注 + 合规保留期 + 不可逆销毁 + `certificate_of_destruction`
- **替代**：可用手动流程暂替
- **工作量**：M

### P2-3：FR-031~036 ExchangeInfo sync runtime 实现

- **状态**：❌ 未完成
- **对应**：FR-031~036
- **当前**：Code-Partial / Evidence-Pending（已有本地 anchors，未闭合四线/live/TC）
- **目标**：四产品线 exchangeInfo 发现 + 持久化 + 6h diff-only 刷新 + sync_tier 分级 + 白名单选择性同步 + admin auth + tier-aware 连接拓扑
- **工作量**：L

### P2-6：Backfill progress 持久化

- **状态**：❌ 未完成
- **对应**：#1117
- **当前**：`HistoryRuntime.jobs` map in-memory，重启后丢失
- **目标**：持久化到 postgresx（`catalog_exchange_info_snapshots` 表已规划），重启后恢复
- **工作量**：M

### P2-7：DLQ 持久化 wiring

- **状态**：❌ 未完成
- **对应**：#1118
- **当前**：`deadletter.FileWriter` 代码就绪 + 测试 PASS，但未接线到生产 dispatch 路径（当前用 in-memory DLQ）
- **目标**：修改 `ingest.go` dispatch 的 dead letter 处理，加 FileWriter 作为持久 backend + replay 流程（读取 JSONL → 重新 Publish → 消费重处理）
- **工作量**：S

### P2-8：五处状态一致性 CI gate

- **状态**：✅ 已完成（2026-06-27）
- **对应**：MO-1
- **完成内容**：新增 `.github/ci/binance-status-consistency-check.sh` 并接入 `.github/workflows/docs-ci.yml`，校验 `README.md`、`FEATURES.md`、`ACCEPTANCE.md`、`TRACEABILITY.md`、`prompt/README.md` 的 FR Code 统计，并校验 Drifted FR 列表、TRACEABILITY §1 摘要与 §6 仪表盘一致。
- **验证**：`bash -n .github/ci/binance-status-consistency-check.sh` PASS；`bash .github/ci/binance-status-consistency-check.sh` PASS。

---

## P2 已完成（3 项，存档参考）

| #    | 工作项                      | 完成证据                                                                                                                                                                    |
| ---- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| P2-4 | 退役文件物理隔离/精简       | 4 文件添加 DEPRECATED 横幅 + 精简（842→95 行）                                                                                                                             |
| P2-5 | Appendix D AC-BNC 迁移      | 迁移到 `docs/migrations/ac-bnc-legacy-mapping.md`，根 SPEC Appendix D 替换为指针                                                                                           |
| P2-8 | 五处状态一致性 CI gate | `.github/ci/binance-status-consistency-check.sh` + `.github/workflows/docs-ci.yml` 已覆盖 README/FEATURES/ACCEPTANCE/TRACEABILITY/prompt README Code 统计、Drifted FR 与 TRACEABILITY §1/§6 一致性 |

---

## 推进策略

### Phase 0：Spec-Runtime Drift 修复（P0-1/2/3，2 周）

最紧迫 — 这 3 项直接对应 IP 封禁、数据漏检、回填/实时争抢风险。

| 步骤 | 工作                                                      | Runtime 文件                                        |
| ---- | --------------------------------------------------------- | --------------------------------------------------- |
| 0.1  | 对齐 FR-013：分钟滑动窗口 + 418/429 退避 + clock skew     | `reliability.go`                                    |
| 0.2  | 对齐 FR-017：按 event_type 分策略缺口检测                 | `server.go` + `quality.go`                          |
| 0.3  | 对齐 FR-025：分钟 weight + P0/P1/P2 优先级                | `throttle.go`                                       |
| 0.4  | 状态复核：FR-013/017/025 从 active Code-Drifted 调整为 Code-Partial；Code-Done/Evidence-Done 依赖 direct TC/live evidence | `ACCEPTANCE.md` + `FEATURES.md` + `TRACEABILITY.md` |

### Phase 1：生产级门禁补全（剩余 P0-5，3-4 周）

| 步骤 | 工作                                        | 对应 PRG         |
| ---- | ------------------------------------------- | ---------------- |
| 1.1  | schema version server 校验 + 兼容矩阵       | PRG-003 / FR-042 |
| 1.2  | feature flag 通用框架 + canary health gate  | PRG-003 / FR-037 |
| 1.3  | kafkax DLQ topic contract + replay endpoint | PRG-002          |
| 1.4  | ✅ ADR：order book rebuild 排除             | MO-4 / ADR-003  |

### Phase 2：运维治理补全（P1-1/2/3/4/5，4-6 周）

| 步骤 | 工作                                                        | 对应 FR       |
| ---- | ----------------------------------------------------------- | ------------- |
| 2.1  | OTel SDK 埋点 + W3C traceparent                             | FR-039        |
| 2.2  | per-line WS 连接池隔离 + per-caller 限流 + CH 超时          | FR-040        |
| 2.3  | Admin 写操作 append-only 审计                               | FR-041        |
| 2.4  | 真实外部 E2E（Kafka → Redis → TDengine → ClickHouse → OSS） | Evidence-Done |
| 2.5  | UM/CM/Options testnet + mainnet live                        | FR-001 G7     |
| 2.6  | ✅ ADR：FR-024 vs FR-036 架构路径                           | MO-3 / ADR-004 |

### Phase 3：Evidence-Done 推进（持续，8-12 周）

1. 先补 FR-013/017/025 direct TC/live evidence，再按证据把 Code-Partial 推进到 Code-Done/Evidence-Done
2. 按 FR 依赖顺序推进：FR-001~009（核心链路）→ FR-006a-e（存储）→ FR-012~015（实时控制）→ 其余
3. 外部 E2E 分批：Redis + NATS → TDengine + Kafka → ClickHouse + OSS
4. 每关闭一个 Evidence-Done，同步更新 ACCEPTANCE.md §4 + TRACEABILITY.md

### Phase 4：P2 可延后项（有替代手段时按需推进）

| 步骤 | 工作                                   |
| ---- | -------------------------------------- |
| 4.1  | FR-031~036 ExchangeInfo sync runtime   |
| 4.2  | Backfill progress 持久化               |
| 4.3  | DLQ 持久化 wiring + replay             |
| 4.4  | ✅ 五处状态一致性 CI gate             |
| 4.5  | Cost observability (FR-043)            |
| 4.6  | Data compliance & destruction (FR-044) |

---

## 关键约束

> [KNOWN, HIGH] 本 TODO 清单中仍需 `/home/binance` runtime 或外部环境的项包括 P0-5、P1-1~P1-5、P2-1~P2-3、P2-6、P2-7 及相关 Evidence/PRG 闭合；本次主仓文档同步已完成 P0-10、P1-6、P2-8、prompt 状态投影和 legacy mapping。剩余未完成项集中在 runtime/外部环境/Evidence/PRG。
>
> [COMPUTED, HIGH] 所有 P0 项完成后才可声明"生产级可发布"。P1 项完成后才可声明"生产级可运营"。P2 项可延后但有替代手段时不应无限期搁置。
>
> [COMPUTED, HIGH] 每完成一项，更新本文件状态列（❌/⚠️/✅/⛔）+ FEATURES.md 实现投影 + SPEC.md 边界说明 + ACCEPTANCE.md §4 + TRACEABILITY.md + README.md + prompt/README.md + CHANGELOG.md；涉及 spec 边界时同步 SPEC.md。
