# Agent 三平台兼容性报告

> 基于 `14-agent-protocols.md` §0 要求：Agent 定义漂移时 MUST 生成 Change Request。本报告是对 Claude Code / Copilot CLI / Codex CLI 三平台 `goal-*` Agent 投影的一阶兼容性审计。

生成日期：2026-06-12
审计范围：`.claude/agents/goal-*.md`、`.copilot/agents/goal-*.md`、`.codex/agents/goal-*.toml`

---

## 1. Agent 存在性矩阵

| Agent | Claude Code | Copilot CLI | Codex CLI |
|-------|------------|-------------|-----------|
| goal-spec | ✅ 348 行 | ✅ 48 行 | ✅ 39 行 |
| goal-matrix | ✅ 253 行 | ✅ 49 行 | ✅ 41 行 |
| goal-reviewer | ✅ 284 行 | ✅ 55 行 | ✅ 47 行 |
| goal-prompt-builder | ✅ 451 行 | ✅ 48 行 | ✅ 40 行 |
| goal-evidence | ✅ 430 行 | ✅ 66 行 | ✅ 57 行 |
| goal-architect | ✅ | ❌ | ❌ |
| goal-context-recovery | ✅ | ❌ | ❌ |
| goal-governance | ✅ | ❌ | ❌ |
| goal-lint | ✅ | ❌ | ❌ |
| goal-planner | ✅ | ❌ | ❌ |

**关键发现**：5 个核心 Agent 三平台同步，5 个辅助 Agent 仅 Claude Code 实现。按 `14-agent-protocols.md` 设计，Copilot/Codex 只需覆盖核心 5 个（spec / matrix / reviewer / prompt-builder / evidence），其余为可选的 Claude 专属能力——此差异符合设计，非漂移。

---

## 2. 文档引用一致性

### 幻影引用（已修复）

| 平台 | Agent | 幻影引用 | 实际文件 | 修复 |
|------|-------|---------|---------|------|
| Codex | goal-spec | `02-goal-schema.md` | `02-goal-standard.md` | ✅ 已修复 |
| Codex | goal-spec | `07-human-approval.md` | → `06-dod.md` | ✅ 已修复 |
| Codex | goal-spec | `09-tasks-and-prompt.md` | `09-templates.md` | ✅ 已修复 |
| Codex | goal-prompt-builder | `09-tasks-and-prompt.md` | `09-templates.md` | ✅ 已修复 |

### Copilot 引用验证

Copilot 5 个 Agent 的 13 个文档引用 **全部有效**，无幻影引用。

### Claude 引用基准

Claude 端 `goal-spec.md` 引用 19 个真实文档，可作为权威引用基准。

---

## 3. 结构差异分析

### 3.1 Agent 定义字段

| 字段 | Claude (.md) | Copilot (.md) | Codex (.toml) |
|------|-------------|---------------|---------------|
| name | ✅ YAML frontmatter | ✅ YAML frontmatter | ✅ TOML key |
| description | ✅ | ✅ | ✅ |
| model | ✅ opus | ❌ | ✅ gpt-5.5 |
| tools | ✅ list | ❌ (平台默认) | ❌ (平台默认) |
| platform metadata | ❌ | ✅ | ❌ |
| system prompt | ✅ 完整 | ✅ 投影 | ✅ 投影 |

**发现**：
- Claude 端明确指定 model 和 tools；Copilot 依赖平台默认——符合设计（`14-agent-protocols.md` 明确此为"平台投影"）。
- Codex 端 model 为 `gpt-5.5`，与 Claude 端的 `opus` 不同——这是跨平台预期的模型差异，不影响规则语义。

### 3.2 权威顺序声明

三平台均以相同顺序声明权威层级：
1. CONSTITUTION.md
2. docs/goal/00-authority-map.md
3. docs/goal/ (核心文档集)
4. .config/goal/schema/rules.yaml

**结论**：权威顺序一致 ✅

### 3.3 MUST / MUST NOT 约束

