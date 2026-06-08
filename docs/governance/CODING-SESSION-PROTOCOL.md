# 编码会话协议

> 每次打开 AI 写代码前的标准流程。

最后更新：2026-06-08

---

## 标准流程

```text
1. Load Context        加载上下文
2. Confirm Scope       确认范围
3. Ask for Plan        让 AI 出计划
4. Approve Plan        审批计划
5. Implement           实现
6. Run Checks          跑检查
7. Self-review         AI 自查
8. Human Review        人工审查
9. Fix                 修复
10. Commit / PR        提交
```text

**原则：先喂上下文，再确认范围，再让它出计划，你看完计划，再让它写代码。**

---

## Context Packet

每次给 AI 的上下文应该是一个完整的 Context Packet，而不是一句话。

### 模板

```markdown
# Context Packet

## Current Task

TASK-{NNN}: {任务标题}

## Related Spec

module/{module}/SPEC.md

## Related Requirements

- FR-XXX
- FR-XXX
- BR-XXX
- AC-XXX

## Project Rules

- Follow AGENTS.md
- Do not implement features outside current task
- Do not introduce new dependencies
- Add or update tests for behavior changes

## Current Scope

{本任务要做什么}

## Out of Scope

- {不做什么 1}
- {不做什么 2}
- {不做什么 3}

## Validation Commands

```bash
go build ./...
go test ./... -race
golangci-lint run
```text

## Required Output

- Files changed
- Requirement coverage
- Tests added
- Verification result
- Risks

```text

### 为什么需要 Context Packet

| 单句 prompt | Context Packet |
|------------|----------------|
| AI 猜上下文 | AI 知道上下文 |
| 容易做多 | 范围明确 |
| 容易漏测试 | 测试要求明确 |
| 无法验证 | 验证命令明确 |

---

## 第一步：让 AI 先出 Plan

**第一个 prompt 应该是让 AI 出计划，不是写代码。**

### Plan Prompt

```markdown
请先不要写代码。

请阅读以下上下文并输出实现计划：

- Spec: module/{module}/SPEC.md
- Task: module/{module}/tasks/TASK-{MODULE}-{NNN}.md
- Architecture: ARCHITECTURE.md
- Agent Rules: AGENTS.md

请输出：
1. 你对任务的理解
2. 会修改的文件
3. 实现步骤
4. 测试计划
5. 风险
6. 是否发现 spec 或 task 有歧义

不要写代码。
```text

### 审批后实现

确认计划没问题后：

```markdown
计划可以。请按计划实现。

限制：
- 只实现 TASK-{NNN}
- 不做 scope 外功能
- 不引入新依赖
- 添加必要测试
```text

**这个节奏可以显著减少 AI 乱改。**

---

## 第二步：实现后自查

### Requirement Coverage Check

代码写完，不要只问"有没有问题"。要让它对照需求编号检查。

```markdown
请根据 TASK-{NNN} 和 SPEC.md 检查当前实现。

输出 Requirement Coverage Table：

| Requirement ID | Expected Behavior | Implemented? | Evidence | Notes |
|---|---|---|---|---|

同时输出：
- Missing requirements
- Extra functionality not in spec
- Test coverage
- Risks
```text

### 理想输出

```markdown
| Requirement ID | Expected Behavior | Implemented? | Evidence | Notes |
|---|---|---|---|---|
| FR-001 | Valid title creates task | Yes | TaskForm submit handler | Covered by test |
| FR-002 | Empty title rejected | Yes | validateTaskTitle | Covered by test |
| BR-001 | Trim title | Yes | validation.ts | Covered by test |
| AC-001 | Task appears in list | Yes | TaskList render | Manual + component test |
```text

---

## 第三步：检查 Spec 外功能

AI 很容易做多。你只让它做创建任务，它顺手做了编辑、删除、筛选、登录。

### Scope Check Prompt

```markdown
请检查当前 diff 是否实现了 Spec 或当前 Task 范围之外的功能。

请输出：
1. Spec-covered changes
2. Out-of-scope changes
3. 是否需要移除 out-of-scope changes
4. 建议保留还是回滚

不要修改代码。
```text

### 移除 Prompt

如果发现做多了：

```markdown
请移除 out-of-scope changes，只保留 TASK-{NNN} 范围内的实现。

不要改变已通过的 TASK-{NNN} 行为。
不要新增功能。
```text

---

## 第四步：人工 Review

AI 自查不够，你还要看 diff。

### 重点看 7 件事

1. 有没有改无关文件
2. 有没有实现 Spec 外功能
3. 有没有为了通过测试写假逻辑
4. 有没有硬编码数据
5. 有没有吞掉错误
6. 有没有引入不必要依赖
7. 有没有把简单事情复杂化

### Review Prompt

```markdown
请作为严格 reviewer 检查当前 diff。

重点关注：
- 是否只实现 TASK-{NNN}
- 是否满足 SPEC
- 是否有 out-of-scope changes
- 是否有过度设计
- 是否有测试缺口
- 是否有安全风险
- 是否有可维护性问题

输出：
1. Must fix
2. Should fix
3. Nice to have
4. Accepted parts
5. Final recommendation
```text

---

## 第五步：修复

