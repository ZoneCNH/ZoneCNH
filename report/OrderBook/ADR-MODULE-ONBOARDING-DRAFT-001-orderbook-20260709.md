# ADR-MODULE-ONBOARDING-DRAFT-001: orderbook 模块准入决策草案

> 状态：Proposed Draft / 未审批
> 日期：2026-07-09
> 决策者：待维护者指定
> 关联：`knowledge/OrderBook.md`、`report/OrderBook/ORDERBOOK-EXECUTION-PLAN-20260709.md`
> 宪法条款：§2.5 模块增殖约束；§2.6 模块与仓库创建授权；§7 命名规范
> 仓库归属：若获授权，正式 ADR 应归 ZoneCNH 主仓 `module/orderbook/`；当前仅为 `report/OrderBook/` 草案

---

## 0. 状态声明

本文是正式准入 ADR 的草案，不是 Accepted ADR。[FRAME, HIGH]

本文不授权创建 `module/orderbook/`，不授权创建 `github.com/ZoneCNH/orderbook`，不修改 `module/registry.yaml`。[COMPUTED, HIGH]

若后续治理层审批与人工显式授权齐备，本文可迁移为 `module/orderbook/ADR-001-independent-orderbook-platform.md` 或等效路径。[FRAME, HIGH]

---

## 1. 背景

`knowledge/OrderBook.md` 提出将 OrderBook 从 `binance/internal/client/orderbook/` 抽象为跨交易所 Market Microstructure Runtime Platform。[COMPUTED, HIGH]

binance 当前已经实现 OrderBook runtime 的首个版本，包括本地 book、snapshot 对齐、序号校验、auto rebuild、TopN/Incremental 输出、持久化和 checksum drift 检测。[COMPUTED, HIGH]

这些能力具有跨 venue 复用价值，但目前只有 Binance 侧证据最完整，第二 venue 需求或 POC 证据尚未在本次工作中验证。[INFERRED, HIGH]

宪法 §2.6 要求新 `module/{模块名}/` 与新 ZoneCNH 仓库创建必须先通过治理层审批和人工显式授权。[COMPUTED, HIGH]

---

## 2. 决策

建议批准 `orderbook` 进入新模块准入评审，但不在本 ADR 草案中批准 runtime repo 创建。[FRAME, HIGH]

建议首个审批目标限定为 `module/orderbook/` 规格制品和 gate 制品，而不是代码迁移。[FRAME, HIGH]

建议在 binance 完成 Phase 1 前置硬化后，再决定是否创建 `github.com/ZoneCNH/orderbook` runtime repo。[FRAME, HIGH]

---

## 3. 奥卡姆剃刀三条件

### 3.1 必要性

必要性有条件成立：如果 ZoneCNH 将接入第二 venue 或要求跨 venue replay/conformance，则独立 `orderbook` contract 能防止每个采集器重复实现 OrderBook 事实链能力。[INFERRED, HIGH]

必要性不应无条件成立：如果未来 90 天仍只有 Binance 一个 venue 使用完整 OrderBook runtime，则应继续在 binance 内硬化，而不是创建独立 runtime 仓库。[INFERRED, HIGH]

### 3.2 唯一性

`domain_market` 拥有 canonical market model，但不拥有 runtime state machine、gap recovery 或 replay gate。[COMPUTED, HIGH]

`domain_exchange` 拥有 venue SPI，但不拥有本地 order book rebuild runtime。[COMPUTED, HIGH]

`binance` 拥有 Binance 私有 adapter 和当前实现，但不应长期成为跨交易所 OrderBook 平台的 SSOT。[INFERRED, HIGH]

`factor_engine`、`market_regime`、`execution` 和 `orderx` 应消费 OrderBook 事实链，不应拥有底层 snapshot/diff 对齐和 gap recovery。[INFERRED, HIGH]

