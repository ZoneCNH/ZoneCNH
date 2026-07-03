# binance 模块运行时缺口修复主计划（PLAN-011）

> **生成日期**：2026-07-02（UTC，10 轮深度分析后定稿）
> **基线分支**：`fix/deps-matrix-drift`（主仓 ZoneCNH/ZoneCNH）/ `main`（runtime 仓 HEAD `f53303f`）
> **目标仓库**：**`ZoneCNH/ZoneCNH`（主仓）** — 所有 GitHub issue 同步到主仓而非 binance 仓
>
> **来源报告**：
> - `report/binance/REVIEW-PROMPT-20260702.md`（v2.1，1269 行，15 治理维度 + 11 已知陷阱）
> - `report/binance/DATA-INTEGRITY-E2E-20260701.md`（v3.9，6378 行，27 轮 200 维度对抗性自审，GAP-E1~E58）
> - `report/binance/EXCHANGEINFO-SYMBOL-TIER-ANALYSIS-20260702.md`（v1.0，448 行，symbol 分级体系）
>
> **方法论**：双口径治理（规格口径 48 Done / 运行时口径 58 Open，正交不矛盾）+ 漏洞链优先 + ROI 优先 + 分阶段交付 + 10 轮深度复核
>
> **总规模**：
> - **58 个运行时缺口**（GAP-E1~E58，55.25 人天实际求和 / RUNTIME-GAP-MATRIX §1 声称 73.5 天含 18.25 天误差）
> - **11 个治理陷阱**（T0-1~T10-1）
> - **15 条漏洞链**
> - **4 个 EXCHANGEINFO 勘误**（§8.1 options 语义 / §8.2 E25 倒置 / §8.3 白名单优先 / §8.4 置信度）
> - **8 阶段执行路径**（核心修复 49d + Phase 8 治理批次 32d ≈ 81d 总工时含治理）

---

## 0. 执行摘要

### 0.1 双口径判定

| 口径             | SSOT                                                  | 当前状态                                                            | 修复门槛                                  |
| ---------------- | ----------------------------------------------------- | ------------------------------------------------------------------- | ----------------------------------------- |
| **规格口径**     | `spec/SPEC.md` §22a + `matrix/TRACEABILITY.md` §4     | 48 Done / 0 Partial / `release_closeable=YES` / PRG-001~007 全 PASS | 已闭合，仅维护                            |
| **运行时口径**   | `module/binance/RUNTIME-GAP-MATRIX.md`（已落地，33k） | 58 Open（3 P0 + 13 P1 + 22 P2 + 20 P3）/ 15 漏洞链 / 55.25 人天实际求和 | 本计划核心目标                            |
| **综合发布判定** | `min(规格, 运行时)`                                   | **运行时口径未闭合 → L3 Production 待复核**                         | 0 P0 Open + 0~3 P1 Open 方可宣告"L3 真实" |

### 0.2 11 个已知陷阱现状（2026-07-02 10 轮核验）

> **REVIEW-PROMPT v2.1 line 1222 显式声明**：T0-1 ~ T10-1 共**十一个**已知陷阱验证点。

