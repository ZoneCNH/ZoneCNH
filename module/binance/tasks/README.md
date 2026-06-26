# module/binance/tasks — Task Index

本目录整合所有 binance 模块的实现任务，按子模块分层：

| 目录 | 范围 | Active | Archived |
|------|------|--------|----------|
| [root/](root/) | 跨切任务（依赖/boundary/文档） | 7 | 0 |
| [client/](client/) | 客户端采集器 | 12 | 2 |
| [server/](server/) | 服务端受理存储 | 14 | 3 |

## Task 引用规则

- 跨 task 引用使用相对路径：`../client/TASK-BINANCE-CLIENT-001-*.md`
- 归档 task 移到各自 `archive/` 子目录（R5 规则）
- 活跃 task 的 FR/AC/TC 锚点以 `TRACEABILITY.md` 为准
