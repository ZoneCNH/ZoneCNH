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

**Pipeline State**：Spec→Code 管线的 S5-Prompt 层。v4.1.0 规格单状态模型为 `65 Done / 0 Partial / 0 Drifted / 0 Pending`（FR-052~061 order book rebuild）；规格 `release_closeable_spec=YES`，runtime `release_closeable_runtime=NO`，直到外部 E2E、正式 tag/release notes 与 rollback evidence 绑定同一 commit。当前 implementation commit 为 `3f6366728b635c32d73565874965d40c20a92caf`；GitHub issue 状态不能替代 runtime release evidence。[COMPUTED, HIGH]

> [COMPUTED, HIGH] 2026-06-28 full E2E 包仅作为历史运行证据，不构成发布关闭结论。后续生成新 Context Package 时，必须引用当前 P10 action plan、team fix context、Beads/GitHub issue 状态、[`../todo.md`](../todo.md) 只读投影与 [`../evidence/2026-06-28/todo-archived.md`](../evidence/2026-06-28/todo-archived.md) 的历史快照。

**已生成 Context Package**：
- `PROMPT-TASK-RUNTIME-E2E-20260704-001-001/`（R1：多产品线并发 + 真实 infra System E2E）

**待生成 Context Package 的 Task**（按需排列）：
- 当前 release packet 必须引用 runtime evidence bundle、external-gates、最终 tag、CI、部署前检查和 rollback；缺失项标记 `BLOCKED`，不得生成“release_closeable=YES”结论
- L3 Production 规格准入投影已归档；runtime release packet 仍为 `BLOCKED`，必须绑定当前 runtime commit 的 external-gates、正式 tag、CI、部署前检查与 rollback 证据后才能转为可发布。

**参考**：其他模块的 Prompt 示例见 `module/observex/prompt/`（10 个 PROMPT 文件）、`module/ossx/prompt/`（7 个 PROMPT 文件）。
