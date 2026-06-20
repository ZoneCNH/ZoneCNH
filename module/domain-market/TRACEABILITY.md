# domain_market 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-16
Source: module/domain_market/SPEC.md

---

## §1 FR Traceability

| FR ID | Requirement | AC ID(s) | TC ID(s) | Verification | Status |
|-------|-------------|----------|----------|--------------|--------|
| FR-MKT-001 | decimal-precision：定义价格/数量/金额/费率字段时使用 `decimalx.Decimal` 或值对象，Public API 禁止 `float64` | AC-MKT-001 | TC-MKT-001 | `go vet` + `staticcheck` | ✅ |
| FR-MKT-002 | tick-validate：构造或校验 Tick 时 Symbol/Venue/Price/Qty/Timestamp/Side/Quality 合法 | AC-MKT-002 | TC-MKT-002 | `go test -run TestTick` | ✅ |
| FR-MKT-003 | quote-validate：构造或校验 Quote 时 bid/ask 非负，ask >= bid，timestamp 必填 | AC-MKT-002 | TC-MKT-003 | `go test -run TestQuote` | ✅ |
| FR-MKT-004 | bar-validate：构造或校验 Bar 时 High >= max(Open,Close,Low)，Low <= min(Open,Close,High)，OpenTime < CloseTime，Volume/Turnover 非负 | AC-MKT-002 | TC-MKT-003 | `go test -run TestBar` | ✅ |
| FR-MKT-005 | orderbook-validate：构造或校验 OrderBook 时 Bids 价格降序，Asks 价格升序，bid < ask，数量非负，seq 连续 | AC-MKT-002 | TC-MKT-003 | `go test -run TestOrderBook` | ✅ |
| FR-MKT-006 | instrument-validate：构造或校验 Instrument 时 precision/tick/minQty/minNotional/status 合法 | AC-MKT-004 | TC-MKT-004 | `go test -run TestInstrument` | ✅ |
| FR-MKT-007 | derivative-validate：构造或校验 Funding/OpenInterest/LongShortRatio 时时间必填，decimal 字段合法，来源质量标签完整 | AC-MKT-005 | TC-MKT-005 | `go test -run "TestFunding\ | ✅ |
| FR-MKT-008 | quality-gate：策略层消费市场数据时只能接受 MarketEventEnvelope；EventTime/ReceivedAt/Symbol/Venue 必填 | AC-MKT-003 | TC-MKT-004 | `go test -run TestMarketEventEnvelope` | ✅ |
| FR-MKT-009 | quality-metrics：校验 MarketDataQuality 时 Channel/Latency/IsReliable 与 DegradeReason 一致 | AC-MKT-003 | TC-MKT-007 | `go test -run TestMarketDataQuality` | ✅ |
| FR-MKT-010 | provider-contract：调用 DataProvider 时返回领域模型，不暴露 HTTP/WS/DB/vendor DTO | AC-MKT-006 | TC-MKT-005 | `staticcheck` boundary scan | ✅ |
| FR-MKT-011 | stale-gate：数据超过 stale threshold 时 fail-closed，拒绝 stale 数据进入策略 | AC-MKT-003 | TC-MKT-007 | `go test -run TestStaleGate` | ✅ |
| FR-MKT-012 | future-gate：EventTime 晚于 ReceivedAt/DecisionTime 时在容忍窗口外拒绝 | AC-MKT-003 | TC-MKT-008 | `go test -run TestFutureGate` | ✅ |
| FR-MKT-013 | domain-no-transport：定义 domain struct 时不含 json/db/yaml/kafka tag；transport schema 属 DTO 层 | AC-MKT-006 | TC-MKT-002 | `lint`: struct tag scan | ✅ |
| FR-MKT-014 | domainx-boundary：与 domainx 枚举归属——Side 表达市场事件方向可保留；OrderType/OrderSide/OrderState 归 domainx | AC-MKT-007 | TC-MKT-006 | `compile smoke` + ADR | ✅ |

---

## §2 BR Traceability

| BR ID | Rule | TC ID(s) | Verification | Status |
|-------|------|----------|--------------|--------|
| BR-MKT-001 | 所有价格/数量/金额/费率字段使用 `decimalx.Decimal`，Public API 禁止 `float64` | — | `go vet` + `staticcheck`：扫描所有 public 字段类型，`float64` 出现即失败 | ✅ |
| BR-MKT-002 | domain struct 不含 transport/persistence/vendor tag | — | kafka:' --include='*.go'` 在 domain 包下命中即失败 | ✅ |
| BR-MKT-003 | 非法数据默认拒绝，不做静默修正（fail-closed） | — | `go test -run TestValidate`：所有 validator 必须对非法输入返回 error，禁止 auto-fix 路径 | ✅ |
| BR-MKT-004 | 策略层不直接消费 Bar/Tick 原始结构体，必须通过 MarketEventEnvelope | — | `go test -run TestConsumerBoundary`：策略入口参数类型为 `MarketEventEnvelope`，编译期禁止裸 Bar/Tick | ✅ |
| BR-MKT-005 | stale/future 数据 fail-closed，DegradeReason + metrics 暴露，不可靠数据不静默进入策略 | — | TestFutureGate"`：stale/future 输入必须返回 error 且 DegradeReason 非空 | ✅ |
| BR-MKT-006 | domain_market 仅表达行情语义，订单生命周期语义归 domainx | — | `compile smoke`：domain_market 不得 import domainx 的 OrderType/OrderSide/OrderState | ✅ |

