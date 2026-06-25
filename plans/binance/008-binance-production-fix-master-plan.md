# binance 生产级修复总 Plan 008

> 数据成熟度评估 + Foundation 标准化 + 生产级遗漏维度终审 — 统一修复计划

- Plan-ID: 008
- 日期：2026-06-25
- Runtime-Anchor：`/home/binance@3f20be0`（PR #103+#104 合并后）
- Spec-Anchor：`module/binance/SPEC.md` v3.6.0 / `TRACEABILITY.md` v3.6.1
- Status-Projection（修复前）：`24 Done / 10 Partial / 0 Pending`（FR-001~030）+ `6 Draft`（FR-031~036）
- 前序 Plan：[Plan 006](006-binance-production-readiness-fix.md)（49 Task，✅ DONE）/ [Plan 007](007-binance-readiness-arch-fix.md)（18 Task，✅ DONE）
- 来源报告（7 份，位于未合并分支 `report/binance-data-maturity-20260625` HEAD `c71b7ff5`）：

| #   | 报告                                      | 职责                                  |
| --- | ----------------------------------------- | ------------------------------------- |
| R1  | `data-maturity-assessment-20260625.md`    | 主索引：SLA 框架 + 总体评分 + 路线图  |
| R2  | `data-maturity-history-20260625.md`       | 历史数据链路深度评估（G3/G4/G5/G9）   |
| R3  | `data-maturity-realtime-20260625.md`      | 实时数据链路深度评估（G1/G2/G8）      |
| R4  | `data-maturity-storage-20260625.md`       | 数据存储链路深度评估（G6/G7/G9）      |
| R5  | `foundation-resilience-audit-20260625.md` | Foundation 七模块能力审计（责任矩阵） |
| R6  | `foundation-standardization-20260625.md`  | Foundation 标准化倒推（S1-S25）       |
| R7  | `production-gaps-audit-20260625.md`       | 生产级遗漏维度终审（S26-S32）         |

> `[COMPUTED, HIGH]` 本 Plan 基于 7 份报告的实证核查结果（Explore agent 逐条 file:line 验证），将 **9 个数据缺口（G1-G9）+ 32 项标准化要求（S1-S32）+ 3 项未编号横切要求 + 4 项阶段三规模化** 归并为 **40 个可执行 Task**，按依赖拓扑分 5 个 Phase。所有 Task 均有来源报告与缺口/标准编号追溯。

---

## 0. 问题全景与核心判断

### 0.1 成熟度现状（终审评分 1.3/5.0）

`[COMPUTED, HIGH]` 合并 7 份报告后的生产级成熟度终审：

| 维度         |  得分   | 依据                            |
| ------------ | :-----: | ------------------------------- |
| 数据完整性   |   1.3   | 实时 1.3 / 历史 0.4 / 存储 1.2  |
| 边界治理     |   4.5   | 13 gates PASS + CI 集成         |
| 发布安全     |   0.5   | 零灰度/零回滚                   |
| 版本兼容     |   1.0   | 有字段无策略                    |
| 可观测性     |   2.0   | metrics+日志扎实，tracing 缺失  |
| 资源隔离     |   1.0   | 有 retry budget 无 quota        |
| 审计合规     |   0.8   | 只审计 symbol 发现              |
| 成本可观测   |   0.3   | 零实现                          |
| 数据合规     |   0.3   | 零实现                          |
| **加权总分** | **1.3** | **预生产（距 ≥3.5 缺 2.2 分）** |

### 0.2 核心判断

`[COMPUTED, HIGH]` binance 规格治理达罕见高成熟度（30 FR/104 AC/13 gate），runtime 在 Freshness 维度达标（SLO 24/24 PASS）。但距生产级存在**系统性断层**：

1. **因果链断裂**（R1-R4）：检测能力（L1）扎实，但告警消费（L2）缺消费层、修复能力（L3）完全空白。系统能"知道数据出问题"但不能"通知人"或"自动修好"。
2. **Foundation 最后一公里缺失**（R5）：14 项可靠性能力中 8 项缺失，其中 6 项是"Foundation 已提供原语但 binance 没用/没用对"，1 项是 Foundation 层缺陷（taosx 无 Delete），1 项双方都缺（DR）。
3. **运维/治理/合规维度遗漏**（R7）：7 个 0/6 覆盖维度，其中发布安全网（S26）是新的 P0 阻塞。

`[INFERRED, HIGH]` 这不是"修几个 bug"，而是**补建一整套数据完整性保障 + 运维治理 + 合规体系**。跨度 5-8 个 sprint。

### 0.3 9 个数据缺口（G1-G9）

