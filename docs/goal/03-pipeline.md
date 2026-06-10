# 统一管线与状态模型

> Gate 体系（G0-G11）的定义见 [04-gates.md](04-gates.md)。各层标准见 [05-layer-standards.md](05-layer-standards.md)。

本文档定义 Goal 驱动交付体系的**统一管线**和**四轴状态模型**。

---

## 1. 完整管线

```text
Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
```

每一层回答一个核心问题：

| 层级         | 核心问题                   | 输出物       |
| ------------ | -------------------------- | ------------ |
| Goal         | 为什么做？做到什么算成功？ | 目标定义     |
| Spec         | 具体要做什么？边界是什么？ | 需求规格     |
| Design       | 怎么做？架构怎么拆？       | 设计方案     |
| Plan         | 任务按什么顺序执行？       | 执行计划     |
| Tasks        | 需要拆成哪些可执行任务？   | 任务清单     |
| Prompt       | 如何让 AI/工程师准确执行？ | 指令模板     |
| Code         | 最终实现是否满足验收？     | 代码与测试   |
| Test         | 实现是否正确？             | 测试结果     |
| Review       | 是否满足 Goal/Spec/Design？ | 审查结论    |
| Release      | 是否可上线？               | 发布清单     |
| Retrospective| 哪里可以改进？             | 复盘与 Patch |

