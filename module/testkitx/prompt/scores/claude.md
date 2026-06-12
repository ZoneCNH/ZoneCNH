# testkitx Prompt 阶段结构评分报告

> **平台**: Claude (Opus) | **日期**: 2026-06-12 | **评分对象**: `module/testkitx/prompt/PROMPT-TESTKITX-000~010.md`（11 个文件）

---

## 总览

| 指标 | 值 |
|------|-----|
| **总分** | **95 / 100** |
| **红线** | 无 |
| **裁断** | Needs-repair (低于 98 门禁) |
| **置信度** | high |
| **Prompt 数量** | 11 |

---

## 各 Prompt 得分

| Prompt | 单Task | 上下文 | 文件范围 | 禁止 | AC | 验证 | 证据 | ID引用 | 总分 |
|--------|--------|--------|----------|------|-----|------|------|--------|------|
| PROMPT-TESTKITX-000 | 15 | 11 | 12 | 12 | 13 | 13 | 10 | 8 | **94** |
| PROMPT-TESTKITX-001 | 15 | 11 | 12 | 12 | 13 | 13 | 10 | 9 | **95** |
| PROMPT-TESTKITX-002 | 15 | 11 | 12 | 12 | 13 | 13 | 10 | 9 | **95** |
| PROMPT-TESTKITX-003 | 15 | 11 | 12 | 12 | 13 | 13 | 10 | 9 | **95** |
| PROMPT-TESTKITX-004 | 15 | 11 | 12 | 12 | 11 | 13 | 10 | 9 | **93** |
| PROMPT-TESTKITX-005 | 15 | 11 | 12 | 12 | 13 | 13 | 10 | 9 | **95** |
| PROMPT-TESTKITX-006 | 15 | 11 | 12 | 12 | 13 | 13 | 10 | 9 | **95** |
| PROMPT-TESTKITX-007 | 15 | 11 | 12 | 12 | 13 | 13 | 10 | 9 | **95** |
| PROMPT-TESTKITX-008 | 15 | 11 | 12 | 12 | 13 | 13 | 10 | 9 | **95** |
| PROMPT-TESTKITX-009 | 15 | 11 | 12 | 12 | 13 | 13 | 10 | 9 | **95** |
| PROMPT-TESTKITX-010 | 15 | 14 | 12 | 12 | 13 | 13 | 10 | 8 | **97** |
| **平均** | **15** | **11** | **12** | **12** | **13** | **13** | **10** | **9** | **95** |

---

## 维度分析

### 1. 单 Task 聚焦 (15/15)

**全部通过。** 每个 Prompt 严格服务一个 Task，无 scope 扩张。

- PROMPT-005 同时覆盖 FakeClock (FR-005) 与 FakeBreaker (FR-006)，但矩阵中将两者均映射至 TASK-TESTKITX-005，属于 Task 自身定义，非 Prompt scope 扩张。
- PROMPT-000 覆盖 FR-001~010 范围引用，但作为项目骨架任务，其职责是搭建所有后续 Task 的基础设施，scope 合理。

### 2. 上下文引用完整 (11/15) — 扣 4 分

**主要问题：10/11 Prompt 缺少 TRACEABILITY.md 引用。**

- 10 个 Prompt（000~009）的 `spec_ref` 仅指向 `SPEC.md` 各节，未引用 `TRACEABILITY.md`
- PROMPT-010 是唯一在 `spec_ref` 中引用 `TRACEABILITY.md` 的 Prompt
- 全部 Prompt 的 `task_ref` 仅使用 Task ID（如 `TASK-TESTKITX-001`），未提供文件路径
- testkitx 无 IMPLEMENTATION-PLAN.md 或 DESIGN.md，Plan 引用不适用

对比 observex 参考模板：
```markdown
> 上游 Task：[TASK-OBSERVEX-005.md](../tasks/TASK-OBSERVEX-005.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 权威 Spec：[SPEC.md](../SPEC.md)
```

### 3. 可改文件范围 (12/12)

**全部通过。** 每个 Prompt 的 `task_files` YAML 字段明确列出允许修改的文件路径，无模糊表述。

### 4. 禁止事项 (12/12)

**全部通过。** 每个 Prompt 列出具体、可操作的禁止事项，覆盖依赖管理、确定性行为、安全约束等。

### 5. 验收标准 (13/13)

**基本通过。** 所有 Prompt 的 AC 表均包含验证命令和预期结果。

- **PROMPT-004 例外**：关联需求中引用 BR-002（确定性行为），但验收标准表中无对应 AC。其他 fake 实现 Prompt（001/002/003）均包含 BR-002 的确定性验证（如 `grep "time.Now\|math.Rand"` 检查），PROMPT-004 遗漏此项。由于仅影响 1/11 Prompt 且 BR-002 对 FakeTracer 的适用性较低，对总分影响计入维度平均后为 0 扣分，但建议补充。

### 6. 验证命令 (13/13)

