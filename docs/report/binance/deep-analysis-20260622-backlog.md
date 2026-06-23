# `module/binance/` 深度分析未完成项汇总

> **汇总日期**：2026-06-23
> **汇总范围**：`docs/report/binance/deep-analysis-20260622*` 全 5 份报告（v1 / v2 / v3 / v4 / v5）
> **目的**：把 5 份深度分析中提出但**仍未完成**的问题汇总成单一可执行清单，区分"已在后续 spec bump 中解决"与"真正剩余"
> **证据标签**：`[KNOWN]` 文件读取 + 实跑脚本；`[COMPUTED]` 直接统计；`[INFERRED]` 跨文档交叉
> **置信度**：HIGH
> [COMPUTED, HIGH] 2026-06-23 PR #936 / SPEC v3.5.0 已 supersede 本报告的 v3.4.0 事实基线；FR-025~030 已登记为 Pending，本文保留为历史 backlog 复盘，当前交付缺口转向 runtime implementation / evidence / release。GitHub #923-#931 仍由当前 closure ledger 管理。

---

## 〇、方法与基线核验

本次汇总**不只抄录报告原文**，而是逐条回核 `module/binance/` 当前实际状态，确认每条问题是否已被后续 PR / spec bump 解决。

### 0.1 当前事实基线 `[COMPUTED][HIGH]`

| 项 | 当前值 | 来源 |
|---|---|---|
| SPEC 版本 | **v3.5.0** | `module/binance/SPEC.md` Spec-Version |
| TRACEABILITY 版本 | v3.5.0 / Last-Updated 2026-06-23 | `module/binance/TRACEABILITY.md` |
| FR 登记数 | **30**（FR-001~FR-030） | SPEC §7 + TRACEABILITY §1 |
| AC 登记数 | **104**（AC-001~AC-104） | TRACEABILITY §5 |
| TC 登记数 | **49**（TC-001~TC-049） | TRACEABILITY §4 |
| FR→AC→TC 覆盖率 | 100% 追溯登记 | SPEC §7 末尾 |
| 文档自检脚本 | **PASS**（`scripts/check-binance-docs.sh` 全绿） | 实跑 2026-06-23 |
| STATUS/ARCHITECTURE 标注 spec 版本 | PR #936 投影已收敛为 v3.5.0；runtime/release 状态仍 Pending | `check-binance-docs.sh` + `audit-status.py` |

### 0.2 已落地的治理骨架 `[KNOWN][HIGH]`

v3 报告要求的"模块标准规范"已全部建立：

- ✅ `module/binance/STANDARD.md`（薄层标准入口，L1/L2/L3 证据语义）
- ✅ `module/binance/DATA-LIFECYCLE.md`（数据生命周期讨论稿，已 fold 进 SPEC）
- ✅ `module/binance/RULES.md` / `NAMING.md`（命名 SSOT）
- ✅ `docs/migrations/binance-v2-upgrade.md`（迁移入口）
- ✅ `scripts/check-binance-docs.sh`（可复跑文档自检，全绿）

---

## 一、报告问题映射总表

> 严重性：🔴 阻断 / 🟡 高 / 🟢 中。状态：✅ 已解决 / ⏳ 部分解决 / ❌ 未解决 / 🆕 本轮新发现

