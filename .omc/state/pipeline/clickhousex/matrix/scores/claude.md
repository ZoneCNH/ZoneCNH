# clickhousex Matrix 结构评分报告

- **评分平台**: Claude (claude)
- **评分时间**: 2026-06-14T10:00:00Z
- **评分对象**: `module/clickhousex/matrix/TRACEABILITY.md` (Matrix v1.1)
- **Spec 版本**: v1.0.1
- **总分**: 100 / 100
- **红线**: 无
- **裁决**: Ready-candidate
- **置信度**: high

---

## 前置检查 (R0-R3)

### R0: 措辞强度分级

| 来源 | 约束 | 强度 | 判定 |
|------|------|------|------|
| TRACEABILITY spec §3 | 不得删除核心列 | **【硬】** | FR 表 6/6 核心列齐全；BR/NFR 列名有变体但功能等价 ✓ |
| RUBRIC 红线: 缺失或为空 | **【硬】** | 不触发 |
| RUBRIC 红线: 无 AC 的 FR | **【硬】** | 不触发 |
| RUBRIC 红线: 无 TC 的 AC | **【硬】** | 不触发 |
| RUBRIC 红线: 无 FR 支撑的 TC | **【硬】** | 不触发 |
| RUBRIC 红线: FR 集合不一致 | **【硬】** | 不触发 |
| RUBRIC 红线: 不存在 Task ID | **【硬】** | 不触发 |

BR 表列结构: `BR | Description | 违反后果 | 验证方式 | Task | Status` — "违反后果" 含 AC 引用，"验证方式" 为 TC 等价列。
NFR 表列结构: `NFR | Description | 目标值 | 验证方式 | Task | Status` — "目标值" 为 AC 等价列。

### R1: 验证链路跨表走查

遍历 TRACEABILITY.md §1-§5 和 SPEC.md §7-§20：

- **§1 FR 表**: 8 FR → 19 AC 引用 → 7 TC，全部闭合
- **§2 BR 表**: 12 BR，各含违反后果 + AC 引用 + 验证方式 + Task
- **§3 NFR 表**: 18 NFR，各含目标值 + 验证方式（Benchmark / CI Gate / Profiling / Review）+ Task
- **§4 TC→FR 反向追溯**: 7 TC → 全部映射回 FR/BR
- **§5 AC 注册表**: 26 AC（AC-001~AC-026），全部有验收条件描述 + Task 分配
- **SPEC §16 Testing**: 26 AC 的测试场景 + 7 TC 的 Given/When/Then 用例 + Benchmark 目标

### R2: 辅助元数据排除

§6 覆盖率仪表盘、§7 变更历史不参与评分。

### R3: 验证机制形式不做降级

以下形式均视为有效：TC-### 引用、Benchmark（NFR-001~006）、Profiling（NFR-007）、`go tool cover`（NFR-008）、`go build`（NFR-009）、`go test -race`（NFR-010）、`go vet`（NFR-011）、`golangci-lint`（NFR-012）、`gitleaks`（NFR-013）、日志审查（NFR-014）、CI gate（NFR-015）、metrics 测试（NFR-016）、tracing 测试（NFR-017）、集成测试 gate（NFR-018）、Config.Validate()（BR-001）、go test 断言（BR-007）。

---

## 维度评分

### 维度1: 表结构完整性 — 15/15

| 表 | 列结构 | 核心列评估 |
|----|--------|-----------|
| §1 FR | `FR \| Description \| Acceptance Criteria \| Test Case \| Task \| Status` | 6/6 标准列 ✓ |
| §2 BR | `BR \| Description \| 违反后果 \| 验证方式 \| Task \| Status` | 功能等价（违反后果=AC引用 + 验证方式=TC等价） ✓ |
| §3 NFR | `NFR \| Description \| 目标值 \| 验证方式 \| Task \| Status` | 功能等价（目标值=AC等价 + 验证方式=TC等价） ✓ |

状态值使用兼容 emoji（⬜=Pending），符合 TRACEABILITY spec §6。表头清晰，附加说明完备。

### 维度2: FR 覆盖闭合 — 20/20

| 类型 | SPEC.md v1.0.1 | TRACEABILITY.md | 匹配 |
|------|---------------|-----------------|------|
| FR | FR-001~008 (8) | FR-001~008 (8) | ✓ |
| BR | BR-001~012 (12) | BR-001~012 (12) | ✓ |

一对一映射，无遗漏。

### 维度3: AC 闭合 — 15/15

8 FR 全部有 AC（共 19 个 AC 引用，含共享 AC）。AC-001~AC-026 注册表中 26 个 AC 全部非空。BR 表通过 "违反后果" 列引用 AC（如 AC-018~AC-026）。NFR 表通过 "目标值" 列内联验收条件。

### 维度4: TC 闭合 — 15/15

