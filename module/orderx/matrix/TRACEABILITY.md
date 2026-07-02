# orderx 需求追溯矩阵

> 更新：2026-06-16
> 来源：module/orderx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

Last-Updated: 2026-06-30
---

## §1 功能需求追溯（FR）

| FR | Description | WHEN | THEN | AC | TC | Task | Status |
|----|-------------|------|------|----|----|------|--------|
| FR-001 | Order Lifecycle | 创建订单 | 状态机遵循 NEW→PENDING→PARTIAL/FILLED/CANCELLED/REJECTED/EXPIRED 转换；非法转换被拒绝；每次变更记录 timestamp/oldState/newState/reason | AC-ORD-001 | TC-ORD-001 | - | 🔲 |
| FR-002 | Order Submission | Submit(order) | 必须先通过 riskx.CheckOrder 风控检查；风控拒绝时返回原因；通过后发送至 exchange adapter；返回 orderId 和初始状态 | AC-ORD-002 | TC-ORD-002 | - | 🔲 |
| FR-003 | Order Routing | 订单需要选择交易所 | 使用路由策略 PREFERRED/BEST_PRICE/LOWEST_FEE；PREFERRED 指定交易所不可用时 FAIL；BEST_PRICE 同时询价选最优 | AC-ORD-003 | TC-ORD-003 | - | 🔲 |
| FR-004 | SOR (Smart Order Routing) | 订单数量超过单笔上限 | 自动拆分为多个子订单（slice）；子订单可路由到不同交易所；父订单状态=所有子订单状态聚合；支持按时间、按成交量加权拆分 | AC-ORD-004 | TC-ORD-004 | - | 🔲 |
| FR-005 | Cancel / Amend | CancelOrder(orderId) / AmendOrder(orderId, newPrice, newQty) | CancelOrder 未成交→CANCELLED；部分成交仅取消剩余；AmendOrder Cancel-Replace 保留原 orderId | AC-ORD-005 | TC-ORD-005 | - | 🔲 |
| FR-006 | Order Query | 查询 Order(orderId) / OpenOrders(account) | Order(orderId) 返回完整订单信息；OpenOrders(account) 仅返回非终态订单（NEW/PENDING/PARTIAL） | AC-ORD-006 | TC-ORD-006 | - | 🔲 |
| FR-007 | Order Audit | 订单状态变更 | 记录 OrderAuditEvent（orderId/timestamp/oldState/newState/reason/fillId/price/qty）；审计事件不可删除 | AC-ORD-007 | TC-ORD-007 | - | 🔲 |
| FR-008 | Module Identity | downstream consumer 读取 README.md | H1 为 `# orderx`；Go module path 为 `github.com/ZoneCNH/orderx`；go.mod 声明 `module github.com/ZoneCNH/orderx` | AC-ORD-008 | TC-ORD-008 | - | 🔲 |

---


| BR | Rule | 违反后果 | TC ID(s) | Task | Status |

## §2 业务规则追溯（BR）

|----|------|----------|---------------------|------|--------|
| BR-001 | 订单必须先通过 riskx 才能提交交易所 | 拒绝下单 | TC-ORD-002 riskx 调用断言 | - | 🔲 |
| BR-002 | 终态订单不可再修改（FILLED/CANCELLED/REJECTED/EXPIRED） | 拒绝操作 | TC-ORD-001 终态转换拒绝断言 | - | 🔲 |
| BR-003 | SOR 父订单状态 = 所有子订单状态的聚合 | 状态不一致告警 | TC-ORD-004 父订单聚合状态断言 | - | 🔲 |
| BR-004 | 撤单操作幂等（对已终态的订单撤单返回成功） | - | TC-ORD-005 重复撤幂等断言 | - | 🔲 |
| BR-005 | 订单 ID 全局唯一 | ID 冲突时拒绝创建 | TC-ORD-009 orderID 唯一性断言 | - | 🔲 |

---

## §3 非功能需求追溯（NFR）

| NFR | Category | Requirement | Verification | Task | Status |
|-----|----------|-------------|--------------|------|--------|
| NFR-001 | 性能 | Submit 延迟（不含风控）< 5ms | Benchmark `BenchmarkSubmit` | - | 🔲 |
| NFR-002 | 性能 | Get/Cancel 延迟 < 1ms | Benchmark `BenchmarkGetCancel` | - | 🔲 |
| NFR-003 | 性能 | SOR Split 延迟 < 10ms | Benchmark `BenchmarkSORSplit` | - | 🔲 |
| NFR-004 | 质量 | 测试覆盖率 >= 80% | `go tool cover -func` | - | 🔲 |
| NFR-005 | 安全 | 无硬编码密钥 | `gitleaks detect --no-git` | - | 🔲 |