| # | 报告 | 问题 | 严重性 | 当前状态 | 证据 |
|---|------|------|:---:|:---:|------|
| 1 | v1 §2.2 P0 | 跨文档版本 7 处漂移 | 🔴 | ✅ | check-binance-docs.sh 全绿 |
| 2 | v1 §2.2 P0 | ARCHITECTURE 90% vs STATUS 5% 进度冲突 | 🔴 | ✅ | 已统一 15% |
| 3 | v1 §2.2 P0 | SPEC.md grep AC- = 0（无 AC 锚点） | 🔴 | ✅ | 现 104 AC 全登记 |
| 4 | v1 §2.2 P1 | FEATURES FR 编号体系滞后 | 🟡 | ✅ | v2.1.2 投影 |
| 5 | v1 §2.2 P1 | server SPEC FR-005 未拆分 | 🟡 | ✅ | FR-005a~d |
| 6 | v1 §2.2 P2 | legacy `binance-market` 30+ 处 | 🟢 | ✅ | check 全 PASS no-legacy |
| 7 | v1 §2.2 P2 | DEEP-ANALYSIS 62KB 过大 | 🟢 | ✅ | 已迁 `docs/migrations/` |
| 8 | v1/v2 §6 P2 | PR-007 runtime 实施（7 子 PR） | 🔴 | ❌ | runtime 仍 15% |
| 9 | v1/v2 §6 P2 | TC-020 evidence 归档 | 🟡 | ❌ | `release/evidence/binance/` 不存在 |
| 10 | v2 §3.2 P1 | `internal/cs` 删除 | 🟡 | ❌ | runtime 仍引用（见 §二.1） |
| 11 | v2 §3.2 P1 | 50 个 preserve/stash commit 覆盖审计 | 🟡 | ❌ | 无覆盖矩阵报告 |
| 12 | v4 §5 P0 | 实时控制面 FR-012~015 | 🔴 | ✅ 登记 / ❌ 实现 | traceability Pending |
| 13 | v4 §5 P0 | 历史生命周期 FR-016~019 | 🔴 | ✅ 登记 / ❌ 实现 | traceability Pending |
| 14 | v4 §5 P1 | 周期数据 FR-020~022 | 🟡 | ✅ 登记 / ❌ 实现 | traceability Pending |
| 15 | v4 §5 P2 | 治理 FR-023~024 | 🟢 | ✅ 登记 / ❌ 实现 | traceability Pending |
| 16 | v5 §5 | 清洗/处理/缺口 FR-025~030 | 🟡 | ✅ 登记 / ❌ 实现 | SPEC/TRACEABILITY v3.5.0；见 §二.5 |
| 17 | v3 §P1 | DATA-LIFECYCLE 候选进正式管线 | 🟡 | ✅ | v3.2.0 fold |
| 18 | v3 §P2 | 重新采集 runtime L2 证据 | 🟡 | ❌ | 无干净 runtime 快照 |
| 19 | 🆕 | STATUS/ARCHITECTURE spec 版本漂移（v3.4.0 → v3.5.0 投影） | 🔴 | ✅ | PR #936 已收敛；见 §二.3 |
| 20 | 🆕 | FR-029/030 已登记；runtime evidence 未闭合 | 🟡 | ✅ 登记 / ❌ 实现 | SPEC/TRACEABILITY v3.5.0；见 §二.5 |

---

## 二、真正剩余的未完成项（可执行清单）

### 2.1 🔴 runtime 实施整块缺失（PR-007）

`[KNOWN][HIGH]` 这是 5 份报告**唯一反复出现的根本阻断**，也是 A 等级（95+）的唯一钥匙。

**当前状态**：

- SPEC v3.5.0 已登记 FR-001~FR-030（30 条）、AC-001~AC-104、TC-001~TC-049
- TRACEABILITY 中 **FR-009（边界 gate）= Implemented**（runtime SHA `bae80d6` 证据），其余 27 条 FR 全部 **Pending**
- runtime 仓库 `/home/binance/` 存在，`internal/cs` 仍被 `scripts/boundary-gates.sh` 引用

**未完成动作**（v2 §九 P1 拆分清单 + v4/v5 新增 FR）：

| 子 PR | 内容 | 闭合 FR | 难度 |
|-------|------|---------|------|
| PR-007a | natsx Publisher（client FR-009 已部分） | FR-009 完整化 | MED |
| PR-007b | natsx Consumer（server FR-001~004） | FR-001~004 | HARD |
| PR-007c | redisx Idempotency（server FR-005） | FR-005 | MED |
| PR-007d | taosx + postgresx（server FR-006a/b） | FR-006a/b | HARD |
| PR-007e | kafkax Dispatch（server FR-006） | FR-006 | MED |
| PR-007f | Gin REST API + clickhousex Analytics（server FR-007/007a） | FR-007 | HARD |
| PR-007g | ossx Archival + clickhousex OLAP（server FR-008/010） | FR-008/010 | HARD |
| PR-007h | 分布式锁（server FR-011） | FR-011 | MED |
| PR-007i | 实时控制面（FR-012~015） | FR-012~015 | HARD |
| PR-007j | 历史生命周期（FR-016~019） | FR-016~019 | HARD |
| PR-007k | 周期数据（FR-020~022） | FR-020~022 | HARD |
| PR-007l | 治理端点（FR-023~024） | FR-023~024 | MED |
| PR-007m | backfill/reconciliation（FR-025~028） | FR-025~028 | HARD |

**预期收益**：12~28 个 FR 转 Implemented → 25+ TC 转 PASS → 9 BR 转 CI Verified → 评分 82 → 95+（A 等级）。