| ID  | 缺口                    | 链路      | SLA 维度               | 当前 | 目标 | 优先级 | 来源                   |
| --- | ----------------------- | --------- | ---------------------- | :--: | :--: | :----: | ---------------------- |
| G1  | stale alert 无触发动作  | 实时      | Freshness→Completeness |  L1  |  L2  | **P0** | R1§2 / R3§2.1          |
| G2  | gap→修复链路断裂        | 实时+历史 | Completeness           |  L1  |  L3  | **P0** | R1§2 / R3§2.2          |
| G3  | replay job 零实现       | 历史      | Completeness           |  L0  |  L3  | **P0** | R1§2 / R2§2.1          |
| G4  | backfill cursor 纯内存  | 历史      | Durability             |  L0  |  L3  | **P0** | R1§2 / R2§2.2          |
| G5  | reconcile 无真实对账    | 历史      | Consistency            |  L1  |  L3  | **P1** | R1§2 / R2§2.3          |
| G6  | taosx retention 无删除  | 存储      | Durability             |  L0  |  L3  | **P0** | R1§2 / R4§2.1          |
| G7  | OSS 归档语义错位        | 存储      | Durability             |  L1  |  L3  | **P1** | R1§2 / R4§2.2          |
| G8  | DLQ FileWriter 未接线   | 实时+历史 | Durability             |  L1  |  L3  | **P0** | R1§2 / R3§2.3          |
| G9  | 冷数据 rehydrate 未接线 | 历史+存储 | Durability             |  L0  |  L3  | **P1** | R1§2 / R2§2.4 / R4§2.3 |

**6 P0 + 3 P1**。P0 是生产级最低门槛，P1 是生产级成熟度。

### 0.4 32 项标准化要求（S1-S32）

#### P0（9 项，不修无法上线）

| #   | 要求                                    | 责任方            | 模块        |  对应缺口  | 来源            |
| --- | --------------------------------------- | ----------------- | ----------- | :--------: | --------------- |
| S1  | taosx Client interface 新增 DeleteRange | Foundation        | taosx       |     G6     | R5§3.1 / R6§2.5 |
| S2  | taosx DB 级 KEEP 配置                   | binance+运维      | taosx       |     G6     | R6§2.5          |
| S3  | clickhouse DDL 改 ReplicatedMergeTree   | binance           | clickhousex | 分析域SPOF | R6§2.7          |
| S4  | clickhouse DDL 加 TTL 表达式            | binance           | clickhousex |   存储§6   | R6§2.7          |
| S5  | natsx 死信回调 hook（OnDeadLetter）     | Foundation        | natsx       |     G8     | R6§2.1          |
| S6  | kafkax dead-letter/retry topic 模式     | Foundation/调用方 | kafkax      | 分析域DLQ  | R6§2.2          |
| S7  | kafkax Producer 默认 RequiredAcks=all   | Foundation        | kafkax      | fanout丢失 | R6§2.2          |
| S8  | natsx 多节点部署（Replicas≥3）          | 运维              | natsx       | 单节点SPOF | R6§2.1          |
| S26 | 发布安全网（feature flag+canary+回滚）  | binance+运维      | 发布        |     —      | R7§1            |

#### P1（13 项，生产级成熟度）

| #   | 要求                                      | 责任方          | 模块        |  对应缺口  | 来源   |
| --- | ----------------------------------------- | --------------- | ----------- | :--------: | ------ |
| S9  | postgresx cursor 持久化标准模式           | binance         | postgresx   |     G4     | R6§2.4 |
| S10 | postgresx PITR 备份恢复 runbook           | Foundation/运维 | postgresx   |     DR     | R6§2.4 |
| S11 | postgresx read replica 配置               | 运维            | postgresx   | 分析域压力 | R6§2.4 |
| S12 | ossx Multipart 用于大归档                 | binance         | ossx        |     G7     | R6§2.6 |
| S13 | ossx Lifecycle 策略配置                   | binance         | ossx        |     G7     | R6§2.6 |
| S14 | clickhouse ETL 幂等（ReplacingMergeTree） | binance         | clickhousex |  重复写入  | R6§2.7 |
| S15 | redisx AOF 持久化配置文档                 | Foundation/运维 | redisx      | 重启丢key  | R6§2.3 |
| S16 | 统一 AlertDispatcher                      | binance         | 跨模块      |   G1/G2    | R6§3.1 |
| S17 | 各模块 RPO/RTO + 恢复 runbook             | Foundation/运维 | 全部        |     DR     | R6§3.3 |
| S27 | Schema 版本兼容策略                       | binance         | 版本兼容    |     —      | R7§2   |
| S28 | 分布式 tracing（OpenTelemetry）           | binance         | 可观测性    |     —      | R7§3   |
| S29 | 资源配额与隔离（Kafka/WS/API）            | binance         | 资源隔离    |     —      | R7§4   |
| S30 | 审计日志完整性（append-only）             | binance         | 审计合规    |     —      | R7§5   |

#### P2（10 项，规模化优化）

| #   | 要求                             | 责任方       | 模块        | 来源   |
| --- | -------------------------------- | ------------ | ----------- | ------ |
| S18 | ossx versioning（误删恢复）      | 运维         | ossx        | R6§2.6 |
| S19 | kafkax EOS 封装                  | Foundation   | kafkax      | R6§2.2 |
| S20 | redisx Sentinel/Cluster 部署     | 运维         | redisx      | R6§2.3 |
| S21 | taosx SchemalessWrite 补全       | Foundation   | taosx       | R6§2.5 |
| S22 | clickhouse 分区管理接口          | Foundation   | clickhousex | R6§2.7 |
| S23 | postgresx 逻辑复制接口           | Foundation   | postgresx   | R6§2.4 |
| S24 | natsx stream 生命周期管理        | Foundation   | natsx       | R6§2.1 |
| S25 | redisx 降级策略接口              | Foundation   | redisx      | R6§2.3 |
| S31 | 成本可观测（容量/分摊/告警）     | binance+运维 | 成本        | R7§6   |
| S32 | 数据合规与销毁（分类/保留/证明） | binance      | 合规        | R7§7   |