| 陷阱 ID         | 描述                                   | 现场核验结果                                                                                                                | 修复优先级                 |
| --------------- | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| **T0-1 / T8-1** | Runtime-Version 四处分裂               | ✅ **确认**：SPEC/README = v0.8.0，DEPLOY = v0.11.0（anchor: f53303f），实际 `git describe` = f53303f（**无 v0.11.0 tag**） | P0（状态分裂阻断 release） |
| **T1-1**        | CHANGELOG 比 SPEC 超前一版（GAP-E52）  | ✅ **确认**：CHANGELOG v3.9.7 > SPEC v3.9.6（违反单向追溯）                                                                 | P1（治理）                 |
| **T2-1**        | evidence 无 GAP-E 引用（GAP-E57）      | ✅ **确认**：`grep -rl "GAP-E" evidence/` = 0 文件                                                                          | P1（证据链）               |
| **T4-1**        | Task 计数矛盾（实际 39 vs README 47/47） | ✅ **确认**：`find tasks/ -name 'TASK-*.md' \| wc -l` = **39**，README 声明 **"47/47 tasks"**（**差 8 个**）              | P1（治理制品一致性）       |
| **T7-1**        | PRG-006 "全 PASS" vs todo.md "Partial"（历史） | ✅ **确认**：TRACEABILITY §4 标 PRG-006 PASS，原 todo.md L23 曾标 Partial（含 gated 测试说明），现 todo.md 已空                       | P0（状态分裂核心）         |
| **T7-2**        | v0.11.0 声明无对应 tag + shallow clone | ✅ **确认**：`git tag -l 'v*'` = 空；`git rev-parse --is-shallow-repository` = **true**（runtime 仓为 shallow clone，修复需先 `git fetch --unshallow`） | P0（PRG-002 实际不满足）   |
| **T8-2**        | SECURITY.md / CONTRIBUTING.md 缺失（GAP-E44/E45） | ✅ **确认**：模块根两者均 MISSING                                                                            | P1（治理）                 |
| **T8-3**        | BR 数量缩减（历史 9 → 现 5，GAP-E53） | ✅ **确认**：CHANGELOG line 566 声明 "BR-001/002/003/005/006/007/008/009 → Implemented"（8 个），当前 SPEC 仅 BR-001~BR-005（5 个），BR-006~009 静默删除 4 个 | P3（spec 完整性 + 治理信任） |
| **T9-1**        | TEST-ANALYSIS 报告描述与代码不符       | ⚠️ **部分确认**：报告含 2026-07-02 免责声明，部分描述与代码不符；原 todo.md 自爆但 SPEC 未同步降级；现 todo.md 已空        | P1（评分需下调）           |
| **T10-1**       | registry.yaml lifecycle/maturity 字段（GAP-E54 同源） | ⚠️ **看似已修复，实有真问题**：`lifecycle: production` + `maturity: L3` 已存在，但 **`release.latest_tag: v0.8.0` 与 DEPLOY v0.11.0 矛盾**（同源 T0-1）；需核 CHANGELOG 时间线 | P1（治理） |

### 0.3 GAP-E54/GAP-E55/GAP-E56 治理结构陷阱

| 缺口        | 现场核验                                                                                                                                                   | 影响               |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| **GAP-E54** | server/SPEC.md 仅 36 FR ≠ root 48 FR（**12 FR 未下沉**）                                                                                                   | 子规格覆盖不全     |
| **GAP-E55** | 模块根 `STANDARD.md` / `FEATURES.md` / `ACCEPTANCE.md` / `TRACEABILITY.md` **全部缺失**（注：`spec/FEATURES.md` 等在 spec/ 子目录存在，但顶层 4 个文档缺） | 治理制品结构不完整 |
| **GAP-E56** | `design/ADR-*.md` 仅有 ADR-002/003/004，**ADR-001 缺失**（编号跳过）                                                                                       | ADR 编号断层       |

### 0.4 EXCHANGEINFO 报告 §8 四项勘误

| 勘误                         | 内容                                                            | 落地方案                                                   |
| ---------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------- |
| **§8.1 options T4 语义错配** | 期权按 `(距到期天数, moneyness)` 分桶，不进 Tier 体系           | 新增 `options_classification` 维度 + decode 加 status 字段 |
| **§8.2 GAP-E25 依赖链倒置**  | E25 应为可选扩容，非 E24 下游依赖（分级后单副本富余）           | 修正依赖序：E6→E26→E24→[评估]→（可选）E25                  |
| **§8.3 静态白名单优先**      | 五级动态分级之前先做 STREAM_SYMBOLS 白名单 MVP（0.5d 覆盖 90%） | 分级为两阶段：白名单 MVP → 动态分级                        |
| **§8.4 勘误置信度**          | options 语义错配 HIGH / E25 倒置 HIGH / 白名单更优 MED          | 落地以 §8 修正为准，原文 §3-§7 保留作历史                  |

### 0.5 工时矛盾发现（10 轮复核新增）

**矛盾**：`RUNTIME-GAP-MATRIX.md §1 总览` 声称 **73.5 人天**，但实际 58 行 GAP-E 求和仅 **55.25 人天**，差 18.25 天。

