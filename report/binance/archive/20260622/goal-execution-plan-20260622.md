# Goal: Binance 模块从规格参考实现升级为可发布 C/S 参考实现

> [COMPUTED, HIGH] **2026-06-23 PR #910 历史闭环状态**：本 goal 引用的 26 个开放 issue（#866~#896，含 #869）已全部关闭（PR #910，GitHub open count = 0）。正文中"开放 issue"字样为 2026-06-22 规划时状态。逐 issue PR #910 基线、证据与残留动作见 [`issues-full-closure-20260623.md`](issues-full-closure-20260623.md)。
> [COMPUTED, HIGH] **2026-06-23 当前状态覆盖声明**：FR-025~FR-030 已在 SPEC/TRACEABILITY/NAMING 登记为 Pending 合同项，但不代表 runtime 完成；GitHub #923~#931 已在后续 PR #947/#949 后全部 CLOSED，当前 closure ledger 仅记录 issue tracking state；runtime/release evidence Pending 继续由 acceptance/release gates 管理。

> 来源：`report/binance/iteration-plan-20260622.md`（27 项 backlog + 7 阶段路线）+ 26 个开放 issue（#866~#896）
> 框架：遵循 `docs/goal/02-goal-standard.md` 结构公式
> 制定日期：2026-06-22

---

## Goal 公式

> 在 **2026 年 Q3 末（2026-09-30）前**，针对 **binance 模块全量文档资产 + runtime 仓 `github.com/ZoneCNH/binance`**，实现 **治理漂移收敛 + 历史/实时数据缺口补齐 + runtime 证据链闭合**，使 **综合评分** 从 **82/100（B+）** 达到 **≥95/100（A）**，并满足 **13 个新 FR 全部进 SPEC + RELEASE DoD 通过**。

---

## 1. Context 背景

[COMPUTED, HIGH] binance 是 ZoneCNH 数据域 **13 个 C/S 模块的参考实现**，其规格质量与 runtime 实现直接影响 okx/bybit/bitget 等 12 个交易所采集模块的 fork 路径。

[COMPUTED, HIGH] 当前状态（v2 报告 2026-06-22）：
- 综合评分 82/100（B+）：规格优秀、对齐良好、runtime 缺失
- 13 个 FR 中 11 个 Pending；25/28 TC 待跑；9/9 BR runtime 未验证
- runtime 仓 `/home/binance` 存在大量未提交变更，不构成可审查快照
- RELEASE DoD = Not Done

[COMPUTED, HIGH] v3/v4 深度分析（2026-06-22）新识别 27 项 backlog：
- 5 项 P0 治理漂移（版本元数据、4×4 矩阵、Kafka topic、任务引用、状态口径）
- 15 项数据生命周期缺口（6 实时 R1-R6 + 9 历史 H1-H9）→ 13 条建议 FR（FR-012~024）
- event_type 枚举需 4→6 扩展（加 funding/mark_price），触发 MAJOR bump + RULES R2 矩阵重算

[INFERRED, HIGH] 若不收敛治理漂移就叠加新 FR，会让 #866/#868 的修复成本指数上升（subject/topic 表反复改）；若不先建讨论稿就动 SPEC，会触发治理风暴。

---

## 2. Objective 目标结果

**一句话**：binance 模块从"规格参考实现 + runtime release blocked"升级为"规格完整 + runtime 可发布 + 证据链闭合"的 A 等级 C/S 参考实现。

**分阶段目标**：

| 阶段 | 目标结果 | 完成标志 |
|---|---|---|
| 0 | 治理漂移收敛 | `scripts/check-binance-docs.sh` 全 PASS |
| 1 | 检查脚本 + 报告索引 | R1-R10 可机器检测，CI 集成方案出稿 |
| 2 | 数据生命周期讨论稿 | `DATA-LIFECYCLE.md` 已成讨论稿；评审通过后 13 FR 落点才算定稿 |
| 3 | 实时控制面 FR-012~015 | SPEC v2.4.0，4 FR + AC/TC 入矩阵 |
| 4 | 历史生命周期 FR-016~019 | SPEC v2.5.0，backfill/gap/throttle/idempotency 闭环 |
| 5 | 周期数据 FR-020~022 | SPEC v3.0.0 MAJOR，event_type 4→6，R2 矩阵 16→24 |
| 6 | 治理可观测 + 标准入口 | FR-023/024 + STANDARD.md + DEEP-ANALYSIS 瘦身 |
| 7 | runtime 证据链 | boundary gate 10/10 + go test + lint + smoke 全 PASS，TRACEABILITY 回填 |