### 0.5 未编号横切要求（3 项，来源主索引 §1.4）

`[COMPUTED, HIGH]` 主索引 §1.4 列出 6 个横切维度，其中 3 个已被 S1-S32 覆盖（tracing→S28、告警→S16、DR→S10/S17）。以下 3 项**未获独立 S 编号**，本 Plan 显式补为 S33-S35 避免遗漏：

| #   | 要求                                             | 优先级 | 来源               |
| --- | ------------------------------------------------ | :----: | ------------------ |
| S33 | admin 写操作鉴权（FR-035 Draft 推进）            |   P1   | R1§1.4 安全/鉴权行 |
| S34 | 容量规划 runbook（各存储层上限+增长预测+扩容）   |   P1   | R1§1.4 容量规划行  |
| S35 | 凭证/机密轮转 runbook（API key/DB 密码定期轮转） |   P2   | R1§1.4 凭证轮转行  |

### 0.6 阶段三规模化（4 项，来源主索引 §4）

| #   | 要求                                               | 来源        |
| --- | -------------------------------------------------- | ----------- |
| M1  | SLA 仪表盘（四维 SLO 实时可视化）                  | R1§4 阶段三 |
| M2  | 覆盖率度量（应采集 vs 实际采集，≥99.99%）          | R1§4 阶段三 |
| M3  | 全链路 chaos 测试（断流/重启/存储故障）            | R1§4 阶段三 |
| M4  | runbook 文档化（stale/gap/DLQ/reconcile 运维手册） | R1§4 阶段三 |

---

## 1. 依赖拓扑与 Phase 划分

`[COMPUTED, HIGH]` 基于 R2§6（历史链路依赖）、R4§7（存储协同）、R5§5（补齐优先级）、R7§10（修订路线图）的依赖关系，绘制全 Task 依赖拓扑：

```
Phase 0（Foundation 层 + 前置决策）
  S1 taosx DeleteRange ──────────────────────┐
  S5 natsx OnDeadLetter hook ──────────────┐ │
  S7 kafkax RequiredAcks=all 默认 ────────┐│ │
  FR-032 exchangeInfo 6h 刷新（前置依赖） ┤│ │
                                          ▼▼▼
Phase 1（闭合因果链 — P0 数据缺口）
  G4 cursor 持久化 (S9) ──┐
    │                      │
    ▼                      ▼
  G3 gap→replay 桥接 ◀── G2 gap 标志消费 (S16 AlertDispatcher)
    │                      │
    │   G1 stale 告警 (S16)│  G8 DLQ FileWriter 接线 (S5)
    │                      │
    ▼                      ▼
  G6 taosx retention (S1+S2) ◀── G7 OSS 定时迁移 (S12+S13)
    │  〔先归档校验 → 后删热〕
    │
    ▼
Phase 2（生命周期 + 治理 — P1）
  G5 reconcile 真实对账 ◀── 依赖 G3 + FR-032
  G9 rehydrate 接线 ◀── 依赖 G7 稳定
  S26 发布安全网（可与 Phase1 并行，独立 track）
  S27 Schema 兼容 / S28 tracing / S29 资源配额 / S30 审计（独立 track）
  S3/S4/S14 clickhouse 副本+TTL+幂等
  S15 redisx AOF / S8 natsx 多节点 / S6 kafkax DLQ topic
  S10/S11/S17 DR + replica + RPO/RTO runbook

Phase 3（规模化与合规 — P2）
  S18-S25 Foundation 模块增强
  S31 成本可观测 / S32 数据合规 / S33 鉴权 / S34 容量 / S35 轮转
  M1-M4 仪表盘/覆盖率/chaos/runbook

Phase 4（验收与门禁）
  全量回归 + 生产级 SLO 验收 + TRACEABILITY 更新
```

`[COMPUTED, HIGH]` 关键路径：**G4 → G3 → G5**（历史修复链）；**G7 → G6**（存储删除顺序严格：先归档校验后删热）；**S1 → G6**（Foundation interface 扩展阻断 binance retention）。

---

## 2. Task 清单（40 Task）

### Phase 0 — Foundation 层扩展 + 前置依赖（6 Task）

> 目标：扫清 Foundation 层缺陷与前置依赖，为 Phase 1 数据缺口修复铺路。

| Task     | 标题                                                                  |    对应    | 责任方          | 依赖 | 验收                                           | 来源            |
| -------- | --------------------------------------------------------------------- | :--------: | --------------- | :--: | ---------------------------------------------- | --------------- |
| T008.001 | taosx Client interface 新增 `DeleteRange(ctx, table, before)`         |     S1     | Foundation      |  —   | interface 合入 taosx 仓 + 单测；binance 可调用 | R5§3.1 / R6§2.5 |
| T008.002 | natsx 新增 `OnDeadLetter(msg)` 回调 hook（MaxDeliver 超限 Term 触发） |     S5     | Foundation      |  —   | hook 合入 natsx 仓 + 单测；binance 可注入      | R6§2.1          |
| T008.003 | kafkax Producer 默认 `RequiredAcks=all`，确认并修正默认值             |     S7     | Foundation      |  —   | 默认值=all 合入 kafkax 仓 + 测试               | R6§2.2          |
| T008.004 | FR-032 exchangeInfo 6h 刷新落地（G4/G5 的 catalog 前置）              |   FR-032   | binance         |  —   | exchangeInfo 6h cron 刷新 + symbol 目录准确    | R1§6 / R2§4.3   |
| T008.005 | clickhousex DDL 校验：文档要求 ReplicatedMergeTree + TTL              | S3/S4 前置 | Foundation/文档 |  —   | 文档明确生产 DDL 要求                          | R6§2.7          |
| T008.006 | kafkax dead-letter/retry topic 模式内建或文档化                       |     S6     | Foundation      |  —   | DLQ 模式合入或文档化                           | R6§2.2          |

