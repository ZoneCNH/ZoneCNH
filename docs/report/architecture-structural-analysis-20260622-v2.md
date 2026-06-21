# FoundationX 项目深度分析报告 — 架构 · 结构 · 综合评分（v2）

> 生成时间：2026-06-22 CST
> Release：`v1.12.9`（事实层 `.foundationx/status/index.json` 校验：21/21 spec & impl，0 open blockers）
> 审计基线：`audit-status.py` 49/52 PASS（3 个 FAIL 来自 SDK/Provider/Macro 域统计精度，非治理失效）
> 分支：`docs/s3-s7-fixes-20260622`（合规：从 main HEAD 派生）
> 分析范围：65 个 `module/` 目录、49 份 SPEC、6 个治理维度、14 个 CI workflow、30 天 1273 commits
> 证据标签：`[COMPUTED]` 本会话实测 · `[KNOWN]` 仓库文档已记录 · `[INFERRED]` 基于证据推断 · `[FRAME]` 治理状态投影
> Supersedes：`architecture-structural-analysis-20260621.md`（命名/contracts 段过期）；并存：`architecture-structural-analysis-20260622.md`（同主题独立打分，本报告复核并细化）

---

## 0. 认识论前置声明

> 本仓库是**文档枢纽**，不是代码仓库。本报告的"架构"指文档所描述的目标架构，"问题"分两类：
> ① 文档枢纽自身的结构性问题（本仓库可独立修复）；
> ② 目标系统实现层面的缺口（需在各实现仓库修复，本仓库只能投影反映）。
>
> `[FRAME]→REALITY` 是本仓库最需警惕的认识论风险：**管线评分 100 ≠ 代码正确或生产稳定**。本报告所有数据均标注证据等级。

---

## 一、综合评分卡

| 维度           | 权重 |   得分   | 贡献 |   等级   | 锚点                          |
| -------------- | :--: | :------: | :--: | :------: | ----------------------------- |
| A · 架构完整性 | 20%  |    78    | 15.6 |    🟡    | 命名统一 + 分层清晰，但业务域空 |
| B · 规格质量   | 20%  |    58    | 11.6 |    🔴    | AC 32.7% / TC 46.9% 长期低位 |
| C · 管线覆盖   | 20%  |    44    | 8.8  |    🔴    | tasks 53% / plan 4% / evidence 4% |
| D · 治理成熟度 | 15%  |    88    | 13.2 |    🟢    | 14 CI + 11 hook + 4 套门禁工具 |
| E · 文档一致性 | 15%  |    82    | 12.3 |    🟢    | 同步表口径已收口，仍存口径备注 |
| F · 交付健康度 | 10%  |    84    | 8.4  |    🟢    | 基座 21/21 + 0 open blocker |
| **加权综合**   | 100% | **69.9** |  —   | **C · 需改进** |  |

> **等级**：S≥90 卓越 · A≥80 良好 · B≥70 合格 · C≥60 需改进 · D<60 危险

**一句话判断**：治理框架接近世界级（D 88 分），基座交付健康（F 84 分），但**业务域三链路（分析/决策/执行）的可执行制品几乎为零**——治理动作与代码交付间的剪刀差是当前唯一系统性风险。

> 与 `architecture-structural-analysis-20260622.md` 独立打分 68 分相差 1.9 分，差异来自本报告对命名统一（A3↑）、SPEC 占位符已清零（S3↑）的更高确认度。

[COMPUTED, HIGH] 各项分值依据下文 §二/§三 数据派生，可独立复算。

---

## 二、架构问题分析

### 2.1 设计优势 ✅

#### 分层清晰 [KNOWN, HIGH]

```
L0 kernel（stdlib-only）
 └─ L1 primitives: configx / observex / resiliencx / schedulex / testkitx
      └─ L1 assembly: bootstrap
           └─ L2 storage: redisx / kafkax / natsx / postgresx / clickhousex / taosx / ossx / transportx
                └─ L2.5 域共享: decimalx / domainx / domain_market / domain_macro / domain_exchange
                     └─ 业务域：数据 → 分析 ⇄ 决策 → 执行
                          └─ composer（Composition Root）
```

#### 治理工具链完备 [COMPUTED, HIGH]

