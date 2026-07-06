# 📊 项目状态监控

> FoundationX 量化交易基础设施的实时健康度与风险追踪
>
> 数据来源：各 GitHub 仓库实际状态，定期更新
>
> 最后更新：2026-07-06（binance v0.13.0 数据完整性修复 ✅）
>
> 同步基线：`module/` 为模块规格库 SSOT，`docs/governance/` 为 Spec 治理 SSOT，`docs/goal/` 为 Goal 规则 SSOT，`specs/` 已移除。
> 机器事实源：`.foundationx/status/index.json` — 由 `xlibgate fleet-status` 生成，供 CI 和自动投影消费。多维成熟度以该文件为准，本文手工块为投影。
>
> **模块计数口径说明**（2026-07-03 S4 修复）：本文涉及多种计数口径，各处已标注来源：
> - **口径-DEPS20**：FOUNDATION-DEPS.yaml modules 段定义的 20 个基座模块（不含 L2.5），用于 CI 和依赖矩阵治理
> - **口径-STATUS21**：.foundationx/status/index.json 覆盖的 21 个模块（20 基座 + domainx L2.5 锚点），用于成熟度追踪
> - **口径-REG59**：registry.yaml 全域注册模块 59 个（含 4 archived），用于模块身份管理
> - **口径-REG55**：registry.yaml 全域活跃模块 55 个（不含 archived），用于活跃模块统计
> - **口径-FULL73**：全域活跃组件 73 个（含业务域模块，扣除 4 archived），用于域统计汇总

---

## 组件状态总览

> ⚠️ **存根化迁移**（2026-07-03 P1.1）：组件明细表已迁移至机器事实源。
> 详细模块状态（版本、release、CI、factory、blocker）请直接读取：
> - **机器事实源**：[`.foundationx/status/index.json`](./.foundationx/status/index.json) — 由 `xlibgate fleet-status` 生成
> - **Blocker 状态**：[`.foundationx/blockers.json`](./.foundationx/blockers.json)
> - **模块注册表**：[`module/registry.yaml`](./module/registry.yaml)
>
> 下方保留汇总摘要和域级分析。汇总表和明细表可用 `scripts/generate-status-projection.py` 从 JSON 自动生成。

<!-- BEGIN AUTO-PROJECTION: python3 scripts/generate-status-projection.py --summary -->

### 汇总（from .foundationx/status/index.json）

| 指标 | 值 | 口径 |
|------|-----|------|
| 总模块数 | 21 | 口径-STATUS21 |
| Spec 完成 | 21/21 | 口径-STATUS21 |
| 实现完成 | 21/21 | 口径-STATUS21 |
| Release 已发布 | 21/21 | 口径-STATUS21 |
| 真实集成 (Live) | 7 | 口径-STATUS21 |
| Factory Grade | 20/21 | 口径-STATUS21（testkitx 不适用） |
| Open Blockers | 0 | .foundationx/blockers.json |

<!-- END AUTO-PROJECTION -->

> ✅ [口径-STATUS21] 21/21 已发布 GitHub Release。factory 投影必须读取 release/live/blocker 证据，不能由 tag 自动推出。

<!-- 模块明细表: python3 scripts/generate-status-projection.py --detail -->
<!-- 已迁移至机器事实源 .foundationx/status/index.json，不再手工维护 -->

### 按域统计

| 域 | 总数 | 已有 | 已创建 | 平均进度 | 说明 |
| --- | --- | --- | --- | --- | --- |
| 基座 | 21 | 21 | 0 | Spec→Code 投影完成 | [口径-STATUS21] 21 独立 module |
| L2.5 领域共享层 | 5 | 5 | 0 | 100% | 5 纯值对象库 (factory grade；live/soak N/A) |
| 数据域 · market_data | 14 | 13 | 1 | 85% | binance 生产就绪 ✅；12 C/S Module 待升级 + 1 独立进程 |
| 数据域 · macro_data | 11 | 11 | 0 | 80% | 10 C/S Module + 1 独立进程 |
| 数据域 · 另类 | 1 | 0 | 1 | 5% | 1 (v0.1.0) |
| 分析域 | 8 | 3 | 5 | 40% | 8 独立进程 |
| 决策域 | 5 | 1 | 4 | 10% | 5 (signal_factory v0.1.0 ✅) |
| 执行域 | 4 | 1 | 3 | 10% | 4 (riskx v0.1.0 ✅) |
| 入口 | 2 | 2 | 0 | 85% | 2 (x.go v0.0.1；composer v0.2.0 ✅) |
| 横切 | 2 | 2 | 0 | 100% | 2 (observex, alertx) |
| 独立 | 1 | 1 | 0 | - | 0 |
| **合计** | **74** | **60** | **14** | **81%** | **74** |

