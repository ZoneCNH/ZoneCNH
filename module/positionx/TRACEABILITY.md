# positionx 需求追溯矩阵

> 更新：2026-06-15
> 来源：module/positionx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | Position Update：FillEvent 触发仓位更新；更新耗时 < 10ms(p95)；记录变更原因和 fill_id | AC-POS-001 | TC-POS-001 | - | 🔲 |
| FR-002 | Position Query：返回最新仓位(longQty/shortQty/netQty/avgPrice)；空参数返回跨交易所聚合视图 | AC-POS-002 | TC-POS-002 | - | 🔲 |
| FR-003 | PnL Calculation：返回 realizedPnl/unrealizedPnl/totalPnl；基于 markPrice；markPrice 不可用时替代标注 stale | AC-POS-003 | TC-POS-003 | - | 🔲 |
| FR-004 | Exposure：返回 totalExposure/byExchange/bySymbol 明细和 netDelta | AC-POS-004 | TC-POS-004 | - | 🔲 |
| FR-005 | Reconciliation：拉取交易所持仓对比本地；差异超过 threshold emit alert；差异写入 audit log | AC-POS-005 | TC-POS-005 | - | 🔲 |
| FR-006 | Snapshot：生成只读仓位快照；通过 observex 推送；间隔可配置（默认 1s） | AC-POS-006 | TC-POS-006 | - | 🔲 |
| FR-007 | Position History：返回指定时间段仓位变更事件列表 | AC-POS-007 | TC-POS-007 | - | 🔲 |
| FR-008 | Module Identity：README H1 为 `# positionx`；Go module path 为 `github.com/ZoneCNH/positionx` | AC-POS-008 | TC-POS-008 | - | 🔲 |

---

## 2. 业务规则追溯（BR）

| BR | Description | 违反后果 | 验证方式 | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | 同一 fill_id 不可重复更新仓位 | 拒绝重复 + emit warning | TC-POS-009 重复 fill_id 拒绝断言 | - | 🔲 |
| BR-002 | long 和 short 不可同时非零 | 交易系统保证（净持仓模式） | TC-POS-001 净持仓模式断言 | - | 🔲 |
| BR-003 | 仓位核对差异 > 5% 必须人工确认 | 告警升级为 critical | TC-POS-005 差异阈值告警断言 | - | 🔲 |
| BR-004 | 快照不可变（创建后不能修改） | 合规要求 | TC-POS-006 快照不可变断言 | - | 🔲 |
| BR-005 | markPrice 来源优先：最新成交 > 买一 > 上次 mark | 标注数据质量 | TC-POS-003 markPrice 降级断言 | - | 🔲 |

---

## 3. 非功能需求追溯（NFR）

| NFR | Description | 目标值 | 验证方式 | Task | Status |
|-----|-------------|--------|----------|------|--------|
| NFR-001 | Position Update 延迟 | < 10ms (p95) | Benchmark + p95 latency | - | 🔲 |
| NFR-002 | Snapshot (1K positions) 延迟 | < 50ms | Benchmark | - | 🔲 |
| NFR-003 | PnL Calculation 延迟 | < 1ms | Benchmark | - | 🔲 |
| NFR-004 | Reconciliation 延迟 | < 5s | Benchmark | - | 🔲 |
| NFR-005 | 测试覆盖率 | >= 80% | `go tool cover -func` | - | 🔲 |
| NFR-006 | 无硬编码密钥 | 全仓扫描零命中 | `gitleaks detect --no-git` | - | 🔲 |

---

## 4. TC → FR 反向追溯

| TC | FR/BR | Given/When/Then 场景 |
|----|-------|---------------------|
| TC-POS-001 | FR-001, BR-002 | FillEvent 触发仓位更新；netQty 和 avgPrice 正确计算；净持仓模式 |
| TC-POS-002 | FR-002 | Position(symbol,account,exchange) 返回最新仓位；空参数返回跨交易所聚合视图 |
| TC-POS-003 | FR-003, BR-005 | PnL 返回 realized/unrealized/total；基于 markPrice；markPrice 不可用时替代标注 stale |
| TC-POS-004 | FR-004 | Exposure 返回 totalExposure/byExchange/bySymbol 明细和 netDelta |
| TC-POS-005 | FR-005, BR-003 | Reconciliation 拉取交易所持仓对比本地；差异超阈值 emit alert；写入 audit log |
| TC-POS-006 | FR-006, BR-004 | Snapshot 生成只读快照；通过 observex 推送；间隔可配置；快照不可变 |
| TC-POS-007 | FR-007 | PositionHistory 返回指定时间段变更事件（timestamp/fill_id/deltaQty/price/reason） |
| TC-POS-008 | FR-008 | README H1 为 `# positionx`；go.mod 声明 `module github.com/ZoneCNH/positionx` |
| TC-POS-009 | BR-001 | 重复 fill_id 拒绝更新 + warning log |

---

## 5. 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 |
|----|-----------|-------------|
| AC-POS-001 | FR-001 | FillEvent 触发仓位更新；耗时 < 10ms(p95)；记录变更原因和 fill_id |
| AC-POS-002 | FR-002 | Position 返回最新仓位；空参数返回跨交易所聚合视图 |
| AC-POS-003 | FR-003 | PnL 返回 realized/unrealized/total；markPrice 不可用时替代标注 stale |
| AC-POS-004 | FR-004 | Exposure 返回 totalExposure/byExchange/bySymbol 和 netDelta |
| AC-POS-005 | FR-005 | Reconciliation 拉取交易所对比本地；差异超阈值 alert；写入 audit log |
| AC-POS-006 | FR-006 | Snapshot 生成只读快照；observex 推送；间隔可配置 |
| AC-POS-007 | FR-007 | PositionHistory 返回时间段内变更事件列表 |
| AC-POS-008 | FR-008 | README H1 为 `# positionx`；go.mod 声明 `module github.com/ZoneCNH/positionx` |

---

## 6. 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 8 | FR-001 ~ FR-008 |
| FR 有 AC 覆盖 | 8/8 (100%) | |
| FR 有 TC 覆盖 | 8/8 (100%) | |
| BR 总数 | 5 | BR-001 ~ BR-005 |
| BR 有 TC 覆盖 | 5/5 (100%) | |
| NFR 总数 | 6 | NFR-001 ~ NFR-006 |
| AC 总数 | 8 | AC-POS-001 ~ AC-POS-008 |
| TC 总数 | 9 | TC-POS-001 ~ TC-POS-009 |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-15 | v1.0 | 初始版本：8 FR + 5 BR + 6 NFR + 9 TC + 8 AC |