**根因**：
- `RUNTIME-GAP-MATRIX.md §1` 的"总工时估算"可能为早期粗估，未随 GAP-E 拆分到位后同步更新
- `GAP-E4` 工时单位异常（`1h` 而非 `0.5d`/`1d`），求和时被当 0 处理
- 部分缺口工时可能在早期评估时偏高（如 GAP-E25 4d 实际在 §8.2 勘误后改为评估-大概率跳过）

**处置**：
- plan 工时分解以 Phase 估算为准（Phase 1=1.5d / Phase 2=0.5d / Phase 3=0d / Phase 4=2.5d / Phase 5=3.5d / Phase 6=4d / Phase 7=5d / Phase 8=32d，核心修复合计 49d）
- 已建 `RUNTIME-GAP-MATRIX.md §1 总览` 修复 follow-up（属于治理文档治理，纳入 Phase 8.10 P3）
- 实际求和 55.25 天与 plan Phase 总和基本一致

**置信度**：HIGH（求和已机器验证 `awk -F'|' '{...sum+=$8}'` = 55.25d）

### 0.6 严重度映射自身矛盾（10 轮复核新增）

**矛盾**：RUNTIME-GAP-MATRIX.md §1 总览 vs §严重度映射表：
- §1 声称：P0=3 / P1=**13** / P2=22 / P3=20
- §严重度映射表声称：P0=3 / P1=**10** / P2=? / P3=?

**核验**：按工时 ≥ 1d 的 HIGH 候选有 24 项（远超 13 也远超 10），实际 P1 应在 13~24 之间。

**处置**：本 plan 采用 §1 总览的 P1=13，并在 Phase 5/6/7 中显式列出 13 项 P1 GAP-E。详见 §1.3。

---

## 1. 修复路径（8 阶段）

### 1.1 阶段总览

```
Phase 1 [P0·治理分裂修复]   1.5d ─→ release_closeable 真实化（11 陷阱）
   ↓
Phase 2 [P0·GAP-E6 全量化]  0.5d ─→ ROI 最高，symbol 全量化前置
   ↓
Phase 3 [P0·GAP-E25 评估]   0d   ─→ §8.2 勘误后改为"评估单副本负载"，大概率不做
   ↓
Phase 4 [P0·GAP-E1 重构]    2.5d ─→ server 端 coverage SSOT
   ↓
Phase 5 [P1·独立可上批次]   3.5d ─→ GAP-E27/E32/E34/E36 + E29 并行（5 项）
   ↓
Phase 6 [P1·EXCHANGEINFO 分级 + interval SSOT] 4d ─→ E26→E24（白名单→动态分级）
   ↓
Phase 7 [P1·数据完整性链]   5d   ─→ GAP-E2/E3/E10/E12/E17/E18/E28（7 项）
   ↓
Phase 8 [P2+P3·治理与长尾]  32d  ─→ 剩余 38 项缺口 + 顶层文档补全
```

### 1.2 阶段依赖图（含漏洞链）

