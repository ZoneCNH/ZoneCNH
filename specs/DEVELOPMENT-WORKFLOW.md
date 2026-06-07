# 开发工作流

> 从 Spec 到 Ship 的完整管线。定义"设计图完成后怎么施工"。

最后更新：2026-06-08

---

## 总览

```text
Spec 编写
  ↓
Spec Review（对抗性审查）     ← spec-review agent
  ↓
解决 Open Questions
  ↓
Spec Approved（状态流转）     ← LIFECYCLE.md
  ↓
生成 Traceability Matrix     ← TRACEABILITY.md
  ↓
拆分 Task                    ← task-split agent
  ↓
按 Task 逐个开发
  ↓  ↺ 自查 → 修复 → 测试 → Review
Feature 验收                 ← DEFINITION-OF-DONE.md
  ↓
PR / Ship
```text

**核心原则：Spec 做完后，不是直接写代码，而是先 review、批准、拆 task，然后一小步一小步按 spec 实现和验收。**

---

## 第一步：Spec Review

Spec 编写完成后，第一件事是让 AI 当审查者，不是开发者。

### 使用方式

```text
Agent(subagent_type="spec-review", prompt="审查 specs/{module}/SPEC.md，判断是否可以进入开发")
```text

### 审查重点

1. 是否有模糊需求
2. 是否有互相冲突的要求
3. 是否缺少 Non-goals
4. 是否缺少边界情况
5. 是否缺少验收标准
6. 是否缺少测试用例
7. 是否有安全、权限或数据风险
8. 是否可以进入开发

### 输出

- Blocking issues
- Non-blocking suggestions
- Missing edge cases
- Missing test cases
- Recommended spec edits
- **Go / No-Go 判断**

### 目标

```text
Spec 是否足够清楚？
AI 是否会误解？
需求是否能被测试？
还有没有没决定的问题？
```text

---

## 第二步：解决 Open Questions

Spec 里的未定问题必须分级处理。

### 分级格式

```markdown
## Open Questions

### Blocking（阻塞开发）
- 数据是否需要持久化？

### Non-blocking（不阻塞开发）
- 完成任务是否自动沉到底部？

### Future（未来考虑）
- 是否支持标签？
```text

### 处理规则

- **Blocking** 问题必须在开发前解决
- **Non-blocking** 问题可以在开发中解决
- **Future** 问题记录备忘，不承诺解决时间

### 决策记录

解决后把决定写回 Spec 的 §23 或新增 Decisions 节：

```markdown
## Decisions

- MVP 使用 localStorage 持久化
- 删除任务不需要确认弹窗
- 允许重复任务标题
```text

---

## 第三步：批准 Spec

Spec 状态必须流转到 `Approved` 才能进入开发。

### 状态流转（详见 LIFECYCLE.md）

```text
Draft → Review → Approved → Implemented
                 ↑
              Changed ──→ Review
```text

### 操作

1. 解决所有 Blocking Open Questions
2. spec-review agent 给出 Go 判断
3. 修改 Metadata 节：`Status: Draft` → `Status: Approved`
4. 更新 `Last-Updated` 日期

### 禁止

- ❌ Draft 状态直接进入开发
- ❌ 有 Blocking Open Questions 时批准

---

## 第四步：生成 Traceability Matrix

建立需求追踪表，**防止 AI 漏功能，也防止 AI 乱加功能。**

### 格式

```markdown
| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
|---|---|---|---|---|---|
| FR-001 | Create Task | AC-001 | TC-001 | TASK-001 | ⬜ |
| FR-002 | Reject Empty | AC-002 | TC-002 | TASK-001 | ⬜ |
```text

### 生成方式

```text
Agent(subagent_type="task-split", prompt="根据 specs/{module}/SPEC.md 生成 Traceability Matrix")
```text

### 校验规则

- 每个 FR 必须有 ≥1 AC
- 每个 AC 必须有 ≥1 TC
- 每个 TC 必须映射回 ≥1 FR
- 不允许无需求支撑的 TC（范围蔓延）
- 不允许无测试覆盖的需求（盲区）

