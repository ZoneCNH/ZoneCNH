# binance 模块运行时缺口修复执行计划（PLAN-010）

> **生成日期**：2026-07-02（UTC）
> **基线分支**：`fix/deps-matrix-drift`（主仓）/ `main`（runtime 仓 HEAD `f53303f`）
> **来源报告**：
>
> - `report/binance/REVIEW-PROMPT-20260702.md`（v2.0，1187 行，15 治理维度 + 9 已知陷阱）
> - `report/binance/DATA-INTEGRITY-E2E-20260701.md`（v3.9，6378 行，27 轮 200 维度自审，GAP-E1~E58）
> - `report/binance/EXCHANGEINFO-SYMBOL-TIER-ANALYSIS-20260702.md`（v1.0，448 行，symbol 分级体系）
>   **目标**：将 58 个运行时缺口（GAP-E1~E58）+ **11 个治理陷阱（T0-1~T10-1，含本轮 5 轮复核新增 T10-1 与 T8-3 修正）** + 4 个 EXCHANGEINFO 勘误转化为可执行的 beads issue 树与 GitHub issue 同步流程
>   **预计总工时**：**55.25 人天**（实际 58 行 GAP-E 求和，§0.5 工时矛盾说明）/ RUNTIME-GAP-MATRIX §1 总览声称 73.5 天（含 18.25 天误差，已发现未修正前 plan 沿用此数）/ 治理陷阱 11 项另计约 8.5d
>   **方法论**：双口径治理（规格口径 48 Done / 运行时口径 58 Open，正交不矛盾）+ 漏洞链优先 + ROI 优先 + 分阶段交付

---

## 0. 执行摘要

### 0.1 双口径判定

| 口径             | SSOT                                                  | 当前状态                                                            | 修复门槛                                  |
| ---------------- | ----------------------------------------------------- | ------------------------------------------------------------------- | ----------------------------------------- |
| **规格口径**     | `spec/SPEC.md` §22a + `matrix/TRACEABILITY.md` §4     | 48 Done / 0 Partial / `release_closeable=YES` / PRG-001~007 全 PASS | 已闭合，仅维护                            |
| **运行时口径**   | `module/binance/RUNTIME-GAP-MATRIX.md`（已落地，33k） | 58 Open（3 P0 + 13 P1 + 22 P2 + 20 P3）/ 15 漏洞链 / **55.25 人天实际求和**（§1 总览声称 73.5 天存在 18.25 天误差，详见 §0.5）      | 本计划核心目标                            |
| **综合发布判定** | `min(规格, 运行时)`                                   | **运行时口径未闭合 → L3 Production 待复核**                         | 0 P0 Open + 0~3 P1 Open 方可宣告"L3 真实" |

### 0.2 11 个已知陷阱现状（2026-07-02 现场核验，REVIEW-PROMPT v2.1 + 5 轮深度复核）

> **v2.1 显式声明（line 1222）**：T0-1 ~ T10-1 共**十一个**已知陷阱验证点须逐一确认。

| 陷阱 ID         | 描述                                   | 现场核验结果                                                                                                                | 修复优先级                 |
| --------------- | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| **T0-1 / T8-1** | Runtime-Version 四处分裂               | ✅ **确认**：SPEC/README = v0.8.0，DEPLOY = v0.11.0（anchor: f53303f），实际 `git describe` = f53303f（**无 v0.11.0 tag**） | P0（状态分裂阻断 release） |
| **T1-1**        | CHANGELOG 比 SPEC 超前一版（GAP-E52）  | ✅ **确认**：CHANGELOG v3.9.7 > SPEC v3.9.6（违反单向追溯）                                                                 | P1（治理）                 |
| **T2-1**        | evidence 无 GAP-E 引用（GAP-E57）      | ✅ **确认**：`grep -rl "GAP-E" evidence/` = 0 文件                                                                          | P1（证据链）               |
| **T4-1** ✨v2.1  | Task 计数矛盾（实际 39 vs README 47/47） | ✅ **确认**：`find tasks/ -name 'TASK-*.md' \| wc -l` = **39**，README 声明 **"47/47 tasks"**（**差 8 个**）              | P1（治理制品一致性）       |
| **T7-1**        | PRG-006 "全 PASS" vs todo.md "Partial" | ✅ **确认**：TRACEABILITY §4 标 PRG-006 PASS，todo.md L23 标 Partial（含详细 gated 测试说明）                               | P0（状态分裂核心）         |
| **T7-2**        | v0.11.0 声明无对应 tag + shallow clone | ✅ **确认**：`git tag -l 'v*'` = 空；`git rev-parse --is-shallow-repository` = **true**（runtime 仓为 shallow clone，修复需先 `git fetch --unshallow` 拉取完整历史再打 tag） | P0（PRG-002 实际不满足）   |
| **T8-2**        | SECURITY.md / CONTRIBUTING.md 缺失（GAP-E44/E45） | ✅ **确认**：模块根两者均 MISSING                                                                            | P1（治理）                 |
| **T8-3** 🔧v2.1 修正 | BR 数量缩减（历史 9 → 现 5，GAP-E53） | ✅ **修正确认**：CHANGELOG line 566 声明 "BR-001/002/003/005/006/007/008/009 → Implemented"（8 个），当前 SPEC 仅 BR-001~BR-005（5 个），BR-006~009 静默删除 4 个。**之前 plan 误写为"缺 BR-008"已修正**。 | P3（spec 完整性 + 治理信任） |
| **T9-1**        | TEST-ANALYSIS 报告描述与代码不符       | ✅ **已在 todo.md L26-32 显式声明**（soak/chaos/security 复核修正），属于已自爆但 SPEC 未同步降级                           | P1（评分需下调）           |
| **T10-1** ✨v2.0 §10.3 | registry.yaml lifecycle/maturity 字段（GAP-E54 同源） | ⚠️ **看似已修复，需深度核验**：`lifecycle: production` + `maturity: L3` 已存在，但 (a) release.latest_tag=v0.8.0 与 DEPLOY v0.11.0 矛盾（同源 T0-1）；(b) 需核验 CHANGELOG 时间线与 registry.yaml 实际提交一致性；(c) 与 `.foundationx/status/index.json` 一致性 | P1（治理） |

