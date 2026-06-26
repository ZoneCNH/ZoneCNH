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

Prompt 层待建立。关键 Task 优先生成 Context Package：
- TASK-BINANCE-SERVER-015 (Gin Market API)
- TASK-BINANCE-SERVER-017 (clickhousex OLAP)
- TASK-BINANCE-CLIENT-014 (natsx publisher)
