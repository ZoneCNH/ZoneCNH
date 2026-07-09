# FRED 模块深度迭代复评报告

**分析日期**：2026-07-08
**复评基线**：`docs/report/fred/01~05`（2026-07-08 首轮）+ `module/fred` 当前制品（v1.1.0 / Implemented）
**方法**：4 路并行 Agent 团队（spec/goal/design · matrix/tasks/prompt · rules/standards · registry/CI/evidence/gate），结果交叉汇总
**结论先行**：

1. **是否还需补充/优化/迭代？—— 是。** 首轮 P0 验收级问题（Goal 状态、孤儿 FR、悬空 TC、别名）已全数闭合，但浮现出**两类新的 P0 阻断**：`registry.yaml` 事实字段与制品脱节、CI 集成门禁因缺 `-tags integration` 实际空转；加上 **prompt 制品零交付** 使 Spec→Code 全链路仍不能宣告就绪。
2. **是否需要建立 fred 模块规则 / 标准规范？—— fred 专属 `RULES.md` 已存在且充分（v1.1.0，与 spec 对齐，无矛盾）；建议"锦上添花"再建一份跨模块的 `宏观数据源 C/S 模块标准`，fred 与 bea/ecb/treasury/yahoo 等同源模块统一引用，避免 15 份重复文档。** fred `RULES.md` 仅需微迭代。

---

## 一、总体评分

| 维度 | 本次 | 首轮 | 趋势 | 关键判断 |
|---|---|---|---|---|
| 需求层（spec/goal/design） | 89 | 87 | ↑ | 孤儿 FR/悬空 TC 已闭合；子规格版本滞后、domain_macro 绑定陈旧、SERIES-NAMING 自矛盾为新问题 |
| 追溯矩阵（matrix/tasks/prompt） | 82 | 82 | → | 主链闭环；AC-008 孤儿、FR-016 Task 错配、根/子状态冲突；**prompt 实体缺失阻断 S5** |
| 规则与标准（rules/standards） | 85（fred 规则）/ 60（标准就绪） | — | 新维度 | RULES.md 充分；缺共享数据源标准 |
| 治理与运维（registry/CI/evidence/gate） | 58 | 70 | ↓ | registry 事实脱节 + CI 集成空转两处 P0 拉低 |
| **综合** | **~72/100** | 76 | ↓ | 工程事实同步与 CI 是真短板，非文档质量 |

---

## 二、P0 阻断项（必须优先处理）

| # | 问题 | 证据 | 影响 | 建议动作 |
|---|---|---|---|---|
| D-P0-1 | `registry.yaml` 事实字段脱节 | `module/registry.yaml:541,545`（`lifecycle: proposed`/`spec_version: v0.1.0-draft`） vs `spec/SPEC.md:3-4`（`Status: Implemented`/`v1.1.0`） | 治理成熟度与版本事实失真，违反 `RULES.md §9.1:216`「版本变更必须同步 registry」 | 改 `lifecycle: implemented`、`spec_version: v1.1.0`；同步 `registered` 之外其余事实字段 |
| D-P0-2 | CI 集成门禁空转 | `module/fred/ci-workflow.yaml:105-106` 运行 `go test ./internal/integration/...` **无 `-tags integration`**；而 `RULES.md:241` 要求 `//go:build integration` | 带 build tag 的集成测试永远不被执行，AC-003/004/005/009/010 端到端验证实际未闭环 | 命令补 `-tags integration`；与 `RULES.md §10.1:236` 对齐 |
| D-P0-3 | prompt 制品零交付，S5 无法推进 | `module/fred/prompt/` 仅有 `README.md`，`PROMPT-FRED-*.md` 实体全缺（Agent B 经 `find` 确认） | Spec→Code 管线停在 S5 Prompt 阶段，无法进入 S6 Code | 按 `prompt/README.md:12-18` 最小结构补齐 `PROMPT-FRED-ROOT-001`/`CLIENT-001`/`SERVER-001` 三份 |

