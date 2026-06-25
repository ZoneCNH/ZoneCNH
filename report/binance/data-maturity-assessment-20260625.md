# binance 数据成熟度评估与生产级规划（主索引）

- Report-ID: binance-data-maturity-20260625
- 评估日期：2026-06-25
- Runtime-Anchor：`/home/binance@3f20be0`（PR #103+#104 合并后）
- Spec-Anchor：`module/binance/SPEC.md` v3.6.0 / `TRACEABILITY.md` v3.6.1
- Status-Projection：`24 Done / 10 Partial / 0 Pending`（FR-001~030）+ `6 Draft`（FR-031~036）
- 范围：历史数据 / 实时数据 / 数据存储 三链路
- 目标：体系化、标准化、规范化，**生产级**
- 作者：ZCode（深度分析 + Explore agent 实证核查）

---

## 0. 如何阅读本报告

本报告采用**自顶向下**结构：先定义统一的生产级 SLA 框架，再用它衡量三条链路的成熟度，最后给出补齐路线图。

| 文档                                                                       | 职责                                             | 读者            |
| -------------------------------------------------------------------------- | ------------------------------------------------ | --------------- |
| **本文件（主索引）**                                                       | SLA 框架 + 总体评分 + 路线图 + 优先级仲裁        | 决策者 / Owner  |
| [`data-maturity-history-20260625.md`](data-maturity-history-20260625.md)   | 历史数据链路深度评估（FR-016~019/026~028）       | 数据工程 / 运维 |
| [`data-maturity-realtime-20260625.md`](data-maturity-realtime-20260625.md) | 实时数据链路深度评估（FR-003/004/012~015/029）   | SRE / 实时工程  |
| [`data-maturity-storage-20260625.md`](data-maturity-storage-20260625.md)   | 数据存储链路深度评估（FR-005~007a/010/011/006d） | 存储 / DBA      |

> [COMPUTED, HIGH] 本报告所有"缺口"声明均经 Explore agent 在 runtime `/home/binance` 逐条 file:line 核查，证据可复现。规格参数来自 SPEC.md 实读。缺口判定方法：规格定义了什么 → runtime 实现了什么 → 差值即缺口。

---

## 1. 生产级 SLA 框架（自顶向下）

`[KNOWN, HIGH]` 生产级行情数据系统的成熟度由四个**正交维度**决定。任何一维不达标，系统就不可声明"生产级"。

### 1.1 四维 SLA 模型

| 维度                       | 定义                                                   | 核心问题         | binance 对应 FR                       |
| -------------------------- | ------------------------------------------------------ | ---------------- | ------------------------------------- |
| **Freshness（时效性）**    | `event_time → persist/fanout` 的端到端延迟             | "数据有多新？"   | FR-029, FR-014                        |
| **Completeness（完整性）** | 应采集的事件，实际采集/持久化的比例                    | "数据有没有丢？" | FR-004, FR-016~019, FR-026            |
| **Durability（持久性）**   | 已持久化数据在故障/重启/过期后可恢复的程度             | "数据会不会没？" | FR-005, FR-006d, FR-018, FR-027       |
| **Consistency（一致性）**  | 跨存储层（redis/taos/pg/ch）、跨时间窗口的数据是否自洽 | "数据对不对？"   | FR-005 幂等, FR-026 对账, FR-030 字段 |

`[KNOWN, HIGH]` 四维并非独立——它们有**因果链**：

- Freshness 下降 → 触发 stale alert → 应触发 Completeness 修复（backfill）
- Completeness 破缺（gap）→ 应触发 Consistency 对账（reconcile）
- Durability 不足（重启丢 cursor）→ 使 Completeness 永久受损
- **runtime 当前最大的问题：这条因果链多处断裂**（见 §2）

### 1.2 三级成熟度模型

`[COMPUTED, HIGH]` 每个维度按实现深度分四级，用 binance 实证锚定：

| 级别        | 含义                                            | binance 实证锚点                                                                              |
| ----------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **L0 缺失** | 规格定义但 runtime 零实现                       | replay job（全链路无）；taosx retention 删除（`taos_writer.go` 无删除能力）                   |
| **L1 检测** | 能发现违约，但无动作                            | `quality.go:66` `IncGapDetected`（gap 检测）；`sla_window.go:80` `staleCount++`（stale 计数） |
| **L2 告警** | 检测后主动告警（metrics/alert/webhook）         | `metrics.go:428` `SetGapRepairRequired`（设 Prometheus gauge，**但无告警消费方**）            |
| **L3 自愈** | 检测后自动触发修复（replay/backfill/reconcile） | **全链路零实现**（6 个 P0 缺口实证，见 §2）                                                   |

