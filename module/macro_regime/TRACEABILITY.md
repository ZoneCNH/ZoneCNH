# macro_regime 需求追溯矩阵

> 更新：2026-06-17
> 来源：module/macro_regime/SPEC.md
> 规范：docs/governance/TRACEABILITY.md

---

## §1 FR 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | M 分类 | AC-MACRO_REGIME-001 | TC-MACRO_REGIME-001 | - | ⬜→§8 |
| FR-002 | Transition 检测 | AC-MACRO_REGIME-002 | TC-MACRO_REGIME-002 | - | ⬜→§8 |

## §2 BR 追溯表

| BR | Description | TC | Task | Status |
|----|-------------|----|------|--------|
| BR-001 | fail-closed | TC-MACRO_REGIME-003 | - | ⬜→§8 |
| BR-002 | 输出不可变 | TC-MACRO_REGIME-004 | - | ⬜→§8 |
| BR-003 | No lookahead | TC-MACRO_REGIME-005 | - | ⬜→§8 |

## §3 NFR 追溯表

| NFR | Description | 验证方式 | Task | Status |
|-----|-------------|----------|------|--------|
| - | 性能与安全基准 | - | - | ⬜→§8 |

## §4 TC→FR 反向追溯

| TC | FR/BR | 测试类型 | Status |
|----|-------|----------|--------|
| TC-MACRO_REGIME-001 | FR-001 | 单元测试 | ⬜→§8 |
| TC-MACRO_REGIME-002 | FR-002 | 单元测试 | ⬜→§8 |
| TC-MACRO_REGIME-003 | BR-001 | 单元测试 | ⬜→§8 |
| TC-MACRO_REGIME-004 | BR-002 | 单元测试 | ⬜→§8 |
| TC-MACRO_REGIME-005 | BR-003 | 单元测试 | ⬜→§8 |

## §5 AC 注册表

| AC | FR | Description | TC | Status |
|----|----|-------------|----|--------|
| AC-MACRO_REGIME-001 | FR-001 | M 分类 | TC-MACRO_REGIME-001 | ⬜→§8 |
| AC-MACRO_REGIME-002 | FR-002 | Transition 检测 | TC-MACRO_REGIME-002 | ⬜→§8 |

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
| 2026-06-25 | v0.1.1 | 新增 §8 Evidence 投影：对齐 STATUS.md 外部 CI 声明 |
| 2026-06-17 | v0.1.0-draft | 初始基线：2 FR + 3 BR + 1 NFR + 5 TC + 2 AC |

---

## §8 Evidence 投影（外部仓库 CI）

> 来源：`STATUS.md` 分析域明细表 `[KNOWN]`
> 认识论声明：以下为 STATUS.md 文档投影，非本会话独立验证；具体 TC↔test 文件映射与 CI run id 待外部仓库 evidence 归档。

| 投影项 | 数值 | 来源 | evidence 状态 |
|--------|------|------|---------------|
| macro_regime tests PASS | 13 | STATUS.md "13 tests PASS" | ⬜ 待归档（外部仓库 CI run id / test 文件路径） |
| 实现进度 | 70% | STATUS.md "████████ 70%" | `[FRAME]` 投影 |
| M1-M7 引擎 | MacroInformationSet mapper+ClassifyFromSet | STATUS.md "MacroInformationSet mapper+ClassifyFromSet" | ⬜ 待归档 |

> **未闭合项**：13 tests 与 §4 的 5 TC 映射未确认（13 tests 可能含 TC 之外的边界/集成测试）；evidence 归档后应在 §4 Status 列逐条 ✅ 并填 evidence 路径。
