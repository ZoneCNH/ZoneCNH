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

**Pipeline State**：Spec→Code 管线的 S5-Prompt 层。v3.9.0 双态模型当前为 Code `23 Done / 25 Partial / 0 Drifted / 0 Pending` (Code-State)；Evidence-State **1 Done (FR-009) / 43 Pending**。FR-031~036、FR-038~044 为 Code-Partial / Evidence-Pending；FR-037 为 Code-Done / Evidence-Pending，本地 anchors 已存在但 production evidence/live/CI/dashboard/credential/multi-tenant/destruction gates 未闭合；后续 Context Package 不得把 anchors 写成生产闭合。

> [COMPUTED, HIGH] 2026-06-27 后如为 #1268-#1279 follow-up 生成 Context Package，必须引用 [`../evidence/2026-06-27/review/ISSUE-BLOCKERS-1268-1279.md`](../evidence/2026-06-27/review/ISSUE-BLOCKERS-1268-1279.md) 与 [`../todo.md`](../todo.md)；tracker state 不得作为 runtime proof。

**待生成 Context Package 的 Task**（按优先级排列）：
- FR-031~036（ExchangeInfo 同步）— Code-Partial / Evidence-Pending，下一轮仅补 direct TC/live/server integration evidence
- FR-013 限流分钟模型对齐 — Code-Partial / Evidence-Pending，下一轮仅补分钟 weight direct TC/live/evidence closure
- FR-017 缺口检测按事件类型分策略 — Code-Partial / Evidence-Pending，下一轮仅补 trade_id/updateId/open_time direct TC/live/evidence closure
- FR-025 P0/P1/P2 三级优先级对齐 — Code-Partial / Evidence-Pending，下一轮仅补优先级 throttle direct TC/live/evidence closure
- TASK-BINANCE-SERVER-015 (Gin Market API) — Partial→Done 缺口闭合
- TASK-BINANCE-SERVER-017 (clickhousex OLAP) — ETL 持久化验证

**参考**：其他模块的 Prompt 示例见 `module/observex/prompt/`（10 个 PROMPT 文件）、`module/ossx/prompt/`（7 个 PROMPT 文件）。
