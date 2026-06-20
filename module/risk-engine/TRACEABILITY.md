# risk_engine 需求追溯矩阵

> 更新：2026-06-17
> 来源：module/risk_engine/SPEC.md
> 规范：docs/governance/TRACEABILITY.md

---

## §1 FR 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | 订单风控 | AC-RISK_ENGINE-001 | TC-RISK_ENGINE-001 | - | ⬜ |
| FR-002 | 回撤熔断 | AC-RISK_ENGINE-002 | TC-RISK_ENGINE-002 | - | ⬜ |
| FR-003 | 风险报告 | AC-RISK_ENGINE-003 | TC-RISK_ENGINE-003 | - | ⬜ |

## §2 BR 追溯表

| BR | Description | TC | Task | Status |
|----|-------------|----|------|--------|
| BR-001 | fail-closed | TC-RISK_ENGINE-004 | - | ⬜ |
| BR-002 | 输出不可变 | TC-RISK_ENGINE-005 | - | ⬜ |
| BR-003 | No lookahead | TC-RISK_ENGINE-006 | - | ⬜ |

## §3 NFR 追溯表

| NFR | Description | 验证方式 | Task | Status |
|-----|-------------|----------|------|--------|
| - | 性能与安全基准 | - | - | ⬜ |

## §4 TC→FR 反向追溯

| TC | FR/BR | 测试类型 | Status |
|----|-------|----------|--------|
| TC-RISK_ENGINE-001 | FR-001 | 单元测试 | ⬜ |
| TC-RISK_ENGINE-002 | FR-002 | 单元测试 | ⬜ |
| TC-RISK_ENGINE-003 | FR-003 | 单元测试 | ⬜ |
| TC-RISK_ENGINE-004 | BR-001 | 单元测试 | ⬜ |
| TC-RISK_ENGINE-005 | BR-002 | 单元测试 | ⬜ |
| TC-RISK_ENGINE-006 | BR-003 | 单元测试 | ⬜ |

## §5 AC 注册表

| AC | FR | Description | TC | Status |
|----|----|-------------|----|--------|
| AC-RISK_ENGINE-001 | FR-001 | 订单风控 | TC-RISK_ENGINE-001 | ⬜ |
| AC-RISK_ENGINE-002 | FR-002 | 回撤熔断 | TC-RISK_ENGINE-002 | ⬜ |
| AC-RISK_ENGINE-003 | FR-003 | 风险报告 | TC-RISK_ENGINE-003 | ⬜ |

## §6 覆盖率仪表盘

| 指标 | 数值 |
|------|------|
| FR 总数 | 3 |
| FR 有 AC 覆盖 | 3/3 (100%) |
| FR 有 TC 覆盖 | 3/3 (100%) |
| BR 总数 | 3 |
| BR 有 TC 覆盖 | 3/3 (100%) |
| NFR 总数 | 1 |
| AC 总数 | 3 |
| TC 总数 | 6 |

## §7 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-17 | v0.1.0-draft | 初始基线：3 FR + 3 BR + 1 NFR + 6 TC + 3 AC |