---

## 3. Scope 范围

### In Scope

- `module/binance/` 全量治理文档（SPEC/TRACEABILITY/ACCEPTANCE/FEATURES/RULES/NAMING/RUNTIME-MAPPING/BOUNDARY-GATES/CHANGELOG + client/server 子规格）
- `module/binance/DATA-LIFECYCLE.md`（新建讨论稿）
- `module/binance/STANDARD.md`（新建薄层标准入口）
- `scripts/check-binance-docs.sh`（新建文档一致性检查脚本）
- runtime 仓 `github.com/ZoneCNH/binance` 的实现快照 + 证据归档
- 13 条新 FR（FR-012~024）的 SPEC 落地 + AC/TC 入矩阵
- event_type 枚举 4→6 扩展 + RULES R2 矩阵重算（16→24 组合，5 层 × 24 = 120 行）

### Out of Scope

- 其他 12 个 C/S 模块（okx/bybit/...）的 fork 升级——binance 完成后再启动（v2 报告 §六 4 阶段路线的第二~四阶段）
- binance runtime 仓的实盘交易能力——本模块是行情采集，不涉及下单（business-types 报告已明确排除）
- v5 报告（212 行清洗/处理缺口）的恢复——已放弃，C1-C8/P1-P7/G1-G4 细节在阶段 3/4 重新推导
- Binance Vision / 第三方数据集接入——v4 H3 仅 REST 历史 API
- cross-exchange 命名统一——仅限 binance 模块内部收敛

---

## 4. Success Metrics 成功指标

| 指标 | 基准值（v2） | 目标值 | 来源 |
|---|---|---|---|
| 综合评分 | 82/100（B+） | ≥95/100（A） | v2 报告 §四 |
| 规格 STRUCTURE | 23/25 | 25/25 | DEEP-ANALYSIS §0 升入 SPEC §4 |
| 追溯 TRACEABILITY | 24/25 | 25/25 | 13 新 FR + AC/TC 全入矩阵 |
| 边界 BOUNDARY | 18/20 | 20/20 | TC-020 evidence 归档 |
| 跨文档对齐 ALIGNMENT | 14/15 | 15/15 | runtime release unblocked |
| 运行时 RUNTIME | 3/15 | 13/15 | 11 个 Pending FR 转 Implemented |
| FR 实现数 | 2/13 Partial | 24/24 Implemented | TRACEABILITY 回填 |
| TC PASS 数 | 3/28 | 28/28 PASS | runtime 证据链 |
| BR CI Verified | 0/9 | 9/9 | boundary gate 10/10 |
| 文档漂移项 | 5 P0 + 4 P2 | 0 | check-binance-docs.sh PASS |
| RELEASE DoD | Not Done | Done | ACCEPTANCE.md |

---

## 5. Acceptance Criteria 验收标准

> 每条 AC 对应一个阶段 gate，二元化（通过/未通过）

### AC-1 治理漂移收敛（阶段 0）
- **Given** #866/#867/#868/#872/#873 已合并
- **When** 运行 `scripts/check-binance-docs.sh`
- **Then** R1-R10 全部 PASS，0 fail

### AC-2 检查脚本可用（阶段 1）
- **Given** `scripts/check-binance-docs.sh` 已落地
- **When** 本地 dry-run
- **Then** 输出 pass/fail + 失败文件位置；CI 集成方案出稿

### AC-3 讨论稿定稿（阶段 2）
- **Given** `module/binance/DATA-LIFECYCLE.md` 已建
- **When** 评审通过
- **Then** 13 FR 落点 + bump 级别 + 依赖关系明确，未修改 SPEC.md