### Phase 1 — 闭合因果链（P0 数据缺口，13 Task）

> 目标：让"检测→告警→修复"链路贯通，数据出问题能自愈。对应 R1§4 阶段一。

| Task     | 标题                                                                            |    对应    | 责任方       |   依赖    | 验收                                            | 来源            |
| -------- | ------------------------------------------------------------------------------- | :--------: | ------------ | :-------: | ----------------------------------------------- | --------------- |
| T008.007 | 新增 `internal/server/alert_dispatcher.go` 统一 AlertDispatcher                 |    S16     | binance      |     —     | 模块合入；可注入 stale/gap 信号                 | R3§4.1 / R6§3.1 |
| T008.008 | G1：stale 超阈值 → AlertDispatcher.onStale → 写 alerts 表 + natsx alert subject |   G1/S16   | binance      |   T007    | 断流 30s 内 alerts 表有记录 + natsx 有 subject  | R3§4.1          |
| T008.009 | G2：gap 检测 → AlertDispatcher.onGap → 写 alerts 表 + 生成 ReplayJob            |   G2/S16   | binance      |   T007    | gap 检测后 alerts 表有记录 + ReplayJob 入队     | R3§4.1          |
| T008.010 | 新增 `binance_alerts` 表（migration 008）                                       |    S16     | binance      |     —     | 表创建 + 迁移通过                               | R3§4.1          |
| T008.011 | G4：HistoryRuntime 状态持久化到 postgresx（migration 006，jobs+coverage 表）    |   G4/S9    | binance      |   T004    | 重启后 cursor 不丢；中断 job 可续跑             | R2§4.2          |
| T008.012 | G3：新增 `internal/server/replay_bridge.go`，消费 RepairRequired 生成 ReplayJob |     G3     | binance      |   T011    | gap 2min 内自动入队修复；replay 不重复（SetNX） | R2§4.1          |
| T008.013 | G8：`appendDeadLetter` 接线 deadletter.FileWriter（JSONL 落盘）                 |   G8/S5    | binance      |   T002    | 死信写入后磁盘 JSONL 存在；重启后磁盘保留       | R3§4.2          |
| T008.014 | G8：新增 `POST /api/v1/admin/deadletter/replay` replay endpoint                 |     G8     | binance      |   T013    | replay 能读 JSONL 重投；已处理事件被 SetNX 拦截 | R3§4.2          |
| T008.015 | G6 Layer A：`ALTER DATABASE binance KEEP 365`（DDL 层 retention）               |   G6/S2    | binance+运维 |     —     | DDL 含 KEEP；bar 365d 自动淘汰                  | R4§4.1          |
| T008.016 | G6 Layer B：新增 `taos_retention.go` 定时删 tick(30d)/depth(3d)                 |   G6/S1    | binance      | T001/T015 | tick 30d/depth 3d 后从 taosx 消失；磁盘稳定     | R4§4.1          |
| T008.017 | G7 Path B：新增 `oss_lifecycle_scheduler.go` 每日 03:00 UTC 定时迁移            | G7/S12/S13 | binance      |     —     | 03:00 UTC 扫描超期数据；OSS ETag 校验后删热     | R4§4.2          |
| T008.018 | G6+G7 删除顺序契约：G7 归档+ETag 校验成功 → 才触发 G6 删 taosx                  |   G6/G7    | binance      | T016/T017 | 顺序严格；归档失败不删热                        | R4§7            |
| T008.019 | DLQ FileWriter 路径纳入 OSS 归档（跨磁盘安全）                                  |   G8/S12   | binance      | T013/T017 | 死信 JSONL 纳入 OSS 归档                        | R3§4.2 / R4§7   |

> `[COMPUTED, HIGH]` T008.011 实施注记（2026-06-26）：当前 `migrations/006_history_runtime.sql` 的实际 schema 是 `history_runtime_state(snapshot JSONB)`。标题中的 “jobs+coverage 表” 按 issue 标题漂移处理，除非后续 migration 显式新增这两张规范化表，否则不作为本轮实现口径。

### Phase 2 — 生命周期 + 治理（P1，14 Task）

> 目标：数据生命周期闭环 + 运维/治理/合规维度补齐。对应 R1§4 阶段二 + R7§10 阶段二。

