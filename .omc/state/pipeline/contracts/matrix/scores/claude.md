# contracts Matrix 结构评分报告

- **评分平台**: Claude (claude)
- **评分时间**: 2026-06-14T09:30:00Z
- **评分对象**: `module/contracts/TRACEABILITY.md`
- **Spec 版本**: v1.0.1-spec
- **总分**: 100 / 100
- **红线**: 无
- **裁决**: Ready-candidate
- **置信度**: high

---

## 前置检查 (R0-R3)

### R0: 措辞强度分级

| 来源 | 约束 | 强度 | 判定 |
|------|------|------|------|
| TRACEABILITY spec §3 | 不得删除核心列 | **【硬】** | FR/BR/NFR 三表核心列齐全 ✓ |
| RUBRIC 红线: 缺失或为空 | **【硬】** | 不触发 |
| RUBRIC 红线: 无 AC 的 FR | **【硬】** | 不触发 |
| RUBRIC 红线: 无 TC 的 AC | **【硬】** | 不触发 |
| RUBRIC 红线: 无 FR 支撑的 TC | **【硬】** | 不触发 |
| RUBRIC 红线: FR 集合不一致 | **【硬】** | 不触发 |
| RUBRIC 红线: 不存在 Task ID | **【硬】** | 不触发 |

### R1: 验证链路跨表走查

遍历 TRACEABILITY.md §1-§5 全部表：

- **§1 FR 表**: 6 FR → 5 AC → 7 TC → 5 Task，全部闭合
  - FR-001/002 共享 AC-FR-001/TC-001（同为 Provider 端口编译期检查，合理共享）
  - FR-005 拥有 2 个 TC（TC-002 JSON round-trip + TC-007 不可变性）
- **§2 BR 表**: 10 BR，各有 AC + Verification + Task
- **§3 NFR 表**: 8 NFR，各有 AC + Verification（CI Gate/Documentation/TC）+ Task
- **§4 TC→FR 反向追溯**: 7 TC 全部映射回 ≥1 FR 或 BR
  - TC-006 → BR-004（端口方法数 3-5）：有 BR 支撑，非野生 TC
- **§5 AC 注册表**: 16 AC，全部有验证方式（TC 引用 / CI Gate / Documentation evidence）

### R2: 辅助元数据排除

§6 覆盖率仪表盘、§7 变更历史不参与评分。

### R3: 验证机制形式不做降级

以下形式均视为有效验证机制：
- TC-### 编号引用
- CI Gate（覆盖率检查、race 检测、vet/lint、gitleaks、breaking change、benchmark、PR 审查、go mod tidy）
- Documentation evidence
- 编译期检查（`var _ Interface = (*Impl)(nil)`）

---

## 维度评分

### 维度1: 表结构完整性 — 15/15

| 表 | 列结构 | 核心列 |
|----|--------|--------|
| §1 FR | `Requirement \| Description \| Acceptance Criteria \| Test Case \| Task \| Status` | 6/6 ✓ |
| §2 BR | `Requirement \| Description \| Acceptance Criteria \| Verification \| Task \| Status` | 6/6（Verification 为 TC 等价列） ✓ |
| §3 NFR | `Requirement \| Description \| Acceptance Criteria \| Verification \| Task \| Status` | 6/6 ✓ |

状态值全部为合法枚举 `Pending`。表头清晰规范。

### 维度2: FR 覆盖闭合 — 20/20

| 类型 | SPEC.md | TRACEABILITY.md | 匹配 |
|------|---------|-----------------|------|
| FR | FR-001~006 (6) | FR-001~006 (6) | ✓ |
| BR | BR-001~010 (10) | BR-001~010 (10) | ✓ |

一对一映射，无遗漏。

### 维度3: AC 闭合 — 15/15

6 条 FR 全部有 AC：
- FR-001 → AC-FR-001 ✓
- FR-002 → AC-FR-001（共享） ✓
- FR-003 → AC-FR-002 ✓
- FR-004 → AC-FR-003 ✓
- FR-005 → AC-FR-004 ✓
- FR-006 → AC-FR-005 ✓

10 条 BR 全部有 AC（通过 FR AC 引用或专用 AC-BR-NNN）。8 条 NFR 全部有 AC（AC-NFR-001~008）。

