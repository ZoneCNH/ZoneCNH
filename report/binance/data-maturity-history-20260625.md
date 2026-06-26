# 历史数据链路成熟度评估（分报告）

- Report-ID: binance-data-maturity-history-20260625
- 所属主报告：[`data-maturity-assessment-20260625.md`](data-maturity-assessment-20260625.md) §3 历史数据行
- Historical Runtime Anchor：`/home/binance@3f20be0`
- Current Effective Runtime Anchor：`/home/binance@f046e16`（含 Plan008 全部 40 Task 代码实现；PR #145 合并）
- 评估日期：2026-06-25
- 范围：FR-016（Backfill Planner）/ FR-017（Gap Replay）/ FR-018（Archive Manifest）/ FR-019（Resource Governance）/ FR-026（Daily Reconcile）/ FR-027（Cold Rehydration）/ FR-028（Backfill Progress API）

> [COMPUTED, HIGH] 本报告所有缺口声明经 Explore agent 在 runtime `/home/binance` 逐条 file:line 核查。规格参数来自 `module/binance/SPEC.md` 实读。
> [COMPUTED, HIGH] 本报告保留 2026-06-25 历史评估语境；当前 issue ledger 与 runtime anchor 以 [`issues-sync-20260625.md`](issues-sync-20260625.md) 和 `/home/binance@f046e16`（含 Plan008 全部 40 Task 代码实现；PR #145 合并）为准。

---

## 1. 链路成熟度评分（SLA 四维）

| 维度             |  得分   |    级别    | 依据                                                 |
| ---------------- | :-----: | :--------: | ---------------------------------------------------- |
| Freshness        |    —    |    N/A     | 历史数据非实时，不评估                               |
| **Completeness** | **0.3** |  **L0+**   | gap→replay 断裂（G3）；backfill 无覆盖恢复（G4）     |
| **Durability**   | **0.5** |  **L0+**   | cursor/coverage 纯内存（G4）；rehydrate 未接线（G9） |
| **Consistency**  | **0.5** |  **L0+**   | reconcile 无真实对账（G5）                           |
| **加权**         | **0.4** | **实验级** | 距生产级（≥2.0）缺口最大                             |

`[COMPUTED, HIGH]` **历史链路是三链路中成熟度最低的**（0.4 vs 实时 1.5 vs 存储 1.2）。核心问题：数据完整性保障的"修复侧"几乎全部空白——能记录 backfill 请求、能检测 gap，但**不能恢复、不能对账、重启即丢**。

---

## 2. 缺口详析

### 2.1 G3：replay job 零实现（P0，Completeness）

**规格要求**（SPEC FR-017 / AC-063~065）：

- gap 检测器基于 sequence/time bucket 发现缺口 → 生成 replay job
- replay job 对已存在数据幂等，不重复写入 taosx/clickhousex
- replay 失败保留原因、重试次数、可恢复 cursor

**runtime 实证**：

- `internal/server/quality.go:57-68` — `observe()` 检测到 gap 时设 `status.RepairRequired = true`，`q.metrics.SetGapRepairRequired(streamID, true)`
- **全仓 grep `RepairRequired`**：生产代码引用仅 `quality.go:62,67,74`（设置）、`admin.go:164`（只读快照）、`metrics.go:428`（gauge 设置）。**没有任何代码读取该标志去 enqueue replay job / 触发 backfill / 写 task 队列。**
- `quality.go:69-74` gap 修复验证完全被动：依赖上游请求自带 `SourceMetadata["repair"]="verified"` 标记，**系统自身从不发起修复**。

`[COMPUTED, HIGH]` **判定：L0（零实现）**。`RepairRequired` 是纯单向写标志，检测与修复之间的桥**完全缺失**。系统能"知道有 gap"，但不能"补 gap"。

**生产级影响**：行情数据出现 gap（网络抖动、Binance 服务端丢消息）后，gap 永久存在，下游策略/回测基于残缺数据，产生错误信号。

### 2.2 G4：backfill cursor 纯内存（P0，Durability + Completeness）

**规格要求**（SPEC FR-016 / AC-061；FR-019 / AC-070）：

- backfill cursor 可持久化并在重启后从上次成功 offset 恢复
- operator 取消 backfill 后 cursor 保持可恢复

**runtime 实证**：

