# 各层标准

> 管线定义见 [03-pipeline.md#完整管线](03-pipeline.md#1-完整管线)，Gate 体系见 [04-gates.md#gate-类型](04-gates.md#1-gate-类型)。

本文档定义 Goal 驱动交付体系中 **Spec、Design、Plan、Tasks、Prompt、Code、Test** 的主流程层级标准，并定义 **Matrix** 作为横切追溯制品的维护标准。唯一主流程顺序定义见 [03-pipeline.md §1 完整管线](03-pipeline.md#1-完整管线)。

Matrix 不参与主流程排序，不作为状态模型阶段。

---

## 1. Spec 标准

### 结构

```text
Spec ID:        SPEC-<domain>-vN
Spec Name:      需求名称
Source Goal:    来自哪个 Goal
User Story:     作为【角色】，我希望【能力】，以便【价值】
Functional Requirements:  功能性需求
Business Rules:           业务规则
Edge Cases:               边界情况
Error Handling:           错误处理
Security Requirements:    安全要求
Performance Requirements: 性能要求
Data Requirements:        数据要求
API / UI Requirements:    接口或界面要求
Acceptance Criteria:      验收标准
Out of Scope:             不包含内容
```

### Goal → Spec 转换

按 7 个问题拆：

| 问题 | 产出 |
|------|------|
| 谁使用？ | Actor / Role |
| 在哪里使用？ | Scenario |
| 要完成什么动作？ | Functional Requirement |
| 输入是什么？ | Input Requirement |
| 输出是什么？ | Output Requirement |
| 有什么规则？ | Business Rule |
| 什么情况算成功？ | Acceptance Criteria |

### 原子化标准

一个 Spec Requirement 应该满足：

```text
- 只表达一个行为
- 有明确主体
- 有明确输入
- 有明确输出
- 可以独立测试
- 可以映射到一个或多个 Task
```

不合格：`系统支持订单导出。`

合格：

```text
REQ-SPEC-export-v1-001: 用户可以点击导出按钮。
REQ-SPEC-export-v1-002: 系统校验用户导出权限。
REQ-SPEC-export-v1-003: 系统校验筛选时间范围。
REQ-SPEC-export-v1-004: 系统创建导出任务。
REQ-SPEC-export-v1-005: 系统生成 CSV 文件。
REQ-SPEC-export-v1-006: 系统提供下载链接。
REQ-SPEC-export-v1-007: 系统记录导出日志。
```

### Spec 状态

```text
Draft → Review → Approved → Superseded / Deprecated
```

`Changed` 不是 Spec 的稳定终态。Approved Spec 如需语义变更，MUST 进入新的 Draft / Review 周期，或由新版本 Supersede 旧版本；历史 prompt 或投影中出现的 `Reviewed` / `Changed` 只能作为兼容显示，不能作为新的控制面状态。

---

## 2. Design 标准

Design 在 Spec 之后、Plan 之前，回答"怎么拆、怎么隔离"。

### 结构

```text
Design ID:    DESIGN-<domain>-vN
Source Goal:  对应 Goal
Source Spec:  对应 Spec
Modules:      模块拆分
Interfaces:   接口定义
Data Flow:    数据流
Dependencies: 依赖关系
ADR:          架构决策记录
Risks:        技术风险
```

### Design Gate 检查

```text
- 每个 Spec Requirement 有对应 Module
- 模块边界清晰
- 接口可测试
- 无循环依赖
- ADR 记录关键决策
```

---

## 3. Plan 标准

Plan 在 Design 之后、Tasks 之前产出，先定义执行策略、阶段顺序、风险处理和拆分边界，再生成可执行 Task 清单。

### 结构

```text
Plan ID:            PLAN-<goal-id>-vN
Source Goal:        对应 Goal
Source Design:      对应 Design
Execution Strategy: 整体执行策略
Phases:             阶段列表（每阶段含 Task、Goal、Output、Validation）
Risks:              风险清单 → 应对方式
Checkpoints:        检查点
Rollback Plan:      回滚方式
Final Validation:   最终验收方式
```

### Plan → Tasks 排序规则

```text
1. 先处理不确定性最高的任务（Technical Spike）
2. 再处理核心主路径（Happy Path）
3. 再处理边界条件（Business Rules）
4. 再处理安全与性能（Security / Performance）
5. 最后处理体验优化和文档（Tests / Docs / Release）
```

### Plan 检查标准

```text
- 是否先做基础能力？
- 是否先处理高风险任务？
- 是否有阶段性验证点？
- 是否有回滚方案？
- 是否避免阻塞依赖？
- 是否能增量交付？
```

---

## 4. Tasks 标准

Tasks 在 Plan 之后产出，遵循 Plan 定义的执行顺序、依赖关系和风险优先级。

### 结构

```text
Task ID:        TASK-<goal-id>-NNN
Task Name:      任务名称
Source:         Goal / Spec / Matrix
Objective:      这个任务要完成什么
Description:    任务说明
Input:          输入内容
Output:         交付结果
Implementation Notes: 实现说明
Acceptance Criteria:  完成标准
Dependencies:   依赖任务
Test Requirement:     测试要求
Priority:       P0 / P1 / P2
```

### 拆解方式

| 拆解方式 | 适用场景 |
|----------|----------|
| 按模块拆 | Controller、Service、Repository、UI |
| 按流程拆 | 输入、处理、输出 |
| 按风险拆 | 先做高风险技术验证 |
| 按验收标准拆 | 每个 AC 对应任务 |
| 按垂直切片拆 | 从 UI 到 DB 完成一条完整路径 |

推荐优先级：**优先垂直切片 → 其次按风险拆 → 最后按模块拆**

### 粒度标准

```text
- 一个 Task 应该在 0.5 天到 2 天内完成
- 一个 Task 应该能独立验证
- 一个 Task 应该有明确代码产物
- 一个 Task 不应该混合多个不相关目标
```

### Task 状态

```text
Unmapped → Mapped → In Progress → Blocked → In Review → Done → Dropped
```

---

## 5. Prompt 标准

### 结构

```text
Prompt ID:    PROMPT-<task-id>-NNN
Role:         AI 或执行者角色
Source:       Task ID
Context:      系统背景
Objective:    本次 Prompt 要完成什么
Requirements: 必须满足的需求
Constraints:  限制条件
Input:        已有代码 / 数据结构 / API / 约定
Output:       期望输出
Acceptance Criteria: 验收标准
Test Requirements:   测试要求
Do Not:       禁止事项
```

### Prompt 分层

| Prompt 类型 | 作用 |
|-------------|------|
| Analysis Prompt | 分析需求和风险 |
| Design Prompt | 设计方案和接口 |
| Implementation Prompt | 生成代码 |
| Test Prompt | 生成测试 |
| Review Prompt | 检查代码是否满足 Matrix |

### 质量标准

```text
- 不依赖猜测
- 不缺上下文
- 不省略约束
- 不混合多个目标
- 不产生无法验证的输出
- 不允许 AI 自行扩大范围
```

对应的自动化检查映射见 [10-lint-rules.md §4 Prompt Lint](10-lint-rules.md#4-prompt-lint)。

---

## 6. Code 标准

### 交付标准

```text
Code Deliverable:
- 业务代码
- 错误处理
- 配置项
- 数据结构变更
- 单元测试
- 集成测试
- 文档或注释
- Matrix 状态更新
```

实现位置：

```text
- 模块实现代码统一在 /home/{module} 对应仓库中修改
- module/{module}/ 只保存 Goal、Spec、Traceability、Task、Plan、Prompt、Evidence 引用，以及受规则 allowlist 约束的只读分析快照
- 不得把模块源码树、vendor 源码或从 /home/{module} 复制出的实现文件提交到本仓库
```

### 反向验证

代码写完后，不是问"代码能不能跑？"，而是问"它是否完成了 Goal？"

```text
Code → Test → Tasks → Spec → Goal
```

---

## 7. Test 标准

Test 贯穿全程，不是 Code 写完后才想。

```text
Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
                                         ↓         ↑
                                       Tests ← Acceptance Criteria
```

| 测试类型 | 来源 | 执行阶段 |
|----------|------|----------|
| 单元测试 | Task / Function Requirement | EXECUTING → VERIFYING |
| 集成测试 | Spec / User Flow | VERIFYING |
| E2E 测试 | Goal / Acceptance Criteria | REVIEWING |
| 性能测试 | Success Metrics / Performance Requirement | REVIEWING |
| 安全测试 | Security Requirement | REVIEWING |
| 回归测试 | Existing Behavior / Constraints | VERIFYING |

---

## 9. Matrix 横切标准

> Matrix 是横切追溯制品，不参与主流程排序，不作为状态机阶段。它在 Spec 审批后可初始化，并随 Design、Plan、Tasks、Prompt、Code、Test、Evidence、Risk 和 Gate 更新。
>
> Canonical Matrix 使用 edge model，不使用旧 row model 作为控制面规则。表格可以作为展示视图存在，但进入 Gate、validator、CI 或 Release 前 MUST 投影为 canonical edge。

### Canonical edge 字段

| 字段 | 说明 |
|------|------|
| edge_id | 唯一边 ID，例如 `EDGE-GOAL-20260610-001-AC01-TEST01` |
| source_type / source_id | 来源节点类型与 ID，如 Goal、Spec、AC、Task、Prompt、Code、Test、Evidence、Risk、Gate |
| target_type / target_id | 目标节点类型与 ID |
| relation | canonical relation vocabulary 中的一个值，见下表 |
| status | Unmapped / Mapped / Linked / Verified / Dropped / Blocked / Changed / Drifted / Stale |
| evidence_id | 证明该 edge 的 Evidence ID；release-critical edge MUST 填写 |
| risk_id | 关联风险；High/Critical 或 release_blocking 风险 MUST 填写 |
| drop_reason | `Dropped` 时必填 |
| updated_at | 最近更新日期或时间戳 |

### Canonical relation vocabulary

进入 `.config/goal/matrix/matrix.yaml`、Gate、validator、CI 或 Release 控制面的 Matrix edge，`relation` 字段 MUST 使用以下枚举：

| relation | 含义 |
|----------|------|
| `decomposes_to` | 上游目标或需求分解为下游制品 |
| `contains` | 上游制品包含下游制品 |
| `accepted_by` | 需求或结果由验收标准确认 |
| `planned_by` | 需求或任务由计划安排 |
| `implemented_by` | 需求、任务或 Prompt 由代码实现 |
| `prompted_by` | 执行由 Prompt 或 Context Package 驱动 |
| `verified_by` | 需求、任务、代码或发布由测试、审查或验证证明 |
| `evidenced_by` | Gate、Release、Risk 或 Matrix edge 由 Evidence Bundle 证明 |

`implements`、`verifies`、`blocks`、`releases`、`measures`、`mitigates`、`approves` 等词可以在叙述、图例或人类展示视图中作为语义别名出现，但 MUST NOT 写入 Matrix 控制面、Gate、validator、CI 或 Release 记录。若需要新增控制面 relation，必须先提交受保护资产 Change Request，并同步 schema、validator 和 CI。

### 展示与导入兼容

旧的 `Goal ID / Spec ID / Task ID / Prompt ID / Code Module / Test Case / Evidence` 表格可以作为人类阅读视图或导入格式存在，但不得作为新的控制面 schema。任何表格视图进入 Gate、validator、CI 或 Release 前，MUST 被投影为 canonical edge；投影失败时不得宣称 Matrix 完整。

### 合格标准

```text
1. 每个 Goal 至少有一条到 Spec 或明确 Non-goal / Dropped 决策的 edge。
2. 每个 Spec Requirement 至少有一条到 Task、Test 或 Decision 的 edge。
3. 每个 P0/P1 Acceptance Criteria 必须同时有 Test edge 与 Evidence edge。
4. 每个 release-critical edge 必须有 status 和 evidence_id。
5. 任何 Dropped edge 必须有 drop_reason 和审批记录。
6. 不允许存在无来源 Task、无来源 Code、无证据 Done 或未解释的 Blocked/Drifted/Stale edge。
```

### Matrix 生命周期

```text
创建时机：Spec 审批后立即创建
维护人：Tech Lead（A），Engineer（R）
更新触发：
  - Spec 变更 → 同步更新相关 edge
  - Plan 完成 → 标记执行顺序、依赖和 Gate edge
  - Task 拆分 → 补充 Task / Test / Evidence edge
  - Task 完成 → 更新 edge Status
  - Prompt / Code 变更 → 同步 Prompt / Code edge
  - 测试通过 → 更新 Test / Evidence edge
完整性检查：
  - Gate G5（Task Gate）自动检查 Matrix edge 覆盖率
  - Release 前必须所有 release-critical edge 为 Status = Verified，或 Status = Dropped 且有 drop_reason
```

### Matrix 状态

```text
Unmapped → Mapped → Linked → Verified
                         ↘ Dropped（必须有 drop_reason）
```

`Blocked`、`Changed`、`Drifted`、`Stale` 是漂移或阻塞元状态，不是完成终态。它们必须回到 `Linked` 后重新验证，或转为带原因的 `Dropped`。

### 风险字段

```text
Risk Level: Low / Medium / High / Critical

Risk Type:
- Requirement Risk
- Technical Risk
- Security Risk
- Performance Risk
- Dependency Risk
- Data Risk
- Release Risk
```
