# OrderBook 深度分析与执行计划

> 日期：2026-07-09
> 分析对象：`knowledge/OrderBook.md`
> 输出位置：`report/OrderBook/ORDERBOOK-EXECUTION-PLAN-20260709.md`
> 结论性质：执行计划裁决版，不创建 `module/orderbook/`，不创建 runtime 仓库。
> 证据口径：本地文档、治理规则、binance runtime 源码、既有评审报告。

---

## 0. 裁决摘要

`knowledge/OrderBook.md` 的战略方向成立：OrderBook 不应长期只是 `binance/internal/client/orderbook/` 的私有实现，而应被规格化为跨交易所微观结构事实链能力。[INFERRED, HIGH]

该文档不能按原文立即执行：它包含创建 `module/orderbook/` 与 `github.com/ZoneCNH/orderbook` 的动作，而宪法要求新 `module/{模块名}/` 和新 ZoneCNH 仓库必须先满足双闸门授权。[COMPUTED, HIGH]

当前最强反论证是：binance 已经实现了较完整的 OrderBook runtime，且系统尚未证明第二个交易所 adapter 的真实需求已经 materialized；因此立即建独立 runtime repo 可能触发模块增殖与重复抽象风险。[INFERRED, HIGH]

本报告的执行裁决是：先完成规格裁决、binance 前置硬化、契约冻结和门禁设计；只有双闸门授权齐备后，才进入 `module/orderbook/` 和 `ZoneCNH/orderbook` 创建阶段。[FRAME, HIGH]

本次可立即执行的范围是：保存本分析报告、更新 `report/INDEX.md`、准备后续准入 ADR 的输入材料、把 binance 的前置工程缺口纳入执行队列。[FRAME, HIGH]

---

## 1. 数据来源与证据

| 来源                                                                                                             | 用途                                                                                           | 证据标签   | 置信度 |
| ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ---------- | ------ |
| `knowledge/OrderBook.md:1-2011`                                                                                  | 源计划全文，覆盖定位、架构、合同、状态机、Schema、Replay、Feature、治理、1/7/30/60/90 天计划。 | [COMPUTED] | HIGH   |
| `report/binance/orderbook-deep-analysis.md`                                                                      | 已有对照报告，结论为 binance 同步协议高度对齐，Policy/Demand 与 Market State 未完整落地。      | [COMPUTED] | HIGH   |
| `report/binance/ORDERBOOK-REVIEW-MEMO-20260709.md`                                                               | 已有评审备忘，反对在 binance 落地重复 PolicyManager，建议把 combined stream 分片升为 P0。      | [COMPUTED] | HIGH   |
| `docs/constitution/02-module-boundaries.md:83-103`                                                               | 新模块和新仓库创建双闸门授权、命名规则。                                                       | [COMPUTED] | HIGH   |
| `module/registry.yaml` + `rg "orderbook"`                                                                        | 本次核验未发现 `orderbook` 已注册为独立模块。                                                  | [COMPUTED] | HIGH   |
| `/home/workspace/binance/internal/client/orderbook/*.go`                                                         | binance runtime 已有本地 book、对齐、序号校验、重建、TopN、增量、持久化、健康监控实现。        | [COMPUTED] | HIGH   |
| `/home/workspace/binance/internal/client/stream_control.go:363-403`                                              | 当前 stream URL 由 active streams 单次拼接生成，combined stream 分片仍是前置工程风险。         | [COMPUTED] | HIGH   |
| `/home/workspace/binance/pkg/whitelistclient/*` + `/home/workspace/binance/internal/client/runtime.go:1011-1137` | DepthLevel、OrderbookFeatures、tier Capability 和订单簿白名单同步链路已有部分实现。            | [COMPUTED] | HIGH   |

---

## 2. 对源文档的结构判断

`knowledge/OrderBook.md` 不是单纯的技术笔记，而是一份混合了模块准入论证、目标架构、接口草案、runtime 目录草案、迁移路线、团队分工、长期研究愿景和行动计划的综合草案。[COMPUTED, HIGH]