- `internal/client/history_lifecycle.go:187-217` — `HistoryRuntime` 结构体字段 `jobs map[string]HistoryJob`、`coverage map[string]HistoryCoverage`、`jobOrder []string` 等全部是内存数据结构，**无 `path` 字段、无 `persistLocked` 方法**。
- 所有方法（`RequestBackfill:228`、`Reconcile:305`、`RefreshCatalog:356`）只操作内存 map/slice。
- **对比**：同包 `Cursor`（`cursor.go:126` `persistLocked` → `writeJSONFile`）和 `Queue`（`queue.go:288,379-388`）**有**本地 JSON 文件持久化，但 `HistoryRuntime` 没有。
- grep `HistoryRuntime` 全仓非测试引用仅在 `admin.go`（注入）和 `runtime.go:106`（构造），无 `persist`/`load`/`serialize`/postgres 写入。

`[COMPUTED, HIGH]` **判定：L0（纯内存）**。进程重启即丢全部 backfill jobs / coverage / reconcile 记录。`FEATURES.md` #1117 自己承认："重启后 backfill 从头开始（in-memory coverage 丢失）"。

**生产级影响**：backfill 是长时任务（可能跨小时）。进程在 backfill 中途崩溃 → 重启后不知道已经 backfill 到哪 → 要么重头开始（浪费 Binance weight 配额，可能触发封禁），要么跳过（数据永久残缺）。

### 2.3 G5：reconcile 无真实对账（P1，Consistency）

**规格要求**（SPEC FR-026 / AC-090~092）：

- 每日 04:00 UTC coordinator 持锁实例跑 symbol×1d 全量对账
- 差异超 tolerance 0.01% 写入 `binance_reconciliation_alerts` 表
- 对账完成发布 `binance.control.reconciliation.completed` + 当日统计

**runtime 实证**：

- `internal/client/cron_reconcile.go:87-114` — `runReconciliation()` 调 `life.QueueDailyReconciliation(req)` 后只 `log.Printf("...queued %d tasks...")`，**无后续执行 worker**。
- `internal/client/lifecycle.go:258-291` — `QueueDailyReconciliation` 仅遍历内存 catalog，为每个 symbol×eventType 造一个 `LifecycleTask{Kind: LifecycleTaskDailyReconciliation, Status: LifecycleTaskQueued}` 调 `putTaskLocked` 入队。**不查 taosx、不调 Binance REST、不做任何数据比对。**
- grep `LifecycleTaskDailyReconciliation` / `LifecycleTaskGapFill`：全仓**无任何 worker/consumer 读取这些 task 去执行**。task 只在内存 `m.tasks` 里堆着供 `Snapshot()` 展示。

`[COMPUTED, HIGH]` **判定：L1（检测/入队）但无执行**。reconcile 只是"记一个 task 入队 + 打日志"，无任何真实数据比对。`cron_reconcile.go:111` 自称 "queued N tasks"，但 N 个 task 永远是 Queued 状态，无人消费。

**生产级影响**：数据一致性无法被证明。taosx 里的数据与 Binance 权威源是否一致，系统不知道，也无法发现静默数据丢失。

### 2.4 G9：冷数据 rehydrate 未接线（P1，Durability）

**规格要求**（SPEC FR-027 / AC-093~095）：

- 冷数据查询返回 202 + job_id，触发 OSS→taosx 回热（24h TTL 临时表）
- `GET /api/v1/admin/rehydration/jobs/:job_id` 返回 pending/running/ready/expired
- 临时表 24h TTL 到期自动删除

**runtime 实证**：

- `internal/server/storage/oss_rehydrate.go:44-60` — `Rehydrate()` 方法**已实现**（读 OSS NDJSON → 反序列化 → 经 StorageWriter 写回），签名完整。
- **但全仓 grep `Rehydrate` 的调用方**：仅 `oss_rehydrate_test.go`（测试）。**生产路径（API handler / admin / cron）无任何调用。**
- 无 `GET /api/v1/admin/rehydration/jobs/:job_id` 端点实现；无 202 + job_id 异步回热流程。

`[COMPUTED, HIGH]` **判定：L0（已实现未接线）**。Rehydrate 是孤立代码（仅测试覆盖），与"冷查询→触发回热→返回数据"的生产流程未连接。

**生产级影响**：冷归档数据（>30d tick / >90d bar）虽然存在 OSS，但**无法被查询**。历史的深度回测、合规审计场景无法满足。

---

## 3. 因果链：历史数据为何"检测到却修不好"

`[COMPUTED, HIGH]` 历史链路的四个缺口构成一条断裂的修复链：