**全部通过。** 所有 Prompt 提供必跑命令，含成功判定标准：

- `go build ./...` — 编译通过
- `go test -race -count=1 ./...` — 无 data race
- `go vet ./...` — 无警告
- 各 Prompt 专属验证命令（接口断言检查、确定性检查等）

### 7. 证据回填要求 (10/10)

**全部通过。** 所有 Prompt 明确列出完成后需提交的证据产物（测试输出、构建输出、文件变更清单等）。

### 8. Requirement/AC/TC ID 引用 (9/10) — 扣 1 分

**主要问题：自定义 AC ID 未与矩阵 AC 编号建立映射。**

- 全部 Prompt 使用自定义 AC ID（如 `AC-SKEL-*`、`AC-FC-*`、`AC-FL-*`、`AC-DOC-*` 等），而非矩阵定义的 `AC-001` 至 `AC-010`
- FR 和 TC 编号引用正常，均使用矩阵定义的标准 ID
- PROMPT-000 使用 `FR-001~010`（范围）而非逐个列举，作为骨架任务可接受
- PROMPT-000 与 PROMPT-010 的关联需求表使用「§」作为类型标记（如 `§14`、`§22`），应替换为规范的 `FR`/`BR`/`NFR`/`AC`/`TC` 类型

---

## 扣分明细

| ID | 严重级别 | 扣分 | 维度 | 描述 |
|----|----------|------|------|------|
| D1 | MEDIUM | 3 | 上下文引用完整 | 10/11 Prompt 缺少 TRACEABILITY.md 引用 |
| D2 | LOW | 1 | 上下文引用完整 | 全部 Prompt 的 task_ref 仅使用 ID，无文件路径 |
| D3 | LOW | 1 | ID 引用 | 全部 Prompt 使用自定义 AC ID，未映射至矩阵 AC-001~010 |

---

## 红线检查

| 红线 | 状态 | 说明 |
|------|------|------|
| Prompt 服务多个 Task | 通过 | 每个 Prompt 严格对应一个 Task |
| Prompt 扩大 Task scope | 通过 | 未发现 scope 扩张 |
| 未引用 Requirement/AC/TC ID | 通过 | 所有 Prompt 均引用 FR/TC/BR ID |
| 验证命令缺失或不可执行 | 通过 | 验证命令完整且可执行 |
| 允许修改文件范围模糊 | 通过 | task_files 明确列出文件路径 |
| 缺少证据回填要求 | 通过 | 证据回填要求完整 |

---

## 建议修复清单

### 修复 D1（MEDIUM）：补全 TRACEABILITY.md 引用

在 PROMPT-TESTKITX-000~009 的 YAML 头部添加：

```yaml
matrix_ref:
  - "module/testkitx/TRACEABILITY.md"
```

或参考 PROMPT-010 的 spec_ref 格式，直接在 spec_ref 中引用 TRACEABILITY.md 的具体小节。

### 修复 D2（LOW）：补全 Task 文件路径

在每个 Prompt 的题注块添加：

```markdown
> 上游 Task：[TASK-TESTKITX-NNN.md](../tasks/TASK-TESTKITX-NNN.md)
```

### 修复 D3（LOW）：建立自定义 AC 到矩阵 AC 的映射

在 AC 表中添加「矩阵 AC」列，例如 PROMPT-001 的 AC 表：

| AC | 矩阵 AC | 关联 | 验证命令 | 预期结果 |
|----|---------|------|----------|----------|
| AC-FC-01 | AC-001 | FR-001 | ... | ... |
| AC-FC-02 | AC-001 | BR-001 | ... | ... |

### 额外建议

- **PROMPT-004**：补充 BR-002 对应的 AC（如 `grep -E "time\.Now|math\.Rand" fake_tracer.go` → 无匹配）
- **PROMPT-000 / PROMPT-010**：将关联需求表中的 `§` 类型条目替换为规范类型（如 `SPEC` 或映射到具体的 FR/BR/NFR 编号）
- **全模块**：若后续创建 IMPLEMENTATION-PLAN.md，应在各 Prompt 中补充 Plan 引用

---

## 仲裁前置检查

| 检查项 | 状态 |
|--------|------|
| 最新版本确认 | 通过 — 提交 678a7fe 为 1 小时内唯一变更 |
| R0 措辞强度分级 | 已执行 — 仅对【硬】约束扣分 |
| R1 跨表走查 | 通过 — FR/BR/NFR/AC/TC 验证链路已跨表确认 |
| R2 辅助元数据排除 | 通过 — §6 仪表盘、§7 变更历史不参与评分 |
| R3 验证机制形式 | 通过 — 所有验证命令均为有效可执行形式 |

---

## 门禁判定

| 条件 | 值 | 通过 |
|------|-----|------|
| composite_score >= 98 | 95 | **否** |
| redline = false | true | 是 |
| confidence != low | high | 是 |

**裁定**: Needs-repair。建议由 executor 修复 D1~D3 三项扣分后重新评分。