### AC-4 实时控制面（阶段 3）
- **Given** FR-012~015 已入 SPEC v2.4.0
- **When** grep `FR-01[2-5]` module/binance/SPEC.md
- **Then** 4 FR 节存在 + AC 锚点 + TRACEABILITY 行

### AC-5 历史生命周期（阶段 4）
- **Given** FR-016~019 已入 SPEC v2.5.0
- **When** 回填+实时并发写入测试
- **Then** idempotency key 维度一致，不双写（FR-019 AC 通过）

### AC-6 周期数据 MAJOR（阶段 5）
- **Given** event_type 枚举 4→6
- **When** 运行 RULES R2 矩阵检测
- **Then** 4×6=24 组合 × 5 层 = 120 行全对称，0 缺口

### AC-7 治理可观测（阶段 6）
- **Given** FR-023/024 + STANDARD.md 已落地
- **When** `POST /api/v1/admin/symbols/reload`
- **Then** client 增减 stream 不重启进程

### AC-8 runtime 证据链（阶段 7）
- **Given** runtime 仓形成可审查快照
- **When** 运行 `./scripts/boundary-gates.sh && go test ./... && golangci-lint run`
- **Then** 10/10 PASS + 全测试通过 + 0 blocker lint，证据归档 `release/evidence/binance/`

### AC-9 RELEASE DoD
- **Given** AC-1~8 全通过
- **When** 检查 ACCEPTANCE.md
- **Then** Release DoD = Done，TRACEABILITY/ACCEPTANCE/FEATURES 三层状态一致

---

## 6. Constraints 约束

### 6.1 治理约束（RULES.md）

- **R1【硬】命名 SSOT**：所有变更必须 100% 匹配 NAMING.md，4 条 grep 期望 0 命中
- **R2【硬】4×N 对称矩阵**：阶段 5 后 N=6，24 组合 × 5 层全对称
- **R3【硬】版本 bump 触发器**：event_type 枚举变更 = MAJOR；bump 必须 PR 最后一个 commit；只能升不能降
- **R4【硬】状态三层一致**：TRACEABILITY / runtime 仓 / 报告 三层一致
- **R5【硬】归档物理隔离**：废弃 task 用 `git mv` 移到 `archive/`
- **R6【硬】ACCEPTANCE 元数据同步**：Module-Version = SPEC Spec-Version

### 6.2 流程约束（CLAUDE.md）

- 禁止在 main 直接编辑/提交；所有分支从 main HEAD 创建
- 同逻辑变更聚合为 1 个 commit；版本 bump 放 PR 最后
- PR 标题 Conventional Commits + 中文描述，≤50 字符
- commit/PR body 末尾 `Co-Authored-By: Claude <noreply@anthropic.com>` / `🤖 Generated with [Claude Code]`
- 涉及数量/版本/百分比必须实际统计，禁止凭记忆编造

### 6.3 顺序约束

- 🔴 **阶段 3 禁止在阶段 0 未收敛时启动**（漂移基线上叠新 FR 会让 #866/#868 反复改）
- 🔴 **阶段 5 MAJOR bump 必须同步重算 R2 矩阵**（否则 R2 硬约束违规）
- 🟡 **阶段 7 runtime 证据前，所有 FR 实现状态只能停 Pending**（禁止文档先行宣称实现完成）

### 6.4 资源约束

- [INFERRED, MED] 预算上限：单会话 ≤$30（CLAUDE.md 成本纪律）
- runtime 仓 `/home/binance` 脏工作区需先整理才能形成快照
- v5 报告已丢失，C1-C8 清洗缺口细节需在阶段 3/4 重新推导

---

## 7. Non-goals 非目标

- 不重构 binance 架构（分布式约束 + boundary gates + G0-1~6 已是高质量基础，问题在执行不在设计）
- 不另起平行规则体系（v3 报告明确：先修复现有规则投影漂移，STANDARD.md 仅作索引入口）
- 不做实盘交易/下单（模块定位是行情采集）
- 不做 cross-exchange 命名统一（仅 binance 内部）
- 不恢复 v5 报告（用户已确认放弃）
- 不在阶段 5 前触碰 event_type 枚举（避免提前触发 MAJOR 风暴）

---

## 8. 执行计划（7 阶段 × issue 映射）