```
[gap 检测 ✅] ──RepairRequired=true──> [断点 G3] 无 replay job 生成
                                              │
                                              ▼ 需要 fetcher 恢复
                                        [断点 G4] cursor 纯内存，无法可靠恢复
                                              │
                                              ▼ 需要验证恢复正确
                                        [断点 G5] reconcile 无真实对账验证
                                              │
                                              ▼ 历史数据超出热窗口
                                        [断点 G9] rehydrate 未接线，冷数据不可查
```

`[INFERRED, HIGH]` 这条链上**任何一个断点都会让历史数据完整性承诺失效**。即使 gap 检测器发现了 100 个 gap，因为 G3（无 replay job），这 100 个 gap 永远不会被补；即使手动补了，因为 G4（cursor 不持久），下次重启会重复或遗漏。

---

## 4. 补齐方案（生产级）

### 4.1 G3：gap→replay 桥接（P0）

**设计**：在 server 侧新增 replay 桥接器，消费 `RepairRequired` 标志生成 ReplayJob。

```text
quality.go observe() 设 RepairRequired=true
  └─> 新增 replayBridge.onGapDetected(streamID, prevTime, observedTime)
        ├─> 生成 ReplayJob{id, product_line, symbol, event_type, start=prevTime, end=observedTime}
        ├─> 复用 FR-005 幂等 key 生成（exchange+pl+symbol+event_type+event_time）
        └─> 投递到 backfill 队列（复用 #1104 修复的 HistoryFetcher 路径）
```

**改动点**：

- `internal/server/quality.go`：`observe()` 内 gap 检测后调用注入的 `ReplayBridge`
- 新增 `internal/server/replay_bridge.go`：桥接器 + ReplayJob 队列
- 复用 `internal/client/history_lifecycle.go` 的 `HistoryFetcher.FetchHistorical()`（PR #103 已注入真实 REST fetcher）

**幂等保障**：`[KNOWN, HIGH]` replay 事件必须复用原 idempotency key（BR-008），redisx SetNX 防止重复写入 taosx（FR-005 已实现）。

**验收**：gap 检测后 2min 内自动生成 ReplayJob 并入队；replay 写入不产生重复（redisx SetNX 拦截）。

### 4.2 G4：backfill cursor 持久化（P0）

**设计**：`HistoryRuntime` 状态持久化到 postgresx。

```text
新增表（migration 006）：
  binance_backfill_jobs (
    id TEXT PK, product_line TEXT, symbol TEXT, data_type TEXT,
    window_start TIMESTAMPTZ, window_end TIMESTAMPTZ,
    status TEXT, cursor_time TIMESTAMPTZ,  -- 关键：可恢复 cursor
    throttle_millis BIGINT, requested_at TIMESTAMPTZ, completed_at TIMESTAMPTZ,
    last_error TEXT, retry_count INT, next_retry_at TIMESTAMPTZ
  )
  binance_backfill_coverage (
    product_line TEXT, symbol TEXT, data_type TEXT,
    window_start TIMESTAMPTZ, window_end TIMESTAMPTZ,
    last_backfill_id TEXT, backfill_count INT, updated_at TIMESTAMPTZ
  )
```

**改动点**：

- `history_lifecycle.go`：`HistoryRuntime` 新增 `persistLocked()` / `loadFromDB()`，每个状态变更后持久化
- 复用 `postgresx` adapter（FR-006b 已装配 `PgCatalog`）
- 重启时 `loadFromDB()` 恢复 jobs/coverage，未完成的 job 标记为 `interrupted` 等待恢复

**验收**：进程重启后 `GET /api/v1/admin/backfill/jobs` 仍显示中断前的 jobs；中断的 job 可从 `cursor_time` 续跑而非重头。

### 4.3 G5：reconcile 真实对账（P1）

**设计**：为 `LifecycleTaskDailyReconciliation` 实现真正的执行 worker。

```text
04:00 UTC cron 触发（cron_reconcile.go 已实现触发）
  └─> 新增 reconcileWorker.consume(task)
        ├─> 对每个 symbol×event_type：
        │     taosx_count = taosx.Query("SELECT count(*) ... WHERE date=trading_date")
        │     binance_count = Binance REST klines/aggTrades count
        │     diff_pct = abs(taosx_count - binance_count) / binance_count
        │     if diff_pct > 0.01%:
        │       INSERT INTO binance_reconciliation_alerts(...)
        │       trigger gap backfill（复用 G3 桥接）
        └─> Publish binance.control.reconciliation.completed
```

**改动点**：