`[COMPUTED, HIGH]` **binance 当前整体处于 L1（检测）成熟度，局部 L2（告警指标已设但无消费），L3（自愈）完全空白。** 这与"生产级"的差距是**系统性的**，不是单点 bug。

### 1.3 生产级门禁（SLO 目标）

`[KNOWN, HIGH]` 参照交易所级行情数据系统实践，binance 要达到"生产级"应满足以下 SLO。这些数值大部分 SPEC.md §17 已定义，这里归并到 SLA 框架。

| SLO                            | 目标                        | SPEC 出处       | 当前实证状态                       |
| ------------------------------ | --------------------------- | --------------- | ---------------------------------- |
| Freshness P99（event→persist） | < 200ms                     | §17             | SLO benchmark 24/24 PASS ✅        |
| Freshness P99（event→fanout）  | < 300ms                     | §17             | 同上 ✅                            |
| Stale alert 阈值               | spot/um/cm 30s，options 60s | §17             | 计数实现 ✅，**告警动作 ❌**（G1） |
| Gap 检测窗口                   | MaxEventGap 2min            | `server.go:83`  | 检测 ✅，**修复 ❌**（G2/G3）      |
| 幂等去重窗口                   | 72h                         | `server.go:80`  | RedisStore ✅                      |
| natsx at-least-once            | 0 丢失                      | FR-004          | JetStream PubAck/Nak ✅            |
| 覆盖率（不应丢的事件）         | ≥ 99.99%（4 个 9）          | 生产级要求      | **无度量、无 SLA** ❌              |
| 历史数据可恢复性               | 重启后 cursor 不丢          | FR-016/019      | **纯内存，重启丢** ❌（G4）        |
| 对账容差                       | 0.01%                       | FR-026 / AC-091 | **对账未真实执行** ❌（G5）        |
| 冷数据可回热                   | OSS→taosx rehydrate         | FR-027          | 代码存在，**未接线** ❌（G9）      |

`[COMPUTED, HIGH]` **10 项 SLO 中 5 项未达成（全在 Completeness/Durability/Consistency 三维），3 项部分达成。** Freshness 维度达标，这也是为什么"实时链路看起来能跑"——但生产级要求的是四维全过。

---

## 2. 三链路缺口全景（因果链断裂图）

`[COMPUTED, HIGH]` 经 Explore agent 在 runtime 逐条核查，确认 **9 个缺口**（6 P0 + 3 P1）。它们不是孤立 bug，而是一条**本应贯通的因果链**上的断点：

```
[事件到达] ──Freshness 检测──✅──> SLA 计数
                                    │
                                    ▼ stale 超阈值
                              [断点❶ G1] stale alert 无动作（只计数不告警）
                                    │
                                    ▼ 应触发
                              [断点❷ G2] 断流无自动 backfill
                                    │
[Gap 检测] ──✅──> RepairRequired=true ──> [断点❸ G2] gap 标志无消费方（不生成 replay）
                                    │
                                    ▼ 应触发
                              [断点❹ G3] replay job 零实现
                                    │
[持久化成功] ──✅──> taosx 写入 ──> [断点❺ G6] taosx retention 无删除（热数据只增不减）
                                    │
                                    ▼ 超期应迁移
                              [断点❻ G7] OSS 归档是 30s batch（非定时迁移语义）
                                    │
[DLQ 入队] ──in-memory──> [断点❼ G8] FileWriter 未接线（重启丢死信）
                                    │
                                    ▼ 应可 replay
                              [断点❽ G8] DLQ replay runbook 未接线
                                    │
[每日对账] ──cron 04:00──> [断点❾ G5] reconcile 只入 task 队列（无真实数据比对）
                                    │
                                    ▼ 应触发
                              [断点❿ G9] 冷数据 rehydrate 未接线
```

`[INFERRED, HIGH]` **最严重的结构性问题**：检测能力（L1）和告警能力（L2 局部）已大量铺设，但**修复能力（L3）几乎为零**。这意味着系统能"知道数据出问题"，但不能"自动把数据修好"。生产级系统必须具备 L3 自愈，否则需要 7×24 人工介入。

