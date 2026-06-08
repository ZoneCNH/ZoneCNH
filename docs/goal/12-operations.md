# 运营管理

## 1. 变更管理

需求一定会变。关键不是避免变化，而是让变化可控。

### 变更类型

| 类型 | 说明 |
|------|------|
| Goal Change | 目标结果变化，例如指标从 30 秒改成 10 秒 |
| Scope Change | 范围变化，例如从 CSV 导出增加 Excel 导出 |
| Spec Change | 业务规则变化，例如导出时间范围从 31 天改成 90 天 |
| Task Change | 实现方式变化，例如同步导出改成异步导出 |
| Code Change | 代码实现变化，但需求不变 |

### 变更影响分析模板

```text
Change Request: CR-001
Change Type: Spec Change

Original: 单次导出时间范围最大 31 天。
New: 单次导出时间范围最大 90 天。
Reason: 运营需要按季度分析订单。

Impact Analysis:
- Goal: 不变
- Spec: SPEC-order-export-v1.0 需要更新
- Matrix: REQ-SPEC-order-export-v1.0-003 需要更新
- Tasks: TASK-GOAL-20260601-001-003 CSV 生成可能受影响
- Plan: 需要增加性能验证
- Prompt: PROMPT-TASK-GOAL-20260601-001-003-001 需要更新
- Code: CsvExportService 查询逻辑可能受影响
- Tests: 需要新增 90 天导出测试
- Risk: 数据量增加，性能风险升高

Decision: 接受，但需要异步导出和分页生成 CSV。
Owner: Backend Team
Status: Approved
```

---

## 2. 版本管理

> **版本管理范围**：本文档定义变更管理流程、制品版本号规范和版本标记方式。Release Manifest（发布清单）的定义见 [17-risk-and-decisions.md §3](17-risk-and-decisions.md#3-release-manifest)。

每个文档都应该有版本。

### 版本号定义

```text
v0.1  Draft（草案）
v0.2  Reviewed（已审查）
v1.0  Approved（已批准）
v1.1  Changed（已变更，需重新审查）
v2.0  Major Change（重大变更）
```

版本管理的目的：

```text
知道什么时候变了
知道为什么变了
知道影响了什么
知道谁批准了
```

版本变更必须记录在制品文件头部或 CHANGELOG 中。

---

## 3. 角色分工

| 角色 | 主要负责 |
|------|----------|
| Product / Owner | Goal、Scope、Success Metrics |
| Analyst / PM | Spec、Acceptance Criteria |
| Tech Lead | Matrix、Plan、Architecture |
| Engineer | Tasks、Prompt、Code、Tests |
| QA | Test Matrix、Acceptance Validation |
| Reviewer | Code Review、Matrix Review |
| Ops / SRE | Release、Monitoring、Rollback |

---

## 4. RACI 模型

```text
R = Responsible，实际执行者
A = Accountable，最终负责人
C = Consulted，被咨询者
I = Informed，被通知者
```

| 阶段 | Product | Tech Lead | Engineer | QA |
|------|---------|-----------|----------|-----|
| Goal | A/R | C | I | I |
| Spec | A/R | C | C | C |
| Matrix | C | A/R | C | C |
| Tasks | I | A | R | C |
| Plan | C | A/R | R | C |
| Prompt | I | C | A/R | C |
| Code | I | C | A/R | C |
| Test | C | C | R | A/R |

---

## 5. 标准操作流程

```text
Step 1:  写 Goal        明确背景、目标、指标、范围、非目标
Step 2:  评审 Goal      确认目标不是方案，确认成功可验证
Step 3:  写 Spec        把目标拆成系统需求、规则、边界、验收标准
Step 4:  建 Matrix      把 Goal、Spec、Task、Prompt、Code、Test 串起来
Step 5:  拆 Tasks       按照 Matrix 拆成可执行任务
Step 6:  排 Plan        按照风险、依赖和交付价值排序
Step 7:  写 Prompt      把每个 Task 转成可执行指令
Step 8:  生成或编写 Code  只实现当前 Task 范围内的内容
Step 9:  写 Test        测试必须覆盖验收标准
Step 10: Review         对照 Matrix 检查覆盖、范围和风险
Step 11: Release        灰度、监控、回滚方案准备好再上线
Step 12: Validate Goal  上线后用指标验证 Goal 是否达成
```

> 质量指标定义见 [08-quality-gates.md §5](08-quality-gates.md#5-质量指标)。
> 上线后 Goal 验证见 [08-quality-gates.md §7](08-quality-gates.md#7-上线后-goal-验证)。
> 反馈闭环见 [01-methodology.md §8](01-methodology.md#8-反馈闭环)。

---

## 6. 制品版本管理

Goal 的规范文档通过 Git 管理；Goal 的运行状态、Registry、Matrix、Evidence 和恢复上下文统一存放在本地 `.config/goal/`，不进入仓库。

### 6.1 目录结构

```text
.config/goal/
├── registry/
│   ├── goals.yaml         # Goal Registry
│   ├── tasks.yaml         # Task Registry
│   ├── issues.yaml        # Issue Registry
│   ├── releases.yaml      # Release Registry
│   ├── risks.yaml         # Risk Registry
│   └── decisions.yaml     # Decision Registry
├── matrix.yaml            # Traceability Matrix
├── evidence/              # Evidence 目录（按日期/Task 分组）
│   └── 2026-06-08/
│       └── TASK-GOAL-20260608-001-001/
│           └── evidence.md
├── state/                 # Goal 运行时状态
└── context.md             # Goal 上下文恢复文件
docs/goal/
├── *.md               # Goal 方法论、门禁、模板和治理文档
└── tools/             # Goal 检查与生成工具
```

### 6.2 PR 工作流

```text
1. 创建分支: goal/<goal-id> 或 task/<task-id>
2. 修改制品文件
3. 运行 lint 检查（计划中）: ./docs/goal/tools/lint-goal.sh docs/goal/
4. 运行 gate 检查（计划中）: ./docs/goal/tools/gate-check.sh .
5. 提交并推送
6. PR 描述使用 Release Manifest 模板（见 [17-risk-and-decisions.md §3](17-risk-and-decisions.md#3-release-manifest)）
7. Review 通过后合并
```

### 6.3 Review 过程

制品变更的 Review 重点：

```text
- Goal 变更: 检查 SMART 合规、指标合理性
- Spec 变更: 检查 AC 完整性、边界覆盖
- Matrix 变更: 检查覆盖率、孤儿项
- Task 变更: 检查 DoD 完整性、依赖合理性
- Evidence 变更: 检查字段完整性、测试结果真实性
- Registry 变更: 检查状态流转合规性
```

### 6.4 合并策略

```text
- 制品文件使用 Squash Merge（保持历史整洁）
- Registry YAML 使用 Merge Commit（保留状态流转历史）
- Evidence 文件合并后不可修改（只追加）
- Spec/Task 变更必须伴随 Matrix 同步更新
```
