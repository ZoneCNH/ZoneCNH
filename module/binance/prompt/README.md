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

**Pipeline State**：Spec→Code 管线的 S5-Prompt 层。Plan008 全部 40 Task 已在 runtime 仓 `/home/binance@f046e16` 实现完毕（代码级别）。v3.9.0 引入双态模型：Code-Done `24 / 10 Partial / 10 Pending`；Evidence-Done 仅 FR-009（L1 边界治理）。本 Prompt 层保留结构以备未来 Spec→Code 管线迭代使用（如 FR-031~036 ExchangeInfo 同步 v3.8.0 Draft→Active 提升时）。

**待生成 Context Package 的 Task**（按优先级排列）：
- FR-031~036（ExchangeInfo 同步）— v3.8.0 Draft→Active 已合并入根 SPEC，P0 级 S5→S6 输入
- FR-013 限流分钟模型对齐（v3.9.0 重写）— client runtime 需从秒模型迁移到分钟 weight 滑动窗口
- FR-017 缺口检测按事件类型分策略（v3.9.0 重写）— server runtime 需从统一时间间隔法迁移到 trade_id/updateId/open_time 序列检测
- TASK-BINANCE-SERVER-015 (Gin Market API) — Partial→Done 缺口闭合
- TASK-BINANCE-SERVER-017 (clickhousex OLAP) — ETL 持久化验证

**参考**：其他模块的 Prompt 示例见 `module/observex/prompt/`（10 个 PROMPT 文件）、`module/ossx/prompt/`（7 个 PROMPT 文件）。
