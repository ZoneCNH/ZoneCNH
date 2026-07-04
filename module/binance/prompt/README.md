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

**Pipeline State**：Spec→Code 管线的 S5-Prompt 层。v3.9.8 当前采用单状态模型：`48 Done / 0 Partial / 0 Drifted / 0 Pending`。release_closeable=YES（规格口径）；运行时口径当前 PRG-006=Partial。43 个 Binance P10 issue 已全部关闭（GitHub #1289~#1331 + Beads 43 条，10 轮验证 ALL PASS）。

> [COMPUTED, HIGH] 2026-06-28 full E2E 包仅作为历史运行证据，不构成发布关闭结论。后续生成新 Context Package 时，必须引用当前 P10 action plan、team fix context、Beads/GitHub issue 状态、[`../todo.md`](../todo.md) 只读投影与 [`../evidence/2026-06-28/todo-archived.md`](../evidence/2026-06-28/todo-archived.md) 的历史快照。

**已生成 Context Package**：
- `PROMPT-TASK-RUNTIME-E2E-20260704-001-001/`（R1：多产品线并发 + 真实 infra System E2E）

**待生成 Context Package 的 Task**（按需排列）：
- 43 个 Binance P10 issue 已全部关闭；PRG-001~007 全 PASS，release_closeable=YES
- L3 Production 准入完成：runtime / CI / release / coverage / soak / chaos 证据包已归档于 `evidence/2026-06-30/release/`

**参考**：其他模块的 Prompt 示例见 `module/observex/prompt/`（10 个 PROMPT 文件）、`module/ossx/prompt/`（7 个 PROMPT 文件）。