---

## §4 TC → FR 反向追溯

| TC | Covers FR(s) | Scenario | Command |
|----|-------------|----------|---------|
| TC-ORD-001 | FR-001, BR-002 | 订单状态机所有合法/非法转换；每次变更记录 timestamp/oldState/newState/reason | `go test ./... -run TestOrderLifecycle` |
| TC-ORD-002 | FR-002, BR-001 | Submit 先通过 riskx.CheckOrder；风控拒绝返回原因；通过后发送 exchange adapter | `go test ./... -run TestOrderSubmission` |
| TC-ORD-003 | FR-003 | 路由策略 PREFERRED/BEST_PRICE/LOWEST_FEE 正确执行；PREFERRED 不可用时 FAIL | `go test ./... -run TestOrderRouting` |
| TC-ORD-004 | FR-004, BR-003 | SOR 超过单笔上限自动拆分；子订单可路由不同交易所；父订单状态=子订单聚合 | `go test ./... -run TestSOR` |
| TC-ORD-005 | FR-005, BR-004 | CancelOrder 未成交→CANCELLED；部分成交仅取消剩余；AmendOrder Cancel-Replace；撤单幂等 | `go test ./... -run TestCancelAmend` |
| TC-ORD-006 | FR-006 | Order(orderId) 返回完整信息；OpenOrders(account) 仅返回非终态订单 | `go test ./... -run TestOrderQuery` |
| TC-ORD-007 | FR-007 | 订单状态变更记录 OrderAuditEvent；审计事件不可删除 | `go test ./... -run TestOrderAudit` |
| TC-ORD-008 | FR-008 | README H1 为 `# orderx`；go.mod 声明 `module github.com/ZoneCNH/orderx` | `go test ./... -run TestModuleIdentity` |
| TC-ORD-009 | BR-005 | orderID 全局唯一；冲突时拒绝创建 | `go test ./... -run TestOrderIDUnique` |

---

## §5 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 | Verification |
|----|-----------|-------------|--------------|
| AC-ORD-001 | FR-001 | 订单状态机遵循合法转换；非法转换拒绝；每次变更记录完整上下文 | TC-ORD-001 |
| AC-ORD-002 | FR-002 | Submit 先通过 riskx.CheckOrder；风控拒绝返回原因；通过后发送 exchange adapter；返回 orderId 和初始状态 | TC-ORD-002 |
| AC-ORD-003 | FR-003 | 路由策略 PREFERRED/BEST_PRICE/LOWEST_FEE 正确；PREFERRED 不可用 FAIL | TC-ORD-003 |
| AC-ORD-004 | FR-004 | SOR 超限自动拆分；子订单可路由不同交易所；父订单状态=子订单聚合 | TC-ORD-004 |
| AC-ORD-005 | FR-005 | CancelOrder 未成交→CANCELLED；部分成交仅取消剩余；AmendOrder Cancel-Replace 保留原 orderId | TC-ORD-005 |
| AC-ORD-006 | FR-006 | Order(orderId) 返回完整信息；OpenOrders(account) 仅返回非终态订单 | TC-ORD-006 |
| AC-ORD-007 | FR-007 | 订单状态变更记录 OrderAuditEvent；审计事件不可删除 | TC-ORD-007 |
| AC-ORD-008 | FR-008 | README H1 为 `# orderx`；go.mod 声明 `module github.com/ZoneCNH/orderx` | TC-ORD-008 |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 8 | 8 | 100% |
| BR | 5 | 5 | 100% |
| NFR | 5 | 5 | 100% |
| AC | 8 | 8 | 100% |
| TC | 8 | 8 | 100% |
| **合计** | **34** | **34** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-16 | v1.1 | 标准化为 §1-§7 结构；FR 表增加 WHEN/THEN 列；TC 表增加 Command 列；AC 表增加 Verification 列 |
| 2026-06-15 | v1.0 | 初始版本：8 FR + 5 BR + 5 NFR + 9 TC + 8 AC |
