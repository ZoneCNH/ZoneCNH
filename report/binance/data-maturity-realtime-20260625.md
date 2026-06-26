# 实时数据链路成熟度评估（分报告）

- Report-ID: binance-data-maturity-realtime-20260625
- 所属主报告：[`data-maturity-assessment-20260625.md`](data-maturity-assessment-20260625.md) §3 实时数据行
- Historical Runtime Anchor：`/home/binance@3f20be0`
- Current Effective Runtime Anchor：`/home/binance@f046e16`（含 Plan008 全部 40 Task 代码实现；PR #145 合并）
- 评估日期：2026-06-25
- 范围：FR-003/004（natsx 通信 + At-Least-Once）/ FR-012~015（Stream 生命周期/可靠性/可观测/控制）/ FR-029（Freshness SLA）

> [COMPUTED, HIGH] 本报告所有缺口声明经 Explore agent 在 runtime `/home/binance` 逐条 file:line 核查。规格参数来自 `module/binance/SPEC.md` 实读。
> [COMPUTED, HIGH] 本报告保留 2026-06-25 历史评估语境；当前 issue ledger 与 runtime anchor 以 [`issues-sync-20260625.md`](issues-sync-20260625.md) 和 `/home/binance@f046e16`（含 Plan008 全部 40 Task 代码实现；PR #145 合并）为准。

---

## 1. 链路成熟度评分（SLA 四维）

| 维度 | 得分 | 级别 | 依据 |
|------|:----:|:----:|------|
| **Freshness** | **1.8** | **L1+** | 延迟测量达 L2（SLO 24/24 PASS），但延迟违约响应仅 L1（G1 stale 无告警）|
| **Completeness** | **0.8** | **L1-** | at-least-once 交付扎实，但 gap→修复断裂（G2）|
| **Durability** | **1.0** | **L1** | DLQ in-memory（G8）；事件本身经 taosx 持久化 |
| **Consistency** | **1.5** | **L1+** | 幂等 SetNX 扎实；断流/重启场景的一致性保障不足 |
| **加权** | **1.3** | **预生产** | 无单一维度达 L2+；Freshness 被 G1 拉低 |

`[COMPUTED, HIGH]` **实时链路是三链路中成熟度最高的**（1.3），但**没有任何单一维度达到生产级门槛**。Freshness 看似最强，实则分裂：延迟**测量**达 L2（SLO benchmark 24/24 PASS，`release/evidence/binance/20260625/slo-report.md`），但延迟**违约响应**仅 L1（G1 stale 计数后无告警动作）——"测得准"不等于"管得住"。核心问题：检测到异常后的响应全链路缺失（stale 不告警、gap 不修复、死信只进内存）。

> [COMPUTED, HIGH] **打分修正说明**：初版给 Freshness 打 2.5（L2+），但同一报告 §2.1 判定 G1（stale 无告警）为 L1，构成内部矛盾。Freshness 应拆为"测量"（L2）与"违约响应"（L1）两个子项，综合 1.8 更诚实。实时加权总分相应从 1.5 下调至 1.3。

---

## 2. 缺口详析

### 2.1 G1：stale alert 无触发动作（P0，Freshness→Completeness）

**规格要求**（SPEC §17 / FR-029 / AC-100）：
- spot/um_perp/cm_perp 30s、options 60s 无新事件触发 **stale alert**
- alert 应是可观测、可响应的动作（非仅计数）

**runtime 实证**：
- `internal/server/sla_window.go:64-83` — `Record()` 在 freshness 超过 `StaleAlertThreshold`（默认 5s）时仅 `w.staleCount++` / `w.totalStale++`，注释（:11）写"供 metrics/alert 消费"，**但实际无消费方**。
- `internal/server/quality.go:102` — `snap.staleCount = q.slaWindow.TotalStale()` 只把计数塞进 snapshot。
- `quality.go:81` 注释自称"freshness SLA P95/P99 滑动窗口 + stale alert"，但**全仓 grep `IsStale`/`StaleCount`/`TotalStale`** 在非测试代码中除 `sla_window.go` 自身定义和 `quality.go:102` 读取外，**没有任何调用方**——即 `IsStale()` 返回值从不被读。
- 无 natsx 发告警 subject、无写 alerts 表、无 webhook、无触发 replay/backfill。
- `internal/server/ingest.go:111` 注释自认："生产环境此处应触发 alertx；首版仅记录。"
- 注意区分：spot/um/cm 30s、options 60s 的阈值体现为 `StaleThreshold` **拒绝门**（`server.go:78` `30 * time.Second`）——那是**拒绝**老事件进入，不是断流告警。两者语义不同。

