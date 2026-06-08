# 自动化 Lint 规则

## 1. Goal Lint

```text
G-LINT-001: Goal 必须包含 objective
G-LINT-002: Goal 必须包含 success_metrics 或 acceptance_criteria
G-LINT-003: Goal 不能只描述实现方案
G-LINT-004: Goal 必须包含 scope_out
G-LINT-005: Goal 必须包含 target_user 或 target_actor
G-LINT-006: Goal 必须至少有一个可验证指标
G-LINT-007: Goal 不应使用模糊词而没有定义
```

### 模糊词检查清单

以下词语必须有量化定义才能使用：

```text
优化、提升、增强、完善、更好、更快、更稳定、体验更佳、高可用、易用、智能化
```

不合格：`提升系统稳定性。`

合格：`将订单导出任务失败率从 3% 降低到 0.5% 以下，并保证导出任务异常时可以自动重试 3 次。`

---

## 2. Spec Lint

```text
S-LINT-001: 每条 Functional Requirement 必须有唯一 ID
S-LINT-002: 每条 Requirement 必须能被测试
S-LINT-003: 每条 Acceptance Criteria 必须有明确结果
S-LINT-004: 权限相关功能必须包含 Security Requirements
S-LINT-005: 数据导入/导出功能必须包含数据量限制
S-LINT-006: 异步任务必须包含状态流转规则
S-LINT-007: 用户可见错误必须包含 Error Handling
S-LINT-008: 涉及外部服务必须包含失败处理
```

---

## 3. Matrix Lint

```text
M-LINT-001: 每个 Goal 至少对应一个 Spec
M-LINT-002: 每个 Spec Requirement 至少对应一个 Matrix Row
M-LINT-003: 每个 Matrix Row 必须有 Task
M-LINT-004: 每个 P0/P1 Matrix Row 必须有 Test Case
M-LINT-005: 每个 Task 必须能追溯到 Matrix Row
M-LINT-006: 不允许存在 Orphan Task
M-LINT-007: 不允许存在 Orphan Code
M-LINT-008: Done 状态必须同时满足 Code + Test
```

---

## 4. Prompt Lint

```text
P-LINT-001: Prompt 必须包含 Source
P-LINT-002: Prompt 必须包含 Task Objective
P-LINT-003: Prompt 必须包含 Requirements
P-LINT-004: Prompt 必须包含 Constraints
P-LINT-005: Prompt 必须包含 Output
P-LINT-006: Prompt 必须包含 Acceptance Criteria
P-LINT-007: Prompt 必须包含 Test Requirements
P-LINT-008: Prompt 必须包含 Do Not
P-LINT-009: Prompt 不能要求一次性实现多个无关任务
P-LINT-010: Prompt 不能允许自行扩大范围
```

---

## 5. Code Lint

PR 描述中必须包含来源信息：

```text
C-LINT-001: PR 必须引用至少一个 Task
C-LINT-002: PR 必须引用至少一个 Matrix Row
C-LINT-003: PR 必须包含测试说明
C-LINT-004: P0/P1 Task 不允许无测试合并
C-LINT-005: PR 不能包含未关联 Task 的大规模代码改动
```

---

## 6. Lint 执行建议

| 层级 | 检查时机 | 自动化程度 |
|------|----------|------------|
| Goal Lint | Goal Review Gate 前 | 可半自动（关键词扫描） |
| Spec Lint | Spec Review Gate 前 | 可半自动（结构检查） |
| Matrix Lint | Matrix Review Gate 前 | 可全自动（覆盖关系检查） |
| Prompt Lint | Prompt 生成后 | 可全自动（字段完整性） |
| Code Lint | PR 提交时 | 可全自动（CI 集成） |
