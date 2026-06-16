# settlement 需求追溯矩阵

> 更新：2026-06-17
> 来源：module/settlement/SPEC.md
> 规范：docs/governance/TRACEABILITY.md

---

## §1 FR 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | 资金对账 | AC-SETTLEMENT-001 | TC-SETTLEMENT-001 | - | ⬜ |
| FR-002 | 手续费核算 | AC-SETTLEMENT-002 | TC-SETTLEMENT-002 | - | ⬜ |

## §2 BR 追溯表

| BR | Description | TC | Task | Status |
|----|-------------|----|------|--------|
| BR-001 | fail-closed | TC-SETTLEMENT-003 | - | ⬜ |
| BR-002 | 输出不可变 | TC-SETTLEMENT-004 | - | ⬜ |
| BR-003 | No lookahead | TC-SETTLEMENT-005 | - | ⬜ |

## §3 NFR 追溯表

| NFR | Description | 验证方式 | Task | Status |
|-----|-------------|----------|------|--------|
| - | 性能与安全基准 | - | - | ⬜ |

## §4 TC→FR 反向追溯

| TC | FR/BR | 测试类型 | Status |
|----|-------|----------|--------|
| TC-SETTLEMENT-001 | FR-001 | 单元测试 | ⬜ |
| TC-SETTLEMENT-002 | FR-002 | 单元测试 | ⬜ |
| TC-SETTLEMENT-003 | BR-001 | 单元测试 | ⬜ |
| TC-SETTLEMENT-004 | BR-002 | 单元测试 | ⬜ |
| TC-SETTLEMENT-005 | BR-003 | 单元测试 | ⬜ |

## §5 AC 注册表

| AC | FR | Description | TC | Status |
|----|----|-------------|----|--------|
| AC-SETTLEMENT-001 | FR-001 | 资金对账 | TC-SETTLEMENT-001 | ⬜ |
| AC-SETTLEMENT-002 | FR-002 | 手续费核算 | TC-SETTLEMENT-002 | ⬜ |

## §6 覆盖率仪表盘

| 指标 | 数值 |
|------|------|
| FR 总数 | 2 |
| FR 有 AC 覆盖 | 2/2 (100%) |
| FR 有 TC 覆盖 | 2/2 (100%) |
| BR 总数 | 3 |
| BR 有 TC 覆盖 | 3/3 (100%) |
| NFR 总数 | 1 |
| AC 总数 | 2 |
| TC 总数 | 5 |

## §7 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-17 | v0.1.0-draft | 初始基线：2 FR + 3 BR + 1 NFR + 5 TC + 2 AC |