### 阶段 0：治理漂移收敛（P0，预计 3 天）

| issue | 任务 | bump | 依赖 |
|---|---|---|---|
| #867 | README root Spec-Version v2.2.0→v3.1.0 | PATCH | 无 |
| #866 | RUNTIME-MAPPING NATS 4×4 补 3 个 trade | MINOR | 无 |
| #868 | Kafka topic 旧式→`binance.{pl}.{et}.v1` | MINOR | 无 |
| #873 | RULES.md 任务文件名引用修正 | PATCH | 无 |
| #872 | 状态口径分层 L1/L2 | MINOR | 无 |

**Gate**：5 个 PR 合并 + `check-binance-docs.sh`（阶段 1 落地后）全 PASS → SPEC v2.3.0

### 阶段 1：检查脚本 + 报告索引（P1，预计 2 天）

| issue | 任务 |
|---|---|
| #870 | `scripts/check-binance-docs.sh` 覆盖 R1-R10 + 4×4 + 版本元数据 + 任务引用 |
| — | INDEX.md 补 v3/v4/iteration-plan 条目（已完成）|

**Gate**：脚本本地 PASS + CI 集成方案出稿 → SPEC v2.3.1

**CI 集成方案草案**：在 docs CI 中于通用漂移检查后运行 `bash scripts/check-binance-docs.sh`；该脚本不引入新依赖，输出 `PASS/FAIL <file>:<reason>`，并在失败时以非零退出码阻断后续 runtime evidence jobs。

### 阶段 2：数据生命周期讨论稿（P1，预计 3 天）

| issue | 任务 |
|---|---|
| #879 | `module/binance/DATA-LIFECYCLE.md` 整理 15 缺口 + 13 建议 FR |

**Gate**：讨论稿评审通过，13 FR 落点 + bump + 依赖明确。无 bump（讨论稿）。

**当前执行证据（2026-06-22）**：[COMPUTED, HIGH] `module/binance/DATA-LIFECYCLE.md` 已落地为 Discussion Draft，覆盖 15 个生命周期缺口、13 个建议 FR 落点、bump 级别和依赖关系；review checklist 已闭合，并记录只批准拆分/依赖/bump/落点计划，不批准 runtime 行为、SPEC/TRACEABILITY 修改或 Release DoD。因此 AC-3 通过，后续 FR 仍需按阶段 3-6 进入 SPEC。

### 阶段 3：实时控制面 FR（P0，预计 1 周）

| issue | FR | 内容 |
|---|---|---|
| #880 | FR-012 | Symbol Discovery & Filtering |
| #881 | FR-013 | WebSocket Connection Policy |
| #882 | FR-014 | Bar Interval Subscription Set |
| #883 | FR-015 | Depth Snapshot Tier |

**Gate**：4 FR 入 SPEC + AC/TC + NAMING 新增 `instruments.changed` subject → SPEC v2.4.0

### 阶段 4：历史生命周期 FR（P0，预计 1 周）

| issue | FR | 内容 |
|---|---|---|
| #884 | FR-016 | Historical Backfill on Cold Start |
| #885 | FR-017 | Gap Detection & Fill |
| #886 | FR-018 | Backfill Throttle & Priority |
| #887 | FR-019 | Backfill Idempotency Key Strategy |

**Gate**：4 FR 入 server/SPEC §7 Backfill 章节 + 新增 `binance_backfill_jobs` 表 + BR-008 扩展 → SPEC v2.5.0

### 阶段 5：周期数据 MAJOR（P1，预计 2 周）

| issue | FR | 内容 |
|---|---|---|
| #888 | FR-020 | Funding Rate / Mark Price Stream（含 event_type 4→6）|
| #889 | FR-021 | Daily Reconciliation Job |
| #890 | FR-022 | Cold Data Rehydration |

**Gate**：event_type 4→6 + R2 矩阵重算（24×5=120 行）+ 新增 taosx 超表 `binance_market_funding`/`_mark_price` + 8 条 Kafka topic → **SPEC v3.0.0 MAJOR**

### 阶段 6：治理可观测 + 标准入口（P2/P3，预计 1 周）

