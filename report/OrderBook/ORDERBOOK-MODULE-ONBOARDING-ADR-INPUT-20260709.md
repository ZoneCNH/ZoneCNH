# orderbook 模块准入 ADR 输入包

> 日期：2026-07-09
> 状态：Pre-ADR Input / 非正式 ADR
> 目标：为后续 `ADR-MODULE-ONBOARDING` 提供可审输入
> 约束：本文不等于治理层审批，不授权创建 `module/orderbook/` 或 `github.com/ZoneCNH/orderbook`
> 来源：`knowledge/OrderBook.md`、`report/OrderBook/ORDERBOOK-EXECUTION-PLAN-20260709.md`、`docs/governance/module-governance/06-module-onboarding.md`

---

## 0. 决策前提

本文件是准入 ADR 的输入材料，不是正式 ADR，也不改变 `module/registry.yaml`。[FRAME, HIGH]

当前未发现 `orderbook` 已作为独立模块登记在 `module/registry.yaml` 中。[COMPUTED, HIGH]

创建 `module/orderbook/` 和 `github.com/ZoneCNH/orderbook` 需要治理层审批与当前会话人工显式授权两个闸门同时满足。[COMPUTED, HIGH]

本输入包的建议状态是：`Proposed for review`，不得写成 `Accepted`。[FRAME, HIGH]

---

## 1. 问题陈述

binance 已经拥有 OrderBook runtime 的首个实现，包括本地 book、snapshot 对齐、序号校验、重建、TopN/增量输出、持久化和健康监控。[COMPUTED, HIGH]

这些能力具有跨交易所复用潜力，因为 Binance、OKX、Bybit 等 venue 都需要 snapshot/diff 语义适配、gap 处理、replay、quality 和 conformance 证明。[INFERRED, HIGH]

如果长期把通用微观结构 runtime 留在 `binance/internal/client/orderbook/`，后续 venue 接入可能重复实现 BookBuilder、GapDetector、Replay、BookHash、Quality Gate 和 Adapter Conformance。[INFERRED, HIGH]

反论证同样成立：目前只有 binance 的完整实现证据最充分，第二 venue 需求尚未在本次核验中被证明已 materialized，过早建独立模块会增加维护和认知成本。[INFERRED, HIGH]

因此，正式 ADR 应把问题限定为“是否先准入一个 proposed 状态的 orderbook 规格模块”，而不是直接批准 runtime 仓库创建或代码迁移。[FRAME, HIGH]

---

## 2. 奥卡姆剃刀三条件

### 2.1 必要性

不新增 `orderbook` 时，短期可以继续由 binance 承担 OrderBook runtime。[INFERRED, HIGH]

不新增 `orderbook` 的长期代价是：跨 venue 的 replay、gap fixture、BookHash、quality flags 和 conformance gate 缺少独立 contract，可能在每个采集器中重复或漂移。[INFERRED, HIGH]

必要性成立的前提条件是：至少存在第二 venue adapter 或明确的跨 venue 研究/执行需求，需要复用同一套 OrderBook contract 与 gate。[INFERRED, HIGH]

若没有第二 venue 或跨 venue 消费需求，必要性不足，应该继续在 binance 内硬化而不是新增模块。[INFERRED, HIGH]

### 2.2 唯一性

| 现有模块               | 能承担的部分                                                                     | 不能承担的部分                                                         | 结论                                                                           |
| ---------------------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `domain_market`        | `OrderBook`、`PriceLevel`、`MarketDataQuality` canonical model。[COMPUTED, HIGH] | WS 订阅、snapshot 对齐、gap recovery、replay runtime。[INFERRED, HIGH] | 不适合承担 runtime platform。[INFERRED, HIGH]                                  |
| `domain_exchange`      | Venue SPI、capability、rate limit、exchange error。[COMPUTED, HIGH]              | 本地 book rebuild、BookEvent store、Replay Gate。[INFERRED, HIGH]      | 适合作为 adapter contract 依赖，不适合拥有 OrderBook runtime。[INFERRED, HIGH] |
| `binance`              | Binance 私有 REST/WS adapter、当前 OrderBook v0 runtime。[COMPUTED, HIGH]        | 跨交易所通用 runtime 和 conformance 平台。[INFERRED, HIGH]             | 可作为首个 adapter，不应长期成为通用平台 SSOT。[INFERRED, HIGH]                |
| `market_data`          | 行情接收、校验、排序、分发。[INFERRED, MED]                                      | 微观结构状态机、BookHash、跨 venue replay conformance。[INFERRED, MED] | 可消费或路由，不宜内嵌平台。[INFERRED, MED]                                    |
| `factor_engine`        | 因子和特征研究。[INFERRED, HIGH]                                                 | 原始 depth 采集、snapshot/diff 对齐、gap recovery。[INFERRED, HIGH]    | 消费 orderbook 输出，不拥有底层事实链。[INFERRED, HIGH]                        |
| `execution` / `orderx` | 执行策略、下单、订单生命周期。[INFERRED, HIGH]                                   | 交易所行情重建与事实链治理。[INFERRED, HIGH]                           | 消费质量标注后的执行深度状态。[INFERRED, HIGH]                                 |

