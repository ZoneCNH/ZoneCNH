# module/binance prompt

Context Package 目录。按 Task 组织，每个 Task 一个子目录：

```text
prompt/
└── PROMPT-TASK-GOAL-YYYYMMDD-NNN-NNN/
    ├── v1.md             ← Context Package
    └── prompt-meta.yaml   ← 元数据
```

## Context Package 必须包含

- Goal 摘要
- Spec 摘要
- Matrix edge 映射
- Task 定义（输入/输出/DoD）
- 已有代码结构
- 约束与禁止事项
- 测试要求
- 停止条件

规范参考：`docs/goal/11-ai-collaboration.md` §2

## 当前状态

**Pipeline State**：Spec→Code 管线的 S5-Prompt 层。v3.9.0 双态模型当前为 Code `23 Done / 25 Partial / 0 Drifted / 0 Pending` (Code-State)；Evidence-State **44 Done / 0 Pending**。release_closeable=YES。GitHub #1267-#1279 全部 CLOSED。2026-06-28 全量 E2E 证据闭合：7 个外部依赖 live PASS + 4 产品线 mainnet live PASS + 全量门禁 PASS。

> [COMPUTED, HIGH] 2026-06-28 全量 E2E 证据闭合完成。后续如需生成新 Context Package，引用 [`../evidence/2026-06-28/release/full-e2e-closure.md`](../evidence/2026-06-28/release/full-e2e-closure.md) 与 [`../todo.md`](../todo.md)。

**待生成 Context Package 的 Task**（按需排列）：
- 全部 P0/P1/P2 项已完成，Evidence-Done 已闭合
- 后续如有新 FR 或迭代需求，按 Goal 管线流程生成新 Context Package

**参考**：其他模块的 Prompt 示例见 `module/observex/prompt/`（10 个 PROMPT 文件）、`module/ossx/prompt/`（7 个 PROMPT 文件）。
