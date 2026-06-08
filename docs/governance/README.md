# Spec 治理文档

`docs/governance/` 是模块规格与 Spec -> Code 管线的全局治理文档目录，不是可交付模块目录；这里承载模板、生命周期、追溯规则、评分协议和发布检查。`module/` 保留具体模块的规格、矩阵、任务和实现计划。

## 核心文档

| 文档 | 用途 |
|------|------|
| [DEVELOPMENT-WORKFLOW.md](DEVELOPMENT-WORKFLOW.md) | Spec -> Code 管线总流程 |
| [PRE-DEVELOPMENT.md](PRE-DEVELOPMENT.md) | 开发前置检查 |
| [LIFECYCLE.md](LIFECYCLE.md) | Spec 状态流转与版本规则 |
| [TRACEABILITY.md](TRACEABILITY.md) | 需求追溯矩阵规范 |
| [DEFINITION-OF-READY.md](DEFINITION-OF-READY.md) | 进入开发的前置条件 |
| [DEFINITION-OF-DONE.md](DEFINITION-OF-DONE.md) | 完成验收条件 |
| [CODING-SESSION-PROTOCOL.md](CODING-SESSION-PROTOCOL.md) | 编码会话协议 |
| [SPEC-DRIFT-PROTOCOL.md](SPEC-DRIFT-PROTOCOL.md) | Spec 漂移处理协议 |

## 模板

| 模板 | 用途 |
|------|------|
| [SPEC-TEMPLATE.md](SPEC-TEMPLATE.md) | 模块 Spec 模板 |
| [TASK-TEMPLATE.md](TASK-TEMPLATE.md) | Task Spec 模板 |
| [AGENT-SPEC-TEMPLATE.md](AGENT-SPEC-TEMPLATE.md) | Agent Spec 模板 |
| [ANALYSIS-TEMPLATE.md](ANALYSIS-TEMPLATE.md) | 分析报告模板 |
| [PR-TEMPLATE.md](PR-TEMPLATE.md) | PR 描述模板 |

## 质量与评分

| 文档 | 用途 |
|------|------|
| [STRUCTURAL-SCORING.md](STRUCTURAL-SCORING.md) | 四源结构评分方法与门禁 |
| [scoring/README.md](scoring/README.md) | Rubric 与仲裁协议索引 |
| [TESTING-STRATEGY.md](TESTING-STRATEGY.md) | 测试策略 |
| [REVIEW-STRATEGY.md](REVIEW-STRATEGY.md) | 审查策略 |
| [DEPLOYMENT.md](DEPLOYMENT.md) | 发布与部署规则 |
| [anti-requirements.md](anti-requirements.md) | 反需求与范围约束 |

## 路径边界

- 治理规则、模板、rubric 和门禁协议放在 `docs/governance/`。
- 模块级产物放在 `module/{module}/`。
- 跨平台 agent、CI 和 CODEOWNERS 应引用 `docs/governance/...`，不得恢复到治理文件位于 `module/` 下的旧布局。
