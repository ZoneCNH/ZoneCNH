# domainx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-14
Source: `module/domainx/SPEC.md`

## §1 功能需求追溯（FR）

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | Order 值对象 — 构造、校验与初始状态 | AC-001, AC-009 | TC-001 | TASK-DOMAINX-001 | Done |
| FR-002 | OrderState 枚举与合法状态流转 | AC-002, AC-010 | TC-002 | TASK-DOMAINX-001 | Done |
| FR-003 | Trade 值对象 — 构造、数量、价格与手续费校验 | AC-003 | TC-004 | TASK-DOMAINX-002 | Done |
| FR-004 | Position 值对象 — 只读字段与 WithQuantity 均价更新 | AC-004 | TC-005 | TASK-DOMAINX-003 | Done |
| FR-005 | ExecutionReport 值对象 — 执行状态与数量一致性 | AC-005 | TC-006 | TASK-DOMAINX-004 | Done |
| FR-006 | Portfolio 值对象 — 余额、持仓与 totalEquity 自动计算 | AC-006, AC-011 | TC-007 | TASK-DOMAINX-005 | Done |
| FR-007 | 序列化兼容 — snake_case、decimal 字符串与 RFC3339 时间 | AC-007 | TC-003 | TASK-DOMAINX-005 | Done |
| FR-008 | 不可变性 — 无公开 setter、copy-on-write 与并发读安全 | AC-008 | TC-008 | TASK-DOMAINX-005 | Done |


| Requirement | Description | 违反后果 | TC ID(s) | Task | Status |
| --- | --- | --- | --- | --- | --- |
| BR-001 | 所有金额/价格字段使用 decimal.Decimal，不得使用 float64 | 编译失败：类型不匹配 | go test ./... | TASK-DOMAINX-006 | Done |
| BR-002 | Order.quantity > 0 且限价单 price >= 0（市价单 price 可为 0） | 返回 ErrInvalidQuantity 或 ErrInvalidPrice | TC-001 | TASK-DOMAINX-001 | Done |
| BR-003 | OrderState 流转必须遵循合法迁移表 | 返回 ErrInvalidTransition | TC-002 | TASK-DOMAINX-001 | Done |
| BR-004 | Trade 必须关联有效的 OrderID | 返回 ErrOrderNotFound（由调用方校验） | TC-004 | TASK-DOMAINX-002 | Done |
| BR-005 | Position.avgPrice 在加仓/减仓后按加权均价重新计算 | WithQuantity 返回新 Position，avgPrice 自动更新 | TC-005 | TASK-DOMAINX-003 | Done |
| BR-006 | ExecutionReport.state 为 FILLED 时 remainingQty 必须为 0 | 返回 ErrStateQuantityMismatch | TC-006 | TASK-DOMAINX-004 | Done |
| BR-007 | 所有值对象字段不可变（私有 + getter） | 编译期约束，无公开 setter | TC-008 | TASK-DOMAINX-005 | Done |
| BR-008 | JSON tag 统一使用 snake_case | CI Gate: TC-003 JSON round-trip 测试失败 | TC-003 | TASK-DOMAINX-005 | Done |
| BR-009 | 错误消息格式：`domainx: <type>: <detail>` | CI Gate 错误格式检查失败 | go test ./... | TASK-DOMAINX-006 | Done |
| BR-010 | Portfolio.totalEquity = sum(balances) + sum(positions.marketValue) | 返回 ErrPortfolioBalanceMismatch | TC-007 | TASK-DOMAINX-005 | Done |

## §3 非功能需求追溯（NFR）

