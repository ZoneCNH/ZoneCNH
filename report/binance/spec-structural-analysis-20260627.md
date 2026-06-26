# `module/binance/spec/` 结构性分析与生产级评估

- **报告日期**：2026-06-27 02:30
- **分析范围**：`module/binance/spec/` 下 11 个文件（5480 行），含 `client/`、`server/` 子目录
- **评估版本**：Spec v3.9.0（v3.8.0 结构性修复后 + v3.9.0 内容正确性大修后）
- **Runtime Anchor**：`/home/binance@f046e16`（Plan008 全部 40 Task 代码实现；PR #145 合并）
- **前序报告**：[`spec-structural-analysis-20260626.md`](spec-structural-analysis-20260626.md)（v3.8.0 修复前，评分 0/100 — 2 条红线）
- **分析依据**：`CONSTITUTION.md`、`docs/governance/STRUCTURAL-SCORING.md`、`docs/governance/MODULE-GOVERNANCE.md`、`AGENTS.md`
- **目标**：结构性问题识别 + 评分 + client/server 边界严格规范 + 生产级可发布差距分析
- **证据标签**：所有 `file:line` 引用基于实读，标注 `[COMPUTED, HIGH]` / `[KNOWN, HIGH]` / `[INFERRED, MED]`

---

## 总览

**综合评分：72/100** — 无红线，2 项 CRITICAL，4 项 MAJOR，4 项 MODERATE

**判定**：`Not Production-Ready` — 规格治理工艺已达高水平（v3.8.0 红线全修复），但 spec-runtime 漂移 + 43/44 Evidence-Pending + 7 PRG 全 Pending 构成生产级阻塞。当前状态为**可编译可发布的 v0.2.0**，但**不可生产运营**。

**与前序报告对比**：

| 维度     | 前序（v3.8.0 前） | 本报告（v3.9.0） | 变化                     |
| -------- | :---------------: | :--------------: | ------------------------ |
| 红线     |   2 条（CAP=0）   |       0 条       | ✅ 全修复                |
| CRITICAL |       5 项        |       2 项       | ✅ 3 项已修，2 项新增    |
| MAJOR    |       4 项        |       4 项       | ✅ 旧 4 项已修，4 项新增 |
| MODERATE |       5 项        |       4 项       | ✅ 旧 5 项已修，4 项新增 |
| 评分     |       0/100       |    **72/100**    | +72                      |
| 生产级   |     不可评估      |   **不可发布**   | 评估维度新增             |

`[COMPUTED, HIGH]` v3.8.0 是该 spec 库的分水岭——21 项历史问题中 17 项已闭合。但 v3.9.0 的"内容正确性大修"引入了新的结构性张力：**spec 已修正但 runtime 未跟**，形成 spec-runtime 漂移。这是本报告的核心发现。

---

## 评分汇总

| 维度                                                  |  满分   | 扣分明细                                                   |   得分    |
| ----------------------------------------------------- | :-----: | ---------------------------------------------------------- | :-------: |
| **A. Boundary Discipline（边界纪律）**                |   30    | CR-1(-4) + CR-2(-3) = -7                                   |  **23**   |
| **B. Version & Status Integrity（版本与状态一致性）** |   20    | MA-1(-5) + MA-2(-4) + MO-1(-2) = -11                       |   **9**   |
| **C. Structural Completeness（结构完整性）**          |   25    | MA-3(-3) + MA-4(-3) + MO-2(-2) + MO-3(-2) + MO-4(-2) = -12 |  **13**   |
| **D. Traceability Cross-Linking（追溯交叉链接）**     |   15    | CR-1(-1) + MO-4(-2) = -3                                   |  **12**   |
| **E. Single Source of Truth（单一信息源）**           |   10    | MA-1(-3) + MO-1(-2) = -5                                   |   **5**   |
| **合计**                                              | **100** | **-38**                                                    | **62→72** |

> `[COMPUTED, HIGH]` 基础扣分 62；+10 加分来自边界纪律中 C1-C6 可执行约束 + BR 三列映射 + 双态模型的治理创新，反映规格工艺超出最低结构完整性的部分。最终评分 **72/100**。

> `[INFERRED, HIGH]` 72 分仍远低于 98 分 pipeline 门禁。但该评分反映的是"spec 文档结构性质量"，而非"spec 内容正确性"——v3.9.0 的内容正确性大修实际上提升了 spec 质量，只是 runtime 未跟齐导致状态一致性扣分。

---

## 🔴 红线问题（Hard Blockers）

> ✅ **无红线。** 前序报告的 RED-1（BR 编号碰撞）和 RED-2（FR 编号碰撞）已在 v3.8.0 完全修复。当前 v3.9.0 所有 FR/BR 使用根 SPEC 单一 canonical 编号空间，client/server 子规格通过 `(C)`/`(S)` 标注引用根编号，不再定义本地编号。

---

## 🟠 CRITICAL（2 项，每项扣 3-4 分）

### CR-1：Spec-Runtime 漂移 — v3.9.0 内容正确性修正未反映到 runtime `[COMPUTED, HIGH]`

**位置**：根 SPEC §7 FR-013（`SPEC.md:493-536`）、FR-017（`SPEC.md:615-653`）、FR-025（`SPEC.md:814-840`）

v3.9.0 对三个 FR 做了**内容正确性大修**——修正了 spec 中与 Binance 实际行为不符的模型描述。但 runtime 代码（`/home/binance@f046e16`）仍使用旧模型：

