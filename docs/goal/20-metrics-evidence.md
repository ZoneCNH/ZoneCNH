# 指标与证据闭环

Goal 工作流的核心判断不是“代码是否完成”，而是“目标是否被证据证明达成”。因此必须把测试证据、评审证据、发布证据和运行指标串成闭环。

## 基本原则

| 原则 | 含义 |
|------|------|
| No Evidence, No Done | 没有证据的完成状态只能算声明，不能算交付。 |
| No Metric, No Success | 没有成功指标的 Goal 不能在发布后判断是否达成。 |
| Code Done != Goal Achieved | 代码合并只证明实现进入仓库，不证明用户结果发生。 |
| Evidence Must Be Reproducible | 证据必须能定位来源、时间、命令、环境和版本。 |
| Metrics Must Keep Original Intent | 发布后不能为了好看而重写成功指标。 |

## 证据类型

| 类型 | 证明对象 | 最低字段 |
|------|----------|----------|
| Test Report | 验收标准和回归风险 | 命令、环境、结果、失败摘要、关联 AC |
| Review Finding | 设计、代码、风险和缺陷 | reviewer、发现、严重级别、处理状态 |
| Release Manifest | 发布内容和版本边界 | release id、commit、artifact、rollback plan |
| Metrics Snapshot | 目标达成情况 | 指标名、数据源、时间窗口、观测值、预期值 |
| Incident/Postmortem | 发布后偏差和事故 | 影响、根因、修复、预防动作 |
| Retrospective/Patch | 工作流改进 | 问题、证据、改进项、适用范围、验证方式 |

证据可以来自自动化测试、日志、监控、人工评审或用户反馈，但必须进入统一记录，不能散落在聊天上下文里。

## Metrics Review 模板

```yaml
metrics_review_id:
goal_id:
release_id:
measurement_window:
data_source:
expected_metrics:
  - metric:
    target:
    owner:
observed_metrics:
  - metric:
    value:
    source:
    captured_at:
conclusion: achieved | partially_achieved | not_achieved | invalid_metric
analysis:
follow_up:
  - type: new_goal | task | bug | workflow_improvement | none
    owner:
    due:
```

Metrics Review 应在发布后约定窗口内完成。窗口过短会误判，窗口过长会丢失反馈速度。

## Metrics Validation Gate

| 状态 | 含义 | 下一步 |
|------|------|--------|
| Pending | 数据窗口未到或数据源未就绪 | 等待或修复观测能力 |
| Validated | 指标达到目标 | 关闭 Goal，沉淀经验 |
| Partially Achieved | 部分指标达标 | 写 Gap Report，拆 follow-up |
| Not Achieved | 核心指标未达标 | RCA、回退或新一轮 Goal |
| Invalid Metric | 指标无法代表原目标 | 发起指标修正 CR，不能直接宣称成功 |

Gate 的结论必须写回 Goal 或 Release 记录，避免“PR 已合并”掩盖“目标未达成”。

## Metrics Gap Report

当指标未达成时，保留原 Goal 和原成功标准，新增 Gap Report：

```yaml
gap_report_id:
goal_id:
release_id:
expected:
observed:
gap:
severity: low | medium | high | critical
root_cause:
  product:
  engineering:
  data:
  workflow:
decision: rollback | hotfix | follow_up_goal | accept_risk | revise_metric_with_cr
actions:
  - id:
    owner:
    due:
    evidence_required:
```

不得通过降低目标值、删除失败指标或改变口径来关闭 Gap。指标口径确实错误时，必须通过 CR 记录变更原因，并说明新旧指标如何映射。

## Observability Contract

每个需要发布后验证的 Goal 应定义观测契约：

| 字段 | 说明 |
|------|------|
| Metric | 指标名称和业务含义 |
| Source | 数据源、表、日志、监控面板或查询 |
| Window | 观测窗口和采样频率 |
| Baseline | 改动前基线 |
| Target | 目标值和容忍区间 |
| Segment | 用户、市场、环境或版本分组 |
| Owner | 负责读取和解释指标的人 |
| Failure Action | 未达标时的默认动作 |

没有观测契约的指标不应作为发布成功依据。

## Evidence Graph

Evidence Graph 用图结构记录“为什么可以相信这次交付”：

| 节点 | 示例 |
|------|------|
| Goal | 目标、边界、成功指标 |
| Spec | 需求、AC、NFR、风险 |
| Matrix | FR/BR/AC/Task/Test/Evidence 映射 |
| Task | 具体实现单元 |
| Code Change | commit、PR、文件范围 |
| Test Evidence | 测试报告、截图、日志 |
| Review Evidence | 评审意见、批准记录 |
| Release | artifact、版本、部署记录 |
| Metric | 运行指标、业务结果 |
| Improvement | 后续工作流或产品改进 |

关键边包括 `implements`、`verifies`、`blocks`、`releases`、`measures`、`improves`。每条边应保留来源、时间和版本快照。

## 学习闭环

| 层级 | 问题 | 输出 |
|------|------|------|
| Single-loop | 实现是否有缺陷？ | bugfix、测试补充、回归证据 |
| Double-loop | 工作流为什么没提前发现？ | 模板、Gate、Prompt、Review 规则补丁 |
| Triple-loop | 改进机制本身是否有效？ | Scorecard、评估集、改进机制调整 |

没有 Metrics Review 的交付只能完成 Single-loop。要让系统变强，必须把指标偏差和评审发现反馈到工作流改进里。