| Requirement | Description | 目标值 | 验证方式 | Task | Status |
| --- | --- | --- | --- | --- | --- |
| NFR-001 | 值对象构造延迟 | < 1μs | go test -bench . ./... | TASK-DOMAINX-006 | Done |
| NFR-002 | 值对象构造分配 | 0 allocs | go test -bench . -benchmem ./... | TASK-DOMAINX-006 | Done |
| NFR-003 | JSON round-trip 精度 | decimal 精度无损 | TC-003 | TASK-DOMAINX-005 | Done |
| NFR-004 | 单元测试覆盖率 | >= 80% | go test -cover ./... | TASK-DOMAINX-006 | Done |
| NFR-005 | 编译通过 | 零错误 | go build ./... | TASK-DOMAINX-006 | Done |
| NFR-006 | race 检测通过 | 零 data race | go test -race ./... | TASK-DOMAINX-006 | Done |
| NFR-007 | vet 检查通过 | 零警告 | go vet ./... | TASK-DOMAINX-006 | Done |
| NFR-008 | lint 检查通过 | 零错误 | golangci-lint run | TASK-DOMAINX-006 | Done |
| NFR-009 | Secret 扫描通过 | 零命中 | gitleaks detect --no-git | TASK-DOMAINX-006 | Done |
| NFR-010 | 公共 API 与 contracts 对齐 | 快照无漂移 | API snapshot / contracts check | TASK-DOMAINX-006 | Done |

## §4 TC → FR 反向追溯

| Test Case | 覆盖需求 | 测试类型 | 描述 |
| --- | --- | --- | --- |
| TC-001 | FR-001, BR-002 | 单元 | Order 构造与 quantity/price/symbol 校验 |
| TC-002 | FR-002, BR-003 | 单元 | OrderState 合法与非法状态流转 |
| TC-003 | FR-007, BR-008 | 单元 | JSON round-trip 保持 snake_case 与 decimal 精度 |
| TC-004 | FR-003, BR-004 | 单元 | Trade 构造与 OrderID 关联 |
| TC-005 | FR-004, BR-005 | 单元 | Position 加仓/减仓后均价更新 |
| TC-006 | FR-005, BR-006 | 单元 | ExecutionReport 状态与数量一致性 |
| TC-007 | FR-006, BR-010 | 单元 | Portfolio totalEquity 计算与余额一致性 |
| TC-008 | FR-008, BR-007 | 单元 | 值对象不可变性与无公开 setter |

## §5 全局 AC 注册表

| AC ID | 所属需求 | 验证方式 | 状态 |
| --- | --- | --- | --- |
| AC-001 | FR-001 | TC-001: Order 构造校验 quantity/price/symbol | Done |
| AC-002 | FR-002 | TC-002: 合法流转成功，非法返回 ErrInvalidTransition | Done |
| AC-003 | FR-003 | TC-004: Trade 构造校验 quantity/price/fee | Done |
| AC-004 | FR-004 | TC-005: Position 只读，WithQuantity 更新均价 | Done |
| AC-005 | FR-005 | TC-006: ExecutionReport 校验 state/quantity | Done |
| AC-006 | FR-006 | TC-007: Portfolio 自动计算 totalEquity | Done |
| AC-007 | FR-007 | TC-003: JSON round-trip Decimal 精度不变 | Done |
| AC-008 | FR-008 | TC-008: 无公开 setter，修改返回新实例 | Done |
| AC-009 | BR-002 | TC-001: quantity<=0 返回 ErrInvalidQuantity | Done |
| AC-010 | BR-003 | TC-002: 非法流转返回 ErrInvalidTransition | Done |
| AC-011 | BR-010 | TC-007: Portfolio 余额不一致返回错误 | Done |

## §6 覆盖率仪表盘

| 类别 | 总数 | 已覆盖 | 覆盖率 | 状态 |
| --- | --- | --- | --- | --- |
| FR | 8 | 8 | 100% | ✅ |
| BR | 10 | 10 | 100% | ✅ |
| NFR | 10 | 10 | 100% | ✅ |
| TC | 8 | 8 | 100% | ✅ |
| AC | 11 | 11 | 100% | ✅ |
| Task | 6 | 6 | — | 6 Done |

## §7 变更历史

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-06-14 | v1.1 | 对齐当前 SPEC：8 FR + 10 BR + 10 NFR + 8 TC + 11 AC；纳入 traceability 门禁 |