唯一性建议：`orderbook` 只拥有跨 venue 订单簿事实链 contract、runtime core、replay/conformance gate，不拥有策略、下单、账户或 alpha 研究逻辑。[FRAME, HIGH]

### 3.3 净收益

潜在收益是统一 BookEvent、BookHash、GapEvent、QualityEvent、Replay Gate 和 Adapter Conformance Gate。[INFERRED, HIGH]

主要成本是新增模块治理、依赖审查、CI/release、binance 迁移兼容、第二 venue 验证和长期维护预算。[INFERRED, HIGH]

净收益判断为 `conditional positive`：只有 Phase 1 binance 前置硬化完成、最小 contract 冻结、双闸门授权齐备，并至少规划第二 venue conformance POC 后，净收益才足以支撑 runtime repo 创建。[FRAME, HIGH]

---

## 4. 范围

| 范围内 | 范围外 |
| --- | --- |
| Adapter Contract：SnapshotLoader、DiffSubscriber、SequencePolicy、ExchangeSemantics。[FRAME, HIGH] | Binance/OKX/Bybit 私有 REST/WS 实现。[FRAME, HIGH] |
| BookEvent、GapEvent、QualityEvent、BookHash。[FRAME, HIGH] | 因子研究、市场状态解释、策略决策。[FRAME, HIGH] |
| Replay Determinism Gate、Gap Injection Gate、Adapter Conformance Gate。[FRAME, HIGH] | 下单、订单生命周期、账户私有流。[FRAME, HIGH] |
| 通用 BookBuilder、BookMutationEngine、ReplayRunner、QualityFlag。[FRAME, MED] | C/S 白名单 server API 和 venue 控制面。[FRAME, HIGH] |

---

## 5. 替代方案

### 方案 A：不新增模块，继续在 binance 内硬化

优点是复杂度最低，能最快修复 combined stream 分片、DepthLevel 语义和 options depth 口径。[INFERRED, HIGH]

缺点是跨 venue contract 继续缺少独立 SSOT，后续 venue 可能复制 Binance 内部实现。[INFERRED, HIGH]

未选择为最终方向的原因：它不能解决长期跨 venue replay/conformance 漂移问题。[INFERRED, HIGH]

### 方案 B：只建规格模块，不建 runtime repo

优点是先冻结 contract、schema、gate 和 traceability，避免过早迁移代码。[INFERRED, HIGH]

缺点是通用 runtime 仍暂留 binance，迁移收益后置。[INFERRED, MED]

推荐作为第一阶段方案。[FRAME, HIGH]

### 方案 C：直接创建 runtime repo 并迁移 binance

优点是可以立即剥离通用 runtime。[INFERRED, MED]

缺点是绕过前置 hardening 和第二 venue 验证，容易产生 Binance 包装版新模块。[INFERRED, HIGH]

不推荐当前采用。[FRAME, HIGH]

### 方案 D：放入 `market_data`

优点是减少模块数量。[INFERRED, MED]

缺点是把行情分发和微观结构 runtime/replay 混在一起，容易形成过厚数据域模块。[INFERRED, HIGH]

不推荐采用。[FRAME, HIGH]

---

## 6. 依赖与命名

推荐模块名：`orderbook`。[FRAME, HIGH]

`orderbook` 符合 snake_case 仓库命名规则，但不属于现有 `<name>x`、`domain_<name>` 或 `<exchange>` 常规模板，需要治理层明确接受“业务域 runtime platform”命名模式。[COMPUTED, HIGH]

推荐首版 arch_type 为 `contract` 或 `library`，后续 runtime repo 获授权后再评估 `independent_process`。[INFERRED, HIGH]

拟依赖：`kernel`、`decimalx`、`domain_market`、`domain_exchange`、`configx`、`observex`、`resiliencx`、`testkitx`。[INFERRED, MED]

首版不建议直接依赖 `factor_engine`、`execution`、`orderx`、`market_regime`、`natsx`、`kafkax`、`clickhousex` 或 `ossx`，除非它们被放在可选 adapter 层。[INFERRED, HIGH]