### 缺口优先级矩阵

| ID  | 缺口                    | 链路      | SLA 维度               | 当前级别 | 生产级目标 | 优先级 | 详细位置                                              |
| --- | ----------------------- | --------- | ---------------------- | -------- | ---------- | ------ | ----------------------------------------------------- |
| G1  | stale alert 无触发动作  | 实时      | Freshness→Completeness | L1       | L2         | **P0** | [实时分报告 §2.1](data-maturity-realtime-20260625.md) |
| G2  | gap→修复链路断裂        | 实时+历史 | Completeness           | L1       | L3         | **P0** | [实时分报告 §2.2](data-maturity-realtime-20260625.md) |
| G3  | replay job 零实现       | 历史      | Completeness           | L0       | L3         | **P0** | [历史分报告 §2.1](data-maturity-history-20260625.md)  |
| G4  | backfill cursor 纯内存  | 历史      | Durability             | L0       | L3         | **P0** | [历史分报告 §2.2](data-maturity-history-20260625.md)  |
| G5  | reconcile 无真实对账    | 历史      | Consistency            | L1       | L3         | **P1** | [历史分报告 §2.3](data-maturity-history-20260625.md)  |
| G6  | taosx retention 无删除  | 存储      | Durability             | L0       | L2         | **P0** | [存储分报告 §2.1](data-maturity-storage-20260625.md)  |
| G7  | OSS 归档语义错位        | 存储      | Durability             | L1       | L3         | **P1** | [存储分报告 §2.2](data-maturity-storage-20260625.md)  |
| G8  | DLQ FileWriter 未接线   | 实时+历史 | Durability             | L1       | L3         | **P0** | [实时分报告 §2.3](data-maturity-realtime-20260625.md) |
| G9  | 冷数据 rehydrate 未接线 | 历史+存储 | Durability             | L0       | L3         | **P1** | [存储分报告 §2.3](data-maturity-storage-20260625.md)  |

`[COMPUTED, HIGH]` **6 个 P0 + 3 个 P1**。P0 是"生产级最低门槛"（不修无法上线），P1 是"生产级成熟度"（修了才算达标）。

---

## 3. 总体成熟度评分

`[COMPUTED, HIGH]` 用 §1.1 四维模型 × §1.2 四级模型，给 binance 三链路打分（满分 3.0 = L3）：

| 链路     | Freshness  | Completeness | Durability | Consistency | 加权总分 |  等级  |
| -------- | :--------: | :----------: | :--------: | :---------: | :------: | :----: |
| 实时数据 | 2.5（L2+） |  0.8（L1-）  | 1.0（L1）  | 1.5（L1+）  | **1.5**  | 预生产 |
| 历史数据 |     —      |  0.3（L0+）  | 0.5（L0+） | 0.5（L0+）  | **0.4**  | 实验级 |
| 数据存储 | 1.5（L1+） |  1.0（L1）   | 0.8（L1-） | 1.5（L1+）  | **1.2**  | 预生产 |

> 评分依据见三份分报告的逐项证据。加权 = 有效维度均值，历史链路无 Freshness（历史数据非实时），取三维均值并折算到四维。

`[COMPUTED, HIGH]` **综合判定：binance 当前是"预生产"（Preview）级系统**。实时链路时效性达标但完整性/持久性弱；历史链路基本处于"实验级"（检测能力缺失，重启即丢状态）；存储链路有基础设施但缺生命周期管理。距离"生产级"（三链路均 ≥2.0）还需要补齐 9 个缺口，工作量评估见 §4。

---

## 4. 生产级路线图

`[COMPUTED, HIGH]` 按"先闭合因果链 → 再建生命周期 → 最后规模化"三阶段推进。每阶段产出可独立验收。

### 阶段一：闭合因果链（P0，预计 2-3 个 sprint）

**目标**：让"检测→告警→修复"链路贯通，数据出问题能自愈。

| 工作项                 | 缺口  | 产出                                                       | 验收                                |
| ---------------------- | ----- | ---------------------------------------------------------- | ----------------------------------- |
| stale alert 接线       | G1    | stale 超阈值 → 发 natsx alert subject + 写 alerts 表       | 断流 30s 内触发告警                 |
| gap→replay 桥接        | G2+G3 | RepairRequired=true → 生成 ReplayJob → 调 backfill fetcher | gap 2min 内自动入队修复             |
| backfill cursor 持久化 | G4    | HistoryRuntime 状态持久化到 postgresx                      | 重启后 cursor 不丢                  |
| DLQ FileWriter 接线    | G8    | appendDeadLetter 同时写 FileWriter（JSONL）                | 死信重启可读                        |
| taosx retention 删除   | G6    | 定时任务删 taosx 超期数据 + DB KEEP 配置                   | tick 30d/bar 365d/depth 3d 自动过期 |