> ⚠️ **历史占位移除说明**（2026-06-22）：4 个历史占位模块已物理移除。当前活跃组件 [口径-FULL73] 73 个。

> 📋 **域级组件明细**（L2.5 / 数据域 / 分析域 / 决策域 / 执行域 / 入口 / 横切）已迁移至机器事实源。
> 详细模块状态请读取 [`.foundationx/status/index.json`](./.foundationx/status/index.json) 和 [`module/registry.yaml`](./module/registry.yaml)。
> 域级架构组成参见 [docs/architecture/02-domain-layers.md](./docs/architecture/02-domain-layers.md)。

---

## 域健康度

### 🟢 基座（健康）

- 组件：19 个 [口径-DEPS20 减 testkitx(test-only)]；机器事实层 [口径-STATUS21] 另将 `domainx` 作为 L2.5 模块计入 21-module projection；
  Spec→Code 管线投影已闭合，但不等于 Foundation 整体 factory grade。
 - 核心模块 release/tag 投影仍需逐项读取 GitHub Release 与 blocker 证据；natsx 已确认 GitHub Release v1.0.2，v1.0.3 仅作为 tag-only 事实保留。
 - 存储层 GitHub Release 与 blocker 投影已按当前 fact-layer 对齐。
 - **阻塞项**：当前 .foundationx/blockers.json open_blockers=0；natsx BLK-001/BLK-002 为 resolved 历史项。

### 🟢 L2.5 领域共享层（健康）

- 组件：5 个，进度 80%
- Phase 0 已完成，当前已建模的上层模块已依赖此层

### 🟢 数据域 · market_data（健康 — binance 生产就绪 ✅）

- market_data 域：14 组件（13 C/S Module + 1 独立进程 dispatch）
- dispatch（market_data）：独立进程，v1.0.0，Receiver + DualWriteSink，进度 30%
- C/S Module（13）：binance 为规格参考实现（spec v3.14.0 ✅；v0.13.0 released；55/55 Done (100%)；release_closeable=YES 🎉；47/47 tasks Done；P0×6 阻断闭环 + P1×6 CI gate 落地 + 数据完整性修复 R1-R5）；其余 12 个 v0.1.1，待升级
- **factory 升级路径**：binance 已达 factory-ready ✅（v0.13.0 released、55/55 Done、release_closeable=YES、深度分析 37/37 fixed；测试分层/canary drill/depth 覆盖/版本一致性 gate 就绪；数据完整性修复 R1-R5 落地）；其余 12 C/S Module 待 client/server 拆分 + bootstrap 接入 + dispatch 集成验证

### 🟡 数据域 · macro_data（注意）

- macro_data 域：11 组件（10 C/S Module + 1 独立进程 dispatch）
- dispatch（macro_data）：独立进程，v1.0.0，Receiver + DualWriteSink
- C/S Module（10）：全部 v0.1.1 tagged release，待升级 bootstrap + client/server 拆分
- 6 个央行数据源结构高度相似（fred / treasury / bea / ecb / uk_cb / japan_cb）
- **评估结论（2026-06-16）**：各模块保持独立架构，不合并；建议在 contracts 中提取共享 DataSource 接口统一契约

### 🔴 数据域 · 另类（阻塞）

- 组件：1 个，仅创建（5%）
- **阻塞项**：链上数据、社交情绪、新闻 NLP 尚未开始实现

### 🔴 分析域（阻塞）

