# Binance 模块完整更新迭代方案

> [COMPUTED, HIGH] **2026-06-23 闭环状态**：本方案中的 27 项 backlog + 19 个待建 issue 已全部落地并关闭（PR #910，GitHub open count = 0）。正文中"待建 issue"字样为 2026-06-22 规划时状态，实际 issue 编号为 #866~#896（含 #869）。逐 issue 最终状态、证据与残留动作见 [`issues-full-closure-20260623.md`](issues-full-closure-20260623.md)。候选 FR-025~028（Backfill Throttle/Daily Reconciliation/Cold Rehydration/Progress API）未 fold 进 SPEC 为 PR #910 历史口径；post-PR #936/current module docs have since folded FR-025~028 into SPEC/TRACEABILITY/NAMING and added FR-029/030. See `pr-936-governance-docs-closure-20260623.md`.

> [COMPUTED, HIGH] 下文表格中的 `OPEN` / `待建 issue` / `4×4` 均为 2026-06-22 规划快照，不是 post-PR #936/current-docs 当前状态。

- [COMPUTED, HIGH] 制定日期：2026-06-22
- [COMPUTED, HIGH] 输入来源：`docs/report/binance/` 全部 5 份报告（v1/v2/v3/v4 + business-types）+ 现有 8 个开放 issue（#866~#873）+ `module/binance/` 治理文件基线
- [COMPUTED, HIGH] 目标：把分散在 5 份报告中的发现收敛为单一执行计划，并同步到 GitHub issues，形成可追溯的迭代 backlog
- [INFERRED, HIGH] 不修改任何 `module/binance/` 受保护治理文件；本方案是规划文档，落地由各 issue 独立 PR 执行

---

## 一、报告发现收敛矩阵

> 5 份报告的去重合并视图。每行 = 一个独立可执行项。

