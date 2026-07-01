# 分层 DoR / DoD（Definition of Ready / Definition of Done）

> **本文档是 DoR/DoD 的唯一权威来源（SSOT）**。其他文件中的 DoR/DoD 定义应引用本文档。
>
> 各层标准见 [05-layer-standards.md#spec-标准](05-layer-standards.md#1-spec-标准)、[plan-标准](05-layer-standards.md#3-plan-标准)、[tasks-标准](05-layer-standards.md#4-tasks-标准)、[prompt-标准](05-layer-standards.md#5-prompt-标准)、[matrix-标准](05-layer-standards.md#9-matrix-横切标准)。

本文档定义 Goal 驱动交付体系中 **Goal、Spec、Design、Plan、Tasks、Prompt、Code、Test、Review、Issue、Release、Retrospective** 的准备标准和完成标准。主流程顺序与 [03-pipeline.md#完整管线](03-pipeline.md#1-完整管线) 保持一致；Matrix Coverage 是横切追溯制品的覆盖检查，不是主流程阶段，也不是独立 Gate。

---

## 1. Goal DoR / DoD

### DoR（进入 Goal 前必须满足）

```text
- 已说明业务背景
- 已说明目标用户
- 已说明期望结果
- 已说明成功指标
- 已说明范围边界
- 已说明 Non-goals
- 已说明关键约束
```

### DoD（Goal 完成时必须满足）

```text
- 所有关联 Issue 完成
- Success Criteria 满足
- P0/P1 Requirement PASS
- Release Manifest 完整
- Retrospective 完成
- Goal 不再只是口号；可以被拆成具体需求
- 成功可以被验证；范围不会被随意扩张
```

---

## 2. Spec DoR / DoD

### DoR（进入 Spec 前必须满足）

```text
- Goal 已明确
- 业务规则基本清楚
- 用户角色已明确
- 核心流程已明确
```

### DoD（Spec 完成时必须满足）

```text
- 每条需求原子化、可实现、可测试
- 正常/异常/边界路径有描述
- 安全/性能/权限/数据要求无遗漏
```

---

## 3. Design DoR / DoD

### DoR（进入设计前必须满足）

```text
- Spec 已审批
- 核心需求已明确
- 技术约束已识别
- 依赖关系基本清楚
```

### DoD（设计完成时必须满足）

```text
- 每个 Spec Requirement 有对应 Module
- 模块边界清晰
- 接口可测试
- 无循环依赖
- ADR 记录关键决策
```

---

## 4. Plan DoR / DoD

### DoR（进入 Plan 前必须满足）

```text
- Design 已完成
- 主要模块和依赖已知
- 风险点已识别
```

### DoD（Plan 完成时必须满足）

```text
- 执行顺序明确
- 阶段产物明确
- 每阶段有验证点
- 高风险任务提前处理
- 有回滚策略
- 可增量交付
- 已定义 Task 拆分边界和依赖顺序
```

---

## 5. Tasks DoR / DoD

### DoR（进入 Tasks 前必须满足）

```text
- Plan 已完成
- Task 拆分边界已明确
- Matrix 可记录 Goal/Spec/Acceptance Criteria 覆盖关系
```

### DoD（Tasks 完成时必须满足）

```text
- 每个 Task 有明确输入/输出/验收标准/依赖关系
- 每个 Task 足够小，能在合理时间内完成
- 每个 Task 能追溯到 Goal 和 Spec
- 每个 Task 有明确 DoD、验证命令、Evidence 要求和 Rollback 要求
- 无无来源 Task
```

---

## 6. Matrix Coverage DoR / DoD

Matrix Coverage 横切主流程维护，通常在 Spec 后初始化，在 Plan、Tasks、Prompt、Code、Test、Evidence 变化时更新。它不改变 `Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective` 的主流程顺序。

### DoR（初始化或更新 Matrix 覆盖检查前必须满足）

```text
- Goal/Spec/Acceptance Criteria 已编号
- Plan 已完成
- Tasks 已拆分
```

### DoD（Matrix 覆盖检查完成时必须满足）

```text
- 每个 Goal Item 有 Spec 覆盖
- 每条 Spec 有 Task 覆盖
- 每个关键验收标准有 Test 覆盖计划
- 无孤立 Task/Code/需求
- 覆盖检查结果可作为 G5 Task Gate 证据
```

---

## 7. Prompt DoR / DoD

### DoR（进入 Prompt 前必须满足）

```text
- Task 已明确
- 上下文已准备
- 技术约束已明确
```

### DoD（Prompt 完成时必须满足）

```text
- 包含 Goal/Spec/Task
- 输入输出要求明确
- 约束和禁止事项明确
- 验收标准明确
- 测试要求明确
- AI 或工程师可直接执行
```

---

## 8. Code DoR / DoD

### DoR（进入 Code 前必须满足）

```text
- Prompt 已清晰
- 依赖已准备
- 测试要求已明确
- 实现目标仓库已定位为 /home/workspace/{module}
```

### DoD（Code 完成时必须满足）

```text
- 代码实现对应 Task
- 实现变更位于 /home/workspace/{module} 对应代码仓库
- 测试覆盖验收标准
- Matrix 状态已更新
- PR 描述能追溯到 Goal
- 不包含无关功能
- 没有破坏已有能力
- module/{module}/ 未新增模块实现源码树
```

---

## 9. Test DoR / DoD

### DoR（进入测试前必须满足）

```text
- 验收标准已明确
- 测试环境已就绪
- 测试数据已准备
```

### DoD（测试完成时必须满足）

```text
- 单元测试覆盖所有 Task
- 集成测试覆盖关键用户流
- E2E 测试覆盖 Goal 级验收标准
- 性能测试覆盖 Success Metrics
- 测试结果记录在 Evidence 中
```

---

## 10. Review DoR / DoD

### DoR（进入审查前必须满足）

```text
- 实现完成
- 测试通过
- Evidence 已生成
```

### DoD（审查完成时必须满足）

```text
- 代码满足 Task 要求
- 代码满足 Spec 要求
- Matrix 覆盖率达标
- 无 CRITICAL/HIGH 问题
- 安全要求已验证
- 性能要求已验证
```

---

## 11. Issue DoD

```text
- 所有关联 Task 完成
- Traceability Matrix 更新
- Issue 状态更新
- PR 关联
- Evidence 汇总
```

---

## 12. Release DoD

```text
- CI 通过
- PR 描述完整
- CHANGELOG 更新
- Docs 更新
- Release Manifest 完整
- Rollback Plan 完整
- 风险已接受或关闭
```

---

## 13. Retrospective DoD

```text
- 至少识别一个失败或改进点
- 至少生成一个 Prompt / Harness / Rule Patch
- 至少提出一个可自动化 Gate 或脚本建议
- 新增经验进入 Registry 或 rules
```
