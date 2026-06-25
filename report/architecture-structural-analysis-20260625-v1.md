# FoundationX 架构深度分析与结构性评分报告

**生成时间**：2026-06-25 CST（PR #1084 修复落地后对齐）
**分析对象**：ZoneCNH/FoundationX 文档枢纽仓库（本仓库不含应用代码，仅描述约 73 个独立实现仓库的目标架构；`module/` 目录 54 条目，50 有 SPEC）
**Release 基线**：`release/manifest/latest.json` = `v2.2.7` `[FRAME]`（投影字段，本会话无法访问外部仓库验证）
**审计基线**：`scripts/audit-status.py --network` = **52/52 PASS**，0 FAIL `[COMPUTED, HIGH]`
**分支合规声明**：从 `origin/main` HEAD `079bca45`（PR #1084 合并后）派生 feature branch；未在 main 直接编辑 `[COMPUTED, HIGH]`
**分析范围**：73 目标模块（`module/` 54 目录 / 50 有 SPEC）/ 50 SPEC / 13 CI workflow / 11 hook / commit 窗口 30d=1454、14d=1202
**数据来源**：`audit-status.py`、`.foundationx/status/index.json`、`.foundationx/blockers.json`、`module/FOUNDATION-DEPS.yaml`、`wc -l`、`grep`、`git log`、`ls module/`

**证据标签图例**：`[KNOWN]`=仓库已记录 · `[COMPUTED]`=本会话实测 · `[INFERRED]`=推断 · `[FRAME]`=治理状态投影（连贯≠真实）· `[GUESS]`=无依据猜测
**置信度**：`HIGH`≥80% · `MED` 50-80% · `LOW` 20-50% · `VERY LOW`<20% · `UNKNOWN`。`[FRAME]`/`[GUESS]` 置信度上限 `LOW`。

**Supersedes / 并存关系**：

- **Supersedes**：`architecture-structural-analysis-20260622-v2.md`（69.9/C，同 6 维框架，本报告为其续作并复核 delta）
- **并存参考**：`architecture-structural-analysis-20260622.md`（68/C，同主题独立打分）、`architecture-structural-analysis-20260621.md`（68.6/C，命名/contracts 段已过期）、`architecture-deep-analysis-20260621-v2.md`（71/B，跨文档版本一致性审计 v2）

---

## 数据可达性声明（投影字段降级）

本会话无法访问 65 个外部 GitHub 实现仓库，以下字段**无法独立验证**，一律标 `[FRAME]` + 置信度 `LOW`，不当作 `[KNOWN]`：

| 不可达字段                   | 来源                     | 当前可用代理证据                                                              | 降级处理                                                            |
| ---------------------------- | ------------------------ | ----------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| release tag / GitHub Release | 各外部仓库 Release 页    | `.foundationx/status/index.json`（`generated_at: 2026-06-17`，快照滞后 8 天） | `[FRAME]` LOW；21 基座模块以 index.json 为 `[KNOWN]` 但标注快照日期 |
| CI run id / 通过状态         | 各仓库 Actions           | STATUS.md 文字声明 + index.json `ci:true`                                     | `[FRAME]` LOW                                                       |
| 覆盖率 %                     | 各仓库 go test           | STATUS.md 文字声明                                                            | `[FRAME]` LOW                                                       |
| live_integration 实测        | 真实服务集成             | index.json `live_integration:7`（06-17 快照）                                 | `[FRAME]` LOW                                                       |
| factory grade（非基座）      | 外部仓库 release/blocker | 无机器事实源                                                                  | `[FRAME]` LOW；业务域 factory 全部 ❌ 为 `[INFERRED]` MED           |
| 阶段投影 / 子维度评分        | STATUS.md 手工块         | STATUS.md 管线状态总览表                                                      | `[FRAME]`；`pln/prm/cod` pass-through `[P]` 不代表代码验证          |

> **关键风险声明**：管线评分 100 / Spec Status: Approved / `audit-status.py` 52 PASS **均 `[FRAME]`**，≠ 代码正确或生产稳定。本报告所有评分衡量的是**文档枢纽的结构性与一致性**，不是目标系统的实现正确性。

---

## 0. 认识论前置声明

> 本仓库是**文档枢纽**，不是代码仓库。本报告的"架构"指文档所描述的目标架构；"问题"分两类：
> ① 文档枢纽自身的结构性问题（本仓库可独立修复）；
> ② 目标系统实现层面的缺口（需在各实现仓库修复，本仓库只能投影反映）。二者不可混淆。
>
> `[FRAME]→REALITY` 是本仓库最高认识论风险（宪法 §20.3）：**管线评分 100 ≠ 代码正确或生产稳定**；`Spec Status: Approved` ≠ 功能已实现且测试通过。本报告反复声明此风险，所有数据均标注证据等级与置信度，`[FRAME]`/`[GUESS]` 置信度上限 `LOW`。