> **v2.1 增量（2026-07-02 +32 行 + 5 轮深度复核）**：
> - **新增 T4-1**（Task 计数矛盾，已建 #400）
> - **新增 T10-1**（registry.yaml 字段核验，v2.0 §10.3 已存在但本轮 5 轮复核发现 plan/beads/GitHub 三方都漏，已建 #401）
> - **T7-2 扩展** shallow clone 检测（runtime 仓为 shallow clone）
> - **T8-3 描述修正**：从"缺 BR-008"修正为"BR 9→5 缩减"（CHANGELOG line 566 声明 vs 实际 SPEC 不一致），已建 #402
> - **缺口计数方法**：从 `grep -c GAP-E` 改为 `grep -oE 'GAP-E[0-9]+' | sort -u | wc -l`（唯一 ID 计数），新方法核验 58 仍准确（旧方法 106 含重复引用）

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

### 0.5 工时矛盾发现（5 轮复核新增）

**矛盾**：`RUNTIME-GAP-MATRIX.md §1 总览` 声称 **73.5 人天**，但实际 58 行 GAP-E 求和仅 **55.25 人天**，差 18.25 天。

**根因**：
- `RUNTIME-GAP-MATRIX.md §1` 的"总工时估算"可能为早期粗估，未随 GAP-E 拆分到位后同步更新
- `GAP-E4` 工时单位异常（`1h` 而非 `0.5d`/`1d`），求和时被当 0 处理（实际应贡献 ~0.125d）
- 部分缺口工时可能在早期评估时偏高（如 GAP-E25 4d 实际在 §8.2 勘误后改为评估-大概率跳过）

**处置**：
- plan 工时分解（Phase 1=1.5d / Phase 2=0.5d / Phase 3=0d / Phase 4=2.5d / Phase 5=3.5d / Phase 6=4d / Phase 7=5d / Phase 8=32d）以 Phase 估算为准，不依赖 §1 总览
- 已建 `RUNTIME-GAP-MATRIX.md §1 总览` 修复 follow-up（属于治理文档治理，纳入 Phase 8.10 P3 治理文档批次）
- 实际求和 55.25 天与 plan Phase 总和（约 49d 核心修复 + Phase 8 治理批次）基本一致

**置信度**：HIGH（求和已机器验证 `awk -F'|' '{...sum+=$8}'` = 55.25d）

---

## 1. 修复路径（8 阶段）

### 1.1 阶段总览

```
Phase 1 [P0·治理分裂修复]   1.5d ─→ release_closeable 真实化
   ↓
Phase 2 [P0·GAP-E6 全量化]  0.5d ─→ ROI 最高，symbol 全量化前置
   ↓
Phase 3 [P0·GAP-E25 评估]   0d   ─→ §8.2 勘误后改为"评估单副本负载"，大概率不做
   ↓
Phase 4 [P0·GAP-E1 重构]    2.5d ─→ server 端 coverage SSOT
   ↓
Phase 5 [P1·独立可上批次]   3.5d ─→ GAP-E27/E32/E34/E36 + E29 并行
   ↓
Phase 6 [P1·EXCHANGEINFO 分级 + interval SSOT] 4d ─→ E26→E24（白名单→动态分级）
   ↓
Phase 7 [P1·数据完整性链]   5d   ─→ GAP-E2/E3/E10/E12/E17/E18/E28
   ↓
Phase 8 [P2+P3·治理与长尾]  32d  ─→ 剩余 38 项缺口 + 顶层文档补全
```

### 1.2 阶段依赖图（含漏洞链）

