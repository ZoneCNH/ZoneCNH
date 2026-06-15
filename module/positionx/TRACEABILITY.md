# positionx 需求追溯矩阵

> 更新：2026-06-16
> 来源：module/positionx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## §1 功能需求追溯（FR）

| FR | Description | WHEN | THEN | AC | TC | Task | Status |
|----|-------------|------|------|----|----|------|--------|
| FR-001 | Position Update | 接收到 FillEvent（成交事件） | 更新对应 symbol/account/exchange 的仓位；更新耗时 < 10ms（p95）；记录变更原因和来源 fill_id | AC-POS-001 | TC-POS-001 | - | ✅ |
| FR-002 | Position Query | 查询 Position(symbol, account, exchange) | 返回最新仓位：longQty/shortQty/netQty/avgPrice/lastUpdateTime；空参数返回跨交易所聚合视图 | AC-POS-002 | TC-POS-002 | - | ✅ |
| FR-003 | PnL Calculation | 计算 PnL(symbol, account) | 返回 realizedPnl/unrealizedPnl/totalPnl；unrealizedPnl 基于 markPrice；markPrice 不可用时用最近成交价替代并标注 stale=true | AC-POS-003 | TC-POS-003 | - | ✅ |
| FR-004 | Exposure | 查询 Exposure(account) | 返回 totalExposure（所有仓位 netQty*markPrice 绝对值之和）；返回 byExchange/bySymbol 敞口明细；计算 netDelta | AC-POS-004 | TC-POS-004 | - | ✅ |
| FR-005 | Reconciliation | 触发 PositionReconciliation(account, exchange) | 从交易所 API 拉取持仓→与本地对比；差异超过 threshold emit reconciliation_alert；差异写入 audit log | AC-POS-005 | TC-POS-005 | - | ✅ |
| FR-006 | Snapshot | 定时 Snapshot 触发 | 生成当前所有仓位的只读快照；通过 observex 推送给订阅方；间隔可配置（默认 1s） | AC-POS-006 | TC-POS-006 | - | ✅ |
| FR-007 | Position History | 查询 PositionHistory(symbol, account, start, end) | 返回时间段内仓位变更事件列表；每条记录含 timestamp/fill_id/deltaQty/price/reason | AC-POS-007 | TC-POS-007 | - | ✅ |
| FR-008 | Module Identity | downstream consumer 读取 README.md | H1 为 `# positionx`；Go module path 为 `github.com/ZoneCNH/positionx`；go.mod 声明 `module github.com/ZoneCNH/positionx` | AC-POS-008 | TC-POS-008 | - | ✅ |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Verification | Status |
|-------|------|----------|--------------|--------|
| BR-001 | 同一 fill_id 不可重复更新仓位 | TC-POS-009 | TC-POS-009 重复 fill_id 拒绝断言 | ✅ | |
| BR-002 | long 和 short 不可同时非零 | TC-POS-001 | TC-POS-001 净持仓模式断言 | ✅ | |
| BR-003 | 仓位核对差异 > 5% 必须人工确认 | TC-POS-005 | TC-POS-005 差异阈值告警断言 | ✅ | |
| BR-004 | 快照不可变（创建后不能修改） | TC-POS-006 | TC-POS-006 快照不可变断言 | ✅ | |
| BR-005 | markPrice 来源优先：最新成交 > 买一 > 上次 mark | TC-POS-003 | TC-POS-003 markPrice 降级断言 | ✅ | |

---

## §3 非功能需求追溯（NFR）

| NFR | Category | Requirement | Verification | Task | Status |
|-----|----------|-------------|--------------|------|--------|
| NFR-001 | 性能 | Position Update 延迟 < 10ms（p95） | Benchmark + p95 latency | - | ✅ |
| NFR-002 | 性能 | Snapshot（1K positions）延迟 < 50ms | Benchmark `BenchmarkSnapshot` | - | ✅ |
| NFR-003 | 性能 | PnL Calculation 延迟 < 1ms | Benchmark `BenchmarkPnL` | - | ✅ |
| NFR-004 | 性能 | Reconciliation 延迟 < 5s | Benchmark `BenchmarkReconciliation` | - | ✅ |
| NFR-005 | 质量 | 测试覆盖率 >= 80% | `go tool cover -func` | - | ✅ |
| NFR-006 | 安全 | 无硬编码密钥 | `gitleaks detect --no-git` | - | ✅ |