| issue | 任务 |
|---|---|
| #891 | FR-023 Backfill Progress API |
| #892 | FR-024 Symbol Subscription Hot Reload |
| #871 | STANDARD.md 薄层标准入口 |
| #893 | DEEP-ANALYSIS §0 升入 SPEC §4 |
| #894 | DEEP-ANALYSIS §12 迁移 migrations/ |
| #895 | legacy `binance-market` 压缩 |
| #896 | 50 commit 覆盖审计 |

**Gate**：admin API + hot reload + STANDARD.md + 文档瘦身 → SPEC v3.1.0

### 阶段 7：runtime 证据链（P2，贯穿，预计 2 周）

| issue | 任务 |
|---|---|
| #869 | runtime 快照 + boundary gate 10/10 + go test + lint + smoke + 证据归档 |

**Gate**：`release/evidence/binance/` 全量证据 + TRACEABILITY/ACCEPTANCE/FEATURES 回填 + RELEASE DoD = Done

**当前 runtime 审计（2026-06-22）**：[COMPUTED, HIGH] OMX team `read-home-zonecnh-wor-93f0ddf6`、`read-only-audit-inspe-93f0ddf6` 和 runtime team `task-verify-and-finis-a90b0de7` 已 graceful shutdown；worker mailbox 已被 runtime 清理，仅保留 dispatch/state 启动与完成证据，未发现需要 merge 的 worker 产物。`/home/binance/scripts/boundary-gates.sh` 已对齐 `BOUNDARY-GATES.md` 的 10-gate 审计合同。

**Stage7 本地修复证据（2026-06-22）**：[COMPUTED, HIGH] `/home/binance` 已将 runtime 边界修到本地可验证状态：`./scripts/boundary-gates.sh` = 10/10 PASS；`go test ./...` PASS；`golangci-lint run` = 0 issues；`XGO_BINANCE_SMOKE_SELF_TEST=1 go run ./cmd/binance-smoke` PASS；`bash -n scripts/boundary-gates.sh` PASS；`git diff --check` PASS。基础证据已归档到 `/home/binance/release/evidence/binance/20260622/`，摘要文件为 `SUMMARY.md`。修复点包括移除生产 `NewIngestAdapter` 同进程 adapter、将 client 依赖收敛到 `wire.IngestEndpoint`、删除 `wire.EventType/ProductLine` 本地语义枚举、补齐 §11 直接依赖，同步 README / boundary-gates workflow 的 10-gate 描述；后续新增 `POST /api/v1/admin/symbols/reload` 本地 catalog reload 入口与 `internal/client/admin_test.go` 覆盖，并已用最新 `go test ./...`、`golangci-lint run` 和 smoke self-test 复验。

**Stage7 剩余阻塞证据（2026-06-22）**：[COMPUTED, HIGH] TRACEABILITY/ACCEPTANCE/FEATURES 已回填到 v3.1.0 登记态，`RUNTIME-MAPPING.md` 已统一当前本地验证口径为 `POST /api/v1/admin/symbols/reload`；`/home/binance` 端点已存在并通过 `go test ./...` 覆盖成功 reload、非法方法和非法 payload。但尚未证明“client 增减 stream 不重启进程”的完整 FR-024 行为，且未运行 live Binance websocket smoke、远端 CI、release tag 或发布快照。因此 AC-7 只完成规格/追溯登记和本地 endpoint 单元证据，完整 Stage7 Gate 与 RELEASE DoD 仍未闭合。

---

## 9. 版本演进路径

```
当前:     SPEC v3.1.0 / TRACEABILITY v3.1.0 / client v2.1.1 / server v2.1.0 / RULES v1.0.0
阶段 0:   SPEC v2.3.0  (MINOR, subject/topic 收敛 + 状态分层)
阶段 1:   SPEC v2.3.1  (PATCH, 检查脚本配套)
阶段 2:   无 bump      (讨论稿)
阶段 3:   SPEC v2.4.0  (MINOR, FR-012~015)
阶段 4:   SPEC v2.5.0  (MINOR, FR-016~019)
阶段 5:   SPEC v3.0.0  (MAJOR, event_type 4→6 + FR-020~022)  ← 唯一 MAJOR
阶段 6:   SPEC v3.1.0  (MINOR, FR-023~024 + STANDARD.md)
阶段 7:   无 bump      (runtime 证据回填)
```

