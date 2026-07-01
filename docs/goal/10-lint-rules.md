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
M-LINT-002: 每个 Spec Requirement 至少对应一个 Matrix edge
M-LINT-003: 每个 release-critical Matrix edge 必须连接到 Task、Test 或明确的非实现决策
M-LINT-004: 每个 P0/P1 Matrix edge 必须有 Test edge 与 Evidence edge
M-LINT-005: 每个 Task 必须能追溯到 Matrix edge
M-LINT-006: 不允许存在 Orphan Task
M-LINT-007: 不允许存在 Orphan Code
M-LINT-008: Done 状态必须同时满足 Code + Test + Evidence + Gate（四链路）
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

### Prompt 质量标准映射

| 质量标准               | 覆盖规则                                       |
| ---------------------- | ---------------------------------------------- |
| 不依赖猜测             | P-LINT-001、P-LINT-002、P-LINT-003、P-LINT-006 |
| 不缺上下文             | P-LINT-001、P-LINT-003、P-LINT-004、P-LINT-007 |
| 不省略约束             | P-LINT-003、P-LINT-004、P-LINT-005、P-LINT-007 |
| 不混合多个目标         | P-LINT-002、P-LINT-009                         |
| 不产生无法验证的输出   | P-LINT-006、P-LINT-007                         |
| 不允许 AI 自行扩大范围 | P-LINT-008、P-LINT-010                         |

---

## 5. Code Lint

PR 描述中必须包含来源信息：

```text
C-LINT-001: PR 必须引用至少一个 Task
C-LINT-002: PR 必须引用至少一个 Matrix edge
C-LINT-003: PR 必须包含测试说明
C-LINT-004: P0/P1 Task 不允许无测试合并
C-LINT-005: PR 不能包含未关联 Task 的大规模代码改动
C-LINT-006: 模块代码实现必须位于 /home/workspace/{module} 对应仓库
C-LINT-007: 本仓库 module/{module}/ 下不得新增实现源码树或复制出的模块代码；只读分析快照必须在规则 allowlist 内
```

---

## 6. Lint 执行建议

| 层级        | 检查时机                          | 自动化程度               |
| ----------- | --------------------------------- | ------------------------ |
| Goal Lint   | G1 Goal Gate 前                   | 可半自动（关键词扫描）   |
| Spec Lint   | G2 Spec Gate 前                   | 可半自动（结构检查）     |
| Matrix Lint | G5 Task Gate 前的 Matrix 覆盖检查 | 可全自动（覆盖关系检查） |
| Prompt Lint | Prompt 生成后                     | 可全自动（字段完整性）   |
| Code Lint   | PR 提交时                         | 可全自动（CI 集成）      |

## 7. 规则实现状态