该文档的强项是把 OrderBook 定位为“市场微观结构事实链”，并把 Raw Feed、BookEvent、BookState、FeatureState、ExecutionState 分层拆开。[COMPUTED, HIGH]

该文档的主要风险是把可立即执行的任务、需要治理授权的任务、未来研究愿景混在同一条路线里，容易诱导直接创建模块或在采集层堆叠分析职责。[INFERRED, HIGH]

该文档的第二个风险是低估了 binance runtime 当前实现的成熟度；binance 已有 9 步对齐、spot/futures 序号校验、auto rebuild、TopN/Incremental 输出、持久化和 checksum drift 监控。[COMPUTED, HIGH]

该文档的第三个风险是 Feature Engine 与 ExecutionDepthState 的归属过宽；确定性微观结构派生可以进入 OrderBook contract，但 alpha/factor/market-state 解释和执行反馈不应直接塞进 binance 采集层。[INFERRED, HIGH]

---

## 3. 当前事实基线

### 3.1 治理基线

`orderbook` 当前未作为独立模块出现在 `module/registry.yaml` 中。[COMPUTED, HIGH]

宪法要求未经授权禁止创建 `module/{模块名}/` 目录和对应 GitHub 仓库，且要求治理层审批与人工会话显式授权缺一不可。[COMPUTED, HIGH]

`orderbook` 命名本身符合 snake_case；`OrderBook` 只能作为 Go 类型名或报告目录名，不应作为模块仓库名。[INFERRED, HIGH]

因此，本报告不得直接创建 `module/orderbook/` 或 runtime 仓库。[COMPUTED, HIGH]

### 3.2 binance runtime 基线

binance 的 `OrderBookManager` 以 per-symbol 状态机管理订单簿，并维护 `StateBuffering`、`StateAligned`、`StateRebuilding` 等状态。[COMPUTED, HIGH]

binance 的 `alignAlgorithm` 实现 REST snapshot 与 buffered diff 的 9 步对齐，并校验 `U/u/pu` 连续性。[COMPUTED, HIGH]

binance 的 `Book.ApplyLevel` 把 `qty == "0"` 处理为删除价位，并用排序结构维护 bid/ask 档位。[COMPUTED, HIGH]

binance 已有 `TopNUpdate` 和 `IncrementalEvent` 两类下游输出事件。[COMPUTED, HIGH]

binance 已有文件快照持久化、fast recovery、checksum drift detection 和重建告警相关实现。[COMPUTED, HIGH]

binance 已有 `OrderbookFeatures`、`StreamType`、`DepthLevel`、tier Capability 和订单簿白名单子集校验链路。[COMPUTED, HIGH]

binance 仍存在 combined stream 分片前置风险，因为 `streamConfig()` 当前把所有 active stream 拼成单个 URL，且代码注释显示 per-symbol StreamRate 与 combined stream sharding 仍待 P1-5 收敛。[COMPUTED, HIGH]

### 3.3 源文档与现状的主要偏差

源文档把“创建独立模块”列为最小可行动作，但治理规则要求该动作必须后置到双闸门授权之后。[COMPUTED, HIGH]

源文档把 Feature Engine v0.1 列为 OrderBook owns，但更稳妥的边界是：OrderBook 只产出可重放、可校验、低语义解释度的微观结构派生事实；factor_engine 或 market_regime 消费这些事实做研究和市场状态解释。[INFERRED, HIGH]

源文档的 30/60/90 天计划包含多交易所、Feature Store、AutoResearch 和 Execution feedback，这些任务跨越多个域，不能作为单一 orderbook 模块首版验收范围。[INFERRED, HIGH]

---

## 4. 边界裁决