### 阶段二：建生命周期（P1，预计 2 个 sprint）

**目标**：数据从采集到归档到回热的完整闭环。

| 工作项               | 缺口 | 产出                                               | 验收                          |
| -------------------- | ---- | -------------------------------------------------- | ----------------------------- |
| OSS 归档语义修正     | G7   | 从 30s batch 改为定时扫描 taosx 超期数据→迁移→删热 | 与 SPEC §11.2.7 cron 语义一致 |
| reconcile 真实对账   | G5   | 04:00 UTC 真实比对 taosx vs Binance klines         | 容差 0.01% 超标写 alerts 表   |
| 冷数据 rehydrate API | G9   | OSS→taosx 回热 + 202 job_id 轮询                   | 冷查询触发回热并最终返回数据  |

### 阶段三：规模化与规范化（P2，预计 1-2 个 sprint）

**目标**：体系化、标准化，达成生产级 SLO。

| 工作项            | 产出                             | 验收                                                   |
| ----------------- | -------------------------------- | ------------------------------------------------------ |
| SLA 仪表盘        | 四维 SLO 实时可视化              | Freshness/Completeness/Durability/Consistency 全可观测 |
| 覆盖率度量        | "应采集 vs 实际采集" 比率指标    | 覆盖率 ≥ 99.99%（4 个 9）有度量                        |
| 全链路 chaos 测试 | 模拟断流/重启/存储故障           | 故障注入下数据 0 丢失                                  |
| runbook 文档化    | stale/gap/DLQ/reconcile 运维手册 | 每类故障有标准处置流程                                 |

---

## 5. 标准化与规范化建议

`[COMPUTED, HIGH]` 除了补缺口，还需建立以下"标准"，否则修完的缺口会因缺乏约束而回退：

### 5.1 SLA 驱动的 FR 演进标准

`[KNOWN, HIGH]` 当前 FR 的 Done/Partial 判定是"代码存在 + main.go 装配"。生产级应升级为**SLA 驱动**：

| 状态                  | 含义                     | 生产级门禁      |
| --------------------- | ------------------------ | --------------- |
| **L0（Draft）**       | 仅规格登记               | 不可上线        |
| **L1（Detected）**    | 能检测违约（代码存在）   | 标 Partial      |
| **L2（Alerted）**     | 检测后主动告警（有动作） | 标 Partial      |
| **L3（Self-healed）** | 检测后自动修复（闭环）   | **才可标 Done** |

`[INFERRED, HIGH]` 按此标准，当前 24 个 Done FR 中，**只有边界治理类（BR-001~009 / FR-009）真正达标**，其余功能 FR（尤其 Completeness/Durability 相关）应回退为 Partial。

### 5.2 数据完整性审计标准

`[KNOWN, HIGH]` 生产级行情系统必须有**可证明的完整性**，不能"声称完整"：

- **每日 reconcile**：taosx 数据 vs Binance 权威源对账（容差 0.01%）
- **gap 修复证据**：每个被检测的 gap 必须有对应 replay job 的成功证据
- **覆盖率仪表盘**：实时展示"应采集事件数 / 实际采集事件数"
- **DLQ 审计**：死信必须有 replay runbook，定期清零

### 5.3 存储生命周期标准

`[KNOWN, HIGH]` 四层存储（redis/taos/pg/ch/oss）应有统一的生命周期治理：

| 层          | 角色        | 生命周期                       | 删除责任           | 当前状态     |
| ----------- | ----------- | ------------------------------ | ------------------ | ------------ |
| redisx      | 热缓存+幂等 | 5s~72h TTL                     | Redis 自动过期     | ✅ 已实现    |
| taosx       | 热时序      | tick 30d / bar 365d / depth 3d | **模块定时任务删** | ❌ G6 未实现 |
| clickhousex | OLAP        | 聚合数据长期保留               | TTL 表达式         | ❌ 无 TTL    |
| ossx        | 冷归档      | 长期（按合规）                 | `PurgeExpired`     | ✅ 已实现    |

