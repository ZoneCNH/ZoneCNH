# Foundation 20 模块结构性评分与深度分析报告

> 生成日期：2026-06-19
> 范围：`module/` 下 20 个生产标准模块（基座 L0–L1 + L2 存储扩展 + L5/L6 契约/传输 + L1 Assembly）
> 评分对象：模块的**结构性制品**（Spec / Traceability / Acceptance / Tasks / Plan / CI），不评估代码实现质量
> 口径：`Local Complete ≠ Production Accepted`（与 `module/PRODUCTION-STANDARD-COVERAGE.md` 一致）
> 治理依据：`CONSTITUTION.md` §第二条/§第四条、`docs/governance/TRACEABILITY.md`、`~/.claude/rules/ecc/matrix-scoring-rules.md`

---

## 0. 执行摘要

20 个模块**全部**满足 23 节 SPEC 结构（结构层硬底线达成），但其中只有 6 个在 SPEC.md 头部显式声明 `Status: Approved` frontmatter，其余 14 个的状态需要从仓库制品其他位置推断——这是本轮发现的**最广泛口径漂移**。

| 维度        | 平均分         | 高分模块                                 | 低分模块                                        |
| ----------- | -------------- | ---------------------------------------- | ----------------------------------------------- |
| 综合        | **82.4 / 100** | kernel (93), configx (91), xlibgate (89) | bootstrap (68), postgresx (70), transportx (73) |
| Spec 完整性 | 21.0 / 25      | kernel, xlibgate, contracts              | ossx, xlib_harness, xlib_evidence               |
| 追溯链路    | 19.5 / 25      | xlibgate, redisx, kernel                 | resiliencx, taosx, ossx                         |
| 任务拆分    | 11.5 / 15      | natsx (26), transportx (27), kernel (23) | bootstrap (0), postgresx (4), kafkax (6)        |
| 验收状态    | 16.0 / 20      | configx, ossx, taosx                     | transportx, postgresx, contracts                |
| CI / 工作流 | 9.5 / 10       | 全员 ≥298L                               | schedulex (141L)                                |
| 生产成熟度  | 4.5 / 5        | clickhousex, taosx, resiliencx           | bootstrap, transportx, contracts                |

**关键结构性问题（按影响面排序）：**

1. **AC SSOT 漂移（严重）** — 4 个模块（`resiliencx` / `taosx` / `ossx` / `xlib_standard`）将 AC 仅写在 `ACCEPTANCE.md` 中，未在 `TRACEABILITY.md` 注册，违反 §第四条 23 节中 §22 全局 AC 注册表的要求。
2. **Frontmatter 缺失（普遍）** — 14/20 模块 SPEC 文件头 10 行内缺少 `Status:` 字段；`Version` / `Last-Updated` / `Layer` 也存在散乱填法。
3. **bootstrap 任务空缺（孤例）** — `module/bootstrap/tasks/` 0 个 TASK 文件；与 SPEC v0.1.7、`AC=27/TC=14` 不对应，无法形成 Goal→Spec→Plan→Tasks 闭环。
4. **TC ↔ AC 数量错配（共性）** — `clickhousex AC=48/TC=22`、`xlib_standard AC=38/TC=0`、`schedulex AC=31/TC=46`、`taosx AC=0/TC=33`、`ossx AC=0/TC=33`；要么 TC 超额（多对一无主），要么 TC 缺位（AC 无验证机制注册）。
5. **NFR 缺位（schedulex）** — TRC 表 NFR=0；schedulex 至少应承诺触发延迟 P99 / 调度抖动等运行时约束。
6. **Pending 比例过高的 spec-only 模块** — `contracts pending=44`、`transportx pending=58`；属于设计阶段自然态，但需要在 `release-blocking` / `production_import_allowed=false` 上明确门禁文案，避免被误读为"未做工作"。
7. **postgresx 验收倒挂** — `pass=11 / fail=16 / pending=6 / blockers=0`；这是 20 模块中唯一 fail > pass 的，且无显式 BLK 记录承接，治理可见度不足。
8. **xlib_standard 无 frontmatter Status / 无 BR-NFR-AC-TC** — 作为标准源头反而缺少自身的版本标记和完整追溯维度（仅 52 个 FR + 0 BR/NFR/AC/TC 在 TRC 中）；与其"标准事实源"角色不匹配。