唯一性判断：`orderbook` 的唯一职责应限定为“跨 venue 订单簿事实链 runtime contract + replay/conformance gate”，不得扩张为市场状态解释、alpha 研究或执行策略模块。[FRAME, HIGH]

### 2.3 净收益

潜在收益包括：减少多交易所重复实现、统一 replay evidence、统一 gap fixture、统一 BookHash/FeatureHash 确定性规则、统一 adapter conformance gate。[INFERRED, HIGH]

新增成本包括：新增模块治理、依赖矩阵维护、runtime 仓 CI/release、binance 迁移成本、跨域契约协调和模块认知成本。[INFERRED, HIGH]

净收益为正的门槛是：完成 binance 前置硬化、冻结最小 contract、取得双闸门授权，并至少用 Binance + 第二 venue POC 证明 contract 不只是 Binance 包装。[FRAME, HIGH]

在只有 Binance 一个实现的阶段，净收益判断最多是 `conditional positive`，不应写成无条件通过。[INFERRED, HIGH]

---

## 3. 边界声明草案

### 3.1 拟拥有

`orderbook` 拟拥有跨 venue OrderBook sync state machine contract。[FRAME, HIGH]

`orderbook` 拟拥有 BookEvent、GapEvent、QualityEvent、BookHash 和 replay fixture schema。[FRAME, HIGH]

`orderbook` 拟拥有 Adapter Conformance Gate、Replay Determinism Gate、Gap Injection Gate 和 Boundary Gate。[FRAME, HIGH]

`orderbook` 拟拥有通用 BookBuilder、BookMutationEngine、ReplayRunner、QualityFlag 和 StalenessPolicy 的 runtime 实现。[FRAME, MED]

`orderbook` 拟拥有 deterministic primitive feature 的 contract，但不拥有 alpha/factor 研究语义。[FRAME, MED]

### 3.2 明确不拥有

| 排除职责                              | 委派方                                    | 理由                                                     |
| ------------------------------------- | ----------------------------------------- | -------------------------------------------------------- |
| Binance/OKX/Bybit 私有 REST/WS 协议   | `binance`、未来 `okx`、未来 `bybit`       | 交易所私有协议属于具体采集器。[INFERRED, HIGH]           |
| canonical market model                | `domain_market`                           | `domain_market` 是市场语义模型 SSOT。[COMPUTED, HIGH]    |
| venue capability / exchange error SPI | `domain_exchange`                         | 交易所 SPI 不应混入 runtime 实现。[INFERRED, HIGH]       |
| 行情采集白名单 server API             | `binance` server 或对应 venue server      | server 白名单链路属于采集器控制面。[COMPUTED, HIGH]      |
| 因子计算与研究评估                    | `factor_engine`                           | 因子研究属于分析域。[INFERRED, HIGH]                     |
| 市场状态解释                          | `market_regime` 或后续专用模块            | Market State 是解释层，不是底层事实链。[INFERRED, HIGH]  |
| 下单、订单生命周期、账户私有流        | `execution` / `orderx` / venue 私有流模块 | 执行和账户职责不属于 OrderBook runtime。[INFERRED, HIGH] |
| portfolio / strategy decision         | 决策域模块                                | 策略决策不应进入数据事实链模块。[INFERRED, HIGH]         |

---

## 4. 依赖审查草案

### 4.1 拟依赖

