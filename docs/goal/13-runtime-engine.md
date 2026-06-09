# 运行引擎

本文档定义 Goal 驱动交付的运行时机制。工作流和四轴状态模型的权威定义见 [03-pipeline.md#四轴状态模型](03-pipeline.md#2-四轴状态模型)，Gate 体系见 [04-gates.md#gate-类型](04-gates.md#1-gate-类型)，ID 系统见 [07-id-system.md#id-格式](07-id-system.md#1-id-格式)。

---

## 1. 执行模式

根据变更级别选择执行模式，避免一刀切。

### 变更级别

> **变更影响级别（CL0-CL5）**：用于评估变更的影响范围和审批要求。注意：此级别体系与成熟度模型的 L0-L5 级别不同。

| 级别  | 说明                       | 示例                   |
| ----- | -------------------------- | ---------------------- |
| CL0   | 文档修正                   | 修复 README 错别字     |
| CL1   | 局部实现修复               | 修复单个函数的边界条件 |
| CL2   | 模块行为变化               | 新增导出功能           |
| CL3   | 公共接口变化               | 修改 API 响应格式      |
| CL4   | 架构边界变化               | 拆分模块、引入新依赖   |
| CL5   | 数据模型 / 存储 / 迁移变化 | 数据库 Schema 变更     |

### Lite Mode（CL0/CL1）

| 级别 | 适用场景 | 最小流程 | 强制 Gate | 裁剪说明 |
|------|----------|----------|-----------|----------|
| CL0 | 仅文档、注释或元数据修正，不改变行为、接口、Gate、状态模型或可执行规则 | Goal → Plan → Docs Change → Evidence → Review | Evidence Gate (G8)、Review Gate (G9) | Spec / Design / Matrix 可省略；如修改治理规则、状态、模板、脚本或追溯协议，必须升为 CL1+ |
| CL1 | 局部实现、规则或文档体系修正，不改变公共接口和跨模块契约 | Goal → Plan → Tasks → Prompt → Code → Test → Evidence → Review | Task Gate (G5)、Test Gate (G7)、Evidence Gate (G8)、Review Gate (G9) | Spec / Design 可合并进 Goal 或 Plan；当 AC / Test / Evidence 追溯发生变化时，Matrix 必须维护 |

### Standard Mode（CL2）

```text
包含：Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
强制：Traceability Matrix（横切制品，不作为阶段）、Risk Register、Release Manifest、Evidence
```

### Full Mode（CL3/CL4/CL5）

```text
包含：Standard Mode 主流程 + Registry + State Machine + Human Approval Check + Rollback Protocol + Change Propagation Matrix
强制：ADR、Human Approval Check、Executable Gates、Release Manifest、Rollback
```

---

## 2. 对象模型

所有执行对象必须可追踪。

### 核心对象

```text
Goal、Spec、Requirement、Acceptance Criteria、Design、ADR、Plan、Milestone、
Task、Prompt、Code、Test、Evidence、Risk、Decision、Review、Release、Retrospective、
Prompt Patch、Harness Patch、Rule Patch
```

### 对象关系

```text
Goal owns Spec
Spec contains Requirements
Requirement verified_by Acceptance Criteria
Requirement implemented_by Design
Design executed_by Plan
Plan decomposes_to Tasks
Task instructed_by Prompt
Prompt drives Code
Code changes Files
Code verified_by Tests
Task proven_by Evidence
Evidence supports Review
Review unlocks Release
Release triggers Retrospective
Retrospective patches Prompt / Harness / Rules
```

---

## 3. 优先级评分

### 公式

```text
Priority Score
= (Impact × 0.30)
+ (Urgency × 0.20)
+ (Dependency Unlock × 0.20)
+ (Risk Reduction × 0.20)
+ (User Value × 0.10)
- (Effort × 0.15)
```

### 映射

| 分数      | 优先级 |
| --------- | ------ |
| ≥ 4.0     | P0     |
| 3.0 ~ 3.9 | P1     |
| 2.0 ~ 2.9 | P2     |
| < 2.0     | P3     |

### 优先执行原则

```text
高 unlock（解锁其他任务）
高风险降低（尽早暴露问题）
低 effort（快速见效）
高影响（对 Goal 贡献大）
```

---

## 4. Evidence 协议

### 必须包含

```text
Evidence ID:     EVID-xxx
Task ID:         TASK-xxx
Test ID:         TEST-xxx
Goal ID:         GOAL-xxx
Date:            YYYY-MM-DD
Status:          PASS / FAIL / PARTIAL
Files Changed:   [文件清单]
Commands Run:    [执行的命令]
Results:         [执行结果]
Logs:            [关键日志]
Diff Summary:    [变更摘要]
Requirement Proof: [对应需求证明]
Known Limitations: [已知限制]
Risks:           [风险]
Rollback:        [回滚方案]
```

### 禁止

```text
无日志声称完成
无测试声称完成
无文件清单声称完成
无风险说明声称完成
```

---

## 5. 失败预算

### 重试策略

```yaml
failure_policy:
  task_max_retry: 2
  test_fail_threshold: 3
  review_fail_threshold: 2
  ci_fail_threshold: 2
  after_retry_fail: NEEDS_REPLAN
  after_ci_fail: ROOT_CAUSE_ANALYSIS
  after_review_fail: DESIGN_OR_TASK_REVIEW
```

### 降级路径

| 场景         | 降级动作                       |
| ------------ | ------------------------------ |
| 执行失败     | 缩小任务范围                   |
| 测试失败     | 回到 EXECUTING                 |
| Review 失败  | 回到 DESIGN_READY 或 EXECUTING |
| CI 连续失败  | 停止合并，进入 RCA             |
| Release 失败 | NEEDS_ROLLBACK                 |
| 未知问题     | NEEDS_RESEARCH                 |
| 多方案冲突   | NEEDS_DECISION                 |

---

## 6. AutoResearch 协议

### 触发条件

```text
项目信息不足
API 行为不确定
依赖版本不确定
Issue 描述不完整
架构设计存在冲突
文档和代码不一致
测试失败原因不明确
外部系统行为可能变化
```

### 输出格式

```text
Question:    [需要研究的问题]
Sources:     [查阅的来源]
Findings:    [发现的事实]
Confidence:  [置信度 High/Medium/Low]
Impact:      [对当前任务的影响]
Decision:    [基于研究的决定]
Follow-up:   [后续行动]
```

---

## 7. 人工审批检查

### 需要人工确认的场景

```text
Spec Freeze（需求冻结）
Design Accept（设计确认）
Public API Change（公共接口变更）
Architecture Boundary Change（架构边界变更）
Storage Migration（存储迁移）
Security-sensitive Change（安全敏感变更）
Risk Acceptance（风险接受）
Release Approval（发布审批）
Rollback Execution（回滚执行）
```

### 审批检查（H-CHK1 ~ H-CHK8）

H-CHK* 是人工审批检查项，不是独立 Gate 编号；阻塞和通过结论归属对应的 G9 Review Gate 或 G10 Release Gate 证据。

| 检查项 | 名称                                  |
| ---- | ------------------------------------- |
| H-CHK1 | Spec Freeze Approval                  |
| H-CHK2 | Design Review Approval                |
| H-CHK3 | Public API Change Approval            |
| H-CHK4 | Architecture Boundary Change Approval |
| H-CHK5 | Migration Approval                    |
| H-CHK6 | Risk Acceptance Approval              |
| H-CHK7 | Release Approval                      |
| H-CHK8 | Rollback Approval                     |

### 规则

```text
CL0 / CL1 不强制人工确认
CL2 需要 Reviewer 确认
CL3 / CL4 / CL5 必须人工确认
Release 到生产环境必须人工确认
```

---

## 8. 变更传播矩阵

上游变更必须向下游传播。

| 变更对象         | 必须同步                                          |
| ---------------- | ------------------------------------------------- |
| Goal 变更        | Spec / Design / Plan / Tasks / Registry / Issue   |
| Spec 变更        | Design / Plan / Tasks / Test / Traceability       |
| Requirement 变更 | Acceptance Criteria / Tasks / Tests / Evidence    |
| Design 变更      | ADR / Plan / Tasks / Risk / Docs                  |
| Plan 变更        | Tasks / Dependency Graph / Registry               |
| Task 变更        | Prompt / Code / Test / Evidence / Registry / Issue / PR |
| Public API 变更  | Docs / Tests / CHANGELOG / ADR / Release Manifest |
| Storage 变更     | Migration / Rollback / Tests / Release Manifest   |
| Config 变更      | Example / Docs / Tests / Release Manifest         |
| CI 变更          | Harness / Docs / Release Manifest                 |
| Risk 变更        | Review / Release / Retrospective                  |
| Release 变更     | CHANGELOG / Manifest / Rollback / Registry        |

### 传播规则

```text
1. 上游对象变更后，下游对象状态自动进入 STALE
2. STALE 对象必须重新验证
3. Release Gate 禁止存在 P0/P1 STALE 对象
4. Spec / Design 变更后必须触发 NEEDS_REPLAN
```