`[COMPUTED, HIGH]` 当前只有 redis 和 oss 有删除机制，**taosx 和 clickhousex 的生命周期是空白的**——热数据只增不减，最终会撑爆磁盘。

### 5.4 检测→告警→修复契约标准

`[KNOWN, HIGH]` 每一个"检测"必须有对应的"告警"和"修复"契约，三者缺一不可：

| 检测            | 当前告警           | 当前修复     | 契约要求                            |
| --------------- | ------------------ | ------------ | ----------------------------------- |
| stale（断流）   | ❌ 只计数          | ❌ 无        | 告警 → 触发 backfill                |
| gap（事件间断） | ⚠️ 设 gauge 无消费 | ❌ 无        | 告警 → 生成 ReplayJob               |
| DLQ 入队        | ⚠️ metrics         | ❌ 无 replay | 告警 → runbook 处置                 |
| reconcile 差异  | ❌ 无              | ❌ 无        | 告警 → 写 alerts 表 + 触发 backfill |

---

## 6. 关键依赖与风险

`[COMPUTED, HIGH]` 路线图执行需注意以下依赖与风险：

| 风险                                           | 概率 | 影响 | 缓解                                                           |
| ---------------------------------------------- | :--: | :--: | -------------------------------------------------------------- |
| FR-032（exchangeInfo 6h 刷新）是 G4/G5 的前置  | HIGH | HIGH | 阶段一优先推进 FR-032，否则 backfill/reconcile 无 catalog 基础 |
| taosx retention 删除（G6）误删生产数据         | MED  | 严重 | 删除前必须校验 OSS ETag（SPEC FR-006d 已定义，需严格执行）     |
| gap→replay 桥接（G2+G3）可能引入重复写入       | MED  | MED  | replay 必须复用幂等 key（FR-005），redisx SetNX 兜底           |
| DLQ replay 可能重放已过期事件                  | LOW  | MED  | replay 前校验事件 EventTime 是否在 StaleThreshold 内           |
| 全链路 chaos 测试需要真实 Binance testnet 凭据 | HIGH | MED  | 阶段三依赖合约/期权 testnet 凭据闭合（G7 issue 范围）          |
| 路线图跨度 5-7 sprint，期间 runtime 持续演进   | MED  | MED  | 每阶段独立验收，不阻塞已达成维度（如 Freshness）               |

---

## 7. 结论

`[COMPUTED, HIGH]` binance 模块**规格治理达到了罕见的高成熟度**（30 FR / 104 AC / 13 boundary gate / SLA 滑动窗口已建），runtime 在 Freshness 维度已达标（SLO benchmark 24/24 PASS）。但要达到**生产级**，必须从"检测优先"转向"自愈优先"，补齐因果链上的 9 个断点（6 P0 + 3 P1）。

**核心判断**：这不是"修几个 bug"，而是**补建一整套数据完整性保障体系**。建议以本报告的 SLA 框架（四维 × 四级）作为后续 FR 演进的判定标准，让每一个缺口修复都锚定到明确的 SLO，而非主观的"代码看起来写完了"。

**三阶段推进**：阶段一闭合因果链（P0，2-3 sprint）→ 阶段二建生命周期（P1，2 sprint）→ 阶段三规模化规范化（P2，1-2 sprint）。详细方案见三份分报告。

---

`[RULES I BROKE]`：

1. **§20 反奉承红旗**：§1 和 §7 对现有规格治理给出"罕见的高成熟度"等正面评价。这些评价有实证锚点（30 FR/104 AC/13 gate 可复现），但读者应警惕正面评价同样需要权威。我已尽量用数字锚定，避免无依据的赞美。
2. **§20 事后分析**：§2 的因果链图是在知道各缺口后归纳的。它是对现状的描述，不能当作"规格框架本身有缺陷"的预测证据。框架质量（规格层）与实现完整度（runtime 层）是独立的——因果链断裂是 runtime 实现断层，不是规格设计错误。
3. **§20 FRAME→REALITY**：§1.2 的四级模型和 §3 的评分是 `[FRAME]` 性质的评估框架（L0/L1/L2/L3 是我构造的分类）。我已用 runtime 实证锚定每一级，但"L3=生产级"本身是行业惯例映射（`[KNOWN]`），非 binance 内部既定标准。若团队有不同分级标准，应替换。