> **Matrix（追溯矩阵）** 是横切追溯制品，贯穿所有阶段，不是独立的管线层，也不出现在状态流 From/To 中。它将 Goal → Spec → Requirement → AC → Task → Prompt → Code → Test → Evidence 串联为可追溯的映射关系。详见 [05-layer-standards.md §9](05-layer-standards.md#9-matrix-横切标准)。

### 1.1 可执行工作流剖面

`docs/goal` 的可执行入口是 `docs/goal/tools/goal-workflow.sh`。它把规则、控制面、Matrix、Gate 和 CI 自测串成固定剖面，避免直接调用下层脚本时漏掉横切检查。

| 命令 | 覆盖范围 | 状态语义 |
| ---- | -------- | -------- |
| `preflight` | Python 工具编译、Shell 语法、规则漂移、Goal 文档 lint | 工具和规则自检；不推进状态 |
| `validate` | `preflight` + `.config/goal` 严格校验 + Matrix `check-only` | 验证控制面和追溯矩阵一致性 |
| `gate` | `validate` + Gate 制品就绪检查 | 验证进入 Review / Release 前的就绪度 |
| `ci` | `validate` + 工具链自测 + 有运行制品时自动 Gate | PR / CI 默认剖面 |
| `release` | `gate` + Release hard blocker | Release 前硬阻断；通过后可写 Release Gate manifest |

```bash
bash docs/goal/tools/goal-workflow.sh validate
bash docs/goal/tools/goal-workflow.sh gate
bash docs/goal/tools/goal-workflow.sh ci
```

---

## 2. 四轴状态模型

本节是 Pipeline 状态枚举与状态轴边界的 SSOT。Registry、Glossary、Runtime、Gate 与脚本校验不得定义本地新增状态，只能引用或校验本节枚举。

### 2.0 状态轴边界

| 状态轴 | 含义 | 合法取值来源 | 写入边界 |
| ------ | ---- | ------------ | -------- |
| `pipeline_state` | 全局管线状态机位置 | 本文 §2.1、§2.2 | Pipeline 运行器或 Gate 仲裁器写入 |
| `current_phase` | 当前主流程层级 | `GOAL`、`SPEC`、`DESIGN`、`PLAN`、`TASKS`、`PROMPT`、`CODE`、`TEST`、`REVIEW`、`RELEASE`、`RETROSPECTIVE` | 主流程推进时写入；Matrix 不得写入 |
| `phase_status` | 当前主流程层级的局部进度 | `NOT_STARTED`、`IN_PROGRESS`、`IN_REVIEW`、`READY`、`DONE`、`BLOCKED`、`SKIPPED`、`STALE` | 当前阶段 owner 或 Gate 仲裁器写入 |
| `workflow_step` | SOP、Runtime 或 CI 的执行步骤 / 剖面 | `.config/goal/schema/rules.yaml` 的 `pipeline.workflow_steps` 投影 | 运行器、SOP 或 CI 写入；不得覆盖 `current_phase` 或 `pipeline_state` |

### 2.1 正常状态流

```text
INIT → CONTEXT_READY → GOAL_READY → SPEC_READY → DESIGN_READY
→ PLAN_READY → TASKS_READY → EXECUTING → VERIFYING
→ REVIEWING → RELEASING → RETROSPECTING → DONE
```

### 2.2 异常状态

```text
BLOCKED             — 依赖缺失 / 权限缺失
FAILED              — 执行失败
NEEDS_RESEARCH      — 未知项阻塞决策
NEEDS_DECISION      — 多方案且影响 CL3+
NEEDS_REPLAN        — Spec/Design 变更影响 Plan
NEEDS_ROLLBACK      — Release Gate FAIL 后回滚
NEEDS_HUMAN_APPROVAL — CL3+ 变更需人工确认
INCONSISTENT_STATE  — Registry/Artifact/CI 冲突
```

### 2.3 状态输出格式

每次状态输出必须包含：

```text
Current State:       [当前状态]
Next State:          [下一个状态]
Allowed Actions:     [允许的操作]
Blocked By:          [阻塞项]
Required Gate:       [需要通过的 Gate]
Evidence Required:   [需要的证据]
Recommended Next Action: [建议下一步]
```

### 2.4 状态转换规则

| From | To | Guard 条件 |
|------|-----|-----------|
| INIT | CONTEXT_READY | Context Gate PASS |
| CONTEXT_READY | GOAL_READY | Goal Gate PASS |
| GOAL_READY | SPEC_READY | Spec Gate PASS |
| SPEC_READY | DESIGN_READY | Design Gate PASS |
| DESIGN_READY | PLAN_READY | Plan Gate PASS |
| PLAN_READY | TASKS_READY | Task Gate PASS |
| TASKS_READY | EXECUTING | Task selected / Owner assigned |
| EXECUTING | VERIFYING | Implementation done |
| VERIFYING | REVIEWING | Test Gate + Evidence Gate PASS |
| REVIEWING | RELEASING | Review PASS |
| RELEASING | RETROSPECTING | Release Gate PASS |
| RETROSPECTING | DONE | Retrospective Gate PASS |

### 2.5 对象状态总表

> SSOT：各对象的权威状态定义所在文件。其他文件引用本表，不再重复定义。

| 对象 | 状态值 | 定义位置 |
|------|--------|----------|
| Goal | Draft → Active → Paused → Achieved / Abandoned | [15-registry.md §1](15-registry.md#1-goal-registry) |
| Spec | Draft → Review → Approved → Superseded / Deprecated | [05-layer-standards.md §1](05-layer-standards.md#1-spec-标准) |
| Design | Draft → Review → Approved → Superseded | [05-layer-standards.md §2](05-layer-standards.md#2-design-标准) |
| Plan | Draft → Approved → Superseded | [05-layer-standards.md §3](05-layer-standards.md#3-plan-标准) |
| Task | Unmapped → Mapped → In Progress → Blocked → In Review → Done / Dropped | [05-layer-standards.md §4](05-layer-standards.md#4-tasks-标准) |
| Matrix | Unmapped → Mapped → Linked → Verified / Dropped；Drifted / Stale / Blocked / Changed 为漂移或阻塞元状态 | [05-layer-standards.md §9](05-layer-standards.md#9-matrix-横切标准) |
| Pipeline | INIT→…→DONE（见 §2.1） | [本文件 §2.1](#21-正常状态流) |
| Issue | OPEN → TRIAGED → SPEC_READY → DESIGN_READY → TASKS_READY → IN_PROGRESS → IN_REVIEW → READY_FOR_RELEASE → DONE | [15-registry.md §4](15-registry.md#4-issue-生命周期) |
| Gate | PASS / PASS_WITH_RISK / FAIL / BLOCKED | [04-gates.md](04-gates.md) |
| Maturity | L0–L5 | [18-maturity.md](18-maturity.md) |
| Change Level | CL0–CL5 | [13-runtime-engine.md](13-runtime-engine.md) |

`WAIVED` 是豁免策略，不是 Gate 结果值。豁免记录必须保留 `approver`、`reason`、`expires_at`，并在最终 Gate 结果中映射为 `PASS_WITH_RISK` 或 `BLOCKED`。

Gate 的 `result.verdict` 与 Pipeline 的 `phase_status` 是两条独立状态轴。`NOT_STARTED`、`IN_PROGRESS` 等生命周期状态只能出现在 Pipeline、运行态或补充性快照中，不能作为 Gate `result.verdict`；canonical Gate（`G0`-`G11`）进入控制面时必须给出终态裁决。

回退规则：

| From | To | 条件 |
|------|-----|------|
| VERIFYING | EXECUTING | Test Gate FAIL → 修复实现 |
| REVIEWING | EXECUTING | Review FAIL: implementation → 修复实现 |
| REVIEWING | DESIGN_READY | Review FAIL: design → 修改设计 |
| RELEASING | NEEDS_ROLLBACK | Release Gate FAIL after release → 回滚 |
| ANY | BLOCKED | 依赖缺失 / 权限缺失 |
| ANY | NEEDS_RESEARCH | Unknown 阻塞决策 |
| ANY | NEEDS_DECISION | 多方案且影响 CL3+ |
| ANY | NEEDS_REPLAN | Spec/Design 变更影响 Plan |
| ANY | INCONSISTENT_STATE | Registry/Artifact/CI 冲突 |

---

## 3. 完整链路示例

```text
Goal (GOAL-20260608-001):
为已注册用户提供邮箱验证码登录，验证码登录成功率 ≥ 95%，有效期 10 分钟，使用后不可重复使用。

↓ Spec (SPEC-auth-v1)
REQ-SPEC-auth-v1-001: 用户可以请求邮箱验证码
REQ-SPEC-auth-v1-002: 验证码为 6 位数字
REQ-SPEC-auth-v1-003: 验证码 10 分钟过期
REQ-SPEC-auth-v1-004: 验证码正确后创建登录态
REQ-SPEC-auth-v1-005: 验证码使用后立即失效
REQ-SPEC-auth-v1-006: 发送频率需要限制

↓ Design (DESIGN-auth-v1)
Modules: AuthController, AuthService, CodeStore, RateLimiter, SessionService
Interfaces: sendCode(), verifyCode(), createSession()
DEC-20260608-001: 使用 Redis 存储验证码

↓ Plan (PLAN-GOAL-20260608-001-v1)
Phase 1: 验证码存储（TASK-GOAL-20260608-001-002）
Phase 2: 发送接口（TASK-GOAL-20260608-001-001）+ 频率限制（TASK-GOAL-20260608-001-003）
Phase 3: 校验登录（TASK-GOAL-20260608-001-004）
Phase 4: 测试和验收（TASK-GOAL-20260608-001-005）

↓ Tasks
TASK-GOAL-20260608-001-001: 实现发送验证码接口
TASK-GOAL-20260608-001-002: 实现验证码生成和存储
TASK-GOAL-20260608-001-003: 实现频率限制
TASK-GOAL-20260608-001-004: 实现验证码校验和登录
TASK-GOAL-20260608-001-005: 编写测试

↔ Matrix（横切追溯制品，随 Plan / Tasks / Prompt / Code / Test 更新）
GOAL-20260608-001 → REQ-SPEC-auth-v1-001 → TASK-GOAL-20260608-001-001 → PROMPT-TASK-GOAL-20260608-001-001-001 → AuthController.sendCode → TEST-TASK-GOAL-20260608-001-001-001
GOAL-20260608-001 → REQ-SPEC-auth-v1-004 → TASK-GOAL-20260608-001-004 → PROMPT-TASK-GOAL-20260608-001-004-001 → AuthService.verifyCode → TEST-TASK-GOAL-20260608-001-004-001
GOAL-20260608-001 → REQ-SPEC-auth-v1-005 → TASK-GOAL-20260608-001-004 → PROMPT-TASK-GOAL-20260608-001-004-001 → CodeStore.invalidate → TEST-TASK-GOAL-20260608-001-004-002
GOAL-20260608-001 → REQ-SPEC-auth-v1-006 → TASK-GOAL-20260608-001-003 → PROMPT-TASK-GOAL-20260608-001-003-001 → RateLimiter → TEST-TASK-GOAL-20260608-001-003-001

↓ Prompt (PROMPT-TASK-GOAL-20260608-001-004-001)
请实现 TASK-GOAL-20260608-001-004 验证码校验和登录逻辑，要求验证码正确、未过期、未使用，成功后创建登录态，并立即使验证码失效。

↓ Code
AuthCodeService.verify()
SessionService.create()
CodeStore.invalidate()

↓ Test → Review → Release → Retrospective
```