| 约束 | Claude | Copilot | Codex |
|------|--------|---------|-------|
| 不可确认内容标为 Hypothesis/BLOCKED | ✅ | ✅ | ✅ |
| 保留已批准 Goal 核心约束 | ✅ | ✅ | ✅ |
| 明确 Gate 输入/输出/阻断/证据 | ✅ | ✅ | ✅ |
| 自行批准 G0-G11 | ✅ 禁止 | ✅ 禁止 | ✅ 禁止 |
| 放宽 Gate 或删除失败证据 | ✅ 禁止 | ✅ 禁止 | ✅ 禁止 |
| 把 vision 转成已批准规则 | ✅ 禁止 | ✅ 禁止 | ✅ 禁止 |
| 以本角色修改生产代码 | ✅ 禁止 | ✅ 禁止 | ✅ 禁止 |

**结论**：MUST/MUST NOT 语义等价 ✅

---

## 4. 详细度不对称

| 维度 | Claude | Copilot | Codex |
|------|--------|---------|-------|
| 平均行数/Agent | 353 | 53 | 45 |
| 状态文件路径表 | ✅ 11 行 | ❌ | ❌ |
| 权威文档索引表 | ✅ 20+ 文档 | ❌ | ❌ |
| 管线全景图 | ✅ | ❌ | ❌ |
| 工作流步骤 | ✅ 详细 | ✅ 简述 | ✅ 简述 |
| 执行模式 (Lite/Standard/Full) | ✅ | ❌ | ✅ (仅 prompt-builder) |

**评估**：详细度不对称是设计结果——Claude Code 端为"完整定义"，Copilot/Codex 端为"平台投影"。此模式符合 `14-agent-protocols.md` 设计，但存在风险：
- **风险**：Copilot/Codex Agent 在缺乏完整文档索引的情况下，可能无法发现适用的权威文档。
- **缓解**：权威顺序层 3 已列出核心文档清单，Agent 应能据此追溯。

---

## 5. 运行时验证

### 5.1 Copilot CLI Smoke Test

| 测试项 | 结果 |
|--------|------|
| lint-goal.sh (docs/goal/) | 0 ERRORS, 0 WARNINGS ✅ |
| goal-validate.py (strict) | PASS ✅ |
| matrix-gen.py (--check-only) | 100% coverage ✅ |
| self-test.sh | 45/45 PASS ✅ |
| 跨路径执行 (/tmp → lint) | 0 ERRORS ✅ |
| Python 3.14 + yaml | OK ✅ |

### 5.2 Rule Drift Check

```
[PASS] All 10 rule-drift checks passed
[PASS] No stale executable rule literals
[PASS] Gate IDs and status vocabularies match rules.yaml
```

---

## 6. 发现总结

| Severity | 数量 | 描述 |
|----------|------|------|
| HIGH | 4 | Codex 幻影文档引用（已修复） |
| MEDIUM | 0 | — |
| LOW | 1 | Copilot/Codex 缺少完整文档索引表（设计如此，低风险） |

---

## 7. 建议

1. **已执行**：修复 Codex 端 4 处幻影文档引用
2. **建议（P3）**：为 Copilot/Codex Agent 添加精简版文档索引（5-8 个核心文档），降低 Agent 在跨平台执行时的文档发现成本
3. **建议（P3）**：建立 CI 检查——扫描所有 Agent 定义中的 `docs/goal/*.md` 引用，验证目标文件存在
4. **无需操作**：辅助 Agent（architect / context-recovery / governance / lint / planner）仅在 Claude Code 端存在，符合设计

---

## 验证记录

- [x] 幻影引用修复验证（`grep -oh 'docs/goal/[^ )]*,]*\.md' .codex/agents/*.toml \| sort -u \| while read d; do [ -f "$d" ] && echo "OK $d" \|\| echo "PHANTOM $d"; done`）
- [x] Copilot 引用全量验证
- [x] rule-drift-check.py 10/10 PASS
- [x] Copilot CLI smoke 45/45 PASS