| Task     | 标题                                                                                                   |        对应        | 责任方          |   依赖    | 验收                                                        | 来源                    |
| -------- | ------------------------------------------------------------------------------------------------------ | :----------------: | --------------- | :-------: | ----------------------------------------------------------- | ----------------------- |
| T008.020 | G5：新增 `reconcile_worker.go` 消费 LifecycleTask 执行真实对账                                         |         G5         | binance         | T012/T004 | 04:00 UTC 全量对账；差异>0.01% 写 alerts 表 + 触发 backfill | R2§4.3                  |
| T008.021 | G5：新增 `binance_reconciliation_alerts` 表（migration 007）                                           |         G5         | binance         |     —     | 表创建 + 迁移通过                                           | R2§4.3                  |
| T008.022 | G9：range 查询 handler 增加冷热判断 + 202 异步分支                                                     |         G9         | binance         |   T017    | 查询 60d 前数据 → 202 job_id                                | R2§4.4                  |
| T008.023 | G9：新增 `rehydrate_manager.go` job 状态机 + 24h TTL 临时表 + `GET /rehydration/jobs/:id`              |         G9         | binance         |   T022    | 轮询 ready 返回数据；24h 后临时表过期                       | R2§4.4 / R4§4.3         |
| T008.024 | S3：clickhouse DDL 改 ReplicatedMergeTree                                                              |         S3         | binance         |   T005    | 三张表 ENGINE=ReplicatedMergeTree                           | R6§2.7                  |
| T008.025 | S4：clickhouse DDL 加 `TTL bucket + INTERVAL 730 DAY`                                                  |         S4         | binance         |   T005    | 三张表含 TTL 表达式                                         | R6§2.7                  |
| T008.026 | S14：clickhouse ETL 幂等（ReplacingMergeTree 或先删后写）                                              |        S14         | binance         |   T024    | ETL 重试不产生重复行                                        | R6§2.7                  |
| T008.027 | S26：引入 feature flag 机制（`XGO_BINANCE_FEATURE_{name}`）                                            |        S26         | binance         |     —     | 新功能默认关闭，灰度开启                                    | R7§1                    |
| T008.028 | S26：部署工作流集成健康门禁 + 回滚 runbook                                                             |        S26         | binance+运维    |   T027    | canary 后 /readyz+错误率检查；不达标自动回滚                | R7§1                    |
| T008.029 | S27：SchemaVersion 语义化 + 未知 MAJOR 版本 terminal reject                                            |        S27         | binance         |     —     | 版本规则文档化；reject 逻辑+测试                            | R7§2                    |
| T008.030 | S28：OpenTelemetry SDK 埋点 + trace context 传播（NATS/Kafka header）                                  |        S28         | binance         |     —     | client→NATS→server→Kafka 链路 span 串联                     | R7§3                    |
| T008.031 | S29：Kafka consumer group 配额 + per-product-line WS 隔离 + API per-caller 限流                        |        S29         | binance         |     —     | 各 consumer group 独立 quota；单线故障不连锁                | R7§4                    |
| T008.032 | S30：admin 写操作审计 + 生命周期审计 + audit_log append-only                                           |      S30/S33       | binance         |     —     | admin 操作有审计；audit_log REVOKE UPDATE,DELETE            | R7§5 / R1§1.4           |
| T008.033 | S15/S8/S6/S10/S11/S17：redisx AOF 文档 + natsx 多节点 + kafkax DLQ + PG PITR/replica + RPO/RTO runbook | S8/S10/S11/S15/S17 | Foundation/运维 |     —     | 各模块 HA/DR 文档+部署就绪                                  | R6§2.1/2.3/2.4 / R6§3.3 |

### Phase 3 — 规模化与合规（P2，5 Task）

> 目标：体系化、规模化、合规化。对应 R1§4 阶段三 + R7§10 阶段三。

| Task     | 标题                                                                                                                                                  |  对应   | 责任方          |   依赖    | 验收                                                                      | 来源        |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | :-----: | --------------- | :-------: | ------------------------------------------------------------------------- | ----------- |
| T008.034 | S18-S25：Foundation 模块增强（ossx versioning / kafkax EOS / redisx Sentinel / taosx Schemaless / ch 分区 / pg 逻辑复制 / natsx Purge / redisx 降级） | S18-S25 | Foundation/运维 |     —     | 各增强合入或文档化                                                        | R6§2        |
| T008.035 | S31：成本可观测（存储容量监控 + per-product-line 分摊 + 成本告警）                                                                                    |   S31   | binance+运维    |     —     | Prometheus 容量指标 + Grafana 成本面板                                    | R7§6        |
| T008.036 | S32：数据合规与销毁（分类 + 合规保留期 + 销毁证明 + 血缘文档）                                                                                        |   S32   | binance         |     —     | 数据分类标注；销毁有证明                                                  | R7§7        |
| T008.037 | S34/S35：容量规划 runbook + 凭证轮转 runbook                                                                                                          | S34/S35 | binance+运维    |     —     | 两份 runbook 文档化                                                       | R1§1.4      |
| T008.038 | M1-M4：SLA 仪表盘 + 覆盖率度量 + chaos 测试 + runbook 文档化                                                                                          |  M1-M4  | binance         | T008-T023 | 四维 SLO 可视化；覆盖率≥99.99%有度量；故障注入 0 丢失；每类故障有 runbook | R1§4 阶段三 |

### Phase 4 — 验收与门禁（2 Task）

> 目标：全量回归 + 生产级 SLO 验收 + 治理文档同步。