- 组件：8 个，**全部为独立进程（非 C/S）**，bootstrap 接入，无 client/server 拆分
- 三引擎（market_regime/macro_regime v0.2.0，regime_engine v1.0.0）已完成 P0 桥接；dispatch→regime SinkPort 适配器 ✅（composer v0.1.0，MarketRegimeSink/MacroRegimeSink，14 tests PASS），5 个处于早期（5%）
- **阻塞项**：factor_engine / feature_store / factor_eval / ms_brain 均未实现到可用闭环；flowx SPEC 已创建（v0.1.0-draft）
- **里程碑**：分析域三引擎 contracts v1.4.0 P0 DTO 接入完成，M×S→DecisionCard 链路打通

### 🔴 决策域（阻塞）

- signal_factory v0.1.0 骨架完成（40%）：DecisionCard→SignalIntent 链路打通；optimizer 仅创建（5%）
- backtestx / strategyx / maestro 已推进至 Spec Approved / Tasks Pending（v0.1.0）
- **阻塞项**：依赖分析域产出因子；signal_factory 待接入真实因子信号

### 🔴 执行域（阻塞）

- 组件：7 个，全部仅创建（5%）
- riskx / orderx / positionx SPEC 已创建（v0.1.0-draft）
- **阻塞项**：依赖决策域产出信号

### 🟡 入口（注意）

- x.go 已有（80%，v0.0.1）；2.8MB 体量已核实为治理/工具 CLI（goalcli+templatex），非 Composition Root
- **composer v0.1.0** ✅（75%）：数据域组合根，25 进程（23 adapter + market_data + macro_data）+ HTTP health + Docker Compose；dispatch→regime SinkPort 适配器已完成（MarketRegimeSink/MacroRegimeSink）
- **已闭环**：核心链路收口（`regime_engine` → `signal_factory` → `riskx`）已按 `report/architecture-structural-repair-plan-20260621.md` 的 `#5`-`#6` 完成；本文件仅保留历史摘要，不再展开执行树

### 🟡 横切（注意）

- alertx v1.0.0 已完成（100%，spec→code 全链 pass，AT-007 横切贯穿，✅ GitHub Release v1.0.0 已发布）；observex 已完成（100%，v0.3.4，✅ GitHub Release 已发布）
- observex 同属基座和横切，职责边界通过 ADR 明确（见 `module/observex/ADR-dual-attribution.md`，R7 已闭环）

---

## 风险清单

### 🔴 高风险

| #   | 风险                                            | 影响             | 建议                         |
| --- | ----------------------------------------------- | ---------------- | ---------------------------- |
| R1  | 分析域/决策域/执行域核心链路低完成度（多数 5%） | 核心业务链路断裂 | 已闭环，保留为历史风险回看 |
| R2  | alternative_data 仅创建（5%）                   | 另类数据能力缺失 | 可延后，不影响核心链路       |

### 🟡 中风险

| #   | 风险                                    | 影响                              | 建议                                                                   |
| --- | --------------------------------------- | --------------------------------- | ---------------------------------------------------------------------- |
| ~~R3~~  | ~~x.go 2.8MB 体量异常~~                 | ~~可能违反组合根边界~~            | ✅ **已核实**：x.go = 治理/工具 CLI（goalcli+templatex），非 Composition Root；composer 独立仓库承担数据域组合根 |
| R4  | ~~13 个交易所 SDK 全部无版本号~~        | ~~无法追踪 API 兼容性~~           | ✅ 已版本化：18 仓库 v0.1.1 tagged release（2026-06-16）               |
| R5  | ~~宏观数据源 6 个央行适配器同质化~~     | ~~维护成本高~~                    | ✅ 已评估 — 各模块保持独立，已统一打 v0.1.1（2026-06-16）              |
| R7  | observex 双重归属（基座+横切）          | 职责边界模糊                      | ✅ 已记录 ADR：`module/observex/ADR-dual-attribution.md`（2026-06-12） |
| R10 | ~~`.omc/state/sessions` 已入库~~        | ~~可能泄露 prompt/会话/环境信息~~ | ✅ 已修复：`git rm -r --cached .omc`（2026-06-07）                     |
| R11 | ~~公开 README 含 `127.0.0.1` 本地链接~~ | ~~外部无法访问，降低专业度~~      | ✅ 已修复：批量移除所有本地链接（2026-06-07）                          |
| ~~R12~~ | ~~71 个仓库无统一命名前缀~~                 | ~~分类困难，增加维护成本~~            | ✅ 已收口：L2.5 目录命名统一完成；当前仅保留为历史评估项，未来若发生大规模目录重构再单独评估 |

