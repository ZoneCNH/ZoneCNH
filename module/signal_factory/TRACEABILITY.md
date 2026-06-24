# signal_factory 需求追溯矩阵

> 更新：2026-06-17
> 来源：module/signal_factory/SPEC.md
> 规范：docs/governance/TRACEABILITY.md

---

## §1 FR 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | Signal 生成 | AC-SIGNAL_FACTORY-001 | TC-SIGNAL_FACTORY-001 | - | ⬜ |
| FR-002 | 信号组合 | AC-SIGNAL_FACTORY-002 | TC-SIGNAL_FACTORY-002 | - | ⬜ |
| FR-003 | Regime Gate | AC-SIGNAL_FACTORY-003 | TC-SIGNAL_FACTORY-003 | - | ⬜ |
| FR-004 | Signal DTO | AC-SIGNAL_FACTORY-004 | TC-SIGNAL_FACTORY-004 | - | ⬜ |

## §2 BR 追溯表

| BR | Description | TC | Task | Status |
|----|-------------|----|------|--------|
| BR-001 | DENY=FLAT | TC-SIGNAL_FACTORY-005 | - | ⬜ |
| BR-002 | 权重归一化 | TC-SIGNAL_FACTORY-006 | - | ⬜ |
| BR-003 | Confidence 阈值 | TC-SIGNAL_FACTORY-007 | - | ⬜ |

## §3 NFR 追溯表

| NFR | Description | 验证方式 | Task | Status |
|-----|-------------|----------|------|--------|
| - | 性能与安全基准 | - | - | ⬜ |

## §4 TC→FR 反向追溯

| TC | FR/BR | 测试类型 | Status |
|----|-------|----------|--------|
| TC-SIGNAL_FACTORY-001 | FR-001 | 单元测试 | ⬜ |
| TC-SIGNAL_FACTORY-002 | FR-002 | 单元测试 | ⬜ |
| TC-SIGNAL_FACTORY-003 | FR-003 | 单元测试 | ⬜ |
| TC-SIGNAL_FACTORY-004 | FR-004 | 单元测试 | ⬜ |
| TC-SIGNAL_FACTORY-005 | BR-001 | 单元测试 | ⬜ |
| TC-SIGNAL_FACTORY-006 | BR-002 | 单元测试 | ⬜ |
| TC-SIGNAL_FACTORY-007 | BR-003 | 单元测试 | ⬜ |

## §5 AC 注册表

| AC | FR | Description | TC | Status |
|----|----|-------------|----|--------|
| AC-SIGNAL_FACTORY-001 | FR-001 | Signal 生成 | TC-SIGNAL_FACTORY-001 | ⬜ |
| AC-SIGNAL_FACTORY-002 | FR-002 | 信号组合 | TC-SIGNAL_FACTORY-002 | ⬜ |
| AC-SIGNAL_FACTORY-003 | FR-003 | Regime Gate | TC-SIGNAL_FACTORY-003 | ⬜ |
| AC-SIGNAL_FACTORY-004 | FR-004 | Signal DTO | TC-SIGNAL_FACTORY-004 | ⬜ |

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
| 2026-06-25 | v0.1.1 | 新增 §8 Evidence 投影：对齐 STATUS.md 外部 CI 声明 |
| 2026-06-17 | v0.1.0-draft | 初始基线：4 FR + 3 BR + 1 NFR + 7 TC + 4 AC |

---

## §8 Evidence 投影（外部仓库 CI）

> 来源：`STATUS.md` 决策域明细表 `[KNOWN]`
> 认识论声明：以下为 STATUS.md 文档投影，非本会话独立验证；具体 TC↔test 文件映射与 CI run id 待外部仓库 evidence 归档。

| 投影项 | 数值 | 来源 | evidence 状态 |
|--------|------|------|---------------|
| signal_factory tests PASS | 5 | STATUS.md "5 tests PASS" | ⬜ 待归档（外部仓库 CI run id / test 文件路径） |
| 实现进度 | 40% | STATUS.md "████ 40%" | `[FRAME]` 投影 |
| DecisionCard→SignalIntent 链路 | 已打通 | STATUS.md "DecisionCard→SignalIntent[]，冲突门+强度映射" | ⬜ 待归档 |
| SPEC v1.0.0 | 23 节完整 | STATUS.md "SPEC v1.0.0 已补全（386 行 23 节完整，PR #847）" | `[KNOWN]` PR #847 |

> **未闭合项**：5 tests 对应 §4 的 7 TC 中哪些尚未确认；evidence 归档后应在 §4 Status 列逐条 ✅ 并填 evidence 路径。