```
[Phase 1: 治理分裂]
   │
   ├──→ T0-1/T8-1 Runtime-Version 统一（前置：runtime 仓打 v0.11.0 tag）
   ├──→ T7-1 PRG-006 矛盾消除（TRACEABILITY §4 降级 PRG-006 为 Partial）
   ├──→ T7-2 补 v0.11.0 tag + GitHub Release（PRG-002 真实化，shallow clone 先 unshallow）
   ├──→ T1-1 CHANGELOG 回滚到 v3.9.6 或 SPEC bump 到 v3.9.7（同 PR）
   ├──→ T2-1 evidence 引用 GAP-E（运行时口径闭环）
   ├──→ T4-1 Task 计数对齐（39→47 或 47→39）
   ├──→ T8-2 补 SECURITY.md / CONTRIBUTING.md
   ├──→ T8-3 BR 数量决策（恢复 9 个或记录删除原因）
   ├──→ T9-1 SCORECARD 测试维度评分下调（93→85）
   └──→ T10-1 registry.yaml latest_tag 修正（依赖 T7-2）

[Phase 2: GAP-E6 symbol 全量化] ─→ 修复后 catalog 从 5 条 → 全量
   │
   ↓（前置：options decode 加 status 字段过滤 TRADING）
   │
[Phase 3: GAP-E25 评估] ─→ §8.2 勘误：分级后单副本 940 stream（2 连接）富余
   │   大概率跳过；保留为可选扩容路径
   ↓
[Phase 4: GAP-E1 v3.2 重构] ─→ server 端 coverage SSOT + client NATS 上报
   │
   ↓（前置：消除 GAP-E7 SPEC §75 vs §509 矛盾）
   │
[Phase 5: P1 独立可上批次] ─→ 5 项并行（无依赖）
   │
[Phase 6: EXCHANGEINFO 分级] ─→ 两阶段：白名单 MVP（0.5d）→ 动态分级（3.5d）
   │   ├── GAP-E26 interval SSOT（前置）
   │   ├── GAP-E24 Tier/SymbolPriority/Collection（核心）
   │   └── options_classification（§8.1 勘误，独立维度）
   ↓
[Phase 7: 数据完整性链] ─→ 7 项系列（含漏洞链）
   │   ├── GAP-E2 server CompletenessScanner
   │   ├── GAP-E3 E2E 二向对账 + OSS checksum
   │   ├── GAP-E10 catalog diff NATS pub/sub
   │   ├── GAP-E12 AckWait 提升 + backfill 小批次
   │   ├── GAP-E17 server time.Now() 强制 UTC
   │   ├── GAP-E18 TDengine 部分成功捕获
   │   └── GAP-E28 PG 事务管理
   ↓
[Phase 8: P2+P3 治理与长尾] ─→ 38 项剩余 + 顶层文档补全
```

### 1.3 P0/P1 显式清单（24 项核心修复）

| Phase | GAP-E / 陷阱 | 优先级 | 工时 | 依赖 |
|-------|-------------|--------|------|------|
| 1 | T0-1/T8-1 (Runtime-Version) | P0 | 0.25d | T7-2 (tag) |
| 1 | T7-1 (PRG-006) | P0 | 0.25d | — |
| 1 | T7-2 (v0.11.0 tag) | P0 | 0.5d | 用户授权 |
| 2 | GAP-E6 (ExchangeInfoRefresher 4 线) | P0 | 0.5d | — |
| 3 | GAP-E25 (评估单副本负载) | P0→deferred | 0d | GAP-E24 |
| 4 | GAP-E1 (coverage SSOT 重构) | P0 | 2.5d | GAP-E7/E10/E28 |
| 4 | GAP-E7 (SPEC §509 移除违宪文件) | P1 | 0.5d | — |
| 4 | GAP-E20 (drain) | P1 | 1.5d | 同 GAP-E1 PR |
| 5 | GAP-E27 (WS SetReadLimit) | P1 | 0.5d | — |
| 5 | GAP-E29 (golang-migrate) | P1 | 1.5d | — |
| 5 | GAP-E32 (goroutine recover) | P1 | 0.5d | — |
| 5 | GAP-E34 (HTTP 完整超时) | P1 | 0.5d | — |
| 5 | GAP-E36 (ldflags buildinfo) | P1 | 1d | — |
| 6 | GAP-E24 (动态分级) | P1 | 2.5d | GAP-E26 + GAP-E6 |
| 6 | GAP-E26 (interval SSOT) | P1 | 1.5d | — |
| 7 | GAP-E2 (CompletenessScanner) | P1 | 2d | GAP-E6/E23 |
| 7 | GAP-E3 (E2E 对账) | P1 | 1d | GAP-E1/E2/E6/E10 |
| 7 | GAP-E10 (catalog diff NATS) | P1 | 2d | GAP-E1 |
| 7 | GAP-E12 (AckWait 5min) | P1 | 1.5d | — |
| 7 | GAP-E17 (UTC 强制) | P1 | 0.5d | — |
| 7 | GAP-E18 (TDengine 部分成功) | P1 | 1d | 同 GAP-E19 PR |
| 7 | GAP-E19 (PayloadHash server 重算) | P1 | 0.5d | — |
| 7 | GAP-E28 (PG 事务管理) | P1 | 2d | — |
| Phase 8.1~8.10 | 38 项 P2+P3 | P2/P3 | 32d | — |