7 TC（TC-001~TC-007）编号唯一。26 AC 全部通过 FR/BR/NFR 表的验证方式列追溯到 TC/Benchmark/CI Gate/测试断言等可执行机制。Per R3 降级抑制，所有形式有效。

### 维度5: 反向追溯 — 10/10

| TC | 覆盖需求 | FR支撑 | BR支撑 |
|----|----------|--------|--------|
| TC-001 | FR-002, FR-003, FR-004, FR-007, BR-003 | 4 FR | 1 BR |
| TC-002 | FR-002, BR-004 | 1 FR | 1 BR |
| TC-003 | FR-004, BR-002 | 1 FR | 1 BR |
| TC-004 | FR-007, FR-008, BR-011 | 2 FR | 1 BR |
| TC-005 | FR-001 | 1 FR | — |
| TC-006 | FR-005, BR-005 | 1 FR | 1 BR |
| TC-007 | FR-006, BR-009 | 1 FR | 1 BR |

全部 TC 有 FR 或 BR 支撑，无野生 TC。§4 还包含 Given/When/Then 场景描述。

### 维度6: Task 映射 — 10/10

7 个 Task 文件全部存在：

| Task | 覆盖 | 状态 |
|------|------|------|
| TASK-CLICKHOUSEX-001 | FR-001, BR-001, NFR-006, NFR-014 | ✓ |
| TASK-CLICKHOUSEX-002 | FR-002, BR-003, BR-004, BR-006, BR-007, NFR-001 | ✓ |
| TASK-CLICKHOUSEX-003 | FR-003, FR-007, FR-008, BR-011, BR-012, NFR-004, NFR-005 | ✓ |
| TASK-CLICKHOUSEX-004 | FR-004, BR-002, BR-010, NFR-002, NFR-003 | ✓ |
| TASK-CLICKHOUSEX-005 | FR-005, FR-006, BR-005, BR-009 | ✓ |
| TASK-CLICKHOUSEX-006 | BR-008, NFR-016, NFR-017 | ✓ |
| TASK-CLICKHOUSEX-007 | NFR-007~013, NFR-015, NFR-018 | ✓ |

全部 FR/BR/NFR 已分配 Task。AC 注册表 §5 还额外提供 AC→Task 映射。

### 维度7: BR/NFR 覆盖 — 8/8

- 12 BR 各有违反后果（§2 "违反后果" 列）+ 验证方式 ✓
- 18 NFR 各有量化目标值（§3 "目标值" 列）+ 可执行验证方式 ✓
- NFR 覆盖全面：性能基准（6项）、CI 质量门禁（7项）、可观测验证（2项）、安全审查（2项）、集成测试（1项）

### 维度8: 编号一致性 — 7/7

| 编号类型 | 范围 | 连续性 | 重复 |
|----------|------|--------|------|
| FR | 001-008 | 连续 ✓ | 无 |
| BR | 001-012 | 连续 ✓ | 无 |
| NFR | 001-018 | 连续 ✓ | 无 |
| AC | 001-026 | 连续 ✓ | 无 |
| TC | 001-007 | 连续 ✓ | 无 |
| Task | 001-007 | 连续 ✓ | 无 |

---

## 红线检查

| 红线条件 | 状态 |
|----------|------|
| TRACEABILITY.md 缺失或为空 | 不触发 |
| 存在无 AC 的 FR（盲区） | 不触发 |
| 存在无 TC 的 AC（验证缺失） | 不触发（26 AC 全有验证） |
| 存在无 FR 支撑的 TC（范围蔓延） | 不触发（7 TC 全有 FR 或 BR 支撑） |
| 矩阵 FR 集合与 SPEC.md FR 集合不一致 | 不触发 |
| 引用了不存在的 Task ID | 不触发（TASK-CLICKHOUSEX-001~007 全部存在） |

---

## 扣分账本

无扣分项。

---

## 结构亮点

1. **BR 表 "违反后果" 列**：每条 BR 明确记录违规成本（如 "连接资源浪费或不足"、"SQL 注入漏洞"），远超 TRACEABILITY spec 最小要求
2. **NFR 表 "目标值" 列**：18 NFR 全部有量化指标（`< 10ms`、`< 1s`、`≥ 80%`、`零 data race` 等）
3. **§4 TC→FR 反向追溯含 Given/When/Then**：7 TC 全部有行为场景描述
4. **§5 AC 注册表双索引**：AC → 所属 FR/BR + AC → Task 双层映射
5. **18 NFR 覆盖全面**：性能(6) + CI 质量(7) + 可观测(2) + 安全(2) + 集成测试(1)
6. **emoji Status 兼容**：⬜=Pending 与 TRACEABILITY spec §6 兼容

---

## 未验证项

无。全部 FR/BR/NFR/AC/TC/Task 链路已跨表走查并确认闭合。