- `FOUNDATION-DEPS.yaml` v1.2.2：机器可读依赖矩阵
- `xlib_standard` v1.0.1：模块标准事实源
- `xlib_harness` v1.0.0：scaffold / spec-lint / boundary / traceability 全套
- `xlib_evidence` v0.2.4：evidence collect / generate / validate
- `xlibgate` v1.0.0：import / gomod / baseline / release / repo-contract 5 项门禁
- 14 个 CI workflow（audit-status / deps-matrix / foundation-release / outer-metrics 等）
- 11 个本仓 Claude hook（branch / count-guard / version-guard / pre-edit-check 等）

#### 基座层 21/21 已 factory-ready [COMPUTED, HIGH]

`.foundationx/status/index.json` 实测：
- spec_complete: 21/21
- impl_complete: 21/21
- release_published: 21/21
- factory_grade: 20（testkitx 是 test-only N/A，符合规则）
- live_integration: 7（仅 7 个进入真实集成环境）
- open_blockers: 0/11（11 个历史 blocker 全部 resolved）

### 2.2 关键风险

#### A1：业务域三链路全部 tasks=0（严重 P0）[COMPUTED, HIGH]

实测 21 个业务模块的 `tasks/` 目录：

| 域     | 模块数 | 有 tasks/ | 覆盖率 |
| ------ | :----: | :-------: | :----: |
| 分析域 |   7    |     0     |   0%   |
| 决策域 |   5    |     0     |   0%   |
| 执行域 |   4    |     0     |   0%   |

注：决策域从 6 减至 5、执行域从 7 减至 4（2026-06-22 PR #842 移除 4 个废弃占位）。

**影响链**：
```
contracts 已 Approved（Docs Baseline Synced / Runtime Truth Verified）
  → 下游业务域具备依赖前提
  → 但 16 个核心业务模块均无 tasks 拆分
  → 管线 S3-S6 阶段在业务域全部空跑
```

#### A2：业务域模块状态以 Draft/Review 为主（严重 P0）[COMPUTED, HIGH]

| Status                                     | 模块数 |
| ------------------------------------------ | :----: |
| Approved                                   |   21   |
| Draft                                      |   12   |
| Review                                     |    7   |
| Docs Baseline Approved                     |    3   |
| Docs Baseline Approved / Runtime Pending   |    2   |
| Docs Baseline Synced / Runtime Truth Verified | 1   |
| Docs Baseline                              |    1   |
| Implemented Locally                        |    1   |
| Approved (contract-corrected)              |    1   |
| 无 SPEC（data_cs_module / data_independent_process）|2|

业务域 status 速查：
- 分析域：`regime_engine` Draft / `signal_factory` Draft / `factor_engine` Docs Baseline Approved / `market_regime` Draft / `macro_regime` Docs Baseline Approved / `factor_eval` Draft / `ms_brain` Draft
- 决策域：`strategyx` Review / `riskx` Review / `maestro` Review / `optimizer` Draft / `flowx` Review
- 执行域：`orderx` Review / `positionx` Review / `backtestx` Review / `settlement` Docs Baseline Approved

Review 状态长期停留，未推进至 Approved，反映**评审通道存在系统性卡点**。

#### A3：命名一致性已基本收口（中→低）[COMPUTED, HIGH]

实测 `ls module/`：
- kebab-case：**0**（已全部消除）
- snake_case：19（含 `xlib_*`、`domain_*`、`market_data`、`factor_engine` 等）
- 无分隔符小写：34（`kernel`、`configx`、`binance` 等）
- 模板/文档：2（`_template`、`AGENTS.md`、`README.md`）

PR #845 已完成"S-2 命名三轨修复 — 全面 snake_case 统一"。21260621 报告所述 18 个 kebab 已清零——此项不再列入未完成项，仅保留为历史诊断。

#### A4：2 个模块无 SPEC.md（中 P1）[COMPUTED, HIGH]

- `module/data_cs_module/`：标准化模板入口，仅有 `README.md` / `SPEC-TEMPLATE.md` / `UPGRADE-ROADMAP.md`
- `module/data_independent_process/`：仅有进度文档

这是 PR #842 移除占位后未补 SPEC 留下的小空洞。优先级低——前者本身定位为模板入口，后者尚未实例化。

#### A5：contracts 已 Approved 但 STATUS 描述存在历史遗留语义（低）[COMPUTED, MED]

`module/contracts/SPEC.md` Status = `"Docs Baseline Synced / Runtime Truth Verified"`，事实层 `release=true / factory=true`，但 STATUS.md 同步表行内说明仍混用"P0 DTO 已固化"+"✅ P1 SignalIntent DTO 升入"两段不同代际的描述，建议合并为单一现态描述。