- 新增 `internal/client/reconcile_worker.go`：消费 LifecycleTask 并执行对账
- 复用 PR #103 的 `HistoryFetcher` 拉 Binance 权威 count
- 新增 `binance_reconciliation_alerts` 表（migration 007）
- 需要 taosx query 能力（FR-006a 已实现 `Query`）

**依赖**：`[COMPUTED, HIGH]` 强依赖 FR-032（exchangeInfo 6h 刷新）——没有准确的 symbol 目录，对账不知道该比对哪些 symbol。

**验收**：04:00 UTC 自动跑全量对账；差异 >0.01% 写入 alerts 表并触发 backfill。

### 4.4 G9：冷数据 rehydrate 接线（P1）

**设计**：将已实现的 `Rehydrate()` 接入 API 查询路径。

```text
GET /api/v1/market/ticks/:symbol/range?start=...&end=...
  └─> 若 range 命中 OSS 归档区（< now - 30d）：
        ├─> 返回 202 + {job_id, status: "rehydrating"}
        ├─> 异步调用 OssArchiver.Rehydrate() 写入 taosx 临时表（24h TTL）
        └─> 用户轮询 GET /api/v1/admin/rehydration/jobs/:job_id
              └─> ready 后返回 taosx 临时表数据
```

**改动点**：

- `internal/server/api/query.go`：range 查询 handler 增加冷热判断 + 202 异步分支
- 新增 `internal/server/rehydrate_manager.go`：job 状态机（pending/running/ready/expired）+ 24h TTL 清理
- 新增 `GET /api/v1/admin/rehydration/jobs/:job_id` 端点

**验收**：查询 60 天前数据 → 返回 202 job_id → 轮询 → ready 返回数据；24h 后临时表自动过期。

---

## 5. 历史链路生产级标准化清单

`[KNOWN, HIGH]` 历史链路达到生产级必须满足以下标准（除补齐 4 个缺口外）：

| 标准项               | 要求                                                    | 当前                                          |
| -------------------- | ------------------------------------------------------- | --------------------------------------------- |
| **backfill 幂等**    | replay/backfill 复用 idempotency key，redisx SetNX 兜底 | ✅ FR-005 可复用                              |
| **backfill 限流**    | 感知 Binance weight 配额（spot 1200/futures 2400/min）  | ✅ FR-025 已实现（weight-aware token bucket） |
| **backfill 优先级**  | trade > bar > tick；cold_start 80% / repair 20%         | ✅ FR-025 已实现                              |
| **backfill 可取消**  | operator 取消后 cursor 可恢复                           | ❌ 依赖 G4 持久化                             |
| **gap 修复证据**     | 每个 gap 有对应 replay job 成功证据                     | ❌ 依赖 G3                                    |
| **reconcile 可证明** | 每日对账结果可审计（alerts 表 + 统计）                  | ❌ 依赖 G5                                    |
| **冷数据可回热**     | 归档数据可通过 API 触发回热                             | ❌ 依赖 G9                                    |
| **Progress API**     | jobs 列表 + coverage 时间戳 + 诊断字段                  | ⚠️ FR-028 Partial（端点存在，后端内存）       |

---

## 6. 优先级与依赖排序

`[COMPUTED, HIGH]` 历史链路 4 个缺口的实施顺序（考虑依赖）：

```
G4（cursor 持久化）──P0──> 必须最先做
  │  （G3/G5 的 replay/reconcile 结果需要持久化才不丢）
  ▼
G3（gap→replay 桥接）──P0──> 依赖 G4 持久化 replay job
  │
  ▼
G5（reconcile 对账）──P1──> 依赖 G3（对账发现差异要触发 backfill）
  │                  且依赖 FR-032（symbol 目录准确）
  ▼
G9（rehydrate 接线）──P1──> 依赖 OSS 归档稳定（存储分报告 G7）
```

**关键路径**：G4 → G3 → G5。G9 可与 G5 并行（不同子系统）。

---

`[RULES I BROKE]`：

1. **§20 FRAME→REALITY**：§4 的补齐方案中"replay 复用幂等 key 防 重复写入"是设计建议，非 runtime 已验证行为。标注 `[KNOWN]` 基于 FR-005 SetNX 机制存在，但 replay 场景下的幂等 key 生成规则需实现时验证（replay 事件的 event_time 是否与原始事件一致）。置信度 HIGH（机制成立）但实现细节待验证。
2. **§20 事后分析**：§3 的因果链图是在知道各缺口后归纳的，是对现状的描述，不构成"规格设计有缺陷"的证据。
