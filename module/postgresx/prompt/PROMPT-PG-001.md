# PROMPT-PG-001
- Task：[../tasks/](../tasks/) | Trace：[../TRACEABILITY.md](../TRACEABILITY.md) | Spec：[../SPEC.md](../SPEC.md)
## 任务
实现 postgresx PostgreSQL 客户端：连接池/SQL执行/事务/迁移/健康检查/错误映射。
## 要点
1. typed Options 构造连接池
2. WithTx/WithTxOptions 事务边界（commit/rollback/panic回滚）
3. MigrationRunner.Up 升序迁移
4. SQLSTATE->foundationx 错误映射
5. DSN 不泄露到日志