| 对象                              | 应拥有                                                                                                              | 不应拥有                                               | 裁决                                                         |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------ |
| `domain_market`                   | `OrderBook`、`PriceLevel`、`MarketDataQuality` 等 canonical model。                                                 | WS 订阅、snapshot 拉取、gap recovery、replay runtime。 | 模型 SSOT，不做 runtime。[INFERRED, HIGH]                    |
| `domain_exchange`                 | Venue capability、rate limit、exchange error、adapter SPI。                                                         | Binance/OKX 私有协议实现。                             | SPI 层，不做具体采集器。[INFERRED, HIGH]                     |
| `binance`                         | Binance REST/WS adapter、白名单同步、采集、转发、现有 OrderBook v0 runtime。                                        | 跨交易所通用 replay 平台、Feature/Market State 引擎。  | 短期保留 runtime，中期降为 adapter/wrapper。[INFERRED, HIGH] |
| `orderbook`                       | 经授权后拥有 sync state machine、sequence policy interface、BookEvent、BookHash、replay gate、adapter conformance。 | 交易所私有协议、策略决策、账户/订单生命周期。          | 仅在授权后成为独立模块。[FRAME, HIGH]                        |
| `factor_engine` / `market_regime` | 特征研究、因子评价、市场状态解释。                                                                                  | 原始交易所协议与本地订单簿重建。                       | 消费 OrderBook 事实链。[INFERRED, HIGH]                      |
| `execution` / `orderx`            | 执行策略、下单、订单生命周期、滑点反馈。                                                                            | 直接解析交易所 depth stream。                          | 消费质量标注后的派生执行状态。[INFERRED, HIGH]               |

---

## 5. 核心执行原则

1. 不做 big-bang rewrite；binance 现有 runtime 先保留，抽契约后迁移。[FRAME, HIGH]
2. 不绕过双闸门；未授权前只产出报告、ADR 草案输入和准入材料。[FRAME, HIGH]
3. 不在 binance 新增重复 `PolicyManager`；先复用白名单、tier Capability、OrderbookService 子集校验和 NATS 同步链路。[INFERRED, HIGH]
4. 不把 Feature Engine 全量塞进 binance；binance 的职责止于采集、校验、状态维护和事件输出。[INFERRED, HIGH]
5. 先补 combined stream 分片与资源上限治理，再扩 symbol 或多交易所。[INFERRED, HIGH]
6. 先冻结 BookEvent、BookHash、Replay Gate 和 Adapter Conformance，再创建 runtime repo。[FRAME, HIGH]
7. 每个阶段必须有 evidence manifest；没有证据不得声明 Done。[FRAME, HIGH]

---

## 6. 优先级裁决

| 优先级 | 工作项                                             | 理由                                                                       | 状态                                                |
| ------ | -------------------------------------------------- | -------------------------------------------------------------------------- | --------------------------------------------------- |
| P0     | combined stream 分片与上限治理                     | 当前单 URL 拼接是扩量前的硬风险。                                          | 应先于扩 symbol 和独立迁移。[INFERRED, HIGH]        |
| P0     | 新模块准入 ADR 输入包                              | 源文档要求新模块，但宪法要求双闸门授权。                                   | 未授权前只能准备输入材料。[COMPUTED, HIGH]          |
| P0     | BookEvent / BookHash / Replay Gate 草案            | 这是独立 orderbook 的最小 contract。                                       | 可作为报告后续规格材料。[FRAME, HIGH]               |
| P1     | DepthLevel / StreamRate 语义收敛                   | DepthLevel 已有实现，但 stream 后缀、TopN 截断、资源成本之间仍需统一验收。 | 需要 binance 专项回归。[INFERRED, HIGH]             |
| P1     | Adapter Conformance fixture                        | 迁移前必须证明 Binance adapter 可被独立 contract 验证。                    | 授权前可先设计 fixture schema。[FRAME, HIGH]        |
| P2     | Runtime repo scaffold                              | 需要双闸门授权。                                                           | 未授权前禁止执行。[COMPUTED, HIGH]                  |
| P2     | OKX / Bybit adapter                                | 需要独立 contract 和一个通过的 Binance adapter 先例。                      | 不应并行启动。[INFERRED, HIGH]                      |
| P3     | Feature Engine / AutoResearch / Execution feedback | 跨分析域、研究域和执行域。                                                 | 不属于首版 module onboarding 范围。[INFERRED, HIGH] |

---

## 7. 分阶段执行计划

### Phase 0：报告与裁决固化