---

## 第五步：拆分 Task

Spec 是功能合同，Task 是 AI 能执行的小任务。

### 粒度原则

```text
❌ TASK-001: 实现任务管理系统
✅ TASK-001: 定义 Task 数据模型和校验规则
✅ TASK-002: 实现任务 storage/service
✅ TASK-003: 实现新增任务表单
✅ TASK-004: 实现任务列表展示
```text

### 拆分规则（详见 TASK-TEMPLATE.md）

| 规则 | 说明 |
|------|------|
| 上限 | 一个 task 最多 5 个文件、3 个 FR |
| 下限 | 一个 task 至少 1 个 FR + 1 个 AC |
| 测试同体 | 实现文件和测试文件必须在同一个 task |
| 不跨模块 | 一个 task 只涉及一个模块 |
| 必须有 spec_ref | 不允许无规格的自由发挥 |

### 拆分顺序

```text
接口定义（contracts）
  ↓
Data Model + Validation
  ↓
Service / Storage
  ↓
UI Components（如有）
  ↓
Integration
  ↓
Tests 补全
  ↓
Review + Polish
```text

### 使用方式

```text
Agent(subagent_type="task-split", prompt="根据 specs/{module}/SPEC.md 拆分 Task")
```text

### 输出格式

每个 Task 包含：

1. Task ID
2. Goal（一句话目标）
3. Scope（做什么）
4. Non-scope（不做什么）
5. Requirements covered（FR/BR 编号）
6. Files likely to change
7. Acceptance criteria
8. Test plan
9. Depends on（前置 task）
10. Priority（P0/P1/P2）

---

## 第六步：按 Task 逐个开发

### 执行顺序

选第一个最底层、最少依赖的 Task。

### 每个 Task 的执行循环

```text
实现 TASK-{NNN}
  ↓
自查（对照 spec）
  ↓
修复 Required fixes
  ↓
测试（lint + typecheck + test）
  ↓
Code Review
  ↓
修复 Review issues
  ↓
更新 Task 状态为 Done
  ↓
更新 Traceability Matrix
  ↓
实现 TASK-{NNN+1}
```text

### 开发 Prompt

```markdown
请实现 TASK-{MODULE}-{NNN}。

上下文：
- Spec: specs/{module}/SPEC.md
- Task: specs/{module}/tasks/TASK-{MODULE}-{NNN}.md
- Agent Rules: AGENTS.md

限制：
- 只实现当前 task
- 不实现后续 task
- 不做 spec 外功能
- 不引入新依赖（除非 task 明确要求）
- 不修改无关文件

完成后输出：
1. 修改文件清单
2. 实现说明
3. 覆盖的 Requirement IDs
4. 新增测试
5. 如何运行测试
6. 风险或假设
```text

### 自查 Prompt

```markdown
请根据 specs/{module}/SPEC.md 检查当前实现。

不要写新功能。

输出：
1. Requirement coverage table
2. Acceptance criteria result
3. Test coverage result
4. Deviations from spec
5. Required fixes
6. Suggested improvements
```text

### Review Prompt

```markdown
请作为严格代码审查者 review 当前 diff。

参考：specs/{module}/SPEC.md

重点检查：
1. 是否满足 spec
2. 是否实现了 task scope 外的内容
3. 是否漏掉 edge cases
4. 是否有类型问题
5. 是否有安全问题
6. 是否有过度设计
7. 是否需要补测试
8. 是否破坏现有功能

输出：
- Must fix
- Should fix
- Nice to have
- Accepted
```text

---

## 第七步：Feature 验收

当一个模块的所有 Task 都完成后，做完整验收。

### 验收标准（详见 DEFINITION-OF-DONE.md）