---

## §4 TC → FR 反向追溯

| TC | Covers FR(s) | Scenario | Command |
|----|-------------|----------|---------|
| TC-POS-001 | FR-001, BR-002 | FillEvent 触发仓位更新；netQty 和 avgPrice 正确计算；净持仓模式 | `go test ./... -run TestPositionUpdate` |
| TC-POS-002 | FR-002 | Position(symbol,account,exchange) 返回最新仓位；空参数返回跨交易所聚合视图 | `go test ./... -run TestPositionQuery` |
| TC-POS-003 | FR-003, BR-005 | PnL 返回 realized/unrealized/total；基于 markPrice；markPrice 不可用时替代标注 stale | `go test ./... -run TestPnLCalculation` |
| TC-POS-004 | FR-004 | Exposure 返回 totalExposure/byExchange/bySymbol 明细和 netDelta | `go test ./... -run TestExposure` |
| TC-POS-005 | FR-005, BR-003 | Reconciliation 拉取交易所持仓对比本地；差异超阈值 emit alert；写入 audit log | `go test ./... -run TestReconciliation` |
| TC-POS-006 | FR-006, BR-004 | Snapshot 生成只读快照；通过 observex 推送；间隔可配置；快照不可变 | `go test ./... -run TestSnapshot` |
| TC-POS-007 | FR-007 | PositionHistory 返回指定时间段变更事件（timestamp/fill_id/deltaQty/price/reason） | `go test ./... -run TestPositionHistory` |
| TC-POS-008 | FR-008 | README H1 为 `# positionx`；go.mod 声明 `module github.com/ZoneCNH/positionx` | `go test ./... -run TestModuleIdentity` |
| TC-POS-009 | BR-001 | 重复 fill_id 拒绝更新 + warning log | `go test ./... -run TestDuplicateFillReject` |

---

## §5 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 | Verification |
|----|-----------|-------------|--------------|
| AC-POS-001 | FR-001 | FillEvent 触发仓位更新；耗时 < 10ms（p95）；记录变更原因和 fill_id | TC-POS-001 |
| AC-POS-002 | FR-002 | Position 返回最新仓位；空参数返回跨交易所聚合视图 | TC-POS-002 |
| AC-POS-003 | FR-003 | PnL 返回 realized/unrealized/total；markPrice 不可用时替代标注 stale | TC-POS-003 |
| AC-POS-004 | FR-004 | Exposure 返回 totalExposure/byExchange/bySymbol 和 netDelta | TC-POS-004 |
| AC-POS-005 | FR-005 | Reconciliation 拉取交易所对比本地；差异超阈值 alert；写入 audit log | TC-POS-005 |
| AC-POS-006 | FR-006 | Snapshot 生成只读快照；observex 推送；间隔可配置 | TC-POS-006 |
| AC-POS-007 | FR-007 | PositionHistory 返回时间段内变更事件列表 | TC-POS-007 |
| AC-POS-008 | FR-008 | README H1 为 `# positionx`；go.mod 声明 `module github.com/ZoneCNH/positionx` | TC-POS-008 |

---

## §6 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 8 | FR-001 ~ FR-008 |
| FR 有 AC 覆盖 | 8/8 (100%) | |
| FR 有 TC 覆盖 | 8/8 (100%) | |
| BR 总数 | 5 | BR-001 ~ BR-005 |
| BR 有验证机制 | 5/5 (100%) | |
| NFR 总数 | 6 | NFR-001 ~ NFR-006 |
| AC 总数 | 8 | AC-POS-001 ~ AC-POS-008 |
| TC 总数 | 9 | TC-POS-001 ~ TC-POS-009 |

---

## §7 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-16 | v1.1 | 标准化为 §1-§7 结构；FR 表增加 WHEN/THEN 列；TC 表增加 Command 列；AC 表增加 Verification 列 |
| 2026-06-15 | v1.0 | 初始版本：8 FR + 5 BR + 6 NFR + 9 TC + 8 AC |