```markdown
请只修复 review 中的 Must fix 项。

限制：
- 不做新功能
- 不处理 Nice to have
- 不重构无关代码
- 不修改 Spec
- 不改变当前 Task 以外的行为
- 保持测试通过

修复后输出：
1. 修复了哪些问题
2. 修改了哪些文件
3. 哪些 Must fix 已解决
4. 如何验证
5. 是否引入新风险
```text

---

## AI 常见错误

### 错误 1：一次做太多

**表现：** 你让它做创建任务，它顺便做了编辑、删除、登录、数据库

**处理：**

```markdown
请回滚或移除当前 Task 范围外的实现。
只保留 TASK-{NNN} 需要的代码。
```text

### 错误 2：改了架构

**表现：** 引入新框架、重写目录结构、换 UI 库、新建一堆抽象

**处理：**

```markdown
当前修改违反 architecture spec。

请移除不必要的架构改动，恢复到现有项目结构。
不引入新依赖。
只保留最小实现。
```text

### 错误 3：测试覆盖假阳性

**表现：** 测试只检查组件存在，没有真正验证行为

**处理：**

```markdown
请增强测试，让测试真正覆盖用户行为和 Acceptance Criteria。

要求：
- 使用用户可见行为断言
- 不只测试 implementation details
- 每个测试映射到 Requirement ID
```text

### 错误 4：错误处理太粗糙

**表现：** catch 后什么都不做，console.error 后继续，用户看不到错误

**处理：**

```markdown
请按照 Spec 的 Error Handling 要求修复错误处理。

要求：
- 用户输入错误显示明确提示
- 系统错误显示通用提示
- 不暴露 stack trace
- 不吞掉错误
```text

### 错误 5：Spec 和代码不一致

**处理：**

```markdown
请列出当前实现与 Spec 的所有不一致。

不要修改代码。

输出：
- Spec says
- Code does
- Impact
- Recommended fix
- Fix code or update spec
```text

---

## 完整 Task 执行 Prompt

可直接复制使用：

```markdown
你是一个资深工程师。请严格按照当前 Task 实现功能。

## Context

Spec: module/{module}/SPEC.md
Task: module/{module}/tasks/TASK-{MODULE}-{NNN}.md
Architecture: ARCHITECTURE.md
Agent Rules: AGENTS.md

## Current Task

TASK-{NNN}: {任务标题}

## Scope

只实现：
- {具体事项 1}
- {具体事项 2}

## Out of Scope

不要实现：
- {排除事项 1}
- {排除事项 2}

## Requirements Covered

- FR-XXX
- FR-XXX
- AC-XXX

## Rules

- 不引入新依赖
- 不修改无关文件
- 不重写项目结构
- 添加必要测试
- 错误提示遵守 Spec
- 不实现 Spec 外功能

## Required Process

先输出：
1. 任务理解
2. 修改文件计划
3. 实现步骤
4. 测试计划
5. 风险

在计划之后，再进行实现。

## Final Output

完成后输出：
1. 修改文件清单
2. 需求覆盖表
3. 测试覆盖
4. 如何验证
5. 是否有 out-of-scope changes
6. 风险或假设
```text

---

## 完整 Review Prompt

```markdown
你是一个严格的代码审查者。

请 review 当前 diff。

参考：
- module/{module}/SPEC.md
- module/{module}/tasks/TASK-{MODULE}-{NNN}.md
- ARCHITECTURE.md
- AGENTS.md

请检查：

## Spec Compliance

- 是否满足相关 Requirement IDs
- 是否满足 Acceptance Criteria
- 是否覆盖 Test Cases

## Scope Control

- 是否只实现当前 Task
- 是否有 Spec 外功能
- 是否有无关文件修改

## Code Quality

- 是否简单可维护
- 是否类型明确
- 是否有重复逻辑
- 是否有过度抽象
- 是否引入不必要依赖

## Testing

- 是否有必要测试
- 测试是否验证真实用户行为
- 是否有假阳性测试
- 是否覆盖边界情况

## Security

- 是否硬编码 secret
- 是否泄露敏感数据
- 是否有危险日志
- 是否正确处理输入

输出：
1. Must fix
2. Should fix
3. Nice to have
4. Accepted
5. Final decision: Approve / Request changes
```text

---

## 每天的工作节奏

```text
早上：
- 选一个 Task
- 看 Spec
- 让 AI 出 plan

开发中：
- AI 写代码
- 跑测试
- 修 bug

结束前：
- 做 self-review
- 更新 Task 状态
- 更新 traceability
- 写 commit / PR
```text

### 单个 Task 的理想时间分配

```text
Plan   5%
Code   40%
Test   25%
Review 20%
Docs   10%
```text

**不要：** Code 95%, Review 0%, Test 5%

---

## 相关文档

| 文档 | 用途 |
|------|------|
| `docs/governance/DEVELOPMENT-WORKFLOW.md` | 完整管线总览 |
| `docs/governance/SPEC-DRIFT-PROTOCOL.md` | Spec 与代码不一致处理 |
| `docs/governance/TESTING-STRATEGY.md` | 测试策略 |
| `docs/governance/DEPLOYMENT.md` | 部署清单 |
