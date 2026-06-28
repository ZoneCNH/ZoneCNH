# factor_eval 需求追溯矩阵

> 更新：2026-06-17
> 来源：module/factor_eval/SPEC.md
> 规范：docs/governance/TRACEABILITY.md

Last-Updated: 2026-06-29
---

## §1 FR 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | IC 计算 | AC-FACTOR_EVAL-001 | TC-FACTOR_EVAL-001 | - | ⬜ |
| FR-002 | 分层回测 | AC-FACTOR_EVAL-002 | TC-FACTOR_EVAL-002 | - | ⬜ |
| FR-003 | 换手率 | AC-FACTOR_EVAL-003 | TC-FACTOR_EVAL-003 | - | ⬜ |
| FR-004 | 衰减分析 | AC-FACTOR_EVAL-004 | TC-FACTOR_EVAL-004 | - | ⬜ |
| FR-005 | 评估报告 | AC-FACTOR_EVAL-005 | TC-FACTOR_EVAL-005 | - | ⬜ |

## §2 BR 追溯表

| BR | Description | TC | Task | Status |
|----|-------------|----|------|--------|
| BR-001 | fail-closed | TC-FACTOR_EVAL-006 | - | ⬜ |
| BR-002 | 输出不可变 | TC-FACTOR_EVAL-007 | - | ⬜ |
| BR-003 | No lookahead | TC-FACTOR_EVAL-008 | - | ⬜ |

## §3 NFR 追溯表

| NFR | Description | 验证方式 | Task | Status |
|-----|-------------|----------|------|--------|
| - | 性能与安全基准 | - | - | ⬜ |

## §4 TC→FR 反向追溯

| TC | FR/BR | 测试类型 | Status |
|----|-------|----------|--------|
| TC-FACTOR_EVAL-001 | FR-001 | 单元测试 | ⬜ |
| TC-FACTOR_EVAL-002 | FR-002 | 单元测试 | ⬜ |
| TC-FACTOR_EVAL-003 | FR-003 | 单元测试 | ⬜ |
| TC-FACTOR_EVAL-004 | FR-004 | 单元测试 | ⬜ |
| TC-FACTOR_EVAL-005 | FR-005 | 单元测试 | ⬜ |
| TC-FACTOR_EVAL-006 | BR-001 | 单元测试 | ⬜ |
| TC-FACTOR_EVAL-007 | BR-002 | 单元测试 | ⬜ |
| TC-FACTOR_EVAL-008 | BR-003 | 单元测试 | ⬜ |

## §5 AC 注册表

| AC | FR | Description | TC | Status |
|----|----|-------------|----|--------|
| AC-FACTOR_EVAL-001 | FR-001 | IC 计算 | TC-FACTOR_EVAL-001 | ⬜ |
| AC-FACTOR_EVAL-002 | FR-002 | 分层回测 | TC-FACTOR_EVAL-002 | ⬜ |
| AC-FACTOR_EVAL-003 | FR-003 | 换手率 | TC-FACTOR_EVAL-003 | ⬜ |
| AC-FACTOR_EVAL-004 | FR-004 | 衰减分析 | TC-FACTOR_EVAL-004 | ⬜ |
| AC-FACTOR_EVAL-005 | FR-005 | 评估报告 | TC-FACTOR_EVAL-005 | ⬜ |

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 5 | 5 | 100% |
| BR | 3 | 3 | 100% |
| NFR | 1 | 1 | 100% |
| AC | 5 | 5 | 100% |
| TC | 5 | 5 | 100% |
| **合计** | **19** | **19** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-17 | v0.1.0-draft | 初始基线：5 FR + 3 BR + 1 NFR + 8 TC + 5 AC |
