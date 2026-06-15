# domain-exchange Traceability Matrix

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-exchange` |
| 目标版本 | v1.0.0 |
| Spec 版本 | v1.0.0 |
| 状态 | Ready |
| 最后更新 | 2026-06-16 |

---

## §1 FR Traceability (功能需求追溯)

| FR ID | Requirement | AC ID(s) | TC ID(s) | Verification |
| --- | --- | --- | --- | --- |
| FR-EXC-001 | spi-segmentation: WHEN 定义 Exchange 相关接口 THEN 拆分为 AccountReader、OrderPlacer、OrderCanceler、OrderQuerier、MarketReader、DerivativeReader、Streamer 能力接口 | AC-EXC-001 | TC-EXC-001 | `GOWORK=off go test ./...` |
| FR-EXC-002 | place-order: WHEN 调用 OrderPlacer.PlaceOrder THEN PlaceOrderRequest 必须通过 Validate()；返回 domainx.ExecutionReport | AC-EXC-002 | TC-EXC-001 | `GOWORK=off go test -race ./...` |
| FR-EXC-003 | cancel-order: WHEN 调用 OrderCanceler.CancelOrder THEN CancelOrderRequest 统一建模，避免裸参数 | AC-EXC-003 | TC-EXC-001 | `GOWORK=off go test ./...` |
| FR-EXC-004 | query-order: WHEN 调用 OrderQuerier.QueryOrder THEN 返回 domainx.Order 或 typed error | AC-EXC-004 | TC-EXC-001 | `GOWORK=off go test ./...` |
| FR-EXC-005 | capability-check: WHEN 请求交易所不支持的能力 THEN 返回 ErrUnsupportedCapability，不得 panic 或返回空值 | AC-EXC-005 | TC-EXC-002 | `GOWORK=off go test -race ./...` |
| FR-EXC-006 | idempotency: WHEN prod/paper 下单 THEN ClientID 必填；backtest 可自动生成但必须可复现 | AC-EXC-006 | TC-EXC-001 | `GOWORK=off go test ./...` |
| FR-EXC-007 | error-classification: WHEN 交易所返回错误 THEN ExchangeError 区分临时/永久/限速/认证/余额/精度/不支持 | AC-EXC-007 | TC-EXC-003 | `GOWORK=off go test ./...` |
| FR-EXC-008 | retry-semantics: WHEN 调用方收到错误 THEN IsRetryable/RetryAfter/IsIdempotentSafe 可判断重试策略 | AC-EXC-008 | TC-EXC-003 | `GOWORK=off go test ./...` |
| FR-EXC-009 | registry-safe: WHEN 并发注册/查询 Exchange THEN Registry 线程安全；重复注册返回错误；列表排序 deterministic | AC-EXC-009 | TC-EXC-004 | `GOWORK=off go test -race ./...` |
| FR-EXC-010 | market-reader: WHEN 调用 MarketReader THEN 返回 domain-market 类型（Kline/TickerPrice/OrderBook），不重复定义 | AC-EXC-010 | TC-EXC-007 | `GOWORK=off go test ./...` |
| FR-EXC-011 | stream-lifecycle: WHEN ctx cancel 或 stream 关闭 THEN Channel 可预测关闭；不支持 WS 的 venue 返回 ErrUnsupportedCapability | AC-EXC-011 | TC-EXC-005, TC-EXC-006 | `GOWORK=off go test -race ./...` |
| FR-EXC-012 | order-type-alignment: WHEN 返回订单/成交 THEN 使用 domainx.Order/ExecutionReport 或标注 deprecated alias | AC-EXC-012 | TC-EXC-007 | `GOWORK=off go test ./...` |

---

## §2 BR Traceability (业务规则追溯)

| BR ID | Rule | Verification Method |
| --- | --- | --- |
| BR-EXC-001 | Exchange 不支持某 capability 时返回 typed error，不得 panic 或静默空值 | TC-EXC-002 验证 ErrUnsupportedCapability + `GOWORK=off go test -race ./...` |
| BR-EXC-002 | prod/paper 下单必须有 ClientID，保证幂等 | TC-EXC-001 验证 Validate() 拒绝空 ClientID |
| BR-EXC-003 | adapter 必须把交易所原始错误映射为 typed ExchangeError，不暴露原始 DTO | TC-EXC-003 验证 errors.Is/As 可识别 wrapped error |
| BR-EXC-004 | 所有 price/qty/balance 使用 decimalx.Decimal | FR-EXC-002 WHEN/THEN + `GOWORK=off go test ./...` |
| BR-EXC-005 | Balance 的 Total = Free + Locked（可选计算规则） | 单元测试 Balance.Total() 计算正确性 |
| BR-EXC-006 | Registry 重复注册返回错误，不允许覆盖 | TC-EXC-004 验证并发注册行为 + `GOWORK=off go test -race ./...` |
| BR-EXC-007 | WS channel 关闭规则：ctx cancel 后 channel 可预测关闭；不允许 goroutine leak | TC-EXC-006 验证 leak test + `GOWORK=off go test -race ./...` |

---

## §3 NFR Traceability (非功能需求追溯)

| NFR ID | Category | Requirement | Verification |
| --- | --- | --- | --- |
| NFR-EXC-001 | 适配性 (Adapter-Friendly) | SPI 稳定，但不绑定任何单一 vendor API | `GOWORK=off make adoption-check` |
| NFR-EXC-002 | 安全性 (Fail-Closed) | 未知能力、未知错误和不安全重试必须默认失败 | TC-EXC-002 (未知能力→typed error) + TC-EXC-003 (错误分类不走默认路径) |
| NFR-EXC-003 | 可测试性 (Testable) | 所有能力、错误和 retry/idempotency 语义必须可用 fake exchange 验证 | TC-EXC-005 (fake exchange 覆盖成功/拒单/限频/partial fill/stream close) |

---

## §4 TC→FR Reverse Traceability (测试用例反向追溯)

| TC ID | Covers FR(s) | Command |
| --- | --- | --- |
| TC-EXC-001 | FR-EXC-002, FR-EXC-003, FR-EXC-004, FR-EXC-006 | PlaceOrderRequest 缺少 ClientID → Validate() 失败 |
| TC-EXC-002 | FR-EXC-005 | 不支持的 capability → 返回 ErrUnsupportedCapability |
| TC-EXC-003 | FR-EXC-007, FR-EXC-008 | 错误可分类为 retryable / non-retryable / auth / rate limit |
| TC-EXC-004 | FR-EXC-009 | Registry 并发注册安全且 deterministic |
| TC-EXC-005 | FR-EXC-005, FR-EXC-011 | Fake exchange 覆盖成功、拒单、限频、partial fill、stream close |
| TC-EXC-006 | FR-EXC-011 | ctx cancel 后 WS channel 关闭可预测，无 goroutine leak |
| TC-EXC-007 | FR-EXC-010, FR-EXC-012 | 返回订单/成交语义对齐 domainx 类型 |

---

## §5 AC Registry (验收标准注册表)

| AC ID | FR/BR Reference | Criterion | Verification |
| --- | --- | --- | --- |
| AC-EXC-001 | FR-EXC-001 | SPI 拆分为 AccountReader、OrderPlacer、OrderCanceler、OrderQuerier、MarketReader、DerivativeReader、Streamer 能力接口 | TC-EXC-001 compile/adoption |
| AC-EXC-002 | FR-EXC-002 | PlaceOrderRequest 通过 Validate()，返回 domainx.ExecutionReport | TC-EXC-001 request validation |
| AC-EXC-003 | FR-EXC-003 | CancelOrderRequest 统一建模，避免裸参数 | TC-EXC-001 request validation |
| AC-EXC-004 | FR-EXC-004 | QueryOrder 返回 domainx.Order 或 typed error | TC-EXC-001 domainx adoption |
| AC-EXC-005 | FR-EXC-005, BR-EXC-001 | 不支持的 capability 返回 ErrUnsupportedCapability，不得 panic 或返回空值 | TC-EXC-002 capability tests |
| AC-EXC-006 | FR-EXC-006, BR-EXC-002 | ClientID 幂等必填；backtest 可自动生成但必须可复现 | TC-EXC-001 request validation |
| AC-EXC-007 | FR-EXC-007, BR-EXC-003 | ExchangeError 可分类为 retryable / non-retryable / auth / rate-limit 且支持 errors.Is/As | TC-EXC-003 error table tests |
| AC-EXC-008 | FR-EXC-008 | IsRetryable / RetryAfter / IsIdempotentSafe 可判断重试策略 | TC-EXC-003 error table tests |
| AC-EXC-009 | FR-EXC-009, BR-EXC-006 | Registry 线程安全、重复注册返回错误、列表 deterministic | TC-EXC-004 race/concurrency |
| AC-EXC-010 | FR-EXC-010 | MarketReader 返回 domain-market 类型（Kline / TickerPrice / OrderBook），不重复定义行情模型 | TC-EXC-007 type boundary scan |
| AC-EXC-011 | FR-EXC-011, BR-EXC-007 | ctx cancel 后 WS channel 可预测关闭，无 goroutine leak；不支持 WS 的 venue 返回 ErrUnsupportedCapability | TC-EXC-005, TC-EXC-006 stream/leak tests |
| AC-EXC-012 | FR-EXC-012 | 返回订单/成交使用 domainx.Order/ExecutionReport 或标注 deprecated alias | TC-EXC-007 domainx adoption |

---

## 覆盖摘要

| 维度 | 数量 | 覆盖率 |
| --- | --- | --- |
| FR 总数 (§7) | 12 | — |
| BR 总数 (§8) | 7 | — |
| NFR 总数 (§4) | 3 | — |
| AC 总数 (§5) | 12 | 12/12 FR 覆盖 |
| TC 总数 (§16.1) | 7 | 12/12 FR 可追溯 |
| BR→验证 | 7 | 7/7 BR 有验证路径 |
| NFR→验证 | 3 | 3/3 NFR 有验证路径 |

所有数据来源于 `module/domain-exchange/SPEC.md`，未编造。实现和测试证据需在 `domain-exchange` 仓库完成；本文件记录 `ZoneCNH` 文档仓库的 v1.0.0 追溯基线。
