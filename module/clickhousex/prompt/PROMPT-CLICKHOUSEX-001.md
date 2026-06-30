# TASK-CLICKHOUSEX-001 开发 Prompt

- 上游 Task：[tasks/](../tasks/)
- 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
- 权威 Spec：[SPEC.md](../SPEC.md)

## 任务

实现 clickhousex ClickHouse 客户端基础库：连接管理、SQL 执行、OLAP 查询、批量写入。

## 关联需求

FR-001~008（NewClient/Exec/Query/InsertBatch/Health/Close/Rows/ColumnTypes）。
BR-001~012（连接池/参数化/重试/幂等/Nullable/Decimal 映射）。

## 实现要点

1. ClickHouse native protocol 连接池
2. INSERT 使用 batch insert 协议（非拼接 SQL）
3. Nullable 映射到 Go 指针类型
4. Decimal 映射到 shopspring/decimal
5. 所有操作接受 context.Context