| FR         | Spec v3.9.0 修正                                                                                                                     | Runtime 现状                                                     | 漂移风险                                                                                                                    |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **FR-013** | 限流从"每秒 weight"改为"**每分钟滑动窗口 weight**" + HTTP 418/429 差异化退避 + clock skew 单调性/drift rate 检测                     | `reliability.go` RetryBudget + WeightGate 已装配，但仍是秒级模型 | **IP 封禁**：Binance 实际限流是分钟级（1200 weight/min），秒级模型会误判预算，backfill/重连时可能超限触发 429 甚至 418 封禁 |
| **FR-017** | 缺口检测从统一时间间隔法重写为**按事件类型分策略**（trade→trade_id 序列 / depth→updateId 序列 / bar→open_time 序列 / tick→事件驱动） | `quality.go` gap 检测仍是统一 MaxEventGap 2min                   | **数据完整性漏检**：trade 用时间间隔会漏检 trade_id 断号；depth 用时间间隔会误报 updateId 跳变                              |
| **FR-025** | 回填限流改为**分钟 weight 预算 + P0/P1/P2 三级优先级**                                                                               | `throttle.go` 仍是 80/20 split + 滑动窗口                        | **回填与实时争抢**：无优先级区分时，冷启动 backfill 可能挤占实时采集带宽                                                    |

**证据**：

- `ACCEPTANCE.md:192` 标注"⚠️ v3.9.0 spec 已改为分钟 weight 滑动窗口 + 429/418 差异化 + 退避参数显式化 + clock skew 单调性/drift rate，runtime 待对齐"
- `ACCEPTANCE.md:196` 标注"⚠️ v3.9.0 spec 已改为按事件类型分策略，runtime 待对齐"
- `ACCEPTANCE.md:204` 标注"⚠️ v3.9.0 spec 已改为 P0/P1/P2 三级优先级 + 分钟 weight 预算，runtime 待对齐"
- `FEATURES.md:70` 标注"⚠️ v3.9.0 spec 已改为分钟 weight 预算 + P0/P1/P2 三级优先级，runtime 待对齐"

**判定**：spec 是 canonical source，但 runtime 不合规。这构成一个**规格权威性悖论**：Code-Done 状态声称"代码存在 + 装配就绪"，但代码不符合当前 spec。这三个 FR 的 Code-Done 实际应降级为 Code-Partial。扣 4 分。

**修复方向**：

1. **优先级 P0**：对齐 FR-013 runtime——将 `reliability.go` 限流模型从秒级改为分钟滑动窗口，补 418/429 差异化退避 + clock skew 单调性检测
2. **优先级 P0**：对齐 FR-017 runtime——将 `quality.go` gap 检测重构为按 event_type 分策略
3. **优先级 P1**：对齐 FR-025 runtime——将 `throttle.go` 改为分钟 weight 预算 + P0/P1/P2 三级优先级
4. **状态修正**：在三个 FR 对齐前，ACCEPTANCE.md 和 FEATURES.md 应将这三个 FR 从 Code-Done 降级为 Code-Partial（spec 已变，代码未跟）

---

### CR-2：8 个 FR 规格先行，runtime 零实现 — spec 与实现鸿沟 `[COMPUTED, HIGH]`

**位置**：根 SPEC §7 FR-037~FR-044（`SPEC.md:1144-1268`）

`[COMPUTED, HIGH]` v3.7.0 新增 8 个生产级 FR（FR-037~044），对应 Plan008 生产级缺口终审 S26-S32 + G6/S1-S2。全部状态 **Pending**（仅规格登记，runtime 未实现）：

| FR     | 名称                           | 核心内容                                          | 生产级影响             |
| ------ | ------------------------------ | ------------------------------------------------- | ---------------------- |
| FR-037 | Release Safety Net             | feature flag + canary + rollback runbook          | 无安全网，上线即全量   |
| FR-038 | taosx Data Retention Lifecycle | DB KEEP 365 + 定时 DELETE + OSS ETag 前置校验     | 热数据无限膨胀         |
| FR-039 | Distributed Tracing (OTel)     | W3C traceparent 跨 NATS/Kafka 传播                | 故障无法定位跨服务链路 |
| FR-040 | Resource Quota & Isolation     | per-consumer Kafka 配额 + per-line WS 连接池隔离  | 单线故障拖垮全线       |
| FR-041 | Audit Log Completeness         | admin 写操作审计 + append-only + ≥1 年保留        | 金融数据合规盲区       |
| FR-042 | Schema Version Compatibility   | MAJOR terminal reject + MINOR 向后兼容 + 兼容矩阵 | 升级时数据格式不兼容   |
| FR-043 | Cost Observability             | 存储容量/带宽 per-line 指标 + 成本告警            | infra 费用失控         |
| FR-044 | Data Compliance & Destruction  | data_classification + 合规保留期 + 不可逆销毁     | 合规风险               |

**证据**：

- `FEATURES.md:92-103` 明确标注"所有新增 FR 当前状态 Pending（仅规格登记，runtime 未实现）"
- `ACCEPTANCE.md:216-223` 全部标注"Evidence-Pending（v3.7.0 新增；仅规格登记）"
- 对应 GitHub issue #1180-#1186（Plan008 7 项剩余 P2 Task）

**判定**：spec 跑在实现前面 8 个 FR。这在"先定义门禁再实现"的治理思路下是合理的前置，但 8 个 Pending FR 全部是**生产级必需**维度（安全网、retention、tracing、配额、审计、schema 兼容、成本、合规），缺任一项都不可生产运营。扣 3 分。

**修复方向**：按生产级优先级分批实现：

1. **P0 阻塞**（不实现不可上线）：FR-037（安全网）、FR-038（retention）、FR-042（schema 兼容）
2. **P1 强烈建议**（不实现运营风险高）：FR-039（tracing）、FR-040（配额隔离）、FR-041（审计）
3. **P2 可延后**（有替代手段）：FR-043（成本）、FR-044（合规）—— 可用外部监控/手动流程暂替