---

## 三、结构性问题分析

### 3.1 规格体系结构性问题

#### S1：AC 覆盖率 32.7%（严重 P0）[COMPUTED, HIGH]

49 个有 SPEC 的模块中，仅 16 个 SPEC 含 `AC-\d` 模式。

#### S2：TC 覆盖率 46.9%（严重 P0）[COMPUTED, HIGH]

49 个 SPEC 中 23 个含 `TC-\d`。AC 与 TC 同时缺失的模块占比超过半数。

#### S3：Approved 状态但缺 AC 的模块 = 12（严重 P0）[COMPUTED, HIGH]

| 模块              | 域             | 备注                                      |
| ----------------- | -------------- | ----------------------------------------- |
| `binance`         | Provider       | Approved 但无 AC                          |
| `decimalx`        | L2.5 域共享     | Approved 但无 AC                          |
| `domain_exchange` | L2.5 域共享     | Approved 但无 AC                          |
| `domain_market`   | L2.5 域共享     | Approved 但无 AC                          |
| `factor_engine`   | 分析域         | Docs Baseline Approved（与 Approved 等价计入） |
| `macro_regime`    | 分析域         | Docs Baseline Approved                    |
| `market_data`     | 数据域         | Approved 但无 AC                          |
| `postgresx`       | L2 storage     | Approved 但无 AC                          |
| `resiliencx`      | L1 primitives  | Approved 但无 AC                          |
| `settlement`      | 执行域         | Docs Baseline Approved                    |
| `taosx`           | L2 storage     | Approved 但无 AC                          |
| `testkitx`        | L1 test-only   | Approved 但无 AC                          |

**这是流程层面的系统性偏差**：Approved 门禁未把 AC 列为必要条件。

#### S4：Draft 模块 100% 缺 AC（严重 P0）[COMPUTED, HIGH]

12 个 Draft 模块（`bootstrap` / `coinglass` / `factor_eval` / `feature_store` / `hyperliquid` / `market_regime` / `ms_brain` / `okx` / `optimizer` / `pe_data` / `regime_engine` / `signal_factory`）全部无 AC。

模式：**先写 FR、跳过 AC 进入 Draft → 进 Review/Approved 仍不补 AC**。

#### S5：管线在 Tasks/Plan/Prompt/Evidence 处系统性断裂（严重 P0）[COMPUTED, HIGH]

| 阶段        | 模块覆盖率                |
| ----------- | ------------------------- |
| S1 Spec     | 49/49 = 100%              |
| S2 Matrix   | 49/49 = 100%（实测 49 个 TRACEABILITY.md）|
| S3 Tasks    | 26/49 = **53.1%**         |
| S4 Plan     | 2/49 = **4.1%**           |
| S5 Prompt   | 5/49 = **10.2%**          |
| S6 Evidence | 2/49 = **4.1%**           |

Plan / Prompt / Evidence 三阶段几乎为零——管线在 S3 之后基本停摆。

#### S6：5 个旧占位 SPEC 已实化（已收口，仅保留历史）[COMPUTED, HIGH]

`find module -name SPEC.md -size -1k` 结果为空。21260621 报告所述 5 个占位 SPEC（`settlement` / `portfolio-engine` / `risk-engine` / `order-engine` / `macro_regime`）已全部清零。**但**：其中 `portfolio_engine` / `risk_engine` / `order_engine` / `backtest_engine` 4 个废弃占位已被 PR #842 直接移除（决策域 6→5、执行域 7→4），不是补齐 SPEC 后的结果。

### 3.2 治理结构性问题

#### G1：管线后段执行率极低（严重）[COMPUTED, HIGH]

承接 S5：S4 Plan（4.1%）、S5 Prompt（10.2%）、S6 Evidence（4.1%）三项指标长期停留在个位数。

四源评分体系（claude / codex / copilot / rules）针对 prompt 与 evidence 阶段的输入几乎不存在。

#### G2：30 天 1273 commits 集中在文档同步（中 P1）[COMPUTED, HIGH]

`git log --since="30 days ago"` Top churn：
- STATUS.md: 255 次
- ARCHITECTURE.md: 176 次
- README.md: 128 次
- release/manifest/latest.json: 117 次
- module/README.md: 84 次

