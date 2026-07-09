# OrderBook Goal 草案

> 日期：2026-07-09
> 状态：Draft / Report-only
> 候选 Goal ID：`GOAL-20260709-001`
> 目标路径：若获授权，可迁移为 `module/orderbook/goal/goal.md` 或登记到 `.config/goal/registry/goals.yaml`
> 约束：本文不创建 `module/orderbook/`，不登记 `module/registry.yaml`，不修改 `.config/goal/`
> 来源：`knowledge/OrderBook.md`、`report/OrderBook/ORDERBOOK-EXECUTION-PLAN-20260709.md`、`docs/goal/02-goal-standard.md`、`docs/goal/04-gates.md`

---

## 0. 状态声明

本文是 Goal 草案，不是 Active Goal。[FRAME, HIGH]

候选 Goal ID 只用于报告内引用，不代表 `.config/goal/registry/goals.yaml` 已占用该 ID。[FRAME, HIGH]

正式进入 Goal 管线前，必须由维护者指定 owner，并明确是否允许把本草案迁移到 Goal 控制面或模块目录。[COMPUTED, HIGH]

本文不授权创建 `module/orderbook/`、`github.com/ZoneCNH/orderbook` 或 `/home/workspace/orderbook`。[COMPUTED, HIGH]

---

## 1. Goal 一句话

在 2026-08-31 前，将 `knowledge/OrderBook.md` 中的 OrderBook 独立化设想收敛为可被 G1/G2/G3 审查的受治理交付目标，使跨 venue 订单簿事实链具备明确边界、成功指标、Contract/Gate 草案、Traceability seed 和 binance 前置硬化计划，同时保持未授权前零模块创建、零 runtime repo 创建、零 registry 写入。[FRAME, HIGH]

---

## 2. Context

`knowledge/OrderBook.md` 提出了把 OrderBook 从单一交易所实现提升为跨交易所微观结构事实链能力的方向。[COMPUTED, HIGH]

binance runtime 当前已经具备本地 book、snapshot + diff 对齐、sequence validation、TopN/Incremental 输出、重建、持久化和健康监控等 OrderBook v0 能力。[COMPUTED, HIGH]

当前 `orderbook` 尚未作为独立模块登记在 `module/registry.yaml` 中。[COMPUTED, HIGH]

新建 `module/orderbook/` 和新建 `github.com/ZoneCNH/orderbook` 受宪法双闸门约束，必须先有治理层审批和人工会话显式授权。[COMPUTED, HIGH]

因此，本 Goal 的首要结果不是立刻写代码，而是把“是否以及如何独立化 OrderBook”变成可审查、可追溯、可阻断的治理交付目标。[FRAME, HIGH]

---

## 3. Objective

本 Goal 要达成的结果是：OrderBook 独立化从宏大草案降级为一个可进入正式 Goal/Spec/Design/Plan 管线的最小治理包。[FRAME, HIGH]

该治理包必须回答四个问题：[FRAME, HIGH]

1. OrderBook 候选模块解决什么跨 venue 问题。[FRAME, HIGH]
2. 哪些职责继续留在 `binance`、`domain_market`、`domain_exchange`、`factor_engine`、`execution` 或 `orderx`。[FRAME, HIGH]
3. 哪些 Contract、Gate、Replay 和 Traceability 制品足以支撑 G2/G3 审查。[FRAME, HIGH]
4. 哪些 binance 前置硬化任务必须先完成，才能避免把 Binance 私有实现直接包装成新模块。[FRAME, HIGH]

---

## 4. Scope

### 4.1 In Scope

| 范围 | 说明 |
| --- | --- |
| Goal 草案 | 定义背景、目标、成功指标、验收标准、约束和 non-goals。[FRAME, HIGH] |
| G0/G1 Gate 启动包 | 明确 Context Gate 与 Goal Gate 的输入、输出、阻断项和证据需求。[FRAME, HIGH] |
| Contract/Gate 草案 | 覆盖 BookEvent、GapEvent、QualityEvent、BookHash、Replay Gate、Adapter Conformance Gate 和 Boundary Gate。[FRAME, HIGH] |
| Traceability seed | 把 FR/BR 连接到 AC、Gate 和候选 Task。[FRAME, HIGH] |
| binance Phase 1 前置硬化计划 | 聚焦 combined stream 分片、DepthLevel 语义、options depth 口径和 replay fixture 输入。[FRAME, HIGH] |
| 准入 ADR 输入 | 为维护者决定是否启动双闸门提供奥卡姆三条件和替代方案。[FRAME, HIGH] |

### 4.2 Out of Scope