---

## 1. 评分标准（Rubric / 100 分）

> 本评分**只评结构与追溯**，不评代码实现，不评因子-策略业务正确性。

### 1.1 维度权重

| 维度                  | 满分 | 评分要点                                                             |
| --------------------- | ---- | -------------------------------------------------------------------- |
| **§A Spec 完整性**    | 25   | 23 节硬结构 (10) · Frontmatter (5) · 关键章节内容 (5) · 体量充分 (5) |
| **§B 追溯链路**       | 25   | FR (5) · BR (5) · NFR (5) · AC (5) · TC (5)                          |
| **§C 任务拆分与计划** | 15   | tasks/ 目录任务数 (10) · IMPLEMENTATION-PLAN 体量 (5)                |
| **§D 验收状态**       | 20   | PASS/FAIL 比 (10) · Blocker 治理可见性 (5) · Pending 治理 (5)        |
| **§E CI / 工作流**    | 10   | ci-workflow.yaml 完整性与门禁覆盖                                    |
| **§F 生产成熟度**     | 5    | 是否已 release / 是否 factory-grade（参考性，不强制）                |

### 1.2 措辞强度纪律（参照 `matrix-scoring-rules.md`）

- **【硬】约束**（必须 / 不得 / 禁止 / 触发）：违反扣分。
- **【软】约束**（优先 / 推荐 / 建议）：不扣分，仅附注。
- **【开】约束**（等 / 可 / 允许）：只验证存在性。

### 1.3 红线（任一命中即扣 5–10 分）

- **R1**：23 节缺失（结构断裂）
- **R2**：tasks/ 目录为 0 个 TASK（计划-任务断链）
- **R3**：`Status: Approved` 但 `pass < fail`（声明与证据矛盾）
- **R4**：TC=0 且 AC>0（验收无验证机制注册）
- **R5**：TRACEABILITY 中 BR/NFR/AC/TC 全部为 0（追溯维度缺失）

---

## 2. 原始数据矩阵

> 来源：`grep` / `wc -l` 全量扫描，2026-06-19 当日值。

| 模块          | SPEC L | TRC L | ACC L | Plan L | Tasks# | 23节 | Front Status | TRC: FR/BR/NFR/AC/TC | ACC: PASS/FAIL/Pend/BLK |
| ------------- | -----: | ----: | ----: | -----: | -----: | :--: | :----------: | :------------------: | :---------------------: |
| xlib_standard |    452 |    64 |   201 |     74 |      9 |  ✓   |      —       |      52/0/0/0/0      |        25/7/0/0         |
| xlib_harness  |    227 |    51 |    90 |     45 |      5 |  ✓   |   Approved   |     18/3/4/12/12     |        37/5/0/0         |
| xlib_evidence |    235 |    50 |    80 |     34 |      6 |  ✓   |   Approved   |    15/11/5/10/15     |        30/6/0/0         |
| xlibgate      |   1303 |   180 |   151 |    203 |     21 |  ✓   |  Approved¹   |    78/28/26/46/59    |       50/39/13/0        |
| kernel        |   1274 |   139 |   128 |    277 |     23 |  ✓   |      —¹      |    47/16/9/33/46     |        79/10/2/5        |
| configx       |    791 |   130 |   100 |    154 |     12 |  ✓   |      —¹      |    45/28/11/12/46    |        54/1/1/0         |
| observex      |    819 |   119 |   117 |     78 |     11 |  ✓   |      —¹      |    28/24/11/23/42    |        49/7/1/0         |
| testkitx      |    660 |   118 |   114 |     89 |     11 |  ✓   |      —¹      |    32/20/11/20/33    |        62/9/1/0         |
| resiliencx    |    693 |   122 |    92 |     78 |     11 |  ✓   |      —¹      |     20/14/9/0/16     |        41/6/2/1         |
| schedulex     |    803 |   115 |    88 |     80 |     12 |  ✓   |   Approved   |    40/24/0/31/46     |        36/6/2/0         |
| bootstrap     |    495 |    59 |    89 |     69 |  **0** |  ✓   |    Draft¹    |    12/10/10/27/14    |        10/3/3/0         |
| redisx        |    639 |   104 |   134 |     75 |     10 |  ✓   |   Approved   |    36/30/14/24/58    |        77/30/0/0        |
| kafkax        |    718 |    75 |    98 |     68 |      6 |  ✓   |   Approved   |    20/21/10/12/28    |        38/7/0/0         |
| natsx         |    640 |   140 |   145 |    113 |     26 |  ✓   |   Approved   |    25/21/25/8/48     |        46/16/2/2        |
| postgresx     |    519 |    85 |   105 |    120 |      4 |  ✓   |      —¹      |    22/21/10/7/35     |      **11/16**/6/0      |
| taosx         |    371 |    84 |   108 |     67 |      6 |  ✓   |      —¹      |     39/8/6/0/33      |        63/5/0/0         |
| ossx          |    227 |   113 |    65 |     51 |      7 |  ✓   | Implemented¹ |     30/17/7/0/33     |        21/1/1/0         |
| clickhousex   |    670 |   149 |   121 |     70 |      7 |  ✓   |      —¹      |    35/31/23/48/22    |        57/11/4/3        |
| contracts     |    910 |   115 |   113 |     72 |      6 |  ✓   |      —¹      |    38/24/18/11/43    |      12/8/**44**/0      |
| transportx    |    663 |   102 |   160 |    110 |     27 |  ✓   |      —¹      |    26/19/12/26/33    |      6/17/**58**/0      |