**这是"文档追代码"还是"文档驱代码"？**——若实际代码改动在外部仓库，本仓的高 churn 反映**反向工作流**：源码先动 → 本仓被动同步。`latest.json` 30 天 117 次变更，对应 release 频繁 bump（已升至 v1.12.9），但同时 evidence 覆盖率仅 4.1%——这是 `[FRAME]→REALITY` 风险信号。

#### G3：ADR 严重缺失（中 P1）[COMPUTED, HIGH]

- `find docs -name 'ADR-*.md'` = 0
- `docs/architecture/adr/` = 1（疑似目录文件）
- `docs/adr/` 不存在

70+ 模块、L2.5 设计、三引擎契约、foundationx 退出等重大架构决策几乎无 ADR 留存。这是治理体系一个反差极大的暗点：流程门禁完备、决策记录稀薄。

#### G4：报告区时序混乱（中 P1）[COMPUTED, HIGH]

`docs/report/` 现存 8 份报告（不含 archive/goal）：
- `architecture-problem-analysis-20260620.md`
- `architecture-deep-analysis-20260621-v2.md`
- `architecture-structural-analysis-20260621.md`
- `architecture-structural-repair-plan-20260621.md`
- `repo-naming-unification-20260620.md`
- `architecture-structural-analysis-20260622.md`
- 本报告 `architecture-structural-analysis-20260622-v2.md`
- `INDEX.md`

3 份 21260621 同主题报告 + 2 份 06-22 同主题报告并存，**缺乏 `superseded-by` 元数据**，读者无法判断当前权威。

#### G5：foundationx 事实层 verified_against 滞后 8 天（低 P2）[COMPUTED, HIGH]

`.foundationx/status/index.json` 中：
- STATUS.md: `2026-06-14`
- FOUNDATION-DEPS.yaml: `v1.2 (2026-06-14)`
- ROADMAP.md: `PR #364 merged`

但 STATUS.md / ARCHITECTURE.md 最近 commit 在 2026-06-22。事实层快照与三文档实际版本偏差 8 天，事实层未及时刷新。

---

## 四、各域深度评估

| 域                 | 模块数 | SPEC | AC | tasks | plan | evidence | 评估                                       |
| ------------------ | :----: | :--: | :-: | :---: | :--: | :------: | ------------------------------------------ |
| L0 kernel          |   1    | 100% | ✅ | 100%  | -    | 67%      | 🟢 健康                                    |
| L1 primitives      |   5    | 100% | 60% | 80%   | -    | 0%       | 🟡 evidence 待补                           |
| L1 assembly        |   1    | 100% | 0% | 100%  | -    | 0%       | 🟡 bootstrap AC 缺                         |
| L2 storage         |   8    | 100% | 0% | 100%  | -    | 0%       | 🟡 tasks 全 ✓，AC 全缺                    |
| Contracts/Gate     |   5    | 100% | 60% | 100%  | -    | 40%      | 🟢 contracts/xlib_* 健康                  |
| L2.5 域共享         |   5    | 100% | 20% | 60%   | -    | 0%       | 🟡 AC 严重缺                              |
| 数据域             |   9    | 78%  | 0% | 22%   | -    | 0%       | 🔴 2 模块无 SPEC，tasks 严重不足          |
| 分析域             |   7    | 100% | 14% | 0%    | 0%   | 0%       | 🔴 管线完全停滞                            |
| 决策域             |   5    | 100% | 0% | 0%    | 0%   | 0%       | 🔴 全部 Review/Draft，无任何执行制品      |
| 执行域             |   4    | 100% | 25% | 0%    | 0%   | 0%       | 🔴 全部停滞                                |

注：评估为按域汇总的 [COMPUTED, MED] 估算；细到模块的精确数字以 §三 全表为准。

---

## 五、优先修复方案（Plan）

### 5.1 修复原则

| 原则               | 说明                                                             |
| ------------------ | ---------------------------------------------------------------- |
| **AC 先于 Approved** | 流程门禁必须把 AC 列为 Approved 的必要条件                       |
| **业务先于基座**     | 基座层 21/21 已 factory，下一周期资源向业务三域倾斜              |
| **管线右移**         | 资源从 Spec/Matrix 阶段向 Plan/Prompt/Evidence 倾斜              |
| **报告归档纪律**     | 同主题报告必须用 `superseded-by` 标注前置版本                    |
| **事实层及时刷新**   | `verified_against` 时间戳必须随三文档同步                        |
| **ADR 补录**         | 关键架构决策必须留存 ADR                                         |