> 注：D-P0-1/2 属"事实同步类缺陷"，AGENTS.md 明确区分事实字段与投影字段，release/version 只能来自权威制品——此处正是事实未回流的典型。

---

## 三、P1 重要项（应尽快修复）

### 3.1 需求层

| # | 问题 | 证据 | 建议 |
|---|---|---|---|
| D-P1-1 | 子规格版本/状态滞后 | `spec/client/SPEC.md:3-5`、`spec/server/SPEC.md:3-5` 仍 `Status: Planned`/`Spec-Version: v1.0.0`/`Last-Updated: 2026-07-03` | 同步父 SPEC v1.1.0 的状态与版本 |
| D-P1-2 | `domain_macro` 绑定章节陈旧 | `spec/SPEC.md:164` 引 `domain-macro v0.1.0` 并称 7 模型"尚不存在"，但 `OPEN-002`(`:370`)、CHANGELOG 已声明 v1.0.1 | 刷新 §9.1 至 v1.0.1 现状，消除与 §23/CHANGELOG 矛盾 |
| D-P1-3 | `SERIES-NAMING.md` 内部自相矛盾 | `:44` 将 `JPNASSETS` 列为"禁止别名"，但 `:59-63` 与 `spec/SERIES-API.md:74-86` 又将其作为外部路由合法序列；`source_component`/`provider` 字段口径（BoJ vs BOJ）不一致 | 统一命名与字段口径 |
| D-P1-4 | 生产级 SLA 缺失 | `spec/SPEC.md:294-305` 仅 dev P95，无生产 P95/P99 | 补生产环境性能预算 |
| D-P1-5 | Admin API 鉴权规范缺失 | `spec/SPEC.md:322` 仅"必须有鉴权"；`spec/server/SPEC.md:86` OPEN-S2 仍 Open | 补 mTLS/JWT 细则，关闭 OPEN-S2 |

### 3.2 追溯矩阵 / 任务

| # | 问题 | 证据 | 建议 |
|---|---|---|---|
| D-P1-6 | FR-016 Task 列错配 | `matrix/TRACEABILITY.md:44` 写 `TASK-FRED-SERVER-001`，但 SERVER-001 不含 FR-016（实际由 SERVER-002 承接 `tasks/server/TASK-FRED-SERVER-001-ingest-pipeline.md:9-15`） | 改 Task 列为 `CLIENT-001, SERVER-002` |
| D-P1-7 | 根/子矩阵状态冲突 | 子矩阵 FR-S004/005/006/007/011 标 `CI-gated`（`matrix/server/TRACEABILITY.md:12-19`），主矩阵对应 FR 全标 `Done`（`matrix/TRACEABILITY.md:32-44`） | 子矩阵状态与主矩阵对齐，或显式标注"集成验证口径" |
| D-P1-8 | AC-008 孤儿 | `matrix/TRACEABILITY.md:99` 唯一出现，§1/§4 无引用 | 在 G-SC-001 行 AC 列补 AC-008，§4 增 `TC-GOV→AC-008` |

### 3.3 治理 / 门禁

| # | 问题 | 证据 | 建议 |
|---|---|---|---|
| D-P1-9 | RULES §7 与 BOUNDARY-GATES 门禁口径不映射 | `RULES.md:180-186` 列 G1-G5；`gate/BOUNDARY-GATES.md:11-23` 列 BG-001~013；G1（fred import macro_data）在 BG 中无对应项 | 在 BOUNDARY-GATES.md 显式映射 G1-G5↔BG |
| D-P1-10 | 门禁数量 9≠13 | evidence log 报「9 passed」，文档枚举 13 道 | 对齐脚本与文档实际 gate 数 |
| D-P1-11 | 证据未追溯 FR/AC/TC 且仅单日 | `evidence/README.md:28` 要求追溯，但 `evidence/2026-07-08/test/unit-and-gate.log` 仅覆盖率+gate，无 AC 映射；无 review/release/retrospective 目录 | 补 AC 映射与多阶段证据归档 |