---

## 10. 风险与缓解

| 风险 | 严重性 | 缓解措施 |
|---|:---:|---|
| 阶段 3 在阶段 0 未收敛时启动 | 🔴 | 顺序约束硬卡：阶段 0 Gate 未过禁止启动阶段 3 |
| 阶段 5 MAJOR 未同步 R2 矩阵 | 🔴 | AC-6 二元校验：24×5=120 行全对称才放行 |
| runtime 仓脏工作区阻塞阶段 7 | 🟡 | 阶段 3 开始即整理 `/home/binance`，与 FR 落地并行 |
| v5 报告丢失导致清洗缺口细节缺失 | 🟡 | 阶段 3/4 重新推导 C1-C8/P1-P7/G1-G4 |
| 13 个 C/S 模块 fork 漂移放大 | 🟡 | binance 完成后启动 v2 报告 §六 4 阶段迁移路线 |
| 成本超 $30/会话 | 🟡 | 分阶段独立 PR，单会话只做 1 个阶段 |

---

## 11. 决策记录

| 日期 | 决策 | 理由 |
|---|---|---|
| 2026-06-22 | 采用 7 阶段顺序执行而非并行 | 治理漂移必须先于功能扩展，避免在漂移基线上叠新 FR |
| 2026-06-22 | event_type 4→6 推迟到阶段 5 | 集中处理 MAJOR bump，避免多次矩阵重算 |
| 2026-06-22 | 先建 DATA-LIFECYCLE.md 讨论稿再动 SPEC | 避免治理风暴，13 FR 一次性 fold |
| 2026-06-22 | 放弃 v5 报告恢复 | v4 已含 13 FR 核心结论，损失可控 |
| 2026-06-22 | 同步 root SPEC/TRACEABILITY 到 v3.1.0 登记态，FR-024 仍保持 Pending | 允许文档追溯先闭合编号和 endpoint 口径；不把 runtime endpoint 单元证据等同于 active stream no-restart 完成 |

---

## 12. 变更日志

| 日期 | 变更 |
|---|---|
| 2026-06-22 | 同步 `SPEC.md`/`TRACEABILITY.md`/`ACCEPTANCE.md`/`FEATURES.md`/`README.md`/`IMPLEMENTATION-PLAN.md`/`RUNTIME-MAPPING.md` 到 v3.1.0 登记态；`scripts/check-binance-docs.sh` 增加 FR-024、AC-086、TC-042、R2 matrix 与 RUNTIME-MAPPING endpoint 检查 |
| 2026-06-22 | 新增 `module/binance/STANDARD.md` 薄层标准入口，记录 `POST /api/v1/admin/symbols/reload` 当前本地验证口径、FR-024 边界和证据门禁；`scripts/check-binance-docs.sh` 已要求 STANDARD 存在并校验 endpoint/FR-024 关键字 |
| 2026-06-22 | 闭合 `module/binance/DATA-LIFECYCLE.md` review checklist，明确 AC-3 只批准 13 FR 的拆分/依赖/bump/落点计划，不批准 runtime 行为、SPEC/TRACEABILITY 修改或 Release DoD |
| 2026-06-22 | 新增 `/home/binance` client admin reload 端点：`POST /api/v1/admin/symbols/reload` 可替换本地 catalog，`internal/client/admin_test.go` 覆盖成功 reload、非法方法和非法 payload；`go test ./...`、`golangci-lint run` 与 smoke self-test 通过 |
| 2026-06-22 | 修复 `/home/binance` runtime 边界：boundary-gates 从 7/10 提升到 10/10 PASS，`go test ./...`、`golangci-lint run`、`XGO_BINANCE_SMOKE_SELF_TEST=1 go run ./cmd/binance-smoke`、`bash -n scripts/boundary-gates.sh`、`git diff --check` 全通过；证据归档到 `/home/binance/release/evidence/binance/20260622/` |
| 2026-06-22 | 收口 OMX team `read-home-zonecnh-wor-93f0ddf6`；对齐 `/home/binance/scripts/boundary-gates.sh` 到 10 gates；初始 runtime 审计发现 boundary-gates 7/10 PASS，失败 §6/§9/§11，并作为本轮修复输入 |
| 2026-06-22 | 回填 Stage0-Stage2 执行证据：`scripts/check-binance-docs.sh` 本地 PASS，`.github/workflows/docs-ci.yml` 接入 binance docs check，`DATA-LIFECYCLE.md` 讨论稿落地并完成 review checklist；AC-3 通过，Stage3-6 仍未启动 |
| 2026-06-22 | 首次建立。基于 iteration-plan-20260622.md + 26 个开放 issue，按 docs/goal/02-goal-standard.md 模板制定 |