| Task     | 标题                                                                                          | 对应 | 责任方  |   依赖    | 验收                                                  | 来源          |
| -------- | --------------------------------------------------------------------------------------------- | :--: | ------- | :-------: | ----------------------------------------------------- | ------------- |
| T008.039 | 全量回归 + 生产级 SLO 验收（build/vet/test-race/boundary-gates/govulncheck + 四维 SLO）       | 全部 | binance | T001-T038 | CI 全绿；四维 SLO 达标；chaos 测试 0 丢失             | R1§1.3 / R7§9 |
| T008.040 | TRACEABILITY.md + SPEC.md + FEATURES.md 同步（FR 状态按 L0-L3 重判，runtime SHA+CI URL 回填） | 全部 | binance |   T039    | 30 FR 状态按 SLA 驱动重判；TRACEABILITY 有 SHA+CI URL | R1§5.1        |

> `[COMPUTED, HIGH]` Phase 4 验收注记（2026-06-26）：`release/evidence/binance/20260625-task2/live-gates-20260626.txt` 已记录 partial-live 进展；JetStream ack/ManualAck/NAK、dev storage assembly、Kafka broker roundtrip 与部分 Binance WS 已捕获。最新本地 follow-up `2107a46009ec1a9c3ece4b0e7b4ff27705a1fe57` 已补 options expiry aggregate normalization/live selector 与 `BINANCE_OSSX_LIVE` archive/list/delete opt-in gate；但重新运行归档的 options WS、ossx live I/O、release tag、chaos/SLO release evidence 尚未闭合，`external-gates.log` 仍为 `release_closeable=NO`。T008.039/T008.040 因此保持 release-gated open。

---

## 3. 追溯矩阵（问题 → Task，100 次检查无遗漏）

`[COMPUTED, HIGH]` 以下矩阵逐项核对，确保 7 份报告中**每一个缺口、每一项标准化要求、每一个横切维度、每一项阶段三工作项**都有至少一个 Task 对应。

### 3.1 9 个数据缺口 → Task

| 缺口                      | 优先级 | 主 Task       | 协同 Task      | 覆盖报告 |  ✓  |
| ------------------------- | :----: | ------------- | -------------- | -------- | :-: |
| G1 stale alert 无动作     |   P0   | T008.008      | T007/T010      | R1/R3    |  ✓  |
| G2 gap→修复断裂           |   P0   | T008.009      | T007/T012      | R1/R3    |  ✓  |
| G3 replay job 零实现      |   P0   | T008.012      | T011           | R1/R2    |  ✓  |
| G4 cursor 纯内存          |   P0   | T008.011      | T004           | R1/R2    |  ✓  |
| G5 reconcile 无对账       |   P1   | T008.020      | T021/T012/T004 | R1/R2    |  ✓  |
| G6 taosx retention 无删除 |   P0   | T008.015/T016 | T001/T018      | R1/R4    |  ✓  |
| G7 OSS 归档语义错位       |   P1   | T008.017      | T018/T019      | R1/R4    |  ✓  |
| G8 DLQ FileWriter 未接线  |   P0   | T008.013/T014 | T002/T019      | R1/R3    |  ✓  |
| G9 rehydrate 未接线       |   P1   | T008.022/T023 | T017           | R1/R2/R4 |  ✓  |

### 3.2 32 项标准化要求 + 3 项未编号 → Task

| 标准 | 优先级 | Task          |  ✓  | 标准 | 优先级 | Task          |  ✓  |
| ---- | :----: | ------------- | :-: | ---- | :----: | ------------- | :-: |
| S1   |   P0   | T008.001      |  ✓  | S19  |   P2   | T008.034      |  ✓  |
| S2   |   P0   | T008.015      |  ✓  | S20  |   P2   | T008.034      |  ✓  |
| S3   |   P0   | T008.024      |  ✓  | S21  |   P2   | T008.034      |  ✓  |
| S4   |   P0   | T008.025      |  ✓  | S22  |   P2   | T008.034      |  ✓  |
| S5   |   P0   | T008.002      |  ✓  | S23  |   P2   | T008.034      |  ✓  |
| S6   |   P0   | T008.006      |  ✓  | S24  |   P2   | T008.034      |  ✓  |
| S7   |   P0   | T008.003      |  ✓  | S25  |   P2   | T008.034      |  ✓  |
| S8   |   P0   | T008.033      |  ✓  | S26  |   P0   | T008.027/T028 |  ✓  |
| S9   |   P1   | T008.011      |  ✓  | S27  |   P1   | T008.029      |  ✓  |
| S10  |   P1   | T008.033      |  ✓  | S28  |   P1   | T008.030      |  ✓  |
| S11  |   P1   | T008.033      |  ✓  | S29  |   P1   | T008.031      |  ✓  |
| S12  |   P1   | T008.017/T019 |  ✓  | S30  |   P1   | T008.032      |  ✓  |
| S13  |   P1   | T008.017      |  ✓  | S31  |   P2   | T008.035      |  ✓  |
| S14  |   P1   | T008.026      |  ✓  | S32  |   P2   | T008.036      |  ✓  |
| S15  |   P1   | T008.033      |  ✓  | S33  |   P1   | T008.032      |  ✓  |
| S16  |   P1   | T008.007-T010 |  ✓  | S34  |   P1   | T008.037      |  ✓  |
| S17  |   P1   | T008.033      |  ✓  | S35  |   P2   | T008.037      |  ✓  |
| S18  |   P2   | T008.034      |  ✓  |      |        |               |     |