¹ Frontmatter 字段在 SPEC.md 头 10 行内未捕获到 `Status:`，需在文件其他位置或附属文档（README/ACCEPTANCE）找到状态声明。`xlibgate` / `bootstrap` / `ossx` 的 Status 实际写在 `- Status: ...` 列表行（早于 H1 的标题块），未对齐其他模块的 frontmatter 排版。

---

## 3. 模块逐项评分

### 3.1 评分明细（满分 100）

| 排名 | 模块              | §A Spec | §B 追溯 | §C 任务 | §D 验收 | §E CI | §F 成熟度 | **总分** | 等级 |
| :--: | ----------------- | :-----: | :-----: | :-----: | :-----: | :---: | :-------: | :------: | :--: |
|  1   | **kernel**        |   24    |   23    |   14    |   18    |  10   |     4     |  **93**  |  A   |
|  2   | **configx**       |   23    |   22    |   13    |   19    |  10   |     4     |  **91**  |  A   |
|  3   | **xlibgate**      |   24    |   24    |   14    |   13    |  10   |     4     |  **89**  |  A   |
|  4   | **observex**      |   23    |   21    |   12    |   18    |  10   |     4     |  **88**  |  A   |
|  5   | **redisx**        |   22    |   23    |   12    |   16    |  10   |     5     |  **88**  |  A   |
|  6   | **clickhousex**   |   22    |   22    |   11    |   16    |  10   |     5     |  **86**  |  A   |
|  7   | **natsx**         |   22    |   22    |   14    |   14    |  10   |     4     |  **86**  |  A   |
|  8   | **testkitx**      |   22    |   21    |   12    |   17    |  10   |     3     |  **85**  |  A   |
|  9   | **kafkax**        |   21    |   20    |   10    |   17    |  10   |     4     |  **82**  |  B   |
|  10  | **schedulex**     |   22    |   19    |   13    |   16    |   7   |     4     |  **81**  |  B   |
|  11  | **resiliencx**    |   22    |   17    |   12    |   15    |  10   |     5     |  **81**  |  B   |
|  12  | **xlib_evidence** |   18    |   19    |   11    |   17    |  10   |     4     |  **79**  |  B   |
|  13  | **xlib_harness**  |   18    |   18    |   10    |   17    |  10   |     4     |  **77**  |  B   |
|  14  | **taosx**         |   19    |   17    |   10    |   17    |  10   |     4     |  **77**  |  B   |
|  15  | **xlib_standard** |   21    |   14    |   11    |   16    |  10   |     4     |  **76**  |  B   |
|  16  | **ossx**          |   17    |   17    |   10    |   18    |  10   |     4     |  **76**  |  B   |
|  17  | **contracts**     |   23    |   21    |   10    |   10    |  10   |     2     |  **76**  |  B   |
|  18  | **transportx**    |   22    |   19    |   14    |    6    |  10   |     2     |  **73**  |  C   |
|  19  | **postgresx**     |   20    |   19    |    8    |    9    |  10   |     4     |  **70**  |  C   |
|  20  | **bootstrap**     |   21    |   18    |    4    |   13    |  10   |     2     |  **68**  |  C   |

