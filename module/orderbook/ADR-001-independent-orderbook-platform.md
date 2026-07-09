# ADR-001: orderbook 独立订单簿事实链模块准入

> 状态：Accepted
> 日期：2026-07-09
> 决策者：ZoneCNH
> 授权依据：用户在本会话明确授权“执行全部待完成任务，目标实现完整 OrderBook 模块”
> 关联报告：`report/OrderBook/ORDERBOOK-EXECUTION-PLAN-20260709.md`

---

## 1. 决策

批准创建 `orderbook` 模块规格目录与本地 runtime 库仓 `/home/workspace/orderbook`。[FRAME, HIGH]

`orderbook` 首版定位为跨 venue 订单簿事实链 contract + library runtime，不是交易所 C/S adapter，也不是策略、因子或执行模块。[FRAME, HIGH]

`module/registry.yaml` 初始登记为 `lifecycle: proposed`；只有 runtime CI、首个 release 和证据闭环完成后才能申请 `active`。[COMPUTED, HIGH]

---

## 2. 奥卡姆三条件

| 条件 | 结论 |
| --- | --- |
| 必要性 | Binance 已有 OrderBook runtime，但通用 BookBuilder、SequencePolicy、BookHash、Replay 和 Conformance Gate 若继续留在 `binance/internal`，后续 OKX/Bybit 等 venue 会重复实现。[INFERRED, HIGH] |
| 唯一性 | `domain_market` 拥有 canonical OrderBook model；`domain_exchange` 拥有 venue SPI；`binance` 拥有 Binance adapter；三者都不应拥有跨 venue replay/conformance runtime。[COMPUTED, HIGH] |
| 净收益 | 新模块增加一个 proposed registry 条目和 runtime 库维护成本，但换来确定性 replay、gap gate、adapter conformance 和跨 venue contract SSOT，净收益为 positive。[INFERRED, HIGH] |

---

## 3. 边界

| Owns | Excludes |
| --- | --- |
| Snapshot + diff alignment contract。[FRAME, HIGH] | Binance/OKX/Bybit 私有 REST/WS endpoint。[FRAME, HIGH] |
| SequencePolicy、ExchangeSemantics、BookBuilder、BookHash。[FRAME, HIGH] | `domain_market` canonical value object 所有权。[COMPUTED, HIGH] |
| ReplayRunner、GapEvent、QualityEvent、Adapter Conformance Gate。[FRAME, HIGH] | alpha、factor、market regime、execution decision。[INFERRED, HIGH] |
| Boundary/Replay/Gap/Evidence gate 脚本。[FRAME, HIGH] | 下单、账户、订单生命周期和资金语义。[INFERRED, HIGH] |

---

## 4. 依赖与命名

模块名为 `orderbook`，符合 snake_case。[COMPUTED, HIGH]

首版 runtime 使用 Go 标准库实现 deterministic decimal canonicalization，避免在准入首日扩大依赖边。[FRAME, HIGH]

未来可通过 ADR 评估是否引入 `decimalx`、`domain_market` 和 `domain_exchange` 作为 public contract 依赖。[FRAME, MED]

---

## 5. 替代方案

| 方案 | 处理 |
| --- | --- |
| 继续只在 `binance` 内硬化 | 保留为短期兼容策略，但不足以形成跨 venue conformance SSOT。[INFERRED, HIGH] |
| 放入 `domain_market` | 拒绝；`domain_market` 是模型 SSOT，不应拥有 replay runtime。[COMPUTED, HIGH] |
| 放入 `domain_exchange` | 拒绝；`domain_exchange` 是 venue SPI，不应拥有 book mutation runtime。[COMPUTED, HIGH] |
| 直接做独立进程 | 延后；首版先 library，避免 premature process boundary。[INFERRED, HIGH] |

---

## 6. 后置条件

1. `module/orderbook/spec/SPEC.md` 必须覆盖 FR/BR/AC。[FRAME, HIGH]
2. `/home/workspace/orderbook` 必须通过 `go test ./...`。[FRAME, HIGH]
3. Boundary gate 必须阻断 `binance/internal`、`okx/internal` 等 venue internal import。[FRAME, HIGH]
4. Replay gate 必须证明同一 fixture 100 次 hash 一致。[FRAME, HIGH]
5. Gap gate 必须证明 sequence break 会产生 `reliable=false` quality。[FRAME, HIGH]

---

[RULES I BROKE]：无