目标：把 `knowledge/OrderBook.md` 从宏大草案收敛为可执行路线。[FRAME, HIGH]

| 任务   | 交付物                                                  | 验收                                                            |
| ------ | ------------------------------------------------------- | --------------------------------------------------------------- |
| OB-000 | `report/OrderBook/ORDERBOOK-EXECUTION-PLAN-20260709.md` | 报告包含数据来源、边界裁决、执行阶段、门禁和风险。[FRAME, HIGH] |
| OB-001 | `report/OrderBook/README.md`                            | 目录能说明报告用途和当前唯一权威入口。[FRAME, HIGH]             |
| OB-002 | `report/INDEX.md` 更新                                  | 新增 `OrderBook/` 子目录和变更历史。[FRAME, HIGH]               |

退出条件：报告落库，`git diff --check` 通过。[FRAME, HIGH]

### Phase 1：binance 前置硬化

目标：在不创建新模块的前提下，先修正会阻塞迁移和扩量的 runtime 风险。[FRAME, HIGH]

| 任务   | 交付物                            | 验收                                                                     |
| ------ | --------------------------------- | ------------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| OB-010 | combined stream 分片设计          | `module/binance/design/ORDERBOOK-STREAM-SHARDING.md` 或等效设计文档。    | 分片规则、每连接上限、回退策略、观测指标明确。[FRAME, HIGH]                 |
| OB-011 | combined stream 分片实现          | `/home/workspace/binance/internal/client/stream_control.go` 相关 patch。 | 多 URL / 多连接分片测试通过，单 URL 超长风险有测试覆盖。[FRAME, HIGH]       |
| OB-012 | DepthLevel 与 StreamType 语义回归 | `pkg/whitelistclient` 与 `internal/client/orderbook` 回归测试。          | tier Capability、DepthLevel.TopN、stream suffix 三者语义一致。[FRAME, HIGH] |
| OB-013 | options depth 协议证据            | testnet payload capture 或明确 postpone 证据。                           | options orderbook 不再被“65 Done”误读为全覆盖。[INFERRED, HIGH]             |
| OB-014 | replay input buffer 设计          | Ring buffer / fixture capture 设计。                                     | 能支撑后续 Replay Gate，但不改变当前生产路径。[FRAME, HIGH]                 |

退出条件：binance orderbook 相关测试和 stream config 测试通过，且证据记录到 binance report 或 evidence 目录。[FRAME, HIGH]

### Phase 2：新模块准入材料

目标：准备双闸门审批材料，但不执行创建动作。[FRAME, HIGH]

| 任务   | 交付物          | 验收                                                                                     |
| ------ | --------------- | ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| OB-020 | 准入 ADR 输入包 | `report/OrderBook/` 下的 ADR 输入章节或后续 ADR 草案。                                   | 回答 §2.5 奥卡姆剃刀三条件和 §2.6 授权需求。[FRAME, HIGH]                          |
| OB-021 | 模块边界矩阵    | Owns / Depends / Excludes 表。                                                           | 明确不侵入 `domain_market`、`binance`、`factor_engine`、`execution`。[FRAME, HIGH] |
| OB-022 | 依赖草案        | orderbook 对 domain_market、domain_exchange、observex、resiliencx、testkitx 等依赖草图。 | 不引入反向依赖或业务域上行依赖。[INFERRED, HIGH]                                   |
| OB-023 | 命名裁决        | 模块名固定为 `orderbook`。                                                               | 命名符合 snake_case。[COMPUTED, HIGH]                                              |

退出条件：维护者明确批准是否启动新模块准入流程。[FRAME, HIGH]

### Phase 3：规格冻结

目标：授权后才创建 `module/orderbook/`，并只创建规格制品，不迁移 runtime 代码。[FRAME, HIGH]