`[COMPUTED, HIGH]` **判定：L1（检测）无 L2（告警动作）**。stale 被统计进内存窗口计数，`IsStale()` 函数存在但永不消费。

**生产级影响**：stream 断流（Binance 侧故障、网络分区）时，系统默默接受 stale 数据或停止接收，**无任何告警**。运维只能在用户投诉或下游策略异常后才发现断流，MTTD（平均发现时间）不可控。

### 2.2 G2：gap→修复链路断裂（P0，Completeness）

**规格要求**（SPEC FR-017 / AC-063~065）：
- ingest gap detector 基于序列/时间桶发现缺口 → 生成 replay job
- replay 失败保留原因、重试次数、可恢复 cursor

**runtime 实证**：
- `internal/server/quality.go:57-68` — `observe()` 检测到 gap（`req.EventTime.Sub(prev) > q.maxEventGap`，默认 2min）时：
  - `status.RepairRequired = true`
  - `q.gapDetected++` / `q.repairRequired++`
  - `q.metrics.IncGapDetected(streamID)`
  - `q.metrics.SetGapRepairRequired(streamID, true)`
- **全仓 grep `RepairRequired` / `repair_required`**：生产代码引用仅 `quality.go:62,67,74`（设置）、`admin.go:164`（只读快照）、`metrics.go:428-436`（Prometheus gauge）、`wire/types.go:35`（字段定义）。**没有任何代码读取该标志去 enqueue replay job / 触发 backfill / 写 task 队列。**
- `quality.go:69-74` gap 修复验证完全被动：依赖上游请求自带 `SourceMetadata["repair"]="verified"` 标记，系统自身从不发起修复。

`[COMPUTED, HIGH]` **判定：L1（检测）无 L3（修复）**。`RepairRequired` 是纯单向写标志，检测与修复之间的桥完全缺失。

> 注：G2 与历史分报告 G3 是同一断点的两面——G2 指 server 侧 gap 标志无消费，G3 指 client 侧 replay job 无实现。补齐方案需协同设计，详见 §4.1 与 [历史分报告 §4.1](data-maturity-history-20260625.md)。

**生产级影响**：实时流出现 gap（Binance 服务端丢消息、消费端 Nak 重投超 MaxDeliver 进死信）后，gap 永久存在。Prometheus 里能看到 `binance_gap_detected` 计数增长，但**没有任何东西在修它**。

### 2.3 G8：DLQ FileWriter 未接线（P0，Durability）

**规格要求**（SPEC FR-004 / BR-004；DATA-LIFECYCLE G12）：
- dead-letter / poison message 必须有持久化存储 + replay 流程
- 死信重启不丢

**runtime 实证**：
- `internal/server/ingest.go:314-335` — `deadLetter` 是进程级 `var globalDeadLetter = &deadLetter{}`（:326），`appendDeadLetter`（:328）执行 `globalDeadLetter.entries = append(...)`，调 `s.metrics.IncDeadLetter()` 和 `s.logDeadLetter`（日志）。**未调用 `deadletter.FileWriter`/任何 `Writer`。** 注释 :267、:314 均自认"首版 in-memory，未来接持久化 dead-letter queue"。
- `deadletter` 包的接线点：grep `NewFileWriter` 全仓——仅 `deadletter.go:52`（定义）和 `deadletter_test.go:14,52,72`（测试）三处。**`internal/server/` 下无任何 `.go` 文件引用 `deadletter.` 包**。FileWriter 从未在生产路径构造或调用。
- `ingest.go` 三条 dead-letter 路径**全部**走 `appendDeadLetter` → 内存：
  - dispatch 失败（:270）
  - storage 写失败（:294）
  - post-accept hook 失败（:309）

