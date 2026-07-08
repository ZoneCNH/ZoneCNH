# FRED 模块计划与任务层深度分析报告

**分析时间**：2026-07-08  
**覆盖制品**：3 份计划文件、5 份 Task 文件、SPEC.md v1.1.0、TRACEABILITY.md、prompt/README.md

---

## 执行摘要

| 维度 | 评级 | 主要问题 |
|------|------|----------|
| 计划完整性 | ⚠️ 中等 | 主计划无时间估算/风险计划；子计划 TC 编号与根矩阵脱节 |
| Task Spec 质量 | ⚠️ 中等偏低 | 所有 Task 缺失 Scope/Non-scope 节和独立验证命令节；TASK-FRED-001 过于笼统 |
| Task 覆盖度 | ✅ 基本完整 | 16 个 FR、10 个 BR 全部有 Task 对应，但缺集成/性能/运维专项 Task |
| 缺失 Task | ❌ 明显缺失 | 缺集成测试 Task、性能 Task、NFR Task、release calendar Task |
| prompt/ 目录 | ❌ 完全空置 | 仅有 README.md，无任何 Context Package 文件 |
| 实现可行性 | ✅ 总体可行 | 技术要求合理，但 4 个 OPEN issue 影响闭环 |

---

## 计划完整性评估

### 主计划（plan/PLAN.md）

**优点**：阶段划分（0→5）逻辑清晰，约束表（C-001~C-006）明确定义边界，依赖关系形成有向无环图。

**缺陷**：

| 缺失项 | 影响 |
|--------|------|
| 无任何时间估算 | 无法评估进度偏差 |
| 无风险计划 | OPEN-004/008/009 无 fallback 策略 |
| 阶段0无专属 Task | 规格冻结工作不可追溯 |

### 子计划关键缺陷

| 问题 | client/PLAN.md | server/PLAN.md |
|------|---------------|---------------|
| TC 编号孤岛 | TC-C001~C005 在根矩阵不存在 | TC-S001~S006 不存在于根规格 |
| matrix 路径错误 | 引用 matrix/client/TRACEABILITY.md（不存在） | 引用 matrix/server/TRACEABILITY.md（不存在） |
| 无时间估算 | ❌ | ❌ |
| 缺专项 Task | — | P6"集成闭合"无对应 Task 文件 |

---

## Task Spec 质量问题清单

### TASK-FRED-001（根骨架）— ❌ 严重不足

- Covers 使用"All FR/BR/NFR"，无具体 ID 🔴
- 无 Scope/Non-scope 节 🔴
- 无验证命令节（boundary-gates 命令缺失）🔴
- Objective 描述全模块目标而非骨架范畴 🟡

### CLIENT-001 / CLIENT-002 — ⚠️ 中等

- FR 编号使用 FR-C* 命名，与根矩阵脱节 🔴
- 无 Scope/Non-scope 节 🔴
- 无独立验证命令节 🔴

### SERVER-001 — ⚠️ 中等

- FR/BR 全为子规格命名 FR-S*，无根层追溯 🔴
- FR-S011 与 SERVER-002 重叠（双重归属）🔴
- 无 Scope/Non-scope 节 🔴
- 无独立验证命令节 🔴

### SERVER-002 — ⚠️ 中等偏好

- FR 命名混用根规格与子规格两套体系 🟡
- 无 Scope/Non-scope 节 🔴
- 无独立验证命令节 🔴

---

## 缺失 Task 清单

| 优先级 | 建议 Task ID | 理由 | 关联 OPEN |
|--------|-------------|------|-----------|
| 🔴 P0 | TASK-FRED-INTEGRATION-001 | server PLAN.md P6"集成闭合"有专阶段但无 Task | OPEN-004, 005 |
| 🔴 P0 | TASK-FRED-PERF-001 | 6 条量化性能预算无 Task 承接 | OPEN-008 |
| 🟡 P1 | TASK-FRED-OPS-001 | §18/§19 NFR 覆盖过于笼统 | — |
| 🟡 P1 | TASK-FRED-CLIENT-003 | Release Calendar 调度触发无 Task | OPEN-009 |
| 🟡 P1 | TASK-FRED-SERVER-003 | ms_brain 集成契约验证 | OPEN-005 |
| 🟢 P2 | TASK-FRED-PHASE0-001 | 规格冻结与差异盘点存档 | OPEN-001 |

---

## prompt/ 目录评估

**现状**：仅有 README.md 规范，无任何 PROMPT-FRED-*.md 实体文件。

**缺失的 Context Package**：

| 优先级 | 文件名 | 对应 Task |
|--------|--------|-----------|
| 🔴 P0 | PROMPT-FRED-ROOT-001.md | TASK-FRED-001 |
| 🔴 P0 | PROMPT-FRED-CLIENT-001.md | TASK-FRED-CLIENT-001 |
| 🔴 P0 | PROMPT-FRED-SERVER-001.md | TASK-FRED-SERVER-001 |
| 🟡 P1 | PROMPT-FRED-CLIENT-002.md | TASK-FRED-CLIENT-002 |
| 🟡 P1 | PROMPT-FRED-SERVER-002.md | TASK-FRED-SERVER-002 |

---

## 改进建议

### P0（立即修复）

1. **统一 FR/BR 编号体系**：所有 Task Covers 节引用根规格 ID（FR-001..016），子规格命名在括号中补注
2. **为每个 Task 添加 Scope/Non-scope 节**
3. **为每个 Task 添加独立 Verification Commands 节**
4. **修复子计划 matrix 路径引用错误**（改为 `../../matrix/TRACEABILITY.md`）

### P1（本阶段完成）

5. TASK-FRED-001 Covers 节重写，替换"All"为具体 ID
6. 解决 FR-S011 跨 Task 重叠（二选一归属）
7. 主计划补充风险章节（覆盖 OPEN-004/005/008/009）

### P2（后续迭代）

8. 补齐 prompt/ Context Package（5 个文件）
9. SERVER-001 AC 增加量化覆盖率阈值
10. 主计划添加时间估算占位列