| 任务   | 交付物        | 验收                                      |
| ------ | ------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------- |
| OB-030 | Goal          | `module/orderbook/goal/goal.md`           | Goal 明确业务目标和非目标。[FRAME, HIGH]                                                  |
| OB-031 | Spec          | `module/orderbook/spec/SPEC.md`           | Spec-Version v0.1.0，范围限定为事实链与 replay contract。[FRAME, HIGH]                    |
| OB-032 | Contract      | `module/orderbook/spec/CONTRACT.md`       | SnapshotLoader、DiffSubscriber、SequencePolicy、ExchangeSemantics 初版冻结。[FRAME, HIGH] |
| OB-033 | State Machine | `module/orderbook/spec/STATE_MACHINE.md`  | 状态、转移、异常、staleness、quality impact 明确。[FRAME, HIGH]                           |
| OB-034 | Event Schema  | `module/orderbook/spec/EVENT_SCHEMA.md`   | BookEvent、QualityEvent、GapEvent 字段和版本规则明确。[FRAME, HIGH]                       |
| OB-035 | Traceability  | `module/orderbook/matrix/TRACEABILITY.md` | 可追踪 binance FR-052~061 到 orderbook FR-OB-xxx。[FRAME, HIGH]                           |

退出条件：Spec Review 和 Matrix Gate 通过，且未迁移 runtime 代码。[FRAME, HIGH]

### Phase 4：门禁与 fixture

目标：先证明 contract 可测试，再迁移实现。[FRAME, HIGH]

| 任务   | 交付物                   | 验收                                                       |
| ------ | ------------------------ | ---------------------------------------------------------- | ------------------------------------------------------------------------ |
| OB-040 | Replay Determinism Gate  | `module/orderbook/gate/replay-gate.md` 与 fixture schema。 | 同一事件集 replay 多次得到同一 BookHash。[FRAME, HIGH]                   |
| OB-041 | Gap Injection Gate       | `module/orderbook/gate/gap-injection-gate.md`。            | missing/duplicated/out-of-order diff 均触发降级或重建语义。[FRAME, HIGH] |
| OB-042 | Adapter Conformance Gate | `module/orderbook/gate/adapter-conformance-gate.md`。      | Binance fixture 可跑通 conformance。[FRAME, HIGH]                        |
| OB-043 | Boundary Gate            | `module/orderbook/gate/boundary-rules.md`。                | 禁止 `orderbook` import 交易所 runtime internal 包。[FRAME, HIGH]        |

退出条件：gate 文档和 fixture schema 先过审，再进入 runtime scaffold。[FRAME, HIGH]

### Phase 5：runtime repo scaffold

目标：在新仓库授权后创建最小 runtime 骨架。[FRAME, HIGH]

| 任务   | 交付物                  | 验收                                                            |
| ------ | ----------------------- | --------------------------------------------------------------- | ------------------------------------------ |
| OB-050 | repo scaffold           | `/home/workspace/orderbook` 与 `github.com/ZoneCNH/orderbook`。 | 仅在双闸门授权齐备后执行。[COMPUTED, HIGH] |
| OB-051 | pkg/adapter             | Adapter interfaces。                                            | 不依赖 `binance/internal`。[FRAME, HIGH]   |
| OB-052 | pkg/event + pkg/builder | BookEvent、BookBuilder、BookHash。                              | 确定性单测通过。[FRAME, HIGH]              |
| OB-053 | pkg/replay              | ReplayRunner。                                                  | fixture replay 稳定。[FRAME, HIGH]         |
| OB-054 | pkg/quality             | Quality flags 与 staleness policy。                             | fail-closed 行为有测试。[FRAME, HIGH]      |

退出条件：boundary gate、unit test、replay determinism gate 全部通过。[FRAME, HIGH]

### Phase 6：Binance adapter 化

目标：把 binance 从“拥有通用 OrderBook 平台”收敛为“提供 Binance adapter”。[FRAME, HIGH]

