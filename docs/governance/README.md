# Spec 治理文档

> **定位声明**（2026-07-03 P2.3）：Goal→Retro（G0-G11）是唯一管线，SSOT 在 `docs/goal/`。`docs/governance/` 是 Spec→Code 快速通道（S1-S6 ≈ G2-G6）的实现投影：模板、CI 门禁、评分执行和实操指南。标注 `[投影]` 的文档已声明 canonical SSOT 引用。

`docs/governance/` 是 Spec→Code 快速通道的全局治理文档目录，不是可交付模块目录；这里承载模板、生命周期、追溯规则、评分协议和发布检查。`module/` 保留具体模块的规格、矩阵、任务和实现计划。

## 核心文档

| 文档                                                             | 用途                                         | SSOT 引用 |
| ---------------------------------------------------------------- | -------------------------------------------- | --------- |
| [DEVELOPMENT-WORKFLOW.md](DEVELOPMENT-WORKFLOW.md)               | Spec→Code 快速通道实操指南                   | `docs/goal/03-pipeline.md` |
| [PRE-DEVELOPMENT.md](PRE-DEVELOPMENT.md) `[投影]`                | 开发前置检查                                 | `docs/goal/06-dod.md` |
| [LIFECYCLE.md](LIFECYCLE.md) `[投影]`                            | Spec 状态流转与版本规则                      | `docs/goal/05-layer-standards.md §1` |
| [TRACEABILITY.md](TRACEABILITY.md) `[投影]`                      | 需求追溯矩阵展示视图规范                     | `docs/goal/05-layer-standards.md §9` |
| [DEFINITION-OF-READY.md](DEFINITION-OF-READY.md) `[投影]`        | 进入开发的前置条件                           | `docs/goal/06-dod.md §2` |
| [DEFINITION-OF-DONE.md](DEFINITION-OF-DONE.md) `[投影]`          | 完成验收条件                                 | `docs/goal/06-dod.md §8` |
| [CODING-SESSION-PROTOCOL.md](CODING-SESSION-PROTOCOL.md)         | 编码会话协议                                 | — |
| [SPEC-DRIFT-PROTOCOL.md](SPEC-DRIFT-PROTOCOL.md)                 | Spec 漂移处理协议                            | — |
| [AUTOMATED-DELIVERY-WORKFLOW.md](AUTOMATED-DELIVERY-WORKFLOW.md) | 任务完成后的自动提交、合并、同步与清理工作流 | — |

## 模板

| 模板                                             | 用途            | SSOT 引用 |
| ------------------------------------------------ | --------------- | --------- |
| [SPEC-TEMPLATE.md](SPEC-TEMPLATE.md) `[投影]`    | 模块 Spec 模板  | `docs/goal/09-templates.md` + `05-layer-standards.md §1` |
| [TASK-TEMPLATE.md](TASK-TEMPLATE.md) `[投影]`    | Task Spec 模板  | `docs/goal/09-templates.md §5` + `05-layer-standards.md §4` |
| [AGENT-SPEC-TEMPLATE.md](AGENT-SPEC-TEMPLATE.md) | Agent Spec 模板 | — |
| [ANALYSIS-TEMPLATE.md](ANALYSIS-TEMPLATE.md)     | 分析报告模板    | — |
| [PR-TEMPLATE.md](PR-TEMPLATE.md)                 | PR 描述模板     | — |

## 质量与评分

| 文档                                           | 用途                   | SSOT 引用 |
| ---------------------------------------------- | ---------------------- | --------- |
| [STRUCTURAL-SCORING.md](STRUCTURAL-SCORING.md) | 四源结构评分方法与门禁 | `docs/goal/08-quality-gates.md` |
| [scoring/README.md](scoring/README.md)         | Rubric 与仲裁协议索引  | — |
| [TESTING-STRATEGY.md](TESTING-STRATEGY.md)     | 测试策略               | — |
| [REVIEW-STRATEGY.md](REVIEW-STRATEGY.md)       | 审查策略               | — |
| [DEPLOYMENT.md](DEPLOYMENT.md)                 | 发布与部署规则         | — |
| [BOM-FREEZE-GOVERNANCE.md](BOM-FREEZE-GOVERNANCE.md) | BOM 与 freeze 声明边界 | — |
| [anti-requirements.md](anti-requirements.md)   | 反需求与范围约束       | — |

## 模块治理

| 文档 | 用途 |
| --- | --- |
| [MODULE-GOVERNANCE.md](MODULE-GOVERNANCE.md) | 模块治理总纲 — 八域总览、三 SSOT 边界、效力层级 |
| [module-governance/README.md](module-governance/README.md) | 模块治理八专题 + 模板索引 |
| [module-governance/01-module-registry.md](module-governance/01-module-registry.md) | 模块统一注册表 schema 与登记规则 |
| [module-governance/02-module-lifecycle.md](module-governance/02-module-lifecycle.md) | 模块生命周期五态状态机 |
| [module-governance/03-module-ownership.md](module-governance/03-module-ownership.md) | 模块负责人机制 |
| [module-governance/04-module-release-ledger.md](module-governance/04-module-release-ledger.md) | 模块发布账本 |
| [module-governance/05-module-health.md](module-governance/05-module-health.md) | 模块健康度四维模型 |
| [module-governance/06-module-onboarding.md](module-governance/06-module-onboarding.md) | 新模块准入流程 |
| [module-governance/07-module-decommission.md](module-governance/07-module-decommission.md) | 模块退役/迁移流程 |
| [module-governance/08-business-domain-deps.md](module-governance/08-business-domain-deps.md) | 业务域依赖矩阵扩展规划 |
| [`module/registry.yaml`](../module/registry.yaml) | 统一模块注册表（机器可读 SSOT） |

## 路径边界

- 治理规则、模板、rubric 和门禁协议放在 `docs/governance/`。
- 模块治理总纲与专题放在 `docs/governance/module-governance/`；机器可读注册表放在 `module/registry.yaml`。
- 模块级产物放在 `module/{module}/`。
- 跨平台 agent、CI 和 CODEOWNERS 应引用 `docs/governance/...`，不得恢复到治理文件位于 `module/` 下的旧布局。