`[COMPUTED, HIGH]` **判定：L1（in-memory 计数）无 L3（持久化 + replay）**。`deadletter.FileWriter` 是孤立代码（仅测试覆盖），`appendDeadLetter` 仍写进程级内存切片。`FEATURES.md` #1118 自己承认："FileWriter 已实现+测试，待接线到生产 dispatch 路径"。

**生产级影响**：
- 进程重启 → 内存死信全部丢失 → 那些事件的 dispatch/storage 失败**永远无法 replay**。
- `globalDeadLetter` 是无界切片，长时间运行 + 高失败率会 OOM。
- 死信无标准 replay runbook，运维不知如何重新投递。

---

## 3. 因果链：实时数据"时效达标但完整性自愈缺失"

`[COMPUTED, HIGH]` 实时链路三个缺口构成 stale/gap/DLQ 三条平行断裂：

```
[事件 ingest] ──✅ Freshness 检测──> SLA 计数（24/24 PASS）
                    │
                    ├─ stale 超阈值 ──> [断点 G1] 只计数，无告警动作
                    │                      （运维 MTTD 不可控）
                    │
                    ├─ gap 检测 ──✅──> RepairRequired=true ──> [断点 G2] 无消费方
                    │                                            （gap 永久残留）
                    │
                    └─ dispatch/storage 失败 ──> [断点 G8] in-memory DLQ
                                                （重启丢死信，无法 replay）
```

`[INFERRED, HIGH]` 实时链路的**时效性（Freshness）是最扎实的**——这部分达到了生产级。但"出问题之后怎么办"几乎全空白。生产级系统的核心不是"正常运行时很快"，而是**"异常时能自愈/可恢复"**。

---

## 4. 补齐方案（生产级）

### 4.1 G1 + G2 联动：stale/gap 告警→修复闭环（P0）

`[COMPUTED, HIGH]` G1（stale 无告警）和 G2（gap 无修复）应**协同设计**——它们共享同一条"检测→动作"契约，只是触发条件不同（stale = 时间维度断流，gap = 序列/事件时间维度间断）。

**设计**：新增统一的 `AlertDispatcher`，消费 stale/gap 信号，路由到告警 + 修复两条路径。

```text
新增 internal/server/alert_dispatcher.go：

  stale 超阈值（sla_window IsStale）
    └─> AlertDispatcher.onStale(streamID, threshold)
          ├─> 写 binance_alerts 表（level=warn, reason=stale）
          ├─> 发 natsx: binance.alert.stream.stale（供下游订阅）
          └─> 触发 client 侧 stream 健康检查（FR-014 已有 stream state）

  gap 检测（quality RepairRequired）
    └─> AlertDispatcher.onGap(streamID, prevTime, observedTime)
          ├─> 写 binance_alerts 表（level=error, reason=gap）
          ├─> 发 natsx: binance.alert.data.gap
          └─> 生成 ReplayJob → 投递 backfill 队列（桥接 G3）
```

**改动点**：
- `sla_window.go`：`Record()` 内 stale 判断后调用注入的 `AlertDispatcher.onStale()`（当前只 `staleCount++`）
- `quality.go`：`observe()` gap 检测后调用 `AlertDispatcher.onGap()`（当前只设标志）
- 新增 `internal/server/alert_dispatcher.go`：统一告警分发
- 新增 `binance_alerts` 表（migration 008）：`id, level, reason, stream_id, detail(JSONB), created_at, resolved_at`
- 新增 natsx alert subjects：`binance.alert.stream.stale` / `binance.alert.data.gap`

**与现有架构的契合**：`[KNOWN, HIGH]` binance 已有 `ControlPlane`（FR-012~015）暴露 stream state，AlertDispatcher 可复用 stream 标识体系（product_line/symbol/event_type）。

**验收**：
- 断流 30s（spot）→ 30s 内 alerts 表有记录 + natsx 有 alert subject
- gap 检测 → alerts 表有记录 + 生成 ReplayJob（与 G3 协同）

### 4.2 G8：DLQ FileWriter 接线 + replay runbook（P0）

**设计**：`appendDeadLetter` 同时写内存（保留即时查询）+ FileWriter（持久化），并提供 replay CLI/runbook。