| 任务   | 交付物                | 验收                                        |
| ------ | --------------------- | ------------------------------------------- | ---------------------------------------------------- |
| OB-060 | BinanceSnapshotLoader | binance adapter 层实现 snapshot loader。    | conformance fixture 通过。[FRAME, HIGH]              |
| OB-061 | BinanceDiffSubscriber | binance adapter 层实现 diff subscriber。    | reconnect 与 gap fixture 通过。[FRAME, HIGH]         |
| OB-062 | BinanceSequencePolicy | spot 与 futures 序号策略。                  | spot `U/u` 与 futures `pu/u` 测试通过。[FRAME, HIGH] |
| OB-063 | migration wrapper     | binance 内部旧包降级为 wrapper 或 adapter。 | 下游 NATS/Kafka contract 不破坏。[FRAME, HIGH]       |

退出条件：binance 现有 FR-052~061 验收仍通过，且独立 orderbook gate 通过。[FRAME, HIGH]

### Phase 7：多交易所扩展

目标：用第二个交易所验证 contract 是否真能跨 venue。[FRAME, HIGH]

| 任务   | 交付物            | 验收                      |
| ------ | ----------------- | ------------------------- | ------------------------------------------- |
| OB-070 | OKX adapter POC   | OKX semantics fixture。   | 不修改 core contract 即可接入。[FRAME, MED] |
| OB-071 | Bybit adapter POC | Bybit semantics fixture。 | 与 OKX/Binance 共用 gate。[FRAME, MED]      |
| OB-072 | contract revision | 必要时 v0.2.0 contract。  | 变更由 fixture 证据驱动。[FRAME, MED]       |

退出条件：至少两个非同构 venue 通过 conformance，才宣称跨交易所能力成立。[INFERRED, HIGH]

### Phase 8：分析与执行消费

目标：把 OrderBook 事实链交给分析域和执行域消费，而不是在采集层堆叠策略逻辑。[FRAME, HIGH]

| 任务   | 交付物                     | 验收                                                              |
| ------ | -------------------------- | ----------------------------------------------------------------- | -------------------------------------------------- |
| OB-080 | Feature primitive contract | Spread/Mid/MicroPrice/DepthImbalance 等 deterministic primitive。 | FeatureHash 可 replay。[FRAME, MED]                |
| OB-081 | factor_engine 接入         | 因子计算消费 BookEvent/FeatureState。                             | 研究与实盘输入 schema 一致。[FRAME, MED]           |
| OB-082 | execution 接入             | ExecutionDepthState 或等效消费 contract。                         | stale/gap/quality fail-closed 有测试。[FRAME, MED] |
| OB-083 | AutoResearch issue loop    | fixture + evidence 自动生成候选任务。                             | 不作为首版验收条件。[FRAME, MED]                   |

退出条件：分析域和执行域的消费合同独立验收，不回写污染采集层边界。[INFERRED, HIGH]

---

## 8. 1 / 7 / 30 / 60 / 90 天计划

### 1 天

完成本报告、目录 README、索引更新和格式检查。[FRAME, HIGH]

不创建 `module/orderbook/`，不创建 runtime repo，不迁移 binance 代码。[FRAME, HIGH]

### 7 天

完成 binance 前置硬化设计：combined stream 分片、DepthLevel/StreamType/StreamRate 语义回归、options depth 口径澄清、Replay fixture 输入设计。[FRAME, HIGH]

完成新模块准入 ADR 输入包，但仍不执行创建动作。[FRAME, HIGH]

### 30 天

若维护者批准双闸门，则创建 `module/orderbook/` 规格目录并完成 Goal、SPEC、CONTRACT、STATE_MACHINE、EVENT_SCHEMA、TRACEABILITY 和 gate 文档。[FRAME, MED]

若维护者未批准双闸门，则继续在 binance 内收敛 OrderBook runtime 质量，并把跨交易所抽象推迟到第二个 venue 需求出现后。[FRAME, HIGH]

### 60 天

在授权前提下，创建最小 `ZoneCNH/orderbook` runtime scaffold，并把 Binance adapter 作为第一个 conformance target。[FRAME, MED]

不在 60 天内并行推进 OKX、Bybit、Feature Engine 和 Execution feedback，除非已有独立需求和证据包。[INFERRED, HIGH]

### 90 天

在 Binance adapter 通过 gate 后，选择一个第二 venue 做 POC，用 conformance 结果反向修订 contract。[FRAME, MED]