| 依赖目标          | 预期用途                                                                            | 风险                                         |
| ----------------- | ----------------------------------------------------------------------------------- | -------------------------------------------- |
| `kernel`          | 基础错误、时间、ID、生命周期原语。[INFERRED, MED]                                   | 低。[INFERRED, MED]                          |
| `decimalx`        | 价格和数量的确定性 decimal canonicalization。[INFERRED, HIGH]                       | 必须避免 float 污染 BookHash。[COMMON, HIGH] |
| `domain_market`   | `OrderBook`、`PriceLevel`、`MarketDataQuality` 等 canonical model。[COMPUTED, HIGH] | 不得反向依赖 `orderbook`。[FRAME, HIGH]      |
| `domain_exchange` | Adapter SPI、venue semantics、rate limit 表达。[COMPUTED, HIGH]                     | 不得塞入 venue 私有实现。[FRAME, HIGH]       |
| `configx`         | 配置解析和 schema。[INFERRED, MED]                                                  | 中低。[INFERRED, MED]                        |
| `observex`        | metrics / tracing / logging contract。[INFERRED, MED]                               | 中低。[INFERRED, MED]                        |
| `resiliencx`      | retry/backoff/circuit breaker contract。[INFERRED, MED]                             | 中低。[INFERRED, MED]                        |
| `testkitx`        | fixture、conformance、determinism tests。[INFERRED, MED]                            | 中低。[INFERRED, MED]                        |

### 4.2 不建议首版依赖

首版不建议直接依赖 `natsx`、`kafkax`、`clickhousex` 或 `ossx`，除非发布层被抽象为可选 adapter。[INFERRED, HIGH]

首版不建议依赖 `factor_engine`、`execution`、`orderx`、`market_regime`，因为这会把数据事实链模块反向耦合到消费方。[INFERRED, HIGH]

### 4.3 登记位置

`orderbook` 若作为业务域 runtime platform 准入，应先登记到 `module/registry.yaml`，并在业务域依赖矩阵中声明依赖边。[INFERRED, MED]

若治理层决定把 `orderbook` 归入 L2.5 或 foundation-adjacent contract，则还需要同步评估 `module/FOUNDATION-DEPS.yaml` 扩展范围。[INFERRED, MED]

---

## 5. 命名审批草案

推荐模块名为 `orderbook`。[FRAME, HIGH]

`orderbook` 符合 snake_case 仓库命名规则。[COMPUTED, HIGH]

`orderbook` 不属于 `x.go` 或 `binance.rs` 例外。[COMPUTED, HIGH]

命名风险：`06-module-onboarding.md` 的命名模式表没有明确列出“业务域 runtime platform”的模式，`orderbook` 也不是 `<exchange>`、`domain_<name>` 或 `<name>x`。[COMPUTED, HIGH]

建议正式 ADR 将命名审批写为“其他模式：业务域 runtime platform”，并要求治理层明确接受该命名模式，避免以默认规则偷渡。[INFERRED, HIGH]

---

## 6. 架构类型选择草案

推荐首版 arch_type 为 `contract` 或 `library`，而不是立即选择 `independent_process`。[INFERRED, HIGH]

理由是首版目标应冻结 contract、schema、replay gate 和 adapter conformance，不应先创建独立进程和部署面。[FRAME, HIGH]

当 runtime repo 获授权并实现 worker 后，可再从 `library/contract` 演进为 `independent_process` 或拆分出 `cmd/orderbook-worker`。[INFERRED, MED]

如果正式 ADR 直接选择 `independent_process`，必须额外证明部署、SLO、storage、publish、backpressure 和 release evidence 已有可执行方案。[FRAME, HIGH]

---

## 7. 替代方案

### 方案 A：不新增模块，继续在 binance 内硬化

优点：不增加模块和仓库，能最快修复 combined stream 分片、DepthLevel 语义、options depth 口径和 replay fixture。[INFERRED, HIGH]

缺点：跨 venue contract 仍缺少独立 SSOT，后续 OKX/Bybit 可能复制 Binance 内部实现。[INFERRED, HIGH]

适用条件：第二 venue 需求未确认，或双闸门授权未通过。[FRAME, HIGH]

### 方案 B：只抽共享 contract，不创建 runtime repo

优点：能先冻结 BookEvent、SequencePolicy、Replay Gate 和 Adapter Conformance，同时避免过早迁移 runtime。[INFERRED, HIGH]

