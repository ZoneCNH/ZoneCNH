# domain-market 完整实现功能清单

- Status: Generated（与 [SPEC.md](./SPEC.md) 同步抽取，未经 pipeline-arbiter 校验）
- Last-Updated: 2026-06-18
- Source: [SPEC.md](./SPEC.md) · [TRACEABILITY.md](./TRACEABILITY.md) · [goal.md](./goal.md)
- Scale: 17 FR · 7 BR · 0 NFR

> 本文档是 domain-market **要完整实现的、可勾选的功能清单**，把 SPEC 的 FR/BR/NFR 展开成具体可验收的功能点。
> 它不是 Why（goal.md）、不是规格（SPEC.md）、不是追溯矩阵（TRACEABILITY.md）。
> 实现状态以本清单勾选为准；任一未勾选项存在即视为未完整实现。

勾选图例：`[ ]` 待实现 · `[x]` 已实现并通过对应 TC · `[~]` 部分实现（须在备注列注明缺口）

---

## 1. 功能需求（FR）

- [ ] **FR-MKT-001** 市场价格、数量、成交量、金额、费率等公开金融字段必须使用 `decimalx.Decimal` 或值对象。
- [ ] **FR-MKT-002** Tick、Quote、Bar、OrderBook 必须校验 symbol、timestamp、价格/数量边界和 bid/ask 关系。
- [ ] **FR-MKT-003** MarketDataQuality 必须 fail-closed，拒绝 dirty、stale、time-invalid 数据。
- [ ] **FR-MKT-004** Instrument 必须表达交易品种标识、市场类型、价格/数量精度和可交易状态。
- [ ] **FR-MKT-005** Funding、OpenInterest、LongShortRatio 必须有明确时间语义与数据来源。
- [ ] **FR-MKT-006** DataProvider contract 必须返回领域模型，不暴露 HTTP/WS/DB/vendor DTO。
- [ ] **FR-MKT-007** 与 `domainx` 重叠的订单枚举必须迁出或废弃，避免双 SSOT。
- [ ] **FR-MKT-015** ProductLine 枚举必须覆盖 spot、um_perp、cm_perp、option 四产品线，提供 IsValid 校验。
- [ ] **FR-MKT-016** InstrumentKey 必须提供无碰撞标的身份，Symbol 不是全局唯一键。
- [ ] **FR-MKT-017** MarketFactEnvelope 必须定义 canonical wrapper 与时间语义。
- [ ] **FR-MKT-008** quality-gate
- [ ] **FR-MKT-009** quality-metrics
- [ ] **FR-MKT-010** provider-contract
- [ ] **FR-MKT-011** stale-gate
- [ ] **FR-MKT-012** future-gate
- [ ] **FR-MKT-013** domain-no-transport
- [ ] **FR-MKT-014** domainx-boundary

## 2. 业务规则（BR）

- [ ] **BR-MKT-001** 所有价格/数量/金额/费率字段使用 decimalx.Decimal，Public API 禁止 float64
- [ ] **BR-MKT-002** domain struct 不含 transport/persistence/vendor tag
- [ ] **BR-MKT-003** 非法数据默认拒绝，不做静默修正（fail-closed）
- [ ] **BR-MKT-004** 策略层不直接消费 Bar/Tick 原始结构体，必须通过 MarketEventEnvelope
- [ ] **BR-MKT-005** stale/future 数据 fail-closed，DegradeReason + metrics 暴露，不可靠数据不静默进入策略
- [ ] **BR-MKT-006** domain-market 仅表达行情语义，订单生命周期语义归 domainx
- [ ] **BR-MKT-008** canonical event type 使用 exchange-neutral 命名；vendor stream 名称不得成为领域事件枚举

## 3. 非功能需求（NFR）

> SPEC 中未抽取到 `NFR-` 编号；请人工对照 SPEC §11 非功能需求补全（如有）。

---

## 4. 完整实现判定

本清单 §1-§3 全部 `[x]` 勾选 + ACCEPTANCE.md 全部 TC 通过 + SPEC §19 验收门禁通过 + pipeline-arbiter 翻转 Approved。

## 5. 明确不做

参见 [SPEC.md](./SPEC.md) §4 非目标章节。domain-market 只承担 SPEC 范围内的能力，不做范围外业务语义/集成编排/跨模块横切。