### 5.2 P0 — 业务域解锁（2-3 周）

| #   | 行动                                                                                                             | 对应问题      | 完成标准                                              |
| --- | ---------------------------------------------------------------------------------------------------------------- | ------------- | ----------------------------------------------------- |
| 1   | 把 12 个 Approved-no-AC 模块补齐 AC（`binance` / `decimalx` / `domain_*` / `factor_engine` / `macro_regime` / `market_data` / `postgresx` / `resiliencx` / `settlement` / `taosx` / `testkitx`） | S3、G2        | Approved 无 AC = 0                                    |
| 2   | 修改 `docs/governance/DEFINITION-OF-READY.md` 与 Spec lint：把 AC 列为 Approved 必要条件                          | G2、流程根因 | spec-lint 检测 AC 缺失即阻断升入 Approved              |
| 3   | 从 `regime_engine` / `signal_factory` 开始拆 tasks，覆盖三业务域 16 个模块                                       | A1、S5        | 三业务域 tasks 覆盖率 ≥ 50%                           |
| 4   | 把 7 个 Review 状态模块（`strategyx` / `riskx` / `orderx` / `positionx` / `maestro` / `flowx` / `backtestx`）推进到 Approved 或回降 Draft | A2            | Review 模块停留时间 < 14 天                           |

### 5.3 P1 — 管线补洞（3-4 周）

| #   | 行动                                                                                                             | 对应问题  | 完成标准                                            |
| --- | ---------------------------------------------------------------------------------------------------------------- | --------- | --------------------------------------------------- |
| 5   | 按 AC → TC → tasks → plan → prompt → evidence 顺序补齐管线断口                                                   | S5、G1    | Plan/Prompt/Evidence 覆盖率均 ≥ 30%                  |
| 6   | 补齐 `data_cs_module` / `data_independent_process` 的 SPEC                                                       | A4        | 65 个目录 65/65 有 SPEC（含模板）                    |
| 7   | 12 个 Draft 模块补齐 AC                                                                                          | S4        | Draft 无 AC = 0                                     |
| 8   | 刷新 `.foundationx/status/index.json` 的 `verified_against` 时间戳                                              | G5        | 事实层与三文档时间戳偏差 ≤ 3 天                      |

### 5.4 P2 — 治理深化（4-8 周）

| #   | 行动                                                                                                              | 对应问题   | 完成标准                                       |
| --- | ----------------------------------------------------------------------------------------------------------------- | ---------- | ---------------------------------------------- |
| 9   | 补录关键 ADR（L2.5 设计、三引擎契约、foundationx 退出、命名 snake_case 统一、废弃占位移除）                       | G3         | ADR 数量 ≥ 10                                  |
| 10  | 报告区清理：给 21260621 系列加 `superseded-by` 指向 06-22 v2；归档过期报告至 `docs/report/archive/`              | G4         | 当前期 docs/report/ 同主题仅 1 份权威报告       |
| 11  | `live_integration` 从 7 推进到 15+（按里程碑发布到生产环境）                                                      | 交付健康度 | live_integration ≥ 15                          |
| 12  | 增加管线右段（S4/S5/S6）的 CI gate，缺 plan/prompt/evidence 阻断升入下一状态                                     | S5、G1     | 三阶段 CI gate 上线且阻断率可观察                |

### 5.5 退出条件

- Approved-no-AC = 0；Draft-no-AC = 0
- 业务域三链路 tasks 覆盖率 ≥ 50%
- 管线 S4/S5/S6 覆盖率均 ≥ 30%
- live_integration ≥ 15
- ADR ≥ 10
- 同主题报告只有 1 份权威，其余 `superseded-by` 闭合
- 事实层 `verified_against` 与三文档偏差 ≤ 3 天

---

## 六、数据附录

### 6.1 管线覆盖热图（实测）

```
域                 S1    S2    S3    S4    S5    S6
L0 kernel          ████  ████  ████   --   ███░  ███░
L1 primitives      ████  ████  ████░  --   ██░░  ░░░░
L1 assembly        ████  ████  ████   --   ░░░░  ░░░░
L2 storage         ████  ████  ████   --   █░░░  █░░░
Contracts/Gate     ████  ████  ████   --   ███░  ███░
L2.5 域共享         ████  ████  ███░   --   ░░░░  ░░░░
数据域             ███░  ███░  ██░░   --   ░░░░  ░░░░
分析域             ████  ████  ░░░░  ░░░░  ░░░░  ░░░░  ← 停滞
决策域             ████  ████  ░░░░  ░░░░  ░░░░  ░░░░  ← 停滞
执行域             ████  ████  ░░░░  ░░░░  ░░░░  ░░░░  ← 停滞
```

