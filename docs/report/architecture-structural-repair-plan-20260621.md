# FoundationX 架构结构性修复方案（2026-06-21）

> 适用范围：`docs/report/architecture-structural-analysis-20260621.md` 中标记为“当前未完成”的 7 项收口动作。
> 定位：唯一执行版修复计划；分析报告保留结构性诊断与摘要，本文件承载执行顺序、产出、依赖和退出条件。
> 原则：契约先行、AC 先于任务、占位符先实化、命名先定基准、投影分层、入口单一。
> 说明：`domain_market` / `domain_macro` / `domain_exchange` 的目标命名口径已统一为 `snake_case`；当前本地路径投影仍可能保留历史目录名（如 `module/portfolio-engine`），仅允许出现在迁移表和同步说明中，正文规范名统一使用 `snake_case`。

---

## 1. 目标与边界

- 目标：把分析报告里的 7 项残余动作拆成可执行、可验收、可同步的文档修复与规格修复计划。
- 边界：本轮只做文档、规格、追踪关系、同步说明与门禁口径收口，不直接改业务代码。
- 成功标准：每一项都能落到明确产物、依赖和退出条件，且后续文档只引用本计划，不再重复展开完整执行树。

---

## 2. 当前基线

### 2.1 已完成并冻结

- `#4`：L2.5 目录命名基准已固定为 `snake_case`，历史 kebab 仅保留在迁移表与对照清单。
- `#7`：`x.go` / `composer` 入口说明已统一，治理 CLI 与运行时组合根分工已收口。
- `#8`：L2.5 遗留 kebab 引用已清理，对齐同步文档已回写。
- `#3`：5 个占位符 SPEC 已全部实化并冻结，作为后续 tasks 拆分的稳定输入。
- `contracts` 的兼容投影别名已补齐，为 `#1` 的 Approved 收口提供引用基础。
- `#2`：8 个 Approved 模块的 AC 已回写并冻结，不再作为当前待办。

### 2.2 剩余 7 项总览

| 编号 | 优先级 | 当前问题 | 主要依赖 | 退出条件 |
| --- | --- | --- | --- | --- |
| `#1` | P0 | `contracts` 仍未 Approved，跨域 AC / TC 未闭合 | contracts 现有 DTO / event / port 结构 | `contracts = Approved`，并形成冻结版边界清单 |
| `#5` | P1 | 分析域 / 决策域 / 执行域任务树未拆出 | `#1`-`#3` 的稳定输入 | 三个业务域均出现可执行 tasks |
| `#6` | P1 | AC → TC → tasks 串联未形成闭环 | `#1`、`#5` | 不再出现“有任务无验收” |
| `#9` | P2 | 数据域 tasks 不足，标准化入口未完全落地 | `module/data-cs-module/*` | 数据域不再停留在低覆盖状态 |
| `#10` | P2 | prompt / evidence 覆盖不足 | `#5`、`#9` | S5 / S6 覆盖持续提升 |
| `#11` | P2 | 关键 ADR 数量偏少 | 现有治理与边界材料 | 关键决策可追溯 |
| `#12` | P2 | `live_integration` 仍需扩展 | 发布 / 集成清单 | `live_integration` 进入 15+ 目标段 |

### 2.3 现状快照

| 维度 | 当前状态 | 说明 |
| --- | --- | --- |
| `contracts` | 未 Approved | 仍处在可用但未冻结的门禁前状态 |
| Approved 但无 AC | 0 个 | 历史快照曾为 8 个；对应模块 AC 已回写到各自 `SPEC.md` / `TRACEABILITY.md` |
| 完整 Spec 基线 | 5 个 | `module/settlement/SPEC.md`、`module/portfolio-engine/SPEC.md`、`module/risk-engine/SPEC.md`、`module/order-engine/SPEC.md`、`module/macro_regime/SPEC.md` 已全部实化并冻结 |
| 分析 / 决策 / 执行域 tasks | 0 或接近 0 | 任务树尚未形成可执行闭环 |
| 数据域任务 | 不足 | 需要通过 `module/data-cs-module/README.md`、`SPEC-TEMPLATE.md`、`UPGRADE-ROADMAP.md` 统一入口推进 |
| prompt / evidence | 覆盖偏弱 | S5 / S6 尚未形成稳定执行面 |
| ADR | 偏少 | 需要补录关键边界与决策 |
| `live_integration` | 仍在扩展 | 需按里程碑从 7 提升到 15+ |

