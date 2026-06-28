# factor_engine 需求追溯矩阵

> 更新：2026-06-29
> 来源：module/factor_engine/SPEC.md
> 规范：docs/governance/TRACEABILITY.md

Last-Updated: 2026-06-29
---

## §1 FR 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | Factor 接口 | AC-FACTOR_ENGINE-001 | TC-FACTOR_ENGINE-001 | - | ⬜ |
| FR-002 | FactorRegistry | AC-FACTOR_ENGINE-002 | TC-FACTOR_ENGINE-002 | - | ⬜ |
| FR-003 | ComputePipeline | AC-FACTOR_ENGINE-003 | TC-FACTOR_ENGINE-003 | - | ⬜ |
| FR-004 | Input Validation | AC-FACTOR_ENGINE-004 | TC-FACTOR_ENGINE-004 | - | ⬜ |
| FR-005 | FactorOutput | AC-FACTOR_ENGINE-005 | TC-FACTOR_ENGINE-005 | - | ⬜ |
| FR-006 | Warmup | AC-FACTOR_ENGINE-006 | TC-FACTOR_ENGINE-006 | - | ⬜ |
| FR-007 | Observability | AC-FACTOR_ENGINE-007 | TC-FACTOR_ENGINE-007 | - | ⬜ |
| FR-008 | Module Identity | AC-FACTOR_ENGINE-008 | TC-FACTOR_ENGINE-008 | - | ⬜ |

## §2 BR 追溯表

| BR | Description | TC | Task | Status |
|----|-------------|----|------|--------|
| BR-001 | Name 唯一 | TC-FACTOR_ENGINE-009 | - | ⬜ |
| BR-002 | IsReliable=false 拒算 | TC-FACTOR_ENGINE-010 | - | ⬜ |
| BR-003 | 不可变输入 | TC-FACTOR_ENGINE-011 | - | ⬜ |
| BR-004 | 输出入 feature_store | TC-FACTOR_ENGINE-012 | - | ⬜ |
| BR-005 | No lookahead | TC-FACTOR_ENGINE-013 | - | ⬜ |

## §3 NFR 追溯表

| NFR | Description | 验证方式 | Task | Status |
|-----|-------------|----------|------|--------|
| NFR-FACTOR_ENGINE-001 | ('NFR-001', '计算延迟 <100μs') | Benchmark | - | ⬜ |
| NFR-FACTOR_ENGINE-002 | ('NFR-002', '并发延迟 <1ms') | Benchmark | - | ⬜ |
| NFR-FACTOR_ENGINE-003 | ('NFR-003', '覆盖率 ≥80%') | Benchmark | - | ⬜ |
| NFR-FACTOR_ENGINE-004 | ('NFR-004', '无密钥') | Benchmark | - | ⬜ |

## §4 TC→FR 反向追溯

| TC | FR/BR | 测试类型 | Status |
|----|-------|----------|--------|
| TC-FACTOR_ENGINE-001 | FR-001 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-002 | FR-002 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-003 | FR-003 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-004 | FR-004 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-005 | FR-005 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-006 | FR-006 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-007 | FR-007 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-008 | FR-008 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-009 | BR-001 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-010 | BR-002 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-011 | BR-003 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-012 | BR-004 | 单元测试 | ⬜ |
| TC-FACTOR_ENGINE-013 | BR-005 | 单元测试 | ⬜ |

## §5 AC 注册表

| AC | FR | Description | TC | Status |
|----|----|-------------|----|--------|
| AC-FACTOR_ENGINE-001 | FR-001 | Factor 接口 | TC-FACTOR_ENGINE-001 | ⬜ |
| AC-FACTOR_ENGINE-002 | FR-002 | FactorRegistry | TC-FACTOR_ENGINE-002 | ⬜ |
| AC-FACTOR_ENGINE-003 | FR-003 | ComputePipeline | TC-FACTOR_ENGINE-003 | ⬜ |
| AC-FACTOR_ENGINE-004 | FR-004 | Input Validation | TC-FACTOR_ENGINE-004 | ⬜ |
| AC-FACTOR_ENGINE-005 | FR-005 | FactorOutput | TC-FACTOR_ENGINE-005 | ⬜ |
| AC-FACTOR_ENGINE-006 | FR-006 | Warmup | TC-FACTOR_ENGINE-006 | ⬜ |
| AC-FACTOR_ENGINE-007 | FR-007 | Observability | TC-FACTOR_ENGINE-007 | ⬜ |
| AC-FACTOR_ENGINE-008 | FR-008 | Module Identity | TC-FACTOR_ENGINE-008 | ⬜ |

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 8 | 8 | 100% |
| BR | 5 | 5 | 100% |
| NFR | 4 | 4 | 100% |
| AC | 8 | 8 | 100% |
| TC | 8 | 8 | 100% |
| **合计** | **33** | **33** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-17 | v0.1.0-draft | 初始基线：8 FR + 5 BR + 4 NFR + 13 TC + 8 AC |