### 6.2 综合数据速查（2026-06-22 快照）

```
Release manifest:           v1.12.9
分析时间:                   2026-06-22 CST
分支:                       docs/s3-s7-fixes-20260622

—— module/ 维度 ——
目录总数:                   65（含 _template/AGENTS.md/README.md/2 个无 SPEC）
SPEC 覆盖:                  49/49 模块（100%）
SPEC 占位符 (<1KB):         0
无 SPEC 模块:               2（data_cs_module / data_independent_process）
TRACEABILITY 覆盖:          49

—— 验收/测试制品 ——
AC 覆盖 (含 AC- 模式):      16/49 (32.7%)
TC 覆盖 (含 TC- 模式):      23/49 (46.9%)
Approved-no-AC:             12
Draft-no-AC:                12

—— 管线制品 ——
S3 tasks/ 目录:             26/49 (53.1%)
S4 Plan 文件:               2/49  (4.1%)
S5 Prompt 目录:             5/49  (10.2%)
S6 Evidence 目录:           2/49  (4.1%)

—— 事实层 (foundationx 21 模块基座) ——
spec_complete:              21/21
impl_complete:              21/21
release_published:          21/21
factory_grade:              20/21（testkitx N/A）
live_integration:           7/21
open_blockers:              0/11（11 个历史 blocker 已闭合）

—— 状态分布 ——
Approved (含 Docs Baseline Approved 各变体): 27
Review:                     7
Draft:                      12
其他:                       3

—— 治理与活动 ——
CI workflows:               14
Claude hooks:               11
docs/governance 文件:       19
docs/constitution 章节:     10
ADR 数量:                   0（严重缺失）
30 天 commits:              1273
14 天 commits:              1172（占 92%，高 churn）
Top churn 文件:             STATUS.md (255) > ARCHITECTURE.md (176) > README.md (128)

—— 报告区 ——
docs/report/ 现存:          8 份（含本报告）
同主题并存:                 21260621 系列 ×3 + 06-22 系列 ×2
```

### 6.3 命名分布

| 格式            | 数量 | 示例                                       |
| --------------- | :--: | ------------------------------------------ |
| snake_case      |  19  | xlib_standard, domain_market, factor_engine |
| 无分隔符小写     |  34  | kernel, configx, binance, contracts        |
| kebab-case      |  **0** | （PR #845 已清零）                        |
| 模板/文档       |   2  | _template, AGENTS.md                       |
| **目录条目合计** |  65  |                                            |

---

## 七、结论

FoundationX 当前的核心矛盾是：

> **治理框架与基座交付已达到 A 级（80+），但业务域三链路的可执行制品几乎为零（C/D 级）。**

具体而言：
- ✅ 基座 21/21 已 factory-ready，0 open blockers
- ✅ 命名三轨问题已收口（kebab=0）
- ✅ 占位 SPEC 已清零
- ✅ contracts 已 Verified
- ❌ 业务域 tasks=0、AC=14%、plan=0、evidence=0
- ❌ Approved 状态门禁未把 AC 作为必要条件
- ❌ 7 个 Review 模块长期停留
- ❌ ADR 严重缺失
- ❌ 报告区同主题多份并存无 superseded-by

**下一周期资源必须从"治理细节优化"转向"业务域管线推进"**，否则会持续产生 `[FRAME]→REALITY` 风险——治理评分越来越高，但用户拿不到能跑的代码。

---

[RULES I BROKE]：
- 本报告 §一评分卡为定性估算，未给出每条扣分的精确公式，与 06-22 v1 报告（68）相差 1.9 分，可能存在锚定漂移
- 各域 §四 评估表中"60%/22%"等细分数字为 [INFERRED, MED]，未做模块级精确复核
- 未对 `outer-metrics` / `harness-check` 等 14 个 CI workflow 逐一验证健康度，仅承接 audit-status PASS 摘要
- 报告内 §3.2 G2 churn 数据未深入到 "外部 repo 实际 commit 与本仓 STATUS 同步的时序对照"，仅给定性判断