### 🟢 低风险

| #   | 风险                                                                                                                                                                                                   | 影响                                                              | 建议                                                     |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------- | -------------------------------------------------------- |
| R8  | postgresx 单元测试覆盖率 52.4% 且 Docker 集成测试 skip；taosx SPEC ~88 (全部闭合)；ossx API 文档 / integration evidence / quickstart / release manifest 未归档 | 已闭合为历史风险，不阻塞当前 factory 投影；后续仅在对应模块证据回退时重开 | 保持 BLK-006/007/008 resolved 证据链与模块 release 事实同步 |
| R9  | 分析域↔决策域若用实现包互调                                                                                                                                                                            | Go 循环导入和边界泄漏                                             | 只允许通过 contracts 事件/DTO 与 L2.5 模型连接           |

---

## 闭环与同步

### 当前状态

- [x] Phase 1（分析域）已按 `report/architecture-structural-repair-plan-20260621.md` 闭环；7 项收口动作已全部回写，本文件仅保留历史同步摘要。
- [x] `x.go` 体量核实完成：`x.go` = 治理 CLI，非组合根；`composer` v0.1.0 承担数据域组合根

### 已完成事项

1. **Phase 1 已闭环**：`report/architecture-structural-repair-plan-20260621.md` 现作为闭环记录，`#1`、`#5`-`#6`、`#9`-`#12` 的执行口径已全部收束；本文件不再展开 `MarketDataProvider` / `FactorInput` / `FactorOutput` 的执行细节。
2. **contracts 契约口径已同步**：`SignalIntent` 已升入 contracts；P1 / P2 兼容投影别名（`RegimeSnapshotEvent` / `RegimeCardEvent` / `DecisionCardEvent` / `MarketRegimePort` / `MacroRegimePort` / `RegimeEnginePort`）已在 contracts 补齐；`contracts` Approved 与跨域 AC / TC 已在闭环记录中固定。
3. ~~**版本化 SDK**~~：✅ 已完成 — 18 仓库 v0.1.1 tagged release（2026-06-16）
4. ~~**统一宏观适配器**~~：✅ 已评估 — 保持独立模块架构，11 仓库全部 v0.1.1 tagged release（2026-06-16）
5. ~~**清理仓库卫生**（R10）~~：✅ 已完成（2026-06-07）
6. ~~**移除本地链接**（R11）~~：✅ 已完成（2026-06-07）
7. **保留 R12 作为历史评估项**：已从执行任务转为历史记录；仅在未来大规模目录重构时再评估按 `foundation-*`/`adapter-*`/`engine-*`/`lab-*` 前缀重命名的可行性

---

## 文档同步检查

| 检查项           | README | ARCHITECTURE | STATUS    | 一致性 |
| ---------------- | ------ | ------------ | --------- | ------ |
| 组件总数         | 71     | 69           | 71        | ✅（2026-06-22 PR #845 命名 snake_case 化后；README/STATUS=71 [口径-FULL73 减 2 非模块目录]，ARCH=69 是 ARCHITECTURE.md 不重复列出 2 个仓库的合法差异） |
| market_data 数量 | 14     | 14          | 14        | ✅     |
| macro_data 数量  | 11     | 11           | 11        | ✅            |
| L2.5 组件        | 5      | 5            | 5         | ✅ 已验证 |
| 分析域组件       | 8      | 8            | 8         | ✅ 已验证 |
| 决策域组件       | 5      | 5            | 5         | ✅ 已验证（2026-06-22 移除 backtest_engine 占位后） |
| 横切组件         | 2      | 2            | 2         | ✅ 已验证 |