- [ ] 所有 Functional Requirements 已实现
- [ ] 所有 Business Rules 已遵循
- [ ] 所有 Error Handling 已实现
- [ ] 所有 Edge Cases 已处理
- [ ] 所有 Test Cases 已通过
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果符合 Performance Budget
- [ ] CI Gate 全部通过
- [ ] 追溯矩阵更新完成
- [ ] 无硬编码 secret
- [ ] 公共接口有 godoc 注释

### 验收 Prompt

```markdown
请根据 specs/{module}/SPEC.md 对当前功能做完整验收。

检查：
1. 所有 Functional Requirements 是否实现
2. 所有 Acceptance Criteria 是否通过
3. 所有 Test Cases 是否覆盖
4. 是否存在 spec 外功能
5. 是否有已知 bug
6. 是否有安全问题
7. 是否可以标记为 Implemented

输出：
- Pass / Fail
- Requirement coverage table
- Missing items
- Required fixes
- Final recommendation
```text

### 状态流转

验收通过后：

```text
Spec Status: Approved → Implemented
Traceability Matrix: 所有 Status → ✅
```text

---

## 第八步：PR / Ship

PR 描述应引用 Spec：

```markdown
# PR: Implement {module}

## Related Spec
- specs/{module}/SPEC.md

## Requirements Covered
- FR-001, FR-002, FR-003...

## Changes
- {变更清单}

## Verification
- go build ./...
- go test ./... -race
- golangci-lint run

## Acceptance Criteria
| AC | Status |
|---|---|
| AC-001 | ✅ |
| AC-002 | ✅ |
```text

---

## Agent 清单

| Agent | 步骤 | 用途 | 模型 | 可写代码 |
|-------|------|------|------|----------|
| `spec` | Spec | 编写或修订项目 spec | sonnet | 是 |
| `spec-review` | Spec | 对抗性审查 spec，Go/No-Go 判断 | opus | 否 |
| `task-split` | Matrix / Tasks | 拆分 Task + 生成追溯矩阵 | sonnet | 是 |
| `task-planner` | Plan | 为单个 Task 生成分步实现计划 | opus | 否 |
| `prompt-builder` | Prompt | 为单个 Task 生成 Context Packet | sonnet | 否 |
| `task-executor` | Code | 按照 Task spec 编写代码 | sonnet | 是 |
| `code-reviewer` | Review | 代码审查 | opus | 否 |
| `tdd-guide` | Test | 测试驱动开发 | sonnet | 是 |

---

## 相关文档

### 流水线文档

| 文档 | 用途 |
|------|------|
| `specs/PRE-DEVELOPMENT.md` | 开发前准备 — 实现策略、Task 拆分、追溯矩阵 |
| `specs/CODING-SESSION-PROTOCOL.md` | 编码会话协议 — Context Packet、Plan-first、自查、Review |
| `specs/SPEC-DRIFT-PROTOCOL.md` | Spec Drift 处理 — 代码与 Spec 不一致时的协议 |
| `specs/TESTING-STRATEGY.md` | 测试策略 — 从 Spec 生成测试、优先级、验收 |
| `specs/PR-TEMPLATE.md` | PR/Issue/Branch/Commit 模板和命名规则 |
| `specs/DEPLOYMENT.md` | 部署清单 — RC 检查、Smoke Test、CI 配置、Changelog |
| `specs/REVIEW-STRATEGY.md` | 审查策略 — 每层轻审查、转换点强审查、高风险点反审查 |

### 治理文档

| 文档 | 用途 |
|------|------|
| `specs/SPEC-TEMPLATE.md` | 23 节 spec 模板 |
| `specs/TASK-TEMPLATE.md` | Task spec 模板 |
| `specs/LIFECYCLE.md` | Spec 状态流转规则 |
| `specs/TRACEABILITY.md` | 需求追踪矩阵规范 |
| `specs/DEFINITION-OF-READY.md` | 进入开发的前置条件 |
| `specs/DEFINITION-OF-DONE.md` | 完成验收条件 |
| `CONSTITUTION.md` | 最高治理权威 |
