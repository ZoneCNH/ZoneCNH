# Claude Code Agents

FoundationX 文档仓库的 Claude Code 代理配置。Claude Code 在三平台评分体系中作为其中一个 scorer 平台。

## 执行类代理

| Agent | 模型 | 职责 |
|-------|------|------|
| spec | Opus | 编写或修订模块 Spec |
| spec-review | Opus | 对抗性审查 spec，作为结构评分证据与参考 |
| matrix | Sonnet | 生成或校验需求追溯矩阵 |
| task-split | Sonnet | 将 Approved Spec 拆分为可执行的 Task |
| task-planner | Opus | 为单个 TASK 生成分步实现计划 |
| prompt-builder | Sonnet | 为单个 Task 生成 Context Packet |
| task-executor | Sonnet | 按 Task spec 编写代码 |

## 评分类代理（Claude 平台）

| Agent | 阶段 | Rubric |
|-------|------|--------|
| spec-structural-score | Spec | `specs/scoring/RUBRIC-spec.md` |
| matrix-structural-score | Matrix | `specs/scoring/RUBRIC-matrix.md` |
| tasks-structural-score | Tasks | `specs/scoring/RUBRIC-tasks.md` |
| plan-structural-score | Plan | `specs/scoring/RUBRIC-plan.md` |
| prompt-structural-score | Prompt | `specs/scoring/RUBRIC-prompt.md` |
| code-structural-score | Code | `specs/scoring/RUBRIC-code.md` |

## 仲裁类代理

| Agent | 用途 |
|-------|------|
| pipeline-arbiter | 汇总三平台评分，按 `specs/scoring/ARBITER-PROTOCOL.md` 输出 gate 判定 |
| meta-arbiter | 读 `.omc/state/outer-metrics/`，按宪法 §14.4 诊断 Goodhart 信号、输出 RSI 建议（不修改任何受保护文件） |

## 使用方式

```text
/agent spec
/agent spec-structural-score
/agent pipeline-arbiter
```

## 端到端工作流入口

```text
/project:spec-code-pipeline {module}
/project:spec-code-pipeline {module} --from matrix
/project:spec-code-pipeline {module} --stage prompt
```

## 管线流程

每个阶段都由 **agent team** 执行：

```text
executor → [claude scorer | codex scorer | copilot scorer]（并行）
        → pipeline-arbiter（composite_score = min(三平台评分)；composite_score >= 98 且无红线、无低置信度、分差在阈值内）
        → 通过则进入下一阶段；失败则路由回 executor 修复
```

详见 `specs/STRUCTURAL-SCORING.md` 与 `specs/scoring/ARBITER-PROTOCOL.md`。

## 目录结构

```text
.claude/
├── agents/          # 代理配置（Markdown 文件，含 scorer 与 arbiter）
├── commands/        # 自定义命令（release.md、spec-code-pipeline.md）
├── settings.local.json  # 本地设置（已 gitignore）
└── AGENTS.md        # 本文件
```
