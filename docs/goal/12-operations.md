# 运营管理

## 1. 变更管理

需求一定会变。关键不是避免变化，而是让变化可控。

### 变更类型

| 类型         | 说明                                             |
| ------------ | ------------------------------------------------ |
| Goal Change  | 目标结果变化，例如指标从 30 秒改成 10 秒         |
| Scope Change | 范围变化，例如从 CSV 导出增加 Excel 导出         |
| Spec Change  | 业务规则变化，例如导出时间范围从 31 天改成 90 天 |
| Task Change  | 实现方式变化，例如同步导出改成异步导出           |
| Code Change  | 代码实现变化，但需求不变                         |

### 变更影响分析模板

```text
Change Request: CR-001
Change Type: Spec Change

Original: 单次导出时间范围最大 31 天。
New: 单次导出时间范围最大 90 天。
Reason: 运营需要按季度分析订单。

Impact Analysis:
- Goal: 不变
- Spec: SPEC-order-export-v1 需要更新
- Matrix: REQ-SPEC-order-export-v1-003 需要更新
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

| 角色            | 主要负责                                          |
| --------------- | ------------------------------------------------- |
| Product / Owner | Goal、Scope、Success Metrics                      |
| Analyst / PM    | Spec、Acceptance Criteria                         |
| Tech Lead       | Design、Plan、架构边界、Matrix 追溯完整性         |
| Engineer        | Tasks、Prompt、Code、Tests                        |
| QA              | Test、Evidence、验收验证、Matrix 覆盖校验         |
| Reviewer        | Code Review、Release Readiness、Matrix Review     |
| Ops / SRE       | Release、Monitoring、Rollback、Retrospective 输入 |

---

## 4. RACI 模型

```text
R = Responsible，实际执行者
A = Accountable，最终负责人
C = Consulted，被咨询者
I = Informed，被通知者
```

| 阶段          | Product   | Analyst/PM   | Tech Lead   | Engineer   | QA   | Ops/SRE   |
| ------------- | --------- | ------------ | ----------- | ---------- | ---- | --------- |
| Goal          | A/R       | C            | C           | I          | I    | I         |
| Spec          | A         | R            | C           | C          | C    | I         |
| Design        | C         | C            | A/R         | C          | C    | I         |
| Plan          | C         | C            | A/R         | R          | C    | C         |
| Tasks         | I         | C            | A           | R          | C    | I         |
| Prompt        | I         | C            | C           | A/R        | C    | I         |
| Code          | I         | I            | C           | A/R        | C    | I         |
| Test          | C         | C            | C           | R          | A/R  | I         |
| Review        | A         | C            | C           | R          | C    | I         |
| Release       | A         | I            | C           | C          | C    | A/R       |
| Retrospective | A/R       | C            | C           | C          | C    | R         |

---

Matrix 是横切追溯制品，不作为 RACI 阶段；它随 Spec、Design、Plan、Tasks、Prompt、Code、Test、Evidence、Review、Release 的变更同步更新。Tech Lead 对追溯完整性负责，各阶段执行者负责把本阶段事实回填到 Matrix。

## 5. 标准操作流程

```text
Step 1:  写 Goal        明确背景、目标、指标、范围、非目标
Step 2:  评审 Goal      确认目标不是方案，确认成功可验证
Step 3:  写 Spec        把目标拆成系统需求、规则、边界、验收标准
Step 4:  写 Design      固化模块边界、接口、数据流、ADR 和风险
Step 5:  排 Plan        按照风险、依赖和交付价值排序
Step 6:  拆 Tasks       把计划拆成可执行任务
Step 7:  写 Prompt      把每个 Task 转成可执行指令
Step 8:  生成或编写 Code  只实现当前 Task 范围内的内容
Step 9:  写 Test        测试必须覆盖验收标准
Step 10: Review         对照 Matrix 检查覆盖、范围和风险
Step 11: Release        灰度、监控、回滚方案准备好再上线
Step 12: Retrospective  上线后复盘指标、风险、规则和自动化改进
```

Matrix 在 Spec 后初始化，之后在 Design、Plan、Tasks、Prompt、Code、Test、Evidence、Review、Release 变更时横切更新；它不作为主流程步骤编号，也不改变 Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective 顺序。

> 质量指标定义见 [08-quality-gates.md §5](08-quality-gates.md#5-质量指标)。
> 上线后 Goal 验证见 [08-quality-gates.md §7](08-quality-gates.md#7-上线后-goal-验证)。
> 反馈闭环见 [01-methodology.md §8](01-methodology.md#8-反馈闭环)。

---

## 6. 制品版本管理

Goal 的规范文档通过 Git 管理；`.config/goal/` 是统一配置中心，区分可审查控制面与本地运行态。`schema/`、`registry/`、`matrix/`、`gates/`、`pipeline/`、`evidence/` 和 `prompts/` 可进入仓库作为审查快照；`runtime/` 只保存本地缓存、恢复上下文和临时运行态，必须保持 ignored。权威边界见 [00-authority-map.md](00-authority-map.md)。

### 6.1 目录结构

```text
.config/goal/
├── README.md              # 配置中心索引
├── schema/
│   └── rules.yaml         # 从 SSOT 镜像出的校验规则
├── registry/
│   ├── goals.yaml         # Goal Registry
│   ├── tasks.yaml         # Task Registry
│   ├── issues.yaml        # Issue Registry
│   ├── releases.yaml      # Release Registry
│   ├── risks.yaml         # Risk Registry
│   └── decisions.yaml     # Decision Registry
├── matrix/
│   └── matrix.yaml        # Traceability Matrix
├── gates/
│   └── state.yaml         # G0-G11 Gate 状态快照
├── pipeline/
│   └── state.yaml         # 四轴 Pipeline 状态快照
├── evidence/              # Evidence 目录
│   └── EVID-GOAL-20260608-001-001.md
├── prompts/               # Prompt 版本与 Context Package
└── runtime/               # 本地运行态与恢复缓存；不进入仓库
docs/goal/
├── *.md               # Goal 方法论、门禁、模板和治理文档
└── tools/             # Goal 检查与生成工具
```

### 6.2 PR 工作流

```text
1. 创建分支: goal/<goal-id> 或 task/<task-id>
2. 修改制品文件
3. 运行本地预检: bash docs/goal/tools/goal-workflow.sh preflight
4. 运行工作流验证: bash docs/goal/tools/goal-workflow.sh validate
5. 有运行制品时运行 Gate: bash docs/goal/tools/goal-workflow.sh gate
6. Release 前运行硬阻断: bash docs/goal/tools/goal-workflow.sh release
7. 提交并推送
8. PR 描述使用 Release Manifest 模板（见 [17-risk-and-decisions.md §3](17-risk-and-decisions.md#3-release-manifest)）
9. Review 通过后合并
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
