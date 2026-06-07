# Prompt Templates: FoundationX

> 标准化 prompt 模板，用于驱动 AI 代理按 spec 工作。

最后更新：2026-06-07
Status: Approved

---

## 1. Spec 审查 Prompt

用于让 AI 审查 spec 是否可以进入开发。

```markdown
请 review specs/<module>/SPEC.md。

重点检查：
- 是否有模糊需求（参考 docs/ai/prompt-templates.md §9 模糊词替换表）
- 是否有互相冲突的要求
- 是否缺少边界情况（Section 13）
- 是否缺少验收标准（Section 22）
- 是否缺少测试用例（Section 16）
- 是否有安全风险（Section 19）
- Functional Requirements（Section 7）是否使用 WHEN/THEN
- Business Rules（Section 8）是否完整
- Error Handling（Section 12）是否覆盖所有错误
- Open Questions（Section 23）是否有 Blocking 项

不要写代码。

输出：
1. Blocking issues（必须修复才能开发）
2. Non-blocking suggestions（建议改进）
3. Missing test cases（缺失的测试用例）
4. Missing edge cases（缺失的边界场景）
5. Recommended spec edits（建议的 spec 修改）
6. Ready / Not ready（是否可以进入开发）
```text

---

## 2. 任务拆分 Prompt

用于让 AI 把一个 Feature Spec 拆成可执行的 Task。

```markdown
请根据 specs/<module>/SPEC.md 生成 implementation tasks。

要求：
- 每个 task 控制在 200 行代码以内
- 每个 task 都要写清楚 scope（做什么、不做什么）
- 每个 task 都要对应 requirement IDs（FR/BR 编号）
- 每个 task 都要有 acceptance criteria
- 每个 task 都要有测试方式
- 标明建议修改文件
- 按依赖顺序排列（先实现被依赖的）

输出格式：
### TASK-001: <title>
- Related: FR-xxx, BR-xxx
- Scope: ...
- Files: ...
- Acceptance: ...
- Depends on: (none / TASK-xxx)

不写代码。
```text

---

## 3. 模块实现 Prompt

用于让 AI 实现单个模块。

```markdown
请实现 specs/<module>/SPEC.md 中定义的模块。

上下文：
- Spec: specs/<module>/SPEC.md
- Architecture: ARCHITECTURE.md
- Constitution: CONSTITUTION.md
- Agent Rules: docs/ai/agent-rules.md

限制：
- 严格按照 spec 的 Functional Requirements 实现
- 不实现 spec 中 Non-goals 列出的功能
- 不引入 spec 未列出的依赖
- 不修改无关文件
- 必须包含 spec Section 16 中要求的所有测试
- 必须满足 spec Section 17 中的 Performance Budget

完成后输出：
1. 修改文件清单
2. 实现说明（每个文件改了什么）
3. 覆盖的 requirements（FR/BR 编号）
4. 新增或更新的测试（TC 编号）
5. 如何验证（命令）
6. 风险
```text

---

## 4. 自查 Prompt

用于让 AI 自查实现是否符合 spec。

```markdown
请根据以下文件检查当前实现是否符合 spec：

- specs/<module>/SPEC.md
- docs/ai/agent-rules.md
- CONSTITUTION.md

检查项：
1. Requirement coverage table（每个 FR/BR 是否已实现）
2. Acceptance criteria result（每个 AC 是否通过）
3. Test coverage result（每个 TC 是否存在且通过）
4. Edge case coverage（Section 13 的 Edge Cases 是否有测试）
5. Error handling coverage（Section 12 的错误是否都有处理）
6. Performance budget（Section 17 是否达标）
7. Deviations from spec（实现与 spec 的偏差）

输出格式：
| Requirement | Status | Evidence |
|---|---|---|
| FR-001 | ✅ | TestXxx_TC001 |
| FR-002 | ❌ | 未实现 |

不要修改代码。
```text

---

## 5. 修复 Prompt

用于让 AI 修复自查发现的问题。

```markdown
请只修复上一步发现的 Required fixes。

限制：
- 不做新功能
- 不重构无关代码
- 不修改 spec
- 保持 public API 不变
- 每个修复对应一个独立的 commit

完成后重新输出自查结果。
```text

---

## 6. CI Gate 验证 Prompt

用于让 AI 验证模块是否通过所有 CI Gate。

```markdown
请验证 <module> 是否通过 spec Section 20 中定义的所有 CI Gate。

执行以下命令：
1. go build ./...
2. go test ./... -race -count=1
3. go test ./... -coverprofile=cover.out && go tool cover -func=cover.out
4. go vet ./...
5. golangci-lint run
6. go mod tidy && git diff --exit-code go.mod go.sum
7. gitleaks detect --no-git
8. go test -bench=. -benchmem -count=3 ./...

以及模块专属 Gate（spec Section 20.2）。

输出：
| Gate | Command | Result |
|---|---|---|
| 编译 | go build ./... | ✅ / ❌ |
| ... | ... | ... |
```text

---

## 7. Spec Lint Prompt

用于让 AI 检查 spec 质量。

```markdown
请对 specs/<module>/SPEC.md 做一次 Spec Lint。

检查规则：
1. 每个 Functional Requirement 必须有编号（FR-xxx）
2. 每个 Requirement 必须可测试
3. 每个 Requirement 不应该包含多个不相关行为
4. 每个 Acceptance Criteria 必须对应至少一个 Requirement
5. 每个 Test Case 必须对应至少一个 Acceptance Criteria
6. Non-goals 必须明确
7. Open Questions 必须分为 Blocking / Non-blocking / Future
8. 不能出现模糊词，除非有量化说明
9. Data Model 必须明确字段和类型
10. Error Handling 必须覆盖所有公共错误
11. Edge Cases 必须覆盖空值、并发、超时场景
12. Performance Budget 必须有具体数值

输出格式：
- Critical issues（阻塞开发）
- Warnings（建议改进）
- Suggested rewrites（建议重写的段落）
- Missing sections（缺失的章节）
- Final readiness score: 0-100
```text

---

## 8. Traceability 检查 Prompt

用于让 AI 检查需求追踪完整性。

```markdown
请检查 specs/TRACEABILITY.md 的完整性。

验证：
1. 每个 FR/BR 是否有对应的 AC
2. 每个 AC 是否有对应的 TC
3. 每个 TC 是否有对应的实现 task
4. 是否有实现了但没有 spec 支持的功能（scope creep）
5. 是否有 spec 定义了但没有实现的功能（gap）
6. 是否有 spec 定义了但没有测试的功能（test gap）

输出：
1. Coverage gap report
2. Scope creep report
3. Test gap report
4. 建议的修复动作

不要修改代码。
```text

---

## 9. 模糊词替换参考

当 spec 中出现以下模糊词时，应替换为可测试表达：

| 模糊写法 | 替换为 |
|----------|--------|
| 快速 | < Xms（具体数值） |
| 简单 | 无额外依赖 / 无配置 |
| 好看 | 符合设计系统规范 |
| 支持很多 | ≤ N 个（具体数值） |
| 友好的错误 | 包含错误类型 + 修复建议的具体消息 |
| 用户可以 | WHEN 用户执行 X，THEN 系统执行 Y |
| 需要校验 | 字段 A 必须满足条件 B，否则返回错误 C |
| 安全 | 不硬编码 secret，不记录敏感数据，校验输入 |
| 代码干净 | 函数 < 50 行，文件 < 800 行，无重复逻辑 |
| 高性能 | 操作 X < Yms，内存 < ZMB |
| 可扩展 | 支持 N 个实例 / 支持插件式扩展 |