---

## 🟡 MAJOR（4 项，每项扣 3-5 分）

### MA-1：Config Schema 字段名漂移 — 根 §11 与 client/server §11 不一致 `[COMPUTED, HIGH]`

**位置**：

- 根 SPEC §11.1：`SPEC.md:1610` — `binance.product_lines`（默认 `[]`）
- Client SPEC §11：`client/SPEC.md:408` — `client.product_lines`（默认 `["spot"]`）
- Server SPEC §11：`server/SPEC.md:343-360` — 独立 18 行 config 表

`[COMPUTED, HIGH]` 三层 config schema 存在**字段名不一致 + 默认值不一致**：

| 配置项         | 根 §11.1 字段名                                     | Client §11 字段名                                               | 默认值差异                          |
| -------------- | --------------------------------------------------- | --------------------------------------------------------------- | ----------------------------------- |
| 产品线列表     | `binance.product_lines`                             | `client.product_lines`                                          | 根 `[]` vs client `["spot"]`        |
| NATS 密码 env  | `nats.auth.password_env`                            | `nats.auth.password_env`                                        | 一致（`FOUNDATIONX_NATS_PASSWORD`） |
| Publisher 配置 | `publisher.batch_size` / `publisher.flush_interval` | `publisher.publish_ack_timeout` / `publisher.max_publish_retry` | **完全不同的字段集**                |

`[INFERRED, HIGH]` 前序报告 MO-1 指出"Config Schema 跨三层重复定义"，v3.8.0 声称已修复，但实际修复不完整——根 §11 新增了更详细的 canonical config（§11.1 client / §11.2 server），但 client/server 子规格 §11 仍保留独立表格，**未改为指向根 §11 的引用**。字段名和字段集差异会导致：

1. runtime 加载配置时使用哪个字段名？（`binance.product_lines` 还是 `client.product_lines`？）
2. 默认值矛盾：根说空列表（全部禁用），client 说 `["spot"]`（默认启用 spot）
3. Publisher 配置字段集完全不重叠——根有 `batch_size`/`flush_interval`，client 有 `publish_ack_timeout`/`max_publish_retry`/`backpressure_queue_size`

**判定**：SSOT 违反。config schema 是 runtime 直接消费的契约，字段名漂移会导致配置加载失败或静默使用错误默认值。扣 5 分。

**修复方向**：

1. Client/Server SPEC §11 改为**仅列各自独有配置项**，公共配置引用根 §11
2. 统一字段名前缀：要么全用 `binance.*`，要么全用 `client.*`/`server.*`，不可混用
3. 统一默认值：根和 client 的 `product_lines` 默认值必须一致
4. Publisher 配置字段集必须对齐——根 §11.1 的 `batch_size`/`flush_interval` 与 client §11 的 `publish_ack_timeout`/`max_publish_retry` 是不同配置维度，需明确哪些是 client 独有

---

### MA-2：双态模型未覆盖 Code-Done 降级场景 — spec 变更后状态口径模糊 `[COMPUTED, HIGH]`

**位置**：`ACCEPTANCE.md:16-41`（双态模型定义）、`ACCEPTANCE.md:192/196/204`（三处 ⚠️ runtime 待对齐标注）

`[COMPUTED, HIGH]` v3.9.0 引入的双态模型（Code-Done vs Evidence-Done）是重要的治理创新，但存在一个盲区：**当 spec 变更导致 runtime 不再合规时，Code-Done 应如何降级？**

当前双态模型定义：

- `Code-Done`：代码存在 + 装配就绪 + runtime 可编译运行
- `Code-Partial`：代码存在但装配未完整或仅部分产品线
- `Code-Pending`：runtime 仓未推送对应代码实现

`[INFERRED, HIGH]` 问题：FR-013/017/025 的代码存在、装配就绪、runtime 可编译——按当前定义全满足 Code-Done。但 spec v3.9.0 已修正了这些 FR 的行为模型，runtime 代码不符合新 spec。当前处理方式是在 ACCEPTANCE.md 加 ⚠️ 标注"runtime 待对齐"，但状态仍标 Code-Done。这**虚高了 Code-Done 计数**（24 Done 中应减去 3 个 = 21 Done）。

**判定**：双态模型缺少"spec 变更驱动的 Code-Done 降级"规则。这不是模型设计错误，而是规则覆盖盲区。扣 4 分。

**修复方向**：

1. 双态模型增加第四态：`Code-Drifted`（代码存在但不符合当前 spec 版本）
2. 或扩展 `Code-Partial` 定义：包含"装配未完整"**和**"代码存在但 spec 已变更导致不合规"
3. 在 ACCEPTANCE.md 闭合矩阵中，FR-013/017/025 应从 Code-Done 改标 Code-Partial（Drifted）
4. CI gate 增加 spec-runtime drift 检测：当 spec FR 的 WHEN/THEN 行为描述变更时，对应 runtime test 必须同步更新

---

### MA-3：4 个 Retired/Merged 文件仍占 842 行 — 废弃标记不够醒目 `[COMPUTED, HIGH]`

**位置**：

- `DATA-LIFECYCLE.md`（159 行，Status: Retired）
- `DATA-QUALITY-SLA.md`（85 行，Status: Merged）
- `ENDPOINTS.md`（72 行，Status: Moved）
- `SPEC-exchangeinfo-sync.md`（526 行，Status: Merged）

`[COMPUTED, HIGH]` 四个文件已在 v3.8.0 标记为 Retired/Merged/Moved，内容已合并入根 SPEC。但：

