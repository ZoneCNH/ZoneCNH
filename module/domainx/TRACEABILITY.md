# domainx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-14
Source: module/domainx/SPEC.md

## §1 功能需求追溯（FR）

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | Order 值对象 — NewOrder 构造 + 校验（quantity/price/symbol） + getter 只读 | AC-001, AC-002, AC-003, AC-004 | TC-001, TC-002, TC-003, TC-004 | - | Pending |
| FR-002 | Fill 值对象 — NewFill 构造 + 校验（quantity/price/fee） | AC-005, AC-006 | TC-005, TC-006 | - | Pending |
| FR-003 | Position 值对象 — NewPosition + MarketValue() + UnrealizedPnL() | AC-007, AC-008 | TC-007, TC-008 | - | Pending |
| FR-004 | Exposure 值对象 — NewExposure + NetExposureRatio() | AC-009, AC-010 | TC-009, TC-010 | - | Pending |
| FR-005 | JSON 序列化/反序列化 — 所有值对象支持 snake_case round-trip | AC-011, AC-012, AC-013 | TC-011, TC-012, TC-013 | - | Pending |
| FR-006 | 不可变性 — 值对象创建后字段只读 + 并发读安全 | AC-014 | TC-014 | - | Pending |

## §2 业务规则追溯（BR）

| Requirement | Description | 违反后果 | 验证方式 | Task | Status |
| --- | --- | --- | --- | --- | --- |
| BR-001 | 金额精度 — 所有金额/价格/费用字段使用 decimal.Decimal | 精度丢失，跨模块数据不一致 | 编译期类型检查 (`decimal.Decimal`) | - | Pending |
| BR-002 | Quantity 正数校验 — Order/Fill quantity > 0 | 负数量导致风控/结算计算错误 | TC-002, TC-006 (非法 quantity 测试) | - | Pending |
| BR-003 | Price 非负校验 — Order price/Fill price/Position avgPrice >= 0 | 负价格导致估值异常 | TC-003 (非法 price 测试) | - | Pending |
| BR-004 | Symbol 非空 — 所有含 symbol 字段的值对象 symbol != "" | 空 symbol 导致消息路由失败 | TC-004 (空 symbol 测试) | - | Pending |
| BR-005 | 不可变性 — 私有字段 + 公开只读 getter，无 setter | 并发修改导致 data race | TC-014 (并发读取 race 测试) | - | Pending |
| BR-006 | snake_case JSON — 所有 JSON tag 与 contracts DTO 对齐 | 跨模块序列化不兼容 | TC-011, TC-012 (JSON round-trip 测试) | - | Pending |
| BR-007 | Decimal 零值语义 — 拒绝未初始化的 decimal.Decimal{} | 零值与数值 0 混淆，计算错误 | TC-002, TC-003 (零值 decimal 校验) | - | Pending |

## §3 非功能需求追溯（NFR）

| Requirement | Description | 目标值 | 验证方式 | Task | Status |
| --- | --- | --- | --- | --- | --- |
| NFR-001 | Order 构造性能 | < 500ns | Benchmark `BenchmarkNewOrder` | - | Pending |
| NFR-002 | Position.MarketValue() 性能 | < 100ns | Benchmark `BenchmarkMarketValue` | - | Pending |
| NFR-003 | JSON round-trip 性能 | < 1μs | Benchmark `BenchmarkJSONRoundTrip` | - | Pending |
| NFR-004 | 单元测试覆盖率 | ≥ 80% | `go tool cover -func` | - | Pending |
| NFR-005 | 编译通过 | 零错误 | `go build ./...` | - | Pending |
| NFR-006 | race 检测通过 | 零 data race | `go test -race ./...` | - | Pending |
| NFR-007 | vet 检查通过 | 零警告 | `go vet ./...` | - | Pending |
| NFR-008 | lint 检查通过 | 零错误 | `golangci-lint run` | - | Pending |
| NFR-009 | Secret 扫描通过 | 零命中 | `gitleaks detect --no-git` | - | Pending |
| NFR-010 | 零内存分配（单值对象构造） | 0 allocs | `go test -benchmem` | - | Pending |

## §4 TC → FR 反向追溯

