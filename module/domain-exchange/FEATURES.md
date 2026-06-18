# domain-exchange 完整实现功能清单

- Status: Generated（与 [SPEC.md](./SPEC.md) 同步抽取，未经 pipeline-arbiter 校验）
- Last-Updated: 2026-06-18
- Source: [SPEC.md](./SPEC.md) · [TRACEABILITY.md](./TRACEABILITY.md) · [goal.md](./goal.md)
- Scale: 12 FR · 7 BR · 0 NFR

> 本文档是 domain-exchange **要完整实现的、可勾选的功能清单**，把 SPEC 的 FR/BR/NFR 展开成具体可验收的功能点。
> 它不是 Why（goal.md）、不是规格（SPEC.md）、不是追溯矩阵（TRACEABILITY.md）。
> 实现状态以本清单勾选为准；任一未勾选项存在即视为未完整实现。

勾选图例：`[ ]` 待实现 · `[x]` 已实现并通过对应 TC · `[~]` 部分实现（须在备注列注明缺口）

---

## 1. 功能需求（FR）

- [ ] **FR-EXC-001** Exchange SPI 必须拆分读写能力接口，避免单个巨型 interface。
- [ ] **FR-EXC-002** 下单、撤单、查询请求必须表达 client id、idempotency、venue 与 instrument。
- [ ] **FR-EXC-003** ExchangeError 必须区分临时错误、永久错误、限速、认证、余额、精度和不支持能力。
- [ ] **FR-EXC-004** VenueCapability、RateLimitPolicy、VenueProfile 必须可静态描述并可测试。
- [ ] **FR-EXC-005** Registry 必须线程安全，支持 fake exchange 注入。
- [ ] **FR-EXC-006** MarketReader 必须返回 `domain-market` 类型，不重复定义行情模型。
- [ ] **FR-EXC-007** Order 相关返回必须采用 `domainx` 类型或短期兼容 alias，不建立第二套订单 SSOT。
- [ ] **FR-EXC-008** retry-semantics
- [ ] **FR-EXC-009** registry-safe
- [ ] **FR-EXC-010** market-reader
- [ ] **FR-EXC-011** stream-lifecycle
- [ ] **FR-EXC-012** order-type-alignment

## 2. 业务规则（BR）

- [ ] **BR-EXC-001** Exchange 不支持某 capability 时返回 typed error，不得 panic 或静默空值
- [ ] **BR-EXC-002** prod/paper 下单必须有 ClientID，保证幂等
- [ ] **BR-EXC-003** adapter 必须把交易所原始错误映射为 typed ExchangeError，不暴露原始 DTO
- [ ] **BR-EXC-004** 所有 price/qty/balance 使用 decimalx.Decimal
- [ ] **BR-EXC-005** Balance 的 Total = Free + Locked（可选计算规则）
- [ ] **BR-EXC-006** Registry 重复注册返回错误，不允许覆盖
- [ ] **BR-EXC-007** WS channel 关闭规则：ctx cancel 后 channel 可预测关闭；不允许 goroutine leak

## 3. 非功能需求（NFR）

> SPEC 中未抽取到 `NFR-` 编号；请人工对照 SPEC §11 非功能需求补全（如有）。

---

## 4. 完整实现判定

本清单 §1-§3 全部 `[x]` 勾选 + ACCEPTANCE.md 全部 TC 通过 + SPEC §19 验收门禁通过 + pipeline-arbiter 翻转 Approved。

## 5. 明确不做

参见 [SPEC.md](./SPEC.md) §4 非目标章节。domain-exchange 只承担 SPEC 范围内的能力，不做范围外业务语义/集成编排/跨模块横切。