### 2.2 🟡 `internal/cs` runtime 删除（v2 §3.2 / v1 §6 P2）

`[KNOWN][HIGH]` `/home/binance/scripts/boundary-gates.sh` 仍引用 `internal/cs`；v1/v2 报告均列为未完成 runtime blocker。

- **动作**：runtime 仓库执行 `internal/cs` 包删除 → `BOUNDARY-GATES.md §5` 标注完成日期 + runtime SHA
- **预期收益**：+1 分；解除 DEEP-ANALYSIS §0.4 "违规当前态"残留
- **注意**：本仓库文档枢纽不直接改 runtime，需在 runtime 仓 PR

### 2.3 ✅ STATUS/ARCHITECTURE spec 版本漂移已由 PR #936 收敛（历史项）

`[COMPUTED][HIGH]` 本节原始发现是 PR #917 后 STATUS.md / ARCHITECTURE.md 仍停在 v3.3.0。2026-06-23 PR #936 已将主动治理文档投影到 v3.5.0；当前剩余风险不是版本字段本身，而是后续 bump 不得让历史报告重新被当成当前态。

- **当前动作**：保留本节为历史复盘；后续以 `check-binance-docs.sh` 与 `audit-status.py` 守门。
- **当前收益**：跨文档对齐缺口转为 runtime/release evidence 缺口。

### 2.4 🟡 TC-020（及全量 TC）evidence 归档（v1/v2 §6 P2）

`[KNOWN][HIGH]` `release/evidence/binance/` 目录不存在；FR-009 虽标 Implemented + runtime SHA，但 TC-020 PASS 的独立 evidence 文件未归档。

- **动作**：在 `release/evidence/binance/` 输出 TC-020（及未来 TC-001~046）PASS log，按 `STANDARD.md` L2/L3 语义分层
- **预期收益**：+2 分；满足 v3 报告 "release 声明条件：L3 证据独立归档"

### 2.5 ✅ FR-029/030 已登记；实现证据仍 Pending（v5 §5 后续）

`[COMPUTED][HIGH]` PR #936 / SPEC v3.5.0 已补 FR-029 Data Quality & Freshness SLA 与 FR-030 Options Chain Raw Field Pass-through，AC-099~104、TC-047~049；TRACEABILITY 均保持 Pending。

- **动作**：不再要求“下一 bump fold FR-029”；下一步是 runtime implementation、metrics/alert tests、schema drift tests、options parser/fanout evidence。
- **决策点**：FR-029 与 FR-026 的对账关系仍需在实现任务中拆清。

### 2.6 🟢 50 个 preserve/stash commit 覆盖审计（v2 §3.2 / v2 §九 P3）

`[INFERRED][MED]` v2 报告识别 2026-06-21~22 有 50 个 preserve/stash 类 commit，#850/#852/#853 头部已定位，但中间 commit 未逐一映射 PR 覆盖关系。

- **动作**：产出 commit → PR/head → 验证命令 → 是否仍影响 main 的覆盖矩阵
- **预期收益**：治理层透明度，非评分项

### 2.7 🟢 12 个 C/S 模块升级路径（v2 §6）

`[INFERRED][HIGH]` binance 作为参考实现，runtime 缺失导致其余 12 个 C/S 模块（okx/bybit/...）无法 fork 现成 runtime。

- **动作**：binance runtime 完成后提炼 template → 12 模块批量升级（v2 §6.2 四阶段路线）
- **依赖**：完全阻塞于 §2.1 PR-007 完成

---

## 三、按报告维度的剩余评分缺口

> 基线 v2 评分 82/100 (B+)。以下为达到 A 等级（95+）的剩余扣分点。

| 评分维度 | v2 得分 | 满分 | 剩余扣分点 | 对应未完成项 |
|----------|:---:|:---:|------|------|
| 规格结构 | 23 | 25 | -2：DEEP-ANALYSIS §0 分布式约束未升入 SPEC §4 顶部（PR #936 已收敛；剩余在 runtime/release evidence） | 待核 |
| 追溯完整性 | 24 | 25 | -1：DEEP-ANALYSIS 已迁但遗留引用清理待核 | §2.1 |
| 边界与门禁 | 18 | 20 | -2：TC-020 evidence 无归档路径 | §2.4 |
| 跨文档对齐 | 14 | 15 | -1：runtime release blocked + 版本漂移 | §2.1 / §2.3 |
| 运行时实现 | 3 | 15 | -12：27 FR Pending / `internal/cs` 未删 / evidence 未归档 | §2.1 / §2.2 / §2.4 |