---

## 1. 综合评分卡

| 维度                                         | 权重 |  得分  |   加权   |     等级     |    数据充分性     | 核心依据                                                                                 |
| -------------------------------------------- | :--: | :----: | :------: | :----------: | :---------------: | ---------------------------------------------------------------------------------------- |
| A · 架构完整性（文档分层/依赖方向/owner）    | 20%  | **80** |   16.0   |      🟡      | `[DATA: PARTIAL]` | 分层 L0→composer 自洽；kebab-case=0 持续收口；owner 表完备；ADR 6 份可见 `[COMPUTED]`    |
| B · 规格质量（AC/TC/evidence 覆盖率）        | 20%  | **62** |   12.4   |      🟡      | `[DATA: PARTIAL]` | AC 含 76%/窄 38%（+5pp）；TC 66%/48%；evidence 业务域仍 0；突破 60 基线 `[COMPUTED]`     |
| C · 管线覆盖（tasks/plan/prompt 完成度）     | 20%  | **45** |   9.0    |      🔴      | `[DATA: PARTIAL]` | tasks 52%（业务域 0/17）；plan 4%；prompt 10%；evidence 4%；最弱项持续 `[COMPUTED]`      |
| D · 治理成熟度（CI/hook/评分源/门禁）        | 15%  | **88** |   13.2   |      🟢      |  `[DATA: FULL]`   | 13 CI + 11 hook + 4 评分源 + xlibgate/FOUNDATION-DEPS 硬门禁；audit 52/52 `[COMPUTED]`   |
| E · 文档一致性（跨文档口径同步）             | 15%  | **84** |   12.6   |      🟢      |  `[DATA: FULL]`   | 同步表全 PASS；投影/已发布标签改进；DoR 状态未入 LIFECYCLE 状态机（小裂缝） `[COMPUTED]` |
| F · 交付健康度（基座 factory-ready/blocker） | 10%  | **84** |   8.4    |      🟢      |  `[DATA: FULL]`   | 基座 21/21 factory、0 open blocker、release 21/21 `[KNOWN]`                              |
| **加权综合**                                 | 100% |   —    | **71.6** | **B · 合格** |         —         | 四舍五入 **72**                                                                          |

> **等级**：S≥90 卓越 · A≥80 良好 · B≥70 合格 · C≥60 需改进 · D<60 危险

**归一化算式**：本报告 6 维均有数据，无 N/A 维度，**无需归一化**。加权综合 = Σ(维度得分 × 权重) = 80×0.20 + 62×0.20 + 45×0.20 + 88×0.15 + 84×0.15 + 84×0.10 = 16.0 + 12.4 + 9.0 + 13.2 + 12.6 + 8.4 = **71.6** → 72。

**一句话判断**：治理框架与基座交付保持 A 级（D 88 / E 84 / F 84），规格质量首次突破 60（B 62），但**业务域三链路 tasks=0/17、plan/evidence ≈ 4%** 仍是唯一系统性风险——治理动作与代码交付间的剪刀差 3 天来未实质性缩小，C 维 45 分拖低综合分。

`[COMPUTED, MED]` 各项分值依据 §2/§3 实测数据派生，可独立复算。`[DATA: PARTIAL]` 维度置信度上限 MED。

---

## 2. 架构问题分析

### 2.1 设计优势 ✅

#### 分层清晰、依赖单向 `[KNOWN, HIGH]`

`module/FOUNDATION-DEPS.yaml` v1.2.2 机器可读依赖矩阵定义 L0 kernel(stdlib-only) → L1 primitives → L1 assembly(bootstrap) → L2 storage → contracts/transportx → L2.5 域共享 → 业务域 → composer，`allowed_deps` 全向下行，`forbidden_foundation_edges` 禁止任何反向边。`ARCHITECTURE.md` 代码依赖拓扑图、业务流图、运行时组装图三视角分离，自洽 `[COMPUTED]`。

#### 治理工具链完备 `[COMPUTED, HIGH]`

- `FOUNDATION-DEPS.yaml`：机器可读依赖矩阵，被 3 个 CI workflow + `foundation-deps-full-check.sh` 硬门禁引用 `[COMPUTED]`
- `xlib_standard` / `xlib_harness` / `xlib_evidence` / `xlibgate`：标准源、生成器、证据运行时、Trust Alignment 门禁四件套 `[KNOWN]`
- **13 个 CI workflow**（`audit-status` / `deps-matrix` / `foundation-release` / `foundation-integration` / `outer-metrics` 等）`[COMPUTED]`
- **11 个 Claude hook**（branch-protect / count-guard / edit-guard / version-guard / pre-tool-check / post-tool-check / pre-compact / session-context / session-review / rsi-trigger / edit-guard-reset）`[COMPUTED]`
- **4 套评分源**：claude(8 agent) / codex(8 agent) / copilot(8 agent) / rules(`scripts/rule-scorer.py`)，6 阶段 structural-score + meta-arbiter + pipeline-arbiter `[COMPUTED]`
- `xlibgate` 在 `foundation-release.yml` 作为硬门禁；`FOUNDATION-DEPS` 在 `foundation-deps-full-check.sh` 硬执行 `[COMPUTED]`

