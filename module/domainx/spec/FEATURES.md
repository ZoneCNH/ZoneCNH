# domainx 完整实现功能清单

- Status: Generated（与 [SPEC.md](./SPEC.md) 同步抽取，未经 pipeline-arbiter 校验）
- Last-Updated: 2026-06-30
- Source: [SPEC.md](./SPEC.md) · [TRACEABILITY.md](./TRACEABILITY.md) · [goal.md](./goal.md)
- Scale: 8 FR · 10 BR · 0 NFR

> 本文档是 domainx **要完整实现的、可勾选的功能清单**，把 SPEC 的 FR/BR/NFR 展开成具体可验收的功能点。
> 它不是 Why（goal.md）、不是规格（SPEC.md）、不是追溯矩阵（TRACEABILITY.md）。
> 实现状态以本清单勾选为准；任一未勾选项存在即视为未完整实现。

勾选图例：`[ ]` 待实现 · `[x]` 已实现并通过对应 TC · `[~]` 部分实现（须在备注列注明缺口）

---

## 1. 功能需求（FR）

- [ ] **FR-001** Order 值对象
- [ ] **FR-002** OrderState 枚举与流转
- [ ] **FR-003** Trade 值对象
- [ ] **FR-004** Position 值对象
- [ ] **FR-005** ExecutionReport 值对象
- [ ] **FR-006** Portfolio 值对象
- [ ] **FR-007** 序列化兼容
- [ ] **FR-008** 不可变性

## 2. 业务规则（BR）

- [ ] **BR-001** 所有金额/价格字段使用 decimal.Decimal，不得使用 float64
- [ ] **BR-002** Order.quantity > 0 且限价单 price ≥ 0（市价单 price 可为 0）
- [ ] **BR-003** OrderState 流转必须遵循合法迁移表
- [ ] **BR-004** Trade 必须关联有效的 OrderID
- [ ] **BR-005** Position.avgPrice 在加仓/减仓后按加权均价重新计算
- [ ] **BR-006** ExecutionReport.state 为 FILLED 时 remainingQty 必须为 0
- [ ] **BR-007** 所有值对象字段不可变（私有 + getter）
- [ ] **BR-008** JSON tag 统一使用 snake_case
- [ ] **BR-009** 错误消息格式：`domainx: <type>: <detail>`
- [ ] **BR-010** Portfolio.totalEquity = sum(balances) + sum(positions.marketValue)

## 3. 非功能需求（NFR）

> SPEC 中未抽取到 `NFR-` 编号；请人工对照 SPEC §11 非功能需求补全（如有）。

---

## 4. 完整实现判定

本清单 §1-§3 全部 `[x]` 勾选 + ACCEPTANCE.md 全部 TC 通过 + SPEC §19 验收门禁通过 + pipeline-arbiter 翻转 Approved。

## 5. 明确不做

参见 [SPEC.md](./SPEC.md) §4 非目标章节。domainx 只承担 SPEC 范围内的能力，不做范围外业务语义/集成编排/跨模块横切。