| ID       | 来源报告               | 问题                                                                                | 严重性 | 已有 issue |           状态           |
| -------- | ---------------------- | ----------------------------------------------------------------------------------- | :----: | :--------: | :----------------------: |
| G-01     | v3 P0§1                | README root Spec-Version v2.2.0 → v2.2.2 漂移                                       | 🔴 P0  |    #867    |           OPEN           |
| G-02     | v3 P0§2                | RUNTIME-MAPPING NATS 4×4 矩阵缺 3 个 trade 组合                                     | 🔴 P0  |    #866    |           OPEN           |
| G-03     | v3 P0§3                | Kafka topic 旧式 `binance.market.*` 未收敛到 `binance.{pl}.{et}.v1`                 | 🔴 P0  |    #868    |           OPEN           |
| G-04     | v3 P0§4                | RULES.md 任务文件名引用错误（kafkax-export/ossx-archive）                           | 🔴 P0  |    #873    |           OPEN           |
| G-05     | v3 P0§5                | 状态口径未分层（文档门禁 vs 运行证据）                                              | 🔴 P0  |    #872    |           OPEN           |
| G-06     | v3 P1§1-4              | 缺文档一致性检查脚本 `scripts/check-binance-docs.sh`                                | 🟡 P1  |    #870    |           OPEN           |
| G-07     | v3 P2                  | 运行证据链缺失（runtime 仓未提交变更 + 无 boundary/test 输出）                      | 🟡 P2  |    #869    |           OPEN           |
| G-08     | v3 §标准               | 薄层 `STANDARD.md` 标准入口（P0/P1 收敛后启动）                                     | 🟢 P3  |    #871    |           OPEN           |
| G-09     | v2 P1                  | DEEP-ANALYSIS §0 分布式约束未升入 SPEC §4 顶部                                      | 🟢 P2  |     —      |        待建 issue        |
| G-10     | v2 P2                  | DEEP-ANALYSIS 62KB 体量过大，§12 旧代码审计应移 migrations/                         | 🟢 P2  |     —      |        待建 issue        |
| G-11     | v2 P2                  | legacy `binance-market` 30+ 处描述应压缩                                            | 🟢 P2  |     —      |        待建 issue        |
| G-12     | v2 P1                  | 50 个 preserve/stash 类 commit 覆盖审计未做                                         | 🟢 P3  |     —      |        待建 issue        |
| **R-01** | **v4 P0 实时控制面**   | **Symbol Discovery & Filtering（FR-012）**                                          | 🔴 P0  |     —      |      **待建 issue**      |
| **R-02** | **v4 P0 实时控制面**   | **WebSocket Connection Policy（FR-013）**                                           | 🔴 P0  |     —      |      **待建 issue**      |
| **R-03** | **v4 P0 实时控制面**   | **Bar Interval Subscription Set（FR-014）**                                         | 🔴 P0  |     —      |      **待建 issue**      |
| **R-04** | **v4 P0 实时控制面**   | **Depth Snapshot Tier（FR-015）**                                                   | 🔴 P0  |     —      |      **待建 issue**      |
| **R-05** | **v4 P0 历史生命周期** | **Historical Backfill on Cold Start（FR-016）**                                     | 🔴 P0  |     —      |      **待建 issue**      |
| **R-06** | **v4 P0 历史生命周期** | **Gap Detection & Fill（FR-017）**                                                  | 🔴 P0  |     —      |      **待建 issue**      |
| **R-07** | **v4 P0 历史生命周期** | **Backfill Throttle & Priority（FR-018）**                                          | 🔴 P0  |     —      |      **待建 issue**      |
| **R-08** | **v4 P0 历史生命周期** | **Backfill Idempotency Key Strategy（FR-019）**                                     | 🔴 P0  |     —      |      **待建 issue**      |
| **R-09** | **v4 P1 周期数据**     | **Funding Rate / Mark Price Stream（FR-020）**                                      | 🟡 P1  |     —      |        待建 issue        |
| **R-10** | **v4 P1 周期数据**     | **Daily Reconciliation Job（FR-021）**                                              | 🟡 P1  |     —      |        待建 issue        |
| **R-11** | **v4 P1 周期数据**     | **Cold Data Rehydration（FR-022）**                                                 | 🟡 P1  |     —      |        待建 issue        |
| **R-12** | **v4 P2 治理**         | **Backfill Progress API（FR-023）**                                                 | 🟢 P2  |     —      |        待建 issue        |
| **R-13** | **v4 P2 治理**         | **Symbol Subscription Hot Reload（FR-024）**                                        | 🟢 P2  |     —      |        待建 issue        |
| G-13     | v4 §七                 | event_type 枚举 4→6（加 funding/mark_price）触发 RULES R2 4×N 矩阵重算 + MAJOR bump | 🔴 P0  |     —      | 待建 issue（伴随 R-09）  |
| G-14     | v4 §五                 | 建议先建 `module/binance/DATA-LIFECYCLE.md` 讨论稿，再 fold 进 SPEC                 | 🟡 P1  |     —      | 待建 issue（R 系列前置） |

**统计**：27 项。已有 issue 8 项（#866~#873）；待建 issue 19 项（v2 收尾 4 + v4 新增 13 + v4 治理 2）。

---

## 二、分阶段迭代路线

> 阶段划分依据：① 治理漂移优先于功能扩展 ② 文档控制面优先于 runtime 实施 ③ 每个 P0 阶段独立可收敛

### 阶段 0：治理漂移收敛（P0 文档面）

- **范围**：G-01 ~ G-05（#866~#873 中的 P0 子集）
- **目标**：版本元数据一致、4×4 矩阵闭合、Kafka topic 收敛、任务引用可解析、状态口径分层
- **验证**：`scripts/check-binance-docs.sh`（G-06 落地后）全部 PASS
- **bump**：MINOR（subject/topic 枚举变更 + 状态语义扩展）
- **依赖**：无，可立即并行启动 5 个 PR

### 阶段 1：检查脚本 + 报告索引（P1）

- **范围**：G-06（#870 检查脚本）+ INDEX.md 补 v3/v4 条目
- **目标**：RULES R1-R10 转为可运行检查；报告索引完整
- **验证**：脚本本地 dry-run PASS；CI 集成方案出稿
- **依赖**：阶段 0 完成（脚本验证的前提是漂移已修）