| 范围外 | 原因 |
| --- | --- |
| 创建 `module/orderbook/` | 需要双闸门授权。[COMPUTED, HIGH] |
| 创建 `github.com/ZoneCNH/orderbook` 或 `/home/workspace/orderbook` | 需要双闸门授权，且应后置于 Contract/Gate 与 binance 前置硬化。[COMPUTED, HIGH] |
| 修改 `module/registry.yaml` | `orderbook` 尚未通过准入 ADR 和人工授权。[COMPUTED, HIGH] |
| 修改 `.config/goal/registry/goals.yaml` | 本次只产出 report-only 草案，未获得控制面写入授权。[FRAME, HIGH] |
| 实现 OKX / Bybit adapter | 第二 venue 选择仍是未决问题。[INFERRED, HIGH] |
| 实现因子研究、市场状态解释或执行策略 | 这些职责应属于分析域或执行域消费方，而不是 OrderBook 首版事实链目标。[INFERRED, HIGH] |

---

## 5. Success Metrics

| 指标 | 目标值 | 截止建议 | 证据 |
| --- | --- | --- | --- |
| SM-OB-GOAL-001：Context 完整度 | G0 输入包含来源文档、当前分支、commit、工作树范围和阻断项，覆盖率 100%。[FRAME, HIGH] | 2026-07-09 | `ORDERBOOK-GOAL-G0-G1-GATE-PACKET-20260709.md` |
| SM-OB-GOAL-002：G1 可审查性 | Goal 草案包含 Context、Objective、Scope、Success Metrics、AC、Constraints、Non-goals、Priority、Deadline、Downstream Mapping。[FRAME, HIGH] | 2026-07-09 | 本文件 |
| SM-OB-GOAL-003：治理安全 | 未授权前 `module/orderbook/`、runtime repo、`module/registry.yaml`、`.config/goal/` 写入次数为 0。[FRAME, HIGH] | 持续 | `git status --short` |
| SM-OB-GOAL-004：Contract seed 覆盖 | FR-OB-001..012 均可映射到 AC、Gate 和候选 Task seed。[FRAME, HIGH] | 2026-07-09 | `ORDERBOOK-TRACEABILITY-SEED-20260709.md` |
| SM-OB-GOAL-005：binance 前置硬化就绪 | OB-010..014 均有目标、产物、验证命令和阻断关系。[FRAME, HIGH] | 2026-07-09 | `ORDERBOOK-BINANCE-PHASE1-HARDENING-PLAN-20260709.md` |
| SM-OB-GOAL-006：准入决策就绪 | ADR 草案覆盖必要性、唯一性、净收益、替代方案、风险和后置条件。[FRAME, HIGH] | 2026-07-09 | `ADR-MODULE-ONBOARDING-DRAFT-001-orderbook-20260709.md` |

---

## 6. Acceptance Criteria

| AC | Given | When | Then |
| --- | --- | --- | --- |
| AC-GOAL-001 | 给定维护者需要判断是否启动 OrderBook Goal。[FRAME, HIGH] | 查看 `report/OrderBook/`。[FRAME, HIGH] | 能找到 Goal 草案、Gate 启动包、执行计划、ADR 草案、Spec 草案、Contract/Gate 草案和 Traceability seed。[FRAME, HIGH] |
| AC-GOAL-002 | 给定 G1 Goal Gate 要求 owner、成功指标、验收标准、边界和 non-goals。[COMPUTED, HIGH] | 评审本 Goal 草案。[FRAME, HIGH] | 除 owner 仍需人工指定外，其余 G1 字段可被逐项审查。[FRAME, HIGH] |
| AC-GOAL-003 | 给定新模块创建受双闸门约束。[COMPUTED, HIGH] | 执行本 Goal 的 report-only 阶段。[FRAME, HIGH] | 不出现 `module/orderbook/`、runtime repo、`module/registry.yaml` 或 `.config/goal` 的新增写入。[FRAME, HIGH] |
| AC-GOAL-004 | 给定 `knowledge/OrderBook.md` 包含 runtime repo 创建计划。[COMPUTED, HIGH] | 转化为治理执行路线。[FRAME, HIGH] | runtime repo 创建被后置到双闸门、Contract/Gate 和 binance Phase 1 之后。[FRAME, HIGH] |
| AC-GOAL-005 | 给定 binance 已有 OrderBook runtime。[COMPUTED, HIGH] | 评估独立化计划。[FRAME, HIGH] | 计划优先 harden binance 风险，不做 big-bang rewrite。[FRAME, HIGH] |
| AC-GOAL-006 | 给定未来 `orderbook` 需要可追溯。[FRAME, HIGH] | 检查 Traceability seed。[FRAME, HIGH] | FR/BR 能追到 AC、Gate 和候选 Task，且状态保持 Pending。[FRAME, HIGH] |
| AC-GOAL-007 | 给定 G1 需要结果导向目标。[COMPUTED, HIGH] | 审查 Objective 和 Success Metrics。[FRAME, HIGH] | Goal 关注“受治理、可审查、可追溯的独立化基线”，而不是直接指定代码实现。[FRAME, HIGH] |
| AC-GOAL-008 | 给定 owner 尚未指定。[COMPUTED, HIGH] | 执行 G1 自检。[FRAME, HIGH] | Gate 结论必须标为 BLOCKED，而不是伪造 PASS。[FRAME, HIGH] |