### 维度4: TC 闭合 — 15/15

16 个 AC 全部有验证机制。7 个 TC 编号唯一（TC-001~007）。CI Gate 验证（覆盖率/race/vet/lint/gitleaks/breaking change/benchmark/PR 审查）和 Documentation evidence 均为有效机制（R3 降级抑制）。

### 维度5: 反向追溯 — 10/10

| TC | 覆盖需求 | 类型 |
|----|----------|------|
| TC-001 | FR-001, FR-002, BR-007 | FR + BR |
| TC-002 | FR-005, BR-001, BR-009, NFR-008 | FR + BR + NFR |
| TC-003 | FR-006, BR-003, BR-010 | FR + BR |
| TC-004 | FR-004, BR-006 | FR + BR |
| TC-005 | FR-003 | FR |
| TC-006 | BR-004 | BR（端口方法数） |
| TC-007 | FR-005, BR-005 | FR + BR |

全部 TC 有需求支撑。TC-006 仅映射 BR-004（非 FR），但 BR 在 rubric 中明确为有效支撑（"每个 TC 映射回 ≥1 个 FR/BR"）。

### 维度6: Task 映射 — 10/10

全部 FR/BR/NFR 已分配 Task。5 个 Task 文件全部存在：

| Task | 覆盖 | 状态 |
|------|------|------|
| TASK-CONTRACTS-000 | BR-008, NFR-003, NFR-008（基础设施/横切） | ✓ |
| TASK-CONTRACTS-001 | FR-001, FR-002, BR-004, BR-007 | ✓ |
| TASK-CONTRACTS-002 | FR-003, FR-004, FR-005, BR-001, BR-005, BR-006, BR-009 | ✓ |
| TASK-CONTRACTS-003 | FR-006, BR-003, BR-010, NFR-001~006 | ✓ |
| TASK-CONTRACTS-004 | BR-002, NFR-004, NFR-007 | ✓ |

### 维度7: BR/NFR 覆盖 — 8/8

- 10 BR 各有违反后果（SPEC.md §8 表含违反后果列）+ 验证方式 ✓
- 8 NFR 各有度量验证手段：CI Gate（覆盖率/race/vet/lint/secret scan/breaking change/benchmark）、Documentation evidence、TC-002 ✓

### 维度8: 编号一致性 — 7/7

| 编号类型 | 范围 | 连续性 | 重复 |
|----------|------|--------|------|
| FR | 001-006 | 连续 | 无 |
| BR | 001-010 | 连续 | 无 |
| NFR | 001-008 | 连续 | 无 |
| TC | 001-007 | 连续 | 无 |
| AC | FR-001~005, BR-002/004/008, NFR-001~008 | 按前缀分段，间隙自解释 | 无 |

AC 编号按 FR/BR/NFR 前缀分段命名，BR 仅 3 条有独立 AC（其余复用 FR AC），间隙源于命名约定，非结构性跳号。

---

## 红线检查

| 红线条件 | 状态 |
|----------|------|
| TRACEABILITY.md 缺失或为空 | 不触发 |
| 存在无 AC 的 FR（盲区） | 不触发 |
| 存在无 TC 的 AC（验证缺失） | 不触发 |
| 存在无 FR 支撑的 TC（范围蔓延） | 不触发（TC-006→BR-004 有 BR 支撑） |
| 矩阵 FR 集合与 SPEC.md FR 集合不一致 | 不触发 |
| 引用了不存在的 Task ID | 不触发（TASK-CONTRACTS-000~004 全部存在） |

---

## 扣分账本

无扣分项。

---

## 结构亮点

1. **§4 TC→FR 反向追溯表**：7 TC 全部显式列出覆盖的 FR/BR/NFR，多重映射清晰
2. **§5 全局 AC 注册表**：16 AC 统一编号，前缀命名体系（FR/BR/NFR），验证方式列非空
3. **BR 表违反后果**：SPEC.md §8 和矩阵双重记录违反后果 + 错误行为
4. **FR-001/002 共享 AC/TC**：同质 Provider 端口合理共享，避免重复
5. **TASK-CONTRACTS-000**：显式建模横切关注点（基础设施/lint/错误格式），非遗漏

---

## 未验证项

无。全部 FR/BR/NFR/AC/TC/Task 链路已跨表走查并确认闭合。