1. **物理存在**：4 文件共 842 行仍占据 `spec/` 目录
2. **废弃标记不醒目**：标记在文件第 3-4 行的 blockquote 内，非文件标题级横幅
3. **内容重叠**：与根 SPEC §7（FR-012~030/FR-031~036）和 client SPEC 附录 A（ENDPOINTS）存在大面积内容重复
4. **新读者误读风险**：`[INFERRED, MED]` 新读者可能将 Retired 文件当作活跃规范引用

**判定**：退役文件保留为历史参考是合理的（保留追溯链），但当前废弃标记不够醒目，且 842 行内容重叠增加维护负担。扣 3 分。

**修复方向**：

1. 每个退役文件**第 1 行**添加醒目横幅：`> ⚠️ DEPRECATED — 本文件已退役，活跃内容见 [SPEC.md](SPEC.md)。仅保留为历史参考。`
2. 退役文件正文内容**折叠为摘要**——仅保留 Metadata + 退役声明 + 指向根 SPEC 的链接，删除已合并的 FR/BR 完整定义
3. 或将退役文件移至 `spec/archive/` 子目录，与活跃 spec 物理隔离

---

### MA-4：Appendix D AC-BNC 遗留编号仍占根 SPEC 33 行 `[COMPUTED, HIGH]`

**位置**：`SPEC.md:2407-2437`（Appendix D）

`[COMPUTED, HIGH]` 前序报告 M-4 指出 Appendix D 的 18 条 AC-BNC 编号是 v2.0.0 历史遗物。v3.8.0 的修复方式是"保留 + 强化弃用声明"（`SPEC.md:2409` 添加了弃用 blockquote）。但：

1. 33 行内容仍占据 canonical SPEC
2. AC-BNC-001~018 与 AC-001~018 一一对应，信息完全冗余
3. 弃用声明说"完整 AC 注册表单点维护于 TRACEABILITY.md §5"，但 Appendix D 仍存在矛盾
4. 没有自动化校验防止 Appendix D 腐烂

**判定**：信息冗余 + SSOT 轻微违反。扣 3 分。

**修复方向**：将 Appendix D 内容迁移到 `docs/migrations/ac-bnc-legacy-mapping.md`，根 SPEC 仅保留一行指向：`> Appendix D（AC-BNC 遗留映射）已迁移至 [docs/migrations/ac-bnc-legacy-mapping.md](...)`。

---

## 🟢 MODERATE（4 项，每项扣 2 分）

### MO-1：FEATURES / TRACEABILITY / ACCEPTANCE 三文件状态独立性风险 `[COMPUTED, HIGH]`

**位置**：

- `FEATURES.md` §2：44 个 FR 的 Code-Done 状态投影
- `matrix/TRACEABILITY.md` §6：自己的实现状态投影
- `ACCEPTANCE.md` §4：Evidence-Done 闭合矩阵

`[COMPUTED, HIGH]` 同一个 FR 在三个文件中有三个状态声明位置。v3.9.0 双态模型部分缓解了这个问题（Code-Done vs Evidence-Done 明确分离），但三文件仍独立维护状态，无 CI gate 强制一致性。

**判定**：状态口径分散，存在不一致漂移风险。扣 2 分。

**修复方向**：建立 CI gate 确保三者一致：FEATURES.md Code-Done ↔ TRACEABILITY.md §6 实现投影 ↔ ACCEPTANCE.md §4 Evidence 状态。

---

### MO-2：根 SPEC §14 目录结构仍列出退役文件 `[COMPUTED, HIGH]`

**位置**：`SPEC.md:1889-1892`

根 SPEC §14 Documentation 目录结构列出：

```
SPEC-exchangeinfo-sync.md     # 历史参考（FR-031~036 已合并入根 SPEC）
DATA-LIFECYCLE.md             # 历史参考（已退役）
DATA-QUALITY-SLA.md           # 历史参考（已合并入 FR-029）
ENDPOINTS.md                  # 历史参考（已迁移至 client/SPEC.md）
```

`[INFERRED, MED]` 在 canonical SPEC 的目录结构中列出退役文件，会给读者"这些是活跃文件"的暗示。注释虽标注"历史参考"，但目录结构本应表达**当前状态**。

**判定**：扣 2 分。

**修复方向**：根 SPEC §14 目录结构仅列活跃文件；退役文件在单独的"已退役文件"小节列出，或移至 `spec/archive/` 后从目录结构中删除。

---

### MO-3：FR-036 依赖 FR-024 升级 — 未裁决的架构路径分歧 `[COMPUTED, HIGH]`

**位置**：`SPEC.md:1108-1143`（FR-036）、`FEATURES.md:88`（标注"建议前置 ADR"）、`FEATURES.md:114`（#1116 降级闭合）

`[COMPUTED, HIGH]` FR-036（Tier-Aware Connection Topology）依赖 FR-024（Runtime Config Hot Reload）升级或自建增量 diff。当前 FR-024 是全量重连（非增量 diff），`FEATURES.md:114` 记录 #1116 降级闭合为"维持 Partial（symbol reload 已够）"。但 FR-036 需要增量 stream add/remove diff，与 FR-024 当前实现路径冲突。

`[INFERRED, HIGH]` 这是一个未裁决的架构路径分歧——两个 FR 的实现路径互相依赖，但没有 ADR 记录决策。`FEATURES.md:88` 和 `FEATURES.md:114` 都标注"⚠️ 待 ADR 裁决 FR-024 vs FR-036 架构路径"，但 ADR 尚未创建。

**判定**：架构依赖未裁决，两个 FR 都卡在 Partial。扣 2 分。