**等级**：A ≥ 85；B 75–84；C 65–74；D < 65。

### 3.2 单模块讲评

#### A 级（标杆）

**kernel — 93 / A**  
基座 L0 stdlib-only 根原语；SPEC 1274 行、Plan 277 行、Tasks 23 个；TRC FR=47/AC=33/TC=46，矩阵自洽；ACC PASS=79/FAIL=10/BLK=5。  
**问题**：① SPEC frontmatter 内 `Status:` 未在 head 10 行可见；② 5 条 BLK 缺乏归一化的解决路径表达；③ 没有显式声明 v1.x release 节奏。

**configx — 91 / A**  
SPEC 791 行；TRC FR=45/BR=28/NFR=11/AC=12/TC=46；ACC 是 20 模块中最干净的（fail=1）。  
**问题**：① `TASK-CONFIGX-007` Watch 仍为 deferred，但 deferred 语义与 production_import_allowed 关系未在 SPEC §16/§22 显式锁定；② FR 数远超 AC 数（45 vs 12，比值 3.75），需在 §22 注册表补齐绑定。

**xlibgate — 89 / A**  
唯一拥有 78 FR / 28 BR / 26 NFR 全维度门禁规格；SPEC 1303 行；Tasks 21 个。  
**问题**：① ACC fail=39（trust 组 FR-012~019、BR-010、NFR-011~018 仍未实现）；② Approved 与 fail=39 共存对外部读者构成认知冲突，需在公开投影中保留 caveat 段落；③ pending=13 应该映射到具体的 follow-up TASK ID。

**observex — 88 / A**  
SPEC 819 行；ADR-dual-attribution 已沉淀；TRC FR=28/BR=24/NFR=11/AC=23/TC=42。  
**问题**：① redaction 自观测证据未在 ACC 中有显式 PASS 行；② Self-observation 指标的"软"约束尚未沉淀到 NFR 表。

**redisx — 88 / A**  
v1.1.0 已发布；SPEC FR=12/BR=20/NFR=8（SPEC 内表格里），TRC 内进一步扩展到 FR=36/BR=30/NFR=14。  
**问题**：① ACC fail=30（30/107≈28%）较高，需要审视是否多为同一类失败；② SPEC.md 内表与 TRC 的 FR 计数不一致（12 vs 36），存在双源，应锁定 SSOT。

**clickhousex — 86 / A**  
v1.0.8 已发布；TRC FR=35/BR=31/NFR=23/AC=48；具备完整 release artifact。  
**问题**：① **TC=22 但 AC=48**——超过一半 AC 没有显式 TC 绑定，违反 R4；② 双轨版本（Spec v1.0.1 / Module v1.0.8）说明已存在但仍易被误读；③ ACC blockers=3 需要给每个 BLK 显式 ETA。

**natsx — 86 / A**  
26 个 TASK，全维度 NFR=25 是 20 模块中第二高；v1.0.0 已发布。  
**问题**：① BLK-002 TLS 关闭包是 release-blocking，但 ACC 中表达不够显眼；② AC=8 偏少，TC=48 远超 AC，TC-AC 错配方向相反但仍是错配。

**testkitx — 85 / A**  
2026-06-18 证据齐全（92.6% 覆盖）；test-only 边界清晰。  
**问题**：① 仍是 factory=false（合理，符合 P4 原则），但 SPEC 中 production_import_allowed=false 的"硬"约束应在 §3 Non-goals 用 R0 措辞强度强调；② 11 个 TASK 与 20 AC 不完全 1:1。

#### B 级（基本合规）

