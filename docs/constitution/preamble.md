> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [↑ 目录](README.md) · [下一节 →](00-branch-discipline.md)

---

## 序言

FoundationX 由基座层（19 个模块）、L2.5 领域共享层（5 个模块）以及四个业务域组成：数据域 · Data、分析域 · Analytics、决策域 · Decision、执行域 · Execution（域定义见 §2.7）。模块间通信统一使用 HTTP 协议和 Gin 框架（§4.5）。本宪法规定模块实现和交付管线必须遵守的不变量，确保系统在演进过程中保持一致性、可追溯性和可维护性。

本宪法的约束对象：

- 所有基座模块和领域模块的源码实现
- 全系统的交付管线（Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective；Matrix 为横切追溯制品）
- 所有 `module/*/spec/SPEC.md` 规格文档
- 所有 AI 代理的代码生成、审查和重构行为
- 所有人类贡献者的 PR 和代码审查

---