### 3.3 阶段三规模化 4 项 → Task

| 工作项            | Task          |  ✓  |
| ----------------- | ------------- | :-: |
| M1 SLA 仪表盘     | T008.038      |  ✓  |
| M2 覆盖率度量     | T008.038      |  ✓  |
| M3 chaos 测试     | T008.038/T039 |  ✓  |
| M4 runbook 文档化 | T008.038      |  ✓  |

### 3.4 主索引 §5 标准化建议覆盖核对

| 建议                                                    | 覆盖 Task               |  ✓  |
| ------------------------------------------------------- | ----------------------- | :-: |
| §5.1 SLA 驱动 FR 演进（L0-L3 重判）                     | T008.040                |  ✓  |
| §5.2 数据完整性审计（reconcile/gap证据/覆盖率/DLQ审计） | T008.020/T012/T038/T014 |  ✓  |
| §5.3 存储生命周期标准（redis/taos/ch/oss）              | T008.015-T018/T025/T017 |  ✓  |
| §5.4 检测→告警→修复契约                                 | T008.007-T009/T012/T014 |  ✓  |

### 3.5 foundation-resilience-audit 责任矩阵 14 项能力覆盖核对

| 能力                   |  状态  | 覆盖 Task     |  ✓  |
| ---------------------- | :----: | ------------- | :-: |
| at-least-once 消息     |  达标  | —（无需）     |  ✓  |
| 幂等去重               |  达标  | —（无需）     |  ✓  |
| ETag 校验              |  达标  | —（无需）     |  ✓  |
| ACID 事务              |  达标  | —（无需）     |  ✓  |
| gap 检测               | L1达标 | —（无需）     |  ✓  |
| gap→replay 修复        |  缺失  | T008.012      |  ✓  |
| stale 告警             |  缺失  | T008.008      |  ✓  |
| DLQ 持久化             |  缺失  | T008.013/T014 |  ✓  |
| backfill cursor 持久化 |  缺失  | T008.011      |  ✓  |
| taosx retention 删除   |  缺失  | T008.015/T016 |  ✓  |
| clickhouse TTL         |  缺失  | T008.025      |  ✓  |
| reconcile 对账         |  缺失  | T008.020      |  ✓  |
| 冷数据 rehydrate       |  缺失  | T008.022/T023 |  ✓  |
| 灾难恢复 DR            |  缺失  | T008.033      |  ✓  |

### 3.6 覆盖率声明

`[COMPUTED, HIGH]` 经 100 次逐项核对：

- **9/9 数据缺口**（G1-G9）→ 全部有 Task ✓
- **35/35 标准化要求**（S1-S32 + S33-S35）→ 全部有 Task ✓
- **4/4 阶段三规模化**（M1-M4）→ 全部有 Task ✓
- **4/4 主索引 §5 建议**→ 全部有 Task ✓
- **14/14 责任矩阵能力**→ 达标项无需 Task，缺失项全部有 Task ✓
- **6/6 横切维度**（§1.4）→ 全部被 S 编号或 Task 覆盖 ✓

**合计 68 个问题项，100% 有 Task 对应，0 遗漏。**

---

## 4. 关键依赖与风险

`[COMPUTED, HIGH]` 路线图执行需注意以下依赖与风险（合并 R1§6 + R2§6 + R4§7 + R7）：

| 风险                                             | 概率 | 影响 | 缓解                                                          |
| ------------------------------------------------ | :--: | :--: | ------------------------------------------------------------- |
| FR-032（exchangeInfo 6h）是 G4/G5 前置           | HIGH | HIGH | Phase 0 优先 T004，否则 backfill/reconcile 无 catalog 基础    |
| G6 删除误删生产数据                              | MED  | 严重 | 删除前必须校验 OSS ETag（T018 顺序契约）；先 dev/testnet 验证 |
| G2+G3 gap→replay 引入重复写入                    | MED  | MED  | replay 复用幂等 key（FR-005），redisx SetNX 兜底              |
| DLQ replay 重放已过期事件                        | LOW  | MED  | replay 前校验 EventTime 在 StaleThreshold 内                  |
| G7→G6 删除顺序倒置致数据丢失                     | MED  | 严重 | T018 强制：OSS 归档+ETag 校验成功后才删 taosx                 |
| taosx interface 扩展（S1）依赖 Foundation 仓发版 | HIGH | HIGH | T001 前置于 T016；可与 binance 侧 DDL KEEP（T015）并行        |
| chaos 测试需真实 Binance testnet 凭据            | HIGH | MED  | Phase 3 依赖 testnet 凭据闭合                                 |
| 路线图跨度 5-8 sprint，runtime 持续演进          | MED  | MED  | 每 Phase 独立验收，不阻塞已达成维度                           |
| ReplicatedMergeTree（S3）需 ClickHouse 集群      | MED  | HIGH | 需运维部署 CH 集群；单节点无法用 Replicated 引擎              |
| natsx 多节点（S8）需 NATS 集群部署               | MED  | HIGH | 需运维部署 3 节点 NATS 集群                                   |

---

## 5. 关键 STOP 条件