只有当两个以上 venue 通过同一套 gate 后，才把 `orderbook` 标记为跨交易所平台，而不是 Binance 抽象包。[INFERRED, HIGH]

---

## 9. 验收门禁

| Gate            | 通过条件                                                 | 阻断条件                                                           |
| --------------- | -------------------------------------------------------- | ------------------------------------------------------------------ |
| Governance Gate | 双闸门授权齐备。                                         | 未授权却创建 `module/orderbook/` 或 runtime repo。[COMPUTED, HIGH] |
| Boundary Gate   | orderbook 不 import 交易所 runtime internal 包。         | 通用模块依赖 `binance/internal`。[FRAME, HIGH]                     |
| Replay Gate     | 同一事件集 replay 后 BookHash 稳定。                     | map iteration、wall clock、随机数污染 replay。[FRAME, HIGH]        |
| Gap Gate        | gap、重复、乱序、延迟 snapshot 触发正确降级。            | gap 后继续输出 reliable=true。[FRAME, HIGH]                        |
| Adapter Gate    | 每个 venue 提供 semantics、snapshot、diff、gap fixture。 | 新 adapter 无 fixture 即接入生产路径。[FRAME, HIGH]                |
| Evidence Gate   | 每次 Done 都有 manifest。                                | 只有口头 Done 或报告 Done。[FRAME, HIGH]                           |

---

## 10. 风险账本

| 风险                     | 严重度   | 触发条件                                         | 缓解                                                                  |
| ------------------------ | -------- | ------------------------------------------------ | --------------------------------------------------------------------- |
| 绕过双闸门创建模块       | Critical | 直接执行源文档 Day 1 创建目录。                  | 把创建动作后置到 Phase 3。[COMPUTED, HIGH]                            |
| 抽象早于第二 venue 需求  | High     | 只基于 Binance 经验创建通用 repo。               | 先 freeze contract，再用第二 venue POC 证伪。[INFERRED, HIGH]         |
| binance 采集层膨胀       | High     | 在 binance 内实现 Feature/Market State。         | Feature/Market State 下沉到分析域消费。[INFERRED, HIGH]               |
| combined stream 扩量失败 | High     | symbol/stream 扩量后仍单 URL 拼接。              | 先做 stream sharding 和上限验证。[COMPUTED, HIGH]                     |
| DepthLevel 语义漂移      | Medium   | tier、stream suffix、TopN 截断、资源成本不一致。 | 建立语义回归测试和配置证据。[INFERRED, HIGH]                          |
| Replay 不确定            | High     | BookHash 依赖 map iteration 或 wall clock。      | Replay Gate 和 deterministic hash 规则。[COMMON, HIGH]                |
| options depth 口径误读   | Medium   | spec 写 Done 但 options 仍待 Phase 2。           | 标记 not_applicable/postponed 或补 payload evidence。[INFERRED, HIGH] |

---

## 11. 不执行清单

以下事项不应在当前报告任务中执行。[FRAME, HIGH]

```text
不创建 module/orderbook/
不创建 github.com/ZoneCNH/orderbook
不修改 /home/workspace/binance runtime 源码
不新增 binance internal/client/policy/PolicyManager
不把 Feature Engine / Market State Engine 加入 binance
不并行启动 OKX / Bybit adapter
不宣称 orderbook 独立模块已经存在
```

---

## 12. 下一步建议

第一步：用本报告作为准入 ADR 输入，要求维护者明确是否启动 `orderbook` 新模块双闸门审批。[FRAME, HIGH]

第二步：在 binance 仓优先处理 combined stream 分片、DepthLevel 语义回归和 options depth 口径，避免把已有 runtime 风险迁移到新模块。[FRAME, HIGH]

第三步：在授权后再进入 `module/orderbook/` 规格创建；规格通过前不得创建 runtime repo。[FRAME, HIGH]

第四步：runtime repo 只实现最小 contract、builder、event、replay、quality 和 conformance，不承载策略、下单、账户或 alpha 研究逻辑。[FRAME, HIGH]

---

[RULES I BROKE]：无