---

## 四、P2 建议项

| # | 问题 | 证据 | 建议 |
|---|---|---|---|
| D-P2-1 | `spec/SPEC.md §24` 超标准节 | `spec/SPEC.md:379-404` | 变更摘要迁入 CHANGELOG.md，保持 23 节结构 |
| D-P2-2 | OPEN-008/009 缺量化关闭条件 | `spec/SPEC.md:376-377` | 补覆盖审计阈值与外部路由清单确认条件 |
| D-P2-3 | SERIES-CATALOG §11.6 未闭合 checkbox | `spec/SERIES-CATALOG.md:388-392` | 逐项核实 runtime 状态后改 `[x]` |
| D-P2-4 | OPEN-CAT-1 关闭记录过声称 | `SERIES-NAMING.md:88-90` 标"待补录"，但 VIXCLS/WTREGEN 已入 CATALOG | §4 状态回填为已闭合 |
| D-P2-5 | 覆盖率分母示例口径冲突 | `SERIES-NAMING.md:71` 示例 `246` vs CATALOG 全量 `90` | 示例改 90 或明确标注"示例值" |
| D-P2-6 | 子计划过期 + TC 编号孤岛 | `plan/client/PLAN.md:3`、`plan/server/PLAN.md:3` 仍 2026-07-03；引用 `TC-C001~C005` 根矩阵无此编号 | 同步日期并加 FR 命名桥 |
| D-P2-7 | 子矩阵缺 FR 命名桥 | client/server 仍用 FR-C*/FR-S*，无映射表 | 补 FR-C*/FR-S* ↔ 根 FR 映射 |

---

## 五、规则与标准建议（直接回答用户第二问）

### 5.1 fred 专属 `RULES.md` 评估

- **结论：已充分，结构完整（§1-§10），与 spec 一致性良好，无矛盾项。**
- 版本对齐：`RULES.md:3` `v1.1.0` = `spec/SPEC.md:4`；所引制品（SERIES-CATALOG/SERIES-NAMING/SPEC）均存在；核心概念在 spec 中均有依据。
- **微迭代项（非缺陷，属增强）**：
  - §7.1/§10.1 引用的 `scripts/boundary-gates.sh` 实位于 runtime 仓 `/home/workspace/fred`，主仓无法核验——建 PR 前应确认脚本与 gate 表一致（P0 级事实确认）。
  - §1.3「fred 禁止依赖 macro_data 内部包」属跨模块约束，但 `module/FOUNDATION-DEPS.yaml:520` 的 `fred:` 禁止边仅列 analytics/decision/execution 域，**未显式登记 macro_data**——建议回填该边或上升为标准。
  - 缺采集重试/限流/退避（resiliencx 绑定）专章、缺 OSS 重放/backfill 流程专章（§2.3/§5 仅点到）。

### 5.2 是否建立"模块标准规范"——推荐方案 B

**同级 15 个数据源/宏观 C/S 模块（bea/ecb/japan_cb/uk_cb/treasury/yahoo/yield_curve/eastmoney/coinglass/hyperliquid/okx/binance/alternative_data/macro_data/domain_macro）全部无 RULES.md，亦无共享标准。** 这些模块在 `FOUNDATION-DEPS.yaml` 共享同一族约束（均列 `forbidden_deps`、均 `data` 域、均受 `business_forbidden_edges` 数据域上行约束），其规则高度同质：C/S 隔离、raw-first、domain_macro 出域、幂等、no-lookahead、boundary-gate。

若 15 个模块各自补 RULES.md，将产生 15 份高度重复文档并随时间漂移。**建议：**

> **新建跨模块标准 `docs/standards/macro-data-source-module-standard.md`（草案大纲 10 章）**，fred `RULES.md` 改为「引用标准 + 保留 fred 专属差异（FRED 端点矩阵、Series Catalog、Series ID 命名）」。