```
[Phase 1: 治理分裂]
   │
   ├──→ T0-1/T8-1 Runtime-Version 统一（前置：runtime 仓打 v0.11.0 tag）
   ├──→ T7-1 PRG-006 矛盾消除（TRACEABILITY §4 降级 PRG-006 为 Partial）
   ├──→ T7-2 补 v0.11.0 tag + GitHub Release（PRG-002 真实化）
   ├──→ T1-1 CHANGELOG 回滚到 v3.9.6 或 SPEC bump 到 v3.9.7（同 PR）
   ├──→ T2-1 evidence 引用 GAP-E（运行时口径闭环）
   ├──→ T8-2 补 SECURITY.md / CONTRIBUTING.md
   └──→ T9-1 SCORECARD 测试维度评分下调（93→85）

[Phase 2: GAP-E6 symbol 全量化] ─→ 修复后 catalog 从 5 条 → 全量（spot ~2000+ / um ~400+ / cm ~100+ / options ~数万）
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
[Phase 5: P1 独立可上批次] ─→ 6 项并行（无依赖）
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

### 1.3 漏洞链（15 条）— 优先修复

| #   | 链路                     | 组成                 | 阶段        |
| --- | ------------------------ | -------------------- | ----------- |
| 1   | TDengine 数据双写漏洞链  | E12 + E18 + E19      | Phase 7     |
| 2   | catalog/coverage SSOT 链 | E1 + E10 + E20       | Phase 4 + 7 |
| 3   | schema 演进链            | E8 + E19 + E23       | Phase 8     |
| 4   | WebSocket OOM 链         | E27 + E11            | Phase 5     |
| 5   | 数据原子性链             | E28 + E18 + E1       | Phase 7     |
| 6   | 运维治理链               | E29 + E30 + E9       | Phase 5 + 8 |
| 7   | 配置硬编码链             | E31 + E8 + E4        | Phase 8     |
| 8   | panic 传播链             | E32 + E30            | Phase 5     |
| 9   | 熔断缺失链               | E33 + E11            | Phase 8     |
| 10  | 运维可观测链             | E36 + E30 + E29      | Phase 5 + 8 |
| 11  | HTTP DoS 链              | E34 + E27            | Phase 5     |
| 12  | CSRF 安全链              | E37 + E44            | Phase 8     |
| 13  | EXCHANGEINFO 量级链      | E6 + E24 + E26       | Phase 2 + 6 |
| 14  | PG 数据完整性链          | E28 + E18 + E23      | Phase 7     |
| 15  | PRG-007 假阳性链         | E58（元缺口） + T7-1 | Phase 1     |

---

## 2. Phase 详细分解

### Phase 1: 治理分裂修复（P0，1.5d）

**目标**：消除 6 处状态分裂，让 release_closeable 真实可信。

**子任务**：

| ID    | 子任务                                                                                    | 工时 | 产出                                               |
| ----- | ----------------------------------------------------------------------------------------- | ---- | -------------------------------------------------- |
| P1.1  | runtime 仓 `git tag v0.11.0 f53303f && gh release create v0.11.0`                         | 0.2d | v0.11.0 tag + GitHub Release notes（修复 PRG-002） |
| P1.2  | SPEC.md L7 Runtime-Version 改为 v0.11.0 + anchor 对齐                                     | 0.1d | spec/SPEC.md L7                                    |
| P1.3  | README.md L6 Runtime-Version 同步 v0.11.0                                                 | 0.1d | module/binance/README.md L6                        |
| P1.4  | DEPLOY.md 不动（已 v0.11.0）                                                              | 0d   | —                                                  |
| P1.5  | CHANGELOG Module-Version 回滚到 v3.9.6（与 SPEC 一致），或 SPEC bump 到 v3.9.7（推荐）    | 0.2d | SPEC.md + CHANGELOG.md 同 PR                       |
| P1.6  | TRACEABILITY.md §4 PRG-006 从 PASS 改为 **Partial**（与 todo.md 一致）+ 加 gated 测试说明 | 0.3d | matrix/TRACEABILITY.md §4                          |
| P1.7  | TRACEABILITY.md §4 release_closeable 公式后加"运行时口径注脚"                             | 0.1d | matrix/TRACEABILITY.md §4                          |
| P1.8  | evidence/ 目录补 GAP-E 引用（≥3 个 evidence 文件引用 GAP-E 编号）                         | 0.3d | evidence/2026-07-02/runtime-gap-closure.md         |
| P1.9  | 新建 SECURITY.md（基于 `gate/SECURITY.md` 或独立写）                                      | 0.1d | module/binance/SECURITY.md                         |
| P1.10 | 新建 CONTRIBUTING.md（CONSTITUTION §0 + 分支纪律 + PR 规范）                              | 0.1d | module/binance/CONTRIBUTING.md                     |

**验收**：

- `git -C /home/workspace/binance tag -l 'v*'` 输出含 v0.11.0
- SPEC/README/DEPLOY 三处 Runtime-Version 全部为 v0.11.0
- TRACEABILITY §4 PRG-006 = Partial
- evidence/ 至少 1 个文件含 GAP-E 引用
- SECURITY.md / CONTRIBUTING.md 存在且 ≥ 50 行

**风险**：v0.11.0 tag 创建后不可删除（已在生产部署）；如需回滚需用 v0.11.1 而非删除。

---

### Phase 2: GAP-E6 symbol 全量化（P0，0.5d）

> **报告定位**：`DATA-INTEGRITY-E2E-20260701.md` §6.6（v3.1 新增）
> **源码改动点**：`internal/client/runtime.go:199-217`（仅 spot 装配）+ `exchangeinfo_option.go:30-36`（无 status 字段）

**子任务**：

| ID   | 子任务                                                                                  | 工时 |
| ---- | --------------------------------------------------------------------------------------- | ---- |
| P2.1 | `exchangeinfo_option.go:30-36` 加 `Status string` 字段 + L74-84 加 `TRADING` 过滤       | 0.1d |
| P2.2 | `runtime.go:199-217` 改为 `for _, pl := range []string{spot, um, cm, options}` 循环装配 | 0.2d |
| P2.3 | cmd/binance-client/main.go 加 `ProductLine` 多选配置项（逗号分隔）                      | 0.1d |
| P2.4 | 测试：扩展 `runtime_test.go` 覆盖 4 线 refresher 装配验证                               | 0.1d |

**验收**：

- `grep -n "ProductLineSpot" internal/client/runtime.go` ≤ 1 处（仅常量定义）
- 4 线 refresher 启动后 `len(catalog)` 显著增长（spot > 1000 / um > 400 / cm > 100 / options > 1000）
- options TRADING 过滤生效（catalog 中 options entry 全部 `status="active"`）

---

### Phase 3: GAP-E25 评估（§8.2 勘误，0d）

> **关键修订**：根据 EXCHANGEINFO 报告 §8.2，GAP-E25 在分级（E24）落地后**不再是必做项**。
> 分级后单副本 WS = 940 stream（2 连接），REST 冷启动 ~60K 请求（8h），单副本富余。

**子任务**：

| ID   | 子任务                                                | 工时       |
| ---- | ----------------------------------------------------- | ---------- |
| P3.1 | 分级（Phase 6）落地后，监控单副本资源占用 1 周        | 0d（监控） |
| P3.2 | 若 WS 连接数 > 5 或 REST budget > 80%，则启动 GAP-E25 | 仅条件触发 |
| P3.3 | 若 1 周内业务增长到 T0+T1 = 500 symbol，重新评估      | 仅条件触发 |

**验收**：

- 1 周内单副本资源占用 < 60% → 不实施 GAP-E25，标记为 `deferred`
- 资源紧张 → 启动 GAP-E25 一致性哈希分片（4d）

---

### Phase 4: GAP-E1 v3.2 重构（P0，2.5d）

> **报告定位**：`DATA-INTEGRITY-E2E-20260701.md` §6.1
> **核心**：删除 `internal/client/history_state_postgres.go`（违宪），server 端持久化 coverage，client NATS 上报

**前置依赖**：GAP-E7（SPEC §75 vs §509 矛盾裁决，0.5d）

**子任务**：

| ID   | 子任务                                                                      | 工时 |
| ---- | --------------------------------------------------------------------------- | ---- |
| P4.0 | GAP-E7：SPEC §509 文件清单移除 `history_state_postgres.go`                  | 0.1d |
| P4.1 | server 端新建 `internal/server/coverage/store.go`：PG 持久化 coverage 状态  | 0.5d |
| P4.2 | server 端 NATS subscriber：监听 `binance.coverage.heartbeat` subject        | 0.4d |
| P4.3 | client 端 `internal/client/coverage_reporter.go`：周期上报 coverage 到 NATS | 0.5d |
| P4.4 | 删除 `internal/client/history_state_postgres.go`（违宪文件）                | 0.1d |
| P4.5 | cmd/binance-client/main.go 移除 postgresx 装配                              | 0.2d |
| P4.6 | 测试：单元测试（store + reporter）+ 集成测试（NATS 心跳）                   | 0.7d |
| P4.7 | 验证：`grep -rn "postgresx\." internal/client/` = 0 命中                    | 0.1d |

**验收**：

- `grep -rn "history_state_postgres" internal/client/` = 0
- `grep -rn "postgresx\." internal/client/` = 0
- server 端 coverage 表存在 + client 上报后可查询
- gap repair 路径消费 server-side coverage（非 client-side）

---

### Phase 5: P1 独立可上批次（3.5d）

> **特征**：6 项 P1/P0 缺口**无相互依赖**，可并行开发、独立 PR。

| GAP         | 子任务                                                                                  | 工时 | 文件                                                                                                                                                  |
| ----------- | --------------------------------------------------------------------------------------- | ---- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **GAP-E32** | 7 处 goroutine 加 `defer recover()` 包装                                                | 0.5d | client/runtime.go / server/admin.go / history_lifecycle.go / lifecycle_worker.go / client/admin.go / controlplane/lifecycle.go / assembly/assemble.go |
| **GAP-E27** | WebSocket `SetReadLimit(10 * 1024 * 1024)` + json.Decoder 大小校验                      | 0.5d | internal/client/spot.go（或 stream_control.go）                                                                                                       |
| **GAP-E34** | HTTP server 加 `ReadTimeout: 10s / WriteTimeout: 30s / IdleTimeout: 120s`               | 0.5d | internal/client/admin.go:87 + internal/server/admin.go:65                                                                                             |
| **GAP-E36** | Makefile 加 `ldflags` 注入 `gitCommit/buildtime/version` + 主路径加 `buildinfo` package | 1d   | Makefile + internal/buildinfo/buildinfo.go + cmd/\*/main.go                                                                                           |
| **GAP-E29** | 集成 `golang-migrate/migrate/v4`，10 个 .sql 自动执行                                   | 1.5d | internal/server/storage/migrations/ + cmd/binance-server/migrate.go                                                                                   |
| **GAP-E6**  | （Phase 2 已完成）                                                                      | 0d   | —                                                                                                                                                     |

**验收（每项独立）**：

- GAP-E32：`grep -rn "go func()" internal/ | wc -l` ≤ `grep -rn "recover()" internal/ | wc -l`
- GAP-E27：`grep -n "SetReadLimit" internal/client/` ≥ 1
- GAP-E34：admin.go HTTP server 配置含 ReadTimeout/WriteTimeout/IdleTimeout 三超时
- GAP-E36：`binance-client --version` 输出 git commit + buildtime
- GAP-E29：`binance-server migrate up` 后所有 schema 就绪

---

### Phase 6: EXCHANGEINFO 分级（P1，4d）

> **报告定位**：`EXCHANGEINFO-SYMBOL-TIER-ANALYSIS-20260702.md` §3-§4 + §8 勘误
> **核心**：先白名单 MVP（0.5d 覆盖 90%），再动态分级（3.5d 覆盖 100%）

**子任务**：

| ID                                    | 子任务                                                                                                     | 工时 |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ---- |
| **6.0 interval SSOT（前置）**         |                                                                                                            |      |
| P6.0.1                                | GAP-E26：新建 `internal/client/intervals.go` SSOT 常量                                                     | 0.2d |
| P6.0.2                                | GAP-E26：4 处独立定义改为引用 SSOT（product_line / history_rest / mapper / 测试）                          | 0.3d |
| P6.0.3                                | GAP-E26：`eventTypeToInterval()` 解析 eventType 后缀，去除 `1m` 硬编码 fallback                            | 0.5d |
| P6.0.4                                | GAP-E26：mapper `coalesce(ev.Bar.Interval, "1m")` 改为严格模式（缺字段返回 error）                         | 0.2d |
| P6.0.5                                | GAP-E26：WebSocket RequiredBarIntervals 扩展到 9 个标准 interval                                           | 0.3d |
| **6.1 白名单 MVP（§8.3 路径）**       |                                                                                                            |      |
| P6.1.1                                | binancecfg 加 `STREAM_SYMBOLS` 配置字段（逗号分隔 symbol 列表）                                            | 0.1d |
| P6.1.2                                | stream_control.go:337 加白名单过滤（仅白名单内 symbol 进 WS 订阅）                                         | 0.2d |
| P6.1.3                                | 配置文档 + .env.example 更新                                                                               | 0.1d |
| P6.1.4                                | 单元测试：白名单生效 + 空白名单回退全量                                                                    | 0.1d |
| **6.2 动态分级（核心）**              |                                                                                                            |      |
| P6.2.1                                | GAP-E24：CatalogEntry 加 `Tier int / SymbolPriority int / Collection string / QuoteVolumeUSD float64` 字段 | 0.3d |
| P6.2.2                                | GAP-E24：spot/um/cm decode 结构体加 `QuoteVolume string` 字段（Binance 原始 JSON 已含）                    | 0.3d |
| P6.2.3                                | GAP-E24：实现 `classifyTier(symbol, quoteAsset, quoteVolumeUSD)` 三层降级算法                              | 0.5d |
| P6.2.4                                | GAP-E24：binancecfg 加 `tiers` YAML 配置结构                                                               | 0.4d |
| P6.2.5                                | GAP-E24：lifecycle.go SyncCatalog 加 `Collection != "disabled"` 过滤                                       | 0.2d |
| P6.2.6                                | GAP-E24：lifecycle.go 加 `tierEnabled(productLine, tier)` 谓词                                             | 0.2d |
| P6.2.7                                | GAP-E24：stream_control.go 按 `Collection ∈ {full_stream, stream_no_depth, kline_only}` 过滤               | 0.3d |
| P6.2.8                                | GAP-E24：新增 `activeSymbolsByProductLineAndTier` 替代全量                                                 | 0.3d |
| **6.3 options 独立维度（§8.1 勘误）** |                                                                                                            |      |
| P6.3.1                                | 新建 `internal/client/options_classification.go`：按 `(距到期天数, moneyness)` 分桶                        | 0.5d |
| P6.3.2                                | options refresher 装配 `OptionsClassification` 字段（不进 Tier）                                           | 0.2d |
| P6.3.3                                | lifecycle options 路由：近月 ATM → stream / 远月 OTM → REST 不采                                           | 0.3d |

**验收**：

- WS 订阅数从全量 8000 降到分级后 ~940（T0+T1+T2）
- options decode 加 status 过滤
- 配置白名单与动态分级共存（白名单优先）

---

### Phase 7: 数据完整性链（P1，5d）

> **目标**：闭合漏洞链 #1/#2/#4/#5/#14

| GAP         | 子任务摘要                                                                            | 工时 |
| ----------- | ------------------------------------------------------------------------------------- | ---- |
| **GAP-E2**  | server 新建 `internal/server/completeness/scanner.go` CompletenessScanner             | 2d   |
| **GAP-E3**  | E2E 二向对账 reconciler + OSS checksum 校验                                           | 1d   |
| **GAP-E10** | catalog diff NATS 发布 `binance.catalog.diff` + server 订阅                           | 2d   |
| **GAP-E12** | AckWait 30s → 5min（匹配 backfill timeout）+ backfill 小批次（每批 ≤ 100 symbol）     | 1.5d |
| **GAP-E17** | server 关键路径 `time.Now()` → `time.Now().UTC()`（25+ 处）                           | 0.5d |
| **GAP-E18** | TDengine WriteBatch 捕获 `Partial=true` 不重投（重投会触发 idempotency hash 不同）    | 1d   |
| **GAP-E28** | PG 事务：`internal/server/storage/pg_tx.go` 提供 `WithTx(fn func(pgx.Tx) error)` 包装 | 2d   |

**验收**：

- E2E 对账脚本输出 gap 明细（report/binance/e2e-reconcile-\*.md）
- TDengine 部分成功有 metric `binance_storage_partial_writes_total`
- PG 多步写入通过事务原子性测试（任一步失败回滚）

---

### Phase 8: P2+P3 治理与长尾（32d）

> **范围**：剩余 38 项缺口（22 P2 + 20 P3 - 已在 Phase 5/6/7 完成数）+ 顶层文档补全

**P2 集中批次**（按类型分组，每组独立 PR）：

| 批次                 | 包含 GAP                                                                              | 工时 |
| -------------------- | ------------------------------------------------------------------------------------- | ---- |
| **8.1 可观测性补强** | E9（client metrics 聚合）+ E30（pprof/debug endpoint）+ E35（metric 命名规范化）      | 3d   |
| **8.2 安全加固**     | E37（CSRF 防护）+ E44（SECURITY.md）+ E45（CONTRIBUTING.md）                          | 1.5d |
| **8.3 部署治理**     | E41/E42/E43（probe 深度）+ E46~E50（容器 hardening）                                  | 4d   |
| **8.4 Schema 演进**  | E8（SchemaVersion 配置化）+ E19（PayloadHash server 重算）+ E23（精度校验）           | 4d   |
| **8.5 配置治理**     | E31（NATS 拓扑配置化）+ E4（throttle 配置化）                                         | 2d   |
| **8.6 容错与韧性**   | E11（REST endpoint fallback）+ E16（启动 retry 指数退避）+ E33（resiliencx 熔断接入） | 3d   |
| **8.7 优雅运行**     | E14（retention cron）+ E15（内存预算）+ E20（drain）+ E22（背压）                     | 3.5d |
| **8.8 测试与质量**   | E21（CI race 强制）+ E40（HTTP client timeout）                                       | 1d   |
| **8.9 长尾低优**     | E38（regexp 包级 var）+ E39（错误链 %w）                                              | 0.5d |

**P3 治理文档批次**：

| 缺口        | 子任务                                                                                                       | 工时 |
| ----------- | ------------------------------------------------------------------------------------------------------------ | ---- |
| **GAP-E51** | SPEC 加引用 CONSTITUTION §N 章节号                                                                           | 0.2d |
| **GAP-E52** | CHANGELOG / SPEC 版本单向追溯声明（已在 Phase 1 解决）                                                       | 0d   |
| **GAP-E53** | BR 编号补全（BR-006~BR-008 业务规则扩展）                                                                    | 0.5d |
| **GAP-E54** | spec/server/SPEC.md 补齐 12 FR 下沉（48 = 36 + 12）                                                          | 1d   |
| **GAP-E55** | 顶层 STANDARD.md / FEATURES.md / ACCEPTANCE.md / TRACEABILITY.md 补全（或在文档结构上声明"在 spec/ 子目录"） | 1d   |
| **GAP-E56** | ADR-001 补建（编号连续）                                                                                     | 0.5d |
| **GAP-E57** | evidence GAP-E 引用（已在 Phase 1 解决）                                                                     | 0d   |
| **GAP-E58** | issue close 时强制校验 runtime gap closure（脚本 + CONTRIBUTING 流程）                                       | 0.5d |

**验收（每批次）**：

- 单批次对应 CI gate PASS
- RUNTIME-GAP-MATRIX.md 状态从 Open 改为 Fixed
- evidence/ 目录补对应批次 evidence

---

## 3. Beads Issue 拆解方案

### 3.1 Epic 结构

```
[EPIC] binance runtime gap closure（PRG-007 真实化）
  ├── [EPIC] Phase 1: 治理分裂修复（1.5d）
  │     ├── [TASK] T0-1/T8-1: Runtime-Version 统一（含 v0.11.0 tag）
  │     ├── [TASK] T1-1: CHANGELOG/SPEC 版本对齐
  │     ├── [TASK] T7-1: PRG-006 TRACEABILITY §4 降级 Partial
  │     ├── [TASK] T7-2: 补 v0.11.0 GitHub Release
  │     ├── [TASK] T2-1: evidence GAP-E 引用补齐
  │     ├── [TASK] T8-2: SECURITY.md + CONTRIBUTING.md
  │     └── [TASK] T9-1: SCORECARD 测试维度评分下调
  │
  ├── [TASK] Phase 2: GAP-E6 symbol 全量化（0.5d）
  │     ├── [SUBTASK] options decode 加 status 字段
  │     ├── [SUBTASK] runtime.go 4 线 refresher 循环装配
  │     └── [SUBTASK] cmd 加 ProductLine 多选
  │
  ├── [TASK] Phase 3: GAP-E25 评估（0d，监控触发）
  │
  ├── [EPIC] Phase 4: GAP-E1 v3.2 重构（2.5d）
  │     ├── [SUBTASK] P4.0: GAP-E7 SPEC §509 清单修复
  │     ├── [SUBTASK] P4.1: server coverage store
  │     ├── [SUBTASK] P4.2: server NATS subscriber
  │     ├── [SUBTASK] P4.3: client coverage_reporter
  │     ├── [SUBTASK] P4.4: 删除违宪文件
  │     ├── [SUBTASK] P4.5: cmd 移除 postgresx
  │     └── [SUBTASK] P4.6: 测试覆盖
  │
  ├── [EPIC] Phase 5: P1 独立批次（3.5d，6 项并行）
  │     ├── [TASK] GAP-E32 goroutine recover
  │     ├── [TASK] GAP-E27 WebSocket SetReadLimit
  │     ├── [TASK] GAP-E34 HTTP server 完整超时
  │     ├── [TASK] GAP-E36 ldflags buildinfo
  │     └── [TASK] GAP-E29 migration runner
  │
  ├── [EPIC] Phase 6: EXCHANGEINFO 分级（4d）
  │     ├── [TASK] 6.0 GAP-E26 interval SSOT（前置）
  │     ├── [TASK] 6.1 白名单 MVP（§8.3）
  │     ├── [TASK] 6.2 GAP-E24 动态分级
  │     └── [TASK] 6.3 options 独立维度（§8.1 勘误）
  │
  ├── [EPIC] Phase 7: 数据完整性链（5d）
  │     ├── [TASK] GAP-E2 server CompletenessScanner
  │     ├── [TASK] GAP-E3 E2E 二向对账
  │     ├── [TASK] GAP-E10 catalog diff NATS
  │     ├── [TASK] GAP-E12 AckWait + 小批次
  │     ├── [TASK] GAP-E17 time.Now().UTC()
  │     ├── [TASK] GAP-E18 TDengine 部分成功捕获
  │     └── [TASK] GAP-E28 PG 事务管理
  │
  └── [EPIC] Phase 8: P2+P3 治理与长尾（32d）
        ├── [TASK] 8.1 可观测性（E9/E30/E35）
        ├── [TASK] 8.2 安全加固（E37/E44/E45）
        ├── [TASK] 8.3 部署治理（E41~E50）
        ├── [TASK] 8.4 Schema 演进（E8/E19/E23）
        ├── [TASK] 8.5 配置治理（E31/E4）
        ├── [TASK] 8.6 容错与韧性（E11/E16/E33）
        ├── [TASK] 8.7 优雅运行（E14/E15/E20/E22）
        ├── [TASK] 8.8 测试与质量（E21/E40）
        ├── [TASK] 8.9 长尾低优（E38/E39）
        └── [TASK] P3 治理文档（E51~E58）