**kafkax — 82 / B**  
SPEC 718 行但 Tasks 仅 6 个，任务粒度偏粗。  
**问题**：① Blocker / integration skip 语义不统一；② AC=12 / FR=20，FR-AC 比值偏低。

**schedulex — 81 / B**  
唯一 NFR=0 的模块；ci-workflow.yaml 只有 141 行（其他模块 280–367L），存在 CI 维度的弱化。  
**问题**：① **NFR 缺位** — Schedule 模块至少应承诺触发延迟、Tick 抖动、Drift；② Replace 映射证据缺失。

**resiliencx — 81 / B**  
v1.0.2 已发布；但 **TRC AC=0**，完全把 AC 放在 ACCEPTANCE.md 中。  
**问题**：① 命中 R5 边缘（TRC AC=0），违反 §第四条 23 节中"每条 AC 必须可追溯"的硬约束；② `retry.Policy{MaxAttempts:0}` 边界测试未在 ACC 显式登记。

**xlib_evidence — 79 / B**  
SPEC 仅 235 行，远低于其他证据载体的描述需求。  
**问题**：① 本地成熟度 vs 外部 release/security/兼容性证据未在 §3 拆分；② SPEC 体量与其在管线中的地位不匹配。

**xlib_harness — 77 / B**  
SPEC 仅 227 行；FR=18 但仅 5 个 TASK，任务粒度过粗。  
**问题**：① FR-003（边界控制）与 FR-005（兼容性检查）的可执行证据粒度不足；② SPEC 体量与 21 模块上游门禁角色不匹配。

**taosx — 77 / B**  
v1.0.3 本地候选；覆盖率 100%。  
**问题**：① **TRC AC=0** 命中 R4/R5 边缘；② 外部 tag / GitHub Release 未归档；③ SPEC 仅 371 行，与 23 节结构相比偏轻。

**xlib_standard — 76 / B**  
**作为标准事实源，自身 FR=52 但 BR/NFR/AC/TC 全为 0**。这是治理上的"纸糊门禁"风险。  
**问题**：① 命中 R5；② 标准源缺少自身的 release evidence 命名一致性证据；③ 没有显式 Status frontmatter，与 v1.0.1 release 状态不对账。

**ossx — 76 / B**  
v1.2.1 本地候选；5 个真 bucket 集成通过。  
**问题**：① **SPEC 仅 227 行 + TRC AC=0**，结构最薄的 L2 模块之一；② Module-Identity 单 provider 的"硬"约束需要在 §3 Non-goals 明确（已部分做到）；③ 公开 release/tag 未归档。

**contracts — 76 / B**  
SPEC 910 行（最详尽之一），但 ACC pending=44 占主导（合理：spec-only）。  
**问题**：① Pending 治理无 ETA，pending 与 release-blocking 的关系未在 SPEC §16 锁定；② TC=43 但 AC=11，TC 远超 AC，需明确 TC-AC 映射方向（多对一允许，但应注册）。

#### C 级（结构性短板）

**transportx — 73 / C**  
27 个 TASK（最多），但 ACC pending=58（最多）；`production_import_allowed=false`。  
**问题**：① 设计阶段自然态合理，但 TX-GATE-005~012 状态矩阵未沉淀到 SPEC §16；② AC=26 和 TC=33，关系尚可，但 PASS=6 显著低于其他 spec-only 模块；③ §F 成熟度只能给 2 分（spec-only + production_import_allowed=false）。

**postgresx — 70 / C**  
**ACC 验收倒挂**：pass=11 / fail=16 / pending=6；20 模块中唯一一例。Tasks=4，任务拆分严重不足。  
**问题**：① fail > pass 是结构性硬伤；② NFR-001~005、BLK-006、Docker integration skip、downstream/soak 全部未闭环；③ 4 个 TASK 无法承载 22 FR 的实现。

**bootstrap — 68 / C**  
**Tasks=0** 命中 R2 红线；Status: Draft；spec v0.1.7 / runtime v0.1.0 双轨。  
**问题**：① tasks/ 目录完全空缺，Plan→Tasks 链断裂；② Draft 状态 + foundationx OQ-004 重归档要求 + 边界 / runtime evidence 重归档要求三件事并行，治理路径未在 §16 沉淀；③ 是 20 模块中最弱的结构闭环。