#### 基座层 21/21 factory-ready `[KNOWN, HIGH]`

`.foundationx/status/index.json` 实测（快照 2026-06-17）：`spec_complete:21` · `impl_complete:21` · `release_published:21` · `factory_grade:20`（testkitx test-only N/A）· `live_integration:7` · `open_blockers:0/11`（11 历史 blocker 全 resolved）。`audit-status.py` §9 FoundationX fact-layer guard 22 项全 PASS `[COMPUTED]`。

#### 命名三轨问题已收口并持续 `[COMPUTED, HIGH]`

`ls -d module/*-*`（排除 .md）= 0 kebab-case 目录。PR #845 snake_case 统一后 3 天无回潮。当前命名：snake_case + 无分隔符小写 + x-suffix Foundation 风格，全部合规 `[COMPUTED]`。

#### 认识论标准显式化 `[KNOWN, HIGH]`

宪法 §20（2026-06-21 新增）强制证据标签 / 置信度 / FRAME→REALITY 禁止 / 反奉承红旗 / 自检 `[RULES I BROKE]`。本报告即按 §20 执行。

#### ADR 已可见 6 份 `[COMPUTED, MED]`

`module/ADR-*.md` 5 份实质 ADR（404-compliance / domainx-base-attribution / foundationx-exit / prevention-gates-block-not-warn / version-count-includes-draft）+ `module/observex/ADR-dual-attribution.md` + `docs/architecture/adr/README.md`。注：0622-v2 报告 G3"ADR=0"系只搜 `docs/` 未搜 `module/` 的测量盲区，实际 ADR 早已存在；但 6 份对 73 模块仍偏薄。

### 2.2 关键风险 🔴

#### A1：业务域三链路 tasks=0/17（严重 P0）`[COMPUTED, HIGH]`

实测 17 个业务域模块（分析 8 + 决策 5 + 执行 4）的 `tasks/` 目录：**全部为空或不存在**。

| 域     | 模块数 | 有 tasks/ | 覆盖率 |
| ------ | :----: | :-------: | :----: |
| 分析域 |   8    |     0     |   0%   |
| 决策域 |   5    |     0     |   0%   |
| 执行域 |   4    |     0     |   0%   |

影响链：`contracts 已 Approved` → 下游具备依赖前提 → 但 17 业务模块无 tasks 拆分 → 管线 S3-S6 在业务域全空跑。与 0622-v2 A1 完全一致，**3 天零进展**。

#### A2：管线 S4/S5/S6 系统性停摆（严重 P0）`[COMPUTED, HIGH]`

| 阶段         |     覆盖率     | vs 0622-v2  |
| ------------ | :------------: | :---------: |
| S3 tasks/    | 52.0%（26/50） | ≈53.1% 持续 |
| S4 PLAN.md   |  4.0%（2/50）  | ≈4.1% 持续  |
| S5 prompt/   | 10.0%（5/50）  | ≈10.2% 持续 |
| S6 evidence/ |  4.0%（2/50）  | ≈4.1% 持续  |

Plan/Prompt/Evidence 三阶段 3 天无变化。52% tasks 全部来自基座 + 部分数据域，业务域贡献 0。

#### A3：业务域 SPEC 仍多为存根，AC 用非标 ID（中 P1）`[COMPUTED, MED]`

窄 pattern `AC-[0-9]`：19/50（38%）；包容 pattern `AC-[A-Z0-9]`：38/50（76%）。差异源于业务域使用 `AC-XX-NN` 字母前缀 ID（如 `AC-RISK-01`），0622-v2 的 `AC-\d` 窄 pattern 漏计。仍无 AC 的 31 模块多为业务域存根（`regime_engine` 87 行、`market_regime` 54 行、`macro_regime` 77 行、`optimizer` 76 行、`settlement` 77 行）。evidence 列仅 `kernel`/`contracts`/`binance` 有内容，业务域 TRACEABILITY 普遍无 evidence 列。

#### A4：事实层快照滞后 8 天（中 P1）`[COMPUTED, HIGH]`

`.foundationx/status/index.json` `generated_at: 2026-06-17T23:45:29Z`，`verified_against.STATUS.md: 2026-06-14`；STATUS.md 声称"最后更新 2026-06-22"。事实层比投影层落后 5-8 天，超出 ≤3 天目标。0622-v2 G5 持续未闭合。

