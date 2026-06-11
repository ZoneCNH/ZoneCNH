# 18. 成熟度模型

> 本文档从原 `17-maturity-and-improvement.md` 拆分而来，聚焦于成熟度升级路径、体系度量、故障排查和非代码场景适配。Self-improving 复利机制已拆分至 [19-self-improving.md#self-improving-机制](19-self-improving.md#1-self-improving-机制)。

---

## 1. 成熟度模型

### 级别定义

| 级别 | 名称 | 特征 | 核心能力 |
|------|------|------|----------|
| L0 | 无序 | 代码直接写，没有 Goal | 能交付，但不知道交付了什么 |
| L1 | 有目标 | 有 Goal，但没有 Spec 和 Matrix | 知道为什么做，但容易遗漏需求 |
| L2 | 有追溯 | 有 Goal + Spec + Matrix | 需求能追溯到代码和测试 |
| L3 | 有门禁 | 有 Gate 系统，自动检查质量 | 质量有保障，但依赖人工执行 |
| L4 | 有复利 | 有 Retrospective + Patch 闭环 | 每次执行让体系变得更好 |
| L5 | 自治 | Agent 自动执行，人类只做审批 | 大部分流程自动化 |

### 各级要求

#### L0 → L1：建立目标意识

```text
投入：1 天
产出：每个任务有 Goal

必须做到：
- 每个任务先写 Goal 再动手
- Goal 包含：背景、目标、成功标准、截止时间
- 不允许"直接开写"

验证标准：
- 100% 的任务有 Goal
- Goal 有可衡量的成功标准
```

#### L1 → L2：建立追溯链

```text
投入：1 周
产出：需求能追溯到代码

必须做到：
- 每个 Goal 有 Spec
- 建 Traceability Matrix
- 每个 Task 映射到 Requirement
- 每个 Test 映射到 Acceptance Criteria

验证标准：
- 追溯覆盖率 ≥ 90%
- 无孤立 Task（Task 必须映射到 Requirement）
- 无孤立 Code（Code 必须映射到 Task）
```

#### L2 → L3：建立质量门禁

```text
投入：2 周
产出：Gate 系统自动检查

必须做到：
- 建立 G0-G5 至少 6 个 Gate
- 至少 3 个 Gate 是 Executable（可自动执行）
- Gate 结果记录在 Evidence 中
- 失败的 Gate 阻止流程推进

验证标准：
- Gate 通过率数据可查
- 0 个 Gate FAIL 被跳过
- CI 中集成至少 3 个自动 Gate
```

#### L3 → L4：建立复利机制

```text
投入：1 个月
产出：每次执行改进体系

必须做到：
- 每个 Goal 完成后做 Retrospective
- Retrospective 产出至少一个 Patch（Prompt / Harness / Rule）
- Patch 有验证和回滚机制
- Registry 保存长期状态

验证标准：
- 100% 的 Goal 有 Retrospective
- 至少 50% 的 Retrospective 产出可执行的 Patch
- Patch 被验证有效后合并到体系中
```

#### L4 → L5：实现自治

```text
投入：持续
产出：Agent 自动执行大部分流程

必须做到：
- Agent 能自动完成 Context Recovery → Task → Evidence → Review
- 人类只在 Human Approval Check 做决策，结论回填为 G9 Review Gate 或 G10 Release Gate 证据
- Agent 能自动触发 AutoResearch
- Agent 能自动检测异常状态并降级

验证标准：
- 70%+ 的 Task 由 Agent 自动完成
- 人类介入率 < 30%
- Agent 输出质量不低于人工
```

### 升级路径

```text
L0 ──1天──→ L1 ──1周──→ L2 ──2周──→ L3 ──1月──→ L4 ──持续──→ L5
```

**不要跳级。** 每一级的能力是下一级的基础。没有 L2 的追溯链，L3 的 Gate 没有检查对象。没有 L3 的 Gate，L4 的 Retrospective 没有质量数据。

---

## 2. 体系度量

### 效率指标

| 指标 | 说明 | 目标 |
|------|------|------|
| Goal → Done 周期 | 从 Goal 定义到交付的时间 | 趋势下降 |
| Prompt Success Rate | 一次 Prompt 生成后通过测试的比例 | ≥ 70% |
| Gate First-Pass Rate | Gate 一次通过的比例 | ≥ 80% |
| Rework Rate | 因需求不清导致返工的比例 | ≤ 10% |

### 质量指标

> 质量指标表见 [08-quality-gates.md §5](08-quality-gates.md#5-质量指标)。

### 复利指标

| 指标 | 说明 | 目标 |
|------|------|------|
| Retro Completion Rate | 有 Retrospective 的 Goal 占比 | 100% |
| Patch Generation Rate | 产出 Patch 的 Retro 占比 | ≥ 50% |
| Patch Effectiveness | Patch 被验证有效的比例 | ≥ 70% |
| Process Improvement Trend | 门禁通过率的趋势 | 持续上升 |

### 下游采纳指标

> 本体系服务于 ~70 个 ZoneCNH 独立仓库。以下指标用于量化下游仓库的实际采纳程度。

| 指标 | 说明 | 目标 |
|------|------|------|
| `.config/goal/` 初始化率 | 已初始化 Goal 配置中心的仓库占比 | ≥ 30%（短期）/ ≥ 70%（长期） |
| Gate 通过率 | 下游仓库 CI 中 Gate 检查通过的比例 | ≥ 80% |
| Goal 制品覆盖率 | 有至少一个 Goal 定义的仓库占比 | ≥ 50% |
| Matrix 覆盖率 | 有 Matrix 且覆盖率 ≥ 95% 的仓库占比 | ≥ 30% |
| Evidence Bundle 完整率 | Release 时有完整 Evidence Bundle 的仓库占比 | ≥ 20% |
| 工具链同步率 | 核心脚本版本与主仓库一致的仓库占比 | ≥ 60% |

**采集方式**：通过 `deploy/README.md` 中定义的 3 级采纳指南（Lint Only / Standard / Full），在各仓库 CI 中上报采纳级别和 Gate 结果到统一 Scorecard 面板（Phase 5）。

---

## 3. 故障排查指南

### 3.1 Spec 不完整

**症状**：开发过程中频繁发现遗漏需求，Matrix 有缺口。

**根因**：
- Spec 编写时没有走查边界条件
- Acceptance Criteria 不够具体
- 非目标没有明确定义

**修复**：
```text
1. 用 02-goal-standard.md 的评分表自检 Spec
2. 补充边界条件和异常场景
3. 用"如果...会怎样？"走查每个 Requirement
4. 更新 Matrix
```

### 3.2 Gate 反复失败

**症状**：同一个 Gate 失败多次，流程卡住。

**根因**：
- Gate 标准不清晰
- 实现偏离了 Spec
- Gate 本身有 bug

**修复**：
```text
1. 检查 Gate 的 pass_criteria 是否明确
2. 对比实现和 Spec 的差异
3. 如果 Gate 标准有误，走 Harness Patch 修正
4. 如果实现有误，回到 EXECUTING 修复
5. 如果反复失败 3 次，进入 NEEDS_REPLAN
```

### 3.3 Evidence 不充分

**症状**：Review 时发现 Evidence 缺少关键字段。

**根因**：
- 没有使用标准 Evidence 模板
- 执行时没有记录过程
- 对"Evidence 必须包含什么"理解不一致

**修复**：
```text
1. 使用 13-runtime-engine.md 的 Evidence 标准格式
2. 执行过程中实时记录，不要事后补
3. 在 G8 Evidence Gate 设置自动检查
```

### 3.4 Matrix 有缺口

**症状**：Release 前发现有些 Requirement 没有对应的 Task 或 Test。

**根因**：
- 建 Matrix 时遗漏了 Requirement
- 新增 Requirement 后没有更新 Matrix
- Task 拆分时没有回溯 Matrix

**修复**：
```text
1. Release 前强制跑 Matrix 完整性检查
2. 新增 Requirement 时同步更新 Matrix（变更传播规则）
3. Task 完成后回填 Matrix 状态
```

### 3.5 Scope Creep

**症状**：Task 实际产出超出定义范围，混入了无关功能。

**根因**：
- Task 的 Scope 没有明确定义
- 执行时"顺手"做了其他事
- Code Boundary 没有约束

**修复**：
```text
1. Task 必须有明确的 Scope 和 Code Boundary
2. Prompt 中写 Do Not 列表
3. Review 时检查"是否有超出 Task 范围的代码"
4. 发现 Scope Creep → 拆成新 Task
```

### 3.6 状态卡在 BLOCKED

**症状**：流程长时间停在 BLOCKED 状态。

**根因**：
- 依赖未解决
- 权限不足
- 外部系统不可用

**修复**：
```text
1. 输出 Blocker 清单
2. 评估 Blocker 是否可以绕过
3. 如果 Blocker 超过 2 天，进入 NEEDS_REPLAN
4. 考虑拆分任务，先做不被阻塞的部分
```

### 3.7 Agent 输出质量低

**症状**：AI Agent 生成的代码不符合预期。

**根因**：
- Context Package 不完整
- Prompt 缺少约束
- Code Boundary 不明确

**修复**：
```text
1. 检查 Context Package 是否包含所有 10 个要素
2. 检查 Prompt 的 Do Not 列表
3. 检查 Code Boundary 是否明确
4. 用 Review Prompt 做二次检查
5. 如果仍然不行，拆分 Task 降低单次复杂度
```

---

## 4. 非代码场景适配

### 数据分析场景

```text
Goal: 分析用户留存率下降原因
Spec: 定义分析维度、数据源、输出格式
Matrix: 每个分析维度映射到数据查询和可视化
Tasks: 数据提取 → 清洗 → 分析 → 可视化 → 报告
Evidence: 查询 SQL、分析结果、可视化截图
```

### 运维操作场景

```text
Goal: 数据库主从切换零停机
Spec: 切换步骤、验证命令、回滚条件
Matrix: 每个步骤映射到验证命令
Tasks: 预检查 → 切换 → 验证 → 流量切换 → 最终验证
Evidence: 执行日志、延迟数据、流量数据
```

### 文档编写场景

```text
Goal: API 文档覆盖率从 60% 提升到 90%
Spec: 文档标准、覆盖范围、质量要求
Matrix: 每个 API 映射到文档条目
Tasks: 盘点 API → 编写文档 → 审查 → 发布
Evidence: 文档覆盖率数据、审查记录
```
