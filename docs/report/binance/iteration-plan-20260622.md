# Binance 模块完整更新迭代方案

- [COMPUTED, HIGH] 制定日期：2026-06-22
- [COMPUTED, HIGH] 输入来源：`docs/report/binance/` 全部 5 份报告（v1/v2/v3/v4 + business-types）+ 本轮纳入的治理/漂移 issue（#866~#873、#879~#896）+ `module/binance/` 治理文件基线
- [COMPUTED, HIGH] 目标：把分散在 5 份报告中的发现收敛为单一执行计划，并同步到 GitHub issues，形成可追溯的迭代 backlog
- [COMPUTED, HIGH] 2026-06-23 执行已同步 `module/binance/` 治理文件；本文件保留规划轨迹并记录本地关闭口径。

---

## 一、报告发现收敛矩阵

> 5 份报告的去重合并视图。每行 = 一个独立可执行项。

| ID | 来源报告 | 问题 | 严重性 | 已有 issue | 状态 |
|---|---|---|:---:|:---:|:---:|
| G-01 | v3 P0§1 | README root Spec-Version v2.2.0 → v2.2.2 漂移 | 🔴 P0 | #867 | CLOSED(local) |
| G-02 | v3 P0§2 | RUNTIME-MAPPING NATS 4×4 矩阵缺 3 个 trade 组合 | 🔴 P0 | #866 | CLOSED(local) |
| G-03 | v3 P0§3 | Kafka topic 旧式 `binance.market.*` 未收敛到 `binance.{pl}.{et}.v1` | 🔴 P0 | #868 | CLOSED(local) |
| G-04 | v3 P0§4 | RULES.md 任务文件名引用错误（kafkax-export/ossx-archive） | 🔴 P0 | #873 | CLOSED(local) |
| G-05 | v3 P0§5 | 状态口径未分层（文档门禁 vs 运行证据） | 🔴 P0 | #872 | CLOSED(local) |
| G-06 | v3 P1§1-4 | 缺文档一致性检查脚本 `scripts/check-binance-docs.sh` | 🟡 P1 | #870 | CLOSED(local) |
| G-07 | v3 P2 | 运行证据链缺失（runtime 仓未提交变更 + 无 boundary/test 输出） | 🟡 P2 | #869 | LOCAL-EVIDENCE CLOSED |
| G-08 | v3 §标准 | 薄层 `STANDARD.md` 标准入口（P0/P1 收敛后启动） | 🟢 P3 | #871 | CLOSED(local) |
| G-09 | v2 P1 | DEEP-ANALYSIS §0 分布式约束未升入 SPEC §4 顶部 | 🟢 P2 | #893 | CLOSED(local) |
| G-10 | v2 P2 | DEEP-ANALYSIS 62KB 体量过大，§12 旧代码审计应移 migrations/ | 🟢 P2 | #894 | CLOSED(local) |
| G-11 | v2 P2 | legacy `binance-market` 30+ 处描述应压缩 | 🟢 P2 | #895 | CLOSED(local) |
| G-12 | v2 P1 | 50 个 preserve/stash 类 commit 覆盖审计未做 | 🟢 P3 | #896 | PARTIAL(local audit) |
| **R-01** | **v4 P0 实时控制面** | **Symbol Discovery & Filtering（FR-012）** | 🔴 P0 | #880 | DATA-LIFECYCLE draft(local) |
| **R-02** | **v4 P0 实时控制面** | **WebSocket Connection Policy（FR-013）** | 🔴 P0 | #881 | DATA-LIFECYCLE draft(local) |
| **R-03** | **v4 P0 实时控制面** | **Bar Interval Subscription Set（FR-014）** | 🔴 P0 | #882 | DATA-LIFECYCLE draft(local) |
| **R-04** | **v4 P0 实时控制面** | **Depth Snapshot Tier（FR-015）** | 🔴 P0 | #883 | DATA-LIFECYCLE draft(local) |
| **R-05** | **v4 P0 历史生命周期** | **Historical Backfill on Cold Start（FR-016）** | 🔴 P0 | #884 | DATA-LIFECYCLE draft(local) |
| **R-06** | **v4 P0 历史生命周期** | **Gap Detection & Fill（FR-017）** | 🔴 P0 | #885 | DATA-LIFECYCLE draft(local) |
| **R-07** | **v4 P0 历史生命周期** | **Backfill Throttle & Priority（FR-018）** | 🔴 P0 | #886 | DATA-LIFECYCLE draft(local) |
| **R-08** | **v4 P0 历史生命周期** | **Backfill Idempotency Key Strategy（FR-019）** | 🔴 P0 | #887 | DATA-LIFECYCLE draft(local) |
| **R-09** | **v4 P1 周期数据** | **Funding Rate / Mark Price Stream（FR-020）** | 🟡 P1 | #888 | CLOSED(local，v3.0.0 taxonomy fold) |
| **R-10** | **v4 P1 周期数据** | **Daily Reconciliation Job（FR-021）** | 🟡 P1 | #889 | DATA-LIFECYCLE draft(local) |
| **R-11** | **v4 P1 周期数据** | **Cold Data Rehydration（FR-022）** | 🟡 P1 | #890 | DATA-LIFECYCLE draft(local) |
| **R-12** | **v4 P2 治理** | **Backfill Progress API（FR-023）** | 🟢 P2 | #891 | DATA-LIFECYCLE draft(local) |
| **R-13** | **v4 P2 治理** | **Symbol Subscription Hot Reload（FR-024）** | 🟢 P2 | #892 | DATA-LIFECYCLE draft(local) |
| G-13 | v4 §七 | funding_rate/mark_price event_type 扩展触发 RULES R2 4×6 矩阵重算 + MAJOR bump | 🔴 P0 | #888 | CLOSED(local，随 FR-020 折叠进 v3.0.0) |
| G-14 | v4 §五 | 建议先建 `module/binance/DATA-LIFECYCLE.md` 讨论稿，再 fold 进 SPEC | 🟡 P1 | #879 | CLOSED(local discussion draft) |