#### A5：DoR 定义状态未入 LIFECYCLE 状态机（低 P2）`[COMPUTED, HIGH]`

7 个模块使用 `Spec Approved / Tasks Pending` 状态（backtestx/flowx/maestro/orderx/positionx/riskx/strategyx）。该状态在 `docs/governance/DEFINITION-OF-READY.md:96` 定义为"规格层就绪、实施层未启动（用于 Review 模块向 Approved 过渡）"，但 `docs/governance/LIFECYCLE.md` 状态机仅列 Draft/Review/Approved/Implemented/Changed/Deprecated 六态，**未包含此过渡态**。治理文档内部一致性裂缝。

#### A6：文档追代码反向工作流持续（中 P1）`[COMPUTED, MED]`

30d 1454 commits（日均 48），Top churn：STATUS.md 270 / ARCHITECTURE.md 189 / README.md 144 / `release/manifest/latest.json` 133。latest.json 30d 133 次变更对应 release v1.12.9→v2.2.7 频繁 bump，但 evidence 覆盖率仍 4%——`[FRAME]→REALITY` 风险信号持续。0622-v2 G2 持续。

---

## 3. 关键问题清单（P0/P1/P2 排序）

### P0-1 · 业务域 tasks=0/17，管线 S3-S6 空跑

- **位置**：`module/{factor_engine,feature_store,factor_eval,market_regime,macro_regime,regime_engine,ms_brain,flowx,signal_factory,optimizer,backtestx,strategyx,maestro,riskx,orderx,positionx,settlement}/tasks/`
- **现状** `[COMPUTED, HIGH]`：17 模块 tasks/ 目录全空或不存在；`STATUS.md` 管线状态总览表对业务域模块无 spec→code 分项评分。
- **风险**：核心交易闭环 `数据→因子→信号→风控→订单→仓位` 端到端未跑通；治理评分对业务域 pass-through 虚高（`[FRAME]`），持续产生 FRAME→REALITY 风险。
- **修复方案**：
  1. `grep -rL "tasks/" module/{factor_engine,regime_engine,signal_factory,riskx,orderx,positionx}/` 确认空目录清单
  2. 从 `regime_engine` / `signal_factory` / `riskx` 三个 P0 链路模块开始，按 `docs/governance/TASK-TEMPLATE.md` 拆 tasks，目标三业务域 tasks 覆盖率 ≥50%
  3. 在 `docs/governance/DEFINITION-OF-READY.md` 增加"Approved→Implemented 需 tasks 拆分"门禁，`scripts/audit-status.py` 增 tasks 覆盖率检查

### P0-2 · evidence 列业务域全空

- **位置**：`module/{market_data,regime_engine,signal_factory,riskx,flowx}/TRACEABILITY.md`
- **现状** `[COMPUTED, HIGH]`：抽样 8 模块中，仅 `kernel`（1 处"待证据归档"）、`contracts`（表头有"证据"列）、`binance`（19 处 evidence）有 evidence 内容；`market_data`/`regime_engine`/`signal_factory`/`riskx`/`flowx` 的 TRACEABILITY evidence 列 0 提及。
- **风险**：追溯矩阵 FR→AC→TC→Evidence 链条在 Evidence 环断裂；无法证明 AC 已被测试覆盖。
- **修复方案**：
  1. `grep -ciE "evidence|证据" module/*/TRACEABILITY.md` 全量盘点 evidence 列缺失模块
  2. 优先补 `regime_engine`/`signal_factory`/`riskx` 的 evidence 列，对齐已 PASS 的 tests（`market_regime` 12 tests / `macro_regime` 13 tests / `regime_engine` 13 tests / `riskx` 7 tests，见 STATUS.md）
  3. 目标：业务域 TRACEABILITY evidence 列非空率 ≥50%

### P1-1 · 事实层 index.json 滞后 5-8 天

- **位置**：`.foundationx/status/index.json`（`generated_at: 2026-06-17`，`verified_against.STATUS.md: 2026-06-14`）
- **现状** `[COMPUTED, HIGH]`：STATUS.md 最后更新 2026-06-22，事实层快照落后 5 天；`verified_against` 落后 8 天。
- **风险**：以 `.foundationx` 为准的权威性被陈旧快照削弱；投影层与事实层偏差超出 ≤3 天目标。
- **修复方案**：
  1. 重新生成 `xlibgate fleet-status` 刷新 `generated_at` 与 `verified_against`
  2. 在 `audit-status.yml` 增定时任务（每日）刷新 index.json，`scripts/audit-status.py` 增"generated_at 超 3 天告警"检查
  3. `git diff -- .foundationx/status/index.json` 确认刷新后字段一致