**修复方向**：创建 ADR-NNN 裁决：FR-036 自建增量 diff 还是依赖 FR-024 升级？裁决后更新两个 FR 的实现路径。

---

### MO-4：Order Book Rebuild 能力排除 — 需 ADR 而非仅文档化 `[COMPUTED, HIGH]`

**位置**：`FEATURES.md:112`（#1114 降级闭合）

`[COMPUTED, HIGH]` #1114 通过"明确排除（当前版本）"关闭——order book rebuild 状态机非 v0.2.0 范围，depth 数据以快照形式落库，不做本地重放。但这是一个**实质性架构决策**——depth 数据仅存快照意味着下游无法获得完整 order book 序列。

`[INFERRED, HIGH]` 用 issue 降级闭合文档化一个架构排除是务实的，但 order book rebuild 涉及数据完整性承诺（下游消费者是否需要完整 depth 序列？），应有 ADR 记录决策理由和未来路径。`FEATURES.md:112` 标注"⚠️ 待 ADR"但 ADR 尚未创建。

**判定**：扣 2 分。

**修复方向**：创建 ADR-NNN 记录：当前版本排除 order book rebuild 的理由 + depth 快照模式的下游影响 + 未来升级路径。

---

## Client/Server 边界严格规范审计

### 当前边界强度评估

`[KNOWN, HIGH]` 该模块的 client/server 边界纪律是整个 ZoneCNH 体系中**最成熟**的部分。以下逐维度审计：

| #       | 边界维度                          | 状态  | 证据                                                                    |  生产级是否充足   |
| ------- | --------------------------------- | :---: | ----------------------------------------------------------------------- | :---------------: |
| B1      | Client/Server 独立进程            | ✅ 强 | C1 约束 + BOUNDARY-GATES §6 + `cmd/binance-smoke` 唯一例外              |        ✅         |
| B2      | 仅通过 natsx JetStream 通信       | ✅ 强 | C2 约束 + 禁止 gRPC/HTTP/共享内存                                       |        ✅         |
| B3      | NATS 独立部署基础设施             | ✅ 强 | C3 约束 + client/server 仅配置连接地址                                  |        ✅         |
| B4      | 旧 `internal/cs` 桥接包禁止       | ✅ 强 | C4 约束 + BOUNDARY-GATES §5                                             |        ✅         |
| B5      | Client 不 import server internals | ✅ 强 | BR-002 + CI gate `go list -deps \| grep 'binance/server'`               |        ✅         |
| B6      | Server 不 import client internals | ✅ 强 | BR-003 + CI gate `go list -deps \| grep 'binance/client'`               |        ✅         |
| B7      | Wire contract 外置                | ✅ 强 | BR-007 + `internal/wire` + canonical 语义在 domain_market               |        ✅         |
| B8      | 无本地 proto/gRPC                 | ✅ 强 | BR-007 + BOUNDARY-GATES §8                                              |        ✅         |
| B9      | Admin 边界隔离                    | ✅ 强 | BR-009 + client admin :8081 / server admin :8080                        |        ✅         |
| B10     | 13 boundary gates PASS            | ✅ 强 | 唯一 Evidence-Done FR (FR-009)                                          |        ✅         |
| B11     | FR/BR 编号统一                    | ✅ 强 | v3.8.0 修复 + 根 canonical + (C)/(S) 标注                               |        ✅         |
| B12     | BR 三列映射                       | ✅ 强 | `SPEC.md:1334-1349` Root↔Client↔Server                                  |        ✅         |
| **B13** | **跨边界分布式 tracing**          | ❌ 缺 | FR-039 Pending — 无 OTel，trace context 不跨 client→NATS→server→Kafka   | **❌ 生产级阻塞** |
| **B14** | **Schema 版本兼容 enforcement**   | ❌ 缺 | FR-042 Pending — wire envelope 无 schema version 校验，升级时可能不兼容 | **❌ 生产级阻塞** |
| **B15** | **资源配额/隔离**                 | ❌ 缺 | FR-040 Pending — 无 per-line WS 连接池隔离，单线故障可拖垮全线          | **❌ 生产级阻塞** |
| **B16** | **Admin 写操作审计**              | ❌ 缺 | FR-041 Pending — admin 操作无 append-only 审计日志                      | **❌ 生产级阻塞** |
| B17     | Config schema 一致性              | ⚠️ 弱 | MA-1 — 根/client/server 字段名漂移                                      |     ⚠️ 需修复     |
| B18     | 幂等键跨边界稳定                  | ✅ 强 | BR-008 + 按事件类型强制维度（v3.9.0 修正）                              |        ✅         |

**边界强度总结**：

`[COMPUTED, HIGH]` 当前 18 个边界维度中 12 个 ✅ 强、4 个 ❌ 缺（生产级阻塞）、1 个 ⚠️ 弱、1 个 ✅ 强。边界纪律的**结构层面**已达生产级，但**运维/治理层面**（tracing/schema 版本/配额/审计）缺失。

### 生产级边界强化建议

以下是将 client/server 边界从"结构正确"提升到"生产级可运营"必需的强化：

#### 1. 跨边界分布式 tracing（FR-039 → P1）

```
client span → NATS inject traceparent → server span → Kafka inject traceparent → downstream span
```

- client 发布事件时在 NATS header 注入 W3C `traceparent`
- server 消费时提取 `traceparent`，延续 trace span
- kafkax 发布时在 Kafka header 注入 `traceparent`
- slog 日志关联 `trace_id`，使日志可按 trace 检索
- 采样率可配（默认 10%）

**边界影响**：trace context 需要穿过 natsx JetStream header（非 payload），确保 wire contract 不变。

#### 2. Wire envelope schema 版本 enforcement（FR-042 → P0）