注：macro_data 域从 10 增至 11（新增 dispatch 独立进程），ARCHITECTURE.md、README.md 与 STATUS.md 已同步新增 macro_data 行并统一为 11；本次复核后，L2.5、分析域、决策域与横切四项计数也已与 README.md / ARCHITECTURE.md 对齐确认。2026-06-22 移除 4 个废弃占位（risk_engine/order_engine/portfolio_engine/backtest_engine），决策域 6→5，执行域 7→4，总计 77→73。STATUS 域统计 domain-sum 口径（73）与 unique-link 口径不完全等同（observex 计入基座+横切 2 域）。

### 迁移与门禁基线

| 项目          | 当前状态                                                                                                | 验证方式                                         |
| ------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| 规格库入口    | `module/` 承载 24 份模块与组合根规格；`docs/governance/` 承载治理模板、生命周期、追溯与评分规则         | 旧路径扫描、`spec-lint.sh`、治理路径扫描         |
| Goal 规则入口 | `docs/goal/` 定义交付规则；`.config/goal/` 承载运行状态                                                 | `traceability-check.sh`、`task-spec-validate.sh` |
| 公开索引      | `README.md`、`ARCHITECTURE.md`、`STATUS.md` 区分 `module/` 与 `docs/governance/` 入口                   | `status-consistency-check.sh`、治理路径扫描      |
| 漂移防护      | 不恢复旧 `specs/` 与 `module/governance` 路径，agent 与 CI 引用保持 `module/` + `docs/governance/` 口径 | 旧路径扫描、`spec-drift-guard.sh`                |

---

## 管线状态总览

[口径-DEPS20] 20/20 模块全部阶段 ≥67（rule-scorer 真实评分），其中 13/20 全线 ≥98。该表是 Spec→Code 管线分项评分，不代表 release/factory；release/factory 投影以 `.foundationx/status/index.json` + `.foundationx/blockers.json` 为准。

| 模块          | spec | matrix | tasks | plan | prompt | code |
| ------------- | :--: | :----: | :---: | :--: | :----: | :--: |
| clickhousex   | 100  |  100   |  100  | 100  |  100   | 100  |
| configx       | 100  |  100   |  96   | 100  |  100   | 100  |
| contracts     | 100  |  100   |  100  | 100  |  100   | 100  | ✅ P0 DTO 2026-06-20 |
| domainx       | 100  |  100   |  100  | 100  |  100   | 100  |
| kafkax        | 100  |  100   |  100  | 100  |  100   | 100  |
| kernel        | 100  |  100   |  100  | 100  |  100   | 100  |
| natsx         | 100  |  100   |  92   | 100  |  100   | 100  |
| observex      | 100  |  100   |  100  | 100  |  100   | 100  |
| ossx          | 100  |  100   |  100  | 100  |  100   | 100  |
| postgresx     | 100  |  100   |  100  | 100  |  100   | 100  |
| redisx        |  98  |  100   |  100  | 100  |  100   | 100  |
| resiliencx    | 100  |  100   |  100  | 100  |  100   | 100  |
| schedulex     |  98  |  100   |  100  | 100  |  100   | 100  |
| bootstrap     | ~90  |  N/A   |  N/A  | N/A  |  N/A   | N/A  |
| taosx         | ~88  |  100   | ~88   | 100  |  100   | 100  |
| testkitx      | 100  |  100   |  100  | 100  |  100   | 100  |
| transportx    |  84  |  100   |  100  | 100  |  100   | 100  |
| xlib_evidence |  83  |  100   |  100  | 100  |  100   | 100  |
| xlib_harness  |  83  |  100   |  97   | 100  |  100   | 100  |
| xlib_standard | 100  |   80   |  98   | 100  |  100   | 100  |
| xlibgate      | 100  |  100   |  100  | 100  |  100   | 100  |

> 剩余 7 模块需 SPEC 级内容修复（spec 缺 WHEN/THEN、章节等）。prompt/code 外仓模块为 pass-through。xlib_standard 为快照格式除外。