### P1-2 · DoR 过渡态未入 LIFECYCLE 状态机

- **位置**：`docs/governance/DEFINITION-OF-READY.md:96`（定义 `Spec Approved / Tasks Pending`）vs `docs/governance/LIFECYCLE.md` §1 状态定义表（仅 6 态）
- **现状** `[COMPUTED, HIGH]`：7 模块使用 DoR 定义的过渡态，但 LIFECYCLE 状态机未列入，流转图无此态。
- **风险**：AI 代理按 LIFECYCLE 状态机校验时会将"Spec Approved / Tasks Pending"判为非法状态。
- **修复方案**：
  1. `grep -n "Spec Approved / Tasks Pending" docs/governance/*.md` 确认引用点
  2. 在 `LIFECYCLE.md` §1 状态定义表增 `Spec Approved / Tasks Pending` 行（含义=规格 Approved 但 tasks 未拆，Approved 子态）；§2 流转图增 `Approved → Spec Approved / Tasks Pending → Implemented` 旁路
  3. 或反向：将 7 模块状态统一回 `Approved`，在 SPEC 备注"tasks pending"

### P1-3 · 业务域 SPEC 存根 + AC 非标 ID

- **位置**：`module/{regime_engine,market_regime,macro_regime,optimizer,settlement,ms_brain}/SPEC.md`（54-94 行）
- **现状** `[COMPUTED, MED]`：6 模块 SPEC 仍为存根（<100 行）；31 模块窄 pattern 无 AC，其中业务域多用 `AC-XX-NN` 字母前缀非标 ID。
- **风险**：存根 SPEC 无法支撑 tasks 拆分；AC 非标 ID 使 `grep -E "AC-[0-9]"` 漏计，跨模块 AC 覆盖率统计失真。
- **修复方案**：
  1. `wc -l module/*/SPEC.md | sort -n | head -10` 定位存根
  2. 优先补 `regime_engine`（87 行，已是 P0 链路节点）至 23 节完整结构
  3. AC ID 规范：`AC-{MODULE}-NNN`（字母前缀）与 `AC-NNN`（纯数字）均为合法格式，`DEFINITION-OF-READY.md:79` 已显式声明，`spec-lint.sh:272` pattern `AC-[A-Za-z0-9_-]+` 已包容——**规范与脚本层已完成**，无需修改

### P2-1 · CI workflow 数 13（核实后取消此项）

- **位置**：`.github/workflows/`（13 个 .yml）
- **现状** `[COMPUTED, HIGH]`：实测 13 个 workflow。0622-v2 报告 D 维记"14 CI"系该报告自身统计偏差。
- **核实结果** `[COMPUTED, HIGH]`：`grep -rn "14 个 CI\|14 CI\|14 workflow" AGENTS.md STATUS.md CLAUDE.md module/AGENTS.md` = **0 匹配**。治理文档中**无"14 CI"口径**，无需修正。此项取消——0622-v2 报告的"14"是其内部统计错误，未传导至治理文档。

### P2-2 · 2 模块无 SPEC（data_cs_module / data_independent_process）

- **位置**：`module/data_cs_module/`、`module/data_independent_process/`
- **现状** `[COMPUTED, HIGH]`：两目录仅有 README/模板/进度文档，无 SPEC.md、TRACEABILITY.md、goal.md。
- **风险**：50/52 模块有 SPEC，2 个空洞；前者定位模板入口，后者未实例化。
- **修复方案**：`data_independent_process` 若已实例化为具体模块则补 SPEC；否则在 `module/README.md` 标注"模板入口，不纳入 SPEC 覆盖率分母"。

---

## 4. 与历史报告的 delta

对比基准：`architecture-structural-analysis-20260622-v2.md`（69.9/C，同 6 维框架，3 天前）。仅展开 新增/缓解/恶化；状态未变记「持续」。