```

### 3.2 依赖图（bd dep add）

```
EPIC(root) ──blocks──> EPIC(P1) ──blocks──> EPIC(P4) ──blocks──> EPIC(P6) ──blocks──> EPIC(P7) ──blocks──> EPIC(P8)

TASK(P2 GAP-E6) ──blocks──> TASK(P6 GAP-E24)   # 全量化前置分级
TASK(P6.0 GAP-E26) ──blocks──> TASK(P6.2 GAP-E24)  # interval SSOT 前置
TASK(P4.0 GAP-E7) ──blocks──> TASK(P4.1 server store)  # SPEC 矛盾先解决

TASK(P5.*) 无相互依赖（并行）

TASK(P3 GAP-E25 评估) ──blocks──> TASK(P8.7 优雅运行)  # 仅条件触发
```

### 3.3 GitHub Issue 同步

**约束**：

- `gh auth status` 当前返回 **401 Bad credentials**（GH_TOKEN 无效）
- 同步前需先执行 `gh auth login` 或修复 `GH_TOKEN`
- runtime 仓 = `ZoneCNH/binance`，主仓 = `ZoneCNH/ZoneCNH`

**同步策略**（3 选 1）：

| 方案                              | 说明                                                                 | 适用            |
| --------------------------------- | -------------------------------------------------------------------- | --------------- |
| **A. 本地 beads only**            | bd 创建所有 issue + 依赖，记录到 `008-issues-sync-report.md`         | gh 不可用时兜底 |
| **B. gh 批量同步**                | `gh issue create -R ZoneCNH/binance --title ... --body ...` 批量创建 | gh 修复后首选   |
| **C. GitHub Projects automation** | 用 `gh project item-add` 加到 Project Board 看板                     | 长期治理        |

**推荐执行序**：

```bash
# Step 1: 用户修复 gh auth
gh auth login  # 或 export GH_TOKEN=<valid>

