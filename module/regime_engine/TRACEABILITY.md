# regime_engine 需求追溯矩阵

> 更新：2026-06-17
> 来源：module/regime_engine/SPEC.md
> 规范：docs/governance/TRACEABILITY.md

Last-Updated: 2026-06-29
---

## §1 FR 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | M×S 融合 | AC-REGIME_ENGINE-001 | TC-REGIME_ENGINE-001 | - | ⬜→§8 |
| FR-002 | DecisionCard | AC-REGIME_ENGINE-002 | TC-REGIME_ENGINE-002 | - | ⬜→§8 |
| FR-003 | 状态转移 | AC-REGIME_ENGINE-003 | TC-REGIME_ENGINE-003 | - | ⬜→§8 |
| FR-004 | 可解释性 | AC-REGIME_ENGINE-004 | TC-REGIME_ENGINE-004 | - | ⬜→§8 |

## §2 BR 追溯表

| BR | Description | TC | Task | Status |
|----|-------------|----|------|--------|
| BR-001 | fail-closed | TC-REGIME_ENGINE-005 | - | ⬜→§8 |
| BR-002 | 输出不可变 | TC-REGIME_ENGINE-006 | - | ⬜→§8 |
| BR-003 | No lookahead | TC-REGIME_ENGINE-007 | - | ⬜→§8 |

## §3 NFR 追溯表

| NFR | Description | 验证方式 | Task | Status |
|-----|-------------|----------|------|--------|
| - | 性能与安全基准 | - | - | ⬜→§8 |

## §4 TC→FR 反向追溯

| TC | FR/BR | 测试类型 | Status |
|----|-------|----------|--------|
| TC-REGIME_ENGINE-001 | FR-001 | 单元测试 | ⬜→§8 |
| TC-REGIME_ENGINE-002 | FR-002 | 单元测试 | ⬜→§8 |
| TC-REGIME_ENGINE-003 | FR-003 | 单元测试 | ⬜→§8 |
| TC-REGIME_ENGINE-004 | FR-004 | 单元测试 | ⬜→§8 |
| TC-REGIME_ENGINE-005 | BR-001 | 单元测试 | ⬜→§8 |
| TC-REGIME_ENGINE-006 | BR-002 | 单元测试 | ⬜→§8 |
| TC-REGIME_ENGINE-007 | BR-003 | 单元测试 | ⬜→§8 |

## §5 AC 注册表

| AC | FR | Description | TC | Status |
|----|----|-------------|----|--------|
| AC-REGIME_ENGINE-001 | FR-001 | M×S 融合 | TC-REGIME_ENGINE-001 | ⬜→§8 |
| AC-REGIME_ENGINE-002 | FR-002 | DecisionCard | TC-REGIME_ENGINE-002 | ⬜→§8 |
| AC-REGIME_ENGINE-003 | FR-003 | 状态转移 | TC-REGIME_ENGINE-003 | ⬜→§8 |
| AC-REGIME_ENGINE-004 | FR-004 | 可解释性 | TC-REGIME_ENGINE-004 | ⬜→§8 |

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 4 | 4 | 100% |
| BR | 3 | 3 | 100% |
| NFR | 1 | 1 | 100% |
| AC | 4 | 4 | 100% |
| TC | 4 | 4 | 100% |
| **合计** | **16** | **16** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-25 | v0.1.1 | 新增 §8 Evidence 投影：对齐 STATUS.md 外部 CI 声明 |
| 2026-06-17 | v0.1.0-draft | 初始基线：4 FR + 3 BR + 1 NFR + 7 TC + 4 AC |

---