---

## 7. Constraints

| 约束 | 说明 |
| --- | --- |
| 治理约束 | 未经双闸门授权不得创建 `module/orderbook/` 或 runtime repo。[COMPUTED, HIGH] |
| 控制面约束 | 本轮只写 `report/OrderBook/`，不修改 `.config/goal/`。[FRAME, HIGH] |
| 仓库约束 | 本仓是文档治理仓，不承载 runtime 源码。[COMPUTED, HIGH] |
| 边界约束 | `orderbook` 候选职责不得吞并交易所私有 adapter、alpha 研究、执行策略或账户私有流。[FRAME, HIGH] |
| 命名约束 | 若后续准入，模块名应使用 snake_case 的 `orderbook`。[FRAME, HIGH] |
| 证据约束 | 没有 Gate 证据不得声明 Goal/Spec/Task Done。[FRAME, HIGH] |

---

## 8. Non-goals

| Non-goal | 理由 |
| --- | --- |
| 本 Goal 不交付 OrderBook runtime 代码。[FRAME, HIGH] | 当前阶段是治理启动，不是 S6 Code。[COMPUTED, HIGH] |
| 本 Goal 不批准 `orderbook` 模块准入。[FRAME, HIGH] | 准入必须由正式 ADR 和双闸门裁决完成。[COMPUTED, HIGH] |
| 本 Goal 不替代 binance orderbook Phase 1 实现任务。[FRAME, HIGH] | Phase 1 需要在 `/home/workspace/binance` runtime 仓执行。[COMPUTED, HIGH] |
| 本 Goal 不宣称跨 venue 平台完成。[FRAME, HIGH] | 后续已补第二 venue-style conformance fixture，但真实第二 venue adapter/live integration 仍未完成。[COMPUTED, HIGH] |
| 本 Goal 不定义交易策略或下单逻辑。[FRAME, HIGH] | 策略和执行属于下游消费方职责。[INFERRED, HIGH] |

---

## 9. Priority

优先级建议为 P0，因为它阻断 OrderBook 独立化是否能进入正式 Goal/Spec/Design 管线的治理入口。[FRAME, HIGH]

---

## 10. Deadline

建议 G1 人工评审截止时间为 2026-07-12。[FRAME, MED]

建议 binance Phase 1 前置硬化证据截止时间为 2026-07-31。[FRAME, MED]

建议 `orderbook` 是否进入双闸门准入的决策截止时间为 2026-08-31。[FRAME, MED]

上述日期是执行计划草案日期，不是已经批准的项目承诺。[FRAME, HIGH]

---

## 11. Downstream Mapping

| 层级 | 当前草案 |
| --- | --- |
| Spec | `ORDERBOOK-SPEC-DRAFT-20260709.md`。[COMPUTED, HIGH] |
| Design / ADR | `ADR-MODULE-ONBOARDING-DRAFT-001-orderbook-20260709.md`。[COMPUTED, HIGH] |
| Plan | `ORDERBOOK-EXECUTION-PLAN-20260709.md`、`ORDERBOOK-BINANCE-PHASE1-HARDENING-PLAN-20260709.md`。[COMPUTED, HIGH] |
| Matrix | `ORDERBOOK-TRACEABILITY-SEED-20260709.md`。[COMPUTED, HIGH] |
| Contract / Gate | `ORDERBOOK-CONTRACT-GATE-DRAFT-20260709.md`。[COMPUTED, HIGH] |
| Migration Map | `ORDERBOOK-BINANCE-MIGRATION-MAP-20260709.md`。[COMPUTED, HIGH] |

---

## 12. Open Blockers

| Blocker | 影响 | 解除条件 |
| --- | --- | --- |
| Owner 未指定。[COMPUTED, HIGH] | G1 不能 PASS。[COMPUTED, HIGH] | 维护者明确 owner，并写入正式 Goal 或 registry。[FRAME, HIGH] |
| 双闸门授权未完成。[COMPUTED, HIGH] | 不能创建 `module/orderbook/` 或 runtime repo。[COMPUTED, HIGH] | 治理层审批 + 人工会话显式授权。[COMPUTED, HIGH] |
| binance Phase 1 未实现。[COMPUTED, HIGH] | runtime 迁移风险仍高。[INFERRED, HIGH] | combined stream 分片、DepthLevel 回归、options depth 证据和 replay input 证据完成。[FRAME, HIGH] |
| 第二 venue POC 未确定。[INFERRED, HIGH] | 跨 venue 独立化收益仍是条件性判断。[INFERRED, HIGH] | 维护者选择 OKX、Bybit 或其他 venue 并定义 conformance fixture 范围。[FRAME, MED] |

---

[RULES I BROKE]：无
