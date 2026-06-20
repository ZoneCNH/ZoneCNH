# regime_engine 需求追溯矩阵

> 更新：2026-06-17
> 来源：module/regime_engine/SPEC.md
> 规范：docs/governance/TRACEABILITY.md

---

## §1 FR 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | M×S 融合 | AC-REGIME_ENGINE-001 | TC-REGIME_ENGINE-001 | - | ⬜ |
| FR-002 | DecisionCard | AC-REGIME_ENGINE-002 | TC-REGIME_ENGINE-002 | - | ⬜ |
| FR-003 | 状态转移 | AC-REGIME_ENGINE-003 | TC-REGIME_ENGINE-003 | - | ⬜ |
| FR-004 | 可解释性 | AC-REGIME_ENGINE-004 | TC-REGIME_ENGINE-004 | - | ⬜ |

## §2 BR 追溯表

| BR | Description | TC | Task | Status |
|----|-------------|----|------|--------|
| BR-001 | fail-closed | TC-REGIME_ENGINE-005 | - | ⬜ |
| BR-002 | 输出不可变 | TC-REGIME_ENGINE-006 | - | ⬜ |
| BR-003 | No lookahead | TC-REGIME_ENGINE-007 | - | ⬜ |

## §3 NFR 追溯表

| NFR | Description | 验证方式 | Task | Status |
|-----|-------------|----------|------|--------|
| - | 性能与安全基准 | - | - | ⬜ |

## §4 TC→FR 反向追溯

| TC | FR/BR | 测试类型 | Status |
|----|-------|----------|--------|
| TC-REGIME_ENGINE-001 | FR-001 | 单元测试 | ⬜ |
| TC-REGIME_ENGINE-002 | FR-002 | 单元测试 | ⬜ |
| TC-REGIME_ENGINE-003 | FR-003 | 单元测试 | ⬜ |
| TC-REGIME_ENGINE-004 | FR-004 | 单元测试 | ⬜ |
| TC-REGIME_ENGINE-005 | BR-001 | 单元测试 | ⬜ |
| TC-REGIME_ENGINE-006 | BR-002 | 单元测试 | ⬜ |
| TC-REGIME_ENGINE-007 | BR-003 | 单元测试 | ⬜ |

## §5 AC 注册表

| AC | FR | Description | TC | Status |
|----|----|-------------|----|--------|
| AC-REGIME_ENGINE-001 | FR-001 | M×S 融合 | TC-REGIME_ENGINE-001 | ⬜ |
| AC-REGIME_ENGINE-002 | FR-002 | DecisionCard | TC-REGIME_ENGINE-002 | ⬜ |
| AC-REGIME_ENGINE-003 | FR-003 | 状态转移 | TC-REGIME_ENGINE-003 | ⬜ |
| AC-REGIME_ENGINE-004 | FR-004 | 可解释性 | TC-REGIME_ENGINE-004 | ⬜ |

## §6 覆盖率仪表盘

| 指标 | 数值 |
|------|------|
| FR 总数 | 4 |
| FR 有 AC 覆盖 | 4/4 (100%) |
| FR 有 TC 覆盖 | 4/4 (100%) |
| BR 总数 | 3 |
| BR 有 TC 覆盖 | 3/3 (100%) |
| NFR 总数 | 1 |
| AC 总数 | 4 |
| TC 总数 | 7 |

## §7 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-17 | v0.1.0-draft | 初始基线：4 FR + 3 BR + 1 NFR + 7 TC + 4 AC |