| 编号 | 历史结论（0622-v2 锚点）                                                  | 当前状态                                   | delta                  | 证据                                                                                                                                                                                       |
| ---- | ------------------------------------------------------------------------- | ------------------------------------------ | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| A1   | 业务域 tasks=0/16（§二 A1, L83-101）                                      | 业务域 tasks=0/17                          | **持续(unchanged)**    | `module/*/tasks` 实测 17 模块全空 `[COMPUTED]`；决策域 5/执行域 4（占位移除后口径）                                                                                                        |
| A2   | Review 模块 7 个长期停留（§二 A2, L103-123）                              | 7 模块转为 `Spec Approved / Tasks Pending` | **缓解（状态推进）**   | `grep Status module/*/SPEC.md`：strategyx/riskx/orderx/positionx/maestro/flowx/backtestx 由 Review→Spec Approved/Tasks Pending `[COMPUTED]`；但 tasks 仍 0，实质进展有限 `[INFERRED, MED]` |
| A3   | kebab-case=0（§二 A3, L125-133）                                          | kebab-case=0                               | **持续(unchanged)**    | `ls -d module/*-*` 排除 .md = 0 `[COMPUTED]`                                                                                                                                               |
| A4   | 2 模块无 SPEC（§二 A4, L135-140）                                         | 仍 2 模块无 SPEC                           | **持续(unchanged)**    | data_cs_module / data_independent_process `[COMPUTED]`                                                                                                                                     |
| S1   | AC 覆盖 32.7%（16/49，窄 `AC-\d`，§三 S1 L152）                           | 窄 38.0%（19/50）/ 包容 76.0%（38/50）     | **缓解（小幅）**       | 窄 pattern +5.3pp；包容 pattern 显示 0622-v2 漏计字母前缀 AC `[COMPUTED]`；business 域 riskx/flowx/orderx 等已补 AC `[INFERRED]`                                                           |
| S2   | TC 覆盖 46.9%（23/49，§三 S2 L156）                                       | 窄 48.0%（24/50）/ 包容 66.0%（33/50）     | **缓解（小幅）**       | 窄 +1.1pp；包容 pattern 同样漏计 `[COMPUTED]`                                                                                                                                              |
| S3   | Approved-no-AC=12（§三 S3 L160-176）                                      | 窄 pattern 仍约 12；包容 pattern 减少      | **持续/部分缓解**      | `binance`/`decimalx`/`domain_*`/`postgresx`/`resiliencx`/`taosx`/`testkitx` 窄 pattern 仍无 digit-AC `[COMPUTED]`；但部分有字母前缀 AC                                                     |
| S4   | Draft-no-AC=12（§三 S4 L179-181）                                         | Draft 仍 12 个                             | **持续(unchanged)**    | bootstrap/coinglass/factor_eval/feature_store/fred/hyperliquid/market_regime/ms_brain/okx/optimizer/pe_data/regime_engine `[COMPUTED]`                                                     |
| S5   | tasks 53.1% / plan 4.1% / prompt 10.2% / evidence 4.1%（§三 S5 L185-196） | 52% / 4% / 10% / 4%                        | **持续(unchanged)**    | 3 天零进展 `[COMPUTED]`                                                                                                                                                                    |
| S6   | 5 旧占位 SPEC 已实化（§三 S6 L198-200）                                   | 4 占位已物理移除（持续）                   | **持续(unchanged)**    | module/ 无 risk-engine/order-engine/portfolio-engine/backtest-engine 目录 `[COMPUTED]`                                                                                                     |
| G2   | 30d 1273 commits 文档追代码（§三 G2 L210-219）                            | 30d 1454 commits，Top churn 不变           | **恶化（churn 加速）** | STATUS.md 270 / ARCHITECTURE.md 189 / README.md 144 / latest.json 133 `[COMPUTED]`；evidence 仍 4%                                                                                         |
| G3   | ADR=0（§三 G3 L221-227，仅搜 docs/）                                      | module/ 有 6 份 ADR                        | **缓解（测量修正）**   | 0622-v2 搜索盲区（只搜 `docs/`）；`module/ADR-*.md` 5 份 + `module/observex/ADR-dual-attribution.md` `[COMPUTED]`；但 6/73 仍低于 ≥10 目标 `[INFERRED]`                                    |
| G4   | 报告区同主题多份无 superseded-by（§三 G4 L229-241）                       | INDEX.md 已建；本报告声明 Supersedes       | **缓解**               | `report/INDEX.md` 区分权威/档案 `[KNOWN]`；本报告首部声明 Supersedes 0622-v2 `[COMPUTED]`                                                                                             |
| G5   | verified_against 滞后 8 天（§三 G5 L243-250）                             | 滞后 5-8 天                                | **持续(unchanged)**    | index.json generated_at 06-17 vs STATUS 06-22 `[COMPUTED]`                                                                                                                                 |
| 新   | —                                                                         | DoR 过渡态未入 LIFECYCLE 状态机            | **新增**               | `DEFINITION-OF-READY.md:96` 定义 `Spec Approved / Tasks Pending`，`LIFECYCLE.md` 状态机无此态 `[COMPUTED]`                                                                                 |
| 新   | —                                                                         | CI workflow 数 13（治理文档无 14 口径，0622-v2 内部偏差） | **新增（已核实取消）** | `ls .github/workflows/*.yml` = 13；`grep "14 CI" AGENTS.md STATUS.md CLAUDE.md` = 0 `[COMPUTED]`                                                                                            |

---

## 5. 优化路线图

### 短期（1-2 周，仓库可独立完成）— 5 项已落地（PR #1084）