**统计**：27 项。已纳入唯一 GitHub issue 26 个（#866~#873、#879~#896）；G-13 已并入 #888 本地关闭口径。

---

## 二、分阶段迭代路线

> 阶段划分依据：① 治理漂移优先于功能扩展 ② 文档控制面优先于 runtime 实施 ③ 每个 P0 阶段独立可收敛

### 阶段 0：治理漂移收敛（P0 文档面）

- **范围**：G-01 ~ G-05（#866~#873 中的 P0 子集）
- **目标**：版本元数据一致、R2 命名矩阵闭合、Kafka topic 收敛、任务引用可解析、状态口径分层
- **验证**：`scripts/check-binance-docs.sh`（G-06 落地后）全部 PASS
- **bump**：MINOR（subject/topic 枚举变更 + 状态语义扩展）
- **依赖**：无，可立即并行启动 5 个 PR

### 阶段 1：检查脚本 + 报告索引（P1）

- **范围**：G-06（#870 检查脚本）+ INDEX.md 补 v3/v4 条目
- **目标**：RULES R1-R10 转为可运行检查；报告索引完整
- **验证**：脚本本地 dry-run PASS；CI 集成方案出稿
- **依赖**：阶段 0 完成（脚本验证的前提是漂移已修）

### 阶段 2：数据生命周期讨论稿（v4 前置，P1）

- **范围**：G-14（#879 DATA-LIFECYCLE.md 讨论稿）
- **目标**：在不动 SPEC.md 的前提下，把 FR-012~FR-024 的 13 个 lifecycle 缺口整理成可评审讨论稿；G-13/FR-020 taxonomy fold 已进入 SPEC v3.0.0，后续只推进 remaining spec fold / runtime 实现
- **产出**：`module/binance/DATA-LIFECYCLE.md`
- **依赖**：无（纯讨论稿，不触发 bump）；建议阶段 0/1 并行

### 阶段 3：实时控制面 FR 补齐（P0 功能面）

- **范围**：R-01 ~ R-04（#880~#883，FR-012~015）
- **目标**：定义"采什么 / 怎么采 / 多深"
- **bump**：MINOR（新增 4 FR）；G-13/FR-020 已由 v3.0.0 taxonomy fold 关闭
- **依赖**：阶段 2 讨论稿定稿；阶段 0 漂移收敛（避免在漂移基线上叠新 FR）

### 阶段 4：历史数据生命周期 FR（P0 功能面）

- **范围**：R-05 ~ R-08（#884~#887，FR-016~019）
- **目标**：定义"从哪开始 / 缺了怎么办 / 幂等不双写 / 限速不打爆"
- **bump**：MINOR
- **依赖**：阶段 3（实时控制面定了 symbol/周期，历史回填才有锚点）

### 阶段 5：周期数据 + 对账（P1 功能面）

- **范围**：R-09~R-11（#888~#890，FR-020~022）；R-09/FR-020 已按 v3.0.0 taxonomy fold 本地关闭
- **目标**：补全量校验 + 冷数据可用
- **bump**：MINOR 或 PATCH（取决于 reconciliation / rehydration 是否扩展公开合同）；MAJOR taxonomy fold 已由 v3.0.0 承载
- **依赖**：阶段 4；不得回退 v3.0.0 的 4 × 6 event_type 矩阵