| Test Case | 覆盖需求 | 测试类型 | 描述 |
| --- | --- | --- | --- |
| TC-001 | FR-001 | 单元 | Order 正常构造：合法参数 → 返回 Order + nil 错误 |
| TC-002 | FR-001, BR-002, BR-007 | 单元 | Order 非法 quantity：quantity<=0 或 decimal 零值 → ErrInvalidQuantity |
| TC-003 | FR-001, BR-003, BR-007 | 单元 | Order 非法 price：price<0 或 decimal 零值 → ErrInvalidPrice |
| TC-004 | FR-001, BR-004 | 单元 | Order 空 symbol：symbol="" → ErrEmptySymbol |
| TC-005 | FR-002 | 单元 | Fill 正常构造：合法参数 → 返回 Fill + nil 错误 |
| TC-006 | FR-002, BR-002 | 单元 | Fill 非法 fee：fee<0 → ErrInvalidFee |
| TC-007 | FR-003 | 单元 | Position.MarketValue()：quantity * avgPrice 精确计算 |
| TC-008 | FR-003 | 单元 | Position.UnrealizedPnL(currentPrice)：(currentPrice-avgPrice)*quantity |
| TC-009 | FR-004 | 单元 | Exposure 正常构造：合法参数 → 返回 Exposure + nil 错误 |
| TC-010 | FR-004 | 单元 | Exposure.NetExposureRatio() 除零保护：grossExposure=0 → 返回 0 |
| TC-011 | FR-005, BR-006 | 单元 | Order JSON round-trip：Marshal → Unmarshal → 字段值一致 |
| TC-012 | FR-005, BR-006 | 单元 | Fill JSON round-trip：Marshal → Unmarshal → 字段值一致 |
| TC-013 | FR-005 | 单元 | JSON 缺失必填字段：反序列化返回错误 |
| TC-014 | FR-006, BR-005 | 单元 | 并发读取无 data race：多 goroutine 同时 getter → `-race` 零告警 |

## §5 全局 AC 注册表

| AC ID | 所属需求 | 验证方式 | 状态 |
| --- | --- | --- | --- |
| AC-001 | FR-001 | TC-001: Order 正常构造测试 | Pending |
| AC-002 | FR-001, BR-002, BR-007 | TC-002: 非法 quantity 测试 | Pending |
| AC-003 | FR-001, BR-003, BR-007 | TC-003: 非法 price 测试 | Pending |
| AC-004 | FR-001, BR-004 | TC-004: 空 symbol 测试 | Pending |
| AC-005 | FR-002 | TC-005: Fill 正常构造测试 | Pending |
| AC-006 | FR-002, BR-002 | TC-006: 非法 fee 测试 | Pending |
| AC-007 | FR-003 | TC-007: MarketValue() 计算测试 | Pending |
| AC-008 | FR-003 | TC-008: UnrealizedPnL() 计算测试 | Pending |
| AC-009 | FR-004 | TC-009: Exposure 正常构造测试 | Pending |
| AC-010 | FR-004 | TC-010: NetExposureRatio() 除零测试 | Pending |
| AC-011 | FR-005, BR-006 | TC-011: Order JSON round-trip 测试 | Pending |
| AC-012 | FR-005, BR-006 | TC-012: Fill JSON round-trip 测试 | Pending |
| AC-013 | FR-005 | TC-013: JSON 缺失字段错误测试 | Pending |
| AC-014 | FR-006, BR-005 | TC-014: 并发读取 race 测试 | Pending |

## §6 覆盖率仪表盘

| 类别 | 总数 | 已覆盖 | 覆盖率 | 状态 |
| --- | --- | --- | --- | --- |
| FR | 6 | 6 | 100% | ✅ |
| BR | 7 | 7 | 100% | ✅ |
| NFR | 10 | 10 | 100% | ✅ |
| TC | 14 | 14 | 100% | ✅ |
| AC | 14 | 14 | 100% | ✅ |
| Task | 0 | 0 | — | 未拆分 |

## §7 变更历史

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-06-14 | v1.0 | 初始矩阵：6 FR + 7 BR + 10 NFR + 14 TC + 14 AC；覆盖率 100% |