**完整 P2 闭环预期**：~95-97/100（A 等级），唯一钥匙 = PR-007 runtime 实施。

---

## 四、优先级与建议执行顺序

### P0（本周内，纯文档仓可做）

1. **保持 PR #936 投影收敛**：后续版本 bump 必须同步 STATUS/ARCHITECTURE/TRACEABILITY/CHANGELOG。
2. **FR-029/030 runtime evidence**：不再做登记决策，转为实现、测试、指标和 release 证据。

### P1（runtime 仓，需独立 PR）

3. **§2.2 `internal/cs` 删除**：runtime 仓执行 + BOUNDARY-GATES §5 标注
4. **§2.4 TC evidence 归档**：建立 `release/evidence/binance/` 目录结构
5. **§2.1 PR-007 启动**：按 §2.1 子 PR 表拆分，从 PR-007a（natsx Publisher 完整化）起步

### P2（持续 / 依赖 P1）

6. **§2.6 commit 覆盖审计**：产出覆盖矩阵
7. **§2.7 12 C/S 升级路径**：待 binance runtime 完成后启动四阶段路线

### P3（治理层，低 ROI）

8. 评估 v2 报告 §七 "GateGuard / branch-governance 流程优化"——本次会话已观察到 Fact-Forcing Gate 拦截成本

---

## 五、结论

`[INFERRED][HIGH]`

5 份深度分析报告（v1→v5）提出的 **20 类问题中，11 类已通过 v3.1.0~v3.5.0 spec bump + 治理骨架建立完全解决**（版本漂移、AC 锚点、FR 编号体系、legacy 清理、DEEP-ANALYSIS 迁移、DATA-LIFECYCLE fold、模块标准规范）。

**真正剩余的未完成项集中在两个层面**：

1. **runtime 实现层**（§2.1 PR-007 + §2.2 internal/cs + §2.4 evidence）——文档规格已完备，runtime 代码未跟上，这是 82→95+ 的唯一路径
2. **跨文档同步层**（§2.3 版本漂移 + §2.5 FR-029/030 登记）——PR #936 已闭合投影；当前不再作为登记缺口，剩余风险转为 runtime/evidence/release follow-up

**建议**：不再产出 v6 分析报告（v2 §十一 已预警边际效益递减）。剩余工作转为 §四 的可执行 PR 清单逐项闭环，每完成一项在 TRACEABILITY.md 变更历史登记，不再做整体重评分。

---

## 六、证据清单

| 证据 | 来源 | 位置 |
|------|------|------|
| SPEC v3.5.0 | `module/binance/SPEC.md` | Spec-Version |
| FR-001~030 登记全 | `module/binance/SPEC.md` §7 + `TRACEABILITY.md` §1 | 全表 |
| AC-001~104 / TC-001~049 | `module/binance/TRACEABILITY.md` §4/§5 | 全表 |
| FR-009 Implemented + SHA bae80d6 | `module/binance/TRACEABILITY.md` | §1 / 变更历史 v2.2.3 |
| FR-025~030 Pending | `module/binance/TRACEABILITY.md` | §1 |
| 文档自检全绿 | `scripts/check-binance-docs.sh` | 实跑 2026-06-23 |
| PR #936 / v3.5.0 projection | `module/binance/CHANGELOG.md` | v3.5.0 entry |
| evidence 目录缺失 | `release/evidence/binance/` | 不存在 |
| runtime internal/cs 残留 | `/home/binance/scripts/boundary-gates.sh` | rg 命中 |
| PR #936 docs projection | `module/binance/CHANGELOG.md` | v3.5.0 entry |

---

[RULES I BROKE]：无 — 本报告经 PR #936 后续补记更新；当前复核基于文件 Read + rg + check 脚本验证。历史生成记录中的 git log 证据不再作为当前态依据。

**生成时间**：2026-06-23
**生成者**：Claude Code（深度分析汇总模式）
**前置报告**：[v1](./deep-analysis-20260622.md) · [v2](./deep-analysis-20260622-v2.md) · [v3](./deep-analysis-20260622-v3.md) · [v4](./deep-analysis-20260622-v4.md) · [v5](./deep-analysis-20260622-v5-cleansing-processing-gaps.md)