草案大纲：
1. 适用范围：数据域 C/S 采集模块（fred/bea/ecb/treasury/yahoo/yield_curve…）
2. §C/S 隔离：client(采集)/server(持久化) 独立进程、NATS 仅作 handoff/control plane
3. §raw-first：先写 OSS(raw+content_hash) 再发 envelope，OSS 路径格式
4. §出域契约：禁止 Provider DTO 出域，统一转 `domain_macro` 类型
5. §no-lookahead 时间语义：四时间戳与 `IsVisibleAt`
6. §幂等与 checkpoint：幂等键 + 状态机
7. §存储写入顺序：client/server 分层与顺序
8. §边界门禁：G1-G5 通用 gate（含 macro_data 单向依赖边）
9. §可观测性 / CI：结构化日志、fail-fast、health、CI gate
10. §版本与引用：Spec-Version 权威、registry 同步；模块专属差异由各自 RULES.md 补充

> `docs/standards/` 现有 `go-coding-standards.md` 与 L0/L1/L2.5 指南，**无数据域/数据源模块标准**，存在空白，本草案填补之。

---

## 六、优先级执行路线图（建议 PR 顺序）

### 第一阶段（< 1 天，纯文档/配置，无需开发）
1. **D-P0-1** 修正 `registry.yaml` fred 条目（`lifecycle`/`spec_version`）—— 治理事实纠错
2. **D-P0-2** 修正 `ci-workflow.yaml` 集成测试加 `-tags integration`
3. **D-P1-1/2** 同步子规格版本状态、刷新 `domain_macro` 绑定章节
4. **D-P1-3/5** 闭合 SERIES-NAMING 自矛盾、OPEN-CAT-1 记录回填
5. **D-P1-6/7/8** 修 FR-016 Task 错配、根/子矩阵状态对齐、闭合 AC-008

### 第二阶段（< 1 周，制品补齐）
6. **D-P0-3** 补齐 3 份 prompt Context Package（解锁 S5→S6）
7. **D-P1-9/10** BOUNDARY-GATES 映射 G1-G5↔BG、对齐门禁数量
8. **D-P1-4/5/11** 补生产 SLA、Admin 鉴权、证据 AC 追溯与多阶段归档
9. **D-P2** 项（§24 迁移、OPEN-008/009 量化、CATALOG checkbox 等）

### 第三阶段（标准建设）
10. 新建 `docs/standards/macro-data-source-module-standard.md`，fred `RULES.md` 增加「引用标准」声明 + 微迭代 §1.3/重试/backfill 章节
11. 同级模块（bea/ecb/treasury/yahoo…）后续建 RULES.md 时统一引用该标准

---

## 七、正向肯定（保持项）

- ✅ 首轮 4 个 P0 验收问题（Goal 状态、孤儿 FR-C007/C008、悬空 TC-011/V-017、别名 VXVCLS/VIXCLS）已全数闭合
- ✅ 主规格 16/16 FR 有 AC+TC，client 9/9、server 11/11 闭环，无孤儿 FR/TC
- ✅ `RULES.md` 已建立且与 spec 高度对齐，无矛盾
- ✅ boundary-gates 实测通过、cs.Version 四处一致、SERIES-CATALOG 12 类 90 序列分层清晰
- ✅ 单元测试覆盖率优秀（internal/client 96.4%、cs/domain/store 100%）

---

## 八、结论

fred 模块在**文档与需求层**已相当成熟（首轮 P0 全闭合、RULES.md 已建），但**治理事实同步（registry）与工程门禁（CI 集成空转）** 是当前最关键的 P0 短板，且 **prompt 制品缺失阻断 Spec→Code 全链路**。无需"从零建立" fred 规则——它已存在且充分；真正的下一步价值在于 (a) 修复事实/CI 同步缺陷，(b) 补齐 prompt 解锁 S6，(c) **抽离跨模块"宏观数据源 C/S 模块标准"** 以约束 fred 及其 14 个同源模块，避免规范漂移。

[RULES I BROKE]：无。