---

## 13. 最终验证

- [x] AC-1 通过（证据：`bash scripts/check-binance-docs.sh` 全 PASS，0 fail）
- [x] AC-2 通过（证据：`scripts/check-binance-docs.sh` 本地 dry-run 输出 PASS/FAIL；`.github/workflows/docs-ci.yml` 已运行 `bash scripts/check-binance-docs.sh`）
- [x] AC-3 通过（证据：`DATA-LIFECYCLE.md` 已建并列出 15 缺口 + 13 FR；review checklist 已完成；限制：只批准计划落点，不批准 runtime 行为、SPEC/TRACEABILITY 修改或 Release DoD）
- [ ] AC-4 未通过（缺证据：SPEC v2.4.0 + 4 FR grep 命中）
- [ ] AC-5 未通过（缺证据：SPEC v2.5.0 + FR-019 并发测试 PASS）
- [ ] AC-6 未通过（缺证据：SPEC v3.0.0 + R2 矩阵 120 行）
- [ ] AC-7 未通过（证据：`module/binance/STANDARD.md`、`SPEC.md`、`TRACEABILITY.md` 已登记 FR-024；`RUNTIME-MAPPING.md` 已统一为 `POST /api/v1/admin/symbols/reload`；`/home/binance/internal/client/admin.go` 已落地，`go test ./...` 覆盖 reload/method/payload；缺口：尚未证明增减 stream 不重启进程，未取得 live websocket、远端 CI、release tag 或发布快照）
- [x] AC-8 本地 runtime 证据链通过（证据：`/home/binance/scripts/boundary-gates.sh` 本地 10/10 PASS；`go test ./...` PASS；`golangci-lint run` = 0 issues；`XGO_BINANCE_SMOKE_SELF_TEST=1 go run ./cmd/binance-smoke` PASS；`bash -n scripts/boundary-gates.sh` PASS；`git diff --check` PASS；证据归档 `/home/binance/release/evidence/binance/20260622/`；限制：未运行 live websocket smoke、远端 CI 或 release tag）
- [ ] AC-9 未通过（缺证据：ACCEPTANCE.md Release DoD = Done）

**执行边界（2026-06-22）**：[COMPUTED, HIGH] Stage0-Stage6 的文档登记态已同步到 SPEC/TRACEABILITY v3.1.0，且 `DATA-LIFECYCLE.md` review checklist 已闭合；R2 governance matrix 已作为 120-cell 登记口径进入 TRACEABILITY/checker。AC-7 的 admin reload API 与 STANDARD/TRACEABILITY/RUNTIME-MAPPING 口径已局部落地，但仍未满足 active stream 不重启动态增减订阅的 runtime proof。Stage7 本地 boundary gate、Go tests、lint、smoke self-test、脚本语法、补丁格式和证据归档已通过；仍缺 live websocket、远端 CI、release tag 和可审查 release snapshot。OMX team `read-home-zonecnh-wor-93f0ddf6` 当前无 team state 可 shutdown，本轮按文档 reconcile 处理，不得把 FR-012~024 或 RELEASE DoD 宣称为完成。

---

[RULES I BROKE]：一次误将 `omx team inbox inbox-audit-the-contr-7f692a1f --json` 当作只读查询执行，触发了临时 team `inbox-inbox-audit-the-93f0ddf6`；已立即 `force` shutdown 并确认不存在残留。除此之外，本轮修复未在 `/home/ZoneCNH` main 直接编辑；报告中的事实均保留证据标签和置信度；仍未把未闭合 AC 宣称完成