### 2.4 数据域标准化入口

- `module/data-cs-module/README.md`
- `module/data-cs-module/SPEC-TEMPLATE.md`
- `module/data-cs-module/UPGRADE-ROADMAP.md`

---

## 3. 修复顺序

1. 先完成 `#1`，把 `contracts` 冻结到 Approved，并补齐跨域 AC / TC。
2. 然后推进 `#5` 与 `#6`，把分析域 / 决策域 / 执行域任务树拆出来并串成闭环。
3. 最后推进 `#9`、`#10`、`#11`、`#12`，把数据域、治理文档和集成面补齐。

说明：
- `#3` 已完成并冻结，不再作为本轮待办。
- `#5` 与 `#6` 不能倒序；先有任务树，再谈串联闭环。
- `#10`、`#11` 可与 `#9` 并行准备，但不应在 P0 未完成时反向固化范围。

---

## 4. P0 修复方案

### 4.1 `#1` - `contracts` Approved + 跨域 AC / TC

**目标**
- 把 `contracts` 推进到 Approved。
- 冻结跨域事件、端口、DTO 的可引用口径。
- 将跨域 AC / TC 一次性补齐到可复用状态。

**产出**
- 冻结版 `contracts` 边界清单。
- 跨域 AC / TC 对照表。
- 下游引用约束说明。

**完成标准**
- `contracts = Approved`。
- 下游只保留单一契约口径，不再依赖未冻结的投影。
- `contracts` 相关跨域规则可直接被后续任务引用。

### 4.2 `#2` - 8 个 Approved 模块补 AC（已完成并冻结）

**状态**
- 已完成并冻结，8 个 Approved 模块的 AC 已回写，不再作为当前待办。

**目标**
- 为当前已经 Approved 但缺少 AC 的模块补齐验收标准。

**模块范围**
- `binance`
- `decimalx`
- `domain_exchange`
- `domain_market`
- `postgresx`
- `resiliencx`
- `taosx`
- `testkitx`

**产出**
- 每个模块对应的 AC 补丁。
- AC 与现有 FR / TC / task 的映射表。

**完成标准**
- Approved 无 AC = 0。
- 后续模块不得再以“先 Approved，后补 AC”的顺序进入门禁。

### 4.3 `#3` - 5 个占位符 SPEC 实化（已完成）

**状态**
- 已完成并冻结，不再作为待办。

**目标**
- 将 5 个占位符 SPEC 扩充为可拆任务的完整规格。

**模块范围**
- `settlement` (`module/settlement/SPEC.md`)
- `portfolio_engine` (`module/portfolio-engine/SPEC.md`)
- `risk_engine` (`module/risk-engine/SPEC.md`)
- `order_engine` (`module/order-engine/SPEC.md`)
- `macro_regime` (`module/macro_regime/SPEC.md`)

说明：
- `portfolio-engine` / `risk-engine` / `order-engine` 是当前本地路径投影，不是独立的命名体系。
- 正文与同步矩阵中只使用规范名 `portfolio_engine` / `risk_engine` / `order_engine`。

**产出**
- 完整 SPEC 正文。
- FR / AC / TC 初始链条。
- 可拆 task 的边界清单。

**完成标准**
- 占位符 SPEC = 0。
- 每个 SPEC 至少能独立驱动任务拆分。

---

## 5. P1 修复方案

### 5.1 `#5` - 从核心链路拆分 tasks

**目标**
- 从 `regime_engine`、`signal_factory` 等核心链路开始拆分分析域 / 决策域 / 执行域 tasks。

**产出**
- 21 个核心模块的任务树。
- 模块级 task 拆分依据。
- 域间依赖顺序说明。