### 阶段 2：数据生命周期讨论稿（v4 前置，P1）

- **范围**：G-14（DATA-LIFECYCLE.md 讨论稿）
- **目标**：在不动 SPEC.md 的前提下，把 v4 的 15 个缺口（6 实时 + 9 历史）整理成可评审讨论稿，定稿后再一次性 fold 进 SPEC §7
- **产出**：`module/binance/DATA-LIFECYCLE.md`
- **依赖**：无（纯讨论稿，不触发 bump）；建议阶段 0/1 并行

### 阶段 3：实时控制面 FR 补齐（P0 功能面）

- **范围**：R-01 ~ R-04（FR-012~015）+ G-13（event_type 4→6 MAJOR bump 评估）
- **目标**：定义"采什么 / 怎么采 / 多深"
- **bump**：MINOR（新增 4 FR）；若 G-13 同期落地则 MAJOR
- **依赖**：阶段 2 讨论稿定稿；阶段 0 漂移收敛（避免在漂移基线上叠新 FR）

### 阶段 4：历史数据生命周期 FR（P0 功能面）

- **范围**：R-05 ~ R-08（FR-016~019）
- **目标**：定义"从哪开始 / 缺了怎么办 / 幂等不双写 / 限速不打爆"
- **bump**：MINOR
- **依赖**：阶段 3（实时控制面定了 symbol/周期，历史回填才有锚点）

### 阶段 5：周期数据 + 对账（P1 功能面）

- **范围**：R-09（FR-020 funding/mark_price）+ R-10（FR-021 对账）+ R-11（FR-022 冷数据回热）
- **目标**：补非事件性周期数据 + 全量校验 + 冷数据可用
- **bump**：MAJOR（event_type 枚举扩展，RULES R3）
- **依赖**：阶段 4；G-13 在此阶段必须落地

### 阶段 6：治理可观测 + 标准入口（P2/P3）

- **范围**：R-12（FR-023 进度 API）+ R-13（FR-024 热重载）+ G-08（STANDARD.md）+ G-09/G-10/G-11（DEEP-ANALYSIS 重构）+ G-12（commit 覆盖审计）
- **目标**：运维可见 + 可热配 + 模块标准入口 + 历史文档瘦身
- **依赖**：阶段 0~5 收敛后

### 阶段 7：runtime 证据链（P2，贯穿）

- **范围**：G-07（#869 运行证据）
- **目标**：runtime 仓形成可审查快照，boundary gates / go test / lint / smoke 全量输出，回填 TRACEABILITY
- **依赖**：与阶段 3~5 并行（runtime 实现跟随 FR 定义）；是 release DoD 的最终门禁

---

## 三、Issue 同步策略

### 3.1 已有 issue（8 个，保持不动）

#866~#873 已覆盖 v3 全部 P0~P3 + v2 运行证据。仅在以下情况更新：

- 阶段 0 完成时，给 #866/#867/#868/#872/#873 加 `closed-by PR #XXX` 评论
- #870 检查脚本落地后，反哺 #866~#873 的验证命令

### 3.2 待建 issue（19 个，2026-06-22 历史规划口径）

**v2 收尾（4 个，P2~P3）**：

- DEEP-ANALYSIS §0 升入 SPEC §4（G-09）
- DEEP-ANALYSIS §12 迁移到 migrations/（G-10）
- legacy `binance-market` 压缩（G-11）
- 50 commit 覆盖审计（G-12）

**v4 前置（1 个，P1）**：

- DATA-LIFECYCLE.md 讨论稿（G-14）

**v4 实时控制面（4 个，P0）**：

- FR-012 Symbol Discovery（R-01）
- FR-013 WebSocket Connection Policy（R-02）
- FR-014 Bar Interval Subscription Set（R-03）
- FR-015 Depth Snapshot Tier（R-04）

**v4 历史生命周期（4 个，P0）**：

- FR-016 Historical Backfill（R-05）
- FR-017 Gap Detection & Fill（R-06）
- FR-018 Backfill Throttle & Priority（R-07）
- FR-019 Backfill Idempotency Key Strategy（R-08）