### 阶段 6：治理可观测 + 标准入口（P2/P3）

- **范围**：R-12（#891，FR-023 进度 API）+ R-13（#892，FR-024 热重载）+ G-08（#871 STANDARD.md）+ G-09/G-10/G-11（#893~#895 DEEP-ANALYSIS 重构）+ G-12（#896 commit 覆盖审计）
- **目标**：运维可见 + 可热配 + 模块标准入口 + 历史文档瘦身
- **依赖**：阶段 0~5 收敛后

### 阶段 7：runtime 证据链（P2，贯穿）

- **范围**：G-07（#869 运行证据）
- **目标**：runtime 仓形成可审查快照，boundary gates / go test / lint / smoke 全量输出，回填 TRACEABILITY
- **依赖**：与阶段 3~5 并行（runtime 实现跟随 FR 定义）；是 release DoD 的最终门禁

---

## 三、Issue 同步策略

### 3.1 已纳入 issue（26 个，不自动远程关闭）

#866~#873 覆盖 v3 治理漂移与 runtime 本地证据；#879 覆盖 DATA-LIFECYCLE 讨论稿；#880~#887、#889~#892 覆盖 FR-012~FR-019 与 FR-021~FR-024 的 lifecycle draft；#888 覆盖 FR-020/G-13 taxonomy fold；#893~#896 覆盖治理收尾项 G-09~G-12。

仅在明确授权后执行远端评论或关闭：
- #866/#867/#868/#872/#873 可附本地 drift 修复验证命令。
- #869 只能声明 local runtime evidence 已取得；release/live smoke 仍是外部门禁。
- #879~#887、#889~#892 仅能声明 discussion draft 已存在，不得声明 Approved SPEC 或 runtime 实现完成。
- #888 可声明 FR-020/G-13 已折叠进 SPEC v3.0.0 与 4×6 命名矩阵。
- #896 仍需权威 GitHub PR/head 谱系，不能只凭本地审计关闭。

### 3.2 待建 issue（0 个）

本轮报告收敛项已全部映射到 #866~#873 与 #879~#896。后续只有当 FR draft 进入实现或 Release DoD 时，才新建实现型 issue。

### 3.3 标签体系

为便于阶段过滤，建议给所有 binance issue 打标签：
- `module:binance` — 模块归属
- `P0` / `P1` / `P2` / `P3` — 优先级
- `phase-0-governance` ~ `phase-7-runtime` — 阶段归属
- `type:doc-drift` / `type:new-FR` / `type:tooling` / `type:runtime` — 变更类型

> [INFERRED, MED] 当前仓库 issue 无 label 体系（#866~#873 均 0 label）。本方案建议引入，但落地需仓库 owner 确认。

---

## 四、bump 路径与版本演进

```
当前: SPEC v3.0.0 / client v2.1.1 / server v2.1.0 / RULES v2.0.0 / NAMING v2.0.0

已纳入当前版本:
- 阶段 0/1: subject/topic 收敛、状态分层、检查脚本文档化。
- 阶段 2: DATA-LIFECYCLE discussion draft，无 SPEC bump。
- G-13/R-09/FR-020: SPEC v3.0.0 MAJOR taxonomy fold，event_type 4→6。

后续版本不得回退到 v2.x:
- 阶段 3: FR-012~015 fold 后使用 v3.0.0 之后的 next MINOR。
- 阶段 4: FR-016~019 fold 后使用 v3.0.0 之后的 next MINOR。
- 阶段 5: FR-021~022 视公开合同扩展范围使用 next MINOR 或 PATCH；FR-020 不再重复规划。
- 阶段 6: FR-023~024 若形成公开治理 API，使用 next MINOR；仅标准入口补文档时使用 PATCH。
```

> [COMPUTED, HIGH] RULES.md R3 规定 event_type 枚举变更触发 MAJOR。FR-020/G-13 已由 SPEC v3.0.0 承载，R2 4×N 矩阵已重算为 N=6、组合数 24；后续规划不得再把 4→6 当作待落地变更。

---

## 五、风险与停止条件

### 5.1 风险