```text
ingest.go appendDeadLetter 改造：
  ├─> 保留 globalDeadLetter 内存切片（向后兼容，供 admin 即时查询）
  ├─> 新增：调用 deadletter.FileWriter.Write(event, reason)  ← 接线点
  │     路径：{data_dir}/deadletter/{YYYY}/{MM}/{DD}/{batchID}.jsonl
  └─> metrics.IncDeadLetter()（不变）

新增 replay runbook（CLI 或 admin endpoint）：
  POST /api/v1/admin/deadletter/replay?since=...&until=...
    ├─> 读取 FileWriter JSONL
    ├─> 逐条重新 Publish 到 natsx（复用原 subject）
    ├─> server 消费 → 幂等检查（FR-005 SetNX）→ 已处理则跳过
    └─> 返回 replay 统计（replayed / skipped / failed）
```

**改动点**：
- `internal/server/ingest.go:328` `appendDeadLetter`：注入 FileWriter 并调用
- `cmd/binance-server/main.go` / `storage_env.go`：构造 FileWriter 并注入 IngestServer
- 新增 `internal/server/replay_handler.go`：replay endpoint
- FileWriter 路径需纳入 ossx 归档（避免本地磁盘丢失）——与存储分报告 G7 协同

**幂等保障**：`[KNOWN, HIGH]` replay 重新 Publish 后，server 侧 redisx SetNX（FR-005，72h TTL）会拦截已处理事件。但需注意：**若死信事件已超 72h**，幂等 key 已过期，replay 会重复写入。replay 前应校验 EventTime 是否在合理窗口内。

**验收**：
- 死信写入后，磁盘 JSONL 文件存在
- 进程重启后，内存 DLQ 清空，但磁盘文件保留
- replay endpoint 能读取 JSONL 并重新投递，已处理事件被 SetNX 拦截

---

## 5. 实时链路生产级标准化清单

`[KNOWN, HIGH]` 实时链路达到生产级必须满足（除补齐 3 个缺口外）：

| 标准项 | 要求 | 当前 |
|--------|------|------|
| **Freshness SLO** | event→persist P99<200ms，event→fanout P99<300ms | ✅ 24/24 PASS |
| **at-least-once 交付** | JetStream PubAck + ManualAck + NakWithDelay | ✅ FR-004 Done |
| **幂等接受** | redisx SetNX 72h TTL | ✅ FR-005 Done |
| **stale 告警** | 断流超阈值触发告警动作 | ❌ G1 |
| **gap 自愈** | gap 检测→自动 replay | ❌ G2 |
| **DLQ 持久化** | 死信落盘 + replay runbook | ❌ G8 |
| **stream 可观测** | state/lag/unhealthy reason 暴露 | ✅ FR-014 Done |
| **pause/resume/drain** | operator 控制有审计 | ✅ FR-015 Done |
| **retry budget** | connect/read/publish 限额 | ✅ FR-013 Done |
| **覆盖率度量** | 应采集 vs 实际采集比率 | ❌ 无度量（阶段三）|

---

## 6. 与其他链路的协同

`[COMPUTED, HIGH]` 实时链路的补齐与其他分报告有强协同：

| 本链路缺口 | 协同链路 | 协同点 |
|-----------|---------|--------|
| G2（gap 无修复）| [历史 G3](data-maturity-history-20260625.md) | G2 的 ReplayJob 投递到 G3 的 backfill 队列；需协同设计 idempotency key |
| G8（DLQ replay）| [历史 G4](data-maturity-history-20260625.md) | DLQ replay 的进度应持久化（复用 G4 的 postgresx 持久化机制）|
| G1（stale 告警）| [存储 G6](data-maturity-storage-20260625.md) | stale 持续可能预示存储写入瓶颈（taosx 慢导致 ack 延迟）|

---

`[RULES I BROKE]`：
1. **§20 FRAME→REALITY**：§4 的 AlertDispatcher / FileWriter 接线是设计建议，非 runtime 已验证。幂等 replay 不重复写入基于 FR-005 SetNX 机制存在（`[KNOWN]`），但 72h 过期窗口边界需实现时验证。置信度 HIGH（机制成立）。
2. **§20 事后分析**：§3 的因果链是对现状描述，非规格缺陷预测证据。Freshness 达标是 SLO benchmark 实证，与 gap/stale 断链是独立事实。