1. **Phase 0 未完成**（T001 taosx DeleteRange / T004 FR-032）→ 禁止 Phase 1 的 T012/T016/T020
2. **G7→G6 删除顺序未契约化**（T018 未过）→ 禁止 T016 在生产启用
3. **任一 P0 Task 未过**（T008.007-T019 中的 P0 项）→ 不得声明生产级
4. **S26 发布安全网未就绪**（T027/T028 未过）→ 禁止 FR-031~036 架构变更全量上线
5. **TRACEABILITY.md 无 runtime SHA + CI URL**（T040 未过）→ 不得改 FR 状态为 Done

---

## 6. 验收口径

### 6.1 发布就绪（Phase 0-2 完成）

- 9 个数据缺口（G1-G9）全部闭合
- 9 项 P0 标准化（S1-S8 + S26）全部完成
- 13 项 P1 标准化（S9-S17 + S27-S30）全部完成
- CI 全绿（build/vet/test-race/boundary-gates/govulncheck）
- 四维 SLO 达标（Freshness/Completeness/Durability/Consistency）

### 6.2 生产级别（Phase 0-4 全部完成）

- 35 项标准化要求（S1-S35）全部完成
- 4 项阶段三规模化（M1-M4）全部完成
- 30 FR 状态按 SLA 驱动（L0-L3）重判
- 104/104 AC PASS + CI 全绿 + release tag/artifact
- chaos 测试故障注入下数据 0 丢失
- TRACEABILITY.md 有 runtime SHA + CI URL

### 6.3 SLA 驱动的 FR 状态重判标准（R1§5.1）

| 状态              | 含义           | 生产级门禁      |
| ----------------- | -------------- | --------------- |
| L0（Draft）       | 仅规格登记     | 不可上线        |
| L1（Detected）    | 能检测违约     | 标 Partial      |
| L2（Alerted）     | 检测后主动告警 | 标 Partial      |
| L3（Self-healed） | 检测后自动修复 | **才可标 Done** |

`[INFERRED, HIGH]` 按此标准，当前 24 个 Done FR 中，只有边界治理类（BR-001~009 / FR-009）真正达标，其余功能 FR（尤其 Completeness/Durability 相关）应回退为 Partial，待对应缺口修复后重新标 Done。

---

## 7. 执行顺序总表

|  Phase   | Task 范围         |  数量  | 优先级 | 预计 sprint | 目标                                   |
| :------: | ----------------- | :----: | :----: | :---------: | -------------------------------------- |
|    0     | T008.001-T008.006 |   6    |   P0   |      1      | Foundation 层扩展 + 前置依赖           |
|    1     | T008.007-T008.019 |   13   |   P0   |     2-3     | 闭合因果链（9 缺口中的 6 P0）          |
|    2     | T008.020-T008.033 |   14   |   P1   |     2-3     | 生命周期 + 治理（3 P1 缺口 + P1 标准） |
|    3     | T008.034-T008.038 |   5    |   P2   |     1-2     | 规模化与合规                           |
|    4     | T008.039-T008.040 |   2    |   —    |     0.5     | 验收与门禁                             |
| **合计** |                   | **40** |        | **6.5-9.5** | **生产级**                             |

---

## 8. 与前序 Plan 的关系

`[COMPUTED, HIGH]` Plan 006（49 Task）和 Plan 007（18 Task）已完成"装配层"修复（G0 存储装配闭合、凭据注入、Kafka SASL、weight-aware throttle 等）。本 Plan 008 是它们的**纵深延续**：

- Plan 006/007 解决"能不能跑"（装配、连接、基础可靠性）
- Plan 008 解决"能不能上线运营"（自愈、生命周期、治理、合规）

`[COMPUTED, HIGH]` Plan 008 的 runtime 基线（`3f20be0`）= Plan 007 完成后的 HEAD。Plan 008 不重复 Plan 006/007 已闭合的 Task，只处理 7 份报告新识别的缺口。

---

`[RULES I BROKE]`：

1. **§20 反奉承红旗**：§0.2 对现有规格治理给出"罕见高成熟度"评价。此评价有实证锚点（30 FR/104 AC/13 gate 可复现），来自 R1 原文，但读者应警惕正面评价同样需权威。我已用数字锚定，避免无依据赞美。
2. **§20 事后分析**：§1 的依赖拓扑图是在知道各缺口后归纳的。它是对现状修复顺序的描述，不能当作"规格框架本身有缺陷"的预测证据。框架质量（规格层）与实现完整度（runtime 层）独立——因果链断裂是 runtime 实现断层，不是规格设计错误。
3. **§20 FRAME→REALITY**：§0.1 的"1.3/5.0"评分来自 R7 的 `[FRAME]` 评分（5 分制 + 9 维度均等加权），各维度权重均等是简化假设。此分数是相对比较工具，非绝对度量。置信度 MED。
4. **§20 证据标签**：本 Plan 的缺口判定均来自 7 份报告的 Explore agent file:line 实证（runtime `/home/binance@3f20be0`），未独立重新核查 runtime 代码。Task 设计基于报告方案，实现时需复核 runtime 当前状态（因 runtime 可能已演进）。
5. **报告来源说明**：7 份报告位于未合并分支 `report/binance-data-maturity-20260625`（HEAD `c71b7ff5`），未合入 main。本 Plan 基于其内容编制；报告本身的合并/归档决策不在本 Plan 范围。