- 🔴 **阶段 3 在阶段 0 未收敛时启动**：在漂移基线上叠新 FR，会让 #866/#868 的修复更难（subject/topic 表又要改一遍）。**必须阶段 0 先合并**
- 🔴 **v3.0.0 taxonomy 回退风险**：若后续文档或 runtime mapping 重新退回 4 类 event_type，或使用 `funding` 等旧混合命名替代 `funding_rate`/`mark_price`，RULES R2/R3 硬约束违规
- 🟡 **runtime 发布证据仍分层**（#869）：2026-06-23 从 `/home/binance` 重新取得 clean short status、boundary gates PASS 10/10、`go test ./...`、`go vet ./...`、race test 和 `golangci-lint run` 通过证据；Release DoD 仍需远端 CI、release tag、live smoke/deploy 证据。
- 🟡 **v5 报告丢失**（212 行清洗/处理缺口）：v4 已含 13 条 FR 核心结论，但 C1-C8 清洗缺口、P1-P7 处理问题、G1-G4 缺口分类的细节无法恢复；阶段 3/4 落地时需重新推导这部分细节

### 5.2 停止条件

- [COMPUTED, HIGH] 2026-06-23 team 后续执行已完成阶段 0、阶段 1、阶段 2 讨论稿、阶段 6 治理收口与 #869 本地 runtime 命令证据。
- [COMPUTED, HIGH] 当前 26 个 open issue 均已本地映射：#866~#873、#879、#888、#893~#895 达到本地关闭或本地证据口径；#896 保留 external lineage 缺口；#880~#887、#889~#892 保留 lifecycle draft / spec-fold / runtime 后续状态。
- [INFERRED, MED] 阶段 3+ 的 FR 实现和 Release DoD 仍不得因文档本地关闭而自动视为完成。

---

## 六、与现有 issue 的映射核对

| 现有 issue | 对应方案 ID | 阶段 | 一致性 |
|---|---|:---:|:---:|
| #867 README 版本漂移 | G-01 | 0 | ✅ |
| #866 NATS 4×4 缺 3 组合 | G-02 | 0 | ✅ |
| #868 Kafka topic 旧式 | G-03 | 0 | ✅ |
| #873 RULES 任务引用错误 | G-04 | 0 | ✅ |
| #872 状态口径分层 | G-05 | 0 | ✅ |
| #870 检查脚本 | G-06 | 1 | ✅ |
| #869 运行证据 | G-07 | 7 | ✅ local evidence |
| #871 STANDARD.md | G-08 | 6 | ✅ |
| #879 DATA-LIFECYCLE 讨论稿 | G-14 | 2 | ✅ |
| #880 Symbol Discovery & Filtering | R-01 | 3 | ✅ draft |
| #881 WebSocket Connection Policy | R-02 | 3 | ✅ draft |
| #882 Bar Interval Subscription Set | R-03 | 3 | ✅ draft |
| #883 Depth Snapshot Tier | R-04 | 3 | ✅ draft |
| #884 Historical Backfill on Cold Start | R-05 | 4 | ✅ draft |
| #885 Gap Detection & Fill | R-06 | 4 | ✅ draft |
| #886 Backfill Throttle & Priority | R-07 | 4 | ✅ draft |
| #887 Backfill Idempotency Key Strategy | R-08 | 4 | ✅ draft |
| #888 Funding Rate / Mark Price Stream | R-09 / G-13 | 5 | ✅ local taxonomy fold |
| #889 Daily Reconciliation Job | R-10 | 5 | ✅ draft |
| #890 Cold Data Rehydration | R-11 | 5 | ✅ draft |
| #891 Backfill Progress API | R-12 | 6 | ✅ draft |
| #892 Symbol Subscription Hot Reload | R-13 | 6 | ✅ draft |
| #893 DEEP-ANALYSIS §0 → SPEC §4 | G-09 | 6 | ✅ |
| #894 DEEP-ANALYSIS §12 → migrations/ | G-10 | 6 | ✅ |
| #895 legacy binance-market 压缩 | G-11 | 6 | ✅ |
| #896 preserve/stash commit 覆盖审计 | G-12 | 6 | ✅ local audit / ⚠️ external lineage pending |

**结论**：当前 26 个 open issue 全部映射成功；2026-06-23 本地执行后，#866~#873、#879、#888、#893~#895 达到本地关闭或本地证据口径，#896 保留外部 PR/head 谱系缺口，#880~#887 与 #889~#892 保留 lifecycle draft / spec-fold / runtime 后续状态。当前无待建 issue。

---

[RULES I BROKE]：无 — 原始方案是规划文档；2026-06-23 team 后续补记同步本地关闭状态，并将实际治理入口、审计产物、数据生命周期讨论稿和 #869 runtime evidence 记录在 `STANDARD.md`、`RULES.md` R9、`DATA-LIFECYCLE.md` 与 `docs/report/binance/governance-closure-20260623.md`。
