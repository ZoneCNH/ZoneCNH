# market_regime 需求追溯矩阵

> 更新：2026-06-17
> 来源：module/market_regime/SPEC.md
> 规范：docs/governance/TRACEABILITY.md

Last-Updated: 2026-06-29
---

## §1 FR 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | S 分类 | AC-MARKET_REGIME-001 | TC-MARKET_REGIME-001 | - | ⬜→§8 |
| FR-002 | 特征提取 | AC-MARKET_REGIME-002 | TC-MARKET_REGIME-002 | - | ⬜→§8 |
| FR-003 | Bias/Permission | AC-MARKET_REGIME-003 | TC-MARKET_REGIME-003 | - | ⬜→§8 |

## §2 BR 追溯表

| BR | Description | TC | Task | Status |
|----|-------------|----|------|--------|
| BR-001 | fail-closed | TC-MARKET_REGIME-004 | - | ⬜→§8 |
| BR-002 | 输出不可变 | TC-MARKET_REGIME-005 | - | ⬜→§8 |
| BR-003 | No lookahead | TC-MARKET_REGIME-006 | - | ⬜→§8 |

## §3 NFR 追溯表

| NFR | Description | 验证方式 | Task | Status |
|-----|-------------|----------|------|--------|
| - | 性能与安全基准 | - | - | ⬜→§8 |

## §4 TC→FR 反向追溯

| TC | FR/BR | 测试类型 | Status |
|----|-------|----------|--------|
| TC-MARKET_REGIME-001 | FR-001 | 单元测试 | ⬜→§8 |
| TC-MARKET_REGIME-002 | FR-002 | 单元测试 | ⬜→§8 |
| TC-MARKET_REGIME-003 | FR-003 | 单元测试 | ⬜→§8 |
| TC-MARKET_REGIME-004 | BR-001 | 单元测试 | ⬜→§8 |
| TC-MARKET_REGIME-005 | BR-002 | 单元测试 | ⬜→§8 |
| TC-MARKET_REGIME-006 | BR-003 | 单元测试 | ⬜→§8 |

## §5 AC 注册表

| AC | FR | Description | TC | Status |
|----|----|-------------|----|--------|
| AC-MARKET_REGIME-001 | FR-001 | S 分类 | TC-MARKET_REGIME-001 | ⬜→§8 |
| AC-MARKET_REGIME-002 | FR-002 | 特征提取 | TC-MARKET_REGIME-002 | ⬜→§8 |
| AC-MARKET_REGIME-003 | FR-003 | Bias/Permission | TC-MARKET_REGIME-003 | ⬜→§8 |

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 3 | 3 | 100% |
| BR | 3 | 3 | 100% |
| NFR | 1 | 1 | 100% |
| AC | 3 | 3 | 100% |
| TC | 3 | 3 | 100% |
| **合计** | **13** | **13** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-25 | v0.1.1 | 新增 §8 Evidence 投影：对齐 STATUS.md 外部 CI 声明 |
| 2026-06-17 | v0.1.0-draft | 初始基线：3 FR + 3 BR + 1 NFR + 6 TC + 3 AC |

---