---

## §3 NFR Traceability

| NFR ID | Category | Requirement | Verification | Status |
|--------|----------|-------------|--------------|--------|
| NFR-MKT-001 | 质量 | 非法数据默认拒绝，不做静默修正 | `go test -run TestValidate`：所有 validator table test 覆盖 invalid cases，断言返回非 nil error | ✅ |
| NFR-MKT-002 | 领域纯净 | 公共模型中不得出现 transport、persistence 或 vendor schema tag | bson):"' --include='*.go'` 在 domain 包下零命中 | ✅ |
| NFR-MKT-003 | 下游稳定 | v1.0.0 后公共字段含义和时间语义需保持兼容 | `go test -run TestBackwardCompat` + `MIGRATION.md`：字段语义变更必须有 deprecated + migration 路径 | ✅ |

---

## §4 TC→FR Reverse

| TC ID | Covers FR(s) | Command |
|-------|-------------|---------|
| TC-MKT-001 | FR-MKT-001 | `go vet ./...` + `staticcheck ./...` 扫描 float64 使用 |
| TC-MKT-002 | FR-MKT-002, FR-MKT-013 | `lint`: struct tag scan + `go test -run TestTickValidate` |
| TC-MKT-003 | FR-MKT-003, FR-MKT-004, FR-MKT-005 | `go test -run "TestBarValidate\ |
| TC-MKT-004 | FR-MKT-006, FR-MKT-008 | `go test -run "TestInstrument\ |
| TC-MKT-005 | FR-MKT-007, FR-MKT-010 | `go test -run "TestFunding\ |
| TC-MKT-006 | FR-MKT-014 | `go build ./...`：domain_market 不 import domainx OrderType/OrderSide/OrderState |
| TC-MKT-007 | FR-MKT-009, FR-MKT-011 | `go test -run "TestMarketDataQuality\ |
| TC-MKT-008 | FR-MKT-012 | `go test -run TestFutureGate` |

---

## §5 AC Registry

| AC ID | FR/BR Ref | Criterion | Verification | Status |
|-------|-----------|-----------|-------------|--------|
| AC-MKT-001 | FR-MKT-001, BR-MKT-001 | public 金融字段采用 `decimalx.Decimal` 或值对象，Public API 不含 `float64` | (see TRACEABILITY.md §4) | ✅ |
| AC-MKT-002 | FR-MKT-002, FR-MKT-003, FR-MKT-004, FR-MKT-005 | Tick/Quote/Bar/OrderBook 各 Validate 方法对合法输入返回 nil，对非法输入返回 error | (see TRACEABILITY.md §4) | ✅ |
| AC-MKT-003 | FR-MKT-008, FR-MKT-009, FR-MKT-011, FR-MKT-012, BR-MKT-003, BR-MKT-005 | MarketEventEnvelope 校验通过才可交付策略层；stale/future/dirty 数据 fail-closed；MarketDataQuality DegradeReason 与实际状态一致 | (see TRACEABILITY.md §4) | ✅ |
| AC-MKT-004 | FR-MKT-006 | Instrument 的 precision/tick/minQty/minNotional/status 字段语义稳定，非法值在 Validate 时返回 error | (see TRACEABILITY.md §4) | ✅ |
| AC-MKT-005 | FR-MKT-007, BR-MKT-006 | Funding/OpenInterest/LongShortRatio 的 Timestamp 必填，decimal 字段合法，Quality 来源标签完整 | (see TRACEABILITY.md §4) | ✅ |
| AC-MKT-006 | FR-MKT-010, FR-MKT-013, BR-MKT-002 | DataProvider 返回类型均为 domain_market 领域模型，domain struct 不含 transport/persistence/vendor tag | (see TRACEABILITY.md §4) | ✅ |
| AC-MKT-007 | FR-MKT-014, BR-MKT-006 | 与 domainx 枚举单一归属：Side 仅表达市场事件方向可保留；OrderType/OrderSide/OrderState 归 domainx，编译期不交叉引用 | (see TRACEABILITY.md §4) | ✅ |
