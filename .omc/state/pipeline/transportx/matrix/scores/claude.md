# transportx Matrix 结构评分报告（重新评分）

- **评分平台**: Claude (claude)
- **评分时间**: 2026-06-14T09:00:00Z
- **评分对象**: `module/transportx/matrix/TRACEABILITY.md` (post-#177 fix)
- **Spec 版本**: v1.1.1
- **总分**: 100 / 100
- **红线**: 无
- **裁决**: Ready-candidate
- **置信度**: high

---

## 前置检查 (R0-R3)

### R0: 措辞强度分级

| 来源 | 约束 | 强度 | 判定 |
|------|------|------|------|
| TRACEABILITY spec §3 | 不得删除核心列 | **【硬】** | 6 核心列全齐（Requirement/Description/AC/TC/Task/Status） ✓ |
| RUBRIC 红线: 缺失或为空 | **【硬】** | 不触发 |
| RUBRIC 红线: 无 AC 的 FR | **【硬】** | 不触发 |
| RUBRIC 红线: 无 TC 的 AC | **【硬】** | 不触发 |
| RUBRIC 红线: 无 FR 的 TC | **【硬】** | 不触发 |
| RUBRIC 红线: FR 集合不一致 | **【硬】** | 不触发 |
| RUBRIC 红线: 不存在 Task ID | **【硬】** | 不触发 |

全部【硬】约束满足，无需扣分。

### R1: 验证链路跨表走查

遍历 TRACEABILITY.md §1-§4 和 SPEC.md §7-§19 全部验证列：

- **§1 FR 表**: 25 FR → 25 AC → 25 TC → 25 Task，全部闭合 ✓
- **§2 BR 表**: 18 BR，各含验证方式 + 错误码 ✓
- **§3 NFR 表**: 12 NFR，各含验证手段（TC/Benchmark/BR引用/Manual） ✓
- **§4 Gate 表**: 12 Gate，各含覆盖范围 + 证据 ✓
- **SPEC §13 AC 表**: 25 AC，各含可执行验证命令 ✓
- **SPEC §19 Test Matrix**: 25 TC，各含覆盖 FR + 命令 ✓

### R2: 辅助元数据排除

§5 Coverage Notes 确认为辅助元数据，不参与评分。 ✓

### R3: 验证机制形式不做降级

TC 引用、CI Gate、Benchmark、BR 引用、Manual review 均视为有效验证机制。 ✓

---

## 维度评分

### 维度1: 表结构完整性 — 15/15

FR 表列: `Requirement | Description | Type | Source | Acceptance Criteria | Test Case | Task | Status`

TRACEABILITY spec §3 核心列 6/6 齐全，另增 Type/Source 补充列。
BR 表、NFR 表、Gate 表结构完整。状态值全部为合法枚举 `Pending`。

### 维度2: FR 覆盖闭合 — 20/20

SPEC.md FR-001~025 (25) = TRACEABILITY.md FR-001~025 (25)
SPEC.md BR-001~018 (18) = TRACEABILITY.md BR-001~018 (18)
一对一映射，无遗漏。

### 维度3: AC 闭合 — 15/15

每条 FR 对应 1 个 AC。全部 AC 在 SPEC.md §13 有可执行验证命令。

### 维度4: TC 闭合 — 15/15

每条 AC 对应 1 个 TC。TC 编号无重复。全部 TC 在 SPEC.md §19 有可执行命令。

### 维度5: 反向追溯 — 10/10

TC-001 → FR-001, ..., TC-025 → FR-025。全部 TC 有 FR 支撑，无野生 TC。

### 维度6: Task 映射 — 10/10

25 条 FR 全部映射到 TASK-TRANSPORTX-NNN。25 个任务文件均存在且双向交叉引用验证通过。多对多映射正确（如 FR-002 -> TASK-001, TASK-006）。

### 维度7: BR/NFR 覆盖 — 8/8

18 BR 各有错误码 + 验证方式。12 NFR 各有度量验证手段。

### 维度8: 编号一致性 — 7/7

FR/BR/NFR/AC/TC/Gate 编号全部连续、无重复、无跳号。

---

## 红线检查

| 红线条件 | 状态 |
|----------|------|
| TRACEABILITY.md 缺失或为空 | 不触发 |
| 存在无 AC 的 FR（盲区） | 不触发 |
| 存在无 TC 的 AC（验证缺失） | 不触发 |
| 存在无 FR 支撑的 TC（范围蔓延） | 不触发 |
| 矩阵 FR 集合与 SPEC.md FR 集合不一致 | 不触发 |
| 引用了不存在的 Task ID | 不触发（25 个 Task 文件全部存在） |

---

## 扣分账本

无扣分项。

---

## 与首次评分的差异

| 扣分项 | 首次评分 | 修复后 |
|--------|----------|--------|
| DED-001: 缺 Description 列 | -1 (LOW) | 已修复 — 25 条中文描述 |
| DED-002: 缺 Task 列 | -1 (LOW) | 已修复 — 25 条 Task 映射 |
| **总分** | **98** | **100** |

修复 PR: [#177](https://github.com/ZoneCNH/ZoneCNH/pull/177) (squash merged)
