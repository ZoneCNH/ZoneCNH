# docs/constitution/ — FoundationX 宪法章节视图

> **权威来源**：[`CONSTITUTION.md`](../../CONSTITUTION.md)（项目根目录）。
> 本目录是宪法的**章节导航视图**，提供按条款快速跳转的便利。
> 如本目录文件与 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。

## 效力层级

```text
CONSTITUTION.md（根目录，向后兼容存根 + 权威引用点）
  ↓ 内容提取
docs/constitution/（章节视图，按条款快速导航）
```

## 结构概览

- **§0-§14**：约束模块实现质量（代码、接口、测试、命名、安全等）
- **§15-§19**：约束交付流程质量（管线、追溯、AI 辅助、完成层级、改进）
- **附录**：模块清单、文档关系、L2.5 收口边界

## 章节索引

| 文件 | 条款 | 核心内容 |
| ---- | ---- | -------- |
| [`preamble.md`](preamble.md) | 序言 | 宪法约束对象与适用范围 |
| [`00-branch-discipline.md`](00-branch-discipline.md) | 第零条：分支纪律 | 🔴 最高优先级 — 禁止 main 开发、强制 worktree、Agent 约束 |
| [`01-design-principles.md`](01-design-principles.md) | 第一条：设计原则 | 十三条不变量 P1-P13（基座 + 领域） |
| [`02-module-boundaries.md`](02-module-boundaries.md) | 第二条：模块边界 | 职责声明、边界违规、仲裁优先级、奥卡姆剃刀 |
| [`03-dependency-direction.md`](03-dependency-direction.md) | 第三条：依赖方向 | 依赖拓扑、单向下行规则、禁止依赖矩阵 |
| [`04-interface-contracts.md`](04-interface-contracts.md) | 第四条：接口契约 | 窄接口（≤7方法）、编译期检查、WHEN/THEN 行为规格 |
| [`05-testing-standards.md`](05-testing-standards.md) | 第五条：测试标准 | 覆盖率分级（L0=100%）、测试分类、三段式命名 |
| [`06-observability.md`](06-observability.md) | 第六条：可观测性 | Metrics 命名规范、Label Policy、Redaction |
| [`07-naming-conventions.md`](07-naming-conventions.md) | 第七条：命名规范 | Go 命名、模块命名模式、数据域跨层命名 |
| [`08-error-handling.md`](08-error-handling.md) | 第八条：错误处理 | 哨兵错误、%w 包装、错误消息格式 |
| [`09-security.md`](09-security.md) | 第九条：安全要求 | 密钥管理、输入校验、数据保护、依赖安全 |
| [`10-change-management.md`](10-change-management.md) | 第十条：变更管理 | PATCH/MINOR/MAJOR 分类、Breaking Change 流程 |
| [`11-code-review.md`](11-code-review.md) | 第十一条：代码审查 | 审查清单（9项）、严重性级别、AI 代理审查规则 |
| [`12-amendment-procedure.md`](12-amendment-procedure.md) | 第十二条：修正程序 | 修正条件、流程、修正历史记录 |
| [`13-supreme-clause.md`](13-supreme-clause.md) | 第十三条：最高条款 | 效力层级、适用范围（§1-§14 + §15-§19）、解释权 |
| [`14-anti-goodhart.md`](14-anti-goodhart.md) | 第十四条：管线自改约束 | 受保护文件清单、RSI 合法形式（fork/AB/outer/批准） |
| [`15-delivery-pipeline.md`](15-delivery-pipeline.md) | 第十五条：交付管线 | 管线七律 D1-D7、变更传播链 |
| [`16-traceability-gates.md`](16-traceability-gates.md) | 第十六条：追溯与门禁 | 制品 ID 前缀体系、覆盖要求、孤儿检测 |
| [`17-ai-assisted-delivery.md`](17-ai-assisted-delivery.md) | 第十七条：AI 辅助交付 | Prompt 质量标准、代码边界、输出验证 |
| [`18-artifact-completion.md`](18-artifact-completion.md) | 第十八条：制品完成层级 | 四级 Done L1-L4（Code/Test/Release/Goal） |
| [`19-cri.md`](19-cri.md) | 第十九条：受控递归改进 | CRI 七原则 R1-R7、改进边界、风险分级审批 |
| [`appendix.md`](appendix.md) | 附录 A / B / L2.5 | 模块清单（基座+L2.5）、与 CLAUDE.md 关系、L2.5 收口边界 |

## 修改规则

- 修改宪法条款必须先更新根目录 `CONSTITUTION.md`，再同步本目录对应文件
- `CONSTITUTION.md` 是 §14.1 受保护文件，修改须遵循第十二条修正程序
- 本目录文件不是权威来源，不得以本目录文件为依据覆盖 `CONSTITUTION.md`