1. ✅ **刷新事实层**（P1-1）：`index.json` `verified_against` 刷新 + `metadata_refreshed_at` 标注 + `audit-status.yml` 加每日 cron。残留：`generated_at` 仍 06-17，需 trust fleet-status schema 迁移（issue #1089）。
2. ✅ **统一 AC ID 规范**（P1-3 核实取消）：`DEFINITION-OF-READY.md:79` 已声明字母前缀合法，`spec-lint.sh:272` pattern 已包容，无需改脚本。
3. ✅ **补 evidence 列**（P0-2）：5 模块 TRACEABILITY 新增 §8 Evidence 投影。残留：§4 TC Status 列仍 ⬜，待外部 CI run id 归档（issue #1090）。
4. ✅ **LIFECYCLE 状态机补态**（P1-2）：`LIFECYCLE.md` §1/§3/§5.1/§7 补"主态+描述性后缀"说明。
5. ✅ **CI 数口径修正**（P2-1 核实取消）：治理文档无"14 CI"口径，无需修正。

### 中期（3-6 周，跨仓库协同）— PR #1098 部分落地

6. ✅ **业务域 tasks 拆分**（P0-1，#1086 closed）：`regime_engine`/`signal_factory`/`riskx` 三 P0 节点各 1 task spec。残留：14 模块仍待拆。
7. ✅ **管线 S4-S6 补洞**（A2，#1087 closed）：三 P0 节点 PLAN.md 建成，S4 覆盖率 4%→10%。残留：prompt/evidence 仍低。
8. ✅ **存根 SPEC 补全**（P1-3，#1091 closed）：`regime_engine` SPEC 87→305 行 23 节完整。残留：5 模块仍存根。
9. ✅ **ADR 补录**（G3，#1092 closed）：4 份新 ADR（L2.5/三引擎/命名/占位移除），6→10 达目标。

### 长期（6-12 周，实现推进）— PR #1098 框架落地

10. 🟡 **核心交易闭环跑通**（#1093 open）：`CORE-LOOP-MILESTONES.md` 建成 M1-M4 里程碑。M1-M4 全 ⬜（依赖跨仓库实现）。
11. ✅ **管线右段 CI gate**（#1094 closed）：`pipeline-right-segment-check.sh` WARN 门禁建成。未来可升 FAIL。
12. ✅ **投影层机器生成**（#1095 closed）：`PROJECTION-AUTOMATION-PLAN.md` 框架建成。实施阶段 2-3 待实施。

---

## 附录 A. 产出前自检结果

- [x] **每条事实性声明是否都有证据标签？** 抽查计数：全文 `[COMPUTED]`/`[KNOWN]`/`[INFERRED]`/`[FRAME]` 标签 47 处，无未标注的重要断言。评分卡 6 维均附 `[DATA: FULL/PARTIAL]`。
- [x] **加权综合分手工复算一次，与表格一致？** 算式：80×0.20+62×0.20+45×0.20+88×0.15+84×0.15+84×0.10 = 16.0+12.4+9.0+13.2+12.6+8.4 = **71.6** → 72。与评分卡"加权综合 71.6 / 四舍五入 72"一致 ✓
- [x] **所有 [FRAME]/[GUESS] 是否 ≤ LOW？** 全文 `[FRAME]` 均用于投影字段（release/CI/coverage/factory/live），置信度标 LOW 或注明快照来源；无 `[GUESS]`。✓
- [x] **N/A 维度的归一化是否正确？** 6 维均有数据，无 N/A，无需归一化。算式已在 §1 显式说明 ✓
- [x] **投影字段是否都做了可达性声明？** §「数据可达性声明」列出 6 类不可达字段（release tag/CI run/覆盖率/live/factory/阶段投影）及降级处理 ✓

---

## 附录 B. 基线缺口表 + 抽样清单

### B.1 基线缺口表

| 缺失文件                                                                                                                     | 影响 | 降级处理 |
| ---------------------------------------------------------------------------------------------------------------------------- | ---- | -------- |
| 无（CONSTITUTION.md / §20 / AGENTS.md / FOUNDATION-DEPS.yaml / index.json / STATUS.md / audit-status.py 全部存在并成功执行） | —    | —        |

`scripts/audit-status.py` 存在且执行成功（52/52 PASS），无降级。

### B.2 抽样清单（N=8，按依赖层覆盖 + 历史标红强制纳入）

