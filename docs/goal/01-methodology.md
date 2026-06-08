# 核心方法论

> **ID 格式说明**：本文档使用新格式 ID（如 GOAL-YYYYMMDD-NNN、SPEC-domain-v1.0），详见 [07-id-system.md](07-id-system.md)。

## 1. 工作流定位

> 简化版，完整管线定义见 [03-pipeline.md](03-pipeline.md)。

在 **Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective** 工作流里，**Goal 是最上游的"结果锚点"**。

它的作用不是描述"怎么做"，而是定义：

> 我们最终要交付什么结果、为什么要做、做到什么程度算成功、哪些事情不做。

## 2. 核心原则

这条链路的关键不是"写文档"，而是建立一套 **可追踪、可验证、可执行、可复用** 的交付系统。

> 完整管线（11 层）和状态机定义见 [03-pipeline.md](03-pipeline.md)。

```text
Goal   定义结果
Spec   定义需求
Design 定义方案
Plan   安排执行
Tasks  拆成动作
Prompt 驱动生成
Code   实现交付
Test   验证正确
Review 审查质量
Release 发布上线
Retrospective 复盘改进
```

## 3. Goal 的输入

Goal 不是凭空写出来的，通常来自这些输入：

```text
Business Need   业务诉求
User Pain       用户痛点
Product Direction 产品方向
System Problem  系统问题
Metric Gap      指标差距
Compliance Need 合规要求
Technical Debt  技术债
```

**示例：**

```text
输入：
用户登录流失率高，密码找回路径太长，客服反馈忘记密码问题占比高。

输出 Goal：
为已注册用户提供邮箱验证码登录能力，将登录转化率从 82% 提升到 90%，
并保证验证码登录过程安全、可控、可审计。
```

## 4. Goal 的输出

一个合格 Goal 最终应该输出：

```text
GOAL-20260608-001: 新增邮箱验证码登录能力

Objective:
为已注册用户提供邮箱验证码登录方式，降低忘记密码导致的登录失败。

Success Metrics:
- 登录转化率从 82% 提升到 90%
- 验证码邮件发送成功率 ≥ 98%
- 验证码登录成功率 ≥ 95%
- 验证码校验接口 P95 响应时间 ≤ 500ms

Scope:
- 邮箱验证码发送
- 验证码校验
- 登录态创建
- 频率限制
- 安全日志

Non-goals:
- 不做手机号登录
- 不做社交账号登录
- 不重构完整认证系统
```

## 5. 交付契约

每一层都必须向下一层提供足够的信息，下一层不能靠猜。

```text
Goal Contract:    告诉 Spec 为什么做、做到什么算成功。
Spec Contract:    告诉 Matrix 有哪些需求、规则、验收条件。
Matrix Contract:  告诉 Tasks 每个需求要被谁实现、谁验证。
Tasks Contract:   告诉 Plan 每个任务的输入、输出、依赖和完成标准。
Plan Contract:    告诉 Prompt 当前任务应该何时执行、依赖什么、风险是什么。
Prompt Contract:  告诉 Code 只能实现什么、不能实现什么、如何验证。
Code Contract:    告诉 Review 和 Release 代码满足了哪些目标、测试覆盖了哪些验收标准。
```

> **每一层不是文档，而是下一层的输入契约。**

## 6. 追溯关系图

```text
GOAL-20260608-001 Goal
  ├── SPEC-auth-v1.0 Spec
  │     ├── REQ-SPEC-auth-001 Requirement
  │     │     ├── TASK-GOAL-20260608-001-001 Task
  │     │     │     ├── PROMPT-TASK-GOAL-20260608-001-001-001 Prompt
  │     │     │     ├── C-001 Code Module
  │     │     │     └── TC-001 Test Case
  │     │
  │     ├── REQ-SPEC-auth-002 Requirement
  │     │     ├── TASK-GOAL-20260608-001-002 Task
  │     │     ├── PROMPT-TASK-GOAL-20260608-001-002-001 Prompt
  │     │     ├── C-002 Code Module
  │     │     └── TC-002 Test Case
  │     │
  │     └── REQ-SPEC-auth-003 Performance Requirement
  │           ├── TASK-GOAL-20260608-001-003 Task
  │           ├── PROMPT-TASK-GOAL-20260608-001-003-001 Prompt
  │           ├── C-003 Code Module
  │           └── TC-003 Performance Test
```

向下：Goal 可以分解到具体代码。
向上：代码可以证明自己服务于某个目标。

## 7. 追溯关系模型

```text
Goal HAS Spec
Spec HAS Requirement
Requirement HAS Acceptance Criteria
Acceptance Criteria COVERED_BY Test
Requirement IMPLEMENTED_BY Task
Task EXECUTED_BY Prompt
Prompt PRODUCES Code
Code VERIFIED_BY Test
Test VALIDATES Acceptance Criteria
```

简化：

```text
GOAL → SPEC → REQ → AC → TC
             ↓
             TASK → P → C → TC
```

最终闭环：

```text
Goal → Spec → Requirement → Task → Prompt → Code → Test → Acceptance Criteria → Goal
```

## 8. 反馈闭环

上线后如果指标未达成，不应该直接改代码，而是重新进入流程：

```text
Metric Gap
  ↓
New Goal / Goal Adjustment
  ↓
Spec Change
  ↓
Matrix Update
  ↓
Tasks → Plan → Prompt → Code
```

## 9. 最终判断标准

> 任何一行代码，都能追溯到一个 Task；任何一个 Task，都能追溯到一个 Spec；任何一个 Spec，都能追溯到一个 Goal；任何一个 Goal，都有可验证的成功标准。

简化版：

```text
Goal 有结果
Spec 有规则
Matrix 有覆盖
Tasks 有动作
Plan 有顺序
Prompt 有指令
Code 有验证
```