| 规则 ID    | 状态           | 检查工具                       | 说明                                                                  |
| ---------- | -------------- | ------------------------------ | --------------------------------------------------------------------- |
| G-LINT-001 | implemented    | lint-goal.sh                   | Goal 必须包含 objective                                               |
| G-LINT-002 | implemented    | lint-goal.sh                   | Goal 必须包含 success_metrics 或 acceptance_criteria                  |
| G-LINT-003 | semi-automated | lint-goal.sh                   | Goal 不能只描述实现方案（grep 实现词 + [需人工确认]）                 |
| G-LINT-004 | implemented    | lint-goal.sh                   | Goal 必须包含 scope_out                                               |
| G-LINT-005 | semi-automated | lint-goal.sh                   | Goal 必须包含 target_user 或 target_actor（grep 检测 + [需人工确认]） |
| G-LINT-006 | implemented    | lint-goal.sh                   | Goal 必须至少有一个可验证指标                                         |
| G-LINT-007 | semi-automated | lint-goal.sh                   | Goal 不应使用模糊词而没有定义（grep 弱程度词 + [需人工确认]）         |
| S-LINT-001 | implemented    | lint-goal.sh                   | 每条 Functional Requirement 必须有唯一 ID                             |
| S-LINT-002 | implemented    | lint-goal.sh                   | 每条 Requirement 必须能被测试                                         |
| S-LINT-003 | implemented    | lint-goal.sh                   | 每条 Acceptance Criteria 必须有明确结果                               |
| S-LINT-004 | semi-automated | lint-goal.sh                   | 权限相关功能需 Security Requirements（grep 检测，输出 [需人工确认]）  |
| S-LINT-005 | semi-automated | lint-goal.sh                   | 数据导入/导出需数据量限制（grep 检测，输出 [需人工确认]）             |
| S-LINT-006 | semi-automated | lint-goal.sh                   | 异步任务需状态流转规则（grep 检测，输出 [需人工确认]）                |
| S-LINT-007 | semi-automated | lint-goal.sh                   | 用户可见错误需 Error Handling（grep 检测，输出 [需人工确认]）         |
| S-LINT-008 | semi-automated | lint-goal.sh                   | 涉及外部服务需失败处理（grep 检测，输出 [需人工确认]）                |
| M-LINT-001 | implemented    | matrix-gen.py                  | 每个 Goal 至少对应一个 Spec                                           |
| M-LINT-002 | implemented    | matrix-gen.py                  | 每个 Spec Requirement 至少对应一个 Matrix edge                        |
| M-LINT-003 | implemented    | gate-check.sh                  | release-critical edge 必须连接到 Task/Test                            |
| M-LINT-004 | implemented    | gate-check.sh                  | P0/P1 edge 必须有 Test edge + Evidence edge                           |
| M-LINT-005 | implemented    | matrix-gen.py                  | 每个 Task 必须能追溯到 Matrix edge                                    |
| M-LINT-006 | implemented    | matrix-gen.py                  | 不允许存在 Orphan Task                                                |
| M-LINT-007 | implemented    | goal-validate.py               | 不允许存在 Orphan Code                                                |
| M-LINT-008 | implemented    | goal-validate.py               | Done 状态必须同时满足 Code + Test + Evidence + Gate（四链路）         |
| P-LINT-001 | implemented    | lint-goal.sh                   | Prompt 必须包含 Source                                                |
| P-LINT-002 | implemented    | lint-goal.sh                   | Prompt 必须包含 Task Objective                                        |
| P-LINT-003 | implemented    | lint-goal.sh                   | Prompt 必须包含 Requirements                                          |
| P-LINT-004 | implemented    | lint-goal.sh                   | Prompt 必须包含 Constraints                                           |
| P-LINT-005 | implemented    | lint-goal.sh                   | Prompt 必须包含 Output                                                |
| P-LINT-006 | implemented    | lint-goal.sh                   | Prompt 必须包含 Acceptance Criteria                                   |
| P-LINT-007 | implemented    | lint-goal.sh                   | Prompt 必须包含 Test Requirements                                     |
| P-LINT-008 | implemented    | lint-goal.sh                   | Prompt 必须包含 Do Not                                                |
| P-LINT-009 | implemented    | lint-goal.sh                   | Prompt 不能要求一次性实现多个无关任务                                 |
| P-LINT-010 | implemented    | lint-goal.sh                   | Prompt 不能允许自行扩大范围                                           |
| C-LINT-001 | implemented    | lint-goal.sh, goal-validate.py | PR 必须引用至少一个 Task                                              |
| C-LINT-002 | implemented    | lint-goal.sh, goal-validate.py | PR 必须引用至少一个 Matrix edge                                       |
| C-LINT-003 | semi-automated | lint-goal.sh                   | PR 必须包含测试说明（grep test/测试 + [需人工确认]）                  |
| C-LINT-004 | semi-automated | lint-goal.sh                   | P0/P1 Task 不允许无测试合并（grep P0/P1 + test + [需人工确认]）       |
| C-LINT-005 | implemented    | goal-validate.py               | PR 不能包含未关联 Task 的大规模代码改动                               |
| C-LINT-006 | implemented    | rule-drift-check.py            | 模块代码实现必须位于 /home/workspace/{module}                                   |
| C-LINT-007 | implemented    | rule-drift-check.py            | module/{module}/ 下不得新增实现源码树                                 |

### 规则覆盖率

- 总规则数: 40
- implemented: 30 (75%)
- semi-automated: 10 (25%) — S-LINT-004~008, G-LINT-003/005/007, C-LINT-003/004，grep 检测 + [需人工确认] 标记
- manual: 0 (0%)
- planned: 0 (0%)

> 自动化率：30/40 全自动 + 10/40 半自动 = 40/40 (100%)。所有规则均有机器检查，manual 规则已全部消除。

Schema 引用：
- Goal 字段完整性校验见 [schema/goal.schema.yaml](schema/goal.schema.yaml)
- Matrix 字段完整性校验见 [schema/matrix.schema.yaml](schema/matrix.schema.yaml)
- Evidence 字段完整性校验见 [schema/evidence.schema.yaml](schema/evidence.schema.yaml)
- 状态枚举校验见 [schema/state-dictionary.yaml](schema/state-dictionary.yaml)