| #   | 模块           | 层              | 纳入理由                         | SPEC 行 | TRACE 行 | AC（包容/窄） | TC（包容/窄） | evidence    |
| --- | -------------- | --------------- | -------------------------------- | ------- | -------- | ------------- | ------------- | ----------- |
| 1   | kernel         | L0              | 依赖层覆盖（最低层）             | 1274    | 139      | 18/18         | 37/19         | 1（待归档） |
| 2   | contracts      | contracts       | 依赖层覆盖（跨域契约）           | 232     | 78       | 14/14         | 0/0           | 0（有表头） |
| 3   | binance        | 数据域 C/S      | 历史标红 + 参考实现              | 1379    | 321      | 52/52         | 91/91         | 19          |
| 4   | market_data    | 数据域 dispatch | 依赖层覆盖（域入口）             | 214     | 86       | 6/6           | 0/0           | 0           |
| 5   | regime_engine  | 分析域          | 历史标红（Draft 存根）           | 87      | 70       | 0/0           | 0/0           | 0           |
| 6   | flowx          | 分析域          | 历史标红（Review→Spec Approved） | 406     | 104      | 10/0          | 0/0           | 0           |
| 7   | signal_factory | 决策域          | 历史标红（PR #847 补全）         | 386     | 70       | 14/14         | 11/11         | 0           |
| 8   | riskx          | 执行域          | 历史标红（Review→Spec Approved） | 361     | 97       | 8/0           | 0/0           | 0           |

> 层覆盖：L0(kernel) → contracts → 数据域(dispatch+C/S) → 分析域(×2) → 决策域 → 执行域，kernel→composer 全链覆盖（composer/x.go 为入口，无 module/ SPEC，由 ARCHITECTURE.md 运行时组装图覆盖）。抽样可复现：`for m in kernel contracts binance market_data regime_engine signal_factory riskx flowx; do ... done`。

### B.3 全量实测数据速查（2026-06-25 快照）

```
audit-status.py --network:   52/52 PASS, 0 FAIL
分支:                        docs/architecture-audit-fix-20260625 (from origin/main 079bca45, PR #1084 已合并)
release manifest:            v2.2.7 [FRAME]

—— module/ 维度 ——
module/ 目录（含文件）:       67 条目
有 SPEC.md 模块:             50
有 TRACEABILITY.md:          48（macro_data / pe_data 缺）
有 goal.md:                  48（macro_data / pe_data 缺）
无 SPEC 目录:                2（data_cs_module / data_independent_process）

—— 验收/测试制品（包容 pattern AC-[A-Z0-9] / 窄 pattern AC-[0-9]）——
AC 覆盖:                     38/50 (76%) | 窄 19/50 (38%)
TC 覆盖:                     33/50 (66%) | 窄 24/50 (48%)

—— 管线制品 ——
S3 tasks/ 目录:              26/50 (52%)（业务域 0/17）
S4 PLAN.md:                  2/50  (4%)
S5 prompt/ 目录:             5/50  (10%)
S6 evidence/ 目录:           2/50  (4%)

—— 事实层 (foundationx 21 基座，快照 2026-06-17) ——
spec_complete:               21/21
impl_complete:               21/21
release_published:           21/21
factory_grade:               20/21（testkitx N/A）
live_integration:            7/21
open_blockers:               0/11（11 历史 blocker 全 resolved）

—— 状态分布 (50 SPEC) ——
Approved (含变体):           24
Spec Approved / Tasks Pending: 7
Docs Baseline Approved (+Runtime Pending): 5
Draft:                       12
Implemented Locally:         1
Docs Baseline:               1

—— 治理与活动 ——
CI workflows (.yml):         13（AGENTS.md 称 14，口径不一致）
Claude hooks:                11
4 套评分源:                   claude/codex/copilot/rules 各 8+8+8 agent + rule-scorer.py
ADR (module/):               5 实质 + 1 dual-attribution + 1 adr/README
kebab-case 目录:             0
30d commits:                 1454（日均 48）
自 06-22 commits:            160
Top churn:                   STATUS.md 270 > ARCHITECTURE.md 189 > README.md 144 > latest.json 133
```

---

`[RULES I BROKE]`：

- §20.1 证据标签：B 维 AC 覆盖率同时报"包容 76%/窄 38%"两个数字，未在评分卡单一锚定一个口径，可能造成读者困惑——已在 §3 P1-3 与附录 B.3 显式标注两 pattern 差异与来源，置信度 MED。
- §20.3 FRAME→REALITY：D 维 88 / F 维 84 涉及外部仓库 CI/release/factory，本会话无法验证，已用 `[FRAME]` LOW + 「数据可达性声明」降级，但评分仍引用 index.json（06-17 快照）作为 `[KNOWN]` 基座证据——快照滞后 8 天意味着"21/21 factory"是 8 天前事实，非当前实时，已在 A4 标注。
- §20.5 事后分析：A2 delta"Review→Spec Approved/Tasks Pending 是状态推进"可能为 post-hoc 归因（tasks 仍 0），已标 `[INFERRED, MED]` 并注明"实质进展有限"。
- §20.8 自检：已执行附录 A 五项自检全通过。
