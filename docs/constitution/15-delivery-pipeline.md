> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](14-anti-goodhart.md) · [↑ 目录](README.md) · [下一节 →](16-traceability-gates.md)

---

## 第十五条：交付管线

> 适用于所有新功能开发。Bug 修复、文档更新、配置变更可走轻量流程，但仍需满足 D1（有来源）和 D6（有测试）。

### 15.1 管线模型

```text
Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
```

主流程每层必须产出一个具体制品，作为下一层的输入契约。Matrix 是横切追溯制品，必须在 Spec、Design、Plan、Tasks、Code、Test、Review、Release 之间持续更新，不作为主流程阶段。

### 15.2 管线七律

| 编号   | 原则                | 含义                                        |
| ------ | ------------------- | ------------------------------------------- |
| D1     | 无 Goal 不开始      | 任何代码变更必须追溯到已批准的 Goal         |
| D2     | 无 Spec 不拆解      | Goal 必须转化为可测试的 Spec 才能进入 Tasks |
| D3     | 无 Matrix 不开工    | 追溯矩阵必须建立才能开始编码                |
| D4     | 无 Task 不生成      | Prompt 必须引用具体 Task，不得开放式生成    |
| D5     | 无 Prompt 不交给 AI | AI 编码必须有结构化上下文和约束             |
| D6     | 无 Test 不完成      | 每条验收标准必须有对应测试                  |
| D7     | 无 Metrics 不算成功 | 上线后必须验证 Goal 达成                    |

### 15.3 变更传播

需求变更必须流经完整链条（Goal/Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release），并同步更新 Matrix 和 Evidence，禁止直接跳到代码修改。

### 15.4 实现细节

本条款的详细流程、制品模板和 Agent 编排规则见 `docs/governance/DEVELOPMENT-WORKFLOW.md`。

---