缺点：通用 BookBuilder、ReplayRunner 和 Quality Engine 仍暂留 binance 或测试工具中。[INFERRED, MED]

适用条件：治理层愿意批准规格模块，但暂不批准 runtime 仓库。[FRAME, HIGH]

### 方案 C：创建 `orderbook` 独立模块和 runtime repo

优点：能把通用 runtime 从 Binance 中剥离，形成跨 venue 事实链平台。[INFERRED, HIGH]

缺点：成本最高，需要双闸门授权、CI/release、迁移兼容、下游 contract 稳定和至少一个 adapter POC。[INFERRED, HIGH]

适用条件：双闸门授权通过，且 Phase 1/Phase 3/Phase 4 门禁已完成。[FRAME, HIGH]

### 方案 D：放入 `market_data`

优点：减少一个独立模块，行情链路上更集中。[INFERRED, MED]

缺点：容易把 market data 分发职责和微观结构 runtime/replay 职责混在一起。[INFERRED, HIGH]

不推荐原因：OrderBook replay/conformance 的复杂度可能使 `market_data` 变厚，削弱模块边界。[INFERRED, HIGH]

---

## 8. 推荐 ADR 结论草案

推荐正式 ADR 的结论写成：批准进入 `orderbook` 模块准入评审，不直接批准 runtime repo 创建。[FRAME, HIGH]

正式 ADR 应把首个里程碑限定为 `module/orderbook` 规格与 gate 文档，且仅在双闸门授权齐备后创建。[FRAME, HIGH]

runtime repo 创建应成为单独里程碑，依赖 SPEC Approved、Gate 文档完成、Binance conformance fixture 通过和维护者显式授权。[FRAME, HIGH]

---

## 9. 最小实施计划

| 里程碑 | 目标                  | 验收                                                                                    |
| ------ | --------------------- | --------------------------------------------------------------------------------------- |
| M0     | 完成准入 ADR 审查     | ADR 状态由维护者明确决定，不由 agent 自行 Accepted。[FRAME, HIGH]                       |
| M1     | 解决 binance 前置硬化 | combined stream 分片、DepthLevel 语义、options depth 口径有证据。[FRAME, HIGH]          |
| M2     | 授权后创建规格目录    | `module/orderbook/` 仅含 Goal/Spec/Contract/State/Event/Matrix/Gate 文档。[FRAME, HIGH] |
| M3     | 冻结最小 contract     | BookEvent、BookHash、SequencePolicy、Replay Gate、Adapter Gate 可审。[FRAME, HIGH]      |
| M4     | Binance fixture       | Binance adapter conformance fixture 可重复运行。[FRAME, HIGH]                           |
| M5     | 再评估 runtime repo   | 依据 M1-M4 证据决定是否创建 `github.com/ZoneCNH/orderbook`。[FRAME, HIGH]               |

---

## 10. 阻断条件

若没有双闸门授权，必须阻断任何 `module/orderbook/` 和 runtime repo 创建。[COMPUTED, HIGH]

若没有 combined stream 分片与资源上限治理，必须阻断 symbol 扩量和多 venue 扩展。[INFERRED, HIGH]

若没有 BookHash/Replay Gate，必须阻断“可复现研究事实链”声明。[COMMON, HIGH]

若没有第二 venue conformance 证据，必须阻断“跨交易所平台已成立”声明。[INFERRED, HIGH]

若 Feature Engine 需要 alpha/factor/market-state 语义，必须阻断其进入 binance 采集层。[INFERRED, HIGH]

---

## 11. 正式 ADR 待补证据

| 待补证据                       | 来源                                             | 阻断程度             |
| ------------------------------ | ------------------------------------------------ | -------------------- |
| 第二 venue 需求或 POC 计划     | 维护者 / roadmap                                 | 高。[INFERRED, HIGH] |
| combined stream 分片设计与测试 | binance runtime                                  | 高。[COMPUTED, HIGH] |
| options depth 口径             | binance testnet / 官方 payload capture           | 中。[INFERRED, HIGH] |
| BookHash canonicalization 规则 | `decimalx` / `domain_market` / proposed contract | 高。[COMMON, HIGH]   |
| runtime repo owner 与维护预算  | 维护者                                           | 高。[INFERRED, HIGH] |
| 命名模式审批                   | 治理层                                           | 中。[COMPUTED, HIGH] |

---

[RULES I BROKE]：无