---

## 7. 后果

### 正面影响

统一 OrderBook 事实链 contract，降低多 venue 实现漂移概率。[INFERRED, HIGH]

统一 replay evidence 与 conformance gate，使研究和实盘消费更容易共享可验证输入。[INFERRED, HIGH]

把 binance 长期职责收敛为 Binance adapter，降低采集器内的通用平台膨胀。[INFERRED, HIGH]

### 负面影响

新增模块会增加治理、CI、release、owner 和依赖维护成本。[INFERRED, HIGH]

若第二 venue 不出现，`orderbook` 可能成为过早抽象。[INFERRED, HIGH]

binance 迁移会带来兼容性风险，尤其是 NATS/Kafka downstream contract 和 staleness 语义。[INFERRED, HIGH]

### 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
| --- | --- | --- | --- |
| 未授权创建目录或仓库 | 中 | 高 | §2.6 双闸门前只保留报告草案。[COMPUTED, HIGH] |
| 过早 runtime repo | 中 | 高 | 先做规格模块和 gate，runtime repo 单独审批。[FRAME, HIGH] |
| Binance 包装版模块 | 中 | 高 | 第二 venue conformance POC 后再宣称跨 venue。[INFERRED, HIGH] |
| 采集层塞入 Feature/Market State | 中 | 高 | 明确委派给 `factor_engine` / `market_regime`。[INFERRED, HIGH] |
| BookHash 不确定 | 中 | 高 | decimal canonicalization + Replay Determinism Gate。[COMMON, HIGH] |

---

## 8. 实施计划

| 里程碑 | 目标 | 验收 |
| --- | --- | --- |
| M0 | 完成 binance Phase 1 前置硬化 | combined stream 分片、DepthLevel 语义、options 口径、replay fixture input 有证据。[FRAME, HIGH] |
| M1 | 准入 ADR 正式审查 | 维护者决定 Proposed/Accepted/Rejected，不由 agent 自行翻转。[FRAME, HIGH] |
| M2 | 授权后创建规格目录 | `module/orderbook/` 仅含 Goal/Spec/Contract/State/Event/Matrix/Gate 文档。[FRAME, HIGH] |
| M3 | 冻结最小 contract | BookEvent、BookHash、SequencePolicy、Replay Gate、Adapter Gate 可审。[FRAME, HIGH] |
| M4 | Binance conformance fixture | Binance fixture 可重复通过 gate。[FRAME, HIGH] |
| M5 | 再评估 runtime repo | 依据 M0-M4 证据决定是否创建 `github.com/ZoneCNH/orderbook`。[FRAME, HIGH] |

---

## 9. 约束

未满足双闸门授权前，禁止创建 `module/orderbook/`。[COMPUTED, HIGH]

未满足双闸门授权前，禁止创建 `github.com/ZoneCNH/orderbook` 或 `/home/workspace/orderbook`。[COMPUTED, HIGH]

正式 ADR 未 Accepted 前，不得修改 `module/registry.yaml` 登记 `orderbook`。[FRAME, HIGH]

runtime repo 未获授权前，不得把 binance runtime 代码迁移到新仓。[FRAME, HIGH]

---

## 10. 参考

- `knowledge/OrderBook.md`
- `report/OrderBook/ORDERBOOK-EXECUTION-PLAN-20260709.md`
- `report/OrderBook/ORDERBOOK-MODULE-ONBOARDING-ADR-INPUT-20260709.md`
- `report/OrderBook/ORDERBOOK-BINANCE-PHASE1-HARDENING-PLAN-20260709.md`
- `docs/governance/module-governance/06-module-onboarding.md`
- `docs/constitution/02-module-boundaries.md`
- `module/binance/design/ADR-011-order-book-rebuild-inclusion.md`

---

[RULES I BROKE]：无