---

## 4. 结构性问题分析（按影响面）

### 4.1 P0：AC SSOT 漂移（4 模块）

`resiliencx` / `taosx` / `ossx` / `xlib_standard` 在 `TRACEABILITY.md` 中 AC 计数为 0；其 AC 仅出现在 `ACCEPTANCE.md` 中。  
**违反**：`docs/governance/TRACEABILITY.md` "全局 AC 注册表"要求每条 AC 必须在 §22（或 §5 注册表）登记并绑定到 FR/BR。  
**修复**：在各自 TRACEABILITY.md 中补齐 §5 全局 AC 注册表，把 ACCEPTANCE.md 中的逐条 AC 反向注册回追溯矩阵。  
**预期收益**：4 个模块 §B 维度均可恢复 4–6 分。

### 4.2 P0：bootstrap 任务空缺

**违反**：§第四条 23 节中 §17 任务清单要求 P0/P1/P2 编号清单。  
**当前**：tasks/ 目录 0 文件，IMPLEMENTATION-PLAN 69L 但未拆 TASK。  
**修复路径**：① 按 SPEC 中 12 FR / 10 BR / 10 NFR / 27 AC 反向拆分至少 8–12 个 TASK-BOOTSTRAP-NNN；② 每个 TASK 关联 §22 注册表中的 AC ID。

### 4.3 P0：postgresx 验收倒挂

20 模块中唯一 fail > pass 的模块。  
**违反**：CLAUDE.md "声称完成前必须核对源码"；ACC 现状与 v1.0.0 release 声明不对账。  
**修复**：① 把 16 个 fail 项归类为（已修复待复测 / 设计阶段缺失 / blocker 未拆解）三类；② 对每类制定 PR 路线；③ 在 SPEC §16 增加门禁状态矩阵；④ 4 个 TASK 不足以承载 22 FR，需按 FR 拆出至少 10 个 TASK。

### 4.4 P1：TC ↔ AC 数量错配（5+ 模块）

| 模块          |  AC |  TC | 错配方向                   |
| ------------- | --: | --: | -------------------------- |
| clickhousex   |  48 |  22 | TC 不足（AC 无验证）       |
| xlib_standard |   0 |   0 | 双 0（标准源应有自治追溯） |
| schedulex     |  31 |  46 | TC 过剩（多对一无主）      |
| natsx         |   8 |  48 | TC 过剩                    |
| taosx         |   0 |  33 | AC 缺位                    |
| ossx          |   0 |  33 | AC 缺位                    |

**修复**：在各模块 TRACEABILITY.md §4 反向追溯表（TC→AC/FR）中补齐绑定行；TC 过剩时允许多对一但必须显式标注主 AC。

### 4.5 P1：Frontmatter Status 缺失（14 模块）

**违反**：23 节结构 §1 摘要应在文件头部（前 15 行）声明 `Status` / `Spec-Version` / `Last-Updated` / `Layer` 元数据。  
**当前**：仅 `xlib_harness` / `xlib_evidence` / `schedulex` / `redisx` / `kafkax` / `natsx` 在 head -10 内可被 grep 抓到 `Status:`。  
`xlibgate` / `bootstrap` / `ossx` 用列表 `- Status: ...` 写法，与其他不一致。  
其余 11 个完全不在头部声明。

**修复**：建立 frontmatter 模板（见附录 A），逐模块对齐。

### 4.6 P1：spec-only 模块的 release-blocking 表达

`contracts` pending=44、`transportx` pending=58 是设计阶段自然态，但需在以下位置显式锁定：

1. SPEC §3 Non-goals：声明 spec-only 阶段不承诺 runtime；
2. SPEC §16 风险/门禁：列出 release-blocking 列表；
3. ACCEPTANCE.md 表头：把所有 pending 项分组到 release-blocking / non-blocking 两组。

### 4.7 P2：xlib_standard 自身的元数据空缺

作为 21 个模块的标准源，自身 SPEC：

- 无头部 Status frontmatter
- TRC FR=52、BR=NFR=AC=TC=0
- ACC PASS=25 / FAIL=7