**合计**：核心 P0/P1 修复 ≈ 17d（含 4 项治理陷阱另算 1.5d） + Phase 8 长尾 32d = 49d

---

## 2. 同步策略（主仓 ZoneCNH/ZoneCNH）

### 2.1 仓库选择裁决

**用户指示（10 轮分析后确认）**：所有 issue 同步到 **`ZoneCNH/ZoneCNH` 主仓**（即本仓库）。

**历史背景**：之前已将 35 个 issue 同步到 `ZoneCNH/binance` 子仓（#365~#402），10 轮分析后改为全部在主仓新建（编号 #1463 起）。binance 仓的 #365~#402 保留不删（避免破坏历史），新 issue 通过 cross-reference 引用。

### 2.2 主仓 labels（已就绪）

```
phase-1 ~ phase-8（8 个）+ runtime-gap + governance-trap + p0/p1/p2/P3 + independent
```

### 2.3 同步执行

详见 `011-sync-master-issues.sh`（批量创建主仓 issues）+ `011-master-issue-map.tsv`（编号映射）。

---

## 3. 验收门槛

| 门槛 | 标准 | 验证命令 |
|------|------|----------|
| Phase 1 完成 | 11 陷阱全部 close + cross-reference | `gh issue list -R ZoneCNH/ZoneCNH --label governance-trap --state closed` |
| Phase 2 完成 | catalog 全量 + options status 过滤 | runtime 仓 `grep -rn "ExchangeInfoRefresher" internal/client/runtime.go` 含 4 线 |
| Phase 3 完成 | §8.2 评估文档 + 大概率 deferred | 评估报告 `report/binance/gap-e25-evaluation.md` |
| Phase 4 完成 | history_state_postgres.go 删除 + server coverage store 落地 | runtime 仓 `ls internal/client/history_state_postgres.go` 不存在 |
| Phase 5 完成 | 5 项 P1 独立完成 | `gh issue list -R ZoneCNH/ZoneCNH --label independent --state closed` ≥ 5 |
| Phase 6 完成 | STREAM_SYMBOLS 白名单 + 动态分级 | binancecfg.STREAM_SYMBOLS 存在 + CatalogEntry.Tier 字段 |
| Phase 7 完成 | 7 项数据完整性链闭合 | TDengine 双写漏洞链测试 PASS |
| Phase 8 完成 | 38 项 P2/P3 + 顶层文档 | STANDARD/FEATURES/ACCEPTANCE/TRACEABILITY 顶层 4 文档存在 |
| **综合 L3** | **0 P0 Open + ≤3 P1 Open** | `gh issue list -R ZoneCNH/ZoneCNH --label runtime-gap --search "P0 in:title" --state open` = 0 |

---

## 4. 风险与缓解

| 风险 | 缓解 |
|------|------|
| v0.11.0 tag 创建需要用户授权 | 在主仓 issue 中显式标注 "needs-user-authorization"，等待用户授权 |
| shallow clone 阻断 tag 创建 | T7-2 修复时先 `git fetch --unshallow` |
| 58 GAP-E 工时 73.5 vs 55.25 矛盾 | 已在 §0.5 显式记录，工时分解以 Phase 估算为准 |
| P1=13 vs P1=10 矛盾 | 已在 §0.6 显式记录，本 plan 采用 P1=13 |
| 同步到主仓 vs binance 仓的混乱 | 10 轮分析后用户明确选择主仓，binance 仓保留历史 cross-reference |
| 跨 PR 同步（漏洞链同 PR 要求） | bd dep add 配置依赖，PR review 时强制核验 |

---

## 5. 后续工作

- 主仓 issue 已同步到 #1540~#1592，后续按 GitHub/Beads 作为关闭 SSOT 持续对账
- `module/binance/todo.md` 维持 read-only projection，仅做状态镜像不作为关闭依据
- beads gg63 树继续保留，用于主仓 issue 的双向映射与跨会话跟踪

---

**Plan 状态**：✅ 定稿（10 轮深度分析后）
**下一步**：按 Phase 4 起始 open issue 执行闭环，并定期回刷 011 映射表
