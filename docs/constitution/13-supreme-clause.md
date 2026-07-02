> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](12-amendment-procedure.md) · [↑ 目录](README.md) · [下一节 →](14-anti-goodhart.md)

---

## 第十三条：最高条款

### 13.1 效力层级

当文档之间存在冲突时，按以下优先级裁定：

```text
本宪法 (CONSTITUTION.md)
  ↓
模块规格 (module/*/spec/SPEC.md)
  ↓
交付治理文档 (docs/governance/DEVELOPMENT-WORKFLOW.md, TRACEABILITY.md, LIFECYCLE.md 等)
  ↓
架构文档 (ARCHITECTURE.md)
  ↓
模块详情 (module/foundation-modules.md, FOUNDATION-SPEC.md)
  ↓
其他文档
```

### 13.2 适用范围

本宪法适用于 `github.com/ZoneCNH` 下：

- **模块实现**：所有基座层模块（19 个）和 L2.5 领域共享层（5 个）
- **交付管线**：数据域、分析域、决策域、执行域的功能开发（Bug 修复和配置变更可走轻量流程，但仍需满足 §15.2 D1 和 D6）

§1-§14 约束模块实现质量；§15-§19 约束交付流程质量；§20 约束所有贡献者（含 AI Agent）的认识论标准。三者互补，不可互相豁免。

### 13.3 解释权

本宪法的解释权归项目维护者所有。AI 代理在遇到宪法条款的歧义时，应向人类维护者请求澄清，而非自行解释。

---