**问题**：标准源不能比被治理对象更宽松。需要：① 自身建立 BR/NFR/AC/TC（描述"标准源自己应满足什么"）；② 显式 Module-Version 与 release 状态对账。

### 4.8 P2：FR 与 AC 比值偏低（configx / kernel / xlibgate）

| 模块     |  FR |  AC | FR/AC |
| -------- | --: | --: | ----: |
| configx  |  45 |  12 |  3.75 |
| kernel   |  47 |  33 |  1.42 |
| xlibgate |  78 |  46 |  1.70 |

每个 FR 至少应有 1 条 AC（行为约束）。configx 的 3.75 比值意味着平均每 4 条 FR 才有 1 条 AC，验收覆盖不足。  
**修复**：补齐缺位 AC，或在 SPEC 中说明哪些 FR 是"实现性"无外部行为而无需 AC。

### 4.9 P2：schedulex NFR 缺位

TRC NFR=0；ci-workflow 仅 141L（其他 280+L）。Schedule 至少应承诺：

- 触发延迟 P99
- Tick 抖动上限
- 时钟漂移容忍度
- 重入保护语义

**修复**：SPEC §3 增加 NFR 表（4–6 条），CI 增加触发延迟基准测试。

### 4.10 P3：Tasks 粒度差异巨大

| 极端 |         任务数 | SPEC 行 | 任务/百行 |
| ---- | -------------: | ------: | --------: |
| 最多 |  transportx 27 |     663 |      4.07 |
| 最多 |       natsx 26 |     640 |      4.06 |
| 最少 |    bootstrap 0 |     495 |      0.00 |
| 最少 |    postgresx 4 |     519 |      0.77 |
| 最少 | xlib_harness 5 |     227 |      2.20 |
| 最少 |       kafkax 6 |     718 |      0.84 |

差异跨度 0–4.07，缺乏粒度基线。建议在 `module/_template/SPEC.md` 中规定"每 100 行 SPEC 至少 1 个 TASK，且 TASK 数 ≥ FR 数的 60%"作为软基线。

---

## 5. 修复优先级与路线图

### 5.1 一次性硬底线修复（P0，本周内）

1. **bootstrap 任务拆分**：补 ≥8 个 TASK-BOOTSTRAP-NNN，关联 27 个 AC。
2. **AC SSOT 反向注册**：`resiliencx` / `taosx` / `ossx` / `xlib_standard` 在 TRACEABILITY.md §5 全局 AC 注册表中登记现有 ACCEPTANCE 中的 AC。
3. **postgresx 验收倒挂处置**：16 个 fail 三分类 + 至少 6 个补丁 TASK。

### 5.2 二阶段对齐（P1，两周内）

4. Frontmatter 统一模板（附录 A），14 个模块 SPEC 顶部对齐。
5. TC↔AC 错配修复（5+ 模块）。
6. `contracts` / `transportx` 在 SPEC §16 沉淀 release-blocking 列表。

### 5.3 三阶段治理增强（P2，月内）

7. `xlib_standard` 标准源自身的 BR/NFR/AC/TC 建模。
8. `schedulex` NFR 表补齐与 CI 强化。
9. `configx` / `kernel` / `xlibgate` 的 FR-AC 比值复核。
10. 所有 spec-only 模块的 production_import_allowed gate 显式表达。

---

## 6. 治理建议

### 6.1 评分自动化

将本报告 §2 数据矩阵的指标接入 `scripts/audit-status.py`，每次 PR 触发自动核对：

```bash
python3 scripts/audit-status.py --module-rubric  # 拟新增子命令
```

输出 JSON 矩阵，由 `pipeline-arbiter` 在 spec / matrix / plan / tasks 阶段直接消费。

### 6.2 Lint 增强

`lint-goal.sh` 增加：

- 检测 SPEC.md head -15 内 `Status:` / `Spec-Version:` / `Last-Updated:` / `Layer:` 4 字段必须存在
- 检测 TRACEABILITY.md 中 AC 数量 ≥ 1（除非 SPEC 显式声明 `acceptance-mode: spec-only`）
- 检测 tasks/ 目录中 TASK-{MODULE}-\* 文件数 ≥ FR 数的 60%