# Step 2: 用 bd 批量创建（脚本化）
bash /home/workspace/ZoneCNH/plans/binance/010-create-beads-issues.sh

# Step 3: 用 gh 批量同步（脚本化）
bash /home/workspace/ZoneCNH/plans/binance/010-sync-gh-issues.sh

# Step 4: 验证
bash /home/workspace/ZoneCNH/plans/binance/010-verify-issues.sh
```

### 3.4 Issue 标签体系

| label                     | 含义              | 颜色                    |
| ------------------------- | ----------------- | ----------------------- |
| `runtime-gap`             | 运行时口径缺口    | red                     |
| `governance-trap`         | 治理陷阱（T0-T9） | purple                  |
| `phase-1` ~ `phase-8`     | 阶段标签          | blue gradient           |
| `P0` / `P1` / `P2` / `P3` | 优先级            | red/orange/yellow/green |
| `漏洞链-N`                | 属于第 N 条漏洞链 | dark red                |
| `independent`             | 无依赖可并行      | green                   |
| `blocked-by-decision`     | 等待用户决策      | gray                    |

---

## 4. 反向验收（Code → Spec）

> 来源：REVIEW-PROMPT v2.0 §12.5

| 检查项                                  | 期望                            | 验证命令                                                     |
| --------------------------------------- | ------------------------------- | ------------------------------------------------------------ |
| 48 FR 是否真的全 Done（规格口径）       | ✅                              | `grep -cE '^\| FR-[0-9]+.*Done' matrix/TRACEABILITY.md` = 48 |
| 58 GAP-E 是否有 runtime 证据            | 每项 grep 验证                  | 见 REVIEW-PROMPT §6.7                                        |
| 双口径是否在 SPEC 显式声明              | ✅                              | `grep -A 5 "§22a" spec/SPEC.md`                              |
| RUNTIME-GAP-MATRIX 是否被 evidence 引用 | ≥3 个文件                       | `grep -rl "RUNTIME-GAP-MATRIX" evidence/`                    |
| tag/Release/DEPLOY 三处一致             | 全部 v0.11.0                    | `git -C /home/workspace/binance tag -l 'v*'`                 |
| PRG-006 状态                            | TRACEABILITY §4 与 todo.md 一致 | diff                                                         |
| CHANGELOG ≤ SPEC 版本                   | 单向追溯                        | grep + compare                                               |

---

## 5. 风险与缓解

| 风险                                           | 严重度 | 缓解                                                                               |
| ---------------------------------------------- | ------ | ---------------------------------------------------------------------------------- |
| gh CLI 未认证阻断 GitHub 同步                  | MED    | 方案 A（仅本地 beads）兜底，同步推迟到用户修复后                                   |
| v0.11.0 tag 创建后不可删                       | MED    | 用 `git tag -d v0.11.0 && git push --delete` 在 24h 内可纠正（未 release 时）      |
| GAP-E25 评估后若启动需 5-8d 额外工时           | LOW    | 默认 `deferred`，监控触发才启动                                                    |
| options TRADING 过滤可能过滤掉有效合约         | MED    | options §8.1 独立维度设计，先观测再优化                                            |
| 73.5 人天总工时超出资源预算                    | HIGH   | 严格按阶段交付，Phase 1+2+5 = 5.5d 可达成"消除状态分裂 + symbol 全量化 + 独立批次" |
| 漏洞链 #6（运维治理 E29+E30+E9）触发生产事故   | HIGH   | Phase 5 含 E29 migration runner + E36 buildinfo（运维可观测子集）                  |
| GAP-E58（issue close ≠ runtime fix）持续假阳性 | HIGH   | Phase 1 T2-1 + CONTRIBUTING.md 强制 issue close 时引用 evidence                    |

---

## 6. 与历史 plan 的关系

| 历史 plan                                                 | 关系                                                                      |
| --------------------------------------------------------- | ------------------------------------------------------------------------- |
| `plans/binance/008-binance-production-fix-master-plan.md` | v1（2026-06-29），覆盖 PRG-001~007 规格口径闭合；本 plan 为 v3 后续       |
| `plans/binance/FIX-EXECUTION-PLAN-20260630.md`            | v2（2026-06-30），82k，覆盖 release_closeable=YES；本 plan 转向运行时口径 |
| `plans/binance/006-binance-production-readiness-fix.md`   | 历史 PRG 闭合细节                                                         |
| `plans/binance/007-binance-readiness-arch-fix.md`         | 历史 architecture fix                                                     |

**本 plan（010）相对历史 plan 的增量**：

- 首次纳入 **58 运行时缺口**（v3.9 27 轮自审产出）
- 首次纳入 **9 治理陷阱**（REVIEW-PROMPT v2.0）
- 首次纳入 **4 EXCHANGEINFO 勘误**（§8）
- 首次定义 **双口径治理**（规格 vs 运行时）
- 首次纳入 **15 漏洞链** 优先级排序

---

## 7. 验收总清单（Plan 完成判定）

| 项                    | 验证                                       | 完成              |
| --------------------- | ------------------------------------------ | ----------------- |
| Phase 1（治理分裂）   | 9 个陷阱全部 Fixed + grep 证据             | ✅                |
| Phase 2（GAP-E6）     | 4 线 refresher 装配 + options TRADING 过滤 | ✅                |
| Phase 4（GAP-E1）     | client 内 0 postgresx 引用                 | ✅                |
| Phase 5（独立批次）   | 5 项 GAP 全 Fixed                          | ✅                |
| Phase 6（分级）       | WS 订阅数 ≤ 1000 + 白名单生效              | ✅                |
| Phase 7（数据完整性） | 7 项 GAP Fixed + E2E 对账脚本              | ✅（7/7）          |
| Phase 8（长尾）       | 38 项 GAP Fixed + 顶层文档补全             | ☐                 |
| beads issue           | 完整树创建 + 依赖图正确                    | ☐                 |
| GitHub issue          | 主仓 #1540~#1592（53 个）已同步            | ✅（Open 10 / Closed 43） |
| RUNTIME-GAP-MATRIX    | 状态从 Open 改为 Fixed（≥80%）             | ☐                 |
| release_closeable     | 真实 YES（0 P0 + ≤3 P1 Open）              | ☐                 |

---

## 8. 元数据

- **Plan-Version**：1.0
- **生成方式**：基于三份报告（REVIEW-PROMPT v2.0 / DATA-INTEGRITY v3.9 / EXCHANGEINFO v1.0）+ 9 个已知陷阱现场核验 + 4 项 EXCHANGEINFO 勘误
- **执行节奏**：Phase 7（`#1574~#1581`）与 EPIC `#1573` 已关闭，当前进入 Phase 8（`#1582~#1592`）批次推进。
- **反馈机制**：每 Phase 完成后更新 `module/binance/RUNTIME-GAP-MATRIX.md` 状态列 + 关闭对应 bd/GitHub issue + 在 evidence/ 落证据
- **审查节奏**：每 2 周一次对抗性反审查（基于 REVIEW-PROMPT §12）
- **失败回滚**：每个 Phase 失败时 `git revert` + bd issue reopen + 复盘记录到 `evidence/<date>/retrospective/`

---

[RULES I BROKE]：

- ⚠️ Phase 1 子任务 P1.1（`git tag v0.11.0`）涉及 git 写操作，需用户显式授权（CLAUDE.md "执行 actions with care"）
- ⚠️ §3.3 GitHub issue 同步依赖 gh CLI 认证，当前 401 失败需用户修复
- ⚠️ Phase 8 总工时 32d 超出单 PR 范围，建议按批次拆 PR（每批次 1 PR）
- ✅ 所有源码引用基于现场 grep 核验（无凭记忆假设）
- ✅ 双口径治理严格分离（规格口径 48 Done / 运行时口径 58 Open）
- ✅ EXCHANGEINFO §8 勘误全部纳入（不照搬原文 §3-§7）
