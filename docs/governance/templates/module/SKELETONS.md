# FoundationX 模块管线骨架模板

> 用法: 从本文档对应节复制到 `module/{MODULE}/` 目录。
> 当前包含: DESIGN.md + PLAN.md + TRACEABILITY.md 骨架。
> SPEC.md 骨架见 `SPEC.md.skeleton`。

---

## DESIGN.md 骨架

```markdown
# {MODULE} 设计方案

> Design ID: DESIGN-{MODULE}-v1
> Source Spec: [SPEC.md](./SPEC.md) {VERSION}
> 生成日期：{DATE}

---

## 1. 架构概述

{MODULE} 是 {LAYER_DESCRIPTION}

```
┌──────────────────────────────────────────────┐
│               {ARCHITECTURE_DIAGRAM}           │
└──────────────────────────────────────────────┘
```

### 1.1 设计原则

1. {PRINCIPLE_1}
2. {PRINCIPLE_2}

---

## 2. 组件设计

### 2.1 {COMPONENT_NAME}

**职责**：{RESPONSIBILITY}
**核心文件**：`{FILE}` — {DESCRIPTION}
**设计决策**：{DECISION}

---

## 3. 数据流

```
{INPUT} → {PROCESSING} → {OUTPUT}
```

---

## 4. 关键技术决策 (ADR)

| 决策 | 选项 | 选择 | 理由 |
|------|------|------|------|
| {DECISION} | {OPTIONS} | {CHOICE} | {RATIONALE} |

---

## 5. 依赖关系

| 依赖 | 类型 | 用途 |
|------|------|------|
| stdlib | 运行时 | {USAGE} |

---

## 6. 错误处理

| 错误类型 | 处理方式 |
|----------|----------|
| {ERROR} | {HANDLING} |

---

## 7. 输出格式

见 SPEC.md §9 Interface Contract。

---

## 8. 技术风险

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| {RISK} | {PROB} | {IMPACT} | {MITIGATION} |

---

## 9. 设计约束

- {CONSTRAINT}

---

## 10. 测试策略

| 层级 | 覆盖 | 工具 |
|------|------|------|
| 单元测试 | 80%+ | `go test -race` |

---

## 11. 可扩展性

- {EXTENSION_POINT}
```

---

## PLAN.md 骨架

```markdown
# {MODULE} 实现计划

> 来源：[SPEC.md](./SPEC.md) {VERSION}
> 生成日期：{DATE}

---

## 1. 依赖 DAG

\`\`\`text
{ROOT_TASK}
│
├── {TASK_A} ──┐
├── {TASK_B}   │
└── {TASK_C}   │
    │           │
    └── {TASK_D} ──┘
\`\`\`

---

## 2. 实现顺序

### Phase 0: 骨架 (N tasks)

| Task | 交付物 | 依赖 | Effort |
|------|--------|------|--------|
| {TASK_ID} | {DELIVERABLES} | — | {HOURS}h |

**里程碑**：{MILESTONE}

### Phase 1: 核心 (N tasks, 可并行)

| Task | 交付物 | 依赖 | Effort |
|------|--------|------|--------|
| {TASK_ID} | {DELIVERABLES} | {DEPS} | {HOURS}h |

**并行度**：{N}

---

## 3. 关键路径

\`\`\`text
{TASK_A} → {TASK_B} → {TASK_C}
\`\`\`
**工期**：{HOURS}h

---

## 4. 并行策略

| 策略 | 总工时 |
|------|--------|
| 全串行 | {SERIAL}h |
| 最大并行 | {PARALLEL}h |

---

## 5. 文件冲突分析

| 文件 | 创建 Task | 冲突风险 |
|------|-----------|----------|
| {FILE} | {TASK} | 无 |

---

## 6. 测试策略

| 测试类型 | 覆盖 Task | 工具 |
|----------|-----------|------|
| 单元测试 | {TASKS} | `go test -race` |

---

## 7. 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|------|:----:|:----:|------|
| {RISK} | {P} | {I} | {MITIGATION} |

---

## 8. 总工时估算

| Phase | Tasks | 串行 | 并行 |
|-------|-------|------|------|
| Phase 0 | {N} | {H}h | {H}h |
| **总计** | **{TOTAL}** | **{SERIAL}h** | **{PARALLEL}h** |
```

---

## TRACEABILITY.md 骨架

```markdown
# {MODULE} 需求追溯矩阵

> 更新：{DATE} (Matrix v1.0)
> 来源：module/{MODULE}/SPEC.md {VERSION}
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯 (FR)

| FR | Description | AC | TC | Task | Status |
|----|-------------|-----|-----|------|--------|
| FR-001 | {DESCRIPTION} | AC-001 | TC-001 | {TASK_ID} | 🔴 |

---

## 2. 业务规则追溯 (BR)

| BR | Description | 违反后果 | 验证方式 | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | {DESCRIPTION} | {CONSEQUENCE} | {VERIFICATION} | {TASK_ID} | 🔴 |

---

## 3. 非功能需求追溯 (NFR)

| NFR | Description | 目标值 | 验证方式 | Task | Status |
|-----|-------------|--------|----------|------|--------|
| NFR-001 | {DESCRIPTION} | {TARGET} | {VERIFICATION} | {TASK_ID} | 🔴 |

---

## 4. TC → FR 反向追溯

| TC | FR/BR | Given/When/Then |
|----|-------|-----------------|
| TC-001 | FR-001 | Given {P}, When {A}, Then {R} |

---

## 5. 全局 AC 注册表

| AC | 所属 FR/BR | Task | 验收条件摘要 |
|----|-----------|------|-------------|
| AC-001 | FR-001 | {TASK_ID} | {SUMMARY} |

---

## 6. 覆盖率仪表盘

| 指标 | 数值 |
|------|------|
| FR 总数 | {N} |
| BR 总数 | {N} |
| NFR 总数 | {N} |
| AC 总数 | {N} |
| TC 总数 | {N} |
| Task 总数 | {N} |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| {DATE} | v1.0 | 初始版本 |
```