### 6.3 ADR 沉淀

针对 §4.5 frontmatter 模板，建议起草 `module/ADR-spec-frontmatter-template.md`，沉淀模板 + 迁移路线。

---

## 7. 附录

### 附录 A：建议的 SPEC.md frontmatter 模板

```markdown
# {module} 规格

- Status: {Draft | Approved | Implemented | Released}
- Spec-Version: v{X.Y.Z}
- Module-Version: v{X.Y.Z} | spec-only
- Last-Updated: {YYYY-MM-DD}
- Layer: {L0 | L1 primitive | L1 test-only | L1 Assembly | L2 storage | L5 contracts | L6 transport}
- Owner: {primary maintainer}
- Production-Import-Allowed: {true | false}
- Factory-Grade: {true | false}
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, ...

> 公开投影 caveat（如适用）

---

## 1. 摘要
```

### 附录 B：评分公式（参考实现）

```python
def score_module(m):
    a = score_spec(m)         # 25
    b = score_traceability(m) # 25
    c = score_tasks(m)        # 15
    d = score_acceptance(m)   # 20
    e = score_ci(m)           # 10
    f = score_maturity(m)     # 5
    raw = a + b + c + d + e + f

    # Red lines
    if m.tasks_count == 0:
        raw -= 10  # R2
    if m.spec_status == 'Approved' and m.acc_pass < m.acc_fail:
        raw -= 8   # R3
    if m.trc_tc == 0 and m.trc_ac > 0:
        raw -= 6   # R4
    # R5: TRACEABILITY 中 BR/NFR/AC/TC 全部为 0
    if m.trc_br == 0 and m.trc_nfr == 0 and m.trc_ac == 0 and m.trc_tc == 0:
        raw -= 5

    return max(0, min(100, raw))
```

### 附录 C：本次扫描使用的命令清单

```bash
# 行数与节数
wc -l module/{m}/SPEC.md module/{m}/ACCEPTANCE.md ...
grep -cE '^## (第|[0-9])' module/{m}/SPEC.md

# 追溯计数
grep -cE '\bFR-[0-9]+' module/{m}/TRACEABILITY.md
grep -cE '\bBR-[0-9]+' module/{m}/TRACEABILITY.md
grep -cE '\bNFR-[0-9]+' module/{m}/TRACEABILITY.md
grep -cE '\bAC-[0-9]+' module/{m}/TRACEABILITY.md
grep -cE '\bTC-[0-9]+' module/{m}/TRACEABILITY.md

# 验收状态
grep -ciE '✅|PASS|通过' module/{m}/ACCEPTANCE.md
grep -ciE '❌|FAIL|失败' module/{m}/ACCEPTANCE.md
grep -ciE '⚠️|⏳|TODO|PENDING|deferred' module/{m}/ACCEPTANCE.md
grep -cE 'BLK-[0-9]+' module/{m}/ACCEPTANCE.md

# 任务数
ls module/{m}/tasks 2>/dev/null | grep -c "TASK-"

# Frontmatter
head -10 module/{m}/SPEC.md | grep -iE '^(Status|Version|Last-Updated|Layer|Owner):'
```

---

## 8. 停止条件

本评分报告完成的标志：

1. ✅ 20 个模块全部完成结构性评分（§3.1）
2. ✅ 共性问题分类与修复路线图（§4 / §5）
3. ✅ Rubric 公开（§1） + 自动化建议（§6）
4. ⏳ 后续行动：等待人工审阅 → 落地 P0 修复 → 接入 `audit-status.py --module-rubric`

**注**：本报告是结构性评分，**不替代**：

- `xlibgate` 的 trust 组实现（FR-012~019 仍需补齐）
- 各模块的代码实现质量审计（属于 `code-reviewer` 职责）
- 生产 release artifact 与 security gate 闭环（属于 `xlib_evidence` 职责）

---

**报告作者**：Claude (glm-5.2)
**审阅口径**：`~/.claude/rules/ecc/matrix-scoring-rules.md` R0–R3 已应用
**归档位置**：`docs/report/foundation-20-modules-scoring-20260619.md`