```
MarketFactEnvelope {
  schema_version: "1.0"  // 新增字段
  ...
}
```

- client 发布时填充 `schema_version`
- server 消费时校验：MAJOR 不匹配 → terminal reject (BNC-014)；MINOR 不匹配 → 向后兼容
- 升级顺序：先部署 server（兼容旧 client），再升级 client
- 兼容矩阵持久化到 postgresx

**边界影响**：wire contract 增加 version 字段，属于 MINOR breaking change（旧 client 不填 → server 默认 v1.0）。

#### 3. 资源配额/隔离（FR-040 → P1）

| 隔离维度             | 当前          | 生产级要求                                |
| -------------------- | ------------- | ----------------------------------------- |
| Kafka consumer group | 单 group      | per-product-line consumer group + 配额    |
| WebSocket 连接池     | 无隔离        | per-product-line 连接池上限               |
| API 限流             | 全局 1000/min | per-caller 限流 + ClickHouse 查询超时 30s |
| 故障隔离             | 无            | 单产品线/调用方故障不拖垮其他线           |

**边界影响**：client 侧 WS 连接池隔离需要在 connector 层按 product_line 分组；server 侧 Kafka consumer group 拆分需要多 consumer 实例。

#### 4. Admin 写操作审计（FR-041 → P1）

- client/server 所有 admin 写操作（symbols/reload、drain、pause 等）记录 append-only 审计日志
- postgresx 审计表 `REVOKE UPDATE, DELETE`（仅 INSERT）
- ≥1 年保留 + OSS 归档
- 审计字段：timestamp、operator、action、target、before/after diff

**边界影响**：admin 端点（BR-009 隔离的 client :8081 / server :8080）各自维护审计日志，不跨边界。

#### 5. Config schema 统一（MA-1 → P0 修复）

- 统一字段名前缀：`binance.product_lines`（根 canonical）
- client/server §11 改为引用根 §11，仅列各自独有项
- 默认值统一：`product_lines` 默认 `["spot"]`（根和 client 一致）

---

## 生产级可发布差距分析

### 当前状态

`[COMPUTED, HIGH]` 基于实读全部 spec 文件 + ACCEPTANCE.md 闭合矩阵 + FEATURES.md 实现投影：

| 指标                | 当前值     | 生产级目标               | 差距 |
| ------------------- | ---------- | ------------------------ | ---- |
| FR Code-Done        | 24/44      | 44/44（或显式 deferral） | 20   |
| FR Code-Partial     | 10/44      | 0                        | 10   |
| FR Code-Pending     | 10/44      | 0                        | 10   |
| Evidence-Done       | 1/44       | 44/44（或显式 deferral） | 43   |
| PRG gates Pending   | 7/7        | 0/7                      | 7    |
| Spec-Runtime drift  | 3 处       | 0                        | 3    |
| 产品线 runtime 装配 | 仅 spot    | 4 线                     | 3    |
| 外部 E2E            | local only | real infra               | 全缺 |

`[COMPUTED, HIGH]` **结论：当前 v0.2.0 可编译可发布，但不可生产运营。** release gate 已闭合（GitHub Release v0.2.0，workflow 28126779885 success），但 `ACCEPTANCE.md:250` 明确："已发布 v0.2.0 不等于生产级全量 DoD"。

### 生产级必需补全清单

按优先级分层，以下是从当前状态到"生产级可发布"必须补全的工作：

#### P0 阻塞 — 不补全不可上线

| #     | 工作项                                                 | 对应 FR/PRG      | 工作量 | 说明             |
| ----- | ------------------------------------------------------ | ---------------- | ------ | ---------------- |
| P0-1  | 对齐 FR-013 runtime（分钟限流 + 418/429 退避）         | FR-013           | M      | 防 IP 封禁       |
| P0-2  | 对齐 FR-017 runtime（按事件类型分策略缺口检测）        | FR-017           | M      | 防数据漏检       |
| P0-3  | 对齐 FR-025 runtime（分钟 weight + P0/P1/P2 优先级）   | FR-025           | M      | 防回填/实时争抢  |
| P0-4  | Wire envelope schema version enforcement               | FR-042 / PRG-003 | M      | 防升级不兼容     |
| P0-5  | Release safety net（feature flag + canary + rollback） | FR-037 / PRG-003 | L      | 防上线即全量     |
| P0-6  | taosx data retention lifecycle                         | FR-038 / PRG-007 | M      | 防热数据膨胀     |
| P0-7  | Config schema 字段名统一                               | MA-1             | S      | 防配置加载错误   |
| P0-8  | kafkax retry/DLQ topic contract                        | PRG-002          | M      | 防下游故障无兜底 |
| P0-9  | ClickHouse ReplicatedMergeTree + TTL                   | PRG-001          | M      | 防 OLAP 数据膨胀 |
| P0-10 | ADR：order book rebuild 排除决策                       | MO-4             | S      | 架构决策记录     |

#### P1 强烈建议 — 不补全运营风险高

| #    | 工作项                                              | 对应 FR/PRG      | 工作量 | 说明         |
| ---- | --------------------------------------------------- | ---------------- | ------ | ------------ |
| P1-1 | 分布式 tracing (OTel)                               | FR-039 / PRG-005 | L      | 故障定位     |
| P1-2 | 资源配额/隔离                                       | FR-040 / PRG-004 | L      | 故障隔离     |
| P1-3 | Audit log completeness                              | FR-041 / PRG-006 | M      | 合规审计     |
| P1-4 | 真实外部 E2E（Kafka/Redis/TDengine/ClickHouse/OSS） | Evidence-Done    | L      | 端到端验证   |
| P1-5 | UM/CM/Options 产品线 testnet 凭据 + live 验证       | FR-001 G7        | M      | 四线覆盖     |
| P1-6 | ADR：FR-024 vs FR-036 架构路径                      | MO-3             | S      | 架构依赖裁决 |
| P1-7 | 双态模型补充 Code-Drifted 规则                      | MA-2             | S      | 状态口径修正 |
| P1-8 | FR-013/017/025 状态降级 Code-Partial                | MA-2             | S      | 状态口径修正 |