**完成标准**
- 三个业务域都出现明确的可执行 tasks。
- task 不再停留在“概念清单”层。

### 5.2 `#6` - AC → TC → tasks 串联闭环

**目标**
- 按 AC → TC → tasks 的顺序补齐测试与执行制品。

**产出**
- AC / TC / task 串联关系表。
- 任务生成顺序说明。
- 反向校验规则。

**完成标准**
- 不再出现“有任务无验收”。
- 任一 task 都能追溯到 AC 与 TC。

---

## 6. P2 修复方案

### 6.1 `#9` - 数据域 tasks 与标准化入口

**目标**
- 补全数据域 tasks，并按 `module/data-cs-module` 标准入口推进 `market_data` / `macro_data` 的 C/S Module 落地。

**产出**
- 数据域任务树。
- 标准化入口引用规则。
- `market_data` / `macro_data` 的阶段性落地路径。

**完成标准**
- 数据域不再停留在低覆盖状态。
- 新增数据域模块优先走统一入口，不再各自写一套模板。

### 6.2 `#10` - prompt / evidence

**目标**
- 从 Foundation 层和 Approved 业务模块开始补 prompt / evidence。

**产出**
- S5 / S6 运行制品。
- 证据收集与回填规则。

**完成标准**
- Prompt / Evidence 覆盖率不再长期停留在个位数。

### 6.3 `#11` - 关键 ADR

**目标**
- 补录关键 ADR，覆盖 L2.5、三引擎契约、业务域边界等决策。

**产出**
- ADR 队列。
- 决策可追溯索引。

**完成标准**
- 关键决策可直接从 ADR 追到背景与约束。

### 6.4 `#12` - `live_integration` 扩展

**目标**
- 按里程碑把 `live_integration` 从当前水平推进到 15+。

**产出**
- 集成清单。
- 分阶段验证记录。

**完成标准**
- `live_integration` 进入更高覆盖段，且不破坏现有发布级联。

---

## 7. 文档同步矩阵

| 文件 | 需要对齐的内容 |
| --- | --- |
| `docs/report/architecture-structural-analysis-20260621.md` | 保留结构性诊断与摘要，完整执行计划改引用本文件 |
| `STATUS.md` | 阻塞项与下一步行动改为指向本文件 |
| `docs/report/repo-naming-unification-20260620.md` | 只保留命名同步结果与历史投影边界，不再承载完整修复计划 |
| `module/data-cs-module/README.md` | 作为数据域标准化入口，被 `#9` 直接引用 |
| `module/data-cs-module/SPEC-TEMPLATE.md` | 数据域 SPEC 模板入口，服务 `#9` |
| `module/data-cs-module/UPGRADE-ROADMAP.md` | 数据域升级路线，服务 `#9` |
| `docs/architecture/adr/README.md` | ADR 入口索引，服务 `#11` |

---

## 8. 退出条件

1. `contracts` 已 Approved，且下游不再依赖未冻结口径。
2. Approved 无 AC = 0。
3. 5 个占位符 SPEC 已全部实化并冻结（占位符 SPEC = 0）。
4. 分析域、决策域、执行域均形成可执行 tasks。
5. 数据域补齐 tasks，并通过 `module/data-cs-module` 统一入口持续对齐新建模块。
6. `L2.5` 目标命名基准已统一为 `snake_case`，历史路径投影只保留在同步文档和迁移表。
7. `x.go` / `composer` 的入口分工持续保持一致。
8. S5 / S6 覆盖不再长期停留在个位数。
9. 关键 ADR 已补录，`live_integration` 继续按里程碑推进到 15+。
10. 相关同步文档全部指向本文件，不再各自维护一份“完整计划”。

---

## 9. 本文件对应的剩余动作

- `#1` `contracts` Approved + 跨域 AC / TC
- `#2` 8 个 Approved 模块补 AC（已完成并冻结）
- `#5` 核心链路 tasks 拆分
- `#6` AC → TC → tasks 闭环
- `#9` 数据域 tasks 与标准化入口
- `#10` prompt / evidence
- `#11` 关键 ADR
- `#12` `live_integration` 扩展