**v4 周期数据（3 个，P1）**：

- FR-020 Funding Rate / Mark Price Stream（R-09，含 G-13 event_type 扩展）
- FR-021 Daily Reconciliation Job（R-10）
- FR-022 Cold Data Rehydration（R-11）

**v4 治理（2 个，P2）**：

- FR-023 Backfill Progress API（R-12）
- FR-024 Symbol Subscription Hot Reload（R-13）

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
当前: SPEC v2.2.2 / client v2.1.1 / server v2.1.0 / RULES v1.0.0

阶段 0 完成: SPEC v2.3.0 (MINOR, subject/topic 收敛 + 状态分层)
阶段 1 完成: SPEC v2.3.1 (PATCH, 检查脚本配套文档)
阶段 2 完成: 无 bump (讨论稿)
阶段 3 完成: SPEC v2.4.0 (MINOR, FR-012~015)
阶段 4 完成: SPEC v2.5.0 (MINOR, FR-016~019)
阶段 5 完成: SPEC v3.0.0 (MAJOR, event_type 4→6 + FR-020~022)
阶段 6 完成: SPEC v3.1.0 (MINOR, FR-023~024 + STANDARD.md)
```

> [COMPUTED, HIGH] RULES.md R3 规定 event_type 枚举变更触发 MAJOR。阶段 5 是唯一 MAJOR 节点，必须在此阶段同步重算 R2 4×N 矩阵（N 从 4 变 6，组合数 16→24）。

---

## 五、风险与停止条件

### 5.1 风险

- 🔴 **阶段 3 在阶段 0 未收敛时启动**：在漂移基线上叠新 FR，会让 #866/#868 的修复更难（subject/topic 表又要改一遍）。**必须阶段 0 先合并**
- 🔴 **阶段 5 MAJOR bump 未同步 R2 矩阵**：event_type 4→6 后若不补 funding/mark_price 的 8 个新组合，RULES R2 硬约束违规
- 🟡 **runtime 仓脏工作区**（#869）：阶段 7 前不整理，所有 FR 实现状态只能停在 Pending
- 🟡 **v5 报告丢失**（212 行清洗/处理缺口）：v4 已含 13 条 FR 核心结论，但 C1-C8 清洗缺口、P1-P7 处理问题、G1-G4 缺口分类的细节无法恢复；阶段 3/4 落地时需重新推导这部分细节

### 5.2 停止条件

- [COMPUTED, HIGH] 本方案**未修改任何 `module/binance/` 治理文件**
- [INFERRED, HIGH] 历史下一步：用户确认阶段划分 → 创建 19 个待建 issue → 启动阶段 0 的 5 个并行 PR；post-PR #936/current-docs 口径见 `pr-936-governance-docs-closure-20260623.md`
- [INFERRED, MED] 阶段 0 收敛前，禁止启动阶段 3+ 的 FR 落地

---

## 六、与现有 issue 的映射核对

| 现有 issue              | 对应方案 ID | 阶段 | 一致性 |
| ----------------------- | ----------- | :--: | :----: |
| #867 README 版本漂移    | G-01        |  0   |   ✅   |
| #866 NATS 4×4 缺 3 组合 | G-02        |  0   |   ✅   |
| #868 Kafka topic 旧式   | G-03        |  0   |   ✅   |
| #873 RULES 任务引用错误 | G-04        |  0   |   ✅   |
| #872 状态口径分层       | G-05        |  0   |   ✅   |
| #870 检查脚本           | G-06        |  1   |   ✅   |
| #869 运行证据           | G-07        |  7   |   ✅   |
| #871 STANDARD.md        | G-08        |  6   |   ✅   |

**结论**：8 个现有 issue 全部映射成功，无遗漏、无冲突。待建 19 个 issue 为纯增量。

---

[RULES I BROKE]：无 — 本方案是规划文档，仅新增到 `docs/report/binance/`，未触及 `module/binance/` 受保护治理文件；所有事实基于已读报告 + grep 验证（FR-012~020 在 module/binance 中不存在已确认）