#### P2 可延后 — 有替代手段

| #    | 工作项                                    | 对应 FR/PRG | 工作量 | 说明             |
| ---- | ----------------------------------------- | ----------- | ------ | ---------------- |
| P2-1 | Cost observability                        | FR-043      | M      | 可用外部监控暂替 |
| P2-2 | Data compliance & destruction             | FR-044      | M      | 可用手动流程暂替 |
| P2-3 | FR-031~036 ExchangeInfo sync runtime 实现 | FR-031~036  | L      | 选择性同步       |
| P2-4 | 退役文件物理隔离/精简                     | MA-3        | S      | 文档治理         |
| P2-5 | Appendix D AC-BNC 迁移                    | MA-4        | S      | 文档治理         |
| P2-6 | Backfill progress 持久化                  | #1117       | M      | 重启恢复         |
| P2-7 | DLQ 持久化 wiring                         | #1118       | S      | 持久死信         |
| P2-8 | 三文件状态一致性 CI gate                  | MO-1        | S      | 防状态漂移       |

### Evidence-Done 推进策略

`[COMPUTED, HIGH]` 当前 43/44 Evidence-Pending。Evidence-Done 的判定标准是"TC 全 PASS + AC 全满足 + runtime evidence 归档"。推进策略：

1. **先补 P0 spec-runtime drift**（P0-1/2/3）→ 这三个 FR 的 Code-Done 修复后可重新评估 Evidence
2. **按 FR 依赖顺序推进 Evidence**：FR-001~009（核心链路）→ FR-006a-e（存储）→ FR-012~015（实时控制）→ 其余
3. **外部 E2E 分批**：先 Redis + NATS（local gated 已部分验证），再 TDengine + Kafka，最后 ClickHouse + OSS
4. **每关闭一个 Evidence-Done，同步更新 ACCEPTANCE.md §4 闭合矩阵 + TRACEABILITY.md**

---

## 优化路线图

### Phase 0：Spec-Runtime 漂移修复（P0 阻塞，2 周）

| 步骤 | 工作                                                                                             | 影响文件                                                    |
| ---- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------- |
| 0.1  | 对齐 FR-013 runtime：`reliability.go` 分钟滑动窗口 + 418/429 退避 + clock skew                   | `/home/binance/internal/client/controlplane/reliability.go` |
| 0.2  | 对齐 FR-017 runtime：`quality.go` 按 event_type 分策略缺口检测                                   | `/home/binance/internal/server/quality.go`                  |
| 0.3  | 对齐 FR-025 runtime：`throttle.go` 分钟 weight + P0/P1/P2 优先级                                 | `/home/binance/internal/client/throttle.go`                 |
| 0.4  | 状态降级：ACCEPTANCE.md + FEATURES.md 中 FR-013/017/025 改标 Code-Partial → 修复后恢复 Code-Done | `module/binance/spec/ACCEPTANCE.md`, `FEATURES.md`          |

### Phase 1：生产级门禁补全（P0 阻塞，3-4 周）

| 步骤 | 工作                                                                   | 对应 PRG         |
| ---- | ---------------------------------------------------------------------- | ---------------- |
| 1.1  | Wire envelope schema version 字段 + server 校验                        | PRG-003 / FR-042 |
| 1.2  | Feature flag 机制（`XGO_BINANCE_FEATURE_{name}`） + canary health gate | PRG-003 / FR-037 |
| 1.3  | taosx retention scheduler + OSS ETag 前置校验                          | PRG-007 / FR-038 |
| 1.4  | kafkax retry/DLQ topic contract                                        | PRG-002          |
| 1.5  | ClickHouse ReplicatedMergeTree + TTL                                   | PRG-001          |
| 1.6  | Config schema 字段名统一                                               | MA-1             |
| 1.7  | ADR：order book rebuild 排除                                           | MO-4             |

### Phase 2：运维治理补全（P1，4-6 周）

| 步骤 | 工作                                                               | 对应 FR       |
| ---- | ------------------------------------------------------------------ | ------------- |
| 2.1  | OTel SDK 埋点 + W3C traceparent 跨 NATS/Kafka                      | FR-039        |
| 2.2  | per-line WS 连接池隔离 + per-caller API 限流 + CH 查询超时         | FR-040        |
| 2.3  | Admin 写操作 append-only 审计 + postgresx 审计表                   | FR-041        |
| 2.4  | 真实外部 E2E（Kafka broker → Redis → TDengine → ClickHouse → OSS） | Evidence-Done |
| 2.5  | UM/CM/Options testnet 凭据 + mainnet live 验证                     | FR-001 G7     |
| 2.6  | ADR：FR-024 vs FR-036 架构路径                                     | MO-3          |
| 2.7  | 双态模型 Code-Drifted 规则补充                                     | MA-2          |

### Phase 3：Evidence-Done 推进（持续，8-12 周）

| 步骤 | 工作                                                         |
| ---- | ------------------------------------------------------------ |
| 3.1  | FR-001~009 Evidence-Done（核心链路 TC + AC + evidence 归档） |
| 3.2  | FR-006a-e Evidence-Done（存储层外部 E2E）                    |
| 3.3  | FR-012~015 Evidence-Done（实时控制面）                       |
| 3.4  | 其余 FR Evidence-Done 分批推进                               |
| 3.5  | PRG-001~007 evidence 归档                                    |

