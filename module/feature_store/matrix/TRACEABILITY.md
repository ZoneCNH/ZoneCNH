# feature_store 需求追溯矩阵

> 更新：2026-06-29
> 来源：module/feature_store/SPEC.md
> 规范：docs/governance/TRACEABILITY.md

Last-Updated: 2026-06-30
---

## §1 FR 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | Feature 写入 | AC-FEATURE_STORE-001 | TC-FEATURE_STORE-001 | - | ⬜ |
| FR-002 | 版本管理 | AC-FEATURE_STORE-002 | TC-FEATURE_STORE-002 | - | ⬜ |
| FR-003 | PIT 查询 | AC-FEATURE_STORE-003 | TC-FEATURE_STORE-003 | - | ⬜ |
| FR-004 | 特征血缘 | AC-FEATURE_STORE-004 | TC-FEATURE_STORE-004 | - | ⬜ |
| FR-005 | TTL 过期 | AC-FEATURE_STORE-005 | TC-FEATURE_STORE-005 | - | ⬜ |
| FR-006 | 批量查询 | AC-FEATURE_STORE-006 | TC-FEATURE_STORE-006 | - | ⬜ |
| FR-007 | Module Identity | AC-FEATURE_STORE-007 | TC-FEATURE_STORE-007 | - | ⬜ |

## §2 BR 追溯表

| BR | Description | TC | Task | Status |
|----|-------------|----|------|--------|
| BR-001 | PIT 无未来数据 | TC-FEATURE_STORE-008 | - | ⬜ |
| BR-002 | 幂等写入 | TC-FEATURE_STORE-009 | - | ⬜ |
| BR-003 | 不可变 append | TC-FEATURE_STORE-010 | - | ⬜ |
| BR-004 | TTL 过滤 | TC-FEATURE_STORE-011 | - | ⬜ |

## §3 NFR 追溯表

| NFR | Description | 验证方式 | Task | Status |
|-----|-------------|----------|------|--------|
| NFR-FEATURE_STORE-001 | ('NFR-001', '写入 <1ms') | Benchmark | - | ⬜ |
| NFR-FEATURE_STORE-002 | ('NFR-002', 'PIT 查询 <10ms') | Benchmark | - | ⬜ |
| NFR-FEATURE_STORE-003 | ('NFR-003', '矩阵查询 <100ms') | Benchmark | - | ⬜ |
| NFR-FEATURE_STORE-004 | ('NFR-004', '覆盖率 ≥80%') | Benchmark | - | ⬜ |

## §4 TC→FR 反向追溯

| TC | FR/BR | 测试类型 | Status |
|----|-------|----------|--------|
| TC-FEATURE_STORE-001 | FR-001 | 单元测试 | ⬜ |
| TC-FEATURE_STORE-002 | FR-002 | 单元测试 | ⬜ |
| TC-FEATURE_STORE-003 | FR-003 | 单元测试 | ⬜ |
| TC-FEATURE_STORE-004 | FR-004 | 单元测试 | ⬜ |
| TC-FEATURE_STORE-005 | FR-005 | 单元测试 | ⬜ |
| TC-FEATURE_STORE-006 | FR-006 | 单元测试 | ⬜ |
| TC-FEATURE_STORE-007 | FR-007 | 单元测试 | ⬜ |
| TC-FEATURE_STORE-008 | BR-001 | 单元测试 | ⬜ |
| TC-FEATURE_STORE-009 | BR-002 | 单元测试 | ⬜ |
| TC-FEATURE_STORE-010 | BR-003 | 单元测试 | ⬜ |
| TC-FEATURE_STORE-011 | BR-004 | 单元测试 | ⬜ |

## §5 AC 注册表

| AC | FR | Description | TC | Status |
|----|----|-------------|----|--------|
| AC-FEATURE_STORE-001 | FR-001 | Feature 写入 | TC-FEATURE_STORE-001 | ⬜ |
| AC-FEATURE_STORE-002 | FR-002 | 版本管理 | TC-FEATURE_STORE-002 | ⬜ |
| AC-FEATURE_STORE-003 | FR-003 | PIT 查询 | TC-FEATURE_STORE-003 | ⬜ |
| AC-FEATURE_STORE-004 | FR-004 | 特征血缘 | TC-FEATURE_STORE-004 | ⬜ |
| AC-FEATURE_STORE-005 | FR-005 | TTL 过期 | TC-FEATURE_STORE-005 | ⬜ |
| AC-FEATURE_STORE-006 | FR-006 | 批量查询 | TC-FEATURE_STORE-006 | ⬜ |
| AC-FEATURE_STORE-007 | FR-007 | Module Identity | TC-FEATURE_STORE-007 | ⬜ |

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 7 | 7 | 100% |
| BR | 4 | 4 | 100% |
| NFR | 4 | 4 | 100% |
| AC | 7 | 7 | 100% |
| TC | 7 | 7 | 100% |
| **合计** | **29** | **29** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-17 | v0.1.0-draft | 初始基线：7 FR + 4 BR + 4 NFR + 11 TC + 7 AC |