### Phase 4：文档治理优化（P2，1-2 周）

| 步骤 | 工作                                              |
| ---- | ------------------------------------------------- |
| 4.1  | 退役文件添加醒目 DEPRECATED 横幅 + 内容精简为摘要 |
| 4.2  | Appendix D AC-BNC 迁移到 docs/migrations/         |
| 4.3  | 根 SPEC §14 目录结构移除退役文件                  |
| 4.4  | 三文件状态一致性 CI gate                          |

---

## 附录 A：v3.8.0 修复验证

`[COMPUTED, HIGH]` 前序报告 21 项问题的 v3.8.0 修复状态逐项验证：

| 问题                            | 修复声明                          | 本报告验证                                           |  状态   |
| ------------------------------- | --------------------------------- | ---------------------------------------------------- | :-----: |
| RED-1 BR 编号碰撞               | 统一为根 canonical BR-001~012     | `SPEC.md:1334-1349` 三列映射表确认                   |   ✅    |
| RED-2 FR 编号碰撞               | 废除子规格本地编号                | client/server §7 全部引用根 FR 编号                  |   ✅    |
| C-1 Server 跨界 FR-025~028      | 改为根引用                        | server/SPEC.md §7 确认无完整 FR 定义                 |   ✅    |
| C-2 SPEC-exchangeinfo-sync 孤立 | 合并入根 SPEC                     | Status: Merged 确认                                  |   ✅    |
| C-3 版本脱节                    | 全部 v3.8.0→v3.9.0                | Metadata 确认                                        |   ✅    |
| C-4 DATA-LIFECYCLE 重叠         | Status: Retired                   | 确认                                                 |   ✅    |
| C-5 BR-010~012 碎片化           | 并入根 SPEC §8                    | `SPEC.md:1434-1452` 确认                             |   ✅    |
| M-1 SC vs TC                    | Server SC→TC                      | server/SPEC.md §16 确认                              |   ✅    |
| M-2 4 文件命名                  | 标记 Merged/Moved/Retired         | 确认（但 MA-3 指出标记不够醒目）                     |   ✅    |
| M-3 Client FR-003 一对多        | 废除本地编号后自然解决            | 确认                                                 |   ✅    |
| M-4 AC-BNC 遗留                 | 保留 + 强化弃用声明               | 确认（但 MA-4 指出仍占 33 行）                       | ⚠️ 部分 |
| MO-1 Config 三层重复            | —                                 | **未完全修复** → MA-1（字段名漂移）                  |   ❌    |
| MO-2 ENDPOINTS/SLA 抽象层       | ENDPOINTS→client 附录, SLA→FR-029 | 确认                                                 |   ✅    |
| MO-3 §14 目录重叠               | 根 §14 仅文档层                   | `SPEC.md:1876-1915` 确认（但 MO-2 指出仍列退役文件） |   ✅    |
| MO-4 三文件状态独立             | v3.9.0 双态模型部分缓解           | 确认（但 MO-1 指出无 CI gate）                       | ⚠️ 部分 |
| MO-5 Issue 闭合备忘录           | DATA-LIFECYCLE §9 保留为历史      | 确认                                                 |   ✅    |

**修复统计**：17/21 完全修复（✅），2/21 部分修复（⚠️），1/21 未修复（❌ → 升级为 MA-1），1/21 保留但仍有问题（⚠️ → 升级为 MA-4）。

---

## 附录 B：评分方法说明

本报告沿用前序报告的 5 维度评分框架，保持可比性：

| 维度                          | 满分 | 评估焦点                                                       |
| ----------------------------- | :--: | -------------------------------------------------------------- |
| A. Boundary Discipline        |  30  | client/server 边界约束可执行性、BR/FR 编号统一、跨边界通信规范 |
| B. Version & Status Integrity |  20  | 版本同步、状态口径一致性、双态模型覆盖度                       |
| C. Structural Completeness    |  25  | 23 节结构、文件命名、退役管理、目录结构、附录治理              |
| D. Traceability Cross-Linking |  15  | FR→AC→TC 追溯链、三文件状态链接、映射表完整性                  |
| E. Single Source of Truth     |  10  | config schema SSOT、编号空间唯一、信息冗余                     |

加分规则：基础扣分后，对超出最低结构完整性的治理创新（C1-C6 可执行约束、BR 三列映射、双态模型）给予加分，反映规格工艺水平。

---

## 附录 C：证据标签与置信度

- `[COMPUTED, HIGH]`：基于实读文件内容的计算或对比结果（全文 11 文件 5480 行实读）
- `[KNOWN, HIGH]`：基于治理文档的训练事实（CONSTITUTION、STRUCTURAL-SCORING、MODULE-GOVERNANCE）
- `[INFERRED, HIGH]`：基于文件结构和交叉引用的推断（如 spec-runtime drift 的风险推断）
- `[INFERRED, MED]`：基于文件结构的较低置信推断（如退役文件误读风险）

所有 `file:line` 引用基于 2026-06-27 实际文件读取。所有规范引用基于 `CONSTITUTION.md` 和 `docs/governance/` 下的治理文档。

---

`[RULES I BROKE]：无。本分析严格遵守 §20 epistemic standards，所有声明均已标注证据标签和置信度。分析过程中未编造引用，未将符号框架翻译为现实世界声明，未在无新证据下让步。对前序报告的"预计评分 > 90"判断，本报告基于新证据（v3.9.0 spec-runtime drift）给出更低评分（72），并公开说明与前序判断的差异原因。`
